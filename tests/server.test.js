/**
 * Server smoke-test: boot zonder database (MemoryStore + SKIP_DB_INIT) en
 * controleer dat de SPA en de statische assets serveren. Vangt kapotte
 * requires, syntaxfouten en route-regressies vóór de deploy.
 */
const test = require('node:test');
const assert = require('node:assert');
const { spawn } = require('node:child_process');
const path = require('node:path');

const ROOT = path.join(__dirname, '..');
const PORT = 3199;

function get(pathname) {
  return fetch(`http://127.0.0.1:${PORT}${pathname}`).then(async (res) => ({
    status: res.status,
    body: await res.text(),
    type: res.headers.get('content-type') || '',
  }));
}

test('server boot + statische routes', async (t) => {
  const child = spawn(process.execPath, ['server.js'], {
    cwd: ROOT,
    env: {
      ...process.env,
      PORT: String(PORT),
      SKIP_DB_INIT: '1',
      DATABASE_URL: '',
      OLD_DATABASE_URL: '',
      CANONICAL_URL: 'https://test.example', // nodig voor sitemap.xml
    },
    stdio: ['ignore', 'pipe', 'pipe'],
  });
  t.after(() => child.kill());

  // Wachten tot de server luistert (max ~5s).
  let up = false;
  for (let i = 0; i < 50 && !up; i++) {
    up = await get('/').then(() => true).catch(() => false);
    if (!up) await new Promise((r) => setTimeout(r, 100));
  }
  assert.ok(up, 'server kwam niet op binnen 5 seconden');

  await t.test('SPA serveert en bevat de app-titel', async () => {
    const res = await get('/');
    assert.strictEqual(res.status, 200);
    assert.match(res.body, /Veilig Online/);
    assert.match(res.body, /sim-persona/, 'persona-kaart ontbreekt in de SPA');
  });

  await t.test('JS/CSS-assets serveren', async () => {
    for (const p of ['/js/app.js', '/js/locales.js', '/css/style.css']) {
      const res = await get(p);
      assert.strictEqual(res.status, 200, `${p} gaf ${res.status}`);
    }
  });

  await t.test('sitemap.xml bevat alle 7 talen', async () => {
    const res = await get('/sitemap.xml');
    assert.strictEqual(res.status, 200);
    for (const lang of ['nl', 'nl-BE', 'en', 'en-US', 'fr', 'fr-BE', 'de']) {
      assert.match(res.body, new RegExp(`lang=${lang}[<&"]`), `sitemap mist lang=${lang}`);
    }
  });

  await t.test('health endpoint antwoordt (503 zonder DB is ok)', async () => {
    const res = await get('/api/health');
    assert.ok([200, 503].includes(res.status), `onverwachte status ${res.status}`);
  });
});
