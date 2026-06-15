-- Schema voor de Veilig Online phishing-training.
-- Idempotent: kan meermaals worden uitgevoerd.

-- Legacy quiz-subsysteem opruimen. De oude multiple-choice quiz is vervangen
-- door de inbox-simulator (inbox_messages). De drie quiz-tabellen werden niet
-- meer gevuld of door de frontend gebruikt. CASCADE ruimt de FK's mee op.
DROP TABLE IF EXISTS quiz_answers, quiz_attempts, quiz_questions CASCADE;

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
-- Kanaal: maakt naast e-mail ook sms/whatsapp (smishing) en telefoon (vishing)
-- mogelijk binnen dezelfde simulator-engine. Bestaande rijen blijven 'email'.
ALTER TABLE inbox_messages ADD COLUMN IF NOT EXISTS channel TEXT NOT NULL DEFAULT 'email';
-- Categorie: thematische groep van het bericht (bank, overheid, bezorger,
-- account, marktplaats, ceo, familie, overig). Voedt het persoonlijke
-- risicoprofiel op het resultaatscherm. Bestaande rijen blijven 'overig'.
ALTER TABLE inbox_messages ADD COLUMN IF NOT EXISTS category TEXT NOT NULL DEFAULT 'overig';
CREATE INDEX IF NOT EXISTS idx_inbox_messages_locale ON inbox_messages(locale);
CREATE INDEX IF NOT EXISTS idx_inbox_messages_audience ON inbox_messages(audience);
CREATE INDEX IF NOT EXISTS idx_inbox_messages_difficulty ON inbox_messages(difficulty);
CREATE INDEX IF NOT EXISTS idx_inbox_messages_channel ON inbox_messages(channel);
CREATE INDEX IF NOT EXISTS idx_inbox_messages_category ON inbox_messages(category);

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

-- QR-scans uit oefenmails ("quishing"): wie de QR-code écht scant met zijn
-- telefoon, komt op /qr terecht — dat registreren we hier per sessie.
CREATE TABLE IF NOT EXISTS qr_scans (
  id          SERIAL PRIMARY KEY,
  session_id  TEXT        NOT NULL,
  tag         TEXT        NOT NULL,
  scanned_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (session_id, tag)
);
CREATE INDEX IF NOT EXISTS idx_qr_scans_session ON qr_scans(session_id);

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
ALTER TABLE organisations ADD COLUMN IF NOT EXISTS difficulty TEXT NOT NULL DEFAULT 'normal';
ALTER TABLE organisations ADD COLUMN IF NOT EXISTS modules  TEXT[] NOT NULL DEFAULT ARRAY['leren','simulator','kanalen','hulp','wachtwoord'];
ALTER TABLE organisations ADD COLUMN IF NOT EXISTS channels TEXT[] NOT NULL DEFAULT ARRAY['sms','whatsapp','phone'];
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

-- Enterprise: voortgangsgeheugen server-side per training-ronde (anoniem, aan org_user_id).
-- Vervangt de localStorage-aanpak voor zakelijke gebruikers: géén persoonsgegevens,
-- alleen een anoniem intern ID, tijdstip, totaal/correct en of het een opfrisoefening was.
CREATE TABLE IF NOT EXISTS user_completions (
  id              SERIAL PRIMARY KEY,
  org_user_id     INTEGER     NOT NULL REFERENCES org_users(id) ON DELETE CASCADE,
  session_id      TEXT        NOT NULL,
  completed_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  total_messages  INTEGER     NOT NULL DEFAULT 0,
  correct_count   INTEGER     NOT NULL DEFAULT 0,
  was_refresher   BOOLEAN     NOT NULL DEFAULT FALSE
);
CREATE INDEX IF NOT EXISTS idx_user_completions_org_user ON user_completions(org_user_id);

-- Enterprise: verdiende badges per gebruiker (deduplicaat via UNIQUE).
CREATE TABLE IF NOT EXISTS user_badges (
  id            SERIAL PRIMARY KEY,
  org_user_id   INTEGER     NOT NULL REFERENCES org_users(id) ON DELETE CASCADE,
  badge         TEXT        NOT NULL,
  earned_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(org_user_id, badge)
);
CREATE INDEX IF NOT EXISTS idx_user_badges_org_user ON user_badges(org_user_id);

-- Lightweight visitor analytics: no personal data, no cookies beyond existing session.
CREATE TABLE IF NOT EXISTS analytics_events (
  id         SERIAL PRIMARY KEY,
  event      TEXT        NOT NULL,
  lang       TEXT        NOT NULL DEFAULT '',
  audience   TEXT        NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_analytics_events_created ON analytics_events(created_at);
CREATE INDEX IF NOT EXISTS idx_analytics_events_event   ON analytics_events(event);
