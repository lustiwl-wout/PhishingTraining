-- Schema voor de Veilig Online phishing-training.
-- Idempotent: kan meermaals worden uitgevoerd.

CREATE TABLE IF NOT EXISTS quiz_questions (
  id            SERIAL PRIMARY KEY,
  channel       TEXT        NOT NULL CHECK (channel IN ('email', 'sms', 'whatsapp')),
  sender        TEXT        NOT NULL,
  subject       TEXT,
  body          TEXT        NOT NULL,
  is_phishing   BOOLEAN     NOT NULL,
  explanation   TEXT        NOT NULL,
  signs         JSONB       NOT NULL DEFAULT '[]'::jsonb,
  difficulty    INTEGER     NOT NULL DEFAULT 1,
  active        BOOLEAN     NOT NULL DEFAULT TRUE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS examples (
  id            SERIAL PRIMARY KEY,
  channel       TEXT        NOT NULL CHECK (channel IN ('email', 'sms', 'whatsapp')),
  sender        TEXT        NOT NULL,
  subject       TEXT,
  body          TEXT        NOT NULL,
  annotations   JSONB       NOT NULL DEFAULT '[]'::jsonb,
  sort_order    INTEGER     NOT NULL DEFAULT 0,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS quiz_attempts (
  id            SERIAL PRIMARY KEY,
  session_id    TEXT        NOT NULL,
  started_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  finished_at   TIMESTAMPTZ,
  total         INTEGER     NOT NULL DEFAULT 0,
  correct       INTEGER     NOT NULL DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_quiz_attempts_session ON quiz_attempts(session_id);

CREATE TABLE IF NOT EXISTS quiz_answers (
  id              SERIAL PRIMARY KEY,
  attempt_id      INTEGER     NOT NULL REFERENCES quiz_attempts(id) ON DELETE CASCADE,
  question_id     INTEGER     NOT NULL REFERENCES quiz_questions(id),
  answered_phishing BOOLEAN   NOT NULL,
  is_correct      BOOLEAN     NOT NULL,
  answered_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_quiz_answers_attempt ON quiz_answers(attempt_id);
