/**
 * Locales-drift tests: alle 7 talen moeten exact dezelfde sleutel-set hebben,
 * en elke sleutel die de UI gebruikt moet bestaan. Vangt het soort drift dat
 * eerder voorkwam (en-US met een hernoemde sleutel die stilletjes op de
 * Nederlandse fallback terugviel).
 */
const test = require('node:test');
const assert = require('node:assert');
const fs = require('node:fs');
const path = require('node:path');

const ROOT = path.join(__dirname, '..');

// locales.js verwacht een browser-window; een leeg object volstaat.
global.window = {};
require(path.join(ROOT, 'public/js/locales.js'));
const LOCALES = global.window.VO_LOCALES;
const LANGS = Object.keys(LOCALES);

test('alle 7 verwachte talen zijn aanwezig', () => {
  assert.deepStrictEqual(
    LANGS.sort(),
    ['de', 'en', 'en-US', 'fr', 'fr-BE', 'nl', 'nl-BE'].sort()
  );
});

test('elke taal heeft exact dezelfde sleutel-set als nl', () => {
  const base = new Set(Object.keys(LOCALES.nl));
  for (const lang of LANGS) {
    const keys = new Set(Object.keys(LOCALES[lang]));
    const missing = [...base].filter((k) => !keys.has(k));
    const extra = [...keys].filter((k) => !base.has(k));
    assert.deepStrictEqual(missing, [], `${lang} mist sleutels: ${missing.join(', ')}`);
    assert.deepStrictEqual(extra, [], `${lang} heeft onbekende sleutels: ${extra.join(', ')}`);
  }
});

test('elke data-i18n sleutel in index.html bestaat in elke taal', () => {
  const html = fs.readFileSync(path.join(ROOT, 'public/index.html'), 'utf8');
  const used = new Set();
  for (const m of html.matchAll(/data-i18n(?:-html)?="([^"]+)"/g)) used.add(m[1]);
  assert.ok(used.size > 100, `verdacht weinig sleutels gevonden in index.html: ${used.size}`);
  for (const lang of LANGS) {
    const missing = [...used].filter((k) => LOCALES[lang][k] == null);
    assert.deepStrictEqual(missing, [], `${lang} mist UI-sleutels: ${missing.join(', ')}`);
  }
});

test('audience-varianten (.business) hebben altijd een basissleutel', () => {
  // t() valt terug op de basissleutel voor 'personal'; een .business-variant
  // zonder basis betekent dat privé-gebruikers de sleutelnaam zelf zien.
  for (const lang of LANGS) {
    const keys = Object.keys(LOCALES[lang]);
    const orphans = keys.filter(
      (k) => k.endsWith('.business') && !keys.includes(k.slice(0, -'.business'.length))
    );
    assert.deepStrictEqual(orphans, [], `${lang}: .business zonder basis: ${orphans.join(', ')}`);
  }
});

test('vertalingen bevatten geen kapotte placeholders of dubbele accolades', () => {
  for (const lang of LANGS) {
    for (const [key, val] of Object.entries(LOCALES[lang])) {
      if (typeof val !== 'string') continue;
      // {naam}-placeholders moeten in elke taal dezelfde set zijn als in nl.
      const basePh = [...String(LOCALES.nl[key] ?? '').matchAll(/\{(\w+)\}/g)].map((m) => m[1]).sort();
      const ph = [...val.matchAll(/\{(\w+)\}/g)].map((m) => m[1]).sort();
      assert.deepStrictEqual(ph, basePh, `${lang}/${key}: placeholders wijken af van nl`);
    }
  }
});
