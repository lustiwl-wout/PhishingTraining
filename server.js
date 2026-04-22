require('dotenv').config();
const path = require('path');
const express = require('express');
const apiRouter = require('./routes/api');
const { initDbWithRetry } = require('./db/init');

const app = express();
const PORT = process.env.PORT || 3000;

app.disable('x-powered-by');
app.use(express.json({ limit: '64kb' }));

// Statische frontend
app.use(express.static(path.join(__dirname, 'public'), {
  extensions: ['html'],
  maxAge: process.env.NODE_ENV === 'production' ? '1h' : 0,
}));

// API
app.use('/api', apiRouter);

// Fallback voor onbekende routes -> SPA-startpagina
app.get('*', (_req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Centrale foutafhandeling
app.use((err, _req, res, _next) => {
  console.error('[server]', err);
  res.status(500).json({ error: 'er ging iets mis op de server' });
});

app.listen(PORT, () => {
  console.log(`[server] Veilig Online luistert op poort ${PORT}`);

  // Auto-init de database (idempotent). Op Render Free hebben we geen
  // Shell, dus dit is de manier om schema + seed binnen te krijgen.
  // Kan via SKIP_DB_INIT=1 worden uitgezet.
  if (process.env.SKIP_DB_INIT === '1') {
    console.log('[server] SKIP_DB_INIT=1 — database-init overgeslagen.');
    return;
  }
  initDbWithRetry().catch((err) => {
    console.error('[server] init-db onverwachte fout:', err);
  });
});
