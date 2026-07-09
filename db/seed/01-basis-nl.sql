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


