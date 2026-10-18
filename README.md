# OneDocGate108

Passerelle de synchronisation entre OneDoc et Winlogie.

## Branche `service`

Cette branche prépare l'exécution de la passerelle sous forme de service Windows.
Le traitement métier doit pouvoir fonctionner sans fenêtre WinDev ouverte et sans
session utilisateur connectée.

## Principes à respecter

- Le code de synchronisation ne doit pas dépendre d'un bouton ou d'un champ de fenêtre.
- Les boutons de l'application et le service appellent les mêmes procédures métier.
- Ne pas utiliser `Info()`, `Erreur()` ou une autre boîte de dialogue dans le service.
- Les erreurs et les étapes importantes doivent être envoyées dans les logs.
- Le service doit utiliser des chemins absolus accessibles à son compte Windows.
- Une seule synchronisation `down` doit pouvoir s'exécuter à la fois.

Exemple d'organisation :

```wlanguage
// Application avec interface
PROCÉDURE ClicBTN_changes()
SynchroniseChanges(SAI_afterChangeId)

// Service Windows
PROCÉDURE LanceSynchronisationService()
SynchroniseChanges("")
```

La procédure `SynchroniseChanges()` ne doit plus lire ou modifier directement :

- `SAI_afterChangeId` ;
- `SAI_changeId` ;
- `LIB_Debug` ;
- `BTN_changes`.

## Stockage du `changeId`

Le dernier `changeId` traité n'est plus enregistré dans le profil utilisateur de
la base de registre. Un service Windows peut utiliser un compte différent de
l'utilisateur connecté et ne verrait donc pas nécessairement la même valeur.

Emplacement retenu :

```text
C:\ProgramData\Mondovisio\OneDoc\state\changeId.txt
```

Le fichier contient uniquement la dernière valeur validée, par exemple :

```text
1254
```

Déclaration des chemins :

```wlanguage
gsRepEtatOneDoc est une chaîne = ...
	ComplèteRep(SysRep(srCommonAppData)) + "Mondovisio\OneDoc\state\"

gsFichierChangeId est une chaîne = ...
	gsRepEtatOneDoc + "changeId.txt"
```

Lecture du curseur :

```wlanguage
PROCÉDURE LitChangeId() : entier sur 8 octets

SI PAS fRépertoireExiste(gsRepEtatOneDoc) ALORS
	fRepCrée(gsRepEtatOneDoc)
FIN

SI PAS fFichierExiste(gsFichierChangeId) ALORS
	RENVOYER 0
FIN

sChangeId est une chaîne = SansEspace(fChargeTexte(gsFichierChangeId))

SI sChangeId = "" ALORS
	RENVOYER 0
FIN

RENVOYER Val(sChangeId)
```

Écriture du curseur :

```wlanguage
PROCÉDURE SauveChangeId(nChangeId est un entier sur 8 octets) : booléen

SI PAS fRépertoireExiste(gsRepEtatOneDoc) ALORS
	SI PAS fRepCrée(gsRepEtatOneDoc) ALORS
		RENVOYER Faux
	FIN
FIN

RENVOYER fSauveTexte(gsFichierChangeId, nChangeId)
```

Le `changeId` doit être enregistré uniquement après le traitement complet et
réussi du changement correspondant. Il ne faut pas avancer le curseur si une
création, une modification, une suppression ou une corrélation a échoué.

## Synchronisation descendante

Route utilisée :

```text
GET /events/changes?afterChangeId={changeId}
```

Actions actuellement prises en charge :

- `created` : création ou récupération du patient, création du rendez-vous puis
  création de la corrélation `eventId` vers `externalId` ;
- `updated` : recherche de la corrélation puis mise à jour du rendez-vous et de
  `Int_Doctolib` ;
- `deleted` : suppression du rendez-vous puis suppression de la corrélation.

Chaque requête HTTP doit être exécutée une seule fois et sa réponse conservée :

```wlanguage
respEvent est un httpResponse = getRequest(route)

SWITCH respEvent.StatusCode
	CASE 200:
		jsResult est un JSON = respEvent.Content
END
```

Pour construire `UNIC`, toujours utiliser `fic_cleunik`. La variable ne doit pas
dépendre du fait que le patient vient d'être créé ou existait déjà.

## Exécution sous forme de service

À prévoir :

1. Extraire le contenu de `BTN_changes` dans `SynchroniseChanges()`.
2. Remplacer les messages interactifs par des logs.
3. Remplacer le stockage du registre par le fichier `changeId.txt`.
4. Empêcher deux exécutions simultanées de la synchronisation.
5. Vérifier les droits du compte de service sur `C:\ProgramData\Mondovisio\OneDoc`.
6. Vérifier les droits sur les répertoires HFSQL et les répertoires surveillés.
7. Tester un redémarrage du service au milieu d'un batch de changements.
8. Tester les actions `created`, `updated` et `deleted` séparément.

## Points de vigilance

- Un service ne doit pas appeler `ExécuteTraitement(BTN_changes, trtClic)`.
- `ExécuteThreadPrincipal()` suppose l'existence d'un thread principal capable de
  traiter les appels ; le code métier du service doit autant que possible s'en passer.
- Les lecteurs réseau associés à une session utilisateur ne sont pas forcément
  disponibles pour le service.
- Les erreurs HTTP, SQL et HFSQL doivent empêcher l'avancement du `changeId`.
- Le compte du service doit posséder les droits de lecture et d'écriture nécessaires.
