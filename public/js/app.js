/* Veilig Online — frontend logica.
   Bewust simpel gehouden: vanilla JS, duidelijke functienamen, weinig magie. */

(function () {
  'use strict';

  // -------- i18n --------
  const SUPPORTED_LANGS = ['nl', 'nl-BE', 'en', 'fr', 'fr-BE', 'de'];
  const LANG_FLAGS = {
    'nl': '🇳🇱', 'nl-BE': '🇧🇪',
    'en': '🇬🇧',
    'fr': '🇫🇷', 'fr-BE': '🇧🇪',
    'de': '🇩🇪',
  };

  function detectInitialLanguage() {
    // URL-parameter heeft hoogste prioriteit (hreflang-links gebruiken ?lang=)
    const urlLang = new URLSearchParams(location.search).get('lang');
    if (urlLang && SUPPORTED_LANGS.includes(urlLang)) return urlLang;
    const stored = localStorage.getItem('vo_lang');
    if (stored && SUPPORTED_LANGS.includes(stored)) return stored;
    // Match browser preference — e.g. "nl-BE" maps to nl-BE, "fr-CH" falls
    // back to "fr", "nl" stays as "nl". We check the full tag first, then
    // the primary subtag.
    const tag = (navigator.language || 'nl');
    if (SUPPORTED_LANGS.includes(tag)) return tag;
    const primary = tag.slice(0, 2).toLowerCase();
    return SUPPORTED_LANGS.includes(primary) ? primary : null;
  }

  let currentLang = detectInitialLanguage() || 'nl';

  // -------- device (desktop / android / iphone) --------
  // Auto-bepaald bij start van de simulator op basis van het viewport
  // en het besturingssysteem. Onder 600px is het een telefoon-skin;
  // op iOS rendert Apple Mail (privé) of Outlook Mobile (zakelijk),
  // anders Gmail / Outlook Mobile.
  let currentDevice = 'desktop';
  function setDevice(d) {
    currentDevice = d;
    document.body.classList.remove('device-desktop', 'device-android', 'device-iphone');
    document.body.classList.add('device-' + d);
  }
  function detectDevice() {
    const isMobile = window.matchMedia('(max-width: 600px)').matches;
    if (!isMobile) return 'desktop';
    const ua = (navigator.userAgent || '') + ' ' + (navigator.platform || '');
    if (/iPad|iPhone|iPod|Macintosh.*Mobile/i.test(ua)) return 'iphone';
    return 'android';
  }

  // -------- difficulty (normaal vs gevorderd) --------
  const SUPPORTED_DIFFICULTIES = ['normal', 'advanced'];
  let currentDifficulty = 'normal';
  function setDifficulty(d) {
    if (!SUPPORTED_DIFFICULTIES.includes(d)) return;
    currentDifficulty = d;
    document.querySelectorAll('#sim-difficulty-toggle [data-difficulty]').forEach((el) => {
      el.classList.toggle('active', el.dataset.difficulty === d);
    });
  }

  // -------- audience (persoonlijk vs zakelijk) --------
  const SUPPORTED_AUDIENCES = ['personal', 'business'];
  const AUDIENCE_ICONS = { personal: '📥', business: '💼' };
  function detectInitialAudience() {
    const stored = localStorage.getItem('vo_audience');
    return SUPPORTED_AUDIENCES.includes(stored) ? stored : null;
  }
  // Tijdens de eerste bezoek nog geen keuze: tot de picker iets teruggeeft
  // gedragen we ons als 'personal', zodat niets kapot gaat.
  let currentAudience = detectInitialAudience() || 'personal';
  function setAudience(a) {
    if (!SUPPORTED_AUDIENCES.includes(a)) return;
    currentAudience = a;
    localStorage.setItem('vo_audience', a);
    applyI18n();
    refreshActiveData();
  }

  // Centraal: herlaad de actieve data-gedreven view in de huidige taal +
  // doelgroep. Gebruikt door zowel setLanguage als setAudience zodat zowel
  // de desktop-Outlook als de mobiele skin meeschakelen op een wissel.
  function refreshActiveData() {
    const sim = document.getElementById('simulator');
    if (!sim || !sim.classList.contains('active')) return;
    const inboxPhase = document.getElementById('sim-phase-inbox');
    const mobilePhase = document.getElementById('sim-phase-mobile');
    if (inboxPhase && !inboxPhase.hidden) {
      startSimulator();
    } else if (mobilePhase && !mobilePhase.hidden) {
      startMobileSimulator().catch((err) => console.error(err));
    }
  }

  function showAudiencePicker() {
    const p = document.getElementById('audience-picker');
    if (p && !p.open) p.show();
  }
  function hideAudiencePicker() {
    const p = document.getElementById('audience-picker');
    if (p && p.open) p.close();
  }

  function t(key, vars) {
    const loc = (window.VO_LOCALES && window.VO_LOCALES[currentLang]) || {};
    const fallback = (window.VO_LOCALES && window.VO_LOCALES.nl) || {};
    // Doelgroep-specifieke variant (bv. user.email.business) heeft
    // voorrang als de audience 'business' is en de variant bestaat.
    const audienceKey = key + '.' + currentAudience;
    let s;
    if (loc[audienceKey] != null) s = loc[audienceKey];
    else if (loc[key] != null) s = loc[key];
    else if (fallback[audienceKey] != null) s = fallback[audienceKey];
    else if (fallback[key] != null) s = fallback[key];
    else s = key;
    if (vars) {
      s = s.replaceAll(/\{(\w+)\}/g, (m, k) => (vars[k] != null ? vars[k] : m));
    }
    return s;
  }

  function applyI18n(root) {
    const scope = root || document;
    scope.querySelectorAll('[data-i18n]').forEach((el) => {
      el.textContent = t(el.getAttribute('data-i18n'));
    });
    scope.querySelectorAll('[data-i18n-html]').forEach((el) => {
      el.innerHTML = t(el.getAttribute('data-i18n-html'));
    });
    document.documentElement.lang = currentLang;
    const titleEl = document.querySelector('title[data-i18n]');
    if (titleEl) document.title = t(titleEl.getAttribute('data-i18n'));
    const desc = t('meta.description');
    document.querySelector('meta[name="description"]')?.setAttribute('content', desc);
    document.querySelector('meta[property="og:description"]')?.setAttribute('content', desc);
    document.querySelector('meta[property="og:title"]')?.setAttribute('content', document.title);
    const search = document.getElementById('ol-search-input');
    if (search) {
      search.placeholder = t('sim.ol.search');
      search.setAttribute('aria-label', t('sim.ol.search'));
    }
    const nameEl = document.getElementById('lang-switch-name');
    const flagEl = document.getElementById('lang-switch-flag');
    if (nameEl) nameEl.textContent = t('lang.name');
    if (flagEl) flagEl.textContent = LANG_FLAGS[currentLang] || '';
    const audName = document.getElementById('audience-switch-name');
    const audIcon = document.getElementById('audience-switch-icon');
    if (audName) audName.textContent = t('audience.' + currentAudience + '.title');
    if (audIcon) audIcon.textContent = AUDIENCE_ICONS[currentAudience] || '';
    const devName = document.getElementById('device-switch-name');
    const devIcon = document.getElementById('device-switch-icon');
    if (devName) devName.textContent = t('device.' + currentDevice + '.title');
    if (devIcon) devIcon.textContent = DEVICE_ICONS[currentDevice] || '';
  }

  function setLanguage(lang) {
    if (!SUPPORTED_LANGS.includes(lang)) return;
    currentLang = lang;
    localStorage.setItem('vo_lang', lang);
    const url = new URL(location.href);
    url.searchParams.set('lang', lang);
    history.replaceState(null, '', url);
    applyI18n();
    hideLangPicker();
    // Na taalkeuze bij eerste bezoek: direct door naar de doelgroep-keuze.
    if (!localStorage.getItem('vo_audience')) {
      showAudiencePicker();
    }
    refreshActiveData();
  }

  function showLangPicker() {
    const p = document.getElementById('lang-picker');
    if (p && !p.open) p.show();
  }
  function hideLangPicker() {
    const p = document.getElementById('lang-picker');
    if (p && p.open) p.close();
  }

  // Bij eerste bezoek: eerst taal kiezen, daarna doelgroep (privé/zakelijk).
  // setLanguage() (hieronder) zorgt dat na het sluiten van de taal-picker
  // de doelgroep-picker automatisch volgt als die nog niet gekozen is.
  // Herstel ook de laatst-bezochte stap zodat een refresh niet altijd
  // op de welkom-pagina belandt.
  // -------- enterprise config --------
  let enterpriseConfig = null;

  async function loadEnterpriseConfig() {
    try {
      const r = await fetch('/api/enterprise/config');
      if (!r.ok) return;
      const cfg = await r.json();
      if (!cfg.enterprise) return;
      enterpriseConfig = cfg;
      applyEnterpriseConfig(cfg);
    } catch (_) { /* non-enterprise: ignore */ }
  }

  function applyEnterpriseConfig(cfg) {
    // --- talen: verberg kaarten die niet zijn toegestaan ---
    document.querySelectorAll('#lang-picker [data-lang]').forEach(btn => {
      btn.hidden = !cfg.locales.includes(btn.dataset.lang);
    });
    // Als slechts één taal: stel in en verberg picker-knop
    if (cfg.locales.length === 1) {
      setLanguage(cfg.locales[0]);
      const sw = document.getElementById('lang-switch');
      if (sw) sw.hidden = true;
    } else if (!cfg.locales.includes(currentLang)) {
      setLanguage(cfg.locales[0]);
    }

    // --- doelgroep: verberg kaarten die niet zijn toegestaan ---
    document.querySelectorAll('#audience-picker [data-audience]').forEach(btn => {
      btn.hidden = !cfg.audiences.includes(btn.dataset.audience);
    });
    if (cfg.audiences.length === 1) {
      setAudience(cfg.audiences[0]);
      const sw = document.getElementById('audience-switch');
      if (sw) sw.hidden = true;
    } else if (!cfg.audiences.includes(currentAudience)) {
      setAudience(cfg.audiences[0]);
    }

    // --- moeilijkheidsgraad ---
    const toggle = document.getElementById('sim-difficulty-toggle');
    if (cfg.difficulties.length === 1) {
      // Één keuze: toggle helemaal verbergen
      if (toggle) toggle.hidden = true;
      setDifficulty(cfg.difficulties[0]);
    } else {
      // Meerdere: verberg knoppen die niet zijn toegestaan
      if (toggle) {
        toggle.querySelectorAll('[data-difficulty]').forEach(btn => {
          btn.hidden = !cfg.difficulties.includes(btn.dataset.difficulty);
        });
      }
      if (!cfg.difficulties.includes(currentDifficulty)) {
        setDifficulty(cfg.difficulties[0]);
      }
    }

    // Org-naam tonen in header indien aanwezig
    const brandEl = document.querySelector('.nav-brand, #welkom-titel');
    if (brandEl && cfg.orgName) {
      const tag = document.createElement('span');
      tag.style.cssText = 'font-size:.75rem;font-weight:400;color:var(--ink-soft);margin-left:.5rem;vertical-align:middle';
      tag.textContent = '— ' + cfg.orgName;
      brandEl.appendChild(tag);
    }

    // Papieren versie niet beschikbaar voor enterprise-gebruikers
    const printBtn = document.getElementById('sim-print-btn');
    const printOr  = document.querySelector('.sim-print-or');
    if (printBtn) printBtn.hidden = true;
    if (printOr)  printOr.hidden = true;

    // Toon uitlog-knop voor enterprise gebruikers
    const nav = document.querySelector('nav') || document.querySelector('header');
    if (nav) {
      const logoutForm = document.createElement('form');
      logoutForm.method = 'POST';
      logoutForm.action = '/e/logout';
      logoutForm.style.cssText = 'display:inline;margin-left:.5rem';
      logoutForm.innerHTML = '<button type="submit" style="background:none;border:none;cursor:pointer;font-size:.85rem;color:var(--ink-soft)">Uitloggen</button>';
      nav.appendChild(logoutForm);
    }
  }

  document.addEventListener('DOMContentLoaded', () => {
    loadEnterpriseConfig().then(() => {
      applyI18n();
      setDifficulty(currentDifficulty);
    });
    const savedPage = localStorage.getItem('vo_page');
    if (savedPage && pages.includes(savedPage) && savedPage !== 'welkom') {
      go(savedPage);
    }
    // Als de gebruiker midden in de simulator zat, herstellen we apparaat,
    // beoordelingen en het laatst geopende bericht zodat ze niet opnieuw
    // hoeven te beginnen.
    if (savedPage === 'simulator') {
      const saved = loadPersistedSimState();
      if (saved && saved.device) {
        setDevice(saved.device);
        document.body.classList.add('sim-fullscreen');
        if (saved.device === 'desktop') {
          showSimPhase('inbox');
          startSimulator({ restore: true }).catch((err) => console.error(err));
        } else {
          showSimPhase('mobile');
          startMobileSimulator({ restore: true }).catch((err) => console.error(err));
        }
      }
    }
    if (!localStorage.getItem('vo_lang')) {
      showLangPicker();
    } else if (!localStorage.getItem('vo_audience')) {
      showAudiencePicker();
    }
  });

  document.addEventListener('click', (e) => {
    const langCard = e.target.closest('[data-lang]');
    if (langCard) {
      e.preventDefault();
      setLanguage(langCard.dataset.lang);
      return;
    }
    const audCard = e.target.closest('[data-audience]');
    if (audCard) {
      e.preventDefault();
      setAudience(audCard.dataset.audience);
      hideAudiencePicker();
      return;
    }
    const diffBtn = e.target.closest('[data-difficulty]');
    if (diffBtn && diffBtn.closest('#sim-difficulty-toggle')) {
      e.preventDefault();
      setDifficulty(diffBtn.dataset.difficulty);
      return;
    }
    // Apparaat-picker kaart (💻 / 📱 / 🍏) — niet meer in de UI, maar
    // we laten de hook staan voor mogelijke toekomstige debug/preview.
    const devPickCard = e.target.closest('#device-picker [data-device]');
    if (devPickCard) {
      e.preventDefault();
      switchDevice(devPickCard.dataset.device);
      return;
    }
    if (e.target.closest('#lang-switch')) {
      showLangPicker();
    }
    if (e.target.closest('#audience-switch')) {
      showAudiencePicker();
    }
  });

  // Wissel van apparaat midden in de sessie: zet het nieuwe device,
  // herstart de simulator in de juiste skin als we nog in de simulator
  // zitten. Buiten de simulator alleen de voorkeur bijwerken.
  function switchDevice(d) {
    const wasInSim = document.getElementById('simulator').classList.contains('active');
    setDevice(d);
    if (!wasInSim) return;
    // Resultaat-kaart verbergen als die nog open stond
    const result = document.getElementById('sim-result');
    if (result) result.hidden = true;
    document.body.classList.add('sim-fullscreen');
    if (d === 'desktop') {
      showSimPhase('login');
      runMicrosoftLoginAnimation().catch((err) => console.error(err));
    } else {
      showSimPhase('mobile');
      startMobileSimulator().catch((err) => console.error(err));
    }
  }

  // -------- session id (anoniem, alleen om de attempt te koppelen) --------
  function getSessionId() {
    let id = localStorage.getItem('vo_session');
    if (!id) {
      id = 'sess_' + Math.random().toString(36).slice(2, 10) + Date.now().toString(36);
      localStorage.setItem('vo_session', id);
    }
    return id;
  }

  let simulatorStartTracked = false;
  function trackSimulatorStart() {
    if (simulatorStartTracked) return;
    simulatorStartTracked = true;
    fetch('/api/simulator/start', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ session_id: getSessionId() }),
    }).catch(() => {});
  }

  let easterEggTracked = false;
  function trackEasterEgg() {
    if (easterEggTracked) return;
    easterEggTracked = true;
    fetch('/api/easter-egg', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ session_id: getSessionId() }),
    }).catch(() => {});
  }

  // -------- API helpers --------
  // Render Free zet de service na 15 min stil; eerste request kan 30-60s duren.
  // We tonen daarom een vriendelijke "wordt opgestart..." melding na 4s.
  let coldStartTimer = null;
  let coldStartShown = false;

  function showColdStartHint() {
    coldStartShown = true;
    let bar = document.getElementById('coldstart-bar');
    if (!bar) {
      bar = document.createElement('div');
      bar.id = 'coldstart-bar';
      bar.className = 'coldstart-bar';
      bar.setAttribute('role', 'status');
      document.body.appendChild(bar);
    }
    bar.textContent = t('sim.coldstart');
    bar.hidden = false;
  }
  function hideColdStartHint() {
    const bar = document.getElementById('coldstart-bar');
    if (bar) bar.hidden = true;
  }

  async function api(path, opts) {
    if (!coldStartShown) {
      clearTimeout(coldStartTimer);
      coldStartTimer = setTimeout(showColdStartHint, 4000);
    }
    try {
      // Taal en doelgroep meegeven aan GET-requests zodat de database
      // de juiste vertaling en variant teruggeeft. POST-requests
      // blijven ongewijzigd.
      let url = '/api' + path;
      if (!opts || !opts.method || opts.method === 'GET') {
        const sep = path.includes('?') ? '&' : '?';
        url += sep + 'lang=' + encodeURIComponent(currentLang)
             + '&audience=' + encodeURIComponent(currentAudience)
             + '&difficulty=' + encodeURIComponent(currentDifficulty);
      }
      const res = await fetch(url, Object.assign({
        headers: { 'Content-Type': 'application/json' },
      }, opts || {}));
      if (!res.ok) throw new Error('API ' + res.status);
      return await res.json();
    } finally {
      clearTimeout(coldStartTimer);
      hideColdStartHint();
    }
  }

  // -------- navigatie tussen pagina's --------
  const pages = ['welkom', 'leren', 'simulator', 'hulp'];

  function go(step) {
    pages.forEach((p) => {
      const el = document.getElementById(p);
      if (el) el.classList.toggle('active', p === step);
    });
    document.querySelectorAll('#stepbar-list li').forEach((li) => {
      li.classList.toggle('active', li.dataset.step === step);
    });
    // Onthoud welke stap actief is, zodat een refresh op dezelfde pagina belandt.
    try { localStorage.setItem('vo_page', step); } catch (_) {}
    // Fullscreen voor de simulator: verberg trainings-chrome, laat Outlook het scherm vullen.
    document.body.classList.toggle('sim-fullscreen', step === 'simulator');
    // Apparaat-wissel en "Sluit oefening" zijn alleen zinvol in de simulator.
    const inSim = step === 'simulator';
    const exitBtn = document.getElementById('sim-exit-btn');
    const devBtn = document.getElementById('device-switch');
    if (exitBtn) exitBtn.hidden = !inSim;
    if (devBtn) devBtn.hidden = !inSim;

    const main = document.getElementById('hoofd');
    if (main) main.focus();
    window.scrollTo({ top: 0, behavior: 'smooth' });

    if (step === 'simulator') showSimPhase('intro');
  }

  // -------- Print-versie van de training -----------------------
  // Bouwt een statische HTML-versie van alle inbox-scenario's met
  // op iedere bladzijde de e-mail en op de volgende bladzijde het
  // antwoord. Activeert via window.print() het systeem-printvenster.
  async function printTraining() {
    const btn = document.getElementById('sim-print-btn');
    if (btn) btn.disabled = true;
    let messages;
    try {
      messages = await api('/print');
    } catch (err) {
      console.error('print fetch failed', err);
      if (btn) btn.disabled = false;
      return;
    }
    renderPrintView(messages);
    if (btn) btn.disabled = false;
    // Geef de browser een tick om het DOM te updaten voordat we printen.
    setTimeout(() => window.print(), 50);
  }

  function renderPrintView(messages) {
    const view = document.getElementById('print-view');
    if (!view) return;
    const total = messages.length;
    const audienceLabel = t('audience.' + currentAudience + '.title');
    const langLabel = t('lang.name');
    const pages = [];

    // Voorpagina
    pages.push(
      '<section class="print-page print-cover">' +
        '<h1>' + escapeHtml(t('brand.title')) + ' — ' + escapeHtml(t('sim.print.coverTitle')) + '</h1>' +
        '<p class="print-meta">' +
          escapeHtml(audienceLabel) + ' · ' + escapeHtml(langLabel) + ' · ' +
          escapeHtml(t('sim.print.messageCount', { n: total })) +
        '</p>' +
        '<p class="print-instructions">' + t('sim.print.coverInstructions', { n: total }) + '</p>' +
      '</section>'
    );

    messages.forEach((m, idx) => {
      const num = idx + 1;
      // E-mail-pagina
      pages.push(
        '<section class="print-page print-email">' +
          '<p class="print-counter">' + escapeHtml(t('sim.print.messageOf', { n: num, total })) + '</p>' +
          '<div class="print-email-card">' +
            '<div class="print-email-meta">' +
              '<div><strong>' + escapeHtml(t('sim.print.from')) + ':</strong> ' +
                escapeHtml(m.sender_name) + ' &lt;' + escapeHtml(m.sender_address) + '&gt;</div>' +
              '<div><strong>' + escapeHtml(t('sim.print.received')) + ':</strong> ' +
                escapeHtml(m.received_label || '') + '</div>' +
              '<div><strong>' + escapeHtml(t('sim.print.subject')) + ':</strong> ' +
                escapeHtml(m.subject) + '</div>' +
            '</div>' +
            '<div class="print-email-body">' + renderBody(m.body, m.links || []) + '</div>' +
          '</div>' +
          '<p class="print-question">' + escapeHtml(t('sim.print.question')) + '</p>' +
        '</section>'
      );
      // Antwoord-pagina
      const verdictClass = m.is_phishing ? 'phish' : 'real';
      const verdictText = m.is_phishing ? t('sim.print.is.phishing') : t('sim.print.is.real');
      const reds = (m.red_flags || []).map((s) => '<li>' + escapeHtml(s) + '</li>').join('');
      const greens = (m.green_flags || []).map((s) => '<li>' + escapeHtml(s) + '</li>').join('');
      pages.push(
        '<section class="print-page print-answer">' +
          '<p class="print-counter">' + escapeHtml(t('sim.print.answerOf', { n: num, total })) + '</p>' +
          '<h2>' + escapeHtml(m.subject) + '</h2>' +
          '<div class="print-verdict ' + verdictClass + '">' + escapeHtml(verdictText) + '</div>' +
          '<p class="print-explanation">' + escapeHtml(m.explanation || '') + '</p>' +
          (m.sender_note ? '<p class="print-sender-note"><strong>' + escapeHtml(t('sim.verdict.senderNote')) + '</strong> ' + escapeHtml(m.sender_note) + '</p>' : '') +
          (reds   ? '<h3>' + escapeHtml(t('sim.verdict.redFlags'))   + '</h3><ul>' + reds   + '</ul>' : '') +
          (greens ? '<h3>' + escapeHtml(t('sim.verdict.greenFlags')) + '</h3><ul>' + greens + '</ul>' : '') +
        '</section>'
      );
    });

    view.innerHTML = pages.join('');
  }

  // -------- simulator state persistence --------
  // Bewaart tussen refreshes welk apparaat, welke beoordelingen, welk
  // bericht openstond. Wordt geschreven na elke verandering (oordeel,
  // bericht openen) en gewist bij een verse start of als de simulator
  // klaar is.
  const SIM_STATE_KEY = 'vo_sim_state';
  function persistSimState() {
    if (!simState) return;
    try {
      localStorage.setItem(SIM_STATE_KEY, JSON.stringify({
        device: currentDevice,
        audience: currentAudience,
        lang: currentLang,
        judgments: simState.judgments,
        interactions: simState.interactions,
        current: simState.current,
        savedAt: Date.now(),
      }));
    } catch (_) {}
  }
  function loadPersistedSimState() {
    try {
      const raw = localStorage.getItem(SIM_STATE_KEY);
      return raw ? JSON.parse(raw) : null;
    } catch (_) { return null; }
  }
  function clearPersistedSimState() {
    try { localStorage.removeItem(SIM_STATE_KEY); } catch (_) {}
  }

  // -------- Simulator fases (intro -> login -> inbox | mobile) --------
  function showSimPhase(name) {
    ['intro', 'login', 'inbox', 'mobile'].forEach((p) => {
      const el = document.getElementById('sim-phase-' + p);
      if (el) el.hidden = (p !== name);
    });
  }

  async function runMicrosoftLoginAnimation() {
    const emailEl = document.getElementById('ms-email');
    const pwEl = document.getElementById('ms-password');
    const pwRow = document.getElementById('ms-password-row');
    const emailRow = document.getElementById('ms-email-row');
    const title = document.getElementById('ms-title');
    const subtitle = document.getElementById('ms-subtitle');
    const submit = document.getElementById('ms-submit-btn');
    const back = document.getElementById('ms-back-btn');
    const status = document.getElementById('ms-status');
    const mfaRow = document.getElementById('ms-mfa-row');
    const mfaNum = document.getElementById('ms-mfa-num');
    const mfaStatus = document.getElementById('ms-mfa-status');
    const linkRows = document.getElementById('ms-link-rows');
    const actions = submit && submit.parentElement;

    // reset
    emailEl.textContent = '';
    pwEl.textContent = '';
    pwRow.hidden = true;
    emailRow.hidden = false;
    mfaRow.hidden = true;
    if (linkRows) linkRows.hidden = false;
    if (actions) actions.hidden = false;
    title.textContent = t('sim.ms.title');
    subtitle.textContent = t('sim.ms.subtitle');
    submit.textContent = t('sim.ms.next');
    back.hidden = true;
    status.hidden = true;

    const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
    const email = t('user.email');

    await sleep(450);
    for (const ch of email) {
      emailEl.textContent += ch;
      await sleep(55 + Math.random() * 35);
    }
    await sleep(350);
    submit.classList.add('ms-btn-pressed');
    await sleep(180);
    submit.classList.remove('ms-btn-pressed');

    // Stap 2: wachtwoord
    emailRow.hidden = true;
    pwRow.hidden = false;
    title.textContent = t('sim.ms.pwTitle');
    subtitle.innerHTML = t('sim.ms.pwSubtitle', { email });
    submit.textContent = t('sim.ms.submit');
    back.hidden = false;

    await sleep(300);
    for (let i = 0; i < 10; i++) {
      pwEl.textContent += '•';
      await sleep(80 + Math.random() * 60);
    }
    await sleep(350);
    submit.classList.add('ms-btn-pressed');
    await sleep(180);
    submit.classList.remove('ms-btn-pressed');

    // Stap 3 (alleen zakelijk): MFA-goedkeuring via Authenticator.
    if (currentAudience === 'business') {
      pwRow.hidden = true;
      if (linkRows) linkRows.hidden = true;
      if (actions) actions.hidden = true;
      title.textContent = t('sim.ms.mfa.title');
      subtitle.innerHTML = t('sim.ms.pwSubtitle', { email });
      const mfaCode = String(Math.floor(10 + Math.random() * 90)); // tweecijferig
      mfaNum.textContent = mfaCode;
      mfaStatus.innerHTML = '<span class="ms-spinner" aria-hidden="true"></span> ' + escapeHtml(t('sim.ms.mfa.waiting'));
      mfaRow.hidden = false;
      await sleep(2200);
      mfaStatus.innerHTML = '✓ ' + escapeHtml(t('sim.ms.mfa.approved'));
      await sleep(600);
      mfaRow.hidden = true;
    }

    // Bezig met aanmelden
    status.hidden = false;
    status.innerHTML = '<span class="ms-spinner" aria-hidden="true"></span> ' + escapeHtml(t('sim.ms.signingIn'));
    submit.disabled = true;
    back.disabled = true;
    await sleep(900);

    // Door naar de inbox
    showSimPhase('inbox');
    submit.disabled = false;
    back.disabled = false;
    startSimulator();
  }

  document.addEventListener('click', (e) => {
    if (e.target.closest('#sim-start-btn')) {
      e.preventDefault();
      trackSimulatorStart();
      setDevice(detectDevice());
      if (currentDevice === 'desktop') {
        showSimPhase('login');
        runMicrosoftLoginAnimation().catch((err) => console.error(err));
      } else {
        // Op een echte telefoon slaan we de Microsoft-login-animatie over
        // ("je bent al ingelogd"-gevoel). Direct naar de inbox-skin.
        showSimPhase('mobile');
        startMobileSimulator().catch((err) => console.error(err));
      }
      return;
    }
    if (e.target.closest('#sim-print-btn')) {
      e.preventDefault();
      printTraining();
    }
  });

  document.addEventListener('click', (e) => {
    const t = e.target.closest('[data-go]');
    if (t) { e.preventDefault(); go(t.dataset.go); }
  });


  function parseSender(s) {
    const str = String(s || '').trim();
    const m = /^(.*?)\s*<\s*(.+?)\s*>\s*$/.exec(str);
    if (m) return { name: m[1].trim(), addr: m[2].trim() };
    if (str.includes('@')) return { name: str, addr: str };
    return { name: str, addr: '' };
  }

  function annotateText(text, annotations) {
    let html = escapeHtml(text).replaceAll('\n', '<br>');
    annotations.forEach((a, i) => {
      const q = escapeHtml(a.quote);
      const re = new RegExp(escapeRegExp(q), 'i');
      if (re.test(html)) {
        html = html.replace(re, '<mark class="phish-mark">' + q + '<sup class="dot">' + (i + 1) + '</sup></mark>');
      }
    });
    return html;
  }

  // -------- Outlook-simulator --------
  let simState = null;

  async function startSimulator(opts) {
    opts = opts || {};
    const list = document.getElementById('ol-list-items');
    const result = document.getElementById('sim-result');
    result.hidden = true;
    currentFolder = 'inbox';
    setActiveFolderLi('inbox');
    if (!opts.restore) clearPersistedSimState();
    list.innerHTML = '<li class="ol-loading">' + escapeHtml(t('sim.ol.loading')) + '</li>';

    try {
      const messages = await api('/inbox');
      const saved = opts.restore ? loadPersistedSimState() : null;
      simState = {
        messages,
        judgments: (saved && saved.judgments) || {},
        interactions: (saved && saved.interactions) || {},
        current: (saved && saved.current) || null,
      };
      renderInboxList();
      updateProgress();
      // Open het bericht waar de gebruiker gebleven was, anders het
      // eerste nog niet beoordeelde, anders het allereerste.
      if (messages.length > 0) {
        let openId = simState.current;
        if (!openId || !messages.find((m) => m.id === openId)) {
          const next = messages.find((m) => !simState.judgments[m.id]) || messages[0];
          openId = next.id;
        }
        openMessage(openId);
      } else {
        resetReader();
      }
    } catch (err) {
      list.innerHTML = '<li class="ol-loading error">' + escapeHtml(t('sim.ol.loadError')) + '</li>';
    }
  }

  function renderInboxList() {
    const list = document.getElementById('ol-list-items');
    list.innerHTML = '';
    simState.messages.forEach((m) => {
      const judged = simState.judgments[m.id];
      const li = document.createElement('li');
      li.className = 'ol-item' + (judged ? ' judged' : '') + (simState.current === m.id ? ' active' : '');
      li.dataset.id = m.id;
      li.setAttribute('role', 'button');
      li.tabIndex = 0;
      const mark = judged
        ? (judged.correct ? '<span class="ol-status good" title="Goed beoordeeld">✓</span>'
                          : '<span class="ol-status bad"  title="Fout beoordeeld">✗</span>')
        : '<span class="ol-unread" aria-label="Ongelezen"></span>';
      li.innerHTML =
        mark +
        '<div class="ol-item-main">' +
          '<div class="ol-item-top">' +
            '<span class="ol-item-sender">' + escapeHtml(m.sender_name) + '</span>' +
            '<span class="ol-item-time">' + escapeHtml(m.received_label) + '</span>' +
          '</div>' +
          '<div class="ol-item-subject">' + escapeHtml(m.subject) + '</div>' +
          '<div class="ol-item-preview">' + escapeHtml(m.preview || '') + '</div>' +
        '</div>';
      li.addEventListener('click', () => openMessage(m.id));
      li.addEventListener('keydown', (e) => {
        if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); openMessage(m.id); }
      });
      list.appendChild(li);
    });

    const unread = simState.messages.filter((m) => !simState.judgments[m.id]).length;
    const c1 = document.getElementById('ol-unread-count');
    const c2 = document.getElementById('ol-unread-count-2');
    if (c1) c1.textContent = unread;
    if (c2) c2.textContent = unread;
  }

  function updateProgress() {
    const prog = document.getElementById('sim-progress');
    if (!prog) return;
    const total = simState.messages.length;
    const done = Object.keys(simState.judgments).length;
    prog.textContent = done + ' / ' + total;
  }

  function resetReader() {
    document.getElementById('ol-reader').innerHTML =
      '<div class="ol-reader-empty"><div class="ol-reader-empty-art">📬</div>' +
      '<p>' + escapeHtml(t('sim.ol.empty')) + '</p></div>';
  }

  // -------- Folder-switching (easter egg: Ongewenste e-mail) --------
  // De meeste mappen in de zijbalk zijn decoratief. Alleen "Postvak IN"
  // en "Ongewenste e-mail" reageren: de junk-folder toont één vaste mail
  // (de klassieke Nigeriaanse-prins-oplichting) als knipoog naar wat een
  // spamfilter normaal vangt.
  let currentFolder = 'inbox';

  function setActiveFolderLi(folderName) {
    document.querySelectorAll('.ol-folders li').forEach((li) => {
      li.classList.toggle('active', li.dataset && li.dataset.folder === folderName);
    });
  }

  function showFolder(folderName) {
    if (folderName !== 'inbox' && folderName !== 'junk') return;
    currentFolder = folderName;
    setActiveFolderLi(folderName);
    const headerEl = document.querySelector('.ol-list-header h3');
    const hintEl = document.querySelector('.ol-list-header .ol-hint');
    if (folderName === 'junk') {
      if (headerEl) headerEl.textContent = t('sim.ol.junk').replace(/^[^\w]+\s*/, '');
      if (hintEl)   hintEl.textContent = t('sim.ol.inbox.hint');
      trackEasterEgg();
      renderJunkList();
      resetReader();
    } else {
      if (headerEl) headerEl.textContent = t('sim.ol.inbox.title');
      if (hintEl)   hintEl.textContent = t('sim.ol.inbox.hint');
      if (simState) renderInboxList();
      resetReader();
    }
  }

  function renderJunkList() {
    const list = document.getElementById('ol-list-items');
    list.innerHTML = '';
    const li = document.createElement('li');
    li.className = 'ol-item';
    li.setAttribute('role', 'button');
    li.tabIndex = 0;
    li.innerHTML =
      '<span class="ol-unread" aria-label="Ongelezen"></span>' +
      '<div class="ol-item-main">' +
        '<div class="ol-item-top">' +
          '<span class="ol-item-sender">' + escapeHtml(t('sim.junk.sender')) + '</span>' +
          '<span class="ol-item-time">' + escapeHtml(t('sim.junk.received')) + '</span>' +
        '</div>' +
        '<div class="ol-item-subject">' + escapeHtml(t('sim.junk.subject')) + '</div>' +
        '<div class="ol-item-preview">' + escapeHtml(t('sim.junk.preview')) + '</div>' +
      '</div>';
    li.addEventListener('click', () => { renderJunkReader(); li.classList.add('judged'); });
    li.addEventListener('keydown', (e) => {
      if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); renderJunkReader(); }
    });
    list.appendChild(li);
  }

  function renderJunkReader() {
    const reader = document.getElementById('ol-reader');
    reader.innerHTML =
      '<header class="ol-msg-head">' +
        '<h2 class="ol-msg-subject">' + escapeHtml(t('sim.junk.subject')) + '</h2>' +
        '<div class="ol-msg-sender-row">' +
          '<div class="ol-avatar ol-avatar-lg" aria-hidden="true">👑</div>' +
          '<div class="ol-msg-sender-info">' +
            '<div class="ol-msg-sender-line">' +
              '<strong class="ol-msg-sender-name">' + escapeHtml(t('sim.junk.sender')) + '</strong>' +
              ' <span class="ol-sender-addr-inline">&lt;' + escapeHtml(t('sim.junk.senderEmail')) + '&gt;</span>' +
            '</div>' +
            '<div class="ol-msg-time">' + escapeHtml(t('sim.ol.to')) + ' · ' + escapeHtml(t('sim.junk.received')) + '</div>' +
          '</div>' +
        '</div>' +
      '</header>' +
      '<div class="ol-msg-body ol-junk-body">' + t('sim.junk.body') + '</div>' +
      '<div class="ol-msg-actions judged">' +
        '<p class="muted">' + t('sim.junk.note') + '</p>' +
      '</div>';
    reader.scrollTop = 0;
  }

  document.addEventListener('click', (e) => {
    const folderLi = e.target.closest('.ol-folders li[data-folder]');
    if (folderLi) {
      e.preventDefault();
      e.stopPropagation();
      showFolder(folderLi.dataset.folder);
    }
  });

  // Extra directe listeners per folder-li zodat klikken altijd reageert,
  // ook als event-delegatie door een overlay of stoppedPropagation elders
  // wordt gebroken. Loopt bij DOMContentLoaded zodat de DOM bestaat.
  document.addEventListener('DOMContentLoaded', () => {
    document.querySelectorAll('.ol-folders li[data-folder]').forEach((li) => {
      li.addEventListener('click', (e) => {
        e.preventDefault();
        e.stopPropagation();
        showFolder(li.dataset.folder);
      });
    });
  });

  // ================================================================
  // Mobiele simulator (Android / iPhone).
  // Hergebruikt simState, de /api/inbox endpoint en alle modal-logica.
  // Alleen de rendering in #mob-app verschilt per apparaat-skin.
  // ================================================================

  // Mobiele folder-state: 'inbox' is normaal, 'junk' toont de easter egg.
  let currentMobFolder = 'inbox';

  async function startMobileSimulator(opts) {
    opts = opts || {};
    const result = document.getElementById('sim-result');
    result.hidden = true;
    currentFolder = 'inbox';
    currentMobFolder = 'inbox';
    if (!opts.restore) clearPersistedSimState();
    buildMobSkin();
    const list = document.getElementById('mob-list-items');
    if (list) list.innerHTML = '<li class="mob-item" style="justify-content:center"><em>' + escapeHtml(t('sim.ol.loading')) + '</em></li>';
    try {
      const messages = await api('/inbox');
      const saved = opts.restore ? loadPersistedSimState() : null;
      simState = {
        messages,
        judgments: (saved && saved.judgments) || {},
        interactions: (saved && saved.interactions) || {},
        current: (saved && saved.current) || null,
      };
      renderMobList();
      if (messages.length > 0) {
        let openId = simState.current;
        if (!openId || !messages.find((m) => m.id === openId)) {
          const next = messages.find((m) => !simState.judgments[m.id]) || messages[0];
          openId = next.id;
        }
        openMobMessage(openId);
      }
    } catch (err) {
      if (list) list.innerHTML = '<li class="mob-item" style="justify-content:center;color:#b3261e">' + escapeHtml(t('sim.ol.loadError')) + '</li>';
    }
  }

  // Bouwt de DOM voor de juiste skin op basis van audience + device:
  //   zakelijk                → Outlook Mobile (beide platforms)
  //   privé + Android          → Gmail Android
  //   privé + iPhone           → Apple Mail
  function buildMobSkin() {
    const app = document.getElementById('mob-app');
    if (!app) return;
    if (currentAudience === 'business') {
      buildMobOutlook(app);
    } else if (currentDevice === 'android') {
      buildMobGmail(app);
    } else {
      buildMobAppleMail(app);
    }
  }

  function mobDrawerHtml() {
    // Wordt in elk van de skins achteraan toegevoegd. Één gedeelde
    // drawer met twee mappen: Postvak IN (zet je terug op de oefening)
    // en Ongewenste e-mail (de easter egg).
    return (
      '<div class="mob-drawer" id="mob-drawer" hidden>' +
        '<header class="mob-drawer-head">' +
          '<button class="mob-btn mob-btn-drawer-back" aria-label="Sluiten">←</button>' +
          '<h2 class="mob-drawer-title">' + escapeHtml(t('sim.ol.favorites')) + '</h2>' +
        '</header>' +
        '<ol class="mob-drawer-list">' +
          '<li data-mob-folder="inbox">' +
            '<span class="mob-drawer-ico">📥</span>' +
            '<span class="mob-drawer-label">' + escapeHtml(t('sim.ol.inbox.title')) + '</span>' +
          '</li>' +
          '<li data-mob-folder="junk">' +
            '<span class="mob-drawer-ico">⚠️</span>' +
            '<span class="mob-drawer-label">' + escapeHtml(t('sim.ol.junk').replace(/^[^\w]+\s*/, '')) + '</span>' +
          '</li>' +
        '</ol>' +
      '</div>'
    );
  }

  function buildMobOutlook(app) {
    app.className = 'mob-app mob-outlook';
    app.innerHTML =
      '<header class="mob-topbar">' +
        '<button class="mob-btn mob-btn-menu" aria-label="Menu">☰</button>' +
        '<h1 class="mob-title">' + escapeHtml(t('sim.ol.inbox.title')) + '</h1>' +
        '<button class="mob-btn mob-btn-search" aria-label="' + escapeHtml(t('sim.ol.search')) + '">🔍</button>' +
        '<div class="mob-avatar">' + escapeHtml(t('user.avatar')) + '</div>' +
      '</header>' +
      '<ol class="mob-list" id="mob-list-items"></ol>' +
      '<div class="mob-reader" id="mob-reader" hidden></div>' +
      mobDrawerHtml();
  }

  function buildMobGmail(app) {
    app.className = 'mob-app mob-gmail';
    app.innerHTML =
      '<header class="mob-topbar">' +
        '<button class="mob-btn mob-btn-menu" aria-label="Menu">☰</button>' +
        '<div class="mob-search">🔍 ' + escapeHtml(t('sim.ol.search')) + '</div>' +
        '<div class="mob-avatar">' + escapeHtml(t('user.avatar')) + '</div>' +
      '</header>' +
      '<ol class="mob-list" id="mob-list-items"></ol>' +
      '<button class="mob-fab" aria-hidden="true" tabindex="-1">✏️</button>' +
      '<div class="mob-reader" id="mob-reader" hidden></div>' +
      mobDrawerHtml();
  }

  function buildMobAppleMail(app) {
    app.className = 'mob-app mob-applemail';
    app.innerHTML =
      '<header class="mob-topbar">' +
        '<div class="mob-topbar-row">' +
          '<button class="mob-btn mob-btn-menu">‹ Mailboxes</button>' +
          '<button class="mob-btn" aria-hidden="true" tabindex="-1">Edit</button>' +
        '</div>' +
        '<h1 class="mob-title">' + escapeHtml(t('sim.ol.inbox.title')) + '</h1>' +
        '<div class="mob-search">🔍 ' + escapeHtml(t('sim.ol.search')) + '</div>' +
      '</header>' +
      '<ol class="mob-list" id="mob-list-items"></ol>' +
      '<div class="mob-reader" id="mob-reader" hidden></div>' +
      mobDrawerHtml();
  }

  function openMobDrawer() {
    const d = document.getElementById('mob-drawer');
    if (d) d.hidden = false;
  }
  function closeMobDrawer() {
    const d = document.getElementById('mob-drawer');
    if (d) d.hidden = true;
  }

  function switchMobFolder(folder) {
    closeMobDrawer();
    if (folder === currentMobFolder) return;
    currentMobFolder = folder;
    // Reader dichtklappen als die nog open stond
    const reader = document.getElementById('mob-reader');
    if (reader) reader.hidden = true;
    if (folder === 'junk') {
      trackEasterEgg();
      renderMobJunkList();
    } else {
      renderMobList();
    }
  }

  function renderMobJunkList() {
    const list = document.getElementById('mob-list-items');
    if (!list) return;
    list.innerHTML = '';
    const li = document.createElement('li');
    li.className = 'mob-item';
    li.innerHTML =
      '<div class="mob-item-avatar">👑</div>' +
      '<div class="mob-item-body">' +
        '<div class="mob-item-top">' +
          '<span class="mob-item-sender">' + escapeHtml(t('sim.junk.sender')) + '</span>' +
          '<span class="mob-item-time">' + escapeHtml(t('sim.junk.received')) + '</span>' +
        '</div>' +
        '<div class="mob-item-subject">' + escapeHtml(t('sim.junk.subject')) + '</div>' +
        '<div class="mob-item-preview">' + escapeHtml(t('sim.junk.preview')) + '</div>' +
      '</div>';
    li.addEventListener('click', () => renderMobJunkReader());
    list.appendChild(li);
  }

  function renderMobJunkReader() {
    const reader = document.getElementById('mob-reader');
    if (!reader) return;
    reader.hidden = false;
    reader.innerHTML =
      '<header class="mob-reader-head">' +
        '<button class="mob-btn mob-btn-back" aria-label="Terug">←</button>' +
      '</header>' +
      '<div class="mob-reader-content">' +
        '<h2 class="mob-reader-subject">' + escapeHtml(t('sim.junk.subject')) + '</h2>' +
        '<div class="mob-reader-sender">' +
          '<div class="mob-avatar">👑</div>' +
          '<div style="min-width:0">' +
            '<div class="mob-reader-name">' + escapeHtml(t('sim.junk.sender')) + '</div>' +
            '<div class="mob-reader-addr">&lt;' + escapeHtml(t('sim.junk.senderEmail')) + '&gt;</div>' +
            '<div class="mob-reader-to">' + escapeHtml(t('sim.ol.to')) + ' · ' + escapeHtml(t('sim.junk.received')) + '</div>' +
          '</div>' +
        '</div>' +
        '<div class="mob-reader-body mob-junk-body">' + t('sim.junk.body') + '</div>' +
      '</div>' +
      '<div class="mob-junk-note">' + t('sim.junk.note') + '</div>';
    reader.querySelector('.mob-btn-back').addEventListener('click', () => {
      reader.hidden = true;
    });
  }

  function renderMobList() {
    const list = document.getElementById('mob-list-items');
    if (!list || !simState) return;
    list.innerHTML = '';
    simState.messages.forEach((m) => {
      const judged = simState.judgments[m.id];
      const li = document.createElement('li');
      li.className = 'mob-item' + (judged ? ' judged' : '');
      const statusIco = judged
        ? (judged.correct ? ' <span class="mob-item-status good">✓</span>' : ' <span class="mob-item-status bad">✗</span>')
        : '';
      li.innerHTML =
        '<div class="mob-item-avatar">' + escapeHtml(initials(m.sender_name)) + '</div>' +
        '<div class="mob-item-body">' +
          '<div class="mob-item-top">' +
            '<span class="mob-item-sender">' + escapeHtml(m.sender_name) + statusIco + '</span>' +
            '<span class="mob-item-time">' + escapeHtml(m.received_label || '') + '</span>' +
          '</div>' +
          '<div class="mob-item-subject">' + escapeHtml(m.subject) + '</div>' +
          '<div class="mob-item-preview">' + escapeHtml(m.preview || '') + '</div>' +
        '</div>';
      li.addEventListener('click', () => openMobMessage(m.id));
      list.appendChild(li);
    });
  }

  async function openMobMessage(id) {
    simState.current = id;
    if (!simState.interactions[id]) simState.interactions[id] = { clicked_link: false, revealed_sender: false };
    persistSimState();
    const reader = document.getElementById('mob-reader');
    if (!reader) return;
    reader.hidden = false;
    reader.innerHTML =
      '<header class="mob-reader-head">' +
        '<button class="mob-btn mob-btn-back" aria-label="Terug">←</button>' +
      '</header>' +
      '<div class="mob-reader-content"><p class="muted" style="padding:14px">' + escapeHtml(t('sim.ol.loading')) + '</p></div>';
    reader.querySelector('.mob-btn-back').addEventListener('click', closeMobReader);
    let m;
    try { m = await api('/inbox/' + id); }
    catch (_) {
      reader.querySelector('.mob-reader-content').innerHTML =
        '<p class="error" style="padding:14px">' + escapeHtml(t('sim.ol.msgLoadError')) + '</p>';
      return;
    }
    renderMobReader(m);
  }

  function renderMobReader(m) {
    const reader = document.getElementById('mob-reader');
    if (!reader) return;
    const judged = simState.judgments[m.id];
    const verdictBlock = judged
      ? '<div class="mob-verdict judged"><p class="muted">' + escapeHtml(t('sim.reader.alreadyJudged')) + '</p></div>'
      : '<div class="mob-verdict">' +
          '<p class="mob-verdict-q">' + escapeHtml(t('sim.reader.verdictQ')) + '</p>' +
          '<button class="btn-good" data-verdict="trust">' + escapeHtml(t('sim.reader.verdict.trust')) + '</button>' +
          '<button class="btn-bad" data-verdict="phish">' + escapeHtml(t('sim.reader.verdict.phish')) + '</button>' +
        '</div>';
    reader.innerHTML =
      '<header class="mob-reader-head">' +
        '<button class="mob-btn mob-btn-back" aria-label="Terug">←</button>' +
      '</header>' +
      '<div class="mob-reader-content">' +
        '<h2 class="mob-reader-subject">' + escapeHtml(m.subject) + '</h2>' +
        '<div class="mob-reader-sender">' +
          '<div class="mob-avatar">' + escapeHtml(initials(m.sender_name)) + '</div>' +
          '<div style="min-width:0">' +
            '<div class="mob-reader-name">' + escapeHtml(m.sender_name) + '</div>' +
            '<div class="mob-reader-addr">&lt;' + escapeHtml(m.sender_address) + '&gt;</div>' +
            '<div class="mob-reader-to">' + escapeHtml(t('sim.ol.to')) + ' · ' + escapeHtml(m.received_label) + '</div>' +
          '</div>' +
        '</div>' +
        '<div class="mob-reader-body">' + renderBody(m.body, m.links || []) + '</div>' +
      '</div>' +
      verdictBlock;
    reader.querySelector('.mob-btn-back').addEventListener('click', closeMobReader);
    reader.querySelectorAll('[data-link-idx]').forEach((a) => {
      const idx = Number.parseInt(a.dataset.linkIdx, 10);
      const link = (m.links || [])[idx];
      a.addEventListener('click', (e) => {
        e.preventDefault();
        simState.interactions[m.id].clicked_link = true;
        openLinkModal(link);
      });
    });
    reader.querySelectorAll('[data-verdict]').forEach((b) => {
      b.addEventListener('click', () => submitVerdict(m, b.dataset.verdict));
    });
  }

  function closeMobReader() {
    const reader = document.getElementById('mob-reader');
    if (reader) reader.hidden = true;
    if (currentMobFolder === 'junk') renderMobJunkList();
    else renderMobList();
  }

  // Hamburger / "< Mailboxes" / drawer-interacties. Eén enkele delegated
  // click-handler op document om te voorkomen dat we bij elke re-render
  // alles opnieuw moeten binden.
  document.addEventListener('click', (e) => {
    if (e.target.closest('.mob-btn-menu')) {
      e.preventDefault();
      openMobDrawer();
      return;
    }
    if (e.target.closest('.mob-btn-drawer-back')) {
      e.preventDefault();
      closeMobDrawer();
      return;
    }
    const folderLi = e.target.closest('.mob-drawer-list li[data-mob-folder]');
    if (folderLi) {
      e.preventDefault();
      switchMobFolder(folderLi.dataset.mobFolder);
    }
  });

  async function openMessage(id) {
    simState.current = id;
    if (!simState.interactions[id]) simState.interactions[id] = { clicked_link: false, revealed_sender: false };
    persistSimState();
    renderInboxList();
    const reader = document.getElementById('ol-reader');
    reader.innerHTML = '<p class="muted">' + escapeHtml(t('sim.ol.loading')) + '</p>';
    let m;
    try { m = await api('/inbox/' + id); }
    catch (_) { reader.innerHTML = '<p class="error">' + escapeHtml(t('sim.ol.msgLoadError')) + '</p>'; return; }
    renderReader(m);
    reader.scrollTop = 0;
  }

  function renderReader(m) {
    const judged = simState.judgments[m.id];
    const reader = document.getElementById('ol-reader');
    reader.innerHTML =
      '<header class="ol-msg-head">' +
        '<h2 class="ol-msg-subject">' + escapeHtml(m.subject) + '</h2>' +
        '<div class="ol-msg-sender-row">' +
          '<div class="ol-avatar ol-avatar-lg" aria-hidden="true">' + escapeHtml(initials(m.sender_name)) + '</div>' +
          '<div class="ol-msg-sender-info">' +
            '<div class="ol-msg-sender-line">' +
              '<strong class="ol-msg-sender-name">' + escapeHtml(m.sender_name) + '</strong>' +
              ' <span class="ol-sender-addr-inline">&lt;' + escapeHtml(m.sender_address) + '&gt;</span>' +
            '</div>' +
            '<div class="ol-msg-time">' + escapeHtml(t('sim.ol.to')) + ' · ' + escapeHtml(m.received_label) + '</div>' +
          '</div>' +
        '</div>' +
      '</header>' +
      '<div class="ol-msg-body">' + renderBody(m.body, m.links || []) + '</div>' +
      (judged ? '<div class="ol-msg-actions judged"><p class="muted">' + escapeHtml(t('sim.reader.alreadyJudged')) + '</p></div>'
              : '<div class="ol-msg-actions">' +
                  '<p class="ol-verdict-q">' + escapeHtml(t('sim.reader.verdictQ')) + '</p>' +
                  '<button class="btn btn-good big-btn" data-verdict="trust">' + escapeHtml(t('sim.reader.verdict.trust')) + '</button>' +
                  '<button class="btn btn-bad  big-btn" data-verdict="phish">' + escapeHtml(t('sim.reader.verdict.phish')) + '</button>' +
                '</div>');

    reader.querySelectorAll('[data-link-idx]').forEach((a) => {
      const idx = Number.parseInt(a.dataset.linkIdx, 10);
      const link = (m.links || [])[idx];
      a.addEventListener('click', (e) => {
        e.preventDefault();
        simState.interactions[m.id].clicked_link = true;
        openLinkModal(link);
      });
    });

    reader.querySelectorAll('[data-verdict]').forEach((b) => {
      b.addEventListener('click', () => submitVerdict(m, b.dataset.verdict));
    });
  }

  function renderBody(text, links) {
    // Als de body met HTML begint (bv. een SharePoint/OneDrive share-kaart
    // uit de seed) dan trust'en we de markup — de seed is onder onze
    // controle, dus geen XSS-risico. Anders: platte-tekst rendering met
    // HTML-escaping en \n -> <br>.
    const isHtml = /^\s*<[a-z][\s\S]*>/i.test(text);
    let html = isHtml ? text : escapeHtml(text).replaceAll('\n', '<br>');
    html = html.replaceAll(/\{\{link:(\d+)\}\}/g, (_m, n) => {
      const idx = Number.parseInt(n, 10);
      const link = links[idx];
      if (!link) return '';
      const label = escapeHtml(link.label || 'link');
      const url = escapeHtml(link.real_url || '');
      return '<a href="#" class="ol-link" data-link-idx="' + idx + '" ' +
             'title="' + escapeHtml(t('sim.reader.linkTo', { url: link.real_url || '' })) + '">' +
             '<span class="ol-link-label">' + label + '</span>' +
             ' <span class="ol-link-url" aria-hidden="true">' + url + '</span></a>';
    });
    return html;
  }

  function openLinkModal(link) {
    const bad = !!(link && link.suspicious);
    const url = link ? link.real_url : '';
    const warning = link ? (link.warning || '') : '';
    showModal({
      title: bad ? t('sim.link.titleBad') : t('sim.link.titleSafe'),
      variant: bad ? 'bad' : '',
      bodyHtml:
        '<p class="big-text">' + escapeHtml(t('sim.link.goes')) + '</p>' +
        '<p class="mono url-preview ' + (bad ? 'bad' : '') + '">' + escapeHtml(url) + '</p>' +
        (warning ? '<p class="tip-line">' + escapeHtml(warning) + '</p>' : '') +
        '<p>' + (bad ? t('sim.link.dontClick') : escapeHtml(t('sim.link.tip'))) + '</p>',
      actions: [{ label: t('common.close'), primary: true, close: true }],
    });
  }

  async function submitVerdict(m, verdict) {
    // Verdict-knoppen disablen — werkt in beide skins omdat iedere
    // verdict-knop het data-verdict attribuut draagt.
    const activeButtons = document.querySelectorAll((currentDevice === 'desktop' ? '#ol-reader ' : '#mob-reader ') + '[data-verdict]');
    activeButtons.forEach((b) => b.disabled = true);

    const interactions = simState.interactions[m.id] || {};
    let res;
    try {
      res = await api('/inbox/' + m.id + '/judge', {
        method: 'POST',
        body: JSON.stringify({
          session_id: getSessionId(),
          verdict,
          difficulty: currentDifficulty,
          clicked_link: interactions.clicked_link,
          revealed_sender: interactions.revealed_sender,
        }),
      });
    } catch (_) {
      activeButtons.forEach((b) => b.disabled = false);
      showModal({
        title: t('sim.error.title'),
        bodyHtml: '<p>' + escapeHtml(t('sim.error.save')) + '</p>',
        actions: [{ label: t('common.close'), primary: true, close: true }],
      });
      return;
    }

    simState.judgments[m.id] = { verdict, correct: res.correct };
    if (currentDevice === 'desktop') renderInboxList();
    else renderMobList();
    updateProgress();
    persistSimState();
    showVerdictFeedback(m, res);
  }

  function showVerdictFeedback(m, res) {
    const redFlags = (res.red_flags || []).map((s) => '<li>' + escapeHtml(s) + '</li>').join('');
    const greenFlags = (res.green_flags || []).map((s) => '<li>' + escapeHtml(s) + '</li>').join('');
    const senderNote = res.sender_note
      ? '<p><strong>' + escapeHtml(t('sim.verdict.senderNote')) + '</strong> ' + escapeHtml(res.sender_note) + '</p>'
      : '';

    showModal({
      title: res.correct ? t('sim.verdict.correct') : t('sim.verdict.wrong'),
      variant: res.correct ? 'good' : 'bad',
      bodyHtml:
        '<p><strong>' + escapeHtml(t('sim.verdict.answer')) + '</strong> ' +
          escapeHtml(res.is_phishing ? t('sim.verdict.isPhishing') : t('sim.verdict.isReal')) + '</p>' +
        '<p>' + escapeHtml(res.explanation) + '</p>' +
        senderNote +
        (redFlags ? '<p><strong>' + escapeHtml(t('sim.verdict.redFlags')) + '</strong></p><ul class="check-list">' + redFlags + '</ul>' : '') +
        (greenFlags ? '<p><strong>' + escapeHtml(t('sim.verdict.greenFlags')) + '</strong></p><ul class="check-list">' + greenFlags + '</ul>' : ''),
      actions: [
        { label: allJudged() ? t('sim.verdict.seeResult') : t('sim.verdict.next'),
          primary: true, close: true, onClick: nextOrFinish },
      ],
    });
  }

  function allJudged() {
    return simState && Object.keys(simState.judgments).length >= simState.messages.length;
  }

  function nextOrFinish() {
    if (allJudged()) { finishSimulator(); return; }
    const next = simState.messages.find((m) => !simState.judgments[m.id]);
    if (!next) return;
    if (currentDevice === 'desktop') openMessage(next.id);
    else openMobMessage(next.id);
  }

  function finishSimulator() {
    if (currentDevice === 'desktop') {
      resetReader();
    } else {
      const reader = document.getElementById('mob-reader');
      if (reader) reader.hidden = true;
    }
    // Persisted state hoeft niet meer — sessie is afgerond. Refresh
    // op de result-pagina laat de gebruiker dan weer fris beginnen.
    clearPersistedSimState();
    // Verberg alle simulator-fases en verlaat fullscreen zodat
    // het resultaat en de stap-navigatie weer zichtbaar zijn.
    showSimPhase(null);
    document.body.classList.remove('sim-fullscreen');
    const result = document.getElementById('sim-result');
    const total = simState.messages.length;
    const correct = Object.values(simState.judgments).filter((j) => j.correct).length;
    const pct = Math.round((correct / total) * 100);
    let bucket;
    if (pct === 100)    bucket = 'perfect';
    else if (pct >= 80) bucket = 'good';
    else if (pct >= 60) bucket = 'okay';
    else                bucket = 'weak';
    const titel = t('sim.final.' + bucket + '.h');
    const advies = t('sim.final.' + bucket + '.p');

    result.innerHTML =
      '<h2>' + escapeHtml(titel) + '</h2>' +
      '<p class="big-text">' + t('sim.final.score', { correct, total, pct }) + '</p>' +
      '<p>' + escapeHtml(advies) + '</p>' +
      '<div class="actions">' +
        '<button class="btn btn-primary" id="sim-again">' + escapeHtml(t('sim.final.again')) + '</button>' +
        '<button class="btn btn-secondary" data-go="hulp">' + escapeHtml(t('sim.final.help')) + '</button>' +
      '</div>';
    result.hidden = false;
    document.getElementById('sim-again').addEventListener('click', () => {
      // Herstart: sla intro/login over, ga direct terug naar de inbox
      // van hetzelfde apparaat als daarnet.
      document.body.classList.add('sim-fullscreen');
      result.hidden = true;
      if (currentDevice === 'desktop') {
        showSimPhase('inbox');
        startSimulator();
      } else {
        showSimPhase('mobile');
        startMobileSimulator();
      }
    });
    result.scrollIntoView({ behavior: 'smooth', block: 'start' });
  }

  function initials(name) {
    return (name || '').split(/\s+/).filter(Boolean).slice(0, 2).map((w) => w[0].toUpperCase()).join('') || '?';
  }

  // -------- Modal --------
  function showModal({ title, bodyHtml, actions, variant }) {
    const modal = document.getElementById('sim-modal');
    if (!modal) return;
    const card = modal.querySelector('.modal-card');
    card.className = 'modal-card' + (variant ? ' ' + variant : '');
    document.getElementById('sim-modal-title').textContent = title;
    document.getElementById('sim-modal-body').innerHTML = bodyHtml;
    const actionsWrap = document.getElementById('sim-modal-actions');
    actionsWrap.innerHTML = '';
    (actions || []).forEach((a) => {
      const b = document.createElement('button');
      b.className = 'btn ' + (a.primary ? 'btn-primary' : 'btn-secondary');
      b.textContent = a.label;
      b.addEventListener('click', () => {
        if (a.close) closeModal();
        if (typeof a.onClick === 'function') a.onClick();
      });
      actionsWrap.appendChild(b);
    });
    if (!modal.open) modal.show();
    const firstBtn = actionsWrap.querySelector('button');
    if (firstBtn) firstBtn.focus();
  }
  function closeModal() {
    const modal = document.getElementById('sim-modal');
    if (modal && modal.open) modal.close();
  }
  document.addEventListener('click', (e) => {
    if (e.target.closest && e.target.closest('[data-close-modal]')) closeModal();
  });
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') closeModal();
  });

  // -------- utils --------
  function channelLabel(c) {
    return c === 'email' ? 'E‑mail' : c === 'sms' ? 'Sms' : 'WhatsApp';
  }
  function escapeHtml(s) {
    return String(s)
      .replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;').replaceAll("'", '&#39;');
  }
  function escapeRegExp(s) {
    return String(s).replaceAll(/[.*+?^${}()|[\]\\]/g, '\\$&');
  }
})();
