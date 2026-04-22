/**
 * Past schema.sql toe en zaait seed.sql wanneer er nog geen vragen zijn.
 * Idempotent: veilig om bij elke serverstart aan te roepen.
 *
 * Reden: op Render Free is er geen Shell, dus kunnen we `npm run db:init`
 * niet handmatig draaien. We doen het automatisch tijdens de boot.
 */
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
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

    // Seed opnieuw draaien wanneer: tabellen leeg zijn, de seed-inhoud is
    // veranderd (hash wijziging), of wanneer expliciet geforceerd.
    const { rows: countRows } = await client.query(`
      SELECT
        (SELECT COUNT(*) FROM quiz_questions) AS q,
        (SELECT COUNT(*) FROM examples)       AS e,
        (SELECT COUNT(*) FROM inbox_messages) AS i
    `);
    const counts = countRows[0];
    const anyEmpty = Number(counts.q) === 0 || Number(counts.e) === 0 || Number(counts.i) === 0;
    const hashChanged = previousHash !== seedHash;

    if (force || anyEmpty || hashChanged) {
      const reason = force ? 'force' : (anyEmpty ? 'lege tabel' : 'seed-inhoud gewijzigd');
      console.log(`[init-db] seed laden (${reason}). hash: ${previousHash || 'none'} -> ${seedHash}`);
      await client.query(seed);
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
