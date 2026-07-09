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


