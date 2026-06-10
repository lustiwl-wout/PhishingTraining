const { Pool } = require('pg');

if (!process.env.DATABASE_URL) {
  console.warn('[db] DATABASE_URL is niet gezet. De API werkt pas zodra deze gezet is (Neon connection string).');
}

// pg v8 behandelt sslmode=prefer/require/verify-ca als verify-full (volledige
// certificaatvalidatie), maar pg v9 gaat libpq-semantiek volgen waarin
// "require" géén certificaat valideert. Expliciet verify-full pinnen houdt
// het huidige, veilige gedrag — ook na een toekomstige pg-upgrade — en
// onderdrukt de SECURITY WARNING bij het opstarten.
const connectionString = (process.env.DATABASE_URL || '')
  .replace(/\bsslmode=(prefer|require|verify-ca)\b/, 'sslmode=verify-full');

const pool = new Pool({
  connectionString,
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
