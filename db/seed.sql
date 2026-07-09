-- Seed data: realistische voorbeelden van phishing en echte berichten,
-- in vier talen (nl, en, fr, de). Elke taal gebruikt organisaties die voor
-- dat land herkenbaar zijn (NL: ING/Belastingdienst, UK: Barclays/HMRC,
-- FR: Crédit Agricole/Impôts, DE: Sparkasse/Finanzamt, ...).
-- Verwijder eerst bestaande content zodat seed herhaalbaar is.
-- Gebruikersdata wordt bewaard door init.js (save/restore rondom deze seed).

TRUNCATE examples, inbox_messages RESTART IDENTITY CASCADE;

-- ============ VOORBEELDEN (geannoteerd) ============

INSERT INTO examples (channel, sender, subject, body, annotations, sort_order)
SELECT 'email', sender, subject, body, annotations::jsonb, sort_order
FROM (VALUES
('ING Service <service@ing-betaling-secure.com>',
 'Belangrijk: uw rekening wordt geblokkeerd',
 E'Geachte klant,\n\nWij hebben een verdachte transactie op uw rekening opgemerkt. Binnen 24 uur wordt uw rekening GEBLOKKEERD als u uw gegevens niet bevestigt.\n\nKlik hier om uw rekening te beveiligen: http://ing-beveiliging.net/login\n\nMet vriendelijke groet,\nING Beveiligingsteam',
 '[{"quote": "service@ing-betaling-secure.com", "note": "Kijk naar wat NA de @ staat: ing-betaling-secure.com. Dat is niet ING. De echte ING gebruikt altijd @ing.nl. Het deel vóór de @ (\"service\") mag de oplichter zelf verzinnen."}, {"quote": "GEBLOKKEERD als u uw gegevens niet bevestigt", "note": "Angst maken en haast. Een echte bank doet dit nooit."}, {"quote": "Geachte klant", "note": "Geen naam. Uw bank kent uw naam."}, {"quote": "http://ing-beveiliging.net/login", "note": "Vreemde link die niet van ING is. Niet op klikken!"}]',
 10),

('Belastingdienst <noreply@belasting-teruggave.nl>',
 'U heeft recht op € 423,50 teruggave',
 E'Beste burger,\n\nNa controle blijkt u recht te hebben op een belastingteruggave van € 423,50. Vul snel uw gegevens in om het bedrag te ontvangen.\n\nKlik hier: http://belasting-teruggave.nl/claim\n\nBelastingdienst',
 '[{"quote": "noreply@belasting-teruggave.nl", "note": "Kijk na de @: belasting-teruggave.nl. Dat is NIET de Belastingdienst. Het echte domein is belastingdienst.nl."}, {"quote": "Beste burger", "note": "Algemene aanhef zonder uw naam. De Belastingdienst weet wie u bent."}, {"quote": "recht te hebben op een belastingteruggave van € 423,50", "note": "Belofte van geld is een klassieke lokker. De Belastingdienst mailt nooit over teruggaven."}, {"quote": "http://belasting-teruggave.nl/claim", "note": "Vreemde link, niet mijn.belastingdienst.nl. Niet op klikken."}]',
 20),

('DigiD <info@digid-controle.org>',
 'Bevestig uw DigiD-gegevens',
 E'Geachte heer/mevrouw,\n\nWij vragen u om uw DigiD opnieuw te bevestigen. Klik op onderstaande link en log in met uw gebruikersnaam en wachtwoord.\n\nhttp://digid-controle.org/inloggen\n\nBedankt,\nDigiD',
 '[{"quote": "info@digid-controle.org", "note": "Kijk na de @: digid-controle.org. Het echte domein is digid.nl — niets anders."}, {"quote": "Geachte heer/mevrouw", "note": "Algemene aanhef. Een echte organisatie kent uw naam."}, {"quote": "log in met uw gebruikersnaam en wachtwoord", "note": "DigiD vraagt NOOIT per e-mail om uw wachtwoord. Altijd phishing."}, {"quote": "http://digid-controle.org/inloggen", "note": "Vreemde link. Open DigiD alleen via digid.nl of de officiële app."}]',
 30)
) AS t(sender, subject, body, annotations, sort_order);

-- ============ OUTLOOK-SIMULATOR BERICHTEN ============
-- Mix van 5 phishing en 5 echte berichten.
-- Body gebruikt {{link:N}} als placeholder voor link index N uit `links`.
-- Elke link heeft: label (zichtbare tekst), real_url (echte bestemming),
-- suspicious, warning (extra uitleg in de pop-up).

INSERT INTO inbox_messages
  (sender_name, sender_address, sender_note, received_label, subject, preview, body, links, is_phishing, red_flags, green_flags, explanation, sort_order) VALUES

-- 1. PHISHING — ING
('ING Bank',
 'service@ing-betaling-secure.com',
 'Kijk na de @: ing-betaling-secure.com. De echte ING gebruikt altijd @ing.nl.',
 'vandaag 08:42',
 'Belangrijk: uw rekening wordt geblokkeerd',
 'Geachte klant, wij hebben een verdachte transactie opgemerkt op uw...',
 E'<div class="eml fam-bank" style="--brand:#ff6200;--cta:#ff6200;--logo:#d65200"><div class="eml-top"><span class="eml-logo">ING</span></div><div class="eml-body"><p class="eml-h">Verdachte transactie opgemerkt</p><p>Geachte klant,</p><p>Wij hebben een verdachte transactie opgemerkt op uw rekening. Om misbruik te voorkomen wordt uw rekening binnen 24 uur <strong>GEBLOKKEERD</strong> als u uw gegevens niet bevestigt.</p><div class="eml-cta" style="--cta:#ff6200">{{link:0}}</div><p>Met vriendelijke groet,<br>ING Beveiligingsteam</p></div><div class="eml-foot"><p>Dit bericht is automatisch verzonden. © ING Bank N.V.</p><p>U ontvangt deze e-mail omdat uw rekening extra controle vereist.</p></div></div>',
 '[{"label":"Gegevens bevestigen","real_url":"http://ing-beveiliging.net/login","suspicious":true,"warning":"Deze link gaat NIET naar ing.nl maar naar ing-beveiliging.net. Dat is een nep-website die op ING lijkt."}]'::jsonb,
 TRUE,
 '["Afzenderadres eindigt niet op @ing.nl","Dreigt met blokkade binnen 24 uur — paniek maken","Aanhef \"Geachte klant\" zonder uw naam","Link gaat naar ing-beveiliging.net, niet naar ing.nl"]'::jsonb,
 '[]'::jsonb,
 'Dit is phishing. De ING stuurt nooit e-mails om u onder tijdsdruk uw gegevens te laten bevestigen. Had u getwijfeld? Open dan altijd zelf de ING-app of bel 020-22 888 00 (nummer op uw bankpas).',
 10),

-- 2. REAL — Huisarts
('Huisartsenpraktijk De Linde',
 'praktijk@huisartsendelinde.nl',
 'Het adres eindigt op het eigen domein van de praktijk — normaal.',
 'vandaag 09:15',
 'Herinnering: uw afspraak morgen om 10:15',
 'Beste mevrouw Janssen, dit is een herinnering aan uw afspraak...',
 E'Beste mevrouw Janssen,\n\nDit is een herinnering aan uw afspraak bij dokter Jansen morgen om 10:15.\n\nWilt u afzeggen of verzetten? Bel dan 020-123 45 67.\n\nTot morgen.\n\nHuisartsenpraktijk De Linde\nDorpsstraat 12, Amsterdam',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Persoonlijke aanhef met uw naam","Geen link, geen knop","Telefoonnummer om zelf te bellen","Geen vraag om gegevens of geld","Concrete, verwachte informatie"]'::jsonb,
 'Dit is een gewone afspraakherinnering. Geen links, geen gegevens gevraagd — u kunt gewoon bellen als u iets wilt wijzigen.',
 20),

-- 3. PHISHING — Belastingdienst
('Belastingdienst',
 'noreply@belasting-teruggave.nl',
 'Niet @belastingdienst.nl — dus niet van de Belastingdienst, ook al staat de naam er in.',
 'vandaag 10:03',
 'U heeft recht op € 423,50 teruggave',
 'Na controle blijkt u recht te hebben op een belastingteruggave...',
 E'<div class="eml fam-gov" style="--brand:#154273;--cta:#154273"><div class="eml-top"><span class="eml-logo">Belastingdienst</span></div><div class="eml-body"><p>Beste burger,</p><p>Na controle blijkt u recht te hebben op een belastingteruggave van € 423,50.</p><p>Vul uw gegevens in om het bedrag binnen 3 werkdagen te ontvangen: {{link:0}}.</p><p>Belastingdienst</p></div><div class="eml-foot"><p>Dit is een automatisch verzonden bericht — antwoorden is niet mogelijk.</p><p>© 2026 Belastingdienst</p></div></div>',
 '[{"label":"Mijn Belastingdienst","real_url":"http://belasting-teruggave.nl/claim","suspicious":true,"warning":"Het echte adres is mijn.belastingdienst.nl. Deze link gaat naar belasting-teruggave.nl — een nep-site."}]'::jsonb,
 TRUE,
 '["Afzender is @belasting-teruggave.nl, niet @belastingdienst.nl","De Belastingdienst stuurt NOOIT e-mails over teruggaven","Belooft geld om u op de link te laten klikken","Link gaat naar een onbekende website"]'::jsonb,
 '[]'::jsonb,
 'Dit is phishing. De Belastingdienst communiceert over teruggaven via MijnOverheid.nl (Berichtenbox) of per post — nooit per e-mail met een link. Bij twijfel: log zelf in op mijn.belastingdienst.nl.',
 30),

-- 4. PHISHING — PostNL
('PostNL Track & Trace',
 'track@postnl-tracking.info',
 'Het echte domein is postnl.nl. ".info" is vaak verdacht.',
 'gisteren 16:48',
 'Uw pakket kan niet worden bezorgd',
 'Uw pakket wacht op u. Er zijn nog onbetaalde invoerkosten...',
 E'<div class="eml fam-parcel" style="--brand:#f56900;--cta:#f56900"><div class="eml-hero"><span class="eml-logo">PostNL</span></div><div class="eml-body"><p>Beste klant,</p><p>Uw pakket wacht op het distributiecentrum. Er zijn nog onbetaalde invoerkosten (€ 1,95).</p><p>Betaal direct om uitgesteld te voorkomen: {{link:0}}</p><p>PostNL</p></div><div class="eml-foot"><p>Dit is een automatisch verzonden bericht — antwoorden is niet mogelijk.</p><p>© 2026 PostNL</p></div></div>',
 '[{"label":"postnl-tracking.info/betaal","real_url":"http://postnl-tracking.info/betaal","suspicious":true,"warning":"Het echte adres van PostNL is postnl.nl. \".info\"-domeinen worden veel gebruikt voor oplichting."}]'::jsonb,
 TRUE,
 '["Klein bedrag (€ 1,95) om u te laten betalen zonder twijfelen","Afzender @postnl-tracking.info in plaats van @postnl.nl","\"Betaal direct\" — druk uitoefenen","Geen naam, algemene aanhef"]'::jsonb,
 '[]'::jsonb,
 'Dit is phishing. PostNL vraagt nooit per e-mail om invoerkosten. Verwacht u een pakket? Controleer het zelf via de officiële PostNL-app of via postnl.nl.',
 40),

-- 5. REAL — Bibliotheek
('Bibliotheek Amsterdam',
 'klantenservice@oba.nl',
 'Officieel domein van OBA (oba.nl) — klopt.',
 'gisteren 11:22',
 'Uw geleende boek moet terug',
 'Beste mevrouw Janssen, dit is een herinnering dat u uw boek...',
 E'Beste mevrouw Janssen,\n\nDit is een herinnering dat u het boek "De ontdekking van de hemel" uiterlijk vrijdag 28 april moet terugbrengen naar een vestiging van de OBA.\n\nVragen? Bel 020-523 09 00 of kom langs.\n\nMet vriendelijke groet,\nBibliotheek Amsterdam',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Persoonlijke aanhef","Concrete informatie over uw boek en datum","Geen link, geen betaling","Telefoonnummer dat u zelf kunt bellen"]'::jsonb,
 'Dit is een echte herinnering van uw bibliotheek. Geen gevaar.',
 50),

-- 6. PHISHING — DigiD
('DigiD',
 'info@digid-controle.org',
 'Het echte domein is digid.nl. ".org" op DigiD is verdacht.',
 'eergisteren 14:30',
 'Bevestig uw DigiD-gegevens',
 'Geachte heer/mevrouw, wij vragen u om uw DigiD opnieuw te bevestigen...',
 E'<div class="eml fam-gov" style="--brand:#e17000;--cta:#e17000;--logo:#c66300"><div class="eml-top"><span class="eml-logo">DigiD</span></div><div class="eml-body"><p>Geachte heer/mevrouw,</p><p>In verband met een veiligheidscontrole vragen wij u uw DigiD opnieuw te bevestigen.</p><p>Log in via {{link:0}} en vul uw gebruikersnaam en wachtwoord in.</p><p>Bedankt,<br>DigiD</p></div><div class="eml-foot"><p>Dit is een automatisch verzonden bericht — antwoorden is niet mogelijk.</p><p>© 2026 DigiD</p></div></div>',
 '[{"label":"deze beveiligde pagina","real_url":"http://digid-controle.org/inloggen","suspicious":true,"warning":"DigiD vraagt NOOIT per e-mail om uw wachtwoord. Het echte adres is digid.nl — niet digid-controle.org."}]'::jsonb,
 TRUE,
 '["Afzender @digid-controle.org — niet @digid.nl","Vraagt om gebruikersnaam én wachtwoord (doet DigiD NOOIT)","Algemene aanhef \"Geachte heer/mevrouw\"","Link naar onbekend \".org\"-adres"]'::jsonb,
 '[]'::jsonb,
 'Dit is phishing. DigiD stuurt nooit een e-mail met een link om uw wachtwoord te bevestigen. Log alleen in via digid.nl of de officiële DigiD-app.',
 60),

-- 7. REAL — KPN factuur
('KPN',
 'no-reply@kpn.nl',
 'Afzender @kpn.nl is het officiële domein — klopt.',
 '3 dagen geleden',
 'Uw factuur van april staat klaar',
 'Beste klant, uw factuur van € 49,95 staat klaar in MijnKPN...',
 E'<div class="eml fam-tech" style="--brand:#00c300;--cta:#00c300;--logo:#009400"><div class="eml-top"><span class="eml-logo" style="font-weight:800;letter-spacing:1px">KPN</span></div><div class="eml-body"><p>Beste mevrouw Janssen,</p><p>Uw KPN-factuur van € 49,95 over de maand april staat klaar in MijnKPN.</p><p>U kunt de factuur bekijken door zelf in te loggen op kpn.com/mijnkpn (typ dit adres zelf in uw browser of gebruik de MijnKPN-app).</p><p>Het bedrag wordt op 1 mei automatisch van uw rekening afgeschreven.</p><p>KPN Klantenservice</p></div><div class="eml-foot"><p>Dit is een automatisch verzonden bericht — antwoorden is niet mogelijk.</p><p>© 2026 KPN</p></div></div>',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Afzender is @kpn.nl (echt)","Persoonlijke aanhef","Bedrag en datum kloppen met uw abonnement","Geen klikbare link — u wordt gevraagd ZELF in te loggen","Verwachte maandelijkse factuur"]'::jsonb,
 'Dit is een echte KPN-factuur-melding. Let op: ook bij een echt bericht is het verstandig om NIET op links te klikken maar zelf naar de website of app te gaan.',
 70),

-- 8. PHISHING — Microsoft
('Microsoft',
 'support@microsoft-security-check.com',
 'Het echte Microsoft-domein is microsoft.com, niet microsoft-security-check.com.',
 '4 dagen geleden',
 'Waarschuwing: uw account is geblokkeerd',
 'Uw Microsoft-account is geblokkeerd wegens verdachte activiteit...',
 E'<div class="eml fam-tech" style="--brand:#0067b8;--cta:#0067b8"><div class="eml-top"><span class="eml-logo">Microsoft</span></div><div class="eml-body"><p>Beste gebruiker,</p><p>Uw Microsoft-account is tijdelijk geblokkeerd wegens verdachte inlogpogingen vanuit Rusland.</p><p>Als u uw account niet binnen 12 uur ontgrendelt, verliest u al uw bestanden.</p><p>Ontgrendel uw account: {{link:0}}</p></div><div class="eml-foot"><p>Dit is een automatisch verzonden bericht — antwoorden is niet mogelijk.</p><p>© 2026 Microsoft</p></div></div>',
 '[{"label":"Ontgrendel account","real_url":"http://microsoft-security-check.com/unlock","suspicious":true,"warning":"Microsoft gebruikt nooit domeinen met streepjes zoals microsoft-security-check.com. Dit is nep."}]'::jsonb,
 TRUE,
 '["Paniek: \"verliest u al uw bestanden\"","Rare afzender, niet @microsoft.com","Dreiging over inlog vanuit een ander land","Afteltijd (12 uur) om u te laten haasten"]'::jsonb,
 '[]'::jsonb,
 'Dit is phishing. Microsoft belt of mailt u nooit ongevraagd over geblokkeerde accounts. Ontvangt u zoiets? Negeer het en log zelf in op account.microsoft.com om te controleren.',
 80),

-- 9. REAL — Apotheek
('Apotheek Centrum',
 'apotheek@apotheekcentrum.nl',
 'Eigen domein van de apotheek — klopt.',
 '5 dagen geleden',
 'Uw medicijnen liggen klaar',
 'Uw medicijnen liggen klaar bij Apotheek Centrum. U kunt ze ophalen...',
 E'Beste mevrouw Janssen,\n\nUw medicijnen liggen klaar bij Apotheek Centrum, Dorpsstraat 12.\n\nWij zijn vandaag geopend tot 17:30 uur. Neem uw afhaalbewijs of identiteitsbewijs mee.\n\nVragen? Bel 020-111 22 33.\n\nApotheek Centrum',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Persoonlijke aanhef","Bekende apotheek, eigen domein","Concrete informatie: adres, openingstijd","Geen link, geen betaling","Telefoonnummer om zelf te bellen"]'::jsonb,
 'Dit is een normale melding van uw apotheek. Geen gevaar.',
 90),

-- 10. PHISHING — Bol.com winactie
('Bol.com',
 'winactie@bol-winactie.net',
 'Echte bol.com-mails komen van @bol.com, niet van @bol-winactie.net.',
 '6 dagen geleden',
 'Gefeliciteerd! U heeft een iPhone 15 gewonnen',
 'U bent onze gelukkige winnaar! Claim uw prijs binnen 2 uur...',
 E'<div class="eml fam-retail" style="--brand:#0000a4;--cta:#0000a4"><div class="eml-hero"><span class="eml-logo" style="text-transform:lowercase;font-weight:800">bol.com</span></div><div class="eml-body"><p>Beste klant,</p><p>Gefeliciteerd! U bent uit duizenden deelnemers getrokken als onze winnaar van een gloednieuwe iPhone 15.</p><p>Claim uw prijs binnen 2 uur door een kleine verzendbijdrage te betalen: {{link:0}}</p><p>Bol.com Winactie Team</p></div><div class="eml-foot"><p>Dit is een automatisch verzonden bericht — antwoorden is niet mogelijk.</p><p>© 2026 bol.com</p></div></div>',
 '[{"label":"Claim uw prijs","real_url":"http://bol-winactie.net/claim","suspicious":true,"warning":"Bol.com gebruikt alleen bol.com als adres. Een \"verzendbijdrage\" bij een gewonnen prijs is altijd oplichterij."}]'::jsonb,
 TRUE,
 '["U heeft helemaal niet meegedaan aan een winactie","Vraagt om \"verzendbijdrage\" — prijzen zijn nooit tegen betaling","Druk: \"binnen 2 uur\"","Afzender @bol-winactie.net in plaats van @bol.com"]'::jsonb,
 '[]'::jsonb,
 'Dit is phishing. U kunt geen prijs winnen waar u niet aan heeft meegedaan. Een echte winactie vraagt nooit om een verzendbijdrage vooraf.',
 100);


-- ============================================================
-- ENGLISH (UK)
-- ============================================================

-- ======== VOORBEELDEN (EN) ========
INSERT INTO examples (locale, channel, sender, subject, body, annotations, sort_order) VALUES
('en', 'email',
 'Barclays Service <service@barclays-secure-login.com>',
 'Important: your account will be blocked',
 E'Dear customer,\n\nWe have noticed a suspicious transaction on your account. Your account will be BLOCKED within 24 hours unless you confirm your details.\n\nClick here to secure your account: http://barclays-secure-login.com/verify\n\nKind regards,\nBarclays Security Team',
 '[{"quote": "service@barclays-secure-login.com", "note": "Look at what comes AFTER the @: barclays-secure-login.com. That is not Barclays. Real Barclays always uses @barclays.co.uk. The part BEFORE the @ (\"service\") can be anything the scammer wants."}, {"quote": "BLOCKED within 24 hours unless you confirm your details", "note": "Creating fear and urgency. A real bank never does this."}, {"quote": "Dear customer", "note": "No name. Your bank knows your name."}, {"quote": "http://barclays-secure-login.com/verify", "note": "Odd link that is not from Barclays. Do not click!"}]'::jsonb,
 10),

('en', 'email',
 'HMRC <noreply@hmrc-refund.co.uk>',
 'You are entitled to a £423.50 tax refund',
 E'Dear taxpayer,\n\nAfter a review, you are entitled to a tax refund of £423.50. Please fill in your details quickly to receive the amount.\n\nClick here: http://hmrc-refund.co.uk/claim\n\nHMRC',
 '[{"quote": "noreply@hmrc-refund.co.uk", "note": "Look after the @: hmrc-refund.co.uk. That is NOT HMRC. The real HMRC domain is hmrc.gov.uk."}, {"quote": "Dear taxpayer", "note": "Generic greeting without your name. HMRC addresses you by name."}, {"quote": "entitled to a tax refund of £423.50", "note": "A promise of money is a classic bait. HMRC never emails to announce refunds with a link."}, {"quote": "http://hmrc-refund.co.uk/claim", "note": "Odd link, not gov.uk. Do not click."}]'::jsonb,
 20),

('en', 'email',
 'NHS login <info@nhs-verify.org>',
 'Please confirm your NHS login details',
 E'Dear Sir/Madam,\n\nWe kindly ask you to confirm your NHS login details. Click the link below and sign in with your username and password.\n\nhttp://nhs-verify.org/signin\n\nThank you,\nNHS Digital',
 '[{"quote": "info@nhs-verify.org", "note": "Look after the @: nhs-verify.org. The real domain is nhs.uk — nothing else."}, {"quote": "Dear Sir/Madam", "note": "Generic greeting. A real organisation knows your name."}, {"quote": "sign in with your username and password", "note": "The NHS NEVER asks for your password by email. Always phishing."}, {"quote": "http://nhs-verify.org/signin", "note": "Odd link. Only open NHS services via nhs.uk or the official NHS app."}]'::jsonb,
 30);

-- ======== INBOX (EN) ========
INSERT INTO inbox_messages
  (locale, sender_name, sender_address, sender_note, received_label, subject, preview, body, links, is_phishing, red_flags, green_flags, explanation, sort_order) VALUES

-- 1. PHISHING — Barclays
('en',
 'Barclays Bank',
 'service@barclays-secure-login.com',
 'Look after the @: barclays-secure-login.com. Real Barclays always uses @barclays.co.uk.',
 'today 08:42',
 'Important: your account will be blocked',
 'Dear customer, we have noticed a suspicious transaction on your...',
 E'<div class="eml fam-bank" style="--brand:#00aeef;--cta:#00aeef;--logo:#0088ba"><div class="eml-top"><span class="eml-logo">BARCLAYS</span></div><div class="eml-body"><p>Dear customer,</p><p>We have noticed a suspicious transaction on your account. To prevent misuse, your account will be BLOCKED within 24 hours unless you confirm your details.</p><p>Confirm straight away via {{link:0}}.</p><p>Kind regards,<br>Barclays Security Team</p></div><div class="eml-foot"><p>This is an automated message — please do not reply.</p><p>© 2026 BARCLAYS</p></div></div>',
 '[{"label":"this secure page","real_url":"http://barclays-secure-login.com/verify","suspicious":true,"warning":"This link does NOT go to barclays.co.uk but to barclays-secure-login.com. That is a fake site dressed up to look like Barclays."}]'::jsonb,
 TRUE,
 '["Sender address does not end in @barclays.co.uk","Threatens a block within 24 hours — manufactured panic","Greeting is \"Dear customer\" without your name","Link goes to barclays-secure-login.com, not barclays.co.uk"]'::jsonb,
 '[]'::jsonb,
 'This is phishing. Barclays never emails you to confirm your details under time pressure. If in doubt, open the Barclays app yourself or call the number on the back of your bank card.',
 10),

-- 2. REAL — GP surgery
('en',
 'Oakwood Surgery',
 'reception@oakwoodsurgery.nhs.uk',
 'The address ends in the surgery''s own domain — normal.',
 'today 09:15',
 'Reminder: your appointment tomorrow at 10:15',
 'Dear Ms Smith, this is a reminder of your appointment with Dr...',
 E'Dear Ms Smith,\n\nThis is a reminder of your appointment with Dr Patel tomorrow at 10:15.\n\nTo cancel or rearrange, please call 020 7946 0123.\n\nSee you tomorrow.\n\nOakwood Surgery\n12 High Street, London',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Personal greeting with your name","No link, no button","A phone number you can call yourself","No request for details or money","Concrete, expected information"]'::jsonb,
 'This is an ordinary appointment reminder. No links, no details requested — you can just phone if you want to change anything.',
 20),

-- 3. PHISHING — HMRC
('en',
 'HMRC',
 'noreply@hmrc-refund.co.uk',
 'Not @hmrc.gov.uk — so not really from HMRC, even though the name appears.',
 'today 10:03',
 'You are entitled to a £423.50 tax refund',
 'After a review, you are entitled to a tax refund...',
 E'<div class="eml fam-gov" style="--brand:#008476;--cta:#008476"><div class="eml-top"><span class="eml-logo">HM Revenue &amp; Customs</span></div><div class="eml-body"><p>Dear taxpayer,</p><p>After a review, you are entitled to a tax refund of £423.50.</p><p>Fill in your details to receive the amount within 3 working days: {{link:0}}.</p><p>HMRC</p></div><div class="eml-foot"><p>This is an automated message — please do not reply.</p><p>© 2026 HM Revenue &amp; Customs</p></div></div>',
 '[{"label":"HMRC online","real_url":"http://hmrc-refund.co.uk/claim","suspicious":true,"warning":"The real domain is hmrc.gov.uk. This link goes to hmrc-refund.co.uk — a fake site."}]'::jsonb,
 TRUE,
 '["Sender is @hmrc-refund.co.uk, not @hmrc.gov.uk","HMRC NEVER emails about refunds","Promises money to bait a click","Link goes to an unknown website"]'::jsonb,
 '[]'::jsonb,
 'This is phishing. HMRC communicates about refunds through your Personal Tax Account on gov.uk or by post — never by email with a link. If in doubt, sign in to gov.uk yourself.',
 30),

-- 4. PHISHING — Royal Mail
('en',
 'Royal Mail Tracking',
 'track@royal-mail-delivery.info',
 'The real domain is royalmail.com. ".info" is often suspicious.',
 'yesterday 16:48',
 'Your parcel could not be delivered',
 'Your parcel is waiting for you. There is an outstanding customs fee...',
 E'<div class="eml fam-parcel" style="--brand:#de1212;--cta:#de1212"><div class="eml-hero"><span class="eml-logo">Royal Mail</span></div><div class="eml-body"><p>Dear customer,</p><p>Your parcel is waiting at the depot. There is an outstanding customs fee (£1.95).</p><p>Pay now to avoid a delay: {{link:0}}</p><p>Royal Mail</p></div><div class="eml-foot"><p>This is an automated message — please do not reply.</p><p>© 2026 Royal Mail</p></div></div>',
 '[{"label":"royal-mail-delivery.info/pay","real_url":"http://royal-mail-delivery.info/pay","suspicious":true,"warning":"The real address for Royal Mail is royalmail.com. \".info\" domains are widely used for scams."}]'::jsonb,
 TRUE,
 '["Small amount (£1.95) so you pay without thinking","Sender @royal-mail-delivery.info instead of @royalmail.com","\"Pay now\" — time pressure","No name, generic greeting"]'::jsonb,
 '[]'::jsonb,
 'This is phishing. Royal Mail never asks for customs fees by email. Expecting a parcel? Check using the official Royal Mail app or via royalmail.com.',
 40),

-- 5. REAL — Library
('en',
 'Camden Libraries',
 'libraries@camden.gov.uk',
 'Official Camden Council domain — correct.',
 'yesterday 11:22',
 'Your borrowed book is due back',
 'Dear Ms Smith, this is a reminder that your book...',
 E'Dear Ms Smith,\n\nThis is a reminder that the book "Wolf Hall" must be returned to a Camden library branch by Friday 28 April at the latest.\n\nAny questions? Call 020 7974 4001 or drop in.\n\nKind regards,\nCamden Libraries',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Personal greeting","Concrete information about your book and date","No link, no payment","A phone number you can call yourself"]'::jsonb,
 'This is a genuine reminder from your library. No danger.',
 50),

-- 6. PHISHING — Gov.uk Verify
('en',
 'GOV.UK Verify',
 'info@gov-uk-verify.org',
 'The real domain is gov.uk. ".org" on Gov.uk is suspicious.',
 '2 days ago 14:30',
 'Please re-confirm your Gov.uk details',
 'Dear Sir/Madam, we kindly ask you to re-confirm your Gov.uk...',
 E'<div class="eml fam-gov" style="--brand:#0b0c0c;--cta:#0b0c0c"><div class="eml-top"><span class="eml-logo">GOV.UK</span></div><div class="eml-body"><p>Dear Sir/Madam,</p><p>For a security check, we ask you to re-confirm your Gov.uk details.</p><p>Sign in via {{link:0}} and enter your username and password.</p><p>Thank you,<br>GOV.UK</p></div><div class="eml-foot"><p>This is an automated message — please do not reply.</p><p>© 2026 GOV.UK</p></div></div>',
 '[{"label":"this secure page","real_url":"http://gov-uk-verify.org/signin","suspicious":true,"warning":"Gov.uk NEVER asks for your password by email. The real domain is gov.uk — not gov-uk-verify.org."}]'::jsonb,
 TRUE,
 '["Sender @gov-uk-verify.org — not @gov.uk","Asks for both username AND password (Gov.uk NEVER does that)","Generic \"Dear Sir/Madam\" greeting","Link to an unknown .org address"]'::jsonb,
 '[]'::jsonb,
 'This is phishing. Gov.uk never emails a link asking you to confirm your password. Only sign in via gov.uk directly.',
 60),

-- 7. REAL — BT invoice
('en',
 'BT',
 'no-reply@bt.com',
 'Sender @bt.com is the official domain — correct.',
 '3 days ago',
 'Your April bill is ready',
 'Dear customer, your bill of £49.95 is ready in MyBT...',
 E'<div class="eml fam-tech" style="--brand:#5514b4;--cta:#5514b4"><div class="eml-top"><span class="eml-logo">BT</span></div><div class="eml-body"><p>Dear Ms Smith,</p><p>Your BT bill of £49.95 for April is ready in MyBT.</p><p>You can view the bill by signing in yourself at bt.com/mybt (type the address in your browser yourself or use the MyBT app).</p><p>The amount will be taken automatically on 1 May.</p><p>BT Customer Service</p></div><div class="eml-foot"><p>This is an automated message — please do not reply.</p><p>© 2026 BT</p></div></div>',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Sender is @bt.com (real)","Personal greeting","The amount and date match your contract","No clickable link — you are asked to sign in YOURSELF","Expected monthly bill"]'::jsonb,
 'This is a real BT bill notice. Even with genuine messages, it is safer NOT to click links but to go to the site or app yourself.',
 70),

-- 8. PHISHING — Microsoft
('en',
 'Microsoft',
 'support@microsoft-security-check.com',
 'The real Microsoft domain is microsoft.com, not microsoft-security-check.com.',
 '4 days ago',
 'Warning: your account has been blocked',
 'Your Microsoft account has been blocked due to suspicious activity...',
 E'<div class="eml fam-tech" style="--brand:#0067b8;--cta:#0067b8"><div class="eml-top"><span class="eml-logo">Microsoft</span></div><div class="eml-body"><p>Dear user,</p><p>Your Microsoft account has been temporarily blocked due to suspicious sign-in attempts from Russia.</p><p>If you do not unlock your account within 12 hours, you will lose all your files.</p><p>Unlock your account: {{link:0}}</p></div><div class="eml-foot"><p>This is an automated message — please do not reply.</p><p>© 2026 Microsoft</p></div></div>',
 '[{"label":"Unlock account","real_url":"http://microsoft-security-check.com/unlock","suspicious":true,"warning":"Microsoft never uses domains with dashes like microsoft-security-check.com. This is fake."}]'::jsonb,
 TRUE,
 '["Panic: \"you will lose all your files\"","Odd sender, not @microsoft.com","Threat about sign-in from another country","Countdown (12 hours) to rush you"]'::jsonb,
 '[]'::jsonb,
 'This is phishing. Microsoft never calls or emails you out of the blue about blocked accounts. Ignore it and sign in yourself at account.microsoft.com to check.',
 80),

-- 9. REAL — Pharmacy
('en',
 'Boots Pharmacy',
 'pharmacy@boots.co.uk',
 'Boots'' own domain — correct.',
 '5 days ago',
 'Your prescription is ready to collect',
 'Your prescription is ready at Boots Pharmacy. You can collect it...',
 E'Dear Ms Smith,\n\nYour prescription is ready to collect at Boots Pharmacy, 12 High Street.\n\nWe are open today until 17:30. Please bring your ID or collection slip.\n\nAny questions? Call 020 7946 0555.\n\nBoots Pharmacy',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Personal greeting","Known pharmacy, own domain","Concrete information: address and opening hours","No link, no payment","A phone number you can call yourself"]'::jsonb,
 'This is a normal message from your pharmacy. No danger.',
 90),

-- 10. PHISHING — Amazon prize
('en',
 'Amazon',
 'prize@amazon-prize-draw.net',
 'Real Amazon emails come from @amazon.co.uk, not from @amazon-prize-draw.net.',
 '6 days ago',
 'Congratulations! You have won an iPhone 15',
 'You are our lucky winner! Claim your prize within 2 hours...',
 E'<div class="eml fam-retail" style="--brand:#232f3e;--cta:#232f3e"><div class="eml-hero"><span class="eml-logo" style="text-transform:lowercase;font-weight:800">amazon</span></div><div class="eml-body"><p>Dear customer,</p><p>Congratulations! You have been drawn from thousands of entrants as the winner of a brand-new iPhone 15.</p><p>Claim your prize within 2 hours by paying a small postage fee: {{link:0}}</p><p>Amazon Prize Draw Team</p></div><div class="eml-foot"><p>This is an automated message — please do not reply.</p><p>© 2026 amazon</p></div></div>',
 '[{"label":"Claim your prize","real_url":"http://amazon-prize-draw.net/claim","suspicious":true,"warning":"Amazon only ever uses amazon.co.uk. A \"postage fee\" for a prize you won is always a scam."}]'::jsonb,
 TRUE,
 '["You never entered a prize draw","Asks for a \"postage fee\" — real prizes are never sent against payment","Urgency: \"within 2 hours\"","Sender @amazon-prize-draw.net instead of @amazon.co.uk"]'::jsonb,
 '[]'::jsonb,
 'This is phishing. You cannot win a prize you never entered. A real prize draw never asks you to pay a fee upfront.',
 100);


-- ============================================================
-- FRANÇAIS (FR)
-- ============================================================

-- ======== VOORBEELDEN (FR) ========
INSERT INTO examples (locale, channel, sender, subject, body, annotations, sort_order) VALUES
('fr', 'email',
 'Crédit Agricole <service@credit-agricole-securite.com>',
 'Important : votre compte va être bloqué',
 E'Cher client,\n\nNous avons détecté une transaction suspecte sur votre compte. Votre compte sera BLOQUÉ sous 24 heures si vous ne confirmez pas vos informations.\n\nCliquez ici pour sécuriser votre compte : http://credit-agricole-securite.com/verifier\n\nCordialement,\nService Sécurité Crédit Agricole',
 '[{"quote": "service@credit-agricole-securite.com", "note": "Regardez ce qui vient APRÈS le @ : credit-agricole-securite.com. Ce n''est pas le Crédit Agricole. Le vrai Crédit Agricole utilise toujours @credit-agricole.fr. Ce qui est AVANT le @ (« service ») peut être choisi par l''escroc."}, {"quote": "BLOQUÉ sous 24 heures si vous ne confirmez pas vos informations", "note": "On vous fait peur et on vous presse. Une vraie banque ne fait jamais cela."}, {"quote": "Cher client", "note": "Pas de nom. Votre banque connaît votre nom."}, {"quote": "http://credit-agricole-securite.com/verifier", "note": "Lien étrange qui n''est pas du Crédit Agricole. Ne cliquez pas !"}]'::jsonb,
 10),

('fr', 'email',
 'Impôts <noreply@impots-remboursement.fr>',
 'Vous avez droit à un remboursement de 423,50 €',
 E'Cher contribuable,\n\nAprès vérification, vous avez droit à un remboursement d''impôts de 423,50 €. Remplissez vite vos informations pour recevoir le montant.\n\nCliquez ici : http://impots-remboursement.fr/reclamer\n\nDirection Générale des Finances Publiques',
 '[{"quote": "noreply@impots-remboursement.fr", "note": "Regardez après le @ : impots-remboursement.fr. Ce n''est PAS la DGFiP. Le vrai domaine est dgfip.finances.gouv.fr."}, {"quote": "Cher contribuable", "note": "Salutation générique sans votre nom. La DGFiP connaît votre identité."}, {"quote": "droit à un remboursement d''impôts de 423,50 €", "note": "La promesse d''argent est un appât classique. Les impôts ne communiquent jamais un remboursement par e-mail avec un lien."}, {"quote": "http://impots-remboursement.fr/reclamer", "note": "Lien étrange, ce n''est pas impots.gouv.fr. Ne cliquez pas."}]'::jsonb,
 20),

('fr', 'email',
 'Ameli <info@ameli-controle.org>',
 'Confirmez vos informations Ameli',
 E'Madame, Monsieur,\n\nNous vous demandons de confirmer à nouveau vos informations Ameli. Cliquez sur le lien ci-dessous et connectez-vous avec votre identifiant et votre mot de passe.\n\nhttp://ameli-controle.org/connexion\n\nMerci,\nAssurance Maladie',
 '[{"quote": "info@ameli-controle.org", "note": "Regardez après le @ : ameli-controle.org. Le vrai domaine est ameli.fr — rien d''autre."}, {"quote": "Madame, Monsieur", "note": "Salutation générique. Une vraie organisation connaît votre nom."}, {"quote": "connectez-vous avec votre identifiant et votre mot de passe", "note": "Ameli ne demande JAMAIS votre mot de passe par e-mail. Toujours du hameçonnage."}, {"quote": "http://ameli-controle.org/connexion", "note": "Lien étrange. Ouvrez Ameli uniquement via ameli.fr ou l''application officielle."}]'::jsonb,
 30);

-- ======== INBOX (FR) ========
INSERT INTO inbox_messages
  (locale, sender_name, sender_address, sender_note, received_label, subject, preview, body, links, is_phishing, red_flags, green_flags, explanation, sort_order) VALUES

-- 1. PHISHING — Crédit Agricole
('fr',
 'Crédit Agricole',
 'service@credit-agricole-securite.com',
 'Regardez après le @ : credit-agricole-securite.com. Le vrai Crédit Agricole utilise toujours @credit-agricole.fr.',
 'aujourd''hui 08:42',
 'Important : votre compte va être bloqué',
 'Cher client, nous avons détecté une transaction suspecte sur votre...',
 E'<div class="eml fam-bank" style="--brand:#006a4e;--cta:#006a4e"><div class="eml-top"><span class="eml-logo">CRÉDIT AGRICOLE</span></div><div class="eml-body"><p>Cher client,</p><p>Nous avons détecté une transaction suspecte sur votre compte. Pour éviter tout abus, votre compte sera BLOQUÉ sous 24 heures si vous ne confirmez pas vos informations.</p><p>Confirmez immédiatement via {{link:0}}.</p><p>Cordialement,<br>Service Sécurité Crédit Agricole</p></div><div class="eml-foot"><p>Ceci est un message automatique — merci de ne pas y répondre.</p><p>© 2026 CRÉDIT AGRICOLE</p></div></div>',
 '[{"label":"cette page sécurisée","real_url":"http://credit-agricole-securite.com/verifier","suspicious":true,"warning":"Ce lien ne va PAS vers credit-agricole.fr mais vers credit-agricole-securite.com. C''est un faux site qui imite le Crédit Agricole."}]'::jsonb,
 TRUE,
 '["L''adresse de l''expéditeur ne finit pas par @credit-agricole.fr","Menace d''un blocage sous 24 heures — création de panique","Salutation « Cher client » sans votre nom","Le lien mène à credit-agricole-securite.com, pas à credit-agricole.fr"]'::jsonb,
 '[]'::jsonb,
 'C''est du hameçonnage. Le Crédit Agricole ne vous envoie jamais d''e-mail sous pression pour confirmer vos informations. En cas de doute, ouvrez vous-même l''application Ma Banque ou appelez le numéro au dos de votre carte.',
 10),

-- 2. REAL — Médecin
('fr',
 'Cabinet médical des Tilleuls',
 'cabinet@cabinet-tilleuls.fr',
 'L''adresse finit par le domaine du cabinet — normal.',
 'aujourd''hui 09:15',
 'Rappel : votre rendez-vous demain à 10h15',
 'Chère Madame Dupont, rappel de votre rendez-vous...',
 E'Chère Madame Dupont,\n\nCeci est un rappel de votre rendez-vous avec le Dr Martin demain à 10h15.\n\nPour annuler ou reporter, appelez le 01 42 36 12 34.\n\nÀ demain.\n\nCabinet médical des Tilleuls\n12 rue des Lilas, Paris',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Salutation personnelle avec votre nom","Aucun lien, aucun bouton","Numéro de téléphone que vous pouvez appeler vous-même","Pas de demande d''informations ou d''argent","Information concrète et attendue"]'::jsonb,
 'C''est un simple rappel de rendez-vous. Pas de liens, pas d''informations demandées — vous pouvez simplement appeler si vous voulez modifier quelque chose.',
 20),

-- 3. PHISHING — Impôts
('fr',
 'Impôts',
 'noreply@impots-remboursement.fr',
 'Pas @dgfip.finances.gouv.fr — donc pas vraiment des impôts, même si le nom apparaît.',
 'aujourd''hui 10:03',
 'Vous avez droit à un remboursement de 423,50 €',
 'Après vérification, vous avez droit à un remboursement...',
 E'<div class="eml fam-gov" style="--brand:#000091;--cta:#000091"><div class="eml-top"><span class="eml-logo">impots.gouv.fr</span></div><div class="eml-body"><p>Cher contribuable,</p><p>Après vérification, vous avez droit à un remboursement d''impôts de 423,50 €.</p><p>Remplissez vos informations pour recevoir le montant sous 3 jours ouvrés : {{link:0}}.</p><p>Direction Générale des Finances Publiques</p></div><div class="eml-foot"><p>Ceci est un message automatique — merci de ne pas y répondre.</p><p>© 2026 impots.gouv.fr</p></div></div>',
 '[{"label":"Mon espace impots.gouv.fr","real_url":"http://impots-remboursement.fr/reclamer","suspicious":true,"warning":"La vraie adresse est impots.gouv.fr. Ce lien mène à impots-remboursement.fr — un faux site."}]'::jsonb,
 TRUE,
 '["Expéditeur @impots-remboursement.fr, pas @dgfip.finances.gouv.fr","La DGFiP n''envoie JAMAIS d''e-mail concernant les remboursements","Promet de l''argent pour vous faire cliquer","Le lien mène à un site inconnu"]'::jsonb,
 '[]'::jsonb,
 'C''est du hameçonnage. La DGFiP communique sur les remboursements via votre espace personnel sur impots.gouv.fr ou par courrier — jamais par e-mail avec un lien. En cas de doute : connectez-vous vous-même sur impots.gouv.fr.',
 30),

-- 4. PHISHING — La Poste / Colissimo
('fr',
 'Colissimo Suivi',
 'suivi@colissimo-livraison.info',
 'Le vrai domaine est laposte.fr. « .info » est souvent suspect.',
 'hier 16:48',
 'Votre colis n''a pas pu être livré',
 'Votre colis vous attend. Des frais de douane restent impayés...',
 E'<div class="eml fam-parcel" style="--brand:#ffd100;--cta:#ffd100;--cta-ink:#1a1a1a"><div class="eml-hero"><span class="eml-logo">Colissimo</span></div><div class="eml-body"><p>Cher client,</p><p>Votre colis est en attente au centre de distribution. Des frais de douane restent impayés (1,95 €).</p><p>Payez immédiatement pour éviter un retard : {{link:0}}</p><p>Colissimo</p></div><div class="eml-foot"><p>Ceci est un message automatique — merci de ne pas y répondre.</p><p>© 2026 Colissimo</p></div></div>',
 '[{"label":"colissimo-livraison.info/payer","real_url":"http://colissimo-livraison.info/payer","suspicious":true,"warning":"La vraie adresse de La Poste est laposte.fr. Les domaines en « .info » sont très utilisés pour des arnaques."}]'::jsonb,
 TRUE,
 '["Petit montant (1,95 €) pour que vous payiez sans réfléchir","Expéditeur @colissimo-livraison.info au lieu de @laposte.fr","« Payez immédiatement » — pression temporelle","Pas de nom, salutation générique"]'::jsonb,
 '[]'::jsonb,
 'C''est du hameçonnage. La Poste ne demande jamais de frais de douane par e-mail. Vous attendez un colis ? Vérifiez vous-même via l''application officielle La Poste ou sur laposte.fr.',
 40),

-- 5. REAL — Médiathèque
('fr',
 'Médiathèque de la Ville',
 'accueil@mediatheque-paris.fr',
 'Domaine officiel de la médiathèque — correct.',
 'hier 11:22',
 'Votre livre emprunté doit être rendu',
 'Chère Madame Dupont, rappel que votre livre...',
 E'Chère Madame Dupont,\n\nCeci est un rappel que le livre « L''Étranger » doit être retourné dans une médiathèque de Paris avant le vendredi 28 avril.\n\nDes questions ? Appelez le 01 44 59 29 40 ou passez nous voir.\n\nCordialement,\nMédiathèque de la Ville',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Salutation personnelle","Information concrète sur votre livre et la date","Aucun lien, aucun paiement","Numéro de téléphone que vous pouvez appeler vous-même"]'::jsonb,
 'C''est un vrai rappel de votre médiathèque. Aucun danger.',
 50),

-- 6. PHISHING — Ameli
('fr',
 'Ameli',
 'info@ameli-controle.org',
 'Le vrai domaine est ameli.fr. « .org » sur Ameli est suspect.',
 'avant-hier 14:30',
 'Confirmez vos informations Ameli',
 'Madame, Monsieur, nous vous demandons de confirmer à nouveau...',
 E'<div class="eml fam-gov" style="--brand:#0c419a;--cta:#0c419a"><div class="eml-top"><span class="eml-logo">ameli — l’Assurance Maladie</span></div><div class="eml-body"><p>Madame, Monsieur,</p><p>Dans le cadre d''un contrôle de sécurité, nous vous demandons de confirmer à nouveau vos informations Ameli.</p><p>Connectez-vous via {{link:0}} et saisissez votre identifiant et votre mot de passe.</p><p>Merci,<br>Assurance Maladie</p></div><div class="eml-foot"><p>Ceci est un message automatique — merci de ne pas y répondre.</p><p>© 2026 ameli — l’Assurance Maladie</p></div></div>',
 '[{"label":"cette page sécurisée","real_url":"http://ameli-controle.org/connexion","suspicious":true,"warning":"Ameli ne demande JAMAIS votre mot de passe par e-mail. La vraie adresse est ameli.fr — pas ameli-controle.org."}]'::jsonb,
 TRUE,
 '["Expéditeur @ameli-controle.org — pas @ameli.fr","Demande votre identifiant ET votre mot de passe (Ameli ne fait JAMAIS cela)","Salutation générique « Madame, Monsieur »","Lien vers une adresse inconnue en « .org »"]'::jsonb,
 '[]'::jsonb,
 'C''est du hameçonnage. Ameli n''envoie jamais d''e-mail avec un lien pour confirmer votre mot de passe. Connectez-vous uniquement via ameli.fr ou l''application officielle Ameli.',
 60),

-- 7. REAL — Orange
('fr',
 'Orange',
 'no-reply@orange.fr',
 'L''expéditeur @orange.fr est le domaine officiel — correct.',
 'il y a 3 jours',
 'Votre facture d''avril est disponible',
 'Cher client, votre facture de 49,95 € est disponible dans votre espace client...',
 E'<div class="eml fam-tech" style="--brand:#ff7900;--cta:#ff7900;--logo:#c75e00"><div class="eml-top"><span class="eml-logo" style="text-transform:lowercase">orange™</span></div><div class="eml-body"><p>Chère Madame Dupont,</p><p>Votre facture Orange de 49,95 € pour le mois d''avril est disponible dans votre espace client.</p><p>Vous pouvez consulter la facture en vous connectant vous-même à orange.fr/espace-client (tapez cette adresse vous-même dans votre navigateur ou utilisez l''application Orange et moi).</p><p>Le montant sera prélevé automatiquement sur votre compte le 1er mai.</p><p>Service client Orange</p></div><div class="eml-foot"><p>Ceci est un message automatique — merci de ne pas y répondre.</p><p>© 2026 orange™</p></div></div>',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Expéditeur @orange.fr (réel)","Salutation personnelle","Le montant et la date correspondent à votre abonnement","Pas de lien cliquable — on vous demande de vous connecter VOUS-MÊME","Facture mensuelle attendue"]'::jsonb,
 'C''est une vraie notification de facture Orange. Attention : même pour un vrai message, il est plus prudent de NE PAS cliquer sur les liens mais d''aller vous-même sur le site ou l''application.',
 70),

-- 8. PHISHING — Microsoft
('fr',
 'Microsoft',
 'support@microsoft-security-check.com',
 'Le vrai domaine Microsoft est microsoft.com, pas microsoft-security-check.com.',
 'il y a 4 jours',
 'Avertissement : votre compte est bloqué',
 'Votre compte Microsoft est bloqué suite à une activité suspecte...',
 E'<div class="eml fam-tech" style="--brand:#0067b8;--cta:#0067b8"><div class="eml-top"><span class="eml-logo">Microsoft</span></div><div class="eml-body"><p>Cher utilisateur,</p><p>Votre compte Microsoft est temporairement bloqué suite à des tentatives de connexion suspectes depuis la Russie.</p><p>Si vous ne déverrouillez pas votre compte dans les 12 heures, vous perdrez tous vos fichiers.</p><p>Déverrouillez votre compte : {{link:0}}</p></div><div class="eml-foot"><p>Ceci est un message automatique — merci de ne pas y répondre.</p><p>© 2026 Microsoft</p></div></div>',
 '[{"label":"Déverrouiller le compte","real_url":"http://microsoft-security-check.com/unlock","suspicious":true,"warning":"Microsoft n''utilise jamais de domaines avec des tirets comme microsoft-security-check.com. C''est faux."}]'::jsonb,
 TRUE,
 '["Panique : « vous perdrez tous vos fichiers »","Expéditeur étrange, pas @microsoft.com","Menace de connexion depuis un autre pays","Compte à rebours (12 heures) pour vous presser"]'::jsonb,
 '[]'::jsonb,
 'C''est du hameçonnage. Microsoft ne vous appelle ni ne vous envoie jamais d''e-mail non sollicité au sujet de comptes bloqués. Vous recevez cela ? Ignorez et connectez-vous vous-même sur account.microsoft.com pour vérifier.',
 80),

-- 9. REAL — Pharmacie
('fr',
 'Pharmacie Centrale',
 'contact@pharmacie-centrale.fr',
 'Domaine propre de la pharmacie — correct.',
 'il y a 5 jours',
 'Vos médicaments sont prêts',
 'Vos médicaments sont prêts à la Pharmacie Centrale. Vous pouvez les retirer...',
 E'Chère Madame Dupont,\n\nVos médicaments sont prêts à la Pharmacie Centrale, 12 rue des Lilas.\n\nNous sommes ouverts aujourd''hui jusqu''à 19h30. Apportez votre bon de retrait ou votre pièce d''identité.\n\nDes questions ? Appelez le 01 42 36 87 65.\n\nPharmacie Centrale',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Salutation personnelle","Pharmacie connue, domaine propre","Information concrète : adresse, horaires","Aucun lien, aucun paiement","Numéro de téléphone que vous pouvez appeler vous-même"]'::jsonb,
 'C''est un message normal de votre pharmacie. Aucun danger.',
 90),

-- 10. PHISHING — Amazon concours
('fr',
 'Amazon',
 'concours@amazon-tirage.net',
 'Les vrais e-mails Amazon viennent de @amazon.fr, pas de @amazon-tirage.net.',
 'il y a 6 jours',
 'Félicitations ! Vous avez gagné un iPhone 15',
 'Vous êtes notre heureux gagnant ! Réclamez votre prix sous 2 heures...',
 E'<div class="eml fam-retail" style="--brand:#232f3e;--cta:#232f3e"><div class="eml-hero"><span class="eml-logo" style="text-transform:lowercase;font-weight:800">amazon</span></div><div class="eml-body"><p>Cher client,</p><p>Félicitations ! Vous avez été tiré au sort parmi des milliers de participants comme notre gagnant d''un iPhone 15 flambant neuf.</p><p>Réclamez votre prix sous 2 heures en payant une petite participation aux frais d''envoi : {{link:0}}</p><p>Équipe Amazon Tirage au sort</p></div><div class="eml-foot"><p>Ceci est un message automatique — merci de ne pas y répondre.</p><p>© 2026 amazon</p></div></div>',
 '[{"label":"Réclamer votre prix","real_url":"http://amazon-tirage.net/reclamer","suspicious":true,"warning":"Amazon n''utilise que amazon.fr. Une « participation aux frais d''envoi » pour un prix gagné est toujours une arnaque."}]'::jsonb,
 TRUE,
 '["Vous n''avez jamais participé à un tirage au sort","Demande une « participation aux frais d''envoi » — un prix ne se paye jamais","Pression : « sous 2 heures »","Expéditeur @amazon-tirage.net au lieu de @amazon.fr"]'::jsonb,
 '[]'::jsonb,
 'C''est du hameçonnage. On ne peut pas gagner un prix auquel on n''a pas participé. Un vrai tirage au sort ne demande jamais des frais de port à l''avance.',
 100);


-- ============================================================
-- DEUTSCH (DE)
-- ============================================================

-- ======== VOORBEELDEN (DE) ========
INSERT INTO examples (locale, channel, sender, subject, body, annotations, sort_order) VALUES
('de', 'email',
 'Sparkasse <service@sparkasse-sicher-login.com>',
 'Wichtig: Ihr Konto wird gesperrt',
 E'Sehr geehrter Kunde,\n\nWir haben eine verdächtige Transaktion auf Ihrem Konto festgestellt. Innerhalb von 24 Stunden wird Ihr Konto GESPERRT, wenn Sie Ihre Daten nicht bestätigen.\n\nKlicken Sie hier, um Ihr Konto zu sichern: http://sparkasse-sicher-login.com/verify\n\nMit freundlichen Grüßen,\nSparkasse Sicherheitsteam',
 '[{"quote": "service@sparkasse-sicher-login.com", "note": "Achten Sie darauf, was NACH dem @ steht: sparkasse-sicher-login.com. Das ist nicht die Sparkasse. Die echte Sparkasse nutzt immer @sparkasse.de. Der Teil VOR dem @ („service“) kann vom Betrüger frei gewählt werden."}, {"quote": "GESPERRT, wenn Sie Ihre Daten nicht bestätigen", "note": "Angst und Eile erzeugen. Eine echte Bank macht das nie."}, {"quote": "Sehr geehrter Kunde", "note": "Kein Name. Ihre Bank kennt Ihren Namen."}, {"quote": "http://sparkasse-sicher-login.com/verify", "note": "Verdächtiger Link, der nicht von der Sparkasse ist. Nicht anklicken!"}]'::jsonb,
 10),

('de', 'email',
 'Finanzamt <noreply@finanzamt-erstattung.de>',
 'Sie haben Anspruch auf 423,50 € Rückerstattung',
 E'Sehr geehrter Steuerzahler,\n\nNach unserer Prüfung haben Sie Anspruch auf eine Steuererstattung in Höhe von 423,50 €. Geben Sie schnell Ihre Daten ein, um den Betrag zu erhalten.\n\nKlicken Sie hier: http://finanzamt-erstattung.de/anfordern\n\nFinanzamt',
 '[{"quote": "noreply@finanzamt-erstattung.de", "note": "Achten Sie auf den Teil nach dem @: finanzamt-erstattung.de. Das ist NICHT das Finanzamt. Echte Kommunikation läuft über @elster.de oder Briefpost."}, {"quote": "Sehr geehrter Steuerzahler", "note": "Allgemeine Anrede ohne Ihren Namen. Das Finanzamt kennt Sie."}, {"quote": "Anspruch auf eine Steuererstattung in Höhe von 423,50 €", "note": "Ein Geldversprechen ist ein klassischer Köder. Das Finanzamt kündigt Erstattungen nie per E-Mail mit Link an."}, {"quote": "http://finanzamt-erstattung.de/anfordern", "note": "Verdächtiger Link, nicht elster.de. Nicht anklicken."}]'::jsonb,
 20),

('de', 'email',
 'ELSTER <info@elster-sicher.org>',
 'Bitte bestätigen Sie Ihre ELSTER-Daten',
 E'Sehr geehrte Damen und Herren,\n\nWir bitten Sie, Ihre ELSTER-Daten erneut zu bestätigen. Klicken Sie auf den untenstehenden Link und melden Sie sich mit Ihrem Benutzernamen und Passwort an.\n\nhttp://elster-sicher.org/anmelden\n\nMit freundlichen Grüßen,\nELSTER',
 '[{"quote": "info@elster-sicher.org", "note": "Achten Sie auf den Teil nach dem @: elster-sicher.org. Die echte Domain ist elster.de — nichts anderes."}, {"quote": "Sehr geehrte Damen und Herren", "note": "Allgemeine Anrede. Eine echte Organisation kennt Ihren Namen."}, {"quote": "melden Sie sich mit Ihrem Benutzernamen und Passwort an", "note": "ELSTER fragt NIEMALS per E-Mail nach Ihrem Passwort. Immer Phishing."}, {"quote": "http://elster-sicher.org/anmelden", "note": "Verdächtiger Link. Öffnen Sie ELSTER nur über elster.de oder die offizielle App."}]'::jsonb,
 30);

-- ======== INBOX (DE) ========
INSERT INTO inbox_messages
  (locale, sender_name, sender_address, sender_note, received_label, subject, preview, body, links, is_phishing, red_flags, green_flags, explanation, sort_order) VALUES

-- 1. PHISHING — Sparkasse
('de',
 'Sparkasse',
 'service@sparkasse-sicher-login.com',
 'Achten Sie auf den Teil nach dem @: sparkasse-sicher-login.com. Die echte Sparkasse nutzt immer @sparkasse.de.',
 'heute 08:42',
 'Wichtig: Ihr Konto wird gesperrt',
 'Sehr geehrter Kunde, wir haben eine verdächtige Transaktion auf Ihrem...',
 E'<div class="eml fam-bank" style="--brand:#ff0000;--cta:#ff0000;--logo:#fa0000"><div class="eml-top"><span class="eml-logo">Sparkasse</span></div><div class="eml-body"><p>Sehr geehrter Kunde,</p><p>Wir haben eine verdächtige Transaktion auf Ihrem Konto festgestellt. Um Missbrauch zu verhindern, wird Ihr Konto innerhalb von 24 Stunden GESPERRT, wenn Sie Ihre Daten nicht bestätigen.</p><p>Bestätigen Sie sofort über {{link:0}}.</p><p>Mit freundlichen Grüßen,<br>Sparkasse Sicherheitsteam</p></div><div class="eml-foot"><p>Dies ist eine automatische Nachricht — bitte antworten Sie nicht darauf.</p><p>© 2026 Sparkasse</p></div></div>',
 '[{"label":"diese sichere Seite","real_url":"http://sparkasse-sicher-login.com/verify","suspicious":true,"warning":"Dieser Link führt NICHT zu sparkasse.de, sondern zu sparkasse-sicher-login.com. Das ist eine gefälschte Seite, die wie die Sparkasse aussieht."}]'::jsonb,
 TRUE,
 '["Absenderadresse endet nicht auf @sparkasse.de","Droht mit Sperrung innerhalb von 24 Stunden — Panikmache","Anrede „Sehr geehrter Kunde“ ohne Ihren Namen","Link führt zu sparkasse-sicher-login.com, nicht zu sparkasse.de"]'::jsonb,
 '[]'::jsonb,
 'Das ist Phishing. Die Sparkasse schickt niemals E-Mails unter Zeitdruck, um Ihre Daten bestätigen zu lassen. Im Zweifel öffnen Sie selbst die Sparkassen-App oder rufen die Nummer auf der Rückseite Ihrer Karte an.',
 10),

-- 2. REAL — Hausarzt
('de',
 'Hausarztpraxis Dr. Schmidt',
 'praxis@hausarzt-schmidt.de',
 'Die Adresse endet auf der eigenen Domain der Praxis — normal.',
 'heute 09:15',
 'Erinnerung: Ihr Termin morgen um 10:15',
 'Sehr geehrte Frau Müller, dies ist eine Erinnerung an Ihren Termin...',
 E'Sehr geehrte Frau Müller,\n\nDies ist eine Erinnerung an Ihren Termin bei Dr. Schmidt morgen um 10:15.\n\nMöchten Sie absagen oder verschieben? Dann rufen Sie bitte 030 123 45 67 an.\n\nBis morgen.\n\nHausarztpraxis Dr. Schmidt\nHauptstraße 12, Berlin',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Persönliche Anrede mit Ihrem Namen","Kein Link, keine Schaltfläche","Telefonnummer, die Sie selbst anrufen können","Keine Frage nach Daten oder Geld","Konkrete, erwartete Information"]'::jsonb,
 'Das ist eine ganz normale Terminerinnerung. Keine Links, keine Datenabfrage — Sie können einfach anrufen, wenn Sie etwas ändern möchten.',
 20),

-- 3. PHISHING — Finanzamt
('de',
 'Finanzamt',
 'noreply@finanzamt-erstattung.de',
 'Nicht @elster.de — also nicht vom Finanzamt, auch wenn der Name erscheint.',
 'heute 10:03',
 'Sie haben Anspruch auf 423,50 € Rückerstattung',
 'Nach unserer Prüfung haben Sie Anspruch auf eine Steuererstattung...',
 E'<div class="eml fam-gov" style="--brand:#003064;--cta:#003064"><div class="eml-top"><span class="eml-logo">Finanzamt</span></div><div class="eml-body"><p>Sehr geehrter Steuerzahler,</p><p>Nach unserer Prüfung haben Sie Anspruch auf eine Steuererstattung in Höhe von 423,50 €.</p><p>Geben Sie Ihre Daten ein, um den Betrag innerhalb von 3 Werktagen zu erhalten: {{link:0}}.</p><p>Finanzamt</p></div><div class="eml-foot"><p>Dies ist eine automatische Nachricht — bitte antworten Sie nicht darauf.</p><p>© 2026 Finanzamt</p></div></div>',
 '[{"label":"Mein ELSTER","real_url":"http://finanzamt-erstattung.de/anfordern","suspicious":true,"warning":"Die echte Adresse ist elster.de. Dieser Link führt zu finanzamt-erstattung.de — einer gefälschten Seite."}]'::jsonb,
 TRUE,
 '["Absender @finanzamt-erstattung.de, nicht @elster.de","Das Finanzamt versendet NIEMALS E-Mails zu Erstattungen","Verspricht Geld, um Sie zum Klick zu bewegen","Link führt zu einer unbekannten Website"]'::jsonb,
 '[]'::jsonb,
 'Das ist Phishing. Das Finanzamt kommuniziert über ELSTER (elster.de) oder per Briefpost — niemals per E-Mail mit Link. Im Zweifel: melden Sie sich selbst bei elster.de an.',
 30),

-- 4. PHISHING — DHL
('de',
 'DHL Sendungsverfolgung',
 'tracking@dhl-paket-info.com',
 'Die echte Domain ist dhl.de. „.com“ mit Bindestrichen ist oft verdächtig.',
 'gestern 16:48',
 'Ihr Paket konnte nicht zugestellt werden',
 'Ihr Paket wartet auf Sie. Es gibt noch unbezahlte Zollgebühren...',
 E'<div class="eml fam-parcel" style="--brand:#ffcc00;--cta:#ffcc00;--cta-ink:#d40511"><div class="eml-hero"><span class="eml-logo">DHL</span></div><div class="eml-body"><p>Sehr geehrter Kunde,</p><p>Ihr Paket wartet im Verteilzentrum. Es gibt noch unbezahlte Zollgebühren (1,95 €).</p><p>Zahlen Sie sofort, um Verzögerungen zu vermeiden: {{link:0}}</p><p>DHL</p></div><div class="eml-foot"><p>Dies ist eine automatische Nachricht — bitte antworten Sie nicht darauf.</p><p>© 2026 DHL</p></div></div>',
 '[{"label":"dhl-paket-info.com/zahlen","real_url":"http://dhl-paket-info.com/zahlen","suspicious":true,"warning":"Die echte Adresse von DHL ist dhl.de. Domains mit Bindestrichen werden oft für Betrug genutzt."}]'::jsonb,
 TRUE,
 '["Kleiner Betrag (1,95 €), damit Sie ohne Nachdenken zahlen","Absender @dhl-paket-info.com statt @dhl.de","„Zahlen Sie sofort“ — Zeitdruck","Kein Name, allgemeine Anrede"]'::jsonb,
 '[]'::jsonb,
 'Das ist Phishing. DHL verlangt niemals Zollgebühren per E-Mail. Erwarten Sie ein Paket? Prüfen Sie es selbst über die offizielle DHL-App oder auf dhl.de.',
 40),

-- 5. REAL — Stadtbibliothek
('de',
 'Stadtbibliothek Berlin',
 'info@zlb.de',
 'Offizielle Domain der Berliner Stadtbibliothek (zlb.de) — passt.',
 'gestern 11:22',
 'Ihr geliehenes Buch muss zurück',
 'Sehr geehrte Frau Müller, dies ist eine Erinnerung, dass Sie Ihr Buch...',
 E'Sehr geehrte Frau Müller,\n\nDies ist eine Erinnerung, dass das Buch „Der Vorleser“ spätestens am Freitag, 28. April, in einer Zweigstelle der Zentral- und Landesbibliothek zurückgegeben werden muss.\n\nFragen? Rufen Sie 030 90226 401 an oder kommen Sie vorbei.\n\nMit freundlichen Grüßen,\nStadtbibliothek Berlin',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Persönliche Anrede","Konkrete Information zu Ihrem Buch und Datum","Kein Link, keine Zahlung","Telefonnummer, die Sie selbst anrufen können"]'::jsonb,
 'Das ist eine echte Erinnerung Ihrer Bibliothek. Keine Gefahr.',
 50),

-- 6. PHISHING — ELSTER
('de',
 'ELSTER',
 'info@elster-sicher.org',
 'Die echte Domain ist elster.de. „.org“ bei ELSTER ist verdächtig.',
 'vorgestern 14:30',
 'Bitte bestätigen Sie Ihre ELSTER-Daten',
 'Sehr geehrte Damen und Herren, wir bitten Sie, Ihre ELSTER-Daten...',
 E'<div class="eml fam-gov" style="--brand:#5a8f22;--cta:#5a8f22;--logo:#588c21"><div class="eml-top"><span class="eml-logo">ELSTER</span></div><div class="eml-body"><p>Sehr geehrte Damen und Herren,</p><p>Im Rahmen einer Sicherheitsprüfung bitten wir Sie, Ihre ELSTER-Daten erneut zu bestätigen.</p><p>Melden Sie sich über {{link:0}} an und geben Sie Ihren Benutzernamen und Ihr Passwort ein.</p><p>Mit freundlichen Grüßen,<br>ELSTER</p></div><div class="eml-foot"><p>Dies ist eine automatische Nachricht — bitte antworten Sie nicht darauf.</p><p>© 2026 ELSTER</p></div></div>',
 '[{"label":"diese sichere Seite","real_url":"http://elster-sicher.org/anmelden","suspicious":true,"warning":"ELSTER fragt NIEMALS per E-Mail nach Ihrem Passwort. Die echte Adresse ist elster.de — nicht elster-sicher.org."}]'::jsonb,
 TRUE,
 '["Absender @elster-sicher.org — nicht @elster.de","Fragt nach Benutzername UND Passwort (das macht ELSTER NIEMALS)","Allgemeine Anrede „Sehr geehrte Damen und Herren“","Link zu unbekannter „.org“-Adresse"]'::jsonb,
 '[]'::jsonb,
 'Das ist Phishing. ELSTER verschickt nie eine E-Mail mit Link, um Ihr Passwort bestätigen zu lassen. Melden Sie sich nur über elster.de oder die offizielle ElsterSmart-App an.',
 60),

-- 7. REAL — Telekom
('de',
 'Telekom',
 'no-reply@telekom.de',
 'Absender @telekom.de ist die offizielle Domain — passt.',
 'vor 3 Tagen',
 'Ihre April-Rechnung liegt bereit',
 'Sehr geehrter Kunde, Ihre Rechnung über 49,95 € liegt in MeineTelekom bereit...',
 E'<div class="eml fam-tech" style="--brand:#e20074;--cta:#e20074"><div class="eml-top"><span class="eml-logo">T · Telekom</span></div><div class="eml-body"><p>Sehr geehrte Frau Müller,</p><p>Ihre Telekom-Rechnung über 49,95 € für den Monat April liegt in MeineTelekom bereit.</p><p>Sie können die Rechnung einsehen, indem Sie sich selbst unter telekom.de/meinetelekom anmelden (tippen Sie diese Adresse selbst in Ihren Browser oder nutzen Sie die MeineTelekom-App).</p><p>Der Betrag wird am 1. Mai automatisch von Ihrem Konto abgebucht.</p><p>Telekom Kundenservice</p></div><div class="eml-foot"><p>Dies ist eine automatische Nachricht — bitte antworten Sie nicht darauf.</p><p>© 2026 T · Telekom</p></div></div>',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Absender ist @telekom.de (echt)","Persönliche Anrede","Betrag und Datum stimmen mit Ihrem Vertrag überein","Kein anklickbarer Link — Sie werden gebeten, sich SELBST anzumelden","Erwartete Monatsrechnung"]'::jsonb,
 'Das ist eine echte Rechnungsbenachrichtigung der Telekom. Hinweis: Auch bei echten Nachrichten ist es sicherer, NICHT auf Links zu klicken, sondern selbst zur Website oder App zu gehen.',
 70),

-- 8. PHISHING — Microsoft
('de',
 'Microsoft',
 'support@microsoft-security-check.com',
 'Die echte Microsoft-Domain ist microsoft.com, nicht microsoft-security-check.com.',
 'vor 4 Tagen',
 'Warnung: Ihr Konto wurde gesperrt',
 'Ihr Microsoft-Konto wurde wegen verdächtiger Aktivität gesperrt...',
 E'<div class="eml fam-tech" style="--brand:#0067b8;--cta:#0067b8"><div class="eml-top"><span class="eml-logo">Microsoft</span></div><div class="eml-body"><p>Sehr geehrter Nutzer,</p><p>Ihr Microsoft-Konto wurde wegen verdächtiger Anmeldeversuche aus Russland vorübergehend gesperrt.</p><p>Wenn Sie Ihr Konto nicht innerhalb von 12 Stunden entsperren, verlieren Sie alle Ihre Dateien.</p><p>Konto entsperren: {{link:0}}</p></div><div class="eml-foot"><p>Dies ist eine automatische Nachricht — bitte antworten Sie nicht darauf.</p><p>© 2026 Microsoft</p></div></div>',
 '[{"label":"Konto entsperren","real_url":"http://microsoft-security-check.com/unlock","suspicious":true,"warning":"Microsoft nutzt niemals Domains mit Bindestrichen wie microsoft-security-check.com. Das ist gefälscht."}]'::jsonb,
 TRUE,
 '["Panikmache: „verlieren Sie alle Ihre Dateien“","Seltsamer Absender, nicht @microsoft.com","Drohung über Anmeldung aus einem anderen Land","Countdown (12 Stunden), um Sie zu Eile zu zwingen"]'::jsonb,
 '[]'::jsonb,
 'Das ist Phishing. Microsoft ruft Sie nie ungefragt an oder schreibt Sie wegen gesperrter Konten an. Erhalten Sie so etwas? Ignorieren und selbst unter account.microsoft.com anmelden, um zu prüfen.',
 80),

-- 9. REAL — Apotheke
('de',
 'Apotheke am Rathaus',
 'apotheke@apotheke-am-rathaus.de',
 'Eigene Domain der Apotheke — passt.',
 'vor 5 Tagen',
 'Ihre Medikamente sind abholbereit',
 'Ihre Medikamente sind abholbereit in der Apotheke am Rathaus. Sie können sie...',
 E'Sehr geehrte Frau Müller,\n\nIhre Medikamente sind abholbereit in der Apotheke am Rathaus, Hauptstraße 12.\n\nWir haben heute bis 18:30 Uhr geöffnet. Bringen Sie bitte Ihren Abholschein oder einen Ausweis mit.\n\nFragen? Rufen Sie 030 111 22 33 an.\n\nApotheke am Rathaus',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Persönliche Anrede","Bekannte Apotheke, eigene Domain","Konkrete Information: Adresse, Öffnungszeit","Kein Link, keine Zahlung","Telefonnummer, die Sie selbst anrufen können"]'::jsonb,
 'Das ist eine normale Nachricht Ihrer Apotheke. Keine Gefahr.',
 90),

-- 10. PHISHING — Amazon Gewinnspiel
('de',
 'Amazon',
 'gewinn@amazon-gewinnspiel.net',
 'Echte Amazon-Mails kommen von @amazon.de, nicht von @amazon-gewinnspiel.net.',
 'vor 6 Tagen',
 'Herzlichen Glückwunsch! Sie haben ein iPhone 15 gewonnen',
 'Sie sind unser glücklicher Gewinner! Fordern Sie Ihren Preis innerhalb von 2 Stunden an...',
 E'<div class="eml fam-retail" style="--brand:#232f3e;--cta:#232f3e"><div class="eml-hero"><span class="eml-logo" style="text-transform:lowercase;font-weight:800">amazon</span></div><div class="eml-body"><p>Sehr geehrter Kunde,</p><p>Herzlichen Glückwunsch! Sie wurden aus Tausenden von Teilnehmern als Gewinner eines brandneuen iPhone 15 gezogen.</p><p>Fordern Sie Ihren Preis innerhalb von 2 Stunden an, indem Sie einen kleinen Versandbeitrag zahlen: {{link:0}}</p><p>Amazon Gewinnspiel-Team</p></div><div class="eml-foot"><p>Dies ist eine automatische Nachricht — bitte antworten Sie nicht darauf.</p><p>© 2026 amazon</p></div></div>',
 '[{"label":"Preis anfordern","real_url":"http://amazon-gewinnspiel.net/anfordern","suspicious":true,"warning":"Amazon nutzt nur amazon.de. Ein „Versandbeitrag“ für einen gewonnenen Preis ist immer Betrug."}]'::jsonb,
 TRUE,
 '["Sie haben überhaupt nicht an einem Gewinnspiel teilgenommen","Fordert einen „Versandbeitrag“ — Preise werden nie gegen Bezahlung verschickt","Druck: „innerhalb von 2 Stunden“","Absender @amazon-gewinnspiel.net statt @amazon.de"]'::jsonb,
 '[]'::jsonb,
 'Das ist Phishing. Sie können keinen Preis gewinnen, an dem Sie nicht teilgenommen haben. Ein echtes Gewinnspiel verlangt niemals Versandgebühren im Voraus.',
 100);


-- ============================================================
-- NEDERLANDS (BELGIË / VLAAMS) — nl-BE
-- ============================================================

-- ======== VOORBEELDEN (nl-BE) ========
INSERT INTO examples (locale, channel, sender, subject, body, annotations, sort_order) VALUES
('nl-BE', 'email',
 'BNP Paribas Fortis <service@bnp-veilig-login.com>',
 'Belangrijk: uw rekening wordt geblokkeerd',
 E'Geachte klant,\n\nWij hebben een verdachte transactie op uw rekening opgemerkt. Binnen 24 uur wordt uw rekening GEBLOKKEERD als u uw gegevens niet bevestigt.\n\nKlik hier om uw rekening te beveiligen: http://bnp-veilig-login.com/login\n\nMet vriendelijke groeten,\nBNP Paribas Fortis Beveiligingsteam',
 '[{"quote": "service@bnp-veilig-login.com", "note": "Kijk naar wat NA de @ staat: bnp-veilig-login.com. Dat is niet BNP Paribas Fortis. De echte bank gebruikt altijd @bnpparibasfortis.com. Het deel vóór de @ (\"service\") mag de oplichter zelf verzinnen."}, {"quote": "GEBLOKKEERD als u uw gegevens niet bevestigt", "note": "Angst maken en haast. Een echte bank doet dit nooit."}, {"quote": "Geachte klant", "note": "Geen naam. Uw bank kent uw naam."}, {"quote": "http://bnp-veilig-login.com/login", "note": "Vreemde link die niet van BNP Paribas Fortis is. Niet op klikken!"}]'::jsonb,
 10),

('nl-BE', 'email',
 'FOD Financiën <noreply@minfin-teruggave.be>',
 'U heeft recht op € 423,50 terugbetaling',
 E'Beste burger,\n\nNa controle blijkt u recht te hebben op een belastingteruggave van € 423,50. Vul snel uw gegevens in om het bedrag te ontvangen.\n\nKlik hier: http://minfin-teruggave.be/claim\n\nFOD Financiën',
 '[{"quote": "noreply@minfin-teruggave.be", "note": "Kijk na de @: minfin-teruggave.be. Dat is NIET de FOD Financiën. Het echte domein is minfin.fed.be."}, {"quote": "Beste burger", "note": "Algemene aanspreking zonder uw naam. De FOD Financiën kent u."}, {"quote": "recht te hebben op een belastingteruggave van € 423,50", "note": "Belofte van geld is een klassieke lokker. De FOD Financiën mailt nooit over teruggaven."}, {"quote": "http://minfin-teruggave.be/claim", "note": "Vreemde link, niet myminfin.be. Niet op klikken."}]'::jsonb,
 20),

('nl-BE', 'email',
 'itsme <info@itsme-controle.org>',
 'Bevestig uw itsme-gegevens',
 E'Geachte heer/mevrouw,\n\nWij vragen u om uw itsme opnieuw te bevestigen. Klik op onderstaande link en meld u aan met uw gebruikersnaam en paswoord.\n\nhttp://itsme-controle.org/aanmelden\n\nBedankt,\nitsme',
 '[{"quote": "info@itsme-controle.org", "note": "Kijk na de @: itsme-controle.org. Het echte domein is itsme.be — niets anders."}, {"quote": "Geachte heer/mevrouw", "note": "Algemene aanspreking. Een echte organisatie kent uw naam."}, {"quote": "meld u aan met uw gebruikersnaam en paswoord", "note": "itsme werkt via uw eigen app en vraagt NOOIT uw paswoord per e-mail. Altijd phishing."}, {"quote": "http://itsme-controle.org/aanmelden", "note": "Vreemde link. Gebruik itsme alleen via de officiële app of via itsme.be."}]'::jsonb,
 30);

-- ======== INBOX (nl-BE) ========
INSERT INTO inbox_messages
  (locale, sender_name, sender_address, sender_note, received_label, subject, preview, body, links, is_phishing, red_flags, green_flags, explanation, sort_order) VALUES

-- 1. PHISHING — BNP Paribas Fortis
('nl-BE',
 'BNP Paribas Fortis',
 'service@bnp-veilig-login.com',
 'Kijk na de @: bnp-veilig-login.com. BNP Paribas Fortis gebruikt altijd @bnpparibasfortis.com.',
 'vandaag 08:42',
 'Belangrijk: uw rekening wordt geblokkeerd',
 'Geachte klant, wij hebben een verdachte transactie opgemerkt op uw...',
 E'<div class="eml fam-bank" style="--brand:#00965e;--cta:#00965e;--logo:#00905a"><div class="eml-top"><span class="eml-logo">BNP Paribas Fortis</span></div><div class="eml-body"><p>Geachte klant,</p><p>Wij hebben een verdachte transactie opgemerkt op uw rekening. Om misbruik te voorkomen wordt uw rekening binnen 24 uur GEBLOKKEERD als u uw gegevens niet bevestigt.</p><p>Bevestig onmiddellijk via {{link:0}}.</p><p>Met vriendelijke groeten,<br>BNP Paribas Fortis Beveiligingsteam</p></div><div class="eml-foot"><p>Dit is een automatisch verzonden bericht — antwoorden is niet mogelijk.</p><p>© 2026 BNP Paribas Fortis</p></div></div>',
 '[{"label":"deze beveiligde pagina","real_url":"http://bnp-veilig-login.com/login","suspicious":true,"warning":"Deze link gaat NIET naar bnpparibasfortis.com maar naar bnp-veilig-login.com. Dat is een nepwebsite die op BNP Paribas Fortis lijkt."}]'::jsonb,
 TRUE,
 '["Afzenderadres eindigt niet op @bnpparibasfortis.com","Dreigt met blokkering binnen 24 uur — paniek maken","Aanspreking \"Geachte klant\" zonder uw naam","Link gaat naar bnp-veilig-login.com, niet naar bnpparibasfortis.com"]'::jsonb,
 '[]'::jsonb,
 'Dit is phishing. BNP Paribas Fortis stuurt nooit e-mails om u onder tijdsdruk uw gegevens te laten bevestigen. Had u getwijfeld? Open dan altijd zelf de Easy Banking App of bel Card Stop (078 170 170) om uw kaart te blokkeren.',
 10),

-- 2. REAL — Huisarts
('nl-BE',
 'Huisartsenpraktijk De Linde',
 'praktijk@huisartsendelinde.be',
 'Het adres eindigt op het eigen domein van de praktijk — normaal.',
 'vandaag 09:15',
 'Herinnering: uw afspraak morgen om 10u15',
 'Beste mevrouw Peeters, dit is een herinnering aan uw afspraak...',
 E'Beste mevrouw Peeters,\n\nDit is een herinnering aan uw afspraak bij dokter Vermeulen morgen om 10u15.\n\nWilt u afzeggen of verzetten? Bel dan 03 123 45 67.\n\nTot morgen.\n\nHuisartsenpraktijk De Linde\nMarkt 12, Antwerpen',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Persoonlijke aanspreking met uw naam","Geen link, geen knop","Telefoonnummer om zelf te bellen","Geen vraag om gegevens of geld","Concrete, verwachte informatie"]'::jsonb,
 'Dit is een gewone afspraakherinnering. Geen links, geen gegevens gevraagd — u kunt gewoon bellen als u iets wilt wijzigen.',
 20),

-- 3. PHISHING — FOD Financiën
('nl-BE',
 'FOD Financiën',
 'noreply@minfin-teruggave.be',
 'Niet @minfin.fed.be — dus niet van de FOD Financiën, ook al staat de naam er in.',
 'vandaag 10:03',
 'U heeft recht op € 423,50 terugbetaling',
 'Na controle blijkt u recht te hebben op een belastingteruggave...',
 E'<div class="eml fam-gov" style="--brand:#005a9c;--cta:#005a9c"><div class="eml-top"><span class="eml-logo">FOD Financiën</span></div><div class="eml-body"><p>Beste burger,</p><p>Na controle blijkt u recht te hebben op een belastingteruggave van € 423,50.</p><p>Vul uw gegevens in om het bedrag binnen 3 werkdagen te ontvangen: {{link:0}}.</p><p>FOD Financiën</p></div><div class="eml-foot"><p>Dit is een automatisch verzonden bericht — antwoorden is niet mogelijk.</p><p>© 2026 FOD Financiën</p></div></div>',
 '[{"label":"MyMinfin","real_url":"http://minfin-teruggave.be/claim","suspicious":true,"warning":"Het echte adres is myminfin.be. Deze link gaat naar minfin-teruggave.be — een nepsite."}]'::jsonb,
 TRUE,
 '["Afzender is @minfin-teruggave.be, niet @minfin.fed.be","De FOD Financiën stuurt NOOIT e-mails over teruggaven","Belooft geld om u op de link te laten klikken","Link gaat naar een onbekende website"]'::jsonb,
 '[]'::jsonb,
 'Dit is phishing. De FOD Financiën communiceert over teruggaven via MyMinfin of per post — nooit per e-mail met een link. Bij twijfel: meld u zelf aan bij myminfin.be met itsme of uw eID.',
 30),

-- 4. PHISHING — bpost
('nl-BE',
 'bpost Tracking',
 'track@bpost-levering.info',
 'Het echte domein is bpost.be. ".info" is vaak verdacht.',
 'gisteren 16:48',
 'Uw pakket kan niet bezorgd worden',
 'Uw pakket wacht op u. Er zijn nog onbetaalde invoerkosten...',
 E'<div class="eml fam-parcel" style="--brand:#e30613;--cta:#e30613"><div class="eml-hero"><span class="eml-logo">bpost</span></div><div class="eml-body"><p>Beste klant,</p><p>Uw pakket wacht in het sorteercentrum. Er zijn nog onbetaalde invoerkosten (€ 1,95).</p><p>Betaal onmiddellijk om uitstel te vermijden: {{link:0}}</p><p>bpost</p></div><div class="eml-foot"><p>Dit is een automatisch verzonden bericht — antwoorden is niet mogelijk.</p><p>© 2026 bpost</p></div></div>',
 '[{"label":"bpost-levering.info/betaal","real_url":"http://bpost-levering.info/betaal","suspicious":true,"warning":"Het echte adres van bpost is bpost.be. \".info\"-domeinen worden veel gebruikt voor oplichting."}]'::jsonb,
 TRUE,
 '["Klein bedrag (€ 1,95) om u zonder nadenken te laten betalen","Afzender @bpost-levering.info in plaats van @bpost.be","\"Betaal onmiddellijk\" — druk uitoefenen","Geen naam, algemene aanspreking"]'::jsonb,
 '[]'::jsonb,
 'Dit is phishing. bpost vraagt nooit per e-mail om invoerkosten. Verwacht u een pakket? Controleer het zelf via de officiële My bpost app of via bpost.be.',
 40),

-- 5. REAL — Bibliotheek
('nl-BE',
 'Bibliotheek Antwerpen',
 'info@bibliotheek.antwerpen.be',
 'Officieel domein van de stad Antwerpen — klopt.',
 'gisteren 11:22',
 'Uw geleend boek moet terug',
 'Beste mevrouw Peeters, dit is een herinnering dat u uw boek...',
 E'Beste mevrouw Peeters,\n\nDit is een herinnering dat u het boek "Het verdriet van België" ten laatste op vrijdag 28 april moet terugbrengen naar een filiaal van de Bibliotheek Antwerpen.\n\nVragen? Bel 03 338 88 88 of kom langs.\n\nMet vriendelijke groeten,\nBibliotheek Antwerpen',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Persoonlijke aanspreking","Concrete informatie over uw boek en datum","Geen link, geen betaling","Telefoonnummer dat u zelf kunt bellen"]'::jsonb,
 'Dit is een echte herinnering van uw bibliotheek. Geen gevaar.',
 50),

-- 6. PHISHING — itsme
('nl-BE',
 'itsme',
 'info@itsme-controle.org',
 'Het echte domein is itsme.be. ".org" op itsme is verdacht.',
 'eergisteren 14:30',
 'Bevestig uw itsme-gegevens',
 'Geachte heer/mevrouw, wij vragen u om uw itsme opnieuw te bevestigen...',
 E'<div class="eml fam-gov" style="--brand:#ff4612;--cta:#ff4612;--logo:#e53f10"><div class="eml-top"><span class="eml-logo">itsme®</span></div><div class="eml-body"><p>Geachte heer/mevrouw,</p><p>In verband met een veiligheidscontrole vragen wij u uw itsme opnieuw te bevestigen.</p><p>Meld u aan via {{link:0}} en vul uw gebruikersnaam en paswoord in.</p><p>Bedankt,<br>itsme</p></div><div class="eml-foot"><p>Dit is een automatisch verzonden bericht — antwoorden is niet mogelijk.</p><p>© 2026 itsme®</p></div></div>',
 '[{"label":"deze beveiligde pagina","real_url":"http://itsme-controle.org/aanmelden","suspicious":true,"warning":"itsme vraagt NOOIT per e-mail om uw paswoord. Het echte adres is itsme.be — niet itsme-controle.org. itsme werkt alleen via de eigen app."}]'::jsonb,
 TRUE,
 '["Afzender @itsme-controle.org — niet @itsme.be","Vraagt om gebruikersnaam én paswoord (doet itsme NOOIT, want itsme werkt zonder paswoord)","Algemene aanspreking \"Geachte heer/mevrouw\"","Link naar onbekend \".org\"-adres"]'::jsonb,
 '[]'::jsonb,
 'Dit is phishing. itsme werkt via uw eigen gsm-app met vingerafdruk of code — niet via e-mail met een link. Gebruik itsme alleen via de officiële app.',
 60),

-- 7. REAL — Proximus factuur
('nl-BE',
 'Proximus',
 'no-reply@proximus.be',
 'Afzender @proximus.be is het officiële domein — klopt.',
 '3 dagen geleden',
 'Uw factuur van april staat klaar',
 'Beste klant, uw factuur van € 49,95 staat klaar in MyProximus...',
 E'<div class="eml fam-tech" style="--brand:#5c2d91;--cta:#5c2d91"><div class="eml-top"><span class="eml-logo">Proximus</span></div><div class="eml-body"><p>Beste mevrouw Peeters,</p><p>Uw Proximus-factuur van € 49,95 voor de maand april staat klaar in MyProximus.</p><p>U kunt de factuur bekijken door zelf aan te melden op proximus.be/myproximus (typ dit adres zelf in uw browser of gebruik de MyProximus-app).</p><p>Het bedrag wordt op 1 mei automatisch van uw rekening afgeschreven.</p><p>Proximus Klantendienst</p></div><div class="eml-foot"><p>Dit is een automatisch verzonden bericht — antwoorden is niet mogelijk.</p><p>© 2026 Proximus</p></div></div>',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Afzender is @proximus.be (echt)","Persoonlijke aanspreking","Bedrag en datum kloppen met uw abonnement","Geen klikbare link — u wordt gevraagd ZELF aan te melden","Verwachte maandelijkse factuur"]'::jsonb,
 'Dit is een echte Proximus-factuurmelding. Let op: ook bij een echt bericht is het verstandig om NIET op links te klikken maar zelf naar de website of app te gaan.',
 70),

-- 8. PHISHING — Microsoft
('nl-BE',
 'Microsoft',
 'support@microsoft-security-check.com',
 'Het echte Microsoft-domein is microsoft.com, niet microsoft-security-check.com.',
 '4 dagen geleden',
 'Waarschuwing: uw account is geblokkeerd',
 'Uw Microsoft-account is geblokkeerd wegens verdachte activiteit...',
 E'<div class="eml fam-tech" style="--brand:#0067b8;--cta:#0067b8"><div class="eml-top"><span class="eml-logo">Microsoft</span></div><div class="eml-body"><p>Beste gebruiker,</p><p>Uw Microsoft-account is tijdelijk geblokkeerd wegens verdachte aanmeldpogingen vanuit Rusland.</p><p>Als u uw account niet binnen 12 uur ontgrendelt, verliest u al uw bestanden.</p><p>Ontgrendel uw account: {{link:0}}</p></div><div class="eml-foot"><p>Dit is een automatisch verzonden bericht — antwoorden is niet mogelijk.</p><p>© 2026 Microsoft</p></div></div>',
 '[{"label":"Ontgrendel account","real_url":"http://microsoft-security-check.com/unlock","suspicious":true,"warning":"Microsoft gebruikt nooit domeinen met koppeltekens zoals microsoft-security-check.com. Dit is nep."}]'::jsonb,
 TRUE,
 '["Paniek: \"verliest u al uw bestanden\"","Rare afzender, niet @microsoft.com","Dreiging over aanmelding vanuit een ander land","Afteltijd (12 uur) om u te laten haasten"]'::jsonb,
 '[]'::jsonb,
 'Dit is phishing. Microsoft belt of mailt u nooit ongevraagd over geblokkeerde accounts. Ontvangt u zoiets? Negeer het en meld u zelf aan op account.microsoft.com om te controleren.',
 80),

-- 9. REAL — Apotheek
('nl-BE',
 'Apotheek Peeters',
 'apotheek@apotheek-peeters.be',
 'Eigen domein van de apotheek — klopt.',
 '5 dagen geleden',
 'Uw medicijnen liggen klaar',
 'Uw medicijnen liggen klaar bij Apotheek Peeters. U kunt ze afhalen...',
 E'Beste mevrouw Peeters,\n\nUw medicijnen liggen klaar bij Apotheek Peeters, Markt 12.\n\nWij zijn vandaag open tot 18u30. Breng uw afhaalbon of identiteitskaart mee.\n\nVragen? Bel 03 111 22 33.\n\nApotheek Peeters',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Persoonlijke aanspreking","Bekende apotheek, eigen domein","Concrete informatie: adres, openingsuren","Geen link, geen betaling","Telefoonnummer om zelf te bellen"]'::jsonb,
 'Dit is een normale melding van uw apotheek. Geen gevaar.',
 90),

-- 10. PHISHING — Bol.com winactie
('nl-BE',
 'Bol.com',
 'winactie@bol-winactie.net',
 'Echte Bol.com-mails komen van @bol.com, niet van @bol-winactie.net.',
 '6 dagen geleden',
 'Gefeliciteerd! U heeft een iPhone 15 gewonnen',
 'U bent onze gelukkige winnaar! Claim uw prijs binnen 2 uur...',
 E'<div class="eml fam-retail" style="--brand:#0000a4;--cta:#0000a4"><div class="eml-hero"><span class="eml-logo" style="text-transform:lowercase;font-weight:800">bol.com</span></div><div class="eml-body"><p>Beste klant,</p><p>Gefeliciteerd! U bent uit duizenden deelnemers getrokken als onze winnaar van een gloednieuwe iPhone 15.</p><p>Claim uw prijs binnen 2 uur door een kleine verzendbijdrage te betalen: {{link:0}}</p><p>Bol.com Winactie Team</p></div><div class="eml-foot"><p>Dit is een automatisch verzonden bericht — antwoorden is niet mogelijk.</p><p>© 2026 bol.com</p></div></div>',
 '[{"label":"Claim uw prijs","real_url":"http://bol-winactie.net/claim","suspicious":true,"warning":"Bol.com gebruikt alleen bol.com als adres. Een \"verzendbijdrage\" bij een gewonnen prijs is altijd oplichterij."}]'::jsonb,
 TRUE,
 '["U heeft helemaal niet deelgenomen aan een winactie","Vraagt om \"verzendbijdrage\" — prijzen zijn nooit tegen betaling","Druk: \"binnen 2 uur\"","Afzender @bol-winactie.net in plaats van @bol.com"]'::jsonb,
 '[]'::jsonb,
 'Dit is phishing. U kunt geen prijs winnen waar u niet aan heeft deelgenomen. Een echte winactie vraagt nooit om een verzendbijdrage op voorhand.',
 100);


-- ============================================================
-- FRANÇAIS (BELGIQUE) — fr-BE
-- ============================================================

-- ======== VOORBEELDEN (fr-BE) ========
INSERT INTO examples (locale, channel, sender, subject, body, annotations, sort_order) VALUES
('fr-BE', 'email',
 'Belfius <service@belfius-securise.com>',
 'Important : votre compte va être bloqué',
 E'Cher client,\n\nNous avons détecté une transaction suspecte sur votre compte. Votre compte sera BLOQUÉ sous 24 heures si vous ne confirmez pas vos informations.\n\nCliquez ici pour sécuriser votre compte : http://belfius-securise.com/verifier\n\nCordialement,\nService Sécurité Belfius',
 '[{"quote": "service@belfius-securise.com", "note": "Regardez ce qui vient APRÈS le @ : belfius-securise.com. Ce n''est pas Belfius. La vraie banque utilise toujours @belfius.be. Ce qui est AVANT le @ (« service ») peut être choisi par l''escroc."}, {"quote": "BLOQUÉ sous 24 heures si vous ne confirmez pas vos informations", "note": "On vous fait peur et on vous presse. Une vraie banque ne fait jamais cela."}, {"quote": "Cher client", "note": "Pas de nom. Votre banque connaît votre nom."}, {"quote": "http://belfius-securise.com/verifier", "note": "Lien étrange qui n''est pas de Belfius. Ne cliquez pas !"}]'::jsonb,
 10),

('fr-BE', 'email',
 'SPF Finances <noreply@minfin-remboursement.be>',
 'Vous avez droit à un remboursement de 423,50 €',
 E'Cher contribuable,\n\nAprès vérification, vous avez droit à un remboursement d''impôts de 423,50 €. Remplissez vite vos informations pour recevoir le montant.\n\nCliquez ici : http://minfin-remboursement.be/reclamer\n\nSPF Finances',
 '[{"quote": "noreply@minfin-remboursement.be", "note": "Regardez après le @ : minfin-remboursement.be. Ce n''est PAS le SPF Finances. Le vrai domaine est minfin.fed.be."}, {"quote": "Cher contribuable", "note": "Salutation générique sans votre nom. Le SPF Finances connaît votre identité."}, {"quote": "droit à un remboursement d''impôts de 423,50 €", "note": "La promesse d''argent est un appât classique. Le SPF Finances ne communique jamais un remboursement par e-mail avec un lien."}, {"quote": "http://minfin-remboursement.be/reclamer", "note": "Lien étrange, ce n''est pas myminfin.be. Ne cliquez pas."}]'::jsonb,
 20),

('fr-BE', 'email',
 'itsme <info@itsme-controle.org>',
 'Confirmez vos informations itsme',
 E'Madame, Monsieur,\n\nNous vous demandons de confirmer à nouveau vos informations itsme. Cliquez sur le lien ci-dessous et connectez-vous avec votre identifiant et votre mot de passe.\n\nhttp://itsme-controle.org/connexion\n\nMerci,\nitsme',
 '[{"quote": "info@itsme-controle.org", "note": "Regardez après le @ : itsme-controle.org. Le vrai domaine est itsme.be — rien d''autre."}, {"quote": "Madame, Monsieur", "note": "Salutation générique. Une vraie organisation connaît votre nom."}, {"quote": "connectez-vous avec votre identifiant et votre mot de passe", "note": "itsme fonctionne via votre application personnelle et ne demande JAMAIS votre mot de passe par e-mail. Toujours du hameçonnage."}, {"quote": "http://itsme-controle.org/connexion", "note": "Lien étrange. Utilisez itsme uniquement via l''application officielle ou via itsme.be."}]'::jsonb,
 30);

-- ======== INBOX (fr-BE) ========
INSERT INTO inbox_messages
  (locale, sender_name, sender_address, sender_note, received_label, subject, preview, body, links, is_phishing, red_flags, green_flags, explanation, sort_order) VALUES

-- 1. PHISHING — Belfius
('fr-BE',
 'Belfius',
 'service@belfius-securise.com',
 'Regardez après le @ : belfius-securise.com. Le vrai Belfius utilise toujours @belfius.be.',
 'aujourd''hui 08:42',
 'Important : votre compte va être bloqué',
 'Cher client, nous avons détecté une transaction suspecte sur votre...',
 E'<div class="eml fam-bank" style="--brand:#c30045;--cta:#c30045"><div class="eml-top"><span class="eml-logo">Belfius</span></div><div class="eml-body"><p>Cher client,</p><p>Nous avons détecté une transaction suspecte sur votre compte. Pour éviter tout abus, votre compte sera BLOQUÉ sous 24 heures si vous ne confirmez pas vos informations.</p><p>Confirmez immédiatement via {{link:0}}.</p><p>Cordialement,<br>Service Sécurité Belfius</p></div><div class="eml-foot"><p>Ceci est un message automatique — merci de ne pas y répondre.</p><p>© 2026 Belfius</p></div></div>',
 '[{"label":"cette page sécurisée","real_url":"http://belfius-securise.com/verifier","suspicious":true,"warning":"Ce lien ne va PAS vers belfius.be mais vers belfius-securise.com. C''est un faux site qui imite Belfius."}]'::jsonb,
 TRUE,
 '["L''adresse de l''expéditeur ne finit pas par @belfius.be","Menace d''un blocage sous 24 heures — création de panique","Salutation « Cher client » sans votre nom","Le lien mène à belfius-securise.com, pas à belfius.be"]'::jsonb,
 '[]'::jsonb,
 'C''est du hameçonnage. Belfius ne vous envoie jamais d''e-mail sous pression pour confirmer vos informations. En cas de doute, ouvrez vous-même l''application Belfius Mobile ou appelez Card Stop (078 170 170) pour bloquer votre carte.',
 10),

-- 2. REAL — Médecin
('fr-BE',
 'Cabinet médical des Tilleuls',
 'cabinet@cabinet-tilleuls.be',
 'L''adresse finit par le domaine du cabinet — normal.',
 'aujourd''hui 09:15',
 'Rappel : votre rendez-vous demain à 10h15',
 'Chère Madame Dubois, rappel de votre rendez-vous...',
 E'Chère Madame Dubois,\n\nCeci est un rappel de votre rendez-vous avec le Dr Vermeulen demain à 10h15.\n\nPour annuler ou reporter, appelez le 02 123 45 67.\n\nÀ demain.\n\nCabinet médical des Tilleuls\nRue de la Loi 12, Bruxelles',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Salutation personnelle avec votre nom","Aucun lien, aucun bouton","Numéro de téléphone que vous pouvez appeler vous-même","Pas de demande d''informations ou d''argent","Information concrète et attendue"]'::jsonb,
 'C''est un simple rappel de rendez-vous. Pas de liens, pas d''informations demandées — vous pouvez simplement appeler si vous voulez modifier quelque chose.',
 20),

-- 3. PHISHING — SPF Finances
('fr-BE',
 'SPF Finances',
 'noreply@minfin-remboursement.be',
 'Pas @minfin.fed.be — donc pas vraiment du SPF Finances, même si le nom apparaît.',
 'aujourd''hui 10:03',
 'Vous avez droit à un remboursement de 423,50 €',
 'Après vérification, vous avez droit à un remboursement...',
 E'<div class="eml fam-gov" style="--brand:#005a9c;--cta:#005a9c"><div class="eml-top"><span class="eml-logo">SPF Finances</span></div><div class="eml-body"><p>Cher contribuable,</p><p>Après vérification, vous avez droit à un remboursement d''impôts de 423,50 €.</p><p>Remplissez vos informations pour recevoir le montant sous 3 jours ouvrables : {{link:0}}.</p><p>SPF Finances</p></div><div class="eml-foot"><p>Ceci est un message automatique — merci de ne pas y répondre.</p><p>© 2026 SPF Finances</p></div></div>',
 '[{"label":"Mon espace MyMinfin","real_url":"http://minfin-remboursement.be/reclamer","suspicious":true,"warning":"La vraie adresse est myminfin.be. Ce lien mène à minfin-remboursement.be — un faux site."}]'::jsonb,
 TRUE,
 '["Expéditeur @minfin-remboursement.be, pas @minfin.fed.be","Le SPF Finances n''envoie JAMAIS d''e-mail concernant les remboursements","Promet de l''argent pour vous faire cliquer","Le lien mène à un site inconnu"]'::jsonb,
 '[]'::jsonb,
 'C''est du hameçonnage. Le SPF Finances communique sur les remboursements via MyMinfin ou par courrier — jamais par e-mail avec un lien. En cas de doute : connectez-vous vous-même sur myminfin.be avec itsme ou votre eID.',
 30),

-- 4. PHISHING — bpost
('fr-BE',
 'bpost Suivi',
 'suivi@bpost-livraison.info',
 'Le vrai domaine est bpost.be. « .info » est souvent suspect.',
 'hier 16:48',
 'Votre colis n''a pas pu être livré',
 'Votre colis vous attend. Des frais d''importation restent impayés...',
 E'<div class="eml fam-parcel" style="--brand:#e30613;--cta:#e30613"><div class="eml-hero"><span class="eml-logo">bpost</span></div><div class="eml-body"><p>Cher client,</p><p>Votre colis est en attente au centre de tri. Des frais d''importation restent impayés (1,95 €).</p><p>Payez immédiatement pour éviter un retard : {{link:0}}</p><p>bpost</p></div><div class="eml-foot"><p>Ceci est un message automatique — merci de ne pas y répondre.</p><p>© 2026 bpost</p></div></div>',
 '[{"label":"bpost-livraison.info/payer","real_url":"http://bpost-livraison.info/payer","suspicious":true,"warning":"La vraie adresse de bpost est bpost.be. Les domaines en « .info » sont très utilisés pour des arnaques."}]'::jsonb,
 TRUE,
 '["Petit montant (1,95 €) pour que vous payiez sans réfléchir","Expéditeur @bpost-livraison.info au lieu de @bpost.be","« Payez immédiatement » — pression temporelle","Pas de nom, salutation générique"]'::jsonb,
 '[]'::jsonb,
 'C''est du hameçonnage. bpost ne demande jamais de frais d''importation par e-mail. Vous attendez un colis ? Vérifiez vous-même via l''application officielle My bpost ou sur bpost.be.',
 40),

-- 5. REAL — Bibliothèque
('fr-BE',
 'Bibliothèque de Bruxelles',
 'accueil@bibliotheque.bruxelles.be',
 'Domaine officiel de la Ville de Bruxelles — correct.',
 'hier 11:22',
 'Votre livre emprunté doit être rendu',
 'Chère Madame Dubois, rappel que votre livre...',
 E'Chère Madame Dubois,\n\nCeci est un rappel que le livre « Le Chagrin des Belges » doit être retourné dans une succursale de la Bibliothèque de Bruxelles avant le vendredi 28 avril.\n\nDes questions ? Appelez le 02 279 37 60 ou passez nous voir.\n\nCordialement,\nBibliothèque de Bruxelles',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Salutation personnelle","Information concrète sur votre livre et la date","Aucun lien, aucun paiement","Numéro de téléphone que vous pouvez appeler vous-même"]'::jsonb,
 'C''est un vrai rappel de votre bibliothèque. Aucun danger.',
 50),

-- 6. PHISHING — itsme
('fr-BE',
 'itsme',
 'info@itsme-controle.org',
 'Le vrai domaine est itsme.be. « .org » sur itsme est suspect.',
 'avant-hier 14:30',
 'Confirmez vos informations itsme',
 'Madame, Monsieur, nous vous demandons de confirmer à nouveau...',
 E'<div class="eml fam-gov" style="--brand:#ff4612;--cta:#ff4612;--logo:#e53f10"><div class="eml-top"><span class="eml-logo">itsme®</span></div><div class="eml-body"><p>Madame, Monsieur,</p><p>Dans le cadre d''un contrôle de sécurité, nous vous demandons de confirmer à nouveau vos informations itsme.</p><p>Connectez-vous via {{link:0}} et saisissez votre identifiant et votre mot de passe.</p><p>Merci,<br>itsme</p></div><div class="eml-foot"><p>Ceci est un message automatique — merci de ne pas y répondre.</p><p>© 2026 itsme®</p></div></div>',
 '[{"label":"cette page sécurisée","real_url":"http://itsme-controle.org/connexion","suspicious":true,"warning":"itsme ne demande JAMAIS votre mot de passe par e-mail. La vraie adresse est itsme.be — pas itsme-controle.org. itsme fonctionne uniquement via sa propre application."}]'::jsonb,
 TRUE,
 '["Expéditeur @itsme-controle.org — pas @itsme.be","Demande votre identifiant ET votre mot de passe (itsme ne fait JAMAIS cela, puisque itsme fonctionne sans mot de passe)","Salutation générique « Madame, Monsieur »","Lien vers une adresse inconnue en « .org »"]'::jsonb,
 '[]'::jsonb,
 'C''est du hameçonnage. itsme fonctionne via votre application GSM avec empreinte digitale ou code — jamais par e-mail avec un lien. Utilisez itsme uniquement via l''application officielle.',
 60),

-- 7. REAL — Proximus
('fr-BE',
 'Proximus',
 'no-reply@proximus.be',
 'L''expéditeur @proximus.be est le domaine officiel — correct.',
 'il y a 3 jours',
 'Votre facture d''avril est disponible',
 'Cher client, votre facture de 49,95 € est disponible dans MyProximus...',
 E'<div class="eml fam-tech" style="--brand:#5c2d91;--cta:#5c2d91"><div class="eml-top"><span class="eml-logo">Proximus</span></div><div class="eml-body"><p>Chère Madame Dubois,</p><p>Votre facture Proximus de 49,95 € pour le mois d''avril est disponible dans MyProximus.</p><p>Vous pouvez consulter la facture en vous connectant vous-même à proximus.be/myproximus (tapez cette adresse vous-même dans votre navigateur ou utilisez l''application MyProximus).</p><p>Le montant sera prélevé automatiquement sur votre compte le 1er mai.</p><p>Service client Proximus</p></div><div class="eml-foot"><p>Ceci est un message automatique — merci de ne pas y répondre.</p><p>© 2026 Proximus</p></div></div>',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Expéditeur @proximus.be (réel)","Salutation personnelle","Le montant et la date correspondent à votre abonnement","Pas de lien cliquable — on vous demande de vous connecter VOUS-MÊME","Facture mensuelle attendue"]'::jsonb,
 'C''est une vraie notification de facture Proximus. Attention : même pour un vrai message, il est plus prudent de NE PAS cliquer sur les liens mais d''aller vous-même sur le site ou l''application.',
 70),

-- 8. PHISHING — Microsoft
('fr-BE',
 'Microsoft',
 'support@microsoft-security-check.com',
 'Le vrai domaine Microsoft est microsoft.com, pas microsoft-security-check.com.',
 'il y a 4 jours',
 'Avertissement : votre compte est bloqué',
 'Votre compte Microsoft est bloqué suite à une activité suspecte...',
 E'<div class="eml fam-tech" style="--brand:#0067b8;--cta:#0067b8"><div class="eml-top"><span class="eml-logo">Microsoft</span></div><div class="eml-body"><p>Cher utilisateur,</p><p>Votre compte Microsoft est temporairement bloqué suite à des tentatives de connexion suspectes depuis la Russie.</p><p>Si vous ne déverrouillez pas votre compte dans les 12 heures, vous perdrez tous vos fichiers.</p><p>Déverrouillez votre compte : {{link:0}}</p></div><div class="eml-foot"><p>Ceci est un message automatique — merci de ne pas y répondre.</p><p>© 2026 Microsoft</p></div></div>',
 '[{"label":"Déverrouiller le compte","real_url":"http://microsoft-security-check.com/unlock","suspicious":true,"warning":"Microsoft n''utilise jamais de domaines avec des tirets comme microsoft-security-check.com. C''est faux."}]'::jsonb,
 TRUE,
 '["Panique : « vous perdrez tous vos fichiers »","Expéditeur étrange, pas @microsoft.com","Menace de connexion depuis un autre pays","Compte à rebours (12 heures) pour vous presser"]'::jsonb,
 '[]'::jsonb,
 'C''est du hameçonnage. Microsoft ne vous appelle ni ne vous envoie jamais d''e-mail non sollicité au sujet de comptes bloqués. Vous recevez cela ? Ignorez et connectez-vous vous-même sur account.microsoft.com pour vérifier.',
 80),

-- 9. REAL — Pharmacie
('fr-BE',
 'Pharmacie Dubois',
 'contact@pharmacie-dubois.be',
 'Domaine propre de la pharmacie — correct.',
 'il y a 5 jours',
 'Vos médicaments sont prêts',
 'Vos médicaments sont prêts à la Pharmacie Dubois. Vous pouvez les retirer...',
 E'Chère Madame Dubois,\n\nVos médicaments sont prêts à la Pharmacie Dubois, Rue de la Loi 12.\n\nNous sommes ouverts aujourd''hui jusqu''à 18h30. Apportez votre bon de retrait ou votre carte d''identité.\n\nDes questions ? Appelez le 02 111 22 33.\n\nPharmacie Dubois',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Salutation personnelle","Pharmacie connue, domaine propre","Information concrète : adresse, horaires","Aucun lien, aucun paiement","Numéro de téléphone que vous pouvez appeler vous-même"]'::jsonb,
 'C''est un message normal de votre pharmacie. Aucun danger.',
 90),

-- 10. PHISHING — Bol.com concours
('fr-BE',
 'Bol.com',
 'concours@bol-concours.net',
 'Les vrais e-mails Bol.com viennent de @bol.com, pas de @bol-concours.net.',
 'il y a 6 jours',
 'Félicitations ! Vous avez gagné un iPhone 15',
 'Vous êtes notre heureux gagnant ! Réclamez votre prix sous 2 heures...',
 E'<div class="eml fam-retail" style="--brand:#0000a4;--cta:#0000a4"><div class="eml-hero"><span class="eml-logo" style="text-transform:lowercase;font-weight:800">bol.com</span></div><div class="eml-body"><p>Cher client,</p><p>Félicitations ! Vous avez été tiré au sort parmi des milliers de participants comme notre gagnant d''un iPhone 15 flambant neuf.</p><p>Réclamez votre prix sous 2 heures en payant une petite participation aux frais d''envoi : {{link:0}}</p><p>Équipe Bol.com Concours</p></div><div class="eml-foot"><p>Ceci est un message automatique — merci de ne pas y répondre.</p><p>© 2026 bol.com</p></div></div>',
 '[{"label":"Réclamer votre prix","real_url":"http://bol-concours.net/reclamer","suspicious":true,"warning":"Bol.com n''utilise que bol.com. Une « participation aux frais d''envoi » pour un prix gagné est toujours une arnaque."}]'::jsonb,
 TRUE,
 '["Vous n''avez jamais participé à un concours","Demande une « participation aux frais d''envoi » — un prix ne se paye jamais","Pression : « sous 2 heures »","Expéditeur @bol-concours.net au lieu de @bol.com"]'::jsonb,
 '[]'::jsonb,
 'C''est du hameçonnage. On ne peut pas gagner un prix auquel on n''a pas participé. Un vrai concours ne demande jamais des frais de port à l''avance.',
 100);


-- ============================================================
-- ECHTE BERICHTEN MET EEN LEGITIEME LINK
-- Leert dat niet elke klikbare link verdacht is: het gaat om het
-- domein van de afzender, of het adres waar de link naartoe gaat
-- daarbij past, en of u de mail verwacht. Sort order 45 plaatst het
-- tussen het pakketbericht (40) en de bibliotheek (50).
-- ============================================================

-- Booking.com werkt voor beide doelgroepen (audience = 'both'): zowel
-- privé boekingen als zakelijke reizen gebruiken hetzelfde mailpatroon.
INSERT INTO inbox_messages
  (locale, audience, sender_name, sender_address, sender_note, received_label, subject, preview, body, links, is_phishing, red_flags, green_flags, explanation, sort_order) VALUES

-- NL
('nl', 'both',
 'Booking.com',
 'confirmation@booking.com',
 'Het adres eindigt op @booking.com — het echte domein van het bedrijf.',
 '2 dagen geleden',
 'Uw boeking is bevestigd — Van der Valk Amsterdam',
 'Beste mevrouw Janssen, uw boeking bij Van der Valk Amsterdam is...',
 E'<div class="eml fam-retail" style="--brand:#003580;--cta:#003580"><div class="eml-hero"><span class="eml-logo">Booking.com</span></div><div class="eml-body"><p>Beste mevrouw Janssen,</p><p>Uw boeking bij Van der Valk Amsterdam is bevestigd:</p><p>• Check-in: vrijdag 15 mei, vanaf 15:00<br>• Check-out: zondag 17 mei, vóór 11:00<br>• 1 tweepersoonskamer, 2 nachten<br>• Totaal: € 248,00 (al voldaan)</p><p>U kunt uw boeking bekijken of wijzigen via {{link:0}}.</p><p>We kijken ernaar uit u te mogen verwelkomen.</p><p>Booking.com</p></div><div class="eml-foot"><p>Dit is een automatisch verzonden bericht — antwoorden is niet mogelijk.</p><p>© 2026 Booking.com</p></div></div>',
 '[{"label":"Mijn boekingen","real_url":"https://secure.booking.com/myreservations","suspicious":false,"warning":"Dit is een echte link van booking.com. Het domein klopt (secure.booking.com) en past bij de afzender (@booking.com). Nog veiliger: open zelf de Booking.com-app of typ booking.com in uw browser."}]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Afzender @booking.com is het officiële domein","De link gaat naar secure.booking.com — hetzelfde bedrijf","Persoonlijke aanhef met uw naam","Concrete, verwachte boekingsgegevens","Geen druk, geen vraag om paswoord of pincode"]'::jsonb,
 'Dit is een echte boekingsbevestiging. Belangrijke les: ook echte bedrijven sturen soms klikbare links. Wat u controleert: komt het domein van de afzender overeen met waar de link naartoe gaat? Verwachtte u deze mail? Is er geen tijdsdruk? Zelfs bij echte mails blijft het een goede gewoonte om zelf de app of website te openen in plaats van de link te klikken.',
 45),

-- nl-BE
('nl-BE', 'both',
 'Booking.com',
 'confirmation@booking.com',
 'Het adres eindigt op @booking.com — het echte domein van het bedrijf.',
 '2 dagen geleden',
 'Uw boeking is bevestigd — Van der Valk Antwerpen',
 'Beste mevrouw Peeters, uw boeking bij Van der Valk Antwerpen is...',
 E'<div class="eml fam-retail" style="--brand:#003580;--cta:#003580"><div class="eml-hero"><span class="eml-logo">Booking.com</span></div><div class="eml-body"><p>Beste mevrouw Peeters,</p><p>Uw boeking bij Van der Valk Antwerpen is bevestigd:</p><p>• Check-in: vrijdag 15 mei, vanaf 15u<br>• Check-out: zondag 17 mei, vóór 11u<br>• 1 tweepersoonskamer, 2 nachten<br>• Totaal: € 248,00 (reeds betaald)</p><p>U kunt uw boeking bekijken of wijzigen via {{link:0}}.</p><p>Wij kijken ernaar uit u te mogen verwelkomen.</p><p>Booking.com</p></div><div class="eml-foot"><p>Dit is een automatisch verzonden bericht — antwoorden is niet mogelijk.</p><p>© 2026 Booking.com</p></div></div>',
 '[{"label":"Mijn boekingen","real_url":"https://secure.booking.com/myreservations","suspicious":false,"warning":"Dit is een echte link van booking.com. Het domein klopt (secure.booking.com) en past bij de afzender (@booking.com). Nog veiliger: open zelf de Booking.com-app of typ booking.com in uw browser."}]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Afzender @booking.com is het officiële domein","De link gaat naar secure.booking.com — hetzelfde bedrijf","Persoonlijke aanspreking met uw naam","Concrete, verwachte boekingsgegevens","Geen druk, geen vraag om paswoord of pincode"]'::jsonb,
 'Dit is een echte boekingsbevestiging. Belangrijke les: ook echte bedrijven sturen soms klikbare links. Wat u controleert: komt het domein van de afzender overeen met waar de link naartoe gaat? Verwachtte u deze mail? Is er geen tijdsdruk? Zelfs bij echte mails blijft het een goede gewoonte om zelf de app of website te openen in plaats van de link te klikken.',
 45),

-- EN (UK)
('en', 'both',
 'Booking.com',
 'confirmation@booking.com',
 'The address ends in @booking.com — the company''s real domain.',
 '2 days ago',
 'Your booking is confirmed — Premier Inn London County Hall',
 'Dear Ms Smith, your booking at Premier Inn London is confirmed...',
 E'<div class="eml fam-retail" style="--brand:#003580;--cta:#003580"><div class="eml-hero"><span class="eml-logo">Booking.com</span></div><div class="eml-body"><p>Dear Ms Smith,</p><p>Your booking at Premier Inn London County Hall is confirmed:</p><p>• Check-in: Friday 15 May, from 15:00<br>• Check-out: Sunday 17 May, before 12:00<br>• 1 double room, 2 nights<br>• Total: £198.00 (already paid)</p><p>You can view or change your booking via {{link:0}}.</p><p>We look forward to welcoming you.</p><p>Booking.com</p></div><div class="eml-foot"><p>This is an automated message — please do not reply.</p><p>© 2026 Booking.com</p></div></div>',
 '[{"label":"My bookings","real_url":"https://secure.booking.com/myreservations","suspicious":false,"warning":"This is a real link from booking.com. The domain matches (secure.booking.com) and lines up with the sender (@booking.com). Even safer: open the Booking.com app yourself or type booking.com into your browser."}]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Sender @booking.com is the official domain","The link goes to secure.booking.com — same company","Personal greeting with your name","Specific booking details you were expecting","No urgency, no password or PIN requested"]'::jsonb,
 'This is a genuine booking confirmation. Key lesson: real companies do sometimes send clickable links. What to check: does the sender''s domain match where the link goes? Were you expecting this email? Is there no time pressure? Even with legitimate emails, it remains a good habit to open the app or website yourself rather than clicking the link.',
 45),

-- FR
('fr', 'both',
 'Booking.com',
 'confirmation@booking.com',
 'L''adresse se termine par @booking.com — le vrai domaine de l''entreprise.',
 'il y a 2 jours',
 'Votre réservation est confirmée — Hôtel Mercure Paris Centre',
 'Chère Madame Dupont, votre réservation à l''Hôtel Mercure Paris est...',
 E'<div class="eml fam-retail" style="--brand:#003580;--cta:#003580"><div class="eml-hero"><span class="eml-logo">Booking.com</span></div><div class="eml-body"><p>Chère Madame Dupont,</p><p>Votre réservation à l''Hôtel Mercure Paris Centre est confirmée :</p><p>• Arrivée : vendredi 15 mai, à partir de 15h00<br>• Départ : dimanche 17 mai, avant 12h00<br>• 1 chambre double, 2 nuits<br>• Total : 248,00 € (déjà payé)</p><p>Vous pouvez consulter ou modifier votre réservation via {{link:0}}.</p><p>Nous avons hâte de vous accueillir.</p><p>Booking.com</p></div><div class="eml-foot"><p>Ceci est un message automatique — merci de ne pas y répondre.</p><p>© 2026 Booking.com</p></div></div>',
 '[{"label":"Mes réservations","real_url":"https://secure.booking.com/myreservations","suspicious":false,"warning":"C''est un vrai lien de booking.com. Le domaine correspond (secure.booking.com) et concorde avec l''expéditeur (@booking.com). Encore plus sûr : ouvrez vous-même l''application Booking.com ou tapez booking.com dans votre navigateur."}]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["L''expéditeur @booking.com est le domaine officiel","Le lien mène à secure.booking.com — même entreprise","Salutation personnelle avec votre nom","Informations de réservation concrètes et attendues","Aucune pression, aucune demande de mot de passe ni de code"]'::jsonb,
 'C''est une vraie confirmation de réservation. Leçon importante : même les vraies entreprises envoient parfois des liens cliquables. Ce qu''il faut vérifier : le domaine de l''expéditeur correspond-il à celui du lien ? Attendiez-vous cet e-mail ? Y a-t-il une absence de pression temporelle ? Même avec des e-mails légitimes, il reste plus prudent d''ouvrir vous-même l''application ou le site que de cliquer sur le lien.',
 45),

-- fr-BE
('fr-BE', 'both',
 'Booking.com',
 'confirmation@booking.com',
 'L''adresse se termine par @booking.com — le vrai domaine de l''entreprise.',
 'il y a 2 jours',
 'Votre réservation est confirmée — Ibis Brussels Centre',
 'Chère Madame Dubois, votre réservation à l''Ibis Brussels est confirmée...',
 E'<div class="eml fam-retail" style="--brand:#003580;--cta:#003580"><div class="eml-hero"><span class="eml-logo">Booking.com</span></div><div class="eml-body"><p>Chère Madame Dubois,</p><p>Votre réservation à l''Ibis Brussels Centre est confirmée :</p><p>• Arrivée : vendredi 15 mai, à partir de 15h00<br>• Départ : dimanche 17 mai, avant 12h00<br>• 1 chambre double, 2 nuits<br>• Total : 248,00 € (déjà payé)</p><p>Vous pouvez consulter ou modifier votre réservation via {{link:0}}.</p><p>Nous avons hâte de vous accueillir.</p><p>Booking.com</p></div><div class="eml-foot"><p>Ceci est un message automatique — merci de ne pas y répondre.</p><p>© 2026 Booking.com</p></div></div>',
 '[{"label":"Mes réservations","real_url":"https://secure.booking.com/myreservations","suspicious":false,"warning":"C''est un vrai lien de booking.com. Le domaine correspond (secure.booking.com) et concorde avec l''expéditeur (@booking.com). Encore plus sûr : ouvrez vous-même l''application Booking.com ou tapez booking.com dans votre navigateur."}]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["L''expéditeur @booking.com est le domaine officiel","Le lien mène à secure.booking.com — même entreprise","Salutation personnelle avec votre nom","Informations de réservation concrètes et attendues","Aucune pression, aucune demande de mot de passe ni de code"]'::jsonb,
 'C''est une vraie confirmation de réservation. Leçon importante : même les vraies entreprises envoient parfois des liens cliquables. Ce qu''il faut vérifier : le domaine de l''expéditeur correspond-il à celui du lien ? Attendiez-vous cet e-mail ? Y a-t-il une absence de pression temporelle ? Même avec des e-mails légitimes, il reste plus prudent d''ouvrir vous-même l''application ou le site que de cliquer sur le lien.',
 45),

-- DE
('de', 'both',
 'Booking.com',
 'confirmation@booking.com',
 'Die Adresse endet auf @booking.com — die echte Domain des Unternehmens.',
 'vor 2 Tagen',
 'Ihre Buchung ist bestätigt — Motel One Berlin-Alexanderplatz',
 'Sehr geehrte Frau Müller, Ihre Buchung im Motel One Berlin ist...',
 E'<div class="eml fam-retail" style="--brand:#003580;--cta:#003580"><div class="eml-hero"><span class="eml-logo">Booking.com</span></div><div class="eml-body"><p>Sehr geehrte Frau Müller,</p><p>Ihre Buchung im Motel One Berlin-Alexanderplatz ist bestätigt:</p><p>• Check-in: Freitag, 15. Mai, ab 15:00 Uhr<br>• Check-out: Sonntag, 17. Mai, vor 12:00 Uhr<br>• 1 Doppelzimmer, 2 Nächte<br>• Gesamt: 198,00 € (bereits bezahlt)</p><p>Sie können Ihre Buchung ansehen oder ändern über {{link:0}}.</p><p>Wir freuen uns auf Ihren Besuch.</p><p>Booking.com</p></div><div class="eml-foot"><p>Dies ist eine automatische Nachricht — bitte antworten Sie nicht darauf.</p><p>© 2026 Booking.com</p></div></div>',
 '[{"label":"Meine Buchungen","real_url":"https://secure.booking.com/myreservations","suspicious":false,"warning":"Dies ist ein echter Link von booking.com. Die Domain stimmt (secure.booking.com) und passt zum Absender (@booking.com). Noch sicherer: Öffnen Sie die Booking.com-App selbst oder tippen Sie booking.com in Ihren Browser."}]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Absender @booking.com ist die offizielle Domain","Der Link führt zu secure.booking.com — dasselbe Unternehmen","Persönliche Anrede mit Ihrem Namen","Konkrete, erwartete Buchungsdaten","Kein Zeitdruck, keine Abfrage von Passwort oder PIN"]'::jsonb,
 'Das ist eine echte Buchungsbestätigung. Wichtige Lektion: Auch echte Unternehmen versenden manchmal anklickbare Links. Was Sie prüfen: Passt die Absender-Domain zu der Domain, zu der der Link führt? Haben Sie diese E-Mail erwartet? Gibt es keinen Zeitdruck? Auch bei echten Nachrichten bleibt es eine gute Gewohnheit, die App oder Website selbst zu öffnen statt auf den Link zu klicken.',
 45);


-- ============================================================
-- ZAKELIJKE SCENARIO'S (audience = 'business')
-- Werkgever: Kestrel (fictief bedrijf), werkmail van de trainee op
-- @kestrel.nl / @kestrel.be / @kestrel.co.uk enz. Tien scenario's per
-- taal (5 phishing + 5 echt). Booking.com blijft gedeeld op audience
-- = 'both'. Sort-order start op 10 per locale zodat zakelijke lijst
-- een eigen, coherente volgorde heeft.
-- ============================================================

INSERT INTO inbox_messages
  (locale, audience, sender_name, sender_address, sender_note, received_label, subject, preview, body, links, is_phishing, red_flags, green_flags, explanation, sort_order) VALUES

-- ============ NL — BUSINESS (1/2) ============

-- 1. PHISHING — CEO-fraude
('nl', 'business',
 'Peter van Dijk (CEO)',
 'p.vandijk@kestrel-group.com',
 'Let op: het echte domein is @kestrel.nl. Dit is @kestrel-group.com — verdacht.',
 'vandaag 09:02',
 'Kun je even iets voor me regelen?',
 'Johanna, ik zit in een overleg. Kun je nu snel iets voor me regelen? Bel me niet...',
 E'Johanna,\n\nIk zit in een belangrijk overleg met een klant en kan niet bellen. Ik heb iets dringends nodig.\n\nKun jij voor mij 5 iTunes-cadeaubonnen van € 100 halen? Stuur me daarna de codes via deze mail, dan regel ik de terugbetaling via de boekhouding. Bel niemand hierover — het is vertrouwelijk.\n\nAlvast bedankt,\nPeter',
 '[]'::jsonb,
 TRUE,
 '["Afzenderadres @kestrel-group.com, niet @kestrel.nl — nep-domein dat op het bedrijf lijkt","Vraagt om cadeaubonnen als vorm van betaling (klassieke CEO-fraude)","Druk: \"niet bellen\", \"vertrouwelijk\" — bedoeld om u los te snijden van collega''s","Past niet bij de normale procedure — facturen lopen via de boekhouding, niet via medewerkers"]'::jsonb,
 '[]'::jsonb,
 'Dit is CEO-fraude. Oplichters doen zich voor als een leidinggevende en vragen om cadeaubonnen of een spoedoverboeking, onder het mom van vertrouwelijkheid. Loop bij twijfel langs het kantoor van de afzender of bel hem/haar op het bekende nummer — nooit via het nummer of e-mailadres in de verdachte mail.',
 90),

-- 2. REAL — HR-memo
('nl', 'business',
 'HR Kestrel',
 'hr@kestrel.nl',
 'Eigen domein @kestrel.nl — klopt.',
 'vandaag 10:15',
 'Nieuwe vakantiepagina in MijnKestrel',
 'Beste collega, vanaf deze week staat de vernieuwde vakantiepagina in MijnKestrel...',
 E'Beste collega,\n\nVanaf deze week staat de vernieuwde vakantiepagina live in MijnKestrel. U vindt daar uw openstaande dagen, een overzicht per maand en het aanvraagformulier.\n\nU logt in zoals altijd — ga zelf naar MijnKestrel via uw startpagina of via de bladwijzer in uw browser. We sturen bewust geen directe link.\n\nVragen? Loop even langs bij HR, of stuur een mailtje naar hr@kestrel.nl.\n\nMet vriendelijke groet,\nHR Kestrel',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Afzender @kestrel.nl is het officiële interne domein","Geen klikbare link — u wordt gevraagd ZELF naar MijnKestrel te gaan","Geen vraag om wachtwoord of persoonlijke gegevens","Concrete, aannemelijke bedrijfsmededeling","Verwijst naar HR als bekend aanspreekpunt"]'::jsonb,
 'Dit is een echte HR-mededeling. Let op het goede patroon: er wordt GEEN link meegestuurd, u moet zelf naar MijnKestrel navigeren. Dat is precies hoe een professionele interne communicatie eruit zou moeten zien.',
 20),

-- 3. PHISHING — IT wachtwoord-reset
('nl', 'business',
 'IT Support',
 'it-support@kestrel-helpdesk.com',
 'Niet @kestrel.nl maar @kestrel-helpdesk.com — een apart domein dat op het bedrijf lijkt. Verdacht.',
 'vandaag 11:30',
 'Uw wachtwoord verloopt vandaag om 17:00 — verleng nu',
 'Uw Kestrel-wachtwoord verloopt vandaag. Verleng het direct om uitsluiting te voorkomen...',
 E'Beste gebruiker,\n\nUw Kestrel-wachtwoord verloopt vandaag om 17:00. Als u het niet verlengt, verliest u toegang tot e-mail, SharePoint en Teams.\n\nGebruik de onderstaande link om uw wachtwoord te verlengen. Dit duurt 30 seconden.\n\n{{link:0}}\n\nMet vriendelijke groet,\nIT Support Kestrel',
 '[{"label":"Wachtwoord verlengen","real_url":"http://kestrel-helpdesk.com/password-renew","suspicious":true,"warning":"Deze link gaat naar kestrel-helpdesk.com — NIET het officiële domein van Kestrel. Uw echte IT-afdeling stuurt reset-links via het interne portaal, niet via een los domein."}]'::jsonb,
 TRUE,
 '["Afzender @kestrel-helpdesk.com, niet @kestrel.nl","Tijdsdruk (\"verloopt vandaag om 17:00\") om u zonder nadenken te laten klikken","Dreigt met verlies van toegang — angst maken","Link naar een domein dat op het bedrijf lijkt maar het niet is","Echte IT-afdelingen laten u inloggen via interne portalen, nooit via een losse link in een e-mail"]'::jsonb,
 '[]'::jsonb,
 'Dit is phishing die zich voordoet als uw eigen IT-afdeling. De echte IT-afdeling mailt zelden reset-links; en als ze dat al doen, is het via het interne domein en het officiële portaal. Twijfelt u? Bel uw IT-collega of loop langs — nooit via het nummer in de mail.',
 30),

-- 4. PHISHING — Nep SharePoint-deellink
('nl', 'business',
 'Microsoft OneDrive',
 'no-reply@sharepoint-online-share.com',
 'Echte SharePoint-meldingen komen van @sharepointonline.com en de link wijst naar uw eigen tenant (bv. kestrel.sharepoint.com). Dit domein is nep.',
 'vandaag 13:47',
 'BAKKER Anna heeft "Raamovereenkomst-2026.pdf" met u gedeeld',
 'BAKKER Anna heeft een document met u gedeeld via OneDrive. Bekijk het nu...',
 E'<div class="ol-share-card"><div class="ol-share-head"><div class="ol-share-icon">⤴</div><h2 class="ol-share-heading">BAKKER Anna heeft u uitgenodigd om een bestand te bewerken</h2><p class="ol-share-intro" style="color:#888;font-size:.85em">anna.bakker@kestrel-partner.com</p></div><div class="ol-share-body"><p class="ol-share-intro">Dit is het document dat BAKKER Anna met u heeft gedeeld.</p><div class="ol-share-file"><span class="ol-share-file-ico">📄</span><span class="ol-share-file-name">Raamovereenkomst-2026.pdf</span></div><p class="ol-share-protection">🔒 Deze uitnodiging werkt alleen voor u en personen met bestaande toegang.</p><div class="ol-share-actions">{{link:0}}</div></div></div>',
 '[{"label":"Document openen","real_url":"http://sharepoint-online-share.com/view?id=8a3f2","suspicious":true,"warning":"Dit is geen Microsoft-domein. Echte SharePoint- en OneDrive-links gaan naar uw eigen tenant (bv. kestrel.sharepoint.com) of naar onedrive.live.com. \"sharepoint-online-share.com\" is nep. Bovendien gebruikt Anna @kestrel-partner.com in plaats van @kestrel.nl."}]'::jsonb,
 TRUE,
 '["Afzenderdomein sharepoint-online-share.com — geen Microsoft- of Kestrel-domein","De \"deler\" Anna Bakker gebruikt @kestrel-partner.com — niet ons eigen @kestrel.nl","Onverwacht document zonder context van een onbekende persoon","Link gaat naar een los extern domein, niet naar kestrel.sharepoint.com"]'::jsonb,
 '[]'::jsonb,
 'Dit is phishing die een SharePoint/OneDrive-deellink nabootst. Echte deellinks leiden naar uw eigen Microsoft 365-tenant (bv. kestrel.sharepoint.com) of naar onedrive.live.com. Twijfelt u? Open SharePoint zelf via uw browser of Teams-app en kijk onder "Gedeeld met mij" of het document er staat.',
 40),

-- 5. REAL — Agenda-uitnodiging van collega
('nl', 'business',
 'Lisa Verhoeven',
 'l.verhoeven@kestrel.nl',
 'Eigen domein @kestrel.nl van een bekende collega — klopt.',
 'vandaag 14:12',
 'Vergadering donderdag 14:00 — kwartaalplanning Q2',
 'Hoi Johanna, kun je donderdag om 14:00 bij de kwartaalplanning zijn? Agenda staat eronder...',
 E'Hoi Johanna,\n\nKun je donderdag om 14:00 even aanschuiven bij de kwartaalplanning Q2? We bespreken:\n\n• Status van de lopende projecten\n• Planning voor mei en juni\n• Prioriteiten voor het team\n\nHet duurt maximaal een uur. Vergaderzaal De Linde, of via Teams als je liever belt. Geef even een seintje terug.\n\nDank!\nLisa',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Afzender @kestrel.nl is het officiële interne domein","Bekende collega die u normaal ook spreekt","Concrete, aannemelijke werkgerelateerde context","Geen link, geen bijlage, geen vraag om gegevens","Informele, persoonlijke toon — past bij interne communicatie"]'::jsonb,
 'Dit is een gewone agenda-uitnodiging van een collega. Geen actie nodig naast inhoudelijk antwoorden. Goede les: persoonlijk geadresseerde, concrete interne mail zonder links of bijlagen is normaal een veilig teken.',
 50);

-- ============ NL — BUSINESS (2/2) ============

INSERT INTO inbox_messages
  (locale, audience, sender_name, sender_address, sender_note, received_label, subject, preview, body, links, is_phishing, red_flags, green_flags, explanation, sort_order) VALUES

-- 6. PHISHING — Nep-factuur van leverancier
('nl', 'business',
 'Administratie Printwerk BV',
 'facturen@printservice-nl.com',
 'Onbekende leverancier op een los .com-domein. Echte leveranciers van Kestrel staan in uw inkoopsysteem.',
 'gisteren 15:30',
 'Factuur P-2026-0452 — betaaltermijn overschreden',
 'Geachte heer/mevrouw, bijgevoegd de openstaande factuur voor onderhoud. Gelieve spoedig te voldoen...',
 E'Geachte heer/mevrouw,\n\nBijgevoegd treft u factuur P-2026-0452 aan voor periodiek printonderhoud over Q1, bedrag € 1.847,50.\n\nDe betaaltermijn van 14 dagen is overschreden. Gelieve direct te voldoen om aanmaningskosten te voorkomen. Betalingsgegevens staan in de bijlage.\n\nAls u snel wilt betalen: {{link:0}}\n\nMet vriendelijke groet,\nAdministratie Printwerk BV',
 '[{"label":"Direct betalen","real_url":"http://printservice-nl.com/pay/P-2026-0452","suspicious":true,"warning":"Onbekend betaal-domein. Bij Kestrel lopen facturen via het inkoopportaal — niet via een losse link in een e-mail."}]'::jsonb,
 TRUE,
 '["Onbekende leverancier — niet in uw inkoopsysteem","Tijdsdruk: \"betaaltermijn overschreden\", \"direct voldoen\"","Losse betaal-link in plaats van via het inkoopportaal","Algemene aanhef \"Geachte heer/mevrouw\" — zou uw naam moeten gebruiken","Het bedrag (€ 1.847,50) is net hoog genoeg om te drukken, laag genoeg om niet op te vallen"]'::jsonb,
 '[]'::jsonb,
 'Dit is factuurfraude. Onbekende leveranciers met onverwachte facturen horen eerst gecheckt te worden via uw inkoopafdeling of crediteuren. Betaal nooit via een link in een e-mail, altijd via uw eigen inkoopportaal of via een nieuwe factuur-review.',
 60),

-- 7. REAL — SharePoint-document gedeeld door collega
('nl', 'business',
 'Microsoft SharePoint',
 'no-reply@sharepointonline.com',
 'Echte SharePoint-notificaties komen van @sharepointonline.com en de link wijst naar uw eigen tenant (kestrel.sharepoint.com).',
 'gisteren 09:00',
 'VERHOEVEN Lisa heeft "Projectplan-Noord-v4.docx" met u gedeeld',
 'VERHOEVEN Lisa heeft een document met u gedeeld: Projectplan-Noord-v4.docx...',
 E'<div class="ol-share-card"><div class="ol-share-head"><div class="ol-share-icon">⤴</div><h2 class="ol-share-heading">VERHOEVEN Lisa heeft u uitgenodigd om een bestand te bewerken</h2></div><div class="ol-share-body"><p class="ol-share-msg">"Hoi Johanna, dit is de versie voor de planning van donderdag. Laat even weten als er iets moet wijzigen."</p><p class="ol-share-intro">Dit is het document dat VERHOEVEN Lisa met u heeft gedeeld.</p><div class="ol-share-file"><span class="ol-share-file-ico">📄</span><span class="ol-share-file-name">Projectplan-Noord-v4.docx</span></div><p class="ol-share-protection">🔒 Deze uitnodiging werkt alleen voor u en personen met bestaande toegang.</p><div class="ol-share-actions">{{link:0}}</div></div></div>',
 '[{"label":"Document openen","real_url":"https://kestrel.sharepoint.com/:w:/s/ProjectNoord/EYnRNcTq0/Projectplan-Noord-v4.docx","suspicious":false,"warning":"Dit is een echte SharePoint-link binnen ons eigen tenant (kestrel.sharepoint.com). Nog veiliger: open SharePoint of Teams zelf en vind het document onder \"Gedeeld met mij\"."}]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Afzender @sharepointonline.com is het officiële Microsoft-notificatiedomein","Link gaat naar kestrel.sharepoint.com — ons eigen tenant","Interne collega (Lisa via @kestrel.nl) is bekend","Persoonlijk bericht sluit aan op lopend werk (planning donderdag, project Noord)","Geen druk, geen vraag om paswoord"]'::jsonb,
 'Dit is een echte SharePoint-deellink van een collega. Goed patroon: notificatie via @sharepointonline.com, link naar uw eigen tenant (kestrel.sharepoint.com), persoonlijk bericht erbij. Een extra veilige gewoonte: open SharePoint zelf via de app of browser en vind het document onder "Gedeeld met mij".',
 70),

-- 8. PHISHING — Microsoft 365 wachtwoord
('nl', 'business',
 'Microsoft 365',
 'account-security@microsoft-365-secure.com',
 'Het echte Microsoft-domein is microsoft.com. "microsoft-365-secure.com" is nep.',
 '2 dagen geleden 08:14',
 'Uw Microsoft 365-wachtwoord verloopt vandaag',
 'Uw wachtwoord voor Microsoft 365 verloopt binnen 24 uur. Houd uw huidige wachtwoord...',
 E'<div class="eml fam-tech" style="--brand:#0067b8;--cta:#0067b8"><div class="eml-top"><span class="eml-logo">Microsoft 365</span></div><div class="eml-body"><p>Microsoft 365 Accountbeveiliging</p><p>Uw wachtwoord voor Microsoft 365 verloopt binnen 24 uur. Na deze periode verliest u toegang tot e-mail, OneDrive en Teams.</p><p>Klik hieronder om uw huidige wachtwoord te behouden en het verlopen te voorkomen:</p><div class="eml-cta" style="--cta:#0067b8">{{link:0}}</div><p>Deze actie duurt minder dan een minuut. Als u dit negeert, wordt uw account tijdelijk vergrendeld.</p><p>Microsoft 365 Security Team</p></div><div class="eml-foot"><p>Dit is een automatisch verzonden bericht — antwoorden is niet mogelijk.</p><p>© 2026 Microsoft 365</p></div></div>',
 '[{"label":"Wachtwoord behouden","real_url":"http://microsoft-365-secure.com/keep-password","suspicious":true,"warning":"Microsoft gebruikt nooit domeinen met streepjes zoals microsoft-365-secure.com. Dit is nep. Microsoft vraagt u ook nooit om via een link uw wachtwoord te \"behouden\" of te \"bevestigen\"."}]'::jsonb,
 TRUE,
 '["Afzender @microsoft-365-secure.com (niet @microsoft.com)","Tijdsdruk: \"binnen 24 uur\", \"vergrendeld\"","Bizar concept: \"wachtwoord behouden\" via een link bestaat niet","Dreiging met verlies van toegang","Als Microsoft 365 een wachtwoord wil vernieuwen, gebeurt dat bij het inloggen zelf — niet via een losse mail"]'::jsonb,
 '[]'::jsonb,
 'Dit is een van de meest voorkomende zakelijke phishing-varianten. Microsoft communiceert wachtwoordwijzigingen nooit zo. Twijfelt u? Sluit de mail en ga zelf naar portal.office.com of open Teams om te zien of er echt een probleem is.',
 80),

-- 9. REAL — Korte vraag van collega
('nl', 'business',
 'Lisa Verhoeven',
 'l.verhoeven@kestrel.nl',
 'Eigen domein @kestrel.nl van een bekende collega — klopt.',
 '2 dagen geleden 14:45',
 'Kun je even naar de begroting kijken?',
 'Hoi Johanna, Mark vroeg of jij even kan checken of regel 14 in de begroting klopt...',
 E'Hoi Johanna,\n\nMark vroeg of jij snel kunt checken of regel 14 in de begroting van project Noord klopt. Volgens hem staat daar een verkeerd bedrag, maar ik weet niet zeker of hij naar de juiste versie keek.\n\nDe begroting staat op de teamshare onder /Projecten/Noord/2026/.\n\nGeef je het even door?\n\nDank!\nLisa',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Afzender @kestrel.nl, bekende collega","Concrete interne context (Mark, project Noord, teamshare pad)","Geen link naar een extern domein","Geen vraag om gegevens, wachtwoorden of geld","Informele toon past bij normale interne communicatie"]'::jsonb,
 'Dit is een normale werkvraag van een collega. Geen actie behalve kijken en antwoorden. Let op: persoonlijke, concrete werkcontext op intern domein is normaal een goed teken.',
 10),

-- 10. PHISHING — Recruiter met gevaarlijke bijlage
('nl', 'business',
 'Sarah Visser — Premium Talent',
 'sarah.visser@premium-talent-careers.info',
 '".info"-domein en losse recruiter zonder aantoonbare link met een bekend bureau. Verdacht patroon.',
 '3 dagen geleden 17:20',
 'Exclusieve kans bij internationale opdrachtgever — CV beoordeeld',
 'Beste Johanna, ik heb uw profiel op LinkedIn bekeken en heb een exclusieve positie...',
 E'Beste Johanna,\n\nIk heb uw profiel bekeken en heb een exclusieve senior-positie bij een internationale opdrachtgever die volgens mij perfect bij uw ervaring past. Salarisindicatie: € 95k - € 115k.\n\nDe rol is nog niet publiek gemaakt en er is haast bij. Klant wil deze week al een shortlist.\n\nIn de bijlage vindt u de functieomschrijving en het geheimhoudingscontract (NDA) dat ik u vraag te openen en te ondertekenen voordat ik meer details kan delen.\n\nMet vriendelijke groet,\nSarah Visser\nPremium Talent — Executive Search',
 '[]'::jsonb,
 TRUE,
 '["Afzender op \".info\"-domein zonder bekend bureau","Onverwacht contact met een bijlage","De bestandsnaam eindigt op .pdf.exe — dat is een uitvoerbaar programma vermomd als PDF","Tijdsdruk: \"deze week al een shortlist\"","Geheimhouding gevraagd — bedoeld om u te isoleren","Salaris als lokker zonder enige controleerbare context"]'::jsonb,
 '[]'::jsonb,
 'Dit is phishing met een kwaadaardige bijlage. Bestanden met dubbele extensies (.pdf.exe) zijn uitvoerbare programma''s vermomd als document. Open ze NOOIT. Een serieuze recruiter met een serieuze opdracht stuurt geen losse uitvoerbare bijlagen. Meld dit bij IT of verwijder de mail.',
 100);

-- ============ nl-BE — BUSINESS (1/2) ============

INSERT INTO inbox_messages
  (locale, audience, sender_name, sender_address, sender_note, received_label, subject, preview, body, links, is_phishing, red_flags, green_flags, explanation, sort_order) VALUES

-- 1. PHISHING — CEO-fraude
('nl-BE', 'business',
 'Luc Vermeulen (CEO)',
 'l.vermeulen@kestrel-group.com',
 'Let op: het echte domein is @kestrel.be. Dit is @kestrel-group.com — verdacht.',
 'vandaag 09:02',
 'Kun je even iets voor mij regelen?',
 'Petra, ik zit in een overleg. Kun je nu snel iets voor mij regelen? Bel me niet...',
 E'Petra,\n\nIk zit in een belangrijk overleg met een klant en kan niet bellen. Ik heb iets dringends nodig.\n\nKun jij voor mij 5 iTunes-cadeaubonnen van € 100 halen? Stuur me daarna de codes via deze mail, dan regel ik de terugbetaling via de boekhouding. Bel niemand hierover — het is vertrouwelijk.\n\nAlvast bedankt,\nLuc',
 '[]'::jsonb,
 TRUE,
 '["Afzenderadres @kestrel-group.com, niet @kestrel.be — nep-domein dat op het bedrijf lijkt","Vraagt om cadeaubonnen als betaling (klassieke CEO-fraude)","Druk: \"niet bellen\", \"vertrouwelijk\" — bedoeld om u los te snijden van collega''s","Past niet bij de normale procedure — facturen lopen via de boekhouding, niet via medewerkers"]'::jsonb,
 '[]'::jsonb,
 'Dit is CEO-fraude. Oplichters doen zich voor als een leidinggevende en vragen om cadeaubonnen of een spoedoverschrijving, onder het mom van vertrouwelijkheid. Loop bij twijfel langs het bureau van de afzender of bel hem/haar op het bekende nummer — nooit via het nummer of e-mailadres in de verdachte mail.',
 90),

-- 2. REAL — HR-memo
('nl-BE', 'business',
 'HR Kestrel',
 'hr@kestrel.be',
 'Eigen domein @kestrel.be — klopt.',
 'vandaag 10:15',
 'Nieuwe verlofpagina in MijnKestrel',
 'Beste collega, vanaf deze week staat de vernieuwde verlofpagina in MijnKestrel...',
 E'Beste collega,\n\nVanaf deze week staat de vernieuwde verlofpagina live in MijnKestrel. U vindt daar uw resterende verlofdagen, een overzicht per maand en het aanvraagformulier.\n\nU meldt zich aan zoals altijd — ga zelf naar MijnKestrel via uw startpagina of de bladwijzer in uw browser. We sturen bewust geen rechtstreekse link.\n\nVragen? Loop even langs bij HR, of stuur een mailtje naar hr@kestrel.be.\n\nMet vriendelijke groeten,\nHR Kestrel',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Afzender @kestrel.be is het officiële interne domein","Geen klikbare link — u wordt gevraagd ZELF naar MijnKestrel te gaan","Geen vraag om paswoord of persoonlijke gegevens","Concrete, aannemelijke bedrijfsmededeling","Verwijst naar HR als bekend aanspreekpunt"]'::jsonb,
 'Dit is een echte HR-mededeling. Let op het goede patroon: er wordt GEEN link meegestuurd, u moet zelf naar MijnKestrel navigeren. Zo zou een professionele interne communicatie eruit moeten zien.',
 20),

-- 3. PHISHING — IT paswoord-reset
('nl-BE', 'business',
 'IT Support',
 'it-support@kestrel-helpdesk.com',
 'Niet @kestrel.be maar @kestrel-helpdesk.com — een apart domein dat op het bedrijf lijkt. Verdacht.',
 'vandaag 11:30',
 'Uw paswoord verloopt vandaag om 17u — verleng nu',
 'Uw Kestrel-paswoord verloopt vandaag. Verleng het direct om uitsluiting te voorkomen...',
 E'Beste gebruiker,\n\nUw Kestrel-paswoord verloopt vandaag om 17u. Als u het niet verlengt, verliest u toegang tot e-mail, SharePoint en Teams.\n\nGebruik de onderstaande link om uw paswoord te verlengen. Dit duurt 30 seconden.\n\n{{link:0}}\n\nMet vriendelijke groeten,\nIT Support Kestrel',
 '[{"label":"Paswoord verlengen","real_url":"http://kestrel-helpdesk.com/password-renew","suspicious":true,"warning":"Deze link gaat naar kestrel-helpdesk.com — NIET het officiële domein van Kestrel. Uw echte IT-afdeling stuurt reset-links via het interne portaal, niet via een los domein."}]'::jsonb,
 TRUE,
 '["Afzender @kestrel-helpdesk.com, niet @kestrel.be","Tijdsdruk (\"verloopt vandaag om 17u\") om u zonder nadenken te laten klikken","Dreigt met verlies van toegang — angst maken","Link naar een domein dat op het bedrijf lijkt maar het niet is","Echte IT-afdelingen laten u aanmelden via interne portalen, nooit via een losse link in een e-mail"]'::jsonb,
 '[]'::jsonb,
 'Dit is phishing die zich voordoet als uw eigen IT-afdeling. De echte IT-afdeling mailt zelden reset-links; en als ze dat al doen, is het via het interne domein en het officiële portaal. Twijfelt u? Bel uw IT-collega of loop langs — nooit via het nummer in de mail.',
 30),

-- 4. PHISHING — Nep SharePoint-deellink
('nl-BE', 'business',
 'Microsoft OneDrive',
 'no-reply@sharepoint-online-share.com',
 'Echte SharePoint-meldingen komen van @sharepointonline.com en de link wijst naar uw eigen tenant (bv. kestrel.sharepoint.com). Dit domein is nep.',
 'vandaag 13:47',
 'CLAES Bart heeft "Raamovereenkomst-2026.pdf" met u gedeeld',
 'CLAES Bart heeft een document met u gedeeld via OneDrive. Bekijk het nu...',
 E'<div class="ol-share-card"><div class="ol-share-head"><div class="ol-share-icon">⤴</div><h2 class="ol-share-heading">CLAES Bart heeft u uitgenodigd om een bestand te bewerken</h2><p class="ol-share-intro" style="color:#888;font-size:.85em">bart.claes@kestrel-partner.com</p></div><div class="ol-share-body"><p class="ol-share-intro">Dit is het document dat CLAES Bart met u heeft gedeeld.</p><div class="ol-share-file"><span class="ol-share-file-ico">📄</span><span class="ol-share-file-name">Raamovereenkomst-2026.pdf</span></div><p class="ol-share-protection">🔒 Deze uitnodiging werkt alleen voor u en personen met bestaande toegang.</p><div class="ol-share-actions">{{link:0}}</div></div></div>',
 '[{"label":"Document openen","real_url":"http://sharepoint-online-share.com/view?id=8a3f2","suspicious":true,"warning":"Dit is geen Microsoft-domein. Echte SharePoint- en OneDrive-links gaan naar uw eigen tenant (bv. kestrel.sharepoint.com) of naar onedrive.live.com. \"sharepoint-online-share.com\" is nep. Bovendien gebruikt Bart @kestrel-partner.com in plaats van @kestrel.be."}]'::jsonb,
 TRUE,
 '["Afzenderdomein sharepoint-online-share.com — geen Microsoft- of Kestrel-domein","De \"deler\" Bart Claes gebruikt @kestrel-partner.com — niet ons eigen @kestrel.be","Onverwacht document zonder context","Link gaat naar een los extern domein, niet naar kestrel.sharepoint.com"]'::jsonb,
 '[]'::jsonb,
 'Dit is phishing die een SharePoint/OneDrive-deellink nabootst. Echte deellinks leiden naar uw eigen Microsoft 365-tenant (bv. kestrel.sharepoint.com) of naar onedrive.live.com. Twijfelt u? Open SharePoint zelf via uw browser of Teams-app en kijk onder "Gedeeld met mij" of het document er staat.',
 40),

-- 5. REAL — Agenda-uitnodiging van collega
('nl-BE', 'business',
 'Sophie Dewit',
 's.dewit@kestrel.be',
 'Eigen domein @kestrel.be van een bekende collega — klopt.',
 'vandaag 14:12',
 'Vergadering donderdag 14u — kwartaalplanning Q2',
 'Hallo Petra, kun je donderdag om 14u bij de kwartaalplanning zijn? Agenda staat eronder...',
 E'Hallo Petra,\n\nKan jij donderdag om 14u even aansluiten bij de kwartaalplanning Q2? We bespreken:\n\n• Status van de lopende projecten\n• Planning voor mei en juni\n• Prioriteiten voor het team\n\nHet duurt maximaal een uur. Vergaderzaal De Meir, of via Teams als je liever belt. Laat even iets weten.\n\nDank!\nSophie',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Afzender @kestrel.be is het officiële interne domein","Bekende collega die u normaal ook spreekt","Concrete, aannemelijke werkgerelateerde context","Geen link, geen bijlage, geen vraag om gegevens","Informele, persoonlijke toon — past bij interne communicatie"]'::jsonb,
 'Dit is een gewone agenda-uitnodiging van een collega. Geen actie nodig behalve inhoudelijk antwoorden. Goede les: persoonlijk geadresseerde, concrete interne mail zonder links of bijlagen is meestal een veilig teken.',
 50);

-- ============ nl-BE — BUSINESS (2/2) ============

INSERT INTO inbox_messages
  (locale, audience, sender_name, sender_address, sender_note, received_label, subject, preview, body, links, is_phishing, red_flags, green_flags, explanation, sort_order) VALUES

-- 6. PHISHING — Nep-factuur van leverancier
('nl-BE', 'business',
 'Administratie Printwerk BVBA',
 'facturen@printservice-be.com',
 'Onbekende leverancier op een los .com-domein. Echte leveranciers van Kestrel staan in uw inkoopsysteem.',
 'gisteren 15:30',
 'Factuur P-2026-0452 — betaaltermijn overschreden',
 'Geachte heer/mevrouw, bijgevoegd de openstaande factuur voor onderhoud. Gelieve spoedig te voldoen...',
 E'Geachte heer/mevrouw,\n\nBijgevoegd treft u factuur P-2026-0452 aan voor periodiek printonderhoud over Q1, bedrag € 1.847,50.\n\nDe betaaltermijn van 14 dagen is overschreden. Gelieve direct te voldoen om aanmaningskosten te vermijden. Betalingsgegevens staan in de bijlage.\n\nAls u snel wilt betalen: {{link:0}}\n\nMet vriendelijke groeten,\nAdministratie Printwerk BVBA',
 '[{"label":"Direct betalen","real_url":"http://printservice-be.com/pay/P-2026-0452","suspicious":true,"warning":"Onbekend betaal-domein. Bij Kestrel lopen facturen via het inkoopportaal — niet via een losse link in een e-mail."}]'::jsonb,
 TRUE,
 '["Onbekende leverancier — niet in uw inkoopsysteem","Tijdsdruk: \"betaaltermijn overschreden\", \"direct voldoen\"","Losse betaal-link in plaats van via het inkoopportaal","Algemene aanspreking \"Geachte heer/mevrouw\" — zou uw naam moeten gebruiken","Het bedrag is net hoog genoeg om te drukken, laag genoeg om niet op te vallen"]'::jsonb,
 '[]'::jsonb,
 'Dit is factuurfraude. Onbekende leveranciers met onverwachte facturen horen eerst gecontroleerd te worden via uw aankoopdienst of crediteuren. Betaal nooit via een link in een e-mail, altijd via uw eigen inkoopportaal of via een nieuwe factuur-review.',
 60),

-- 7. REAL — SharePoint-document gedeeld door collega
('nl-BE', 'business',
 'Microsoft SharePoint',
 'no-reply@sharepointonline.com',
 'Echte SharePoint-notificaties komen van @sharepointonline.com en de link wijst naar uw eigen tenant (kestrel.sharepoint.com).',
 'gisteren 09u00',
 'DEWIT Sophie heeft "Projectplan-Noord-v4.docx" met u gedeeld',
 'DEWIT Sophie heeft een document met u gedeeld: Projectplan-Noord-v4.docx...',
 E'<div class="ol-share-card"><div class="ol-share-head"><div class="ol-share-icon">⤴</div><h2 class="ol-share-heading">DEWIT Sophie heeft u uitgenodigd om een bestand te bewerken</h2></div><div class="ol-share-body"><p class="ol-share-msg">"Hallo Petra, dit is de versie voor de planning van donderdag. Laat even weten als er iets moet wijzigen."</p><p class="ol-share-intro">Dit is het document dat DEWIT Sophie met u heeft gedeeld.</p><div class="ol-share-file"><span class="ol-share-file-ico">📄</span><span class="ol-share-file-name">Projectplan-Noord-v4.docx</span></div><p class="ol-share-protection">🔒 Deze uitnodiging werkt alleen voor u en personen met bestaande toegang.</p><div class="ol-share-actions">{{link:0}}</div></div></div>',
 '[{"label":"Document openen","real_url":"https://kestrel.sharepoint.com/:w:/s/ProjectNoord/EYnRNcTq0/Projectplan-Noord-v4.docx","suspicious":false,"warning":"Dit is een echte SharePoint-link binnen ons eigen tenant (kestrel.sharepoint.com). Nog veiliger: open SharePoint of Teams zelf en vind het document onder \"Gedeeld met mij\"."}]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Afzender @sharepointonline.com is het officiële Microsoft-notificatiedomein","Link gaat naar kestrel.sharepoint.com — ons eigen tenant","Interne collega (Sophie via @kestrel.be) is bekend","Persoonlijk bericht sluit aan op lopend werk (planning donderdag, project Noord)","Geen druk, geen vraag om paswoord"]'::jsonb,
 'Dit is een echte SharePoint-deellink van een collega. Goed patroon: notificatie via @sharepointonline.com, link naar uw eigen tenant (kestrel.sharepoint.com), persoonlijk bericht erbij. Een extra veilige gewoonte: open SharePoint zelf via de app of browser en vind het document onder "Gedeeld met mij".',
 70),

-- 8. PHISHING — Microsoft 365
('nl-BE', 'business',
 'Microsoft 365',
 'account-security@microsoft-365-secure.com',
 'Het echte Microsoft-domein is microsoft.com. "microsoft-365-secure.com" is nep.',
 '2 dagen geleden 08u14',
 'Uw Microsoft 365-paswoord verloopt vandaag',
 'Uw paswoord voor Microsoft 365 verloopt binnen 24 uur. Behoud uw huidige paswoord...',
 E'<div class="eml fam-tech" style="--brand:#0067b8;--cta:#0067b8"><div class="eml-top"><span class="eml-logo">Microsoft 365</span></div><div class="eml-body"><p>Microsoft 365 Accountbeveiliging</p><p>Uw paswoord voor Microsoft 365 verloopt binnen 24 uur. Na deze periode verliest u toegang tot e-mail, OneDrive en Teams.</p><p>Klik hieronder om uw huidige paswoord te behouden en het verlopen te vermijden:</p><div class="eml-cta" style="--cta:#0067b8">{{link:0}}</div><p>Deze actie duurt minder dan een minuut. Als u dit negeert, wordt uw account tijdelijk vergrendeld.</p><p>Microsoft 365 Security Team</p></div><div class="eml-foot"><p>Dit is een automatisch verzonden bericht — antwoorden is niet mogelijk.</p><p>© 2026 Microsoft 365</p></div></div>',
 '[{"label":"Paswoord behouden","real_url":"http://microsoft-365-secure.com/keep-password","suspicious":true,"warning":"Microsoft gebruikt nooit domeinen met streepjes zoals microsoft-365-secure.com. Dit is nep. Microsoft vraagt u ook nooit om via een link uw paswoord te \"behouden\" of te \"bevestigen\"."}]'::jsonb,
 TRUE,
 '["Afzender @microsoft-365-secure.com (niet @microsoft.com)","Tijdsdruk: \"binnen 24 uur\", \"vergrendeld\"","Bizar concept: \"paswoord behouden\" via een link bestaat niet","Dreiging met verlies van toegang","Als Microsoft 365 een paswoord wil vernieuwen, gebeurt dat bij het aanmelden zelf — niet via een losse mail"]'::jsonb,
 '[]'::jsonb,
 'Dit is een van de meest voorkomende zakelijke phishing-varianten. Microsoft communiceert paswoordwijzigingen nooit zo. Twijfelt u? Sluit de mail en ga zelf naar portal.office.com of open Teams om te zien of er echt een probleem is.',
 80),

-- 9. REAL — Korte vraag van collega
('nl-BE', 'business',
 'Sophie Dewit',
 's.dewit@kestrel.be',
 'Eigen domein @kestrel.be van een bekende collega — klopt.',
 '2 dagen geleden 14u45',
 'Kun je even naar de begroting kijken?',
 'Hallo Petra, Mark vroeg of jij even kan controleren of regel 14 in de begroting klopt...',
 E'Hallo Petra,\n\nMark vroeg of jij snel kunt controleren of regel 14 in de begroting van project Noord klopt. Volgens hem staat daar een verkeerd bedrag, maar ik weet niet zeker of hij naar de juiste versie keek.\n\nDe begroting staat op de teamshare onder /Projecten/Noord/2026/.\n\nGeef je het even door?\n\nDank!\nSophie',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Afzender @kestrel.be, bekende collega","Concrete interne context (Mark, project Noord, teamshare-pad)","Geen link naar een extern domein","Geen vraag om gegevens, paswoorden of geld","Informele toon past bij normale interne communicatie"]'::jsonb,
 'Dit is een normale werkvraag van een collega. Geen actie behalve kijken en antwoorden. Let op: persoonlijke, concrete werkcontext op intern domein is normaal een goed teken.',
 10),

-- 10. PHISHING — Recruiter met gevaarlijke bijlage
('nl-BE', 'business',
 'Sarah Vermeulen — Premium Talent',
 'sarah.vermeulen@premium-talent-careers.info',
 '".info"-domein en losse recruiter zonder aantoonbare link met een bekend bureau. Verdacht patroon.',
 '3 dagen geleden 17u20',
 'Exclusieve kans bij internationale opdrachtgever — profiel beoordeeld',
 'Beste Petra, ik heb uw profiel op LinkedIn bekeken en heb een exclusieve positie...',
 E'Beste Petra,\n\nIk heb uw profiel bekeken en heb een exclusieve senior-positie bij een internationale opdrachtgever die volgens mij perfect bij uw ervaring past. Salarisindicatie: € 95.000 - € 115.000 bruto.\n\nDe rol is nog niet publiek gemaakt en er is haast bij. Klant wil deze week al een shortlist.\n\nIn de bijlage vindt u de functieomschrijving en het geheimhoudingscontract (NDA) dat ik u vraag te openen en te ondertekenen voordat ik meer details kan delen.\n\nMet vriendelijke groeten,\nSarah Vermeulen\nPremium Talent — Executive Search',
 '[]'::jsonb,
 TRUE,
 '["Afzender op \".info\"-domein zonder bekend bureau","Onverwacht contact met een bijlage","De bestandsnaam eindigt op .pdf.exe — dat is een uitvoerbaar programma vermomd als pdf","Tijdsdruk: \"deze week al een shortlist\"","Geheimhouding gevraagd — bedoeld om u te isoleren","Salaris als lokker zonder enige controleerbare context"]'::jsonb,
 '[]'::jsonb,
 'Dit is phishing met een kwaadaardige bijlage. Bestanden met dubbele extensies (.pdf.exe) zijn uitvoerbare programma''s vermomd als document. Open ze NOOIT. Een serieuze recruiter met een serieuze opdracht stuurt geen losse uitvoerbare bijlagen. Meld dit bij IT of verwijder de mail.',
 100);

-- ============ EN (UK) — BUSINESS (1/2) ============

INSERT INTO inbox_messages
  (locale, audience, sender_name, sender_address, sender_note, received_label, subject, preview, body, links, is_phishing, red_flags, green_flags, explanation, sort_order) VALUES

-- 1. PHISHING — CEO fraud
('en', 'business',
 'Thomas Richardson (CEO)',
 't.richardson@kestrel-group.com',
 'The real domain is @kestrel.co.uk. This is @kestrel-group.com — a lookalike.',
 'today 09:02',
 'Quick favour — are you in?',
 'Jane, I''m in a meeting. Can you sort something quickly? Don''t call...',
 E'Jane,\n\nI''m in an important client meeting and can''t take calls. I need something urgently.\n\nCould you pick up 5 Amazon gift cards at £100 each? Email me the codes as soon as you have them, and I''ll have Finance reimburse you. Please keep this between us — it''s confidential until I can explain.\n\nThanks,\nThomas',
 '[]'::jsonb,
 TRUE,
 '["Sender @kestrel-group.com, not @kestrel.co.uk — lookalike domain","Asks for gift cards as a form of payment (textbook CEO fraud)","Pressure: \"don''t call\", \"confidential\" — designed to isolate you from colleagues","Bypasses the normal process — real expenses go through Finance, not via an employee buying gift cards"]'::jsonb,
 '[]'::jsonb,
 'This is CEO fraud. Scammers impersonate a senior leader and ask for gift cards or an urgent transfer, using confidentiality to keep you from double-checking. If in doubt, walk over to the sender''s desk or call them on their known number — never via anything in the suspicious email.',
 90),

-- 2. REAL — HR memo
('en', 'business',
 'HR Kestrel',
 'hr@kestrel.co.uk',
 'Own @kestrel.co.uk domain — correct.',
 'today 10:15',
 'New holiday page available on MyKestrel',
 'Hello colleague, from this week the updated holiday page is live on MyKestrel...',
 E'Hello colleague,\n\nFrom this week the updated holiday page is live on MyKestrel. You''ll find your remaining days, a monthly overview and the request form there.\n\nYou sign in the way you always do — head to MyKestrel yourself via your start page or your browser bookmark. We deliberately don''t send a direct link.\n\nQuestions? Drop by HR or email hr@kestrel.co.uk.\n\nKind regards,\nHR Kestrel',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Sender @kestrel.co.uk is the official internal domain","No clickable link — you are asked to navigate to MyKestrel YOURSELF","No request for a password or personal data","Concrete, plausible internal announcement","Points to HR as the known follow-up contact"]'::jsonb,
 'This is a genuine HR message. Note the good pattern: NO link is sent; you''re asked to navigate to MyKestrel yourself. That''s what professional internal communication should look like.',
 20),

-- 3. PHISHING — IT password reset
('en', 'business',
 'IT Support',
 'it-support@kestrel-helpdesk.com',
 'Not @kestrel.co.uk but @kestrel-helpdesk.com — a separate lookalike domain. Suspicious.',
 'today 11:30',
 'Your password expires today at 17:00 — renew now',
 'Your Kestrel password expires today. Renew immediately to avoid lock-out...',
 E'Dear user,\n\nYour Kestrel password expires today at 17:00. If you don''t renew it, you''ll lose access to email, SharePoint and Teams.\n\nUse the link below to renew your password. This takes 30 seconds.\n\n{{link:0}}\n\nKind regards,\nIT Support Kestrel',
 '[{"label":"Renew password","real_url":"http://kestrel-helpdesk.com/password-renew","suspicious":true,"warning":"This link goes to kestrel-helpdesk.com — NOT Kestrel''s official domain. Your real IT team sends reset links via the internal portal, never via a stand-alone domain."}]'::jsonb,
 TRUE,
 '["Sender @kestrel-helpdesk.com, not @kestrel.co.uk","Time pressure (\"expires today at 17:00\") so you click without thinking","Threat of losing access — fear-based","Link goes to a domain that looks like the company but isn''t","Real IT teams have you sign in via internal portals, never via a stand-alone link in an email"]'::jsonb,
 '[]'::jsonb,
 'This is phishing posing as your own IT team. The real IT team rarely emails reset links — and when they do, it''s via the internal domain and the official portal. Unsure? Call a colleague in IT or drop by in person — never via any number in the email.',
 30),

-- 4. PHISHING — Fake SharePoint share
('en', 'business',
 'Microsoft OneDrive',
 'no-reply@sharepoint-online-share.com',
 'Real SharePoint notifications come from @sharepointonline.com and the link points to your own tenant (e.g. kestrel.sharepoint.com). This domain is fake.',
 'today 13:47',
 'BAKER Adam shared "Framework-Agreement-2026.pdf" with you',
 'BAKER Adam shared a document with you via OneDrive. View it now...',
 E'<div class="ol-share-card"><div class="ol-share-head"><div class="ol-share-icon">⤴</div><h2 class="ol-share-heading">BAKER Adam has invited you to edit a file</h2><p class="ol-share-intro" style="color:#888;font-size:.85em">adam.baker@kestrel-partner.com</p></div><div class="ol-share-body"><p class="ol-share-intro">This is the document BAKER Adam shared with you.</p><div class="ol-share-file"><span class="ol-share-file-ico">📄</span><span class="ol-share-file-name">Framework-Agreement-2026.pdf</span></div><p class="ol-share-protection">🔒 This invitation only works for you and people with existing access.</p><div class="ol-share-actions">{{link:0}}</div></div></div>',
 '[{"label":"Open document","real_url":"http://sharepoint-online-share.com/view?id=8a3f2","suspicious":true,"warning":"This is not a Microsoft domain. Real SharePoint and OneDrive links point to your own tenant (e.g. kestrel.sharepoint.com) or to onedrive.live.com. \"sharepoint-online-share.com\" is fake. On top of that, Adam uses @kestrel-partner.com, not @kestrel.co.uk."}]'::jsonb,
 TRUE,
 '["Sender domain sharepoint-online-share.com — not a Microsoft or Kestrel domain","The \"sharer\" Adam Baker uses @kestrel-partner.com — not our own @kestrel.co.uk","Unexpected document with no context","The link points to a stand-alone external domain rather than kestrel.sharepoint.com"]'::jsonb,
 '[]'::jsonb,
 'This is phishing masquerading as a SharePoint/OneDrive share link. Real share links take you to your own Microsoft 365 tenant (e.g. kestrel.sharepoint.com) or to onedrive.live.com. If in doubt, open SharePoint or the Teams app yourself and check "Shared with me" to see whether the document is actually there.',
 40),

-- 5. REAL — Colleague calendar invite
('en', 'business',
 'Emma Walsh',
 'e.walsh@kestrel.co.uk',
 'Own @kestrel.co.uk domain from a known colleague — fine.',
 'today 14:12',
 'Meeting Thursday 14:00 — Q2 quarterly planning',
 'Hi Jane, can you join the Q2 planning on Thursday at 14:00? Agenda below...',
 E'Hi Jane,\n\nCould you join the Q2 planning on Thursday at 14:00? We''ll cover:\n\n• Status of the running projects\n• Planning for May and June\n• Priorities for the team\n\nOne hour max. Meeting room Ash, or via Teams if you''d rather dial in. Just let me know.\n\nThanks!\nEmma',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Sender @kestrel.co.uk is the official internal domain","Known colleague you normally speak to","Concrete, plausible work context","No link, no attachment, no request for data","Informal, personal tone — fits internal communication"]'::jsonb,
 'This is a normal calendar request from a colleague. Nothing to do other than reply substantively. Good lesson: a personally addressed, specific internal email with no links or attachments is usually a safe signal.',
 50);

-- ============ EN (UK) — BUSINESS (2/2) ============

INSERT INTO inbox_messages
  (locale, audience, sender_name, sender_address, sender_note, received_label, subject, preview, body, links, is_phishing, red_flags, green_flags, explanation, sort_order) VALUES

-- 6. PHISHING — Fake vendor invoice
('en', 'business',
 'Accounts — Print Solutions Ltd',
 'invoices@print-services-uk.com',
 'Unknown supplier on a stand-alone .com domain. Kestrel''s real suppliers are in the purchasing system.',
 'yesterday 15:30',
 'Invoice P-2026-0452 — payment overdue',
 'Dear Sir/Madam, please find attached the outstanding invoice for print servicing. Kindly settle promptly...',
 E'Dear Sir/Madam,\n\nPlease find attached invoice P-2026-0452 for quarterly print servicing (Q1), total £1,847.50.\n\nThe 14-day payment term has now passed. Please settle this immediately to avoid late fees. Payment details are in the attachment.\n\nTo pay now: {{link:0}}\n\nKind regards,\nAccounts — Print Solutions Ltd',
 '[{"label":"Pay now","real_url":"http://print-services-uk.com/pay/P-2026-0452","suspicious":true,"warning":"Unknown payment domain. At Kestrel, invoices go through the purchasing portal — not via a stand-alone link in an email."}]'::jsonb,
 TRUE,
 '["Unknown supplier — not in your purchasing system","Time pressure: \"payment overdue\", \"settle immediately\"","Stand-alone pay link instead of the purchasing portal","Generic \"Dear Sir/Madam\" — should use your name","The amount (£1,847.50) is just high enough to pressure, low enough not to raise flags"]'::jsonb,
 '[]'::jsonb,
 'This is invoice fraud. Unknown suppliers with unexpected invoices should be checked with Purchasing or Accounts Payable first. Never pay via a link in an email — always via your own purchasing portal or via a fresh invoice review.',
 60),

-- 7. REAL — SharePoint document shared by a colleague
('en', 'business',
 'Microsoft SharePoint',
 'no-reply@sharepointonline.com',
 'Real SharePoint notifications come from @sharepointonline.com and the link points to your own tenant (kestrel.sharepoint.com).',
 'yesterday 09:00',
 'WALSH Emma shared "Project-North-Plan-v4.docx" with you',
 'WALSH Emma shared a document with you: Project-North-Plan-v4.docx...',
 E'<div class="ol-share-card"><div class="ol-share-head"><div class="ol-share-icon">⤴</div><h2 class="ol-share-heading">WALSH Emma has invited you to edit a file</h2></div><div class="ol-share-body"><p class="ol-share-msg">"Hi Jane, this is the version for Thursday''s planning. Let me know if anything needs to change."</p><p class="ol-share-intro">This is the document WALSH Emma shared with you.</p><div class="ol-share-file"><span class="ol-share-file-ico">📄</span><span class="ol-share-file-name">Project-North-Plan-v4.docx</span></div><p class="ol-share-protection">🔒 This invitation only works for you and people with existing access.</p><div class="ol-share-actions">{{link:0}}</div></div></div>',
 '[{"label":"Open document","real_url":"https://kestrel.sharepoint.com/:w:/s/ProjectNorth/EYnRNcTq0/Project-North-Plan-v4.docx","suspicious":false,"warning":"This is a genuine SharePoint link within our own tenant (kestrel.sharepoint.com). Even safer: open SharePoint or Teams yourself and find the document under \"Shared with me\"."}]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Sender @sharepointonline.com is the official Microsoft notification domain","Link points to kestrel.sharepoint.com — our own tenant","Internal colleague (Emma via @kestrel.co.uk) is known","Personal message ties in with ongoing work (Thursday''s planning, Project North)","No pressure, no password request"]'::jsonb,
 'This is a genuine SharePoint share link from a colleague. The good pattern: notification via @sharepointonline.com, link to your own tenant (kestrel.sharepoint.com), a personal message attached. An even safer habit: open SharePoint or Teams yourself and find the document under "Shared with me".',
 70),

-- 8. PHISHING — Microsoft 365 password
('en', 'business',
 'Microsoft 365',
 'account-security@microsoft-365-secure.com',
 'The real Microsoft domain is microsoft.com. "microsoft-365-secure.com" is fake.',
 '2 days ago 08:14',
 'Your Microsoft 365 password expires today',
 'Your password for Microsoft 365 expires within 24 hours. Keep your current password...',
 E'<div class="eml fam-tech" style="--brand:#0067b8;--cta:#0067b8"><div class="eml-top"><span class="eml-logo">Microsoft 365</span></div><div class="eml-body"><p>Microsoft 365 Account Security</p><p>Your password for Microsoft 365 expires within 24 hours. After this period you will lose access to email, OneDrive and Teams.</p><p>Click below to keep your current password and prevent expiry:</p><div class="eml-cta" style="--cta:#0067b8">{{link:0}}</div><p>This action takes less than a minute. If you ignore this, your account will be temporarily locked.</p><p>Microsoft 365 Security Team</p></div><div class="eml-foot"><p>This is an automated message — please do not reply.</p><p>© 2026 Microsoft 365</p></div></div>',
 '[{"label":"Keep password","real_url":"http://microsoft-365-secure.com/keep-password","suspicious":true,"warning":"Microsoft never uses hyphenated domains like microsoft-365-secure.com. This is fake. Microsoft also never asks you to \"keep\" or \"confirm\" a password via a link."}]'::jsonb,
 TRUE,
 '["Sender @microsoft-365-secure.com (not @microsoft.com)","Time pressure: \"within 24 hours\", \"locked\"","Nonsensical concept: \"keep password\" via a link doesn''t exist","Threat of losing access","If Microsoft 365 wants to rotate a password, it happens at sign-in — not via a stand-alone email"]'::jsonb,
 '[]'::jsonb,
 'This is one of the most common business phishing variants. Microsoft never communicates password changes this way. Unsure? Close the email and go to portal.office.com yourself, or open Teams to see whether there''s really a problem.',
 80),

-- 9. REAL — Short question from a colleague
('en', 'business',
 'Emma Walsh',
 'e.walsh@kestrel.co.uk',
 'Own @kestrel.co.uk domain from a known colleague — fine.',
 '2 days ago 14:45',
 'Could you check the budget?',
 'Hi Jane, Mark asked whether you could quickly check that row 14 in the budget is right...',
 E'Hi Jane,\n\nMark asked whether you could quickly check that row 14 in the Project North budget is right. He thinks the amount is wrong, but I''m not sure he was looking at the latest version.\n\nThe budget lives on the team share under /Projects/North/2026/.\n\nCould you let him know?\n\nThanks!\nEmma',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Sender @kestrel.co.uk, known colleague","Concrete internal context (Mark, Project North, team share path)","No link to an external domain","No request for data, passwords or money","Informal tone fits normal internal communication"]'::jsonb,
 'This is a normal work question from a colleague. Nothing to do other than look and reply. Note: a personally addressed, specific work context on an internal domain is generally a good sign.',
 10),

-- 10. PHISHING — Recruiter with malicious attachment
('en', 'business',
 'Sarah Clarke — Premium Talent',
 'sarah.clarke@premium-talent-careers.info',
 'A ".info" domain and a lone recruiter with no demonstrable connection to a known agency. Suspicious pattern.',
 '3 days ago 17:20',
 'Exclusive opportunity with an international client — profile shortlisted',
 'Dear Jane, I''ve reviewed your profile on LinkedIn and have an exclusive position...',
 E'Dear Jane,\n\nI''ve reviewed your profile and I have an exclusive senior position with an international client that, in my view, fits your experience perfectly. Salary range: £85k - £105k.\n\nThe role hasn''t been made public yet and it''s urgent. The client wants a shortlist this week.\n\nAttached you''ll find the job specification and the non-disclosure agreement (NDA) that I''d ask you to open and sign before I can share more details.\n\nKind regards,\nSarah Clarke\nPremium Talent — Executive Search',
 '[]'::jsonb,
 TRUE,
 '["Sender on a \".info\" domain with no known recognised agency","Unsolicited contact with an attachment","File name ends in .pdf.exe — that is an executable program disguised as a PDF","Time pressure: \"shortlist this week\"","Asks for confidentiality — designed to isolate you","Salary as bait with no verifiable context"]'::jsonb,
 '[]'::jsonb,
 'This is phishing with a malicious attachment. Files with double extensions (.pdf.exe) are executable programs disguised as documents. NEVER open them. A real recruiter with a real role does not send stand-alone executable attachments. Report to IT or delete the email.',
 100);

-- ============ FR — BUSINESS (1/2) ============

INSERT INTO inbox_messages
  (locale, audience, sender_name, sender_address, sender_note, received_label, subject, preview, body, links, is_phishing, red_flags, green_flags, explanation, sort_order) VALUES

-- 1. PHISHING — CEO fraud
('fr', 'business',
 'Jean-Philippe Moreau (CEO)',
 'jp.moreau@kestrel-group.com',
 'Le vrai domaine est @kestrel.fr. Ici c''est @kestrel-group.com — imitation.',
 'aujourd''hui 09:02',
 'Tu peux me rendre un service rapidement ?',
 'Pauline, je suis en réunion. Peux-tu régler quelque chose rapidement ? Ne m''appelle pas...',
 E'Pauline,\n\nJe suis en réunion importante avec un client et je ne peux pas être dérangé au téléphone. J''ai besoin de quelque chose d''urgent.\n\nPeux-tu acheter 5 cartes cadeaux Amazon à 100 € chacune ? Envoie-moi les codes par retour de mail dès que tu les as, je demanderai à la comptabilité de te rembourser. Merci de ne pas en parler autour de toi — c''est confidentiel pour le moment.\n\nMerci,\nJean-Philippe',
 '[]'::jsonb,
 TRUE,
 '["Expéditeur @kestrel-group.com, pas @kestrel.fr — domaine imitation","Demande des cartes cadeaux comme moyen de paiement (fraude au dirigeant classique)","Pression : \"ne m''appelle pas\", \"confidentiel\" — vise à vous isoler de vos collègues","Contourne la procédure normale — les dépenses passent par la comptabilité, pas par un salarié"]'::jsonb,
 '[]'::jsonb,
 'C''est de la fraude au dirigeant. Les escrocs se font passer pour un responsable et réclament des cartes cadeaux ou un virement urgent, sous couvert de confidentialité. En cas de doute, rendez-vous au bureau de l''expéditeur ou appelez-le sur son numéro connu — jamais via les coordonnées de l''e-mail suspect.',
 90),

-- 2. REAL — HR memo
('fr', 'business',
 'RH Kestrel',
 'rh@kestrel.fr',
 'Domaine interne @kestrel.fr — correct.',
 'aujourd''hui 10:15',
 'Nouvelle page congés sur MonKestrel',
 'Chers collègues, à partir de cette semaine, la page congés actualisée est disponible sur MonKestrel...',
 E'Chers collègues,\n\nÀ partir de cette semaine, la nouvelle page des congés est disponible sur MonKestrel. Vous y trouverez vos jours restants, un récapitulatif mensuel et le formulaire de demande.\n\nConnectez-vous comme d''habitude — rendez-vous vous-même sur MonKestrel via votre page de démarrage ou votre favori. Nous n''envoyons volontairement aucun lien direct.\n\nDes questions ? Passez aux RH ou écrivez à rh@kestrel.fr.\n\nCordialement,\nRH Kestrel',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Expéditeur @kestrel.fr, domaine interne officiel","Aucun lien cliquable — on vous demande d''aller VOUS-MÊME sur MonKestrel","Aucune demande de mot de passe ou d''informations personnelles","Communication concrète et plausible","Renvoie aux RH comme point de contact connu"]'::jsonb,
 'C''est une vraie communication RH. Le bon réflexe : AUCUN lien direct n''est envoyé, on vous demande de vous rendre vous-même sur MonKestrel. C''est ainsi que devrait ressembler une communication interne professionnelle.',
 20),

-- 3. PHISHING — IT mot de passe
('fr', 'business',
 'Support Informatique',
 'support-it@kestrel-helpdesk.com',
 'Pas @kestrel.fr mais @kestrel-helpdesk.com — un autre domaine qui imite l''entreprise. Suspect.',
 'aujourd''hui 11:30',
 'Votre mot de passe expire aujourd''hui à 17h — renouvelez maintenant',
 'Votre mot de passe Kestrel expire aujourd''hui. Renouvelez-le immédiatement pour éviter le blocage...',
 E'Cher utilisateur,\n\nVotre mot de passe Kestrel expire aujourd''hui à 17h. Si vous ne le renouvelez pas, vous perdrez l''accès à la messagerie, SharePoint et Teams.\n\nUtilisez le lien ci-dessous pour renouveler votre mot de passe. Cela prend 30 secondes.\n\n{{link:0}}\n\nCordialement,\nSupport Informatique Kestrel',
 '[{"label":"Renouveler le mot de passe","real_url":"http://kestrel-helpdesk.com/password-renew","suspicious":true,"warning":"Ce lien mène vers kestrel-helpdesk.com — PAS le domaine officiel de Kestrel. Votre vrai service informatique envoie les liens de renouvellement via le portail interne, pas via un domaine séparé."}]'::jsonb,
 TRUE,
 '["Expéditeur @kestrel-helpdesk.com, pas @kestrel.fr","Pression temporelle (\"expire aujourd''hui à 17h\") pour vous faire cliquer sans réfléchir","Menace de perte d''accès — ton anxiogène","Lien vers un domaine qui ressemble à l''entreprise mais n''en fait pas partie","Les vrais services informatiques vous font vous connecter via des portails internes, jamais via un lien isolé dans un e-mail"]'::jsonb,
 '[]'::jsonb,
 'C''est du hameçonnage qui se fait passer pour votre service informatique. Votre vrai service informatique envoie rarement des liens de réinitialisation, et quand il le fait, c''est via le domaine interne et le portail officiel. Dans le doute, appelez un(e) collègue de l''informatique ou passez le voir — jamais via le numéro indiqué dans l''e-mail.',
 30),

-- 4. PHISHING — Faux partage SharePoint
('fr', 'business',
 'Microsoft OneDrive',
 'no-reply@sharepoint-online-share.com',
 'Les vraies notifications SharePoint viennent de @sharepointonline.com et le lien pointe vers votre propre tenant (p. ex. kestrel.sharepoint.com). Ce domaine est faux.',
 'aujourd''hui 13:47',
 'MARTIN Julien a partagé "Contrat-Cadre-2026.pdf" avec vous',
 'MARTIN Julien a partagé un document avec vous via OneDrive. Consultez-le maintenant...',
 E'<div class="ol-share-card"><div class="ol-share-head"><div class="ol-share-icon">⤴</div><h2 class="ol-share-heading">MARTIN Julien vous a invité à modifier un fichier</h2><p class="ol-share-intro" style="color:#888;font-size:.85em">julien.martin@kestrel-partner.com</p></div><div class="ol-share-body"><p class="ol-share-intro">Voici le document que MARTIN Julien a partagé avec vous.</p><div class="ol-share-file"><span class="ol-share-file-ico">📄</span><span class="ol-share-file-name">Contrat-Cadre-2026.pdf</span></div><p class="ol-share-protection">🔒 Cette invitation ne fonctionne que pour vous et les personnes ayant déjà accès.</p><div class="ol-share-actions">{{link:0}}</div></div></div>',
 '[{"label":"Ouvrir le document","real_url":"http://sharepoint-online-share.com/view?id=8a3f2","suspicious":true,"warning":"Ce n''est pas un domaine Microsoft. Les vrais liens SharePoint et OneDrive pointent vers votre propre tenant (p. ex. kestrel.sharepoint.com) ou vers onedrive.live.com. \"sharepoint-online-share.com\" est faux. De plus, Julien utilise @kestrel-partner.com, pas @kestrel.fr."}]'::jsonb,
 TRUE,
 '["Domaine expéditeur sharepoint-online-share.com — pas un domaine Microsoft ni Kestrel","L''\"partageur\" Julien Martin utilise @kestrel-partner.com — pas notre @kestrel.fr","Document inattendu sans contexte","Le lien mène à un domaine externe isolé, pas à kestrel.sharepoint.com"]'::jsonb,
 '[]'::jsonb,
 'C''est du hameçonnage qui imite un lien de partage SharePoint/OneDrive. Les vrais liens de partage pointent vers votre tenant Microsoft 365 (p. ex. kestrel.sharepoint.com) ou vers onedrive.live.com. En cas de doute, ouvrez SharePoint ou l''application Teams vous-même et vérifiez sous « Partagé avec moi » si le document y est.',
 40),

-- 5. REAL — Invitation réunion collègue
('fr', 'business',
 'Claire Lambert',
 'c.lambert@kestrel.fr',
 'Domaine interne @kestrel.fr d''une collègue connue — correct.',
 'aujourd''hui 14:12',
 'Réunion jeudi 14h — planification Q2',
 'Bonjour Pauline, peux-tu te joindre à la planification Q2 jeudi à 14h ? Ordre du jour ci-dessous...',
 E'Bonjour Pauline,\n\nPeux-tu te joindre à la planification Q2 jeudi à 14h ? On abordera :\n\n• Statut des projets en cours\n• Planning de mai et juin\n• Priorités pour l''équipe\n\nUne heure maximum. Salle Érable, ou via Teams si tu préfères. Confirme-moi ta présence.\n\nMerci !\nClaire',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Expéditeur @kestrel.fr, domaine interne officiel","Collègue connue avec qui vous travaillez","Contexte de travail concret et plausible","Aucun lien, aucune pièce jointe, aucune demande d''information","Ton informel et personnel — cohérent avec la communication interne"]'::jsonb,
 'C''est une invitation de réunion tout à fait normale d''une collègue. Aucune action à prendre en dehors d''une réponse sur le fond. Bonne leçon : un e-mail interne adressé personnellement, concret, sans lien ni pièce jointe, est en général un bon signe.',
 50);

-- ============ FR — BUSINESS (2/2) ============

INSERT INTO inbox_messages
  (locale, audience, sender_name, sender_address, sender_note, received_label, subject, preview, body, links, is_phishing, red_flags, green_flags, explanation, sort_order) VALUES

-- 6. PHISHING — Fake vendor invoice
('fr', 'business',
 'Comptabilité — Atelier Impression SARL',
 'factures@imprimerie-services.com',
 'Fournisseur inconnu sur un domaine .com isolé. Les vrais fournisseurs de Kestrel figurent dans le système d''achats.',
 'hier 15:30',
 'Facture P-2026-0452 — délai de paiement dépassé',
 'Madame, Monsieur, veuillez trouver ci-joint la facture en souffrance. Merci de régler rapidement...',
 E'Madame, Monsieur,\n\nVeuillez trouver ci-joint la facture P-2026-0452 pour la maintenance trimestrielle des imprimantes (Q1), d''un montant de 1 847,50 €.\n\nLe délai de paiement de 14 jours est désormais dépassé. Merci de régler immédiatement pour éviter les pénalités de retard. Les coordonnées de paiement sont dans la pièce jointe.\n\nPour régler rapidement : {{link:0}}\n\nCordialement,\nComptabilité — Atelier Impression SARL',
 '[{"label":"Payer maintenant","real_url":"http://imprimerie-services.com/pay/P-2026-0452","suspicious":true,"warning":"Domaine de paiement inconnu. Chez Kestrel, les factures passent par le portail des achats — pas via un lien isolé dans un e-mail."}]'::jsonb,
 TRUE,
 '["Fournisseur inconnu — absent du système d''achats","Pression temporelle : \"délai dépassé\", \"régler immédiatement\"","Lien de paiement isolé au lieu du portail des achats","Formule générique \"Madame, Monsieur\" — devrait utiliser votre nom","Le montant (1 847,50 €) est juste assez élevé pour presser, assez bas pour ne pas attirer l''attention"]'::jsonb,
 '[]'::jsonb,
 'C''est de la fraude à la fausse facture. Un fournisseur inconnu envoyant une facture inattendue doit d''abord être vérifié auprès du service Achats ou Comptabilité fournisseurs. Ne payez jamais via un lien dans un e-mail — toujours via votre propre portail d''achats ou après un nouvel examen de la facture.',
 60),

-- 7. REAL — Document SharePoint partagé par une collègue
('fr', 'business',
 'Microsoft SharePoint',
 'no-reply@sharepointonline.com',
 'Les vraies notifications SharePoint viennent de @sharepointonline.com et le lien pointe vers votre propre tenant (kestrel.sharepoint.com).',
 'hier 09h00',
 'LAMBERT Claire a partagé "Plan-Projet-Nord-v4.docx" avec vous',
 'LAMBERT Claire a partagé un document avec vous : Plan-Projet-Nord-v4.docx...',
 E'<div class="ol-share-card"><div class="ol-share-head"><div class="ol-share-icon">⤴</div><h2 class="ol-share-heading">LAMBERT Claire vous a invité à modifier un fichier</h2></div><div class="ol-share-body"><p class="ol-share-msg">"Bonjour Pauline, voici la version pour la planification de jeudi. Dis-moi si quelque chose doit être modifié."</p><p class="ol-share-intro">Voici le document que LAMBERT Claire a partagé avec vous.</p><div class="ol-share-file"><span class="ol-share-file-ico">📄</span><span class="ol-share-file-name">Plan-Projet-Nord-v4.docx</span></div><p class="ol-share-protection">🔒 Cette invitation ne fonctionne que pour vous et les personnes ayant déjà accès.</p><div class="ol-share-actions">{{link:0}}</div></div></div>',
 '[{"label":"Ouvrir le document","real_url":"https://kestrel.sharepoint.com/:w:/s/ProjetNord/EYnRNcTq0/Plan-Projet-Nord-v4.docx","suspicious":false,"warning":"C''est un vrai lien SharePoint au sein de notre propre tenant (kestrel.sharepoint.com). Encore plus sûr : ouvrez SharePoint ou Teams vous-même et retrouvez le document sous « Partagé avec moi »."}]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Expéditeur @sharepointonline.com est le domaine officiel de notification Microsoft","Le lien pointe vers kestrel.sharepoint.com — notre propre tenant","Collègue interne (Claire via @kestrel.fr) connue","Message personnel relié au travail en cours (planification de jeudi, projet Nord)","Aucune pression, aucune demande de mot de passe"]'::jsonb,
 'C''est un vrai lien de partage SharePoint d''une collègue. Le bon modèle : notification via @sharepointonline.com, lien vers votre propre tenant (kestrel.sharepoint.com), message personnel joint. Habitude encore plus sûre : ouvrez SharePoint ou Teams vous-même et retrouvez le document sous « Partagé avec moi ».',
 70),

-- 8. PHISHING — Microsoft 365
('fr', 'business',
 'Microsoft 365',
 'account-security@microsoft-365-secure.com',
 'Le vrai domaine Microsoft est microsoft.com. "microsoft-365-secure.com" est faux.',
 'il y a 2 jours 08h14',
 'Votre mot de passe Microsoft 365 expire aujourd''hui',
 'Votre mot de passe Microsoft 365 expire dans 24 heures. Conservez votre mot de passe actuel...',
 E'<div class="eml fam-tech" style="--brand:#0067b8;--cta:#0067b8"><div class="eml-top"><span class="eml-logo">Microsoft 365</span></div><div class="eml-body"><p>Sécurité du compte Microsoft 365</p><p>Votre mot de passe Microsoft 365 expire dans 24 heures. Passé ce délai, vous perdrez l''accès à la messagerie, à OneDrive et à Teams.</p><p>Cliquez ci-dessous pour conserver votre mot de passe actuel et éviter l''expiration :</p><div class="eml-cta" style="--cta:#0067b8">{{link:0}}</div><p>Cette action prend moins d''une minute. Si vous l''ignorez, votre compte sera temporairement verrouillé.</p><p>Équipe Sécurité Microsoft 365</p></div><div class="eml-foot"><p>Ceci est un message automatique — merci de ne pas y répondre.</p><p>© 2026 Microsoft 365</p></div></div>',
 '[{"label":"Conserver le mot de passe","real_url":"http://microsoft-365-secure.com/keep-password","suspicious":true,"warning":"Microsoft n''utilise jamais de domaines avec des tirets comme microsoft-365-secure.com. C''est faux. Microsoft ne vous demande jamais non plus de \"conserver\" ou \"confirmer\" un mot de passe via un lien."}]'::jsonb,
 TRUE,
 '["Expéditeur @microsoft-365-secure.com (pas @microsoft.com)","Pression temporelle : \"dans 24 heures\", \"verrouillé\"","Concept absurde : \"conserver un mot de passe\" via un lien n''existe pas","Menace de perte d''accès","Si Microsoft 365 souhaite renouveler un mot de passe, cela se passe à la connexion — pas via un e-mail isolé"]'::jsonb,
 '[]'::jsonb,
 'C''est l''une des variantes de hameçonnage les plus fréquentes en entreprise. Microsoft ne communique jamais ainsi sur les mots de passe. En cas de doute, fermez l''e-mail et rendez-vous vous-même sur portal.office.com ou ouvrez Teams pour voir s''il y a réellement un problème.',
 80),

-- 9. REAL — Question courte d'un collègue
('fr', 'business',
 'Claire Lambert',
 'c.lambert@kestrel.fr',
 'Domaine interne @kestrel.fr d''une collègue connue — correct.',
 'il y a 2 jours 14h45',
 'Tu peux jeter un œil au budget ?',
 'Bonjour Pauline, Marc demande si tu peux vérifier rapidement la ligne 14 du budget...',
 E'Bonjour Pauline,\n\nMarc demande si tu peux vérifier rapidement que la ligne 14 du budget du projet Nord est correcte. Selon lui le montant est faux, mais je ne suis pas sûre qu''il regardait la bonne version.\n\nLe budget est sur le partage d''équipe sous /Projets/Nord/2026/.\n\nTu peux lui faire un retour ?\n\nMerci !\nClaire',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Expéditeur @kestrel.fr, collègue connue","Contexte interne concret (Marc, projet Nord, chemin du partage d''équipe)","Aucun lien vers un domaine externe","Aucune demande d''information, de mot de passe ou d''argent","Ton informel cohérent avec la communication interne normale"]'::jsonb,
 'C''est une question de travail tout à fait normale d''une collègue. Rien à faire sinon regarder et répondre. À retenir : un contexte de travail concret et personnalisé sur un domaine interne est en général un bon signe.',
 10),

-- 10. PHISHING — Recruteur avec pièce jointe malveillante
('fr', 'business',
 'Sophie Clément — Premium Talent',
 'sophie.clement@premium-talent-careers.info',
 'Domaine en ".info" et recruteuse isolée sans lien démontrable avec un cabinet connu. Schéma suspect.',
 'il y a 3 jours 17h20',
 'Opportunité exclusive chez un grand compte international — profil sélectionné',
 'Bonjour Pauline, j''ai examiné votre profil sur LinkedIn et j''ai un poste exclusif...',
 E'Bonjour Pauline,\n\nJ''ai examiné votre profil et j''ai un poste senior exclusif chez un grand compte international qui correspond parfaitement à votre expérience, selon moi. Fourchette de rémunération : 85 000 € — 105 000 € brut.\n\nLe poste n''a pas été rendu public et il y a urgence. Le client veut une shortlist cette semaine.\n\nEn pièce jointe, vous trouverez la fiche de poste et l''accord de confidentialité (NDA) que je vous demande d''ouvrir et de signer avant que je puisse vous communiquer plus de détails.\n\nCordialement,\nSophie Clément\nPremium Talent — Executive Search',
 '[]'::jsonb,
 TRUE,
 '["Expéditrice sur un domaine \".info\" sans cabinet reconnu","Contact non sollicité avec une pièce jointe","Le nom du fichier se termine par .pdf.exe — c''est un programme exécutable déguisé en PDF","Pression temporelle : \"shortlist cette semaine\"","Confidentialité demandée — vise à vous isoler","Rémunération utilisée comme appât, sans contexte vérifiable"]'::jsonb,
 '[]'::jsonb,
 'C''est du hameçonnage avec une pièce jointe malveillante. Les fichiers à double extension (.pdf.exe) sont des programmes exécutables déguisés en document. Ne les ouvrez JAMAIS. Un(e) vrai(e) recruteur(se) sérieux(se) avec un vrai poste n''envoie pas de pièces jointes exécutables isolées. Signalez-le à l''informatique ou supprimez l''e-mail.',
 100);

-- ============ fr-BE — BUSINESS (1/2) ============

INSERT INTO inbox_messages
  (locale, audience, sender_name, sender_address, sender_note, received_label, subject, preview, body, links, is_phishing, red_flags, green_flags, explanation, sort_order) VALUES

-- 1. PHISHING — CEO fraud
('fr-BE', 'business',
 'Philippe Vermeulen (CEO)',
 'p.vermeulen@kestrel-group.com',
 'Le vrai domaine est @kestrel.be. Ici c''est @kestrel-group.com — imitation.',
 'aujourd''hui 09:02',
 'Tu peux me rendre un service rapidement ?',
 'Pauline, je suis en réunion. Peux-tu régler quelque chose rapidement ? Ne m''appelle pas...',
 E'Pauline,\n\nJe suis en réunion importante avec un client et je ne peux pas être dérangé au téléphone. J''ai besoin de quelque chose d''urgent.\n\nPeux-tu acheter 5 cartes cadeaux Bol.com à 100 € chacune ? Envoie-moi les codes par retour de mail dès que tu les as, je demanderai à la comptabilité de te rembourser. Merci de ne pas en parler autour de toi — c''est confidentiel pour le moment.\n\nMerci,\nPhilippe',
 '[]'::jsonb,
 TRUE,
 '["Expéditeur @kestrel-group.com, pas @kestrel.be — domaine imitation","Demande des cartes cadeaux comme moyen de paiement (fraude au dirigeant classique)","Pression : \"ne m''appelle pas\", \"confidentiel\" — vise à vous isoler de vos collègues","Contourne la procédure normale — les dépenses passent par la comptabilité"]'::jsonb,
 '[]'::jsonb,
 'C''est de la fraude au dirigeant. Les escrocs se font passer pour un responsable et réclament des cartes cadeaux ou un virement urgent, sous couvert de confidentialité. En cas de doute, rendez-vous au bureau de l''expéditeur ou appelez-le sur son numéro connu — jamais via les coordonnées de l''e-mail suspect.',
 90),

-- 2. REAL — HR memo
('fr-BE', 'business',
 'RH Kestrel',
 'rh@kestrel.be',
 'Domaine interne @kestrel.be — correct.',
 'aujourd''hui 10:15',
 'Nouvelle page congés sur MonKestrel',
 'Chers collègues, dès cette semaine, la page congés actualisée est disponible sur MonKestrel...',
 E'Chers collègues,\n\nDès cette semaine, la nouvelle page des congés est disponible sur MonKestrel. Vous y trouverez vos jours restants, un récapitulatif mensuel et le formulaire de demande.\n\nConnectez-vous comme d''habitude — rendez-vous vous-même sur MonKestrel via votre page d''accueil ou votre favori. Nous n''envoyons volontairement aucun lien direct.\n\nDes questions ? Passez au service RH ou écrivez à rh@kestrel.be.\n\nBien à vous,\nRH Kestrel',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Expéditeur @kestrel.be, domaine interne officiel","Aucun lien cliquable — on vous demande d''aller VOUS-MÊME sur MonKestrel","Aucune demande de mot de passe ou d''informations personnelles","Communication concrète et plausible","Renvoie aux RH comme point de contact connu"]'::jsonb,
 'C''est une vraie communication RH. Le bon réflexe : AUCUN lien direct n''est envoyé, on vous demande de vous rendre vous-même sur MonKestrel. C''est ainsi que devrait ressembler une communication interne professionnelle.',
 20),

-- 3. PHISHING — IT mot de passe
('fr-BE', 'business',
 'Support Informatique',
 'support-it@kestrel-helpdesk.com',
 'Pas @kestrel.be mais @kestrel-helpdesk.com — un autre domaine qui imite l''entreprise. Suspect.',
 'aujourd''hui 11:30',
 'Votre mot de passe expire aujourd''hui à 17h — renouvelez maintenant',
 'Votre mot de passe Kestrel expire aujourd''hui. Renouvelez-le immédiatement...',
 E'Cher utilisateur,\n\nVotre mot de passe Kestrel expire aujourd''hui à 17h. Si vous ne le renouvelez pas, vous perdrez l''accès à la messagerie, SharePoint et Teams.\n\nUtilisez le lien ci-dessous pour renouveler votre mot de passe. Cela prend 30 secondes.\n\n{{link:0}}\n\nBien à vous,\nSupport Informatique Kestrel',
 '[{"label":"Renouveler le mot de passe","real_url":"http://kestrel-helpdesk.com/password-renew","suspicious":true,"warning":"Ce lien mène vers kestrel-helpdesk.com — PAS le domaine officiel de Kestrel. Votre vrai service informatique envoie les liens de renouvellement via le portail interne, pas via un domaine séparé."}]'::jsonb,
 TRUE,
 '["Expéditeur @kestrel-helpdesk.com, pas @kestrel.be","Pression temporelle (\"expire aujourd''hui à 17h\") pour vous faire cliquer sans réfléchir","Menace de perte d''accès","Lien vers un domaine qui ressemble à l''entreprise mais n''en fait pas partie","Les vrais services informatiques utilisent des portails internes, jamais un lien isolé dans un e-mail"]'::jsonb,
 '[]'::jsonb,
 'C''est du hameçonnage qui se fait passer pour votre service informatique. Dans le doute, appelez un(e) collègue de l''informatique ou passez le voir — jamais via le numéro indiqué dans l''e-mail.',
 30),

-- 4. PHISHING — Faux partage SharePoint
('fr-BE', 'business',
 'Microsoft OneDrive',
 'no-reply@sharepoint-online-share.com',
 'Les vraies notifications SharePoint viennent de @sharepointonline.com et le lien pointe vers votre propre tenant (p. ex. kestrel.sharepoint.com). Ce domaine est faux.',
 'aujourd''hui 13:47',
 'LECLERCQ Thomas a partagé "Contrat-Cadre-2026.pdf" avec vous',
 'LECLERCQ Thomas a partagé un document avec vous via OneDrive. Consultez-le maintenant...',
 E'<div class="ol-share-card"><div class="ol-share-head"><div class="ol-share-icon">⤴</div><h2 class="ol-share-heading">LECLERCQ Thomas vous a invité à modifier un fichier</h2><p class="ol-share-intro" style="color:#888;font-size:.85em">thomas.leclercq@kestrel-partner.com</p></div><div class="ol-share-body"><p class="ol-share-intro">Voici le document que LECLERCQ Thomas a partagé avec vous.</p><div class="ol-share-file"><span class="ol-share-file-ico">📄</span><span class="ol-share-file-name">Contrat-Cadre-2026.pdf</span></div><p class="ol-share-protection">🔒 Cette invitation ne fonctionne que pour vous et les personnes ayant déjà accès.</p><div class="ol-share-actions">{{link:0}}</div></div></div>',
 '[{"label":"Ouvrir le document","real_url":"http://sharepoint-online-share.com/view?id=8a3f2","suspicious":true,"warning":"Ce n''est pas un domaine Microsoft. Les vrais liens SharePoint et OneDrive pointent vers votre propre tenant (p. ex. kestrel.sharepoint.com) ou vers onedrive.live.com. \"sharepoint-online-share.com\" est faux. De plus, Thomas utilise @kestrel-partner.com, pas @kestrel.be."}]'::jsonb,
 TRUE,
 '["Domaine expéditeur sharepoint-online-share.com — pas un domaine Microsoft ni Kestrel","Le \"partageur\" Thomas Leclercq utilise @kestrel-partner.com — pas notre @kestrel.be","Document inattendu sans contexte","Le lien mène à un domaine externe isolé, pas à kestrel.sharepoint.com"]'::jsonb,
 '[]'::jsonb,
 'C''est du hameçonnage qui imite un lien de partage SharePoint/OneDrive. Les vrais liens pointent vers votre tenant Microsoft 365 (p. ex. kestrel.sharepoint.com) ou vers onedrive.live.com. En cas de doute, ouvrez SharePoint ou Teams vous-même et vérifiez sous « Partagé avec moi » si le document y est.',
 40),

-- 5. REAL — Invitation réunion collègue
('fr-BE', 'business',
 'Marie Lemaire',
 'm.lemaire@kestrel.be',
 'Domaine interne @kestrel.be d''une collègue connue — correct.',
 'aujourd''hui 14:12',
 'Réunion jeudi 14h — planification Q2',
 'Bonjour Pauline, peux-tu te joindre à la planification Q2 jeudi à 14h ?',
 E'Bonjour Pauline,\n\nPeux-tu te joindre à la planification Q2 jeudi à 14h ? On abordera :\n\n• Statut des projets en cours\n• Planning de mai et juin\n• Priorités pour l''équipe\n\nUne heure maximum. Salle Magnolia, ou via Teams si tu préfères. Confirme-moi ta présence.\n\nMerci !\nMarie',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Expéditeur @kestrel.be, domaine interne officiel","Collègue connue avec qui vous travaillez","Contexte de travail concret et plausible","Aucun lien, aucune pièce jointe, aucune demande d''information","Ton informel et personnel — cohérent avec la communication interne"]'::jsonb,
 'C''est une invitation de réunion tout à fait normale. Aucune action à prendre en dehors d''une réponse sur le fond. À retenir : un e-mail interne adressé personnellement, concret, sans lien ni pièce jointe, est en général un bon signe.',
 50);

-- ============ fr-BE — BUSINESS (2/2) ============

INSERT INTO inbox_messages
  (locale, audience, sender_name, sender_address, sender_note, received_label, subject, preview, body, links, is_phishing, red_flags, green_flags, explanation, sort_order) VALUES

-- 6. PHISHING — Fake vendor invoice
('fr-BE', 'business',
 'Comptabilité — Atelier Impression SPRL',
 'factures@imprimerie-services.com',
 'Fournisseur inconnu sur un domaine .com isolé. Les vrais fournisseurs de Kestrel figurent dans le système d''achats.',
 'hier 15:30',
 'Facture P-2026-0452 — délai de paiement dépassé',
 'Madame, Monsieur, veuillez trouver ci-joint la facture en souffrance. Merci de régler rapidement...',
 E'Madame, Monsieur,\n\nVeuillez trouver ci-joint la facture P-2026-0452 pour la maintenance trimestrielle des imprimantes (Q1), d''un montant de 1.847,50 €.\n\nLe délai de paiement de 14 jours est désormais dépassé. Merci de régler immédiatement pour éviter les pénalités de retard.\n\nPour régler rapidement : {{link:0}}\n\nBien à vous,\nComptabilité — Atelier Impression SPRL',
 '[{"label":"Payer maintenant","real_url":"http://imprimerie-services.com/pay/P-2026-0452","suspicious":true,"warning":"Domaine de paiement inconnu. Chez Kestrel, les factures passent par le portail des achats — pas via un lien isolé dans un e-mail."}]'::jsonb,
 TRUE,
 '["Fournisseur inconnu — absent du système d''achats","Pression temporelle : \"délai dépassé\", \"régler immédiatement\"","Lien de paiement isolé au lieu du portail des achats","Formule générique \"Madame, Monsieur\" — devrait utiliser votre nom","Le montant est juste assez élevé pour presser, assez bas pour ne pas attirer l''attention"]'::jsonb,
 '[]'::jsonb,
 'C''est de la fraude à la fausse facture. Un fournisseur inconnu envoyant une facture inattendue doit d''abord être vérifié auprès du service Achats. Ne payez jamais via un lien dans un e-mail.',
 60),

-- 7. REAL — Document SharePoint partagé par une collègue
('fr-BE', 'business',
 'Microsoft SharePoint',
 'no-reply@sharepointonline.com',
 'Les vraies notifications SharePoint viennent de @sharepointonline.com et le lien pointe vers votre propre tenant (kestrel.sharepoint.com).',
 'hier 09h00',
 'LEMAIRE Marie a partagé "Plan-Projet-Nord-v4.docx" avec vous',
 'LEMAIRE Marie a partagé un document avec vous : Plan-Projet-Nord-v4.docx...',
 E'<div class="ol-share-card"><div class="ol-share-head"><div class="ol-share-icon">⤴</div><h2 class="ol-share-heading">LEMAIRE Marie vous a invité à modifier un fichier</h2></div><div class="ol-share-body"><p class="ol-share-msg">"Bonjour Pauline, voici la version pour la planification de jeudi. Dis-moi si quelque chose doit être modifié."</p><p class="ol-share-intro">Voici le document que LEMAIRE Marie a partagé avec vous.</p><div class="ol-share-file"><span class="ol-share-file-ico">📄</span><span class="ol-share-file-name">Plan-Projet-Nord-v4.docx</span></div><p class="ol-share-protection">🔒 Cette invitation ne fonctionne que pour vous et les personnes ayant déjà accès.</p><div class="ol-share-actions">{{link:0}}</div></div></div>',
 '[{"label":"Ouvrir le document","real_url":"https://kestrel.sharepoint.com/:w:/s/ProjetNord/EYnRNcTq0/Plan-Projet-Nord-v4.docx","suspicious":false,"warning":"C''est un vrai lien SharePoint au sein de notre propre tenant (kestrel.sharepoint.com). Encore plus sûr : ouvrez SharePoint ou Teams vous-même et retrouvez le document sous « Partagé avec moi »."}]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Expéditeur @sharepointonline.com est le domaine officiel de notification Microsoft","Le lien pointe vers kestrel.sharepoint.com — notre propre tenant","Collègue interne (Marie via @kestrel.be) connue","Message personnel relié au travail en cours (planification de jeudi, projet Nord)","Aucune pression, aucune demande de mot de passe"]'::jsonb,
 'C''est un vrai lien de partage SharePoint d''une collègue. Le bon modèle : notification via @sharepointonline.com, lien vers votre propre tenant (kestrel.sharepoint.com), message personnel joint.',
 70),

-- 8. PHISHING — Microsoft 365
('fr-BE', 'business',
 'Microsoft 365',
 'account-security@microsoft-365-secure.com',
 'Le vrai domaine Microsoft est microsoft.com. "microsoft-365-secure.com" est faux.',
 'il y a 2 jours 08h14',
 'Votre mot de passe Microsoft 365 expire aujourd''hui',
 'Votre mot de passe Microsoft 365 expire dans 24 heures. Conservez votre mot de passe actuel...',
 E'<div class="eml fam-tech" style="--brand:#0067b8;--cta:#0067b8"><div class="eml-top"><span class="eml-logo">Microsoft 365</span></div><div class="eml-body"><p>Sécurité du compte Microsoft 365</p><p>Votre mot de passe Microsoft 365 expire dans 24 heures. Passé ce délai, vous perdrez l''accès à la messagerie, à OneDrive et à Teams.</p><p>Cliquez ci-dessous pour conserver votre mot de passe actuel :</p><div class="eml-cta" style="--cta:#0067b8">{{link:0}}</div><p>Cette action prend moins d''une minute. Si vous l''ignorez, votre compte sera temporairement verrouillé.</p><p>Équipe Sécurité Microsoft 365</p></div><div class="eml-foot"><p>Ceci est un message automatique — merci de ne pas y répondre.</p><p>© 2026 Microsoft 365</p></div></div>',
 '[{"label":"Conserver le mot de passe","real_url":"http://microsoft-365-secure.com/keep-password","suspicious":true,"warning":"Microsoft n''utilise jamais de domaines avec des tirets. C''est faux. Microsoft ne vous demande jamais de \"conserver\" un mot de passe via un lien."}]'::jsonb,
 TRUE,
 '["Expéditeur @microsoft-365-secure.com (pas @microsoft.com)","Pression temporelle : \"dans 24 heures\", \"verrouillé\"","Concept absurde : \"conserver un mot de passe\" via un lien n''existe pas","Menace de perte d''accès","Si Microsoft 365 souhaite renouveler un mot de passe, cela se passe à la connexion — pas via un e-mail isolé"]'::jsonb,
 '[]'::jsonb,
 'C''est l''une des variantes de hameçonnage les plus fréquentes en entreprise. En cas de doute, fermez l''e-mail et rendez-vous vous-même sur portal.office.com ou ouvrez Teams pour voir s''il y a réellement un problème.',
 80),

-- 9. REAL — Question d'une collègue
('fr-BE', 'business',
 'Marie Lemaire',
 'm.lemaire@kestrel.be',
 'Domaine interne @kestrel.be d''une collègue connue — correct.',
 'il y a 2 jours 14h45',
 'Tu peux jeter un œil au budget ?',
 'Bonjour Pauline, Marc demande si tu peux vérifier rapidement la ligne 14...',
 E'Bonjour Pauline,\n\nMarc demande si tu peux vérifier rapidement que la ligne 14 du budget du projet Nord est correcte. Selon lui le montant est faux, mais je ne suis pas sûre qu''il regardait la bonne version.\n\nLe budget est sur le partage d''équipe sous /Projets/Nord/2026/.\n\nTu peux lui faire un retour ?\n\nMerci !\nMarie',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Expéditeur @kestrel.be, collègue connue","Contexte interne concret (Marc, projet Nord, chemin du partage d''équipe)","Aucun lien vers un domaine externe","Aucune demande d''information, de mot de passe ou d''argent","Ton informel cohérent avec la communication interne normale"]'::jsonb,
 'C''est une question de travail tout à fait normale. Rien à faire sinon regarder et répondre. À retenir : un contexte de travail concret et personnalisé sur un domaine interne est en général un bon signe.',
 10),

-- 10. PHISHING — Recruiter with attachment
('fr-BE', 'business',
 'Sophie Delvaux — Premium Talent',
 'sophie.delvaux@premium-talent-careers.info',
 'Domaine en ".info" et recruteuse isolée sans lien démontrable avec un cabinet connu. Schéma suspect.',
 'il y a 3 jours 17h20',
 'Opportunité exclusive chez un grand compte international — profil sélectionné',
 'Bonjour Pauline, j''ai examiné votre profil sur LinkedIn et j''ai un poste exclusif...',
 E'Bonjour Pauline,\n\nJ''ai examiné votre profil et j''ai un poste senior exclusif chez un grand compte international qui correspond parfaitement à votre expérience, selon moi. Fourchette de rémunération : 85.000 € — 105.000 € brut.\n\nLe poste n''a pas été rendu public et il y a urgence. Le client veut une shortlist cette semaine.\n\nEn pièce jointe, vous trouverez la fiche de poste et l''accord de confidentialité (NDA) que je vous demande d''ouvrir et de signer avant que je puisse vous communiquer plus de détails.\n\nBien à vous,\nSophie Delvaux\nPremium Talent — Executive Search',
 '[]'::jsonb,
 TRUE,
 '["Expéditrice sur un domaine \".info\" sans cabinet reconnu","Contact non sollicité avec une pièce jointe","Le nom du fichier se termine par .pdf.exe — c''est un programme exécutable déguisé en PDF","Pression temporelle : \"shortlist cette semaine\"","Confidentialité demandée — vise à vous isoler","Rémunération utilisée comme appât, sans contexte vérifiable"]'::jsonb,
 '[]'::jsonb,
 'C''est du hameçonnage avec une pièce jointe malveillante. Les fichiers à double extension (.pdf.exe) sont des programmes exécutables déguisés en document. Ne les ouvrez JAMAIS. Signalez-le à l''informatique ou supprimez l''e-mail.',
 100);

-- ============ DE — BUSINESS (1/2) ============

INSERT INTO inbox_messages
  (locale, audience, sender_name, sender_address, sender_note, received_label, subject, preview, body, links, is_phishing, red_flags, green_flags, explanation, sort_order) VALUES

-- 1. PHISHING — CEO-Betrug
('de', 'business',
 'Thomas Schneider (CEO)',
 't.schneider@kestrel-group.com',
 'Die echte Domain ist @kestrel.de. Hier steht @kestrel-group.com — eine Fälschung.',
 'heute 09:02',
 'Kannst du mir kurz einen Gefallen tun?',
 'Martina, ich bin in einer Besprechung. Kannst du schnell etwas für mich erledigen?',
 E'Martina,\n\nIch bin in einer wichtigen Kundenbesprechung und kann nicht telefonieren. Ich brauche dringend etwas.\n\nKannst du für mich 5 Amazon-Gutscheine à 100 € kaufen? Schick mir die Codes per Mail, sobald du sie hast, dann sorgt die Buchhaltung für die Erstattung. Bitte sprich mit niemandem darüber — das ist vertraulich, bis ich es erklären kann.\n\nDanke,\nThomas',
 '[]'::jsonb,
 TRUE,
 '["Absender @kestrel-group.com, nicht @kestrel.de — nachgemachte Domain","Bittet um Gutscheine als Zahlungsmittel (typischer CEO-Betrug)","Druck: \"nicht telefonieren\", \"vertraulich\" — soll Sie von Kollegen isolieren","Umgeht den normalen Prozess — Ausgaben laufen über die Buchhaltung, nicht über Mitarbeiter"]'::jsonb,
 '[]'::jsonb,
 'Das ist CEO-Betrug. Betrüger geben sich als Führungsperson aus und bitten um Gutscheine oder eine dringende Überweisung, unter dem Vorwand der Vertraulichkeit. Gehen Sie im Zweifel persönlich beim Absender vorbei oder rufen Sie ihn/sie auf der bekannten Nummer an — nie über etwas aus der verdächtigen E-Mail.',
 90),

-- 2. REAL — HR-Memo
('de', 'business',
 'HR Kestrel',
 'hr@kestrel.de',
 'Eigene Domain @kestrel.de — korrekt.',
 'heute 10:15',
 'Neue Urlaubsseite in MeinKestrel',
 'Liebe Kolleginnen und Kollegen, ab dieser Woche ist die aktualisierte Urlaubsseite in MeinKestrel verfügbar...',
 E'Liebe Kolleginnen und Kollegen,\n\nab dieser Woche ist die aktualisierte Urlaubsseite in MeinKestrel verfügbar. Sie finden dort Ihre verbleibenden Tage, eine monatliche Übersicht und das Antragsformular.\n\nMelden Sie sich wie gewohnt an — gehen Sie selbst auf MeinKestrel über Ihre Startseite oder Ihr Browser-Lesezeichen. Wir senden bewusst keinen Direktlink.\n\nFragen? Kommen Sie bei HR vorbei oder schreiben Sie an hr@kestrel.de.\n\nViele Grüße,\nHR Kestrel',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Absender @kestrel.de, die offizielle interne Domain","Kein anklickbarer Link — Sie werden gebeten, SELBST auf MeinKestrel zu gehen","Keine Abfrage von Passwort oder persönlichen Daten","Konkrete, plausible interne Ankündigung","Verweist auf HR als bekannten Ansprechpartner"]'::jsonb,
 'Das ist eine echte HR-Nachricht. Achten Sie auf das gute Muster: KEIN Direktlink, Sie navigieren selbst zu MeinKestrel. Genau so sollte professionelle interne Kommunikation aussehen.',
 20),

-- 3. PHISHING — IT Passwort-Reset
('de', 'business',
 'IT Support',
 'it-support@kestrel-helpdesk.com',
 'Nicht @kestrel.de, sondern @kestrel-helpdesk.com — eine separate, nachgemachte Domain. Verdächtig.',
 'heute 11:30',
 'Ihr Passwort läuft heute um 17:00 Uhr ab — jetzt verlängern',
 'Ihr Kestrel-Passwort läuft heute ab. Verlängern Sie es sofort, um eine Sperre zu vermeiden...',
 E'Sehr geehrte/r Nutzer/in,\n\nIhr Kestrel-Passwort läuft heute um 17:00 Uhr ab. Wenn Sie es nicht verlängern, verlieren Sie den Zugriff auf E-Mail, SharePoint und Teams.\n\nVerwenden Sie den untenstehenden Link, um Ihr Passwort zu verlängern. Das dauert 30 Sekunden.\n\n{{link:0}}\n\nMit freundlichen Grüßen,\nIT Support Kestrel',
 '[{"label":"Passwort verlängern","real_url":"http://kestrel-helpdesk.com/password-renew","suspicious":true,"warning":"Dieser Link führt zu kestrel-helpdesk.com — NICHT zur offiziellen Kestrel-Domain. Ihre echte IT verschickt Reset-Links über das interne Portal, nicht über eine separate Domain."}]'::jsonb,
 TRUE,
 '["Absender @kestrel-helpdesk.com, nicht @kestrel.de","Zeitdruck (\"läuft heute um 17:00 ab\"), damit Sie ohne Nachdenken klicken","Drohung mit Zugriffsverlust","Link zu einer Domain, die wie das Unternehmen aussieht, es aber nicht ist","Echte IT-Abteilungen lassen Sie sich über interne Portale anmelden, niemals über einen isolierten Link in einer E-Mail"]'::jsonb,
 '[]'::jsonb,
 'Das ist Phishing, das Ihre eigene IT vortäuscht. Die echte IT verschickt selten Reset-Links, und wenn doch, dann über die interne Domain und das offizielle Portal. Im Zweifel: rufen Sie eine/n IT-Kollegin/Kollegen an oder gehen Sie persönlich vorbei — nie über die Nummer in der E-Mail.',
 30),

-- 4. PHISHING — Gefälschter SharePoint-Freigabelink
('de', 'business',
 'Microsoft OneDrive',
 'no-reply@sharepoint-online-share.com',
 'Echte SharePoint-Benachrichtigungen kommen von @sharepointonline.com, und der Link führt zu Ihrem eigenen Tenant (z. B. kestrel.sharepoint.com). Diese Domain ist gefälscht.',
 'heute 13:47',
 'BECKER Stefan hat "Rahmenvertrag-2026.pdf" mit Ihnen geteilt',
 'BECKER Stefan hat ein Dokument per OneDrive mit Ihnen geteilt. Jetzt ansehen...',
 E'<div class="ol-share-card"><div class="ol-share-head"><div class="ol-share-icon">⤴</div><h2 class="ol-share-heading">BECKER Stefan hat Sie eingeladen, eine Datei zu bearbeiten</h2><p class="ol-share-intro" style="color:#888;font-size:.85em">stefan.becker@kestrel-partner.com</p></div><div class="ol-share-body"><p class="ol-share-intro">Dies ist das Dokument, das BECKER Stefan mit Ihnen geteilt hat.</p><div class="ol-share-file"><span class="ol-share-file-ico">📄</span><span class="ol-share-file-name">Rahmenvertrag-2026.pdf</span></div><p class="ol-share-protection">🔒 Diese Einladung funktioniert nur für Sie und Personen mit bestehendem Zugriff.</p><div class="ol-share-actions">{{link:0}}</div></div></div>',
 '[{"label":"Dokument öffnen","real_url":"http://sharepoint-online-share.com/view?id=8a3f2","suspicious":true,"warning":"Dies ist keine Microsoft-Domain. Echte SharePoint- und OneDrive-Links führen zu Ihrem eigenen Tenant (z. B. kestrel.sharepoint.com) oder zu onedrive.live.com. \"sharepoint-online-share.com\" ist gefälscht. Außerdem nutzt Stefan @kestrel-partner.com statt @kestrel.de."}]'::jsonb,
 TRUE,
 '["Absenderdomain sharepoint-online-share.com — keine Microsoft- oder Kestrel-Domain","Der \"Freigebende\" Stefan Becker nutzt @kestrel-partner.com — nicht unser eigenes @kestrel.de","Unerwartetes Dokument ohne Kontext","Der Link führt zu einer separaten externen Domain, nicht zu kestrel.sharepoint.com"]'::jsonb,
 '[]'::jsonb,
 'Das ist Phishing, das einen SharePoint/OneDrive-Freigabelink nachahmt. Echte Freigabelinks führen zu Ihrem Microsoft 365-Tenant (z. B. kestrel.sharepoint.com) oder zu onedrive.live.com. Im Zweifel: Öffnen Sie SharePoint oder Teams selbst und prüfen Sie unter „Mit mir geteilt", ob das Dokument dort steht.',
 40),

-- 5. REAL — Kalender-Einladung Kollegin
('de', 'business',
 'Anna Weber',
 'a.weber@kestrel.de',
 'Eigene Domain @kestrel.de einer bekannten Kollegin — korrekt.',
 'heute 14:12',
 'Besprechung Donnerstag 14:00 — Quartalsplanung Q2',
 'Hallo Martina, kannst du am Donnerstag um 14:00 zur Quartalsplanung dazukommen?',
 E'Hallo Martina,\n\nkannst du am Donnerstag um 14:00 zur Quartalsplanung Q2 dazukommen? Wir besprechen:\n\n• Status der laufenden Projekte\n• Planung für Mai und Juni\n• Prioritäten fürs Team\n\nMaximal eine Stunde. Besprechungsraum Linde, oder per Teams, falls dir das lieber ist. Gib kurz Bescheid.\n\nDanke!\nAnna',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Absender @kestrel.de, die offizielle interne Domain","Bekannte Kollegin, mit der Sie normalerweise sprechen","Konkreter, plausibler Arbeitskontext","Kein Link, kein Anhang, keine Datenabfrage","Informeller, persönlicher Ton — passt zur internen Kommunikation"]'::jsonb,
 'Das ist eine normale Kalender-Einladung einer Kollegin. Außer inhaltlich antworten ist nichts zu tun. Gute Lektion: Eine persönlich adressierte, konkrete interne Nachricht ohne Links oder Anhänge ist meist ein sicheres Zeichen.',
 50);

-- ============ DE — BUSINESS (2/2) ============

INSERT INTO inbox_messages
  (locale, audience, sender_name, sender_address, sender_note, received_label, subject, preview, body, links, is_phishing, red_flags, green_flags, explanation, sort_order) VALUES

-- 6. PHISHING — Fake-Rechnung vom Lieferanten
('de', 'business',
 'Buchhaltung — Druckservice GmbH',
 'rechnungen@druckservice-de.com',
 'Unbekannter Lieferant auf einer separaten .com-Domain. Echte Lieferanten von Kestrel stehen in Ihrem Einkaufssystem.',
 'gestern 15:30',
 'Rechnung P-2026-0452 — Zahlungsfrist überschritten',
 'Sehr geehrte Damen und Herren, anbei die offene Rechnung für Druckerwartung. Bitte umgehend begleichen...',
 E'Sehr geehrte Damen und Herren,\n\nim Anhang finden Sie Rechnung P-2026-0452 für die vierteljährliche Druckerwartung (Q1) über 1.847,50 €.\n\nDie Zahlungsfrist von 14 Tagen ist überschritten. Bitte begleichen Sie die Rechnung umgehend, um Mahngebühren zu vermeiden. Die Zahlungsdaten finden Sie im Anhang.\n\nFür eine schnelle Zahlung: {{link:0}}\n\nMit freundlichen Grüßen,\nBuchhaltung — Druckservice GmbH',
 '[{"label":"Jetzt zahlen","real_url":"http://druckservice-de.com/pay/P-2026-0452","suspicious":true,"warning":"Unbekannte Zahlungsdomain. Bei Kestrel laufen Rechnungen über das Einkaufsportal — nicht über einen isolierten Link in einer E-Mail."}]'::jsonb,
 TRUE,
 '["Unbekannter Lieferant — nicht im Einkaufssystem","Zeitdruck: \"Frist überschritten\", \"umgehend begleichen\"","Separater Zahlungslink statt Einkaufsportal","Allgemeine Anrede \"Sehr geehrte Damen und Herren\" — sollte Ihren Namen nutzen","Der Betrag (1.847,50 €) ist gerade hoch genug, um Druck zu erzeugen, niedrig genug, um nicht aufzufallen"]'::jsonb,
 '[]'::jsonb,
 'Das ist Rechnungsbetrug. Unbekannte Lieferanten mit unerwarteten Rechnungen sollten zuerst über den Einkauf oder die Kreditorenbuchhaltung geprüft werden. Zahlen Sie nie über einen Link in einer E-Mail, sondern immer über Ihr eigenes Einkaufsportal oder nach einer erneuten Rechnungsprüfung.',
 60),

-- 7. REAL — SharePoint-Dokument von Kollegin geteilt
('de', 'business',
 'Microsoft SharePoint',
 'no-reply@sharepointonline.com',
 'Echte SharePoint-Benachrichtigungen kommen von @sharepointonline.com, und der Link führt zu Ihrem eigenen Tenant (kestrel.sharepoint.com).',
 'gestern 09:00',
 'WEBER Anna hat "Projektplan-Nord-v4.docx" mit Ihnen geteilt',
 'WEBER Anna hat ein Dokument mit Ihnen geteilt: Projektplan-Nord-v4.docx...',
 E'<div class="ol-share-card"><div class="ol-share-head"><div class="ol-share-icon">⤴</div><h2 class="ol-share-heading">WEBER Anna hat Sie eingeladen, eine Datei zu bearbeiten</h2></div><div class="ol-share-body"><p class="ol-share-msg">"Hallo Martina, das ist die Version für die Planung am Donnerstag. Gib Bescheid, falls etwas geändert werden muss."</p><p class="ol-share-intro">Dies ist das Dokument, das WEBER Anna mit Ihnen geteilt hat.</p><div class="ol-share-file"><span class="ol-share-file-ico">📄</span><span class="ol-share-file-name">Projektplan-Nord-v4.docx</span></div><p class="ol-share-protection">🔒 Diese Einladung funktioniert nur für Sie und Personen mit bestehendem Zugriff.</p><div class="ol-share-actions">{{link:0}}</div></div></div>',
 '[{"label":"Dokument öffnen","real_url":"https://kestrel.sharepoint.com/:w:/s/ProjektNord/EYnRNcTq0/Projektplan-Nord-v4.docx","suspicious":false,"warning":"Dies ist ein echter SharePoint-Link innerhalb unseres eigenen Tenants (kestrel.sharepoint.com). Noch sicherer: Öffnen Sie SharePoint oder Teams selbst und suchen Sie das Dokument unter „Mit mir geteilt\"."}]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Absender @sharepointonline.com ist die offizielle Microsoft-Benachrichtigungsdomain","Der Link führt zu kestrel.sharepoint.com — unser eigener Tenant","Interne Kollegin (Anna via @kestrel.de) ist bekannt","Persönliche Nachricht passt zu laufender Arbeit (Planung Donnerstag, Projekt Nord)","Kein Druck, keine Passwortabfrage"]'::jsonb,
 'Das ist ein echter SharePoint-Freigabelink von einer Kollegin. Gutes Muster: Benachrichtigung über @sharepointonline.com, Link zu Ihrem eigenen Tenant (kestrel.sharepoint.com), persönliche Nachricht dabei. Noch sicherere Gewohnheit: SharePoint oder Teams selbst öffnen und das Dokument unter „Mit mir geteilt" suchen.',
 70),

-- 8. PHISHING — Microsoft 365
('de', 'business',
 'Microsoft 365',
 'account-security@microsoft-365-secure.com',
 'Die echte Microsoft-Domain ist microsoft.com. "microsoft-365-secure.com" ist gefälscht.',
 'vor 2 Tagen 08:14',
 'Ihr Microsoft 365-Passwort läuft heute ab',
 'Ihr Passwort für Microsoft 365 läuft innerhalb von 24 Stunden ab. Behalten Sie Ihr aktuelles Passwort...',
 E'<div class="eml fam-tech" style="--brand:#0067b8;--cta:#0067b8"><div class="eml-top"><span class="eml-logo">Microsoft 365</span></div><div class="eml-body"><p>Microsoft 365 Kontosicherheit</p><p>Ihr Passwort für Microsoft 365 läuft innerhalb von 24 Stunden ab. Danach verlieren Sie den Zugriff auf E-Mail, OneDrive und Teams.</p><p>Klicken Sie unten, um Ihr aktuelles Passwort zu behalten und den Ablauf zu verhindern:</p><div class="eml-cta" style="--cta:#0067b8">{{link:0}}</div><p>Diese Aktion dauert weniger als eine Minute. Wenn Sie dies ignorieren, wird Ihr Konto vorübergehend gesperrt.</p><p>Microsoft 365 Security Team</p></div><div class="eml-foot"><p>Dies ist eine automatische Nachricht — bitte antworten Sie nicht darauf.</p><p>© 2026 Microsoft 365</p></div></div>',
 '[{"label":"Passwort behalten","real_url":"http://microsoft-365-secure.com/keep-password","suspicious":true,"warning":"Microsoft verwendet nie Domains mit Bindestrichen wie microsoft-365-secure.com. Das ist gefälscht. Microsoft fordert Sie auch nie dazu auf, ein Passwort per Link zu \"behalten\" oder zu \"bestätigen\"."}]'::jsonb,
 TRUE,
 '["Absender @microsoft-365-secure.com (nicht @microsoft.com)","Zeitdruck: \"innerhalb von 24 Stunden\", \"gesperrt\"","Unsinniges Konzept: \"Passwort behalten\" per Link gibt es nicht","Drohung mit Zugriffsverlust","Wenn Microsoft 365 ein Passwort erneuern will, passiert das beim Login — nicht über eine separate E-Mail"]'::jsonb,
 '[]'::jsonb,
 'Das ist eine der häufigsten Phishing-Varianten im Unternehmen. Microsoft kommuniziert Passwortänderungen nie so. Im Zweifel: Schließen Sie die E-Mail und gehen Sie selbst zu portal.office.com oder öffnen Sie Teams, um zu sehen, ob wirklich ein Problem vorliegt.',
 80),

-- 9. REAL — Kurze Frage einer Kollegin
('de', 'business',
 'Anna Weber',
 'a.weber@kestrel.de',
 'Eigene Domain @kestrel.de einer bekannten Kollegin — korrekt.',
 'vor 2 Tagen 14:45',
 'Kannst du kurz auf das Budget schauen?',
 'Hallo Martina, Markus hat gefragt, ob du kurz prüfen kannst, ob Zeile 14 im Budget stimmt...',
 E'Hallo Martina,\n\nMarkus hat gefragt, ob du kurz prüfen kannst, ob Zeile 14 im Budget des Projekts Nord stimmt. Seiner Meinung nach ist der Betrag falsch, aber ich bin nicht sicher, ob er die aktuelle Version angesehen hat.\n\nDas Budget liegt auf dem Team-Share unter /Projekte/Nord/2026/.\n\nKannst du ihm kurz Bescheid geben?\n\nDanke!\nAnna',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Absender @kestrel.de, bekannte Kollegin","Konkreter interner Kontext (Markus, Projekt Nord, Team-Share-Pfad)","Kein Link zu einer externen Domain","Keine Datenabfrage, kein Passwort, kein Geld","Informeller Ton passt zur normalen internen Kommunikation"]'::jsonb,
 'Das ist eine ganz normale Arbeitsfrage einer Kollegin. Außer nachsehen und antworten ist nichts zu tun. Merke: Ein persönlich adressierter, konkreter Arbeitskontext auf der internen Domain ist in der Regel ein gutes Zeichen.',
 10),

-- 10. PHISHING — Recruiter mit gefährlichem Anhang
('de', 'business',
 'Sophie Hoffmann — Premium Talent',
 'sophie.hoffmann@premium-talent-careers.info',
 '".info"-Domain und einzelne Recruiterin ohne nachvollziehbare Verbindung zu einer bekannten Agentur. Verdächtiges Muster.',
 'vor 3 Tagen 17:20',
 'Exklusive Chance bei internationalem Kunden — Profil ausgewählt',
 'Sehr geehrter Herr Müller, ich habe Ihr LinkedIn-Profil gesehen und habe eine exklusive Position...',
 E'Sehr geehrter Herr Müller,\n\nich habe Ihr Profil gesehen und habe eine exklusive Senior-Position bei einem internationalen Kunden, die meiner Meinung nach perfekt zu Ihrer Erfahrung passt. Gehaltsrahmen: 85.000 € — 105.000 € brutto.\n\nDie Rolle ist noch nicht öffentlich, und es eilt. Der Kunde möchte diese Woche eine Shortlist.\n\nIm Anhang finden Sie die Stellenbeschreibung und die Geheimhaltungsvereinbarung (NDA), die ich Sie bitte zu öffnen und zu unterzeichnen, bevor ich weitere Details teilen kann.\n\nMit freundlichen Grüßen,\nSophie Hoffmann\nPremium Talent — Executive Search',
 '[]'::jsonb,
 TRUE,
 '["Absenderin auf einer \".info\"-Domain ohne bekannte Agentur","Unerwartete Kontaktaufnahme mit Anhang","Der Dateiname endet auf .pdf.exe — das ist ein ausführbares Programm, getarnt als PDF","Zeitdruck: \"diese Woche Shortlist\"","Vertraulichkeit gefordert — soll Sie isolieren","Gehalt als Köder ohne überprüfbaren Kontext"]'::jsonb,
 '[]'::jsonb,
 'Das ist Phishing mit einem bösartigen Anhang. Dateien mit doppelten Endungen (.pdf.exe) sind ausführbare Programme, getarnt als Dokument. Öffnen Sie diese NIE. Eine seriöse Recruiterin mit einer seriösen Rolle schickt keine einzelnen ausführbaren Anhänge. Melden Sie das der IT oder löschen Sie die E-Mail.',
 100);


-- ============================================================
-- ZAKELIJKE GEANNOTEERDE VOORBEELDEN (audience = 'business')
-- Drie klassieke corporate phishing-scenario's per taal: CEO-fraude,
-- IT-helpdesk wachtwoordreset en een nep SharePoint-deellink. Worden
-- op de voorbeelden-pagina getoond wanneer de gebruiker "Zakelijk"
-- heeft gekozen. Sort-order 10/20/30 per locale.
-- ============================================================

INSERT INTO examples (locale, audience, channel, sender, subject, body, annotations, sort_order) VALUES

-- ======== NL (business) ========
('nl', 'business', 'email',
 'Peter van Dijk (CEO) <p.vandijk@kestrel-group.com>',
 'Kun je iets snel voor mij regelen?',
 E'Johanna,\n\nIk zit in een belangrijk overleg en kan niet bellen. Kun je voor mij 5 iTunes-cadeaubonnen van € 100 halen en mij de codes mailen? Ik regel de terugbetaling achteraf via de boekhouding. Bel niemand hierover — het is vertrouwelijk.\n\nDank,\nPeter',
 '[{"quote": "p.vandijk@kestrel-group.com", "note": "Kijk wat NA de @ staat: kestrel-group.com. Het echte Kestrel gebruikt @kestrel.nl. De naam van de directeur kan de oplichter vrij invullen."}, {"quote": "5 iTunes-cadeaubonnen van € 100", "note": "Cadeaubonnen als betaalmiddel is dé klassieke CEO-fraude. Echte bedrijven betalen nooit zo."}, {"quote": "Bel niemand hierover — het is vertrouwelijk", "note": "Bedoeld om u te isoleren van collega''s die de fraude zouden herkennen. Een echte leidinggevende vraagt dit nooit."}, {"quote": "Ik regel de terugbetaling achteraf", "note": "Past niet bij normale procedures. Uitgaven lopen via de boekhouding, niet via medewerkers."}]'::jsonb,
 10),

('nl', 'business', 'email',
 'IT Support <it-support@kestrel-helpdesk.com>',
 'Uw wachtwoord verloopt vandaag om 17:00 — verleng nu',
 E'Beste gebruiker,\n\nUw Kestrel-wachtwoord verloopt vandaag om 17:00. Als u het niet verlengt, verliest u toegang tot e-mail, SharePoint en Teams.\n\nGebruik de onderstaande link om uw wachtwoord te verlengen: http://kestrel-helpdesk.com/password-renew\n\nMet vriendelijke groet,\nIT Support Kestrel',
 '[{"quote": "it-support@kestrel-helpdesk.com", "note": "Niet @kestrel.nl maar @kestrel-helpdesk.com — een apart domein met streepje dat op het bedrijf lijkt. Uw echte IT-afdeling gebruikt het eigen Kestrel-domein."}, {"quote": "verloopt vandaag om 17:00", "note": "Kunstmatige tijdsdruk om u zonder nadenken te laten klikken. Echte wachtwoordverlopen kondigt u dagen van tevoren aan — en meestal verandert u ze zelf via portal.office.com."}, {"quote": "verliest u toegang tot e-mail, SharePoint en Teams", "note": "Dreigen met verlies van toegang is een standaard phishing-truc om angst op te wekken."}, {"quote": "http://kestrel-helpdesk.com/password-renew", "note": "Losse link naar een domein dat niet van Kestrel is. Echte IT laat u aanmelden via het interne portaal, nooit via een losse link."}]'::jsonb,
 20),

('nl', 'business', 'email',
 'Microsoft OneDrive <no-reply@sharepoint-online-share.com>',
 'BAKKER Anna heeft u uitgenodigd om "Raamovereenkomst-2026.pdf" te bewerken',
 E'BAKKER Anna heeft u uitgenodigd om een bestand te bewerken\n\nDit is het document dat BAKKER Anna met u heeft gedeeld.\n\n📎 Raamovereenkomst-2026.pdf\n\nDeze uitnodiging werkt alleen voor u en personen met bestaande toegang.\n\nhttp://sharepoint-online-share.com/view?id=8a3f2',
 '[{"quote":"no-reply@sharepoint-online-share.com","note":"Echte SharePoint-berichten komen van @sharepointonline.com. \"sharepoint-online-share.com\" is geen Microsoft-domein."}, {"quote":"BAKKER Anna heeft u uitgenodigd","note":"Kent u deze persoon? Uw collega''s gebruiken @kestrel.nl. Controleer het échte afzenderadres (hierboven) voordat u iets opent."}, {"quote":"Deze uitnodiging werkt alleen voor u en personen met bestaande toegang.","note":"Dit is Microsofts standaardtekst — phishers kopiëren hem één op één. De tekst zelf bewijst dus NIETS over de echtheid."}, {"quote":"http://sharepoint-online-share.com/view","note":"Echte SharePoint-links gaan naar uw eigen tenant (bijvoorbeeld kestrel.sharepoint.com) of naar onedrive.live.com — nooit naar een los extern domein."}]'::jsonb,
 30),

-- ======== nl-BE (business) ========
('nl-BE', 'business', 'email',
 'Luc Vermeulen (CEO) <l.vermeulen@kestrel-group.com>',
 'Kun je iets snel voor mij regelen?',
 E'Petra,\n\nIk zit in een belangrijk overleg en kan niet bellen. Kun je voor mij 5 iTunes-cadeaubonnen van € 100 halen en mij de codes mailen? Ik regel de terugbetaling achteraf via de boekhouding. Bel niemand hierover — het is vertrouwelijk.\n\nDank,\nLuc',
 '[{"quote": "l.vermeulen@kestrel-group.com", "note": "Kijk wat NA de @ staat: kestrel-group.com. Het echte Kestrel gebruikt @kestrel.be. De naam van de directeur kan de oplichter vrij invullen."}, {"quote": "5 iTunes-cadeaubonnen van € 100", "note": "Cadeaubonnen als betaalmiddel is dé klassieke CEO-fraude. Echte bedrijven betalen nooit zo."}, {"quote": "Bel niemand hierover — het is vertrouwelijk", "note": "Bedoeld om u te isoleren van collega''s die de fraude zouden herkennen."}, {"quote": "Ik regel de terugbetaling achteraf", "note": "Past niet bij normale procedures. Uitgaven lopen via de boekhouding."}]'::jsonb,
 10),

('nl-BE', 'business', 'email',
 'IT Support <it-support@kestrel-helpdesk.com>',
 'Uw paswoord verloopt vandaag om 17u — verleng nu',
 E'Beste gebruiker,\n\nUw Kestrel-paswoord verloopt vandaag om 17u. Als u het niet verlengt, verliest u toegang tot e-mail, SharePoint en Teams.\n\nGebruik de onderstaande link om uw paswoord te verlengen: http://kestrel-helpdesk.com/password-renew\n\nMet vriendelijke groeten,\nIT Support Kestrel',
 '[{"quote": "it-support@kestrel-helpdesk.com", "note": "Niet @kestrel.be maar @kestrel-helpdesk.com — een apart domein dat op het bedrijf lijkt."}, {"quote": "verloopt vandaag om 17u", "note": "Kunstmatige tijdsdruk. Echte paswoordverlopen kondigt u dagen van tevoren aan."}, {"quote": "verliest u toegang tot e-mail, SharePoint en Teams", "note": "Dreigen met verlies van toegang is een standaard phishing-truc."}, {"quote": "http://kestrel-helpdesk.com/password-renew", "note": "Losse link naar een domein dat niet van Kestrel is. Echte IT laat u aanmelden via het interne portaal."}]'::jsonb,
 20),

('nl-BE', 'business', 'email',
 'Microsoft OneDrive <no-reply@sharepoint-online-share.com>',
 'CLAES Bart heeft u uitgenodigd om "Raamovereenkomst-2026.pdf" te bewerken',
 E'CLAES Bart heeft u uitgenodigd om een bestand te bewerken\n\nDit is het document dat CLAES Bart met u heeft gedeeld.\n\n📎 Raamovereenkomst-2026.pdf\n\nDeze uitnodiging werkt alleen voor u en personen met bestaande toegang.\n\nhttp://sharepoint-online-share.com/view?id=8a3f2',
 '[{"quote":"no-reply@sharepoint-online-share.com","note":"Echte SharePoint-berichten komen van @sharepointonline.com. \"sharepoint-online-share.com\" is geen Microsoft-domein."}, {"quote":"CLAES Bart heeft u uitgenodigd","note":"Kent u deze persoon? Uw collega''s gebruiken @kestrel.be. Controleer het echte afzenderadres (hierboven) voordat u iets opent."}, {"quote":"Deze uitnodiging werkt alleen voor u en personen met bestaande toegang.","note":"Dit is Microsofts standaardtekst — phishers kopiëren hem één op één. De tekst zelf bewijst dus NIETS over de echtheid."}, {"quote":"http://sharepoint-online-share.com/view","note":"Echte SharePoint-links gaan naar uw eigen tenant (bijvoorbeeld kestrel.sharepoint.com) of naar onedrive.live.com — nooit naar een los extern domein."}]'::jsonb,
 30);

INSERT INTO examples (locale, audience, channel, sender, subject, body, annotations, sort_order) VALUES

-- ======== EN (business) ========
('en', 'business', 'email',
 'Thomas Richardson (CEO) <t.richardson@kestrel-group.com>',
 'Quick favour — are you in?',
 E'Jane,\n\nI''m in an important client meeting and can''t take calls. Could you pick up 5 Amazon gift cards at £100 each and email me the codes? I''ll have Finance reimburse you afterwards. Please keep this between us — it''s confidential until I can explain.\n\nThanks,\nThomas',
 '[{"quote": "t.richardson@kestrel-group.com", "note": "Look at what comes AFTER the @: kestrel-group.com. Real Kestrel uses @kestrel.co.uk. The CEO''s name is easy for a scammer to pick."}, {"quote": "5 Amazon gift cards at £100 each", "note": "Gift cards as a form of payment is textbook CEO fraud. Real companies never pay this way."}, {"quote": "Please keep this between us — it''s confidential", "note": "Designed to isolate you from colleagues who would spot the fraud. A real manager never asks for this."}, {"quote": "I''ll have Finance reimburse you afterwards", "note": "Bypasses the normal process. Expenses go through Finance, not via an employee buying gift cards."}]'::jsonb,
 10),

('en', 'business', 'email',
 'IT Support <it-support@kestrel-helpdesk.com>',
 'Your password expires today at 17:00 — renew now',
 E'Dear user,\n\nYour Kestrel password expires today at 17:00. If you don''t renew it, you''ll lose access to email, SharePoint and Teams.\n\nUse the link below to renew your password: http://kestrel-helpdesk.com/password-renew\n\nKind regards,\nIT Support Kestrel',
 '[{"quote": "it-support@kestrel-helpdesk.com", "note": "Not @kestrel.co.uk but @kestrel-helpdesk.com — a separate hyphenated domain that looks like the company. Your real IT team uses the company''s own domain."}, {"quote": "expires today at 17:00", "note": "Artificial time pressure to make you click without thinking. Real password expiries are announced days in advance — and you usually rotate them yourself via portal.office.com."}, {"quote": "you''ll lose access to email, SharePoint and Teams", "note": "Threatening loss of access is a standard phishing trick designed to create anxiety."}, {"quote": "http://kestrel-helpdesk.com/password-renew", "note": "Stand-alone link to a domain that is not Kestrel''s. Real IT has you sign in via the internal portal, never via a one-off link."}]'::jsonb,
 20),

('en', 'business', 'email',
 'Microsoft OneDrive <no-reply@sharepoint-online-share.com>',
 'BAKER Adam has invited you to edit "Framework-Agreement-2026.pdf"',
 E'BAKER Adam has invited you to edit a file\n\nThis is the document BAKER Adam shared with you.\n\n📎 Framework-Agreement-2026.pdf\n\nThis invitation only works for you and people with existing access.\n\nhttp://sharepoint-online-share.com/view?id=8a3f2',
 '[{"quote":"no-reply@sharepoint-online-share.com","note":"Real SharePoint notifications come from @sharepointonline.com. \"sharepoint-online-share.com\" is not a Microsoft domain."}, {"quote":"BAKER Adam has invited you","note":"Do you know this person? Your colleagues use @kestrel.co.uk. Check the real sender address (above) before opening anything."}, {"quote":"This invitation only works for you and people with existing access.","note":"This is Microsoft''s stock text — phishers copy it word for word. The sentence itself proves NOTHING about authenticity."}, {"quote":"http://sharepoint-online-share.com/view","note":"Real SharePoint links go to your own tenant (for example kestrel.sharepoint.com) or to onedrive.live.com — never to a stand-alone external domain."}]'::jsonb,
 30),

-- ======== FR (business) ========
('fr', 'business', 'email',
 'Jean-Philippe Moreau (CEO) <jp.moreau@kestrel-group.com>',
 'Tu peux me rendre un service rapidement ?',
 E'Pauline,\n\nJe suis en réunion importante avec un client et je ne peux pas être dérangé au téléphone. Peux-tu acheter 5 cartes cadeaux Amazon à 100 € chacune et m''envoyer les codes par retour de mail ? Je demanderai à la comptabilité de te rembourser. Merci de ne pas en parler autour de toi — c''est confidentiel.\n\nMerci,\nJean-Philippe',
 '[{"quote": "jp.moreau@kestrel-group.com", "note": "Regardez ce qui vient APRÈS le @ : kestrel-group.com. Le vrai Kestrel utilise @kestrel.fr. Le nom du dirigeant est facile à trouver pour un escroc."}, {"quote": "5 cartes cadeaux Amazon à 100 € chacune", "note": "Les cartes cadeaux comme moyen de paiement, c''est la fraude au dirigeant classique. Les vraies entreprises ne paient jamais ainsi."}, {"quote": "Merci de ne pas en parler autour de toi — c''est confidentiel", "note": "Vise à vous isoler des collègues qui reconnaîtraient la fraude. Un(e) vrai(e) manager ne demande jamais cela."}, {"quote": "Je demanderai à la comptabilité de te rembourser", "note": "Contourne la procédure normale. Les dépenses passent par la comptabilité, pas par un(e) salarié(e)."}]'::jsonb,
 10),

('fr', 'business', 'email',
 'Support Informatique <support-it@kestrel-helpdesk.com>',
 'Votre mot de passe expire aujourd''hui à 17h — renouvelez maintenant',
 E'Cher utilisateur,\n\nVotre mot de passe Kestrel expire aujourd''hui à 17h. Si vous ne le renouvelez pas, vous perdrez l''accès à la messagerie, SharePoint et Teams.\n\nUtilisez le lien ci-dessous pour renouveler votre mot de passe : http://kestrel-helpdesk.com/password-renew\n\nCordialement,\nSupport Informatique Kestrel',
 '[{"quote": "support-it@kestrel-helpdesk.com", "note": "Pas @kestrel.fr mais @kestrel-helpdesk.com — un domaine séparé avec tiret qui imite l''entreprise. Votre vrai service informatique utilise le domaine propre de l''entreprise."}, {"quote": "expire aujourd''hui à 17h", "note": "Pression temporelle artificielle pour vous faire cliquer sans réfléchir. Les vraies expirations sont annoncées des jours à l''avance."}, {"quote": "vous perdrez l''accès à la messagerie, SharePoint et Teams", "note": "La menace de perte d''accès est un classique pour créer de l''angoisse."}, {"quote": "http://kestrel-helpdesk.com/password-renew", "note": "Lien isolé vers un domaine qui n''est pas celui de Kestrel. Le vrai service informatique vous fait vous connecter via le portail interne."}]'::jsonb,
 20),

('fr', 'business', 'email',
 'Microsoft OneDrive <no-reply@sharepoint-online-share.com>',
 'MARTIN Julien vous a invité à modifier « Contrat-Cadre-2026.pdf »',
 E'MARTIN Julien vous a invité à modifier un fichier\n\nVoici le document que MARTIN Julien a partagé avec vous.\n\n📎 Contrat-Cadre-2026.pdf\n\nCette invitation ne fonctionne que pour vous et les personnes ayant déjà accès.\n\nhttp://sharepoint-online-share.com/view?id=8a3f2',
 '[{"quote":"no-reply@sharepoint-online-share.com","note":"Les vraies notifications SharePoint viennent de @sharepointonline.com. « sharepoint-online-share.com » n’est pas un domaine Microsoft."}, {"quote":"MARTIN Julien vous a invité","note":"Connaissez-vous cette personne ? Vos collègues utilisent @kestrel.fr. Vérifiez l’adresse réelle de l’expéditeur (ci-dessus) avant d’ouvrir quoi que ce soit."}, {"quote":"Cette invitation ne fonctionne que pour vous et les personnes ayant déjà accès.","note":"C’est le texte standard de Microsoft — les escrocs le copient mot pour mot. Cette phrase ne prouve donc RIEN sur l’authenticité."}, {"quote":"http://sharepoint-online-share.com/view","note":"Les vrais liens SharePoint pointent vers votre propre tenant (par exemple kestrel.sharepoint.com) ou vers onedrive.live.com — jamais vers un domaine externe isolé."}]'::jsonb,
 30);

INSERT INTO examples (locale, audience, channel, sender, subject, body, annotations, sort_order) VALUES

-- ======== fr-BE (business) ========
('fr-BE', 'business', 'email',
 'Philippe Vermeulen (CEO) <p.vermeulen@kestrel-group.com>',
 'Tu peux me rendre un service rapidement ?',
 E'Pauline,\n\nJe suis en réunion importante avec un client et je ne peux pas être dérangé au téléphone. Peux-tu acheter 5 cartes cadeaux Bol.com à 100 € chacune et m''envoyer les codes par retour de mail ? Je demanderai à la comptabilité de te rembourser. Merci de ne pas en parler autour de toi — c''est confidentiel.\n\nMerci,\nPhilippe',
 '[{"quote": "p.vermeulen@kestrel-group.com", "note": "Regardez ce qui vient APRÈS le @ : kestrel-group.com. Le vrai Kestrel utilise @kestrel.be."}, {"quote": "5 cartes cadeaux Bol.com à 100 € chacune", "note": "Les cartes cadeaux comme moyen de paiement, c''est la fraude au dirigeant classique."}, {"quote": "Merci de ne pas en parler autour de toi — c''est confidentiel", "note": "Vise à vous isoler des collègues qui reconnaîtraient la fraude."}, {"quote": "Je demanderai à la comptabilité de te rembourser", "note": "Contourne la procédure normale. Les dépenses passent par la comptabilité."}]'::jsonb,
 10),

('fr-BE', 'business', 'email',
 'Support Informatique <support-it@kestrel-helpdesk.com>',
 'Votre mot de passe expire aujourd''hui à 17h — renouvelez maintenant',
 E'Cher utilisateur,\n\nVotre mot de passe Kestrel expire aujourd''hui à 17h. Si vous ne le renouvelez pas, vous perdrez l''accès à la messagerie, SharePoint et Teams.\n\nUtilisez le lien ci-dessous pour renouveler votre mot de passe : http://kestrel-helpdesk.com/password-renew\n\nBien à vous,\nSupport Informatique Kestrel',
 '[{"quote": "support-it@kestrel-helpdesk.com", "note": "Pas @kestrel.be mais @kestrel-helpdesk.com — un domaine séparé qui imite l''entreprise."}, {"quote": "expire aujourd''hui à 17h", "note": "Pression temporelle artificielle. Les vraies expirations sont annoncées des jours à l''avance."}, {"quote": "vous perdrez l''accès à la messagerie, SharePoint et Teams", "note": "La menace de perte d''accès est un classique pour créer de l''angoisse."}, {"quote": "http://kestrel-helpdesk.com/password-renew", "note": "Lien isolé vers un domaine qui n''est pas celui de Kestrel. Le vrai service informatique passe par le portail interne."}]'::jsonb,
 20),

('fr-BE', 'business', 'email',
 'Microsoft OneDrive <no-reply@sharepoint-online-share.com>',
 'LECLERCQ Thomas vous a invité à modifier « Contrat-Cadre-2026.pdf »',
 E'LECLERCQ Thomas vous a invité à modifier un fichier\n\nVoici le document que LECLERCQ Thomas a partagé avec vous.\n\n📎 Contrat-Cadre-2026.pdf\n\nCette invitation ne fonctionne que pour vous et les personnes ayant déjà accès.\n\nhttp://sharepoint-online-share.com/view?id=8a3f2',
 '[{"quote":"no-reply@sharepoint-online-share.com","note":"Les vraies notifications SharePoint viennent de @sharepointonline.com. « sharepoint-online-share.com » n’est pas un domaine Microsoft."}, {"quote":"LECLERCQ Thomas vous a invité","note":"Connaissez-vous cette personne ? Vos collègues utilisent @kestrel.be. Vérifiez l’adresse réelle de l’expéditeur (ci-dessus) avant d’ouvrir quoi que ce soit."}, {"quote":"Cette invitation ne fonctionne que pour vous et les personnes ayant déjà accès.","note":"C’est le texte standard de Microsoft — les escrocs le copient mot pour mot. Cette phrase ne prouve donc RIEN sur l’authenticité."}, {"quote":"http://sharepoint-online-share.com/view","note":"Les vrais liens SharePoint pointent vers votre propre tenant (par exemple kestrel.sharepoint.com) ou vers onedrive.live.com — jamais vers un domaine externe isolé."}]'::jsonb,
 30),

-- ======== DE (business) ========
('de', 'business', 'email',
 'Thomas Schneider (CEO) <t.schneider@kestrel-group.com>',
 'Kannst du mir kurz einen Gefallen tun?',
 E'Martina,\n\nich bin in einer wichtigen Kundenbesprechung und kann nicht telefonieren. Kannst du für mich 5 Amazon-Gutscheine à 100 € kaufen und mir die Codes per Mail schicken? Die Buchhaltung erstattet dir das Geld danach. Bitte sprich mit niemandem darüber — das ist vertraulich, bis ich es erklären kann.\n\nDanke,\nThomas',
 '[{"quote": "t.schneider@kestrel-group.com", "note": "Achten Sie darauf, was NACH dem @ steht: kestrel-group.com. Das echte Kestrel nutzt @kestrel.de. Den Namen der Geschäftsleitung kann jeder Betrüger leicht finden."}, {"quote": "5 Amazon-Gutscheine à 100 €", "note": "Gutscheine als Zahlungsmittel ist typischer CEO-Betrug. Echte Unternehmen zahlen nie so."}, {"quote": "Bitte sprich mit niemandem darüber — das ist vertraulich", "note": "Soll Sie von Kolleginnen und Kollegen isolieren, die den Betrug erkennen würden. Eine echte Führungskraft bittet darum nie."}, {"quote": "Die Buchhaltung erstattet dir das Geld danach", "note": "Umgeht den normalen Prozess. Ausgaben laufen über die Buchhaltung, nicht über Mitarbeitende, die Gutscheine kaufen."}]'::jsonb,
 10),

('de', 'business', 'email',
 'IT Support <it-support@kestrel-helpdesk.com>',
 'Ihr Passwort läuft heute um 17:00 Uhr ab — jetzt verlängern',
 E'Sehr geehrte/r Nutzer/in,\n\nIhr Kestrel-Passwort läuft heute um 17:00 Uhr ab. Wenn Sie es nicht verlängern, verlieren Sie den Zugriff auf E-Mail, SharePoint und Teams.\n\nVerwenden Sie den untenstehenden Link, um Ihr Passwort zu verlängern: http://kestrel-helpdesk.com/password-renew\n\nMit freundlichen Grüßen,\nIT Support Kestrel',
 '[{"quote": "it-support@kestrel-helpdesk.com", "note": "Nicht @kestrel.de, sondern @kestrel-helpdesk.com — eine separate Domain mit Bindestrich, die wie das Unternehmen aussieht. Ihre echte IT nutzt die eigene Firmen-Domain."}, {"quote": "läuft heute um 17:00 Uhr ab", "note": "Künstlicher Zeitdruck, damit Sie ohne Nachdenken klicken. Echte Passwortabläufe werden Tage vorher angekündigt."}, {"quote": "verlieren Sie den Zugriff auf E-Mail, SharePoint und Teams", "note": "Die Drohung mit Zugriffsverlust ist ein Standardtrick, um Angst zu erzeugen."}, {"quote": "http://kestrel-helpdesk.com/password-renew", "note": "Einzelner Link zu einer Domain, die nicht zu Kestrel gehört. Die echte IT lässt Sie sich über das interne Portal anmelden, nie über einen losen Link."}]'::jsonb,
 20),

('de', 'business', 'email',
 'Microsoft OneDrive <no-reply@sharepoint-online-share.com>',
 'BECKER Stefan hat Sie eingeladen, "Rahmenvertrag-2026.pdf" zu bearbeiten',
 E'BECKER Stefan hat Sie eingeladen, eine Datei zu bearbeiten\n\nDies ist das Dokument, das BECKER Stefan mit Ihnen geteilt hat.\n\n📎 Rahmenvertrag-2026.pdf\n\nDiese Einladung funktioniert nur für Sie und Personen mit bestehendem Zugriff.\n\nhttp://sharepoint-online-share.com/view?id=8a3f2',
 '[{"quote":"no-reply@sharepoint-online-share.com","note":"Echte SharePoint-Benachrichtigungen kommen von @sharepointonline.com. \"sharepoint-online-share.com\" ist keine Microsoft-Domain."}, {"quote":"BECKER Stefan hat Sie eingeladen","note":"Kennen Sie diese Person? Ihre Kolleginnen und Kollegen nutzen @kestrel.de. Prüfen Sie die tatsächliche Absenderadresse (oben), bevor Sie etwas öffnen."}, {"quote":"Diese Einladung funktioniert nur für Sie und Personen mit bestehendem Zugriff.","note":"Das ist Microsofts Standardtext — Phisher kopieren ihn Wort für Wort. Der Satz an sich beweist also NICHTS über die Echtheit."}, {"quote":"http://sharepoint-online-share.com/view","note":"Echte SharePoint-Links führen zu Ihrem eigenen Tenant (z. B. kestrel.sharepoint.com) oder zu onedrive.live.com — nie zu einer separaten externen Domain."}]'::jsonb,
 30);


-- ============================================================
-- GEVORDERD (advanced difficulty) — subtiele phishing
-- Professionele opmaak, geen spelfouten, bijna-correcte domeinen.
-- Bedoeld voor gebruikers die de basis al beheersen.
-- ============================================================

INSERT INTO inbox_messages
  (locale, audience, sender_name, sender_address, sender_note, received_label,
   subject, preview, body, links, is_phishing, red_flags, green_flags,
   explanation, sort_order, difficulty) VALUES

('nl', 'both',
 'Rabobank',
 'noreply@rabobank-authenticatie.com',
 'Kijk goed na de @: rabobank-authenticatie.com. De echte Rabobank stuurt altijd vanuit @rabobank.nl.',
 'vandaag 09:15',
 'Uw Rabo Scanner verloopt over 3 dagen — verleng nu',
 'Beste klant, uw Rabo Scanner-koppeling verloopt binnenkort. Zonder actie kunt u...',
 E'<div class="eml fam-bank" style="--brand:#fd6400;--cta:#fd6400;--logo:#d55400"><div class="eml-top"><span class="eml-logo">Rabobank</span></div><div class="eml-body"><p>Beste klant,</p><p>Uw Rabo Scanner-koppeling verloopt over 3 dagen. Na het verlopen kunt u niet meer inloggen in Mobiel Bankieren of betalingen goedkeuren.</p><p>Verleng uw Rabo Scanner via {{link:0}}. Het duurt minder dan 2 minuten.</p><p>Met vriendelijke groet,<br>Rabobank Klantendienst</p></div><div class="eml-foot"><p>Dit is een automatisch verzonden bericht — antwoorden is niet mogelijk.</p><p>© 2026 Rabobank</p></div></div>',
 '[{"label":"Rabo Scanner verlengen","real_url":"http://rabobank-authenticatie.com/scanner/verleng","suspicious":true,"warning":"Deze link gaat naar rabobank-authenticatie.com, niet naar rabobank.nl. Typ altijd zelf rabobank.nl in uw browser of open de Rabo-app."}]'::jsonb,
 TRUE,
 '["Afzender eindigt op .com in plaats van @rabobank.nl","De link gaat naar rabobank-authenticatie.com, geen Rabobank-domein","Tijdsdruk: over 3 dagen maar de bank belt u altijd persoonlijk voor dit soort zaken","De echte Rabo-app toont uw koppelstatus — daar kunt u het zelf controleren"]'::jsonb,
 '[]'::jsonb,
 'Dit is phishing. Het domein rabobank-authenticatie.com lijkt op Rabobank, maar is het niet. De echte Rabobank gebruikt altijd @rabobank.nl. Open de Rabo-app rechtstreeks — nooit via een link in een e-mail.',
 100, 'advanced'),

('nl', 'both',
 'PostNL',
 'noreply@postnl-pakket.com',
 'Let op het domein: postnl-pakket.com. PostNL gebruikt @postnl.nl voor e-mails.',
 'gisteren 16:03',
 'Uw pakket wordt aangehouden — betaal €2,45 douanekosten',
 'Uw pakket met trackingnummer 3SPBR123456789 wordt aangehouden bij de douane...',
 E'<div class="eml fam-parcel" style="--brand:#f56900;--cta:#f56900"><div class="eml-hero"><span class="eml-logo">PostNL</span></div><div class="eml-body"><p>Geachte afzender,</p><p>Uw pakket met trackingnummer 3SPBR123456789 wordt aangehouden bij de douane. Om uw pakket vrij te geven, dient u een bedrag van €2,45 aan douanekosten te voldoen.</p><p>Betaal eenvoudig via {{link:0}}. Na betaling wordt uw pakket binnen 1-2 werkdagen bezorgd.</p><p>Met vriendelijke groet,<br>PostNL Bezorgservice</p></div><div class="eml-foot"><p>Dit is een automatisch verzonden bericht — antwoorden is niet mogelijk.</p><p>© 2026 PostNL</p></div></div>',
 '[{"label":"Douanekosten betalen","real_url":"http://postnl-pakket.com/betalen?id=3SPBR123456789","suspicious":true,"warning":"Deze link gaat naar postnl-pakket.com, niet naar postnl.nl. Het is een namaakwebsite om uw betaalgegevens te stelen."}]'::jsonb,
 TRUE,
 '["Domein postnl-pakket.com is niet van PostNL — het echte adres is @postnl.nl","Kleine betaling om u snel te laten klikken zonder veel nadenken","Bij echte douanekosten ontvangt u een fysieke brief, geen e-mail met betaallink","Controleer trackingnummers altijd zelf op postnl.nl"]'::jsonb,
 '[]'::jsonb,
 'Dit is phishing. De domeinnaam postnl-pakket.com lijkt op PostNL maar is het niet. Echte PostNL-e-mails komen van @postnl.nl. Bij werkelijke douanekosten ontvangt u een brief van de Douane zelf, nooit een e-mail met een betaallink.',
 110, 'advanced'),

('nl', 'both',
 'Belastingdienst',
 'mijn@belasting-terugave.nl',
 'Domein belasting-terugave.nl is niet van de overheid. De Belastingdienst gebruikt belastingdienst.nl.',
 'gisteren 11:47',
 'Uw belastingteruggave van €387,00 staat klaar',
 'Geachte belastingplichtige, wij hebben uw aangifte verwerkt en een teruggave...',
 E'<div class="eml fam-gov" style="--brand:#154273;--cta:#154273"><div class="eml-top"><span class="eml-logo">Belastingdienst</span></div><div class="eml-body"><p>Geachte belastingplichtige,</p><p>Wij hebben uw aangifte inkomstenbelasting verwerkt en vastgesteld dat u recht heeft op een teruggave van €387,00.</p><p>Om de teruggave te ontvangen, bevestig uw rekeningnummer via {{link:0}}. Zonder bevestiging kunnen wij het bedrag niet uitbetalen.</p><p>Met vriendelijke groet,<br>Belastingdienst Nederland</p></div><div class="eml-foot"><p>Dit is een automatisch verzonden bericht — antwoorden is niet mogelijk.</p><p>© 2026 Belastingdienst</p></div></div>',
 '[{"label":"Rekeningnummer bevestigen","real_url":"http://belasting-terugave.nl/bevestig","suspicious":true,"warning":"Dit is geen officieel overheidsdomein. De echte Belastingdienst bereikt u via belastingdienst.nl of MijnOverheid. Vul nooit uw bankgegevens in via een link in een e-mail."}]'::jsonb,
 TRUE,
 '["Domein belasting-terugave.nl is geen overheidsdomein — let op de koppeltekens en het ontbrekende woord dienst","De Belastingdienst kent uw rekeningnummer al uit eerdere aangiften","Teruggave-berichten komen via MijnBelastingdienst of een brief, nooit met een betaallink","Controleer altijd via mijn.belastingdienst.nl of er werkelijk een teruggave is"]'::jsonb,
 '[]'::jsonb,
 'Dit is phishing. De Belastingdienst stuurt geen e-mails met een link om uw rekeningnummer te bevestigen — zij kennen dit al. Controleer teruggaven altijd via mijn.belastingdienst.nl, nooit via een link in een e-mail.',
 120, 'advanced'),

('nl', 'both',
 'ABN AMRO',
 'noreply@abnamro.nl',
 'Het adres eindigt op @abnamro.nl — het officiële domein van de bank.',
 'gisteren 07:30',
 'Uw maandoverzicht van mei 2026 staat klaar',
 'Beste mevrouw Janssen, uw maandoverzicht van april is beschikbaar in...',
 E'<div class="eml fam-bank" style="--brand:#009286;--cta:#009286;--logo:#008c81"><div class="eml-top"><span class="eml-logo">ABN AMRO</span></div><div class="eml-body"><p>Beste mevrouw Janssen,</p><p>Uw maandoverzicht van mei 2026 is beschikbaar in Mijn ABN AMRO en in de ABN AMRO-app.</p><p>U vindt het overzicht onder Documenten → Rekeningafschriften.</p><p>Heeft u vragen? Bel ons op 0900-0024 (lokaal tarief).</p><p>Met vriendelijke groet,<br>ABN AMRO Bank</p></div><div class="eml-foot"><p>Dit is een automatisch verzonden bericht — antwoorden is niet mogelijk.</p><p>© 2026 ABN AMRO</p></div></div>',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Afzender @abnamro.nl is het officiële domein van de bank","Geen link in het bericht — de bank vraagt u zelf de app te openen","Persoonlijke aanhef met uw eigen naam","Geen vraag om wachtwoord, pincode of andere gegevens","Verwijst naar het officiële telefoonnummer van de bank"]'::jsonb,
 'Dit is een echt bericht. Let op hoe de bank nooit vraagt om op een link te klikken — ze verwijzen u naar de app of het officiële telefoonnummer. De afzender eindigt correct op @abnamro.nl.',
 130, 'advanced'),

('nl', 'both',
 'LinkedIn',
 'messages-noreply@linkedin.com',
 'Het adres eindigt op @linkedin.com — het officiële domein van LinkedIn.',
 'vandaag 08:52',
 'Jan de Vries wil graag met u connecten op LinkedIn',
 'Jan de Vries (Senior Accountmanager bij Philips) wil graag met u connecten...',
 E'<div class="eml fam-tech" style="--brand:#0a66c2;--cta:#0a66c2"><div class="eml-top"><span class="eml-logo">LinkedIn</span></div><div class="eml-body"><p>Jan de Vries wil graag met u connecten op LinkedIn.</p><p>Jan de Vries<br>Senior Accountmanager bij Philips<br>32 connecties</p><p>U kunt deze uitnodiging bekijken en accepteren of negeren in uw LinkedIn-profiel. Log daarvoor zelf in op linkedin.com.</p><p>U ontvangt dit bericht omdat u e-mailberichten van LinkedIn heeft ingeschakeld.</p></div><div class="eml-foot"><p>Dit is een automatisch verzonden bericht — antwoorden is niet mogelijk.</p><p>© 2026 LinkedIn</p></div></div>',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Afzender @linkedin.com is het officiële domein","Geen dringende vraag of betaalverzoek","Bericht bevat geen links die u ergens anders naartoe sturen","LinkedIn raadt aan zelf in te loggen op linkedin.com, niet via een link"]'::jsonb,
 'Dit is een echt LinkedIn-bericht. Tip: ook al is dit echt, het is nog veiliger om zelf naar linkedin.com te gaan dan op een link in de e-mail te klikken — zo weet u altijd zeker dat u op de echte site bent.',
 140, 'advanced'),

('en', 'both',
 'HM Revenue & Customs',
 'refunds@hmrc-gov-refund.com',
 'Note the domain: hmrc-gov-refund.com. Real HMRC emails come from @hmrc.gov.uk.',
 'yesterday 14:22',
 'Your tax refund of £312.00 is ready to process',
 'Dear taxpayer, we have calculated that you are entitled to a tax refund of...',
 E'<div class="eml fam-gov" style="--brand:#008476;--cta:#008476"><div class="eml-top"><span class="eml-logo">HM Revenue &amp; Customs</span></div><div class="eml-body"><p>Dear taxpayer,</p><p>Following a review of your tax records, we have calculated that you are entitled to a refund of £312.00 for the 2025-2026 tax year.</p><p>To receive your refund, please verify your bank details via {{link:0}}. Refunds not claimed within 14 days will be returned to HMRC.</p><p>Yours faithfully,<br>HM Revenue &amp; Customs</p></div><div class="eml-foot"><p>This is an automated message — please do not reply.</p><p>© 2026 HM Revenue &amp; Customs</p></div></div>',
 '[{"label":"Claim your refund","real_url":"http://hmrc-gov-refund.com/claim","suspicious":true,"warning":"This link goes to hmrc-gov-refund.com, not hmrc.gov.uk. Real HMRC communications always use hmrc.gov.uk — never a .com address."}]'::jsonb,
 TRUE,
 '["Domain hmrc-gov-refund.com ends in .com, not .gov.uk — UK government sites always use .gov.uk","HMRC already holds your bank details from previous returns","Artificial deadline (14 days) creates pressure to act without thinking","Real HMRC refunds are processed automatically — they never ask you to verify bank details by email"]'::jsonb,
 '[]'::jsonb,
 'This is phishing. HMRC never asks you to verify bank details via email. Any refund is paid automatically to the account on record. Check your tax position directly at gov.uk/personal-tax-account.',
 100, 'advanced'),

('en', 'both',
 'Royal Mail',
 'delivery@royalmail-parcel.co.uk',
 'Note: royalmail-parcel.co.uk is not Royal Mail. The official domain is royalmail.com.',
 'today 10:41',
 'Your parcel is being held — customs fee of £1.99 required',
 'We attempted to deliver your parcel but it requires a customs payment before...',
 E'<div class="eml fam-parcel" style="--brand:#de1212;--cta:#de1212"><div class="eml-hero"><span class="eml-logo">Royal Mail</span></div><div class="eml-body"><p>We attempted to deliver your parcel (reference RL123456789GB) but it is currently being held at our depot.</p><p>A customs fee of £1.99 is required before we can release your parcel for delivery. Once paid, your parcel will be delivered within 2 working days.</p><p>Pay the fee via {{link:0}}.</p><p>Royal Mail Customer Services</p></div><div class="eml-foot"><p>This is an automated message — please do not reply.</p><p>© 2026 Royal Mail</p></div></div>',
 '[{"label":"Pay customs fee","real_url":"http://royalmail-parcel.co.uk/pay?ref=RL123456789GB","suspicious":true,"warning":"This link goes to royalmail-parcel.co.uk, not royalmail.com. This is a fake site designed to steal your payment details."}]'::jsonb,
 TRUE,
 '["Domain royalmail-parcel.co.uk is not Royal Mail — the official site is royalmail.com","Small fee amount (£1.99) designed to make you pay without thinking","Real customs charges come as physical cards through your letterbox, not email payment links","Check any Royal Mail reference on royalmail.com directly"]'::jsonb,
 '[]'::jsonb,
 'This is phishing. Royal Mail never requests customs payments via email. Genuine customs charges are delivered as physical notices. Check any parcel on royalmail.com directly.',
 110, 'advanced'),

('en', 'both',
 'Microsoft account team',
 'account-security@microsoft-accounts.net',
 'The real Microsoft uses @microsoft.com or @accountprotection.microsoft.com — never microsoft-accounts.net.',
 'today 07:18',
 'Unusual sign-in activity detected on your Microsoft account',
 'We detected an unusual sign-in to your Microsoft account from an unrecognised device...',
 E'<div class="eml fam-tech" style="--brand:#0067b8;--cta:#0067b8"><div class="eml-top"><span class="eml-logo">Microsoft account</span></div><div class="eml-body"><p>We detected an unusual sign-in to your Microsoft account.</p><p>Date: Today at 06:47<br>Location: Frankfurt, Germany<br>Device: Windows PC (unrecognised)</p><p>If this was you, you can ignore this message. If this was not you, your account may be at risk.</p><p>Secure your account immediately via {{link:0}}.</p><p>The Microsoft account team</p></div><div class="eml-foot"><p>This is an automated message — please do not reply.</p><p>© 2026 Microsoft account</p></div></div>',
 '[{"label":"Review recent activity","real_url":"http://microsoft-accounts.net/security","suspicious":true,"warning":"This link goes to microsoft-accounts.net, not microsoft.com. Real Microsoft security alerts link to account.microsoft.com only."}]'::jsonb,
 TRUE,
 '["Domain microsoft-accounts.net is not Microsoft — the real domain is microsoft.com","Mentions a foreign location to trigger concern and make you act fast","Real Microsoft alerts link to account.microsoft.com, not third-party domains","Go directly to account.microsoft.com to check your sign-in history without clicking any link"]'::jsonb,
 '[]'::jsonb,
 'This is phishing. Microsoft security emails always come from @microsoft.com domains and link to account.microsoft.com. Check your account directly at account.microsoft.com — never via a link in a suspicious email.',
 120, 'advanced'),

('en', 'both',
 'GitHub',
 'noreply@github.com',
 'The address ends in @github.com — GitHub official domain.',
 'yesterday 22:05',
 'A new public key was added to your account',
 'A new SSH key was added to your GitHub account. If you did not add this key...',
 E'<div class="eml fam-tech" style="--brand:#24292f;--cta:#24292f"><div class="eml-top"><span class="eml-logo">GitHub</span></div><div class="eml-body"><p>A new public key was added to your GitHub account.</p><p>Key fingerprint: SHA256:AbCdEf1234...<br>Added: yesterday at 21:58</p><p>If you added this key, no action is needed.</p><p>If you did not add this key, visit your account security settings to remove it and consider changing your password.</p><p>The GitHub Team</p></div><div class="eml-foot"><p>This is an automated message — please do not reply.</p><p>© 2026 GitHub</p></div></div>',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Sender is @github.com — GitHub official domain","No link asking you to click — you are told to go to your settings yourself","Informational tone: tells you what happened without demanding immediate action","Explains what to do if it was not you, without creating panic"]'::jsonb,
 'This is a genuine GitHub notification. Notice it contains no links — it tells you to visit your settings yourself. This is how legitimate security notifications should work.',
 130, 'advanced'),

('en', 'both',
 'Spotify',
 'no-reply@spotify.com',
 'The address ends in @spotify.com — Spotify official domain.',
 '3 days ago',
 'Your Spotify Premium subscription has been renewed',
 'Hi there, your monthly Spotify Premium subscription has been renewed...',
 E'<div class="eml fam-retail" style="--brand:#1db954;--cta:#1db954"><div class="eml-hero"><span class="eml-logo" style="font-weight:800">Spotify</span></div><div class="eml-body"><p>Hi there,</p><p>Your monthly Spotify Premium subscription has been renewed.</p><p>Amount charged: £10.99<br>Date: 3 days ago<br>Payment method: Visa ending in 4242</p><p>You can manage your subscription and view past invoices in your account settings at spotify.com/account.</p><p>Thanks for being a Premium member.<br>The Spotify Team</p></div><div class="eml-foot"><p>This is an automated message — please do not reply.</p><p>© 2026 Spotify</p></div></div>',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Sender @spotify.com is Spotify official domain","Shows the exact amount and last 4 digits of card — matches what you would expect","No link demanding immediate action","Refers you to account settings at spotify.com, not a separate domain"]'::jsonb,
 'This is a genuine Spotify renewal receipt. The email shows exactly what was charged and tells you to manage your account at spotify.com. No suspicious links or urgent demands.',
 140, 'advanced'),

('fr', 'both',
 'Crédit Agricole',
 'securite@credit-agricole-services.com',
 'Domaine credit-agricole-services.com : ce n’est pas Crédit Agricole. Le vrai domaine est credit-agricole.fr.',
 'hier 15:33',
 'Votre accès à votre espace client est temporairement suspendu',
 'Cher client, nous avons détecté une activité inhabituelle sur votre compte…',
 E'<div class="eml fam-bank" style="--brand:#006a4e;--cta:#006a4e"><div class="eml-top"><span class="eml-logo">CRÉDIT AGRICOLE</span></div><div class="eml-body"><p>Cher client,</p><p>Nous avons détecté une activité inhabituelle sur votre compte Crédit Agricole. Par mesure de sécurité, votre accès a été temporairement suspendu.</p><p>Pour rétablir votre accès, veuillez vérifier votre identité via {{link:0}}. Sans action de votre part sous 48 heures, votre compte sera définitivement bloqué.</p><p>Cordialement,<br>Le Service Sécurité Crédit Agricole</p></div><div class="eml-foot"><p>Ceci est un message automatique — merci de ne pas y répondre.</p><p>© 2026 CRÉDIT AGRICOLE</p></div></div>',
 '[{"label":"Vérifier mon identité","real_url":"http://credit-agricole-services.com/verifier","suspicious":true,"warning":"Ce lien mène vers credit-agricole-services.com, pas vers credit-agricole.fr. C’est un faux site qui imite votre banque."}]'::jsonb,
 TRUE,
 '["Le domaine credit-agricole-services.com n’est pas celui de la banque — le vrai est credit-agricole.fr","La menace de blocage définitif en 48 h crée une pression artificielle","Le Crédit Agricole ne demande jamais de vérifier votre identité par e-mail","Connectez-vous directement sur credit-agricole.fr ou appelez le numéro au dos de votre carte"]'::jsonb,
 '[]'::jsonb,
 'Il s’agit de phishing. Le Crédit Agricole ne suspend pas les comptes par e-mail et ne vous demande pas de vérifier votre identité via un lien. Connectez-vous directement sur credit-agricole.fr ou appelez le numéro inscrit au dos de votre carte.',
 100, 'advanced'),

('fr', 'both',
 'La Poste',
 'suivi@laposte-livraison.fr',
 'Domaine laposte-livraison.fr : ce n’est pas La Poste. L’adresse officielle est @laposte.fr.',
 'aujourd’hui 11:08',
 'Votre colis est retenu — réglez les frais de douane (2,99 €)',
 'Votre colis (référence LP123456789FR) est actuellement retenu en douane…',
 E'<div class="eml fam-parcel" style="--brand:#ffd100;--cta:#ffd100;--cta-ink:#003366"><div class="eml-hero"><span class="eml-logo">LA POSTE</span></div><div class="eml-body"><p>Votre colis (référence LP123456789FR) est actuellement retenu en douane.</p><p>Pour procéder à la livraison, des frais de douane d’un montant de 2,99 € doivent être réglés.</p><p>Effectuez le paiement via {{link:0}}. Après validation, votre colis sera livré sous 2 jours ouvrables.</p><p>La Poste — Service Clients</p></div><div class="eml-foot"><p>Ceci est un message automatique — merci de ne pas y répondre.</p><p>© 2026 LA POSTE</p></div></div>',
 '[{"label":"Payer les frais","real_url":"http://laposte-livraison.fr/payer?ref=LP123456789FR","suspicious":true,"warning":"Ce lien mène vers laposte-livraison.fr, pas vers laposte.fr. C’est un faux site conçu pour voler vos données bancaires."}]'::jsonb,
 TRUE,
 '["Le domaine laposte-livraison.fr n’est pas celui de La Poste — le vrai est @laposte.fr","Un petit montant (2,99 €) pour que vous payiez sans réfléchir","Les vrais frais de douane sont notifiés par un avis papier dans votre boîte aux lettres, jamais par un lien e-mail","Vérifiez tout colis directement sur laposte.fr"]'::jsonb,
 '[]'::jsonb,
 'Il s’agit de phishing. La Poste ne demande pas le règlement de frais de douane par e-mail avec un lien de paiement. Les vrais frais de douane sont notifiés par courrier physique. Vérifiez votre colis directement sur laposte.fr.',
 110, 'advanced'),

('fr', 'both',
 'Direction Générale des Finances Publiques',
 'remboursement@impots-gouv.net',
 'impots-gouv.net n’est pas un domaine officiel. Le vrai service utilise impots.gouv.fr.',
 'hier 09:55',
 'Votre remboursement d’impôts de 274 € est disponible',
 'Madame, Monsieur, suite au traitement de votre déclaration, vous bénéficiez…',
 E'<div class="eml fam-gov" style="--brand:#000091;--cta:#000091"><div class="eml-top"><span class="eml-logo">impots.gouv.fr</span></div><div class="eml-body"><p>Madame, Monsieur,</p><p>Suite au traitement de votre déclaration de revenus, vous bénéficiez d’un remboursement de 274,00 €.</p><p>Afin de procéder au virement, veuillez confirmer votre relevé d’identité bancaire (RIB) via {{link:0}}. Passé un délai de 15 jours, le remboursement sera annulé.</p><p>Cordialement,<br>Direction Générale des Finances Publiques</p></div><div class="eml-foot"><p>Ceci est un message automatique — merci de ne pas y répondre.</p><p>© 2026 impots.gouv.fr</p></div></div>',
 '[{"label":"Confirmer mon RIB","real_url":"http://impots-gouv.net/confirmer-rib","suspicious":true,"warning":"Ce lien mène vers impots-gouv.net — pas impots.gouv.fr. Les sites officiels français utilisent toujours le domaine .gouv.fr."}]'::jsonb,
 TRUE,
 '["impots-gouv.net n’est pas un site gouvernemental — les sites officiels français utilisent .gouv.fr","La DGFiP connaît déjà votre RIB et rembourse automatiquement — elle ne vous le demande jamais par e-mail","L’échéance de 15 jours crée une pression artificielle","Vérifiez votre situation fiscale directement sur impots.gouv.fr"]'::jsonb,
 '[]'::jsonb,
 'Il s’agit de phishing. Les remboursements d’impôts sont effectués automatiquement sur le compte connu du fisc. La DGFiP ne demande jamais de confirmer un RIB par e-mail. Vérifiez toujours sur impots.gouv.fr.',
 120, 'advanced'),

('fr', 'both',
 'Doctolib',
 'notification@doctolib.fr',
 'L’adresse se termine par @doctolib.fr — le domaine officiel de la plateforme.',
 'aujourd’hui 08:00',
 'Rappel : votre rendez-vous demain à 10h30 — Dr Martin',
 'Bonjour, voici un rappel pour votre rendez-vous de demain avec le Dr Martin…',
 E'<div class="eml fam-tech" style="--brand:#107aca;--cta:#107aca"><div class="eml-top"><span class="eml-logo">Doctolib</span></div><div class="eml-body"><p>Bonjour,</p><p>Voici un rappel pour votre rendez-vous de demain :</p><p>• Praticien : Dr Sophie Martin — Médecin généraliste<br>• Date : demain à 10h30<br>• Adresse : 12 rue des Lilas, 75011 Paris</p><p>Pour annuler ou reporter, connectez-vous à votre espace Doctolib sur doctolib.fr.</p><p>Doctolib</p></div><div class="eml-foot"><p>Ceci est un message automatique — merci de ne pas y répondre.</p><p>© 2026 Doctolib</p></div></div>',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["L’expéditeur @doctolib.fr est le domaine officiel","Pas de lien à cliquer — vous êtes renvoyé vers doctolib.fr pour gérer le rendez-vous","Informations concrètes et attendues (praticien, date, adresse)","Aucune demande de paiement ni d’informations personnelles"]'::jsonb,
 'Il s’agit d’un vrai rappel Doctolib. Notez qu’il ne contient aucun lien de paiement ou demande d’informations sensibles — seulement les détails du rendez-vous et une invitation à gérer cela sur doctolib.fr.',
 130, 'advanced'),

('fr', 'both',
 'Amazon',
 'shipment-tracking@amazon.fr',
 'L’adresse se termine par @amazon.fr — le domaine officiel d’Amazon France.',
 'avant-hier 17:45',
 'Votre commande a été expédiée — livraison prévue vendredi',
 'Bonjour, bonne nouvelle : votre commande est en route. Voici les détails…',
 E'<div class="eml fam-retail" style="--brand:#232f3e;--cta:#232f3e"><div class="eml-hero"><span class="eml-logo" style="text-transform:lowercase;font-weight:800">amazon</span></div><div class="eml-body"><p>Bonjour,</p><p>Bonne nouvelle : votre commande est en route !</p><p>📦 Commande n° 406-1234567-8901234<br>Livraison estimée : vendredi entre 14h et 18h<br>Transporteur : Amazon Logistics</p><p>Vous pouvez suivre votre colis dans la rubrique « Mes commandes » de votre compte Amazon sur amazon.fr.</p><p>Merci de votre confiance.<br>Amazon</p></div><div class="eml-foot"><p>Ceci est un message automatique — merci de ne pas y répondre.</p><p>© 2026 amazon</p></div></div>',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["L’expéditeur @amazon.fr est le domaine officiel d’Amazon France","Numéro de commande concret — vérifiable dans votre compte","Pas de demande de paiement ou d’informations bancaires","Vous êtes renvoyé vers amazon.fr pour le suivi, pas vers un domaine externe"]'::jsonb,
 'Il s’agit d’un vrai e-mail d’Amazon. Il contient un numéro de commande concret et vous renvoie vers amazon.fr pour le suivi. Aucune demande de paiement ni d’informations personnelles.',
 140, 'advanced'),

('de', 'both',
 'Sparkasse',
 'sicherheit@sparkasse-online.de',
 'Achtung: sparkasse-online.de ist nicht die echte Sparkasse. Das offizielle Domain ist sparkasse.de.',
 'gestern 16:21',
 'Wichtige Sicherheitsprüfung Ihres Kontos erforderlich',
 'Sehr geehrte/r Kundin/Kunde, im Rahmen unserer Sicherheitsmaßnahmen…',
 E'<div class="eml fam-bank" style="--brand:#ff0000;--cta:#ff0000;--logo:#fa0000"><div class="eml-top"><span class="eml-logo">Sparkasse</span></div><div class="eml-body"><p>Sehr geehrte/r Kundin/Kunde,</p><p>im Rahmen unserer Sicherheitsmaßnahmen bitten wir Sie, Ihre Online-Banking-Zugangsdaten einmalig zu bestätigen. Ohne diese Bestätigung wird Ihr Konto in 48 Stunden eingeschränkt.</p><p>Bestätigen Sie Ihre Daten über {{link:0}}.</p><p>Mit freundlichen Grüßen,<br>Ihr Sparkassen-Sicherheitsteam</p></div><div class="eml-foot"><p>Dies ist eine automatische Nachricht — bitte antworten Sie nicht darauf.</p><p>© 2026 Sparkasse</p></div></div>',
 '[{"label":"Zugangsdaten bestätigen","real_url":"http://sparkasse-online.de/sicherheit/bestaetigen","suspicious":true,"warning":"Dieser Link führt zu sparkasse-online.de, nicht zu sparkasse.de. Das ist eine gefälschte Website."}]'::jsonb,
 TRUE,
 '["sparkasse-online.de ist nicht das offizielle Domain — das echte ist sparkasse.de","Drohung mit Kontosperrung nach 48 Stunden erzeugt künstlichen Druck","Keine Sparkasse bittet per E-Mail um Bestätigung von Zugangsdaten","Melden Sie sich immer direkt über sparkasse.de an, nie über einen E-Mail-Link"]'::jsonb,
 '[]'::jsonb,
 'Dies ist Phishing. Kein Kreditinstitut fordert Sie per E-Mail auf, Zugangsdaten zu bestätigen. Loggen Sie sich direkt über sparkasse.de ein oder rufen Sie die Nummer auf Ihrer Bankkarte an.',
 100, 'advanced'),

('de', 'both',
 'DHL Paket',
 'tracking@dhl-pakete.com',
 'dhl-pakete.com ist nicht DHL. Die offizielle E-Mail-Domain von DHL lautet @dhl.de.',
 'heute 09:37',
 'Ihr Paket wird zurückgehalten — Zollgebühr von 2,99 € erforderlich',
 'Ihr Paket (Sendungsnummer 1Z999AA10123456784) befindet sich derzeit im Zoll…',
 E'<div class="eml fam-parcel" style="--brand:#ffcc00;--cta:#ffcc00;--cta-ink:#d40511"><div class="eml-hero"><span class="eml-logo">DHL</span></div><div class="eml-body"><p>Ihr Paket (Sendungsnummer 1Z999AA10123456784) befindet sich derzeit beim Zoll und kann erst nach Zahlung einer Zollgebühr von 2,99 € zugestellt werden.</p><p>Bitte begleichen Sie die Gebühr über {{link:0}}. Nach erfolgreicher Zahlung wird Ihr Paket innerhalb von 1-2 Werktagen zugestellt.</p><p>Mit freundlichen Grüßen,<br>DHL Kundenservice</p></div><div class="eml-foot"><p>Dies ist eine automatische Nachricht — bitte antworten Sie nicht darauf.</p><p>© 2026 DHL</p></div></div>',
 '[{"label":"Zollgebühr bezahlen","real_url":"http://dhl-pakete.com/zahlen?id=1Z999AA10123456784","suspicious":true,"warning":"Dieser Link führt zu dhl-pakete.com, nicht zu dhl.de. Es handelt sich um eine gefälschte Website."}]'::jsonb,
 TRUE,
 '["dhl-pakete.com ist nicht die offizielle DHL-Domain — das echte ist @dhl.de","Kleiner Betrag (2,99 €) soll dazu verleiten, ohne Nachdenken zu zahlen","Echte Zollgebühren werden durch einen physischen Benachrichtigungszettel angekündigt, nicht per E-Mail","Prüfen Sie Sendungen immer direkt auf dhl.de"]'::jsonb,
 '[]'::jsonb,
 'Dies ist Phishing. DHL fordert keine Zollgebühren per E-Mail mit Zahlungslink. Echte Zollbenachrichtigungen kommen als Papierzettel. Verfolgen Sie Sendungen direkt auf dhl.de.',
 110, 'advanced'),

('de', 'both',
 'Bundeszentralamt für Steuern',
 'erstattung@steuer-rueckzahlung.de',
 'steuer-rueckzahlung.de ist keine Behörden-Website. Offizielle Finanzämter nutzen die Domain bzst.de oder Ihr zuständiges Finanzamt.',
 'gestern 10:12',
 'Ihre Steuererstattung von 412 € steht zur Auszahlung bereit',
 'Sehr geehrte/r Steuerpflichtige/r, nach Prüfung Ihrer Einkommenssteuererklärung…',
 E'<div class="eml fam-gov" style="--brand:#003064;--cta:#003064"><div class="eml-top"><span class="eml-logo">Bundeszentralamt für Steuern</span></div><div class="eml-body"><p>Sehr geehrte/r Steuerpflichtige/r,</p><p>nach Prüfung Ihrer Einkommensteuererklärung für das Steuerjahr 2025 steht Ihnen eine Steuererstattung von 412,00 € zu.</p><p>Zur Auszahlung bestätigen Sie bitte Ihre Bankverbindung über {{link:0}}. Ohne Bestätigung innerhalb von 14 Tagen kann der Betrag nicht ausgezahlt werden.</p><p>Mit freundlichen Grüßen,<br>Bundeszentralamt für Steuern</p></div><div class="eml-foot"><p>Dies ist eine automatische Nachricht — bitte antworten Sie nicht darauf.</p><p>© 2026 Bundeszentralamt für Steuern</p></div></div>',
 '[{"label":"Bankverbindung bestätigen","real_url":"http://steuer-rueckzahlung.de/bestaetigen","suspicious":true,"warning":"steuer-rueckzahlung.de ist keine offizielle Behörden-Website. Deutsche Behörden nutzen immer .de-Domains wie bzst.de oder finanzamt.de."}]'::jsonb,
 TRUE,
 '["steuer-rueckzahlung.de ist kein offizielles Behörden-Domain — Finanzämter nutzen finanzamt.de oder ihr jeweiliges Landes-Domain","Das Finanzamt kennt Ihre Bankverbindung bereits aus früheren Steuerbescheiden","Die 14-Tage-Frist erzeugt künstlichen Druck","Erstattungen werden automatisch ausgezahlt — das Finanzamt fragt nie per E-Mail nach einer Bankverbindung"]'::jsonb,
 '[]'::jsonb,
 'Dies ist Phishing. Steuererstattungen werden automatisch an die bekannte Bankverbindung ausgezahlt. Das Finanzamt bittet nie per E-Mail um Bestätigung der Bankverbindung. Prüfen Sie Bescheide über Ihr ELSTER-Konto auf elster.de.',
 120, 'advanced'),

('de', 'both',
 'Amazon.de',
 'shipment-tracking@amazon.de',
 'Die Adresse endet auf @amazon.de — die offizielle Domain von Amazon Deutschland.',
 'vorgestern 18:30',
 'Ihre Bestellung wurde versandt — Lieferung voraussichtlich Freitag',
 'Hallo, Ihre Bestellung ist auf dem Weg zu Ihnen. Hier sind die Details…',
 E'<div class="eml fam-retail" style="--brand:#232f3e;--cta:#232f3e"><div class="eml-hero"><span class="eml-logo" style="text-transform:lowercase;font-weight:800">amazon.de</span></div><div class="eml-body"><p>Hallo,</p><p>Ihre Bestellung ist auf dem Weg zu Ihnen!</p><p>📦 Bestellnummer: 302-1234567-8901234<br>Voraussichtliche Lieferung: Freitag zwischen 14 und 18 Uhr<br>Versanddienstleister: Amazon Logistics</p><p>Sie können Ihre Sendung im Bereich „Meine Bestellungen“ in Ihrem Amazon-Konto auf amazon.de verfolgen.</p><p>Vielen Dank für Ihren Einkauf.<br>Amazon</p></div><div class="eml-foot"><p>Dies ist eine automatische Nachricht — bitte antworten Sie nicht darauf.</p><p>© 2026 amazon.de</p></div></div>',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Absender @amazon.de ist die offizielle Domain von Amazon Deutschland","Konkrete Bestellnummer — in Ihrem Konto nachprüfbar","Keine Zahlungsaufforderung oder Anfrage nach persönlichen Daten","Verweist auf amazon.de für die Sendungsverfolgung, nicht auf eine externe Domain"]'::jsonb,
 'Dies ist eine echte Amazon-Versandverfolgung. Sie enthält eine nachprüfbare Bestellnummer und verweist auf amazon.de. Keine verdächtigen Links, keine Zahlungsaufforderung.',
 130, 'advanced'),

('de', 'both',
 'LinkedIn',
 'messages-noreply@linkedin.com',
 'Die Adresse endet auf @linkedin.com — die offizielle Domain von LinkedIn.',
 'heute 08:14',
 'Markus Weber möchte sich mit Ihnen auf LinkedIn vernetzen',
 'Markus Weber (Senior Berater bei Deloitte) möchte sich mit Ihnen vernetzen…',
 E'<div class="eml fam-tech" style="--brand:#0a66c2;--cta:#0a66c2"><div class="eml-top"><span class="eml-logo">LinkedIn</span></div><div class="eml-body"><p>Markus Weber möchte sich mit Ihnen auf LinkedIn vernetzen.</p><p>Markus Weber<br>Senior Berater bei Deloitte<br>148 Kontakte</p><p>Sie können die Einladung in Ihrem LinkedIn-Profil annehmen oder ablehnen. Melden Sie sich dafür direkt auf linkedin.com an.</p><p>Sie erhalten diese Nachricht, weil Sie E-Mail-Benachrichtigungen von LinkedIn aktiviert haben.</p></div><div class="eml-foot"><p>Dies ist eine automatische Nachricht — bitte antworten Sie nicht darauf.</p><p>© 2026 LinkedIn</p></div></div>',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Absender @linkedin.com ist die offizielle Domain","Keine dringende Aufforderung und keine Zahlungsanfrage","LinkedIn empfiehlt, sich direkt auf linkedin.com anzumelden, statt auf einen Link zu klicken","Keine externen Domains oder verdächtigen Links im Text"]'::jsonb,
 'Dies ist eine echte LinkedIn-Kontaktanfrage. Tipp: Auch wenn diese E-Mail echt ist, ist es noch sicherer, direkt auf linkedin.com zu gehen, statt auf einen Link in der E-Mail zu klicken.',
 140, 'advanced');

-- nl-BE en fr-BE: kopieën van nl/fr advanced-berichten met aangepaste locale.
INSERT INTO inbox_messages
  (locale, audience, sender_name, sender_address, sender_note, received_label,
   subject, preview, body, links, is_phishing, red_flags, green_flags,
   explanation, sort_order, difficulty)
SELECT 'nl-BE', audience, sender_name, sender_address, sender_note, received_label,
       subject, preview, body, links, is_phishing, red_flags, green_flags,
       explanation, sort_order, difficulty
FROM inbox_messages
WHERE locale = 'nl' AND difficulty = 'advanced';

INSERT INTO inbox_messages
  (locale, audience, sender_name, sender_address, sender_note, received_label,
   subject, preview, body, links, is_phishing, red_flags, green_flags,
   explanation, sort_order, difficulty)
SELECT 'fr-BE', audience, sender_name, sender_address, sender_note, received_label,
       subject, preview, body, links, is_phishing, red_flags, green_flags,
       explanation, sort_order, difficulty
FROM inbox_messages
WHERE locale = 'fr' AND difficulty = 'advanced';


-- Aanvullende advanced berichten om het totaal gelijk te maken aan normaal.
INSERT INTO inbox_messages
  (locale, audience, sender_name, sender_address, sender_note, received_label,
   subject, preview, body, links, is_phishing, red_flags, green_flags,
   explanation, sort_order, difficulty) VALUES

('nl', 'both',
 'bol.com',
 'service@bol-service.com',
 'bol-service.com is niet bol.com. Echte bol.com-mails komen van @bol.com.',
 'vandaag 13:22',
 'Uw bestelling #1234567890 is geannuleerd — actie vereist',
 'Uw bestelling is geannuleerd wegens een probleem met uw betaling...',
 E'<div class="eml fam-retail" style="--brand:#0000a4;--cta:#0000a4"><div class="eml-hero"><span class="eml-logo" style="text-transform:lowercase;font-weight:800">bol.com</span></div><div class="eml-body"><p>Beste klant,</p><p>Er was helaas een probleem met de betaling van uw bestelling #1234567890. Uw bestelling is daardoor geannuleerd.</p><p>Om uw bestelling opnieuw te plaatsen en uw betaalgegevens bij te werken, gaat u naar {{link:0}}.</p><p>Met vriendelijke groet,<br>bol.com Klantenservice</p></div><div class="eml-foot"><p>Dit is een automatisch verzonden bericht — antwoorden is niet mogelijk.</p><p>© 2026 bol.com</p></div></div>',
 '[{"label":"Bestelling herstellen","real_url":"http://bol-service.com/betaling-bijwerken","suspicious":true,"warning":"bol-service.com is geen bol.com-domein. Het echte domein is altijd @bol.com. Typ zelf bol.com in uw browser."}]'::jsonb,
 TRUE,
 '["Domein bol-service.com is niet van bol.com — het echte is @bol.com","Geen ordernummer dat u kunt terugvinden in uw account","Vraagt om betaalgegevens bij te werken via een link — doet bol.com nooit zo","Controleer bestellingen altijd zelf in uw bol.com-account"]'::jsonb,
 '[]'::jsonb,
 'Dit is phishing. Het domein bol-service.com is geen bol.com. Bol.com stuurt geen e-mails om betaalgegevens bij te werken via een link. Log altijd zelf in op bol.com om uw bestellingen te controleren.',
 150, 'advanced'),

('nl', 'both',
 'DHL',
 'noreply@dhl-bezorging.nl',
 'dhl-bezorging.nl is niet van DHL. Het officiële domein van DHL is dhl.nl of dhl.com.',
 'gisteren 10:55',
 'Bezorging mislukt — bevestig uw bezorgadres',
 'Wij konden uw pakket niet bezorgen. Bevestig uw adres om een nieuwe bezorging...',
 E'<div class="eml fam-parcel" style="--brand:#ffcc00;--cta:#ffcc00;--cta-ink:#d40511"><div class="eml-hero"><span class="eml-logo">DHL</span></div><div class="eml-body"><p>Geachte klant,</p><p>Wij hebben geprobeerd uw pakket (referentie DHL1234567890) te bezorgen, maar niemand was thuis.</p><p>Bevestig uw bezorgadres via {{link:0}} om een nieuwe bezorging te plannen. Uw pakket wordt 3 dagen bewaard.</p><p>Met vriendelijke groet,<br>DHL Bezorgservice</p></div><div class="eml-foot"><p>Dit is een automatisch verzonden bericht — antwoorden is niet mogelijk.</p><p>© 2026 DHL</p></div></div>',
 '[{"label":"Bezorgadres bevestigen","real_url":"http://dhl-bezorging.nl/herplanning","suspicious":true,"warning":"Dit is niet dhl.nl of dhl.com. Het is een nagemaakte site die op DHL lijkt — bedoeld om uw persoonsgegevens of betaalgegevens te stelen."}]'::jsonb,
 TRUE,
 '["dhl-bezorging.nl is geen DHL-domein — het echte is dhl.nl","DHL vraagt nooit per e-mail om een adres te bevestigen via een externe link","Trackingnummers van DHL beginnen met specifieke patronen — controleer altijd op dhl.nl","De urgentie (3 dagen bewaard) is bedoeld om u snel te laten klikken"]'::jsonb,
 '[]'::jsonb,
 'Dit is phishing. DHL vraagt u nooit via een e-mail-link om uw adres opnieuw te bevestigen. Controleer uw pakket altijd zelf via dhl.nl met het trackingnummer.',
 160, 'advanced'),

('nl', 'both',
 'Apple',
 'noreply@apple-id-info.com',
 'apple-id-info.com is geen Apple-domein. Apple stuurt meldingen altijd vanuit @apple.com.',
 'vandaag 06:41',
 'Uw Apple ID is gebruikt op een nieuw apparaat in Duitsland',
 'Uw Apple ID is zojuist aangemeld op een iPhone 15 in München...',
 E'<div class="eml fam-tech" style="--brand:#000000;--cta:#000000"><div class="eml-top"><span class="eml-logo">Apple</span></div><div class="eml-body"><p>Uw Apple ID (janssen.m@email.nl) is gebruikt om in te loggen op een nieuwe iPhone 15 in München, Duitsland.</p><p>Datum: vandaag om 06:38</p><p>Was dit u? Dan hoeft u niets te doen.</p><p>Was dit u niet? Beveilig uw account onmiddellijk via {{link:0}} om te voorkomen dat uw gegevens worden misbruikt.</p></div><div class="eml-foot"><p>Dit is een automatisch verzonden bericht — antwoorden is niet mogelijk.</p><p>© 2026 Apple</p></div></div>',
 '[{"label":"Account beveiligen","real_url":"http://apple-id-info.com/beveiligen","suspicious":true,"warning":"apple-id-info.com is geen Apple-domein. Echte Apple-beveiligingsmeldingen linken altijd naar appleid.apple.com."}]'::jsonb,
 TRUE,
 '["apple-id-info.com is geen Apple-domein — het echte is @apple.com","Meldt een buitenlandse locatie om schrik aan te jagen","Echte Apple-beveiligingsmeldingen verwijzen naar appleid.apple.com, niet naar externe sites","Log zelf in via appleid.apple.com om recente aanmeldingen te controleren"]'::jsonb,
 '[]'::jsonb,
 'Dit is phishing. Apple stuurt beveiligingsmeldingen altijd vanuit @apple.com en verwijst naar appleid.apple.com. Controleer uw account zelf via appleid.apple.com — nooit via een link in een e-mail.',
 170, 'advanced'),

('nl', 'both',
 'Coolblue',
 'noreply@coolblue.nl',
 'Het adres eindigt op @coolblue.nl — het officiële domein van Coolblue.',
 'vandaag 07:03',
 'Uw bestelling wordt morgen bezorgd tussen 10:00 en 12:00',
 'Beste mevrouw Janssen, uw bestelling met ordernummer 123456789 wordt morgen bezorgd...',
 E'<div class="eml fam-retail" style="--brand:#0090e3;--cta:#0090e3"><div class="eml-hero"><span class="eml-logo">Coolblue</span></div><div class="eml-body"><p>Beste mevrouw Janssen,</p><p>Goed nieuws: uw bestelling (ordernummer 123456789) wordt morgen bezorgd.</p><p>Bezorgmoment: morgen tussen 10:00 en 12:00<br>Adres: Dorpsstraat 12, 1234 AB Amsterdam</p><p>U hoeft niets te betalen bij de deur — alles is al voldaan.</p><p>Vragen? Bel ons op 010-7980090 of check de status in uw Coolblue-account.</p><p>Vriendelijke groet,<br>Coolblue</p></div><div class="eml-foot"><p>Dit is een automatisch verzonden bericht — antwoorden is niet mogelijk.</p><p>© 2026 Coolblue</p></div></div>',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Afzender @coolblue.nl is het officiële domein","Concrete bezorginformatie die overeenkomt met uw verwachte bestelling","Geen betaallink — alles is al voldaan","Verwijst naar eigen telefoonnummer en account, niet naar externe link"]'::jsonb,
 'Dit is een echte bezorgbevestiging van Coolblue. Let op: concrete ordernummer, geen betaalverzoek, en verwijs naar hun eigen kanalen. Echte bezorgmeldingen bevatten geen betaallinks.',
 180, 'advanced'),

('nl', 'both',
 'Google',
 'no-reply@accounts.google.com',
 'Het adres eindigt op @accounts.google.com — het officiële domein voor Google-beveiligingsmeldingen.',
 'gisteren 20:14',
 'Er is een nieuw apparaat aangemeld bij uw Google-account',
 'Er is een nieuwe aanmelding gedetecteerd op uw Google-account...',
 E'<div class="eml fam-tech" style="--brand:#4285f4;--cta:#4285f4;--logo:#3d7ae0"><div class="eml-top"><span class="eml-logo" style="font-weight:500">Google</span></div><div class="eml-body"><p>Er is een nieuwe aanmelding op uw Google-account gedetecteerd.</p><p>Apparaat: Windows-pc<br>Locatie: Amsterdam, Nederland<br>Tijdstip: gisteren om 20:11</p><p>Was dit u? Dan hoeft u niets te doen.</p><p>Was dit u niet? Ga dan zelf naar myaccount.google.com om uw wachtwoord te wijzigen en verdachte activiteit te bekijken.</p></div><div class="eml-foot"><p>Dit is een automatisch verzonden bericht — antwoorden is niet mogelijk.</p><p>© 2026 Google</p></div></div>',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Afzender @accounts.google.com is het officiële domein voor Google-meldingen","Geen link in het bericht — u wordt gevraagd zelf naar myaccount.google.com te gaan","Locatie Amsterdam past bij normaal gebruik","Informatieve toon zonder paniek of tijdsdruk"]'::jsonb,
 'Dit is een echte Google-aanmeldingsmelding. Let op hoe Google geen link stuurt om op te klikken, maar u vraagt zelf naar myaccount.google.com te gaan. Dat is precies hoe legitieme beveiligingsmeldingen horen te werken.',
 190, 'advanced'),

('nl', 'both',
 'NS Klantenservice',
 'klantenservice@ns.nl',
 'Het adres eindigt op @ns.nl — het officiële domein van NS.',
 '3 dagen geleden',
 'Uw treinticket voor 22 mei is gereed',
 'Beste mevrouw Janssen, uw ticket voor de reis Amsterdam-Rotterdam op 22 mei staat...',
 E'<div class="eml fam-parcel" style="--brand:#ffc917;--cta:#ffc917;--cta-ink:#003082"><div class="eml-hero"><span class="eml-logo">NS</span></div><div class="eml-body"><p>Beste mevrouw Janssen,</p><p>Uw treinticket voor de volgende reis is gereed:</p><p>Datum: woensdag 22 mei<br>Reis: Amsterdam Centraal → Rotterdam Centraal<br>Vertrek: 09:14 — Aankomst: 10:09<br>Klasse: 2e klas</p><p>Uw ticket staat in de NS-app. U kunt het ook bekijken via Mijn NS op ns.nl.</p><p>Goede reis!<br>NS</p></div><div class="eml-foot"><p>Dit is een automatisch verzonden bericht — antwoorden is niet mogelijk.</p><p>© 2026 NS</p></div></div>',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Afzender @ns.nl is het officiële domein van NS","Concrete reisgegevens die u verwacht — datum, route, tijd","Geen betaalverzoek, geen link — verwijst naar de NS-app of ns.nl","Geen tijdsdruk of dreiging"]'::jsonb,
 'Dit is een echte NS-ticketbevestiging. Alle informatie klopt, er is geen betaallink en u wordt verwezen naar de NS-app of ns.nl voor details.',
 200, 'advanced'),

('en', 'both',
 'Amazon',
 'order-update@amazon-uk.com',
 'amazon-uk.com is not Amazon. Real Amazon UK emails come from @amazon.co.uk.',
 'today 14:07',
 'Your order has been cancelled — update your payment details',
 'We were unable to process payment for your order. Your order has been cancelled...',
 E'<div class="eml fam-retail" style="--brand:#232f3e;--cta:#232f3e"><div class="eml-hero"><span class="eml-logo" style="text-transform:lowercase;font-weight:800">amazon</span></div><div class="eml-body"><p>Dear customer,</p><p>We were unable to process payment for your recent order. As a result, your order has been cancelled.</p><p>To reinstate your order and update your payment details, please visit {{link:0}} within 24 hours.</p><p>Kind regards,<br>Amazon Customer Service</p></div><div class="eml-foot"><p>This is an automated message — please do not reply.</p><p>© 2026 amazon</p></div></div>',
 '[{"label":"Update payment details","real_url":"http://amazon-uk.com/payment-update","suspicious":true,"warning":"amazon-uk.com is not Amazon. The real domain is amazon.co.uk. Never update payment details via a link in an email — go directly to amazon.co.uk."}]'::jsonb,
 TRUE,
 '["Domain amazon-uk.com is not Amazon — the real domain is amazon.co.uk","Amazon never asks you to update payment details via an email link","The 24-hour deadline creates artificial urgency","Check your orders directly in your Amazon account at amazon.co.uk"]'::jsonb,
 '[]'::jsonb,
 'This is phishing. Amazon always sends emails from @amazon.co.uk and never asks you to update payment details via a link in an email. Check any order directly at amazon.co.uk.',
 150, 'advanced'),

('en', 'both',
 'Apple',
 'noreply@apple-account-verify.com',
 'apple-account-verify.com is not Apple. Real Apple emails come from @apple.com.',
 'today 05:58',
 'Your Apple ID was used to sign in on a new device in Poland',
 'Your Apple ID was just used to sign in on an iPhone 15 in Warsaw...',
 E'<div class="eml fam-tech" style="--brand:#000000;--cta:#000000"><div class="eml-top"><span class="eml-logo">Apple</span></div><div class="eml-body"><p>Your Apple ID (yourname@email.com) was used to sign in on a new iPhone 15 in Warsaw, Poland.</p><p>Date: today at 05:55</p><p>If this was you, no action is needed.</p><p>If this was not you, your account may be at risk. Secure your account immediately via {{link:0}}.</p></div><div class="eml-foot"><p>This is an automated message — please do not reply.</p><p>© 2026 Apple</p></div></div>',
 '[{"label":"Secure your account","real_url":"http://apple-account-verify.com/secure","suspicious":true,"warning":"apple-account-verify.com is not Apple. Real Apple security alerts always link to appleid.apple.com — never to third-party domains."}]'::jsonb,
 TRUE,
 '["apple-account-verify.com is not Apple — real emails come from @apple.com","Mentions a foreign location to create alarm","Real Apple alerts link to appleid.apple.com, not external sites","Go directly to appleid.apple.com to review recent activity without clicking any link"]'::jsonb,
 '[]'::jsonb,
 'This is phishing. Apple security notifications always come from @apple.com and link to appleid.apple.com. Check your account directly at appleid.apple.com — never via a link in a suspicious email.',
 160, 'advanced'),

('en', 'both',
 'PayPal',
 'service@paypal-account.net',
 'paypal-account.net is not PayPal. All real PayPal emails come from @paypal.com.',
 'yesterday 11:34',
 'Your PayPal account has been temporarily limited',
 'We have noticed some unusual activity in your account. To restore full access...',
 E'<div class="eml fam-pay" style="--brand:#003087;--cta:#003087"><div class="eml-hero"><span class="eml-logo" style="font-style:italic;font-weight:800">PayPal</span></div><div class="eml-body"><p>Dear customer,</p><p>We have noticed some unusual activity in your PayPal account and have temporarily limited access as a precaution.</p><p>To restore full access, please confirm your identity via {{link:0}}. Failure to verify within 48 hours may result in permanent account suspension.</p><p>Kind regards,<br>PayPal Security Team</p></div><div class="eml-foot"><p>This is an automated message — please do not reply.</p><p>© 2026 PayPal</p></div></div>',
 '[{"label":"Confirm your identity","real_url":"http://paypal-account.net/verify","suspicious":true,"warning":"paypal-account.net is not PayPal. All real PayPal emails come from @paypal.com. Log in directly at paypal.com."}]'::jsonb,
 TRUE,
 '["paypal-account.net is not PayPal — the real domain is paypal.com","Threat of permanent suspension creates urgency","PayPal never asks you to verify identity via an email link","Log in directly at paypal.com to check your account status"]'::jsonb,
 '[]'::jsonb,
 'This is phishing. PayPal never asks you to verify your identity via an email link. All real PayPal communications come from @paypal.com. Check your account status by going directly to paypal.com.',
 170, 'advanced'),

('en', 'both',
 'Google',
 'no-reply@accounts.google.com',
 'The address ends in @accounts.google.com — Google official domain for security notifications.',
 'yesterday 19:42',
 'New sign-in on your Google account',
 'A new sign-in was detected on your Google account...',
 E'<div class="eml fam-tech" style="--brand:#4285f4;--cta:#4285f4;--logo:#3d7ae0"><div class="eml-top"><span class="eml-logo" style="font-weight:500">Google</span></div><div class="eml-body"><p>A new sign-in was detected on your Google account.</p><p>Device: Windows PC<br>Location: London, United Kingdom<br>Time: yesterday at 19:39</p><p>If this was you, no action is needed.</p><p>If this was not you, visit myaccount.google.com to change your password and review recent activity.</p></div><div class="eml-foot"><p>This is an automated message — please do not reply.</p><p>© 2026 Google</p></div></div>',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Sender @accounts.google.com is Google official domain for security alerts","No link to click — you are directed to myaccount.google.com directly","Location matches normal usage (UK)","Informational tone without panic or time pressure"]'::jsonb,
 'This is a genuine Google sign-in notification. Notice how Google does not include a link to click — it tells you to go to myaccount.google.com yourself. That is how legitimate security alerts work.',
 180, 'advanced'),

('en', 'both',
 'Amazon',
 'shipment-tracking@amazon.co.uk',
 'The address ends in @amazon.co.uk — Amazon UK official domain.',
 '2 days ago',
 'Your order has been dispatched — arriving tomorrow',
 'Great news! Your order is on its way and is expected to arrive tomorrow...',
 E'<div class="eml fam-retail" style="--brand:#232f3e;--cta:#232f3e"><div class="eml-hero"><span class="eml-logo" style="text-transform:lowercase;font-weight:800">amazon</span></div><div class="eml-body"><p>Great news! Your order is on its way.</p><p>📦 Order number: 203-1234567-8901234<br>Estimated delivery: tomorrow between 9am and 1pm<br>Carrier: Amazon Logistics</p><p>You can track your parcel in the Your Orders section of your Amazon account at amazon.co.uk.</p><p>Thank you for shopping with us.<br>Amazon</p></div><div class="eml-foot"><p>This is an automated message — please do not reply.</p><p>© 2026 amazon</p></div></div>',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Sender @amazon.co.uk is Amazon UK official domain","Concrete order number — verifiable in your account","No payment request or urgent action needed","Directs you to amazon.co.uk for tracking, not an external site"]'::jsonb,
 'This is a genuine Amazon dispatch notification. It contains a real order number and directs you to amazon.co.uk. No payment request, no urgent demands.',
 190, 'advanced'),

('en', 'both',
 'Microsoft',
 'microsoft-noreply@microsoft.com',
 'The address ends in @microsoft.com — Microsoft official domain.',
 '3 days ago',
 'Your Microsoft 365 subscription invoice for May',
 'Your monthly Microsoft 365 Personal invoice is now available...',
 E'<div class="eml fam-tech" style="--brand:#0067b8;--cta:#0067b8"><div class="eml-top"><span class="eml-logo">Microsoft</span></div><div class="eml-body"><p>Your monthly Microsoft 365 Personal invoice is now available.</p><p>Amount: £7.99<br>Date: 3 days ago<br>Payment method: Visa ending in 1234</p><p>You can view your full invoice and manage your subscription at account.microsoft.com.</p><p>Thank you,<br>Microsoft</p></div><div class="eml-foot"><p>This is an automated message — please do not reply.</p><p>© 2026 Microsoft</p></div></div>',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Sender @microsoft.com is Microsoft official domain","Shows exact amount and last 4 digits of payment card","No urgent link to click — directs you to account.microsoft.com","Matches expected monthly subscription charge"]'::jsonb,
 'This is a genuine Microsoft subscription receipt. It shows the charge details and directs you to account.microsoft.com. No suspicious links, no urgent demands.',
 200, 'advanced'),

('fr', 'both',
 'Orange',
 'facture@orange-espace-client.fr',
 'orange-espace-client.fr nest pas Orange. Les mails officiels dOrange viennent de @orange.fr.',
 'hier 13:45',
 'Votre facture Orange de mai est impayée — réglez maintenant',
 'Votre facture de mai 2025 dun montant de 39,99 € na pas pu être prélevée...',
 E'<div class="eml fam-tech" style="--brand:#ff7900;--cta:#ff7900;--logo:#c75e00"><div class="eml-top"><span class="eml-logo" style="text-transform:lowercase">orange™</span></div><div class="eml-body"><p>Cher client,</p><p>Votre facture Orange de mai 2025 (39,99 €) na pas pu être prélevée sur votre compte. Pour éviter la suspension de votre ligne, réglez votre facture via {{link:0}} avant le 30 mai.</p><p>Cordialement,<br>Orange Service Facturation</p></div><div class="eml-foot"><p>Ceci est un message automatique — merci de ne pas y répondre.</p><p>© 2026 orange™</p></div></div>',
 '[{"label":"Régler ma facture","real_url":"http://orange-espace-client.fr/paiement","suspicious":true,"warning":"orange-espace-client.fr nest pas Orange. Les mails dOrange viennent de @orange.fr. Connectez-vous directement sur orange.fr."}]'::jsonb,
 TRUE,
 '["Le domaine orange-espace-client.fr nest pas celui dOrange — le vrai est @orange.fr","La menace de suspension de ligne crée une pression artificielle","Orange ne demande jamais de régler une facture via un lien dans un e-mail","Connectez-vous directement sur orange.fr pour gérer votre facture"]'::jsonb,
 '[]'::jsonb,
 'Il sagit de phishing. Orange ne demande pas de régler des factures via un lien dans un e-mail. Les vrais e-mails dOrange viennent de @orange.fr. Gérez votre facture directement sur orange.fr.',
 150, 'advanced'),

('fr', 'both',
 'Apple',
 'noreply@apple-id-securite.com',
 'apple-id-securite.com nest pas Apple. Les vrais mails dApple viennent de @apple.com.',
 'aujourdhui 05:47',
 'Votre identifiant Apple a été utilisé depuis lAllemagne',
 'Votre identifiant Apple vient dêtre utilisé pour se connecter sur un iPhone à Berlin...',
 E'<div class="eml fam-tech" style="--brand:#000000;--cta:#000000"><div class="eml-top"><span class="eml-logo">Apple</span></div><div class="eml-body"><p>Votre identifiant Apple (votreprenom@email.fr) a été utilisé pour se connecter sur un nouvel iPhone 15 à Berlin, Allemagne.</p><p>Date : aujourdhui à 05:44</p><p>Était-ce vous ? Dans ce cas, aucune action nest requise.</p><p>Si ce nétait pas vous, sécurisez votre compte immédiatement via {{link:0}}.</p></div><div class="eml-foot"><p>Ceci est un message automatique — merci de ne pas y répondre.</p><p>© 2026 Apple</p></div></div>',
 '[{"label":"Sécuriser mon compte","real_url":"http://apple-id-securite.com/securiser","suspicious":true,"warning":"apple-id-securite.com nest pas Apple. Les vraies alertes de sécurité Apple mènent toujours vers appleid.apple.com."}]'::jsonb,
 TRUE,
 '["apple-id-securite.com nest pas Apple — le vrai domaine est @apple.com","Mentionne une localisation étrangère pour provoquer la panique","Les vraies alertes Apple renvoient vers appleid.apple.com, pas vers des sites externes","Rendez-vous directement sur appleid.apple.com pour consulter les connexions récentes"]'::jsonb,
 '[]'::jsonb,
 'Il sagit de phishing. Les alertes de sécurité Apple viennent toujours de @apple.com et renvoient vers appleid.apple.com. Vérifiez votre compte directement sur appleid.apple.com.',
 160, 'advanced'),

('fr', 'both',
 'Assurance Maladie',
 'remboursement@ameli-sante.fr',
 'ameli-sante.fr nest pas lAssurance Maladie. Le vrai domaine est ameli.fr.',
 'avant-hier 09:21',
 'Votre remboursement de 58,40 € est disponible',
 'Suite à votre dernière consultation, vous avez droit à un remboursement de 58,40 €...',
 E'<div class="eml fam-gov" style="--brand:#0c419a;--cta:#0c419a"><div class="eml-top"><span class="eml-logo">l’Assurance Maladie</span></div><div class="eml-body"><p>Madame, Monsieur,</p><p>Suite à votre dernière consultation médicale, vous avez droit à un remboursement de 58,40 €.</p><p>Pour recevoir ce remboursement, veuillez mettre à jour votre RIB via {{link:0}}. Sans mise à jour, le remboursement ne pourra pas être versé.</p><p>Cordialement,<br>LAssurance Maladie</p></div><div class="eml-foot"><p>Ceci est un message automatique — merci de ne pas y répondre.</p><p>© 2026 l’Assurance Maladie</p></div></div>',
 '[{"label":"Mettre à jour mon RIB","real_url":"http://ameli-sante.fr/rib","suspicious":true,"warning":"ameli-sante.fr nest pas lAssurance Maladie. Le vrai domaine est ameli.fr. LAssurance Maladie connaît déjà votre RIB et ne le demande jamais par e-mail."}]'::jsonb,
 TRUE,
 '["ameli-sante.fr nest pas lAssurance Maladie — le vrai domaine est ameli.fr","LAssurance Maladie connaît déjà votre RIB et rembourse automatiquement","Elle ne demande jamais de mettre à jour un RIB par e-mail","Vérifiez vos remboursements directement sur ameli.fr ou dans lappli Ameli"]'::jsonb,
 '[]'::jsonb,
 'Il sagit de phishing. LAssurance Maladie dispose déjà de votre RIB et effectue les remboursements automatiquement. Elle ne demande jamais de le mettre à jour par e-mail. Consultez vos remboursements sur ameli.fr.',
 170, 'advanced'),

('fr', 'both',
 'Google',
 'no-reply@accounts.google.com',
 'Ladresse se termine par @accounts.google.com — le domaine officiel de Google pour les alertes de sécurité.',
 'hier 20:07',
 'Nouvelle connexion sur votre compte Google',
 'Une nouvelle connexion a été détectée sur votre compte Google...',
 E'<div class="eml fam-tech" style="--brand:#4285f4;--cta:#4285f4;--logo:#3d7ae0"><div class="eml-top"><span class="eml-logo" style="font-weight:500">Google</span></div><div class="eml-body"><p>Une nouvelle connexion a été détectée sur votre compte Google.</p><p>Appareil : PC Windows<br>Localisation : Paris, France<br>Heure : hier à 20:04</p><p>Était-ce vous ? Dans ce cas, aucune action nest requise.</p><p>Si ce nétait pas vous, rendez-vous sur myaccount.google.com pour modifier votre mot de passe et consulter lactivité récente.</p></div><div class="eml-foot"><p>Ceci est un message automatique — merci de ne pas y répondre.</p><p>© 2026 Google</p></div></div>',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Lexpéditeur @accounts.google.com est le domaine officiel de Google pour les alertes","Pas de lien à cliquer — vous êtes renvoyé vers myaccount.google.com directement","Localisation cohérente (Paris, France)","Ton informatif, sans panique ni pression temporelle"]'::jsonb,
 'Il sagit dune vraie alerte de connexion Google. Notez que Google ninclut pas de lien à cliquer — il vous demande daller vous-même sur myaccount.google.com. Cest ainsi que fonctionnent les vraies alertes de sécurité.',
 180, 'advanced'),

('fr', 'both',
 'SNCF Connect',
 'noreply@sncf-connect.com',
 'Ladresse se termine par @sncf-connect.com — le domaine officiel de lapplication SNCF Connect.',
 '2 jours avant',
 'Votre billet Paris-Lyon du 22 mai est confirmé',
 'Votre billet pour le TGV Paris-Lyon du mercredi 22 mai est confirmé...',
 E'<div class="eml fam-parcel" style="--brand:#1f2940;--cta:#1f2940"><div class="eml-hero"><span class="eml-logo">SNCF CONNECT</span></div><div class="eml-body"><p>Bonjour,</p><p>Votre billet est confirmé :</p><p>🚄 TGV Paris-Lyon<br>Date : mercredi 22 mai<br>Départ : Paris Gare de Lyon à 09:22<br>Arrivée : Lyon Part-Dieu à 11:00<br>Voyageur : M. Dupont<br>Classe : 2e classe</p><p>Votre billet est disponible dans lapplication SNCF Connect.</p><p>Bon voyage !<br>SNCF Connect</p></div><div class="eml-foot"><p>Ceci est un message automatique — merci de ne pas y répondre.</p><p>© 2026 SNCF CONNECT</p></div></div>',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Lexpéditeur @sncf-connect.com est le domaine officiel de lapplication SNCF","Informations concrètes et attendues : trajet, date, heure, nom","Pas de lien de paiement ni de demande dinformations","Renvoie vers lapplication SNCF Connect pour accéder au billet"]'::jsonb,
 'Il sagit dun vrai billet de train SNCF. Toutes les informations sont concrètes et correspondent à une réservation attendue. Aucun lien de paiement ni demande dinformations personnelles.',
 190, 'advanced'),

('fr', 'both',
 'PayPal',
 'service@paypal.com',
 'Ladresse se termine par @paypal.com — le domaine officiel de PayPal.',
 '4 jours avant',
 'Confirmation de paiement : 24,99 €',
 'Vous avez effectué un paiement de 24,99 € à Netflix via PayPal...',
 E'<div class="eml fam-pay" style="--brand:#003087;--cta:#003087"><div class="eml-hero"><span class="eml-logo" style="font-style:italic;font-weight:800">PayPal</span></div><div class="eml-body"><p>Vous avez effectué un paiement.</p><p>Montant : 24,99 €<br>Destinataire : Netflix<br>Date : il y a 4 jours<br>Moyen de paiement : carte Visa se terminant par 4242</p><p>Pour consulter les détails de cette transaction ou signaler un problème, connectez-vous à votre compte sur paypal.com.</p><p>Merci dutiliser PayPal.<br>Léquipe PayPal</p></div><div class="eml-foot"><p>Ceci est un message automatique — merci de ne pas y répondre.</p><p>© 2026 PayPal</p></div></div>',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Lexpéditeur @paypal.com est le domaine officiel de PayPal","Montant et destinataire concrets — vérifiables dans votre compte","Pas de lien urgent à cliquer — renvoie vers paypal.com","Correspond à un abonnement mensuel attendu (Netflix)"]'::jsonb,
 'Il sagit dune vraie confirmation de paiement PayPal. Elle montre les détails de la transaction et renvoie vers paypal.com. Aucune demande urgente ni lien suspect.',
 200, 'advanced'),

('de', 'both',
 'PayPal',
 'service@paypal-konto.de',
 'paypal-konto.de ist nicht PayPal. Alle echten PayPal-E-Mails kommen von @paypal.com.',
 'gestern 11:34',
 'Ihr PayPal-Konto wurde vorübergehend eingeschränkt',
 'Wir haben ungewöhnliche Aktivitäten auf Ihrem Konto festgestellt...',
 E'<div class="eml fam-pay" style="--brand:#003087;--cta:#003087"><div class="eml-hero"><span class="eml-logo" style="font-style:italic;font-weight:800">PayPal</span></div><div class="eml-body"><p>Sehr geehrte/r Kundin/Kunde,</p><p>Wir haben ungewöhnliche Aktivitäten auf Ihrem PayPal-Konto festgestellt und haben den Zugang vorübergehend eingeschränkt.</p><p>Um den vollen Zugang wiederherzustellen, bestätigen Sie bitte Ihre Identität über {{link:0}}. Ohne Bestätigung innerhalb von 48 Stunden kann Ihr Konto dauerhaft gesperrt werden.</p><p>Mit freundlichen Grüßen,<br>PayPal Sicherheitsteam</p></div><div class="eml-foot"><p>Dies ist eine automatische Nachricht — bitte antworten Sie nicht darauf.</p><p>© 2026 PayPal</p></div></div>',
 '[{"label":"Identität bestätigen","real_url":"http://paypal-konto.de/verifizieren","suspicious":true,"warning":"paypal-konto.de ist nicht PayPal. Alle echten PayPal-E-Mails kommen von @paypal.com. Loggen Sie sich direkt auf paypal.com ein."}]'::jsonb,
 TRUE,
 '["paypal-konto.de ist nicht PayPal — das echte Domain ist paypal.com","Drohung mit dauerhafter Sperrung nach 48 Stunden","PayPal bittet nie per E-Mail-Link um Identitätsbestätigung","Prüfen Sie Ihren Kontostatus direkt auf paypal.com"]'::jsonb,
 '[]'::jsonb,
 'Dies ist Phishing. PayPal bittet Sie nie, Ihre Identität über einen E-Mail-Link zu bestätigen. Alle echten PayPal-E-Mails kommen von @paypal.com. Prüfen Sie Ihren Status direkt auf paypal.com.',
 150, 'advanced'),

('de', 'both',
 'Apple',
 'noreply@apple-sicherheit.de',
 'apple-sicherheit.de ist nicht Apple. Echte Apple-E-Mails kommen von @apple.com.',
 'heute 05:51',
 'Ihre Apple-ID wurde in Polen auf einem neuen Gerät verwendet',
 'Ihre Apple-ID wurde soeben auf einem neuen iPhone in Warschau verwendet...',
 E'<div class="eml fam-tech" style="--brand:#000000;--cta:#000000"><div class="eml-top"><span class="eml-logo">Apple</span></div><div class="eml-body"><p>Ihre Apple-ID (ihrname@email.de) wurde verwendet, um sich auf einem neuen iPhone 15 in Warschau, Polen, anzumelden.</p><p>Datum: heute um 05:48</p><p>Waren Sie das? Dann müssen Sie nichts unternehmen.</p><p>Waren Sie das nicht? Sichern Sie Ihr Konto sofort über {{link:0}}, um einen Missbrauch zu verhindern.</p></div><div class="eml-foot"><p>Dies ist eine automatische Nachricht — bitte antworten Sie nicht darauf.</p><p>© 2026 Apple</p></div></div>',
 '[{"label":"Konto sichern","real_url":"http://apple-sicherheit.de/sichern","suspicious":true,"warning":"apple-sicherheit.de ist nicht Apple. Echte Apple-Sicherheitsmeldungen führen immer zu appleid.apple.com — nie zu externen Domains."}]'::jsonb,
 TRUE,
 '["apple-sicherheit.de ist nicht Apple — echte E-Mails kommen von @apple.com","Nennt einen ausländischen Ort, um Panik zu erzeugen","Echte Apple-Meldungen führen zu appleid.apple.com, nicht zu Drittseiten","Besuchen Sie direkt appleid.apple.com, um aktuelle Anmeldungen zu prüfen"]'::jsonb,
 '[]'::jsonb,
 'Dies ist Phishing. Apple-Sicherheitsmeldungen kommen immer von @apple.com und führen zu appleid.apple.com. Prüfen Sie Ihr Konto direkt auf appleid.apple.com.',
 160, 'advanced'),

('de', 'both',
 'Volksbank',
 'sicherheit@volksbank-online.de',
 'volksbank-online.de ist nicht Ihre Volksbank. Das echte Domain Ihrer Bank endet auf volksbank.de oder eine regionale Variante.',
 'vorgestern 16:08',
 'Sicherheitswarnung: Bitte bestätigen Sie Ihre Identität',
 'Wir haben eine verdächtige Anmeldung auf Ihrem Online-Banking-Konto festgestellt...',
 E'<div class="eml fam-bank" style="--brand:#0066b3;--cta:#0066b3"><div class="eml-top"><span class="eml-logo">Volksbank</span></div><div class="eml-body"><p>Sehr geehrte/r Kundin/Kunde,</p><p>Wir haben eine verdächtige Anmeldung auf Ihrem Online-Banking-Konto festgestellt. Als Sicherheitsmaßnahme wurde Ihr Zugang vorübergehend eingeschränkt.</p><p>Bitte bestätigen Sie Ihre Identität über {{link:0}}, um Ihren Zugang wiederherzustellen.</p><p>Mit freundlichen Grüßen,<br>Volksbank Sicherheitsdienst</p></div><div class="eml-foot"><p>Dies ist eine automatische Nachricht — bitte antworten Sie nicht darauf.</p><p>© 2026 Volksbank</p></div></div>',
 '[{"label":"Identität bestätigen","real_url":"http://volksbank-online.de/sicherheit","suspicious":true,"warning":"volksbank-online.de ist kein offizielles Domain einer Volksbank. Ihre echte Bank verwendet ihr eigenes Domain (z. B. volksbank-musterstadt.de). Loggen Sie sich immer direkt über die Website Ihrer Filiale ein."}]'::jsonb,
 TRUE,
 '["volksbank-online.de klingt offiziell, ist aber nicht das Domain Ihrer Volksbank","Jede Volksbank hat ihr eigenes regionales Domain — prüfen Sie es auf Ihrer Bankkarte","Keine Bank bittet per E-Mail um Identitätsbestätigung über einen Link","Loggen Sie sich direkt über die Website Ihrer Volksbank-Filiale ein"]'::jsonb,
 '[]'::jsonb,
 'Dies ist Phishing. Jede Volksbank hat ihr eigenes regionales Domain (z. B. volksbank-musterstadt.de). Kein Kreditinstitut bittet per E-Mail um Identitätsbestätigung. Loggen Sie sich direkt über die offizielle Website Ihrer Filiale ein.',
 170, 'advanced'),

('de', 'both',
 'Google',
 'no-reply@accounts.google.com',
 'Die Adresse endet auf @accounts.google.com — Googles offizielles Domain für Sicherheitsmeldungen.',
 'gestern 19:51',
 'Neue Anmeldung bei Ihrem Google-Konto',
 'Eine neue Anmeldung wurde bei Ihrem Google-Konto festgestellt...',
 E'<div class="eml fam-tech" style="--brand:#4285f4;--cta:#4285f4;--logo:#3d7ae0"><div class="eml-top"><span class="eml-logo" style="font-weight:500">Google</span></div><div class="eml-body"><p>Eine neue Anmeldung wurde bei Ihrem Google-Konto festgestellt.</p><p>Gerät: Windows-PC<br>Standort: Berlin, Deutschland<br>Uhrzeit: gestern um 19:48</p><p>Waren Sie das? Dann müssen Sie nichts unternehmen.</p><p>Waren Sie das nicht? Besuchen Sie myaccount.google.com, um Ihr Passwort zu ändern und aktuelle Aktivitäten einzusehen.</p></div><div class="eml-foot"><p>Dies ist eine automatische Nachricht — bitte antworten Sie nicht darauf.</p><p>© 2026 Google</p></div></div>',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Absender @accounts.google.com ist Googles offizielles Domain für Sicherheitsmeldungen","Kein Link zum Klicken — Sie werden direkt zu myaccount.google.com weitergeleitet","Standort Deutschland — passt zu normalem Nutzungsverhalten","Informativer Ton ohne Panik oder Zeitdruck"]'::jsonb,
 'Dies ist eine echte Google-Anmeldebenachrichtigung. Beachten Sie, dass Google keinen Link zum Klicken enthält — Sie werden gebeten, myaccount.google.com selbst aufzurufen. So funktionieren legitime Sicherheitsmeldungen.',
 180, 'advanced'),

('de', 'both',
 'OTTO',
 'bestellung@otto.de',
 'Die Adresse endet auf @otto.de — das offizielle Domain von OTTO.',
 '2 Tage vor',
 'Ihre Bestellung bei OTTO wird morgen geliefert',
 'Ihre Bestellung (Bestellnummer 1234567890) wird morgen zwischen 10 und 12 Uhr geliefert...',
 E'<div class="eml fam-retail" style="--brand:#d4021d;--cta:#d4021d"><div class="eml-hero"><span class="eml-logo">OTTO</span></div><div class="eml-body"><p>Hallo,</p><p>Ihre Bestellung ist unterwegs!</p><p>📦 Bestellnummer: 1234567890<br>Voraussichtliche Lieferung: morgen zwischen 10:00 und 12:00 Uhr<br>Versanddienstleister: DHL</p><p>Sie können Ihre Sendung im Bereich „Meine Bestellungen" auf otto.de verfolgen.</p><p>Vielen Dank für Ihren Einkauf.<br>OTTO</p></div><div class="eml-foot"><p>Dies ist eine automatische Nachricht — bitte antworten Sie nicht darauf.</p><p>© 2026 OTTO</p></div></div>',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Absender @otto.de ist das offizielle Domain von OTTO","Konkrete Bestellnummer — in Ihrem OTTO-Konto nachprüfbar","Keine Zahlungsaufforderung oder Anfrage nach persönlichen Daten","Verweist auf otto.de für die Sendungsverfolgung"]'::jsonb,
 'Dies ist eine echte Lieferbenachrichtigung von OTTO. Sie enthält eine nachprüfbare Bestellnummer und verweist auf otto.de. Keine verdächtigen Links, keine Zahlungsaufforderung.',
 190, 'advanced'),

('de', 'both',
 'Netflix',
 'info@mailer.netflix.com',
 'Die Adresse endet auf @mailer.netflix.com — ein offizielles Netflix-Versand-Domain.',
 '4 Tage vor',
 'Ihre monatliche Netflix-Zahlung wurde bestätigt',
 'Ihre monatliche Zahlung für Netflix wurde erfolgreich verarbeitet...',
 E'<div class="eml fam-retail" style="--brand:#000000;--cta:#000000;--cta-ink:#e50914"><div class="eml-hero"><span class="eml-logo" style="letter-spacing:1px;font-weight:800">NETFLIX</span></div><div class="eml-body"><p>Ihre monatliche Zahlung wurde verarbeitet.</p><p>Betrag: 17,99 €<br>Datum: vor 4 Tagen<br>Zahlungsmethode: Visa endend auf 5678</p><p>Sie können Ihr Abonnement und Ihre Zahlungshistorie unter netflix.com/YourAccount verwalten.</p><p>Danke, dass Sie Netflix nutzen.<br>Das Netflix-Team</p></div><div class="eml-foot"><p>Dies ist eine automatische Nachricht — bitte antworten Sie nicht darauf.</p><p>© 2026 NETFLIX</p></div></div>',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Absender @mailer.netflix.com ist ein offizielles Netflix-Domain für Rechnungen","Konkreter Betrag und letzte 4 Ziffern der Karte — entspricht Ihrer monatlichen Zahlung","Kein dringender Link — verweist auf netflix.com für die Kontoverwaltung","Entspricht der erwarteten monatlichen Abbuchung"]'::jsonb,
 'Dies ist eine echte Netflix-Zahlungsbestätigung. Sie zeigt den abgebuchten Betrag und verweist auf netflix.com. Keine verdächtigen Links, keine dringenden Forderungen.',
 200, 'advanced');

-- nl-BE en fr-BE: kopieën van nieuwe nl/fr advanced-berichten.
INSERT INTO inbox_messages
  (locale, audience, sender_name, sender_address, sender_note, received_label,
   subject, preview, body, links, is_phishing, red_flags, green_flags,
   explanation, sort_order, difficulty)
SELECT 'nl-BE', audience, sender_name, sender_address, sender_note, received_label,
       subject, preview, body, links, is_phishing, red_flags, green_flags,
       explanation, sort_order, difficulty
FROM inbox_messages
WHERE locale = 'nl' AND difficulty = 'advanced' AND sort_order >= 150;

INSERT INTO inbox_messages
  (locale, audience, sender_name, sender_address, sender_note, received_label,
   subject, preview, body, links, is_phishing, red_flags, green_flags,
   explanation, sort_order, difficulty)
SELECT 'fr-BE', audience, sender_name, sender_address, sender_note, received_label,
       subject, preview, body, links, is_phishing, red_flags, green_flags,
       explanation, sort_order, difficulty
FROM inbox_messages
WHERE locale = 'fr' AND difficulty = 'advanced' AND sort_order >= 150;

-- ── SharePoint-phishing (sort_order 210, business, advanced) ──────────────
INSERT INTO inbox_messages
  (locale, audience, sender_name, sender_address, sender_note, received_label,
   subject, preview, body, links, is_phishing, red_flags, green_flags,
   explanation, sort_order, difficulty)
VALUES
('nl', 'business',
 'Microsoft SharePoint',
 'no-reply@sharepointonline-files.com',
 'Het domein is sharepointonline-files.com — niet sharepointonline.com. Microsoft verstuurt uitnodigingen altijd via @sharepointonline.com.',
 'vandaag 14:22',
 'Vandenberghe Koen heeft een bestand met u gedeeld',
 'Vandenberghe Koen heeft u uitgenodigd om ‘Salarisschalen_en_Bonussen_2026_NL’ te bewerken.',
 E'<div class="ol-share-card"><div class="ol-share-head"><div class="ol-share-icon">⤴</div><h2 class="ol-share-heading">Vandenberghe Koen heeft u uitgenodigd om een bestand te bewerken</h2></div><div class="ol-share-body"><p class="ol-share-msg">"Vertrouwelijk — ter review voor HR en management. Graag feedback voor maandag."</p><p class="ol-share-intro">Dit is het bestand dat Vandenberghe Koen met u heeft gedeeld.</p><div class="ol-share-file"><span class="ol-share-file-ico">📄</span><span class="ol-share-file-name">Salarisschalen_en_Bonussen_2026_NL.xlsx</span></div><p class="ol-share-protection">🔒 Deze uitnodiging werkt alleen voor u en personen met bestaande toegang.</p><div class="ol-share-actions">{{link:0}}</div></div></div>',
 '[{"label":"Bestand openen","real_url":"http://sharepointonline-files.com/share/view?id=a9f3c2","suspicious":true,"warning":"Dit is geen Microsoft-link. Het domein sharepointonline-files.com is nep. U wordt naar een valse inlogpagina geleid om uw Microsoft-wachtwoord te stelen."}]'::jsonb,
 TRUE,
 '["Het afzenderdomein sharepointonline-files.com is niet van Microsoft — het echte is @sharepointonline.com","Een echte SharePoint-uitnodiging opent het bestand direct — er wordt nooit om een nieuw wachtwoord gevraagd","De link gaat naar sharepointonline-files.com in plaats van sharepoint.com of microsoft.com","Controleer uitnodigingen altijd via Microsoft 365 zelf, niet via een e-maillink"]'::jsonb,
 '[]'::jsonb,
 'Dit is phishing. Het afzenderdomein sharepointonline-files.com lijkt sterk op het echte Microsoft-domein, maar is nep. Via de link wordt u naar een valse Microsoft-inlogpagina geleid om uw werkwachtwoord te stelen. Echte SharePoint-uitnodigingen komen altijd van @sharepointonline.com en openen het bestand zonder opnieuw in te loggen.',
 210, 'advanced'),
('en', 'business',
 'Microsoft SharePoint',
 'no-reply@sharepointonline-files.com',
 'The domain is sharepointonline-files.com — not sharepointonline.com. Microsoft always sends sharing invitations from @sharepointonline.com.',
 'today 14:22',
 'Vandenberghe Koen has shared a file with you',
 'Vandenberghe Koen has invited you to edit ‘Salary_Scales_and_Bonuses_2026_EN’.',
 E'<div class="ol-share-card"><div class="ol-share-head"><div class="ol-share-icon">⤴</div><h2 class="ol-share-heading">Vandenberghe Koen has invited you to edit a file</h2></div><div class="ol-share-body"><p class="ol-share-msg">"Confidential — for review by HR and management. Feedback by Monday please."</p><p class="ol-share-intro">This is the file Vandenberghe Koen shared with you.</p><div class="ol-share-file"><span class="ol-share-file-ico">📄</span><span class="ol-share-file-name">Salary_Scales_and_Bonuses_2026_EN.xlsx</span></div><p class="ol-share-protection">🔒 This invitation only works for you and people with existing access.</p><div class="ol-share-actions">{{link:0}}</div></div></div>',
 '[{"label":"Open file","real_url":"http://sharepointonline-files.com/share/view?id=a9f3c2","suspicious":true,"warning":"This is not a Microsoft link. The domain sharepointonline-files.com is fake. You will be taken to a fake login page to steal your Microsoft password."}]'::jsonb,
 TRUE,
 '["The sender domain sharepointonline-files.com is not Microsoft — the real one is @sharepointonline.com","A genuine SharePoint invitation opens the file directly — you are never asked to log in again","The link points to sharepointonline-files.com rather than sharepoint.com or microsoft.com","Always check sharing invitations via Microsoft 365 directly, not through an email link"]'::jsonb,
 '[]'::jsonb,
 'This is phishing. The sender domain sharepointonline-files.com closely resembles the real Microsoft domain but is fake. The link leads to a false Microsoft login page designed to steal your work password. Genuine SharePoint invitations always come from @sharepointonline.com and open the file without requiring you to log in again.',
 210, 'advanced'),
('fr', 'business',
 'Microsoft SharePoint',
 'no-reply@sharepointonline-files.com',
 'Le domaine est sharepointonline-files.com — pas sharepointonline.com. Microsoft envoie toujours les invitations depuis @sharepointonline.com.',
 'aujourd''hui 14:22',
 'Vandenberghe Koen a partagé un fichier avec vous',
 'Vandenberghe Koen vous a invité(e) à modifier ‘Grilles_Salaires_Primes_2026_FR’.',
 E'<div class="ol-share-card"><div class="ol-share-head"><div class="ol-share-icon">⤴</div><h2 class="ol-share-heading">Vandenberghe Koen vous a invité(e) à modifier un fichier</h2></div><div class="ol-share-body"><p class="ol-share-msg">« Confidentiel — à relire par les RH et la direction. Merci de me faire part de vos retours avant lundi. »</p><p class="ol-share-intro">Voici le fichier que Vandenberghe Koen a partagé avec vous.</p><div class="ol-share-file"><span class="ol-share-file-ico">📄</span><span class="ol-share-file-name">Grilles_Salaires_Primes_2026_FR.xlsx</span></div><p class="ol-share-protection">🔒 Cette invitation ne fonctionne que pour vous et les personnes ayant déjà accès.</p><div class="ol-share-actions">{{link:0}}</div></div></div>',
 '[{"label":"Ouvrir le fichier","real_url":"http://sharepointonline-files.com/share/view?id=a9f3c2","suspicious":true,"warning":"Ce lien ne provient pas de Microsoft. Le domaine sharepointonline-files.com est frauduleux. Vous serez redirigé(e) vers une fausse page de connexion Microsoft pour vous voler votre mot de passe."}]'::jsonb,
 TRUE,
 '["Le domaine expéditeur sharepointonline-files.com n''est pas Microsoft — le vrai est @sharepointonline.com","Une vraie invitation SharePoint ouvre directement le fichier — on ne vous demande jamais de vous reconnecter","Le lien pointe vers sharepointonline-files.com et non vers sharepoint.com ou microsoft.com","Vérifiez toujours les invitations de partage directement via Microsoft 365, pas via un lien e-mail"]'::jsonb,
 '[]'::jsonb,
 'Il s''agit de phishing. Le domaine sharepointonline-files.com ressemble fortement au vrai domaine Microsoft, mais il est frauduleux. Le lien mène vers une fausse page de connexion Microsoft conçue pour voler votre mot de passe professionnel. Les vraies invitations SharePoint viennent toujours de @sharepointonline.com et ouvrent le fichier sans nouvelle connexion.',
 210, 'advanced'),
('de', 'business',
 'Microsoft SharePoint',
 'no-reply@sharepointonline-files.com',
 'Die Domain lautet sharepointonline-files.com — nicht sharepointonline.com. Microsoft versendet Einladungen immer über @sharepointonline.com.',
 'heute 14:22',
 'Vandenberghe Koen hat eine Datei mit Ihnen geteilt',
 'Vandenberghe Koen hat Sie eingeladen, ‘Gehaltstabellen_und_Praemien_2026_DE’ zu bearbeiten.',
 E'<div class="ol-share-card"><div class="ol-share-head"><div class="ol-share-icon">⤴</div><h2 class="ol-share-heading">Vandenberghe Koen hat Sie eingeladen, eine Datei zu bearbeiten</h2></div><div class="ol-share-body"><p class="ol-share-msg">„Vertraulich — zur Durchsicht für HR und Management. Feedback bitte bis Montag."</p><p class="ol-share-intro">Dies ist die Datei, die Vandenberghe Koen mit Ihnen geteilt hat.</p><div class="ol-share-file"><span class="ol-share-file-ico">📄</span><span class="ol-share-file-name">Gehaltstabellen_und_Praemien_2026_DE.xlsx</span></div><p class="ol-share-protection">🔒 Diese Einladung funktioniert nur für Sie und Personen mit bestehendem Zugriff.</p><div class="ol-share-actions">{{link:0}}</div></div></div>',
 '[{"label":"Datei öffnen","real_url":"http://sharepointonline-files.com/share/view?id=a9f3c2","suspicious":true,"warning":"Dies ist kein Microsoft-Link. Die Domain sharepointonline-files.com ist gefälscht. Sie werden auf eine gefälschte Microsoft-Anmeldeseite weitergeleitet, um Ihr Passwort zu stehlen."}]'::jsonb,
 TRUE,
 '["Die Absender-Domain sharepointonline-files.com gehört nicht zu Microsoft — die echte ist @sharepointonline.com","Eine echte SharePoint-Einladung öffnet die Datei direkt — Sie werden nie aufgefordert, sich erneut anzumelden","Der Link zeigt auf sharepointonline-files.com statt auf sharepoint.com oder microsoft.com","Überprüfen Sie Freigabe-Einladungen immer direkt über Microsoft 365, nicht über einen E-Mail-Link"]'::jsonb,
 '[]'::jsonb,
 'Dies ist Phishing. Die Domain sharepointonline-files.com ähnelt der echten Microsoft-Domain stark, ist aber gefälscht. Der Link führt auf eine gefälschte Microsoft-Anmeldeseite, die Ihr Arbeitspasswort stehlen soll. Echte SharePoint-Einladungen kommen immer von @sharepointonline.com und öffnen die Datei ohne erneute Anmeldung.',
 210, 'advanced');

-- nl-BE copy
INSERT INTO inbox_messages
  (locale, audience, sender_name, sender_address, sender_note, received_label,
   subject, preview, body, links, is_phishing, red_flags, green_flags,
   explanation, sort_order, difficulty)
SELECT 'nl-BE', audience, sender_name, sender_address, sender_note, received_label,
       subject, preview, body, links, is_phishing, red_flags, green_flags,
       explanation, sort_order, difficulty
FROM inbox_messages
WHERE locale = 'nl' AND difficulty = 'advanced' AND sort_order = 210;

-- fr-BE copy
INSERT INTO inbox_messages
  (locale, audience, sender_name, sender_address, sender_note, received_label,
   subject, preview, body, links, is_phishing, red_flags, green_flags,
   explanation, sort_order, difficulty)
SELECT 'fr-BE', audience, sender_name, sender_address, sender_note, received_label,
       subject, preview, body, links, is_phishing, red_flags, green_flags,
       explanation, sort_order, difficulty
FROM inbox_messages
WHERE locale = 'fr' AND difficulty = 'advanced' AND sort_order = 210;

-- ============================================================
-- ZAKELIJK GEVORDERD (audience='business', difficulty='advanced')
-- Subtiele phishing gericht op werknemers: Microsoft-licenties,
-- VPN-certificaten, DocuSign, IBAN-fraude + 2 echte berichten.
-- ============================================================

INSERT INTO inbox_messages
  (locale, audience, sender_name, sender_address, sender_note, received_label,
   subject, preview, body, links, is_phishing, red_flags, green_flags,
   explanation, sort_order, difficulty)
VALUES

-- 1. PHISHING — Microsoft 365 licentie
('nl', 'business',
 'Microsoft 365 Licenties',
 'licenties@microsoft365-zakelijk.com',
 'microsoft365-zakelijk.com is geen Microsoft-domein. Officieel licentiebeheer gaat via admin.microsoft.com.',
 'vandaag 09:44',
 'Actie vereist: uw Microsoft 365 Business-licentie voor kestrel.nl verloopt over 5 dagen',
 'Beste beheerder, uw Microsoft 365 Business Standard-abonnement voor tenant kestrel.nl verloopt...',
 E'<div class="eml fam-tech" style="--brand:#0067b8;--cta:#0067b8"><div class="eml-top"><span class="eml-logo">Microsoft 365</span></div><div class="eml-body"><p class="eml-h">Uw abonnement verloopt over 5 dagen</p><p>Beste IT-beheerder,</p><p>Uw Microsoft 365 Business Standard-abonnement voor de tenant <strong>kestrel.nl</strong> verloopt op 15 juni 2026. Na het verlopen hebben uw medewerkers geen toegang meer tot Outlook, Teams en SharePoint.</p><div class="eml-cta" style="--cta:#0067b8">{{link:0}}</div><p>De verlenging duurt minder dan 5 minuten.</p></div><div class="eml-foot"><p>Microsoft Corporation, One Microsoft Way, Redmond, WA 98052</p><p>U ontvangt dit bericht als beheerder van de tenant kestrel.nl.</p></div></div>',
 '[{"label":"Licentie verlengen","real_url":"http://microsoft365-zakelijk.com/verlengen?tenant=kestrel.nl","suspicious":true,"warning":"microsoft365-zakelijk.com is geen Microsoft-domein. Echte Microsoft-facturering gaat via admin.microsoft.com of microsoft.com."}]'::jsonb,
 TRUE,
 '["microsoft365-zakelijk.com is geen Microsoft-domein — officieel is microsoft.com of admin.microsoft.com","Verlengingsherinneringen staan in het Microsoft 365 Admin Center, nooit als externe link per e-mail","Tijdsdruk (5 dagen) en vermelding van uw eigen tenantnaam om legitiem te lijken","Microsoft stuurt geen e-mails met externe links voor licentieverlenging"]'::jsonb,
 '[]'::jsonb,
 'Dit is phishing. Verlengingen van Microsoft 365-licenties beheer u altijd via het officiële Microsoft 365 Admin Center (admin.microsoft.com). Microsoft stuurt geen e-mails met externe links om licenties te verlengen. Log altijd direct in op admin.microsoft.com — nooit via een link in een e-mail.',
 220, 'advanced'),

-- 2. PHISHING — Nep VPN-certificaat IT-mail
('nl', 'business',
 'IT-Security Kestrel',
 'it-security@kestrel-access.nl',
 'Let op: kestrel-access.nl is NIET kestrel.nl. Een extra woord of koppelstreepje maakt het verschil.',
 'vandaag 11:17',
 'Verplicht: vernieuwen van uw Cisco AnyConnect VPN-certificaat — kestrel.nl',
 'Beste collega, uw Cisco AnyConnect VPN-certificaat voor de kestrel.nl-omgeving verloopt morgen...',
 E'Beste collega,\n\nUw Cisco AnyConnect VPN-certificaat voor de kestrel.nl-omgeving verloopt morgen. Zonder verlenging kunt u niet meer via VPN inloggen op het netwerk.\n\nVernieuwen duurt 2 minuten en gaat volledig automatisch. Klik op de onderstaande link en log in met uw kestrel.nl-account.\n\n{{link:0}}\n\nHeeft u vragen? Neem contact op met de helpdesk via helpdesk@kestrel.nl.\n\nMet vriendelijke groet,\nIT-Security Team — Kestrel',
 '[{"label":"Certificaat verlengen","real_url":"http://kestrel-access.nl/vpn-renew","suspicious":true,"warning":"kestrel-access.nl is niet kestrel.nl. Dit is een nep-IT-domein dat sterk op het interne domein lijkt."}]'::jsonb,
 TRUE,
 '["Afzender gebruikt kestrel-access.nl, niet kestrel.nl — let op het verschil","VPN-certificaten verlopen nooit binnen 24 uur zonder langere waarschuwing via het IT-systeem","De echte IT-helpdesk communiceert via Teams of intranet, niet via zo''n e-mail met externe link","Controleer bij twijfel altijd via de officiële helpdesk (helpdesk@kestrel.nl), nooit via de link in een verdachte mail"]'::jsonb,
 '[]'::jsonb,
 'Dit is phishing. Het afzenderdomein kestrel-access.nl lijkt sterk op kestrel.nl maar is het niet. VPN-certificaten worden beheerd door uw IT-afdeling. Neem bij twijfel altijd telefonisch of via Teams contact op met de helpdesk.',
 230, 'advanced'),

-- 3. PHISHING — DocuSign nep-uitnodiging
('nl', 'business',
 'DocuSign Electronic Signature',
 'dse@docusign-notification.com',
 'Echte DocuSign-meldingen komen van @docusign.net. docusign-notification.com is nep.',
 'gisteren 14:38',
 'Maarten de Graaf heeft een document ter ondertekening naar u gestuurd via DocuSign',
 'Maarten de Graaf (Directeur, Kestrel NV) heeft u uitgenodigd om de Verwerkersovereenkomst AVG te ondertekenen...',
 E'<div class="eml fam-tech" style="--brand:#191823;--cta:#191823"><div class="eml-top"><span class="eml-logo">DocuSign</span></div><div class="eml-body"><p class="eml-h">Maarten de Graaf heeft een document naar u gestuurd</p><p>Maarten de Graaf (Directeur, Kestrel NV) nodigt u uit om het volgende document te bekijken en te ondertekenen:</p><p><strong>Verwerkersovereenkomst AVG 2026 — Kestrel NV</strong><br>Deadline voor ondertekening: 20 juni 2026</p><div class="eml-cta" style="--cta:#ffc820;--cta-ink:#191823">{{link:0}}</div><p>Heeft u vragen over dit document? Neem contact op met Maarten de Graaf.</p></div><div class="eml-foot"><p>Dit is een automatisch bericht van DocuSign Electronic Signature Service.</p><p>Do Not Share This Email: deze e-mail bevat een beveiligde link.</p></div></div>',
 '[{"label":"Document bekijken en ondertekenen","real_url":"http://docusign-notification.com/sign?token=abc123xyz","suspicious":true,"warning":"Echte DocuSign-uitnodigingen komen van @docusign.net, niet van docusign-notification.com. Log in op docusign.com om te zien of het document daar staat."}]'::jsonb,
 TRUE,
 '["docusign-notification.com is geen DocuSign-domein — het echte is @docusign.net","Vermeldt een bekende collega en plausibel document (AVG-verwerkersovereenkomst) om vertrouwen te wekken","Log in op docusign.com om te controleren of het document daar werkelijk staat","Bij twijfel: bel de afzender op zijn bekende nummer — nooit via het nummer in de mail"]'::jsonb,
 '[]'::jsonb,
 'Dit is phishing. Echte DocuSign-uitnodigingen worden verstuurd via @docusign.net. U kunt ook zelf inloggen op docusign.com om te zien welke documenten op u wachten. Bel de afzender altijd buiten de e-mail om ter verificatie.',
 240, 'advanced'),

-- 4. PHISHING — IBAN-fraude leverancier
('nl', 'business',
 'Administratie Vertexron NV',
 'admin@vertexron-group.nl',
 'Controleer bij IBAN-wijzigingen altijd het bekende telefoonnummer van uw leverancier — nooit het nummer uit de mail.',
 'gisteren 16:02',
 'Bijgewerkte betaalgegevens — factuur V2026-0142 (€9.240,00)',
 'Geachte relatie, wegens een wisseling van bankrelatie hebben wij een nieuw IBAN voor betalingen...',
 E'Geachte relatie,\n\nPer 1 mei 2025 zijn wij overgestapt naar een andere bankrelatie. Onze betaalgegevens zijn daardoor gewijzigd.\n\nWij verzoeken u vriendelijk om bij de betaling van factuur V2026-0142 (€9.240,00) het nieuwe IBAN te gebruiken:\n\nNieuw IBAN: NL58 INGB 0002 3456 78\nTen name van: Vertexron NV\n\nOns oude bankrekeningnummer is niet langer actief. Betalingen naar het oude nummer worden niet meer bijgeschreven.\n\nHeeft u vragen? U kunt ons bereiken via admin@vertexron-group.nl of op 020-7654321.\n\nMet vriendelijke groet,\nAdministratie Vertexron NV',
 '[]'::jsonb,
 TRUE,
 '["IBAN-wijzigingen per e-mail zijn een klassieke betaalfraude — bel altijd het bekende nummer van uw leverancier ter verificatie","Gebruik nooit het telefoonnummer uit de e-mail zelf — dat kan ook nep zijn","Controleer of het afzenderdomein overeenkomt met wat u gewend bent van deze leverancier","Legitieme IBAN-wijzigingen gaan gepaard met officieel briefpapier, niet alleen een e-mail"]'::jsonb,
 '[]'::jsonb,
 'Dit is IBAN-fraude (ook wel CEO-fraude of BEC-fraude). Oplichters doen zich voor als een bekende leverancier en vragen om betalingen naar een nieuw rekeningnummer over te maken. Bel de leverancier altijd op hun bekende nummer om een IBAN-wijziging te bevestigen. Gebruik nooit contactgegevens uit de e-mail zelf.',
 250, 'advanced'),

-- 5. ECHT — HR nieuwe cao akkoordverklaring
('nl', 'business',
 'HR Kestrel',
 'hr@kestrel.nl',
 'Het adres @kestrel.nl is het officiële interne domein. Dit is een legitieme HR-mededeling.',
 'vandaag 08:30',
 'Actie vereist: digitale akkoordverklaring nieuwe cao — deadline 15 juni',
 'Beste collega, in het kader van de nieuwe cao ontvangen alle medewerkers een akkoordverklaring ter ondertekening...',
 E'Beste collega,\n\nIn het kader van de nieuwe cao voor 2025-2026 ontvangen alle medewerkers een persoonlijk document ter akkoordverklaring. Wij vragen u om uiterlijk 15 juni 2025 uw digitale handtekening te plaatsen.\n\nU ontvangt een DocuSign-uitnodiging op uw zakelijke e-mailadres. Verwacht deze van no-reply@docusign.net.\n\nHeeft u de uitnodiging na 48 uur nog niet ontvangen? Neem dan contact met ons op via hr@kestrel.nl of kom langs bij HR op de 3e verdieping.\n\nVragen over de nieuwe cao vindt u op het intranet onder HR → Arbeidsvoorwaarden 2025.\n\nMet vriendelijke groet,\nHR Kestrel',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Afzender @kestrel.nl is het officiële interne domein","Geen directe kliklink — DocuSign-uitnodiging volgt apart van @docusign.net","Verwijst naar HR-afdeling en intranet als verificatiebron","Concrete, verifieerbare context (nieuwe cao, deadline 15 juni)"]'::jsonb,
 'Dit is een echte HR-mededeling. Let op: er zit geen klikbare link in deze e-mail — de DocuSign-uitnodiging volgt apart via @docusign.net. De afzender gebruikt het interne @kestrel.nl-domein. Tip: koppel dit bericht aan het vorige (DocuSign-phishing) — zo ziet u hoe een echte uitnodiging eruitziet versus een nep-DocuSign-mail.',
 260, 'advanced'),

-- 6. ECHT — Microsoft Teams dagelijks digest
('nl', 'business',
 'Microsoft Teams',
 'no-reply@email.teams.microsoft.com',
 'Het domein @email.teams.microsoft.com is het officiële Microsoft Teams-notificatiedomein.',
 'vandaag 07:01',
 'U heeft 4 gemiste berichten in Teams — dagelijkse samenvatting',
 'U heeft nieuwe berichten in de kanalen Algemeen, IT-Helpdesk en Project Alpha van kestrel.nl...',
 E'<div class="eml fam-tech" style="--brand:#464eb8;--cta:#464eb8"><div class="eml-top"><span class="eml-logo">Microsoft Teams</span></div><div class="eml-body"><p>Goedemorgen,</p><p>U heeft vandaag 4 gemiste berichten in Microsoft Teams:</p><p>• Kanaal Algemeen: "Vergaderverzoek: teamoverleg dinsdag 10:00" – Lisa Janssen<br>• Kanaal IT-Helpdesk: "Reminder: VPN-update this week" – IT Kestrel<br>• Kanaal Project Alpha: "Feedback gevraagd op voorstel v3" – Karim Benali<br>• Privéberichten: 1 ongelezen bericht van Sofie de Groot</p><p>Open Teams om te reageren, of ga naar teams.microsoft.com.</p><p>U kunt de frequentie van deze samenvattingen aanpassen via uw Teams-instellingen.</p><p>Microsoft Teams</p></div><div class="eml-foot"><p>Dit is een automatisch verzonden bericht — antwoorden is niet mogelijk.</p><p>© 2026 Microsoft Teams</p></div></div>',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Afzender @email.teams.microsoft.com is het officiële domein voor Teams-notificaties","Geen inloglink of betaalverzoek — u wordt gevraagd zelf Teams te openen","Concrete berichten van bekende collega''s die passen bij normaal werkgebruik","Verwijst naar teams.microsoft.com — een bekend officieel Microsoft-domein"]'::jsonb,
 'Dit is een echte Teams-digestmelding. Microsoft verstuurt samenvattingen via @email.teams.microsoft.com. Let op: er is geen inloglink — u wordt gevraagd zelf Teams te openen. Echte Teams-meldingen bevatten geen verdachte externe links.',
 270, 'advanced');

-- Kopieer nieuwe zakelijke geavanceerde berichten naar nl-BE
INSERT INTO inbox_messages
  (locale, audience, sender_name, sender_address, sender_note, received_label,
   subject, preview, body, links, is_phishing, red_flags, green_flags,
   explanation, sort_order, difficulty)
SELECT 'nl-BE', audience, sender_name, sender_address, sender_note, received_label,
       subject, preview, body, links, is_phishing, red_flags, green_flags,
       explanation, sort_order, difficulty
FROM inbox_messages
WHERE locale = 'nl' AND difficulty = 'advanced' AND audience = 'business'
  AND sort_order BETWEEN 220 AND 270
ON CONFLICT DO NOTHING;

-- ============================================================
-- Herstel audience: consumentgerichte geavanceerde berichten
-- worden 'personal' zodat zakelijke trainingen zakelijk blijven.
-- ============================================================
UPDATE inbox_messages
SET audience = 'personal'
WHERE difficulty = 'advanced'
  AND audience = 'both'
  AND sender_name IN (
    'Rabobank', 'PostNL', 'ABN AMRO', 'bol.com', 'DHL', 'Apple', 'Coolblue',
    'NS Klantenservice', 'Royal Mail', 'Spotify', 'PayPal', 'Volksbank',
    'HM Revenue & Customs'
  );

-- ============================================================
-- QR-code phishing (quishing) — actueel aanvalspatroon dat in
-- de oorspronkelijke seed ontbrak. QR-codes in e-mail zijn niet
-- te controleren vóór het scannen: belangrijke les.
-- ============================================================

INSERT INTO inbox_messages
  (locale, audience, sender_name, sender_address, sender_note, received_label,
   subject, preview, body, links, is_phishing, red_flags, green_flags,
   explanation, sort_order, difficulty) VALUES

-- ZAKELIJK — nep-MFA-herregistratie via QR-code
('nl', 'business',
 'Microsoft Authenticator',
 'mfa-verificatie@microsoft-device-check.com',
 'Het echte Microsoft-domein is microsoft.com. "microsoft-device-check.com" is nep — en Microsoft vraagt nooit via e-mail om een QR-code te scannen.',
 'vandaag 08:47',
 'Actie vereist: herregistreer uw Authenticator vóór vrijdag',
 'Uw Microsoft Authenticator-koppeling verloopt. Scan de QR-code om opnieuw te registreren...',
 E'<div class="eml fam-tech" style="--brand:#0067b8;--cta:#0067b8"><div class="eml-top"><span class="eml-logo">Microsoft Authenticator</span></div><div class="eml-body"><p class="eml-h">Herregistratie vereist vóór vrijdag</p><p>Beste medewerker,</p><p>In verband met een beveiligingsupdate verloopt de koppeling van uw Microsoft Authenticator-app aanstaande vrijdag. Om toegang tot uw account te behouden moet u uw apparaat opnieuw registreren.</p><p><strong>Scan de onderstaande QR-code met uw telefoon:</strong></p><div style="text-align:center;margin:14px 0"><img src="/qr-img/mfa" width="150" height="150" alt="QR-code" style="background:#fff;padding:10px;border:1px solid #ddd;border-radius:4px"></div><p>Kunt u de code niet scannen? {{link:0}}</p><p>Na vrijdag wordt niet-geregistreerde toegang automatisch geblokkeerd.</p></div><div class="eml-foot"><p>Microsoft Corporation, One Microsoft Way, Redmond, WA 98052</p><p>Dit is een verplichte beveiligingsmelding voor alle medewerkers.</p></div></div>',
 '[{"label":"Handmatig registreren","real_url":"http://microsoft-device-check.com/enroll?id=8842","suspicious":true,"warning":"microsoft-device-check.com is geen Microsoft-domein. Echte Authenticator-registratie verloopt via uw eigen IT-afdeling of portal.office.com — nooit via een QR-code in een e-mail."}]'::jsonb,
 TRUE,
 '["QR-code in een e-mail: u kunt niet zien waar die naartoe leidt vóór u scant","Afzender @microsoft-device-check.com — niet @microsoft.com","Tijdsdruk: \"vóór vrijdag\", \"automatisch geblokkeerd\"","Uw IT-afdeling kondigt MFA-wijzigingen aan via bekende interne kanalen, niet via een losse mail","Scannen met uw telefoon omzeilt de beveiliging van uw werkcomputer — precies wat de aanvaller wil"]'::jsonb,
 '[]'::jsonb,
 'Dit is "quishing": phishing via een QR-code. Aanvallers gebruiken QR-codes omdat e-mailfilters de link in de afbeelding niet kunnen lezen — en u ook niet. Scan nooit een QR-code uit een onverwachte e-mail. Twijfelt u over uw Authenticator? Ga zelf naar portal.office.com of vraag het uw IT-afdeling.',
 95, 'normal'),

-- PRIVÉ — nep-betaalverzoek via QR-code
('nl', 'personal',
 'Tikkie',
 'service@tikkie-betaalverzoeken.nl',
 'Tikkie (ABN AMRO) gebruikt het domein tikkie.me en stuurt betaalverzoeken via de app of sms — niet via e-mail met een QR-code.',
 'gisteren 19:22',
 'Herinnering: openstaand betaalverzoek van € 12,50',
 'Je hebt nog een openstaand Tikkie-betaalverzoek. Scan de QR-code om direct te betalen...',
 E'<div class="eml fam-pay" style="--brand:#46117d;--cta:#46117d"><div class="eml-hero"><span class="eml-logo">Tikkie</span></div><div class="eml-body"><p class="eml-h">Je hebt nog een openstaand Tikkie</p><p>Hoi!</p><p>Je hebt nog een openstaand betaalverzoek van <strong>€ 12,50</strong> van M. de Groot.</p><p>Scan de QR-code hieronder met je bank-app om direct te betalen:</p><div style="text-align:center;margin:14px 0"><img src="/qr-img/tikkie" width="150" height="150" alt="QR-code" style="background:#fff;padding:10px;border:1px solid #ddd;border-radius:4px"></div><p>Lukt het scannen niet? {{link:0}}</p><p>Dit verzoek verloopt over 24 uur.</p></div><div class="eml-foot"><p>Tikkie is een dienst van ABN AMRO Bank N.V.</p><p>Je ontvangt deze herinnering omdat het betaalverzoek nog openstaat.</p></div></div>',
 '[{"label":"Betaal via de browser","real_url":"http://tikkie-betaalverzoeken.nl/pay/8X2KQ","suspicious":true,"warning":"Het echte Tikkie-domein is tikkie.me. Dit nep-domein probeert uw bankgegevens te stelen."}]'::jsonb,
 TRUE,
 '["QR-code in een e-mail: u ziet niet waar die naartoe leidt vóór u scant","Afzender @tikkie-betaalverzoeken.nl — het echte domein is tikkie.me","Onverwacht: kent u M. de Groot? Verwachtte u een betaalverzoek?","Tijdsdruk: \"verloopt over 24 uur\"","Echte Tikkies komen via de app, sms of WhatsApp — niet via e-mail"]'::jsonb,
 '[]'::jsonb,
 'Dit is een nep-betaalverzoek met QR-code ("quishing"). Scan nooit een QR-code uit een onverwachte e-mail — uw telefoon opent dan een nep-betaalpagina die uw bankgegevens steelt. Verwacht u echt een Tikkie? Open dan zelf de app en kijk daar.',
 96, 'normal');

-- Kopieer de Authenticator-QR naar nl-BE. De Tikkie-variant NIET:
-- Belgen gebruiken Payconiq — die krijgt verderop een eigen bericht.
INSERT INTO inbox_messages
  (locale, audience, sender_name, sender_address, sender_note, received_label,
   subject, preview, body, links, is_phishing, red_flags, green_flags,
   explanation, sort_order, difficulty)
SELECT 'nl-BE', audience, sender_name, sender_address, sender_note, received_label,
       subject, preview, body, links, is_phishing, red_flags, green_flags,
       explanation, sort_order, difficulty
FROM inbox_messages
WHERE locale = 'nl' AND difficulty = 'normal' AND sort_order = 95
  AND sender_name = 'Microsoft Authenticator'
ON CONFLICT DO NOTHING;

-- ============================================================
-- Zakelijk + gevorderd voor EN/FR/DE — vertaald/gelokaliseerd
-- van de Nederlandse set (220-270). Personas: Jane/Emma Walsh
-- (kestrel.co.uk), Pierre/Claire Lambert (kestrel.fr),
-- Martin/Anna Weber (kestrel.de).
-- ============================================================

INSERT INTO inbox_messages
  (locale, audience, sender_name, sender_address, sender_note, received_label,
   subject, preview, body, links, is_phishing, red_flags, green_flags,
   explanation, sort_order, difficulty) VALUES

-- ===== EN =====

('en', 'business',
 'Microsoft 365 Licensing',
 'licensing@microsoft365-business.com',
 'Microsoft only mails from @microsoft.com. "microsoft365-business.com" is a lookalike domain.',
 'today 08:31',
 'Action required: your Microsoft 365 Business licence for kestrel.co.uk expires in 5 days',
 'Your Microsoft 365 Business Standard subscription for tenant kestrel.co.uk expires on 15 June 2026...',
 E'<div class="eml fam-tech" style="--brand:#0067b8;--cta:#0067b8"><div class="eml-top"><span class="eml-logo">Microsoft 365</span></div><div class="eml-body"><p class="eml-h">Your subscription expires in 5 days</p><p>Dear IT administrator,</p><p>Your Microsoft 365 Business Standard subscription for tenant <strong>kestrel.co.uk</strong> expires on 15 June 2026. To avoid interruption to email, Teams and OneDrive for all users, renew the licence today.</p><div class="eml-cta" style="--cta:#0067b8">{{link:0}}</div><p>If the licence lapses, all mailboxes will be set to read-only.</p></div><div class="eml-foot"><p>Microsoft Corporation, One Microsoft Way, Redmond, WA 98052</p><p>You receive this message as an administrator of tenant kestrel.co.uk.</p></div></div>',
 '[{"label":"Renew licence","real_url":"http://microsoft365-business.com/renew?tenant=kestrel","suspicious":true,"warning":"microsoft365-business.com is not a Microsoft domain. Licence management happens in the Microsoft 365 admin center (admin.microsoft.com) — never via a link in an email."}]'::jsonb,
 TRUE,
 '["Sender @microsoft365-business.com — Microsoft mails from @microsoft.com","Time pressure: \"expires in 5 days\", \"read-only\"","Licence renewal happens in the admin center, not via email links","Addressed to \"IT administrator\" — generic, not a name","Threatens consequences for all colleagues to add pressure"]'::jsonb,
 '[]'::jsonb,
 'This is licence-expiry phishing aimed at businesses. Microsoft sends billing notices from @microsoft.com and renewal happens inside admin.microsoft.com. In doubt? Open the admin center yourself or ask your IT department — never use the link in the email.',
 220, 'advanced'),

('en', 'business',
 'IT Security Kestrel',
 'it-security@kestrel-access.co.uk',
 'Watch closely: kestrel-access.co.uk is NOT kestrel.co.uk. An extra word with a hyphen makes it a different domain.',
 'today 07:58',
 'Mandatory: renew your Cisco AnyConnect VPN certificate — kestrel.co.uk',
 'Your VPN certificate expires within 24 hours. Renew it now to keep remote access...',
 E'Dear colleague,\n\nAs part of our security maintenance, the VPN certificates of all employees are being renewed. Our records show your certificate expires within 24 hours.\n\nWithout a valid certificate you will lose remote access to the Kestrel network.\n\nRenew your certificate here:\n\n{{link:0}}\n\nThis takes less than two minutes.\n\nIT Security\nKestrel',
 '[{"label":"Renew certificate","real_url":"http://kestrel-access.co.uk/vpn-renew","suspicious":true,"warning":"kestrel-access.co.uk is not kestrel.co.uk. This is a fake IT domain that closely mimics the internal one."}]'::jsonb,
 TRUE,
 '["Sender uses kestrel-access.co.uk, not kestrel.co.uk — spot the difference","VPN certificates never expire within 24 hours without earlier warning through IT systems","The real IT helpdesk communicates via Teams or the intranet, not via an email with an external link","In doubt, always check with the official helpdesk (helpdesk@kestrel.co.uk), never via a link in a suspicious email"]'::jsonb,
 '[]'::jsonb,
 'This is phishing. The sender domain kestrel-access.co.uk closely resembles kestrel.co.uk but is not the same. VPN certificates are managed by your IT department. In doubt, contact the helpdesk by phone or Teams.',
 230, 'advanced'),

('en', 'business',
 'DocuSign Electronic Signature',
 'dse@docusign-notification.com',
 'Real DocuSign mail comes from @docusign.net or @docusign.com. "docusign-notification.com" is fake.',
 'yesterday 16:20',
 'Oliver Hughes has sent you a document to sign via DocuSign',
 'Please review and sign: Supplier_Agreement_Kestrel_2026.pdf...',
 E'<div class="eml fam-tech" style="--brand:#191823;--cta:#191823"><div class="eml-top"><span class="eml-logo">DocuSign</span></div><div class="eml-body"><p class="eml-h">Oliver Hughes has sent you a document</p><p>Oliver Hughes (procurement@kestrel.co.uk) has sent you a document to review and sign:</p><p><strong>Supplier_Agreement_Kestrel_2026.pdf</strong><br>Please sign before Friday — the agreement must be returned to the supplier this week.</p><div class="eml-cta" style="--cta:#ffc820;--cta-ink:#191823">{{link:0}}</div></div><div class="eml-foot"><p>This is an automated message from DocuSign Electronic Signature Service.</p><p>Do Not Share This Email: this email contains a secure link.</p></div></div>',
 '[{"label":"Review document","real_url":"http://docusign-notification.com/sign?d=99412","suspicious":true,"warning":"Real DocuSign links go to docusign.net or docusign.com. This domain is fake — it will show a fake login page to steal your credentials."}]'::jsonb,
 TRUE,
 '["Sender @docusign-notification.com — real DocuSign mails from @docusign.net or @docusign.com","Were you expecting a contract to sign? Unexpected signing requests are a classic trick","Time pressure: \"before Friday\"","The \"sender\" Oliver Hughes is named in the body, but the mail does not come from him or from Kestrel","Hover over the link: it does not go to docusign.net"]'::jsonb,
 '[]'::jsonb,
 'This is DocuSign phishing — very common in businesses. The fake signing page steals your work password. Expecting a real document? Open docusign.com yourself or check with the colleague named in the email.',
 240, 'advanced'),

('en', 'business',
 'Accounts — Vertexron Ltd',
 'accounts@vertexron-group.com',
 'A supplier suddenly announcing new bank details by email is THE signature of invoice fraud — verify by phone.',
 'yesterday 11:47',
 'Updated payment details — invoice V2026-0142 (£8,140.00)',
 'Please note our updated bank details for the open invoice V2026-0142...',
 E'Dear accounts payable team,\n\nDue to a change of bank we kindly ask you to pay open invoice V2026-0142 (£8,140.00, due this week) to our updated account:\n\nIBAN: GB29 NWBK 6016 1331 9268 19\nName: Vertexron Group Ltd\n\nAll future invoices should also be paid to this account. The old account is no longer in use.\n\nKind regards,\nS. Mason\nAccounts, Vertexron Ltd',
 '[]'::jsonb,
 TRUE,
 '["New bank details announced by email — the classic pattern of invoice fraud","Pressure: the invoice is \"due this week\"","No phone number to verify — fraudsters avoid verification channels","Sender domain vertexron-group.com differs subtly from the supplier you know","Always verify changed bank details by PHONE using the number you already have on file"]'::jsonb,
 '[]'::jsonb,
 'This is invoice fraud (also known as supplier fraud or BEC). Criminals intercept or imitate a real supplier relationship and announce "new bank details". Always verify a change of account by phone with your known contact — never via the email itself.',
 250, 'advanced'),

('en', 'business',
 'HR Kestrel',
 'hr@kestrel.co.uk',
 'Our own domain @kestrel.co.uk — correct. HR announcements like this go through internal channels.',
 '2 days ago 09:00',
 'Action required: acknowledge the updated employment terms — deadline 15 June',
 'The updated employee handbook takes effect on 1 July. Please acknowledge it via MyKestrel before 15 June...',
 E'Dear colleague,\n\nThe updated employment terms (handbook 2026) take effect on 1 July. All employees are asked to read and acknowledge them digitally.\n\nHow to do it:\n• Go to MyKestrel (you know the address from the intranet)\n• Open "My documents" → "Handbook 2026"\n• Click "Acknowledge" after reading\n\nDeadline: 15 June. Questions? Walk by HR or ask via the intranet.\n\nWe deliberately do not include a direct link — you know where to find MyKestrel.\n\nKind regards,\nHR Kestrel',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Sender @kestrel.co.uk — the official internal domain","Deliberately NO link: you are asked to navigate to MyKestrel yourself","Concrete, plausible HR context with a reasonable deadline","Refers to known internal channels (intranet, HR)","No request for passwords or personal data"]'::jsonb,
 'This is a real internal HR announcement. Note the safest pattern there is: no link at all — you are asked to open the known internal portal yourself. That is exactly how phishing-resistant communication works.',
 260, 'advanced'),

('en', 'business',
 'Microsoft Teams',
 'no-reply@email.teams.microsoft.com',
 'Real Teams notifications come from @email.teams.microsoft.com — correct.',
 '2 days ago 17:30',
 'You have 4 missed messages in Teams — daily digest',
 'Emma Walsh: "Are you joining the stand-up tomorrow?" and 3 other messages...',
 E'<div class="eml fam-tech" style="--brand:#464eb8;--cta:#464eb8"><div class="eml-top"><span class="eml-logo">Microsoft Teams</span></div><div class="eml-body"><p>You have missed messages in Microsoft Teams.</p><p>Emma Walsh (Project North): "Are you joining the stand-up tomorrow at 9:15?"<br>Team Procurement: 2 new messages in "Supplier review Q3"<br>Mark Reed: "The updated budget is on the share, can you take a look?"</p><p>Open Teams on your computer or phone to read and reply.</p><p>Microsoft Teams<br>You receive this digest because of your notification settings.</p></div><div class="eml-foot"><p>This is an automated message — please do not reply.</p><p>© 2026 Microsoft Teams</p></div></div>',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Sender @email.teams.microsoft.com is the official Teams notification domain","No login link or payment request — you are asked to open Teams yourself","Concrete messages from known colleagues matching normal work","Refers to teams.microsoft.com — a well-known official Microsoft domain"]'::jsonb,
 'This is a real Teams digest notification. Microsoft sends summaries from @email.teams.microsoft.com. Note: there is no login link — you are asked to open Teams yourself. Real Teams notifications contain no suspicious external links.',
 270, 'advanced'),

-- ===== FR =====

('fr', 'business',
 'Licences Microsoft 365',
 'licences@microsoft365-entreprise.com',
 'Microsoft n''écrit que depuis @microsoft.com. « microsoft365-entreprise.com » est un domaine imité.',
 'aujourd''hui 08:31',
 'Action requise : votre licence Microsoft 365 Business pour kestrel.fr expire dans 5 jours',
 'Votre abonnement Microsoft 365 Business Standard pour le tenant kestrel.fr expire le 15 juin 2026...',
 E'<div class="eml fam-tech" style="--brand:#0067b8;--cta:#0067b8"><div class="eml-top"><span class="eml-logo">Microsoft 365</span></div><div class="eml-body"><p class="eml-h">Votre abonnement expire dans 5 jours</p><p>Cher administrateur informatique,</p><p>Votre abonnement Microsoft 365 Business Standard pour le tenant <strong>kestrel.fr</strong> expire le 15 juin 2026. Pour éviter toute interruption de la messagerie, de Teams et de OneDrive pour tous les utilisateurs, renouvelez la licence aujourd''hui.</p><div class="eml-cta" style="--cta:#0067b8">{{link:0}}</div><p>Si la licence expire, toutes les boîtes mail passeront en lecture seule.</p></div><div class="eml-foot"><p>Microsoft Corporation, One Microsoft Way, Redmond, WA 98052</p><p>Vous recevez ce message en tant qu''administrateur du tenant kestrel.fr.</p></div></div>',
 '[{"label":"Renouveler la licence","real_url":"http://microsoft365-entreprise.com/renew?tenant=kestrel","suspicious":true,"warning":"microsoft365-entreprise.com n''est pas un domaine Microsoft. La gestion des licences se fait dans le centre d''administration Microsoft 365 (admin.microsoft.com) — jamais via un lien dans un e-mail."}]'::jsonb,
 TRUE,
 '["Expéditeur @microsoft365-entreprise.com — Microsoft écrit depuis @microsoft.com","Pression temporelle : « expire dans 5 jours », « lecture seule »","Le renouvellement de licence se fait dans le centre d''administration, pas via un lien","Adressé à « administrateur informatique » — générique, sans nom","Menace de conséquences pour tous les collègues pour augmenter la pression"]'::jsonb,
 '[]'::jsonb,
 'Ceci est du phishing à la licence expirée, ciblant les entreprises. Microsoft envoie les avis de facturation depuis @microsoft.com et le renouvellement se fait dans admin.microsoft.com. En cas de doute ? Ouvrez vous-même le centre d''administration ou demandez à votre service informatique.',
 220, 'advanced'),

('fr', 'business',
 'Sécurité informatique Kestrel',
 'it-security@kestrel-access.fr',
 'Regardez bien : kestrel-access.fr n''est PAS kestrel.fr. Un mot en plus avec un tiret = un autre domaine.',
 'aujourd''hui 07:58',
 'Obligatoire : renouvellement de votre certificat VPN Cisco AnyConnect — kestrel.fr',
 'Votre certificat VPN expire dans 24 heures. Renouvelez-le maintenant pour conserver l''accès à distance...',
 E'Cher collègue,\n\nDans le cadre de notre maintenance de sécurité, les certificats VPN de tous les employés sont renouvelés. Nos données indiquent que votre certificat expire dans 24 heures.\n\nSans certificat valide, vous perdrez l''accès à distance au réseau Kestrel.\n\nRenouvelez votre certificat ici :\n\n{{link:0}}\n\nCela prend moins de deux minutes.\n\nSécurité informatique\nKestrel',
 '[{"label":"Renouveler le certificat","real_url":"http://kestrel-access.fr/vpn-renew","suspicious":true,"warning":"kestrel-access.fr n''est pas kestrel.fr. C''est un faux domaine informatique qui imite de près le domaine interne."}]'::jsonb,
 TRUE,
 '["L''expéditeur utilise kestrel-access.fr, pas kestrel.fr — voyez la différence","Les certificats VPN n''expirent jamais sous 24 heures sans avertissement préalable via les systèmes informatiques","Le vrai helpdesk informatique communique via Teams ou l''intranet, pas par un e-mail avec un lien externe","En cas de doute, vérifiez toujours auprès du helpdesk officiel (helpdesk@kestrel.fr), jamais via le lien d''un e-mail suspect"]'::jsonb,
 '[]'::jsonb,
 'Ceci est du phishing. Le domaine kestrel-access.fr ressemble fortement à kestrel.fr mais n''est pas le même. Les certificats VPN sont gérés par votre service informatique. En cas de doute, contactez le helpdesk par téléphone ou Teams.',
 230, 'advanced'),

('fr', 'business',
 'DocuSign Electronic Signature',
 'dse@docusign-notification.com',
 'Les vrais e-mails DocuSign viennent de @docusign.net ou @docusign.com. « docusign-notification.com » est faux.',
 'hier 16:20',
 'Antoine Moreau vous a envoyé un document à signer via DocuSign',
 'Veuillez consulter et signer : Contrat_Fournisseur_Kestrel_2026.pdf...',
 E'<div class="eml fam-tech" style="--brand:#191823;--cta:#191823"><div class="eml-top"><span class="eml-logo">DocuSign</span></div><div class="eml-body"><p class="eml-h">Antoine Moreau vous a envoyé un document</p><p>Antoine Moreau (achats@kestrel.fr) vous a envoyé un document à consulter et à signer :</p><p><strong>Contrat_Fournisseur_Kestrel_2026.pdf</strong><br>Merci de signer avant vendredi — le contrat doit être renvoyé au fournisseur cette semaine.</p><div class="eml-cta" style="--cta:#ffc820;--cta-ink:#191823">{{link:0}}</div></div><div class="eml-foot"><p>Ceci est un message automatique de DocuSign Electronic Signature Service.</p><p>Do Not Share This Email : cet e-mail contient un lien sécurisé.</p></div></div>',
 '[{"label":"Consulter le document","real_url":"http://docusign-notification.com/sign?d=99412","suspicious":true,"warning":"Les vrais liens DocuSign mènent à docusign.net ou docusign.com. Ce domaine est faux — il affichera une fausse page de connexion pour voler vos identifiants."}]'::jsonb,
 TRUE,
 '["Expéditeur @docusign-notification.com — les vrais e-mails DocuSign viennent de @docusign.net ou @docusign.com","Attendiez-vous un contrat à signer ? Les demandes de signature inattendues sont un piège classique","Pression temporelle : « avant vendredi »","L''« expéditeur » Antoine Moreau est nommé dans le texte, mais l''e-mail ne vient ni de lui ni de Kestrel","Survolez le lien : il ne mène pas à docusign.net"]'::jsonb,
 '[]'::jsonb,
 'Ceci est du phishing DocuSign — très courant en entreprise. La fausse page de signature vole votre mot de passe professionnel. Vous attendez un vrai document ? Ouvrez vous-même docusign.com ou vérifiez auprès du collègue nommé.',
 240, 'advanced'),

('fr', 'business',
 'Comptabilité — Vertexron SARL',
 'comptabilite@vertexron-group.com',
 'Un fournisseur qui annonce soudain de nouvelles coordonnées bancaires par e-mail : LA signature de la fraude au virement — vérifiez par téléphone.',
 'hier 11:47',
 'Coordonnées de paiement mises à jour — facture V2026-0142 (9 240,00 €)',
 'Veuillez noter nos nouvelles coordonnées bancaires pour la facture ouverte V2026-0142...',
 E'Cher service comptabilité,\n\nEn raison d''un changement de banque, nous vous prions de régler la facture ouverte V2026-0142 (9 240,00 €, échéance cette semaine) sur notre nouveau compte :\n\nIBAN : FR76 3000 6000 0112 3456 7890 189\nNom : Vertexron Group SARL\n\nToutes les factures futures doivent également être réglées sur ce compte. L''ancien compte n''est plus utilisé.\n\nCordialement,\nS. Mercier\nComptabilité, Vertexron SARL',
 '[]'::jsonb,
 TRUE,
 '["Nouvelles coordonnées bancaires annoncées par e-mail — le schéma classique de la fraude au virement","Pression : la facture « échoit cette semaine »","Aucun numéro de téléphone pour vérifier — les fraudeurs évitent les canaux de vérification","Le domaine vertexron-group.com diffère subtilement du fournisseur que vous connaissez","Vérifiez toujours un changement de RIB par TÉLÉPHONE au numéro déjà connu"]'::jsonb,
 '[]'::jsonb,
 'Ceci est une fraude au virement (fraude au fournisseur). Des criminels imitent une relation fournisseur réelle et annoncent de « nouvelles coordonnées bancaires ». Vérifiez toujours un changement de compte par téléphone avec votre contact connu — jamais via l''e-mail lui-même.',
 250, 'advanced'),

('fr', 'business',
 'RH Kestrel',
 'rh@kestrel.fr',
 'Notre propre domaine @kestrel.fr — correct. Ce type d''annonce RH passe par les canaux internes.',
 'il y a 2 jours 09:00',
 'Action requise : validation du nouvel accord d''entreprise — échéance 15 juin',
 'Le nouvel accord d''entreprise entre en vigueur le 1er juillet. Validez-le via MonKestrel avant le 15 juin...',
 E'Cher collègue,\n\nLe nouvel accord d''entreprise (édition 2026) entre en vigueur le 1er juillet. Tous les employés sont invités à le lire et à le valider numériquement.\n\nComment faire :\n• Allez sur MonKestrel (vous connaissez l''adresse via l''intranet)\n• Ouvrez « Mes documents » → « Accord 2026 »\n• Cliquez sur « Valider » après lecture\n\nÉchéance : le 15 juin. Des questions ? Passez voir les RH ou demandez via l''intranet.\n\nNous n''incluons volontairement pas de lien direct — vous savez où trouver MonKestrel.\n\nCordialement,\nRH Kestrel',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Expéditeur @kestrel.fr — le domaine interne officiel","Volontairement AUCUN lien : on vous demande d''aller vous-même sur MonKestrel","Contexte RH concret et plausible avec une échéance raisonnable","Renvoie aux canaux internes connus (intranet, RH)","Aucune demande de mot de passe ou de données personnelles"]'::jsonb,
 'Ceci est une vraie annonce RH interne. Notez le schéma le plus sûr qui existe : aucun lien — on vous demande d''ouvrir vous-même le portail interne connu. C''est exactement ainsi que fonctionne une communication résistante au phishing.',
 260, 'advanced'),

('fr', 'business',
 'Microsoft Teams',
 'no-reply@email.teams.microsoft.com',
 'Les vraies notifications Teams viennent de @email.teams.microsoft.com — correct.',
 'il y a 2 jours 17:30',
 'Vous avez 4 messages manqués dans Teams — résumé quotidien',
 'Claire Lambert : « Tu participes au stand-up demain ? » et 3 autres messages...',
 E'<div class="eml fam-tech" style="--brand:#464eb8;--cta:#464eb8"><div class="eml-top"><span class="eml-logo">Microsoft Teams</span></div><div class="eml-body"><p>Vous avez des messages manqués dans Microsoft Teams.</p><p>Claire Lambert (Projet Nord) : « Tu participes au stand-up demain à 9h15 ? »<br>Équipe Achats : 2 nouveaux messages dans « Revue fournisseurs T3 »<br>Marc Renaud : « Le budget mis à jour est sur le partage, tu peux jeter un œil ? »</p><p>Ouvrez Teams sur votre ordinateur ou votre téléphone pour lire et répondre.</p><p>Microsoft Teams<br>Vous recevez ce résumé en raison de vos paramètres de notification.</p></div><div class="eml-foot"><p>Ceci est un message automatique — merci de ne pas y répondre.</p><p>© 2026 Microsoft Teams</p></div></div>',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Expéditeur @email.teams.microsoft.com — le domaine officiel des notifications Teams","Pas de lien de connexion ni de demande de paiement — on vous invite à ouvrir Teams vous-même","Messages concrets de collègues connus correspondant au travail normal","Renvoie à teams.microsoft.com — un domaine Microsoft officiel connu"]'::jsonb,
 'Ceci est une vraie notification de résumé Teams. Microsoft envoie les résumés depuis @email.teams.microsoft.com. Notez : pas de lien de connexion — on vous demande d''ouvrir Teams vous-même. Les vraies notifications Teams ne contiennent pas de liens externes suspects.',
 270, 'advanced'),

-- ===== DE =====

('de', 'business',
 'Microsoft 365 Lizenzen',
 'lizenzen@microsoft365-geschaeftlich.com',
 'Microsoft schreibt nur von @microsoft.com. „microsoft365-geschaeftlich.com" ist eine nachgeahmte Domain.',
 'heute 08:31',
 'Aktion erforderlich: Ihre Microsoft 365 Business-Lizenz für kestrel.de läuft in 5 Tagen ab',
 'Ihr Microsoft 365 Business Standard-Abonnement für den Tenant kestrel.de läuft am 15. Juni 2026 ab...',
 E'<div class="eml fam-tech" style="--brand:#0067b8;--cta:#0067b8"><div class="eml-top"><span class="eml-logo">Microsoft 365</span></div><div class="eml-body"><p class="eml-h">Ihr Abonnement läuft in 5 Tagen ab</p><p>Sehr geehrter IT-Administrator,</p><p>Ihr Microsoft 365 Business Standard-Abonnement für den Tenant <strong>kestrel.de</strong> läuft am 15. Juni 2026 ab. Um Unterbrechungen von E-Mail, Teams und OneDrive für alle Benutzer zu vermeiden, verlängern Sie die Lizenz noch heute.</p><div class="eml-cta" style="--cta:#0067b8">{{link:0}}</div><p>Läuft die Lizenz ab, werden alle Postfächer auf schreibgeschützt gesetzt.</p></div><div class="eml-foot"><p>Microsoft Corporation, One Microsoft Way, Redmond, WA 98052</p><p>Sie erhalten diese Nachricht als Administrator des Tenants kestrel.de.</p></div></div>',
 '[{"label":"Lizenz verlängern","real_url":"http://microsoft365-geschaeftlich.com/renew?tenant=kestrel","suspicious":true,"warning":"microsoft365-geschaeftlich.com ist keine Microsoft-Domain. Lizenzverwaltung erfolgt im Microsoft 365 Admin Center (admin.microsoft.com) — nie über einen Link in einer E-Mail."}]'::jsonb,
 TRUE,
 '["Absender @microsoft365-geschaeftlich.com — Microsoft schreibt von @microsoft.com","Zeitdruck: \"läuft in 5 Tagen ab\", \"schreibgeschützt\"","Lizenzverlängerung erfolgt im Admin Center, nicht über E-Mail-Links","Anrede \"IT-Administrator\" — generisch, ohne Namen","Droht mit Folgen für alle Kollegen, um Druck aufzubauen"]'::jsonb,
 '[]'::jsonb,
 'Dies ist Lizenz-Phishing, das auf Unternehmen zielt. Microsoft versendet Abrechnungshinweise von @microsoft.com, und die Verlängerung erfolgt in admin.microsoft.com. Im Zweifel? Öffnen Sie selbst das Admin Center oder fragen Sie Ihre IT-Abteilung.',
 220, 'advanced'),

('de', 'business',
 'IT-Sicherheit Kestrel',
 'it-security@kestrel-access.de',
 'Genau hinsehen: kestrel-access.de ist NICHT kestrel.de. Ein zusätzliches Wort mit Bindestrich = eine andere Domain.',
 'heute 07:58',
 'Verpflichtend: Erneuerung Ihres Cisco AnyConnect VPN-Zertifikats — kestrel.de',
 'Ihr VPN-Zertifikat läuft in 24 Stunden ab. Erneuern Sie es jetzt, um den Fernzugriff zu behalten...',
 E'Liebe Kollegin, lieber Kollege,\n\nim Rahmen unserer Sicherheitswartung werden die VPN-Zertifikate aller Mitarbeitenden erneuert. Unseren Daten zufolge läuft Ihr Zertifikat in 24 Stunden ab.\n\nOhne gültiges Zertifikat verlieren Sie den Fernzugriff auf das Kestrel-Netzwerk.\n\nErneuern Sie Ihr Zertifikat hier:\n\n{{link:0}}\n\nDas dauert weniger als zwei Minuten.\n\nIT-Sicherheit\nKestrel',
 '[{"label":"Zertifikat erneuern","real_url":"http://kestrel-access.de/vpn-renew","suspicious":true,"warning":"kestrel-access.de ist nicht kestrel.de. Dies ist eine gefälschte IT-Domain, die der internen täuschend ähnlich sieht."}]'::jsonb,
 TRUE,
 '["Absender nutzt kestrel-access.de, nicht kestrel.de — achten Sie auf den Unterschied","VPN-Zertifikate laufen nie binnen 24 Stunden ab, ohne frühere Warnung über die IT-Systeme","Der echte IT-Helpdesk kommuniziert über Teams oder das Intranet, nicht per E-Mail mit externem Link","Im Zweifel immer beim offiziellen Helpdesk nachfragen (helpdesk@kestrel.de), nie über den Link einer verdächtigen E-Mail"]'::jsonb,
 '[]'::jsonb,
 'Dies ist Phishing. Die Absenderdomain kestrel-access.de ähnelt kestrel.de stark, ist aber nicht dieselbe. VPN-Zertifikate werden von Ihrer IT-Abteilung verwaltet. Im Zweifel kontaktieren Sie den Helpdesk telefonisch oder über Teams.',
 230, 'advanced'),

('de', 'business',
 'DocuSign Electronic Signature',
 'dse@docusign-notification.com',
 'Echte DocuSign-Mails kommen von @docusign.net oder @docusign.com. „docusign-notification.com" ist gefälscht.',
 'gestern 16:20',
 'Thomas Schneider hat Ihnen ein Dokument zur Unterschrift über DocuSign gesendet',
 'Bitte prüfen und unterschreiben: Lieferantenvertrag_Kestrel_2026.pdf...',
 E'<div class="eml fam-tech" style="--brand:#191823;--cta:#191823"><div class="eml-top"><span class="eml-logo">DocuSign</span></div><div class="eml-body"><p class="eml-h">Thomas Schneider hat Ihnen ein Dokument gesendet</p><p>Thomas Schneider (einkauf@kestrel.de) hat Ihnen ein Dokument zur Prüfung und Unterschrift gesendet:</p><p><strong>Lieferantenvertrag_Kestrel_2026.pdf</strong><br>Bitte unterschreiben Sie vor Freitag — der Vertrag muss diese Woche an den Lieferanten zurück.</p><div class="eml-cta" style="--cta:#ffc820;--cta-ink:#191823">{{link:0}}</div></div><div class="eml-foot"><p>Dies ist eine automatische Nachricht des DocuSign Electronic Signature Service.</p><p>Do Not Share This Email: Diese E-Mail enthält einen sicheren Link.</p></div></div>',
 '[{"label":"Dokument prüfen","real_url":"http://docusign-notification.com/sign?d=99412","suspicious":true,"warning":"Echte DocuSign-Links führen zu docusign.net oder docusign.com. Diese Domain ist gefälscht — sie zeigt eine falsche Anmeldeseite, um Ihre Zugangsdaten zu stehlen."}]'::jsonb,
 TRUE,
 '["Absender @docusign-notification.com — echte DocuSign-Mails kommen von @docusign.net oder @docusign.com","Haben Sie einen Vertrag zur Unterschrift erwartet? Unerwartete Signaturanfragen sind ein klassischer Trick","Zeitdruck: \"vor Freitag\"","Der \"Absender\" Thomas Schneider wird im Text genannt, aber die Mail kommt weder von ihm noch von Kestrel","Fahren Sie mit der Maus über den Link: Er führt nicht zu docusign.net"]'::jsonb,
 '[]'::jsonb,
 'Dies ist DocuSign-Phishing — in Unternehmen sehr verbreitet. Die gefälschte Signaturseite stiehlt Ihr Arbeitspasswort. Erwarten Sie ein echtes Dokument? Öffnen Sie selbst docusign.com oder fragen Sie den genannten Kollegen.',
 240, 'advanced'),

('de', 'business',
 'Buchhaltung — Vertexron GmbH',
 'buchhaltung@vertexron-group.com',
 'Ein Lieferant, der plötzlich neue Bankdaten per E-Mail mitteilt: DAS Kennzeichen von Rechnungsbetrug — telefonisch prüfen.',
 'gestern 11:47',
 'Aktualisierte Zahlungsdaten — Rechnung V2026-0142 (9.240,00 €)',
 'Bitte beachten Sie unsere neuen Bankdaten für die offene Rechnung V2026-0142...',
 E'Sehr geehrtes Buchhaltungsteam,\n\naufgrund eines Bankwechsels bitten wir Sie, die offene Rechnung V2026-0142 (9.240,00 €, fällig diese Woche) auf unser neues Konto zu überweisen:\n\nIBAN: DE89 3704 0044 0532 0130 00\nName: Vertexron Group GmbH\n\nAlle künftigen Rechnungen sind ebenfalls auf dieses Konto zu zahlen. Das alte Konto wird nicht mehr verwendet.\n\nMit freundlichen Grüßen,\nS. Brandt\nBuchhaltung, Vertexron GmbH',
 '[]'::jsonb,
 TRUE,
 '["Neue Bankdaten per E-Mail angekündigt — das klassische Muster von Rechnungsbetrug","Druck: Die Rechnung ist \"diese Woche fällig\"","Keine Telefonnummer zur Überprüfung — Betrüger meiden Verifizierungswege","Die Domain vertexron-group.com weicht subtil vom bekannten Lieferanten ab","Geänderte Bankdaten immer TELEFONISCH über die bereits bekannte Nummer prüfen"]'::jsonb,
 '[]'::jsonb,
 'Dies ist Rechnungsbetrug (Lieferantenbetrug / BEC). Kriminelle ahmen eine echte Lieferantenbeziehung nach und kündigen „neue Bankdaten" an. Prüfen Sie eine Kontoänderung immer telefonisch beim bekannten Ansprechpartner — nie über die E-Mail selbst.',
 250, 'advanced'),

('de', 'business',
 'HR Kestrel',
 'hr@kestrel.de',
 'Unsere eigene Domain @kestrel.de — korrekt. Solche HR-Mitteilungen laufen über interne Kanäle.',
 'vor 2 Tagen 09:00',
 'Aktion erforderlich: Bestätigung der neuen Betriebsvereinbarung — Frist 15. Juni',
 'Die neue Betriebsvereinbarung tritt am 1. Juli in Kraft. Bitte bestätigen Sie sie über MeinKestrel vor dem 15. Juni...',
 E'Liebe Kollegin, lieber Kollege,\n\ndie neue Betriebsvereinbarung (Ausgabe 2026) tritt am 1. Juli in Kraft. Alle Mitarbeitenden werden gebeten, sie zu lesen und digital zu bestätigen.\n\nSo geht es:\n• Gehen Sie zu MeinKestrel (die Adresse kennen Sie vom Intranet)\n• Öffnen Sie „Meine Dokumente" → „Vereinbarung 2026"\n• Klicken Sie nach dem Lesen auf „Bestätigen"\n\nFrist: 15. Juni. Fragen? Kommen Sie bei HR vorbei oder fragen Sie über das Intranet.\n\nWir fügen bewusst keinen direkten Link bei — Sie wissen, wo Sie MeinKestrel finden.\n\nMit freundlichen Grüßen,\nHR Kestrel',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Absender @kestrel.de — die offizielle interne Domain","Bewusst KEIN Link: Sie werden gebeten, selbst zu MeinKestrel zu gehen","Konkreter, plausibler HR-Kontext mit angemessener Frist","Verweist auf bekannte interne Kanäle (Intranet, HR)","Keine Abfrage von Passwörtern oder persönlichen Daten"]'::jsonb,
 'Dies ist eine echte interne HR-Mitteilung. Beachten Sie das sicherste Muster überhaupt: gar kein Link — Sie werden gebeten, selbst das bekannte interne Portal zu öffnen. Genau so funktioniert Phishing-resistente Kommunikation.',
 260, 'advanced'),

('de', 'business',
 'Microsoft Teams',
 'no-reply@email.teams.microsoft.com',
 'Echte Teams-Benachrichtigungen kommen von @email.teams.microsoft.com — korrekt.',
 'vor 2 Tagen 17:30',
 'Sie haben 4 verpasste Nachrichten in Teams — tägliche Zusammenfassung',
 'Anna Weber: „Bist du morgen beim Stand-up dabei?" und 3 weitere Nachrichten...',
 E'<div class="eml fam-tech" style="--brand:#464eb8;--cta:#464eb8"><div class="eml-top"><span class="eml-logo">Microsoft Teams</span></div><div class="eml-body"><p>Sie haben verpasste Nachrichten in Microsoft Teams.</p><p>Anna Weber (Projekt Nord): „Bist du morgen um 9:15 beim Stand-up dabei?"<br>Team Einkauf: 2 neue Nachrichten in „Lieferanten-Review Q3"<br>Markus Vogel: „Das aktualisierte Budget liegt auf dem Share, kannst du mal draufschauen?"</p><p>Öffnen Sie Teams auf Ihrem Computer oder Telefon, um zu lesen und zu antworten.</p><p>Microsoft Teams<br>Sie erhalten diese Zusammenfassung aufgrund Ihrer Benachrichtigungseinstellungen.</p></div><div class="eml-foot"><p>Dies ist eine automatische Nachricht — bitte antworten Sie nicht darauf.</p><p>© 2026 Microsoft Teams</p></div></div>',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Absender @email.teams.microsoft.com — die offizielle Teams-Benachrichtigungsdomain","Kein Anmeldelink und keine Zahlungsaufforderung — Sie werden gebeten, Teams selbst zu öffnen","Konkrete Nachrichten bekannter Kollegen, die zum normalen Arbeitsalltag passen","Verweist auf teams.microsoft.com — eine bekannte offizielle Microsoft-Domain"]'::jsonb,
 'Dies ist eine echte Teams-Zusammenfassung. Microsoft versendet sie von @email.teams.microsoft.com. Beachten Sie: kein Anmeldelink — Sie werden gebeten, Teams selbst zu öffnen. Echte Teams-Benachrichtigungen enthalten keine verdächtigen externen Links.',
 270, 'advanced');

-- ============================================================
-- Consumentgerichte 'both'-berichten (gevorderd) naar 'personal'
-- voor EN/FR/DE, zoals eerder al voor NL gedaan — zakelijke
-- trainingen blijven zo zakelijk.
-- ============================================================
UPDATE inbox_messages SET audience = 'personal'
WHERE difficulty = 'advanced' AND audience = 'both' AND (
  (locale = 'en' AND sender_name IN ('Amazon')) OR
  (locale = 'de' AND sender_name IN ('Sparkasse', 'DHL Paket', 'Bundeszentralamt für Steuern', 'Amazon.de', 'OTTO', 'Netflix')) OR
  (locale = 'fr' AND sender_name IN ('Crédit Agricole', 'La Poste', 'Direction Générale des Finances Publiques', 'Doctolib', 'Amazon', 'Orange', 'Assurance Maladie', 'SNCF Connect')) OR
  (locale = 'fr-BE' AND sender_name IN ('Crédit Agricole', 'La Poste', 'Direction Générale des Finances Publiques', 'Doctolib', 'Amazon', 'Orange', 'Assurance Maladie', 'SNCF Connect'))
);

-- fr-BE: kopieer de nieuwe Franse zakelijke gevorderde berichten, met
-- domeincorrectie kestrel.fr → kestrel.be (Belgische vestiging).
INSERT INTO inbox_messages
  (locale, audience, sender_name, sender_address, sender_note, received_label,
   subject, preview, body, links, is_phishing, red_flags, green_flags,
   explanation, sort_order, difficulty)
SELECT 'fr-BE', audience, sender_name,
       replace(replace(sender_address, 'kestrel-access.fr', 'kestrel-access.be'), 'kestrel.fr', 'kestrel.be'),
       replace(replace(sender_note, 'kestrel-access.fr', 'kestrel-access.be'), 'kestrel.fr', 'kestrel.be'),
       received_label,
       replace(subject, 'kestrel.fr', 'kestrel.be'),
       replace(preview, 'kestrel.fr', 'kestrel.be'),
       replace(replace(body, 'kestrel-access.fr', 'kestrel-access.be'), 'kestrel.fr', 'kestrel.be'),
       replace(replace(links::text, 'kestrel-access.fr', 'kestrel-access.be'), 'kestrel.fr', 'kestrel.be')::jsonb,
       is_phishing,
       replace(replace(red_flags::text, 'kestrel-access.fr', 'kestrel-access.be'), 'kestrel.fr', 'kestrel.be')::jsonb,
       replace(green_flags::text, 'kestrel.fr', 'kestrel.be')::jsonb,
       replace(replace(explanation, 'kestrel-access.fr', 'kestrel-access.be'), 'kestrel.fr', 'kestrel.be'),
       sort_order, difficulty
FROM inbox_messages
WHERE locale = 'fr' AND difficulty = 'advanced' AND audience = 'business'
  AND sort_order BETWEEN 220 AND 270
ON CONFLICT DO NOTHING;

-- ============================================================
-- QR-phishing (quishing) voor alle overige talen.
-- Zakelijk: nep-Authenticator-herregistratie (en/fr/de + fr-BE).
-- Privé: nep-betaalverzoek — PayPal (en/fr/de), Payconiq (nl-BE/fr-BE).
-- ============================================================

INSERT INTO inbox_messages
  (locale, audience, sender_name, sender_address, sender_note, received_label,
   subject, preview, body, links, is_phishing, red_flags, green_flags,
   explanation, sort_order, difficulty) VALUES

-- EN — business Authenticator QR
('en', 'business',
 'Microsoft Authenticator',
 'mfa-verification@microsoft-device-check.com',
 'The real Microsoft domain is microsoft.com. And Microsoft never asks you to scan a QR code from an email.',
 'today 08:47',
 'Action required: re-register your Authenticator before Friday',
 'Your Microsoft Authenticator pairing expires. Scan the QR code to re-register...',
 E'<div class="eml fam-tech" style="--brand:#0067b8;--cta:#0067b8"><div class="eml-top"><span class="eml-logo">Microsoft Authenticator</span></div><div class="eml-body"><p class="eml-h">Re-registration required before Friday</p><p>Dear employee,</p><p>Due to a security update, the pairing of your Microsoft Authenticator app expires this Friday. To keep access to your account, you must re-register your device.</p><p><strong>Scan the QR code below with your phone:</strong></p><div style="text-align:center;margin:14px 0"><img src="/qr-img/mfa" width="150" height="150" alt="QR code" style="background:#fff;padding:10px;border:1px solid #ddd;border-radius:4px"></div><p>Unable to scan? {{link:0}}</p><p>After Friday, unregistered access will be blocked automatically.</p></div><div class="eml-foot"><p>Microsoft Corporation, One Microsoft Way, Redmond, WA 98052</p><p>This is a mandatory security notice for all employees.</p></div></div>',
 '[{"label":"Register manually","real_url":"http://microsoft-device-check.com/enroll?id=8842","suspicious":true,"warning":"microsoft-device-check.com is not a Microsoft domain. Real Authenticator registration goes through your own IT department or portal.office.com — never via a QR code in an email."}]'::jsonb,
 TRUE,
 '["A QR code in an email: you cannot see where it leads before you scan it","Sender @microsoft-device-check.com — not @microsoft.com","Time pressure: \"before Friday\", \"blocked automatically\"","Your IT department announces MFA changes through known internal channels, not a stand-alone email","Scanning with your phone bypasses your work computer''s protection — exactly what the attacker wants"]'::jsonb,
 '[]'::jsonb,
 'This is "quishing": phishing via a QR code. Attackers use QR codes because email filters cannot read the link inside the image — and neither can you. Never scan a QR code from an unexpected email. Unsure about your Authenticator? Go to portal.office.com yourself or ask your IT department.',
 95, 'normal'),

-- EN — personal PayPal QR
('en', 'personal',
 'PayPal',
 'service@paypal-payment-request.com',
 'Real PayPal mail comes from @paypal.com or @paypal.co.uk. This lookalike domain is fake.',
 'yesterday 19:22',
 'Reminder: you have an outstanding payment request of £12.50',
 'You still have an outstanding payment request. Scan the QR code to pay instantly...',
 E'<div class="eml fam-pay" style="--brand:#003087;--cta:#003087"><div class="eml-hero"><span class="eml-logo" style="font-style:italic;font-weight:800">PayPal</span></div><div class="eml-body"><p class="eml-h">You have an outstanding payment request</p><p>Hello,</p><p>You still have an outstanding payment request of <strong>£12.50</strong> from M. Green.</p><p>Scan the QR code below with your banking app to pay instantly:</p><div style="text-align:center;margin:14px 0"><img src="/qr-img/paypal" width="150" height="150" alt="QR code" style="background:#fff;padding:10px;border:1px solid #ddd;border-radius:4px"></div><p>Unable to scan? {{link:0}}</p><p>This request expires in 24 hours.</p></div><div class="eml-foot"><p>PayPal (Europe) S.à r.l. et Cie, S.C.A.</p><p>You receive this reminder because the payment request is still open.</p></div></div>',
 '[{"label":"Pay in your browser","real_url":"http://paypal-payment-request.com/pay/8X2KQ","suspicious":true,"warning":"The real PayPal domain is paypal.com. This fake domain tries to steal your bank details."}]'::jsonb,
 TRUE,
 '["A QR code in an email: you cannot see where it leads before you scan it","Sender @paypal-payment-request.com — the real domain is paypal.com","Unexpected: do you know M. Green? Were you expecting a payment request?","Time pressure: \"expires in 24 hours\"","Real PayPal requests appear in the app or on paypal.com — check there"]'::jsonb,
 '[]'::jsonb,
 'This is a fake payment request with a QR code ("quishing"). Never scan a QR code from an unexpected email — your phone would open a fake payment page that steals your bank details. Expecting a real request? Open the PayPal app yourself and check there.',
 96, 'normal'),

-- FR — business Authenticator QR
('fr', 'business',
 'Microsoft Authenticator',
 'mfa-verification@microsoft-device-check.com',
 'Le vrai domaine Microsoft est microsoft.com. Et Microsoft ne demande jamais de scanner un QR code depuis un e-mail.',
 'aujourd''hui 08:47',
 'Action requise : réenregistrez votre Authenticator avant vendredi',
 'Le couplage de votre application Microsoft Authenticator expire. Scannez le QR code pour le réenregistrer...',
 E'<div class="eml fam-tech" style="--brand:#0067b8;--cta:#0067b8"><div class="eml-top"><span class="eml-logo">Microsoft Authenticator</span></div><div class="eml-body"><p class="eml-h">Réenregistrement requis avant vendredi</p><p>Cher collaborateur,</p><p>En raison d''une mise à jour de sécurité, le couplage de votre application Microsoft Authenticator expire ce vendredi. Pour conserver l''accès à votre compte, vous devez réenregistrer votre appareil.</p><p><strong>Scannez le QR code ci-dessous avec votre téléphone :</strong></p><div style="text-align:center;margin:14px 0"><img src="/qr-img/mfa" width="150" height="150" alt="QR code" style="background:#fff;padding:10px;border:1px solid #ddd;border-radius:4px"></div><p>Impossible de scanner ? {{link:0}}</p><p>Après vendredi, les accès non réenregistrés seront automatiquement bloqués.</p></div><div class="eml-foot"><p>Microsoft Corporation, One Microsoft Way, Redmond, WA 98052</p><p>Ceci est un avis de sécurité obligatoire pour tous les collaborateurs.</p></div></div>',
 '[{"label":"Enregistrer manuellement","real_url":"http://microsoft-device-check.com/enroll?id=8842","suspicious":true,"warning":"microsoft-device-check.com n''est pas un domaine Microsoft. Le véritable enregistrement Authenticator passe par votre service informatique ou portal.office.com — jamais par un QR code dans un e-mail."}]'::jsonb,
 TRUE,
 '["Un QR code dans un e-mail : impossible de voir où il mène avant de le scanner","Expéditeur @microsoft-device-check.com — pas @microsoft.com","Pression temporelle : « avant vendredi », « bloqués automatiquement »","Votre service informatique annonce les changements MFA via les canaux internes connus, pas par un e-mail isolé","Scanner avec votre téléphone contourne la protection de votre ordinateur de travail — exactement ce que veut l''attaquant"]'::jsonb,
 '[]'::jsonb,
 'Ceci est du « quishing » : du phishing par QR code. Les attaquants utilisent les QR codes parce que les filtres e-mail ne peuvent pas lire le lien dans l''image — et vous non plus. Ne scannez jamais un QR code d''un e-mail inattendu. Un doute sur votre Authenticator ? Allez vous-même sur portal.office.com ou demandez à votre service informatique.',
 95, 'normal'),

-- FR — personal PayPal QR
('fr', 'personal',
 'PayPal',
 'service@paypal-demande-paiement.com',
 'Les vrais e-mails PayPal viennent de @paypal.com ou @paypal.fr. Ce domaine imité est faux.',
 'hier 19:22',
 'Rappel : vous avez une demande de paiement en attente de 12,50 €',
 'Vous avez encore une demande de paiement en attente. Scannez le QR code pour payer immédiatement...',
 E'<div class="eml fam-pay" style="--brand:#003087;--cta:#003087"><div class="eml-hero"><span class="eml-logo" style="font-style:italic;font-weight:800">PayPal</span></div><div class="eml-body"><p class="eml-h">Vous avez une demande de paiement en attente</p><p>Bonjour,</p><p>Vous avez encore une demande de paiement en attente de <strong>12,50 €</strong> de M. Legrand.</p><p>Scannez le QR code ci-dessous avec votre application bancaire pour payer immédiatement :</p><div style="text-align:center;margin:14px 0"><img src="/qr-img/paypal" width="150" height="150" alt="QR code" style="background:#fff;padding:10px;border:1px solid #ddd;border-radius:4px"></div><p>Impossible de scanner ? {{link:0}}</p><p>Cette demande expire dans 24 heures.</p></div><div class="eml-foot"><p>PayPal (Europe) S.à r.l. et Cie, S.C.A.</p><p>Vous recevez ce rappel car la demande de paiement est toujours ouverte.</p></div></div>',
 '[{"label":"Payer dans le navigateur","real_url":"http://paypal-demande-paiement.com/pay/8X2KQ","suspicious":true,"warning":"Le vrai domaine PayPal est paypal.com. Ce faux domaine tente de voler vos données bancaires."}]'::jsonb,
 TRUE,
 '["Un QR code dans un e-mail : impossible de voir où il mène avant de le scanner","Expéditeur @paypal-demande-paiement.com — le vrai domaine est paypal.com","Inattendu : connaissez-vous M. Legrand ? Attendiez-vous une demande de paiement ?","Pression temporelle : « expire dans 24 heures »","Les vraies demandes PayPal apparaissent dans l''application ou sur paypal.com — vérifiez-y"]'::jsonb,
 '[]'::jsonb,
 'Ceci est une fausse demande de paiement avec QR code (« quishing »). Ne scannez jamais un QR code d''un e-mail inattendu — votre téléphone ouvrirait une fausse page de paiement qui vole vos données bancaires. Vous attendez une vraie demande ? Ouvrez vous-même l''application PayPal et vérifiez-y.',
 96, 'normal'),

-- DE — business Authenticator QR
('de', 'business',
 'Microsoft Authenticator',
 'mfa-verifizierung@microsoft-device-check.com',
 'Die echte Microsoft-Domain ist microsoft.com. Und Microsoft bittet nie per E-Mail, einen QR-Code zu scannen.',
 'heute 08:47',
 'Aktion erforderlich: Registrieren Sie Ihren Authenticator vor Freitag neu',
 'Die Kopplung Ihrer Microsoft Authenticator-App läuft ab. Scannen Sie den QR-Code zur Neuregistrierung...',
 E'<div class="eml fam-tech" style="--brand:#0067b8;--cta:#0067b8"><div class="eml-top"><span class="eml-logo">Microsoft Authenticator</span></div><div class="eml-body"><p class="eml-h">Neuregistrierung vor Freitag erforderlich</p><p>Liebe Mitarbeiterin, lieber Mitarbeiter,</p><p>aufgrund eines Sicherheitsupdates läuft die Kopplung Ihrer Microsoft Authenticator-App diesen Freitag ab. Um den Zugriff auf Ihr Konto zu behalten, müssen Sie Ihr Gerät neu registrieren.</p><p><strong>Scannen Sie den QR-Code unten mit Ihrem Telefon:</strong></p><div style="text-align:center;margin:14px 0"><img src="/qr-img/mfa" width="150" height="150" alt="QR-Code" style="background:#fff;padding:10px;border:1px solid #ddd;border-radius:4px"></div><p>Scannen nicht möglich? {{link:0}}</p><p>Nach Freitag wird nicht registrierter Zugriff automatisch blockiert.</p></div><div class="eml-foot"><p>Microsoft Corporation, One Microsoft Way, Redmond, WA 98052</p><p>Dies ist ein verpflichtender Sicherheitshinweis für alle Mitarbeitenden.</p></div></div>',
 '[{"label":"Manuell registrieren","real_url":"http://microsoft-device-check.com/enroll?id=8842","suspicious":true,"warning":"microsoft-device-check.com ist keine Microsoft-Domain. Die echte Authenticator-Registrierung läuft über Ihre IT-Abteilung oder portal.office.com — nie über einen QR-Code in einer E-Mail."}]'::jsonb,
 TRUE,
 '["Ein QR-Code in einer E-Mail: Sie sehen nicht, wohin er führt, bevor Sie ihn scannen","Absender @microsoft-device-check.com — nicht @microsoft.com","Zeitdruck: \"vor Freitag\", \"automatisch blockiert\"","Ihre IT-Abteilung kündigt MFA-Änderungen über bekannte interne Kanäle an, nicht per einzelner E-Mail","Das Scannen mit dem Telefon umgeht den Schutz Ihres Arbeitsrechners — genau das will der Angreifer"]'::jsonb,
 '[]'::jsonb,
 'Dies ist "Quishing": Phishing über einen QR-Code. Angreifer nutzen QR-Codes, weil E-Mail-Filter den Link im Bild nicht lesen können — und Sie auch nicht. Scannen Sie nie einen QR-Code aus einer unerwarteten E-Mail. Unsicher wegen Ihres Authenticators? Gehen Sie selbst zu portal.office.com oder fragen Sie Ihre IT-Abteilung.',
 95, 'normal'),

-- DE — personal PayPal QR
('de', 'personal',
 'PayPal',
 'service@paypal-zahlungsanfrage.com',
 'Echte PayPal-Mails kommen von @paypal.com oder @paypal.de. Diese nachgeahmte Domain ist gefälscht.',
 'gestern 19:22',
 'Erinnerung: Sie haben eine offene Zahlungsanfrage über 12,50 €',
 'Sie haben noch eine offene Zahlungsanfrage. Scannen Sie den QR-Code, um sofort zu zahlen...',
 E'<div class="eml fam-pay" style="--brand:#003087;--cta:#003087"><div class="eml-hero"><span class="eml-logo" style="font-style:italic;font-weight:800">PayPal</span></div><div class="eml-body"><p class="eml-h">Sie haben eine offene Zahlungsanfrage</p><p>Hallo,</p><p>Sie haben noch eine offene Zahlungsanfrage über <strong>12,50 €</strong> von M. Grün.</p><p>Scannen Sie den QR-Code unten mit Ihrer Banking-App, um sofort zu zahlen:</p><div style="text-align:center;margin:14px 0"><img src="/qr-img/paypal" width="150" height="150" alt="QR-Code" style="background:#fff;padding:10px;border:1px solid #ddd;border-radius:4px"></div><p>Scannen nicht möglich? {{link:0}}</p><p>Diese Anfrage läuft in 24 Stunden ab.</p></div><div class="eml-foot"><p>PayPal (Europe) S.à r.l. et Cie, S.C.A.</p><p>Sie erhalten diese Erinnerung, weil die Zahlungsanfrage noch offen ist.</p></div></div>',
 '[{"label":"Im Browser zahlen","real_url":"http://paypal-zahlungsanfrage.com/pay/8X2KQ","suspicious":true,"warning":"Die echte PayPal-Domain ist paypal.com. Diese gefälschte Domain versucht, Ihre Bankdaten zu stehlen."}]'::jsonb,
 TRUE,
 '["Ein QR-Code in einer E-Mail: Sie sehen nicht, wohin er führt, bevor Sie ihn scannen","Absender @paypal-zahlungsanfrage.com — die echte Domain ist paypal.com","Unerwartet: Kennen Sie M. Grün? Haben Sie eine Zahlungsanfrage erwartet?","Zeitdruck: \"läuft in 24 Stunden ab\"","Echte PayPal-Anfragen erscheinen in der App oder auf paypal.com — prüfen Sie dort"]'::jsonb,
 '[]'::jsonb,
 'Dies ist eine gefälschte Zahlungsanfrage mit QR-Code ("Quishing"). Scannen Sie nie einen QR-Code aus einer unerwarteten E-Mail — Ihr Telefon würde eine gefälschte Zahlungsseite öffnen, die Ihre Bankdaten stiehlt. Erwarten Sie eine echte Anfrage? Öffnen Sie selbst die PayPal-App und prüfen Sie dort.',
 96, 'normal'),

-- NL-BE — personal Payconiq QR (Belgisch alternatief voor Tikkie)
('nl-BE', 'personal',
 'Payconiq by Bancontact',
 'service@payconiq-betaalverzoek.be',
 'Echte Payconiq-meldingen komen via de app, niet via e-mail met een QR-code. Dit domein is nep.',
 'gisteren 19:22',
 'Herinnering: openstaand betaalverzoek van € 12,50',
 'U hebt nog een openstaand betaalverzoek. Scan de QR-code om direct te betalen...',
 E'<div class="eml fam-pay" style="--brand:#e6007e;--cta:#e6007e"><div class="eml-hero"><span class="eml-logo">Payconiq by Bancontact</span></div><div class="eml-body"><p class="eml-h">U hebt nog een openstaand betaalverzoek</p><p>Dag!</p><p>U hebt nog een openstaand betaalverzoek van <strong>€ 12,50</strong> van M. Peeters.</p><p>Scan de QR-code hieronder met uw bank-app om direct te betalen:</p><div style="text-align:center;margin:14px 0"><img src="/qr-img/payconiq" width="150" height="150" alt="QR-code" style="background:#fff;padding:10px;border:1px solid #ddd;border-radius:4px"></div><p>Lukt het scannen niet? {{link:0}}</p><p>Dit verzoek vervalt over 24 uur.</p></div><div class="eml-foot"><p>Payconiq International S.A.</p><p>U ontvangt deze herinnering omdat het betaalverzoek nog openstaat.</p></div></div>',
 '[{"label":"Betaal via de browser","real_url":"http://payconiq-betaalverzoek.be/pay/8X2KQ","suspicious":true,"warning":"Het echte domein is payconiq.be / payconiq.com. Dit nep-domein probeert uw bankgegevens te stelen."}]'::jsonb,
 TRUE,
 '["QR-code in een e-mail: u ziet niet waar die naartoe leidt vóór u scant","Afzender @payconiq-betaalverzoek.be — het echte domein is payconiq.be","Onverwacht: kent u M. Peeters? Verwachtte u een betaalverzoek?","Tijdsdruk: \"vervalt over 24 uur\"","Echte Payconiq-verzoeken verschijnen in de app — niet via e-mail"]'::jsonb,
 '[]'::jsonb,
 'Dit is een nep-betaalverzoek met QR-code ("quishing"). Scan nooit een QR-code uit een onverwachte e-mail — uw telefoon opent dan een nep-betaalpagina die uw bankgegevens steelt. Verwacht u echt een verzoek? Open dan zelf de Payconiq-app en kijk daar.',
 96, 'normal'),

-- FR-BE — business Authenticator QR (kopie van fr) + personal Payconiq QR
('fr-BE', 'personal',
 'Payconiq by Bancontact',
 'service@payconiq-demande-paiement.be',
 'Les vraies notifications Payconiq arrivent via l''application, pas par e-mail avec un QR code. Ce domaine est faux.',
 'hier 19:22',
 'Rappel : demande de paiement en attente de 12,50 €',
 'Vous avez encore une demande de paiement en attente. Scannez le QR code pour payer immédiatement...',
 E'<div class="eml fam-pay" style="--brand:#e6007e;--cta:#e6007e"><div class="eml-hero"><span class="eml-logo">Payconiq by Bancontact</span></div><div class="eml-body"><p class="eml-h">Vous avez une demande de paiement en attente</p><p>Bonjour !</p><p>Vous avez encore une demande de paiement en attente de <strong>12,50 €</strong> de M. Peeters.</p><p>Scannez le QR code ci-dessous avec votre application bancaire pour payer immédiatement :</p><div style="text-align:center;margin:14px 0"><img src="/qr-img/payconiq" width="150" height="150" alt="QR code" style="background:#fff;padding:10px;border:1px solid #ddd;border-radius:4px"></div><p>Impossible de scanner ? {{link:0}}</p><p>Cette demande expire dans 24 heures.</p></div><div class="eml-foot"><p>Payconiq International S.A.</p><p>Vous recevez ce rappel car la demande de paiement est toujours ouverte.</p></div></div>',
 '[{"label":"Payer dans le navigateur","real_url":"http://payconiq-demande-paiement.be/pay/8X2KQ","suspicious":true,"warning":"Le vrai domaine est payconiq.be / payconiq.com. Ce faux domaine tente de voler vos données bancaires."}]'::jsonb,
 TRUE,
 '["Un QR code dans un e-mail : impossible de voir où il mène avant de le scanner","Expéditeur @payconiq-demande-paiement.be — le vrai domaine est payconiq.be","Inattendu : connaissez-vous M. Peeters ? Attendiez-vous une demande de paiement ?","Pression temporelle : « expire dans 24 heures »","Les vraies demandes Payconiq apparaissent dans l''application — pas par e-mail"]'::jsonb,
 '[]'::jsonb,
 'Ceci est une fausse demande de paiement avec QR code (« quishing »). Ne scannez jamais un QR code d''un e-mail inattendu — votre téléphone ouvrirait une fausse page de paiement qui vole vos données bancaires. Vous attendez une vraie demande ? Ouvrez vous-même l''application Payconiq et vérifiez-y.',
 96, 'normal');

-- fr-BE: kopieer de Franse Authenticator-QR (geen domeinverschil nodig)
INSERT INTO inbox_messages
  (locale, audience, sender_name, sender_address, sender_note, received_label,
   subject, preview, body, links, is_phishing, red_flags, green_flags,
   explanation, sort_order, difficulty)
SELECT 'fr-BE', audience, sender_name, sender_address, sender_note, received_label,
       subject, preview, body, links, is_phishing, red_flags, green_flags,
       explanation, sort_order, difficulty
FROM inbox_messages
WHERE locale = 'fr' AND difficulty = 'normal' AND sort_order = 95
  AND sender_name = 'Microsoft Authenticator'
ON CONFLICT DO NOTHING;

-- ============================================================
-- Bijlagen: de recruiter-phishing heeft een kwaadaardige bijlage
-- (.pdf.exe). We tonen die als echte, klikbare bijlage-chip i.p.v.
-- als tekst in de body. Per taal de juiste bestandsnaam + uitleg.
-- ============================================================
UPDATE inbox_messages SET attachments =
  '[{"filename":"Functiebeschrijving_en_NDA.pdf.exe","size":"248 KB","dangerous":true,"warning":"Dit bestand heet \".pdf.exe\". De échte extensie is .exe — een uitvoerbaar programma, vermomd als PDF. Open dit nooit. Een serieuze recruiter stuurt geen los uitvoerbaar bestand."}]'::jsonb
WHERE locale IN ('nl','nl-BE') AND sender_address LIKE '%premium-talent-careers.info';

UPDATE inbox_messages SET attachments =
  '[{"filename":"Job_Spec_and_NDA.pdf.exe","size":"248 KB","dangerous":true,"warning":"This file is named \".pdf.exe\". Its real extension is .exe — an executable program disguised as a PDF. Never open it. A genuine recruiter does not send a stand-alone executable."}]'::jsonb
WHERE locale = 'en' AND sender_address LIKE '%premium-talent-careers.info';

UPDATE inbox_messages SET attachments =
  '[{"filename":"Fiche_Poste_et_NDA.pdf.exe","size":"248 KB","dangerous":true,"warning":"Ce fichier s’appelle « .pdf.exe ». Sa vraie extension est .exe — un programme exécutable déguisé en PDF. Ne l’ouvrez jamais. Un vrai recruteur n’envoie pas un exécutable isolé."}]'::jsonb
WHERE locale IN ('fr','fr-BE') AND sender_address LIKE '%premium-talent-careers.info';

UPDATE inbox_messages SET attachments =
  '[{"filename":"Stellenbeschreibung_und_NDA.pdf.exe","size":"248 KB","dangerous":true,"warning":"Diese Datei heißt „.pdf.exe\". Ihre echte Endung ist .exe — ein ausführbares Programm, getarnt als PDF. Öffnen Sie sie nie. Ein echter Recruiter sendet keine einzelne ausführbare Datei."}]'::jsonb
WHERE locale = 'de' AND sender_address LIKE '%premium-talent-careers.info';


-- ============================================================
-- FASE 1: SMISHING — sms- en WhatsApp-scenario's.
-- Eén INSERT met expliciete kolommen locale/channel/audience/difficulty.
-- channel = 'sms' of 'whatsapp'; audience 'both'; difficulty 'normal'.
-- WhatsApp "familie-in-nood"-oplichting heeft GEEN link: de actie is
-- antwoorden/geld overmaken, dus links = []. sort_order vanaf 300 zodat
-- het niet botst met de e-mailscenario's.
-- ============================================================
INSERT INTO inbox_messages
  (locale, channel, audience, difficulty, sender_name, sender_address, sender_note, received_label, subject, preview, body, links, is_phishing, red_flags, green_flags, explanation, sort_order) VALUES

-- ---------- NL ----------
('nl','sms','both','normal',
 'PostNL','+31 6 21 34 55 78',
 'PostNL stuurt sms''jes nooit vanaf een 06-nummer en vraagt nooit om betaling van bezorgkosten.',
 'vandaag 14:02','PostNL',
 'Uw pakket kon niet bezorgd worden. Betaal € 0,69 verzendkosten...',
 E'PostNL: uw pakket kon niet worden bezorgd. Betaal de openstaande verzendkosten van € 0,69 om opnieuw te laten bezorgen: {{link:0}}',
 '[{"label":"postnl-herbezorging.com","real_url":"http://postnl-herbezorging.com/betaal","suspicious":true,"warning":"Het echte adres is postnl.nl. \"postnl-herbezorging.com\" is een nepsite. Een klein bedrag (€ 0,69) is een trucje zodat u zonder nadenken uw kaartgegevens invult."}]'::jsonb,
 TRUE,
 '["Onbekend 06-nummer als afzender","Heel klein bedrag — u twijfelt niet","Link gaat naar postnl-herbezorging.com, niet postnl.nl","Druk: \"betaal om opnieuw te laten bezorgen\""]'::jsonb,
 '[]'::jsonb,
 'Dit is smishing (phishing via sms). PostNL vraagt nooit per sms om bezorgkosten te betalen. Verwacht u een pakket? Controleer het zelf in de PostNL-app of op postnl.nl — typ het adres zelf in.',
 300),

('nl','sms','both','normal',
 'ING','+31 97 01 02 88 31',
 'De echte ING sms''t alleen verificatiecodes en zet er nooit een link bij.',
 'vandaag 11:20','ING',
 'Er is ingelogd op een nieuw apparaat. Was u dit niet? Beveilig...',
 E'ING: er is zojuist ingelogd op een NIEUW apparaat. Was u dit niet? Beveilig direct uw rekening via {{link:0}}',
 '[{"label":"ing-veilig-inloggen.net","real_url":"http://ing-veilig-inloggen.net","suspicious":true,"warning":"De echte ING gebruikt ing.nl en de ING-app. \"ing-veilig-inloggen.net\" is nep en wil uw inloggegevens stelen."}]'::jsonb,
 TRUE,
 '["Speelt in op angst (\"vreemd apparaat\")","Link in een bank-sms — de ING doet dat nooit","Domein ing-veilig-inloggen.net is niet ing.nl","Drang om \"direct\" te handelen"]'::jsonb,
 '[]'::jsonb,
 'Dit is smishing. Uw bank stuurt nooit een sms met een link om in te loggen. Vertrouwt u het niet? Open zelf de ING-app of bel het nummer op uw bankpas.',
 301),

('nl','whatsapp','both','normal',
 'Onbekend nummer','+31 6 48 22 19 07',
 'Een "nieuw nummer"-bericht van familie dat meteen om geld vraagt en niet wil bellen, is bijna altijd oplichting.',
 'vandaag 18:45','Onbekend nummer',
 'Hoi mam, dit is mijn nieuwe nummer. Mijn telefoon is kapot...',
 E'Hoi mam 👋 Dit is mijn nieuwe nummer, mijn oude telefoon is kapot. Kun je me even helpen? Ik moet vandaag een rekening van € 850 betalen maar kom er met mijn bankapp niet in. Kun jij het voorschieten? Ik betaal je morgen terug. Bellen lukt nu niet, alleen appen. ❤️',
 '[]'::jsonb,
 TRUE,
 '["Onbekend nummer dat zegt familie te zijn","\"Nieuw nummer, oude telefoon kapot\" — klassieke smoes","Vraagt met spoed om geld over te maken","Wil NIET bellen — alleen appen, zodat u de stem niet hoort"]'::jsonb,
 '[]'::jsonb,
 'Dit is WhatsApp-fraude (de \"hallo mama/papa\"-oplichting). Bel altijd het ORIGINELE, bekende nummer van uw kind voordat u iets overmaakt. Een oplichter wil juist niet dat u belt.',
 302),

('nl','whatsapp','both','normal',
 'Marktplaats-koper','+31 6 12 90 33 41',
 'Een "koper" die u naar een betaallink stuurt om u 1 cent te laten "ontvangen", is een bekende oplichtingstruc.',
 'vandaag 16:10','Marktplaats-koper',
 'Hoi! Ik wil je bankstel kopen. Bevestig even via deze link...',
 E'Hoi! Ik wil graag je bankstel kopen via Marktplaats. Om te bevestigen dat jouw rekening werkt, stuur ik je € 0,01. Klik op deze link en log in met je bank om het te ontvangen: {{link:0}}',
 '[{"label":"marktplaats-betaalcheck.com","real_url":"http://marktplaats-betaalcheck.com/verify","suspicious":true,"warning":"Marktplaats/Tikkie laat u nooit \"inloggen om geld te ONTVANGEN\". Deze link leidt naar een nep-inlogpagina die uw bankgegevens steelt."}]'::jsonb,
 TRUE,
 '["Je hoeft nooit in te loggen om geld te ONTVANGEN","Verdacht klein bedrag (1 cent) als lokkertje","Link naar marktplaats-betaalcheck.com — niet de echte app","Buiten de officiële Marktplaats-chat om"]'::jsonb,
 '[]'::jsonb,
 'Dit is oplichting. Om geld te ontvangen hoeft u nooit ergens in te loggen. Houd betalingen altijd binnen de officiële app en klik niet op toegestuurde betaallinks.',
 303),

('nl','sms','both','normal',
 'Tandarts Hagedoorn','Tandarts','Een afspraakherinnering zonder link, met een nummer dat u zelf kunt bellen, is normaal.',
 'vandaag 09:30','Tandarts Hagedoorn',
 'Herinnering: uw controle morgen om 10:40. Afzeggen? Bel 020-1234567.',
 E'Tandartspraktijk Hagedoorn: herinnering aan uw controle morgen om 10:40. Verhinderd? Bel ons op 020-123 45 67. Tot morgen!',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Geen link en geen betaalverzoek","Concrete, verwachte afspraakinformatie","Telefoonnummer om zelf te bellen","Afzendernaam van uw eigen praktijk"]'::jsonb,
 'Dit is een gewone afspraakherinnering van uw tandarts. Geen link, geen gegevens gevraagd — u kunt gerust bellen als u wilt verzetten.',
 304),

('nl','sms','both','normal',
 'CJIB','3990','Het CJIB stuurt betalingsverzoeken per post (acceptgiro), nooit een sms met een link en spoed.',
 'gisteren 13:15','CJIB',
 'Openstaande boete € 49. Betaal binnen 24 uur om verhoging te...',
 E'CJIB: u heeft een openstaande verkeersboete van € 49. Betaal binnen 24 uur om een verhoging te voorkomen: {{link:0}}',
 '[{"label":"cjib-betalen.com","real_url":"http://cjib-betalen.com/boete","suspicious":true,"warning":"Het CJIB stuurt boetes per post en gebruikt cjib.nl. \"cjib-betalen.com\" is nep en mikt op uw betaalgegevens."}]'::jsonb,
 TRUE,
 '["Overheid stuurt boetes per post, niet per sms met link","Tijdsdruk: \"binnen 24 uur\"","Domein cjib-betalen.com is niet cjib.nl","Dreigt met verhoging om u te haasten"]'::jsonb,
 '[]'::jsonb,
 'Dit is smishing. Het CJIB int boetes via een acceptgiro per post, nooit via een sms-link onder tijdsdruk. Controleer bij twijfel op cjib.nl.',
 305),

-- ---------- nl-BE ----------
('nl-BE','sms','both','normal',
 'bpost','+32 460 21 34 55',
 'bpost stuurt sms''jes nooit vanaf een gsm-nummer en vraagt nooit om bezorgkosten via een link.',
 'vandaag 14:02','bpost',
 'Uw pakje kon niet geleverd worden. Betaal € 0,69 leveringskosten...',
 E'bpost: uw pakje kon niet geleverd worden. Betaal de openstaande leveringskosten van € 0,69 om opnieuw te laten leveren: {{link:0}}',
 '[{"label":"bpost-herlevering.com","real_url":"http://bpost-herlevering.com/betaal","suspicious":true,"warning":"Het echte adres is bpost.be. \"bpost-herlevering.com\" is een nepsite. Een klein bedrag is een trucje zodat u uw kaartgegevens invult."}]'::jsonb,
 TRUE,
 '["Onbekend gsm-nummer als afzender","Heel klein bedrag — u twijfelt niet","Link naar bpost-herlevering.com, niet bpost.be","Druk om snel te betalen"]'::jsonb,
 '[]'::jsonb,
 'Dit is smishing. bpost vraagt nooit per sms om leveringskosten. Verwacht u een pakje? Kijk zelf in de bpost-app of op bpost.be.',
 310),

('nl-BE','sms','both','normal',
 'Belfius','+32 471 88 31 02',
 'Belfius stuurt enkel verificatiecodes per sms en zet er nooit een link bij.',
 'vandaag 11:20','Belfius',
 'Er is aangemeld op een nieuw toestel. Was u dit niet? Beveilig...',
 E'Belfius: er werd zonet aangemeld op een NIEUW toestel. Was u dit niet? Beveilig meteen uw rekening via {{link:0}}',
 '[{"label":"belfius-veilig.net","real_url":"http://belfius-veilig.net","suspicious":true,"warning":"De echte Belfius gebruikt belfius.be en de app. \"belfius-veilig.net\" is nep en wil uw codes stelen."}]'::jsonb,
 TRUE,
 '["Speelt in op angst (\"vreemd toestel\")","Link in een bank-sms — Belfius doet dat nooit","Domein belfius-veilig.net is niet belfius.be","Drang om \"meteen\" te handelen"]'::jsonb,
 '[]'::jsonb,
 'Dit is smishing. Uw bank stuurt nooit een sms met een link om aan te melden. Open zelf de Belfius-app of bel het nummer op uw bankkaart.',
 311),

('nl-BE','whatsapp','both','normal',
 'Onbekend nummer','+32 470 22 19 07',
 'Een "nieuw nummer"-bericht van familie dat meteen om geld vraagt en niet wil bellen, is bijna altijd oplichting.',
 'vandaag 18:45','Onbekend nummer',
 'Dag mama, dit is mijn nieuw nummer. Mijn gsm is stuk...',
 E'Dag mama 👋 Dit is mijn nieuw nummer, mijn oude gsm is stuk. Kun je me even depanneren? Ik moet vandaag een factuur van € 850 betalen maar geraak niet in mijn bankapp. Kun jij het voorschieten? Ik stort het je morgen terug. Bellen lukt niet, enkel appen. ❤️',
 '[]'::jsonb,
 TRUE,
 '["Onbekend nummer dat zegt familie te zijn","\"Nieuw nummer, oude gsm stuk\" — klassieke smoes","Vraagt met spoed om geld te storten","Wil NIET bellen — enkel appen, zodat u de stem niet hoort"]'::jsonb,
 '[]'::jsonb,
 'Dit is WhatsApp-fraude (de \"hallo mama/papa\"-oplichting). Bel altijd het ORIGINELE, gekende nummer van uw kind voor u iets stort. Een oplichter wil net niet dat u belt.',
 312),

('nl-BE','whatsapp','both','normal',
 '2dehands-koper','+32 468 90 33 41',
 'Een "koper" die u naar een betaallink stuurt om u 1 cent te laten "ontvangen", is een gekende oplichtingstruc.',
 'vandaag 16:10','2dehands-koper',
 'Hallo! Ik wil je zetel kopen. Bevestig even via deze link...',
 E'Hallo! Ik wil graag je zetel kopen via 2dehands. Om te bevestigen dat je rekening werkt, stuur ik je € 0,01. Klik op deze link en meld je aan met je bank om het te ontvangen: {{link:0}}',
 '[{"label":"2dehands-betaalcheck.com","real_url":"http://2dehands-betaalcheck.com/verify","suspicious":true,"warning":"U hoeft nooit aan te melden om geld te ONTVANGEN. Deze link leidt naar een nep-aanmeldpagina die uw bankgegevens steelt."}]'::jsonb,
 TRUE,
 '["Je moet nooit aanmelden om geld te ONTVANGEN","Verdacht klein bedrag (1 cent) als lokaas","Link naar 2dehands-betaalcheck.com — niet de echte app","Buiten de officiële chat om"]'::jsonb,
 '[]'::jsonb,
 'Dit is oplichting. Om geld te ontvangen hoeft u zich nergens aan te melden. Houd betalingen binnen de officiële app en klik niet op toegestuurde betaallinks.',
 313),

('nl-BE','sms','both','normal',
 'Garage Verlinden','Garage','Een afspraakherinnering zonder link, met een nummer dat u zelf kunt bellen, is normaal.',
 'vandaag 09:30','Garage Verlinden',
 'Herinnering: onderhoud van uw wagen morgen om 08:30. Bel 03-1234567.',
 E'Garage Verlinden: herinnering aan het onderhoud van uw wagen morgen om 08:30. Verhinderd? Bel ons op 03-123 45 67. Tot morgen!',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Geen link en geen betaalverzoek","Concrete, verwachte afspraakinformatie","Telefoonnummer om zelf te bellen","Afzendernaam van uw eigen garage"]'::jsonb,
 'Dit is een gewone afspraakherinnering van uw garage. Geen link, geen gegevens gevraagd — u kunt gerust bellen als u wilt verzetten.',
 314),

('nl-BE','sms','both','normal',
 'FOD Financiën','8811','De FOD Financiën communiceert via MyMinfin en per post, nooit via een sms-link met spoed.',
 'gisteren 13:15','FOD Financiën',
 'U heeft recht op € 213 teruggave. Bevestig binnen 24u uw gegevens...',
 E'FOD Financiën: u heeft recht op een teruggave van € 213. Bevestig binnen 24u uw gegevens om de uitbetaling te ontvangen: {{link:0}}',
 '[{"label":"minfin-teruggave.com","real_url":"http://minfin-teruggave.com/claim","suspicious":true,"warning":"De FOD Financiën gebruikt MyMinfin (financien.belgium.be). \"minfin-teruggave.com\" is nep en mikt op uw gegevens."}]'::jsonb,
 TRUE,
 '["Overheid belooft geld om u op de link te krijgen","Tijdsdruk: \"binnen 24u\"","Domein minfin-teruggave.com is niet officieel","Vraagt om gegevens te \"bevestigen\""]'::jsonb,
 '[]'::jsonb,
 'Dit is smishing. De FOD Financiën regelt teruggaven via MyMinfin of per post, nooit via een sms-link onder tijdsdruk. Log zelf in op financien.belgium.be.',
 315),

-- ---------- en (UK) ----------
('en','sms','both','normal',
 'Royal Mail','+44 7700 900321',
 'Royal Mail does not text from a mobile number and never asks you to pay a redelivery fee via a link.',
 'today 14:02','Royal Mail',
 'Your parcel could not be delivered. Pay the £0.69 redelivery fee...',
 E'Royal Mail: your parcel could not be delivered. Please pay the outstanding £0.69 redelivery fee to rearrange delivery: {{link:0}}',
 '[{"label":"royalmail-redelivery.com","real_url":"http://royalmail-redelivery.com/pay","suspicious":true,"warning":"The real site is royalmail.com. \"royalmail-redelivery.com\" is a fake. A tiny fee (£0.69) is a trick so you enter your card details without thinking."}]'::jsonb,
 TRUE,
 '["Unknown mobile number as sender","Tiny amount — you do not stop to think","Link goes to royalmail-redelivery.com, not royalmail.com","Pressure: pay to rearrange delivery"]'::jsonb,
 '[]'::jsonb,
 'This is smishing (phishing by text). Royal Mail never texts you to pay a redelivery fee. Expecting a parcel? Check it yourself in the Royal Mail app or at royalmail.com — type the address yourself.',
 320),

('en','sms','both','normal',
 'HMRC','+44 7700 900812',
 'HMRC never texts you a link to claim a refund — refunds go through your online tax account.',
 'today 11:20','HMRC',
 'You are due a tax refund of £276.40. Claim within 24 hours...',
 E'HMRC: our records show you are due a tax refund of £276.40. Claim it within 24 hours here: {{link:0}}',
 '[{"label":"hmrc-refund-claim.com","real_url":"http://hmrc-refund-claim.com/claim","suspicious":true,"warning":"HMRC uses gov.uk. \"hmrc-refund-claim.com\" is a fake site built to steal your bank and tax details."}]'::jsonb,
 TRUE,
 '["Government does not text refund links","Time pressure: \"within 24 hours\"","Domain hmrc-refund-claim.com is not gov.uk","Promises money to make you click"]'::jsonb,
 '[]'::jsonb,
 'This is smishing. HMRC never notifies you of a refund by text with a link. If unsure, log in yourself at gov.uk through your Personal Tax Account.',
 321),

('en','whatsapp','both','normal',
 'Unknown number','+44 7456 221907',
 'A "new number" message from family that immediately asks for money and refuses to call is almost always a scam.',
 'today 18:45','Unknown number',
 'Hi mum, this is my new number. My phone broke...',
 E'Hi mum 👋 This is my new number, my old phone broke. Can you help me out? I need to pay a £850 bill today but I am locked out of my banking app. Could you cover it? I will pay you back tomorrow. Can not call right now, only text. ❤️',
 '[]'::jsonb,
 TRUE,
 '["Unknown number claiming to be family","\"New number, old phone broke\" — classic excuse","Urgently asks you to transfer money","Refuses to call — only text, so you never hear the voice"]'::jsonb,
 '[]'::jsonb,
 'This is a WhatsApp \"hi mum/dad\" scam. Always call your child on their ORIGINAL, known number before sending any money. A scammer specifically does not want you to call.',
 322),

('en','whatsapp','both','normal',
 'Delivery','+44 7456 903341',
 'A real 2FA login code is short, has no link, and you only ever enter it in the app you logged into yourself.',
 'today 16:10','Delivery',
 'WhatsApp code 472-913. Forward it to verify your account...',
 E'Hi, sorry! I accidentally sent my WhatsApp verification code to your number. It is 472-913. Could you forward it back to me? I really need to get back into my account, thanks so much! 🙏',
 '[]'::jsonb,
 TRUE,
 '["No one legitimately needs YOUR verification code","A code sent to you unlocks YOUR account, not theirs","Friendly, apologetic tone to lower your guard","Pressure to act quickly and \"help\""]'::jsonb,
 '[]'::jsonb,
 'This is an account-takeover scam. The code was sent to you because someone is trying to hijack YOUR WhatsApp. Never share a verification code with anyone — not even a \"friend\".',
 323),

('en','sms','both','normal',
 'Brightsmile Dental','Dental','An appointment reminder with no link and a number you can call yourself is normal.',
 'today 09:30','Brightsmile Dental',
 'Reminder: your check-up tomorrow at 10:40. To cancel call 020 7946 0123.',
 E'Brightsmile Dental: a reminder of your check-up tomorrow at 10:40. Need to cancel or rearrange? Call us on 020 7946 0123. See you then!',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["No link and no payment request","Concrete, expected appointment details","A phone number you can call yourself","Sender name of your own practice"]'::jsonb,
 'This is an ordinary appointment reminder from your dentist. No link, no details requested — feel free to call if you want to change it.',
 324),

('en','sms','both','normal',
 'Verify','782244',
 'A genuine 2FA code is sent only when YOU just tried to log in, contains no link, and tells you not to share it.',
 'today 08:05','Verify',
 'Your verification code is 558019. Do not share it with anyone.',
 E'558019 is your verification code. Do not share this code with anyone. If you did not request it, ignore this message.',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["No link to tap","Tells you NOT to share the code","Sent because you just tried to sign in yourself","Short code from a recognised short number"]'::jsonb,
 'This is a genuine two-factor (2FA) code. It is safe as long as YOU just requested it — enter it only in the app or site you logged into. Never read it out or forward it to anyone.',
 325),

-- ---------- fr ----------
('fr','sms','both','normal',
 'Chronopost','+33 6 21 34 55 78',
 'Chronopost n''envoie pas de SMS depuis un numéro de portable et ne demande jamais de payer des frais via un lien.',
 'aujourd''hui 14:02','Chronopost',
 'Votre colis n''a pas pu être livré. Réglez 0,69 € de frais...',
 E'Chronopost : votre colis n''a pas pu être livré. Réglez les frais de réexpédition de 0,69 € pour planifier une nouvelle livraison : {{link:0}}',
 '[{"label":"chronopost-relivraison.com","real_url":"http://chronopost-relivraison.com/payer","suspicious":true,"warning":"Le vrai site est chronopost.fr. « chronopost-relivraison.com » est un faux. Un petit montant (0,69 €) est une ruse pour que vous saisissiez votre carte sans réfléchir."}]'::jsonb,
 TRUE,
 '["Numéro de portable inconnu comme expéditeur","Montant minuscule — vous ne vous méfiez pas","Le lien mène à chronopost-relivraison.com, pas chronopost.fr","Pression : payez pour relivrer"]'::jsonb,
 '[]'::jsonb,
 'C''est du smishing (hameçonnage par SMS). Chronopost ne demande jamais de frais par SMS. Vous attendez un colis ? Vérifiez vous-même dans l''appli ou sur chronopost.fr en tapant l''adresse.',
 330),

('fr','sms','both','normal',
 'Banque','+33 6 70 10 28 83',
 'Votre banque envoie uniquement des codes de vérification par SMS et n''y joint jamais de lien.',
 'aujourd''hui 11:20','Banque',
 'Connexion depuis un nouvel appareil. Ce n''était pas vous ?...',
 E'Votre banque : une connexion vient d''avoir lieu depuis un NOUVEL appareil. Ce n''était pas vous ? Sécurisez votre compte immédiatement : {{link:0}}',
 '[{"label":"securite-banque-acces.net","real_url":"http://securite-banque-acces.net","suspicious":true,"warning":"Votre vraie banque utilise son propre site et son appli. « securite-banque-acces.net » est un faux qui veut voler vos identifiants."}]'::jsonb,
 TRUE,
 '["Joue sur la peur (« appareil inconnu »)","Un lien dans un SMS bancaire — la banque ne fait jamais ça","Domaine securite-banque-acces.net non officiel","Incite à agir « immédiatement »"]'::jsonb,
 '[]'::jsonb,
 'C''est du smishing. Votre banque n''envoie jamais de SMS avec un lien de connexion. En cas de doute, ouvrez vous-même l''appli ou appelez le numéro figurant sur votre carte.',
 331),

('fr','whatsapp','both','normal',
 'Numéro inconnu','+33 6 48 22 19 07',
 'Un message « nouveau numéro » d''un proche qui réclame aussitôt de l''argent et refuse d''appeler est presque toujours une arnaque.',
 'aujourd''hui 18:45','Numéro inconnu',
 'Coucou maman, c''est mon nouveau numéro. Mon téléphone est cassé...',
 E'Coucou maman 👋 C''est mon nouveau numéro, mon ancien téléphone est cassé. Tu peux m''aider ? Je dois régler une facture de 850 € aujourd''hui mais je n''arrive plus à accéder à mon appli bancaire. Tu peux avancer ? Je te rembourse demain. Je ne peux pas appeler, seulement écrire. ❤️',
 '[]'::jsonb,
 TRUE,
 '["Numéro inconnu se faisant passer pour un proche","« Nouveau numéro, ancien téléphone cassé » — prétexte classique","Demande en urgence un virement","Refuse d''appeler — seulement écrire, pour que vous n''entendiez pas la voix"]'::jsonb,
 '[]'::jsonb,
 'C''est l''arnaque WhatsApp « bonjour maman/papa ». Appelez toujours votre enfant sur son numéro D''ORIGINE connu avant d''envoyer le moindre euro. L''escroc, justement, ne veut pas que vous appeliez.',
 332),

('fr','whatsapp','both','normal',
 'Acheteur Leboncoin','+33 6 12 90 33 41',
 'Un « acheteur » qui vous envoie un lien de paiement pour vous faire « recevoir » 1 centime est une arnaque connue.',
 'aujourd''hui 16:10','Acheteur Leboncoin',
 'Bonjour ! Je veux acheter votre canapé. Confirmez via ce lien...',
 E'Bonjour ! Je souhaite acheter votre canapé sur Leboncoin. Pour vérifier que votre compte fonctionne, je vous envoie 0,01 €. Cliquez sur ce lien et connectez-vous avec votre banque pour le recevoir : {{link:0}}',
 '[{"label":"leboncoin-paiement-verif.com","real_url":"http://leboncoin-paiement-verif.com/verify","suspicious":true,"warning":"On ne se connecte jamais pour RECEVOIR de l''argent. Ce lien mène à une fausse page de connexion qui vole vos données bancaires."}]'::jsonb,
 TRUE,
 '["On ne se connecte jamais pour RECEVOIR de l''argent","Montant minuscule (1 centime) comme appât","Lien vers leboncoin-paiement-verif.com — pas la vraie appli","En dehors de la messagerie officielle"]'::jsonb,
 '[]'::jsonb,
 'C''est une arnaque. Pour recevoir de l''argent, vous n''avez jamais à vous connecter quelque part. Restez dans l''appli officielle et ne cliquez pas sur les liens de paiement envoyés.',
 333),

('fr','sms','both','normal',
 'Cabinet Dr Martin','Cabinet','Un rappel de rendez-vous sans lien, avec un numéro que vous pouvez appeler, est normal.',
 'aujourd''hui 09:30','Cabinet Dr Martin',
 'Rappel : votre rendez-vous demain à 10h40. Pour annuler : 01 23 45 67 89.',
 E'Cabinet du Dr Martin : rappel de votre rendez-vous demain à 10h40. Empêché(e) ? Appelez-nous au 01 23 45 67 89. À demain !',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Aucun lien ni demande de paiement","Informations de rendez-vous concrètes et attendues","Un numéro que vous pouvez appeler vous-même","Nom de votre propre cabinet"]'::jsonb,
 'C''est un simple rappel de rendez-vous de votre médecin. Aucun lien, aucune donnée demandée — appelez librement si vous voulez le déplacer.',
 334),

('fr','sms','both','normal',
 'CodeAcces','32100','Un vrai code de vérification ne contient pas de lien et vous demande de ne pas le partager.',
 'aujourd''hui 08:05','CodeAcces',
 'Votre code de vérification est 558019. Ne le partagez avec personne.',
 E'558019 est votre code de vérification. Ne le communiquez à personne. Si vous n''êtes pas à l''origine de cette demande, ignorez ce message.',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Aucun lien à cliquer","Vous demande de NE PAS partager le code","Envoyé parce que vous venez de vous connecter vous-même","Code court depuis un numéro court reconnu"]'::jsonb,
 'C''est un vrai code à deux facteurs (2FA). Il est sûr tant que c''est VOUS qui venez de le demander — saisissez-le uniquement dans l''appli ou le site où vous vous connectez. Ne le communiquez jamais à personne.',
 335),

-- ---------- fr-BE ----------
('fr-BE','sms','both','normal',
 'bpost','+32 460 21 34 55',
 'bpost n''envoie pas de SMS depuis un numéro de GSM et ne demande jamais de payer des frais via un lien.',
 'aujourd''hui 14:02','bpost',
 'Votre colis n''a pas pu être livré. Réglez 0,69 € de frais...',
 E'bpost : votre colis n''a pas pu être livré. Réglez les frais de relivraison de 0,69 € pour planifier une nouvelle livraison : {{link:0}}',
 '[{"label":"bpost-relivraison.com","real_url":"http://bpost-relivraison.com/payer","suspicious":true,"warning":"Le vrai site est bpost.be. « bpost-relivraison.com » est un faux. Un petit montant (0,69 €) est une ruse pour que vous saisissiez votre carte sans réfléchir."}]'::jsonb,
 TRUE,
 '["Numéro de GSM inconnu comme expéditeur","Montant minuscule — vous ne vous méfiez pas","Le lien mène à bpost-relivraison.com, pas bpost.be","Pression : payez pour relivrer"]'::jsonb,
 '[]'::jsonb,
 'C''est du smishing. bpost ne demande jamais de frais par SMS. Vous attendez un colis ? Vérifiez vous-même dans l''appli ou sur bpost.be en tapant l''adresse.',
 340),

('fr-BE','sms','both','normal',
 'Banque','+32 471 10 28 83',
 'Votre banque envoie uniquement des codes de vérification par SMS et n''y joint jamais de lien.',
 'aujourd''hui 11:20','Banque',
 'Connexion depuis un nouvel appareil. Ce n''était pas vous ?...',
 E'Votre banque : une connexion vient d''avoir lieu depuis un NOUVEL appareil. Ce n''était pas vous ? Sécurisez votre compte tout de suite : {{link:0}}',
 '[{"label":"securite-banque-acces.net","real_url":"http://securite-banque-acces.net","suspicious":true,"warning":"Votre vraie banque utilise son propre site et son appli. « securite-banque-acces.net » est un faux qui veut voler vos identifiants."}]'::jsonb,
 TRUE,
 '["Joue sur la peur (« appareil inconnu »)","Un lien dans un SMS bancaire — la banque ne fait jamais ça","Domaine securite-banque-acces.net non officiel","Incite à agir « tout de suite »"]'::jsonb,
 '[]'::jsonb,
 'C''est du smishing. Votre banque n''envoie jamais de SMS avec un lien de connexion. En cas de doute, ouvrez vous-même l''appli ou appelez le numéro figurant sur votre carte.',
 341),

('fr-BE','whatsapp','both','normal',
 'Numéro inconnu','+32 470 22 19 07',
 'Un message « nouveau numéro » d''un proche qui réclame aussitôt de l''argent et refuse d''appeler est presque toujours une arnaque.',
 'aujourd''hui 18:45','Numéro inconnu',
 'Coucou maman, c''est mon nouveau numéro. Mon GSM est cassé...',
 E'Coucou maman 👋 C''est mon nouveau numéro, mon ancien GSM est cassé. Tu peux m''aider ? Je dois payer une facture de 850 € aujourd''hui mais je n''arrive plus à accéder à mon appli bancaire. Tu peux avancer ? Je te rembourse demain. Je ne sais pas appeler, seulement écrire. ❤️',
 '[]'::jsonb,
 TRUE,
 '["Numéro inconnu se faisant passer pour un proche","« Nouveau numéro, ancien GSM cassé » — prétexte classique","Demande en urgence un virement","Refuse d''appeler — seulement écrire, pour que vous n''entendiez pas la voix"]'::jsonb,
 '[]'::jsonb,
 'C''est l''arnaque WhatsApp « bonjour maman/papa ». Appelez toujours votre enfant sur son numéro D''ORIGINE connu avant d''envoyer le moindre euro. L''escroc, justement, ne veut pas que vous appeliez.',
 342),

('fr-BE','whatsapp','both','normal',
 'Acheteur 2ememain','+32 468 90 33 41',
 'Un « acheteur » qui vous envoie un lien de paiement pour vous faire « recevoir » 1 centime est une arnaque connue.',
 'aujourd''hui 16:10','Acheteur 2ememain',
 'Bonjour ! Je veux acheter votre divan. Confirmez via ce lien...',
 E'Bonjour ! Je souhaite acheter votre divan sur 2ememain. Pour vérifier que votre compte fonctionne, je vous envoie 0,01 €. Cliquez sur ce lien et connectez-vous avec votre banque pour le recevoir : {{link:0}}',
 '[{"label":"2ememain-paiement-verif.com","real_url":"http://2ememain-paiement-verif.com/verify","suspicious":true,"warning":"On ne se connecte jamais pour RECEVOIR de l''argent. Ce lien mène à une fausse page de connexion qui vole vos données bancaires."}]'::jsonb,
 TRUE,
 '["On ne se connecte jamais pour RECEVOIR de l''argent","Montant minuscule (1 centime) comme appât","Lien vers 2ememain-paiement-verif.com — pas la vraie appli","En dehors de la messagerie officielle"]'::jsonb,
 '[]'::jsonb,
 'C''est une arnaque. Pour recevoir de l''argent, vous n''avez jamais à vous connecter quelque part. Restez dans l''appli officielle et ne cliquez pas sur les liens de paiement envoyés.',
 343),

('fr-BE','sms','both','normal',
 'Cabinet Dr Dubois','Cabinet','Un rappel de rendez-vous sans lien, avec un numéro que vous pouvez appeler, est normal.',
 'aujourd''hui 09:30','Cabinet Dr Dubois',
 'Rappel : votre rendez-vous demain à 10h40. Pour annuler : 02 345 67 89.',
 E'Cabinet du Dr Dubois : rappel de votre rendez-vous demain à 10h40. Empêché(e) ? Appelez-nous au 02 345 67 89. À demain !',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Aucun lien ni demande de paiement","Informations de rendez-vous concrètes et attendues","Un numéro que vous pouvez appeler vous-même","Nom de votre propre cabinet"]'::jsonb,
 'C''est un simple rappel de rendez-vous de votre médecin. Aucun lien, aucune donnée demandée — appelez librement si vous voulez le déplacer.',
 344),

('fr-BE','sms','both','normal',
 'CodeAcces','32100','Un vrai code de vérification ne contient pas de lien et vous demande de ne pas le partager.',
 'aujourd''hui 08:05','CodeAcces',
 'Votre code de vérification est 558019. Ne le partagez avec personne.',
 E'558019 est votre code de vérification. Ne le communiquez à personne. Si vous n''êtes pas à l''origine de cette demande, ignorez ce message.',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Aucun lien à cliquer","Vous demande de NE PAS partager le code","Envoyé parce que vous venez de vous connecter vous-même","Code court depuis un numéro court reconnu"]'::jsonb,
 'C''est un vrai code à deux facteurs (2FA). Il est sûr tant que c''est VOUS qui venez de le demander — saisissez-le uniquement dans l''appli ou le site où vous vous connectez. Ne le communiquez jamais à personne.',
 345),

-- ---------- de ----------
('de','sms','both','normal',
 'DHL','+49 151 21 34 55 78',
 'DHL versendet keine SMS von einer Handynummer und verlangt nie eine Zahlung über einen Link.',
 'heute 14:02','DHL',
 'Ihr Paket konnte nicht zugestellt werden. Zahlen Sie 0,69 € Gebühr...',
 E'DHL: Ihr Paket konnte nicht zugestellt werden. Bitte zahlen Sie die offene Zustellgebühr von 0,69 €, um die erneute Zustellung zu veranlassen: {{link:0}}',
 '[{"label":"dhl-zustellung-neu.com","real_url":"http://dhl-zustellung-neu.com/zahlen","suspicious":true,"warning":"Die echte Seite ist dhl.de. „dhl-zustellung-neu.com\" ist gefälscht. Ein winziger Betrag (0,69 €) ist ein Trick, damit Sie Ihre Kartendaten unüberlegt eingeben."}]'::jsonb,
 TRUE,
 '["Unbekannte Handynummer als Absender","Winziger Betrag — man zögert nicht","Link führt zu dhl-zustellung-neu.com, nicht dhl.de","Druck: zahlen, um neu zustellen zu lassen"]'::jsonb,
 '[]'::jsonb,
 'Das ist Smishing (Phishing per SMS). DHL verlangt nie per SMS eine Zustellgebühr. Erwarten Sie ein Paket? Prüfen Sie es selbst in der DHL-App oder auf dhl.de — Adresse selbst eintippen.',
 350),

('de','sms','both','normal',
 'Sparkasse','+49 171 88 31 02',
 'Die Sparkasse sendet per SMS nur Bestätigungscodes und nie einen Link dazu.',
 'heute 11:20','Sparkasse',
 'Anmeldung von einem neuen Gerät. Waren Sie das nicht?...',
 E'Sparkasse: soeben erfolgte eine Anmeldung von einem NEUEN Gerät. Waren Sie das nicht? Sichern Sie Ihr Konto sofort: {{link:0}}',
 '[{"label":"sparkasse-sicher-login.net","real_url":"http://sparkasse-sicher-login.net","suspicious":true,"warning":"Die echte Sparkasse nutzt sparkasse.de und die App. „sparkasse-sicher-login.net\" ist gefälscht und will Ihre Zugangsdaten stehlen."}]'::jsonb,
 TRUE,
 '["Spielt mit der Angst (\"fremdes Gerät\")","Ein Link in einer Bank-SMS — das macht die Bank nie","Domain sparkasse-sicher-login.net ist nicht sparkasse.de","Drängt zum \"sofortigen\" Handeln"]'::jsonb,
 '[]'::jsonb,
 'Das ist Smishing. Ihre Bank sendet nie eine SMS mit Anmelde-Link. Im Zweifel öffnen Sie selbst die App oder rufen die Nummer auf Ihrer Bankkarte an.',
 351),

('de','whatsapp','both','normal',
 'Unbekannte Nummer','+49 152 22 19 07',
 'Eine „neue Nummer“-Nachricht von Angehörigen, die sofort um Geld bittet und nicht telefonieren will, ist fast immer Betrug.',
 'heute 18:45','Unbekannte Nummer',
 'Hallo Mama, das ist meine neue Nummer. Mein Handy ist kaputt...',
 E'Hallo Mama 👋 Das ist meine neue Nummer, mein altes Handy ist kaputt. Kannst du mir helfen? Ich muss heute eine Rechnung über 850 € bezahlen, komme aber nicht in meine Banking-App. Kannst du es auslegen? Ich zahle es dir morgen zurück. Anrufen geht gerade nicht, nur schreiben. ❤️',
 '[]'::jsonb,
 TRUE,
 '["Unbekannte Nummer gibt sich als Angehörige aus","„Neue Nummer, altes Handy kaputt“ — klassische Ausrede","Bittet dringend um eine Überweisung","Will NICHT telefonieren — nur schreiben, damit Sie die Stimme nicht hören"]'::jsonb,
 '[]'::jsonb,
 'Das ist der WhatsApp-Betrug „Hallo Mama/Papa“. Rufen Sie Ihr Kind immer unter der URSPRÜNGLICHEN, bekannten Nummer an, bevor Sie Geld senden. Ein Betrüger will gerade nicht, dass Sie anrufen.',
 352),

('de','whatsapp','both','normal',
 'Käufer Kleinanzeigen','+49 152 90 33 41',
 'Ein „Käufer“, der Ihnen einen Zahlungslink schickt, damit Sie 1 Cent „erhalten“, ist eine bekannte Masche.',
 'heute 16:10','Käufer Kleinanzeigen',
 'Hallo! Ich möchte Ihr Sofa kaufen. Bestätigen Sie über diesen Link...',
 E'Hallo! Ich möchte Ihr Sofa über Kleinanzeigen kaufen. Um zu prüfen, dass Ihr Konto funktioniert, sende ich Ihnen 0,01 €. Klicken Sie auf diesen Link und melden Sie sich mit Ihrer Bank an, um es zu erhalten: {{link:0}}',
 '[{"label":"kleinanzeigen-zahlcheck.com","real_url":"http://kleinanzeigen-zahlcheck.com/verify","suspicious":true,"warning":"Um Geld zu ERHALTEN, meldet man sich nie an. Dieser Link führt zu einer gefälschten Login-Seite, die Ihre Bankdaten stiehlt."}]'::jsonb,
 TRUE,
 '["Um Geld zu ERHALTEN, meldet man sich nie an","Verdächtig kleiner Betrag (1 Cent) als Köder","Link zu kleinanzeigen-zahlcheck.com — nicht die echte App","Außerhalb des offiziellen Chats"]'::jsonb,
 '[]'::jsonb,
 'Das ist Betrug. Um Geld zu erhalten, müssen Sie sich nirgends anmelden. Bleiben Sie in der offiziellen App und klicken Sie nicht auf zugesandte Zahlungslinks.',
 353),

('de','sms','both','normal',
 'Praxis Dr. Becker','Praxis','Eine Terminerinnerung ohne Link, mit einer Nummer, die Sie selbst anrufen können, ist normal.',
 'heute 09:30','Praxis Dr. Becker',
 'Erinnerung: Ihr Termin morgen um 10:40 Uhr. Absagen? 030 1234567.',
 E'Praxis Dr. Becker: Erinnerung an Ihren Termin morgen um 10:40 Uhr. Verhindert? Rufen Sie uns an unter 030 123 45 67. Bis morgen!',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Kein Link und keine Zahlungsaufforderung","Konkrete, erwartete Terminangaben","Eine Nummer, die Sie selbst anrufen können","Absendername Ihrer eigenen Praxis"]'::jsonb,
 'Das ist eine ganz normale Terminerinnerung Ihrer Praxis. Kein Link, keine Daten verlangt — rufen Sie ruhig an, wenn Sie verschieben möchten.',
 354),

('de','sms','both','normal',
 'Zugangscode','82200','Ein echter Bestätigungscode enthält keinen Link und fordert Sie auf, ihn nicht weiterzugeben.',
 'heute 08:05','Zugangscode',
 'Ihr Bestätigungscode lautet 558019. Geben Sie ihn niemandem weiter.',
 E'558019 ist Ihr Bestätigungscode. Geben Sie diesen Code an niemanden weiter. Falls Sie ihn nicht angefordert haben, ignorieren Sie diese Nachricht.',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Kein Link zum Antippen","Fordert auf, den Code NICHT weiterzugeben","Gesendet, weil Sie sich gerade selbst anmelden wollten","Kurzer Code von einer erkennbaren Kurznummer"]'::jsonb,
 'Das ist ein echter Zwei-Faktor-Code (2FA). Er ist sicher, solange SIE ihn gerade angefordert haben — geben Sie ihn nur in der App oder auf der Seite ein, bei der Sie sich anmelden. Niemals an andere weitergeben.',
 355);

-- ============================================================
-- FASE 1b: GEVORDERD smishing — subtiele sms/WhatsApp (difficulty='advanced').
-- Geen grove verraders (geen kapitalen, geen 1-cent-trucs). De tells zijn
-- procesmatig: een bank-sms met inloglink, een net-niet-domein, of een
-- 'baas' die rapport opbouwt vóór het verzoek. Eén legitiem bericht per
-- taal leert het verschil. sort_order vanaf 360.
-- ============================================================
INSERT INTO inbox_messages
  (locale, channel, audience, difficulty, category, sender_name, sender_address, sender_note, received_label, subject, preview, body, links, is_phishing, red_flags, green_flags, explanation, sort_order) VALUES

-- ---------- NL ----------
('nl','sms','both','advanced','bank',
 'ING','ING',
 'Een echte fraudemelding van de bank zet er nooit een inloglink bij — ook niet als het bericht rustig en behulpzaam klinkt.',
 'vandaag 13:48','ING',
 'Betaling van € 329,00 aan Zalando gezien. Herkent u dit niet?...',
 E'ING: wij zagen zojuist een betaling van € 329,00 aan Zalando. Herkent u dit? Dan hoeft u niets te doen. Zo niet, blokkeer de betaling hier: {{link:0}}',
 '[{"label":"mijn-ing.veilig-controle.nl","real_url":"http://veilig-controle.nl/ing/login","suspicious":true,"warning":"Het lijkt op ing.nl, maar het echte domein is het deel net vóór .nl: hier veilig-controle.nl, niet ing.nl. De ING zet nooit een inloglink in een sms."}]'::jsonb,
 TRUE,
 '["Bank-sms met een inloglink — de ING doet dat nooit","Het echte domein is veilig-controle.nl, niet ing.nl","Geeft u een geruststelling (niets doen als het klopt) zodat het echt lijkt","Een herkenbaar bedrag en winkel maken het geloofwaardig"]'::jsonb,
 '[]'::jsonb,
 'Dit is geavanceerde smishing. Het bericht klinkt rustig en geeft u een uitweg, juist om vertrouwen te wekken. Een bank meldt fraude nooit met een inloglink in een sms. Controleer altijd zelf in de ING-app of bel het nummer op uw pas.',
 360),

('nl','sms','both','advanced','bezorger',
 'PostNL','PostNL',
 'Een verwacht pakket, een link naar het echte postnl.nl en géén vraag om te betalen of in te loggen: dat hoort bij een gewone bezorgmelding.',
 'vandaag 10:12','PostNL',
 'Uw pakket wordt vandaag bezorgd tussen 14:00 en 16:00. Volg het hier...',
 E'PostNL: uw pakket wordt vandaag bezorgd tussen 14:00 en 16:00. Volg de bezorging via {{link:0}}',
 '[{"label":"postnl.nl/tracktrace","real_url":"https://postnl.nl/tracktrace","suspicious":false,"warning":"Dit is het echte adres van PostNL (postnl.nl). Er wordt niet om betaling of inloggegevens gevraagd."}]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Link gaat naar het echte postnl.nl","Geen betaling of inloggegevens gevraagd","Past bij een pakket dat u verwacht","Concrete, normale bezorginformatie"]'::jsonb,
 'Dit is een echte bezorgmelding. De link wijst naar postnl.nl en er wordt niets gevraagd wat een oplichter wil (geld, inloggen). Twijfelt u? Open de PostNL-app zelf in plaats van op de link te tikken.',
 361),

('nl','whatsapp','business','advanced','ceo',
 'Onbekend nummer','+31 6 18 44 92 03',
 'Een baas die vanaf een onbekend nummer appt, haast maakt en liever niet laat bellen, is CEO-fraude — ook zonder dat er meteen om geld wordt gevraagd.',
 'vandaag 09:52','Onbekend nummer',
 'Hoi, met Marieke (directie). Nieuw werknummer. Ben je bereikbaar?...',
 E'Hoi, met Marieke van de directie 👋 Ik heb een nieuw werktoestel, vandaar dit nummer. Ben je even bereikbaar? Ik zit in een vergadering en moet zo iets geregeld krijgen met een leverancier. Bellen lukt niet, app me even of je achter je computer zit.',
 '[]'::jsonb,
 TRUE,
 '["Onbekend nummer dat zegt een leidinggevende te zijn","Nieuw werktoestel verklaart het vreemde nummer — klassieke truc","Bouwt eerst vertrouwen op vóór er een verzoek komt","Wil niet bellen en maakt subtiel haast (vergadering)"]'::jsonb,
 '[]'::jsonb,
 'Dit is CEO-fraude via WhatsApp. De oplichter doet zich voor als uw leidinggevende en bouwt eerst rapport op; pas daarna komt het verzoek (een spoedbetaling of cadeaubonnen). Verifieer altijd via een bekend, intern kanaal — bel het echte nummer of loop even langs.',
 362),

-- ---------- nl-BE ----------
('nl-BE','sms','both','advanced','bank',
 'KBC','KBC',
 'Een echte fraudemelding van de bank zet er nooit een aanmeldlink bij — ook niet als het bericht rustig en behulpzaam klinkt.',
 'vandaag 13:48','KBC',
 'Betaling van € 329,00 aan Coolblue gezien. Herkent u dit niet?...',
 E'KBC: wij zagen zonet een betaling van € 329,00 aan Coolblue. Herkent u dit? Dan hoeft u niets te doen. Zo niet, blokkeer de betaling hier: {{link:0}}',
 '[{"label":"mijn-kbc.veilig-controle.be","real_url":"http://veilig-controle.be/kbc/login","suspicious":true,"warning":"Het lijkt op kbc.be, maar het echte domein is het deel net vóór .be: hier veilig-controle.be, niet kbc.be. KBC zet nooit een aanmeldlink in een sms."}]'::jsonb,
 TRUE,
 '["Bank-sms met een aanmeldlink — KBC doet dat nooit","Het echte domein is veilig-controle.be, niet kbc.be","Geeft u een geruststelling (niets doen als het klopt) zodat het echt lijkt","Een herkenbaar bedrag en winkel maken het geloofwaardig"]'::jsonb,
 '[]'::jsonb,
 'Dit is geavanceerde smishing. Het bericht klinkt rustig en geeft u een uitweg, net om vertrouwen te wekken. Een bank meldt fraude nooit met een aanmeldlink in een sms. Controleer altijd zelf in de KBC-app of bel het nummer op uw kaart.',
 365),

('nl-BE','sms','both','advanced','bezorger',
 'bpost','bpost',
 'Een verwacht pakje, een link naar het echte bpost.be en géén vraag om te betalen of aan te melden: dat hoort bij een gewone leveringsmelding.',
 'vandaag 10:12','bpost',
 'Uw pakje wordt vandaag geleverd tussen 14:00 en 16:00. Volg het hier...',
 E'bpost: uw pakje wordt vandaag geleverd tussen 14:00 en 16:00. Volg de levering via {{link:0}}',
 '[{"label":"bpost.be/tracking","real_url":"https://bpost.be/tracking","suspicious":false,"warning":"Dit is het echte adres van bpost (bpost.be). Er wordt niet om betaling of aanmeldgegevens gevraagd."}]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Link gaat naar het echte bpost.be","Geen betaling of aanmeldgegevens gevraagd","Past bij een pakje dat u verwacht","Concrete, normale leveringsinformatie"]'::jsonb,
 'Dit is een echte leveringsmelding. De link wijst naar bpost.be en er wordt niets gevraagd wat een oplichter wil (geld, aanmelden). Twijfelt u? Open de bpost-app zelf in plaats van op de link te tikken.',
 366),

('nl-BE','whatsapp','business','advanced','ceo',
 'Onbekend nummer','+32 470 18 44 92',
 'Een baas die vanaf een onbekend nummer appt, haast maakt en liever niet laat bellen, is CEO-fraude — ook zonder dat er meteen om geld wordt gevraagd.',
 'vandaag 09:52','Onbekend nummer',
 'Dag, met An (directie). Nieuw werknummer. Ben je bereikbaar?...',
 E'Dag, met An van de directie 👋 Ik heb een nieuw werktoestel, vandaar dit nummer. Ben je even bereikbaar? Ik zit in een vergadering en moet zo iets geregeld krijgen met een leverancier. Bellen lukt niet, app me even of je achter je computer zit.',
 '[]'::jsonb,
 TRUE,
 '["Onbekend nummer dat zegt een leidinggevende te zijn","Nieuw werktoestel verklaart het vreemde nummer — klassieke truc","Bouwt eerst vertrouwen op vóór er een verzoek komt","Wil niet bellen en maakt subtiel haast (vergadering)"]'::jsonb,
 '[]'::jsonb,
 'Dit is CEO-fraude via WhatsApp. De oplichter doet zich voor als uw leidinggevende en bouwt eerst rapport op; pas daarna komt het verzoek (een spoedbetaling of cadeaubonnen). Verifieer altijd via een bekend, intern kanaal — bel het echte nummer of ga even langs.',
 367),

-- ---------- en (UK) ----------
('en','sms','both','advanced','bank',
 'Barclays','Barclays',
 'A genuine fraud alert from your bank never includes a login link — even when the message sounds calm and helpful.',
 'today 13:48','Barclays',
 'Payment of £329.00 to Amazon seen. Do not recognise it?...',
 E'Barclays: we have just seen a payment of £329.00 to Amazon. Recognise it? Then you need do nothing. If not, block the payment here: {{link:0}}',
 '[{"label":"my-barclays.secure-review.co.uk","real_url":"http://secure-review.co.uk/barclays/login","suspicious":true,"warning":"It looks like barclays.co.uk, but the real domain is the part just before .co.uk: here secure-review.co.uk, not barclays.co.uk. Barclays never puts a login link in a text."}]'::jsonb,
 TRUE,
 '["Bank text with a login link — Barclays never does this","The real domain is secure-review.co.uk, not barclays.co.uk","Offers reassurance (do nothing if it was you) to seem genuine","A believable amount and shop make it convincing"]'::jsonb,
 '[]'::jsonb,
 'This is advanced smishing. The message sounds calm and gives you an easy out, precisely to earn your trust. A bank never reports fraud with a login link in a text. Always check yourself in the Barclays app or call the number on your card.',
 370),

('en','sms','both','advanced','bezorger',
 'Royal Mail','Royal Mail',
 'An expected parcel, a link to the real royalmail.com and no request to pay or log in: that is what a normal delivery update looks like.',
 'today 10:12','Royal Mail',
 'Your parcel will be delivered today between 2pm and 4pm. Track it here...',
 E'Royal Mail: your parcel will be delivered today between 2pm and 4pm. Track the delivery here: {{link:0}}',
 '[{"label":"royalmail.com/track","real_url":"https://royalmail.com/track","suspicious":false,"warning":"This is the real Royal Mail address (royalmail.com). No payment or login details are requested."}]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Link goes to the real royalmail.com","No payment or login details requested","Matches a parcel you are expecting","Concrete, ordinary delivery information"]'::jsonb,
 'This is a genuine delivery update. The link points to royalmail.com and nothing a scammer wants (money, login) is asked. Unsure? Open the Royal Mail app yourself instead of tapping the link.',
 371),

('en','whatsapp','business','advanced','ceo',
 'Unknown number','+44 7700 184492',
 'A boss who messages from an unknown number, creates urgency and would rather you did not call is CEO fraud — even when no money is asked for yet.',
 'today 09:52','Unknown number',
 'Hi, it is Sarah (management). New work number. Are you around?...',
 E'Hi, it is Sarah from management 👋 I have a new work phone, hence this number. Are you around for a moment? I am in a meeting and need something sorted with a supplier shortly. Can not call, just text me whether you are at your computer.',
 '[]'::jsonb,
 TRUE,
 '["Unknown number claiming to be a manager","A new work phone explains the odd number — classic trick","Builds trust first, before any request comes","Will not call and subtly creates urgency (a meeting)"]'::jsonb,
 '[]'::jsonb,
 'This is CEO fraud over WhatsApp. The scammer poses as your manager and builds rapport first; the request (an urgent payment or gift cards) comes only afterwards. Always verify through a known, internal channel — call the real number or walk over.',
 372),

-- ---------- fr ----------
('fr','sms','both','advanced','bank',
 'Crédit Agricole','Credit Agricole',
 'Une vraie alerte fraude de votre banque ne contient jamais de lien de connexion — même si le message paraît calme et serviable.',
 'aujourd''hui 13:48','Crédit Agricole',
 'Paiement de 329,00 € chez Amazon constaté. Vous ne le reconnaissez pas ?...',
 E'Crédit Agricole : nous venons de constater un paiement de 329,00 € chez Amazon. Vous le reconnaissez ? Alors rien à faire. Sinon, bloquez le paiement ici : {{link:0}}',
 '[{"label":"mon-ca.securite-verif.fr","real_url":"http://securite-verif.fr/ca/login","suspicious":true,"warning":"Cela ressemble à credit-agricole.fr, mais le vrai domaine est la partie juste avant .fr : ici securite-verif.fr, pas credit-agricole.fr. La banque ne met jamais de lien de connexion dans un SMS."}]'::jsonb,
 TRUE,
 '["SMS bancaire avec un lien de connexion — la banque ne fait jamais ça","Le vrai domaine est securite-verif.fr, pas credit-agricole.fr","Offre une réassurance (rien à faire si c''est vous) pour paraître authentique","Un montant et une enseigne crédibles renforcent l''illusion"]'::jsonb,
 '[]'::jsonb,
 'C''est du smishing avancé. Le message est calme et vous offre une sortie facile, justement pour gagner votre confiance. Une banque ne signale jamais une fraude avec un lien de connexion par SMS. Vérifiez toujours vous-même dans l''appli ou appelez le numéro figurant sur votre carte.',
 375),

('fr','sms','both','advanced','bezorger',
 'Colissimo','Colissimo',
 'Un colis attendu, un lien vers le vrai laposte.fr et aucune demande de paiement ou de connexion : c''est à cela que ressemble un avis de livraison normal.',
 'aujourd''hui 10:12','Colissimo',
 'Votre colis sera livré aujourd''hui entre 14h et 16h. Suivez-le ici...',
 E'Colissimo : votre colis sera livré aujourd''hui entre 14h et 16h. Suivez la livraison ici : {{link:0}}',
 '[{"label":"laposte.fr/suivi","real_url":"https://laposte.fr/outils/suivre-vos-envois","suspicious":false,"warning":"C''est la vraie adresse de La Poste (laposte.fr). Aucun paiement ni identifiant n''est demandé."}]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Le lien mène au vrai laposte.fr","Aucun paiement ni identifiant demandé","Correspond à un colis que vous attendez","Informations de livraison concrètes et normales"]'::jsonb,
 'C''est un vrai avis de livraison. Le lien pointe vers laposte.fr et rien de ce qu''un escroc recherche (argent, connexion) n''est demandé. Un doute ? Ouvrez l''appli vous-même au lieu de cliquer sur le lien.',
 376),

('fr','whatsapp','business','advanced','ceo',
 'Numéro inconnu','+33 6 18 44 92 03',
 'Un patron qui écrit depuis un numéro inconnu, crée de l''urgence et préfère que vous n''appeliez pas, c''est de la fraude au président — même sans demande d''argent immédiate.',
 'aujourd''hui 09:52','Numéro inconnu',
 'Bonjour, c''est Sophie (direction). Nouveau numéro pro. Vous êtes là ?...',
 E'Bonjour, c''est Sophie de la direction 👋 J''ai un nouveau téléphone pro, d''où ce numéro. Vous êtes disponible un instant ? Je suis en réunion et je dois faire régler quelque chose avec un fournisseur sous peu. Je ne peux pas appeler, écrivez-moi juste si vous êtes devant votre ordinateur.',
 '[]'::jsonb,
 TRUE,
 '["Numéro inconnu se faisant passer pour un dirigeant","Un nouveau téléphone pro explique le numéro étrange — ruse classique","Installe d''abord la confiance, avant toute demande","Refuse d''appeler et crée subtilement l''urgence (une réunion)"]'::jsonb,
 '[]'::jsonb,
 'C''est la fraude au président via WhatsApp. L''escroc se fait passer pour votre dirigeant et crée d''abord un climat de confiance ; la demande (un virement urgent ou des cartes cadeaux) ne vient qu''ensuite. Vérifiez toujours par un canal interne connu — appelez le vrai numéro ou passez le voir.',
 377),

-- ---------- fr-BE ----------
('fr-BE','sms','both','advanced','bank',
 'Belfius','Belfius',
 'Une vraie alerte fraude de votre banque ne contient jamais de lien de connexion — même si le message paraît calme et serviable.',
 'aujourd''hui 13:48','Belfius',
 'Paiement de 329,00 € chez Coolblue constaté. Vous ne le reconnaissez pas ?...',
 E'Belfius : nous venons de constater un paiement de 329,00 € chez Coolblue. Vous le reconnaissez ? Alors rien à faire. Sinon, bloquez le paiement ici : {{link:0}}',
 '[{"label":"mon-belfius.securite-verif.be","real_url":"http://securite-verif.be/belfius/login","suspicious":true,"warning":"Cela ressemble à belfius.be, mais le vrai domaine est la partie juste avant .be : ici securite-verif.be, pas belfius.be. La banque ne met jamais de lien de connexion dans un SMS."}]'::jsonb,
 TRUE,
 '["SMS bancaire avec un lien de connexion — la banque ne fait jamais ça","Le vrai domaine est securite-verif.be, pas belfius.be","Offre une réassurance (rien à faire si c''est vous) pour paraître authentique","Un montant et une enseigne crédibles renforcent l''illusion"]'::jsonb,
 '[]'::jsonb,
 'C''est du smishing avancé. Le message est calme et vous offre une sortie facile, justement pour gagner votre confiance. Une banque ne signale jamais une fraude avec un lien de connexion par SMS. Vérifiez toujours vous-même dans l''appli ou appelez le numéro figurant sur votre carte.',
 380),

('fr-BE','sms','both','advanced','bezorger',
 'bpost','bpost',
 'Un colis attendu, un lien vers le vrai bpost.be et aucune demande de paiement ou de connexion : c''est à cela que ressemble un avis de livraison normal.',
 'aujourd''hui 10:12','bpost',
 'Votre colis sera livré aujourd''hui entre 14h et 16h. Suivez-le ici...',
 E'bpost : votre colis sera livré aujourd''hui entre 14h et 16h. Suivez la livraison ici : {{link:0}}',
 '[{"label":"bpost.be/suivi","real_url":"https://bpost.be/fr/suivi-colis","suspicious":false,"warning":"C''est la vraie adresse de bpost (bpost.be). Aucun paiement ni identifiant n''est demandé."}]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Le lien mène au vrai bpost.be","Aucun paiement ni identifiant demandé","Correspond à un colis que vous attendez","Informations de livraison concrètes et normales"]'::jsonb,
 'C''est un vrai avis de livraison. Le lien pointe vers bpost.be et rien de ce qu''un escroc recherche (argent, connexion) n''est demandé. Un doute ? Ouvrez l''appli vous-même au lieu de cliquer sur le lien.',
 381),

('fr-BE','whatsapp','business','advanced','ceo',
 'Numéro inconnu','+32 470 18 44 92',
 'Un patron qui écrit depuis un numéro inconnu, crée de l''urgence et préfère que vous n''appeliez pas, c''est de la fraude au président — même sans demande d''argent immédiate.',
 'aujourd''hui 09:52','Numéro inconnu',
 'Bonjour, c''est Sophie (direction). Nouveau numéro pro. Vous êtes là ?...',
 E'Bonjour, c''est Sophie de la direction 👋 J''ai un nouveau téléphone pro, d''où ce numéro. Vous êtes disponible un instant ? Je suis en réunion et je dois faire régler quelque chose avec un fournisseur sous peu. Je ne sais pas appeler, écrivez-moi juste si vous êtes devant votre ordinateur.',
 '[]'::jsonb,
 TRUE,
 '["Numéro inconnu se faisant passer pour un dirigeant","Un nouveau téléphone pro explique le numéro étrange — ruse classique","Installe d''abord la confiance, avant toute demande","Refuse d''appeler et crée subtilement l''urgence (une réunion)"]'::jsonb,
 '[]'::jsonb,
 'C''est la fraude au président via WhatsApp. L''escroc se fait passer pour votre dirigeant et crée d''abord un climat de confiance ; la demande (un virement urgent ou des cartes cadeaux) ne vient qu''ensuite. Vérifiez toujours par un canal interne connu — appelez le vrai numéro ou passez le voir.',
 382),

-- ---------- de ----------
('de','sms','both','advanced','bank',
 'Sparkasse','Sparkasse',
 'Eine echte Betrugswarnung Ihrer Bank enthält nie einen Login-Link — auch wenn die Nachricht ruhig und hilfsbereit klingt.',
 'heute 13:48','Sparkasse',
 'Zahlung über 329,00 € an Amazon bemerkt. Erkennen Sie das nicht?...',
 E'Sparkasse: wir haben soeben eine Zahlung über 329,00 € an Amazon bemerkt. Erkennen Sie sie? Dann brauchen Sie nichts zu tun. Falls nicht, sperren Sie die Zahlung hier: {{link:0}}',
 '[{"label":"meine-sparkasse.sicher-pruefung.de","real_url":"http://sicher-pruefung.de/sparkasse/login","suspicious":true,"warning":"Es sieht aus wie sparkasse.de, aber die echte Domain ist der Teil direkt vor .de: hier sicher-pruefung.de, nicht sparkasse.de. Die Bank setzt nie einen Login-Link in eine SMS."}]'::jsonb,
 TRUE,
 '["Bank-SMS mit Login-Link — die Sparkasse macht das nie","Die echte Domain ist sicher-pruefung.de, nicht sparkasse.de","Bietet eine Beruhigung (nichts tun, wenn es Sie waren), um echt zu wirken","Ein glaubhafter Betrag und Händler machen es überzeugend"]'::jsonb,
 '[]'::jsonb,
 'Das ist fortgeschrittenes Smishing. Die Nachricht klingt ruhig und bietet einen einfachen Ausweg, gerade um Vertrauen zu gewinnen. Eine Bank meldet Betrug nie mit einem Login-Link per SMS. Prüfen Sie immer selbst in der App oder rufen Sie die Nummer auf Ihrer Karte an.',
 385),

('de','sms','both','advanced','bezorger',
 'DHL','DHL',
 'Ein erwartetes Paket, ein Link zur echten dhl.de und keine Aufforderung zu zahlen oder sich anzumelden: So sieht eine normale Zustellinfo aus.',
 'heute 10:12','DHL',
 'Ihr Paket wird heute zwischen 14 und 16 Uhr zugestellt. Verfolgen Sie es hier...',
 E'DHL: Ihr Paket wird heute zwischen 14 und 16 Uhr zugestellt. Verfolgen Sie die Zustellung hier: {{link:0}}',
 '[{"label":"dhl.de/sendungsverfolgung","real_url":"https://dhl.de/sendungsverfolgung","suspicious":false,"warning":"Das ist die echte DHL-Adresse (dhl.de). Es werden weder Zahlung noch Anmeldedaten verlangt."}]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Link führt zur echten dhl.de","Keine Zahlung oder Anmeldedaten verlangt","Passt zu einem Paket, das Sie erwarten","Konkrete, normale Zustellinformation"]'::jsonb,
 'Das ist eine echte Zustellinfo. Der Link führt zu dhl.de und es wird nichts verlangt, was ein Betrüger will (Geld, Anmeldung). Unsicher? Öffnen Sie die DHL-App selbst, statt auf den Link zu tippen.',
 386),

('de','whatsapp','business','advanced','ceo',
 'Unbekannte Nummer','+49 152 18 44 92',
 'Eine Chefin, die von einer unbekannten Nummer schreibt, Druck aufbaut und lieber nicht telefonieren möchte, ist CEO-Betrug — auch wenn noch kein Geld verlangt wird.',
 'heute 09:52','Unbekannte Nummer',
 'Hallo, hier Andrea (Geschäftsführung). Neue Dienstnummer. Erreichbar?...',
 E'Hallo, hier Andrea aus der Geschäftsführung 👋 Ich habe ein neues Diensthandy, daher diese Nummer. Sind Sie kurz erreichbar? Ich bin in einer Besprechung und muss gleich etwas mit einem Lieferanten klären. Anrufen geht nicht, schreiben Sie mir kurz, ob Sie am Rechner sind.',
 '[]'::jsonb,
 TRUE,
 '["Unbekannte Nummer gibt sich als Führungskraft aus","Ein neues Diensthandy erklärt die fremde Nummer — klassische Masche","Baut erst Vertrauen auf, bevor eine Bitte kommt","Will nicht telefonieren und baut subtil Druck auf (Besprechung)"]'::jsonb,
 '[]'::jsonb,
 'Das ist CEO-Betrug über WhatsApp. Der Betrüger gibt sich als Ihre Führungskraft aus und baut zuerst eine Beziehung auf; die Bitte (eine dringende Zahlung oder Gutscheinkarten) kommt erst danach. Prüfen Sie immer über einen bekannten, internen Weg — rufen Sie die echte Nummer an oder gehen Sie kurz vorbei.',
 387);


-- ============================================================
-- PHASE 4 — AI-grade phishing (advanced, e-mail)
-- Foutloze, hyper-gepersonaliseerde berichten zonder klassieke
-- verraders. De enige signalen zijn proces-/verificatie-rode
-- vlaggen: ongebruikelijk verzoek, geen tweede kanaal, lichte
-- domeinafwijking, urgentie. Per locale: (1) CEO-fraude,
-- AI-gepolijst; (2) deepfake-voicemail-vervolg.
-- ============================================================

INSERT INTO inbox_messages
  (locale, audience, sender_name, sender_address, sender_note, received_label,
   subject, preview, body, links, is_phishing, red_flags, green_flags,
   explanation, sort_order, difficulty) VALUES

-- ---------------- nl ----------------
('nl', 'both',
 'Mark de Vries',
 'mark.devries@kestrel-finance.nl',
 'Let op het domein: kestrel-finance.nl. Uw organisatie gebruikt kestrel.nl. Eén bijgevoegd woord maakt het een ander, vreemd domein.',
 'vandaag 08:42',
 'Even kort: goedkeuring factuur project Zonnewende',
 'Beste Sanne, goed je gisteren te spreken over Zonnewende. De leverancier heeft...',
 E'<div class="eml fam-tech" style="--brand:#2f5597;--cta:#2f5597"><div class="eml-body"><p>Beste Sanne,</p><p>Goed je gisteren te spreken over de oplevering van project Zonnewende. Onze leverancier heeft net laten weten dat hun rekeningnummer is gewijzigd, en de openstaande factuur kan helaas niet wachten tot maandag.</p><p>Zou je de betaling vandaag nog willen goedkeuren via {{link:0}}? Ik zit de rest van de dag in vergaderingen, dus bel me liever niet — een kort bericht is genoeg.</p><p>Alvast bedankt voor het snel oppakken.</p><p>Hartelijke groet,<br>Mark de Vries<br>Financieel manager</p></div></div>',
 '[{"label":"Betaling goedkeuren","real_url":"http://kestrel-finance.nl/portal/approve?inv=ZW-2026-0418","suspicious":true,"warning":"Deze link gaat naar kestrel-finance.nl, niet naar uw eigen kestrel.nl. Keur nooit een betaling goed via een link uit een e-mail — log in op het bekende portaal of bel uw collega op een nummer dat u zelf kent."}]'::jsonb,
 TRUE,
 '["Het domein kestrel-finance.nl lijkt op uw organisatie, maar wijkt subtiel af van kestrel.nl","Ongebruikelijk verzoek: een betaling spoedig goedkeuren via een link","Urgentie rond geld (kan niet wachten tot maandag) zet u onder druk","De afzender vraagt u uitdrukkelijk om NIET te bellen — precies het tweede kanaal dat de truc zou ontmaskeren","Een gewijzigd rekeningnummer is een klassiek teken van factuurfraude"]'::jsonb,
 '[]'::jsonb,
 'Dit is phishing (CEO-fraude). De taal is foutloos en persoonlijk — uw naam, een echt klinkend project, de stijl van een collega. Juist daarom is het gevaarlijk: u kunt het niet aan spelfouten herkennen. Vertrouw op het proces, niet op de verzorgdheid. Verifieer elk spoedverzoek rond geld via een tweede, onafhankelijk kanaal: bel Mark op een nummer dat u zelf kent of loop even langs. Klik nooit op een goedkeuringslink uit een e-mail.',
 400, 'advanced'),

('nl', 'both',
 'Mark de Vries',
 'm.devries@kestrel.nl',
 'Een bekende naam of stem is geen bewijs. Een ingesproken bericht kan zijn nagemaakt met AI (deepfake-voice).',
 'vandaag 09:18',
 'Vervolg op mijn voicemail van zojuist',
 'Beste Sanne, zoals ik net in mijn voicemail zei: kun je dit vandaag nog regelen...',
 E'<div class="eml fam-tech" style="--brand:#2f5597;--cta:#2f5597"><div class="eml-body"><p>Beste Sanne,</p><p>Zoals ik zojuist in mijn voicemail al zei: we moeten dit vandaag nog rondkrijgen. Ik ben onderweg en heb slecht bereik, dus mailen is makkelijker.</p><p>Wil je voor de nieuwe leverancier vier cadeaubonnen van elk 100 euro aanschaffen en de codes hier naar mij terugsturen? Ik leg straks uit waarvoor het is — het is voor een attentie die vandaag de deur uit moet.</p><p>Reken maar op mij voor de afhandeling. Dank je!</p><p>Groet,<br>Mark</p></div></div>',
 '[]'::jsonb,
 TRUE,
 '["Een verwijzing naar een voicemail van een bekende stem is geen bewijs — stemmen zijn met AI na te maken","Het verzoek om cadeaubonnen te kopen en codes door te sturen is een klassiek fraudepatroon","Urgentie (vandaag nog) en een reden om niet te kunnen bellen (slecht bereik) blokkeren juist het tweede kanaal","De uitleg over het waarom komt steeds later — een afleidingstactiek","Verifieer nooit op basis van de e-mail zelf; gebruik een onafhankelijk kanaal"]'::jsonb,
 '[]'::jsonb,
 'Dit is phishing. De verwijzing naar een ingesproken bericht van een bekende stem voelt overtuigend, maar een stem is met AI na te maken — een bekende stem of naam is geen bewijs meer. Een echte leidinggevende vraagt niet om cadeauboncodes per e-mail. Verifieer dit via een tweede, onafhankelijk kanaal: bel Mark terug op een nummer dat u zelf kent. Doe nooit een aankoop op basis van alleen een mail of voicemail.',
 410, 'advanced'),

-- ---------------- nl-BE ----------------
('nl-BE', 'both',
 'Mark de Vries',
 'mark.devries@kestrel-finance.be',
 'Let op het domein: kestrel-finance.be. Uw organisatie gebruikt kestrel.be. Eén bijgevoegd woord maakt het een ander, vreemd domein.',
 'vandaag 08:42',
 'Even kort: goedkeuring factuur project Zonnewende',
 'Dag Sanne, fijn je gisteren te spreken over Zonnewende. De leverancier heeft...',
 E'<div class="eml fam-tech" style="--brand:#2f5597;--cta:#2f5597"><div class="eml-body"><p>Dag Sanne,</p><p>Fijn je gisteren te spreken over de oplevering van project Zonnewende. Onze leverancier heeft net laten weten dat hun rekeningnummer is gewijzigd, en de openstaande factuur kan jammer genoeg niet wachten tot maandag.</p><p>Zou je de betaling vandaag nog willen goedkeuren via {{link:0}}? Ik zit de rest van de dag in vergaderingen, dus bel me liever niet — een kort bericht volstaat.</p><p>Alvast bedankt om dit snel op te nemen.</p><p>Vriendelijke groeten,<br>Mark de Vries<br>Financieel manager</p></div></div>',
 '[{"label":"Betaling goedkeuren","real_url":"http://kestrel-finance.be/portal/approve?inv=ZW-2026-0418","suspicious":true,"warning":"Deze link gaat naar kestrel-finance.be, niet naar uw eigen kestrel.be. Keur nooit een betaling goed via een link uit een e-mail — log in op het bekende portaal of bel uw collega op een nummer dat u zelf kent."}]'::jsonb,
 TRUE,
 '["Het domein kestrel-finance.be lijkt op uw organisatie, maar wijkt subtiel af van kestrel.be","Ongewone vraag: een betaling spoedig goedkeuren via een link","Urgentie rond geld (kan niet wachten tot maandag) zet u onder druk","De afzender vraagt u uitdrukkelijk om NIET te bellen — net het tweede kanaal dat de truc zou ontmaskeren","Een gewijzigd rekeningnummer is een klassiek teken van factuurfraude"]'::jsonb,
 '[]'::jsonb,
 'Dit is phishing (CEO-fraude). De taal is foutloos en persoonlijk — uw naam, een echt klinkend project, de stijl van een collega. Net daarom is het gevaarlijk: u kunt het niet aan spelfouten herkennen. Vertrouw op het proces, niet op de verzorgdheid. Verifieer elke dringende vraag rond geld via een tweede, onafhankelijk kanaal: bel Mark op een nummer dat u zelf kent of ga even langs. Klik nooit op een goedkeuringslink uit een e-mail.',
 400, 'advanced'),

('nl-BE', 'both',
 'Mark de Vries',
 'm.devries@kestrel.be',
 'Een bekende naam of stem is geen bewijs. Een ingesproken bericht kan nagemaakt zijn met AI (deepfake-voice).',
 'vandaag 09:18',
 'Vervolg op mijn voicemail van daarnet',
 'Dag Sanne, zoals ik daarnet in mijn voicemail zei: kun je dit vandaag nog regelen...',
 E'<div class="eml fam-tech" style="--brand:#2f5597;--cta:#2f5597"><div class="eml-body"><p>Dag Sanne,</p><p>Zoals ik daarnet in mijn voicemail al zei: we moeten dit vandaag nog rond krijgen. Ik ben onderweg en heb slecht bereik, dus mailen is makkelijker.</p><p>Wil je voor de nieuwe leverancier vier cadeaubonnen van elk 100 euro aankopen en de codes hier naar mij terugsturen? Ik leg straks uit waarvoor het dient — het is voor een attentie die vandaag nog weg moet.</p><p>Reken maar op mij voor de afhandeling. Dank je!</p><p>Groeten,<br>Mark</p></div></div>',
 '[]'::jsonb,
 TRUE,
 '["Een verwijzing naar een voicemail van een bekende stem is geen bewijs — stemmen zijn met AI na te maken","De vraag om cadeaubonnen te kopen en codes door te sturen is een klassiek fraudepatroon","Urgentie (vandaag nog) en een reden om niet te kunnen bellen (slecht bereik) blokkeren net het tweede kanaal","De uitleg over het waarom komt steeds later — een afleidingstactiek","Verifieer nooit op basis van de e-mail zelf; gebruik een onafhankelijk kanaal"]'::jsonb,
 '[]'::jsonb,
 'Dit is phishing. De verwijzing naar een ingesproken bericht van een bekende stem voelt overtuigend, maar een stem is met AI na te maken — een bekende stem of naam is geen bewijs meer. Een echte leidinggevende vraagt niet om cadeauboncodes per e-mail. Verifieer dit via een tweede, onafhankelijk kanaal: bel Mark terug op een nummer dat u zelf kent. Doe nooit een aankoop op basis van enkel een mail of voicemail.',
 410, 'advanced'),

-- ---------------- en ----------------
('en', 'both',
 'Mark de Vries',
 'mark.devries@kestrel-finance.com',
 'Note the domain: kestrel-finance.com. Your organisation uses kestrel.com. One extra word makes it a different, foreign domain.',
 'today 08:42',
 'Quick one: approval for Solstice project invoice',
 'Hi Sanne, good to catch up yesterday about Solstice. The supplier has just...',
 E'<div class="eml fam-tech" style="--brand:#2f5597;--cta:#2f5597"><div class="eml-body"><p>Hi Sanne,</p><p>Good to catch up yesterday about the Solstice project delivery. Our supplier has just let us know their account number has changed, and unfortunately the outstanding invoice can’t wait until Monday.</p><p>Could you approve the payment today via {{link:0}}? I’m in meetings for the rest of the day, so please don’t call — a quick message is fine.</p><p>Thanks for picking this up quickly.</p><p>Best regards,<br>Mark de Vries<br>Finance Manager</p></div></div>',
 '[{"label":"Approve payment","real_url":"http://kestrel-finance.com/portal/approve?inv=SOL-2026-0418","suspicious":true,"warning":"This link goes to kestrel-finance.com, not your own kestrel.com. Never approve a payment from an email link — log in to the known portal or call your colleague on a number you already have."}]'::jsonb,
 TRUE,
 '["The domain kestrel-finance.com looks like your organisation but differs subtly from kestrel.com","Unusual request: approve a payment urgently via a link","Urgency around money (can not wait until Monday) puts you under pressure","The sender explicitly asks you NOT to call — exactly the second channel that would expose the trick","A changed account number is a classic sign of invoice fraud"]'::jsonb,
 '[]'::jsonb,
 'This is phishing (CEO fraud). The language is flawless and personal — your name, a real-sounding project, a colleague’s style. That is precisely why it is dangerous: you can not catch it by spelling mistakes. Trust the process, not the polish. Verify any urgent money request through a second, independent channel: call Mark on a number you already have, or walk over. Never click an approval link from an email.',
 400, 'advanced'),

('en', 'both',
 'Mark de Vries',
 'm.devries@kestrel.com',
 'A familiar name or voice is not proof. A voicemail can be faked with AI (deepfake voice).',
 'today 09:18',
 'Following up on my voicemail just now',
 'Hi Sanne, as I mentioned in my voicemail just now, can you sort this today...',
 E'<div class="eml fam-tech" style="--brand:#2f5597;--cta:#2f5597"><div class="eml-body"><p>Hi Sanne,</p><p>As I mentioned in my voicemail just now, we need to get this done today. I’m on the road with poor signal, so email is easier.</p><p>Could you buy four gift cards of 100 euros each for our new supplier and send me the codes here? I’ll explain what it’s for shortly — it’s a thank-you gift that has to go out today.</p><p>Count on me to handle the rest. Thanks!</p><p>Mark</p></div></div>',
 '[]'::jsonb,
 TRUE,
 '["A reference to a voicemail from a familiar voice is not proof — voices can be cloned with AI","The request to buy gift cards and send the codes is a classic fraud pattern","Urgency (today) and a reason not to call (poor signal) block the very second channel that would help","The reason “why” keeps being deferred — a distraction tactic","Never verify based on the email itself; use an independent channel"]'::jsonb,
 '[]'::jsonb,
 'This is phishing. The reference to a voicemail from a familiar voice feels convincing, but a voice can be cloned with AI — a familiar voice or name is no longer proof. A real manager does not ask for gift card codes by email. Verify through a second, independent channel: call Mark back on a number you already have. Never make a purchase based on an email or voicemail alone.',
 410, 'advanced'),

-- ---------------- fr ----------------
('fr', 'both',
 'Marc Dupont',
 'marc.dupont@kestrel-finance.fr',
 'Attention au domaine : kestrel-finance.fr. Votre organisation utilise kestrel.fr. Un mot ajouté en fait un domaine différent et étranger.',
 'aujourd’hui 08:42',
 'Rapide : validation de la facture du projet Solstice',
 'Bonjour Sanne, content d’avoir échangé hier au sujet de Solstice. Le fournisseur...',
 E'<div class="eml fam-tech" style="--brand:#2f5597;--cta:#2f5597"><div class="eml-body"><p>Bonjour Sanne,</p><p>Content d’avoir échangé hier au sujet de la livraison du projet Solstice. Notre fournisseur vient de nous informer que son numéro de compte a changé, et la facture en attente ne peut malheureusement pas attendre lundi.</p><p>Pourrais-tu valider le paiement aujourd’hui via {{link:0}} ? Je suis en réunion le reste de la journée, alors évite de m’appeler — un petit message suffit.</p><p>Merci de prendre cela en charge rapidement.</p><p>Bien cordialement,<br>Marc Dupont<br>Directeur financier</p></div></div>',
 '[{"label":"Valider le paiement","real_url":"http://kestrel-finance.fr/portal/approve?inv=SOL-2026-0418","suspicious":true,"warning":"Ce lien mène vers kestrel-finance.fr, pas vers votre propre kestrel.fr. Ne validez jamais un paiement depuis un lien d’e-mail — connectez-vous au portail connu ou appelez votre collègue sur un numéro que vous avez déjà."}]'::jsonb,
 TRUE,
 '["Le domaine kestrel-finance.fr ressemble à votre organisation mais diffère subtilement de kestrel.fr","Demande inhabituelle : valider un paiement en urgence via un lien","L’urgence autour de l’argent (ne peut pas attendre lundi) vous met sous pression","L’expéditeur vous demande explicitement de NE PAS appeler — précisément le second canal qui démasquerait l’arnaque","Un changement de numéro de compte est un signe classique de fraude à la facture"]'::jsonb,
 '[]'::jsonb,
 'Il s’agit de phishing (fraude au président). La langue est impeccable et personnelle — votre nom, un projet crédible, le style d’un collègue. C’est précisément ce qui la rend dangereuse : vous ne pouvez pas la repérer aux fautes d’orthographe. Fiez-vous au processus, pas à la qualité de la rédaction. Vérifiez toute demande urgente d’argent par un second canal indépendant : appelez Marc sur un numéro que vous avez déjà, ou allez le voir. Ne cliquez jamais sur un lien de validation reçu par e-mail.',
 400, 'advanced'),

('fr', 'both',
 'Marc Dupont',
 'm.dupont@kestrel.fr',
 'Un nom ou une voix connue n’est pas une preuve. Un message vocal peut être imité avec l’IA (voix deepfake).',
 'aujourd’hui 09:18',
 'Suite à mon message vocal de tout à l’heure',
 'Bonjour Sanne, comme je l’ai dit dans mon message vocal, peux-tu régler cela...',
 E'<div class="eml fam-tech" style="--brand:#2f5597;--cta:#2f5597"><div class="eml-body"><p>Bonjour Sanne,</p><p>Comme je l’ai dit dans mon message vocal de tout à l’heure, il faut boucler cela aujourd’hui. Je suis sur la route avec un mauvais réseau, donc l’e-mail est plus simple.</p><p>Peux-tu acheter quatre cartes-cadeaux de 100 euros chacune pour notre nouveau fournisseur et m’envoyer les codes ici ? Je t’expliquerai à quoi cela sert plus tard — c’est un cadeau de remerciement qui doit partir aujourd’hui.</p><p>Compte sur moi pour la suite. Merci !</p><p>Marc</p></div></div>',
 '[]'::jsonb,
 TRUE,
 '["Une référence à un message vocal d’une voix connue n’est pas une preuve — les voix peuvent être clonées avec l’IA","La demande d’acheter des cartes-cadeaux et d’envoyer les codes est un schéma de fraude classique","L’urgence (aujourd’hui) et une raison de ne pas appeler (mauvais réseau) bloquent justement le second canal","La raison « pourquoi » est sans cesse reportée — une tactique de diversion","Ne vérifiez jamais à partir de l’e-mail lui-même ; utilisez un canal indépendant"]'::jsonb,
 '[]'::jsonb,
 'Il s’agit de phishing. La référence à un message vocal d’une voix connue paraît convaincante, mais une voix peut être clonée avec l’IA — une voix ou un nom connu n’est plus une preuve. Un vrai responsable ne demande pas des codes de cartes-cadeaux par e-mail. Vérifiez par un second canal indépendant : rappelez Marc sur un numéro que vous avez déjà. N’effectuez jamais un achat sur la seule base d’un e-mail ou d’un message vocal.',
 410, 'advanced'),

-- ---------------- fr-BE ----------------
('fr-BE', 'both',
 'Marc Dupont',
 'marc.dupont@kestrel-finance.be',
 'Attention au domaine : kestrel-finance.be. Votre organisation utilise kestrel.be. Un mot ajouté en fait un domaine différent et étranger.',
 'aujourd’hui 08:42',
 'Rapide : validation de la facture du projet Solstice',
 'Bonjour Sanne, content d’avoir échangé hier au sujet de Solstice. Le fournisseur...',
 E'<div class="eml fam-tech" style="--brand:#2f5597;--cta:#2f5597"><div class="eml-body"><p>Bonjour Sanne,</p><p>Content d’avoir échangé hier au sujet de la livraison du projet Solstice. Notre fournisseur vient de nous informer que son numéro de compte a changé, et la facture en attente ne peut malheureusement pas attendre lundi.</p><p>Pourrais-tu valider le paiement aujourd’hui via {{link:0}} ? Je suis en réunion le reste de la journée, alors évite de m’appeler — un petit message suffit.</p><p>Merci de prendre cela en charge rapidement.</p><p>Bien à toi,<br>Marc Dupont<br>Directeur financier</p></div></div>',
 '[{"label":"Valider le paiement","real_url":"http://kestrel-finance.be/portal/approve?inv=SOL-2026-0418","suspicious":true,"warning":"Ce lien mène vers kestrel-finance.be, pas vers votre propre kestrel.be. Ne validez jamais un paiement depuis un lien d’e-mail — connectez-vous au portail connu ou appelez votre collègue sur un numéro que vous avez déjà."}]'::jsonb,
 TRUE,
 '["Le domaine kestrel-finance.be ressemble à votre organisation mais diffère subtilement de kestrel.be","Demande inhabituelle : valider un paiement en urgence via un lien","L’urgence autour de l’argent (ne peut pas attendre lundi) vous met sous pression","L’expéditeur vous demande explicitement de NE PAS appeler — précisément le second canal qui démasquerait l’arnaque","Un changement de numéro de compte est un signe classique de fraude à la facture"]'::jsonb,
 '[]'::jsonb,
 'Il s’agit de phishing (fraude au président). La langue est impeccable et personnelle — votre nom, un projet crédible, le style d’un collègue. C’est précisément ce qui la rend dangereuse : vous ne pouvez pas la repérer aux fautes d’orthographe. Fiez-vous au processus, pas à la qualité de la rédaction. Vérifiez toute demande urgente d’argent par un second canal indépendant : appelez Marc sur un numéro que vous avez déjà, ou allez le voir. Ne cliquez jamais sur un lien de validation reçu par e-mail.',
 400, 'advanced'),

('fr-BE', 'both',
 'Marc Dupont',
 'm.dupont@kestrel.be',
 'Un nom ou une voix connue n’est pas une preuve. Un message vocal peut être imité avec l’IA (voix deepfake).',
 'aujourd’hui 09:18',
 'Suite à mon message vocal de tout à l’heure',
 'Bonjour Sanne, comme je l’ai dit dans mon message vocal, peux-tu régler cela...',
 E'<div class="eml fam-tech" style="--brand:#2f5597;--cta:#2f5597"><div class="eml-body"><p>Bonjour Sanne,</p><p>Comme je l’ai dit dans mon message vocal de tout à l’heure, il faut boucler cela aujourd’hui. Je suis sur la route avec un mauvais réseau, donc l’e-mail est plus simple.</p><p>Peux-tu acheter quatre cartes-cadeaux de 100 euros chacune pour notre nouveau fournisseur et m’envoyer les codes ici ? Je t’expliquerai à quoi cela sert plus tard — c’est un cadeau de remerciement qui doit partir aujourd’hui.</p><p>Compte sur moi pour la suite. Merci !</p><p>Marc</p></div></div>',
 '[]'::jsonb,
 TRUE,
 '["Une référence à un message vocal d’une voix connue n’est pas une preuve — les voix peuvent être clonées avec l’IA","La demande d’acheter des cartes-cadeaux et d’envoyer les codes est un schéma de fraude classique","L’urgence (aujourd’hui) et une raison de ne pas appeler (mauvais réseau) bloquent justement le second canal","La raison « pourquoi » est sans cesse reportée — une tactique de diversion","Ne vérifiez jamais à partir de l’e-mail lui-même ; utilisez un canal indépendant"]'::jsonb,
 '[]'::jsonb,
 'Il s’agit de phishing. La référence à un message vocal d’une voix connue paraît convaincante, mais une voix peut être clonée avec l’IA — une voix ou un nom connu n’est plus une preuve. Un vrai responsable ne demande pas des codes de cartes-cadeaux par e-mail. Vérifiez par un second canal indépendant : rappelez Marc sur un numéro que vous avez déjà. N’effectuez jamais un achat sur la seule base d’un e-mail ou d’un message vocal.',
 410, 'advanced'),

-- ---------------- de ----------------
('de', 'both',
 'Mark de Vries',
 'mark.devries@kestrel-finance.de',
 'Achten Sie auf die Domain: kestrel-finance.de. Ihre Organisation nutzt kestrel.de. Ein zusätzliches Wort macht daraus eine andere, fremde Domain.',
 'heute 08:42',
 'Kurz: Freigabe der Rechnung für Projekt Sonnenwende',
 'Hallo Sanne, schön, dass wir uns gestern zu Sonnenwende austauschen konnten...',
 E'<div class="eml fam-tech" style="--brand:#2f5597;--cta:#2f5597"><div class="eml-body"><p>Hallo Sanne,</p><p>schön, dass wir uns gestern zur Abnahme des Projekts Sonnenwende austauschen konnten. Unser Lieferant hat uns gerade mitgeteilt, dass sich seine Kontonummer geändert hat, und die offene Rechnung kann leider nicht bis Montag warten.</p><p>Könntest du die Zahlung heute noch über {{link:0}} freigeben? Ich bin den Rest des Tages in Besprechungen, ruf mich also bitte nicht an — eine kurze Nachricht genügt.</p><p>Danke, dass du das schnell übernimmst.</p><p>Herzliche Grüße,<br>Mark de Vries<br>Leiter Finanzen</p></div></div>',
 '[{"label":"Zahlung freigeben","real_url":"http://kestrel-finance.de/portal/approve?inv=SW-2026-0418","suspicious":true,"warning":"Dieser Link führt zu kestrel-finance.de, nicht zu Ihrem eigenen kestrel.de. Geben Sie eine Zahlung niemals über einen E-Mail-Link frei — melden Sie sich im bekannten Portal an oder rufen Sie Ihren Kollegen unter einer Nummer an, die Sie bereits haben."}]'::jsonb,
 TRUE,
 '["Die Domain kestrel-finance.de ähnelt Ihrer Organisation, weicht aber subtil von kestrel.de ab","Ungewöhnliche Bitte: eine Zahlung dringend über einen Link freigeben","Druck durch Eile rund ums Geld (kann nicht bis Montag warten)","Der Absender bittet Sie ausdrücklich, NICHT anzurufen — genau der zweite Kanal, der den Trick entlarven würde","Eine geänderte Kontonummer ist ein klassisches Zeichen für Rechnungsbetrug"]'::jsonb,
 '[]'::jsonb,
 'Dies ist Phishing (CEO-Betrug). Die Sprache ist fehlerfrei und persönlich — Ihr Name, ein echt klingendes Projekt, der Stil eines Kollegen. Genau das macht es gefährlich: Sie erkennen es nicht an Rechtschreibfehlern. Vertrauen Sie auf den Prozess, nicht auf die sprachliche Sorgfalt. Prüfen Sie jede dringende Geldforderung über einen zweiten, unabhängigen Kanal: Rufen Sie Mark unter einer Nummer an, die Sie bereits haben, oder gehen Sie vorbei. Klicken Sie nie auf einen Freigabe-Link aus einer E-Mail.',
 400, 'advanced'),

('de', 'both',
 'Mark de Vries',
 'm.devries@kestrel.de',
 'Ein bekannter Name oder eine bekannte Stimme ist kein Beweis. Eine Sprachnachricht kann mit KI nachgeahmt werden (Deepfake-Voice).',
 'heute 09:18',
 'Nachgang zu meiner Sprachnachricht von gerade eben',
 'Hallo Sanne, wie ich gerade in meiner Sprachnachricht sagte, kannst du das heute...',
 E'<div class="eml fam-tech" style="--brand:#2f5597;--cta:#2f5597"><div class="eml-body"><p>Hallo Sanne,</p><p>wie ich gerade in meiner Sprachnachricht sagte, müssen wir das heute noch abschließen. Ich bin unterwegs und habe schlechten Empfang, daher ist E-Mail einfacher.</p><p>Könntest du für unseren neuen Lieferanten vier Gutscheinkarten zu je 100 Euro kaufen und mir die Codes hier zurückschicken? Wofür es ist, erkläre ich dir gleich — es ist ein Dankeschön, das heute noch raus muss.</p><p>Verlass dich auf mich für den Rest. Danke!</p><p>Mark</p></div></div>',
 '[]'::jsonb,
 TRUE,
 '["Ein Verweis auf eine Sprachnachricht einer bekannten Stimme ist kein Beweis — Stimmen lassen sich mit KI klonen","Die Bitte, Gutscheinkarten zu kaufen und die Codes zu schicken, ist ein klassisches Betrugsmuster","Eile (heute noch) und ein Grund, nicht anzurufen (schlechter Empfang), blockieren genau den zweiten Kanal","Der Grund „wofür“ wird immer wieder verschoben — ein Ablenkungsmanöver","Prüfen Sie nie anhand der E-Mail selbst; nutzen Sie einen unabhängigen Kanal"]'::jsonb,
 '[]'::jsonb,
 'Dies ist Phishing. Der Verweis auf eine Sprachnachricht einer bekannten Stimme wirkt überzeugend, aber eine Stimme lässt sich mit KI klonen — eine bekannte Stimme oder ein bekannter Name ist kein Beweis mehr. Eine echte Führungskraft bittet nicht per E-Mail um Gutschein-Codes. Prüfen Sie über einen zweiten, unabhängigen Kanal: Rufen Sie Mark unter einer Nummer zurück, die Sie bereits haben. Tätigen Sie nie einen Kauf allein aufgrund einer E-Mail oder Sprachnachricht.',
 410, 'advanced');


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


-- ===========================================================================
-- Fase 8 — Jongeren-scenario's (doelgroepvariant: jeugd).
-- Realistische, regiogerichte oplichting die jongeren raakt: gestolen
-- game-accounts en nep "gratis V-Bucks/Robux", "je Instagram/TikTok wordt
-- verwijderd", nep-winacties ("je hebt een iPhone gewonnen") en doorverkoop
-- van concert-/festivaltickets. Plus per taal één ECHTE (te vertrouwen)
-- 2FA-code, zodat het niet allemaal phishing is.
--
-- audience = 'personal' (privé-pool), difficulty 'normal', mix van kanalen
-- (email/sms/whatsapp). Categorie expliciet meegegeven (gaming/social =
-- 'account' want het is account-overname; ticketdoorverkoop = 'marktplaats';
-- winactie = 'overig'). Deze INSERT staat NA de Fase-6 categorie-UPDATEs,
-- zodat de hier gezette categorieën niet worden overschreven.
-- sort_order vanaf 500 zodat het niet botst met eerdere scenario's.
-- ===========================================================================

INSERT INTO inbox_messages
  (locale, channel, audience, difficulty, category, sender_name, sender_address, sender_note, received_label, subject, preview, body, links, is_phishing, red_flags, green_flags, explanation, sort_order) VALUES

-- ---------- NL ----------
('nl','email','personal','normal','account',
 'Fortnite Rewards','rewards@free-vbucks-claim.com',
 'Epic Games gebruikt @epicgames.com. "free-vbucks-claim.com" is nep — gratis V-Bucks via een externe site bestaan niet.',
 'vandaag 16:40','🎁 Je 13.500 GRATIS V-Bucks staan klaar!',
 'Gefeliciteerd! Je account is geselecteerd voor 13.500 gratis V-Bucks. Claim ze nu...',
 E'<div class="eml fam-tech" style="--brand:#7b2ff7;--cta:#7b2ff7"><div class="eml-body"><p>Gefeliciteerd!</p><p>Jouw account is geselecteerd voor <strong>13.500 GRATIS V-Bucks</strong>. Log in om ze te claimen voordat de actie vervalt:</p><p>{{link:0}}</p><p>Let op: deze actie verloopt over 30 minuten. Mis het niet!</p><p>— Het Fortnite Rewards-team</p></div></div>',
 '[{"label":"Claim mijn V-Bucks","real_url":"http://free-vbucks-claim.com/login","suspicious":true,"warning":"Het echte domein is epicgames.com. Een externe site die naar je login vraagt om \"gratis V-Bucks\" te geven, steelt je Fortnite-account."}]'::jsonb,
 TRUE,
 '["Gratis in-game valuta bestaat niet — het is altijd lokaas","Afzenderdomein free-vbucks-claim.com is niet epicgames.com","Tijdsdruk: \"verloopt over 30 minuten\"","De link vraagt je om in te loggen op een vreemde site"]'::jsonb,
 '[]'::jsonb,
 'Dit is phishing om je game-account te stelen. Niemand geeft gratis V-Bucks weg via een link. Wie inlogt op zo''n nepsite, geeft zijn Epic Games-account weg. Koop V-Bucks alleen in de game zelf en zet tweestapsverificatie aan.',
 500),

('nl','sms','personal','normal','account',
 'Instagram','+31 6 48 22 19 03',
 'Instagram stuurt geen sms vanaf een 06-nummer en dreigt niet met verwijdering via een link.',
 'vandaag 19:12','Instagram',
 'Je account wordt binnen 24 uur verwijderd wegens een copyrightmelding...',
 E'Instagram: we hebben een copyrightklacht over jouw account ontvangen. Je account wordt binnen 24 uur VERWIJDERD tenzij je bezwaar maakt: {{link:0}}',
 '[{"label":"instagram-help-center.com","real_url":"http://instagram-help-center.com/appeal","suspicious":true,"warning":"Instagram gebruikt instagram.com en de app zelf. \"instagram-help-center.com\" is nep en wil je wachtwoord stelen."}]'::jsonb,
 TRUE,
 '["Dreigen met verwijdering binnen 24 uur = paniek zaaien","Afzender is een 06-nummer, geen officieel kanaal","Link gaat naar instagram-help-center.com, niet instagram.com","Echte meldingen staan in de app, niet in een sms"]'::jsonb,
 '[]'::jsonb,
 'Dit is phishing. Oplichters dreigen met verwijdering om je in paniek te laten klikken. Controleer meldingen altijd in de Instagram-app zelf (Instellingen). Klik nooit op een link uit zo''n bericht.',
 501),

('nl','whatsapp','personal','normal','overig',
 'Onbekend nummer','+31 6 12 90 34 77',
 'Een "win-actie" die je nooit hebt meegedaan, is altijd nep. Bekende merken loten geen winnaars uit via WhatsApp.',
 'vandaag 13:05','WhatsApp',
 'GEFELICITEERD! Jouw nummer is getrokken: je hebt een iPhone 16 Pro gewonnen...',
 E'🎉 GEFELICITEERD! 🎉 Jouw telefoonnummer is getrokken in onze actie. Je hebt een *iPhone 16 Pro* gewonnen! Betaal alleen € 1,95 verzendkosten en vul je gegevens in: {{link:0}}',
 '[{"label":"apple-winactie-nl.com","real_url":"http://apple-winactie-nl.com/claim","suspicious":true,"warning":"Apple verloot geen telefoons via WhatsApp. De site vraagt om betaalgegevens — die worden misbruikt."}]'::jsonb,
 TRUE,
 '["Je hebt nooit aan een win-actie meegedaan","Klein bedrag (€ 1,95) om je kaartgegevens te ontfutselen","Onbekend nummer via WhatsApp","Link naar apple-winactie-nl.com, niet apple.com"]'::jsonb,
 '[]'::jsonb,
 'Dit is een prijs-scam. Als je niets hebt gewonnen omdat je nergens aan meedeed, klopt het niet. Het kleine bedrag is een truc om je kaartgegevens te krijgen. Negeren en blokkeren.',
 502),

('nl','sms','personal','normal','account',
 'Steam','Steam',
 'Dit is een ECHTE Steam Guard-code. Steam stuurt zo''n code alleen als JIJ zelf probeert in te loggen, en zet er nooit een link bij.',
 'vandaag 20:31','Steam',
 'Je Steam Guard-code is 5KQ7T. Deel deze code met niemand.',
 E'Steam Guard: je inlogcode is <strong>5KQ7T</strong>.\n\nDeze code is bedoeld om in te loggen op je eigen account. Deel hem met niemand — Steam-medewerkers vragen er nooit naar.',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Geen link in het bericht — alleen een code","Je probeerde zelf zojuist in te loggen","De afzender is Steam, geen vreemd nummer","Het bericht vraagt niets, maar waarschuwt juist om de code geheim te houden"]'::jsonb,
 'Dit is een echte tweestapsverificatie-code (Steam Guard). Die krijg je als je zelf inlogt. Belangrijk: deel zo''n code NOOIT met iemand anders — wie je code vraagt (in een chat, telefoongesprek of "support") wil je account stelen. Typ hem alleen zelf in het officiële inlogscherm.',
 503),

-- ---------- nl-BE ----------
('nl-BE','email','personal','normal','account',
 'Roblox Prijzen','support@robux-gratis-claim.com',
 'Roblox gebruikt @roblox.com. "robux-gratis-claim.com" is nep — gratis Robux via een externe site bestaan niet.',
 'vandaag 16:40','🎁 Je 10.000 GRATIS Robux staan klaar!',
 'Proficiat! Je account is geselecteerd voor 10.000 gratis Robux. Claim ze nu...',
 E'<div class="eml fam-tech" style="--brand:#e2231a;--cta:#e2231a"><div class="eml-body"><p>Proficiat!</p><p>Jouw account werd geselecteerd voor <strong>10.000 GRATIS Robux</strong>. Meld je aan om ze te claimen voor de actie afloopt:</p><p>{{link:0}}</p><p>Opgelet: deze actie verloopt over 30 minuten!</p><p>— Het Roblox-prijzenteam</p></div></div>',
 '[{"label":"Claim mijn Robux","real_url":"http://robux-gratis-claim.com/login","suspicious":true,"warning":"Het echte domein is roblox.com. Een externe site die naar je login vraagt om \"gratis Robux\" te geven, steelt je Roblox-account."}]'::jsonb,
 TRUE,
 '["Gratis in-game valuta bestaat niet — het is altijd lokaas","Afzenderdomein robux-gratis-claim.com is niet roblox.com","Tijdsdruk: \"verloopt over 30 minuten\"","De link vraagt je om aan te melden op een vreemde site"]'::jsonb,
 '[]'::jsonb,
 'Dit is phishing om je game-account te stelen. Niemand geeft gratis Robux weg via een link. Wie aanmeldt op zo''n nepsite, geeft zijn Roblox-account weg. Koop Robux alleen in de app zelf en zet tweestapsverificatie aan.',
 500),

('nl-BE','sms','personal','normal','account',
 'TikTok','+32 470 88 21 09',
 'TikTok stuurt geen sms vanaf een gsm-nummer en dreigt niet met verwijdering via een link.',
 'vandaag 19:12','TikTok',
 'Je account wordt binnen 24 uur verwijderd wegens schending van de regels...',
 E'TikTok: we ontvingen een klacht over jouw account. Het wordt binnen 24 uur VERWIJDERD tenzij je bezwaar aantekent: {{link:0}}',
 '[{"label":"tiktok-beroep.com","real_url":"http://tiktok-beroep.com/appeal","suspicious":true,"warning":"TikTok gebruikt tiktok.com en de app zelf. \"tiktok-beroep.com\" is nep en wil je wachtwoord stelen."}]'::jsonb,
 TRUE,
 '["Dreigen met verwijdering binnen 24 uur = paniek zaaien","Afzender is een gsm-nummer, geen officieel kanaal","Link gaat naar tiktok-beroep.com, niet tiktok.com","Echte meldingen staan in de app, niet in een sms"]'::jsonb,
 '[]'::jsonb,
 'Dit is phishing. Oplichters dreigen met verwijdering om je in paniek te laten klikken. Controleer meldingen altijd in de TikTok-app zelf. Klik nooit op een link uit zo''n bericht.',
 501),

('nl-BE','whatsapp','personal','normal','marktplaats',
 'Onbekend nummer','+32 489 33 70 12',
 'Een ticketverkoper die alleen vooraf wil betaald worden en buiten het officiële kanaal blijft, is bijna altijd een oplichter.',
 'vandaag 13:05','WhatsApp',
 'Nog 2 tickets voor Tomorrowland! Betaal via overschrijving en ik stuur ze door...',
 E'Hey! Ik heb nog 2 tickets voor *Tomorrowland* die ik niet meer kan gebruiken. 150 euro per stuk. Betaal via overschrijving, dan stuur ik de pdf-tickets meteen door. Eerst betalen want er is veel interesse! 👍',
 '[]'::jsonb,
 TRUE,
 '["Vooraf betalen via overschrijving = geen enkele bescherming","Druk: \"eerst betalen want veel interesse\"","Onbekend nummer buiten het officiële verkoopkanaal","Pdf-tickets kunnen meermaals worden doorverkocht"]'::jsonb,
 '[]'::jsonb,
 'Dit is ticketfraude. Wie vooraf via overschrijving laat betalen en buiten een officieel platform blijft, verdwijnt vaak met je geld. Koop tickets enkel via de officiële verkoper of een platform met doorverkoopgarantie (bv. Ticketswap).',
 502),

('nl-BE','sms','personal','normal','account',
 'itsme','itsme',
 'Dit is een ECHTE itsme-melding. itsme vraagt je om de actie in de app zelf te bevestigen en zet nooit een link in de sms.',
 'vandaag 20:31','itsme',
 'Bevestig je aanmelding in de itsme-app. Heb jij dit niet gestart? Weiger dan.',
 E'itsme: er is een aanmelding gestart. Open de <strong>itsme-app</strong> om te bevestigen.\n\nHeb jij dit zelf niet gestart? Weiger de aanvraag in de app en wijzig je code.',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Geen link in het bericht — je bevestigt in de app zelf","Je startte zelf zojuist een aanmelding","De sms vraagt geen wachtwoord of code","Het bericht zegt expliciet: weiger als jij het niet was"]'::jsonb,
 'Dit is een echte tweestapsmelding van itsme. Je bevestigt zo''n actie altijd in de itsme-app zelf, nooit via een link. Was jij het niet? Dan weiger je de aanvraag — iemand probeert dan met jouw gegevens in te loggen.',
 503),

-- ---------- EN (UK) ----------
('en','email','personal','normal','account',
 'Fortnite Rewards','rewards@free-vbucks-claim.com',
 'Epic Games uses @epicgames.com. "free-vbucks-claim.com" is fake — free V-Bucks from an outside site do not exist.',
 'today 16:40','🎁 Your 13,500 FREE V-Bucks are waiting!',
 'Congratulations! Your account has been selected for 13,500 free V-Bucks. Claim them now...',
 E'<div class="eml fam-tech" style="--brand:#7b2ff7;--cta:#7b2ff7"><div class="eml-body"><p>Congratulations!</p><p>Your account has been selected for <strong>13,500 FREE V-Bucks</strong>. Sign in to claim them before the offer expires:</p><p>{{link:0}}</p><p>Hurry — this offer expires in 30 minutes!</p><p>— The Fortnite Rewards team</p></div></div>',
 '[{"label":"Claim my V-Bucks","real_url":"http://free-vbucks-claim.com/login","suspicious":true,"warning":"The real domain is epicgames.com. A site that asks you to sign in to give you \"free V-Bucks\" steals your Fortnite account."}]'::jsonb,
 TRUE,
 '["Free in-game currency does not exist — it is always bait","Sender domain free-vbucks-claim.com is not epicgames.com","Time pressure: \"expires in 30 minutes\"","The link asks you to sign in on a strange site"]'::jsonb,
 '[]'::jsonb,
 'This is phishing to steal your game account. Nobody gives away free V-Bucks via a link. Signing in on that fake site hands over your Epic Games account. Buy V-Bucks only inside the game and turn on two-factor authentication.',
 500),

('en','sms','personal','normal','account',
 'Instagram','+44 7700 900482',
 'Instagram does not text from a mobile number and does not threaten deletion via a link.',
 'today 19:12','Instagram',
 'Your account will be deleted within 24 hours due to a copyright report...',
 E'Instagram: we received a copyright complaint about your account. It will be DELETED within 24 hours unless you appeal: {{link:0}}',
 '[{"label":"instagram-help-center.com","real_url":"http://instagram-help-center.com/appeal","suspicious":true,"warning":"Instagram uses instagram.com and the app itself. \"instagram-help-center.com\" is fake and wants to steal your password."}]'::jsonb,
 TRUE,
 '["Threatening deletion within 24 hours is panic-mongering","Sender is a mobile number, not an official channel","Link goes to instagram-help-center.com, not instagram.com","Real notices appear in the app, not in a text"]'::jsonb,
 '[]'::jsonb,
 'This is phishing. Scammers threaten deletion to make you click in a panic. Always check notices inside the Instagram app (Settings). Never tap a link from a message like this.',
 501),

('en','whatsapp','personal','normal','overig',
 'Unknown number','+44 7700 900913',
 'A "prize draw" you never entered is always fake. Real brands do not pick winners over WhatsApp.',
 'today 13:05','WhatsApp',
 'CONGRATULATIONS! Your number was drawn — you have won an iPhone 16 Pro...',
 E'🎉 CONGRATULATIONS! 🎉 Your phone number was drawn in our giveaway. You have won an *iPhone 16 Pro*! Just pay £1.95 for postage and enter your details: {{link:0}}',
 '[{"label":"apple-giveaway-uk.com","real_url":"http://apple-giveaway-uk.com/claim","suspicious":true,"warning":"Apple does not give away phones over WhatsApp. The site asks for payment details, which are then misused."}]'::jsonb,
 TRUE,
 '["You never entered any prize draw","Small fee (£1.95) to harvest your card details","Unknown number over WhatsApp","Link to apple-giveaway-uk.com, not apple.com"]'::jsonb,
 '[]'::jsonb,
 'This is a prize scam. If you won something you never entered, it is fake. The tiny fee is a trick to capture your card details. Ignore and block.',
 502),

('en','sms','personal','normal','account',
 'Steam','Steam',
 'This is a GENUINE Steam Guard code. Steam only sends it when YOU try to log in, and never adds a link.',
 'today 20:31','Steam',
 'Your Steam Guard code is 5KQ7T. Do not share this code with anyone.',
 E'Steam Guard: your sign-in code is <strong>5KQ7T</strong>.\n\nThis code is for signing in to your own account. Do not share it with anyone — Steam staff will never ask for it.',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["No link in the message — just a code","You tried to sign in yourself just now","The sender is Steam, not a strange number","The message asks for nothing; it warns you to keep the code secret"]'::jsonb,
 'This is a genuine two-factor code (Steam Guard). You receive it when you sign in yourself. Important: NEVER share such a code with anyone — whoever asks for your code (in a chat, a call or "support") wants to steal your account. Only type it into the official sign-in screen.',
 503),

-- ---------- FR ----------
('fr','email','personal','normal','account',
 'Fortnite Récompenses','rewards@free-vbucks-claim.com',
 'Epic Games utilise @epicgames.com. « free-vbucks-claim.com » est faux — des V-Bucks gratuits via un site externe, ça n''existe pas.',
 'aujourd''hui 16:40','🎁 Vos 13 500 V-Bucks GRATUITS vous attendent !',
 'Félicitations ! Votre compte a été sélectionné pour 13 500 V-Bucks gratuits. Réclamez-les...',
 E'<div class="eml fam-tech" style="--brand:#7b2ff7;--cta:#7b2ff7"><div class="eml-body"><p>Félicitations !</p><p>Votre compte a été sélectionné pour <strong>13 500 V-Bucks GRATUITS</strong>. Connectez-vous pour les réclamer avant la fin de l’offre :</p><p>{{link:0}}</p><p>Dépêchez-vous — l’offre expire dans 30 minutes !</p><p>— L’équipe Fortnite Récompenses</p></div></div>',
 '[{"label":"Réclamer mes V-Bucks","real_url":"http://free-vbucks-claim.com/login","suspicious":true,"warning":"Le vrai domaine est epicgames.com. Un site qui vous demande de vous connecter pour offrir des « V-Bucks gratuits » vole votre compte Fortnite."}]'::jsonb,
 TRUE,
 '["La monnaie de jeu gratuite n’existe pas — c’est toujours un appât","Le domaine free-vbucks-claim.com n’est pas epicgames.com","Pression du temps : « expire dans 30 minutes »","Le lien vous demande de vous connecter sur un site inconnu"]'::jsonb,
 '[]'::jsonb,
 'C’est de l’hameçonnage pour voler votre compte de jeu. Personne n’offre de V-Bucks gratuits par un lien. Se connecter sur ce faux site revient à donner son compte Epic Games. Achetez des V-Bucks uniquement dans le jeu et activez la double authentification.',
 500),

('fr','sms','personal','normal','account',
 'Instagram','+33 6 12 48 75 03',
 'Instagram n’envoie pas de SMS depuis un numéro de portable et ne menace pas de suppression via un lien.',
 'aujourd''hui 19:12','Instagram',
 'Votre compte sera supprimé dans 24 heures à la suite d''un signalement...',
 E'Instagram : nous avons reçu une plainte pour droits d’auteur concernant votre compte. Il sera SUPPRIMÉ sous 24 heures sauf si vous contestez : {{link:0}}',
 '[{"label":"instagram-help-center.com","real_url":"http://instagram-help-center.com/appeal","suspicious":true,"warning":"Instagram utilise instagram.com et l’application. « instagram-help-center.com » est faux et veut voler votre mot de passe."}]'::jsonb,
 TRUE,
 '["Menacer d’une suppression sous 24 h, c’est semer la panique","L’expéditeur est un numéro de portable, pas un canal officiel","Le lien mène à instagram-help-center.com, pas instagram.com","Les vrais avis apparaissent dans l’app, pas dans un SMS"]'::jsonb,
 '[]'::jsonb,
 'C’est de l’hameçonnage. Les escrocs menacent de suppression pour vous faire cliquer dans la panique. Vérifiez toujours les avis dans l’application Instagram (Réglages). Ne cliquez jamais sur un lien d’un tel message.',
 501),

('fr','whatsapp','personal','normal','overig',
 'Numéro inconnu','+33 6 99 30 41 77',
 'Un « tirage au sort » auquel vous n’avez jamais participé est toujours faux. Les vraies marques ne désignent pas de gagnants par WhatsApp.',
 'aujourd''hui 13:05','WhatsApp',
 'FÉLICITATIONS ! Votre numéro a été tiré au sort : vous avez gagné un iPhone 16 Pro...',
 E'🎉 FÉLICITATIONS ! 🎉 Votre numéro a été tiré au sort dans notre jeu-concours. Vous avez gagné un *iPhone 16 Pro* ! Payez seulement 1,95 € de frais de port et indiquez vos coordonnées : {{link:0}}',
 '[{"label":"apple-jeu-concours-fr.com","real_url":"http://apple-jeu-concours-fr.com/claim","suspicious":true,"warning":"Apple n’organise pas de tirage par WhatsApp. Le site demande vos données de paiement, qui sont ensuite détournées."}]'::jsonb,
 TRUE,
 '["Vous n’avez jamais participé à un concours","Petit montant (1,95 €) pour récupérer vos données bancaires","Numéro inconnu via WhatsApp","Lien vers apple-jeu-concours-fr.com, pas apple.com"]'::jsonb,
 '[]'::jsonb,
 'C’est une arnaque au prix. Si vous avez « gagné » sans avoir participé, c’est faux. Le petit montant est une ruse pour capter vos données bancaires. Ignorez et bloquez.',
 502),

('fr','sms','personal','normal','account',
 'Steam','Steam',
 'C’est un VRAI code Steam Guard. Steam ne l’envoie que lorsque VOUS tentez de vous connecter, et n’ajoute jamais de lien.',
 'aujourd''hui 20:31','Steam',
 'Votre code Steam Guard est 5KQ7T. Ne le communiquez à personne.',
 E'Steam Guard : votre code de connexion est <strong>5KQ7T</strong>.\n\nCe code sert à vous connecter à votre propre compte. Ne le communiquez à personne — le personnel de Steam ne le demande jamais.',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Aucun lien dans le message — juste un code","Vous venez de tenter de vous connecter vous-même","L’expéditeur est Steam, pas un numéro inconnu","Le message ne demande rien ; il vous invite à garder le code secret"]'::jsonb,
 'C’est un vrai code de double authentification (Steam Guard). Vous le recevez quand vous vous connectez vous-même. Important : ne communiquez JAMAIS un tel code — quiconque vous le demande (dans un chat, par téléphone ou via un « support ») veut voler votre compte. Saisissez-le uniquement dans l’écran de connexion officiel.',
 503),

-- ---------- fr-BE ----------
('fr-BE','email','personal','normal','account',
 'Roblox Récompenses','support@robux-gratuit-claim.com',
 'Roblox utilise @roblox.com. « robux-gratuit-claim.com » est faux — des Robux gratuits via un site externe, ça n''existe pas.',
 'aujourd''hui 16:40','🎁 Vos 10 000 Robux GRATUITS vous attendent !',
 'Félicitations ! Votre compte a été sélectionné pour 10 000 Robux gratuits. Réclamez-les...',
 E'<div class="eml fam-tech" style="--brand:#e2231a;--cta:#e2231a"><div class="eml-body"><p>Félicitations !</p><p>Votre compte a été sélectionné pour <strong>10 000 Robux GRATUITS</strong>. Connectez-vous pour les réclamer avant la fin de l’offre :</p><p>{{link:0}}</p><p>Dépêchez-vous — l’offre expire dans 30 minutes !</p><p>— L’équipe Roblox Récompenses</p></div></div>',
 '[{"label":"Réclamer mes Robux","real_url":"http://robux-gratuit-claim.com/login","suspicious":true,"warning":"Le vrai domaine est roblox.com. Un site qui vous demande de vous connecter pour offrir des « Robux gratuits » vole votre compte Roblox."}]'::jsonb,
 TRUE,
 '["La monnaie de jeu gratuite n’existe pas — c’est toujours un appât","Le domaine robux-gratuit-claim.com n’est pas roblox.com","Pression du temps : « expire dans 30 minutes »","Le lien vous demande de vous connecter sur un site inconnu"]'::jsonb,
 '[]'::jsonb,
 'C’est de l’hameçonnage pour voler votre compte de jeu. Personne n’offre de Robux gratuits par un lien. Se connecter sur ce faux site revient à donner son compte Roblox. Achetez des Robux uniquement dans l’application et activez la double authentification.',
 500),

('fr-BE','sms','personal','normal','account',
 'TikTok','+32 470 12 88 41',
 'TikTok n’envoie pas de SMS depuis un numéro de GSM et ne menace pas de suppression via un lien.',
 'aujourd''hui 19:12','TikTok',
 'Votre compte sera supprimé dans 24 heures pour non-respect des règles...',
 E'TikTok : nous avons reçu une plainte concernant votre compte. Il sera SUPPRIMÉ sous 24 heures sauf si vous introduisez un recours : {{link:0}}',
 '[{"label":"tiktok-recours.com","real_url":"http://tiktok-recours.com/appeal","suspicious":true,"warning":"TikTok utilise tiktok.com et l’application. « tiktok-recours.com » est faux et veut voler votre mot de passe."}]'::jsonb,
 TRUE,
 '["Menacer d’une suppression sous 24 h, c’est semer la panique","L’expéditeur est un numéro de GSM, pas un canal officiel","Le lien mène à tiktok-recours.com, pas tiktok.com","Les vrais avis apparaissent dans l’app, pas dans un SMS"]'::jsonb,
 '[]'::jsonb,
 'C’est de l’hameçonnage. Les escrocs menacent de suppression pour vous faire cliquer dans la panique. Vérifiez toujours les avis dans l’application TikTok. Ne cliquez jamais sur un lien d’un tel message.',
 501),

('fr-BE','whatsapp','personal','normal','marktplaats',
 'Numéro inconnu','+32 489 70 33 12',
 'Un vendeur de tickets qui exige un paiement à l’avance et reste hors du canal officiel est presque toujours un escroc.',
 'aujourd''hui 13:05','WhatsApp',
 'Encore 2 tickets pour les Ardentes ! Paiement par virement et je les envoie...',
 E'Salut ! J’ai encore 2 tickets pour *Les Ardentes* que je ne peux plus utiliser. 120 € pièce. Paie par virement et je t’envoie les PDF tout de suite. Paie d’abord car il y a beaucoup de demandes ! 👍',
 '[]'::jsonb,
 TRUE,
 '["Payer à l’avance par virement = aucune protection","Pression : « paie d’abord car beaucoup de demandes »","Numéro inconnu hors du canal de vente officiel","Des tickets PDF peuvent être revendus plusieurs fois"]'::jsonb,
 '[]'::jsonb,
 'C’est une arnaque aux tickets. Celui qui exige un paiement à l’avance par virement et reste hors d’une plateforme officielle disparaît souvent avec votre argent. Achetez vos tickets uniquement via le vendeur officiel ou une plateforme avec garantie de revente (par ex. Ticketswap).',
 502),

('fr-BE','sms','personal','normal','account',
 'itsme','itsme',
 'Ceci est une VRAIE notification itsme. itsme vous demande de confirmer dans l’app elle-même et n’ajoute jamais de lien dans le SMS.',
 'aujourd''hui 20:31','itsme',
 'Confirmez votre connexion dans l’app itsme. Ce n’est pas vous ? Refusez.',
 E'itsme : une connexion a été lancée. Ouvrez l’<strong>application itsme</strong> pour confirmer.\n\nCe n’est pas vous ? Refusez la demande dans l’app et modifiez votre code.',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Aucun lien dans le message — vous confirmez dans l’app","Vous venez de lancer une connexion vous-même","Le SMS ne demande ni mot de passe ni code","Le message dit explicitement : refusez si ce n’est pas vous"]'::jsonb,
 'Ceci est une vraie notification de double authentification d’itsme. Vous confirmez toujours ce type d’action dans l’app itsme, jamais via un lien. Ce n’était pas vous ? Refusez la demande — quelqu’un tente alors de se connecter avec vos données.',
 503),

-- ---------- DE ----------
('de','email','personal','normal','account',
 'Fortnite Belohnungen','rewards@free-vbucks-claim.com',
 'Epic Games nutzt @epicgames.com. „free-vbucks-claim.com“ ist gefälscht — kostenlose V-Bucks über eine externe Seite gibt es nicht.',
 'heute 16:40','🎁 Deine 13.500 GRATIS V-Bucks warten!',
 'Glückwunsch! Dein Konto wurde für 13.500 kostenlose V-Bucks ausgewählt. Hol sie dir...',
 E'<div class="eml fam-tech" style="--brand:#7b2ff7;--cta:#7b2ff7"><div class="eml-body"><p>Glückwunsch!</p><p>Dein Konto wurde für <strong>13.500 GRATIS V-Bucks</strong> ausgewählt. Melde dich an, um sie vor Ablauf des Angebots einzulösen:</p><p>{{link:0}}</p><p>Beeil dich — das Angebot läuft in 30 Minuten ab!</p><p>— Das Fortnite-Belohnungsteam</p></div></div>',
 '[{"label":"Meine V-Bucks einlösen","real_url":"http://free-vbucks-claim.com/login","suspicious":true,"warning":"Die echte Domain ist epicgames.com. Eine Seite, die dich zum Anmelden auffordert, um „kostenlose V-Bucks“ zu geben, stiehlt dein Fortnite-Konto."}]'::jsonb,
 TRUE,
 '["Kostenlose Spielwährung gibt es nicht — es ist immer ein Köder","Absenderdomain free-vbucks-claim.com ist nicht epicgames.com","Zeitdruck: „läuft in 30 Minuten ab“","Der Link verlangt eine Anmeldung auf einer fremden Seite"]'::jsonb,
 '[]'::jsonb,
 'Das ist Phishing, um dein Spielkonto zu stehlen. Niemand verschenkt V-Bucks über einen Link. Wer sich auf dieser gefälschten Seite anmeldet, gibt sein Epic-Games-Konto her. Kaufe V-Bucks nur im Spiel selbst und aktiviere die Zwei-Faktor-Authentifizierung.',
 500),

('de','sms','personal','normal','account',
 'Instagram','+49 151 23456789',
 'Instagram schickt keine SMS von einer Handynummer und droht nicht per Link mit Löschung.',
 'heute 19:12','Instagram',
 'Dein Konto wird innerhalb von 24 Stunden gelöscht wegen einer Beschwerde...',
 E'Instagram: Wir haben eine Urheberrechtsbeschwerde zu deinem Konto erhalten. Es wird innerhalb von 24 Stunden GELÖSCHT, sofern du keinen Einspruch einlegst: {{link:0}}',
 '[{"label":"instagram-help-center.com","real_url":"http://instagram-help-center.com/appeal","suspicious":true,"warning":"Instagram nutzt instagram.com und die App selbst. „instagram-help-center.com“ ist gefälscht und will dein Passwort stehlen."}]'::jsonb,
 TRUE,
 '["Drohung mit Löschung in 24 Stunden ist Panikmache","Absender ist eine Handynummer, kein offizieller Kanal","Link führt zu instagram-help-center.com, nicht instagram.com","Echte Hinweise erscheinen in der App, nicht in einer SMS"]'::jsonb,
 '[]'::jsonb,
 'Das ist Phishing. Betrüger drohen mit Löschung, damit du in Panik klickst. Prüfe Hinweise immer in der Instagram-App selbst (Einstellungen). Tippe nie auf einen Link aus so einer Nachricht.',
 501),

('de','whatsapp','personal','normal','overig',
 'Unbekannte Nummer','+49 160 98765432',
 'Eine „Verlosung“, an der du nie teilgenommen hast, ist immer gefälscht. Echte Marken küren keine Gewinner über WhatsApp.',
 'heute 13:05','WhatsApp',
 'GLÜCKWUNSCH! Deine Nummer wurde gezogen — du hast ein iPhone 16 Pro gewonnen...',
 E'🎉 GLÜCKWUNSCH! 🎉 Deine Telefonnummer wurde bei unserer Verlosung gezogen. Du hast ein *iPhone 16 Pro* gewonnen! Zahl nur 1,95 € Versand und gib deine Daten ein: {{link:0}}',
 '[{"label":"apple-gewinnspiel-de.com","real_url":"http://apple-gewinnspiel-de.com/claim","suspicious":true,"warning":"Apple verlost keine Telefone über WhatsApp. Die Seite verlangt Zahlungsdaten, die dann missbraucht werden."}]'::jsonb,
 TRUE,
 '["Du hast nie an einem Gewinnspiel teilgenommen","Kleiner Betrag (1,95 €), um deine Kartendaten abzugreifen","Unbekannte Nummer über WhatsApp","Link zu apple-gewinnspiel-de.com, nicht apple.com"]'::jsonb,
 '[]'::jsonb,
 'Das ist ein Gewinn-Betrug. Wenn du etwas „gewonnen“ hast, ohne teilgenommen zu haben, stimmt etwas nicht. Der kleine Betrag ist ein Trick, um an deine Kartendaten zu kommen. Ignorieren und blockieren.',
 502),

('de','sms','personal','normal','account',
 'Steam','Steam',
 'Das ist ein ECHTER Steam-Guard-Code. Steam sendet ihn nur, wenn DU dich anmeldest, und fügt nie einen Link hinzu.',
 'heute 20:31','Steam',
 'Dein Steam-Guard-Code lautet 5KQ7T. Teile diesen Code mit niemandem.',
 E'Steam Guard: Dein Anmeldecode lautet <strong>5KQ7T</strong>.\n\nDieser Code dient zur Anmeldung in deinem eigenen Konto. Teile ihn mit niemandem — Steam-Mitarbeiter fragen nie danach.',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Kein Link in der Nachricht — nur ein Code","Du hast dich gerade selbst anmelden wollen","Der Absender ist Steam, keine fremde Nummer","Die Nachricht verlangt nichts; sie warnt, den Code geheim zu halten"]'::jsonb,
 'Das ist ein echter Zwei-Faktor-Code (Steam Guard). Du erhältst ihn, wenn du dich selbst anmeldest. Wichtig: Teile so einen Code NIEMALS — wer nach deinem Code fragt (im Chat, am Telefon oder als „Support“), will dein Konto stehlen. Gib ihn nur selbst im offiziellen Anmeldebildschirm ein.',
 503);


-- ============================================================
-- GEVORDERD SMS/WHATSAPP (advanced difficulty)
-- 7 scenario's × 6 locales = 42 rijen.
-- SMS A–D (sort 362–365), WhatsApp E–G (sort 370–372).
-- ============================================================
INSERT INTO inbox_messages
  (locale, channel, audience, difficulty, sender_name, sender_address, sender_note, received_label, subject, preview, body, links, is_phishing, red_flags, green_flags, explanation, sort_order) VALUES

-- ==================== NL ====================

-- NL / SMS A — Rabobank phishing (sort 362)
('nl','sms','both','advanced',
 'Rabobank','+31 6 19 83 44 72',
 'Een bank stuurt nooit een link om in te loggen via sms — ook niet als het bericht rustig en professioneel klinkt.',
 'vandaag 09:18','Rabobank',
 'Rabobank: wij zagen een onbekende inlogpoging...',
 E'Rabobank: wij signaleerden een inlogpoging op uw rekening vanuit een onbekend apparaat. Klopt dit niet? Blokkeer uw toegang tijdelijk via {{link:0}}',
 '[{"label":"Toegang blokkeren","real_url":"https://rabo-accountcheck.nl/blokkeer","suspicious":true,"warning":"Link gaat naar rabo-accountcheck.nl, niet rabobank.nl. Dit is een nepsite."}]'::jsonb,
 TRUE,
 '["Link naar rabo-accountcheck.nl in plaats van rabobank.nl","Banken sturen nooit een inloglink via sms","Bericht klinkt rustig en officieel — extra verdacht","Onbekend apparaat-melding is een klassiek smishing-trucje"]'::jsonb,
 '[]'::jsonb,
 'Dit is geavanceerde smishing. De domeinnaam rabo-accountcheck.nl lijkt op Rabobank maar is het niet. De Rabobank stuurt nooit inloglinks via sms. Open altijd zelf de Rabo-app of bel het nummer op uw bankpas.',
 362),

-- NL / SMS B — DHL customs phishing (sort 363)
('nl','sms','both','advanced',
 'DHL','+31 97 01 55 38 21',
 'Echte douanekosten komen per brief van de Douane zelf — nooit via een sms-link van de bezorger.',
 'vandaag 14:33','DHL',
 'DHL: uw zending is aangehouden bij de douane. Vrijgave...',
 E'DHL: uw zending (JD014600007030174950) is aangehouden bij de douane. Vrijgave vereist €2,10 aan douanekosten. Betaal op {{link:0}} — bezorging volgt morgen.',
 '[{"label":"Douanekosten betalen","real_url":"https://dhl-bezorging.com/douane/vrijgave","suspicious":true,"warning":"Link naar dhl-bezorging.com, niet dhl.nl of dhl.com. Dit is een nepsite die uw betaalgegevens steelt."}]'::jsonb,
 TRUE,
 '["Link naar dhl-bezorging.com in plaats van dhl.nl","Echte douanekosten komen per brief, nooit via sms","Klein bedrag (€2,10) laat u snel betalen zonder na te denken","Specifiek trackingnummer wekt onterecht vertrouwen"]'::jsonb,
 '[]'::jsonb,
 'Dit is smishing. Echte douanekosten worden gemeld via een brief van de Douane zelf — niet via een sms-link van de bezorger. Controleer zendingen altijd via dhl.nl of de DHL-app.',
 363),

-- NL / SMS C — KPN phishing (sort 364)
('nl','sms','both','advanced',
 'KPN','+31 97 01 02 19 74',
 'KPN stuurt factuurmeldingen via e-mail of Mijn KPN — nooit als betaallink in een sms.',
 'vandaag 10:05','KPN',
 'KPN: uw factuur van € 49,95 staat klaar. Betaal vóór...',
 E'KPN: uw factuur van €49,95 (mei) staat klaar. Betaal vóór 30 mei via {{link:0}} om afsluiting van uw abonnement te voorkomen.',
 '[{"label":"Factuur betalen","real_url":"https://kpn-betalen.com/factuur/mei","suspicious":true,"warning":"Link naar kpn-betalen.com, niet mijn.kpn.com. Dit is een nepsite."}]'::jsonb,
 TRUE,
 '["Link naar kpn-betalen.com in plaats van mijn.kpn.com","KPN verstuurt facturen via e-mail, niet als sms-betaallink","Dreigt met afsluiting om druk te zetten","Geloofwaardig bedrag (€49,95) maakt het moeilijker te herkennen"]'::jsonb,
 '[]'::jsonb,
 'Dit is smishing. KPN verstuurt factuurmeldingen via e-mail of de Mijn KPN-app — nooit als betaallink in een sms. Log altijd zelf in via mijn.kpn.com als u uw factuur wil bekijken.',
 364),

-- NL / SMS D — Albert Heijn legitimate (sort 365)
('nl','sms','both','advanced',
 'Albert Heijn','Albert Heijn',
 'Albert Heijn stuurt bonusbevestigingen via sms als u daarvoor toestemming heeft gegeven. Geen link, geen betaling.',
 'vandaag 08:03','Albert Heijn',
 'AH: uw bonus-actualisatie is verwerkt. Uw nieuwe saldo...',
 E'AH: uw Bonuskaart is bijgewerkt. Uw huidige statuszegel-saldo: 28 zegels. Bekijk uw bonus-aanbiedingen in de AH-app of op ah.nl.',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Geen link in het bericht — doorverwijzing naar de officiële app of website","Geen verzoek om te betalen of in te loggen","Alleen informatie over uw eigen saldo","Past bij informatie die u bij aanmelding heeft opgegeven"]'::jsonb,
 'Dit is een echt sms-bericht van Albert Heijn. Let op het verschil: géén link, géén betaling gevraagd — alleen een statusupdate. Twijfelt u? Open de AH-app zelf in plaats van te reageren op het sms-bericht.',
 365),

-- NL / WhatsApp E — "is dit jij?" phishing (sort 370)
('nl','whatsapp','both','advanced',
 'Onbekend nummer','+31 6 77 03 94 21',
 'Een "is dit jij?"-link van een onbekend nummer leidt altijd naar account-overname via QR-code of verificatiecode.',
 'vandaag 21:09','Onbekend nummer',
 'Haha, is dit jij?? 😂😂 Moet je écht even kijken...',
 E'Haha, is dit jij?? 😂😂 Moet je écht even kijken:\n\n{{link:0}}\n\nIk schrok me wild toen ik het zag lol',
 '[{"label":"Filmpje bekijken","real_url":"https://wa-video-check.com/kijk?id=NL-447","suspicious":true,"warning":"Link naar wa-video-check.com, geen officieel WhatsApp-domein. Klikken kan leiden tot account-overname."}]'::jsonb,
 TRUE,
 '["Onbekend nummer — geen bekende contactnaam","\"Is dit jij?\" is een bekende phishingzin op WhatsApp","Link naar wa-video-check.com, niet whatsapp.com","Klikken leidt vaak naar QR-scan of verificatiecode waarmee uw account wordt overgenomen"]'::jsonb,
 '[]'::jsonb,
 'Dit is een klassieke WhatsApp-phishinglink. Wie erop klikt, wordt gevraagd een QR-code te scannen of een verificatiecode in te voeren. Daarna nemen oplichters uw account over en sturen hetzelfde bericht naar al uw contacten.',
 370),

-- NL / WhatsApp F — fake Tikkie (sort 371)
('nl','whatsapp','both','advanced',
 'Onbekend nummer','+31 6 58 14 77 03',
 'Tikkie-links kunnen nep zijn. Het echte domein is tikkie.me. Een toegestuurde link is nooit nodig om geld te ontvangen.',
 'vandaag 15:22','Onbekend nummer',
 'Hé! Ik moet nog een bedragje naar je sturen van vorige week...',
 E'Hé! Ik moet nog een bedragje naar je sturen van vorige week, maar mijn app doet raar. Kun jij even bevestigen via {{link:0}}? Dan schrijf ik het direct over. 🙏',
 '[{"label":"Tikkie bevestigen","real_url":"https://tikkie-betaalverzoek.nl/pay?t=5f8a2","suspicious":true,"warning":"Link naar tikkie-betaalverzoek.nl, niet het echte tikkie.me. Dit is een nep-betaallink die uw bankgegevens steelt."}]'::jsonb,
 TRUE,
 '["Link naar tikkie-betaalverzoek.nl in plaats van tikkie.me","Om geld te ONTVANGEN hoeft u nooit ergens op te klikken of in te loggen","Onbekend nummer — geen naam van afzender","Sociale druk (\"van vorige week\") om snel te klikken"]'::jsonb,
 '[]'::jsonb,
 'Dit is Tikkie-fraude. De link gaat naar een nepsite die uw bankgegevens steelt. Een echt Tikkie-verzoek ontvangen werkt via de officiële app — u hoeft nooit op een toegestuurde link te klikken om geld te ontvangen.',
 371),

-- NL / WhatsApp G — DHL real (sort 372)
('nl','whatsapp','both','advanced',
 'DHL Express','DHL Express',
 'DHL gebruikt WhatsApp Business voor bezorgmeldingen. Geen link naar extern domein, geen betaling — alleen statusinformatie.',
 'vandaag 11:48','DHL Express',
 'DHL Express: uw zending 1234567890 is onderweg...',
 E'DHL Express 📦\n\nUw zending 1234567890 is onderweg en wordt vandaag bezorgd.\n\nGeschatte levertijd: 14:00–16:00\nBestemming: Amsterdam\n\nVraag? Beantwoord dit bericht of ga naar dhl.nl',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Geen externe link — doorverwijzing naar het officiële dhl.nl","Geen betaling of inloggegevens gevraagd","Concrete bezorginformatie met trackingnummer en tijdvak","Zakelijke, neutrale toon zonder druk"]'::jsonb,
 'Dit is een echt WhatsApp Business-bericht van DHL. Er wordt niets gevraagd — alleen een statusmelding. Wil u het zeker weten? Zoek het trackingnummer zelf op via dhl.nl of de DHL-app.',
 372),

-- ==================== NL-BE ====================

-- NL-BE / SMS A — ING bank phishing (sort 362)
('nl-BE','sms','both','advanced',
 'ING','+32 4 97 18 33 56',
 'ING stuurt nooit een sms-link om uw rekening te beveiligen. Open altijd de officiële ING-app.',
 'vandaag 09:18','ING',
 'ING: wij detecteerden een inlogpoging op een onbekend...',
 E'ING: wij detecteerden een inlogpoging op een onbekend apparaat. Niet u? Beveilig uw rekening tijdelijk via {{link:0}}',
 '[{"label":"Rekening beveiligen","real_url":"https://ing-card-verify.be/beveilig","suspicious":true,"warning":"Link naar ing-card-verify.be, niet ing.be. Dit is een nepsite."}]'::jsonb,
 TRUE,
 '["Link naar ing-card-verify.be in plaats van ing.be","ING stuurt nooit een inloglink via sms","Melding van onbekend apparaat creëert onterecht paniek","Bericht klinkt professioneel — net als een echte bankmelding"]'::jsonb,
 '[]'::jsonb,
 'Dit is geavanceerde smishing. ing-card-verify.be is geen ING-domein. ING stuurt nooit links via sms om in te loggen. Open altijd de officiële ING-app of bel het nummer op uw bankkaart.',
 362),

-- NL-BE / SMS B — bpost customs phishing (sort 363)
('nl-BE','sms','both','advanced',
 'bpost','+32 4 56 88 12 37',
 'Echte douanekosten komen via een officieel aanslagbiljet — nooit als betaallink in een sms van de bezorger.',
 'vandaag 14:33','bpost',
 'bpost: uw pakket is aangehouden aan de douane...',
 E'bpost: uw pakket (BE201234567890) wordt aangehouden aan de douane. Vrijgave vereist €2,35 invoerrechten. Betaal nu via {{link:0}}',
 '[{"label":"Invoerrechten betalen","real_url":"https://bpost-douane.be/vrijgave","suspicious":true,"warning":"Link naar bpost-douane.be, niet bpost.be. Dit is een nepsite."}]'::jsonb,
 TRUE,
 '["Link naar bpost-douane.be in plaats van bpost.be","Douanekosten komen als officieel aanslagbiljet, niet als sms","Klein bedrag (€2,35) laat u snel betalen","Valse trackingnummer wekt vertrouwen"]'::jsonb,
 '[]'::jsonb,
 'Dit is smishing. Echte invoerrechten worden opgelegd via een officieel aanslagbiljet — nooit via een sms-link. Controleer pakketten altijd via bpost.be of de bpost-app.',
 363),

-- NL-BE / SMS C — Proximus phishing (sort 364)
('nl-BE','sms','both','advanced',
 'Proximus','+32 4 99 07 44 81',
 'Proximus stuurt facturen via e-mail of Mijn Proximus — nooit als betaallink in een sms.',
 'vandaag 10:05','Proximus',
 'Proximus: uw factuur van € 52,00 staat open. Betaal...',
 E'Proximus: uw maandfactuur van €52,00 staat nog open. Betaal vóór 28 mei via {{link:0}} om onderbreking van uw verbinding te vermijden.',
 '[{"label":"Factuur betalen","real_url":"https://proximus-betalen.com/factuur","suspicious":true,"warning":"Link naar proximus-betalen.com, niet mijnproximus.be. Dit is een nepsite."}]'::jsonb,
 TRUE,
 '["Link naar proximus-betalen.com in plaats van mijnproximus.be","Proximus stuurt facturen via e-mail, niet als sms-betaallink","Dreigt met onderbreking om druk te zetten","Geloofwaardig bedrag maakt het lastiger te herkennen"]'::jsonb,
 '[]'::jsonb,
 'Dit is smishing. Proximus verstuurt factuurmeldingen via e-mail of Mijn Proximus — nooit als betaallink in een sms. Log altijd zelf in via mijnproximus.be.',
 364),

-- NL-BE / SMS D — Colruyt legitimate (sort 367; 365/366 waren al bezet)
('nl-BE','sms','both','advanced',
 'Colruyt','Colruyt',
 'Colruyt stuurt loyaliteitsberichten als u daarvoor toestemming gaf. Geen link, geen betaling.',
 'vandaag 08:03','Colruyt',
 'Colruyt: uw Xtra-punten zijn bijgewerkt. Uw saldo...',
 E'Colruyt: uw Xtra-saldo is bijgewerkt naar 340 punten. Bekijk uw voordelen in de Xtra-app of op xtra.be.',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Geen link in het bericht — doorverwijzing naar de officiële app of website","Geen verzoek om te betalen of in te loggen","Alleen informatie over uw eigen puntensaldo","Consistent met wat u bij aanmelding heeft opgegeven"]'::jsonb,
 'Dit is een echt sms-bericht van Colruyt. Géén link, géén betaling gevraagd — alleen een saldo-update. Twijfelt u? Open de Xtra-app zelf.',
 367),

-- NL-BE / WhatsApp E — "ben jij dit?" phishing (sort 370)
('nl-BE','whatsapp','both','advanced',
 'Onbekend nummer','+32 4 89 33 57 12',
 'Een "is dit jij?"-link van een onbekend nummer leidt altijd naar account-overname via QR-code of verificatiecode.',
 'vandaag 21:09','Onbekend nummer',
 'Haha, ben jij dit?? 😂😂 Moet je echt eens kijken...',
 E'Haha, ben jij dit?? 😂😂 Moet je echt eens kijken:\n\n{{link:0}}\n\nIk was echt geschrokken haha',
 '[{"label":"Filmpje bekijken","real_url":"https://wa-video-check.com/kijk?id=BE-497","suspicious":true,"warning":"Link naar wa-video-check.com, geen officieel WhatsApp-domein. Klikken kan leiden tot account-overname."}]'::jsonb,
 TRUE,
 '["Onbekend nummer — geen bekende contactnaam","\"Ben jij dit?\" is een bekende phishingzin op WhatsApp","Link naar wa-video-check.com, niet whatsapp.com","Klikken leidt vaak naar QR-scan of code waarmee uw account wordt overgenomen"]'::jsonb,
 '[]'::jsonb,
 'Dit is een klassieke WhatsApp-phishinglink. Wie erop klikt, wordt gevraagd een QR-code te scannen of een verificatiecode in te voeren. Daarna nemen oplichters uw account over en sturen hetzelfde bericht naar al uw contacten.',
 370),

-- NL-BE / WhatsApp F — fake Payconiq (sort 371)
('nl-BE','whatsapp','both','advanced',
 'Onbekend nummer','+32 4 77 14 58 03',
 'Payconiq-links die u "moet bevestigen" zijn nep. Om geld te ontvangen hoeft u nooit op een link te klikken.',
 'vandaag 15:22','Onbekend nummer',
 'Hey! Ik wil je nog een bedragje doorsturen maar mijn app doet raar...',
 E'Hey! Ik wil je nog een bedragje doorsturen maar mijn Payconiq doet moeilijk. Kun je even bevestigen via {{link:0}}? Dan stuur ik het zo door. 🙏',
 '[{"label":"Payconiq bevestigen","real_url":"https://payconiq-bevestig.be/pay?ref=bc447","suspicious":true,"warning":"Link naar payconiq-bevestig.be, niet het echte payconiq.be. Dit is een nep-betaallink."}]'::jsonb,
 TRUE,
 '["Link naar payconiq-bevestig.be in plaats van payconiq.be","Om geld te ONTVANGEN hoeft u nooit op een link te klikken","Onbekend nummer — geen naam van afzender","Informele urgentie (\"doet moeilijk\") om snel te klikken"]'::jsonb,
 '[]'::jsonb,
 'Dit is Payconiq-fraude. De link gaat naar een nepsite. Om geld te ontvangen hoeft u nooit een link te bevestigen — dat werkt via de officiële Payconiq-app. Klik nooit op betaallinks van onbekende nummers.',
 371),

-- NL-BE / WhatsApp G — bpost real (sort 372)
('nl-BE','whatsapp','both','advanced',
 'bpost','bpost',
 'bpost gebruikt WhatsApp Business voor pakketmeldingen. Geen externe link, geen betaling.',
 'vandaag 11:48','bpost',
 'bpost: uw pakket BA987654321BE is onderweg...',
 E'bpost 📦\n\nUw pakket BA987654321BE is onderweg en wordt vandaag geleverd.\n\nGeschat tijdvak: 13:00–15:00\n\nOpvolgen via bpost.be of de bpost-app.',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Geen externe link — doorverwijzing naar het officiële bpost.be","Geen betaling of inloggegevens gevraagd","Concrete bezorginformatie met trackingnummer en tijdvak","Zakelijke toon zonder urgentie of druk"]'::jsonb,
 'Dit is een echt WhatsApp Business-bericht van bpost. Geen link, geen betaling — alleen een statusmelding. Wil u het zeker weten? Zoek het trackingnummer op via bpost.be of de bpost-app.',
 372),

-- ==================== EN (British English) ====================

-- EN / SMS A — Barclays phishing (sort 362)
('en','sms','both','advanced',
 'Barclays','+44 7700 900 183',
 'Banks never send a link to log in via text message, even if the message sounds calm and professional.',
 'today 09:18','Barclays',
 'Barclays: we detected a sign-in attempt from an unknown...',
 E'Barclays: we detected a sign-in attempt from an unknown device. Not you? Temporarily lock your account at {{link:0}}',
 '[{"label":"Lock my account","real_url":"https://barclays-verify.net/lock","suspicious":true,"warning":"Link goes to barclays-verify.net, not barclays.co.uk. This is a fake site designed to steal your details."}]'::jsonb,
 TRUE,
 '["Link to barclays-verify.net instead of barclays.co.uk","Banks never send login links via text","Calm, professional tone is designed to lower your guard","Unknown-device alert is a classic smishing technique"]'::jsonb,
 '[]'::jsonb,
 'This is advanced smishing. barclays-verify.net is not a Barclays domain. Banks never send login links by text. Open the official Barclays app yourself or call the number on your card.',
 362),

-- EN / SMS B — Royal Mail customs phishing (sort 363)
('en','sms','both','advanced',
 'Royal Mail','+44 7700 900 374',
 'Royal Mail does not charge customs fees by text link. Any genuine customs charges are notified by post.',
 'today 14:33','Royal Mail',
 'Royal Mail: your parcel is held at customs. Pay £1.99...',
 E'Royal Mail: your parcel (GB006281234567) is held at customs. Release requires a customs fee of £1.99. Pay at {{link:0}} — delivery follows within 24 hours.',
 '[{"label":"Pay customs fee","real_url":"https://royalmail-parcel.co.uk/customs/release","suspicious":true,"warning":"Link to royalmail-parcel.co.uk, not royalmail.com. This is a fake site."}]'::jsonb,
 TRUE,
 '["Link to royalmail-parcel.co.uk instead of royalmail.com","Royal Mail notifies customs charges by post, not text","Small amount (£1.99) makes you pay without thinking","Specific tracking number gives a false sense of legitimacy"]'::jsonb,
 '[]'::jsonb,
 'This is smishing. Genuine customs charges are notified by a letter from HMRC or CITES — not a text link from the courier. Always check parcels at royalmail.com or in the Royal Mail app.',
 363),

-- EN / SMS C — O2 invoice phishing (sort 364)
('en','sms','both','advanced',
 'O2','+44 7700 900 892',
 'O2 sends bills by email or through the My O2 app — never as a payment link in a text.',
 'today 10:05','O2',
 'O2: your March bill of £35.00 is ready. Pay before...',
 E'O2: your March bill of £35.00 is ready. Pay before 31 March via {{link:0}} to avoid suspension of your service.',
 '[{"label":"Pay bill","real_url":"https://o2-invoices.com/pay/march","suspicious":true,"warning":"Link to o2-invoices.com, not my.o2.co.uk. This is a fake site."}]'::jsonb,
 TRUE,
 '["Link to o2-invoices.com instead of my.o2.co.uk","O2 sends bills by email, not as text payment links","Threatens service suspension to create urgency","Plausible amount makes it harder to spot"]'::jsonb,
 '[]'::jsonb,
 'This is smishing. O2 sends bill notifications by email or through the My O2 app — never as a payment link in a text. Always log in at my.o2.co.uk to view your bill.',
 364),

-- EN / SMS D — Amazon legitimate (sort 365)
('en','sms','both','advanced',
 'Amazon','AMAZON',
 'Amazon sends delivery updates by text if you opted in. No link to an external site, no payment required.',
 'today 08:03','Amazon',
 'Amazon: your order 204-7382910-4563821 will be delivered...',
 E'Amazon: your order 204-7382910-4563821 will be delivered today between 1pm–3pm. Track at amazon.co.uk/orders or in the Amazon app.',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Directs you to amazon.co.uk — the official site","No payment or login credentials requested","Concrete delivery window and order number","No external link or pressure to click"]'::jsonb,
 'This is a genuine Amazon delivery update. Note: no suspicious link, no payment request — just a status update with a time window. If in doubt, go to amazon.co.uk yourself rather than following any link in a text.',
 365),

-- EN / WhatsApp E — "is this you?" phishing (sort 370)
('en','whatsapp','both','advanced',
 'Unknown number','+44 7700 900 671',
 'An "is this you?" link from an unknown number always leads to account takeover via a QR code or verification code.',
 'today 21:09','Unknown number',
 'Haha, is this you?? 😂😂 You have to see this...',
 E'Haha, is this you?? 😂😂 You have to see this:\n\n{{link:0}}\n\nI couldn''t believe it when I saw it lol',
 '[{"label":"Watch video","real_url":"https://wa-video-check.com/view?id=GB-447","suspicious":true,"warning":"Link to wa-video-check.com, not an official WhatsApp domain. Clicking can lead to account takeover."}]'::jsonb,
 TRUE,
 '["Unknown number — not a saved contact","\"Is this you?\" is a well-known WhatsApp phishing phrase","Link to wa-video-check.com, not whatsapp.com","Clicking typically leads to a QR code or verification code that hijacks your account"]'::jsonb,
 '[]'::jsonb,
 'This is a classic WhatsApp phishing link. Clicking it asks you to scan a QR code or enter a verification code — after which scammers take over your WhatsApp account and send the same message to all your contacts.',
 370),

-- EN / WhatsApp F — fake PayPal request (sort 371)
('en','whatsapp','both','advanced',
 'Unknown number','+44 7700 900 823',
 'PayPal links shared via WhatsApp are almost always fake. To receive money you never need to click a link.',
 'today 15:22','Unknown number',
 'Hey! I owe you a bit from last week but my PayPal is playing up...',
 E'Hey! I owe you a bit from last week but my PayPal is playing up. Can you just confirm via {{link:0}} and I''ll send it right over? 🙏',
 '[{"label":"Confirm PayPal","real_url":"https://paypal-request.co.uk/confirm?id=gb447","suspicious":true,"warning":"Link to paypal-request.co.uk, not paypal.com. This is a fake payment page that steals your details."}]'::jsonb,
 TRUE,
 '["Link to paypal-request.co.uk instead of paypal.com","You never need to click a link to RECEIVE money","Unknown number — no name shown","Social pressure (\"from last week\") to make you act quickly"]'::jsonb,
 '[]'::jsonb,
 'This is PayPal fraud. The link goes to a fake page designed to steal your bank or PayPal credentials. Receiving money via PayPal requires nothing from you — it just appears in your account. Never click payment links sent via WhatsApp.',
 371),

-- EN / WhatsApp G — Amazon delivery real (sort 372)
('en','whatsapp','both','advanced',
 'Amazon','Amazon',
 'Amazon uses WhatsApp Business for delivery notifications in some regions. No external link, no payment required.',
 'today 11:48','Amazon',
 'Amazon: your order 204-7382910-4563821 is on its way...',
 E'Amazon 📦\n\nYour order 204-7382910-4563821 is on its way and will be delivered today.\n\nEstimated time: 1pm–3pm\nDelivery address: London\n\nTrack at amazon.co.uk/orders or in the Amazon app.',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["No external link — directs you to the official amazon.co.uk","No payment or credentials requested","Concrete delivery information with order number and time window","Professional, neutral tone with no pressure"]'::jsonb,
 'This is a genuine WhatsApp Business message from Amazon. Nothing is asked of you — it is just a status update. To verify, look up your order number at amazon.co.uk or in the Amazon app.',
 372),

-- ==================== FR (French) ====================

-- FR / SMS A — Crédit Agricole phishing (sort 362)
('fr','sms','both','advanced',
 'Crédit Agricole','+33 6 52 83 17 44',
 'Une banque n''envoie jamais de lien de connexion par SMS — même si le message semble calme et officiel.',
 'aujourd''hui 09:18','Crédit Agricole',
 'Crédit Agricole : nous avons détecté une connexion depuis...',
 E'Crédit Agricole : nous avons détecté une connexion depuis un appareil inconnu. Ce n''est pas vous ? Bloquez temporairement votre accès via {{link:0}}',
 '[{"label":"Bloquer mon accès","real_url":"https://ca-espace-client.com/bloquer","suspicious":true,"warning":"Lien vers ca-espace-client.com, pas credit-agricole.fr. C''est un site frauduleux."}]'::jsonb,
 TRUE,
 '["Lien vers ca-espace-client.com au lieu de credit-agricole.fr","Une banque n''envoie jamais de lien de connexion par SMS","Le ton calme et professionnel est conçu pour rassurer","L''alerte \"appareil inconnu\" est une technique classique de smishing"]'::jsonb,
 '[]'::jsonb,
 'C''est du smishing évolué. ca-espace-client.com n''est pas un domaine du Crédit Agricole. Votre banque ne vous envoie jamais de lien de connexion par SMS. Ouvrez toujours l''appli officielle ou appelez le numéro au dos de votre carte.',
 362),

-- FR / SMS B — La Poste customs phishing (sort 363)
('fr','sms','both','advanced',
 'La Poste','+33 6 71 44 28 93',
 'Les droits de douane sont notifiés par courrier officiel — jamais par lien SMS de la part du transporteur.',
 'aujourd''hui 14:33','La Poste',
 'La Poste : votre colis est retenu en douane. Réglez...',
 E'La Poste : votre colis (1A18006281234567) est retenu en douane. Sa libération nécessite €2,50 de frais de douane. Réglez sur {{link:0}} — livraison sous 24 h.',
 '[{"label":"Payer les frais","real_url":"https://laposte-suivi.com/douane/liberation","suspicious":true,"warning":"Lien vers laposte-suivi.com, pas laposte.fr. C''est un site frauduleux."}]'::jsonb,
 TRUE,
 '["Lien vers laposte-suivi.com au lieu de laposte.fr","Les droits de douane sont notifiés par courrier, pas par SMS","Petite somme (€2,50) pour vous faire payer sans réfléchir","Numéro de suivi inventé pour paraître crédible"]'::jsonb,
 '[]'::jsonb,
 'C''est du smishing. Les vrais droits de douane font l''objet d''un avis officiel des Douanes françaises — jamais d''un lien SMS du transporteur. Vérifiez toujours vos colis sur laposte.fr ou dans l''appli La Poste.',
 363),

-- FR / SMS C — Orange invoice phishing (sort 364)
('fr','sms','both','advanced',
 'Orange','+33 6 88 04 37 12',
 'Orange envoie les factures par e-mail ou via Mon Espace Orange — jamais comme lien de paiement par SMS.',
 'aujourd''hui 10:05','Orange',
 'Orange : votre facture de 49,90 € est disponible...',
 E'Orange : votre facture de 49,90 € (mai) est disponible. Réglez avant le 31 mai via {{link:0}} pour éviter la suspension de votre ligne.',
 '[{"label":"Payer ma facture","real_url":"https://orange-facture-client.com/payer/mai","suspicious":true,"warning":"Lien vers orange-facture-client.com, pas espaceclient.orange.fr. C''est un site frauduleux."}]'::jsonb,
 TRUE,
 '["Lien vers orange-facture-client.com au lieu de espaceclient.orange.fr","Orange envoie les factures par e-mail, pas comme lien SMS","Menace de suspension pour créer de l''urgence","Montant crédible difficile à identifier comme fraude"]'::jsonb,
 '[]'::jsonb,
 'C''est du smishing. Orange envoie les notifications de facture par e-mail ou via Mon Espace Orange — jamais comme lien de paiement dans un SMS. Connectez-vous toujours sur espaceclient.orange.fr pour voir votre facture.',
 364),

-- FR / SMS D — Amazon legitimate (sort 365)
('fr','sms','both','advanced',
 'Amazon','AMAZON',
 'Amazon envoie des SMS de livraison si vous avez donné votre accord. Aucun lien vers un site externe, aucun paiement requis.',
 'aujourd''hui 08:03','Amazon',
 'Amazon : votre commande 401-7382910-4563821 sera livrée...',
 E'Amazon : votre commande 401-7382910-4563821 sera livrée aujourd''hui entre 13 h et 15 h. Suivi sur amazon.fr/commandes ou dans l''appli Amazon.',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Redirige vers amazon.fr — le site officiel","Aucun paiement ni identifiant demandé","Créneau de livraison concret et numéro de commande","Aucun lien externe ni pression pour cliquer"]'::jsonb,
 'C''est un vrai SMS de livraison d''Amazon. Remarquez : aucun lien suspect, aucun paiement demandé — juste une mise à jour de statut. En cas de doute, rendez-vous vous-même sur amazon.fr.',
 365),

-- FR / WhatsApp E — "c'est toi?" phishing (sort 370)
('fr','whatsapp','both','advanced',
 'Numéro inconnu','+33 6 74 03 94 21',
 'Un lien "c''est toi sur la vidéo ?" d''un numéro inconnu conduit toujours à une prise de contrôle de compte.',
 'aujourd''hui 21:09','Numéro inconnu',
 'Haha, c''est toi sur cette vidéo ?? 😂😂 Il faut vraiment...',
 E'Haha, c''est toi sur cette vidéo ?? 😂😂 Il faut vraiment que tu regardes ça :\n\n{{link:0}}\n\nJ''en revenais pas en voyant ça lol',
 '[{"label":"Voir la vidéo","real_url":"https://wa-video-check.com/voir?id=FR-447","suspicious":true,"warning":"Lien vers wa-video-check.com, pas un domaine WhatsApp officiel. Cliquer peut entraîner la prise de contrôle de votre compte."}]'::jsonb,
 TRUE,
 '["Numéro inconnu — pas un contact enregistré","\"C''est toi ?\" est une formule classique de phishing WhatsApp","Lien vers wa-video-check.com, pas whatsapp.com","Cliquer mène souvent à un QR code ou code de vérification qui permet de pirater votre compte"]'::jsonb,
 '[]'::jsonb,
 'C''est un lien de phishing WhatsApp classique. En cliquant, on vous demande de scanner un QR code ou d''entrer un code de vérification. Les escrocs prennent alors le contrôle de votre compte et envoient le même message à tous vos contacts.',
 370),

-- FR / WhatsApp F — fake Lydia (sort 371)
('fr','whatsapp','both','advanced',
 'Numéro inconnu','+33 6 58 14 77 03',
 'Les liens de paiement partagés via WhatsApp sont presque toujours faux. Pour recevoir de l''argent, vous n''avez jamais besoin de cliquer sur un lien.',
 'aujourd''hui 15:22','Numéro inconnu',
 'Coucou ! Je te dois encore un peu d''argent de la semaine...',
 E'Coucou ! Je te dois encore un peu d''argent de la semaine dernière mais mon appli Lydia bug. Tu peux confirmer via {{link:0}} et je te vire ça tout de suite ? 🙏',
 '[{"label":"Confirmer Lydia","real_url":"https://lydia-paiement.fr/confirmer?ref=fr447","suspicious":true,"warning":"Lien vers lydia-paiement.fr, pas lydia-app.com. C''est une fausse page de paiement."}]'::jsonb,
 TRUE,
 '["Lien vers lydia-paiement.fr au lieu de lydia-app.com","Pour RECEVOIR de l''argent, vous n''avez jamais besoin de cliquer sur un lien","Numéro inconnu — pas de nom d''expéditeur","Pression sociale (\"de la semaine dernière\") pour agir vite"]'::jsonb,
 '[]'::jsonb,
 'C''est une fraude Lydia. Le lien mène vers un faux site qui vole vos coordonnées bancaires. Recevoir de l''argent via Lydia ne demande rien de votre part — l''argent apparaît directement dans votre appli. Ne cliquez jamais sur des liens de paiement envoyés par WhatsApp.',
 371),

-- FR / WhatsApp G — Chronopost real (sort 372)
('fr','whatsapp','both','advanced',
 'Chronopost','Chronopost',
 'Chronopost utilise WhatsApp Business pour les notifications de livraison. Pas de lien externe, pas de paiement.',
 'aujourd''hui 11:48','Chronopost',
 'Chronopost: votre colis XP123456789FR est en cours...',
 E'Chronopost 📦\n\nVotre colis XP123456789FR est en cours de livraison et sera remis aujourd''hui.\n\nCréneau estimé : 13 h–15 h\nVille : Paris\n\nSuivi sur chronopost.fr ou dans l''appli Chronopost.',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Pas de lien externe — redirige vers chronopost.fr officiel","Aucun paiement ni identifiant demandé","Informations concrètes : numéro de colis et créneau","Ton professionnel et neutre sans urgence"]'::jsonb,
 'C''est un vrai message WhatsApp Business de Chronopost. Aucune action n''est demandée — c''est juste une notification de statut. Pour vérifier, cherchez votre numéro de colis vous-même sur chronopost.fr.',
 372),

-- ==================== FR-BE (Belgian French) ====================

-- FR-BE / SMS A — ING phishing (sort 362)
('fr-BE','sms','both','advanced',
 'ING','+32 4 77 58 33 56',
 'ING n''envoie jamais de lien de connexion par SMS. Ouvrez toujours l''appli ING officielle.',
 'aujourd''hui 09:18','ING',
 'ING : nous avons détecté une connexion depuis un appareil...',
 E'ING : nous avons détecté une connexion depuis un appareil inconnu. Pas vous ? Bloquez temporairement votre compte via {{link:0}}',
 '[{"label":"Bloquer mon compte","real_url":"https://ing-verification.be/bloquer","suspicious":true,"warning":"Lien vers ing-verification.be, pas ing.be. C''est un site frauduleux."}]'::jsonb,
 TRUE,
 '["Lien vers ing-verification.be au lieu de ing.be","ING n''envoie jamais de lien de connexion par SMS","Alerte \"appareil inconnu\" conçue pour créer de la panique","Ton professionnel pour imiter une vraie notification bancaire"]'::jsonb,
 '[]'::jsonb,
 'C''est du smishing évolué. ing-verification.be n''est pas un domaine ING. ING n''envoie jamais de liens par SMS pour vous connecter. Ouvrez toujours l''appli ING officielle ou appelez le numéro au dos de votre carte.',
 362),

-- FR-BE / SMS B — bpost phishing (sort 363)
('fr-BE','sms','both','advanced',
 'bpost','+32 4 56 88 12 37',
 'Les vrais droits de douane font l''objet d''un avis officiel — jamais d''un lien SMS de la part du transporteur.',
 'aujourd''hui 14:33','bpost',
 'bpost : votre colis est retenu à la douane...',
 E'bpost : votre colis (BE201234567890) est retenu à la douane. Sa libération nécessite €2,35 de droits d''entrée. Réglez maintenant via {{link:0}}',
 '[{"label":"Payer les droits","real_url":"https://bpost-suivi.be/douane","suspicious":true,"warning":"Lien vers bpost-suivi.be, pas bpost.be. C''est un site frauduleux."}]'::jsonb,
 TRUE,
 '["Lien vers bpost-suivi.be au lieu de bpost.be","Les droits de douane font l''objet d''un avis officiel, pas d''un SMS","Petite somme (€2,35) pour vous faire payer rapidement","Faux numéro de suivi pour paraître légitime"]'::jsonb,
 '[]'::jsonb,
 'C''est du smishing. Les vrais droits d''entrée sont communiqués via un avis officiel — jamais par lien SMS. Vérifiez vos colis sur bpost.be ou dans l''appli bpost.',
 363),

-- FR-BE / SMS C — Proximus phishing (sort 364)
('fr-BE','sms','both','advanced',
 'Proximus','+32 4 99 07 44 81',
 'Proximus envoie les factures par e-mail ou via Mon Proximus — jamais comme lien de paiement dans un SMS.',
 'aujourd''hui 10:05','Proximus',
 'Proximus : votre facture de 52,00 € est en attente...',
 E'Proximus : votre facture mensuelle de €52,00 est en attente. Payez avant le 28 mai via {{link:0}} pour éviter toute interruption de service.',
 '[{"label":"Payer ma facture","real_url":"https://proximus-payer.be/facture","suspicious":true,"warning":"Lien vers proximus-payer.be, pas monproximus.be. C''est un site frauduleux."}]'::jsonb,
 TRUE,
 '["Lien vers proximus-payer.be au lieu de monproximus.be","Proximus envoie les factures par e-mail, pas via un SMS","Menace d''interruption pour créer de l''urgence","Montant crédible difficile à reconnaître comme fraude"]'::jsonb,
 '[]'::jsonb,
 'C''est du smishing. Proximus envoie les notifications de facturation par e-mail ou via Mon Proximus — jamais comme lien de paiement SMS. Connectez-vous toujours sur monproximus.be.',
 364),

-- FR-BE / SMS D — Amazon legitimate (sort 365)
('fr-BE','sms','both','advanced',
 'Amazon','AMAZON',
 'Amazon envoie des SMS de livraison si vous y avez consenti. Aucun lien externe, aucun paiement requis.',
 'aujourd''hui 08:03','Amazon',
 'Amazon : votre commande 401-7382910-4563821 sera livrée...',
 E'Amazon : votre commande 401-7382910-4563821 sera livrée aujourd''hui entre 13 h et 15 h. Suivi sur amazon.fr/commandes ou dans l''appli Amazon.',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Redirige vers amazon.fr — le site officiel","Aucun paiement ni identifiant demandé","Créneau de livraison concret et numéro de commande","Aucun lien externe ni pression pour cliquer"]'::jsonb,
 'C''est un vrai SMS de livraison d''Amazon. Remarquez : aucun lien suspect, aucun paiement demandé — juste une mise à jour de statut. En cas de doute, rendez-vous vous-même sur amazon.fr.',
 365),

-- FR-BE / WhatsApp E — "c'est toi?" phishing (sort 370)
('fr-BE','whatsapp','both','advanced',
 'Numéro inconnu','+32 4 89 33 57 12',
 'Un lien "c''est toi sur la vidéo ?" d''un numéro inconnu conduit toujours à une prise de contrôle de compte.',
 'aujourd''hui 21:09','Numéro inconnu',
 'Haha, c''est bien toi sur cette vidéo ?? 😂😂 Tu dois vraiment...',
 E'Haha, c''est bien toi sur cette vidéo ?? 😂😂 Tu dois vraiment regarder ça :\n\n{{link:0}}\n\nJ''en revenais pas lol',
 '[{"label":"Voir la vidéo","real_url":"https://wa-video-check.com/voir?id=BE-497","suspicious":true,"warning":"Lien vers wa-video-check.com, pas un domaine WhatsApp officiel. Cliquer peut mener à la prise de contrôle de votre compte."}]'::jsonb,
 TRUE,
 '["Numéro inconnu — pas un contact enregistré","\"C''est toi ?\" est une formule classique de phishing WhatsApp","Lien vers wa-video-check.com, pas whatsapp.com","Cliquer mène souvent à un QR code ou code de vérification qui permet de pirater votre compte"]'::jsonb,
 '[]'::jsonb,
 'C''est un lien de phishing WhatsApp classique. En cliquant, on vous demande de scanner un QR code ou d''entrer un code de vérification. Les escrocs prennent alors le contrôle de votre compte et envoient le même message à tous vos contacts.',
 370),

-- FR-BE / WhatsApp F — fake Payconiq French (sort 371)
('fr-BE','whatsapp','both','advanced',
 'Numéro inconnu','+32 4 77 14 58 03',
 'Les liens Payconiq partagés via WhatsApp sont presque toujours faux. Pour recevoir de l''argent, vous n''avez jamais besoin de cliquer sur un lien.',
 'aujourd''hui 15:22','Numéro inconnu',
 'Salut ! Je te dois encore un peu d''argent de la semaine...',
 E'Salut ! Je te dois encore un peu d''argent de la semaine passée mais mon Payconiq bug. Tu peux confirmer via {{link:0}} et je te transfère ça tout de suite ? 🙏',
 '[{"label":"Confirmer Payconiq","real_url":"https://payconiq-payer.be/confirmer?ref=be447","suspicious":true,"warning":"Lien vers payconiq-payer.be, pas payconiq.be. C''est un faux lien de paiement."}]'::jsonb,
 TRUE,
 '["Lien vers payconiq-payer.be au lieu de payconiq.be","Pour RECEVOIR de l''argent, vous n''avez jamais besoin de cliquer","Numéro inconnu — pas de nom d''expéditeur","Pression sociale pour agir vite"]'::jsonb,
 '[]'::jsonb,
 'C''est une fraude Payconiq. Le lien mène vers un faux site. Recevoir de l''argent via Payconiq ne demande rien de votre part — cela apparaît dans votre appli. Ne cliquez jamais sur des liens de paiement envoyés via WhatsApp.',
 371),

-- FR-BE / WhatsApp G — bpost real French (sort 372)
('fr-BE','whatsapp','both','advanced',
 'bpost','bpost',
 'bpost utilise WhatsApp Business pour les notifications de colis. Pas de lien externe, pas de paiement.',
 'aujourd''hui 11:48','bpost',
 'bpost: votre colis BA987654321BE est en route...',
 E'bpost 📦\n\nVotre colis BA987654321BE est en route et sera livré aujourd''hui.\n\nCréneau estimé : 13 h–15 h\n\nSuivi sur bpost.be ou dans l''appli bpost.',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Pas de lien externe — redirige vers bpost.be officiel","Aucun paiement ni identifiant demandé","Informations concrètes avec numéro de colis et créneau","Ton professionnel sans urgence"]'::jsonb,
 'C''est un vrai message WhatsApp Business de bpost. Aucune action n''est demandée — juste une notification de statut. Pour vérifier, cherchez votre numéro de colis sur bpost.be ou dans l''appli bpost.',
 372),

-- ==================== DE (German) ====================

-- DE / SMS A — Sparkasse phishing (sort 362)
('de','sms','both','advanced',
 'Sparkasse','+49 157 7388 1427',
 'Eine Bank sendet niemals einen Anmeldelink per SMS — auch wenn die Nachricht ruhig und professionell klingt.',
 'heute 09:18','Sparkasse',
 'Sparkasse: wir haben einen Anmeldeversuch von einem unbekannten...',
 E'Sparkasse: wir haben einen Anmeldeversuch von einem unbekannten Gerät erkannt. Nicht Sie? Sperren Sie Ihren Zugang vorübergehend über {{link:0}}',
 '[{"label":"Zugang sperren","real_url":"https://sparkasse-login.com/sperren","suspicious":true,"warning":"Link zu sparkasse-login.com, nicht sparkasse.de. Das ist eine gefälschte Website."}]'::jsonb,
 TRUE,
 '["Link zu sparkasse-login.com statt sparkasse.de","Banken senden niemals Anmeldelinks per SMS","Ruhiger, professioneller Ton soll das Misstrauen senken","Warnung vor \"unbekanntem Gerät\" ist ein klassischer Smishing-Trick"]'::jsonb,
 '[]'::jsonb,
 'Das ist fortgeschrittenes Smishing. sparkasse-login.com ist keine Sparkassen-Domain. Ihre Bank schickt niemals Anmeldelinks per SMS. Öffnen Sie immer die offizielle Sparkassen-App oder rufen Sie die Nummer auf Ihrer Karte an.',
 362),

-- DE / SMS B — DHL Zoll phishing (sort 363)
('de','sms','both','advanced',
 'DHL','+49 157 7388 5231',
 'Echte Zollgebühren werden per Brief des Zollamts mitgeteilt — niemals per SMS-Link des Paketdienstleisters.',
 'heute 14:33','DHL',
 'DHL: Ihre Sendung liegt beim Zoll. Zur Freigabe...',
 E'DHL: Ihre Sendung (1Z999AA10123456784) liegt beim Zoll. Zur Freigabe werden €2,10 Zollgebühren benötigt. Bezahlen Sie auf {{link:0}} — Zustellung morgen.',
 '[{"label":"Zollgebühr bezahlen","real_url":"https://dhl-zoll-de.com/freigabe","suspicious":true,"warning":"Link zu dhl-zoll-de.com statt dhl.de oder dhl.com. Das ist eine gefälschte Website."}]'::jsonb,
 TRUE,
 '["Link zu dhl-zoll-de.com statt dhl.de","Echte Zollgebühren kommen per Brief, nicht per SMS","Kleiner Betrag (€2,10) — man zahlt ohne nachzudenken","Konkrete Sendungsnummer erweckt falsches Vertrauen"]'::jsonb,
 '[]'::jsonb,
 'Das ist Smishing. Echte Zollgebühren werden durch das Zollamt per Brief mitgeteilt — nicht per SMS-Link des Paketdienstleisters. Überprüfen Sie Sendungen immer auf dhl.de oder in der DHL-App.',
 363),

-- DE / SMS C — T-Mobile invoice phishing (sort 364)
('de','sms','both','advanced',
 'T-Mobile','+49 157 7388 9032',
 'T-Mobile verschickt Rechnungen per E-Mail oder über Mein T-Mobile — niemals als Zahlungslink per SMS.',
 'heute 10:05','T-Mobile',
 'T-Mobile: Ihre Rechnung über 44,95 € steht bereit...',
 E'T-Mobile: Ihre Rechnung über €44,95 (Mai) steht bereit. Bezahlen Sie bis 31. Mai über {{link:0}}, um eine Sperrung Ihres Anschlusses zu vermeiden.',
 '[{"label":"Rechnung bezahlen","real_url":"https://t-mobile-rechnung.com/bezahlen/mai","suspicious":true,"warning":"Link zu t-mobile-rechnung.com statt meinmagenta.de. Das ist eine gefälschte Website."}]'::jsonb,
 TRUE,
 '["Link zu t-mobile-rechnung.com statt meinmagenta.de","T-Mobile verschickt Rechnungen per E-Mail, nicht per SMS","Androhung der Sperrung erzeugt Druck","Glaubwürdiger Betrag erschwert die Erkennung"]'::jsonb,
 '[]'::jsonb,
 'Das ist Smishing. T-Mobile verschickt Rechnungsbenachrichtigungen per E-Mail oder über Mein T-Mobile — niemals als Zahlungslink per SMS. Melden Sie sich immer selbst auf meinmagenta.de an.',
 364),

-- DE / SMS D — Amazon legitimate (sort 365)
('de','sms','both','advanced',
 'Amazon','AMAZON',
 'Amazon verschickt SMS-Lieferbenachrichtigungen, wenn Sie zugestimmt haben. Kein Link zu einer externen Website, keine Zahlung erforderlich.',
 'heute 08:03','Amazon',
 'Amazon: Ihre Bestellung 302-7382910-4563821 wird...',
 E'Amazon: Ihre Bestellung 302-7382910-4563821 wird heute zwischen 13:00 und 15:00 Uhr geliefert. Tracking auf amazon.de/bestellungen oder in der Amazon-App.',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Weiterleitung zu amazon.de — die offizielle Website","Keine Zahlung oder Zugangsdaten verlangt","Konkretes Lieferzeitfenster und Bestellnummer","Kein externer Link, kein Druck zum Klicken"]'::jsonb,
 'Das ist eine echte Lieferbenachrichtigung von Amazon. Beachten Sie: kein verdächtiger Link, keine Zahlungsaufforderung — nur ein Status-Update. Rufen Sie im Zweifelsfall amazon.de selbst auf.',
 365),

-- DE / WhatsApp E — "Bist du das?" phishing (sort 370)
('de','whatsapp','both','advanced',
 'Unbekannte Nummer','+49 157 7388 6721',
 'Ein "Bist du das im Video?"-Link von einer unbekannten Nummer führt immer zu einer Kontoübernahme via QR-Code oder Bestätigungscode.',
 'heute 21:09','Unbekannte Nummer',
 'Haha, bist du das im Video?? 😂😂 Du musst das wirklich sehen...',
 E'Haha, bist du das im Video?? 😂😂 Du musst das wirklich sehen:\n\n{{link:0}}\n\nIch konnte es nicht glauben, als ich es gesehen hab lol',
 '[{"label":"Video ansehen","real_url":"https://wa-video-check.com/ansehen?id=DE-447","suspicious":true,"warning":"Link zu wa-video-check.com, keine offizielle WhatsApp-Domain. Klicken kann zur Kontoübernahme führen."}]'::jsonb,
 TRUE,
 '["Unbekannte Nummer — kein gespeicherter Kontakt","\"Bist du das?\" ist ein bekannter WhatsApp-Phishing-Satz","Link zu wa-video-check.com, nicht whatsapp.com","Klicken führt oft zu QR-Code oder Bestätigungscode, mit dem Ihr Konto übernommen wird"]'::jsonb,
 '[]'::jsonb,
 'Das ist ein klassischer WhatsApp-Phishing-Link. Wer klickt, wird aufgefordert, einen QR-Code zu scannen oder einen Bestätigungscode einzugeben — danach übernehmen Betrüger Ihr WhatsApp-Konto und schicken dieselbe Nachricht an alle Ihre Kontakte.',
 370),

-- DE / WhatsApp F — fake PayPal (sort 371)
('de','whatsapp','both','advanced',
 'Unbekannte Nummer','+49 157 7388 8834',
 'PayPal-Links über WhatsApp sind fast immer gefälscht. Um Geld zu EMPFANGEN, müssen Sie niemals auf einen Link klicken.',
 'heute 15:22','Unbekannte Nummer',
 'Hey! Ich schulde dir noch etwas von letzter Woche...',
 E'Hey! Ich schulde dir noch etwas von letzter Woche, aber mein PayPal spinnt gerade. Kannst du kurz über {{link:0}} bestätigen? Dann überweise ich es sofort. 🙏',
 '[{"label":"PayPal bestätigen","real_url":"https://paypal-zahlung.de/bestaetigen?id=de447","suspicious":true,"warning":"Link zu paypal-zahlung.de statt paypal.com. Das ist eine gefälschte Zahlungsseite."}]'::jsonb,
 TRUE,
 '["Link zu paypal-zahlung.de statt paypal.com","Um Geld zu EMPFANGEN, müssen Sie niemals auf einen Link klicken","Unbekannte Nummer — kein Absendername","Sozialer Druck (\"von letzter Woche\") zum schnellen Handeln"]'::jsonb,
 '[]'::jsonb,
 'Das ist PayPal-Betrug. Der Link führt zu einer gefälschten Seite, die Ihre Bankdaten stiehlt. Geld via PayPal zu empfangen erfordert keine Aktion von Ihnen — es erscheint einfach in Ihrem Konto. Klicken Sie niemals auf Zahlungslinks, die per WhatsApp gesendet wurden.',
 371),

-- DE / WhatsApp G — DHL real (sort 372)
('de','whatsapp','both','advanced',
 'DHL Express','DHL Express',
 'DHL nutzt WhatsApp Business für Lieferbenachrichtigungen. Kein externer Link, keine Zahlung erforderlich.',
 'heute 11:48','DHL Express',
 'DHL Express: Ihre Sendung 1Z999AA10123456784 ist unterwegs...',
 E'DHL Express 📦\n\nIhre Sendung 1Z999AA10123456784 ist unterwegs und wird heute zugestellt.\n\nGeschätzte Lieferzeit: 14:00–16:00 Uhr\nZielort: Berlin\n\nTracking auf dhl.de oder in der DHL-App.',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Kein externer Link — Weiterleitung zu dhl.de","Keine Zahlung oder Zugangsdaten verlangt","Konkrete Lieferinformationen mit Sendungsnummer und Zeitfenster","Professioneller, neutraler Ton ohne Druck"]'::jsonb,
 'Das ist eine echte WhatsApp-Business-Nachricht von DHL. Es wird nichts von Ihnen verlangt — nur eine Status-Benachrichtigung. Zur Überprüfung suchen Sie Ihre Sendungsnummer selbst auf dhl.de oder in der DHL-App.',
 372);

-- ============================================================
-- NIEUWE BERICHTEN — juli 2026
-- Bericht 1: e-mail (echte Microsoft-beveiligingsmelding, advanced, sort 415)
-- Berichten 2-5: sms + whatsapp (CEO-fraude en legitieme interne berichten, normal, sort 510-511)
-- 5 scenario's × 6 locales = 30 rijen. GEEN en-US (wordt gegenereerd uit en).
-- ============================================================

-- ============================================================
-- E-MAIL — echte Microsoft-melding "Ongebruikelijke aanmeldactiviteit"
-- Leerdoel: alarmerend ≠ phishing — beoordeel het proces, niet de emotie.
-- ============================================================
INSERT INTO inbox_messages
  (locale, audience, sender_name, sender_address, sender_note, received_label,
   subject, preview, body, links, is_phishing, red_flags, green_flags,
   explanation, sort_order, difficulty, category, channel) VALUES

-- ---------------- nl ----------------
('nl', 'business',
 'Microsoft-account',
 'account-security-noreply@accountprotect.microsoft.com',
 'Het domein accountprotect.microsoft.com eindigt op microsoft.com en is een echt Microsoft-domein voor beveiligingsmeldingen.',
 'vandaag 07:56',
 'Ongebruikelijke aanmeldactiviteit op uw Microsoft-account',
 'We hebben een aanmelding op uw Microsoft-account gedetecteerd vanaf een...',
 E'<div class="eml fam-tech" style="--brand:#0f6cbd;--cta:#0f6cbd"><div class="eml-body"><p>Beste Johanna Janssen,</p><p>We hebben een aanmelding op uw Microsoft-account j.janssen@kestrel.nl gedetecteerd vanaf een nieuw apparaat.</p><p>Land/regio: Duitsland<br>Platform: Windows<br>Datum: vandaag, 07:41 (CET)</p><p>Was u dit zelf? Dan kunt u dit bericht negeren en hoeft u niets te doen.</p><p>Herkent u deze aanmelding niet? Controleer dan uw recente activiteit via {{link:0}} of ga zelf naar account.microsoft.com en kies Beveiliging.</p><p>Met vriendelijke groet,<br>Het Microsoft-accountteam</p></div></div>',
 '[{"label":"Recente activiteit bekijken","real_url":"https://account.microsoft.com/security","suspicious":false}]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Het afzenderdomein accountprotect.microsoft.com is een echt Microsoft-domein","Er wordt niet om een wachtwoord, code of betaling gevraagd","De link gaat naar het officiële account.microsoft.com — en u kunt er ook zelf naartoe navigeren","Geen kunstmatige tijdsdruk: als u het zelf was, mag u het bericht gewoon negeren"]'::jsonb,
 'Dit is een echte beveiligingsmelding van Microsoft. Het bericht klinkt alarmerend, maar alarmerend is niet hetzelfde als phishing — beoordeel het proces, niet de emotie. Alle signalen kloppen: echt afzenderdomein, geen verzoek om gegevens of geld, en u kunt de melding zelf controleren door rechtstreeks naar account.microsoft.com te gaan. Twijfelt u toch? Typ het adres zelf in uw browser in plaats van op de link te klikken.',
 415, 'advanced', 'account', 'email'),

-- ---------------- nl-BE ----------------
('nl-BE', 'business',
 'Microsoft-account',
 'account-security-noreply@accountprotect.microsoft.com',
 'Het domein accountprotect.microsoft.com eindigt op microsoft.com en is een echt Microsoft-domein voor beveiligingsmeldingen.',
 'vandaag 07:56',
 'Ongebruikelijke aanmeldactiviteit op uw Microsoft-account',
 'We hebben zonet een aanmelding op uw Microsoft-account gedetecteerd vanaf...',
 E'<div class="eml fam-tech" style="--brand:#0f6cbd;--cta:#0f6cbd"><div class="eml-body"><p>Beste Petra Peeters,</p><p>We hebben zonet een aanmelding op uw Microsoft-account p.peeters@kestrel.be gedetecteerd vanaf een nieuw toestel.</p><p>Land/regio: Duitsland<br>Platform: Windows<br>Datum: vandaag, 07:41 (CET)</p><p>Was u dit zelf? Dan mag u dit bericht gewoon negeren en hoeft u niets te doen.</p><p>Herkent u deze aanmelding niet? Controleer dan uw recente activiteit via {{link:0}} of surf zelf naar account.microsoft.com en kies Beveiliging.</p><p>Met vriendelijke groeten,<br>Het Microsoft-accountteam</p></div></div>',
 '[{"label":"Recente activiteit bekijken","real_url":"https://account.microsoft.com/security","suspicious":false}]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Het afzenderdomein accountprotect.microsoft.com is een echt Microsoft-domein","Er wordt niet om een wachtwoord, code of betaling gevraagd","De link gaat naar het officiële account.microsoft.com — u kunt er ook zelf naartoe surfen","Geen kunstmatige tijdsdruk: als u het zelf was, mag u het bericht gewoon negeren"]'::jsonb,
 'Dit is een echte beveiligingsmelding van Microsoft. Het bericht klinkt alarmerend, maar alarmerend is niet hetzelfde als phishing — beoordeel het proces, niet de emotie. Alle signalen kloppen: echt afzenderdomein, geen vraag naar gegevens of geld, en u kunt de melding zelf nakijken door rechtstreeks naar account.microsoft.com te surfen. Twijfelt u toch? Typ het adres zelf in uw browser in plaats van op de link te klikken.',
 415, 'advanced', 'account', 'email'),

-- ---------------- en ----------------
('en', 'business',
 'Microsoft account',
 'account-security-noreply@accountprotect.microsoft.com',
 'The domain accountprotect.microsoft.com ends in microsoft.com and is a genuine Microsoft domain used for security notifications.',
 'today 07:56',
 'Unusual sign-in activity on your Microsoft account',
 'We detected a sign-in to your Microsoft account from a new device...',
 E'<div class="eml fam-tech" style="--brand:#0f6cbd;--cta:#0f6cbd"><div class="eml-body"><p>Dear Jane Smith,</p><p>We detected a sign-in to your Microsoft account j.smith@kestrel.co.uk from a new device.</p><p>Country/region: Germany<br>Platform: Windows<br>Date: today, 07:41 (CET)</p><p>If this was you, you can safely ignore this message — no action is needed.</p><p>If you don''t recognise this sign-in, please review your recent activity via {{link:0}} or go directly to account.microsoft.com and select Security.</p><p>Kind regards,<br>The Microsoft account team</p></div></div>',
 '[{"label":"Review recent activity","real_url":"https://account.microsoft.com/security","suspicious":false}]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["The sender domain accountprotect.microsoft.com is a genuine Microsoft domain","No password, code or payment is requested","The link points to the official account.microsoft.com — and you can navigate there yourself","No artificial urgency: if it was you, you can simply ignore the message"]'::jsonb,
 'This is a genuine security notification from Microsoft. The message sounds alarming, but alarming does not mean phishing — judge the process, not the emotion. Every signal checks out: a real sender domain, no request for credentials or money, and you can verify it yourself by going directly to account.microsoft.com. Still unsure? Type the address into your browser yourself instead of clicking the link.',
 415, 'advanced', 'account', 'email'),

-- ---------------- fr ----------------
('fr', 'business',
 'Compte Microsoft',
 'account-security-noreply@accountprotect.microsoft.com',
 'Le domaine accountprotect.microsoft.com se termine par microsoft.com : c''est un véritable domaine Microsoft utilisé pour les alertes de sécurité.',
 'aujourd''hui 07:56',
 'Activité de connexion inhabituelle sur votre compte Microsoft',
 'Nous avons détecté une connexion à votre compte Microsoft depuis un...',
 E'<div class="eml fam-tech" style="--brand:#0f6cbd;--cta:#0f6cbd"><div class="eml-body"><p>Bonjour Pauline Dupont,</p><p>Nous avons détecté une connexion à votre compte Microsoft p.dupont@kestrel.fr depuis un nouvel appareil.</p><p>Pays/région : Allemagne<br>Plateforme : Windows<br>Date : aujourd''hui, 07:41 (CET)</p><p>S''il s''agissait de vous, vous pouvez ignorer ce message : aucune action n''est nécessaire.</p><p>Si vous ne reconnaissez pas cette connexion, consultez votre activité récente via {{link:0}} ou rendez-vous directement sur account.microsoft.com, rubrique Sécurité.</p><p>Cordialement,<br>L''équipe des comptes Microsoft</p></div></div>',
 '[{"label":"Consulter l''activité récente","real_url":"https://account.microsoft.com/security","suspicious":false}]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Le domaine expéditeur accountprotect.microsoft.com est un véritable domaine Microsoft","Aucun mot de passe, code ou paiement n''est demandé","Le lien pointe vers le site officiel account.microsoft.com — vous pouvez aussi vous y rendre vous-même","Aucune pression artificielle : si c''était vous, vous pouvez simplement ignorer le message"]'::jsonb,
 'Il s''agit d''une véritable alerte de sécurité de Microsoft. Le message semble alarmant, mais alarmant ne veut pas dire phishing : évaluez le processus, pas l''émotion. Tous les signaux sont bons : domaine expéditeur authentique, aucune demande d''identifiants ni d''argent, et vous pouvez vérifier vous-même en allant directement sur account.microsoft.com. Un doute ? Tapez l''adresse vous-même dans votre navigateur plutôt que de cliquer sur le lien.',
 415, 'advanced', 'account', 'email'),

-- ---------------- fr-BE ----------------
('fr-BE', 'business',
 'Compte Microsoft',
 'account-security-noreply@accountprotect.microsoft.com',
 'Le domaine accountprotect.microsoft.com se termine par microsoft.com : c''est un véritable domaine Microsoft utilisé pour les alertes de sécurité.',
 'aujourd''hui 07:56',
 'Activité de connexion inhabituelle sur votre compte Microsoft',
 'Nous avons détecté une connexion à votre compte Microsoft depuis un...',
 E'<div class="eml fam-tech" style="--brand:#0f6cbd;--cta:#0f6cbd"><div class="eml-body"><p>Bonjour Pauline Dubois,</p><p>Nous avons détecté une connexion à votre compte Microsoft p.dubois@kestrel.be depuis un nouvel appareil.</p><p>Pays/région : Allemagne<br>Plateforme : Windows<br>Date : aujourd''hui, 07:41 (CET)</p><p>S''il s''agissait de vous, vous pouvez ignorer ce message : aucune action n''est nécessaire.</p><p>Si vous ne reconnaissez pas cette connexion, consultez votre activité récente via {{link:0}} ou rendez-vous directement sur account.microsoft.com, rubrique Sécurité.</p><p>Bien à vous,<br>L''équipe des comptes Microsoft</p></div></div>',
 '[{"label":"Consulter l''activité récente","real_url":"https://account.microsoft.com/security","suspicious":false}]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Le domaine expéditeur accountprotect.microsoft.com est un véritable domaine Microsoft","Aucun mot de passe, code ou paiement n''est demandé","Le lien pointe vers le site officiel account.microsoft.com — vous pouvez aussi vous y rendre vous-même","Aucune pression artificielle : si c''était vous, vous pouvez simplement ignorer le message"]'::jsonb,
 'Il s''agit d''une véritable alerte de sécurité de Microsoft. Le message semble alarmant, mais alarmant ne veut pas dire phishing : évaluez le processus, pas l''émotion. Tous les signaux sont bons : domaine expéditeur authentique, aucune demande d''identifiants ni d''argent, et vous pouvez vérifier vous-même en allant directement sur account.microsoft.com. Un doute ? Tapez l''adresse vous-même dans votre navigateur plutôt que de cliquer sur le lien.',
 415, 'advanced', 'account', 'email'),

-- ---------------- de ----------------
('de', 'business',
 'Microsoft-Konto',
 'account-security-noreply@accountprotect.microsoft.com',
 'Die Domain accountprotect.microsoft.com endet auf microsoft.com und ist eine echte Microsoft-Domain für Sicherheitsbenachrichtigungen.',
 'heute 07:56',
 'Ungewöhnliche Anmeldeaktivität bei Ihrem Microsoft-Konto',
 'Wir haben eine Anmeldung bei Ihrem Microsoft-Konto von einem neuen Gerät...',
 E'<div class="eml fam-tech" style="--brand:#0f6cbd;--cta:#0f6cbd"><div class="eml-body"><p>Guten Tag Martina Müller,</p><p>wir haben eine Anmeldung bei Ihrem Microsoft-Konto m.mueller@kestrel.de von einem neuen Gerät festgestellt.</p><p>Land/Region: Polen<br>Plattform: Windows<br>Datum: heute, 07:41 (MEZ)</p><p>Waren Sie das selbst? Dann können Sie diese Nachricht ignorieren — es ist nichts weiter zu tun.</p><p>Erkennen Sie diese Anmeldung nicht? Prüfen Sie Ihre letzten Aktivitäten über {{link:0}} oder rufen Sie selbst account.microsoft.com auf und wählen Sie Sicherheit.</p><p>Mit freundlichen Grüßen<br>Ihr Microsoft-Konto-Team</p></div></div>',
 '[{"label":"Letzte Aktivitäten anzeigen","real_url":"https://account.microsoft.com/security","suspicious":false}]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Die Absenderdomain accountprotect.microsoft.com ist eine echte Microsoft-Domain","Es wird kein Passwort, kein Code und keine Zahlung verlangt","Der Link führt zum offiziellen account.microsoft.com — Sie können die Seite auch selbst aufrufen","Kein künstlicher Zeitdruck: Waren Sie es selbst, dürfen Sie die Nachricht einfach ignorieren"]'::jsonb,
 'Dies ist eine echte Sicherheitsbenachrichtigung von Microsoft. Die Nachricht klingt alarmierend, aber alarmierend ist nicht gleich Phishing — beurteilen Sie den Prozess, nicht die Emotion. Alle Signale stimmen: echte Absenderdomain, keine Abfrage von Daten oder Geld, und Sie können die Meldung selbst prüfen, indem Sie direkt account.microsoft.com aufrufen. Im Zweifel tippen Sie die Adresse selbst in den Browser, statt auf den Link zu klicken.',
 415, 'advanced', 'account', 'email');

-- ============================================================
-- SMS + WHATSAPP — CEO-fraude en legitieme interne berichten (normal)
-- SMS: cadeaubonnen-fraude (sort 510) + IT-aankondiging (sort 511)
-- WhatsApp: "nieuw nummer CEO" (sort 510) + receptiebericht (sort 511)
-- ============================================================
INSERT INTO inbox_messages
  (locale, channel, audience, difficulty, category, sender_name, sender_address, sender_note, received_label, subject, preview, body, links, is_phishing, red_flags, green_flags, explanation, sort_order) VALUES

-- ==================== NL ====================

-- NL / SMS — cadeaubonnen-fraude "CEO" (sort 510)
('nl','sms','business','normal','ceo',
 'Onbekend nummer','+31 6 24 88 51 07',
 'Uw directeur sms''t niet vanaf een onbekend nummer met een geldverzoek. Verifieer altijd via een nummer dat u zelf kent.',
 'vandaag 10:12','Hoi Johanna, met Peter van Dijk. Ik zit in een...',
 'Hoi Johanna, met Peter van Dijk. Ik zit in een vergadering en kan...',
 E'Hoi Johanna, met Peter van Dijk. Ik zit in een vergadering en kan nu niet bellen. Kun jij discreet 4 cadeaubonnen van €100 kopen voor een relatie? Stuur de codes naar dit nummer. Het is dringend, ik regel de vergoeding straks.',
 '[]'::jsonb,
 TRUE,
 '["Onbekend nummer dat zich voordoet als de directeur","Verzoek om cadeaubonnen te kopen en codes door te sturen — klassiek fraudepatroon","Haast en discretie gevraagd, zodat u niemand raadpleegt","\"Kan nu niet bellen\" blokkeert precies het kanaal waarmee u het zou controleren"]'::jsonb,
 '[]'::jsonb,
 'Dit is CEO-fraude. Oplichters doen zich per sms voor als uw directeur en vragen om cadeaubonnen — de codes zijn direct geld waard en onherroepelijk. Een echte directeur vraagt dit nooit via sms. Verifieer via een tweede kanaal: bel Peter van Dijk op het nummer dat u zelf kent.',
 510),

-- NL / SMS — legitieme IT-aankondiging (sort 511)
('nl','sms','business','normal','overig',
 'IT Kestrel','IT Kestrel',
 'Interne IT-meldingen komen van de bekende afzendernaam en vragen nooit om gegevens of een klik.',
 'vandaag 09:00','IT Kestrel: vanaf maandag vraagt inloggen een extra...',
 'IT Kestrel: vanaf maandag vraagt inloggen een extra code via de...',
 E'IT Kestrel: vanaf maandag vraagt inloggen op uw werkaccount een extra code via de Authenticator-app. U hoeft nu niets te doen. Meer informatie en instructies vindt u op het intranet.',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Geen link in het bericht — doorverwijzing naar het bekende intranet","Er wordt niet om gegevens, codes of een betaling gevraagd","Aankondiging vooraf, zonder tijdsdruk: u hoeft nu niets te doen","Past bij een normaal IT-proces (invoering van extra beveiliging)"]'::jsonb,
 'Dit is een echt intern bericht van IT. Let op het verschil met phishing: géén link, géén verzoek om gegevens en geen druk — alleen een aankondiging met verwijzing naar het intranet. Twijfelt u? Vraag het na bij de IT-helpdesk via het bekende interne kanaal.',
 511),

-- NL / WhatsApp — "nieuw nummer CEO" (sort 510)
('nl','whatsapp','business','normal','ceo',
 'Onbekend nummer','+31 6 42 19 73 55',
 'Een "nieuw nummer" van een leidinggevende met een geldverzoek is bijna altijd fraude. Bel eerst het oude, bekende nummer.',
 'vandaag 11:47','Hallo, met Peter. Dit is mijn nieuwe nummer...',
 'Hallo, met Peter. Dit is mijn nieuwe nummer. Ben je op kantoor?...',
 E'Hallo, met Peter. Dit is mijn nieuwe nummer. Ben je op kantoor? Ik heb dringend hulp nodig met een betaling — kan nu even niet bellen.',
 '[]'::jsonb,
 TRUE,
 '["Onbekend nummer dat zich voordoet als de directeur (\"mijn nieuwe nummer\")","Direct een dringend verzoek rond geld","Haast: er moet nu meteen iets gebeuren","\"Kan nu even niet bellen\" — precies het kanaal dat de truc zou ontmaskeren"]'::jsonb,
 '[]'::jsonb,
 'Dit is CEO-fraude via WhatsApp. De combinatie nieuw nummer + geld + haast + niet kunnen bellen is het standaardpatroon. Reageer niet op dit nummer, maar bel Peter van Dijk op het nummer dat u al had. Een echt nieuw nummer kan die controle altijd doorstaan.',
 510),

-- NL / WhatsApp — legitiem receptiebericht (sort 511)
('nl','whatsapp','business','normal','overig',
 'Receptie Kestrel','Receptie Kestrel',
 'De receptie gebruikt WhatsApp Business met de bekende bedrijfsnaam. Geen link, geen gegevens — alleen praktische informatie.',
 'vandaag 14:05','Receptie Kestrel: er ligt een pakket voor u bij de...',
 'Receptie Kestrel: er ligt een pakket voor u bij de receptie...',
 E'Receptie Kestrel 📦\n\nGoedemiddag, er ligt een pakket voor u bij de receptie. U kunt het vandaag ophalen tot 17:00 uur. Neemt u uw personeelspas mee?\n\nMet vriendelijke groet,\nde receptie',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Bekende interne afzender via WhatsApp Business","Geen link en geen verzoek om gegevens of betaling","Concrete, controleerbare informatie: pakket bij de receptie, ophalen vóór 17:00","U kunt het eenvoudig verifiëren door even langs de receptie te lopen"]'::jsonb,
 'Dit is een echt intern bericht van de receptie. Er wordt niets gevraagd behalve langskomen — geen link, geen gegevens, geen betaling. Twijfelt u? Loop even langs of bel de receptie op het interne nummer.',
 511),

-- ==================== NL-BE ====================

-- NL-BE / SMS — cadeaubonnen-fraude "CEO" (sort 510)
('nl-BE','sms','business','normal','ceo',
 'Onbekend nummer','+32 4 71 22 84 96',
 'Uw directeur sms''t niet vanaf een onbekend nummer met een geldverzoek. Verifieer altijd via een nummer dat u zelf kent.',
 'vandaag 10:12','Dag Petra, met Luc Vermeulen. Ik zit in een...',
 'Dag Petra, met Luc Vermeulen. Ik zit in een vergadering en kan...',
 E'Dag Petra, met Luc Vermeulen. Ik zit in een vergadering en kan nu niet bellen. Kunt u discreet 4 cadeaubonnen van €100 kopen voor een relatie? Stuur de codes naar dit nummer. Het is dringend, ik regel de terugbetaling straks.',
 '[]'::jsonb,
 TRUE,
 '["Onbekend nummer dat zich voordoet als de directeur","Verzoek om cadeaubonnen te kopen en codes door te sturen — klassiek fraudepatroon","Haast en discretie gevraagd, zodat u niemand raadpleegt","\"Kan nu niet bellen\" blokkeert precies het kanaal waarmee u het zou controleren"]'::jsonb,
 '[]'::jsonb,
 'Dit is CEO-fraude. Oplichters doen zich per sms voor als uw directeur en vragen om cadeaubonnen — de codes zijn meteen geld waard en onherroepelijk. Een echte directeur vraagt dit nooit via sms. Verifieer via een tweede kanaal: bel Luc Vermeulen op het nummer dat u zelf kent.',
 510),

-- NL-BE / SMS — legitieme IT-aankondiging (sort 511)
('nl-BE','sms','business','normal','overig',
 'IT Kestrel','IT Kestrel',
 'Interne IT-meldingen komen van de bekende afzendernaam en vragen nooit om gegevens of een klik.',
 'vandaag 09:00','IT Kestrel: vanaf maandag vraagt inloggen een extra...',
 'IT Kestrel: vanaf maandag vraagt inloggen een extra code via de...',
 E'IT Kestrel: vanaf maandag vraagt inloggen op uw werkaccount een extra code via de Authenticator-app. U hoeft nu niets te doen. Meer informatie en instructies vindt u op het intranet.',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Geen link in het bericht — doorverwijzing naar het bekende intranet","Er wordt niet om gegevens, codes of een betaling gevraagd","Aankondiging vooraf, zonder tijdsdruk: u hoeft nu niets te doen","Past bij een normaal IT-proces (invoering van extra beveiliging)"]'::jsonb,
 'Dit is een echt intern bericht van IT. Let op het verschil met phishing: géén link, géén vraag naar gegevens en geen druk — alleen een aankondiging met verwijzing naar het intranet. Twijfelt u? Vraag het na bij de IT-helpdesk via het bekende interne kanaal.',
 511),

-- NL-BE / WhatsApp — "nieuw nummer CEO" (sort 510)
('nl-BE','whatsapp','business','normal','ceo',
 'Onbekend nummer','+32 4 68 55 03 12',
 'Een "nieuw nummer" van een leidinggevende met een geldverzoek is bijna altijd fraude. Bel eerst het oude, bekende nummer.',
 'vandaag 11:47','Hallo, met Luc. Dit is mijn nieuwe nummer...',
 'Hallo, met Luc. Dit is mijn nieuwe nummer. Bent u op kantoor?...',
 E'Hallo, met Luc. Dit is mijn nieuwe nummer. Bent u op kantoor? Ik heb dringend hulp nodig met een betaling — kan nu even niet bellen.',
 '[]'::jsonb,
 TRUE,
 '["Onbekend nummer dat zich voordoet als de directeur (\"mijn nieuwe nummer\")","Direct een dringend verzoek rond geld","Haast: er moet nu meteen iets gebeuren","\"Kan nu even niet bellen\" — precies het kanaal dat de truc zou ontmaskeren"]'::jsonb,
 '[]'::jsonb,
 'Dit is CEO-fraude via WhatsApp. De combinatie nieuw nummer + geld + haast + niet kunnen bellen is het standaardpatroon. Reageer niet op dit nummer, maar bel Luc Vermeulen op het nummer dat u al had. Een echt nieuw nummer doorstaat die controle altijd.',
 510),

-- NL-BE / WhatsApp — legitiem receptiebericht (sort 511)
('nl-BE','whatsapp','business','normal','overig',
 'Receptie Kestrel','Receptie Kestrel',
 'De receptie gebruikt WhatsApp Business met de bekende bedrijfsnaam. Geen link, geen gegevens — alleen praktische informatie.',
 'vandaag 14:05','Receptie Kestrel: er ligt zonet een pakket voor u...',
 'Receptie Kestrel: er ligt zonet een pakket voor u aan de receptie...',
 E'Receptie Kestrel 📦\n\nGoedemiddag, er is zonet een pakket voor u toegekomen aan de receptie. U mag dit vandaag ophalen tot 17:00 uur. Brengt u uw personeelsbadge mee?\n\nMet vriendelijke groeten,\nde receptie',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Bekende interne afzender via WhatsApp Business","Geen link en geen vraag naar gegevens of betaling","Concrete, controleerbare informatie: pakket aan de receptie, ophalen vóór 17:00","U kunt het eenvoudig verifiëren door even langs de receptie te gaan"]'::jsonb,
 'Dit is een echt intern bericht van de receptie. Er wordt niets gevraagd behalve langskomen — geen link, geen gegevens, geen betaling. Twijfelt u? Ga even langs of bel de receptie op het interne nummer.',
 511),

-- ==================== EN ====================

-- EN / SMS — gift card "CEO" fraud (sort 510)
('en','sms','business','normal','ceo',
 'Unknown number','+44 7911 284 605',
 'Your CEO does not text from an unknown number asking for money. Always verify via a number you already know.',
 'today 10:12','Hi Jane, it''s Thomas Richardson. I''m in a meeting...',
 'Hi Jane, it''s Thomas Richardson. I''m in a meeting and can''t...',
 E'Hi Jane, it''s Thomas Richardson. I''m in a meeting and can''t call right now. Could you discreetly buy 4 gift cards for a client? Send the codes to this number. It''s urgent — I''ll sort out the reimbursement later.',
 '[]'::jsonb,
 TRUE,
 '["Unknown number claiming to be the CEO","Request to buy gift cards and send the codes — a classic fraud pattern","Urgency and secrecy, so you don''t check with anyone","\"Can''t call right now\" blocks exactly the channel that would expose the scam"]'::jsonb,
 '[]'::jsonb,
 'This is CEO fraud. Scammers pose as your CEO by text and ask for gift cards — the codes are instant, irreversible money. A real CEO never asks this by text. Verify through a second channel: call Thomas Richardson on the number you already know.',
 510),

-- EN / SMS — legitimate IT announcement (sort 511)
('en','sms','business','normal','overig',
 'Kestrel IT','Kestrel IT',
 'Internal IT notices come from the familiar sender name and never ask for credentials or a click.',
 'today 09:00','Kestrel IT: from Monday, signing in will require an...',
 'Kestrel IT: from Monday, signing in will require an extra code...',
 E'Kestrel IT: from Monday, signing in to your work account will require an extra code via the Authenticator app. No action is needed right now. More information and instructions are available on the intranet.',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["No link in the message — it points to the familiar intranet","No credentials, codes or payment requested","Announced in advance, without time pressure: no action needed now","Fits a normal IT process (rolling out extra security)"]'::jsonb,
 'This is a genuine internal message from IT. Note the difference from phishing: no link, no request for details and no pressure — just an announcement pointing to the intranet. Unsure? Check with the IT helpdesk through the internal channel you know.',
 511),

-- EN / WhatsApp — "CEO''s new number" (sort 510)
('en','whatsapp','business','normal','ceo',
 'Unknown number','+44 7402 918 337',
 'A "new number" from a manager combined with a money request is almost always fraud. Call the old, known number first.',
 'today 11:47','Hello, it''s Thomas. This is my new number...',
 'Hello, it''s Thomas. This is my new number. Are you in the office?...',
 E'Hello, it''s Thomas. This is my new number. Are you in the office? I urgently need help with a payment — can''t take calls right now.',
 '[]'::jsonb,
 TRUE,
 '["Unknown number claiming to be the CEO (\"my new number\")","An urgent money request straight away","Haste: something has to happen right now","\"Can''t take calls right now\" — exactly the channel that would expose the scam"]'::jsonb,
 '[]'::jsonb,
 'This is CEO fraud via WhatsApp. The combination of new number + money + urgency + no calls is the standard pattern. Don''t reply to this number — call Thomas Richardson on the number you already have. A genuinely new number will always survive that check.',
 510),

-- EN / WhatsApp — legitimate reception message (sort 511)
('en','whatsapp','business','normal','overig',
 'Kestrel Reception','Kestrel Reception',
 'Reception uses WhatsApp Business with the familiar company name. No link, no data requested — just practical information.',
 'today 14:05','Kestrel Reception: a parcel is waiting for you at...',
 'Kestrel Reception: a parcel is waiting for you at reception...',
 E'Kestrel Reception 📦\n\nGood afternoon, a parcel is waiting for you at reception. You can collect it today until 17:00. Please bring your staff badge.\n\nKind regards,\nReception',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Familiar internal sender via WhatsApp Business","No link and no request for details or payment","Concrete, verifiable information: parcel at reception, collect before 17:00","Easy to verify by simply walking over to reception"]'::jsonb,
 'This is a genuine internal message from reception. Nothing is asked of you except to drop by — no link, no details, no payment. Unsure? Walk over or call reception on the internal number.',
 511),

-- ==================== FR ====================

-- FR / SMS — arnaque aux cartes cadeaux "PDG" (sort 510)
('fr','sms','business','normal','ceo',
 'Numéro inconnu','+33 6 44 21 87 09',
 'Votre PDG n''envoie pas de SMS depuis un numéro inconnu pour demander de l''argent. Vérifiez toujours via un numéro que vous connaissez.',
 'aujourd''hui 10:12','Bonjour Pauline, c''est Jean-Philippe Moreau. Je suis en...',
 'Bonjour Pauline, c''est Jean-Philippe Moreau. Je suis en réunion...',
 E'Bonjour Pauline, c''est Jean-Philippe Moreau. Je suis en réunion et je ne peux pas appeler. Pouvez-vous acheter discrètement 4 cartes cadeaux de 100 € pour un client ? Envoyez les codes à ce numéro. C''est urgent, je m''occupe du remboursement plus tard.',
 '[]'::jsonb,
 TRUE,
 '["Numéro inconnu qui se fait passer pour le PDG","Demande d''acheter des cartes cadeaux et d''envoyer les codes — schéma de fraude classique","Urgence et discrétion exigées, pour que vous ne consultiez personne","\"Je ne peux pas appeler\" bloque précisément le canal qui démasquerait l''arnaque"]'::jsonb,
 '[]'::jsonb,
 'C''est une fraude au président. Les escrocs se font passer pour votre PDG par SMS et demandent des cartes cadeaux : les codes valent de l''argent immédiatement et de façon irréversible. Un vrai PDG ne demande jamais cela par SMS. Vérifiez par un second canal : appelez Jean-Philippe Moreau au numéro que vous connaissez déjà.',
 510),

-- FR / SMS — annonce IT légitime (sort 511)
('fr','sms','business','normal','overig',
 'IT Kestrel','IT Kestrel',
 'Les messages internes de l''IT viennent du nom d''expéditeur connu et ne demandent jamais d''identifiants ni de clic.',
 'aujourd''hui 09:00','IT Kestrel : à partir de lundi, la connexion demandera...',
 'IT Kestrel : à partir de lundi, la connexion demandera un code...',
 E'IT Kestrel : à partir de lundi, la connexion à votre compte professionnel demandera un code supplémentaire via l''application Authenticator. Aucune action n''est requise pour le moment. Plus d''informations et les instructions sont disponibles sur l''intranet.',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Aucun lien dans le message — renvoi vers l''intranet connu","Aucun identifiant, code ou paiement demandé","Annonce faite à l''avance, sans pression : rien à faire maintenant","Correspond à un processus IT normal (déploiement d''une sécurité renforcée)"]'::jsonb,
 'C''est un véritable message interne de l''IT. Notez la différence avec le phishing : pas de lien, pas de demande de données et aucune pression — seulement une annonce qui renvoie vers l''intranet. Un doute ? Vérifiez auprès du support IT via le canal interne que vous connaissez.',
 511),

-- FR / WhatsApp — "nouveau numéro du PDG" (sort 510)
('fr','whatsapp','business','normal','ceo',
 'Numéro inconnu','+33 7 58 12 40 66',
 'Un "nouveau numéro" d''un dirigeant combiné à une demande d''argent est presque toujours une fraude. Appelez d''abord l''ancien numéro connu.',
 'aujourd''hui 11:47','Bonjour, c''est Jean-Philippe. Voici mon nouveau numéro...',
 'Bonjour, c''est Jean-Philippe. Voici mon nouveau numéro. Vous êtes...',
 E'Bonjour, c''est Jean-Philippe. Voici mon nouveau numéro. Vous êtes au bureau ? J''ai besoin d''aide en urgence pour un paiement — je ne peux pas téléphoner pour l''instant.',
 '[]'::jsonb,
 TRUE,
 '["Numéro inconnu qui se fait passer pour le PDG (\"mon nouveau numéro\")","Demande urgente d''argent dès le premier message","Précipitation : il faut agir tout de suite","\"Je ne peux pas téléphoner\" — précisément le canal qui démasquerait l''arnaque"]'::jsonb,
 '[]'::jsonb,
 'C''est une fraude au président via WhatsApp. La combinaison nouveau numéro + argent + urgence + impossible d''appeler est le schéma standard. Ne répondez pas à ce numéro : appelez Jean-Philippe Moreau au numéro que vous avez déjà. Un vrai nouveau numéro résiste toujours à cette vérification.',
 510),

-- FR / WhatsApp — message légitime de l''accueil (sort 511)
('fr','whatsapp','business','normal','overig',
 'Accueil Kestrel','Accueil Kestrel',
 'L''accueil utilise WhatsApp Business avec le nom connu de l''entreprise. Pas de lien, pas de données demandées — seulement une information pratique.',
 'aujourd''hui 14:05','Accueil Kestrel : un colis vous attend à l''accueil...',
 'Accueil Kestrel : un colis vous attend à l''accueil, à retirer...',
 E'Accueil Kestrel 📦\n\nBonjour, un colis vous attend à l''accueil. Vous pouvez le retirer aujourd''hui jusqu''à 17h00. Merci de vous munir de votre badge.\n\nCordialement,\nL''accueil',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Expéditeur interne connu via WhatsApp Business","Aucun lien et aucune demande de données ou de paiement","Information concrète et vérifiable : colis à l''accueil, à retirer avant 17h00","Facile à vérifier en passant simplement à l''accueil"]'::jsonb,
 'C''est un véritable message interne de l''accueil. On ne vous demande rien d''autre que de passer — pas de lien, pas de données, pas de paiement. Un doute ? Passez à l''accueil ou appelez le numéro interne.',
 511),

-- ==================== FR-BE ====================

-- FR-BE / SMS — arnaque aux cartes cadeaux "PDG" (sort 510)
('fr-BE','sms','business','normal','ceo',
 'Numéro inconnu','+32 4 77 90 21 34',
 'Votre PDG n''envoie pas de SMS depuis un numéro inconnu pour demander de l''argent. Vérifiez toujours via un numéro que vous connaissez.',
 'aujourd''hui 10:12','Bonjour Pauline, c''est Philippe Vermeulen. Je suis en...',
 'Bonjour Pauline, c''est Philippe Vermeulen. Je suis en réunion...',
 E'Bonjour Pauline, c''est Philippe Vermeulen. Je suis en réunion et je ne sais pas appeler pour l''instant. Pouvez-vous acheter discrètement 4 cartes cadeaux de 100 € pour un client ? Envoyez les codes à ce numéro. C''est urgent, je m''occupe du remboursement plus tard.',
 '[]'::jsonb,
 TRUE,
 '["Numéro inconnu qui se fait passer pour le PDG","Demande d''acheter des cartes cadeaux et d''envoyer les codes — schéma de fraude classique","Urgence et discrétion exigées, pour que vous ne consultiez personne","\"Je ne sais pas appeler\" bloque précisément le canal qui démasquerait l''arnaque"]'::jsonb,
 '[]'::jsonb,
 'C''est une fraude au président. Les escrocs se font passer pour votre PDG par SMS et demandent des cartes cadeaux : les codes valent de l''argent immédiatement et de façon irréversible. Un vrai PDG ne demande jamais cela par SMS. Vérifiez par un second canal : appelez Philippe Vermeulen au numéro que vous connaissez déjà.',
 510),

-- FR-BE / SMS — annonce IT légitime (sort 511)
('fr-BE','sms','business','normal','overig',
 'IT Kestrel','IT Kestrel',
 'Les messages internes de l''IT viennent du nom d''expéditeur connu et ne demandent jamais d''identifiants ni de clic.',
 'aujourd''hui 09:00','IT Kestrel : à partir de lundi, la connexion demandera...',
 'IT Kestrel : à partir de lundi, la connexion demandera un code...',
 E'IT Kestrel : à partir de lundi, la connexion à votre compte professionnel demandera un code supplémentaire via l''application Authenticator. Aucune action n''est requise pour le moment. Plus d''informations et les instructions se trouvent sur l''intranet.',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Aucun lien dans le message — renvoi vers l''intranet connu","Aucun identifiant, code ou paiement demandé","Annonce faite à l''avance, sans pression : rien à faire maintenant","Correspond à un processus IT normal (déploiement d''une sécurité renforcée)"]'::jsonb,
 'C''est un véritable message interne de l''IT. Notez la différence avec le phishing : pas de lien, pas de demande de données et aucune pression — seulement une annonce qui renvoie vers l''intranet. Un doute ? Vérifiez auprès du support IT via le canal interne que vous connaissez.',
 511),

-- FR-BE / WhatsApp — "nouveau numéro du PDG" (sort 510)
('fr-BE','whatsapp','business','normal','ceo',
 'Numéro inconnu','+32 4 65 18 42 79',
 'Un "nouveau numéro" d''un dirigeant combiné à une demande d''argent est presque toujours une fraude. Appelez d''abord l''ancien numéro connu.',
 'aujourd''hui 11:47','Bonjour, c''est Philippe. Voici mon nouveau numéro...',
 'Bonjour, c''est Philippe. Voici mon nouveau numéro. Vous êtes...',
 E'Bonjour, c''est Philippe. Voici mon nouveau numéro. Vous êtes au bureau ? J''ai besoin d''aide en urgence pour un paiement — je ne sais pas téléphoner pour l''instant.',
 '[]'::jsonb,
 TRUE,
 '["Numéro inconnu qui se fait passer pour le PDG (\"mon nouveau numéro\")","Demande urgente d''argent dès le premier message","Précipitation : il faut agir tout de suite","\"Je ne sais pas téléphoner\" — précisément le canal qui démasquerait l''arnaque"]'::jsonb,
 '[]'::jsonb,
 'C''est une fraude au président via WhatsApp. La combinaison nouveau numéro + argent + urgence + impossible d''appeler est le schéma standard. Ne répondez pas à ce numéro : appelez Philippe Vermeulen au numéro que vous avez déjà. Un vrai nouveau numéro résiste toujours à cette vérification.',
 510),

-- FR-BE / WhatsApp — message légitime de l''accueil (sort 511)
('fr-BE','whatsapp','business','normal','overig',
 'Accueil Kestrel','Accueil Kestrel',
 'L''accueil utilise WhatsApp Business avec le nom connu de l''entreprise. Pas de lien, pas de données demandées — seulement une information pratique.',
 'aujourd''hui 14:05','Accueil Kestrel : un colis vous attend à l''accueil...',
 'Accueil Kestrel : un colis vous attend à l''accueil, à retirer...',
 E'Accueil Kestrel 📦\n\nBonjour, un colis vous attend à l''accueil. Vous pouvez venir le retirer aujourd''hui jusqu''à 17h00. Merci de vous munir de votre badge.\n\nBien à vous,\nL''accueil',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Expéditeur interne connu via WhatsApp Business","Aucun lien et aucune demande de données ou de paiement","Information concrète et vérifiable : colis à l''accueil, à retirer avant 17h00","Facile à vérifier en passant simplement à l''accueil"]'::jsonb,
 'C''est un véritable message interne de l''accueil. On ne vous demande rien d''autre que de passer — pas de lien, pas de données, pas de paiement. Un doute ? Passez à l''accueil ou appelez le numéro interne.',
 511),

-- ==================== DE ====================

-- DE / SMS — Geschenkkarten-Betrug "CEO" (sort 510)
('de','sms','business','normal','ceo',
 'Unbekannte Nummer','+49 152 28374615',
 'Ihr Geschäftsführer schreibt keine SMS von einer unbekannten Nummer mit einer Geldbitte. Verifizieren Sie immer über eine Nummer, die Sie selbst kennen.',
 'heute 10:12','Hallo Frau Müller, hier Thomas Schneider. Ich sitze in...',
 'Hallo Frau Müller, hier Thomas Schneider. Ich sitze in einem...',
 E'Hallo Frau Müller, hier Thomas Schneider. Ich sitze in einem Meeting und kann gerade nicht telefonieren. Könnten Sie diskret 4 Geschenkkarten zu je 100 € für einen Kunden besorgen? Senden Sie die Codes an diese Nummer. Es ist dringend — die Erstattung regle ich später.',
 '[]'::jsonb,
 TRUE,
 '["Unbekannte Nummer, die sich als Geschäftsführer ausgibt","Bitte, Geschenkkarten zu kaufen und die Codes zu senden — klassisches Betrugsmuster","Eile und Diskretion gefordert, damit Sie niemanden fragen","\"Kann gerade nicht telefonieren\" blockiert genau den Kanal, der den Betrug entlarven würde"]'::jsonb,
 '[]'::jsonb,
 'Das ist CEO-Fraud. Betrüger geben sich per SMS als Ihr Geschäftsführer aus und verlangen Geschenkkarten — die Codes sind sofort und unwiderruflich Geld wert. Ein echter Geschäftsführer bittet nie per SMS darum. Verifizieren Sie über einen zweiten Kanal: Rufen Sie Thomas Schneider unter der Nummer an, die Sie selbst kennen.',
 510),

-- DE / SMS — legitime IT-Ankündigung (sort 511)
('de','sms','business','normal','overig',
 'IT Kestrel','IT Kestrel',
 'Interne IT-Mitteilungen kommen vom bekannten Absendernamen und fragen nie nach Zugangsdaten oder einem Klick.',
 'heute 09:00','IT Kestrel: Ab Montag erfordert die Anmeldung einen...',
 'IT Kestrel: Ab Montag erfordert die Anmeldung einen zusätzlichen...',
 E'IT Kestrel: Ab Montag erfordert die Anmeldung an Ihrem Arbeitskonto einen zusätzlichen Code über die Authenticator-App. Sie müssen jetzt nichts tun. Weitere Informationen und Anleitungen finden Sie im Intranet.',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Kein Link in der Nachricht — Verweis auf das bekannte Intranet","Keine Zugangsdaten, Codes oder Zahlungen verlangt","Ankündigung im Voraus, ohne Zeitdruck: Sie müssen jetzt nichts tun","Passt zu einem normalen IT-Prozess (Einführung zusätzlicher Sicherheit)"]'::jsonb,
 'Das ist eine echte interne Mitteilung der IT. Beachten Sie den Unterschied zu Phishing: kein Link, keine Datenabfrage und kein Druck — nur eine Ankündigung mit Verweis auf das Intranet. Im Zweifel fragen Sie beim IT-Helpdesk über den bekannten internen Kanal nach.',
 511),

-- DE / WhatsApp — "neue Nummer des CEO" (sort 510)
('de','whatsapp','business','normal','ceo',
 'Unbekannte Nummer','+49 176 44120583',
 'Eine "neue Nummer" einer Führungskraft in Kombination mit einer Geldbitte ist fast immer Betrug. Rufen Sie zuerst die alte, bekannte Nummer an.',
 'heute 11:47','Hallo, hier Thomas. Das ist meine neue Nummer...',
 'Hallo, hier Thomas. Das ist meine neue Nummer. Sind Sie im Büro?...',
 E'Hallo, hier Thomas. Das ist meine neue Nummer. Sind Sie im Büro? Ich brauche dringend Hilfe bei einer Zahlung — kann gerade nicht telefonieren.',
 '[]'::jsonb,
 TRUE,
 '["Unbekannte Nummer, die sich als Geschäftsführer ausgibt (\"meine neue Nummer\")","Sofort eine dringende Bitte rund um Geld","Eile: Es muss jetzt sofort etwas passieren","\"Kann gerade nicht telefonieren\" — genau der Kanal, der den Betrug entlarven würde"]'::jsonb,
 '[]'::jsonb,
 'Das ist CEO-Fraud über WhatsApp. Die Kombination neue Nummer + Geld + Eile + nicht telefonieren können ist das Standardmuster. Antworten Sie nicht auf diese Nummer, sondern rufen Sie Thomas Schneider unter der Nummer an, die Sie bereits haben. Eine echte neue Nummer besteht diese Prüfung immer.',
 510),

-- DE / WhatsApp — legitime Nachricht vom Empfang (sort 511)
('de','whatsapp','business','normal','overig',
 'Empfang Kestrel','Empfang Kestrel',
 'Der Empfang nutzt WhatsApp Business mit dem bekannten Firmennamen. Kein Link, keine Datenabfrage — nur praktische Informationen.',
 'heute 14:05','Empfang Kestrel: Am Empfang liegt ein Paket für Sie...',
 'Empfang Kestrel: Am Empfang liegt ein Paket für Sie bereit...',
 E'Empfang Kestrel 📦\n\nGuten Tag, am Empfang liegt ein Paket für Sie bereit. Sie können es heute bis 17:00 Uhr abholen. Bitte bringen Sie Ihren Mitarbeiterausweis mit.\n\nMit freundlichen Grüßen\nder Empfang',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Bekannter interner Absender über WhatsApp Business","Kein Link und keine Abfrage von Daten oder Zahlungen","Konkrete, überprüfbare Information: Paket am Empfang, Abholung bis 17:00 Uhr","Leicht zu verifizieren, indem Sie einfach kurz am Empfang vorbeigehen"]'::jsonb,
 'Das ist eine echte interne Nachricht vom Empfang. Es wird nichts verlangt außer vorbeizukommen — kein Link, keine Daten, keine Zahlung. Im Zweifel gehen Sie kurz vorbei oder rufen Sie den Empfang unter der internen Nummer an.',
 511);

-- ============================================================
-- GAP-BERICHTEN — juli 2026 (e-mail, business)
-- Rij 1-3: legitieme HR-vitaliteitsweek (nl, nl-BE, en — normal, sort 110)
-- Rij 4: "mailbox bijna vol"-phishing (en — normal, sort 120)
-- Rij 5-6: onkostennota-fraude (fr, fr-BE — advanced, sort 280)
-- 6 rijen. GEEN en-US (wordt gegenereerd uit en).
-- ============================================================
INSERT INTO inbox_messages
  (locale, audience, sender_name, sender_address, sender_note, received_label,
   subject, preview, body, links, is_phishing, red_flags, green_flags,
   explanation, sort_order, difficulty, category, channel) VALUES

-- ---------------- nl — HR vitaliteitsweek (legitiem, sort 110) ----------------
('nl', 'business',
 'HR Kestrel',
 'hr@kestrel.nl',
 'Het adres hr@kestrel.nl gebruikt het echte bedrijfsdomein kestrel.nl — een bekende interne afzender.',
 'vandaag 09:15',
 'Vitaliteitsweek 2026: schrijf u in voor de workshops',
 'Van maandag 20 t/m vrijdag 24 juli organiseren we weer de jaarlijkse...',
 E'<div class="eml fam-tech" style="--brand:#1a7a3c;--cta:#1a7a3c"><div class="eml-body"><p>Beste Johanna,</p><p>Van maandag 20 t/m vrijdag 24 juli organiseren we weer de jaarlijkse vitaliteitsweek. Ook dit jaar is er een gevarieerd programma met workshops over gezond werken, waaronder stoelmassage, een lunchwandeling, een workshop slaap en een sessie over werkdruk en energie.</p><p>Deelname is vrijwillig en kosteloos. Aanmelden kan tot en met vrijdag 17 juli via de bekende pagina op het intranet, onder Personeel &gt; Vitaliteitsweek. Vol is vol, maar de meeste workshops worden meerdere keren gegeven.</p><p>Vragen? Loop gerust binnen bij HR of stuur ons een bericht.</p><p>Met vriendelijke groet,<br>Team HR<br>Kestrel</p></div></div>',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["De afzender hr@kestrel.nl gebruikt het echte bedrijfsdomein kestrel.nl","Geen link in het bericht — aanmelden gaat via het bekende intranet","Er wordt niet om een wachtwoord, gegevens of betaling gevraagd","Geen kunstmatige tijdsdruk: deelname is vrijwillig en de deadline is een gewone inschrijftermijn"]'::jsonb,
 'Dit is een echt intern HR-bericht. Alle signalen kloppen: een bekende afzender op het echte bedrijfsdomein, geen link, geen verzoek om gegevens of geld en geen druk. Aanmelden gaat via het intranet dat u zelf al kent — precies zoals het hoort. Twijfelt u toch? Vraag het even na bij HR via het bekende interne kanaal.',
 110, 'normal', 'overig', 'email'),

-- ---------------- nl-BE — HR vitaliteitsweek (legitiem, sort 110) ----------------
('nl-BE', 'business',
 'HR Kestrel',
 'hr@kestrel.be',
 'Het adres hr@kestrel.be gebruikt het echte bedrijfsdomein kestrel.be — een bekende interne afzender.',
 'vandaag 09:15',
 'Vitaliteitsweek 2026: schrijf u in voor de workshops',
 'Van maandag 20 t/m vrijdag 24 juli organiseren we opnieuw de jaarlijkse...',
 E'<div class="eml fam-tech" style="--brand:#1a7a3c;--cta:#1a7a3c"><div class="eml-body"><p>Beste Petra,</p><p>Van maandag 20 t/m vrijdag 24 juli organiseren we opnieuw de jaarlijkse vitaliteitsweek. Ook dit jaar is er een gevarieerd programma met workshops rond gezond werken, waaronder stoelmassage, een lunchwandeling, een workshop slaap en een sessie over werkdruk en energie.</p><p>Deelname is vrijblijvend en gratis. Inschrijven kan tot en met vrijdag 17 juli via de bekende pagina op het intranet, onder Personeel &gt; Vitaliteitsweek. Volzet is volzet, maar de meeste workshops worden meerdere keren gegeven.</p><p>Vragen? Spring gerust binnen bij HR of stuur ons een berichtje.</p><p>Met vriendelijke groeten,<br>Team HR<br>Kestrel</p></div></div>',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["De afzender hr@kestrel.be gebruikt het echte bedrijfsdomein kestrel.be","Geen link in het bericht — inschrijven gaat via het bekende intranet","Er wordt niet om een wachtwoord, gegevens of betaling gevraagd","Geen kunstmatige tijdsdruk: deelname is vrijblijvend en de deadline is een gewone inschrijftermijn"]'::jsonb,
 'Dit is een echt intern HR-bericht. Alle signalen kloppen: een bekende afzender op het echte bedrijfsdomein, geen link, geen vraag naar gegevens of geld en geen druk. Inschrijven gaat via het intranet dat u zelf al kent — precies zoals het hoort. Twijfelt u toch? Vraag het even na bij HR via het bekende interne kanaal.',
 110, 'normal', 'overig', 'email'),

-- ---------------- en — HR wellbeing week (legitiem, sort 110) ----------------
('en', 'business',
 'Kestrel HR',
 'hr@kestrel.co.uk',
 'The address hr@kestrel.co.uk uses the genuine company domain kestrel.co.uk — a familiar internal sender.',
 'today 09:15',
 'Wellbeing Week 2026: sign up for the workshops',
 'From Monday 20 to Friday 24 July we are once again running our annual...',
 E'<div class="eml fam-tech" style="--brand:#1a7a3c;--cta:#1a7a3c"><div class="eml-body"><p>Dear Jane,</p><p>From Monday 20 to Friday 24 July we are once again running our annual Wellbeing Week. This year''s programme offers a varied set of workshops on healthy working, including chair massage, a lunchtime walk, a workshop on sleep and a session on workload and energy.</p><p>Taking part is voluntary and free of charge. You can sign up until Friday 17 July via the usual page on the intranet, under People &gt; Wellbeing Week. Places are limited, but most workshops run several times during the week.</p><p>Any questions? Do pop in to see the HR team or drop us a message.</p><p>Kind regards,<br>The HR team<br>Kestrel</p></div></div>',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["The sender hr@kestrel.co.uk uses the genuine company domain kestrel.co.uk","No link in the message — sign-up happens via the familiar intranet","No password, personal details or payment requested","No artificial urgency: taking part is voluntary and the deadline is an ordinary sign-up window"]'::jsonb,
 'This is a genuine internal HR message. Every signal checks out: a familiar sender on the real company domain, no link, no request for details or money and no pressure. Sign-up goes through the intranet you already know — exactly as it should. Still unsure? Check with HR through the internal channel you know.',
 110, 'normal', 'overig', 'email'),

-- ---------------- en — "mailbox almost full" phishing (sort 120) ----------------
('en', 'business',
 'IT Support',
 'support@kestrel-mailservice.com',
 'The domain kestrel-mailservice.com is not your company''s domain: your real IT department mails from kestrel.co.uk.',
 'today 13:42',
 'Action required: your mailbox is almost full',
 'Your mailbox j.smith@kestrel.co.uk has reached 98% of its storage...',
 E'<div class="eml fam-tech" style="--brand:#2f5597;--cta:#2f5597"><div class="eml-body"><p>Dear user,</p><p>Your mailbox j.smith@kestrel.co.uk has reached 98% of its storage limit. If you do not act today, incoming messages will be rejected and important emails may be permanently lost.</p><p>To keep receiving email, please sign in below to verify your account and upgrade your mailbox storage free of charge:</p><p>{{link:0}}</p><p>This must be completed within 24 hours. Mailboxes that are not upgraded will be suspended automatically.</p><p>Regards,<br>IT Support<br>Mail Services Team</p></div></div>',
 '[{"label":"Upgrade mailbox storage","real_url":"http://kestrel-mailservice.com/quota/login","suspicious":true,"warning":"This link goes to kestrel-mailservice.com — not your company''s real domain kestrel.co.uk. The sign-in page it leads to exists only to steal your work password."}]'::jsonb,
 TRUE,
 '["The sender domain kestrel-mailservice.com is not your company''s real domain kestrel.co.uk","Urgency and threats: act within 24 hours or your mailbox will be suspended and email lost","A link asking you to sign in — real IT never asks for your password via an email link","Generic greeting (\"Dear user\") instead of your name, unlike genuine internal messages"]'::jsonb,
 '[]'::jsonb,
 'This is a classic "mailbox full" phishing email. The lookalike domain kestrel-mailservice.com, the 24-hour deadline and the sign-in link are all designed to make you hand over your work password in a panic. Real IT messages come from your own company domain and never ask you to log in via an email link. Unsure whether your mailbox really is full? Ask your IT helpdesk through the internal channel you know.',
 120, 'normal', 'account', 'email'),

-- ---------------- fr — fraude à la note de frais (advanced, sort 280) ----------------
('fr', 'business',
 'Service Comptabilité',
 'comptabilite@kestrel-finances.fr',
 'Le domaine kestrel-finances.fr n''est pas le vrai domaine de l''entreprise : votre service financier écrit depuis kestrel.fr.',
 'aujourd''hui 08:37',
 'Nouvelle plateforme de notes de frais — activation de votre compte',
 'Dans le cadre de la modernisation de nos outils financiers, nous...',
 E'<div class="eml fam-tech" style="--brand:#2f5597;--cta:#2f5597"><div class="eml-body"><p>Bonjour Pauline,</p><p>Dans le cadre de la modernisation de nos outils financiers, nous migrons vers une nouvelle plateforme de notes de frais. Votre compte a été précréé et n''attend plus que votre activation.</p><p>Merci d''activer votre accès avant la fin du mois via le lien ci-dessous :</p><p>{{link:0}}</p><p>Sans activation de votre part, vos notes de frais du mois de novembre ne pourront pas être traitées dans la nouvelle plateforme et leur remboursement sera retardé.</p><p>Nous restons à votre disposition pour toute question.</p><p>Cordialement,<br>Le service comptabilité<br>Kestrel</p></div></div>',
 '[{"label":"Activer mon compte","real_url":"https://kestrel-finances.fr/activation/notes-de-frais","suspicious":true,"warning":"Ce lien mène vers kestrel-finances.fr — un domaine imitation, le vrai domaine de l''entreprise est kestrel.fr. La page d''activation sert à voler vos identifiants professionnels."}]'::jsonb,
 TRUE,
 '["Le domaine expéditeur kestrel-finances.fr diffère du vrai domaine de l''entreprise, kestrel.fr","Un lien d''activation non sollicité, alors que les changements d''outils internes passent par les canaux connus (intranet, annonce officielle)","Une pression douce autour de l''argent : sans action, votre remboursement sera retardé","Aucune annonce préalable de cette migration par les canaux internes habituels"]'::jsonb,
 '[]'::jsonb,
 'C''est une fraude soignée à la note de frais : le message est professionnel et sans fautes, mais le processus ne tient pas. Le domaine kestrel-finances.fr imite le vrai domaine kestrel.fr, le lien d''activation arrive sans annonce préalable, et la pression joue subtilement sur votre remboursement. Face à un nouveau portail financier, ne cliquez pas : vérifiez l''information sur l''intranet ou auprès du service comptabilité via le canal interne que vous connaissez.',
 280, 'advanced', 'ceo', 'email'),

-- ---------------- fr-BE — fraude à la note de frais (advanced, sort 280) ----------------
('fr-BE', 'business',
 'Service Comptabilité',
 'comptabilite@kestrel-finances.be',
 'Le domaine kestrel-finances.be n''est pas le vrai domaine de l''entreprise : votre service financier écrit depuis kestrel.be.',
 'aujourd''hui 08:37',
 'Nouvelle plateforme de notes de frais — activation de votre compte',
 'Dans le cadre de la modernisation de nos outils financiers, nous...',
 E'<div class="eml fam-tech" style="--brand:#2f5597;--cta:#2f5597"><div class="eml-body"><p>Bonjour Pauline,</p><p>Dans le cadre de la modernisation de nos outils financiers, nous migrons vers une nouvelle plateforme de notes de frais. Votre compte a été précréé et n''attend plus que votre activation.</p><p>Merci d''activer votre accès avant la fin du mois via le lien ci-dessous :</p><p>{{link:0}}</p><p>Sans activation de votre part, vos notes de frais du mois de novembre ne pourront pas être traitées dans la nouvelle plateforme et leur remboursement sera retardé.</p><p>Nous restons à votre disposition pour toute question.</p><p>Bien à vous,<br>Le service comptabilité<br>Kestrel</p></div></div>',
 '[{"label":"Activer mon compte","real_url":"https://kestrel-finances.be/activation/notes-de-frais","suspicious":true,"warning":"Ce lien mène vers kestrel-finances.be — un domaine imitation, le vrai domaine de l''entreprise est kestrel.be. La page d''activation sert à voler vos identifiants professionnels."}]'::jsonb,
 TRUE,
 '["Le domaine expéditeur kestrel-finances.be diffère du vrai domaine de l''entreprise, kestrel.be","Un lien d''activation non sollicité, alors que les changements d''outils internes passent par les canaux connus (intranet, annonce officielle)","Une pression douce autour de l''argent : sans action, votre remboursement sera retardé","Aucune annonce préalable de cette migration par les canaux internes habituels"]'::jsonb,
 '[]'::jsonb,
 'C''est une fraude soignée à la note de frais : le message est professionnel et sans fautes, mais le processus ne tient pas. Le domaine kestrel-finances.be imite le vrai domaine kestrel.be, le lien d''activation arrive sans annonce préalable, et la pression joue subtilement sur votre remboursement. Face à un nouveau portail financier, ne cliquez pas : vérifiez l''information sur l''intranet ou auprès du service comptabilité via le canal interne que vous connaissez.',
 280, 'advanced', 'ceo', 'email');

-- O2 → AT&T brand conversion for en-US (SMS telecom phishing, sort 364)
-- Applied after en-US is copied from en, so this updates the en-US copy only.


-- ============================================================
-- en-US: eigen Amerikaanse set. Kopie van de Britse (en) rijen,
-- daarna geamerikaniseerd via gecoördineerde REPLACE (merk + echt
-- domein + lookalike samen): HMRC→IRS, Barclays→Chase, Royal Mail→USPS,
-- NHS→Medicare, £→$, .co.uk→.com, Amerikaanse spelling. Zo is en-US een
-- volwaardige aparte taal met eigen DB-inhoud, net als nl-BE/fr-BE.
-- ============================================================
INSERT INTO examples (locale, audience, channel, sender, subject, body, annotations, sort_order)
SELECT 'en-US', audience, channel, sender, subject, body, annotations, sort_order
FROM examples WHERE locale = 'en';

INSERT INTO inbox_messages
  (locale, audience, channel, category, sender_name, sender_address, sender_note,
   received_label, subject, preview, body, links, attachments, is_phishing,
   red_flags, green_flags, explanation, sort_order, difficulty, active)
SELECT 'en-US', audience, channel, category, sender_name, sender_address, sender_note,
   received_label, subject, preview, body, links, attachments, is_phishing,
   red_flags, green_flags, explanation, sort_order, difficulty, active
FROM inbox_messages WHERE locale = 'en';

UPDATE examples SET
  sender = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(sender, 'hmrc-refund.co.uk', 'irs-refund.com'), 'hmrc.gov.uk', 'irs.gov'), 'my-barclays.secure-review.co.uk', 'my-chase.secure-review.com'), 'barclays-secure-login.com', 'chase-secure-login.com'), 'barclays.co.uk', 'chase.com'), 'royalmail-parcel.co.uk', 'usps-parcel.com'), 'nhs-verify.org', 'medicare-verify.org'), 'nhs.uk', 'medicare.gov'), 'amazon.co.uk', 'amazon.com'), 'paypal.co.uk', 'paypal.com'), 'boots.co.uk', 'cvs.com'), 'camden.gov.uk', 'camden.gov'), 'kestrel-access.co.uk', 'kestrel-access.com'), 'kestrel.co.uk', 'kestrel.com'), 'secure-review.co.uk', 'secure-review.com'), 'HM Revenue &amp; Customs', 'Internal Revenue Service'), 'HM Revenue & Customs', 'Internal Revenue Service'), 'HMRC', 'IRS'), 'BARCLAYS', 'CHASE'), 'Barclays', 'Chase'), 'Royal Mail', 'USPS'), 'NHS Digital', 'Medicare'), 'NHS', 'Medicare'), 'Boots', 'CVS'), 'council tax', 'property tax'), 'Council Tax', 'Property tax'), '.co.uk', '.com'), 'gov.uk', 'usa.gov'), '£', '$'), 'colour', 'color'), 'favourite', 'favorite'), 'organisation', 'organization'), 'licence', 'license'), 'Licence', 'License'), 'apologise', 'apologize'), 'recognise', 'recognize'),
  subject = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(subject, 'hmrc-refund.co.uk', 'irs-refund.com'), 'hmrc.gov.uk', 'irs.gov'), 'my-barclays.secure-review.co.uk', 'my-chase.secure-review.com'), 'barclays-secure-login.com', 'chase-secure-login.com'), 'barclays.co.uk', 'chase.com'), 'royalmail-parcel.co.uk', 'usps-parcel.com'), 'nhs-verify.org', 'medicare-verify.org'), 'nhs.uk', 'medicare.gov'), 'amazon.co.uk', 'amazon.com'), 'paypal.co.uk', 'paypal.com'), 'boots.co.uk', 'cvs.com'), 'camden.gov.uk', 'camden.gov'), 'kestrel-access.co.uk', 'kestrel-access.com'), 'kestrel.co.uk', 'kestrel.com'), 'secure-review.co.uk', 'secure-review.com'), 'HM Revenue &amp; Customs', 'Internal Revenue Service'), 'HM Revenue & Customs', 'Internal Revenue Service'), 'HMRC', 'IRS'), 'BARCLAYS', 'CHASE'), 'Barclays', 'Chase'), 'Royal Mail', 'USPS'), 'NHS Digital', 'Medicare'), 'NHS', 'Medicare'), 'Boots', 'CVS'), 'council tax', 'property tax'), 'Council Tax', 'Property tax'), '.co.uk', '.com'), 'gov.uk', 'usa.gov'), '£', '$'), 'colour', 'color'), 'favourite', 'favorite'), 'organisation', 'organization'), 'licence', 'license'), 'Licence', 'License'), 'apologise', 'apologize'), 'recognise', 'recognize'),
  body = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(body, 'hmrc-refund.co.uk', 'irs-refund.com'), 'hmrc.gov.uk', 'irs.gov'), 'my-barclays.secure-review.co.uk', 'my-chase.secure-review.com'), 'barclays-secure-login.com', 'chase-secure-login.com'), 'barclays.co.uk', 'chase.com'), 'royalmail-parcel.co.uk', 'usps-parcel.com'), 'nhs-verify.org', 'medicare-verify.org'), 'nhs.uk', 'medicare.gov'), 'amazon.co.uk', 'amazon.com'), 'paypal.co.uk', 'paypal.com'), 'boots.co.uk', 'cvs.com'), 'camden.gov.uk', 'camden.gov'), 'kestrel-access.co.uk', 'kestrel-access.com'), 'kestrel.co.uk', 'kestrel.com'), 'secure-review.co.uk', 'secure-review.com'), 'HM Revenue &amp; Customs', 'Internal Revenue Service'), 'HM Revenue & Customs', 'Internal Revenue Service'), 'HMRC', 'IRS'), 'BARCLAYS', 'CHASE'), 'Barclays', 'Chase'), 'Royal Mail', 'USPS'), 'NHS Digital', 'Medicare'), 'NHS', 'Medicare'), 'Boots', 'CVS'), 'council tax', 'property tax'), 'Council Tax', 'Property tax'), '.co.uk', '.com'), 'gov.uk', 'usa.gov'), '£', '$'), 'colour', 'color'), 'favourite', 'favorite'), 'organisation', 'organization'), 'licence', 'license'), 'Licence', 'License'), 'apologise', 'apologize'), 'recognise', 'recognize'),
  annotations = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(annotations::text, 'hmrc-refund.co.uk', 'irs-refund.com'), 'hmrc.gov.uk', 'irs.gov'), 'my-barclays.secure-review.co.uk', 'my-chase.secure-review.com'), 'barclays-secure-login.com', 'chase-secure-login.com'), 'barclays.co.uk', 'chase.com'), 'royalmail-parcel.co.uk', 'usps-parcel.com'), 'nhs-verify.org', 'medicare-verify.org'), 'nhs.uk', 'medicare.gov'), 'amazon.co.uk', 'amazon.com'), 'paypal.co.uk', 'paypal.com'), 'boots.co.uk', 'cvs.com'), 'camden.gov.uk', 'camden.gov'), 'kestrel-access.co.uk', 'kestrel-access.com'), 'kestrel.co.uk', 'kestrel.com'), 'secure-review.co.uk', 'secure-review.com'), 'HM Revenue &amp; Customs', 'Internal Revenue Service'), 'HM Revenue & Customs', 'Internal Revenue Service'), 'HMRC', 'IRS'), 'BARCLAYS', 'CHASE'), 'Barclays', 'Chase'), 'Royal Mail', 'USPS'), 'NHS Digital', 'Medicare'), 'NHS', 'Medicare'), 'Boots', 'CVS'), 'council tax', 'property tax'), 'Council Tax', 'Property tax'), '.co.uk', '.com'), 'gov.uk', 'usa.gov'), '£', '$'), 'colour', 'color'), 'favourite', 'favorite'), 'organisation', 'organization'), 'licence', 'license'), 'Licence', 'License'), 'apologise', 'apologize'), 'recognise', 'recognize')::jsonb
WHERE locale = 'en-US';

UPDATE inbox_messages SET
  sender_name = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(sender_name, 'hmrc-refund.co.uk', 'irs-refund.com'), 'hmrc.gov.uk', 'irs.gov'), 'my-barclays.secure-review.co.uk', 'my-chase.secure-review.com'), 'barclays-secure-login.com', 'chase-secure-login.com'), 'barclays.co.uk', 'chase.com'), 'royalmail-parcel.co.uk', 'usps-parcel.com'), 'nhs-verify.org', 'medicare-verify.org'), 'nhs.uk', 'medicare.gov'), 'amazon.co.uk', 'amazon.com'), 'paypal.co.uk', 'paypal.com'), 'boots.co.uk', 'cvs.com'), 'camden.gov.uk', 'camden.gov'), 'kestrel-access.co.uk', 'kestrel-access.com'), 'kestrel.co.uk', 'kestrel.com'), 'secure-review.co.uk', 'secure-review.com'), 'HM Revenue &amp; Customs', 'Internal Revenue Service'), 'HM Revenue & Customs', 'Internal Revenue Service'), 'HMRC', 'IRS'), 'BARCLAYS', 'CHASE'), 'Barclays', 'Chase'), 'Royal Mail', 'USPS'), 'NHS Digital', 'Medicare'), 'NHS', 'Medicare'), 'Boots', 'CVS'), 'council tax', 'property tax'), 'Council Tax', 'Property tax'), '.co.uk', '.com'), 'gov.uk', 'usa.gov'), '£', '$'), 'colour', 'color'), 'favourite', 'favorite'), 'organisation', 'organization'), 'licence', 'license'), 'Licence', 'License'), 'apologise', 'apologize'), 'recognise', 'recognize'),
  sender_address = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(sender_address, 'hmrc-refund.co.uk', 'irs-refund.com'), 'hmrc.gov.uk', 'irs.gov'), 'my-barclays.secure-review.co.uk', 'my-chase.secure-review.com'), 'barclays-secure-login.com', 'chase-secure-login.com'), 'barclays.co.uk', 'chase.com'), 'royalmail-parcel.co.uk', 'usps-parcel.com'), 'nhs-verify.org', 'medicare-verify.org'), 'nhs.uk', 'medicare.gov'), 'amazon.co.uk', 'amazon.com'), 'paypal.co.uk', 'paypal.com'), 'boots.co.uk', 'cvs.com'), 'camden.gov.uk', 'camden.gov'), 'kestrel-access.co.uk', 'kestrel-access.com'), 'kestrel.co.uk', 'kestrel.com'), 'secure-review.co.uk', 'secure-review.com'), 'HM Revenue &amp; Customs', 'Internal Revenue Service'), 'HM Revenue & Customs', 'Internal Revenue Service'), 'HMRC', 'IRS'), 'BARCLAYS', 'CHASE'), 'Barclays', 'Chase'), 'Royal Mail', 'USPS'), 'NHS Digital', 'Medicare'), 'NHS', 'Medicare'), 'Boots', 'CVS'), 'council tax', 'property tax'), 'Council Tax', 'Property tax'), '.co.uk', '.com'), 'gov.uk', 'usa.gov'), '£', '$'), 'colour', 'color'), 'favourite', 'favorite'), 'organisation', 'organization'), 'licence', 'license'), 'Licence', 'License'), 'apologise', 'apologize'), 'recognise', 'recognize'),
  sender_note = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(sender_note, 'hmrc-refund.co.uk', 'irs-refund.com'), 'hmrc.gov.uk', 'irs.gov'), 'my-barclays.secure-review.co.uk', 'my-chase.secure-review.com'), 'barclays-secure-login.com', 'chase-secure-login.com'), 'barclays.co.uk', 'chase.com'), 'royalmail-parcel.co.uk', 'usps-parcel.com'), 'nhs-verify.org', 'medicare-verify.org'), 'nhs.uk', 'medicare.gov'), 'amazon.co.uk', 'amazon.com'), 'paypal.co.uk', 'paypal.com'), 'boots.co.uk', 'cvs.com'), 'camden.gov.uk', 'camden.gov'), 'kestrel-access.co.uk', 'kestrel-access.com'), 'kestrel.co.uk', 'kestrel.com'), 'secure-review.co.uk', 'secure-review.com'), 'HM Revenue &amp; Customs', 'Internal Revenue Service'), 'HM Revenue & Customs', 'Internal Revenue Service'), 'HMRC', 'IRS'), 'BARCLAYS', 'CHASE'), 'Barclays', 'Chase'), 'Royal Mail', 'USPS'), 'NHS Digital', 'Medicare'), 'NHS', 'Medicare'), 'Boots', 'CVS'), 'council tax', 'property tax'), 'Council Tax', 'Property tax'), '.co.uk', '.com'), 'gov.uk', 'usa.gov'), '£', '$'), 'colour', 'color'), 'favourite', 'favorite'), 'organisation', 'organization'), 'licence', 'license'), 'Licence', 'License'), 'apologise', 'apologize'), 'recognise', 'recognize'),
  subject = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(subject, 'hmrc-refund.co.uk', 'irs-refund.com'), 'hmrc.gov.uk', 'irs.gov'), 'my-barclays.secure-review.co.uk', 'my-chase.secure-review.com'), 'barclays-secure-login.com', 'chase-secure-login.com'), 'barclays.co.uk', 'chase.com'), 'royalmail-parcel.co.uk', 'usps-parcel.com'), 'nhs-verify.org', 'medicare-verify.org'), 'nhs.uk', 'medicare.gov'), 'amazon.co.uk', 'amazon.com'), 'paypal.co.uk', 'paypal.com'), 'boots.co.uk', 'cvs.com'), 'camden.gov.uk', 'camden.gov'), 'kestrel-access.co.uk', 'kestrel-access.com'), 'kestrel.co.uk', 'kestrel.com'), 'secure-review.co.uk', 'secure-review.com'), 'HM Revenue &amp; Customs', 'Internal Revenue Service'), 'HM Revenue & Customs', 'Internal Revenue Service'), 'HMRC', 'IRS'), 'BARCLAYS', 'CHASE'), 'Barclays', 'Chase'), 'Royal Mail', 'USPS'), 'NHS Digital', 'Medicare'), 'NHS', 'Medicare'), 'Boots', 'CVS'), 'council tax', 'property tax'), 'Council Tax', 'Property tax'), '.co.uk', '.com'), 'gov.uk', 'usa.gov'), '£', '$'), 'colour', 'color'), 'favourite', 'favorite'), 'organisation', 'organization'), 'licence', 'license'), 'Licence', 'License'), 'apologise', 'apologize'), 'recognise', 'recognize'),
  preview = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(preview, 'hmrc-refund.co.uk', 'irs-refund.com'), 'hmrc.gov.uk', 'irs.gov'), 'my-barclays.secure-review.co.uk', 'my-chase.secure-review.com'), 'barclays-secure-login.com', 'chase-secure-login.com'), 'barclays.co.uk', 'chase.com'), 'royalmail-parcel.co.uk', 'usps-parcel.com'), 'nhs-verify.org', 'medicare-verify.org'), 'nhs.uk', 'medicare.gov'), 'amazon.co.uk', 'amazon.com'), 'paypal.co.uk', 'paypal.com'), 'boots.co.uk', 'cvs.com'), 'camden.gov.uk', 'camden.gov'), 'kestrel-access.co.uk', 'kestrel-access.com'), 'kestrel.co.uk', 'kestrel.com'), 'secure-review.co.uk', 'secure-review.com'), 'HM Revenue &amp; Customs', 'Internal Revenue Service'), 'HM Revenue & Customs', 'Internal Revenue Service'), 'HMRC', 'IRS'), 'BARCLAYS', 'CHASE'), 'Barclays', 'Chase'), 'Royal Mail', 'USPS'), 'NHS Digital', 'Medicare'), 'NHS', 'Medicare'), 'Boots', 'CVS'), 'council tax', 'property tax'), 'Council Tax', 'Property tax'), '.co.uk', '.com'), 'gov.uk', 'usa.gov'), '£', '$'), 'colour', 'color'), 'favourite', 'favorite'), 'organisation', 'organization'), 'licence', 'license'), 'Licence', 'License'), 'apologise', 'apologize'), 'recognise', 'recognize'),
  body = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(body, 'hmrc-refund.co.uk', 'irs-refund.com'), 'hmrc.gov.uk', 'irs.gov'), 'my-barclays.secure-review.co.uk', 'my-chase.secure-review.com'), 'barclays-secure-login.com', 'chase-secure-login.com'), 'barclays.co.uk', 'chase.com'), 'royalmail-parcel.co.uk', 'usps-parcel.com'), 'nhs-verify.org', 'medicare-verify.org'), 'nhs.uk', 'medicare.gov'), 'amazon.co.uk', 'amazon.com'), 'paypal.co.uk', 'paypal.com'), 'boots.co.uk', 'cvs.com'), 'camden.gov.uk', 'camden.gov'), 'kestrel-access.co.uk', 'kestrel-access.com'), 'kestrel.co.uk', 'kestrel.com'), 'secure-review.co.uk', 'secure-review.com'), 'HM Revenue &amp; Customs', 'Internal Revenue Service'), 'HM Revenue & Customs', 'Internal Revenue Service'), 'HMRC', 'IRS'), 'BARCLAYS', 'CHASE'), 'Barclays', 'Chase'), 'Royal Mail', 'USPS'), 'NHS Digital', 'Medicare'), 'NHS', 'Medicare'), 'Boots', 'CVS'), 'council tax', 'property tax'), 'Council Tax', 'Property tax'), '.co.uk', '.com'), 'gov.uk', 'usa.gov'), '£', '$'), 'colour', 'color'), 'favourite', 'favorite'), 'organisation', 'organization'), 'licence', 'license'), 'Licence', 'License'), 'apologise', 'apologize'), 'recognise', 'recognize'),
  explanation = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(explanation, 'hmrc-refund.co.uk', 'irs-refund.com'), 'hmrc.gov.uk', 'irs.gov'), 'my-barclays.secure-review.co.uk', 'my-chase.secure-review.com'), 'barclays-secure-login.com', 'chase-secure-login.com'), 'barclays.co.uk', 'chase.com'), 'royalmail-parcel.co.uk', 'usps-parcel.com'), 'nhs-verify.org', 'medicare-verify.org'), 'nhs.uk', 'medicare.gov'), 'amazon.co.uk', 'amazon.com'), 'paypal.co.uk', 'paypal.com'), 'boots.co.uk', 'cvs.com'), 'camden.gov.uk', 'camden.gov'), 'kestrel-access.co.uk', 'kestrel-access.com'), 'kestrel.co.uk', 'kestrel.com'), 'secure-review.co.uk', 'secure-review.com'), 'HM Revenue &amp; Customs', 'Internal Revenue Service'), 'HM Revenue & Customs', 'Internal Revenue Service'), 'HMRC', 'IRS'), 'BARCLAYS', 'CHASE'), 'Barclays', 'Chase'), 'Royal Mail', 'USPS'), 'NHS Digital', 'Medicare'), 'NHS', 'Medicare'), 'Boots', 'CVS'), 'council tax', 'property tax'), 'Council Tax', 'Property tax'), '.co.uk', '.com'), 'gov.uk', 'usa.gov'), '£', '$'), 'colour', 'color'), 'favourite', 'favorite'), 'organisation', 'organization'), 'licence', 'license'), 'Licence', 'License'), 'apologise', 'apologize'), 'recognise', 'recognize'),
  links = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(links::text, 'hmrc-refund.co.uk', 'irs-refund.com'), 'hmrc.gov.uk', 'irs.gov'), 'my-barclays.secure-review.co.uk', 'my-chase.secure-review.com'), 'barclays-secure-login.com', 'chase-secure-login.com'), 'barclays.co.uk', 'chase.com'), 'royalmail-parcel.co.uk', 'usps-parcel.com'), 'nhs-verify.org', 'medicare-verify.org'), 'nhs.uk', 'medicare.gov'), 'amazon.co.uk', 'amazon.com'), 'paypal.co.uk', 'paypal.com'), 'boots.co.uk', 'cvs.com'), 'camden.gov.uk', 'camden.gov'), 'kestrel-access.co.uk', 'kestrel-access.com'), 'kestrel.co.uk', 'kestrel.com'), 'secure-review.co.uk', 'secure-review.com'), 'HM Revenue &amp; Customs', 'Internal Revenue Service'), 'HM Revenue & Customs', 'Internal Revenue Service'), 'HMRC', 'IRS'), 'BARCLAYS', 'CHASE'), 'Barclays', 'Chase'), 'Royal Mail', 'USPS'), 'NHS Digital', 'Medicare'), 'NHS', 'Medicare'), 'Boots', 'CVS'), 'council tax', 'property tax'), 'Council Tax', 'Property tax'), '.co.uk', '.com'), 'gov.uk', 'usa.gov'), '£', '$'), 'colour', 'color'), 'favourite', 'favorite'), 'organisation', 'organization'), 'licence', 'license'), 'Licence', 'License'), 'apologise', 'apologize'), 'recognise', 'recognize')::jsonb,
  red_flags = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(red_flags::text, 'hmrc-refund.co.uk', 'irs-refund.com'), 'hmrc.gov.uk', 'irs.gov'), 'my-barclays.secure-review.co.uk', 'my-chase.secure-review.com'), 'barclays-secure-login.com', 'chase-secure-login.com'), 'barclays.co.uk', 'chase.com'), 'royalmail-parcel.co.uk', 'usps-parcel.com'), 'nhs-verify.org', 'medicare-verify.org'), 'nhs.uk', 'medicare.gov'), 'amazon.co.uk', 'amazon.com'), 'paypal.co.uk', 'paypal.com'), 'boots.co.uk', 'cvs.com'), 'camden.gov.uk', 'camden.gov'), 'kestrel-access.co.uk', 'kestrel-access.com'), 'kestrel.co.uk', 'kestrel.com'), 'secure-review.co.uk', 'secure-review.com'), 'HM Revenue &amp; Customs', 'Internal Revenue Service'), 'HM Revenue & Customs', 'Internal Revenue Service'), 'HMRC', 'IRS'), 'BARCLAYS', 'CHASE'), 'Barclays', 'Chase'), 'Royal Mail', 'USPS'), 'NHS Digital', 'Medicare'), 'NHS', 'Medicare'), 'Boots', 'CVS'), 'council tax', 'property tax'), 'Council Tax', 'Property tax'), '.co.uk', '.com'), 'gov.uk', 'usa.gov'), '£', '$'), 'colour', 'color'), 'favourite', 'favorite'), 'organisation', 'organization'), 'licence', 'license'), 'Licence', 'License'), 'apologise', 'apologize'), 'recognise', 'recognize')::jsonb,
  green_flags = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(green_flags::text, 'hmrc-refund.co.uk', 'irs-refund.com'), 'hmrc.gov.uk', 'irs.gov'), 'my-barclays.secure-review.co.uk', 'my-chase.secure-review.com'), 'barclays-secure-login.com', 'chase-secure-login.com'), 'barclays.co.uk', 'chase.com'), 'royalmail-parcel.co.uk', 'usps-parcel.com'), 'nhs-verify.org', 'medicare-verify.org'), 'nhs.uk', 'medicare.gov'), 'amazon.co.uk', 'amazon.com'), 'paypal.co.uk', 'paypal.com'), 'boots.co.uk', 'cvs.com'), 'camden.gov.uk', 'camden.gov'), 'kestrel-access.co.uk', 'kestrel-access.com'), 'kestrel.co.uk', 'kestrel.com'), 'secure-review.co.uk', 'secure-review.com'), 'HM Revenue &amp; Customs', 'Internal Revenue Service'), 'HM Revenue & Customs', 'Internal Revenue Service'), 'HMRC', 'IRS'), 'BARCLAYS', 'CHASE'), 'Barclays', 'Chase'), 'Royal Mail', 'USPS'), 'NHS Digital', 'Medicare'), 'NHS', 'Medicare'), 'Boots', 'CVS'), 'council tax', 'property tax'), 'Council Tax', 'Property tax'), '.co.uk', '.com'), 'gov.uk', 'usa.gov'), '£', '$'), 'colour', 'color'), 'favourite', 'favorite'), 'organisation', 'organization'), 'licence', 'license'), 'Licence', 'License'), 'apologise', 'apologize'), 'recognise', 'recognize')::jsonb
WHERE locale = 'en-US';

-- en-US polish: 24u→12u tijden, US-telefoon/plaats/idioom, mum→mom.
UPDATE inbox_messages SET
  sender_name = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(sender_name, '020 7946 0123', '(212) 555-0123'), '020 7946 0555', '(212) 555-0177'), 'Premier Inn London County Hall', 'Hampton Inn Chicago Downtown'), 'Premier Inn', 'Hampton Inn'), 'London County Hall', 'Chicago Downtown'), 'London, United Kingdom', 'Chicago, United States'), '12 High Street, London', '12 Main Street, Chicago, IL'), 'High Street', 'Main Street'), 'Oakwood Surgery', 'Oakwood Family Clinic'), 'ready to collect', 'ready for pickup'), 'collection slip', 'pickup slip'), 'rearrange', 'reschedule'), 'working days', 'business days'), 'New holiday page', 'New time-off page'), 'holiday page', 'time-off page'), 'holiday', 'vacation'), '2025-2026 tax year', '2025 tax year'), '2025/2026 tax year', '2025 tax year'), 'Friday 15 May', 'Friday, May 15'), 'Sunday 17 May', 'Sunday, May 17'), '15 May', 'May 15'), '17 May', 'May 17'), '05:55', '5:55 AM'), '06:47', '6:47 AM'), '10:15', '10:15 AM'), '10:40', '10:40 AM'), '17:30', '5:30 PM'), '17:00', '5:00 PM'), '21:58', '9:58 PM'), '19:39', '7:39 PM'), '14:00', '2:00 PM'), '15:00', '3:00 PM'), '12:00', '12:00 PM'), '9:15', '9:15 AM'),
  sender_address = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(sender_address, '020 7946 0123', '(212) 555-0123'), '020 7946 0555', '(212) 555-0177'), 'Premier Inn London County Hall', 'Hampton Inn Chicago Downtown'), 'Premier Inn', 'Hampton Inn'), 'London County Hall', 'Chicago Downtown'), 'London, United Kingdom', 'Chicago, United States'), '12 High Street, London', '12 Main Street, Chicago, IL'), 'High Street', 'Main Street'), 'Oakwood Surgery', 'Oakwood Family Clinic'), 'ready to collect', 'ready for pickup'), 'collection slip', 'pickup slip'), 'rearrange', 'reschedule'), 'working days', 'business days'), 'New holiday page', 'New time-off page'), 'holiday page', 'time-off page'), 'holiday', 'vacation'), '2025-2026 tax year', '2025 tax year'), '2025/2026 tax year', '2025 tax year'), 'Friday 15 May', 'Friday, May 15'), 'Sunday 17 May', 'Sunday, May 17'), '15 May', 'May 15'), '17 May', 'May 17'), '05:55', '5:55 AM'), '06:47', '6:47 AM'), '10:15', '10:15 AM'), '10:40', '10:40 AM'), '17:30', '5:30 PM'), '17:00', '5:00 PM'), '21:58', '9:58 PM'), '19:39', '7:39 PM'), '14:00', '2:00 PM'), '15:00', '3:00 PM'), '12:00', '12:00 PM'), '9:15', '9:15 AM'),
  sender_note = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(sender_note, '020 7946 0123', '(212) 555-0123'), '020 7946 0555', '(212) 555-0177'), 'Premier Inn London County Hall', 'Hampton Inn Chicago Downtown'), 'Premier Inn', 'Hampton Inn'), 'London County Hall', 'Chicago Downtown'), 'London, United Kingdom', 'Chicago, United States'), '12 High Street, London', '12 Main Street, Chicago, IL'), 'High Street', 'Main Street'), 'Oakwood Surgery', 'Oakwood Family Clinic'), 'ready to collect', 'ready for pickup'), 'collection slip', 'pickup slip'), 'rearrange', 'reschedule'), 'working days', 'business days'), 'New holiday page', 'New time-off page'), 'holiday page', 'time-off page'), 'holiday', 'vacation'), '2025-2026 tax year', '2025 tax year'), '2025/2026 tax year', '2025 tax year'), 'Friday 15 May', 'Friday, May 15'), 'Sunday 17 May', 'Sunday, May 17'), '15 May', 'May 15'), '17 May', 'May 17'), '05:55', '5:55 AM'), '06:47', '6:47 AM'), '10:15', '10:15 AM'), '10:40', '10:40 AM'), '17:30', '5:30 PM'), '17:00', '5:00 PM'), '21:58', '9:58 PM'), '19:39', '7:39 PM'), '14:00', '2:00 PM'), '15:00', '3:00 PM'), '12:00', '12:00 PM'), '9:15', '9:15 AM'),
  subject = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(subject, '020 7946 0123', '(212) 555-0123'), '020 7946 0555', '(212) 555-0177'), 'Premier Inn London County Hall', 'Hampton Inn Chicago Downtown'), 'Premier Inn', 'Hampton Inn'), 'London County Hall', 'Chicago Downtown'), 'London, United Kingdom', 'Chicago, United States'), '12 High Street, London', '12 Main Street, Chicago, IL'), 'High Street', 'Main Street'), 'Oakwood Surgery', 'Oakwood Family Clinic'), 'ready to collect', 'ready for pickup'), 'collection slip', 'pickup slip'), 'rearrange', 'reschedule'), 'working days', 'business days'), 'New holiday page', 'New time-off page'), 'holiday page', 'time-off page'), 'holiday', 'vacation'), '2025-2026 tax year', '2025 tax year'), '2025/2026 tax year', '2025 tax year'), 'Friday 15 May', 'Friday, May 15'), 'Sunday 17 May', 'Sunday, May 17'), '15 May', 'May 15'), '17 May', 'May 17'), '05:55', '5:55 AM'), '06:47', '6:47 AM'), '10:15', '10:15 AM'), '10:40', '10:40 AM'), '17:30', '5:30 PM'), '17:00', '5:00 PM'), '21:58', '9:58 PM'), '19:39', '7:39 PM'), '14:00', '2:00 PM'), '15:00', '3:00 PM'), '12:00', '12:00 PM'), '9:15', '9:15 AM'),
  preview = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(preview, '020 7946 0123', '(212) 555-0123'), '020 7946 0555', '(212) 555-0177'), 'Premier Inn London County Hall', 'Hampton Inn Chicago Downtown'), 'Premier Inn', 'Hampton Inn'), 'London County Hall', 'Chicago Downtown'), 'London, United Kingdom', 'Chicago, United States'), '12 High Street, London', '12 Main Street, Chicago, IL'), 'High Street', 'Main Street'), 'Oakwood Surgery', 'Oakwood Family Clinic'), 'ready to collect', 'ready for pickup'), 'collection slip', 'pickup slip'), 'rearrange', 'reschedule'), 'working days', 'business days'), 'New holiday page', 'New time-off page'), 'holiday page', 'time-off page'), 'holiday', 'vacation'), '2025-2026 tax year', '2025 tax year'), '2025/2026 tax year', '2025 tax year'), 'Friday 15 May', 'Friday, May 15'), 'Sunday 17 May', 'Sunday, May 17'), '15 May', 'May 15'), '17 May', 'May 17'), '05:55', '5:55 AM'), '06:47', '6:47 AM'), '10:15', '10:15 AM'), '10:40', '10:40 AM'), '17:30', '5:30 PM'), '17:00', '5:00 PM'), '21:58', '9:58 PM'), '19:39', '7:39 PM'), '14:00', '2:00 PM'), '15:00', '3:00 PM'), '12:00', '12:00 PM'), '9:15', '9:15 AM'),
  body = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(body, '020 7946 0123', '(212) 555-0123'), '020 7946 0555', '(212) 555-0177'), 'Premier Inn London County Hall', 'Hampton Inn Chicago Downtown'), 'Premier Inn', 'Hampton Inn'), 'London County Hall', 'Chicago Downtown'), 'London, United Kingdom', 'Chicago, United States'), '12 High Street, London', '12 Main Street, Chicago, IL'), 'High Street', 'Main Street'), 'Oakwood Surgery', 'Oakwood Family Clinic'), 'ready to collect', 'ready for pickup'), 'collection slip', 'pickup slip'), 'rearrange', 'reschedule'), 'working days', 'business days'), 'New holiday page', 'New time-off page'), 'holiday page', 'time-off page'), 'holiday', 'vacation'), '2025-2026 tax year', '2025 tax year'), '2025/2026 tax year', '2025 tax year'), 'Friday 15 May', 'Friday, May 15'), 'Sunday 17 May', 'Sunday, May 17'), '15 May', 'May 15'), '17 May', 'May 17'), '05:55', '5:55 AM'), '06:47', '6:47 AM'), '10:15', '10:15 AM'), '10:40', '10:40 AM'), '17:30', '5:30 PM'), '17:00', '5:00 PM'), '21:58', '9:58 PM'), '19:39', '7:39 PM'), '14:00', '2:00 PM'), '15:00', '3:00 PM'), '12:00', '12:00 PM'), '9:15', '9:15 AM'),
  explanation = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(explanation, '020 7946 0123', '(212) 555-0123'), '020 7946 0555', '(212) 555-0177'), 'Premier Inn London County Hall', 'Hampton Inn Chicago Downtown'), 'Premier Inn', 'Hampton Inn'), 'London County Hall', 'Chicago Downtown'), 'London, United Kingdom', 'Chicago, United States'), '12 High Street, London', '12 Main Street, Chicago, IL'), 'High Street', 'Main Street'), 'Oakwood Surgery', 'Oakwood Family Clinic'), 'ready to collect', 'ready for pickup'), 'collection slip', 'pickup slip'), 'rearrange', 'reschedule'), 'working days', 'business days'), 'New holiday page', 'New time-off page'), 'holiday page', 'time-off page'), 'holiday', 'vacation'), '2025-2026 tax year', '2025 tax year'), '2025/2026 tax year', '2025 tax year'), 'Friday 15 May', 'Friday, May 15'), 'Sunday 17 May', 'Sunday, May 17'), '15 May', 'May 15'), '17 May', 'May 17'), '05:55', '5:55 AM'), '06:47', '6:47 AM'), '10:15', '10:15 AM'), '10:40', '10:40 AM'), '17:30', '5:30 PM'), '17:00', '5:00 PM'), '21:58', '9:58 PM'), '19:39', '7:39 PM'), '14:00', '2:00 PM'), '15:00', '3:00 PM'), '12:00', '12:00 PM'), '9:15', '9:15 AM'),
  links = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(links::text, '020 7946 0123', '(212) 555-0123'), '020 7946 0555', '(212) 555-0177'), 'Premier Inn London County Hall', 'Hampton Inn Chicago Downtown'), 'Premier Inn', 'Hampton Inn'), 'London County Hall', 'Chicago Downtown'), 'London, United Kingdom', 'Chicago, United States'), '12 High Street, London', '12 Main Street, Chicago, IL'), 'High Street', 'Main Street'), 'Oakwood Surgery', 'Oakwood Family Clinic'), 'ready to collect', 'ready for pickup'), 'collection slip', 'pickup slip'), 'rearrange', 'reschedule'), 'working days', 'business days'), 'New holiday page', 'New time-off page'), 'holiday page', 'time-off page'), 'holiday', 'vacation'), '2025-2026 tax year', '2025 tax year'), '2025/2026 tax year', '2025 tax year'), 'Friday 15 May', 'Friday, May 15'), 'Sunday 17 May', 'Sunday, May 17'), '15 May', 'May 15'), '17 May', 'May 17'), '05:55', '5:55 AM'), '06:47', '6:47 AM'), '10:15', '10:15 AM'), '10:40', '10:40 AM'), '17:30', '5:30 PM'), '17:00', '5:00 PM'), '21:58', '9:58 PM'), '19:39', '7:39 PM'), '14:00', '2:00 PM'), '15:00', '3:00 PM'), '12:00', '12:00 PM'), '9:15', '9:15 AM')::jsonb,
  red_flags = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(red_flags::text, '020 7946 0123', '(212) 555-0123'), '020 7946 0555', '(212) 555-0177'), 'Premier Inn London County Hall', 'Hampton Inn Chicago Downtown'), 'Premier Inn', 'Hampton Inn'), 'London County Hall', 'Chicago Downtown'), 'London, United Kingdom', 'Chicago, United States'), '12 High Street, London', '12 Main Street, Chicago, IL'), 'High Street', 'Main Street'), 'Oakwood Surgery', 'Oakwood Family Clinic'), 'ready to collect', 'ready for pickup'), 'collection slip', 'pickup slip'), 'rearrange', 'reschedule'), 'working days', 'business days'), 'New holiday page', 'New time-off page'), 'holiday page', 'time-off page'), 'holiday', 'vacation'), '2025-2026 tax year', '2025 tax year'), '2025/2026 tax year', '2025 tax year'), 'Friday 15 May', 'Friday, May 15'), 'Sunday 17 May', 'Sunday, May 17'), '15 May', 'May 15'), '17 May', 'May 17'), '05:55', '5:55 AM'), '06:47', '6:47 AM'), '10:15', '10:15 AM'), '10:40', '10:40 AM'), '17:30', '5:30 PM'), '17:00', '5:00 PM'), '21:58', '9:58 PM'), '19:39', '7:39 PM'), '14:00', '2:00 PM'), '15:00', '3:00 PM'), '12:00', '12:00 PM'), '9:15', '9:15 AM')::jsonb,
  green_flags = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(green_flags::text, '020 7946 0123', '(212) 555-0123'), '020 7946 0555', '(212) 555-0177'), 'Premier Inn London County Hall', 'Hampton Inn Chicago Downtown'), 'Premier Inn', 'Hampton Inn'), 'London County Hall', 'Chicago Downtown'), 'London, United Kingdom', 'Chicago, United States'), '12 High Street, London', '12 Main Street, Chicago, IL'), 'High Street', 'Main Street'), 'Oakwood Surgery', 'Oakwood Family Clinic'), 'ready to collect', 'ready for pickup'), 'collection slip', 'pickup slip'), 'rearrange', 'reschedule'), 'working days', 'business days'), 'New holiday page', 'New time-off page'), 'holiday page', 'time-off page'), 'holiday', 'vacation'), '2025-2026 tax year', '2025 tax year'), '2025/2026 tax year', '2025 tax year'), 'Friday 15 May', 'Friday, May 15'), 'Sunday 17 May', 'Sunday, May 17'), '15 May', 'May 15'), '17 May', 'May 17'), '05:55', '5:55 AM'), '06:47', '6:47 AM'), '10:15', '10:15 AM'), '10:40', '10:40 AM'), '17:30', '5:30 PM'), '17:00', '5:00 PM'), '21:58', '9:58 PM'), '19:39', '7:39 PM'), '14:00', '2:00 PM'), '15:00', '3:00 PM'), '12:00', '12:00 PM'), '9:15', '9:15 AM')::jsonb
WHERE locale = 'en-US';

UPDATE inbox_messages SET
  subject = regexp_replace(regexp_replace(subject, '\ymum\y','mom','g'), '\yMum\y','Mom','g'),
  preview = regexp_replace(regexp_replace(preview, '\ymum\y','mom','g'), '\yMum\y','Mom','g'),
  body = regexp_replace(regexp_replace(body, '\ymum\y','mom','g'), '\yMum\y','Mom','g')
WHERE locale = 'en-US';

UPDATE examples SET
  sender = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(sender, '020 7946 0123', '(212) 555-0123'), '020 7946 0555', '(212) 555-0177'), 'Premier Inn London County Hall', 'Hampton Inn Chicago Downtown'), 'Premier Inn', 'Hampton Inn'), 'London County Hall', 'Chicago Downtown'), 'London, United Kingdom', 'Chicago, United States'), '12 High Street, London', '12 Main Street, Chicago, IL'), 'High Street', 'Main Street'), 'Oakwood Surgery', 'Oakwood Family Clinic'), 'ready to collect', 'ready for pickup'), 'collection slip', 'pickup slip'), 'rearrange', 'reschedule'), 'working days', 'business days'), 'New holiday page', 'New time-off page'), 'holiday page', 'time-off page'), 'holiday', 'vacation'), '2025-2026 tax year', '2025 tax year'), '2025/2026 tax year', '2025 tax year'), 'Friday 15 May', 'Friday, May 15'), 'Sunday 17 May', 'Sunday, May 17'), '15 May', 'May 15'), '17 May', 'May 17'), '05:55', '5:55 AM'), '06:47', '6:47 AM'), '10:15', '10:15 AM'), '10:40', '10:40 AM'), '17:30', '5:30 PM'), '17:00', '5:00 PM'), '21:58', '9:58 PM'), '19:39', '7:39 PM'), '14:00', '2:00 PM'), '15:00', '3:00 PM'), '12:00', '12:00 PM'), '9:15', '9:15 AM'),
  subject = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(subject, '020 7946 0123', '(212) 555-0123'), '020 7946 0555', '(212) 555-0177'), 'Premier Inn London County Hall', 'Hampton Inn Chicago Downtown'), 'Premier Inn', 'Hampton Inn'), 'London County Hall', 'Chicago Downtown'), 'London, United Kingdom', 'Chicago, United States'), '12 High Street, London', '12 Main Street, Chicago, IL'), 'High Street', 'Main Street'), 'Oakwood Surgery', 'Oakwood Family Clinic'), 'ready to collect', 'ready for pickup'), 'collection slip', 'pickup slip'), 'rearrange', 'reschedule'), 'working days', 'business days'), 'New holiday page', 'New time-off page'), 'holiday page', 'time-off page'), 'holiday', 'vacation'), '2025-2026 tax year', '2025 tax year'), '2025/2026 tax year', '2025 tax year'), 'Friday 15 May', 'Friday, May 15'), 'Sunday 17 May', 'Sunday, May 17'), '15 May', 'May 15'), '17 May', 'May 17'), '05:55', '5:55 AM'), '06:47', '6:47 AM'), '10:15', '10:15 AM'), '10:40', '10:40 AM'), '17:30', '5:30 PM'), '17:00', '5:00 PM'), '21:58', '9:58 PM'), '19:39', '7:39 PM'), '14:00', '2:00 PM'), '15:00', '3:00 PM'), '12:00', '12:00 PM'), '9:15', '9:15 AM'),
  body = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(body, '020 7946 0123', '(212) 555-0123'), '020 7946 0555', '(212) 555-0177'), 'Premier Inn London County Hall', 'Hampton Inn Chicago Downtown'), 'Premier Inn', 'Hampton Inn'), 'London County Hall', 'Chicago Downtown'), 'London, United Kingdom', 'Chicago, United States'), '12 High Street, London', '12 Main Street, Chicago, IL'), 'High Street', 'Main Street'), 'Oakwood Surgery', 'Oakwood Family Clinic'), 'ready to collect', 'ready for pickup'), 'collection slip', 'pickup slip'), 'rearrange', 'reschedule'), 'working days', 'business days'), 'New holiday page', 'New time-off page'), 'holiday page', 'time-off page'), 'holiday', 'vacation'), '2025-2026 tax year', '2025 tax year'), '2025/2026 tax year', '2025 tax year'), 'Friday 15 May', 'Friday, May 15'), 'Sunday 17 May', 'Sunday, May 17'), '15 May', 'May 15'), '17 May', 'May 17'), '05:55', '5:55 AM'), '06:47', '6:47 AM'), '10:15', '10:15 AM'), '10:40', '10:40 AM'), '17:30', '5:30 PM'), '17:00', '5:00 PM'), '21:58', '9:58 PM'), '19:39', '7:39 PM'), '14:00', '2:00 PM'), '15:00', '3:00 PM'), '12:00', '12:00 PM'), '9:15', '9:15 AM'),
  annotations = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(annotations::text, '020 7946 0123', '(212) 555-0123'), '020 7946 0555', '(212) 555-0177'), 'Premier Inn London County Hall', 'Hampton Inn Chicago Downtown'), 'Premier Inn', 'Hampton Inn'), 'London County Hall', 'Chicago Downtown'), 'London, United Kingdom', 'Chicago, United States'), '12 High Street, London', '12 Main Street, Chicago, IL'), 'High Street', 'Main Street'), 'Oakwood Surgery', 'Oakwood Family Clinic'), 'ready to collect', 'ready for pickup'), 'collection slip', 'pickup slip'), 'rearrange', 'reschedule'), 'working days', 'business days'), 'New holiday page', 'New time-off page'), 'holiday page', 'time-off page'), 'holiday', 'vacation'), '2025-2026 tax year', '2025 tax year'), '2025/2026 tax year', '2025 tax year'), 'Friday 15 May', 'Friday, May 15'), 'Sunday 17 May', 'Sunday, May 17'), '15 May', 'May 15'), '17 May', 'May 17'), '05:55', '5:55 AM'), '06:47', '6:47 AM'), '10:15', '10:15 AM'), '10:40', '10:40 AM'), '17:30', '5:30 PM'), '17:00', '5:00 PM'), '21:58', '9:58 PM'), '19:39', '7:39 PM'), '14:00', '2:00 PM'), '15:00', '3:00 PM'), '12:00', '12:00 PM'), '9:15', '9:15 AM')::jsonb
WHERE locale = 'en-US';

-- en-US polish 2: Amerikaanse afsluitingen/termen.
UPDATE inbox_messages SET
  sender_name = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(sender_name, 'Kind regards', 'Best regards'), 'Yours faithfully', 'Sincerely'), 'Yours sincerely', 'Sincerely'), 'Personal Tax Account', 'online IRS account'), 'by post', 'by mail'), 'usa.gov', 'irs.gov'), 'cancelled', 'canceled'), 'Cancelled', 'Canceled'), 'mobile phone', 'cell phone'), 'mobile number', 'cell number'), 'your mobile', 'your cell'),
  sender_note = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(sender_note, 'Kind regards', 'Best regards'), 'Yours faithfully', 'Sincerely'), 'Yours sincerely', 'Sincerely'), 'Personal Tax Account', 'online IRS account'), 'by post', 'by mail'), 'usa.gov', 'irs.gov'), 'cancelled', 'canceled'), 'Cancelled', 'Canceled'), 'mobile phone', 'cell phone'), 'mobile number', 'cell number'), 'your mobile', 'your cell'),
  subject = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(subject, 'Kind regards', 'Best regards'), 'Yours faithfully', 'Sincerely'), 'Yours sincerely', 'Sincerely'), 'Personal Tax Account', 'online IRS account'), 'by post', 'by mail'), 'usa.gov', 'irs.gov'), 'cancelled', 'canceled'), 'Cancelled', 'Canceled'), 'mobile phone', 'cell phone'), 'mobile number', 'cell number'), 'your mobile', 'your cell'),
  preview = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(preview, 'Kind regards', 'Best regards'), 'Yours faithfully', 'Sincerely'), 'Yours sincerely', 'Sincerely'), 'Personal Tax Account', 'online IRS account'), 'by post', 'by mail'), 'usa.gov', 'irs.gov'), 'cancelled', 'canceled'), 'Cancelled', 'Canceled'), 'mobile phone', 'cell phone'), 'mobile number', 'cell number'), 'your mobile', 'your cell'),
  body = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(body, 'Kind regards', 'Best regards'), 'Yours faithfully', 'Sincerely'), 'Yours sincerely', 'Sincerely'), 'Personal Tax Account', 'online IRS account'), 'by post', 'by mail'), 'usa.gov', 'irs.gov'), 'cancelled', 'canceled'), 'Cancelled', 'Canceled'), 'mobile phone', 'cell phone'), 'mobile number', 'cell number'), 'your mobile', 'your cell'),
  explanation = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(explanation, 'Kind regards', 'Best regards'), 'Yours faithfully', 'Sincerely'), 'Yours sincerely', 'Sincerely'), 'Personal Tax Account', 'online IRS account'), 'by post', 'by mail'), 'usa.gov', 'irs.gov'), 'cancelled', 'canceled'), 'Cancelled', 'Canceled'), 'mobile phone', 'cell phone'), 'mobile number', 'cell number'), 'your mobile', 'your cell'),
  links = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(links::text, 'Kind regards', 'Best regards'), 'Yours faithfully', 'Sincerely'), 'Yours sincerely', 'Sincerely'), 'Personal Tax Account', 'online IRS account'), 'by post', 'by mail'), 'usa.gov', 'irs.gov'), 'cancelled', 'canceled'), 'Cancelled', 'Canceled'), 'mobile phone', 'cell phone'), 'mobile number', 'cell number'), 'your mobile', 'your cell')::jsonb,
  red_flags = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(red_flags::text, 'Kind regards', 'Best regards'), 'Yours faithfully', 'Sincerely'), 'Yours sincerely', 'Sincerely'), 'Personal Tax Account', 'online IRS account'), 'by post', 'by mail'), 'usa.gov', 'irs.gov'), 'cancelled', 'canceled'), 'Cancelled', 'Canceled'), 'mobile phone', 'cell phone'), 'mobile number', 'cell number'), 'your mobile', 'your cell')::jsonb,
  green_flags = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(green_flags::text, 'Kind regards', 'Best regards'), 'Yours faithfully', 'Sincerely'), 'Yours sincerely', 'Sincerely'), 'Personal Tax Account', 'online IRS account'), 'by post', 'by mail'), 'usa.gov', 'irs.gov'), 'cancelled', 'canceled'), 'Cancelled', 'Canceled'), 'mobile phone', 'cell phone'), 'mobile number', 'cell number'), 'your mobile', 'your cell')::jsonb
WHERE locale = 'en-US';

UPDATE examples SET
  body = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(body, 'Kind regards', 'Best regards'), 'Yours faithfully', 'Sincerely'), 'Yours sincerely', 'Sincerely'), 'Personal Tax Account', 'online IRS account'), 'by post', 'by mail'), 'usa.gov', 'irs.gov'), 'cancelled', 'canceled'), 'Cancelled', 'Canceled'), 'mobile phone', 'cell phone'), 'mobile number', 'cell number'), 'your mobile', 'your cell'),
  annotations = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(annotations::text, 'Kind regards', 'Best regards'), 'Yours faithfully', 'Sincerely'), 'Yours sincerely', 'Sincerely'), 'Personal Tax Account', 'online IRS account'), 'by post', 'by mail'), 'usa.gov', 'irs.gov'), 'cancelled', 'canceled'), 'Cancelled', 'Canceled'), 'mobile phone', 'cell phone'), 'mobile number', 'cell number'), 'your mobile', 'your cell')::jsonb
WHERE locale = 'en-US';

-- en-US brand conversion: O2 → AT&T for SMS telecom phishing (sort 364)
UPDATE inbox_messages SET
  sender_name = REPLACE(sender_name, 'O2', 'AT&T'),
  sender_note = REPLACE(REPLACE(sender_note, 'O2 sends bills by email or through the My O2 app — never as a payment link in a text.', 'AT&T sends bills by email or through the myAT&T app — never as a payment link in a text.'), 'O2', 'AT&T'),
  body = REPLACE(REPLACE(REPLACE(body, 'O2: your March bill of £35.00 is ready. Pay before 31 March via {{link:0}} to avoid suspension of your service.', 'AT&T: your March bill of $35.00 is ready. Pay before March 31 via {{link:0}} to avoid suspension of your service.'), 'O2', 'AT&T'), '£', '$'),
  preview = REPLACE(REPLACE(preview, 'O2', 'AT&T'), '£', '$'),
  subject = REPLACE(subject, 'O2', 'AT&T'),
  links = REPLACE(REPLACE(REPLACE(links::text, 'o2-invoices.com', 'att-invoices.com'), 'my.o2.co.uk', 'myatt.com'), 'O2', 'AT&T')::jsonb,
  red_flags = REPLACE(REPLACE(REPLACE(red_flags::text, 'o2-invoices.com', 'att-invoices.com'), 'my.o2.co.uk', 'myatt.com'), 'O2', 'AT&T')::jsonb,
  explanation = REPLACE(REPLACE(REPLACE(explanation, 'O2 sends bill notifications by email or through the My O2 app — never as a payment link in a text. Always log in at my.o2.co.uk to view your bill.', 'AT&T sends bill notifications by email or through the myAT&T app — never as a payment link in a text. Always log in at myatt.com to view your bill.'), 'O2', 'AT&T'), 'my.o2.co.uk', 'myatt.com')
WHERE locale = 'en-US' AND channel = 'sms' AND sort_order = 364;
