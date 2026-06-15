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

// Kanaal van de simulator: e-mail (standaard), sms/whatsapp (smishing) of
// telefoon (vishing). Onbekende waarde valt terug op 'email'.
const SUPPORTED_CHANNELS = new Set(['email', 'sms', 'whatsapp', 'phone']);
function pickChannel(req) {
  const q = req.query?.channel || '';
  return SUPPORTED_CHANNELS.has(q) ? q : 'email';
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

// ======== INBOX-SIMULATOR ========

// GET /api/inbox?lang=nl|nl-BE|en|fr|fr-BE|de&audience=personal|business&difficulty=normal|advanced
// — lijst berichten zonder spoilers, gefilterd op taal, doelgroep en moeilijkheid.
router.get('/inbox', async (req, res, next) => {
  try {
    const locale = pickLocale(req);
    const audience = pickAudience(req);
    const difficulty = pickDifficulty(req);
    const channel = pickChannel(req);
    const listQuery = (loc, diff) => db.query(
      `SELECT id, channel, category, sender_name, sender_address, received_label, subject, preview,
              attachments
         FROM inbox_messages
        WHERE active = TRUE AND locale = $1 AND audience IN ($2, 'both')
          AND difficulty = $3 AND channel = $4
        ORDER BY sort_order, id`,
      [loc, audience, diff, channel]
    );
    let result = await withFallback(locale, (loc) => listQuery(loc, difficulty));
    // Niveau-fallback: heeft dit kanaal (nog) geen 'advanced'-berichten, val
    // dan terug op 'normal' zodat de simulator nooit leeg is.
    if (result.rowCount === 0 && difficulty !== 'normal') {
      result = await withFallback(locale, (loc) => listQuery(loc, 'normal'));
    }
    // In de lijst alleen tonen DÁT er een bijlage is (voor de paperclip).
    // Of die gevaarlijk is en de waarschuwing horen pas bij het openen —
    // net zoals we is_phishing/uitleg hier ook niet meegeven.
    const rows = result.rows.map((r) => Object.assign({}, r, {
      attachments: (r.attachments || []).map((a) => ({ filename: a.filename, size: a.size })),
    }));
    res.json(rows);

    // Analytics: training_start — once per session, fire-and-forget.
    // Admin-sessies tellen niet mee.
    if (!req.session.admin && !req.session.analyticsStarted) {
      req.session.analyticsStarted = true;
      req.session.save(() => {});
      db.query(
        `INSERT INTO analytics_events (event, lang, audience) VALUES ('training_start', $1, $2)`,
        [locale, audience]
      ).catch(() => {});
    }
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
    const channel = pickChannel(req);
    const printQuery = (loc, diff) => db.query(
      `SELECT id, channel, sender_name, sender_address, sender_note, received_label,
              subject, body, links, attachments, is_phishing, red_flags, green_flags,
              explanation, sort_order
         FROM inbox_messages
        WHERE active = TRUE AND locale = $1 AND audience IN ($2, 'both')
          AND difficulty = $3 AND channel = $4
        ORDER BY sort_order, id`,
      [loc, audience, diff, channel]
    );
    let result = await withFallback(locale, (loc) => printQuery(loc, difficulty));
    if (result.rowCount === 0 && difficulty !== 'normal') {
      result = await withFallback(locale, (loc) => printQuery(loc, 'normal'));
    }
    res.json(result.rows);
  } catch (err) { next(err); }
});

// GET /api/inbox/:id — volledig bericht, MAAR zonder uitslag/uitleg/rode vlaggen
router.get('/inbox/:id', async (req, res, next) => {
  try {
    const id = Number.parseInt(req.params.id, 10);
    if (!Number.isInteger(id)) return res.status(400).json({ error: 'ongeldig id' });
    const { rows } = await db.query(
      `SELECT id, channel, category, sender_name, sender_address, received_label, subject, body, links, attachments
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

    const { session_id: bodySessionId, verdict, difficulty: rawDiff, clicked_link = false, revealed_sender = false, enterprise = false } = req.body || {};
    if (verdict !== 'trust' && verdict !== 'phish') {
      return res.status(400).json({ error: 'verdict moet "trust" of "phish" zijn' });
    }
    const difficulty = SUPPORTED_DIFFICULTIES.has(rawDiff) ? rawDiff : 'normal';

    // Enterprise session overrides client-supplied session_id
    const orgUserId = req.session?.enterpriseOrgUserId || null;

    // De client dénkt enterprise te zijn maar de sessie is verlopen:
    // expliciet 401 — anders wordt het oordeel anoniem opgeslagen en
    // verliest de medewerker zijn voortgang zonder het te merken.
    if (enterprise && !orgUserId) {
      return res.status(401).json({ error: 'sessie verlopen', requiresReauth: true });
    }

    const session_id = orgUserId
      ? req.session.enterpriseSessionId
      : bodySessionId;

    if (!isUuidLike(session_id)) return res.status(400).json({ error: 'ongeldig session_id' });

    const { rows } = await db.query(
      `SELECT is_phishing, red_flags, green_flags, explanation, sender_note, locale, audience, channel
       FROM inbox_messages WHERE id = $1 AND active = TRUE`,
      [id]
    );
    if (rows.length === 0) return res.status(404).json({ error: 'niet gevonden' });

    const msg = rows[0];
    const isCorrect = verdict === (msg.is_phishing ? 'phish' : 'trust');

    // Altijd opslaan — voor enterprise ook org_user_id, voor publiek null.
    // ON CONFLICT: bij hertraining in dezelfde sessie telt het eerste oordeel;
    // de unique constraint houdt ook de tabelgroei in toom.
    await db.query(
      `INSERT INTO inbox_judgments
         (session_id, message_id, verdict, is_correct, clicked_link, revealed_sender, ip_address, difficulty, org_user_id)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)
       ON CONFLICT (session_id, message_id) DO NOTHING`,
      [session_id, id, verdict, isCorrect, !!clicked_link, !!revealed_sender, clientIp(req), difficulty, orgUserId]
    );
    if (orgUserId) {
      db.query(`UPDATE org_sessions SET last_active = NOW() WHERE session_id = $1`, [session_id]).catch(() => {});
    }

    res.json({
      correct: isCorrect,
      is_phishing: msg.is_phishing,
      red_flags: msg.red_flags,
      green_flags: msg.green_flags,
      explanation: msg.explanation,
      sender_note: msg.sender_note,
    });

    // Analytics: training_complete — check if all messages for this session are now judged.
    // Admin-sessies tellen niet mee. Fire-and-forget.
    if (!req.session.admin) db.query(
      `SELECT
         (SELECT COUNT(DISTINCT j.message_id)::int
            FROM inbox_judgments j
            JOIN inbox_messages m ON m.id = j.message_id
            WHERE j.session_id = $1 AND m.channel = $5) AS judged,
         (SELECT COUNT(*)::int
            FROM inbox_messages
            WHERE active = TRUE AND locale = $2 AND audience IN ($3, 'both')
              AND difficulty = $4 AND channel = $5) AS total`,
      [session_id, msg.locale, msg.audience, difficulty, msg.channel]
    ).then(({ rows: [r] }) => {
      if (r && r.judged >= r.total && r.total > 0) {
        db.query(
          `INSERT INTO analytics_events (event, lang, audience) VALUES ('training_complete', $1, $2)`,
          [msg.locale, msg.audience]
        ).catch(() => {});
      }
    }).catch(() => {});
  } catch (err) { next(err); }
});

// POST /api/simulator/start — no-op voor gratis gebruikers
router.post('/simulator/start', (_req, res) => res.status(201).json({ ok: true }));

// POST /api/easter-egg — no-op voor gratis gebruikers
router.post('/easter-egg', (_req, res) => res.status(201).json({ ok: true }));

// GET /api/enterprise/config
router.get('/enterprise/config', async (req, res, next) => {
  try {
    const orgUserId = req.session?.enterpriseOrgUserId;
    if (!orgUserId) return res.json({ enterprise: false });

    const { rows } = await db.query(`
      SELECT o.name, o.slug, o.locales, o.audiences, o.difficulties, o.email_domain, o.modules, o.channels
      FROM org_users u
      JOIN organisations o ON o.id = u.org_id
      WHERE u.id = $1
    `, [orgUserId]);

    if (!rows[0]) return res.json({ enterprise: false });
    const org = rows[0];
    const ALL_MODULES  = ['leren','simulator','kanalen','hulp','wachtwoord'];
    const ALL_CHANNELS = ['sms','whatsapp','phone'];
    res.json({
      enterprise: true,
      orgName: org.name,
      orgSlug: org.slug,
      locales: org.locales,
      audiences: org.audiences,
      difficulties: org.difficulties,
      emailDomain: org.email_domain || null,
      modules:  org.modules  || ALL_MODULES,
      channels: org.channels || ALL_CHANNELS,
    });
  } catch (err) { next(err); }
});

// GET /api/enterprise/progress — voortgang van de ingelogde enterprise-gebruiker
// Alleen de huidige trainingsronde: judgments worden opgeslagen met de
// enterpriseSessionId die bij iedere login opnieuw wordt aangemaakt. Zonder
// dit filter zou een herhaaltraining de oordelen van de vórige ronde mee
// terugkrijgen en na een paar antwoorden direct op "afgerond" springen.
router.get('/enterprise/progress', async (req, res, next) => {
  const orgUserId = req.session?.enterpriseOrgUserId;
  const sessionId = req.session?.enterpriseSessionId;
  if (!orgUserId || !sessionId) return res.json({ judgments: {} });
  try {
    const { rows } = await db.query(
      `SELECT j.message_id, j.verdict, j.is_correct, m.is_phishing
       FROM inbox_judgments j
       JOIN inbox_messages m ON m.id = j.message_id
       WHERE j.org_user_id = $1 AND j.session_id = $2
       ORDER BY j.answered_at ASC`,
      [orgUserId, sessionId]
    );
    const judgments = {};
    rows.forEach(r => {
      judgments[r.message_id] = { verdict: r.verdict, correct: r.is_correct, is_phishing: r.is_phishing };
    });
    res.json({ judgments });
  } catch (err) { next(err); }
});

// GET /api/enterprise/history — laatste afronding, gemiste berichten, verdiende badges.
// Géén persoonsgegevens: alles gekoppeld aan het anonieme interne org_user_id.
router.get('/enterprise/history', async (req, res, next) => {
  const orgUserId = req.session?.enterpriseOrgUserId;
  if (!orgUserId) return res.status(401).json({ error: 'unauthorized' });
  try {
    const [compResult, badgesResult, missedResult] = await Promise.all([
      db.query(
        `SELECT EXTRACT(EPOCH FROM completed_at)::float * 1000 AS ts
           FROM user_completions
          WHERE org_user_id = $1
          ORDER BY completed_at DESC LIMIT 1`,
        [orgUserId]
      ),
      db.query(
        `SELECT badge FROM user_badges WHERE org_user_id = $1`,
        [orgUserId]
      ),
      db.query(
        `SELECT DISTINCT j.message_id::text AS mid
           FROM inbox_judgments j
          WHERE j.org_user_id = $1 AND j.is_correct = FALSE`,
        [orgUserId]
      ),
    ]);
    res.json({
      lastCompletion: compResult.rows[0] ? Number(compResult.rows[0].ts) : 0,
      badges:         badgesResult.rows.map((r) => r.badge),
      missedIds:      missedResult.rows.map((r) => r.mid),
    });
  } catch (err) { next(err); }
});

// POST /api/enterprise/complete — sla afronding + verdiende badges op (server-side retentie).
router.post('/enterprise/complete', async (req, res, next) => {
  const orgUserId = req.session?.enterpriseOrgUserId;
  const sessionId = req.session?.enterpriseSessionId;
  if (!orgUserId || !sessionId) return res.status(401).json({ error: 'unauthorized' });
  try {
    const { total = 0, correct = 0, wasRefresher = false, badges = [] } = req.body || {};
    await db.query(
      `INSERT INTO user_completions (org_user_id, session_id, total_messages, correct_count, was_refresher)
       VALUES ($1, $2, $3, $4, $5)`,
      [orgUserId, sessionId, Number(total) || 0, Number(correct) || 0, !!wasRefresher]
    );
    if (Array.isArray(badges) && badges.length > 0) {
      for (const badge of badges) {
        if (typeof badge !== 'string' || !badge) continue;
        await db.query(
          `INSERT INTO user_badges (org_user_id, badge) VALUES ($1, $2) ON CONFLICT DO NOTHING`,
          [orgUserId, badge]
        );
      }
    }
    res.json({ ok: true });
  } catch (err) { next(err); }
});

// GET /api/qr-scans?session_id=… — heeft deze sessie de QR-code(s) gescand?
// Enterprise: sessie uit de cookie. Publiek: session_id-parameter.
router.get('/qr-scans', async (req, res, next) => {
  try {
    const sid = req.session?.enterpriseSessionId || String(req.query.session_id || '');
    if (!isUuidLike(sid)) return res.json({ scans: [] });
    const { rows } = await db.query(
      `SELECT tag FROM qr_scans WHERE session_id = $1`, [sid]
    );
    res.json({ scans: rows.map(r => r.tag) });
  } catch (err) { next(err); }
});

module.exports = router;
