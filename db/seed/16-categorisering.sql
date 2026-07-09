-- ===========================================================================
-- Fase 6 — Categorisering t.b.v. het persoonlijke risicoprofiel.
-- Elk bericht krijgt een thematische categorie. De UPDATEs lopen van
-- algemeen naar specifiek: latere statements mogen eerdere overschrijven.
-- Vaste set sleutels (sturen de i18n in locales.js): bank, overheid,
-- bezorger, account, marktplaats, ceo, familie, overig (= standaard).
-- Gematcht op sender_address / sender_name / subject met ILIKE, zodat alle
-- 6 talen in één keer worden meegenomen.
-- ===========================================================================

-- ---- bank / betaaldiensten ----
UPDATE inbox_messages SET category = 'bank' WHERE
     sender_address ILIKE '%ing-%' OR sender_address ILIKE '%rabobank%'
  OR sender_address ILIKE '%abnamro%' OR sender_address ILIKE '%belfius%'
  OR sender_address ILIKE '%bnp-%' OR sender_address ILIKE '%credit-agricole%'
  OR sender_address ILIKE '%barclays%' OR sender_address ILIKE '%sparkasse%'
  OR sender_address ILIKE '%volksbank%' OR sender_address ILIKE '%paypal%'
  OR sender_address ILIKE '%tikkie%' OR sender_address ILIKE '%payconiq%'
  OR sender_name ILIKE 'ING%' OR sender_name ILIKE 'ABN AMRO%'
  OR sender_name ILIKE 'Rabobank%' OR sender_name ILIKE 'Belfius%'
  OR sender_name ILIKE 'BNP Paribas%' OR sender_name ILIKE 'Crédit Agricole%'
  OR sender_name ILIKE 'Barclays%' OR sender_name ILIKE 'Sparkasse%'
  OR sender_name ILIKE 'Volksbank%' OR sender_name ILIKE 'PayPal%'
  OR sender_name ILIKE 'Tikkie%' OR sender_name ILIKE 'Payconiq%'
  OR sender_name = 'Banque';

-- ---- overheid / belastingen / authenticatie-overheid ----
UPDATE inbox_messages SET category = 'overheid' WHERE
     sender_address ILIKE '%belasting%' OR sender_address ILIKE '%minfin%'
  OR sender_address ILIKE '%impots%' OR sender_address ILIKE '%impôts%'
  OR sender_address ILIKE '%finanzamt%' OR sender_address ILIKE '%steuer%'
  OR sender_address ILIKE '%hmrc%' OR sender_address ILIKE '%gov-uk%'
  OR sender_address ILIKE '%gov.uk%' OR sender_address ILIKE '%digid%'
  OR sender_address ILIKE '%itsme-%' OR sender_address ILIKE '%elster%'
  OR sender_address ILIKE '%ameli%' OR sender_name ILIKE 'Belastingdienst%'
  OR sender_name ILIKE 'FOD Financiën%' OR sender_name ILIKE 'SPF Finances%'
  OR sender_name ILIKE 'Impôts%' OR sender_name ILIKE 'Finanzamt%'
  OR sender_name ILIKE 'HMRC%' OR sender_name ILIKE 'HM Revenue%'
  OR sender_name ILIKE 'DigiD%' OR sender_name ILIKE 'itsme%'
  OR sender_name ILIKE 'ELSTER%' OR sender_name ILIKE 'GOV.UK%'
  OR sender_name ILIKE 'Bundeszentralamt%' OR sender_name ILIKE 'Direction Générale des Finances%'
  OR sender_name ILIKE 'Ameli%' OR sender_name ILIKE 'Assurance Maladie%'
  OR sender_name = 'CJIB';

-- ---- bezorger / pakketten ----
UPDATE inbox_messages SET category = 'bezorger' WHERE
     sender_address ILIKE '%postnl%' OR sender_address ILIKE '%dhl-%'
  OR sender_address ILIKE '%dhl-paket%' OR sender_address ILIKE '%bpost-%'
  OR sender_address ILIKE '%royalmail%' OR sender_address ILIKE '%royal-mail%'
  OR sender_address ILIKE '%colissimo%' OR sender_address ILIKE '%laposte%'
  OR sender_name ILIKE 'PostNL%' OR sender_name ILIKE 'DHL%'
  OR sender_name ILIKE 'bpost%' OR sender_name ILIKE 'Royal Mail%'
  OR sender_name ILIKE 'Chronopost%' OR sender_name ILIKE 'Colissimo%'
  OR sender_name ILIKE 'La Poste%';

-- ---- account / tech / login ----
UPDATE inbox_messages SET category = 'account' WHERE
     sender_address ILIKE '%microsoft%' OR sender_address ILIKE '%sharepoint%'
  OR sender_address ILIKE '%apple-%' OR sender_address ILIKE '%mfa-%'
  OR sender_address ILIKE '%device-check%' OR sender_address ILIKE '%docusign%'
  OR sender_address ILIKE '%kestrel-access%' OR sender_address ILIKE '%kestrel-helpdesk%'
  OR sender_name ILIKE 'Microsoft%' OR sender_name ILIKE 'Apple%'
  OR sender_name ILIKE 'DocuSign%' OR sender_name ILIKE 'IT Support%'
  OR sender_name ILIKE 'IT-Security%' OR sender_name ILIKE 'IT Security%'
  OR sender_name ILIKE 'IT-Sicherheit%' OR sender_name ILIKE 'Sécurité informatique%'
  OR sender_name ILIKE 'Support Informatique%' OR sender_name ILIKE 'Licences Microsoft%'
  OR sender_name ILIKE 'Licenties Microsoft%'
  OR subject ILIKE '%wachtwoord verloopt%' OR subject ILIKE '%paswoord verloopt%'
  OR subject ILIKE '%password expires%' OR subject ILIKE '%mot de passe expire%'
  OR subject ILIKE '%Passwort läuft%' OR subject ILIKE '%VPN%'
  OR sender_name IN ('Verify','CodeAcces','Zugangscode')
  OR (sender_name = 'Delivery' AND channel = 'whatsapp');

-- ---- marktplaats / tweedehands ----
UPDATE inbox_messages SET category = 'marktplaats' WHERE
     sender_name ILIKE '%Marktplaats%' OR sender_name ILIKE '%2dehands%'
  OR sender_name ILIKE '%2ememain%' OR sender_name ILIKE '%Leboncoin%'
  OR sender_name ILIKE '%Kleinanzeigen%';

-- ---- familie / vriend-in-nood ("nieuw nummer", "hi mum") ----
UPDATE inbox_messages SET category = 'familie' WHERE
  channel = 'whatsapp' AND sender_name IN
    ('Onbekend nummer','Unknown number','Numéro inconnu','Unbekannte Nummer');

-- ---- CEO-fraude / zakelijke spear-phishing ----
-- Specifiek genoeg om eerdere (account/bank) overschrijvingen te corrigeren:
-- factuurfraude, leverancier-rekeningwijziging en de geavanceerde AI-scenario's.
UPDATE inbox_messages SET category = 'ceo' WHERE
     sender_name ILIKE '%(CEO)%' OR sender_address ILIKE '%kestrel-group%'
  OR sender_address ILIKE '%kestrel-finance%' OR sender_address ILIKE '%vertexron%'
  OR sender_address ILIKE '%printservice%' OR sender_address ILIKE '%imprimerie-services%'
  OR sender_address ILIKE '%print-services%' OR sender_address ILIKE '%druckservice%'
  OR sender_address ILIKE '%premium-talent%'
  OR (sender_name = 'Mark de Vries' AND is_phishing = TRUE)
  OR (sender_name = 'Marc Dupont' AND is_phishing = TRUE);


