/**
 * Past schema.sql toe en zaait seed.sql wanneer er nog geen vragen zijn.
 * Idempotent: veilig om bij elke serverstart aan te roepen.
 *
 * Reden: op Render Free is er geen Shell, dus kunnen we `npm run db:init`
 * niet handmatig draaien. We doen het automatisch tijdens de boot.
 */
const fs = require('fs');
const path = require('path');
const db = require('./index');

const SCHEMA_PATH = path.join(__dirname, 'schema.sql');
const SEED_PATH = path.join(__dirname, 'seed.sql');

async function initDb({ force = false } = {}) {
  if (!process.env.DATABASE_URL) {
    throw new Error('DATABASE_URL is niet gezet — kan database niet initialiseren.');
  }

  const schema = fs.readFileSync(SCHEMA_PATH, 'utf8');
  const seed = fs.readFileSync(SEED_PATH, 'utf8');

  const client = await db.pool.connect();
  try {
    console.log('[init-db] schema toepassen...');
    await client.query(schema);

    const { rows } = await client.query('SELECT COUNT(*)::int AS n FROM quiz_questions');
    const isEmpty = rows[0].n === 0;

    if (isEmpty || force) {
      console.log(`[init-db] seed laden${force ? ' (force)' : ''}...`);
      await client.query(seed);
    } else {
      console.log(`[init-db] ${rows[0].n} vragen aanwezig — seed overgeslagen.`);
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
