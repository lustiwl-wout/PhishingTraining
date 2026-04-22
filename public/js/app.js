/* Veilig Online — frontend logica.
   Bewust simpel gehouden: vanilla JS, duidelijke functienamen, weinig magie. */

(function () {
  'use strict';

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
      bar.innerHTML = '⏳ De website wordt even opgestart. Een momentje geduld…';
      document.body.appendChild(bar);
    }
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
      const res = await fetch('/api' + path, Object.assign({
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
    const main = document.getElementById('hoofd');
    if (main) main.focus();
    window.scrollTo({ top: 0, behavior: 'smooth' });

    if (step === 'voorbeelden') loadExamples();
    if (step === 'simulator') startSimulator();
  }

  document.addEventListener('click', (e) => {
    const t = e.target.closest('[data-go]');
    if (t) { e.preventDefault(); go(t.dataset.go); }
  });

  // -------- toegankelijkheid: tekstgrootte + contrast --------
  const root = document.documentElement;
  const savedScale = parseFloat(localStorage.getItem('vo_scale') || '1');
  root.style.setProperty('--text-scale', savedScale);
  if (localStorage.getItem('vo_contrast') === '1') document.body.classList.add('high-contrast');

  function setScale(s) {
    const clamped = Math.max(0.85, Math.min(1.6, s));
    root.style.setProperty('--text-scale', clamped);
    localStorage.setItem('vo_scale', String(clamped));
  }
  document.getElementById('text-bigger').addEventListener('click', () => setScale(parseFloat(getComputedStyle(root).getPropertyValue('--text-scale')) + 0.1));
  document.getElementById('text-smaller').addEventListener('click', () => setScale(parseFloat(getComputedStyle(root).getPropertyValue('--text-scale')) - 0.1));
  document.getElementById('contrast-toggle').addEventListener('click', () => {
    const on = document.body.classList.toggle('high-contrast');
    localStorage.setItem('vo_contrast', on ? '1' : '0');
  });

  // -------- voorbeelden --------
  let examplesLoaded = false;
  async function loadExamples() {
    if (examplesLoaded) return;
    const container = document.getElementById('voorbeelden-lijst');
    container.innerHTML = '<p class="muted">Bezig met laden…</p>';
    try {
      const items = await api('/examples');
      container.innerHTML = '';
      items.forEach((ex) => container.appendChild(renderExample(ex)));
      examplesLoaded = true;
    } catch (err) {
      container.innerHTML = '<p class="error">De voorbeelden konden niet geladen worden. Probeer het later nog eens.</p>';
    }
  }

  function renderExample(ex) {
    const wrap = document.createElement('article');
    wrap.className = 'example card';

    const head = document.createElement('div');
    head.className = 'example-head ' + ex.channel;
    head.innerHTML =
      '<span class="badge ' + ex.channel + '">' + channelLabel(ex.channel) + '</span>' +
      '<div class="from">Van: <strong>' + escapeHtml(ex.sender) + '</strong></div>' +
      (ex.subject ? '<div class="subj">Onderwerp: ' + escapeHtml(ex.subject) + '</div>' : '');
    wrap.appendChild(head);

    const body = document.createElement('div');
    body.className = 'example-body';
    body.innerHTML = annotateBody(ex.body, ex.annotations || []);
    wrap.appendChild(body);

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

  function annotateBody(text, annotations) {
    let html = escapeHtml(text).replace(/\n/g, '<br>');
    annotations.forEach((a, i) => {
      const q = escapeHtml(a.quote);
      const re = new RegExp(escapeRegExp(q), 'i');
      html = html.replace(re, '<mark class="phish-mark">' + q + '<sup class="dot">' + (i + 1) + '</sup></mark>');
    });
    return html;
  }

  // -------- Outlook-simulator --------
  let simState = null;

  async function startSimulator() {
    const list = document.getElementById('ol-list-items');
    const result = document.getElementById('sim-result');
    result.hidden = true;
    list.innerHTML = '<li class="ol-loading">Bezig met laden…</li>';

    try {
      const messages = await api('/inbox');
      simState = { messages, judgments: {}, current: null, interactions: {} };
      renderInboxList();
      updateProgress();
      resetReader();
    } catch (err) {
      list.innerHTML = '<li class="ol-loading error">Kon de inbox niet laden.</li>';
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
    prog.textContent = 'Voortgang: ' + done + ' van ' + total + ' beoordeeld';
  }

  function resetReader() {
    document.getElementById('ol-reader').innerHTML =
      '<div class="ol-reader-empty"><div class="ol-reader-empty-art">📬</div>' +
      '<p>Selecteer een bericht links om te beginnen.</p></div>';
  }

  async function openMessage(id) {
    simState.current = id;
    if (!simState.interactions[id]) simState.interactions[id] = { clicked_link: false, revealed_sender: false };
    renderInboxList();
    const reader = document.getElementById('ol-reader');
    reader.innerHTML = '<p class="muted">Laden…</p>';
    let m;
    try { m = await api('/inbox/' + id); }
    catch (_) { reader.innerHTML = '<p class="error">Bericht kon niet geladen worden.</p>'; return; }
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
              '<strong class="ol-msg-sender-name">' + escapeHtml(m.sender_name) + '</strong> ' +
              '<button class="ol-sender-reveal" type="button" aria-expanded="false">Toon adres</button>' +
            '</div>' +
            '<div class="ol-sender-address" hidden>' +
              '<span class="ol-sender-addr-text">&lt;' + escapeHtml(m.sender_address) + '&gt;</span>' +
            '</div>' +
            '<div class="ol-msg-time">Aan: u · ' + escapeHtml(m.received_label) + '</div>' +
          '</div>' +
        '</div>' +
      '</header>' +
      '<div class="ol-msg-body">' + renderBody(m.body, m.links || []) + '</div>' +
      (judged ? '<div class="ol-msg-actions judged"><p class="muted">U heeft dit bericht al beoordeeld.</p></div>'
              : '<div class="ol-msg-actions">' +
                  '<p class="ol-verdict-q">Wat vindt u van dit bericht?</p>' +
                  '<button class="btn btn-good big-btn" data-verdict="trust">✅ Ik vertrouw het</button>' +
                  '<button class="btn btn-bad  big-btn" data-verdict="phish">⚠️ Melden als phishing</button>' +
                '</div>');

    const revealBtn = reader.querySelector('.ol-sender-reveal');
    if (revealBtn) {
      revealBtn.addEventListener('click', () => {
        const addr = reader.querySelector('.ol-sender-address');
        const showing = !addr.hidden;
        addr.hidden = showing;
        revealBtn.textContent = showing ? 'Toon adres' : 'Verberg adres';
        revealBtn.setAttribute('aria-expanded', String(!showing));
        if (!showing) simState.interactions[m.id].revealed_sender = true;
      });
    }

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
    let html = escapeHtml(text).replace(/\n/g, '<br>');
    html = html.replace(/\{\{link:(\d+)\}\}/g, (_m, n) => {
      const idx = parseInt(n, 10);
      const link = links[idx];
      if (!link) return '';
      const label = escapeHtml(link.label || 'deze link');
      const url = escapeHtml(link.real_url || '');
      return '<a href="#" class="ol-link" data-link-idx="' + idx + '" ' +
             'title="Gaat naar: ' + url + '">' + label +
             ' <span class="ol-link-url" aria-hidden="true">(' + url + ')</span></a>';
    });
    return html;
  }

  function openLinkModal(link) {
    const bad = !!(link && link.suspicious);
    const url = link ? link.real_url : '';
    const warning = link ? (link.warning || '') : '';
    showModal({
      title: bad ? '⚠️ Let op — verdachte link' : 'Link openen?',
      variant: bad ? 'bad' : '',
      bodyHtml:
        '<p class="big-text">Deze link gaat naar:</p>' +
        '<p class="mono url-preview ' + (bad ? 'bad' : '') + '">' + escapeHtml(url) + '</p>' +
        (warning ? '<p class="tip-line">' + escapeHtml(warning) + '</p>' : '') +
        '<p>' + (bad
          ? '<strong>Klik niet op deze link.</strong> Sluit dit bericht en meld het als phishing.'
          : 'Tip: ook bij bekende organisaties is het veiliger om zelf naar hun website te gaan dan op links in e‑mail te klikken.') + '</p>',
      actions: [{ label: 'Sluiten', primary: true, close: true }],
    });
  }

  async function submitVerdict(m, verdict) {
    const reader = document.getElementById('ol-reader');
    reader.querySelectorAll('[data-verdict]').forEach((b) => b.disabled = true);

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
      reader.querySelectorAll('[data-verdict]').forEach((b) => b.disabled = false);
      showModal({
        title: 'Er ging iets mis',
        bodyHtml: '<p>Kon uw antwoord niet opslaan. Probeer het opnieuw.</p>',
        actions: [{ label: 'Sluiten', primary: true, close: true }],
      });
      return;
    }

    simState.judgments[m.id] = { verdict, correct: res.correct };
    renderInboxList();
    updateProgress();
    showVerdictFeedback(m, res);
  }

  function showVerdictFeedback(m, res) {
    const redFlags = (res.red_flags || []).map((s) => '<li>' + escapeHtml(s) + '</li>').join('');
    const greenFlags = (res.green_flags || []).map((s) => '<li>' + escapeHtml(s) + '</li>').join('');
    const senderNote = res.sender_note ? '<p><strong>Over het afzenderadres:</strong> ' + escapeHtml(res.sender_note) + '</p>' : '';

    showModal({
      title: res.correct ? '✅ Goed beoordeeld!' : '❌ Dat klopt niet.',
      variant: res.correct ? 'good' : 'bad',
      bodyHtml:
        '<p><strong>Het juiste antwoord:</strong> ' + (res.is_phishing ? 'dit is phishing.' : 'dit is een echt bericht.') + '</p>' +
        '<p>' + escapeHtml(res.explanation) + '</p>' +
        senderNote +
        (redFlags ? '<p><strong>Rode vlaggen:</strong></p><ul class="check-list">' + redFlags + '</ul>' : '') +
        (greenFlags ? '<p><strong>Groene vlaggen:</strong></p><ul class="check-list">' + greenFlags + '</ul>' : ''),
      actions: [
        { label: allJudged() ? 'Bekijk uw resultaat →' : 'Volgende bericht →',
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
    if (next) openMessage(next.id);
    else resetReader();
  }

  function finishSimulator() {
    resetReader();
    const result = document.getElementById('sim-result');
    const total = simState.messages.length;
    const correct = Object.values(simState.judgments).filter((j) => j.correct).length;
    const pct = Math.round((correct / total) * 100);
    let titel, advies;
    if (pct === 100)    { titel = 'Perfect! 🎉';          advies = 'U herkende alle berichten goed. Blijf alert bij echte e‑mail.'; }
    else if (pct >= 80) { titel = 'Heel goed gedaan! 👍'; advies = 'U weet bijna alles. Bekijk de uitleg van de berichten die u miste nog eens.'; }
    else if (pct >= 60) { titel = 'Goede start.';         advies = 'Oefen de simulator gerust nog een keer. Herhaling helpt.'; }
    else                 { titel = 'Geen zorgen.';         advies = 'Phishing is lastig. Bekijk de lesjes en voorbeelden, en probeer het opnieuw.'; }

    result.innerHTML =
      '<h2>' + titel + '</h2>' +
      '<p class="big-text">U beoordeelde <strong>' + correct + ' van de ' + total + '</strong> berichten goed (' + pct + '%).</p>' +
      '<p>' + advies + '</p>' +
      '<div class="actions">' +
        '<button class="btn btn-primary" id="sim-again">Opnieuw oefenen</button>' +
        '<button class="btn btn-secondary" data-go="hulp">Bekijk hulp en tips</button>' +
      '</div>';
    result.hidden = false;
    document.getElementById('sim-again').addEventListener('click', startSimulator);
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
