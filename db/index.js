const { Pool } = require('pg');

if (!process.env.DATABASE_URL) {
  console.warn('[db] DATABASE_URL is niet gezet. De API werkt pas zodra deze gezet is (Neon connection string).');
}

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.PGSSL === 'disable' ? false : { rejectUnauthorized: true },
  max: 5,
  idleTimeoutMillis: 30_000,
});

pool.on('error', (err) => {
  console.error('[db] onverwachte pool-fout:', err.message);
});

module.exports = {
  query: (text, params) => pool.query(text, params),
  pool,
};
