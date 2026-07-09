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


