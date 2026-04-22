#!/usr/bin/env node
/**
 * Handmatige database-initialisatie — handig voor lokaal of voor een
 * éénmalige run vanaf je eigen machine tegen de Neon-DB.
 *
 *   npm run db:init                # alleen seeden als de tabel leeg is
 *   node scripts/init-db.js --force-seed
 *
 * Op Render Free hoef je dit NIET te draaien: de server doet het zelf
 * bij het opstarten (zie db/init.js).
 */
require('dotenv').config();
const { initDb } = require('../db/init');
const { pool } = require('../db');

const force = process.argv.includes('--force-seed');

initDb({ force })
  .then(() => {
    console.log('[init-db] klaar.');
    return pool.end();
  })
  .catch((err) => {
    console.error('[init-db] fout:', err);
    pool.end().finally(() => process.exit(1));
  });
