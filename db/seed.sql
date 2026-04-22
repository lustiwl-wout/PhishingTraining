-- Seed data: realistische Nederlandse voorbeelden van phishing en echte berichten.
-- Verwijder eerst bestaande rijen zodat seed herhaalbaar is.

TRUNCATE quiz_answers, quiz_attempts, quiz_questions, examples RESTART IDENTITY CASCADE;

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
 E'Beste mevrouw De Vries,\n\nDit is een herinnering dat u het boek "De ontdekking van de hemel" uiterlijk vrijdag 28 april moet terugbrengen.\n\nMet vriendelijke groet,\nBibliotheek Amsterdam',
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
