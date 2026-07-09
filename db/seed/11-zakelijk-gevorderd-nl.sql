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

