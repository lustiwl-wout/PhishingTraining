-- Seed data: realistische Nederlandse voorbeelden van phishing en echte berichten.
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

('sms',
 'PostNL',
 NULL,
 E'PostNL: Uw pakket kan niet worden bezorgd door onbetaalde invoerkosten (€ 1,95). Betaal direct: postnl-tracking.info/betaal',
 '[
   {"quote": "€ 1,95", "note": "Klein bedrag om u niet te laten twijfelen. Typisch voor oplichters."},
   {"quote": "postnl-tracking.info/betaal", "note": "Rare link. De echte website van PostNL is postnl.nl."},
   {"quote": "Betaal direct", "note": "Druk om snel te handelen. Niet doen."}
 ]'::jsonb,
 20),

('whatsapp',
 'Onbekend nummer (+31 6 12 34 56 78)',
 NULL,
 E'Hoi mam, ik ben het. Mijn telefoon is kapot, dit is mijn nieuwe nummer. Kun je me snel helpen? Ik moet een rekening betalen maar kom er niet bij met mijn bank.',
 '[
   {"quote": "Hoi mam", "note": "Geen naam erbij. Uw kind noemt u meestal bij naam of heeft een vaste aanhef."},
   {"quote": "Mijn telefoon is kapot, dit is mijn nieuwe nummer", "note": "Klassieke truc: nieuw nummer + noodgeval = betaal snel."},
   {"quote": "Ik moet een rekening betalen", "note": "Vraag om geld. Bel altijd eerst het oude nummer om het te checken!"}
 ]'::jsonb,
 30);

-- ============ QUIZVRAGEN ============

INSERT INTO quiz_questions (channel, sender, subject, body, is_phishing, explanation, signs, difficulty) VALUES

-- 1. Phishing: Belastingdienst
('email',
 'Belastingdienst <noreply@belasting-teruggave.nl>',
 'U heeft recht op € 423,50 teruggave',
 E'Beste burger,\n\nNa controle blijkt u recht te hebben op een belastingteruggave van € 423,50. Vul snel uw gegevens in om het bedrag te ontvangen.\n\nKlik hier: http://belasting-teruggave.nl/claim\n\nBelastingdienst',
 TRUE,
 'Dit is phishing. De Belastingdienst stuurt nooit e-mails om u geld terug te geven, en zeker geen links om "gegevens in te vullen". Het adres eindigt niet op belastingdienst.nl.',
 '["Vreemd afzenderadres (niet belastingdienst.nl)", "Belofte van geld lokt u naar de link", "Aanhef zonder uw naam", "Klikbare link naar een vreemd adres"]'::jsonb,
 1),

-- 2. Echt: afspraak huisarts
('sms',
 'Huisartsenpraktijk De Linde',
 NULL,
 E'Herinnering: uw afspraak is morgen om 10:15 bij dokter Jansen. Afzeggen kan via 020-1234567. Tot morgen.',
 FALSE,
 'Dit is een gewone afspraakherinnering. Er wordt geen link gebruikt, geen betaling gevraagd en u kunt gewoon bellen om af te zeggen.',
 '["Duidelijke afzender die u kent", "Geen link of knop", "Geen vraag om gegevens of geld", "U kunt zelf bellen om te controleren"]'::jsonb,
 1),

-- 3. Phishing: Bank
('sms',
 'ING',
 NULL,
 E'ING: uw bankpas is verlopen. Vraag een nieuwe aan via ing-nieuwe-pas.com voor 24 uur, anders wordt uw account gesloten.',
 TRUE,
 'Dit is phishing. Uw bank stuurt u nooit een sms met een link om een nieuwe pas aan te vragen. Doe dat altijd via de officiële app of bel de bank.',
 '["Onbekend websiteadres (niet ing.nl)", "Dreiging: \"anders wordt uw account gesloten\"", "Druk om binnen 24 uur te handelen", "Link in sms-bericht"]'::jsonb,
 1),

-- 4. Phishing: DigiD
('email',
 'DigiD <info@digid-controle.org>',
 'Bevestig uw DigiD-gegevens',
 E'Geachte heer/mevrouw,\n\nWij vragen u om uw DigiD opnieuw te bevestigen. Klik op onderstaande link en log in met uw gebruikersnaam en wachtwoord.\n\nhttp://digid-controle.org/inloggen\n\nBedankt,\nDigiD',
 TRUE,
 'Dit is phishing. DigiD vraagt u nooit per e-mail om uw gebruikersnaam en wachtwoord. Het echte adres is digid.nl.',
 '["Afzender is niet @digid.nl", "E-mail vraagt om inlognaam en wachtwoord", "Link gaat naar een onbekend domein", "Algemene aanhef \"Geachte heer/mevrouw\""]'::jsonb,
 2),

-- 5. Echt: bibliotheek
('email',
 'Bibliotheek Amsterdam <klantenservice@oba.nl>',
 'Uw geleende boek moet terug',
 E'Beste mevrouw Janssen,\n\nDit is een herinnering dat u het boek "De ontdekking van de hemel" uiterlijk vrijdag 28 april moet terugbrengen.\n\nMet vriendelijke groet,\nBibliotheek Amsterdam',
 FALSE,
 'Dit is een echte e-mail. U wordt persoonlijk aangesproken, er is geen link om op te klikken, en er wordt niets gevraagd.',
 '["Persoonlijke aanhef met uw naam", "Concrete informatie over uw boek", "Geen links of knoppen", "Geen vraag om gegevens of betaling"]'::jsonb,
 2),

-- 6. Phishing: WhatsApp kleinkind-truc
('whatsapp',
 'Onbekend nummer',
 NULL,
 E'Hallo oma, mijn telefoon is stuk en dit is mijn nieuwe nummer. Kun je een rekening voor mij betalen? Ik stuur zo het rekeningnummer.',
 TRUE,
 'Dit is de beruchte "WhatsApp-fraude" of kleinkind-truc. Oplichters doen alsof ze familie zijn en vragen om geld. Bel altijd eerst het oude nummer.',
 '["Nieuw, onbekend nummer", "Vraagt direct om geld", "Noemt geen naam (alleen \"oma\" of \"mam\")", "Reden om niet te bellen (\"telefoon stuk\")"]'::jsonb,
 1),

-- 7. Phishing: Microsoft
('email',
 'Microsoft Support <support@microsoft-security-check.com>',
 'Uw computer is geïnfecteerd',
 E'Waarschuwing! Uw computer heeft een virus. Bel direct 020-0000000 voor hulp, anders verliest u al uw bestanden.',
 TRUE,
 'Dit is phishing of scam. Microsoft belt of mailt u nooit ongevraagd over virussen. Het is vaak een opstapje naar telefonische oplichting.',
 '["Vreemd afzenderadres", "Dreigt met verlies van bestanden", "Vraagt om direct te bellen", "Paniekerige toon"]'::jsonb,
 1),

-- 8. Echt: bevestiging nieuwsbrief
('email',
 'De Lokale Krant <nieuwsbrief@lokalekrant.nl>',
 'Bedankt voor uw aanmelding',
 E'Beste lezer,\n\nBedankt voor uw aanmelding voor onze wekelijkse nieuwsbrief. U ontvangt elke vrijdag het laatste nieuws uit uw buurt.\n\nUitschrijven kan altijd onderaan elke nieuwsbrief.\n\nHet team van De Lokale Krant',
 FALSE,
 'Dit is een echte bevestigingsmail van een nieuwsbrief. Er wordt niets gevraagd, geen geld, geen wachtwoord.',
 '["Normale bevestiging, geen actie vereist", "Geen vraag om gegevens", "Duidelijke uitschrijf-mogelijkheid", "Geen druk of haast"]'::jsonb,
 2),

-- 9. Phishing: gewonnen prijs
('sms',
 'Bol.com',
 NULL,
 E'Gefeliciteerd! U heeft een iPhone 15 gewonnen. Claim uw prijs binnen 2 uur: bol-winactie.net/claim',
 TRUE,
 'U heeft niets gewonnen. Dit is een lokker-truc: u wordt naar een valse website geleid om uw gegevens af te geven.',
 '["U heeft niet meegedaan aan een winactie", "Druk: \"binnen 2 uur\"", "Valse website (niet bol.com)", "Te mooi om waar te zijn"]'::jsonb,
 1),

-- 10. Echt: apotheek
('sms',
 'Apotheek Centrum',
 NULL,
 E'Uw medicijnen liggen klaar bij Apotheek Centrum, Dorpsstraat 12. Geopend tot 17:30.',
 FALSE,
 'Dit is een normale melding van de apotheek. Geen link, geen betaling, geen gegevens gevraagd.',
 '["Duidelijke, bekende afzender", "Concrete informatie (adres, tijd)", "Geen link of betalingsverzoek", "Geen druk of dreiging"]'::jsonb,
 1);

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
