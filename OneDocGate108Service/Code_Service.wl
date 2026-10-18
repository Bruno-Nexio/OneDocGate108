// ============================================================================
// OneDocGate108Service - code des événements du service
// ============================================================================
// Ce fichier sert de source de référence pendant la mise en place du projet
// WINDEV. Le code doit être copié dans les événements correspondants du projet.


// ----------------------------------------------------------------------------
// ÉVÉNEMENT : Initialisation de OneDocGate108Service
// ----------------------------------------------------------------------------

Trace("[SERVICE] Démarrage de OneDocGate108Service")

// Variables globales utilisées par les procédures de synchronisation.
// Placées dans le code d'initialisation du projet, elles restent disponibles
// pendant toute la durée de vie du service.
gMyConnect est une Connexion
gUri est une chaîne
gAuthorization est une chaîne
route est une chaîne
changeId est une chaîne
fic_cleunik est un entier

gsRepEtatOneDoc est une chaîne = ...
	ComplèteRep(SysRep(srCommonAppData)) + "OneDocGate108Down\state\"

gsFichierChangeId est une chaîne = ...
	gsRepEtatOneDoc + "changeId.txt"

// La configuration est placée à côté de l'exécutable du service.
gsFichierINI est une chaîne = fRepExe() + ["\\"] + "settings.ini"

SI PAS fFichierExiste(gsFichierINI) ALORS
	Trace("[SERVICE][ERREUR] Fichier de configuration absent : " + gsFichierINI)
	FinProgramme(1)
FIN

// Connexion à la base HFSQL de Winlogie.
gMyConnect..Utilisateur       = INILit("DATABASE", "LOGIN", "", gsFichierINI)
gMyConnect..MotDePasse       = INILit("DATABASE", "PASSWORD", "", gsFichierINI)
gMyConnect..Serveur          = INILit("DATABASE", "SERVER", "", gsFichierINI)
gMyConnect..BaseDeDonnées    = INILit("DATABASE", "BDD", "", gsFichierINI)
gMyConnect..Provider         = hAccèsHFClientServeur
gMyConnect..Accès            = hOLectureEcriture
gMyConnect..OptionsCurseur   = hCurseurClient
gMyConnect..Compression      = Faux

SI PAS HOuvreConnexion(gMyConnect) ALORS
	Trace("[SERVICE][ERREUR] Connexion HFSQL impossible : " + HErreurInfo())
	FinProgramme(2)
FIN

HChangeConnexion("*", gMyConnect)
HChangeRep(FIC_ADM, "Commun")
HChangeRep(Int_Doctolib, "Commun")
HChangeRep(ASSURCH, "Commun")

// Accès à la passerelle NexAPI. AUTHORIZATION contient la valeur Base64 déjà
// utilisée par l'application actuelle. Elle ne doit jamais apparaître en trace.
gUri = INILit("NEXAPI", "URI", "", gsFichierINI)
gAuthorization = INILit("NEXAPI", "AUTHORIZATION", "", gsFichierINI)

SI gUri = "" OU gAuthorization = "" ALORS
	Trace("[SERVICE][ERREUR] Configuration NEXAPI incomplète")
	FinProgramme(3)
FIN

Trace("[SERVICE] Initialisation terminée")


// ----------------------------------------------------------------------------
// ÉVÉNEMENT : Exécution du service (appelé en boucle)
// ----------------------------------------------------------------------------

// Une exécution traite tous les changements disponibles puis rend la main au
// gestionnaire de services Windows. La temporisation évite une boucle CPU et
// permet au système de transmettre rapidement une demande d'arrêt.
SI PAS SynchroniseChangesSansDependances() ALORS
	Trace("[SERVICE][ERREUR] Échec de la synchronisation descendante")
SINON
	Trace("[SERVICE] Cycle de synchronisation terminé")
FIN

// 5 secondes entre deux interrogations. Cette valeur pourra ensuite devenir
// un paramètre de settings.ini si nécessaire.
ServiceTemporise(5000)


// ----------------------------------------------------------------------------
// ÉVÉNEMENT : Arrêt du service
// ----------------------------------------------------------------------------

Trace("[SERVICE] Arrêt demandé")

// HFermeConnexion est sans effet gênant si la connexion a déjà été fermée
// pendant l'arrêt de l'application.
HFermeConnexion(gMyConnect)

Trace("[SERVICE] Arrêt terminé")
