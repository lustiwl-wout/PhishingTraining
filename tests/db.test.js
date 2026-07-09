/**
 * Database/seed sanity-tests. Draaien alleen wanneer TEST_DATABASE_URL is
 * gezet (een wegwerp-Postgres); anders worden ze geskipt zodat `npm test`
 * ook zonder database werkt. De testdatabase wordt door init-db gevuld.
 *
 * Lokaal bijvoorbeeld:
 *   TEST_DATABASE_URL=postgresql://postgres:test@localhost:5432/test_db npm test
 */
const test = require('node:test');
const assert = require('node:assert');

const TEST_URL = process.env.TEST_DATABASE_URL;

test('seed + schema sanity', { skip: !TEST_URL && 'TEST_DATABASE_URL niet gezet' }, async (t) => {
  process.env.DATABASE_URL = TEST_URL;
  process.env.PGSSL = process.env.PGSSL || 'disable';
  const { initDb } = require('../db/init');
  const db = require('../db');
  t.after(() => db.pool.end());

  await initDb();

  await t.test('content-tabellen zijn gevuld', async () => {
    const { rows: [r] } = await db.query(
      `SELECT (SELECT COUNT(*)::int FROM examples) e, (SELECT COUNT(*)::int FROM inbox_messages) m`);
    assert.ok(r.e > 0, 'examples is leeg');
    assert.ok(r.m > 300, `verdacht weinig berichten: ${r.m}`);
  });

  await t.test('elk bericht heeft een unieke slug', async () => {
    const { rows: [r] } = await db.query(
      `SELECT COUNT(*)::int total, COUNT(slug)::int with_slug, COUNT(DISTINCT slug)::int uniq FROM inbox_messages`);
    assert.strictEqual(r.with_slug, r.total, 'berichten zonder slug');
    assert.strictEqual(r.uniq, r.total, 'dubbele slugs');
  });

  await t.test('natuurlijke sleutel is uniek (geen dubbele sort_orders)', async () => {
    const { rows } = await db.query(`
      SELECT locale, channel, audience, difficulty, sort_order, COUNT(*)
        FROM inbox_messages GROUP BY 1,2,3,4,5 HAVING COUNT(*) > 1`);
    assert.deepStrictEqual(rows, [], `dubbele natuurlijke sleutels: ${JSON.stringify(rows)}`);
  });

  await t.test('elke taal heeft berichten voor elk kanaal', async () => {
    const { rows } = await db.query(`
      SELECT locale, channel, COUNT(*)::int n FROM inbox_messages GROUP BY 1,2`);
    const langs = ['nl', 'nl-BE', 'en', 'en-US', 'fr', 'fr-BE', 'de'];
    for (const lang of langs) {
      for (const ch of ['email', 'sms', 'whatsapp']) {
        const hit = rows.find((r) => r.locale === lang && r.channel === ch);
        assert.ok(hit && hit.n > 0, `${lang}/${ch}: geen berichten`);
      }
    }
  });

  await t.test('normaal en geavanceerd zijn per taal/kanaal/doelgroep even groot', async () => {
    // Requirement uit de training: beide niveaus bieden evenveel oefening.
    // Gemeten zoals de gebruiker het ziet: de API filtert op
    // audience IN (eigen, 'both') en difficulty = gekozen niveau.
    const { rows } = await db.query(`
      SELECT m.locale, m.channel, a.aud,
             COUNT(*) FILTER (WHERE m.difficulty = 'normal')::int   AS normal,
             COUNT(*) FILTER (WHERE m.difficulty = 'advanced')::int AS advanced
        FROM inbox_messages m
        JOIN (VALUES ('personal'), ('business')) a(aud)
          ON m.audience IN (a.aud, 'both')
       WHERE m.active = TRUE
       GROUP BY 1,2,3 ORDER BY 1,2,3`);
    const uneven = rows.filter((r) => r.normal !== r.advanced);
    assert.deepStrictEqual(uneven, [],
      'ongelijke aantallen: ' + uneven.map((r) => `${r.locale}/${r.channel}/${r.aud} ${r.normal}≠${r.advanced}`).join(', '));
  });

  await t.test('phishing-berichten hebben red flags, echte berichten green flags', async () => {
    const { rows } = await db.query(`
      SELECT id, slug, is_phishing FROM inbox_messages
       WHERE (is_phishing AND jsonb_array_length(red_flags) = 0)
          OR (NOT is_phishing AND jsonb_array_length(green_flags) = 0)`);
    assert.deepStrictEqual(rows, [],
      'berichten zonder passende flags: ' + rows.map((r) => r.slug).join(', '));
  });

  await t.test('links in de body verwijzen naar bestaande link-indexen', async () => {
    const { rows } = await db.query(`SELECT slug, body, links FROM inbox_messages`);
    const broken = [];
    for (const r of rows) {
      for (const m of r.body.matchAll(/\{\{link:(\d+)\}\}/g)) {
        if (Number(m[1]) >= r.links.length) broken.push(`${r.slug} -> link:${m[1]}`);
      }
    }
    assert.deepStrictEqual(broken, [], `kapotte link-verwijzingen: ${broken.join(', ')}`);
  });
});
