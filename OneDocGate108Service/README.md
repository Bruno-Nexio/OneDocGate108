# OneDocGate108Service

Projet WINDEV 2025 de type **Service Windows 64 bits** destiné à exécuter la
synchronisation descendante OneDoc vers Winlogie sans fenêtre utilisateur.

## État actuel

- le squelette `OneDocGate108Service.wdp` est créé ;
- l'analyse `Logik.wdd` a été ajoutée directement dans le dossier du service ;
- les onze requêtes `REQ_*.WDR` utilisées par la synchronisation sont copiées
  dans le dossier du service ;
- la logique métier testée reste dans `SynchroniseChangesSansDependances()` ;
- le curseur est persisté dans
  `C:\ProgramData\OneDocGate108Down\state\changeId.txt` ;
- `Code_Service.wl` contient le code de référence des trois événements du
  service : initialisation, exécution en boucle et arrêt.
- `Procedures_Service.wl` contient une copie autonome des six procédures à
  importer dans le projet Service.

## Éléments à rattacher dans WINDEV

1. Vérifier dans l'explorateur WINDEV que l'analyse `Logik.wdd` est bien
   associée au projet.
2. Rattacher au projet les onze requêtes `REQ_*.WDR` déjà présentes dans ce
   dossier. Leur simple présence sur disque ne suffit pas : elles doivent
   apparaître sous **Requêtes** dans l'explorateur du projet.
3. Les procédures indépendantes de l'interface :
   - `LitChangeId()` ;
   - `SauveChangeId()` ;
   - `getRequest()` ;
   - `postRequest()` ;
   - `deleteRequest()` ;
   - `SynchroniseChangesSansDependances()`.
   Leur code est regroupé dans `Procedures_Service.wl`.
4. Copier `settings.ini.example` sous le nom `settings.ini` à côté de
   l'exécutable du service, puis renseigner les valeurs propres au client.

## Configuration

Le fichier `settings.ini` n'est pas versionné, car il contient les accès HFSQL
et l'autorisation Basic Auth de la passerelle. Le service le lit avec
`fRepExe()`, donc depuis le dossier de son exécutable, y compris lorsqu'il est
lancé par le gestionnaire de services Windows.

La procédure `SynchroniseChanges()` reste propre à la fenêtre de test, car elle
lit et écrit des champs `SAI_*`. Elle ne doit pas être appelée par le service.

## Boucle de fonctionnement

À chaque cycle, le service :

1. lit le dernier `changeId` sauvegardé ;
2. appelle `GET /events/changes?afterChangeId=...` ;
3. traite les créations, modifications et suppressions ;
4. sauvegarde chaque `changeId` seulement après traitement réussi ;
5. attend 5 secondes avec `ServiceTemporise(5000)`.

## Validation avant installation

- compiler la configuration **Service 64 bits** sans erreur ;
- lancer le service en mode test depuis WINDEV ;
- vérifier les traces `[SERVICE]` et `[TEST DOWN]` ;
- confirmer que `changeId.txt` progresse ;
- redémarrer le service et confirmer la reprise au dernier `changeId` ;
- vérifier qu'aucun dialogue `Erreur()` ou `Info()` n'est appelé dans le code
  exécuté par le service.

## Validation réalisée

Le 18 octobre 2026, le service a été validé sur Windows 11 Pro :

- compilation et génération de l'exécutable 64 bits sans erreur ;
- génération et exécution de l'installation autonome ;
- démarrage et arrêt propres du service ;
- connexion à HFSQL et à l'API de développement ;
- lecture et sauvegarde du curseur dans `changeId.txt` ;
- rejeu contrôlé du changement 712 depuis le curseur 711 ;
- détection de la corrélation existante sans nouvelle insertion.

## Génération et installation

1. Ouvrir `OneDocGate108Service.wdp` avec WINDEV 2025.
2. Recompiler le projet et vérifier qu'il n'existe aucune erreur.
3. Générer la configuration courante **Service Windows 64 bits**.
4. Copier un `settings.ini` client valide dans le répertoire de l'exécutable.
5. Générer une **installation autonome**.
6. Exécuter l'installation en tant qu'administrateur sur le serveur Winlogie.
7. Vérifier dans `services.msc` que le service démarre et reste à l'état
   **En cours d'exécution**.
8. Configurer la récupération automatique avec le script
   `scripts/configure-service-recovery.ps1` lancé en administrateur.

## Compte et droits du service

Le compte Windows utilisé par le service doit pouvoir :

- lire le dossier d'installation et `settings.ini` ;
- créer et modifier
  `C:\ProgramData\OneDocGate108Down\state\changeId.txt` ;
- joindre le serveur HFSQL sur le réseau ;
- lire et modifier les fichiers HFSQL nécessaires dans `Commun` et dans les
  répertoires `Prat<n>`.

Éviter de laisser des droits plus larges que nécessaire. Après tout changement
de compte, redémarrer le service et rejouer le test du curseur.

## Exploitation

Le service interroge l'API toutes les cinq secondes. Le fichier
`changeId.txt` ne doit être modifié manuellement que lorsque le service est
arrêté. Diminuer sa valeur provoque le rejeu des changements suivants.

Les traces WINDEV ont permis de valider la première version. La prochaine
évolution d'observabilité consistera à écrire ces messages dans un fichier avec
rotation, puis à les transmettre au serveur de logs central.
