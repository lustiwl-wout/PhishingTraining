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


