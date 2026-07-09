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


