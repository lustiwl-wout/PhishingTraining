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

  // -------- eenvoudige modus (toegankelijkheid / grote letters) --------
  // Een site-brede schakelaar die de hele app groter en rustiger maakt voor
  // minder-digitale en oudere gebruikers. Puur cosmetisch via één body-klasse;
  // geen persoonsgegevens, alleen een voorkeur in localStorage (vo_simple).
  // We lezen en passen de voorkeur meteen toe — nog vóór DOMContentLoaded —
  // zodat de pagina niet eerst klein verschijnt en dan opspringt.
  function loadSimpleMode() {
    try { return localStorage.getItem('vo_simple') === '1'; } catch (_) { return false; }
  }
  let simpleMode = loadSimpleMode();
  function applySimpleMode() {
    document.body.classList.toggle('simple-mode', simpleMode);
    const sw = document.getElementById('simple-switch');
    if (sw) {
      sw.setAttribute('aria-pressed', simpleMode ? 'true' : 'false');
      sw.setAttribute('aria-label', t(simpleMode ? 'simple.off' : 'simple.on'));
    }
    const nameEl = document.getElementById('simple-switch-name');
    if (nameEl) nameEl.textContent = t(simpleMode ? 'simple.off' : 'simple.on');
  }
  function setSimpleMode(on) {
    simpleMode = !!on;
    try { localStorage.setItem('vo_simple', simpleMode ? '1' : '0'); } catch (_) {}
    applySimpleMode();
  }
  // Body-klasse direct zetten (de tekstlabels volgen zodra i18n draait).
  if (simpleMode && document.body) document.body.classList.add('simple-mode');
  else if (simpleMode) document.addEventListener('DOMContentLoaded', () => document.body.classList.add('simple-mode'), { once: true });

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

  // -------- channel (email / sms / whatsapp / phone) --------
  // E-mail is de klassieke simulator. sms/whatsapp = smishing, phone = vishing.
  // De engine (lijst, lezen, oordelen) is kanaal-agnostisch; alleen de skin
  // en de fetch-filter verschillen. Default 'email' houdt bestaand gedrag.
  const SUPPORTED_CHANNELS = ['email', 'sms', 'whatsapp', 'phone'];
  let currentChannel = 'email';
  // 'email' = stap 3 e-mail simulator; 'extra' = stap 4 sms/whatsapp/telefoon.
  let simMode = 'email';
  function setChannel(c) {
    if (!SUPPORTED_CHANNELS.includes(c)) return;
    currentChannel = c;
    document.body.classList.remove(
      'channel-email', 'channel-sms', 'channel-whatsapp', 'channel-phone');
    document.body.classList.add('channel-' + c);
    document.querySelectorAll('#sim-channel-toggle [data-channel]').forEach((el) => {
      el.classList.toggle('active', el.dataset.channel === c);
    });
  }
  // sms/whatsapp delen de chat-skin in een telefoon-frame; e-mail gebruikt
  // de bestaande desktop/mobiele mail-skins.
  function isChatChannel() {
    return currentChannel === 'sms' || currentChannel === 'whatsapp';
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
    const chatPhase = document.getElementById('sim-phase-chat');
    const callPhase = document.getElementById('sim-phase-call');
    // restore: true — taal/doelgroep/niveau/kanaal wisselen mag de voortgang
    // niet wissen. Berichten van een andere taal/kanaal hebben andere id's,
    // dus oordelen blijven netjes per combinatie bewaard.
    if (callPhase && !callPhase.hidden) {
      // Bel-simulator: teken de huidige stap opnieuw in de nieuwe taal,
      // zonder het gesprek opnieuw te beginnen.
      renderCallStep();
    } else if (chatPhase && !chatPhase.hidden) {
      startChatSimulator({ restore: true }).catch((err) => console.error(err));
    } else if (inboxPhase && !inboxPhase.hidden) {
      startSimulator({ restore: true });
    } else if (mobilePhase && !mobilePhase.hidden) {
      startMobileSimulator({ restore: true }).catch((err) => console.error(err));
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
      el.textContent = replaceDomain(t(el.getAttribute('data-i18n')));
    });
    scope.querySelectorAll('[data-i18n-html]').forEach((el) => {
      el.innerHTML = replaceDomain(t(el.getAttribute('data-i18n-html')));
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
    // Eenvoudige modus: knoplabel + aria-label meevertalen.
    if (typeof applySimpleMode === 'function') applySimpleMode();
    // Retentie: de "Tip van de week" hangt af van de taal — bij elke
    // (her)toepassing van i18n opnieuw zetten met de juiste vertaling.
    if (typeof renderWeeklyTip === 'function') renderWeeklyTip();
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
  // Server-side retentiehistorie voor enterprise-gebruikers (null = niet geladen).
  let serverHistory = null;

  async function loadEnterpriseConfig() {
    try {
      const r = await fetch('/api/enterprise/config');
      if (!r.ok) return;
      const cfg = await r.json();
      if (!cfg.enterprise) return;
      enterpriseConfig = cfg;
      applyEnterpriseConfig(cfg);
      // Laad meteen de retentiehistorie zodat de terugkeer-nudge en de
      // opfrisoefening direct na init de juiste gegevens hebben.
      try {
        const hr = await fetch('/api/enterprise/history');
        if (hr.ok) serverHistory = await hr.json();
      } catch (_) {}
    } catch (_) { /* non-enterprise: ignore */ }
  }

  function applyEnterpriseConfig(cfg) {
    // Footer: "gratis training" klopt niet voor medewerkers van een
    // betalende organisatie — toon daar de organisatienaam.
    document.querySelectorAll('[data-i18n="footer.tagline"]').forEach((el) => {
      el.setAttribute('data-i18n', 'footer.tagline.enterprise');
    });
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
      logoutForm.action = '/logout';
      logoutForm.style.cssText = 'display:inline;margin-left:.5rem';
      logoutForm.innerHTML = '<button type="submit" style="background:none;border:none;cursor:pointer;font-size:.85rem;color:var(--ink-soft)">Uitloggen</button>';
      nav.appendChild(logoutForm);
    }

    // Modules: verberg uitgeschakelde stappen in de stepbar en navigatieknoppen.
    if (cfg.modules) {
      document.querySelectorAll('#stepbar-list [data-step]').forEach(li => {
        if (!cfg.modules.includes(li.dataset.step)) li.hidden = true;
      });
      // Verberg data-go knoppen die verwijzen naar uitgeschakelde modules.
      const moduleSet = new Set(cfg.modules);
      document.querySelectorAll('[data-go]').forEach(btn => {
        if (ALL_MODULES.includes(btn.dataset.go) && !moduleSet.has(btn.dataset.go)) {
          btn.hidden = true;
        }
      });
    }
  }

  const ALL_MODULES = ['leren', 'simulator', 'kanalen', 'hulp', 'wachtwoord'];

  // Vervang het fictieve interne domein "kestrel.nl/be/de" door het domein
  // van de organisatie zodat de training realistisch aanvoelt voor medewerkers.
  function replaceDomain(s) {
    if (!s || !enterpriseConfig) return s;
    const domain  = enterpriseConfig.emailDomain;
    const orgName = enterpriseConfig.orgName;
    const orgSlug = enterpriseConfig.orgSlug;
    let r = s;
    if (domain) {
      r = r.replace(/\bkestrel\.(nl|be|de|com|fr|co\.uk)\b/g, domain)
           .replace(/\bkestrel\.sharepoint\.com\b/g, domain.split('.')[0] + '.sharepoint.com');
    }
    if (orgSlug) {
      // Replace kestrel-lookalike domains (e.g. kestrel-access.nl → test-access.nl)
      // so phishing lessons stay relevant: "test-access.nl is not test.nl"
      r = r.replace(/\bkestrel-(\w+)\.(nl|be|de|com|net|fr|co\.uk)\b/g, orgSlug + '-$1.$2');
    }
    if (orgName) {
      r = r.replace(/\bKestrel\b/g, orgName);
    }
    return r;
  }

  function applyOrgDomain(messages) {
    if (!enterpriseConfig?.emailDomain) return messages;
    return messages.map(m => Object.assign({}, m, {
      sender_address: replaceDomain(m.sender_address),
      sender_name:    replaceDomain(m.sender_name),
      preview:        replaceDomain(m.preview),
      body:           replaceDomain(m.body),
      subject:        replaceDomain(m.subject),
    }));
  }

  document.addEventListener('DOMContentLoaded', () => {
    const savedPage = localStorage.getItem('vo_page');
    if (savedPage && pages.includes(savedPage) && savedPage !== 'welkom') {
      go(savedPage);
    }

    loadEnterpriseConfig().then(() => {
      applyI18n();
      // Retentie: terugkeer-nudge bij het laden van de welkom-pagina. go()
      // doet dit ook, maar bij het direct openen van welkom draait go() niet.
      renderReturnNudge();
      setDifficulty(currentDifficulty);
      // Pickers tonen als er een keuze te maken valt.
      // Bij enterprise zijn de opties al gefilterd door applyEnterpriseConfig();
      // toon de picker alleen als er meerdere toegestane opties zijn.
      const allowedLangs     = enterpriseConfig ? enterpriseConfig.locales    : null;
      const allowedAudiences = enterpriseConfig ? enterpriseConfig.audiences  : null;
      const needLang     = !localStorage.getItem('vo_lang')     || (allowedLangs     && !allowedLangs.includes(localStorage.getItem('vo_lang')));
      const needAudience = !localStorage.getItem('vo_audience') || (allowedAudiences && !allowedAudiences.includes(localStorage.getItem('vo_audience')));
      if (needLang && (!allowedLangs || allowedLangs.length > 1)) {
        showLangPicker();
      } else if (needAudience) {
        // Audience nog niet gekozen: stel de eerste toegestane in (geen picker).
        const firstAllowed = allowedAudiences ? allowedAudiences[0] : 'personal';
        setAudience(firstAllowed);
      }

      // Simulator herstellen NA enterprise config zodat audience/difficulty
      // al correct zijn ingesteld voordat de eerste fetch plaatsvindt.
      // Het apparaat bepalen we opnieuw: wie op desktop oefende en op een
      // telefoon terugkomt, krijgt gewoon de mobiele weergave.
      if (savedPage === 'simulator' || savedPage === 'kanalen') {
        const saved = loadPersistedSimState();
        if (saved) {
          // Kanaal herstellen zodat een reload de juiste skin (mail of chat)
          // teruggeeft. setChannel() zet ook de body-klasse die de CSS stuurt.
          if (saved.channel && SUPPORTED_CHANNELS.includes(saved.channel)) {
            setChannel(saved.channel);
          }
          simMode = savedPage === 'kanalen' ? 'extra' : 'email';
          setDevice(detectDevice());
          document.body.classList.add('sim-fullscreen');
          if (currentChannel === 'phone') {
            // De bel-simulator bewaart geen voortgang (efemeer, geen
            // persoonsgegevens): begin het gesprek opnieuw.
            showSimPhase('call');
            startCallSimulator();
          } else if (isChatChannel()) {
            showSimPhase('chat');
            startChatSimulator({ restore: true }).catch((err) => console.error(err));
          } else if (currentDevice === 'desktop') {
            showSimPhase('inbox');
            startSimulator({ restore: true }).catch((err) => console.error(err));
          } else {
            showSimPhase('mobile');
            startMobileSimulator({ restore: true }).catch((err) => console.error(err));
          }
        }
      }
    });
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
    const chBtn = e.target.closest('[data-channel]');
    if (chBtn && chBtn.closest('#sim-channel-toggle')) {
      e.preventDefault();
      const wasChat = isChatChannel();
      setChannel(chBtn.dataset.channel);
      // Midden in een sessie van kanaal wisselen: herstart de simulator in
      // de juiste skin. restore:true zodat reeds-beoordeelde berichten van
      // dit kanaal bewaard blijven (oordelen zijn per bericht-id gescheiden).
      const sim = document.getElementById('simulator');
      if (sim && sim.classList.contains('active') && !document.body.classList.contains('sim-fullscreen') === false) {
        const inExercise = ['inbox', 'mobile', 'chat', 'call'].some((p) => {
          const el = document.getElementById('sim-phase-' + p);
          return el && !el.hidden;
        });
        if (inExercise) {
          if (currentChannel === 'phone') {
            showSimPhase('call');
            startCallSimulator();
          } else if (isChatChannel()) {
            showSimPhase('chat');
            startChatSimulator({ restore: true }).catch((err) => console.error(err));
          } else {
            setDevice(detectDevice());
            if (currentDevice === 'desktop') {
              showSimPhase('inbox');
              startSimulator({ restore: true });
            } else {
              showSimPhase('mobile');
              startMobileSimulator({ restore: true }).catch((err) => console.error(err));
            }
          }
        }
      }
      void wasChat;
      return;
    }
    if (e.target.closest('#lang-switch')) {
      showLangPicker();
    }
    if (e.target.closest('#audience-switch')) {
      // Direct switchen tussen privé en zakelijk — geen tussenmenu.
      const allowed = enterpriseConfig?.audiences || SUPPORTED_AUDIENCES;
      if (allowed.length > 1) {
        const next = SUPPORTED_AUDIENCES.find((a) => a !== currentAudience && allowed.includes(a))
          || allowed[0];
        setAudience(next);
        hideAudiencePicker();
      }
    }
    if (e.target.closest('#simple-switch')) {
      setSimpleMode(!simpleMode);
    }
  });

  // Wissel van apparaat midden in de sessie: zet het nieuwe device,
  // herstart de simulator in de juiste skin als we nog in de simulator
  // zitten. Buiten de simulator alleen de voorkeur bijwerken.

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
             + '&difficulty=' + encodeURIComponent(currentDifficulty)
             + '&channel=' + encodeURIComponent(currentChannel);
      }
      const res = await fetch(url, Object.assign({
        headers: { 'Content-Type': 'application/json' },
      }, opts || {}));
      if (!res.ok) {
        const err = new Error('API ' + res.status);
        err.status = res.status;
        throw err;
      }
      return await res.json();
    } finally {
      clearTimeout(coldStartTimer);
      hideColdStartHint();
    }
  }

  // -------- navigatie tussen pagina's --------
  const pages = ['welkom', 'leren', 'simulator', 'kanalen', 'hulp', 'wachtwoord'];

  function go(step) {
    pages.forEach((p) => {
      // 'kanalen' heeft geen eigen DOM-sectie; sla het over.
      // De #simulator sectie wordt hieronder via p='simulator' afgehandeld.
      if (p === 'kanalen') return;
      const el = document.getElementById(p);
      // #simulator is actief voor zowel 'simulator' als 'kanalen'.
      const isActive = p === step || (p === 'simulator' && step === 'kanalen');
      if (el) el.classList.toggle('active', isActive);
    });
    document.querySelectorAll('#stepbar-list li').forEach((li) => {
      li.classList.toggle('active', li.dataset.step === step);
    });
    // Onthoud welke stap actief is, zodat een refresh op dezelfde pagina belandt.
    try { localStorage.setItem('vo_page', step); } catch (_) {}
    // Fullscreen voor de simulator: verberg trainings-chrome, laat Outlook het scherm vullen.
    const isSimPage = step === 'simulator' || step === 'kanalen';
    document.body.classList.toggle('sim-fullscreen', isSimPage);
    // "Sluit oefening" is alleen zinvol in de simulator.
    const exitBtn = document.getElementById('sim-exit-btn');
    if (exitBtn) {
      exitBtn.hidden = !isSimPage;
      // E-mail sim → terug naar welkom; extra sim → terug naar kanalen intro.
      exitBtn.dataset.go = step === 'kanalen' ? 'kanalen' : 'welkom';
    }

    const main = document.getElementById('hoofd');
    if (main) main.focus();
    window.scrollTo({ top: 0, behavior: 'smooth' });

    if (step === 'simulator') {
      simMode = 'email';
      setChannel('email');
      showSimPhase('intro');
    }
    if (step === 'kanalen') {
      simMode = 'extra';
      if (currentChannel === 'email') setChannel('sms');
      showSimPhase('intro');
    }
    // Retentie: terugkeer-nudge en weektip verversen wanneer we de
    // welkom-pagina tonen (historie kan ondertussen veranderd zijn).
    if (step === 'welkom') { renderReturnNudge(); renderWeeklyTip(); }
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
            // Op papier kun je niet hoveren of klikken — daarom hier wél de
            // doel-URL's, als voetnoten onder het bericht.
            ((m.links || []).length ? '<div class="print-links"><strong>' +
              escapeHtml(t('sim.print.links')) + '</strong><ul>' +
              (m.links || []).map((l) => '<li>' + escapeHtml(l.label || 'link') +
                ' → <span class="mono">' + escapeHtml(l.real_url || '') + '</span></li>').join('') +
              '</ul></div>' : '') +
            ((m.attachments && m.attachments.length)
              ? '<div class="print-attach">📎 ' + escapeHtml(t('sim.attach.label', { count: m.attachments.length })) + ' ' +
                  m.attachments.map((a) => escapeHtml(a.filename)).join(', ') + '</div>'
              : '') +
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
        channel: currentChannel,
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

  // -------- Retentie: voortgangsgeheugen --------
  // Enterprise-gebruikers: server-side opslag via /api/enterprise/history +
  // /api/enterprise/complete (anoniem, gekoppeld aan org_user_id, geen PII).
  // Publieke gebruikers: localStorage (vo_progress) — geen account, geen server.
  const PROGRESS_KEY = 'vo_progress';

  function loadProgress() {
    try {
      const raw = localStorage.getItem(PROGRESS_KEY);
      const p = raw ? JSON.parse(raw) : null;
      if (p && typeof p === 'object') return p;
    } catch (_) {}
    return { lastCompletion: 0, messages: {} };
  }
  function saveProgress(p) {
    try { localStorage.setItem(PROGRESS_KEY, JSON.stringify(p)); } catch (_) {}
  }

  // Bericht-id's die de gebruiker eerder FOUT beoordeelde (om te resurfacen).
  // Enterprise: uit serverHistory (alle ronden); publiek: uit localStorage.
  function getMissedMessageIds() {
    if (enterpriseConfig && serverHistory) {
      return Array.isArray(serverHistory.missedIds) ? serverHistory.missedIds : [];
    }
    const p = loadProgress();
    const ids = [];
    Object.keys(p.messages || {}).forEach((id) => {
      if (p.messages[id] && p.messages[id].correct === false) ids.push(id);
    });
    return ids;
  }

  // Tijdstip (ms) van de laatste afronding, of 0 als er nog geen historie is.
  // Enterprise: uit serverHistory; publiek: uit localStorage.
  function getLastCompletion() {
    if (enterpriseConfig && serverHistory) return serverHistory.lastCompletion || 0;
    return loadProgress().lastCompletion || 0;
  }

  // -------- Lichte gamification: badges --------
  // Per-run prestaties uit simState berekend.
  // facts = { total, correct, pct, phishTotal, phishCorrect, clicked, opened, wasRefresher }.
  const BADGE_DEFS = [
    { id: 'sharp',     icon: '🎯', earn: (f) => f.total > 0 && f.correct === f.total },
    { id: 'spotter',   icon: '🕵️', earn: (f) => f.phishTotal > 0 && f.phishCorrect === f.phishTotal },
    { id: 'cool',      icon: '🧊', earn: (f) => f.clicked === 0 && f.opened === 0 },
    { id: 'finisher',  icon: '🏁', earn: (f) => f.total >= 5 },
    { id: 'comeback',  icon: '🔁', earn: (f) => f.wasRefresher },
    { id: 'flawless',  icon: '🛡️', earn: (f) => f.total >= 5 && f.correct === f.total && f.clicked === 0 && f.opened === 0 },
  ];
  function earnedBadges(facts) {
    return BADGE_DEFS.filter((b) => {
      try { return b.earn(facts); } catch (_) { return false; }
    });
  }

  // Server-side opslaan voor enterprise; localStorage voor publiek.
  async function recordCompletionAndBadges(total, correct, wasRefresher, badges) {
    if (enterpriseConfig) {
      try {
        await fetch('/api/enterprise/complete', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ total, correct, wasRefresher, badges: badges.map((b) => b.id) }),
        });
        // Cache bijwerken zodat de nudge en opfris-oefening direct kloppen
        if (!serverHistory) serverHistory = { lastCompletion: 0, badges: [], missedIds: [] };
        serverHistory.lastCompletion = Date.now();
        if (!Array.isArray(serverHistory.badges)) serverHistory.badges = [];
        badges.forEach((b) => {
          if (!serverHistory.badges.includes(b.id)) serverHistory.badges.push(b.id);
        });
        // Gemiste berichten: berichten waarvoor is_correct=false in deze ronde
        if (!Array.isArray(serverHistory.missedIds)) serverHistory.missedIds = [];
        if (simState) {
          simState.messages.forEach((m) => {
            const j = simState.judgments[m.id];
            if (!j) return;
            const sid = String(m.id);
            if (!j.correct && !serverHistory.missedIds.includes(sid)) {
              serverHistory.missedIds.push(sid);
            } else if (j.correct) {
              serverHistory.missedIds = serverHistory.missedIds.filter((id) => id !== sid);
            }
          });
        }
      } catch (_) {}
      return;
    }
    // Publiek: localStorage
    const p = loadProgress();
    p.lastCompletion = Date.now();
    if (!p.messages || typeof p.messages !== 'object') p.messages = {};
    const now = Date.now();
    if (simState) {
      simState.messages.forEach((m) => {
        const j = simState.judgments[m.id];
        if (!j) return;
        p.messages[m.id] = { correct: !!j.correct, seenAt: now };
      });
    }
    if (!Array.isArray(p.badges)) p.badges = [];
    badges.forEach((b) => { if (!p.badges.includes(b.id)) p.badges.push(b.id); });
    saveProgress(p);
  }

  // -------- Retentie: ISO-weeknummer voor de "Tip van de week" --------
  // Deterministisch per ISO-week zodat de tip wekelijks verandert en voor
  // iedereen dezelfde is in die week.
  function isoWeekNumber(d) {
    const date = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()));
    // Donderdag in deze week bepaalt het jaar (ISO-8601).
    const day = date.getUTCDay() || 7;
    date.setUTCDate(date.getUTCDate() + 4 - day);
    const yearStart = new Date(Date.UTC(date.getUTCFullYear(), 0, 1));
    return Math.ceil((((date - yearStart) / 86400000) + 1) / 7);
  }

  // Aantal beschikbare tips (tip.1 … tip.N) — losgekoppeld van de taal zodat
  // de index voor iedereen gelijk is. Houden in sync met locales.js.
  const WEEKLY_TIP_COUNT = 8;
  function currentWeeklyTipKey() {
    const week = isoWeekNumber(new Date());
    const idx = ((week - 1) % WEEKLY_TIP_COUNT) + 1;
    return 'tip.' + idx;
  }

  function renderWeeklyTip() {
    const el = document.getElementById('weekly-tip-text');
    if (el) el.textContent = t(currentWeeklyTipKey());
  }

  // -------- Retentie: terugkeer-nudge op de welkom-pagina --------
  // Toon een vriendelijke banner als de gebruiker eerder een training afrondde
  // én het ≥ 30 dagen geleden is. Geen historie of < 30 dagen: verbergen.
  const RETURN_NUDGE_DAYS = 30;
  function renderReturnNudge() {
    const banner = document.getElementById('return-nudge');
    if (!banner) return;
    const last = getLastCompletion();
    const days = last ? (Date.now() - last) / 86400000 : 0;
    banner.hidden = !(last && days >= RETURN_NUDGE_DAYS);
  }

  // -------- Retentie: opfris-oefening (spaced repetition) --------
  // Hergebruikt de bestaande simulator-engine volledig. We halen de normale
  // /inbox-set op, bouwen een subset van ~5 berichten (eerst eerder-gemiste,
  // daarna willekeurige niet-recent-geziene), zetten simState en renderen via
  // de bestaande skin-functies.
  const REFRESHER_SIZE = 5;

  function pickRefresherMessages(messages) {
    const p = loadProgress();
    const missedSet = new Set(getMissedMessageIds());
    const present = messages.filter((m) => missedSet.has(m.id));
    const rest = messages.filter((m) => !missedSet.has(m.id));
    // De rest sorteren op "minst recent gezien eerst" (ongeziene = 0), met
    // een willekeurige tiebreaker zodat het niet elke keer dezelfde volgorde is.
    rest.sort((a, b) => {
      const sa = (p.messages[a.id] && p.messages[a.id].seenAt) || 0;
      const sb = (p.messages[b.id] && p.messages[b.id].seenAt) || 0;
      if (sa !== sb) return sa - sb;
      return Math.random() - 0.5;
    });
    const chosen = present.concat(rest).slice(0, REFRESHER_SIZE);
    return chosen.length ? chosen : messages.slice(0, REFRESHER_SIZE);
  }

  // Start de opfris-oefening. Geeft de oefening een schone start (verse
  // simState, geen herstel) zodat een lopende sessie niet wordt vervuild.
  async function startRefresher() {
    trackSimulatorStart();
    refresherMode = true;
    go('simulator');
    setDevice(detectDevice());
    // E-mail blijft het standaardkanaal voor de opfrisser; we forceren niets
    // wat de gebruiker zelf op het introscherm gekozen had voor een volle run.
    document.body.classList.add('sim-fullscreen');
    clearPersistedSimState();
    try {
      const all = applyOrgDomain(await api('/inbox'));
      const messages = pickRefresherMessages(all);
      simState = { messages, judgments: {}, interactions: {}, current: null };
      if (isChatChannel()) {
        showSimPhase('chat');
        buildChatSkin();
        renderChatList();
        if (messages.length) openChatMessage(messages[0].id);
      } else if (currentDevice === 'desktop') {
        showSimPhase('inbox');
        const result = document.getElementById('sim-result');
        if (result) result.hidden = true;
        currentFolder = 'inbox';
        setActiveFolderLi('inbox');
        renderInboxList();
        updateProgress();
        if (messages.length) openMessage(messages[0].id);
      } else {
        showSimPhase('mobile');
        const result = document.getElementById('sim-result');
        if (result) result.hidden = true;
        currentMobFolder = 'inbox';
        buildMobSkin();
        renderMobList();
        if (messages.length) openMobMessage(messages[0].id);
      }
    } catch (err) {
      console.error('refresher fetch failed', err);
      refresherMode = false;
    }
  }
  let refresherMode = false;

  // -------- Simulator fases (intro -> login -> inbox | mobile) --------
  function showSimPhase(name) {
    ['intro', 'login', 'inbox', 'mobile', 'chat', 'call'].forEach((p) => {
      const el = document.getElementById('sim-phase-' + p);
      if (el) el.hidden = (p !== name);
    });
    if (name === 'intro') {
      // Kanaal-toggle alleen tonen in extra-modus (sms/whatsapp/phone).
      const toggle = document.getElementById('sim-channel-toggle');
      if (toggle) {
        if (simMode === 'email') {
          toggle.hidden = true;
        } else {
          // In extra-modus: filter kanalen op basis van enterprise-config.
          const allowedCh = enterpriseConfig?.channels || ['sms', 'whatsapp', 'phone'];
          let visibleCount = 0;
          toggle.querySelectorAll('[data-channel]').forEach(btn => {
            const show = allowedCh.includes(btn.dataset.channel);
            btn.hidden = !show;
            if (show) visibleCount++;
          });
          // Als maar één kanaal beschikbaar: toggle verbergen en direct instellen.
          if (visibleCount <= 1) {
            toggle.hidden = true;
            if (allowedCh.length > 0) setChannel(allowedCh[0]);
          } else {
            toggle.hidden = false;
            // Zorg dat het actieve kanaal binnen de toegestane set valt.
            if (!allowedCh.includes(currentChannel)) setChannel(allowedCh[0]);
          }
        }
      }
    }
  }

  async function runMicrosoftLoginAnimation(simOpts) {
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
    const email = replaceDomain(t('user.email'));

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
    subtitle.innerHTML = t('sim.ms.pwSubtitle', { email: escapeHtml(email) });
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
      subtitle.innerHTML = t('sim.ms.pwSubtitle', { email: escapeHtml(email) });
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
    startSimulator(simOpts);
  }

  document.addEventListener('click', (e) => {
    if (e.target.closest('#sim-start-btn')) {
      e.preventDefault();
      trackSimulatorStart();
      setDevice(detectDevice());
      if (currentChannel === 'phone') {
        // Telefoon = vishing: geen postvak, maar een vertakkend
        // gespreksscript in het telefoon-frame (op elk apparaat).
        showSimPhase('call');
        startCallSimulator();
      } else if (isChatChannel()) {
        // sms/WhatsApp: geen mail-login, direct de chat-skin in het
        // telefoon-frame (op elk apparaat).
        showSimPhase('chat');
        startChatSimulator().catch((err) => console.error(err));
      } else if (currentDevice === 'desktop') {
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

  // Retentie: startknoppen voor de opfris-oefening (welkom-pagina en nudge).
  document.addEventListener('click', (e) => {
    const r = e.target.closest('#welkom-refresher, #nudge-refresher');
    if (r) { e.preventDefault(); startRefresher(); }
  });

  // Stappenbalk: een stap aanklikken navigeert naar die pagina. De stappen
  // gebruiken data-step (ook door go() gebruikt om de actieve stap te
  // markeren); we hergebruiken dat hier als navigatie.
  document.addEventListener('click', (e) => {
    const li = e.target.closest('#stepbar-list li[data-step]');
    if (li && pages.includes(li.dataset.step)) { e.preventDefault(); go(li.dataset.step); }
  });

  // -------- "Ik ben erin getrapt — wat nu?" beslisboom (hulp-pagina) --------
  // Geen backend, geen persoonsgegevens: puur tonen/verbergen van panelen.
  // Het antwoordpaneel krijgt dynamisch een data-i18n-html-attribuut, zodat
  // een taalwissel het automatisch mee-vertaalt via applyI18n(document).
  function watnuShow(key) {
    const body = document.getElementById('watnu-answer-body');
    const questions = document.getElementById('watnu-questions');
    const answer = document.getElementById('watnu-answer');
    if (!body || !questions || !answer) return;
    body.setAttribute('data-i18n-html', 'watnu.a.' + key);
    body.innerHTML = replaceDomain(t('watnu.a.' + key));
    // Actief markeren — werkt ook als antwoord al zichtbaar was (andere vraag kiezen).
    document.querySelectorAll('[data-watnu]').forEach((btn) => {
      btn.classList.toggle('watnu-active', btn.dataset.watnu === key);
    });
    answer.hidden = false;
    answer.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
  }
  document.addEventListener('click', (e) => {
    const q = e.target.closest('[data-watnu]');
    if (q) { e.preventDefault(); watnuShow(q.dataset.watnu); }
  });

  // -------- AI-phishing: "Vroeger vs. nu" vergelijking (leren-pagina) --------
  // Toont dezelfde phishing-bedoeling als klungelige versie van vroeger of als
  // foutloze AI-versie van nu. De mail en het onderschrift krijgen dynamisch een
  // data-i18n-html-attribuut zodat een taalwissel ze automatisch mee-vertaalt.
  function aiCompareShow(which) {
    const mail = document.getElementById('ai-compare-mail');
    const caption = document.getElementById('ai-compare-caption');
    if (!mail || !caption) return;
    // Attribuut bijhouden zodat taalwissel later alsnog de juiste tekst kiest.
    mail.setAttribute('data-i18n-html', 'leren.ai.compare.' + which);
    caption.setAttribute('data-i18n-html', 'leren.ai.compare.caption.' + which);
    // Direct vullen: applyI18n(element) zoekt alleen in descendants, niet
    // op het element zelf — dus innerHTML hier zelf zetten.
    mail.innerHTML    = replaceDomain(t('leren.ai.compare.' + which));
    caption.innerHTML = replaceDomain(t('leren.ai.compare.caption.' + which));
    document.querySelectorAll('#ai-compare .ai-compare-tab').forEach((el) => {
      el.classList.toggle('active', el.dataset.aiCompare === which);
    });
  }
  document.addEventListener('click', (e) => {
    const tab = e.target.closest('[data-ai-compare]');
    if (tab) { e.preventDefault(); aiCompareShow(tab.dataset.aiCompare); }
  });

  // -------- Wachtwoord & MFA-module (wachtwoord-pagina) --------
  // Geen backend, geen invoervelden, geen persoonsgegevens: alles is een
  // illustratieve demonstratie met tonen/verbergen en CSS-animaties.

  // 1. Hergebruik-domino: één gedeeld wachtwoord lekt, alle accounts vallen.
  // Eenmalige demonstratie: er is geen "opnieuw" — de les is na één keer duidelijk.
  function dominoTrigger() {
    const row = document.getElementById('domino-row');
    const trigger = document.getElementById('domino-trigger');
    const explain = document.getElementById('domino-explain');
    if (!row) return;
    const accts = row.querySelectorAll('.domino-acct');
    accts.forEach((el, i) => {
      // Trapsgewijs: elk account valt iets later, als een rij dominostenen.
      setTimeout(() => {
        el.classList.add('hacked');
        const state = el.querySelector('.domino-state');
        if (state) {
          state.setAttribute('data-i18n', 'ww.domino.hacked');
          state.textContent = t('ww.domino.hacked');
        }
      }, 250 + i * 450);
    });
    if (trigger) trigger.hidden = true;
    setTimeout(() => {
      if (explain) explain.hidden = false;
    }, 250 + accts.length * 450);
  }

  // 2. Wachtwoordzin-voorbeelden: klik vouwt de geschatte kraaktijd uit.
  function pwToggle(btn) {
    const crack = btn.querySelector('.pw-crack');
    if (!crack) return;
    const open = btn.getAttribute('aria-expanded') === 'true';
    btn.setAttribute('aria-expanded', open ? 'false' : 'true');
    crack.hidden = open;
  }

  // 3. MFA-moeheid: de gebruiker krijgt een melding die hij niet startte.
  // Goedkeuren = de aanvaller is binnen; weigeren = juiste keuze.
  function mfaRespond(choice) {
    const phone = document.getElementById('mfa-phone');
    const feedback = document.getElementById('mfa-feedback');
    const body = document.getElementById('mfa-feedback-body');
    if (!phone || !feedback || !body) return;
    feedback.classList.toggle('good', choice === 'deny');
    feedback.classList.toggle('bad', choice === 'approve');
    const mfaKey = choice === 'approve' ? 'ww.fatigue.approve.result' : 'ww.fatigue.deny.result';
    body.setAttribute('data-i18n-html', mfaKey);
    body.innerHTML = replaceDomain(t(mfaKey));
    phone.hidden = true;
    feedback.hidden = false;
    // "Probeer opnieuw" alleen tonen bij een foute keuze (goedkeuren), zodat
    // de gebruiker de veilige actie alsnog kan oefenen. Bij weigeren (juist)
    // is opnieuw proberen overbodig.
    const restart = document.getElementById('mfa-restart');
    if (restart) restart.hidden = (choice === 'deny');
    feedback.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
  }
  function mfaRestart() {
    const phone = document.getElementById('mfa-phone');
    const feedback = document.getElementById('mfa-feedback');
    const body = document.getElementById('mfa-feedback-body');
    if (!phone || !feedback || !body) return;
    body.removeAttribute('data-i18n-html');
    body.innerHTML = '';
    feedback.classList.remove('good', 'bad');
    feedback.hidden = true;
    phone.hidden = false;
  }

  document.addEventListener('click', (e) => {
    if (e.target.closest('#domino-trigger')) { e.preventDefault(); dominoTrigger(); return; }
    const pwBtn = e.target.closest('.pw-example');
    if (pwBtn) { e.preventDefault(); pwToggle(pwBtn); return; }
    const mfaBtn = e.target.closest('[data-mfa]');
    if (mfaBtn) { e.preventDefault(); mfaRespond(mfaBtn.dataset.mfa); return; }
    if (e.target.closest('#mfa-restart')) { e.preventDefault(); mfaRestart(); }
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
      const messages = applyOrgDomain(await api('/inbox'));
      const saved = opts.restore ? loadPersistedSimState() : null;
      let judgments = (saved && saved.judgments) || {};
      // Enterprise: laad beoordelingen uit DB zodat voortgang apparaat-
      // onafhankelijk is. Niet bij fresh (= "Opnieuw oefenen"): anders
      // zou elke hertraining direct als volledig beoordeeld starten.
      if (enterpriseConfig && !opts.fresh) {
        try {
          const progress = await api('/enterprise/progress');
          if (progress.judgments) judgments = Object.assign({}, judgments, progress.judgments);
        } catch (_) {}
      }
      simState = {
        messages,
        judgments,
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
        // Geen berichten voor deze taal/doelgroep/niveau-combinatie:
        // duidelijke melding i.p.v. een eeuwig "bezig met laden".
        list.innerHTML = '<li class="ol-loading">' + escapeHtml(t('sim.ol.noMessages')) + '</li>';
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
          '<div class="ol-item-subject">' +
            ((m.attachments && m.attachments.length) ? '<span class="ol-item-clip" aria-label="Bijlage">📎</span> ' : '') +
            escapeHtml(m.subject) + '</div>' +
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
      '<div class="ol-msg-body ol-junk-body">' + replaceDomain(t('sim.junk.body')) + '</div>' +
      '<div class="ol-msg-actions judged">' +
        '<p class="muted">' + replaceDomain(t('sim.junk.note')) + '</p>' +
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
      const messages = applyOrgDomain(await api('/inbox'));
      const saved = opts.restore ? loadPersistedSimState() : null;
      let judgments = (saved && saved.judgments) || {};
      if (enterpriseConfig && !opts.fresh) {
        try {
          const progress = await api('/enterprise/progress');
          if (progress.judgments) judgments = Object.assign({}, judgments, progress.judgments);
        } catch (_) {}
      }
      simState = {
        messages,
        judgments,
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
      } else if (list) {
        list.innerHTML = '<li class="mob-item" style="justify-content:center"><em>' + escapeHtml(t('sim.ol.noMessages')) + '</em></li>';
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
        '<div class="mob-reader-body mob-junk-body">' + replaceDomain(t('sim.junk.body')) + '</div>' +
      '</div>' +
      '<div class="mob-junk-note">' + replaceDomain(t('sim.junk.note')) + '</div>';
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
          '<div class="mob-item-subject">' +
            ((m.attachments && m.attachments.length) ? '📎 ' : '') +
            escapeHtml(m.subject) + '</div>' +
          '<div class="mob-item-preview">' + escapeHtml(m.preview || '') + '</div>' +
        '</div>';
      li.addEventListener('click', () => openMobMessage(m.id));
      list.appendChild(li);
    });
  }

  async function openMobMessage(id) {
    simState.current = id;
    if (!simState.interactions[id]) simState.interactions[id] = { clicked_link: false };
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
    try { m = applyOrgDomain([await api('/inbox/' + id)])[0]; }
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
        renderAttachments(m) +
      '</div>' +
      verdictBlock;
    reader.querySelector('.mob-btn-back').addEventListener('click', closeMobReader);
    wireAttachments(reader, m);
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

  // ================================================================
  // Chat-simulator (sms / WhatsApp = smishing).
  // Eén telefoon-frame op elk apparaat (desktop én mobiel). Hergebruikt
  // simState, /api/inbox (gefilterd op channel), renderBody (zodat
  // {{link:0}} een tikbare link wordt → waarschuwingsmodal), submitVerdict
  // en alle feedback-/eindscherm-logica. Alleen de skin verschilt:
  //   .channel-sms      → grijze/blauwe sms-bubbels, afzender = nummer
  //   .channel-whatsapp → groene koptekst, witte inkomende bubbels, avatar
  // De body-klasse wordt door setChannel() gezet en stuurt de CSS.

  async function startChatSimulator(opts) {
    opts = opts || {};
    const result = document.getElementById('sim-result');
    if (result) result.hidden = true;
    if (!opts.restore) clearPersistedSimState();
    buildChatSkin();
    const list = document.getElementById('chat-list-items');
    if (list) list.innerHTML = '<li class="chat-list-loading"><em>' + escapeHtml(t('sim.ol.loading')) + '</em></li>';
    try {
      const messages = applyOrgDomain(await api('/inbox'));
      const saved = opts.restore ? loadPersistedSimState() : null;
      let judgments = (saved && saved.judgments) || {};
      if (enterpriseConfig && !opts.fresh) {
        try {
          const progress = await api('/enterprise/progress');
          if (progress.judgments) judgments = Object.assign({}, judgments, progress.judgments);
        } catch (_) {}
      }
      simState = {
        messages,
        judgments,
        interactions: (saved && saved.interactions) || {},
        current: (saved && saved.current) || null,
      };
      renderChatList();
      updateProgress();
      if (messages.length > 0) {
        let openId = simState.current;
        if (!openId || !messages.find((m) => m.id === openId)) {
          const next = messages.find((m) => !simState.judgments[m.id]) || messages[0];
          openId = next.id;
        }
        openChatMessage(openId);
      } else if (list) {
        list.innerHTML = '<li class="chat-list-loading"><em>' + escapeHtml(t('sim.ol.noMessages')) + '</em></li>';
      }
    } catch (err) {
      if (list) list.innerHTML = '<li class="chat-list-loading" style="color:#b3261e">' + escapeHtml(t('sim.ol.loadError')) + '</li>';
    }
  }

  // Bouwt de chat-app: een koptekst (titel = "Berichten" voor sms,
  // "WhatsApp" voor WhatsApp), een gesprekkenlijst en een leeg
  // thread-paneel dat openChatMessage() vult.
  function buildChatSkin() {
    const app = document.getElementById('chat-app');
    if (!app) return;
    const isWa = currentChannel === 'whatsapp';
    app.className = 'chat-app ' + (isWa ? 'chat-whatsapp' : 'chat-sms');
    app.innerHTML =
      '<header class="chat-topbar">' +
        '<h1 class="chat-app-title">' + escapeHtml(isWa ? t('sim.chat.whatsapp.title') : t('sim.chat.sms.title')) + '</h1>' +
      '</header>' +
      '<ol class="chat-list" id="chat-list-items"></ol>' +
      '<div class="chat-thread" id="chat-thread" hidden></div>';
  }

  function renderChatList() {
    const list = document.getElementById('chat-list-items');
    if (!list || !simState) return;
    list.innerHTML = '';
    const isWa = currentChannel === 'whatsapp';
    simState.messages.forEach((m) => {
      const judged = simState.judgments[m.id];
      const li = document.createElement('li');
      li.className = 'chat-row' + (judged ? ' judged' : '') + (simState.current === m.id ? ' active' : '');
      li.setAttribute('role', 'button');
      li.tabIndex = 0;
      const statusIco = judged
        ? (judged.correct ? '<span class="chat-row-status good">✓</span>' : '<span class="chat-row-status bad">✗</span>')
        : '<span class="chat-row-unread" aria-label="ongelezen"></span>';
      const avatar = isWa
        ? '<div class="chat-row-avatar">' + escapeHtml(initials(m.sender_name)) + '</div>'
        : '<div class="chat-row-avatar chat-row-avatar-sms" aria-hidden="true">💬</div>';
      li.innerHTML =
        avatar +
        '<div class="chat-row-body">' +
          '<div class="chat-row-top">' +
            '<span class="chat-row-sender">' + escapeHtml(m.sender_name) + '</span>' +
            '<span class="chat-row-time">' + escapeHtml(m.received_label || '') + '</span>' +
          '</div>' +
          '<div class="chat-row-preview">' +
            ((m.attachments && m.attachments.length) ? '📎 ' : '') +
            escapeHtml(m.preview || stripPlaceholders(m.subject) || '') +
          '</div>' +
        '</div>' +
        statusIco;
      li.addEventListener('click', () => openChatMessage(m.id));
      li.addEventListener('keydown', (e) => {
        if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); openChatMessage(m.id); }
      });
      list.appendChild(li);
    });
  }

  // Verwijdert {{link:N}}-placeholders uit een preview-tekst.
  function stripPlaceholders(s) {
    return String(s || '').replaceAll(/\{\{link:\d+\}\}/g, '').trim();
  }

  async function openChatMessage(id) {
    simState.current = id;
    if (!simState.interactions[id]) simState.interactions[id] = { clicked_link: false };
    persistSimState();
    renderChatList();
    const thread = document.getElementById('chat-thread');
    if (!thread) return;
    thread.hidden = false;
    thread.innerHTML =
      '<header class="chat-thread-head">' +
        '<button class="chat-btn chat-btn-back" aria-label="Terug">←</button>' +
      '</header>' +
      '<div class="chat-thread-body"><p class="muted" style="padding:14px">' + escapeHtml(t('sim.ol.loading')) + '</p></div>';
    thread.querySelector('.chat-btn-back').addEventListener('click', closeChatThread);
    let m;
    try { m = applyOrgDomain([await api('/inbox/' + id)])[0]; }
    catch (_) {
      thread.querySelector('.chat-thread-body').innerHTML =
        '<p class="error" style="padding:14px">' + escapeHtml(t('sim.ol.msgLoadError')) + '</p>';
      return;
    }
    renderChatThread(m);
  }

  function renderChatThread(m) {
    const thread = document.getElementById('chat-thread');
    if (!thread) return;
    const isWa = currentChannel === 'whatsapp';
    const judged = simState.judgments[m.id];
    const senderName = escapeHtml(m.sender_name);
    const senderAddr = escapeHtml(m.sender_address || '');
    const avatar = isWa
      ? '<div class="chat-thread-avatar">' + escapeHtml(initials(m.sender_name)) + '</div>'
      : '';
    // Een sms/WhatsApp-bericht kan uit meerdere alinea's bestaan; we tonen
    // de hele body als één inkomende bubbel met renderBody zodat {{link:0}}
    // klikbaar wordt en de bijlage-chips meekomen.
    const bubble =
      '<div class="chat-bubble chat-bubble-in">' +
        '<div class="chat-bubble-text">' + renderBody(m.body, m.links || []) + '</div>' +
        renderAttachments(m) +
        '<span class="chat-bubble-time">' + escapeHtml(m.received_label || '') + '</span>' +
      '</div>';
    const verdictBlock = judged
      ? '<div class="chat-verdict judged"><p class="muted">' + escapeHtml(t('sim.reader.alreadyJudged')) + '</p></div>'
      : '<div class="chat-verdict">' +
          '<p class="chat-verdict-q">' + escapeHtml(t('sim.reader.verdictQ')) + '</p>' +
          '<div class="chat-verdict-btns">' +
            '<button class="btn btn-good" data-verdict="trust">' + escapeHtml(t('sim.reader.verdict.trust')) + '</button>' +
            '<button class="btn btn-bad" data-verdict="phish">' + escapeHtml(t('sim.reader.verdict.phish')) + '</button>' +
          '</div>' +
        '</div>';
    thread.innerHTML =
      '<header class="chat-thread-head">' +
        '<button class="chat-btn chat-btn-back" aria-label="Terug">←</button>' +
        avatar +
        '<div class="chat-thread-id">' +
          '<div class="chat-thread-name">' + senderName + '</div>' +
          (senderAddr ? '<div class="chat-thread-addr">' + senderAddr + '</div>' : '') +
        '</div>' +
      '</header>' +
      '<div class="chat-thread-body">' +
        '<div class="chat-day-sep">' + escapeHtml(t('sim.chat.today')) + '</div>' +
        bubble +
      '</div>' +
      verdictBlock;
    thread.querySelector('.chat-btn-back').addEventListener('click', closeChatThread);
    wireAttachments(thread, m);
    thread.querySelectorAll('[data-link-idx]').forEach((a) => {
      const idx = Number.parseInt(a.dataset.linkIdx, 10);
      const link = (m.links || [])[idx];
      a.addEventListener('click', (e) => {
        e.preventDefault();
        simState.interactions[m.id].clicked_link = true;
        openLinkModal(link);
      });
    });
    thread.querySelectorAll('[data-verdict]').forEach((b) => {
      b.addEventListener('click', () => submitVerdict(m, b.dataset.verdict));
    });
    const body = thread.querySelector('.chat-thread-body');
    if (body) body.scrollTop = body.scrollHeight;
  }

  function closeChatThread() {
    const thread = document.getElementById('chat-thread');
    if (thread) thread.hidden = true;
    renderChatList();
  }

  // ======================================================================
  // BEL-SIMULATOR (telefoon = vishing)
  // ----------------------------------------------------------------------
  // Een telefoongesprek is geen los vertrouw/phish-bericht, dus dit is GEEN
  // postvak/oordeel-engine maar een vertakkend gespreksscript: een kleine
  // toestandsmachine. Elk scenario heeft een 'incoming'-scherm (caller +
  // accepteren/weigeren) en een reeks 'beats' (de beller zegt iets, de
  // gebruiker kiest uit 2-3 antwoorden). Elke optie wijst naar de volgende
  // beat of naar een uitkomst (debrief). Alle zichtbare tekst staat als
  // i18n-sleutel in locales.js; hier staan alleen sleutels + de structuur.
  //
  // node-vorm:
  //   beats: { <id>: { lineKey, options:[{ labelKey, next?|outcome?, safe? }] } }
  //   outcomes: { <id>: { safe:bool, resultKey, lessonKeys:[...] } }
  // ======================================================================
  const CALL_SCENARIOS = [
    {
      id: 'bank',
      difficulty: 'normal',
      callerNameKey: 'sim.call.bank.caller',
      callerNumberKey: 'sim.call.bank.number',
      // Een onbekend/zakelijk ogend nummer; weigeren is hier al een veilige zet.
      declineOutcome: 'bank.declined',
      start: 'b1',
      beats: {
        b1: {
          lineKey: 'sim.call.bank.b1.line',
          options: [
            { labelKey: 'sim.call.bank.b1.o1', next: 'b2', safe: false },
            { labelKey: 'sim.call.bank.b1.o2', next: 'b3', safe: true },
          ],
        },
        b2: {
          lineKey: 'sim.call.bank.b2.line',
          options: [
            { labelKey: 'sim.call.bank.b2.o1', outcome: 'bank.code', safe: false },
            { labelKey: 'sim.call.bank.b2.o2', outcome: 'bank.transfer', safe: false },
            { labelKey: 'sim.call.bank.b2.o3', outcome: 'bank.hangup', safe: true },
          ],
        },
        b3: {
          lineKey: 'sim.call.bank.b3.line',
          options: [
            { labelKey: 'sim.call.bank.b3.o1', outcome: 'bank.code', safe: false },
            { labelKey: 'sim.call.bank.b3.o2', outcome: 'bank.hangup', safe: true },
          ],
        },
      },
      outcomes: {
        'bank.declined': { safe: true, resultKey: 'sim.call.bank.out.declined', lessonKeys: ['sim.call.rule.callback', 'sim.call.rule.nocodes'] },
        'bank.hangup':   { safe: true, resultKey: 'sim.call.bank.out.hangup',   lessonKeys: ['sim.call.rule.callback', 'sim.call.rule.nocodes'] },
        'bank.code':     { safe: false, resultKey: 'sim.call.bank.out.code',     lessonKeys: ['sim.call.rule.nocodes', 'sim.call.rule.callback'] },
        'bank.transfer': { safe: false, resultKey: 'sim.call.bank.out.transfer', lessonKeys: ['sim.call.rule.nosafeaccount', 'sim.call.rule.callback'] },
      },
    },
    {
      id: 'tech',
      difficulty: 'normal',
      callerNameKey: 'sim.call.tech.caller',
      callerNumberKey: 'sim.call.tech.number',
      declineOutcome: 'tech.declined',
      start: 't1',
      beats: {
        t1: {
          lineKey: 'sim.call.tech.t1.line',
          options: [
            { labelKey: 'sim.call.tech.t1.o1', next: 't2', safe: false },
            { labelKey: 'sim.call.tech.t1.o2', outcome: 'tech.hangup', safe: true },
          ],
        },
        t2: {
          lineKey: 'sim.call.tech.t2.line',
          options: [
            { labelKey: 'sim.call.tech.t2.o1', outcome: 'tech.remote', safe: false },
            { labelKey: 'sim.call.tech.t2.o2', outcome: 'tech.creds', safe: false },
            { labelKey: 'sim.call.tech.t2.o3', outcome: 'tech.hangup', safe: true },
          ],
        },
      },
      outcomes: {
        'tech.declined': { safe: true, resultKey: 'sim.call.tech.out.declined', lessonKeys: ['sim.call.rule.mscold', 'sim.call.rule.noremote'] },
        'tech.hangup':   { safe: true, resultKey: 'sim.call.tech.out.hangup',   lessonKeys: ['sim.call.rule.mscold', 'sim.call.rule.noremote'] },
        'tech.remote':   { safe: false, resultKey: 'sim.call.tech.out.remote',   lessonKeys: ['sim.call.rule.noremote', 'sim.call.rule.mscold'] },
        'tech.creds':    { safe: false, resultKey: 'sim.call.tech.out.creds',    lessonKeys: ['sim.call.rule.nopassword', 'sim.call.rule.mscold'] },
      },
    },
    {
      id: 'authority',
      difficulty: 'normal',
      callerNameKey: 'sim.call.authority.caller',
      callerNumberKey: 'sim.call.authority.number',
      declineOutcome: 'authority.declined',
      start: 'a1',
      beats: {
        a1: {
          lineKey: 'sim.call.authority.a1.line',
          options: [
            { labelKey: 'sim.call.authority.a1.o1', next: 'a2', safe: false },
            { labelKey: 'sim.call.authority.a1.o2', outcome: 'authority.verify', safe: true },
          ],
        },
        a2: {
          lineKey: 'sim.call.authority.a2.line',
          options: [
            { labelKey: 'sim.call.authority.a2.o1', outcome: 'authority.paid', safe: false },
            { labelKey: 'sim.call.authority.a2.o2', outcome: 'authority.data', safe: false },
            { labelKey: 'sim.call.authority.a2.o3', outcome: 'authority.hangup', safe: true },
          ],
        },
      },
      outcomes: {
        'authority.declined': { safe: true, resultKey: 'sim.call.authority.out.declined', lessonKeys: ['sim.call.rule.nopressure', 'sim.call.rule.officialchannel'] },
        'authority.verify':   { safe: true, resultKey: 'sim.call.authority.out.verify',   lessonKeys: ['sim.call.rule.officialchannel', 'sim.call.rule.nopressure'] },
        'authority.hangup':   { safe: true, resultKey: 'sim.call.authority.out.hangup',   lessonKeys: ['sim.call.rule.nopressure', 'sim.call.rule.officialchannel'] },
        'authority.paid':     { safe: false, resultKey: 'sim.call.authority.out.paid',     lessonKeys: ['sim.call.rule.nopressure', 'sim.call.rule.officialchannel'] },
        'authority.data':     { safe: false, resultKey: 'sim.call.authority.out.data',     lessonKeys: ['sim.call.rule.officialchannel', 'sim.call.rule.nopressure'] },
      },
    },

    // ===================== GEVORDERD (difficulty='advanced') =====================
    // Subtielere vishing: een gespooft bank-nummer, een deepfake-stem van de
    // directie, en een 'interne' IT-helpdesk. De tells zijn procesmatig
    // (verifieer zelf, geen codes/wachtwoorden, ongebruikelijk verzoek), niet
    // grof. Weigeren/zelf-terugbellen is steeds de veilige route.
    {
      id: 'advbank',
      difficulty: 'advanced',
      callerNameKey: 'sim.call.advbank.caller',
      callerNumberKey: 'sim.call.advbank.number',
      declineOutcome: 'advbank.declined',
      start: 'b1',
      beats: {
        b1: {
          lineKey: 'sim.call.advbank.b1.line',
          options: [
            { labelKey: 'sim.call.advbank.b1.o1', next: 'b2', safe: false },
            { labelKey: 'sim.call.advbank.b1.o2', outcome: 'advbank.callback', safe: true },
          ],
        },
        b2: {
          lineKey: 'sim.call.advbank.b2.line',
          options: [
            { labelKey: 'sim.call.advbank.b2.o1', outcome: 'advbank.code', safe: false },
            { labelKey: 'sim.call.advbank.b2.o2', outcome: 'advbank.transfer', safe: false },
            { labelKey: 'sim.call.advbank.b2.o3', outcome: 'advbank.callback', safe: true },
          ],
        },
      },
      outcomes: {
        'advbank.declined': { safe: true, resultKey: 'sim.call.advbank.out.declined', lessonKeys: ['sim.call.rule.spoofing', 'sim.call.rule.callback'] },
        'advbank.callback': { safe: true, resultKey: 'sim.call.advbank.out.callback', lessonKeys: ['sim.call.rule.spoofing', 'sim.call.rule.callback'] },
        'advbank.code':     { safe: false, resultKey: 'sim.call.advbank.out.code',     lessonKeys: ['sim.call.rule.nocodes', 'sim.call.rule.spoofing'] },
        'advbank.transfer': { safe: false, resultKey: 'sim.call.advbank.out.transfer', lessonKeys: ['sim.call.rule.nosafeaccount', 'sim.call.rule.callback'] },
      },
    },
    {
      id: 'advceo',
      difficulty: 'advanced',
      callerNameKey: 'sim.call.advceo.caller',
      callerNumberKey: 'sim.call.advceo.number',
      declineOutcome: 'advceo.declined',
      start: 'b1',
      beats: {
        b1: {
          lineKey: 'sim.call.advceo.b1.line',
          options: [
            { labelKey: 'sim.call.advceo.b1.o1', next: 'b2', safe: false },
            { labelKey: 'sim.call.advceo.b1.o2', outcome: 'advceo.verify', safe: true },
          ],
        },
        b2: {
          lineKey: 'sim.call.advceo.b2.line',
          options: [
            { labelKey: 'sim.call.advceo.b2.o1', outcome: 'advceo.paid', safe: false },
            { labelKey: 'sim.call.advceo.b2.o2', outcome: 'advceo.verify', safe: true },
          ],
        },
      },
      outcomes: {
        'advceo.declined': { safe: true, resultKey: 'sim.call.advceo.out.declined', lessonKeys: ['sim.call.rule.verifyinternal', 'sim.call.rule.newpayee'] },
        'advceo.verify':   { safe: true, resultKey: 'sim.call.advceo.out.verify',   lessonKeys: ['sim.call.rule.verifyinternal', 'sim.call.rule.newpayee'] },
        'advceo.paid':     { safe: false, resultKey: 'sim.call.advceo.out.paid',     lessonKeys: ['sim.call.rule.newpayee', 'sim.call.rule.verifyinternal'] },
      },
    },
    {
      id: 'advtech',
      difficulty: 'advanced',
      callerNameKey: 'sim.call.advtech.caller',
      callerNumberKey: 'sim.call.advtech.number',
      declineOutcome: 'advtech.declined',
      start: 'b1',
      beats: {
        b1: {
          lineKey: 'sim.call.advtech.b1.line',
          options: [
            { labelKey: 'sim.call.advtech.b1.o1', next: 'b2', safe: false },
            { labelKey: 'sim.call.advtech.b1.o2', outcome: 'advtech.verify', safe: true },
          ],
        },
        b2: {
          lineKey: 'sim.call.advtech.b2.line',
          options: [
            { labelKey: 'sim.call.advtech.b2.o1', outcome: 'advtech.creds', safe: false },
            { labelKey: 'sim.call.advtech.b2.o2', outcome: 'advtech.mfa', safe: false },
            { labelKey: 'sim.call.advtech.b2.o3', outcome: 'advtech.hangup', safe: true },
          ],
        },
      },
      outcomes: {
        'advtech.declined': { safe: true, resultKey: 'sim.call.advtech.out.declined', lessonKeys: ['sim.call.rule.verifyinternal', 'sim.call.rule.nopassword'] },
        'advtech.verify':   { safe: true, resultKey: 'sim.call.advtech.out.verify',   lessonKeys: ['sim.call.rule.verifyinternal', 'sim.call.rule.nopassword'] },
        'advtech.hangup':   { safe: true, resultKey: 'sim.call.advtech.out.hangup',   lessonKeys: ['sim.call.rule.nopassword', 'sim.call.rule.mfaonlyyou'] },
        'advtech.creds':    { safe: false, resultKey: 'sim.call.advtech.out.creds',    lessonKeys: ['sim.call.rule.nopassword', 'sim.call.rule.verifyinternal'] },
        'advtech.mfa':      { safe: false, resultKey: 'sim.call.advtech.out.mfa',      lessonKeys: ['sim.call.rule.mfaonlyyou', 'sim.call.rule.verifyinternal'] },
      },
    },
  ];

  // Toestand van het lopende gesprek. Geen persoonsgegevens; niet opgeslagen.
  let callState = null;

  // Scenario's voor het gekozen niveau. Valt terug op 'normal' als er voor
  // 'advanced' (nog) geen scenario's zijn, zodat de bel-simulator nooit leeg is.
  function activeCallScenarios() {
    const want = currentDifficulty === 'advanced' ? 'advanced' : 'normal';
    const list = CALL_SCENARIOS.filter((s) => (s.difficulty || 'normal') === want);
    return list.length ? list : CALL_SCENARIOS.filter((s) => (s.difficulty || 'normal') === 'normal');
  }

  function startCallSimulator() {
    const result = document.getElementById('sim-result');
    if (result) result.hidden = true;
    // Begin bij het eerste scenario; de debrief biedt "volgend scenario" aan.
    callState = { scenarios: activeCallScenarios(), scenarioIndex: 0, phase: 'incoming', beatId: null, outcomeId: null };
    renderCallStep();
  }

  function currentScenario() {
    const list = (callState && callState.scenarios) ? callState.scenarios : CALL_SCENARIOS;
    return list[callState ? callState.scenarioIndex : 0];
  }

  // Tekent de huidige toestand opnieuw (gebruikt door taal-/kanaalwissel).
  function renderCallStep() {
    const app = document.getElementById('call-app');
    if (!app || !callState) return;
    if (callState.phase === 'incoming') renderCallIncoming(app);
    else if (callState.phase === 'incall') renderCallInCall(app);
    else if (callState.phase === 'debrief') renderCallDebrief(app);
  }

  function renderCallIncoming(app) {
    const sc = currentScenario();
    app.className = 'call-app call-incoming';
    app.innerHTML =
      '<div class="call-incoming-top">' +
        '<p class="call-incoming-label">' + escapeHtml(t('sim.call.incoming')) + '</p>' +
        '<div class="call-avatar" aria-hidden="true">📞</div>' +
        '<h1 class="call-caller-name">' + escapeHtml(t(sc.callerNameKey)) + '</h1>' +
        '<p class="call-caller-number">' + escapeHtml(t(sc.callerNumberKey)) + '</p>' +
      '</div>' +
      '<div class="call-incoming-actions">' +
        '<button class="call-action call-decline" data-call-action="decline">' +
          '<span class="call-action-icon" aria-hidden="true">📵</span>' +
          '<span class="call-action-label">' + escapeHtml(t('sim.call.decline')) + '</span>' +
        '</button>' +
        '<button class="call-action call-accept" data-call-action="accept">' +
          '<span class="call-action-icon" aria-hidden="true">📞</span>' +
          '<span class="call-action-label">' + escapeHtml(t('sim.call.accept')) + '</span>' +
        '</button>' +
      '</div>';
    app.querySelector('[data-call-action="accept"]').addEventListener('click', () => {
      callState.phase = 'incall';
      callState.beatId = currentScenario().start;
      renderCallStep();
    });
    app.querySelector('[data-call-action="decline"]').addEventListener('click', () => {
      callState.phase = 'debrief';
      callState.outcomeId = currentScenario().declineOutcome;
      renderCallStep();
    });
  }

  function renderCallInCall(app) {
    const sc = currentScenario();
    const beat = sc.beats[callState.beatId];
    if (!beat) return;
    app.className = 'call-app call-inprogress';
    const optsHtml = beat.options.map((o, i) =>
      '<button class="call-option" data-call-opt="' + i + '">' + escapeHtml(t(o.labelKey)) + '</button>'
    ).join('');
    app.innerHTML =
      '<header class="call-bar">' +
        '<div class="call-bar-name">' + escapeHtml(t(sc.callerNameKey)) + '</div>' +
        '<div class="call-bar-status">' + escapeHtml(t('sim.call.connected')) + '</div>' +
      '</header>' +
      '<div class="call-convo">' +
        '<div class="call-line">' +
          '<div class="call-line-who">' + escapeHtml(t('sim.call.theyText')) + '</div>' +
          '<p class="call-bubble">' + escapeHtml(t(beat.lineKey)) + '</p>' +
        '</div>' +
      '</div>' +
      '<div class="call-options">' +
        '<p class="call-options-q">' + escapeHtml(t('sim.call.yourReply')) + '</p>' +
        optsHtml +
      '</div>';
    beat.options.forEach((o, i) => {
      app.querySelector('[data-call-opt="' + i + '"]').addEventListener('click', () => {
        if (o.outcome) {
          callState.phase = 'debrief';
          callState.outcomeId = o.outcome;
          renderCallStep();
        } else if (o.next) {
          callState.beatId = o.next;
          renderCallStep();
        }
      });
    });
  }

  function renderCallDebrief(app) {
    const sc = currentScenario();
    const outcome = sc.outcomes[callState.outcomeId];
    if (!outcome) return;
    app.className = 'call-app call-debrief ' + (outcome.safe ? 'call-debrief-safe' : 'call-debrief-trap');
    const lessons = outcome.lessonKeys.map((k) =>
      '<li>' + escapeHtml(t(k)) + '</li>'
    ).join('');
    const scenarioCount = (callState.scenarios || CALL_SCENARIOS).length;
    const isLast = callState.scenarioIndex >= scenarioCount - 1;
    const nextBtn = isLast
      ? '<button class="btn btn-primary" data-call-action="done">' + escapeHtml(t('sim.call.done')) + '</button>'
      : '<button class="btn btn-primary" data-call-action="next">' + escapeHtml(t('sim.call.next')) + '</button>';
    app.innerHTML =
      '<div class="call-debrief-inner">' +
        '<div class="call-debrief-icon" aria-hidden="true">' + (outcome.safe ? '✅' : '⚠️') + '</div>' +
        '<h2 class="call-debrief-h">' + escapeHtml(t(outcome.safe ? 'sim.call.debrief.safeH' : 'sim.call.debrief.trapH')) + '</h2>' +
        '<p class="call-debrief-result">' + escapeHtml(t(outcome.resultKey)) + '</p>' +
        '<div class="call-remember">' +
          '<p class="call-remember-h">' + escapeHtml(t('sim.call.debrief.remember')) + '</p>' +
          '<ul class="call-remember-list">' + lessons + '</ul>' +
        '</div>' +
        '<p class="call-golden">' + escapeHtml(t('sim.call.debrief.golden')) + '</p>' +
        '<div class="call-debrief-actions">' +
          nextBtn +
        '</div>' +
      '</div>';
    const nextEl = app.querySelector('[data-call-action="next"]');
    if (nextEl) nextEl.addEventListener('click', () => {
      callState.scenarioIndex += 1;
      callState.phase = 'incoming';
      callState.beatId = null;
      callState.outcomeId = null;
      renderCallStep();
    });
    const doneEl = app.querySelector('[data-call-action="done"]');
    if (doneEl) doneEl.addEventListener('click', () => {
      showSimPhase('intro');
    });
  }

  async function openMessage(id) {
    simState.current = id;
    if (!simState.interactions[id]) simState.interactions[id] = { clicked_link: false };
    persistSimState();
    renderInboxList();
    const reader = document.getElementById('ol-reader');
    reader.innerHTML = '<p class="muted">' + escapeHtml(t('sim.ol.loading')) + '</p>';
    let m;
    try { m = applyOrgDomain([await api('/inbox/' + id)])[0]; }
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
      renderAttachments(m) +
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
    wireAttachments(reader, m);

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
    // QR-afbeeldingen krijgen de sessie en taal mee zodat een echte scan
    // met de telefoon herleidbaar is naar deze trainingssessie én de
    // lespagina in de juiste taal verschijnt (zie /qr-img en /qr).
    html = html.replaceAll(/src="\/qr-img\/(\w+)"/g, (_m, tag) =>
      'src="/qr-img/' + tag + '?s=' + encodeURIComponent(getSessionId()) +
      '&l=' + encodeURIComponent(currentLang) + '"');
    html = html.replaceAll(/\{\{link:(\d+)\}\}/g, (_m, n) => {
      const idx = Number.parseInt(n, 10);
      const link = links[idx];
      if (!link) return '';
      const label = escapeHtml(link.label || 'link');
      // We tonen de bestemmings-URL bewust NIET inline in de mail. Net als in
      // een echte mailclient ontdekt de gebruiker waar de link heen gaat door
      // te hoveren (tooltip) of erop te klikken (de link-modal toont het doel).
      // Zo blijft de oefening realistisch: zelf controleren, niet voorgekauwd.
      return '<a href="#" class="ol-link" data-link-idx="' + idx + '" ' +
             'title="' + escapeHtml(t('sim.reader.linkTo', { url: link.real_url || '' })) + '">' +
             '<span class="ol-link-label">' + label + '</span></a>';
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

  // Pictogram per bestandstype. Bij een dubbele extensie (bv. .pdf.exe)
  // toont een echte aanvaller het icoon van het type dat hij NABOOTST —
  // de .exe blijft verborgen. Wij doen dat ook: de vermomming is
  // overtuigend, de enige tell is de bestandsnaam zelf.
  function attachIcon(filename) {
    const parts = (filename || '').toLowerCase().split('.');
    const real = parts.pop();
    const exec = ['exe', 'scr', 'bat', 'com', 'cmd', 'js', 'jar', 'msi'];
    const shown = (exec.includes(real) && parts.length) ? parts.pop() : real;

    let color = '#6b7280', label = (shown || 'bin').toUpperCase().slice(0, 4);
    if (shown === 'pdf')                             { color = '#e53e3e'; label = 'PDF'; }
    else if (['doc', 'docx'].includes(shown))        { color = '#2b5fd8'; label = 'DOC'; }
    else if (['xls', 'xlsx', 'csv'].includes(shown)) { color = '#276749'; label = 'XLS'; }
    else if (['ppt', 'pptx'].includes(shown))        { color = '#c05621'; label = 'PPT'; }
    else if (['zip', 'rar', '7z'].includes(shown))   { color = '#d69e2e'; label = 'ZIP'; }
    else if (['jpg','jpeg','png','gif','webp'].includes(shown)) { color = '#6b46c1'; label = 'IMG'; }

    return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 40" width="28" height="35" aria-hidden="true">'
      + '<path d="M4 0h17l7 8v32H4z" fill="#fff" stroke="#d1d5db" stroke-width="1.5"/>'
      + '<path d="M21 0l7 8h-7z" fill="#e5e7eb" stroke="#d1d5db" stroke-width="1.5"/>'
      + '<rect x="4" y="24" width="24" height="12" rx="2" fill="' + color + '"/>'
      + '<text x="16" y="34" text-anchor="middle" font-family="system-ui,sans-serif"'
      + ' font-size="7" font-weight="700" fill="#fff">' + label + '</text>'
      + '</svg>';
  }

  function renderAttachments(m) {
    const atts = m.attachments || [];
    if (atts.length === 0) return '';
    const chips = atts.map((a, i) =>
      '<button class="ol-attach-chip" data-attach-idx="' + i + '" type="button">' +
        '<span class="ol-attach-ico" aria-hidden="true">' + attachIcon(a.filename) + '</span>' +
        '<span class="ol-attach-info">' +
          '<span class="ol-attach-name">' + escapeHtml(a.filename || 'bijlage') + '</span>' +
          (a.size ? '<span class="ol-attach-size">' + escapeHtml(a.size) + '</span>' : '') +
        '</span>' +
      '</button>'
    ).join('');
    return '<div class="ol-attach-bar">' +
      '<div class="ol-attach-label">' + escapeHtml(t('sim.attach.label', { count: atts.length })) + '</div>' +
      '<div class="ol-attach-chips">' + chips + '</div></div>';
  }

  function wireAttachments(scope, m) {
    scope.querySelectorAll('[data-attach-idx]').forEach((btn) => {
      const idx = Number.parseInt(btn.dataset.attachIdx, 10);
      const att = (m.attachments || [])[idx];
      btn.addEventListener('click', (e) => {
        e.preventDefault();
        // Een bijlage openen is "ik trapte erin", maar het is géén link-klik —
        // aparte teller zodat de eindrapportage feitelijk klopt.
        if (simState.interactions[m.id]) simState.interactions[m.id].opened_attachment = true;
        openAttachmentModal(att);
      });
    });
  }

  function openAttachmentModal(att) {
    const bad = !!(att && att.dangerous);
    const warning = att ? (att.warning || '') : '';
    showModal({
      title: bad ? t('sim.attach.titleBad') : t('sim.attach.titleSafe'),
      variant: bad ? 'bad' : '',
      bodyHtml:
        '<p class="big-text">' + escapeHtml(t('sim.attach.opens')) + '</p>' +
        '<p class="mono url-preview ' + (bad ? 'bad' : '') + '">' +
          escapeHtml(att ? att.filename : '') + '</p>' +
        (warning ? '<p class="tip-line">' + escapeHtml(warning) + '</p>' : '') +
        '<p>' + (bad ? t('sim.attach.dontOpen') : escapeHtml(t('sim.attach.tip'))) + '</p>',
      actions: [{ label: t('common.close'), primary: true, close: true }],
    });
  }

  async function submitVerdict(m, verdict) {
    // Verdict-knoppen disablen — werkt in beide skins omdat iedere
    // verdict-knop het data-verdict attribuut draagt.
    const readerSel = isChatChannel() ? '#chat-thread ' : (currentDevice === 'desktop' ? '#ol-reader ' : '#mob-reader ');
    const activeButtons = document.querySelectorAll(readerSel + '[data-verdict]');
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
          // De server weigert met 401 als onze enterprise-sessie
          // ondertussen verlopen is — zo gaat geen voortgang verloren.
          enterprise: !!enterpriseConfig,
        }),
      });
    } catch (err) {
      activeButtons.forEach((b) => b.disabled = false);
      if (err && err.status === 401 && enterpriseConfig) {
        showModal({
          title: t('sim.error.title'),
          bodyHtml: '<p>' + escapeHtml(t('sim.error.sessionExpired')) + '</p>',
          actions: [{ label: t('sim.error.relogin'), primary: true,
                      onClick: () => { window.location.href = '/'; } }],
        });
        return;
      }
      showModal({
        title: t('sim.error.title'),
        bodyHtml: '<p>' + escapeHtml(t('sim.error.save')) + '</p>',
        actions: [{ label: t('common.close'), primary: true, close: true }],
      });
      return;
    }

    simState.judgments[m.id] = { verdict, correct: res.correct, is_phishing: res.is_phishing, red_flags: res.red_flags || [] };
    if (isChatChannel()) renderChatList();
    else if (currentDevice === 'desktop') renderInboxList();
    else renderMobList();
    updateProgress();
    persistSimState();
    showVerdictFeedback(m, res);
  }

  function showVerdictFeedback(m, res) {
    const redFlags = (res.red_flags || []).map((s) => '<li>' + escapeHtml(replaceDomain(s)) + '</li>').join('');
    const greenFlags = (res.green_flags || []).map((s) => '<li>' + escapeHtml(replaceDomain(s)) + '</li>').join('');
    const senderNote = res.sender_note
      ? '<p><strong>' + escapeHtml(t('sim.verdict.senderNote')) + '</strong> ' + escapeHtml(replaceDomain(res.sender_note)) + '</p>'
      : '';

    // De feedback verschilt per uitkomst: een terechte melding bevestigt
    // de meld-reflex; een onterechte melding van een echt bericht krijgt
    // een mildere toon dan "fout" — voorzichtigheid is geen domme fout.
    const reported = simState.judgments[m.id]?.verdict === 'phish';
    let title, variant;
    if (res.correct) {
      title = reported ? t('sim.verdict.reported.correct') : t('sim.verdict.correct');
      variant = 'good';
    } else if (reported) {
      title = t('sim.verdict.falsereport.title');
      variant = '';
    } else {
      title = t('sim.verdict.wrong');
      variant = 'bad';
    }
    const reportNote = reported
      ? (res.correct
        ? '<p>' + escapeHtml(t('sim.verdict.reported.note', {
            org: (enterpriseConfig && enterpriseConfig.orgName) || t('sim.verdict.reported.orgFallback'),
          })) + '</p>'
        : '<p>' + escapeHtml(t('sim.verdict.falsereport.note')) + '</p>')
      : '';

    showModal({
      title,
      variant,
      bodyHtml:
        '<p><strong>' + escapeHtml(t('sim.verdict.answer')) + '</strong> ' +
          escapeHtml(res.is_phishing ? t('sim.verdict.isPhishing') : t('sim.verdict.isReal')) + '</p>' +
        '<p>' + escapeHtml(replaceDomain(res.explanation)) + '</p>' +
        senderNote +
        reportNote +
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
    if (isChatChannel()) openChatMessage(next.id);
    else if (currentDevice === 'desktop') openMessage(next.id);
    else openMobMessage(next.id);
  }

  async function finishSimulator() {
    if (isChatChannel()) {
      const thread = document.getElementById('chat-thread');
      if (thread) thread.hidden = true;
    } else if (currentDevice === 'desktop') {
      resetReader();
    } else {
      const reader = document.getElementById('mob-reader');
      if (reader) reader.hidden = true;
    }
    // Persisted state hoeft niet meer — sessie is afgerond. Refresh
    // op de result-pagina laat de gebruiker dan weer fris beginnen.
    clearPersistedSimState();
    // Was dit een opfris-oefening? Bewaren vóór de reset hieronder, want de
    // "Comeback"-badge hangt ervan af.
    const wasRefresher = refresherMode;
    refresherMode = false;
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

    // Inzichten: verdeel phishing vs. echte mails, toon wat gemist is.
    const phishingMsgs = simState.messages.filter((m) => simState.judgments[m.id]?.is_phishing);
    const legitMsgs    = simState.messages.filter((m) => simState.judgments[m.id] && !simState.judgments[m.id].is_phishing);
    const phishCorrect = phishingMsgs.filter((m) => simState.judgments[m.id].correct).length;
    const legitCorrect = legitMsgs.filter((m) => simState.judgments[m.id].correct).length;
    const missedPhish  = phishingMsgs.filter((m) => !simState.judgments[m.id].correct);

    const breakdownHtml = (phishingMsgs.length > 0 || legitMsgs.length > 0) ? (
      '<div class="final-breakdown">' +
        (phishingMsgs.length > 0
          ? '<span>' + escapeHtml(t('sim.final.insight.phishing', { correct: phishCorrect, total: phishingMsgs.length })) + '</span>'
          : '') +
        (legitMsgs.length > 0
          ? '<span>' + escapeHtml(t('sim.final.insight.legit', { correct: legitCorrect, total: legitMsgs.length })) + '</span>'
          : '') +
      '</div>'
    ) : '';

    // Hoe vaak klikte de gebruiker op een verdachte link in een phishing-mail?
    const clickedCount = simState.messages.filter((m) => {
      const j = simState.judgments[m.id];
      return j && j.is_phishing && simState.interactions[m.id]?.clicked_link;
    }).length;
    const clickedHtml = clickedCount > 0
      ? '<div class="final-qr-scanned">⚠️ ' + escapeHtml(t('sim.final.clickedLinks', { count: clickedCount })) + '</div>'
      : '';

    // Apart: hoe vaak opende de gebruiker een gevaarlijke bijlage?
    const openedCount = simState.messages.filter((m) => {
      const j = simState.judgments[m.id];
      return j && j.is_phishing && simState.interactions[m.id]?.opened_attachment;
    }).length;
    const openedHtml = openedCount > 0
      ? '<div class="final-qr-scanned">⚠️ ' + escapeHtml(t('sim.final.openedAttachment', { count: openedCount })) + '</div>'
      : '';

    // Gamification: badges op basis van deze run.
    const badges = earnedBadges({
      total, correct, pct,
      phishTotal: phishingMsgs.length,
      phishCorrect,
      clicked: clickedCount,
      opened: openedCount,
      wasRefresher,
    });
    // Retentie: enterprise → server-side; publiek → localStorage.
    await recordCompletionAndBadges(total, correct, wasRefresher, badges);

    // Toon alle verdiende badges (over alle trainingsronden heen).
    // Enterprise: uit serverHistory (bijgewerkt door recordCompletionAndBadges).
    // Publiek: uit de huidige run + localStorage-collectie.
    let allBadgeIds;
    if (enterpriseConfig && serverHistory && Array.isArray(serverHistory.badges)) {
      allBadgeIds = serverHistory.badges;
    } else {
      const p = loadProgress();
      allBadgeIds = Array.isArray(p.badges) ? p.badges : badges.map((b) => b.id);
    }
    const allBadges = BADGE_DEFS.filter((b) => allBadgeIds.includes(b.id));
    const newBadgeIds = new Set(badges.map((b) => b.id));
    const badgesHtml = allBadges.length > 0 ? (
      '<div class="final-badges">' +
        '<p class="final-badges-h">' + escapeHtml(t('badge.h')) + '</p>' +
        '<ul class="badge-row">' + allBadges.map((b) =>
          '<li class="badge-chip' + (newBadgeIds.has(b.id) ? ' badge-new' : '') + '" title="' + escapeHtml(t('badge.' + b.id + '.desc')) + '">' +
            '<span class="badge-icon" aria-hidden="true">' + b.icon + '</span>' +
            '<span class="badge-label">' + escapeHtml(t('badge.' + b.id + '.name')) + '</span>' +
          '</li>'
        ).join('') + '</ul>' +
      '</div>'
    ) : '';

    // Persoonlijk risicoprofiel: groepeer de beoordeelde berichten per
    // categorie en bereken per categorie het percentage correct. Zo wordt de
    // feedback actiegericht ("Sterk in: bankfraude" / "Let op bij: gezag").
    // Volledig client-side uit simState; categorie komt uit het berichtobject.
    const catStats = {};
    simState.messages.forEach((m) => {
      const j = simState.judgments[m.id];
      if (!j) return;
      const cat = m.category || 'overig';
      const s = catStats[cat] || (catStats[cat] = { total: 0, correct: 0 });
      s.total += 1;
      if (j.correct) s.correct += 1;
    });
    const catRows = Object.keys(catStats).map((cat) => {
      const s = catStats[cat];
      const cp = Math.round((s.correct / s.total) * 100);
      const level = cp >= 80 ? 'good' : cp >= 60 ? 'okay' : 'weak';
      return { cat, total: s.total, correct: s.correct, pct: cp, level };
    }).sort((a, b) => b.pct - a.pct || b.total - a.total);

    let profileHtml = '';
    if (catRows.length > 0) {
      // Kopregel met sterkste en zwakste categorie. De zwakke tip alleen tonen
      // als die op minstens 2 berichten berust — anders is hij misleidend.
      const strongest = catRows[0];
      const weakCandidates = catRows.filter((r) => r.total >= 2);
      const weakest = weakCandidates.length ? weakCandidates[weakCandidates.length - 1] : null;
      let headline = '';
      if (catRows.length < 2 || (weakest && weakest.cat === strongest.cat)) {
        headline = '<p class="profile-none">' + escapeHtml(t('profile.none')) + '</p>';
      } else {
        headline = '<p class="profile-headline">';
        if (strongest.pct >= 60) {
          headline += '<span class="profile-strong">' +
            escapeHtml(t('profile.strong', { cat: t('cat.' + strongest.cat) })) + '</span>';
        }
        if (weakest && weakest.pct < 80 && weakest.cat !== strongest.cat) {
          headline += '<span class="profile-weak">' +
            escapeHtml(t('profile.weak', { cat: t('cat.' + weakest.cat) })) + '</span>';
        }
        headline += '</p>';
        if (headline === '<p class="profile-headline"></p>') {
          headline = '<p class="profile-none">' + escapeHtml(t('profile.none')) + '</p>';
        }
      }
      profileHtml =
        '<div class="risk-profile">' +
          '<p class="profile-h">' + escapeHtml(t('profile.h')) + '</p>' +
          headline +
          '<ul class="profile-list">' + catRows.map((r) =>
            '<li class="profile-item">' +
              '<span class="profile-cat">' + escapeHtml(t('cat.' + r.cat)) + '</span>' +
              '<span class="profile-bar"><span class="profile-bar-fill profile-' + r.level + '" style="width:' + r.pct + '%"></span></span>' +
              '<span class="profile-count">' + r.correct + '/' + r.total + '</span>' +
            '</li>'
          ).join('') + '</ul>' +
        '</div>';
    }

    const missedHtml = missedPhish.length > 0 ? (
      '<div class="final-missed">' +
        '<p class="final-missed-h">' + escapeHtml(t('sim.final.insight.missed')) + '</p>' +
        '<ul>' + missedPhish.map((m) => {
          const flags = simState.judgments[m.id].red_flags || [];
          const tip = flags[0] ? ' <em>— ' + escapeHtml(replaceDomain(flags[0])) + '</em>' : '';
          return '<li>' + escapeHtml(m.subject) + tip + '</li>';
        }).join('') +
        '</ul>' +
      '</div>'
    ) : '';

    // Opt-in kaarten ná de e-mail simulator. De kern blijft kort (welkom →
    // simulator); verdiepende onderdelen bieden we hier pas aan, zodat
    // beginners niet overspoeld worden. Elke kaart respecteert de
    // enterprise-moduleconfig.
    const mods = enterpriseConfig?.modules || ['leren', 'simulator', 'kanalen', 'hulp', 'wachtwoord'];
    let extraHtml = '';
    if (simMode === 'email') {
      const cards = [];
      if (mods.includes('kanalen')) {
        cards.push(
          '<button class="optin-card" id="extra-naar-kanalen">' +
            '<span class="optin-icon" aria-hidden="true">💬</span>' +
            '<span class="optin-text"><strong>' + escapeHtml(t('sim.final.optin.kanalen.h')) + '</strong>' +
            '<span>' + escapeHtml(t('sim.final.optin.kanalen.p')) + '</span></span>' +
          '</button>');
      }
      if (mods.includes('wachtwoord')) {
        cards.push(
          '<button class="optin-card" data-go="wachtwoord">' +
            '<span class="optin-icon" aria-hidden="true">🔑</span>' +
            '<span class="optin-text"><strong>' + escapeHtml(t('sim.final.optin.ww.h')) + '</strong>' +
            '<span>' + escapeHtml(t('sim.final.optin.ww.p')) + '</span></span>' +
          '</button>');
      }
      if (cards.length) {
        extraHtml =
          '<div class="sim-optin">' +
            '<h3>' + escapeHtml(t('sim.final.optin.h')) + '</h3>' +
            '<div class="optin-grid">' + cards.join('') + '</div>' +
          '</div>';
      }
    }

    // De 7 signalen als compacte naslag — alleen na de e-mail simulator, want
    // dit zijn de e-mail-phishingsignalen. Geeft het mentale model één keer,
    // ná het doen, zonder leesmuur vooraf.
    const signalsHtml = (simMode === 'email')
      ? '<div class="sim-signals">' +
          '<h3>' + escapeHtml(t('sim.final.signals.h')) + '</h3>' +
          '<ol class="signals-list">' +
            [1, 2, 3, 4, 5, 6, 7].map((n) =>
              '<li>' + escapeHtml(t('leren.it' + n + '.h')) + '</li>').join('') +
          '</ol>' +
        '</div>'
      : '';

    result.innerHTML =
      '<h2>' + escapeHtml(titel) + '</h2>' +
      '<p class="big-text">' + t('sim.final.score', { correct, total, pct }) + '</p>' +
      '<p>' + escapeHtml(advies) + '</p>' +
      badgesHtml +
      breakdownHtml +
      profileHtml +
      clickedHtml +
      openedHtml +
      '<div id="final-qr-warning"></div>' +
      missedHtml +
      signalsHtml +
      extraHtml +
      '<div class="actions">' +
        '<button class="btn btn-primary" id="sim-again">' + escapeHtml(t('sim.final.again')) + '</button>' +
        '<button class="btn btn-secondary" id="sim-refresher">' + escapeHtml(t('refresher.start')) + '</button>' +
        '<button class="btn btn-secondary" data-go="hulp">' + escapeHtml(t('sim.final.help')) + '</button>' +
      '</div>';
    result.hidden = false;
    document.getElementById('sim-refresher').addEventListener('click', () => {
      startRefresher();
    });
    document.getElementById('sim-again').addEventListener('click', () => {
      // Herstart: sla intro/login over, ga direct terug naar de inbox
      // van hetzelfde apparaat als daarnet.
      document.body.classList.add('sim-fullscreen');
      result.hidden = true;
      if (isChatChannel()) {
        showSimPhase('chat');
        startChatSimulator({ fresh: true }).catch((err) => console.error(err));
      } else if (currentDevice === 'desktop') {
        showSimPhase('inbox');
        startSimulator({ fresh: true });
      } else {
        showSimPhase('mobile');
        startMobileSimulator({ fresh: true });
      }
    });
    // Na e-mail simulator: knop naar stap 4 meer kanalen.
    const extraBtn = document.getElementById('extra-naar-kanalen');
    if (extraBtn) extraBtn.addEventListener('click', () => { go('kanalen'); });

    result.scrollIntoView({ behavior: 'smooth', block: 'start' });

    // Heeft de gebruiker tijdens de oefening écht een QR-code gescand
    // met de telefoon? Dan tonen we dat als extra leermoment.
    api('/qr-scans?session_id=' + encodeURIComponent(getSessionId()))
      .then((r) => {
        if (!r.scans || r.scans.length === 0) return;
        const el = document.getElementById('final-qr-warning');
        if (!el) return;
        el.innerHTML =
          '<div class="final-qr-scanned">⚠️ ' +
          escapeHtml(t('sim.final.qrScanned')) +
          '</div>';
      })
      .catch(() => {});
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
