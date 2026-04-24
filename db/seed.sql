-- Seed data: realistische voorbeelden van phishing en echte berichten,
-- in vier talen (nl, en, fr, de). Elke taal gebruikt organisaties die voor
-- dat land herkenbaar zijn (NL: ING/Belastingdienst, UK: Barclays/HMRC,
-- FR: Crédit Agricole/Impôts, DE: Sparkasse/Finanzamt, ...).
-- Verwijder eerst bestaande rijen zodat seed herhaalbaar is.

TRUNCATE quiz_answers, quiz_attempts, quiz_questions, examples,
         inbox_judgments, inbox_messages
         RESTART IDENTITY CASCADE;

-- ============ VOORBEELDEN (geannoteerd) ============

INSERT INTO examples (channel, sender, subject, body, annotations, sort_order) VALUES
('email',
 'ING Service <service@ing-betaling-secure.com>',
 'Belangrijk: uw rekening wordt geblokkeerd',
 E'Geachte klant,\n\nWij hebben een verdachte transactie op uw rekening opgemerkt. Binnen 24 uur wordt uw rekening GEBLOKKEERD als u uw gegevens niet bevestigt.\n\nKlik hier om uw rekening te beveiligen: http://ing-beveiliging.net/login\n\nMet vriendelijke groet,\nING Beveiligingsteam',
 '[
   {"quote": "service@ing-betaling-secure.com", "note": "Kijk naar wat NA de @ staat: ing-betaling-secure.com. Dat is niet ING. De echte ING gebruikt altijd @ing.nl. Het deel vóór de @ (\"service\") mag de oplichter zelf verzinnen."},
   {"quote": "GEBLOKKEERD als u uw gegevens niet bevestigt", "note": "Angst maken en haast. Een echte bank doet dit nooit."},
   {"quote": "Geachte klant", "note": "Geen naam. Uw bank kent uw naam."},
   {"quote": "http://ing-beveiliging.net/login", "note": "Vreemde link die niet van ING is. Niet op klikken!"}
 ]'::jsonb,
 10),

('email',
 'Belastingdienst <noreply@belasting-teruggave.nl>',
 'U heeft recht op € 423,50 teruggave',
 E'Beste burger,\n\nNa controle blijkt u recht te hebben op een belastingteruggave van € 423,50. Vul snel uw gegevens in om het bedrag te ontvangen.\n\nKlik hier: http://belasting-teruggave.nl/claim\n\nBelastingdienst',
 '[
   {"quote": "noreply@belasting-teruggave.nl", "note": "Kijk na de @: belasting-teruggave.nl. Dat is NIET de Belastingdienst. Het echte domein is belastingdienst.nl."},
   {"quote": "Beste burger", "note": "Algemene aanhef zonder uw naam. De Belastingdienst weet wie u bent."},
   {"quote": "recht te hebben op een belastingteruggave van € 423,50", "note": "Belofte van geld is een klassieke lokker. De Belastingdienst mailt nooit over teruggaven."},
   {"quote": "http://belasting-teruggave.nl/claim", "note": "Vreemde link, niet mijn.belastingdienst.nl. Niet op klikken."}
 ]'::jsonb,
 20),

('email',
 'DigiD <info@digid-controle.org>',
 'Bevestig uw DigiD-gegevens',
 E'Geachte heer/mevrouw,\n\nWij vragen u om uw DigiD opnieuw te bevestigen. Klik op onderstaande link en log in met uw gebruikersnaam en wachtwoord.\n\nhttp://digid-controle.org/inloggen\n\nBedankt,\nDigiD',
 '[
   {"quote": "info@digid-controle.org", "note": "Kijk na de @: digid-controle.org. Het echte domein is digid.nl — niets anders."},
   {"quote": "Geachte heer/mevrouw", "note": "Algemene aanhef. Een echte organisatie kent uw naam."},
   {"quote": "log in met uw gebruikersnaam en wachtwoord", "note": "DigiD vraagt NOOIT per e-mail om uw wachtwoord. Altijd phishing."},
   {"quote": "http://digid-controle.org/inloggen", "note": "Vreemde link. Open DigiD alleen via digid.nl of de officiële app."}
 ]'::jsonb,
 30);

-- (De `quiz_questions`-tabel blijft in het schema bestaan voor toekomstig
-- gebruik, maar wordt niet meer gevuld: de simulator draait op
-- `inbox_messages`.)

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
 E'Geachte klant,\n\nWij hebben een verdachte transactie opgemerkt op uw rekening. Om misbruik te voorkomen wordt uw rekening binnen 24 uur GEBLOKKEERD als u uw gegevens niet bevestigt.\n\nBevestig direct via {{link:0}}.\n\nMet vriendelijke groet,\nING Beveiligingsteam',
 '[{"label":"deze beveiligde pagina","real_url":"http://ing-beveiliging.net/login","suspicious":true,"warning":"Deze link gaat NIET naar ing.nl maar naar ing-beveiliging.net. Dat is een nep-website die op ING lijkt."}]'::jsonb,
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
 E'Beste burger,\n\nNa controle blijkt u recht te hebben op een belastingteruggave van € 423,50.\n\nVul uw gegevens in om het bedrag binnen 3 werkdagen te ontvangen: {{link:0}}.\n\nBelastingdienst',
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
 E'Beste klant,\n\nUw pakket wacht op het distributiecentrum. Er zijn nog onbetaalde invoerkosten (€ 1,95).\n\nBetaal direct om uitgesteld te voorkomen: {{link:0}}\n\nPostNL',
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
 E'Geachte heer/mevrouw,\n\nIn verband met een veiligheidscontrole vragen wij u uw DigiD opnieuw te bevestigen.\n\nLog in via {{link:0}} en vul uw gebruikersnaam en wachtwoord in.\n\nBedankt,\nDigiD',
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
 E'Beste mevrouw Janssen,\n\nUw KPN-factuur van € 49,95 over de maand april staat klaar in MijnKPN.\n\nU kunt de factuur bekijken door zelf in te loggen op kpn.com/mijnkpn (typ dit adres zelf in uw browser of gebruik de MijnKPN-app).\n\nHet bedrag wordt op 1 mei automatisch van uw rekening afgeschreven.\n\nKPN Klantenservice',
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
 E'Beste gebruiker,\n\nUw Microsoft-account is tijdelijk geblokkeerd wegens verdachte inlogpogingen vanuit Rusland.\n\nAls u uw account niet binnen 12 uur ontgrendelt, verliest u al uw bestanden.\n\nOntgrendel uw account: {{link:0}}',
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
 E'Beste klant,\n\nGefeliciteerd! U bent uit duizenden deelnemers getrokken als onze winnaar van een gloednieuwe iPhone 15.\n\nClaim uw prijs binnen 2 uur door een kleine verzendbijdrage te betalen: {{link:0}}\n\nBol.com Winactie Team',
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
 '[
   {"quote": "service@barclays-secure-login.com", "note": "Look at what comes AFTER the @: barclays-secure-login.com. That is not Barclays. Real Barclays always uses @barclays.co.uk. The part BEFORE the @ (\"service\") can be anything the scammer wants."},
   {"quote": "BLOCKED within 24 hours unless you confirm your details", "note": "Creating fear and urgency. A real bank never does this."},
   {"quote": "Dear customer", "note": "No name. Your bank knows your name."},
   {"quote": "http://barclays-secure-login.com/verify", "note": "Odd link that is not from Barclays. Do not click!"}
 ]'::jsonb,
 10),

('en', 'email',
 'HMRC <noreply@hmrc-refund.co.uk>',
 'You are entitled to a £423.50 tax refund',
 E'Dear taxpayer,\n\nAfter a review, you are entitled to a tax refund of £423.50. Please fill in your details quickly to receive the amount.\n\nClick here: http://hmrc-refund.co.uk/claim\n\nHMRC',
 '[
   {"quote": "noreply@hmrc-refund.co.uk", "note": "Look after the @: hmrc-refund.co.uk. That is NOT HMRC. The real HMRC domain is hmrc.gov.uk."},
   {"quote": "Dear taxpayer", "note": "Generic greeting without your name. HMRC addresses you by name."},
   {"quote": "entitled to a tax refund of £423.50", "note": "A promise of money is a classic bait. HMRC never emails to announce refunds with a link."},
   {"quote": "http://hmrc-refund.co.uk/claim", "note": "Odd link, not gov.uk. Do not click."}
 ]'::jsonb,
 20),

('en', 'email',
 'NHS login <info@nhs-verify.org>',
 'Please confirm your NHS login details',
 E'Dear Sir/Madam,\n\nWe kindly ask you to confirm your NHS login details. Click the link below and sign in with your username and password.\n\nhttp://nhs-verify.org/signin\n\nThank you,\nNHS Digital',
 '[
   {"quote": "info@nhs-verify.org", "note": "Look after the @: nhs-verify.org. The real domain is nhs.uk — nothing else."},
   {"quote": "Dear Sir/Madam", "note": "Generic greeting. A real organisation knows your name."},
   {"quote": "sign in with your username and password", "note": "The NHS NEVER asks for your password by email. Always phishing."},
   {"quote": "http://nhs-verify.org/signin", "note": "Odd link. Only open NHS services via nhs.uk or the official NHS app."}
 ]'::jsonb,
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
 E'Dear customer,\n\nWe have noticed a suspicious transaction on your account. To prevent misuse, your account will be BLOCKED within 24 hours unless you confirm your details.\n\nConfirm straight away via {{link:0}}.\n\nKind regards,\nBarclays Security Team',
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
 E'Dear taxpayer,\n\nAfter a review, you are entitled to a tax refund of £423.50.\n\nFill in your details to receive the amount within 3 working days: {{link:0}}.\n\nHMRC',
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
 E'Dear customer,\n\nYour parcel is waiting at the depot. There is an outstanding customs fee (£1.95).\n\nPay now to avoid a delay: {{link:0}}\n\nRoyal Mail',
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
 E'Dear Sir/Madam,\n\nFor a security check, we ask you to re-confirm your Gov.uk details.\n\nSign in via {{link:0}} and enter your username and password.\n\nThank you,\nGOV.UK',
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
 E'Dear Ms Smith,\n\nYour BT bill of £49.95 for April is ready in MyBT.\n\nYou can view the bill by signing in yourself at bt.com/mybt (type the address in your browser yourself or use the MyBT app).\n\nThe amount will be taken automatically on 1 May.\n\nBT Customer Service',
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
 E'Dear user,\n\nYour Microsoft account has been temporarily blocked due to suspicious sign-in attempts from Russia.\n\nIf you do not unlock your account within 12 hours, you will lose all your files.\n\nUnlock your account: {{link:0}}',
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
 E'Dear customer,\n\nCongratulations! You have been drawn from thousands of entrants as the winner of a brand-new iPhone 15.\n\nClaim your prize within 2 hours by paying a small postage fee: {{link:0}}\n\nAmazon Prize Draw Team',
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
 '[
   {"quote": "service@credit-agricole-securite.com", "note": "Regardez ce qui vient APRÈS le @ : credit-agricole-securite.com. Ce n''est pas le Crédit Agricole. Le vrai Crédit Agricole utilise toujours @credit-agricole.fr. Ce qui est AVANT le @ (« service ») peut être choisi par l''escroc."},
   {"quote": "BLOQUÉ sous 24 heures si vous ne confirmez pas vos informations", "note": "On vous fait peur et on vous presse. Une vraie banque ne fait jamais cela."},
   {"quote": "Cher client", "note": "Pas de nom. Votre banque connaît votre nom."},
   {"quote": "http://credit-agricole-securite.com/verifier", "note": "Lien étrange qui n''est pas du Crédit Agricole. Ne cliquez pas !"}
 ]'::jsonb,
 10),

('fr', 'email',
 'Impôts <noreply@impots-remboursement.fr>',
 'Vous avez droit à un remboursement de 423,50 €',
 E'Cher contribuable,\n\nAprès vérification, vous avez droit à un remboursement d''impôts de 423,50 €. Remplissez vite vos informations pour recevoir le montant.\n\nCliquez ici : http://impots-remboursement.fr/reclamer\n\nDirection Générale des Finances Publiques',
 '[
   {"quote": "noreply@impots-remboursement.fr", "note": "Regardez après le @ : impots-remboursement.fr. Ce n''est PAS la DGFiP. Le vrai domaine est dgfip.finances.gouv.fr."},
   {"quote": "Cher contribuable", "note": "Salutation générique sans votre nom. La DGFiP connaît votre identité."},
   {"quote": "droit à un remboursement d''impôts de 423,50 €", "note": "La promesse d''argent est un appât classique. Les impôts ne communiquent jamais un remboursement par e-mail avec un lien."},
   {"quote": "http://impots-remboursement.fr/reclamer", "note": "Lien étrange, ce n''est pas impots.gouv.fr. Ne cliquez pas."}
 ]'::jsonb,
 20),

('fr', 'email',
 'Ameli <info@ameli-controle.org>',
 'Confirmez vos informations Ameli',
 E'Madame, Monsieur,\n\nNous vous demandons de confirmer à nouveau vos informations Ameli. Cliquez sur le lien ci-dessous et connectez-vous avec votre identifiant et votre mot de passe.\n\nhttp://ameli-controle.org/connexion\n\nMerci,\nAssurance Maladie',
 '[
   {"quote": "info@ameli-controle.org", "note": "Regardez après le @ : ameli-controle.org. Le vrai domaine est ameli.fr — rien d''autre."},
   {"quote": "Madame, Monsieur", "note": "Salutation générique. Une vraie organisation connaît votre nom."},
   {"quote": "connectez-vous avec votre identifiant et votre mot de passe", "note": "Ameli ne demande JAMAIS votre mot de passe par e-mail. Toujours du hameçonnage."},
   {"quote": "http://ameli-controle.org/connexion", "note": "Lien étrange. Ouvrez Ameli uniquement via ameli.fr ou l''application officielle."}
 ]'::jsonb,
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
 E'Cher client,\n\nNous avons détecté une transaction suspecte sur votre compte. Pour éviter tout abus, votre compte sera BLOQUÉ sous 24 heures si vous ne confirmez pas vos informations.\n\nConfirmez immédiatement via {{link:0}}.\n\nCordialement,\nService Sécurité Crédit Agricole',
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
 E'Cher contribuable,\n\nAprès vérification, vous avez droit à un remboursement d''impôts de 423,50 €.\n\nRemplissez vos informations pour recevoir le montant sous 3 jours ouvrés : {{link:0}}.\n\nDirection Générale des Finances Publiques',
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
 E'Cher client,\n\nVotre colis est en attente au centre de distribution. Des frais de douane restent impayés (1,95 €).\n\nPayez immédiatement pour éviter un retard : {{link:0}}\n\nColissimo',
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
 E'Madame, Monsieur,\n\nDans le cadre d''un contrôle de sécurité, nous vous demandons de confirmer à nouveau vos informations Ameli.\n\nConnectez-vous via {{link:0}} et saisissez votre identifiant et votre mot de passe.\n\nMerci,\nAssurance Maladie',
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
 E'Chère Madame Dupont,\n\nVotre facture Orange de 49,95 € pour le mois d''avril est disponible dans votre espace client.\n\nVous pouvez consulter la facture en vous connectant vous-même à orange.fr/espace-client (tapez cette adresse vous-même dans votre navigateur ou utilisez l''application Orange et moi).\n\nLe montant sera prélevé automatiquement sur votre compte le 1er mai.\n\nService client Orange',
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
 E'Cher utilisateur,\n\nVotre compte Microsoft est temporairement bloqué suite à des tentatives de connexion suspectes depuis la Russie.\n\nSi vous ne déverrouillez pas votre compte dans les 12 heures, vous perdrez tous vos fichiers.\n\nDéverrouillez votre compte : {{link:0}}',
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
 E'Cher client,\n\nFélicitations ! Vous avez été tiré au sort parmi des milliers de participants comme notre gagnant d''un iPhone 15 flambant neuf.\n\nRéclamez votre prix sous 2 heures en payant une petite participation aux frais d''envoi : {{link:0}}\n\nÉquipe Amazon Tirage au sort',
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
 '[
   {"quote": "service@sparkasse-sicher-login.com", "note": "Achten Sie darauf, was NACH dem @ steht: sparkasse-sicher-login.com. Das ist nicht die Sparkasse. Die echte Sparkasse nutzt immer @sparkasse.de. Der Teil VOR dem @ („service“) kann vom Betrüger frei gewählt werden."},
   {"quote": "GESPERRT, wenn Sie Ihre Daten nicht bestätigen", "note": "Angst und Eile erzeugen. Eine echte Bank macht das nie."},
   {"quote": "Sehr geehrter Kunde", "note": "Kein Name. Ihre Bank kennt Ihren Namen."},
   {"quote": "http://sparkasse-sicher-login.com/verify", "note": "Verdächtiger Link, der nicht von der Sparkasse ist. Nicht anklicken!"}
 ]'::jsonb,
 10),

('de', 'email',
 'Finanzamt <noreply@finanzamt-erstattung.de>',
 'Sie haben Anspruch auf 423,50 € Rückerstattung',
 E'Sehr geehrter Steuerzahler,\n\nNach unserer Prüfung haben Sie Anspruch auf eine Steuererstattung in Höhe von 423,50 €. Geben Sie schnell Ihre Daten ein, um den Betrag zu erhalten.\n\nKlicken Sie hier: http://finanzamt-erstattung.de/anfordern\n\nFinanzamt',
 '[
   {"quote": "noreply@finanzamt-erstattung.de", "note": "Achten Sie auf den Teil nach dem @: finanzamt-erstattung.de. Das ist NICHT das Finanzamt. Echte Kommunikation läuft über @elster.de oder Briefpost."},
   {"quote": "Sehr geehrter Steuerzahler", "note": "Allgemeine Anrede ohne Ihren Namen. Das Finanzamt kennt Sie."},
   {"quote": "Anspruch auf eine Steuererstattung in Höhe von 423,50 €", "note": "Ein Geldversprechen ist ein klassischer Köder. Das Finanzamt kündigt Erstattungen nie per E-Mail mit Link an."},
   {"quote": "http://finanzamt-erstattung.de/anfordern", "note": "Verdächtiger Link, nicht elster.de. Nicht anklicken."}
 ]'::jsonb,
 20),

('de', 'email',
 'ELSTER <info@elster-sicher.org>',
 'Bitte bestätigen Sie Ihre ELSTER-Daten',
 E'Sehr geehrte Damen und Herren,\n\nWir bitten Sie, Ihre ELSTER-Daten erneut zu bestätigen. Klicken Sie auf den untenstehenden Link und melden Sie sich mit Ihrem Benutzernamen und Passwort an.\n\nhttp://elster-sicher.org/anmelden\n\nMit freundlichen Grüßen,\nELSTER',
 '[
   {"quote": "info@elster-sicher.org", "note": "Achten Sie auf den Teil nach dem @: elster-sicher.org. Die echte Domain ist elster.de — nichts anderes."},
   {"quote": "Sehr geehrte Damen und Herren", "note": "Allgemeine Anrede. Eine echte Organisation kennt Ihren Namen."},
   {"quote": "melden Sie sich mit Ihrem Benutzernamen und Passwort an", "note": "ELSTER fragt NIEMALS per E-Mail nach Ihrem Passwort. Immer Phishing."},
   {"quote": "http://elster-sicher.org/anmelden", "note": "Verdächtiger Link. Öffnen Sie ELSTER nur über elster.de oder die offizielle App."}
 ]'::jsonb,
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
 E'Sehr geehrter Kunde,\n\nWir haben eine verdächtige Transaktion auf Ihrem Konto festgestellt. Um Missbrauch zu verhindern, wird Ihr Konto innerhalb von 24 Stunden GESPERRT, wenn Sie Ihre Daten nicht bestätigen.\n\nBestätigen Sie sofort über {{link:0}}.\n\nMit freundlichen Grüßen,\nSparkasse Sicherheitsteam',
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
 E'Sehr geehrter Steuerzahler,\n\nNach unserer Prüfung haben Sie Anspruch auf eine Steuererstattung in Höhe von 423,50 €.\n\nGeben Sie Ihre Daten ein, um den Betrag innerhalb von 3 Werktagen zu erhalten: {{link:0}}.\n\nFinanzamt',
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
 E'Sehr geehrter Kunde,\n\nIhr Paket wartet im Verteilzentrum. Es gibt noch unbezahlte Zollgebühren (1,95 €).\n\nZahlen Sie sofort, um Verzögerungen zu vermeiden: {{link:0}}\n\nDHL',
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
 E'Sehr geehrte Damen und Herren,\n\nIm Rahmen einer Sicherheitsprüfung bitten wir Sie, Ihre ELSTER-Daten erneut zu bestätigen.\n\nMelden Sie sich über {{link:0}} an und geben Sie Ihren Benutzernamen und Ihr Passwort ein.\n\nMit freundlichen Grüßen,\nELSTER',
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
 E'Sehr geehrte Frau Müller,\n\nIhre Telekom-Rechnung über 49,95 € für den Monat April liegt in MeineTelekom bereit.\n\nSie können die Rechnung einsehen, indem Sie sich selbst unter telekom.de/meinetelekom anmelden (tippen Sie diese Adresse selbst in Ihren Browser oder nutzen Sie die MeineTelekom-App).\n\nDer Betrag wird am 1. Mai automatisch von Ihrem Konto abgebucht.\n\nTelekom Kundenservice',
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
 E'Sehr geehrter Nutzer,\n\nIhr Microsoft-Konto wurde wegen verdächtiger Anmeldeversuche aus Russland vorübergehend gesperrt.\n\nWenn Sie Ihr Konto nicht innerhalb von 12 Stunden entsperren, verlieren Sie alle Ihre Dateien.\n\nKonto entsperren: {{link:0}}',
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
 E'Sehr geehrter Kunde,\n\nHerzlichen Glückwunsch! Sie wurden aus Tausenden von Teilnehmern als Gewinner eines brandneuen iPhone 15 gezogen.\n\nFordern Sie Ihren Preis innerhalb von 2 Stunden an, indem Sie einen kleinen Versandbeitrag zahlen: {{link:0}}\n\nAmazon Gewinnspiel-Team',
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
 '[
   {"quote": "service@bnp-veilig-login.com", "note": "Kijk naar wat NA de @ staat: bnp-veilig-login.com. Dat is niet BNP Paribas Fortis. De echte bank gebruikt altijd @bnpparibasfortis.com. Het deel vóór de @ (\"service\") mag de oplichter zelf verzinnen."},
   {"quote": "GEBLOKKEERD als u uw gegevens niet bevestigt", "note": "Angst maken en haast. Een echte bank doet dit nooit."},
   {"quote": "Geachte klant", "note": "Geen naam. Uw bank kent uw naam."},
   {"quote": "http://bnp-veilig-login.com/login", "note": "Vreemde link die niet van BNP Paribas Fortis is. Niet op klikken!"}
 ]'::jsonb,
 10),

('nl-BE', 'email',
 'FOD Financiën <noreply@minfin-teruggave.be>',
 'U heeft recht op € 423,50 terugbetaling',
 E'Beste burger,\n\nNa controle blijkt u recht te hebben op een belastingteruggave van € 423,50. Vul snel uw gegevens in om het bedrag te ontvangen.\n\nKlik hier: http://minfin-teruggave.be/claim\n\nFOD Financiën',
 '[
   {"quote": "noreply@minfin-teruggave.be", "note": "Kijk na de @: minfin-teruggave.be. Dat is NIET de FOD Financiën. Het echte domein is minfin.fed.be."},
   {"quote": "Beste burger", "note": "Algemene aanspreking zonder uw naam. De FOD Financiën kent u."},
   {"quote": "recht te hebben op een belastingteruggave van € 423,50", "note": "Belofte van geld is een klassieke lokker. De FOD Financiën mailt nooit over teruggaven."},
   {"quote": "http://minfin-teruggave.be/claim", "note": "Vreemde link, niet myminfin.be. Niet op klikken."}
 ]'::jsonb,
 20),

('nl-BE', 'email',
 'itsme <info@itsme-controle.org>',
 'Bevestig uw itsme-gegevens',
 E'Geachte heer/mevrouw,\n\nWij vragen u om uw itsme opnieuw te bevestigen. Klik op onderstaande link en meld u aan met uw gebruikersnaam en paswoord.\n\nhttp://itsme-controle.org/aanmelden\n\nBedankt,\nitsme',
 '[
   {"quote": "info@itsme-controle.org", "note": "Kijk na de @: itsme-controle.org. Het echte domein is itsme.be — niets anders."},
   {"quote": "Geachte heer/mevrouw", "note": "Algemene aanspreking. Een echte organisatie kent uw naam."},
   {"quote": "meld u aan met uw gebruikersnaam en paswoord", "note": "itsme werkt via uw eigen app en vraagt NOOIT uw paswoord per e-mail. Altijd phishing."},
   {"quote": "http://itsme-controle.org/aanmelden", "note": "Vreemde link. Gebruik itsme alleen via de officiële app of via itsme.be."}
 ]'::jsonb,
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
 E'Geachte klant,\n\nWij hebben een verdachte transactie opgemerkt op uw rekening. Om misbruik te voorkomen wordt uw rekening binnen 24 uur GEBLOKKEERD als u uw gegevens niet bevestigt.\n\nBevestig onmiddellijk via {{link:0}}.\n\nMet vriendelijke groeten,\nBNP Paribas Fortis Beveiligingsteam',
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
 E'Beste burger,\n\nNa controle blijkt u recht te hebben op een belastingteruggave van € 423,50.\n\nVul uw gegevens in om het bedrag binnen 3 werkdagen te ontvangen: {{link:0}}.\n\nFOD Financiën',
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
 E'Beste klant,\n\nUw pakket wacht in het sorteercentrum. Er zijn nog onbetaalde invoerkosten (€ 1,95).\n\nBetaal onmiddellijk om uitstel te vermijden: {{link:0}}\n\nbpost',
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
 E'Geachte heer/mevrouw,\n\nIn verband met een veiligheidscontrole vragen wij u uw itsme opnieuw te bevestigen.\n\nMeld u aan via {{link:0}} en vul uw gebruikersnaam en paswoord in.\n\nBedankt,\nitsme',
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
 E'Beste mevrouw Peeters,\n\nUw Proximus-factuur van € 49,95 voor de maand april staat klaar in MyProximus.\n\nU kunt de factuur bekijken door zelf aan te melden op proximus.be/myproximus (typ dit adres zelf in uw browser of gebruik de MyProximus-app).\n\nHet bedrag wordt op 1 mei automatisch van uw rekening afgeschreven.\n\nProximus Klantendienst',
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
 E'Beste gebruiker,\n\nUw Microsoft-account is tijdelijk geblokkeerd wegens verdachte aanmeldpogingen vanuit Rusland.\n\nAls u uw account niet binnen 12 uur ontgrendelt, verliest u al uw bestanden.\n\nOntgrendel uw account: {{link:0}}',
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
 E'Beste klant,\n\nGefeliciteerd! U bent uit duizenden deelnemers getrokken als onze winnaar van een gloednieuwe iPhone 15.\n\nClaim uw prijs binnen 2 uur door een kleine verzendbijdrage te betalen: {{link:0}}\n\nBol.com Winactie Team',
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
 '[
   {"quote": "service@belfius-securise.com", "note": "Regardez ce qui vient APRÈS le @ : belfius-securise.com. Ce n''est pas Belfius. La vraie banque utilise toujours @belfius.be. Ce qui est AVANT le @ (« service ») peut être choisi par l''escroc."},
   {"quote": "BLOQUÉ sous 24 heures si vous ne confirmez pas vos informations", "note": "On vous fait peur et on vous presse. Une vraie banque ne fait jamais cela."},
   {"quote": "Cher client", "note": "Pas de nom. Votre banque connaît votre nom."},
   {"quote": "http://belfius-securise.com/verifier", "note": "Lien étrange qui n''est pas de Belfius. Ne cliquez pas !"}
 ]'::jsonb,
 10),

('fr-BE', 'email',
 'SPF Finances <noreply@minfin-remboursement.be>',
 'Vous avez droit à un remboursement de 423,50 €',
 E'Cher contribuable,\n\nAprès vérification, vous avez droit à un remboursement d''impôts de 423,50 €. Remplissez vite vos informations pour recevoir le montant.\n\nCliquez ici : http://minfin-remboursement.be/reclamer\n\nSPF Finances',
 '[
   {"quote": "noreply@minfin-remboursement.be", "note": "Regardez après le @ : minfin-remboursement.be. Ce n''est PAS le SPF Finances. Le vrai domaine est minfin.fed.be."},
   {"quote": "Cher contribuable", "note": "Salutation générique sans votre nom. Le SPF Finances connaît votre identité."},
   {"quote": "droit à un remboursement d''impôts de 423,50 €", "note": "La promesse d''argent est un appât classique. Le SPF Finances ne communique jamais un remboursement par e-mail avec un lien."},
   {"quote": "http://minfin-remboursement.be/reclamer", "note": "Lien étrange, ce n''est pas myminfin.be. Ne cliquez pas."}
 ]'::jsonb,
 20),

('fr-BE', 'email',
 'itsme <info@itsme-controle.org>',
 'Confirmez vos informations itsme',
 E'Madame, Monsieur,\n\nNous vous demandons de confirmer à nouveau vos informations itsme. Cliquez sur le lien ci-dessous et connectez-vous avec votre identifiant et votre mot de passe.\n\nhttp://itsme-controle.org/connexion\n\nMerci,\nitsme',
 '[
   {"quote": "info@itsme-controle.org", "note": "Regardez après le @ : itsme-controle.org. Le vrai domaine est itsme.be — rien d''autre."},
   {"quote": "Madame, Monsieur", "note": "Salutation générique. Une vraie organisation connaît votre nom."},
   {"quote": "connectez-vous avec votre identifiant et votre mot de passe", "note": "itsme fonctionne via votre application personnelle et ne demande JAMAIS votre mot de passe par e-mail. Toujours du hameçonnage."},
   {"quote": "http://itsme-controle.org/connexion", "note": "Lien étrange. Utilisez itsme uniquement via l''application officielle ou via itsme.be."}
 ]'::jsonb,
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
 E'Cher client,\n\nNous avons détecté une transaction suspecte sur votre compte. Pour éviter tout abus, votre compte sera BLOQUÉ sous 24 heures si vous ne confirmez pas vos informations.\n\nConfirmez immédiatement via {{link:0}}.\n\nCordialement,\nService Sécurité Belfius',
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
 E'Cher contribuable,\n\nAprès vérification, vous avez droit à un remboursement d''impôts de 423,50 €.\n\nRemplissez vos informations pour recevoir le montant sous 3 jours ouvrables : {{link:0}}.\n\nSPF Finances',
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
 E'Cher client,\n\nVotre colis est en attente au centre de tri. Des frais d''importation restent impayés (1,95 €).\n\nPayez immédiatement pour éviter un retard : {{link:0}}\n\nbpost',
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
 E'Madame, Monsieur,\n\nDans le cadre d''un contrôle de sécurité, nous vous demandons de confirmer à nouveau vos informations itsme.\n\nConnectez-vous via {{link:0}} et saisissez votre identifiant et votre mot de passe.\n\nMerci,\nitsme',
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
 E'Chère Madame Dubois,\n\nVotre facture Proximus de 49,95 € pour le mois d''avril est disponible dans MyProximus.\n\nVous pouvez consulter la facture en vous connectant vous-même à proximus.be/myproximus (tapez cette adresse vous-même dans votre navigateur ou utilisez l''application MyProximus).\n\nLe montant sera prélevé automatiquement sur votre compte le 1er mai.\n\nService client Proximus',
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
 E'Cher utilisateur,\n\nVotre compte Microsoft est temporairement bloqué suite à des tentatives de connexion suspectes depuis la Russie.\n\nSi vous ne déverrouillez pas votre compte dans les 12 heures, vous perdrez tous vos fichiers.\n\nDéverrouillez votre compte : {{link:0}}',
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
 E'Cher client,\n\nFélicitations ! Vous avez été tiré au sort parmi des milliers de participants comme notre gagnant d''un iPhone 15 flambant neuf.\n\nRéclamez votre prix sous 2 heures en payant une petite participation aux frais d''envoi : {{link:0}}\n\nÉquipe Bol.com Concours',
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
 E'Beste mevrouw Janssen,\n\nUw boeking bij Van der Valk Amsterdam is bevestigd:\n\n• Check-in: vrijdag 15 mei, vanaf 15:00\n• Check-out: zondag 17 mei, vóór 11:00\n• 1 tweepersoonskamer, 2 nachten\n• Totaal: € 248,00 (al voldaan)\n\nU kunt uw boeking bekijken of wijzigen via {{link:0}}.\n\nWe kijken ernaar uit u te mogen verwelkomen.\n\nBooking.com',
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
 E'Beste mevrouw Peeters,\n\nUw boeking bij Van der Valk Antwerpen is bevestigd:\n\n• Check-in: vrijdag 15 mei, vanaf 15u\n• Check-out: zondag 17 mei, vóór 11u\n• 1 tweepersoonskamer, 2 nachten\n• Totaal: € 248,00 (reeds betaald)\n\nU kunt uw boeking bekijken of wijzigen via {{link:0}}.\n\nWij kijken ernaar uit u te mogen verwelkomen.\n\nBooking.com',
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
 E'Dear Ms Smith,\n\nYour booking at Premier Inn London County Hall is confirmed:\n\n• Check-in: Friday 15 May, from 15:00\n• Check-out: Sunday 17 May, before 12:00\n• 1 double room, 2 nights\n• Total: £198.00 (already paid)\n\nYou can view or change your booking via {{link:0}}.\n\nWe look forward to welcoming you.\n\nBooking.com',
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
 E'Chère Madame Dupont,\n\nVotre réservation à l''Hôtel Mercure Paris Centre est confirmée :\n\n• Arrivée : vendredi 15 mai, à partir de 15h00\n• Départ : dimanche 17 mai, avant 12h00\n• 1 chambre double, 2 nuits\n• Total : 248,00 € (déjà payé)\n\nVous pouvez consulter ou modifier votre réservation via {{link:0}}.\n\nNous avons hâte de vous accueillir.\n\nBooking.com',
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
 E'Chère Madame Dubois,\n\nVotre réservation à l''Ibis Brussels Centre est confirmée :\n\n• Arrivée : vendredi 15 mai, à partir de 15h00\n• Départ : dimanche 17 mai, avant 12h00\n• 1 chambre double, 2 nuits\n• Total : 248,00 € (déjà payé)\n\nVous pouvez consulter ou modifier votre réservation via {{link:0}}.\n\nNous avons hâte de vous accueillir.\n\nBooking.com',
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
 E'Sehr geehrte Frau Müller,\n\nIhre Buchung im Motel One Berlin-Alexanderplatz ist bestätigt:\n\n• Check-in: Freitag, 15. Mai, ab 15:00 Uhr\n• Check-out: Sonntag, 17. Mai, vor 12:00 Uhr\n• 1 Doppelzimmer, 2 Nächte\n• Gesamt: 198,00 € (bereits bezahlt)\n\nSie können Ihre Buchung ansehen oder ändern über {{link:0}}.\n\nWir freuen uns auf Ihren Besuch.\n\nBooking.com',
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
 'Jan, ik zit in een overleg. Kun je nu snel iets voor me regelen? Bel me niet...',
 E'Jan,\n\nIk zit in een belangrijk overleg met een klant en kan niet bellen. Ik heb iets dringends nodig.\n\nKun jij voor mij 5 iTunes-cadeaubonnen van € 100 halen? Stuur me daarna de codes via deze mail, dan regel ik de terugbetaling via de boekhouding. Bel niemand hierover — het is vertrouwelijk.\n\nAlvast bedankt,\nPeter',
 '[]'::jsonb,
 TRUE,
 '["Afzenderadres @kestrel-group.com, niet @kestrel.nl — nep-domein dat op het bedrijf lijkt","Vraagt om cadeaubonnen als vorm van betaling (klassieke CEO-fraude)","Druk: \"niet bellen\", \"vertrouwelijk\" — bedoeld om u los te snijden van collega''s","Past niet bij de normale procedure — facturen lopen via de boekhouding, niet via medewerkers"]'::jsonb,
 '[]'::jsonb,
 'Dit is CEO-fraude. Oplichters doen zich voor als een leidinggevende en vragen om cadeaubonnen of een spoedoverboeking, onder het mom van vertrouwelijkheid. Loop bij twijfel langs het kantoor van de afzender of bel hem/haar op het bekende nummer — nooit via het nummer of e-mailadres in de verdachte mail.',
 10),

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

-- 4. PHISHING — DocuSign
('nl', 'business',
 'DocuSign via Adam Bakker',
 'dse@docusigne-delivery.com',
 'Echte DocuSign gebruikt @docusign.net of @docusign.com. "docusigne" is een typefout in het domein.',
 'vandaag 13:47',
 'Adam Bakker wil dat u een document ondertekent',
 'U heeft een document ontvangen via DocuSign. Het document "Raamovereenkomst-2024.pdf" wacht...',
 E'DocuSign\n\nAdam Bakker (a.bakker@kestrel-group.com) heeft u gevraagd om een document te ondertekenen via DocuSign.\n\nDocument: Raamovereenkomst-2024.pdf\nVerzonden: vandaag om 13:47\n\nOpen het document: {{link:0}}\n\nDank u wel,\nDocuSign',
 '[{"label":"Document beoordelen","real_url":"http://docusigne-delivery.com/sign?id=78a2f","suspicious":true,"warning":"Dit domein is docusigne-delivery.com — een typefout op DocuSign. Het echte domein is docusign.net. Bovendien gebruikt Adam Bakker @kestrel-group.com, niet @kestrel.nl."}]'::jsonb,
 TRUE,
 '["Domein is \"docusigne-delivery.com\" (niet docusign.net/.com)","De \"afzender\" Adam Bakker gebruikt @kestrel-group.com — niet ons eigen @kestrel.nl","Onverwacht document van een collega die u niet recent sprak","Echte DocuSign-notificaties bevatten meestal een beveiligingscode die u op docusign.com kunt invoeren om het document terug te vinden"]'::jsonb,
 '[]'::jsonb,
 'Dit is phishing die DocuSign nabootst. Bij twijfel: open nooit de link, maar ga zelf naar docusign.com en vul daar de beveiligingscode uit een echte DocuSign-mail in. Of bel Adam direct om te vragen of hij echt iets heeft gestuurd.',
 40),

-- 5. REAL — Agenda-uitnodiging van collega
('nl', 'business',
 'Lisa Verhoeven',
 'l.verhoeven@kestrel.nl',
 'Eigen domein @kestrel.nl van een bekende collega — klopt.',
 'vandaag 14:12',
 'Vergadering donderdag 14:00 — kwartaalplanning Q2',
 'Hoi Jan, kun je donderdag om 14:00 bij de kwartaalplanning zijn? Agenda staat eronder...',
 E'Hoi Jan,\n\nKun je donderdag om 14:00 even aanschuiven bij de kwartaalplanning Q2? We bespreken:\n\n• Status van de lopende projecten\n• Planning voor mei en juni\n• Prioriteiten voor het team\n\nHet duurt maximaal een uur. Vergaderzaal De Linde, of via Teams als je liever belt. Geef even een seintje terug.\n\nDank!\nLisa',
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
 'Factuur P-2024-0452 — betaaltermijn overschreden',
 'Geachte heer/mevrouw, bijgevoegd de openstaande factuur voor onderhoud. Gelieve spoedig te voldoen...',
 E'Geachte heer/mevrouw,\n\nBijgevoegd treft u factuur P-2024-0452 aan voor periodiek printonderhoud over Q1, bedrag € 1.847,50.\n\nDe betaaltermijn van 14 dagen is overschreden. Gelieve direct te voldoen om aanmaningskosten te voorkomen. Betalingsgegevens staan in de bijlage.\n\nAls u snel wilt betalen: {{link:0}}\n\nMet vriendelijke groet,\nAdministratie Printwerk BV',
 '[{"label":"Direct betalen","real_url":"http://printservice-nl.com/pay/P-2024-0452","suspicious":true,"warning":"Onbekend betaal-domein. Bij Kestrel lopen facturen via het inkoopportaal — niet via een losse link in een e-mail."}]'::jsonb,
 TRUE,
 '["Onbekende leverancier — niet in uw inkoopsysteem","Tijdsdruk: \"betaaltermijn overschreden\", \"direct voldoen\"","Losse betaal-link in plaats van via het inkoopportaal","Algemene aanhef \"Geachte heer/mevrouw\" — zou uw naam moeten gebruiken","Het bedrag (€ 1.847,50) is net hoog genoeg om te drukken, laag genoeg om niet op te vallen"]'::jsonb,
 '[]'::jsonb,
 'Dit is factuurfraude. Onbekende leveranciers met onverwachte facturen horen eerst gecheckt te worden via uw inkoopafdeling of crediteuren. Betaal nooit via een link in een e-mail, altijd via uw eigen inkoopportaal of via een nieuwe factuur-review.',
 60),

-- 7. REAL — Interne nieuwsbrief
('nl', 'business',
 'Kestrel Communicatie',
 'communicatie@kestrel.nl',
 'Eigen domein @kestrel.nl — klopt.',
 'gisteren 09:00',
 'Kwartaalupdate Q1 — Kestrel in het kort',
 'Beste collega''s, hierbij de kwartaalupdate met nieuws uit alle teams...',
 E'Beste collega''s,\n\nHierbij de kwartaalupdate over het eerste kwartaal van 2024.\n\nHoogtepunten:\n• Drie nieuwe klantprojecten gestart\n• Team Operations is met vier mensen gegroeid\n• De nieuwe kantoorplattegrond is klaar (te bekijken op MijnKestrel)\n• Volgende all-hands: donderdag 16 mei, 16:00 in de kantine\n\nDe volledige update staat op MijnKestrel. Log zelf in zoals gewoonlijk — we sturen bewust geen rechtstreekse link.\n\nVragen of ideeën? Loop langs bij Communicatie (kamer 2.14) of stuur een berichtje.\n\nTot volgend kwartaal!\nCommunicatieteam Kestrel',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Afzender @kestrel.nl, intern bekend","Concrete, verwachte interne informatie","Geen klikbare link — u wordt gevraagd ZELF naar MijnKestrel te gaan","Geen druk of vraag om gegevens","Verwijst naar een bekende interne plek (kamer 2.14) als aanspreekpunt"]'::jsonb,
 'Dit is een normale interne nieuwsbrief. Goed patroon: intern domein, verwachte inhoud, en geen link die u dwingt ergens in te loggen.',
 70),

-- 8. PHISHING — Microsoft 365 wachtwoord
('nl', 'business',
 'Microsoft 365',
 'account-security@microsoft-365-secure.com',
 'Het echte Microsoft-domein is microsoft.com. "microsoft-365-secure.com" is nep.',
 '2 dagen geleden 08:14',
 'Uw Microsoft 365-wachtwoord verloopt vandaag',
 'Uw wachtwoord voor Microsoft 365 verloopt binnen 24 uur. Houd uw huidige wachtwoord...',
 E'Microsoft 365 Accountbeveiliging\n\nUw wachtwoord voor Microsoft 365 verloopt binnen 24 uur. Na deze periode verliest u toegang tot e-mail, OneDrive en Teams.\n\nKlik hieronder om uw huidige wachtwoord te behouden en het verlopen te voorkomen:\n\n{{link:0}}\n\nDeze actie duurt minder dan een minuut. Als u dit negeert, wordt uw account tijdelijk vergrendeld.\n\nMicrosoft 365 Security Team',
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
 'Hoi Jan, Mark vroeg of jij even kan checken of regel 14 in de begroting klopt...',
 E'Hoi Jan,\n\nMark vroeg of jij snel kunt checken of regel 14 in de begroting van project Noord klopt. Volgens hem staat daar een verkeerd bedrag, maar ik weet niet zeker of hij naar de juiste versie keek.\n\nDe begroting staat op de teamshare onder /Projecten/Noord/2024/.\n\nGeef je het even door?\n\nDank!\nLisa',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Afzender @kestrel.nl, bekende collega","Concrete interne context (Mark, project Noord, teamshare pad)","Geen link naar een extern domein","Geen vraag om gegevens, wachtwoorden of geld","Informele toon past bij normale interne communicatie"]'::jsonb,
 'Dit is een normale werkvraag van een collega. Geen actie behalve kijken en antwoorden. Let op: persoonlijke, concrete werkcontext op intern domein is normaal een goed teken.',
 90),

-- 10. PHISHING — Recruiter met gevaarlijke bijlage
('nl', 'business',
 'Sarah Visser — Premium Talent',
 'sarah.visser@premium-talent-careers.info',
 '".info"-domein en losse recruiter zonder aantoonbare link met een bekend bureau. Verdacht patroon.',
 '3 dagen geleden 17:20',
 'Exclusieve kans bij internationale opdrachtgever — CV beoordeeld',
 'Beste Jan, ik heb uw profiel op LinkedIn bekeken en heb een exclusieve positie...',
 E'Beste Jan,\n\nIk heb uw profiel bekeken en heb een exclusieve senior-positie bij een internationale opdrachtgever die volgens mij perfect bij uw ervaring past. Salarisindicatie: € 95k - € 115k.\n\nDe rol is nog niet publiek gemaakt en er is haast bij. Klant wil deze week al een shortlist.\n\nIn de bijlage vindt u de functieomschrijving en het geheimhoudingscontract (NDA) dat ik u vraag te openen en te ondertekenen voordat ik meer details kan delen.\n\nBijlage: Functiebeschrijving_en_NDA.pdf.exe\n\nMet vriendelijke groet,\nSarah Visser\nPremium Talent — Executive Search',
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
 'Peter, ik zit in een overleg. Kun je nu snel iets voor mij regelen? Bel me niet...',
 E'Peter,\n\nIk zit in een belangrijk overleg met een klant en kan niet bellen. Ik heb iets dringends nodig.\n\nKun jij voor mij 5 iTunes-cadeaubonnen van € 100 halen? Stuur me daarna de codes via deze mail, dan regel ik de terugbetaling via de boekhouding. Bel niemand hierover — het is vertrouwelijk.\n\nAlvast bedankt,\nLuc',
 '[]'::jsonb,
 TRUE,
 '["Afzenderadres @kestrel-group.com, niet @kestrel.be — nep-domein dat op het bedrijf lijkt","Vraagt om cadeaubonnen als betaling (klassieke CEO-fraude)","Druk: \"niet bellen\", \"vertrouwelijk\" — bedoeld om u los te snijden van collega''s","Past niet bij de normale procedure — facturen lopen via de boekhouding, niet via medewerkers"]'::jsonb,
 '[]'::jsonb,
 'Dit is CEO-fraude. Oplichters doen zich voor als een leidinggevende en vragen om cadeaubonnen of een spoedoverschrijving, onder het mom van vertrouwelijkheid. Loop bij twijfel langs het bureau van de afzender of bel hem/haar op het bekende nummer — nooit via het nummer of e-mailadres in de verdachte mail.',
 10),

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

-- 4. PHISHING — DocuSign
('nl-BE', 'business',
 'DocuSign via Bart Claes',
 'dse@docusigne-delivery.com',
 'Echte DocuSign gebruikt @docusign.net of @docusign.com. "docusigne" is een typefout in het domein.',
 'vandaag 13:47',
 'Bart Claes wil dat u een document ondertekent',
 'U heeft een document ontvangen via DocuSign. Het document "Raamovereenkomst-2024.pdf" wacht...',
 E'DocuSign\n\nBart Claes (b.claes@kestrel-group.com) heeft u gevraagd om een document te ondertekenen via DocuSign.\n\nDocument: Raamovereenkomst-2024.pdf\nVerzonden: vandaag om 13u47\n\nOpen het document: {{link:0}}\n\nDank u wel,\nDocuSign',
 '[{"label":"Document beoordelen","real_url":"http://docusigne-delivery.com/sign?id=78a2f","suspicious":true,"warning":"Dit domein is docusigne-delivery.com — een typefout op DocuSign. Het echte domein is docusign.net. Bovendien gebruikt Bart Claes @kestrel-group.com, niet @kestrel.be."}]'::jsonb,
 TRUE,
 '["Domein is \"docusigne-delivery.com\" (niet docusign.net/.com)","De \"afzender\" Bart Claes gebruikt @kestrel-group.com — niet ons eigen @kestrel.be","Onverwacht document van een collega die u niet recent sprak","Echte DocuSign-notificaties bevatten een beveiligingscode die u op docusign.com kunt invoeren om het document terug te vinden"]'::jsonb,
 '[]'::jsonb,
 'Dit is phishing die DocuSign nabootst. Bij twijfel: open nooit de link, maar ga zelf naar docusign.com en vul daar de beveiligingscode uit een echte DocuSign-mail in. Of bel Bart rechtstreeks om te vragen of hij echt iets heeft verstuurd.',
 40),

-- 5. REAL — Agenda-uitnodiging van collega
('nl-BE', 'business',
 'Sophie Dewit',
 's.dewit@kestrel.be',
 'Eigen domein @kestrel.be van een bekende collega — klopt.',
 'vandaag 14:12',
 'Vergadering donderdag 14u — kwartaalplanning Q2',
 'Hallo Peter, kun je donderdag om 14u bij de kwartaalplanning zijn? Agenda staat eronder...',
 E'Hallo Peter,\n\nKan jij donderdag om 14u even aansluiten bij de kwartaalplanning Q2? We bespreken:\n\n• Status van de lopende projecten\n• Planning voor mei en juni\n• Prioriteiten voor het team\n\nHet duurt maximaal een uur. Vergaderzaal De Meir, of via Teams als je liever belt. Laat even iets weten.\n\nDank!\nSophie',
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
 'Factuur P-2024-0452 — betaaltermijn overschreden',
 'Geachte heer/mevrouw, bijgevoegd de openstaande factuur voor onderhoud. Gelieve spoedig te voldoen...',
 E'Geachte heer/mevrouw,\n\nBijgevoegd treft u factuur P-2024-0452 aan voor periodiek printonderhoud over Q1, bedrag € 1.847,50.\n\nDe betaaltermijn van 14 dagen is overschreden. Gelieve direct te voldoen om aanmaningskosten te vermijden. Betalingsgegevens staan in de bijlage.\n\nAls u snel wilt betalen: {{link:0}}\n\nMet vriendelijke groeten,\nAdministratie Printwerk BVBA',
 '[{"label":"Direct betalen","real_url":"http://printservice-be.com/pay/P-2024-0452","suspicious":true,"warning":"Onbekend betaal-domein. Bij Kestrel lopen facturen via het inkoopportaal — niet via een losse link in een e-mail."}]'::jsonb,
 TRUE,
 '["Onbekende leverancier — niet in uw inkoopsysteem","Tijdsdruk: \"betaaltermijn overschreden\", \"direct voldoen\"","Losse betaal-link in plaats van via het inkoopportaal","Algemene aanspreking \"Geachte heer/mevrouw\" — zou uw naam moeten gebruiken","Het bedrag is net hoog genoeg om te drukken, laag genoeg om niet op te vallen"]'::jsonb,
 '[]'::jsonb,
 'Dit is factuurfraude. Onbekende leveranciers met onverwachte facturen horen eerst gecontroleerd te worden via uw aankoopdienst of crediteuren. Betaal nooit via een link in een e-mail, altijd via uw eigen inkoopportaal of via een nieuwe factuur-review.',
 60),

-- 7. REAL — Interne nieuwsbrief
('nl-BE', 'business',
 'Kestrel Communicatie',
 'communicatie@kestrel.be',
 'Eigen domein @kestrel.be — klopt.',
 'gisteren 09u',
 'Kwartaalupdate Q1 — Kestrel in het kort',
 'Beste collega''s, hierbij de kwartaalupdate met nieuws uit alle teams...',
 E'Beste collega''s,\n\nHierbij de kwartaalupdate over het eerste kwartaal van 2024.\n\nHoogtepunten:\n• Drie nieuwe klantprojecten gestart\n• Team Operations is met vier mensen gegroeid\n• De nieuwe kantoorplattegrond is klaar (te bekijken op MijnKestrel)\n• Volgende all-hands: donderdag 16 mei, 16u in de bedrijfsrestaurant\n\nDe volledige update staat op MijnKestrel. Meld uzelf aan zoals gewoonlijk — we sturen bewust geen rechtstreekse link.\n\nVragen of ideeën? Loop langs bij Communicatie (bureau 2.14) of stuur een berichtje.\n\nTot volgend kwartaal!\nCommunicatieteam Kestrel',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Afzender @kestrel.be, intern bekend","Concrete, verwachte interne informatie","Geen klikbare link — u wordt gevraagd ZELF naar MijnKestrel te gaan","Geen druk of vraag om gegevens","Verwijst naar een bekende interne plek (bureau 2.14) als aanspreekpunt"]'::jsonb,
 'Dit is een normale interne nieuwsbrief. Goed patroon: intern domein, verwachte inhoud en geen link die u dwingt ergens aan te melden.',
 70),

-- 8. PHISHING — Microsoft 365
('nl-BE', 'business',
 'Microsoft 365',
 'account-security@microsoft-365-secure.com',
 'Het echte Microsoft-domein is microsoft.com. "microsoft-365-secure.com" is nep.',
 '2 dagen geleden 08u14',
 'Uw Microsoft 365-paswoord verloopt vandaag',
 'Uw paswoord voor Microsoft 365 verloopt binnen 24 uur. Behoud uw huidige paswoord...',
 E'Microsoft 365 Accountbeveiliging\n\nUw paswoord voor Microsoft 365 verloopt binnen 24 uur. Na deze periode verliest u toegang tot e-mail, OneDrive en Teams.\n\nKlik hieronder om uw huidige paswoord te behouden en het verlopen te vermijden:\n\n{{link:0}}\n\nDeze actie duurt minder dan een minuut. Als u dit negeert, wordt uw account tijdelijk vergrendeld.\n\nMicrosoft 365 Security Team',
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
 'Hallo Peter, Mark vroeg of jij even kan controleren of regel 14 in de begroting klopt...',
 E'Hallo Peter,\n\nMark vroeg of jij snel kunt controleren of regel 14 in de begroting van project Noord klopt. Volgens hem staat daar een verkeerd bedrag, maar ik weet niet zeker of hij naar de juiste versie keek.\n\nDe begroting staat op de teamshare onder /Projecten/Noord/2024/.\n\nGeef je het even door?\n\nDank!\nSophie',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Afzender @kestrel.be, bekende collega","Concrete interne context (Mark, project Noord, teamshare-pad)","Geen link naar een extern domein","Geen vraag om gegevens, paswoorden of geld","Informele toon past bij normale interne communicatie"]'::jsonb,
 'Dit is een normale werkvraag van een collega. Geen actie behalve kijken en antwoorden. Let op: persoonlijke, concrete werkcontext op intern domein is normaal een goed teken.',
 90),

-- 10. PHISHING — Recruiter met gevaarlijke bijlage
('nl-BE', 'business',
 'Sarah Vermeulen — Premium Talent',
 'sarah.vermeulen@premium-talent-careers.info',
 '".info"-domein en losse recruiter zonder aantoonbare link met een bekend bureau. Verdacht patroon.',
 '3 dagen geleden 17u20',
 'Exclusieve kans bij internationale opdrachtgever — profiel beoordeeld',
 'Beste Peter, ik heb uw profiel op LinkedIn bekeken en heb een exclusieve positie...',
 E'Beste Peter,\n\nIk heb uw profiel bekeken en heb een exclusieve senior-positie bij een internationale opdrachtgever die volgens mij perfect bij uw ervaring past. Salarisindicatie: € 95.000 - € 115.000 bruto.\n\nDe rol is nog niet publiek gemaakt en er is haast bij. Klant wil deze week al een shortlist.\n\nIn de bijlage vindt u de functieomschrijving en het geheimhoudingscontract (NDA) dat ik u vraag te openen en te ondertekenen voordat ik meer details kan delen.\n\nBijlage: Functiebeschrijving_en_NDA.pdf.exe\n\nMet vriendelijke groeten,\nSarah Vermeulen\nPremium Talent — Executive Search',
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
 10),

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

-- 4. PHISHING — DocuSign lookalike
('en', 'business',
 'DocuSign via Adam Baker',
 'dse@docusigne-delivery.com',
 'Real DocuSign uses @docusign.net or @docusign.com. "docusigne" is a typo in the domain.',
 'today 13:47',
 'Adam Baker would like you to sign a document',
 'You have a document waiting via DocuSign. The document "Framework-Agreement-2024.pdf" is...',
 E'DocuSign\n\nAdam Baker (a.baker@kestrel-group.com) has asked you to sign a document via DocuSign.\n\nDocument: Framework-Agreement-2024.pdf\nSent: today at 13:47\n\nOpen the document: {{link:0}}\n\nThank you,\nDocuSign',
 '[{"label":"Review document","real_url":"http://docusigne-delivery.com/sign?id=78a2f","suspicious":true,"warning":"The domain is docusigne-delivery.com — a typo on DocuSign. The real domain is docusign.net. On top of that, Adam Baker is using @kestrel-group.com, not @kestrel.co.uk."}]'::jsonb,
 TRUE,
 '["Domain is \"docusigne-delivery.com\" (not docusign.net/.com)","The \"sender\" Adam Baker uses @kestrel-group.com — not our own @kestrel.co.uk","An unexpected document from a colleague you haven''t spoken to recently","Real DocuSign notifications include a security code you can enter on docusign.com to retrieve the document"]'::jsonb,
 '[]'::jsonb,
 'This is phishing masquerading as DocuSign. If in doubt, don''t open the link — go to docusign.com yourself and enter the security code from a real DocuSign email. Or phone Adam directly to check whether he actually sent anything.',
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
 'Invoice P-2024-0452 — payment overdue',
 'Dear Sir/Madam, please find attached the outstanding invoice for print servicing. Kindly settle promptly...',
 E'Dear Sir/Madam,\n\nPlease find attached invoice P-2024-0452 for quarterly print servicing (Q1), total £1,847.50.\n\nThe 14-day payment term has now passed. Please settle this immediately to avoid late fees. Payment details are in the attachment.\n\nTo pay now: {{link:0}}\n\nKind regards,\nAccounts — Print Solutions Ltd',
 '[{"label":"Pay now","real_url":"http://print-services-uk.com/pay/P-2024-0452","suspicious":true,"warning":"Unknown payment domain. At Kestrel, invoices go through the purchasing portal — not via a stand-alone link in an email."}]'::jsonb,
 TRUE,
 '["Unknown supplier — not in your purchasing system","Time pressure: \"payment overdue\", \"settle immediately\"","Stand-alone pay link instead of the purchasing portal","Generic \"Dear Sir/Madam\" — should use your name","The amount (£1,847.50) is just high enough to pressure, low enough not to raise flags"]'::jsonb,
 '[]'::jsonb,
 'This is invoice fraud. Unknown suppliers with unexpected invoices should be checked with Purchasing or Accounts Payable first. Never pay via a link in an email — always via your own purchasing portal or via a fresh invoice review.',
 60),

-- 7. REAL — Internal newsletter
('en', 'business',
 'Kestrel Communications',
 'communications@kestrel.co.uk',
 'Own @kestrel.co.uk domain — fine.',
 'yesterday 09:00',
 'Q1 update — Kestrel in brief',
 'Dear colleagues, here''s the Q1 update with news from every team...',
 E'Dear colleagues,\n\nHere''s the quarterly update covering the first three months of 2024.\n\nHighlights:\n• Three new client projects started\n• Operations team grew by four people\n• The new floor plan is live (see MyKestrel)\n• Next all-hands: Thursday 16 May, 16:00 in the canteen\n\nThe full update is on MyKestrel. Sign in the way you always do — we deliberately don''t send a direct link.\n\nQuestions or ideas? Drop by Communications (office 2.14) or send a message.\n\nSee you next quarter!\nKestrel Communications team',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Sender @kestrel.co.uk, internally known","Concrete, expected internal content","No clickable link — you are asked to go to MyKestrel YOURSELF","No pressure, no request for data","Points to a known internal location (office 2.14) as follow-up"]'::jsonb,
 'This is a normal internal newsletter. The good pattern: internal domain, expected content and no link that would push you to sign in somewhere.',
 70),

-- 8. PHISHING — Microsoft 365 password
('en', 'business',
 'Microsoft 365',
 'account-security@microsoft-365-secure.com',
 'The real Microsoft domain is microsoft.com. "microsoft-365-secure.com" is fake.',
 '2 days ago 08:14',
 'Your Microsoft 365 password expires today',
 'Your password for Microsoft 365 expires within 24 hours. Keep your current password...',
 E'Microsoft 365 Account Security\n\nYour password for Microsoft 365 expires within 24 hours. After this period you will lose access to email, OneDrive and Teams.\n\nClick below to keep your current password and prevent expiry:\n\n{{link:0}}\n\nThis action takes less than a minute. If you ignore this, your account will be temporarily locked.\n\nMicrosoft 365 Security Team',
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
 E'Hi Jane,\n\nMark asked whether you could quickly check that row 14 in the Project North budget is right. He thinks the amount is wrong, but I''m not sure he was looking at the latest version.\n\nThe budget lives on the team share under /Projects/North/2024/.\n\nCould you let him know?\n\nThanks!\nEmma',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Sender @kestrel.co.uk, known colleague","Concrete internal context (Mark, Project North, team share path)","No link to an external domain","No request for data, passwords or money","Informal tone fits normal internal communication"]'::jsonb,
 'This is a normal work question from a colleague. Nothing to do other than look and reply. Note: a personally addressed, specific work context on an internal domain is generally a good sign.',
 90),

-- 10. PHISHING — Recruiter with malicious attachment
('en', 'business',
 'Sarah Clarke — Premium Talent',
 'sarah.clarke@premium-talent-careers.info',
 'A ".info" domain and a lone recruiter with no demonstrable connection to a known agency. Suspicious pattern.',
 '3 days ago 17:20',
 'Exclusive opportunity with an international client — profile shortlisted',
 'Dear Jane, I''ve reviewed your profile on LinkedIn and have an exclusive position...',
 E'Dear Jane,\n\nI''ve reviewed your profile and I have an exclusive senior position with an international client that, in my view, fits your experience perfectly. Salary range: £85k - £105k.\n\nThe role hasn''t been made public yet and it''s urgent. The client wants a shortlist this week.\n\nAttached you''ll find the job specification and the non-disclosure agreement (NDA) that I''d ask you to open and sign before I can share more details.\n\nAttachment: Job_Spec_and_NDA.pdf.exe\n\nKind regards,\nSarah Clarke\nPremium Talent — Executive Search',
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
 'Pierre, je suis en réunion. Peux-tu régler quelque chose rapidement ? Ne m''appelle pas...',
 E'Pierre,\n\nJe suis en réunion importante avec un client et je ne peux pas être dérangé au téléphone. J''ai besoin de quelque chose d''urgent.\n\nPeux-tu acheter 5 cartes cadeaux Amazon à 100 € chacune ? Envoie-moi les codes par retour de mail dès que tu les as, je demanderai à la comptabilité de te rembourser. Merci de ne pas en parler autour de toi — c''est confidentiel pour le moment.\n\nMerci,\nJean-Philippe',
 '[]'::jsonb,
 TRUE,
 '["Expéditeur @kestrel-group.com, pas @kestrel.fr — domaine imitation","Demande des cartes cadeaux comme moyen de paiement (fraude au dirigeant classique)","Pression : \"ne m''appelle pas\", \"confidentiel\" — vise à vous isoler de vos collègues","Contourne la procédure normale — les dépenses passent par la comptabilité, pas par un salarié"]'::jsonb,
 '[]'::jsonb,
 'C''est de la fraude au dirigeant. Les escrocs se font passer pour un responsable et réclament des cartes cadeaux ou un virement urgent, sous couvert de confidentialité. En cas de doute, rendez-vous au bureau de l''expéditeur ou appelez-le sur son numéro connu — jamais via les coordonnées de l''e-mail suspect.',
 10),

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

-- 4. PHISHING — DocuSign
('fr', 'business',
 'DocuSign via Julien Martin',
 'dse@docusigne-delivery.com',
 'Le vrai DocuSign utilise @docusign.net ou @docusign.com. "docusigne" est une faute de frappe dans le domaine.',
 'aujourd''hui 13:47',
 'Julien Martin vous demande de signer un document',
 'Vous avez un document en attente sur DocuSign. Le document "Contrat-Cadre-2024.pdf"...',
 E'DocuSign\n\nJulien Martin (j.martin@kestrel-group.com) vous demande de signer un document via DocuSign.\n\nDocument : Contrat-Cadre-2024.pdf\nEnvoyé : aujourd''hui à 13h47\n\nOuvrez le document : {{link:0}}\n\nMerci,\nDocuSign',
 '[{"label":"Consulter le document","real_url":"http://docusigne-delivery.com/sign?id=78a2f","suspicious":true,"warning":"Le domaine est docusigne-delivery.com — une faute de frappe sur DocuSign. Le vrai domaine est docusign.net. De plus, Julien Martin utilise @kestrel-group.com, pas @kestrel.fr."}]'::jsonb,
 TRUE,
 '["Le domaine est \"docusigne-delivery.com\" (pas docusign.net/.com)","L''\"expéditeur\" Julien Martin utilise @kestrel-group.com — pas notre @kestrel.fr","Document inattendu d''un collègue que vous n''avez pas vu récemment","Les vraies notifications DocuSign contiennent un code de sécurité que vous pouvez saisir sur docusign.com pour retrouver le document"]'::jsonb,
 '[]'::jsonb,
 'C''est du hameçonnage qui imite DocuSign. En cas de doute, ne cliquez jamais sur le lien : rendez-vous vous-même sur docusign.com et entrez le code de sécurité d''un vrai e-mail DocuSign. Ou appelez Julien directement pour vérifier s''il a vraiment envoyé quelque chose.',
 40),

-- 5. REAL — Invitation réunion collègue
('fr', 'business',
 'Claire Lambert',
 'c.lambert@kestrel.fr',
 'Domaine interne @kestrel.fr d''une collègue connue — correct.',
 'aujourd''hui 14:12',
 'Réunion jeudi 14h — planification Q2',
 'Bonjour Pierre, peux-tu te joindre à la planification Q2 jeudi à 14h ? Ordre du jour ci-dessous...',
 E'Bonjour Pierre,\n\nPeux-tu te joindre à la planification Q2 jeudi à 14h ? On abordera :\n\n• Statut des projets en cours\n• Planning de mai et juin\n• Priorités pour l''équipe\n\nUne heure maximum. Salle Érable, ou via Teams si tu préfères. Confirme-moi ta présence.\n\nMerci !\nClaire',
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
 'Facture P-2024-0452 — délai de paiement dépassé',
 'Madame, Monsieur, veuillez trouver ci-joint la facture en souffrance. Merci de régler rapidement...',
 E'Madame, Monsieur,\n\nVeuillez trouver ci-joint la facture P-2024-0452 pour la maintenance trimestrielle des imprimantes (Q1), d''un montant de 1 847,50 €.\n\nLe délai de paiement de 14 jours est désormais dépassé. Merci de régler immédiatement pour éviter les pénalités de retard. Les coordonnées de paiement sont dans la pièce jointe.\n\nPour régler rapidement : {{link:0}}\n\nCordialement,\nComptabilité — Atelier Impression SARL',
 '[{"label":"Payer maintenant","real_url":"http://imprimerie-services.com/pay/P-2024-0452","suspicious":true,"warning":"Domaine de paiement inconnu. Chez Kestrel, les factures passent par le portail des achats — pas via un lien isolé dans un e-mail."}]'::jsonb,
 TRUE,
 '["Fournisseur inconnu — absent du système d''achats","Pression temporelle : \"délai dépassé\", \"régler immédiatement\"","Lien de paiement isolé au lieu du portail des achats","Formule générique \"Madame, Monsieur\" — devrait utiliser votre nom","Le montant (1 847,50 €) est juste assez élevé pour presser, assez bas pour ne pas attirer l''attention"]'::jsonb,
 '[]'::jsonb,
 'C''est de la fraude à la fausse facture. Un fournisseur inconnu envoyant une facture inattendue doit d''abord être vérifié auprès du service Achats ou Comptabilité fournisseurs. Ne payez jamais via un lien dans un e-mail — toujours via votre propre portail d''achats ou après un nouvel examen de la facture.',
 60),

-- 7. REAL — Newsletter interne
('fr', 'business',
 'Communication Kestrel',
 'communication@kestrel.fr',
 'Domaine interne @kestrel.fr — correct.',
 'hier 09h00',
 'Lettre d''info T1 — Kestrel en bref',
 'Chers collègues, voici la lettre trimestrielle avec les nouvelles de chaque équipe...',
 E'Chers collègues,\n\nVoici la lettre trimestrielle couvrant les trois premiers mois de 2024.\n\nFaits marquants :\n• Trois nouveaux projets clients lancés\n• L''équipe Opérations s''est agrandie de quatre personnes\n• Le nouveau plan des bureaux est disponible (voir MonKestrel)\n• Prochaine réunion générale : jeudi 16 mai, 16h, à la cafétéria\n\nLa lettre complète est sur MonKestrel. Connectez-vous comme d''habitude — nous n''envoyons volontairement aucun lien direct.\n\nQuestions ou idées ? Passez à la Communication (bureau 2.14) ou envoyez un message.\n\nÀ la prochaine !\nÉquipe Communication Kestrel',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Expéditeur @kestrel.fr, interne connue","Contenu interne concret et attendu","Aucun lien cliquable — on vous demande d''aller VOUS-MÊME sur MonKestrel","Aucune pression, aucune demande d''information","Renvoie à un endroit interne connu (bureau 2.14) comme point de contact"]'::jsonb,
 'C''est une newsletter interne classique. Le bon modèle : domaine interne, contenu attendu, aucun lien qui vous obligerait à vous connecter quelque part.',
 70),

-- 8. PHISHING — Microsoft 365
('fr', 'business',
 'Microsoft 365',
 'account-security@microsoft-365-secure.com',
 'Le vrai domaine Microsoft est microsoft.com. "microsoft-365-secure.com" est faux.',
 'il y a 2 jours 08h14',
 'Votre mot de passe Microsoft 365 expire aujourd''hui',
 'Votre mot de passe Microsoft 365 expire dans 24 heures. Conservez votre mot de passe actuel...',
 E'Sécurité du compte Microsoft 365\n\nVotre mot de passe Microsoft 365 expire dans 24 heures. Passé ce délai, vous perdrez l''accès à la messagerie, à OneDrive et à Teams.\n\nCliquez ci-dessous pour conserver votre mot de passe actuel et éviter l''expiration :\n\n{{link:0}}\n\nCette action prend moins d''une minute. Si vous l''ignorez, votre compte sera temporairement verrouillé.\n\nÉquipe Sécurité Microsoft 365',
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
 'Bonjour Pierre, Marc demande si tu peux vérifier rapidement la ligne 14 du budget...',
 E'Bonjour Pierre,\n\nMarc demande si tu peux vérifier rapidement que la ligne 14 du budget du projet Nord est correcte. Selon lui le montant est faux, mais je ne suis pas sûre qu''il regardait la bonne version.\n\nLe budget est sur le partage d''équipe sous /Projets/Nord/2024/.\n\nTu peux lui faire un retour ?\n\nMerci !\nClaire',
 '[]'::jsonb,
 FALSE,
 '[]'::jsonb,
 '["Expéditeur @kestrel.fr, collègue connue","Contexte interne concret (Marc, projet Nord, chemin du partage d''équipe)","Aucun lien vers un domaine externe","Aucune demande d''information, de mot de passe ou d''argent","Ton informel cohérent avec la communication interne normale"]'::jsonb,
 'C''est une question de travail tout à fait normale d''une collègue. Rien à faire sinon regarder et répondre. À retenir : un contexte de travail concret et personnalisé sur un domaine interne est en général un bon signe.',
 90),

-- 10. PHISHING — Recruteur avec pièce jointe malveillante
('fr', 'business',
 'Sophie Clément — Premium Talent',
 'sophie.clement@premium-talent-careers.info',
 'Domaine en ".info" et recruteuse isolée sans lien démontrable avec un cabinet connu. Schéma suspect.',
 'il y a 3 jours 17h20',
 'Opportunité exclusive chez un grand compte international — profil sélectionné',
 'Bonjour Pierre, j''ai examiné votre profil sur LinkedIn et j''ai un poste exclusif...',
 E'Bonjour Pierre,\n\nJ''ai examiné votre profil et j''ai un poste senior exclusif chez un grand compte international qui correspond parfaitement à votre expérience, selon moi. Fourchette de rémunération : 85 000 € — 105 000 € brut.\n\nLe poste n''a pas été rendu public et il y a urgence. Le client veut une shortlist cette semaine.\n\nEn pièce jointe, vous trouverez la fiche de poste et l''accord de confidentialité (NDA) que je vous demande d''ouvrir et de signer avant que je puisse vous communiquer plus de détails.\n\nPièce jointe : Fiche_Poste_et_NDA.pdf.exe\n\nCordialement,\nSophie Clément\nPremium Talent — Executive Search',
 '[]'::jsonb,
 TRUE,
 '["Expéditrice sur un domaine \".info\" sans cabinet reconnu","Contact non sollicité avec une pièce jointe","Le nom du fichier se termine par .pdf.exe — c''est un programme exécutable déguisé en PDF","Pression temporelle : \"shortlist cette semaine\"","Confidentialité demandée — vise à vous isoler","Rémunération utilisée comme appât, sans contexte vérifiable"]'::jsonb,
 '[]'::jsonb,
 'C''est du hameçonnage avec une pièce jointe malveillante. Les fichiers à double extension (.pdf.exe) sont des programmes exécutables déguisés en document. Ne les ouvrez JAMAIS. Un(e) vrai(e) recruteur(se) sérieux(se) avec un vrai poste n''envoie pas de pièces jointes exécutables isolées. Signalez-le à l''informatique ou supprimez l''e-mail.',
 100);
