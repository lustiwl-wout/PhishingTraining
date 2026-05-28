const express = require('express');
const db = require('../db');

const router = express.Router();

// --- helpers ---
function clientIp(req) {
  const fwd = req.headers['x-forwarded-for'];
  return (fwd ? fwd.split(',')[0] : req.socket?.remoteAddress || '').trim();
}

function isUuidLike(s) {
  return typeof s === 'string' && /^[a-zA-Z0-9_-]{8,64}$/.test(s);
}

const SUPPORTED_LOCALES = new Set(['nl', 'nl-BE', 'en', 'fr', 'fr-BE', 'de']);
function pickLocale(req) {
  const q = req.query?.lang || '';
  return SUPPORTED_LOCALES.has(q) ? q : 'nl';
}

const SUPPORTED_AUDIENCES = new Set(['personal', 'business']);
function pickAudience(req) {
  const q = req.query?.audience || '';
  return SUPPORTED_AUDIENCES.has(q) ? q : 'personal';
}

const SUPPORTED_DIFFICULTIES = new Set(['normal', 'advanced']);
function pickDifficulty(req) {
  const q = req.query?.difficulty || '';
  return SUPPORTED_DIFFICULTIES.has(q) ? q : 'normal';
}

// Voer `queryFn(locale)` uit voor de gevraagde taal en val terug op 'nl'
// wanneer er nog geen vertaalde rijen bestaan. Zo breekt de UI niet bij
// een nieuwe locale die nog niet in de seed zit.
async function withFallback(locale, queryFn) {
  const primary = await queryFn(locale);
  if (primary.rowCount > 0 || locale === 'nl') return primary;
  return queryFn('nl');
}

// GET /api/health
router.get('/health', async (_req, res) => {
  try {
    const { rows } = await db.query('SELECT NOW() AS now');
    res.json({ ok: true, db_time: rows[0].now });
  } catch {
    res.status(503).json({ ok: false, error: 'database niet bereikbaar' });
  }
});

// GET /api/examples?lang=nl|nl-BE|en|fr|fr-BE|de&audience=personal|business
router.get('/examples', async (req, res, next) => {
  try {
    const locale = pickLocale(req);
    const audience = pickAudience(req);
    const result = await withFallback(locale, (loc) => db.query(
      `SELECT id, channel, sender, subject, body, annotations, sort_order
         FROM examples
        WHERE locale = $1 AND audience IN ($2, 'both')
        ORDER BY sort_order, id`,
      [loc, audience]
    ));
    res.json(result.rows);
  } catch (err) { next(err); }
});

// GET /api/quiz?limit=5
router.get('/quiz', async (req, res, next) => {
  try {
    const limit = Math.min(Number.parseInt(req.query.limit, 10) || 5, 20);
    const { rows } = await db.query(
      `SELECT id, channel, sender, subject, body, is_phishing, explanation, signs, difficulty
       FROM quiz_questions
       WHERE active = TRUE
       ORDER BY RANDOM()
       LIMIT $1`,
      [limit]
    );
    res.json(rows);
  } catch (err) { next(err); }
});

// POST /api/attempts  { session_id }
router.post('/attempts', async (req, res, next) => {
  try {
    const sessionId = req.body?.session_id || '';
    if (!isUuidLike(sessionId)) {
      return res.status(400).json({ error: 'ongeldig session_id' });
    }
    const { rows } = await db.query(
      'INSERT INTO quiz_attempts (session_id, ip_address) VALUES ($1, $2) RETURNING id, started_at',
      [sessionId, clientIp(req)]
    );
    res.status(201).json(rows[0]);
  } catch (err) { next(err); }
});

// POST /api/attempts/:id/answers  { question_id, answered_phishing }
router.post('/attempts/:id/answers', async (req, res, next) => {
  try {
    const attemptId = Number.parseInt(req.params.id, 10);
    if (!Number.isInteger(attemptId)) return res.status(400).json({ error: 'ongeldige attempt id' });

    const { question_id, answered_phishing } = req.body || {};
    if (!Number.isInteger(question_id) || typeof answered_phishing !== 'boolean') {
      return res.status(400).json({ error: 'question_id (int) en answered_phishing (bool) vereist' });
    }

    const q = await db.query('SELECT is_phishing FROM quiz_questions WHERE id = $1', [question_id]);
    if (q.rowCount === 0) return res.status(404).json({ error: 'vraag niet gevonden' });

    const isCorrect = q.rows[0].is_phishing === answered_phishing;

    await db.query(
      `INSERT INTO quiz_answers (attempt_id, question_id, answered_phishing, is_correct)
       VALUES ($1, $2, $3, $4)`,
      [attemptId, question_id, answered_phishing, isCorrect]
    );

    await db.query(
      `UPDATE quiz_attempts
       SET total = total + 1,
           correct = correct + CASE WHEN $2 THEN 1 ELSE 0 END
       WHERE id = $1`,
      [attemptId, isCorrect]
    );

    res.json({ correct: isCorrect, was_phishing: q.rows[0].is_phishing });
  } catch (err) { next(err); }
});

// POST /api/attempts/:id/finish
router.post('/attempts/:id/finish', async (req, res, next) => {
  try {
    const attemptId = Number.parseInt(req.params.id, 10);
    if (!Number.isInteger(attemptId)) return res.status(400).json({ error: 'ongeldige attempt id' });

    const { rows } = await db.query(
      `UPDATE quiz_attempts SET finished_at = NOW()
       WHERE id = $1
       RETURNING id, total, correct, started_at, finished_at`,
      [attemptId]
    );
    if (rows.length === 0) return res.status(404).json({ error: 'attempt niet gevonden' });
    res.json(rows[0]);
  } catch (err) { next(err); }
});

// ======== INBOX-SIMULATOR ========

// GET /api/inbox?lang=nl|nl-BE|en|fr|fr-BE|de&audience=personal|business&difficulty=normal|advanced
// — lijst berichten zonder spoilers, gefilterd op taal, doelgroep en moeilijkheid.
router.get('/inbox', async (req, res, next) => {
  try {
    const locale = pickLocale(req);
    const audience = pickAudience(req);
    const difficulty = pickDifficulty(req);
    const result = await withFallback(locale, (loc) => db.query(
      `SELECT id, sender_name, sender_address, received_label, subject, preview
         FROM inbox_messages
        WHERE active = TRUE AND locale = $1 AND audience IN ($2, 'both') AND difficulty = $3
        ORDER BY sort_order, id`,
      [loc, audience, difficulty]
    ));
    res.json(result.rows);
  } catch (err) { next(err); }
});

// GET /api/print?lang=&audience=&difficulty=normal|advanced
// — alle inhoud (subject, body, links, sender_note, is_phishing,
//   red_flags, green_flags, explanation) zodat een printbare versie
//   van de training gegenereerd kan worden waarop het antwoord op
//   de volgende bladzijde staat.
router.get('/print', async (req, res, next) => {
  try {
    const locale = pickLocale(req);
    const audience = pickAudience(req);
    const difficulty = pickDifficulty(req);
    const result = await withFallback(locale, (loc) => db.query(
      `SELECT id, sender_name, sender_address, sender_note, received_label,
              subject, body, links, is_phishing, red_flags, green_flags,
              explanation, sort_order
         FROM inbox_messages
        WHERE active = TRUE AND locale = $1 AND audience IN ($2, 'both') AND difficulty = $3
        ORDER BY sort_order, id`,
      [loc, audience, difficulty]
    ));
    res.json(result.rows);
  } catch (err) { next(err); }
});

// GET /api/inbox/:id — volledig bericht, MAAR zonder uitslag/uitleg/rode vlaggen
router.get('/inbox/:id', async (req, res, next) => {
  try {
    const id = Number.parseInt(req.params.id, 10);
    if (!Number.isInteger(id)) return res.status(400).json({ error: 'ongeldig id' });
    const { rows } = await db.query(
      `SELECT id, sender_name, sender_address, received_label, subject, body, links, attachments
       FROM inbox_messages WHERE id = $1 AND active = TRUE`,
      [id]
    );
    if (rows.length === 0) return res.status(404).json({ error: 'niet gevonden' });
    res.json(rows[0]);
  } catch (err) { next(err); }
});

// POST /api/inbox/:id/judge  { session_id, verdict, difficulty?, clicked_link?, revealed_sender? }
router.post('/inbox/:id/judge', async (req, res, next) => {
  try {
    const id = Number.parseInt(req.params.id, 10);
    if (!Number.isInteger(id)) return res.status(400).json({ error: 'ongeldig id' });

    const { session_id: bodySessionId, verdict, difficulty: rawDiff, clicked_link = false, revealed_sender = false } = req.body || {};
    if (verdict !== 'trust' && verdict !== 'phish') {
      return res.status(400).json({ error: 'verdict moet "trust" of "phish" zijn' });
    }
    const difficulty = SUPPORTED_DIFFICULTIES.has(rawDiff) ? rawDiff : 'normal';

    // Enterprise session overrides client-supplied session_id
    const orgUserId = req.session?.enterpriseOrgUserId || null;
    const session_id = orgUserId
      ? req.session.enterpriseSessionId
      : bodySessionId;

    if (!isUuidLike(session_id)) return res.status(400).json({ error: 'ongeldig session_id' });

    const { rows } = await db.query(
      `SELECT is_phishing, red_flags, green_flags, explanation, sender_note
       FROM inbox_messages WHERE id = $1 AND active = TRUE`,
      [id]
    );
    if (rows.length === 0) return res.status(404).json({ error: 'niet gevonden' });

    const msg = rows[0];
    const isCorrect = verdict === (msg.is_phishing ? 'phish' : 'trust');

    await db.query(
      `INSERT INTO inbox_judgments
         (session_id, message_id, verdict, is_correct, clicked_link, revealed_sender, ip_address, difficulty, org_user_id)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)`,
      [session_id, id, verdict, isCorrect, !!clicked_link, !!revealed_sender, clientIp(req), difficulty, orgUserId]
    );

    // Update org_session last_active
    if (orgUserId && req.session.enterpriseSessionId) {
      db.query(`UPDATE org_sessions SET last_active = NOW() WHERE session_id = $1`, [req.session.enterpriseSessionId]).catch(() => {});
    }

    res.json({
      correct: isCorrect,
      is_phishing: msg.is_phishing,
      red_flags: msg.red_flags,
      green_flags: msg.green_flags,
      explanation: msg.explanation,
      sender_note: msg.sender_note,
    });
  } catch (err) { next(err); }
});

// GET /api/stats — geanonimiseerde geaggregeerde statistieken
router.get('/stats', async (_req, res, next) => {
  try {
    const totals = await db.query(
      `SELECT
         (SELECT COUNT(*)::int FROM quiz_attempts WHERE finished_at IS NOT NULL) AS afgerond,
         (SELECT COUNT(*)::int FROM quiz_answers) AS antwoorden,
         (SELECT COALESCE(ROUND(AVG(CASE WHEN is_correct THEN 1.0 ELSE 0.0 END) * 100), 0)::int
            FROM quiz_answers) AS gemiddeld_pct`
    );
    res.json(totals.rows[0]);
  } catch (err) { next(err); }
});

// POST /api/simulator/start  { session_id }
router.post('/simulator/start', async (req, res, next) => {
  try {
    const sessionId = req.body?.session_id || '';
    if (!isUuidLike(sessionId)) return res.status(400).json({ error: 'ongeldig session_id' });
    await db.query(
      'INSERT INTO simulator_starts (session_id, ip_address) VALUES ($1, $2)',
      [sessionId, clientIp(req)]
    );
    res.status(201).json({ ok: true });
  } catch (err) { next(err); }
});

// POST /api/easter-egg  { session_id }
router.post('/easter-egg', async (req, res, next) => {
  try {
    const sessionId = req.body?.session_id || '';
    if (!isUuidLike(sessionId)) return res.status(400).json({ error: 'ongeldig session_id' });
    await db.query(
      'INSERT INTO easter_egg_views (session_id, ip_address) VALUES ($1, $2)',
      [sessionId, clientIp(req)]
    );
    res.status(201).json({ ok: true });
  } catch (err) { next(err); }
});

module.exports = router;
