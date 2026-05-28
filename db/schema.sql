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
  locale        TEXT        NOT NULL DEFAULT 'nl',
  channel       TEXT        NOT NULL CHECK (channel IN ('email', 'sms', 'whatsapp')),
  sender        TEXT        NOT NULL,
  subject       TEXT,
  body          TEXT        NOT NULL,
  annotations   JSONB       NOT NULL DEFAULT '[]'::jsonb,
  sort_order    INTEGER     NOT NULL DEFAULT 0,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Bestaande installaties: kolom achteraf toevoegen (idempotent).
ALTER TABLE examples ADD COLUMN IF NOT EXISTS locale TEXT NOT NULL DEFAULT 'nl';
ALTER TABLE examples ADD COLUMN IF NOT EXISTS audience TEXT NOT NULL DEFAULT 'personal';
CREATE INDEX IF NOT EXISTS idx_examples_locale ON examples(locale);
CREATE INDEX IF NOT EXISTS idx_examples_audience ON examples(audience);

CREATE TABLE IF NOT EXISTS quiz_attempts (
  id            SERIAL PRIMARY KEY,
  session_id    TEXT        NOT NULL,
  started_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  finished_at   TIMESTAMPTZ,
  total         INTEGER     NOT NULL DEFAULT 0,
  correct       INTEGER     NOT NULL DEFAULT 0
);

ALTER TABLE quiz_attempts ADD COLUMN IF NOT EXISTS ip_address TEXT;
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

-- Outlook-achtige e-mailsimulator: rijkere berichten met knopbare links,
-- herkenbare afzenders en een expliciete uitleg achteraf.
CREATE TABLE IF NOT EXISTS inbox_messages (
  id              SERIAL PRIMARY KEY,
  locale          TEXT        NOT NULL DEFAULT 'nl',
  sender_name     TEXT        NOT NULL,
  sender_address  TEXT        NOT NULL,
  sender_note     TEXT,
  received_label  TEXT        NOT NULL DEFAULT 'vandaag',
  subject         TEXT        NOT NULL,
  preview         TEXT,
  body            TEXT        NOT NULL,
  links           JSONB       NOT NULL DEFAULT '[]'::jsonb,
  attachments     JSONB       NOT NULL DEFAULT '[]'::jsonb,
  is_phishing     BOOLEAN     NOT NULL,
  red_flags       JSONB       NOT NULL DEFAULT '[]'::jsonb,
  green_flags     JSONB       NOT NULL DEFAULT '[]'::jsonb,
  explanation     TEXT        NOT NULL,
  sort_order      INTEGER     NOT NULL DEFAULT 0,
  active          BOOLEAN     NOT NULL DEFAULT TRUE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE inbox_messages ADD COLUMN IF NOT EXISTS locale TEXT NOT NULL DEFAULT 'nl';
ALTER TABLE inbox_messages ADD COLUMN IF NOT EXISTS audience TEXT NOT NULL DEFAULT 'personal';
ALTER TABLE inbox_messages ADD COLUMN IF NOT EXISTS difficulty TEXT NOT NULL DEFAULT 'normal';
CREATE INDEX IF NOT EXISTS idx_inbox_messages_locale ON inbox_messages(locale);
CREATE INDEX IF NOT EXISTS idx_inbox_messages_audience ON inbox_messages(audience);
CREATE INDEX IF NOT EXISTS idx_inbox_messages_difficulty ON inbox_messages(difficulty);

CREATE TABLE IF NOT EXISTS inbox_judgments (
  id              SERIAL PRIMARY KEY,
  session_id      TEXT        NOT NULL,
  message_id      INTEGER     NOT NULL REFERENCES inbox_messages(id),
  verdict         TEXT        NOT NULL CHECK (verdict IN ('trust', 'phish')),
  is_correct      BOOLEAN     NOT NULL,
  clicked_link    BOOLEAN     NOT NULL DEFAULT FALSE,
  revealed_sender BOOLEAN     NOT NULL DEFAULT FALSE,
  answered_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE inbox_judgments ADD COLUMN IF NOT EXISTS ip_address TEXT;
CREATE INDEX IF NOT EXISTS idx_inbox_judgments_session ON inbox_judgments(session_id);

CREATE TABLE IF NOT EXISTS easter_egg_views (
  id          SERIAL PRIMARY KEY,
  session_id  TEXT        NOT NULL,
  ip_address  TEXT,
  viewed_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS simulator_starts (
  id          SERIAL PRIMARY KEY,
  session_id  TEXT        NOT NULL,
  ip_address  TEXT,
  started_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
