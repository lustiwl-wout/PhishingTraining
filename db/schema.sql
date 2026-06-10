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
ALTER TABLE inbox_judgments ADD COLUMN IF NOT EXISTS difficulty TEXT NOT NULL DEFAULT 'normal';
ALTER TABLE inbox_judgments ADD COLUMN IF NOT EXISTS org_user_id INTEGER;
CREATE INDEX IF NOT EXISTS idx_inbox_judgments_session ON inbox_judgments(session_id);
CREATE INDEX IF NOT EXISTS idx_inbox_judgments_org_user ON inbox_judgments(org_user_id);
CREATE INDEX IF NOT EXISTS idx_inbox_judgments_message  ON inbox_judgments(message_id);
CREATE INDEX IF NOT EXISTS idx_inbox_judgments_org_user_message ON inbox_judgments(org_user_id, message_id);

-- Eén oordeel per sessie per bericht: voorkomt dubbele rijen bij hertraining
-- en spam-inserts. Bestaande duplicaten worden eerst opgeruimd (oudste blijft,
-- dat is consistent met de "eerste oordeel telt"-statistieken).
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'uq_inbox_judgments_session_message'
  ) THEN
    DELETE FROM inbox_judgments a USING inbox_judgments b
      WHERE a.session_id = b.session_id AND a.message_id = b.message_id AND a.id > b.id;
    ALTER TABLE inbox_judgments
      ADD CONSTRAINT uq_inbox_judgments_session_message UNIQUE (session_id, message_id);
  END IF;
END $$;

-- ── Enterprise tables ──────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS organisations (
  id           SERIAL PRIMARY KEY,
  name         TEXT        NOT NULL,
  slug         TEXT        NOT NULL UNIQUE,
  email_domain TEXT,
  locales      TEXT[]      NOT NULL DEFAULT ARRAY['nl','nl-BE','en','fr','fr-BE','de'],
  audiences    TEXT[]      NOT NULL DEFAULT ARRAY['personal','business'],
  difficulties TEXT[]      NOT NULL DEFAULT ARRAY['normal','advanced'],
  max_users    INTEGER     NOT NULL DEFAULT 50,
  valid_until  DATE        NOT NULL,
  admin_token  TEXT        NOT NULL UNIQUE,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE organisations ADD COLUMN IF NOT EXISTS email_domain TEXT;
CREATE INDEX IF NOT EXISTS idx_organisations_slug        ON organisations(slug);
CREATE INDEX IF NOT EXISTS idx_organisations_admin_token ON organisations(admin_token);

CREATE TABLE IF NOT EXISTS org_users (
  id               SERIAL PRIMARY KEY,
  org_id           INTEGER     NOT NULL REFERENCES organisations(id) ON DELETE CASCADE,
  numeric_id       TEXT        NOT NULL,
  pincode_hash     TEXT        NOT NULL,
  allow_retrain    BOOLEAN     NOT NULL DEFAULT FALSE,
  failed_attempts  INTEGER     NOT NULL DEFAULT 0,
  locked_until     TIMESTAMPTZ,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (org_id, numeric_id)
);
CREATE INDEX IF NOT EXISTS idx_org_users_org_id ON org_users(org_id);

CREATE TABLE IF NOT EXISTS org_sessions (
  id           SERIAL PRIMARY KEY,
  org_user_id  INTEGER     NOT NULL REFERENCES org_users(id) ON DELETE CASCADE,
  session_id   TEXT        NOT NULL UNIQUE,
  started_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_active  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_org_sessions_session_id  ON org_sessions(session_id);
CREATE INDEX IF NOT EXISTS idx_org_sessions_org_user_id ON org_sessions(org_user_id);

-- FK van inbox_judgments → org_users (pas toevoegen als tabel bestaat)
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'inbox_judgments_org_user_id_fkey'
  ) THEN
    ALTER TABLE inbox_judgments
      ADD CONSTRAINT inbox_judgments_org_user_id_fkey
      FOREIGN KEY (org_user_id) REFERENCES org_users(id);
  END IF;
END $$;

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
