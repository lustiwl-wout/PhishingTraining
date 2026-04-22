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
  const pages = ['welkom', 'leren', 'voorbeelden', 'quiz', 'hulp'];

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
    if (step === 'quiz') startQuiz();
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

  // -------- quiz --------
  let quizState = null;

  async function startQuiz() {
    const card = document.getElementById('quiz-card');
    const result = document.getElementById('quiz-result');
    const feedback = document.getElementById('quiz-feedback');
    const next = document.getElementById('quiz-next');
    result.hidden = true;
    feedback.hidden = true;
    next.hidden = true;
    card.innerHTML = '<p class="muted">Bezig met laden…</p>';

    try {
      const [questions, attempt] = await Promise.all([
        api('/quiz?limit=5'),
        api('/attempts', { method: 'POST', body: JSON.stringify({ session_id: getSessionId() }) }),
      ]);
      quizState = { questions, index: 0, attempt, correct: 0 };
      renderQuestion();
    } catch (err) {
      card.innerHTML = '<p class="error">De quiz kon niet geladen worden. Controleer of de database bereikbaar is en probeer opnieuw.</p>';
    }
  }

  function renderQuestion() {
    const card = document.getElementById('quiz-card');
    const progress = document.getElementById('quiz-progress');
    const feedback = document.getElementById('quiz-feedback');
    const next = document.getElementById('quiz-next');
    feedback.hidden = true;
    next.hidden = true;

    const q = quizState.questions[quizState.index];
    progress.textContent = 'Vraag ' + (quizState.index + 1) + ' van ' + quizState.questions.length;

    card.innerHTML =
      '<div class="example-head ' + q.channel + '">' +
        '<span class="badge ' + q.channel + '">' + channelLabel(q.channel) + '</span>' +
        '<div class="from">Van: <strong>' + escapeHtml(q.sender) + '</strong></div>' +
        (q.subject ? '<div class="subj">Onderwerp: ' + escapeHtml(q.subject) + '</div>' : '') +
      '</div>' +
      '<div class="example-body">' + escapeHtml(q.body).replace(/\n/g, '<br>') + '</div>' +
      '<div class="quiz-choices">' +
        '<button class="btn btn-good big-btn" data-answer="false">✅ Veilig</button>' +
        '<button class="btn btn-bad  big-btn" data-answer="true">⚠️ Phishing</button>' +
      '</div>';

    card.querySelectorAll('[data-answer]').forEach((b) => {
      b.addEventListener('click', () => answer(b.dataset.answer === 'true'));
    });
  }

  async function answer(saidPhishing) {
    const q = quizState.questions[quizState.index];
    const feedback = document.getElementById('quiz-feedback');
    const next = document.getElementById('quiz-next');

    document.querySelectorAll('#quiz-card [data-answer]').forEach((b) => b.disabled = true);

    let serverSays = null;
    try {
      serverSays = await api('/attempts/' + quizState.attempt.id + '/answers', {
        method: 'POST',
        body: JSON.stringify({ question_id: q.id, answered_phishing: saidPhishing }),
      });
    } catch (_) {
      // Bij netwerkfout valt de evaluatie terug op de lokaal bekende vraagdata
      serverSays = { correct: saidPhishing === q.is_phishing, was_phishing: q.is_phishing };
    }

    if (serverSays.correct) quizState.correct++;

    const signsHtml = (q.signs || []).map((s) => '<li>' + escapeHtml(s) + '</li>').join('');
    feedback.className = 'feedback ' + (serverSays.correct ? 'good' : 'bad');
    feedback.innerHTML =
      '<h3>' + (serverSays.correct ? 'Goed gedaan!' : 'Helaas, dit was niet juist.') + '</h3>' +
      '<p><strong>Het juiste antwoord:</strong> ' + (serverSays.was_phishing ? 'phishing' : 'veilig') + '.</p>' +
      '<p>' + escapeHtml(q.explanation) + '</p>' +
      (signsHtml ? '<p><strong>Waar u op kunt letten:</strong></p><ul class="check-list">' + signsHtml + '</ul>' : '');
    feedback.hidden = false;

    next.hidden = false;
    next.textContent = (quizState.index + 1 >= quizState.questions.length) ? 'Bekijk uw resultaat →' : 'Volgende →';
    next.focus();
  }

  document.getElementById('quiz-next').addEventListener('click', async () => {
    quizState.index++;
    if (quizState.index >= quizState.questions.length) {
      await finishQuiz();
    } else {
      renderQuestion();
    }
  });

  async function finishQuiz() {
    const card = document.getElementById('quiz-card');
    const feedback = document.getElementById('quiz-feedback');
    const next = document.getElementById('quiz-next');
    const result = document.getElementById('quiz-result');
    card.innerHTML = '';
    feedback.hidden = true;
    next.hidden = true;

    try { await api('/attempts/' + quizState.attempt.id + '/finish', { method: 'POST' }); } catch (_) {}

    const total = quizState.questions.length;
    const pct = Math.round((quizState.correct / total) * 100);
    let titel, advies;
    if (pct === 100)      { titel = 'Perfect! 🎉';            advies = 'U herkent phishing uitstekend. Blijf wel altijd alert.'; }
    else if (pct >= 80)   { titel = 'Heel knap gedaan! 👍';   advies = 'U weet bijna alles. Bekijk de uitleg van de vraag die u miste nog eens.'; }
    else if (pct >= 60)   { titel = 'Goede start.';            advies = 'U herkent het vaak. Doe de quiz nog een keer, dan onthoudt u het beter.'; }
    else                  { titel = 'Geen zorgen.';            advies = 'Phishing is lastig. Bekijk de uitleg en de tips, en doe de quiz nog een keer.'; }

    result.innerHTML =
      '<h2>' + titel + '</h2>' +
      '<p class="big-text">U had <strong>' + quizState.correct + ' van de ' + total + '</strong> goed (' + pct + '%).</p>' +
      '<p>' + advies + '</p>' +
      '<div class="actions">' +
        '<button class="btn btn-primary" data-go="quiz">Nog een keer oefenen</button>' +
        '<button class="btn btn-secondary" data-go="hulp">Bekijk hulp en tips</button>' +
      '</div>';
    result.hidden = false;
  }

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
