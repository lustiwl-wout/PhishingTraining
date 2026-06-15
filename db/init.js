/**
 * Past schema.sql toe en zaait seed.sql wanneer er nog geen vragen zijn.
 * Idempotent: veilig om bij elke serverstart aan te roepen.
 *
 * Reden: op Render Free is er geen Shell, dus kunnen we `npm run db:init`
 * niet handmatig draaien. We doen het automatisch tijdens de boot.
 */
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const db = require('./index');

const SCHEMA_PATH = path.join(__dirname, 'schema.sql');
const SEED_PATH = path.join(__dirname, 'seed.sql');

async function initDb({ force = false } = {}) {
  if (!process.env.DATABASE_URL) {
    throw new Error('DATABASE_URL is niet gezet — kan database niet initialiseren.');
  }

  const schema = fs.readFileSync(SCHEMA_PATH, 'utf8');
  const seed = fs.readFileSync(SEED_PATH, 'utf8');
  const seedHash = crypto.createHash('sha256').update(seed).digest('hex').slice(0, 16);

  const client = await db.pool.connect();
  try {
    console.log('[init-db] schema toepassen...');
    await client.query(schema);

    // Mini "migratie"-tabel: onthoudt welke seed-hash als laatste is geladen.
    await client.query(`
      CREATE TABLE IF NOT EXISTS schema_meta (
        key   TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      )
    `);

    const { rows: metaRows } = await client.query(
      `SELECT value FROM schema_meta WHERE key = 'seed_hash'`
    );
    const previousHash = metaRows[0] && metaRows[0].value;

    // Seed opnieuw draaien wanneer: een tabel die de seed vult leeg is, de
    // seed-inhoud is veranderd (hash wijziging), of wanneer expliciet geforceerd.
    // We controleren alleen de tabellen die de seed daadwerkelijk vult.
    const { rows: countRows } = await client.query(`
      SELECT
        (SELECT COUNT(*) FROM examples)       AS e,
        (SELECT COUNT(*) FROM inbox_messages) AS i
    `);
    const counts = countRows[0];
    const anyEmpty = Number(counts.e) === 0 || Number(counts.i) === 0;
    const hashChanged = previousHash !== seedHash;

    // Altijd de actuele rij-aantallen loggen, zodat je ook bij een
    // overgeslagen seed ziet hoe vol de content-tabellen zijn.
    console.log(`[init-db] content-tabellen: examples=${counts.e} inbox_messages=${counts.i}`);

    if (force || anyEmpty || hashChanged) {
      let reason;
      if (force) {
        reason = 'force';
      } else if (anyEmpty) {
        // Benoem precies wélke tabel(len) leeg zijn — dat is de info die
        // we nodig hebben om een onverwachte her-seed te debuggen.
        const empty = [];
        if (Number(counts.e) === 0) empty.push('examples');
        if (Number(counts.i) === 0) empty.push('inbox_messages');
        reason = `lege tabel: ${empty.join(', ')}`;
      } else {
        reason = 'seed-inhoud gewijzigd';
      }
      console.log(`[init-db] seed laden (${reason}). hash: ${previousHash || 'none'} -> ${seedHash}`);

      // Bewaar gebruikersdata vóór de seed — sequentieel op dezelfde client.
      const judgments  = await client.query('SELECT * FROM inbox_judgments').catch(() => ({ rows: [] }));
      const eggs       = await client.query('SELECT * FROM easter_egg_views').catch(() => ({ rows: [] }));
      const simStarts  = await client.query('SELECT * FROM simulator_starts').catch(() => ({ rows: [] }));
      const orgs       = await client.query('SELECT * FROM organisations').catch(() => ({ rows: [] }));
      const orgUsers   = await client.query('SELECT * FROM org_users').catch(() => ({ rows: [] }));
      const orgSessions = await client.query('SELECT * FROM org_sessions').catch(() => ({ rows: [] }));
      console.log(`[init-db] ${judgments.rows.length} oordelen, ${eggs.rows.length} easter-egg views, ${simStarts.rows.length} simulator-starts, ${orgs.rows.length} organisaties, ${orgUsers.rows.length} org-gebruikers opgeslagen.`);

      await client.query(seed);

      // Zet gebruikersdata terug. message_id-referenties zijn geldig zolang de
      // seed dezelfde berichten in dezelfde volgorde invoegt (RESTART IDENTITY).
      // Organisations first (org_users + org_sessions depend on them)
      if (orgs.rows.length > 0) {
        for (const r of orgs.rows) {
          await client.query(
            `INSERT INTO organisations
               (id, name, slug, email_domain, locales, audiences, difficulties, max_users, valid_until, admin_token, created_at)
             VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11) ON CONFLICT (id) DO NOTHING`,
            [r.id, r.name, r.slug, r.email_domain ?? null, r.locales, r.audiences, r.difficulties, r.max_users, r.valid_until, r.admin_token, r.created_at]
          );
        }
        await client.query(`SELECT setval('organisations_id_seq', MAX(id)) FROM organisations`);
        console.log(`[init-db] ${orgs.rows.length} organisaties teruggezet.`);
      }
      if (orgUsers.rows.length > 0) {
        for (const r of orgUsers.rows) {
          await client.query(
            `INSERT INTO org_users
               (id, org_id, numeric_id, pincode_hash, allow_retrain, failed_attempts, locked_until, created_at)
             VALUES ($1,$2,$3,$4,$5,$6,$7,$8) ON CONFLICT (id) DO NOTHING`,
            [r.id, r.org_id, r.numeric_id, r.pincode_hash, r.allow_retrain,
             r.failed_attempts, r.locked_until, r.created_at]
          );
        }
        await client.query(`SELECT setval('org_users_id_seq', MAX(id)) FROM org_users`);
        console.log(`[init-db] ${orgUsers.rows.length} org-gebruikers teruggezet.`);
      }
      if (orgSessions.rows.length > 0) {
        for (const r of orgSessions.rows) {
          await client.query(
            `INSERT INTO org_sessions (id, org_user_id, session_id, started_at, last_active)
             VALUES ($1,$2,$3,$4,$5) ON CONFLICT (id) DO NOTHING`,
            [r.id, r.org_user_id, r.session_id, r.started_at, r.last_active]
          );
        }
        await client.query(`SELECT setval('org_sessions_id_seq', MAX(id)) FROM org_sessions`);
        console.log(`[init-db] ${orgSessions.rows.length} org-sessies teruggezet.`);
      }

      if (judgments.rows.length > 0) {
        for (const r of judgments.rows) {
          await client.query(
            `INSERT INTO inbox_judgments
               (id, session_id, message_id, verdict, is_correct, clicked_link,
                revealed_sender, ip_address, difficulty, org_user_id, answered_at)
             VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)
             ON CONFLICT DO NOTHING`,
            [r.id, r.session_id, r.message_id, r.verdict, r.is_correct,
             r.clicked_link, r.revealed_sender, r.ip_address,
             r.difficulty ?? 'normal', r.org_user_id ?? null, r.answered_at]
          );
        }
        await client.query(`SELECT setval('inbox_judgments_id_seq', MAX(id)) FROM inbox_judgments`);
        console.log(`[init-db] ${judgments.rows.length} oordelen teruggezet.`);
      }
      if (eggs.rows.length > 0) {
        for (const r of eggs.rows) {
          await client.query(
            `INSERT INTO easter_egg_views (id, session_id, ip_address, viewed_at)
             VALUES ($1,$2,$3,$4) ON CONFLICT (id) DO NOTHING`,
            [r.id, r.session_id, r.ip_address, r.viewed_at]
          );
        }
        await client.query(`SELECT setval('easter_egg_views_id_seq', MAX(id)) FROM easter_egg_views`);
        console.log(`[init-db] ${eggs.rows.length} easter-egg views teruggezet.`);
      }
      if (simStarts.rows.length > 0) {
        for (const r of simStarts.rows) {
          await client.query(
            `INSERT INTO simulator_starts (id, session_id, ip_address, started_at)
             VALUES ($1,$2,$3,$4) ON CONFLICT (id) DO NOTHING`,
            [r.id, r.session_id, r.ip_address, r.started_at]
          );
        }
        await client.query(`SELECT setval('simulator_starts_id_seq', MAX(id)) FROM simulator_starts`);
        console.log(`[init-db] ${simStarts.rows.length} simulator-starts teruggezet.`);
      }

      await client.query(
        `INSERT INTO schema_meta (key, value, updated_at)
         VALUES ('seed_hash', $1, NOW())
         ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value, updated_at = NOW()`,
        [seedHash]
      );
    } else {
      console.log(`[init-db] seed al actueel (hash ${seedHash}) — overgeslagen.`);
    }
  } finally {
    client.release();
  }
}

async function initDbWithRetry({ retries = 5, delayMs = 2000 } = {}) {
  for (let attempt = 1; attempt <= retries; attempt++) {
    try {
      await initDb();
      return true;
    } catch (err) {
      console.warn(`[init-db] poging ${attempt}/${retries} mislukt: ${err.message}`);
      if (attempt < retries) {
        await new Promise((r) => setTimeout(r, delayMs * attempt));
      }
    }
  }
  console.error('[init-db] kon database niet initialiseren — server blijft draaien, /api/health zal 503 geven.');
  return false;
}

module.exports = { initDb, initDbWithRetry };
