#!/usr/bin/env node
/**
 * Eenmalige database-initialisatie: voert schema.sql uit en seed.sql.
 * Lokaal: `npm run db:init` (vereist DATABASE_URL).
 * Op Render: kan handmatig gedraaid worden via "Shell" of als one-off job.
 */
require('dotenv').config();
const fs = require('fs');
const path = require('path');
const { pool } = require('../db');

async function run() {
  const schema = fs.readFileSync(path.join(__dirname, '..', 'db', 'schema.sql'), 'utf8');
  const seed = fs.readFileSync(path.join(__dirname, '..', 'db', 'seed.sql'), 'utf8');

  const client = await pool.connect();
  try {
    console.log('[init-db] schema.sql toepassen...');
    await client.query(schema);

    const { rows } = await client.query('SELECT COUNT(*)::int AS n FROM quiz_questions');
    if (rows[0].n === 0 || process.argv.includes('--force-seed')) {
      console.log('[init-db] seed.sql laden...');
      await client.query(seed);
    } else {
      console.log(`[init-db] ${rows[0].n} vragen aanwezig — seed overgeslagen (gebruik --force-seed om te overschrijven).`);
    }

    console.log('[init-db] klaar.');
  } finally {
    client.release();
    await pool.end();
  }
}

run().catch((err) => {
  console.error('[init-db] fout:', err);
  process.exit(1);
});
