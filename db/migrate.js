/**
 * Eenmalige datamigratie van de oude Neon-database (OLD_DATABASE_URL) naar de
 * nieuwe (DATABASE_URL). Draait automatisch bij het opstarten, vóór init-db.
 *
 * Reden: op Render Free is er geen Shell en lokaal ontbreekt pg-tooling, dus
 * de migratie moet tijdens de deploy zelf gebeuren.
 *
 * Werking:
 *  1. Skip als de marker 'migrated_from' al in schema_meta van de nieuwe DB
 *     staat — idempotent, OLD_DATABASE_URL mag dus blijven staan.
 *  2. Past schema.sql toe op de nieuwe DB zodat alle tabellen bestaan.
 *  3. Kloont alle tabellen verbatim (inhoud + id's + seed-hash) binnen één
 *     transactie. Verbatim is belangrijk: inbox_judgments.message_id verwijst
 *     naar inbox_messages-id's uit de oude seed-volgorde. Na de kloon ziet
 *     init-db zelf of de seed-hash is veranderd en her-seedt dan met zijn
 *     bestaande backup/restore van gebruikersdata.
 *  4. Kopieert ook de sessie-tabel (user_sessions) zodat ingelogde
 *     gebruikers niet uitgelogd raken door de migratie.
 */
const fs = require('node:fs');
const path = require('node:path');
const { Pool } = require('pg');
const db = require('./index');

const SCHEMA_PATH = path.join(__dirname, 'schema.sql');

// Volgorde is FK-veilig: ouders vóór kinderen.
const TABLES = [
  'examples',
  'inbox_messages',
  'qr_scans',
  'organisations',
  'org_users',
  'org_sessions',
  'inbox_judgments',
  'easter_egg_views',
  'simulator_starts',
  'user_completions',
  'analytics_events',
  'schema_meta',
];

// Zelfde definitie als connect-pg-simple's table.sql, zodat we sessies
// kunnen kopiëren voordat de session-store de tabel zelf aanmaakt.
const SESSIONS_DDL = `
  CREATE TABLE IF NOT EXISTS user_sessions (
    sid    VARCHAR NOT NULL PRIMARY KEY,
    sess   JSON NOT NULL,
    expire TIMESTAMP(6) NOT NULL
  );
  CREATE INDEX IF NOT EXISTS idx_user_sessions_expire ON user_sessions (expire);
`;

function oldDbHost(url) {
  try { return new URL(url).host; } catch { return 'onbekend'; }
}

async function tableExists(client, table) {
  const { rows } = await client.query(
    `SELECT 1 FROM information_schema.tables
      WHERE table_schema = 'public' AND table_name = $1`,
    [table]
  );
  return rows.length > 0;
}

async function tableColumns(client, table) {
  const { rows } = await client.query(
    `SELECT column_name, data_type FROM information_schema.columns
      WHERE table_schema = 'public' AND table_name = $1
      ORDER BY ordinal_position`,
    [table]
  );
  return rows.map((r) => ({ name: r.column_name, type: r.data_type }));
}

async function copyTable(oldClient, newClient, table) {
  if (!(await tableExists(oldClient, table))) {
    console.log(`[migrate] ${table}: bestaat niet in oude DB — overgeslagen.`);
    return 0;
  }
  // Alleen kolommen kopiëren die in beide databases bestaan; zo breekt een
  // oud schema (zonder later toegevoegde kolommen) de migratie niet.
  const oldCols = await tableColumns(oldClient, table);
  const newColNames = (await tableColumns(newClient, table)).map((c) => c.name);
  const cols = oldCols.filter((c) => newColNames.includes(c.name));
  if (cols.length === 0) return 0;

  const { rows } = await oldClient.query(
    `SELECT ${cols.map((c) => `"${c.name}"`).join(', ')} FROM "${table}"`
  );
  if (rows.length === 0) return 0;

  const colList = cols.map((c) => `"${c.name}"`).join(', ');
  // In blokken van 200 rijen invoegen: snel genoeg en ruim onder de
  // parameterlimiet van Postgres (65535).
  const CHUNK = 200;
  for (let i = 0; i < rows.length; i += CHUNK) {
    const chunk = rows.slice(i, i + CHUNK);
    const values = [];
    const params = [];
    chunk.forEach((row, ri) => {
      const ph = cols.map((_, ci) => `$${ri * cols.length + ci + 1}`);
      values.push(`(${ph.join(', ')})`);
      cols.forEach((c) => {
        let v = row[c.name];
        // node-pg parseert json(b)-kolommen naar JS-waarden, maar zou een
        // JS-array bij het invoegen als Postgres-array formatteren — dat is
        // ongeldige JSON. Daarom json(b) expliciet terug naar tekst.
        if ((c.type === 'json' || c.type === 'jsonb') && v !== null) {
          v = JSON.stringify(v);
        }
        params.push(v);
      });
    });
    await newClient.query(
      `INSERT INTO "${table}" (${colList}) VALUES ${values.join(', ')}
       ON CONFLICT DO NOTHING`,
      params
    );
  }

  // SERIAL-sequence gelijkzetten met de gekopieerde id's.
  if (cols.some((c) => c.name === 'id')) {
    await newClient.query(
      `SELECT setval(pg_get_serial_sequence('${table}', 'id'),
                     (SELECT MAX(id) FROM "${table}"))`
    ).catch(() => {}); // tabellen zonder sequence (bv. schema_meta) overslaan
  }
  return rows.length;
}

async function migrateFromOldDb() {
  const oldUrl = process.env.OLD_DATABASE_URL;
  if (!oldUrl) return false;
  if (!process.env.DATABASE_URL) {
    console.warn('[migrate] DATABASE_URL ontbreekt — migratie overgeslagen.');
    return false;
  }

  // Zelfde ssl-aanpak als db/index.js.
  const oldConnStr = oldUrl.replace(/\bsslmode=(prefer|require|verify-ca)\b/, 'sslmode=verify-full');
  const oldPool = new Pool({
    connectionString: oldConnStr,
    ssl: process.env.PGSSL === 'disable' ? false : { rejectUnauthorized: true },
    max: 2,
  });

  const newClient = await db.pool.connect();
  let oldClient;
  try {
    // Schema eerst, zodat alle doeltabellen bestaan. schema_meta zit niet in
    // schema.sql (init.js maakt die aan), dus hier ook expliciet aanmaken.
    await newClient.query(fs.readFileSync(SCHEMA_PATH, 'utf8'));
    await newClient.query(SESSIONS_DDL);
    await newClient.query(`
      CREATE TABLE IF NOT EXISTS schema_meta (
        key   TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      )
    `);

    const { rows: marker } = await newClient.query(
      `SELECT value FROM schema_meta WHERE key = 'migrated_from'`
    );
    if (marker.length > 0) {
      console.log(`[migrate] al gemigreerd vanaf ${marker[0].value} — overgeslagen. OLD_DATABASE_URL kan uit Render worden verwijderd.`);
      return false;
    }

    console.log(`[migrate] start migratie van ${oldDbHost(oldUrl)} naar nieuwe database...`);
    oldClient = await oldPool.connect();

    await newClient.query('BEGIN');
    // Verbatim kloon: doeltabellen eerst leegmaken zodat id's exact
    // overeenkomen met de oude database (nodig voor message_id-verwijzingen).
    await newClient.query(
      `TRUNCATE ${TABLES.map((t) => `"${t}"`).join(', ')} RESTART IDENTITY CASCADE`
    );

    for (const table of TABLES) {
      const n = await copyTable(oldClient, newClient, table);
      console.log(`[migrate] ${table}: ${n} rijen gekopieerd.`);
    }

    // Actieve sessies meenemen (geen onderdeel van TABLES: niet truncaten,
    // eventuele nieuwe sessies op de nieuwe DB blijven staan).
    const nSessions = await copyTable(oldClient, newClient, 'user_sessions');
    console.log(`[migrate] user_sessions: ${nSessions} rijen gekopieerd.`);

    await newClient.query(
      `INSERT INTO schema_meta (key, value, updated_at)
       VALUES ('migrated_from', $1, NOW())
       ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value, updated_at = NOW()`,
      [oldDbHost(oldUrl)]
    );
    await newClient.query('COMMIT');
    console.log('[migrate] klaar. OLD_DATABASE_URL kan nu uit Render worden verwijderd.');
    return true;
  } catch (err) {
    await newClient.query('ROLLBACK').catch(() => {});
    throw err;
  } finally {
    if (oldClient) oldClient.release();
    newClient.release();
    await oldPool.end().catch(() => {});
  }
}

module.exports = { migrateFromOldDb };
