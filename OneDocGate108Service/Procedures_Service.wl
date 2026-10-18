// Procédures indépendantes de l'interface, extraites du projet de test.
// Source de référence pour leur import dans le projet WINDEV Service.

// ============================================================================
// getRequest
// ============================================================================
//!
//! @brief <indiquez ici ce que fait la procédure>
//!
//! @param _route  route  routes  <indiquez ici le rôle de routes>
//!
//! @return (httpRéponse)  <indiquez ici les valeurs possibles ainsi que leur interprétation>
//!
//!

procédure getRequest(_route)

cMaRequête is httpRequest
cMaRequête.URL						= guri + _route
cMaRequête.Header["Authorization"]	= "Basic " + gauthorization

cMaRéponse is httpResponse = HTTPSend(cMaRequête)
jsResult est un JSON = cMaRéponse.Contenu


RETOUR cMaRéponse

// ============================================================================
// postRequest
// ============================================================================
//!
//! @brief <indiquez ici ce que fait la procédure>
//!
//! @param _route  route  <indiquez ici le rôle de route>
//! @param body  <indiquez ici le rôle de body>
//!
//! @return (httpRéponse)  <indiquez ici les valeurs possibles ainsi que leur interprétation>
//!
//!

procédure postRequest(_route, body)

cMaRequête is httpRequest
cMaRequête.Méthode					= httpPost
cMaRequête.URL						= guri + _route
cMaRequête.Header["Authorization"]	= "Basic " + gauthorization
cMaRequête.ContentType				= typeMimeJSON
cMaRequête.Contenu					= ChaîneVersUTF8(body)
//cMaRequête.ProcédureTrace			= ProcTrace
cMaRéponse	is httpResponse			= HTTPSend(cMaRequête)

RETOUR cMaRéponse


// ============================================================================
// deleteRequest
// ============================================================================
//!
//! @brief <indiquez ici ce que fait la procédure>
//!
//! @param _route  route  <indiquez ici le rôle de route>
//!
//! @return (httpRéponse)  <indiquez ici les valeurs possibles ainsi que leur interprétation>
//!
//!

procédure deleteRequest(_route)
cMaRequête is httpRequest
cMaRequête.Méthode					= httpDelete
cMaRequête.URL						= guri + _route
cMaRequête.Header["Authorization"]	= "Basic " + gauthorization

cMaRéponse	is httpResponse	= HTTPSend(cMaRequête)
jsResult	est un JSON		= cMaRéponse.Contenu

RETOUR cMaRéponse


// ============================================================================
// LitChangeId
// ============================================================================
PROCÉDURE LitChangeId() : entier sur 8 octets

	Trace("[TEST DOWN] Lecture du fichier : " + gsFichierChangeId)

	SI PAS fRépertoireExiste(gsRepEtatOneDoc) ALORS
		fRepCrée(gsRepEtatOneDoc)
	FIN

	SI PAS fFichierExiste(gsFichierChangeId) ALORS
		Trace("[TEST DOWN] Fichier absent, démarrage avec changeId=0")
		RENVOYER 0
	FIN

	sChangeId est une chaîne = SansEspace(fChargeTexte(gsFichierChangeId))
	sChangeId = Replace(sChangeId, [Charact(13), Charact(10)], "")

	SI sChangeId = "" ALORS
		Trace("[TEST DOWN] Fichier vide, démarrage avec changeId=0")
		RENVOYER 0
	FIN

Trace("[TEST DOWN] Valeur trouvée dans le fichier : " + sChangeId)
RENVOYER Val(sChangeId)


// ============================================================================
// SauveChangeId
// ============================================================================
PROCÉDURE SauveChangeId(nChangeId est un entier sur 8 octets) : booléen

SI PAS fRépertoireExiste(gsRepEtatOneDoc) ALORS
	SI PAS fRepCrée(gsRepEtatOneDoc) ALORS
		Trace("[TEST DOWN] Impossible de créer le répertoire : " + gsRepEtatOneDoc)
		RENVOYER Faux
	FIN
FIN

Trace("[TEST DOWN] Ecriture du changeId " + nChangeId + " dans " + gsFichierChangeId)
bSauvegarde est un booléen = fSauveTexte(gsFichierChangeId, nChangeId)
Trace("[TEST DOWN] Résultat écriture fichier : " + bSauvegarde)
RENVOYER bSauvegarde


// ============================================================================
// SynchroniseChangesSansDependances
// ============================================================================
PROCÉDURE SynchroniseChangesSansDependances(nAfterChangeIdForce est un entier sur 8 octets = -1) : booléen

/*
Synchronisation descendante : OneDoc vers Winlogie.<§cs:10§>
<§cs:10§>
Cette procédure contient le traitement métier et ne dépend d'aucun champ de fenêtre.<§cs:10§>
Elle pourra donc être appelée aussi bien depuis l'application de test que depuis le<§cs:10§>
futur service Windows.<§cs:10§>
<§cs:10§>
Paramètre :<§cs:10§>
- nAfterChangeIdForce = -1 : la procédure reprend automatiquement au dernier changeId<§cs:10§>
  enregistré dans le fichier changeId.txt ;<§cs:10§>
- nAfterChangeIdForce >= 0 : la valeur fournie est utilisée comme point de départ.<§cs:10§>
  Cette possibilité sert principalement aux tests et aux reprises manuelles.<§cs:10§>
<§cs:10§>
Valeur de retour :<§cs:10§>
- Vrai : la requête et tous les changements parcourus ont été traités ;<§cs:10§>
- Faux : une erreur HTTP, HFSQL ou une erreur d'écriture du changeId est survenue.<§cs:10§>
<§cs:10§>
Principe important : le changeId d'un élément est enregistré uniquement à la fin de<§cs:10§>
son traitement. En cas d'erreur avant cette sauvegarde, le même changement sera donc<§cs:10§>
redemandé lors de la prochaine exécution au lieu d'être perdu.<§cs:10§>
*/

// Par défaut, on récupère le dernier changeId dans le fichier.
// Une valeur positive ou nulle permet de forcer le curseur pour les tests.

nAfterChangeId est un entier sur 8 octets

// Détermination du point de reprise.
// En fonctionnement normal, le service appellera cette procédure sans paramètre et
// utilisera donc la valeur persistée dans C:\ProgramData. Une valeur forcée permet de
// rejouer volontairement les changements à partir d'un identifiant précis.

SI nAfterChangeIdForce < 0 ALORS
	nAfterChangeId = LitChangeId()
	Trace("[TEST DOWN] changeId lu dans le fichier : " + nAfterChangeId)
SINON
	nAfterChangeId = nAfterChangeIdForce
	Trace("[TEST DOWN] changeId forcé par paramètre : " + nAfterChangeId)
FIN

// Construction de la requête globale des changements.
// L'API renvoie tous les changements dont le changeId est strictement supérieur au
// curseur fourni, triés dans l'ordre croissant. L'en-tête Authorization n'est jamais
// écrit dans les traces afin de ne pas exposer les identifiants Basic Auth.

cMaRequête is httpRequest
cMaRequête.URL						= guri + "/events/changes?afterChangeId=" + nAfterChangeId
cMaRequête.Header["Authorization"]	= "Basic " + gauthorization
Trace("[TEST DOWN] GET " + cMaRequête.URL)
//cMaRequête.ProcédureTrace 			= ProcTrace
cMaRéponse is httpResponse 			= HTTPSend(cMaRequête)

// Une erreur de transport signifie qu'aucune réponse HTTP exploitable n'a été reçue.
// On arrête immédiatement le batch et on conserve l'ancien changeId pour permettre
// une nouvelle tentative lors du prochain passage.

if ErrorOccurred then
	Trace("[TEST DOWN] Erreur HTTP : " + ErrorInfo(errFullDetails))
	RENVOYER Faux
else
	Trace("[TEST DOWN] Statut HTTP : " + cMaRéponse.StatusCode)
	switch cMaRéponse.StatusCode
		case 200

			// La réponse est un tableau JSON. Chaque élément décrit une action à appliquer
			// dans Winlogie : création, modification ou suppression d'un rendez-vous.

			Trace("[TEST DOWN] Données reçues : " + cMaRéponse.Content)
			js is JSON = cMaRéponse.Content
			// ON BOUCLE SUR LE TABLEAU RETOUR LE member.calendarId DONNE LE PRATICIEN
			FOR EACH member of js

				// Les changements sont traités séquentiellement. Ce choix garantit que le
				// changeId sauvegardé correspond toujours au dernier élément réellement traité.

				Trace("[TEST DOWN] Traitement changeId=" + member.changeId + ...
					" | action=" + member.action + ...
					" | calendarId=" + member.calendarId + ...
					" | eventId=" + member.eventId)
				switch member.action
					case "created":

						/*
						CREATION D'UN RENDEZ-VOUS<§cs:10§>
						Le changement ne contient que les identifiants techniques. On commence donc<§cs:10§>
						par demander le détail complet de l'événement à l'API. Ce détail contient les<§cs:10§>
						informations du patient, les horaires et les informations du rendez-vous.<§cs:10§>
						*/

						route = "/calendars/" + member.calendarId + "/events/" + member.eventId
						respEventCreate is httpResponse = getRequest(route)
						jsResult is JSON = respEventCreate.Content

						switch respEventCreate.StatusCode
							case 200

								// Recherche du patient dans FIC_ADM.
								// L'identification actuelle repose sur le nom, le prénom et la date de naissance.
								// Si le patient existe, son FICLEUNIK sera réutilisé. Sinon, un nouveau dossier
								// patient sera créé avant l'insertion du rendez-vous.

								REQ_checkIfPatientExists._nom		= Upper(jsResult.patient.lastName)
								REQ_checkIfPatientExists._prenom	= Upper(jsResult.patient.firstName)
								REQ_checkIfPatientExists._datnais	= StringDelete(jsResult.patient.birthDate,"-")
								Trace("[TEST DOWN][DB] Recherche du patient dans FIC_ADM")

								if HExecuteQuery(REQ_checkIfPatientExists) = False then
									Trace("[TEST DOWN][DB] ECHEC recherche patient : " + HErrorInfo())
									Trace("[TEST DOWN][DB] Erreur HFSQL : " + HErrorInfo())
									RENVOYER Faux
								else

									// La requête renvoie FICLEUNIK=0 lorsqu'aucun patient correspondant n'a été trouvé.

									switch REQ_checkIfPatientExists.FICLEUNIK
										case 0: // LE PATIENT N'EXISTE PAS ON L'INSERT ET ON RECUPERE LE FICLEUNIK
											Trace("[TEST DOWN][DB] Patient absent : début insertion FIC_ADM")

											// Conversion des données OneDoc vers les rubriques Winlogie.
											// Les noms et prénoms sont normalisés en majuscules et le genre OneDoc est
											// converti vers les valeurs M/F utilisées dans FIC_ADM.

											REQ_createPatient.titre		= jsResult.patient.gender = "male"? "Monsieur" else "Madame"
											REQ_createPatient.nom		= Upper(jsResult.patient.lastName)
											REQ_createPatient.prenom	= Upper(jsResult.patient.firstName)
											REQ_createPatient.datnais	= StringDelete(jsResult.patient.birthDate, "-")
											REQ_createPatient.sexe		= jsResult.patient.gender = "male"? "M" else "F"
											REQ_createPatient.email		= jsResult.patient.email
											REQ_createPatient.tel_port	= jsResult.patient.mobilePhoneNumber
											REQ_createPatient.adresse	= jsResult.patient.address.street + " " + jsResult.patient.address.streetNumber
											REQ_createPatient.cdpost	= jsResult.patient.address.zipCode
											REQ_createPatient.ville		= jsResult.patient.address.city
											REQ_createPatient.cleinterv = member.calendarId // Attribution du patient à un médecin

											if HExecuteQuery(REQ_createPatient, hCheckIntegrity + hCheckDuplicates) = False then
												Trace("[TEST DOWN][DB] ECHEC insertion patient : " + HErrorInfo())
												Trace("[TEST DOWN][DB] Erreur HFSQL : " + HErrorInfo())
												RENVOYER Faux
											else
												fic_cleunik = SQL.IDAuto
												Trace("[TEST DOWN][DB] Patient inséré, FICLEUNIK=" + fic_cleunik)

												// La carte d'assurance est enregistrée uniquement lorsqu'un numéro a été
												// fourni. Elle est liée au patient grâce au FICLEUNIK créé ci-dessus.

												SWITCH jsResult.patient.insuranceCardNumber
													CASE <> "":

														REQ_insertInsuranceCardNumber.CARDID = jsResult.patient.insuranceCardNumber
														REQ_insertInsuranceCardNumber.FICLEUNIK = fic_cleunik
														IF HExecuteQuery(REQ_insertInsuranceCardNumber, hCheckIntegrity + hCheckDuplicates) = False THEN
															Trace("[TEST DOWN][DB] ECHEC insertion carte assurance : " + HErrorInfo())
															Trace("[TEST DOWN][DB] Erreur HFSQL : " + HErrorInfo())
															RENVOYER Faux
														ELSE
															Trace("[TEST DOWN][DB] Carte assurance insérée pour FICLEUNIK=" + fic_cleunik)
														END
												END
											end

										case <> 0: // LE PATIENT EXISTE ET ON RECUPERE SON FICLEUNIK

											fic_cleunik = REQ_checkIfPatientExists.FICLEUNIK
											Trace("[TEST DOWN][DB] Patient existant, FICLEUNIK=" + fic_cleunik)
									end

									// Avant toute insertion de rendez-vous, on vérifie la corrélation côté API.
									// Une réponse 200 signifie qu'un externalEventLink existe déjà pour cet eventId.
									// Une réponse 404 signifie que l'événement OneDoc n'a pas encore été associé
									// à un rendez-vous Winlogie et que l'insertion peut commencer.

									route = "/calendars/" + member.calendarId + "/external-event-links/eventId/" + member.eventId
									resp is httpResponse = getRequest(route)
									Trace("[TEST DOWN][DB] Recherche corrélation, statut Corrélation HTTP=" + resp.StatusCode)

									SWITCH resp.StatusCode
										CASE 404:

											// NEGATIF
											// Les fichiers RDV et CLSCOURT sont séparés par praticien. calendarId
											// correspond ici au numéro de praticien Winlogie et détermine les répertoires.

											Prat is int	= member.calendarId
											HChangeDir("RDV", "Prat" + Prat)
											HChangeDir("CLSCOURT","Prat" + Prat)


											UNIC	is string	= NumToString(Val(fic_cleunik),"010d")+Left(Replace(jsResult.startDateTime,["-","T",":"],""),12)
											HDEB	is Time		= StringToTime(Right(jsResult.startDateTime,8))
											HFIN	is Time		= StringToTime(Right(jsResult.endDateTime,8))
											CADATE	is Date		= StringDelete(jsResult.startDateTime,"-")

											// UNIC est la clé fonctionnelle du rendez-vous Winlogie. Elle est composée
											// du FICLEUNIK sur 10 caractères suivi de la date et de l'heure du rendez-vous.
											// Une seconde vérification locale évite donc d'insérer deux fois le même RDV,
											// même si la corrélation distante était absente.

											REQ_checkIfAppointmentExists.UNIC = UNIC
											Trace("[TEST DOWN][DB] Recherche du RDV, UNIC=" + UNIC + " | Prat=" + Prat)

											IF HExecuteQuery(REQ_checkIfAppointmentExists) = False THEN
												Trace("[TEST DOWN][DB] ECHEC recherche RDV : " + HErrorInfo())
												Trace("[TEST DOWN][DB] Erreur HFSQL : " + HErrorInfo())
												RENVOYER Faux
											ELSE

												SWITCH REQ_checkIfAppointmentExists.RDCLEUNIK
													CASE 0: //  LE RDV N'EXISTE PAS
														Trace("[TEST DOWN][DB] RDV absent : début insertion, UNIC=" + UNIC)

														// Préparation des valeurs attendues par le fichier RDV. L'identifiant généré
														// par Winlogie après l'insertion deviendra l'externalId transmis à l'API.

														REQ_insertAppointment.FICLEUNIK		= fic_cleunik
														REQ_insertAppointment.NOM			= Upper(jsResult.patient.lastName)
														REQ_insertAppointment.PRENOM		= Upper(jsResult.patient.firstName)
														REQ_insertAppointment.RAISRDV		= "OneDoc"
														REQ_insertAppointment.CADATE		= CADATE
														REQ_insertAppointment.HDEB			= HDEB
														REQ_insertAppointment.TYPRDV		= "Médical"
														REQ_insertAppointment.HFIN			= HFIN
														REQ_insertAppointment.DUREE			= IntegerToTime(Abs(TimeDifference(HDEB, HFIN)))
														REQ_insertAppointment.LIEU			= 1
														REQ_insertAppointment.ABSENCE		= 3 // SI CADATE ET HDEB > date et heure du jour ALORS 3 SINON 1
														REQ_insertAppointment.CLEINTERV		= Prat
														REQ_insertAppointment.CODEPRAT		= Prat
														REQ_insertAppointment.FORMTET		= "ONEDOC"
														REQ_insertAppointment.UNIC			= UNIC

														IF HExecuteQuery(REQ_insertAppointment, hCheckDuplicates) = False THEN
															Trace("[TEST DOWN][DB] ECHEC insertion RDV : " + HErrorInfo())
															Trace("[TEST DOWN][DB] Erreur HFSQL : " + HErrorInfo())
															RENVOYER Faux
														ELSE

															// SQL.IDAuto contient le RDCLEUNIK généré par l'insertion du rendez-vous.
															// La table Int_Doctolib mémorise ensuite la relation interne entre UNIC,
															// praticien et état d'absence pour les traitements Winlogie ultérieurs.

															insertedID is int = SQL.IDAuto
															Trace("[TEST DOWN][DB] RDV inséré, RDCLEUNIK=" + insertedID + " | UNIC=" + UNIC)
															REQ_insertInt_Doctolib.unic		= UNIC
															REQ_insertInt_Doctolib.cleinterv = Prat
															REQ_insertInt_Doctolib.absence	= 3

															IF HExecuteQuery(REQ_insertInt_Doctolib) = False THEN
																Trace("[TEST DOWN][DB] ECHEC insertion Int_Doctolib : " + HErrorInfo())
																Trace("[TEST DOWN][DB] Erreur HFSQL : " + HErrorInfo())
																RENVOYER Faux
															ELSE
																Trace("[TEST DOWN][DB] Int_Doctolib inséré, UNIC=" + UNIC + " | Prat=" + Prat)

															END

															// Le résumé et le commentaire OneDoc sont regroupés dans CLSCOURT.
															// La liaison avec le rendez-vous est réalisée par la valeur UNIC.

															REQ_insertCommentAndSummary.typcom		= "CommentRDV"
															REQ_insertCommentAndSummary.comcourt	= jsResult.summary + " - " + jsResult.comment
															REQ_insertCommentAndSummary.UNIC		= UNIC

															IF HExecuteQuery(REQ_insertCommentAndSummary) = False THEN
																Trace("[TEST DOWN][DB] ECHEC insertion CLSCOURT : " + HErrorInfo())
																Trace("[TEST DOWN][DB] Erreur HFSQL : " + HErrorInfo())
																RENVOYER Faux
															ELSE
																Trace("[TEST DOWN][DB] CLSCOURT inséré, UNIC=" + UNIC)

															END

															// Dernière étape de la création : publication de la corrélation dans l'API.
															// eventId identifie l'événement OneDoc ; externalId contient le RDCLEUNIK
															// créé par Winlogie. Cette relation permettra les updates et suppressions.

															link is string = [
																{
																"externalId": "%1",
																"eventId": "%2"
																}
															]

															link	= StringBuild(link,insertedID, jsResult.id)
															route	= "/calendars/" + member.calendarId + "/external-event-links"
															statusCode is string = postRequest(route, link).StatusCode

															SWITCH statusCode
																CASE 201:
																	Trace("[TEST DOWN][DB] Corrélation créée, eventId=" + jsResult.id + " | externalId=" + insertedID)
																CASE 500:
																	Trace("[TEST DOWN][DB] ECHEC création corrélation, statut HTTP=500")
																OTHER CASE:
																	Trace("[TEST DOWN][DB] Statut inattendu création corrélation : " + statusCode)
															END

														END

														// --------------------------------------------------- ON INSERT LE COMMENT ET LE SUMMARY SI ILS SONT DIFFERENTS DE ""
														SWITCH (True)
															CASE (jsResult.comment <> "" OR jsResult.summary <> ""):

															OTHER CASE:

														END
												END
											END
									END
								end
							case 404

								//Trace( "Not Found")

						end
					case "updated":

						// MISE A JOUR D'UN RENDEZ-VOUS
						// On commence par retrouver la corrélation eventId -> externalId. L'externalId
						// correspond au RDCLEUNIK utilisé pour retrouver le rendez-vous dans Winlogie.

						route = "/calendars/" + member.calendarId + "/external-event-links/eventId/" + member.eventId
						resp is httpResponse = getRequest(route)

						SWITCH resp.StatusCode
							CASE 200: // ON A UN EXTERNALID DONC ON A UN 200 ET DU COUP ON REQUETE SUR LES DETAILS DU UPDATE
								// ON RECUPERE LE EXTERNALID (RDCLEUNIK)
								jsLink est un jsON = resp.Contenu
								rdcleunik est string = jsLink.externalId

								route = "/calendars/" + member.calendarId + "/events/" + member.eventId
								respEvent est un httpRéponse = getRequest(route)
								jsResult is jsON = respEvent.Contenu

								// Le calendrier détermine le répertoire RDV du praticien concerné.
								// L'UNIC doit être recalculé si la date ou l'heure du rendez-vous a changé.

								HChangeDir("RDV", "Prat" + member.calendarId)

								REQ_getFicleunikByRdcleunik.RDCLEUNIK = rdcleunik

								IF HExecuteQuery(REQ_getFicleunikByRdcleunik) = False THEN
									Trace("[TEST DOWN][DB] Erreur HFSQL : " + HErrorInfo())
									RENVOYER Faux
								ELSE
									UNICOLD is string   = REQ_getFicleunikByRdcleunik.UNIC
									UNIC	is string	= NumToString(Val(REQ_getFicleunikByRdcleunik.FICLEUNIK),"010d")+Left(Replace(jsResult.startDateTime,["-","T",":"],""),12)
									HDEB	is Time		= StringToTime(Right(jsResult.startDateTime,8))
									HFIN	is Time		= StringToTime(Right(jsResult.endDateTime,8))
									CADATE	is Date		= StringDelete(jsResult.startDateTime,"-")
									DUREE 	is Time		= IntegerToTime(Abs(TimeDifference(HDEB, HFIN)))

									REQ_updateAppointment.UNIC = UNIC
									REQ_updateAppointment.CADATE = CADATE
									REQ_updateAppointment.HDEB = HDEB
									REQ_updateAppointment.HFIN = HFIN
									REQ_updateAppointment.DUREE = DUREE
									REQ_updateAppointment.RDCLEUNIK = rdcleunik

									IF HExecuteQuery(REQ_updateAppointment) = False THEN
										Trace("[TEST DOWN][DB] Erreur HFSQL : " + HErrorInfo())
										RENVOYER Faux
									ELSE
										REQ_updateInt_Doctolib.NEWUNIC = UNIC
										REQ_updateInt_Doctolib.OLDUNIC = UNICOLD
										REQ_updateInt_Doctolib.CLEINTERV = member.calendarId

										IF HExecuteQuery(REQ_updateInt_Doctolib) = False THEN
											Trace("[TEST DOWN][DB] Erreur HFSQL : " + HErrorInfo())
											RENVOYER Faux
										ELSE
											// SYSLOG
										END
										//Trace("Update")
									END
								END
							CASE 404:

								//Trace( "Pas de corrélation")
						END

					case "deleted":

						// SUPPRESSION D'UN RENDEZ-VOUS
						// La corrélation fournit le RDCLEUNIK à supprimer dans Winlogie. Une fois
						// la suppression locale réussie, le lien distant est lui aussi supprimé afin
						// de conserver les deux systèmes dans un état cohérent.

						route = "/calendars/" + member.calendarId + "/external-event-links/eventId/" + member.eventId
						resp is httpResponse = getRequest(route)

						SWITCH resp.StatusCode
							CASE 200:
								jsResult IS jsON = resp.Contenu
								REQ_deleteAppointment.RDCLEUNIK = jsResult.externalId
								IF HExecuteQuery(REQ_deleteAppointment) = False THEN
									Trace("[TEST DOWN][DB] Erreur HFSQL : " + HErrorInfo())
									RENVOYER Faux
								ELSE

									route = "/calendars/" + member.calendarId + "/external-event-links/eventId/" + member.eventId
									resp = deleteRequest(route)
									SWITCH resp.StatusCode
										CASE 204:
											//Trace("Lien supprimé")
										OTHER CASE
											// SYSLOG
									END
								END
						END
				end

				// Point de validation du changement courant.
				// Cette écriture est volontairement placée après le SWITCH de l'action : tant
				// que toutes les opérations du changement ne sont pas terminées, le curseur
				// ne doit pas avancer. Une erreur d'écriture arrête également le batch.
				// IMPORTANT : chaque branche HTTP ou HFSQL en échec doit impérativement faire
				// RENVOYER Faux avant ce point. Sinon le changeId serait validé malgré un
				// traitement incomplet et le changement ne serait pas rejoué automatiquement.

				changeId = member.changeId
				SI PAS SauveChangeId(Val(changeId)) ALORS
					Trace("[TEST DOWN] ECHEC sauvegarde changeId=" + changeId)
					Trace("[TEST DOWN] Impossible d'enregistrer le changeId " + changeId)
					RENVOYER Faux
				FIN
				Trace("[TEST DOWN] changeId sauvegardé : " + changeId)
			end

		other case
	end
end

// Si l'exécution atteint ce point, aucune branche n'a demandé d'arrêt anticipé.
// Les statuts HTTP inattendus devront progressivement être transformés en retours
// Faux afin que cette valeur signifie réellement que tout le batch a été validé.

RENVOYER Vrai


