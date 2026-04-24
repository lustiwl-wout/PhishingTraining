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
  // Per sessie gekozen bij elke start van de simulator; niet opgeslagen.
  const SUPPORTED_DEVICES = ['desktop', 'android', 'iphone'];
  let currentDevice = 'desktop';
  function setDevice(d) {
    if (!SUPPORTED_DEVICES.includes(d)) return;
    currentDevice = d;
    // Body-klasse zodat CSS per device kan stijlen.
    document.body.classList.remove('device-desktop', 'device-android', 'device-iphone');
    document.body.classList.add('device-' + d);
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
    // Data-gedreven views opnieuw laden in de nieuwe variant.
    if (document.getElementById('voorbeelden').classList.contains('active')) {
      loadExamples();
    }
    const inboxPhase = document.getElementById('sim-phase-inbox');
    const simActive = document.getElementById('simulator').classList.contains('active');
    if (simActive && inboxPhase && !inboxPhase.hidden) {
      startSimulator();
    }
  }

  function showAudiencePicker() {
    const p = document.getElementById('audience-picker');
    if (p) p.hidden = false;
  }
  function hideAudiencePicker() {
    const p = document.getElementById('audience-picker');
    if (p) p.hidden = true;
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
      s = s.replace(/\{(\w+)\}/g, (m, k) => (vars[k] != null ? vars[k] : m));
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
  }

  function setLanguage(lang) {
    if (!SUPPORTED_LANGS.includes(lang)) return;
    currentLang = lang;
    localStorage.setItem('vo_lang', lang);
    applyI18n();
    hideLangPicker();
    // Na taalkeuze bij eerste bezoek: direct door naar de doelgroep-keuze.
    if (!localStorage.getItem('vo_audience')) {
      showAudiencePicker();
    }
    // Data-gedreven views opnieuw ophalen in de nieuwe taal.
    if (document.getElementById('voorbeelden').classList.contains('active')) {
      loadExamples();
    }
    const simActive = document.getElementById('simulator').classList.contains('active');
    const inboxPhase = document.getElementById('sim-phase-inbox');
    if (simActive && inboxPhase && !inboxPhase.hidden) {
      startSimulator();
    }
  }

  function showLangPicker() {
    const p = document.getElementById('lang-picker');
    if (p) p.hidden = false;
  }
  function hideLangPicker() {
    const p = document.getElementById('lang-picker');
    if (p) p.hidden = true;
  }

  // Bij eerste bezoek: eerst taal kiezen, daarna doelgroep (privé/zakelijk).
  // setLanguage() (hieronder) zorgt dat na het sluiten van de taal-picker
  // de doelgroep-picker automatisch volgt als die nog niet gekozen is.
  document.addEventListener('DOMContentLoaded', () => {
    applyI18n();
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
    if (e.target.closest('#lang-switch')) {
      showLangPicker();
    }
    if (e.target.closest('#audience-switch')) {
      showAudiencePicker();
    }
  });

  // -------- session id (anoniem, alleen om de attempt te koppelen) --------
  function getSessionId() {
    let id = localStorage.getItem('vo_session');
    if (!id) {
      id = 'sess_' + Math.random().toString(36).slice(2, 10) + Date.now().toString(36);
      localStorage.setItem('vo_session', id);
    }
    return id;
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
             + '&audience=' + encodeURIComponent(currentAudience);
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
  const pages = ['welkom', 'leren', 'voorbeelden', 'simulator', 'hulp'];

  function go(step) {
    pages.forEach((p) => {
      const el = document.getElementById(p);
      if (el) el.classList.toggle('active', p === step);
    });
    document.querySelectorAll('#stepbar-list li').forEach((li) => {
      li.classList.toggle('active', li.dataset.step === step);
    });
    // Fullscreen voor de simulator: verberg trainings-chrome, laat Outlook het scherm vullen.
    document.body.classList.toggle('sim-fullscreen', step === 'simulator');

    const main = document.getElementById('hoofd');
    if (main) main.focus();
    window.scrollTo({ top: 0, behavior: 'smooth' });

    if (step === 'voorbeelden') loadExamples();
    if (step === 'simulator') showSimPhase('intro');
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
    const devBtn = e.target.closest('.sim-device-btn[data-device]');
    if (devBtn) {
      e.preventDefault();
      setDevice(devBtn.dataset.device);
      if (currentDevice === 'desktop') {
        showSimPhase('login');
        runMicrosoftLoginAnimation().catch((err) => console.error(err));
      } else {
        // Mobiel: geen MS-login-animatie, de "je bent al ingelogd"-situatie
        // van een telefoon simuleren. Direct naar de inbox.
        showSimPhase('mobile');
        startMobileSimulator().catch((err) => console.error(err));
      }
    }
  });

  document.addEventListener('click', (e) => {
    const t = e.target.closest('[data-go]');
    if (t) { e.preventDefault(); go(t.dataset.go); }
  });


  // -------- voorbeelden --------
  async function loadExamples() {
    const container = document.getElementById('voorbeelden-lijst');
    container.innerHTML = '<p class="muted">' + escapeHtml(t('voorbeelden.loading')) + '</p>';
    try {
      const items = await api('/examples');
      container.innerHTML = '';
      items.forEach((ex) => container.appendChild(renderExample(ex)));
    } catch (err) {
      container.innerHTML = '<p class="error">' + escapeHtml(t('voorbeelden.error')) + '</p>';
    }
  }

  function renderExample(ex) {
    const wrap = document.createElement('article');
    wrap.className = 'example-outlook';

    const parsed = parseSender(ex.sender);
    const addrHtml = parsed.addr ? annotateText(parsed.addr, ex.annotations || []) : '';
    const subjectHtml = ex.subject ? annotateText(ex.subject, ex.annotations || []) : '';
    const bodyHtml = annotateText(ex.body || '', ex.annotations || []);

    wrap.innerHTML =
      '<header class="ol-msg-head">' +
        (subjectHtml ? '<h2 class="ol-msg-subject">' + subjectHtml + '</h2>' : '') +
        '<div class="ol-msg-sender-row">' +
          '<div class="ol-avatar ol-avatar-lg" aria-hidden="true">' + escapeHtml(initials(parsed.name)) + '</div>' +
          '<div class="ol-msg-sender-info">' +
            '<div class="ol-msg-sender-line">' +
              '<strong class="ol-msg-sender-name">' + escapeHtml(parsed.name || parsed.addr) + '</strong>' +
            '</div>' +
            (addrHtml ? '<div class="ol-example-addr">&lt;' + addrHtml + '&gt;</div>' : '') +
            '<div class="ol-msg-time">' + escapeHtml(t('voorbeelden.to')) + '</div>' +
          '</div>' +
        '</div>' +
      '</header>' +
      '<div class="ol-msg-body">' + bodyHtml + '</div>';

    if (ex.annotations && ex.annotations.length) {
      const list = document.createElement('ol');
      list.className = 'annotation-list';
      ex.annotations.forEach((a, i) => {
        const li = document.createElement('li');
        li.innerHTML = '<span class="dot">' + (i + 1) + '</span> ' + escapeHtml(a.note);
        list.appendChild(li);
      });
      wrap.appendChild(list);
    }
    return wrap;
  }

  function parseSender(s) {
    const str = String(s || '').trim();
    const m = /^(.*?)\s*<\s*(.+?)\s*>\s*$/.exec(str);
    if (m) return { name: m[1].trim(), addr: m[2].trim() };
    if (str.includes('@')) return { name: str, addr: str };
    return { name: str, addr: '' };
  }

  function annotateText(text, annotations) {
    let html = escapeHtml(text).replace(/\n/g, '<br>');
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

  async function startSimulator() {
    const list = document.getElementById('ol-list-items');
    const result = document.getElementById('sim-result');
    result.hidden = true;
    currentFolder = 'inbox';
    setActiveFolderLi('inbox');
    list.innerHTML = '<li class="ol-loading">' + escapeHtml(t('sim.ol.loading')) + '</li>';

    try {
      const messages = await api('/inbox');
      simState = { messages, judgments: {}, current: null, interactions: {} };
      renderInboxList();
      updateProgress();
      // Open het eerste bericht automatisch zodat de gebruiker meteen
      // ziet wat er van hem/haar verwacht wordt (lezen + beoordelen).
      if (messages.length > 0) {
        openMessage(messages[0].id);
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

  async function startMobileSimulator() {
    const result = document.getElementById('sim-result');
    result.hidden = true;
    currentFolder = 'inbox';
    buildMobSkin();
    const list = document.getElementById('mob-list-items');
    if (list) list.innerHTML = '<li class="mob-item" style="justify-content:center"><em>' + escapeHtml(t('sim.ol.loading')) + '</em></li>';
    try {
      const messages = await api('/inbox');
      simState = { messages, judgments: {}, current: null, interactions: {} };
      renderMobList();
      if (messages.length > 0) openMobMessage(messages[0].id);
    } catch (err) {
      if (list) list.innerHTML = '<li class="mob-item" style="justify-content:center;color:#b3261e">' + escapeHtml(t('sim.ol.loadError')) + '</li>';
    }
  }

  // Bouwt de DOM voor de juiste skin op basis van audience + device:
  //   zakelijk                → Outlook Mobile (beide platforms)
  //   privé + Android          → Gmail Android
  //   privé + iPhone           → Apple Mail (M5 — nu nog Outlook-fallback)
  function buildMobSkin() {
    const app = document.getElementById('mob-app');
    if (!app) return;
    if (currentAudience === 'business') {
      buildMobOutlook(app);
    } else if (currentDevice === 'android') {
      buildMobGmail(app);
    } else {
      buildMobOutlook(app); // iPhone personal → todo: Apple Mail
    }
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
      '<div class="mob-reader" id="mob-reader" hidden></div>';
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
      '<div class="mob-reader" id="mob-reader" hidden></div>';
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
      const idx = parseInt(a.dataset.linkIdx, 10);
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
    renderMobList();
  }

  async function openMessage(id) {
    simState.current = id;
    if (!simState.interactions[id]) simState.interactions[id] = { clicked_link: false, revealed_sender: false };
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
      const idx = parseInt(a.dataset.linkIdx, 10);
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
    let html = isHtml ? text : escapeHtml(text).replace(/\n/g, '<br>');
    html = html.replace(/\{\{link:(\d+)\}\}/g, (_m, n) => {
      const idx = parseInt(n, 10);
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
    modal.hidden = false;
    const firstBtn = actionsWrap.querySelector('button');
    if (firstBtn) firstBtn.focus();
  }
  function closeModal() {
    const modal = document.getElementById('sim-modal');
    if (modal) modal.hidden = true;
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
      .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;').replace(/'/g, '&#39;');
  }
  function escapeRegExp(s) {
    return String(s).replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  }
})();
