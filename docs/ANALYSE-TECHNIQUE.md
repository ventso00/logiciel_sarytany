# Rapport d’analyse technique — dépôt SaryTany

**Date de l’analyse :** 27 octobre 2026
**Périmètre :** dépôt local `SaryTany_logiciel`, sources C#/WPF, PowerShell, XAML, manifestes, documents existants et inventaire des exécutables.
**Nature :** revue statique et analyse des flux; pas un test de pénétration ni une certification.

**Mainteneur renseigné :** Ventso Rajaomanjato — [GitHub @ventso00](https://github.com/ventso00).

## 1. Synthèse exécutive

Le dépôt rassemble cinq générations ou variantes d’outils d’administration Windows autour de Bentley, Terra et SintegraLidar. `SarytanyAssistant` est le client le plus unifié : application WPF C# avec cinq moteurs fonctionnels et un manifeste qui demande l’élévation. Les répertoires historiques restent séparés, certains avec leurs propres interfaces et fichiers exécutables. Il n’y a pas de README général préalable ni de procédure de release/test centralisée; cette documentation constitue donc un point d’entrée, pas une preuve de conformité.

**Le risque opérationnel le plus important est l’élévation combinée à des changements de sécurité système.** Le manifeste WPF réclame les droits administrateur dès le lancement. Le code désactive automatiquement la protection en temps réel de Defender et le pare-feu Windows avant certaines installations, sans blocage si l’opération échoue; la réactivation est manuelle. L’installation Sintegra accorde en outre `Full Control` au SID Everyone sur son répertoire et importe un fichier `.reg` issu du dossier source avec les privilèges du programme. En parallèle, les sources d’installation choisies sont exécutées sans validation de signature ou d’empreinte identifiée dans le code examiné.

Constats de validation :

- Lors de l’audit initial, le parseur PowerShell de Windows a analysé **25 fichiers `.ps1`** : **3 fichiers avaient des erreurs de syntaxe**, dont les deux scripts Sintegra non archivés et un ancien script Terra archivé. Dans le snapshot de publication, l’archive Terra a été exclue, les deux scripts Sintegra ont été corrigés et les **23 scripts inclus passent l’analyse syntaxique**. Leur comportement réel n’a pas été testé.
- Le SDK local est .NET `10.0.401`. La restauration a été tentée, mais a échoué lors de la négociation TLS/authentification avec `api.nuget.org`; le build sans restauration échoue ensuite faute de `SarytanyAssistant/obj/project.assets.json`. **La compilabilité du projet reste indéterminée.**
- La reconstruction des exécutables a été tentée : `ps2exe` n’est pas installé et son téléchargement depuis PowerShell Gallery échoue également sur TLS. Aucun nouveau binaire n’a été produit; les exécutables précompilés sont exclus du snapshot public.
- Les codes/empreintes de licence intégrés connus ont été retirés du snapshot et remplacés par une configuration locale par variables d’environnement ou fichier d’activation non versionné. Le snapshot utilise une nouvelle racine Git pour ne pas republier l’historique antérieur; l’archive Terra contenant l’ancien script keygen est omise.
- Aucun installeur n’a été lancé; les changements au domaine, au registre, aux protections, au PATH et aux fichiers système n’ont pas été exécutés ni vérifiés.
- La documentation fournie dans `Installation Terra/README.md` ne correspond pas intégralement à l’arborescence actuelle; la documentation `Micro/Documentation-Installateur-Bentley.md` est également à confronter au comportement réel.

**Recommandation immédiate :** suspendre l’usage des fonctions de désactivation de protections et de l’intégration Sintegra en production jusqu’à revue, correction des ACL et mise en place de contrôles de provenance des binaires.

## 2. Périmètre et méthode

L’examen a porté sur les fichiers sources et documents identifiés dans les cinq sous-projets, notamment les moteurs C#, leurs vues WPF, les scripts PowerShell actifs, le manifeste d’application, les scripts de build disponibles, `.gitignore` et les copies d’exécutables visibles. L’analyse n’a pas tenté de décompiler les binaires, d’exécuter du code, de joindre un domaine, de modifier le registre ou de récupérer des dépendances sur Internet.

Contrôles réalisés : lecture des moteurs et points d’entrée, examen des opérations de lancement de processus et des écritures système, inventaire des outils disponibles, analyse syntaxique PowerShell via `System.Management.Automation.Language.Parser`, et tentative `dotnet build --no-restore`. L’analyse statique ne démontre pas l’absence d’autres bogues. Les comportements dépendent aussi des droits, versions Windows/Bentley, stratégies d’entreprise, antivirus et contenus des installateurs source.

## 3. Carte du dépôt

```text
SaryTany_logiciel/
├── SarytanyAssistant/       Application WPF C# consolidée (.NET 10 Windows)
│   ├── Engines/             Déploiement, Suite, PC, Terra, Sintegra
│   ├── Views/               Vues de ces cinq fonctions et contrôles communs
│   ├── Themes/              Thème XAML
│   ├── App.xaml(.cs)        Initialisation et cycle de vie WPF
│   ├── MainWindow.xaml(.cs) Navigation et shell principal
│   ├── LicenseWindow.*      Écran de licence
│   ├── SelfTest.cs          Tests internes disponibles
│   └── app.manifest         Élévation administrateur, compatibilité, DPI
├── ConfigurationPc/         Interface/script PowerShell historique de configuration et déploiement
├── Installation Terra/      Interface et moteur PowerShell Terra + scripts d’archive
├── Micro/                   Installateur Bentley Suite PowerShell et documentation
├── SintegraLidar/           Deux scripts PowerShell Sintegra, documentation/artefacts
├── docs/ANALYSE-TECHNIQUE.md Rapport d’audit (ce document)
└── README.md                Point d’entrée de la documentation
```

Les exécutables `.exe` visibles dans plusieurs dossiers n’ont pas tous de métadonnées de version, et certains noms comportent des copies et/ou un espace insécable final. Sans manifeste de release, empreinte connue et lien explicite avec la source, il est impossible d’établir de manière fiable lequel est le livrable courant.

## 4. Architecture de l’application intégrée

### 4.1 Socle WPF

`SarytanyAssistant/SarytanyAssistant.csproj` cible `net10.0-windows`, active WPF et inclut `System.Management` (version déclarée 9.0.8). `App.xaml` charge `Themes/NeoCarbon.xaml`. `MainWindow` héberge la navigation; `RunViewControl` fournit la progression, les statuts, le journal et les commandes génériques. Les interactions système sont réparties dans `Engines/`; les vues font l’interface et délèguent les traitements longs par tâches asynchrones.

`app.manifest` déclare `requireAdministrator`, la compatibilité Windows 10/11 et le DPI PerMonitorV2. L’élévation est donc demandée pour toute l’application, et non seulement au moment où une action privilégiée en a besoin. Cela augmente l’impact d’un défaut dans un chemin ou un fichier source.

### 4.2 Moteurs

| Moteur | Rôle et opérations principales |
|---|---|
| `DeploymentEngine` | Copie des configurations Bentley vers les profils utilisateurs et mécanisme de déploiement automatique au prochain logon via `HKLM\...\RunOnce`. Utilise des scripts/fichiers temporaires et `robocopy`. |
| `SuiteEngine` | Détecte un ensemble de modules Bentley MSI/MSP/EXE dans un dossier source, les installe en séquence; gère certains assistants en mode interactif et une résolution manuelle de modules absents. |
| `PcConfigEngine` | Inventaire réseau, DNS, IPv6, tests DNS, contrôles Active Directory, renommage/jonction au domaine via WMI, état de Defender et du pare-feu, désactivation et réactivation. |
| `TerraEngine` | Six étapes : localiser les sources Terra, obtenir `PTC_LAS.ptc`, initialiser PowerDraft, lancer `setup.exe`, collecter le Computer ID puis copier le fichier dans TerraScan et relancer PowerDraft. Paramètres persistés en JSON local. |
| `SintegraEngine` | Sept étapes : créer dossier, permissions, copie, import `.reg`, PATH machine, séparateur décimal Windows, module VBA Bentley. Le compteur d’essais est local à l’instance de l’application, non une licence durable. |

Les fichiers `IEngine.cs`, `Ui.cs`, les contrôles communs et le thème portent les contrats et éléments transversaux. La documentation et les commentaires de port mentionnent parfois des anciens noms de fichiers (`src\22-...`, etc.) qui ne sont pas présents sous ces noms exacts dans le dépôt actuel : à actualiser.

### 4.3 Vues et parcours opérateur

- **Déploiement :** sélectionner ou préparer les fichiers de configuration, lancer la copie ou programmer le déploiement au logon.
- **Suite Bentley :** choisir le répertoire des installateurs, vérifier la présence des modules attendus, puis démarrer la séquence. Les étapes manuelles ouvrent les exécutables interactifs en élévation.
- **Configuration PC :** choisir l’adaptateur, saisir DNS et valeurs de poste/domaine, exécuter les contrôles, appliquer le réseau ou la jonction. Le mode simulation est disponible sur certaines actions. La réactivation des protections se fait par un bouton distinct.
- **Terra :** configurer les chemins et options dans la fenêtre de réglages, puis suivre les six étapes dans le contrôle commun.
- **Sintegra :** choisir le dossier source et suivre les sept étapes; l’intégration est interrompue si le contrôle anti-analyse retourne vrai.

Les mots de passe de jonction au domaine sont saisis dans un `PasswordBox` et transmis au moteur en mémoire; l’audit n’a pas identifié de persistance volontaire de ces identifiants. Éviter toutefois de saisir des secrets sur un poste ou un exécutable dont la provenance n’a pas été vérifiée.

## 5. Projets historiques et relation avec l’application WPF

### `ConfigurationPc/`
Contient un ancien outil PowerShell composé de moteurs, modes, thème, contrôles et vues (déploiement Bentley et configuration de PC), ainsi que `Install-Bentley-GUI.ps1` et `Build-Exe.ps1`. Il recouvre en partie les fonctionnalités des moteurs WPF, mais ne doit pas être considéré automatiquement comme leur source courante. Comparer les listes de modules, protections, valeurs par défaut et comportements avant toute mise à jour.

### `Installation Terra/`
Contient `src/01-Config.ps1` à `05-UI.ps1` et `main.ps1`, les documents de conception et `_archive/`. Le guide existant décrit une maquette/une génération antérieure (codes d’activation, options, structure build/dist et gestes d’interface) qui ne sont pas tous corroborés par les sources présentes. En particulier, l’ancien guide affirme que l’antivirus n’est pas modifié; cette affirmation n’est pas valable comme description générale de l’application WPF consolidée, dont le moteur PC désactive Defender et le pare-feu avant certaines installations.

### `Micro/`
`Install-BentleySuite.ps1` est une application WinForms PowerShell indépendante. Sa séquence de modules et son traitement interactif manuel ne sont pas identiques à `SuiteEngine` : l’ancien script demande une confirmation explicite après l’assistant, alors que le moteur WPF reprend automatiquement et accepte tout code de sortie inhabituel d’un installateur manuel comme une réussite à vérifier. Le README local annonce une autre version et un autre total que certains éléments du code; la version et la liste de modules doivent être synchronisées.

### `SintegraLidar/`
Contient les sources PowerShell dédiées, tandis que le moteur C# constitue une autre implémentation. Les deux scripts PowerShell actifs ne passent pas l’analyse syntaxique. Les copies `.exe` du dossier ne portent pas toutes de métadonnées exploitables; ne pas choisir un binaire par son seul nom.

## 6. Configuration et exploitation

### 6.1 Prérequis à confirmer par environnement

- Windows compatible avec WPF, accès administrateur pour les fonctions qui modifient les paramètres machine, le registre, les profils réseau, le domaine ou les répertoires protégés.
- Pour compiler : SDK .NET 10 correspondant à la cible; le projet déclare la dépendance NuGet `System.Management`. Pour exécuter une compilation non autonome : runtime Windows Desktop compatible à confirmer sur le poste cible.
- Réseau, DNS, contrôleur Active Directory, comptes d’administration autorisés et médias officiels Bentley adaptés au poste.
- Les installateurs et fichiers `.reg` doivent provenir d’une source de confiance et être contrôlés par l’organisation avant exécution.

### 6.2 Compilation WPF

Depuis la racine :

```powershell
dotnet restore .\SarytanyAssistant\SarytanyAssistant.csproj
dotnet build .\SarytanyAssistant\SarytanyAssistant.csproj -c Release
```

La reconstruction demandée a tenté `dotnet restore`, qui a échoué à charger l’index de service NuGet en raison d’une erreur TLS/authentification; `dotnet build --no-restore` s’arrête faute de `project.assets.json`. Il s’agit d’un blocage d’accès aux dépendances, pas d’une erreur de code démontrée. Le client Bentley PowerShell modifié passe l’analyse syntaxique, mais le compilateur `ps2exe` était absent; sa récupération depuis PowerShell Gallery a échoué sur la même erreur TLS. Les sources Sintegra ont par ailleurs des erreurs de syntaxe. Aucun `.exe` n’a donc été reconstruit, et les binaires existants n’ont pas été écrasés. Après rétablissement de l’accès aux dépendances, vérifier le répertoire de sortie, le runtime ciblé, les dépendances, le manifeste incorporé et le comportement dans une machine de test propre. Aucun script de publication/signature des binaires WPF n’a été identifié dans le périmètre.

### 6.3 Vérification syntaxique PowerShell sans exécution

Commande de diagnostic à lancer depuis la racine du dépôt (elle analyse le texte seulement) :

```powershell
$files = Get-ChildItem -Recurse -File -Filter *.ps1
foreach ($file in $files) {
    $tokens = $null; $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile(
        $file.FullName, [ref]$tokens, [ref]$errors) | Out-Null
    if ($errors) {
        "ERREUR : $($file.FullName)"
        $errors | Select-Object Message, @{n='Ligne';e={$_.Extent.StartLineNumber}}
    }
}
```

Résultat obtenu lors de l’audit : deux erreurs hors archive (`SintegraLidar/Install-SintegraLidar.ps1`, `SintegraLidar/Interface-SintegraLidar.ps1`), plus une erreur dans `Installation Terra/_archive/Install-PowerDraft-Terra.ps1`. Corriger et relancer avant de présenter ces scripts comme compilables.

### 6.4 Journalisation et configuration

Les moteurs WPF publient des statuts et lignes de journal dans l’interface. Les paramètres Terra sont enregistrés par `TerraEngine.SaveSettings` dans un `settings.json` partagé avec l’installateur PowerDraft historique. L’installation Bentley Suite crée aussi des logs MSI dans le répertoire temporaire. Les répertoires exacts des logs, leur rétention, la protection du JSON et la politique de suppression des temporaires devraient être documentés/testés pour la version publiée.

## 7. Constats et risques hiérarchisés

### Critique — ACL Sintegra trop permissives

`SintegraEngine.Run` invoque `icacls` sur `C:\Program Files\SintegraLidar` (ou la destination fournie) avec le SID universel Everyone et les droits hérités/modifiables `Full Control`, de façon récursive (`/T`). N’importe quel utilisateur local peut alors remplacer/modifier des exécutables ou fichiers installés dans ce dossier protégé, ce qui ouvre la voie à l’exécution ultérieure de code avec les droits de l’utilisateur qui le lance. **Supprimer cette règle; appliquer uniquement des droits nécessaires au groupe administrateur/SYSTEM et, si besoin, un droit de lecture/exécution aux utilisateurs standards.** Vérifier aussi les ACL existantes avant de les remplacer.

### Élevé — Defender et pare-feu coupés automatiquement

`PcConfigEngine.DisableInstallProtections` demande la désactivation de la protection Defender en temps réel et exécute `netsh advfirewall set allprofiles state off`. Les vues Déploiement, Terra, Sintegra et la jonction de domaine appellent ce chemin automatiquement dans certains flux. Le moteur est « best effort » : une erreur ou la protection anti-falsification peut empêcher la désactivation, mais l’installation continue. La remise en service est manuelle, donc une fermeture forcée, un crash ou un oubli peut laisser le poste sans protections. En environnement administré, écrire des clés de stratégie pour Defender n’est pas une méthode sûre de contrôle de l’état réel et peut entrer en conflit avec les politiques MDM/EDR.

**Recommandé :** ne jamais abaisser simultanément les deux protections par défaut; justifier un besoin précis, demander une confirmation explicite par opération, imposer une durée/portée limitée, conserver l’état initial et restaurer dans un `finally`, puis vérifier l’état réel et alerter si la restauration échoue. Respecter les stratégies d’entreprise au lieu de contourner Tamper Protection.

### Élevé — exécutables source exécutés en élévation sans preuve d’intégrité

`SuiteEngine` accepte les fichiers repérés dans un répertoire choisi, puis lance MSI/MSP/EXE en mode silencieux ou interactif; plusieurs processus demandent `runas`. La vérification de readiness vérifie principalement les noms/présence, pas l’éditeur, la signature Authenticode, l’empreinte attendue ou la provenance du média. Le même principe s’applique aux sources et scripts d’installation spécialisés. Un fichier malveillant ou substitué serait exécuté avec des droits élevés.

**Recommandé :** distribuer un manifeste signé des versions et empreintes SHA-256, contrôler signature + empreinte avant tout lancement, restreindre les dossiers source, afficher l’éditeur/version/chemin et obtenir une confirmation opérateur avant la séquence. Ne pas considérer un nom de fichier comme preuve d’authenticité.

### Élevé — import de registre Sintegra issu du dossier source

L’étape 4 importe avec `reg.exe import` le fichier `Las2Laz+IIQ+EXIF.reg` trouvé dans le dossier source ou copié en destination. Elle s’exécute dans un programme administrateur et le contenu n’est pas validé dans ce moteur avant import. Un `.reg` non fiable peut écrire des clés sensibles selon son contenu. Ne pas exécuter sur un fichier fourni par une source non vérifiée; valider et signer le paquet, inspecter le `.reg` et borner les clés attendues.

### Élevé — secrets/licence embarqués et contrôle anti-contournement

Les sources de plusieurs composants contiennent des valeurs de licence en clair ou des mécanismes de licence côté client. `SarytanyAssistant` expose un paramètre de lancement `-NoLicense` selon le point d’entrée examiné; un contrôle local embarqué n’est donc pas une frontière de sécurité robuste. Les sources Sintegra historiques embarquent également les éléments cryptographiques. Toute personne ayant accès au dépôt ou à l’exécutable peut récupérer ou contourner un contrôle client. **Ne pas utiliser ces codes comme secrets ou moyen d’autorisation**; retirer les secrets du dépôt, les renouveler s’ils ont été exposés et déplacer une décision réellement sensible vers un service de confiance. Les valeurs elles-mêmes ne sont pas reproduites dans ce rapport.

### Élevé — chiffrements Sintegra sans IV conservé

Dans `SintegraEngine.EncryptString`, AES-CBC chiffre avec un IV généré par l’instance, mais seul le ciphertext Base64 est retourné. `DecryptString` crée un nouvel objet AES et utilise son propre IV aléatoire; l’IV de chiffrement n’est ni préfixé ni stocké avec le ciphertext. Une paire chiffre/déchiffre ne peut donc pas être fiable. Cette interface ne doit pas être utilisée pour protéger des données tant que le format n’inclut pas un IV unique et que l’authenticité n’est pas assurée (préférer un format AEAD, avec gestion de clé adaptée). Le fait que la clé soit dans le code signifie de toute manière que le chiffrement n’est pas un coffre à secrets.

### Moyen à élevé — blocage Sintegra par détection anti-analyse fragile

Le moteur refuse l’installation si le nom du poste contient certains mots comme `TEST`, `VIRTUAL` ou `VMWARE`, si un débogueur est attaché ou si certaines variables d’environnement existent. Les noms courants de machines de test/VM peuvent donc être rejetés. La vérification détecte aussi l’analyse, sans bénéfice démontré pour une application d’installation d’entreprise, et rend la validation/support plus difficiles. Les deux scripts PowerShell historiques contiennent en outre des erreurs de syntaxe. Supprimer cette logique ou la remplacer par des contrôles d’intégrité/administration transparents, et tester sur les VM de recette.

### Moyen — succès manuel Suite déclaré sans vérification

Dans `SuiteEngine`, une étape manuelle est comptée comme réussite dès que l’installateur s’est fermé, même si son code de retour est inhabituel; le journal demande alors une vérification, mais le compteur de succès progresse. L’ancien WinForms, lui, demande une confirmation Oui/Non/Annuler. Risque de résultat final faussement positif. Réintroduire une confirmation ou vérifier l’état installé par produit/version avant d’avancer.

### Moyen — état RunOnce et robustesse du déploiement automatique

Le moteur écrit une entrée HKLM `RunOnce` et génère un script de logon. Il faut vérifier au runtime l’encodage/quoting de la commande, le comportement selon le type de session/UAC, la stratégie de poste, l’existence du script et le résultat de copie. Dans le modèle examiné, les chemins sont intégrés dans des fragments de script; ils doivent être échappés pour le langage cible (PowerShell/CMD) et non seulement entourés de guillemets. Tester avec espaces, apostrophes, caractères spéciaux, profils existants et chemins réseau. Ajouter un journal durable, un état de reprise et un nettoyage contrôlé des tâches/valeurs RunOnce.

### Moyen — guides, versions et exécutables en décalage

Les README Terra et Micro décrivent des générations/options qui ne sont pas parfaitement alignées aux sources actuelles. Plusieurs exécutables ont des copies, des espaces insécables ou aucune version de fichier exploitable; l’exécutable Terra `dist/PowerDraft-Setup.exe` a une version ressource 2.0.2, mais cela ne prouve pas qu’il est construit à partir de l’état source courant. Les scripts Sintegra actifs ne passent même pas le parseur. Établir un seul identifiant de version, générer les binaires depuis le commit tagué, joindre un manifeste et un SHA-256, puis archiver les anciennes copies hors des chemins opérateur.

### Moyen — nom réseau / sélection d’adaptateur dépendants de la langue

`PcConfigView.UpdateAdapterListAsync` sélectionne le premier adaptateur dont le libellé contient `Up`. Sur une machine localisée, l’état peut s’afficher autrement; la sélection risque de ne pas retenir une carte connectée. Utiliser `NetworkInterfaceOperationalStatus.Up`/le statut typé plutôt qu’une recherche de texte UI. Vérifier également la validation des adresses DNS et la sélection de l’interface WMI/netsh sur les postes avec plusieurs cartes.

## 8. Anomalies et limites de validation vérifiées

1. **PowerShell :** les deux sources Sintegra non archivées ont des erreurs de parsing (dont interpolation/parenthèses et délimitation de chaîne); l’ancien script Terra de `_archive` a également une erreur de syntaxe. Les erreurs d’archive ne bloquent pas nécessairement l’application courante, mais les deux erreurs Sintegra affectent les scripts actifs.
2. **Compilation .NET :** non réalisée, faute d’assets de restauration; la dépendance déclarée doit être restaurée avant compilation. Ce rapport ne certifie pas le build.
3. **Pas de tests unitaires identifiés comme projet séparé :** `SelfTest.cs` fournit un test interne, mais aucun projet de test dédié n’a été recensé. Il faut ajouter tests automatisés des parsers, chemins, commandes, annulations, quoting, licence et transitions d’état.
4. **Pas de validation terrain :** aucune modification d’un vrai poste, jonction AD, installation Bentley, changement Defender/pare-feu ou test de restauration n’a été effectué.
5. **Binaire :** les métadonnées et duplications ne permettent pas d’attester que chaque `.exe` correspond aux sources présentes. Un audit de binaire nécessiterait les artefacts précis, leur provenance et leur empreinte; ce rapport ne les inspecte pas en profondeur.

## 9. Plan d’action conseillé

### P0 — avant tout usage élargi

1. Désactiver ou retirer l’attribution `Everyone: Full Control`; valider les ACL après installation et sur tous les descendants.
2. Désactiver par défaut les changements automatiques de Defender/pare-feu; rendre l’activation temporaire, visible, auditée et systématiquement restaurée.
3. Bloquer l’exécution de médias non signés/non conformes à des empreintes approuvées; vérifier les signatures avant lancement.
4. Inspecter/valider le `.reg` Sintegra; limiter ses chemins de registre attendus et obtenir confirmation avant import.
5. Supprimer les secrets et codes en clair du dépôt; considérer comme compromis tout code déjà diffusé; revoir `-NoLicense` et ne pas présenter la licence locale comme sécurité.

### P1 — rendre le code fiable et testable

6. Corriger les erreurs de parsing PowerShell Sintegra et décider si ces anciens scripts doivent être supportés ou retirés.
7. Corriger le format de chiffrement en stockant/transmettant l’IV (et utiliser un schéma authentifié) ou supprimer cette API morte; ajouter des vecteurs de test.
8. Supprimer la détection anti-analyse basée sur nom d’ordinateur/environnement ou documenter un besoin légitime avec tests VM.
9. Revoir `SuiteEngine` pour ne pas comptabiliser la fermeture d’un installeur comme succès; comparer au flux de confirmation de l’ancien WinForms.
10. Remplacer les commandes assemblées en chaînes par des API/process arguments sûrs, échapper les valeurs injectées dans les scripts et tester les chemins inhabituels.
11. Exécuter restore + build Release sur CI Windows, puis tests automatisés et installation contrôlée dans une VM isolée (snapshot/restauration), jamais sur un poste métier.

### P2 — rendre la maintenance et la livraison prévisibles

12. Faire du WPF la source de vérité ou désigner formellement le composant courant; marquer les versions historiques comme archivées.
13. Synchroniser README Terra/Micro, noms de modules, version, liste de fichiers requis, étapes, codes de retour et gestion des protections.
14. Créer une procédure de release : version sémantique, commit/tag, build reproductible, signature Authenticode, SHA-256, inventaire des dépendances, notes de version et test smoke.
15. Documenter les chemins de logs/settings, leur sensibilité et la rétention; masquer les identifiants et éviter les données sensibles dans les journaux.
16. Ajouter des scénarios de test documentés : utilisateur standard, UAC refusé, Defender administré, antivirus tiers, DNS multi-interface, réseau déconnecté, installation annulée, code de retour 3010, annulation, profil déjà configuré, VM et nom d’hôte contenant « TEST ».

## 10. Checklist opérateur — avant toute installation

- Vérifier le nom/version de l’outil et l’empreinte du binaire contre une source officielle interne.
- Confirmer que les médias Bentley sont autorisés, complets et intègres; ne pas utiliser un dossier source non maîtrisé.
- Lire et valider le contenu du `.reg` Sintegra avant import.
- Vérifier la sauvegarde, l’état Defender/EDR, les profils pare-feu et la possibilité de restauration; ne pas désactiver une politique gérée par l’organisation.
- Confirmer l’adaptateur, DNS, domaine, nom de poste, identifiant de compte et fenêtre de redémarrage; ne jamais mettre le mot de passe dans un ticket/log.
- Tester le flux dans une VM isolée; prévoir une procédure d’arrêt et de retour arrière.
- Après installation, vérifier manuellement pare-feu/Defender/EDR, PATH, ACL, registre, version des produits, journaux d’erreur et état de redémarrage requis.

## 11. Glossaire rapide

- **WPF / XAML :** technologie .NET de l’interface de `SarytanyAssistant`.
- **MSI / MSP / EXE :** paquets d’installation Windows; MSP est généralement un correctif.
- **RunOnce :** entrée de registre Windows qui planifie une commande pour une ouverture de session ultérieure.
- **SID Everyone (`S-1-1-0`) :** principal de sécurité regroupant tous les utilisateurs; lui accorder un contrôle total est très permissif.
- **Tamper Protection :** mécanisme Windows/Defender qui limite la modification non autorisée des paramètres de sécurité.
- **Computer ID :** donnée saisie depuis Bentley PowerDraft; ce rapport ne la traite pas comme une clé de licence vérifiée.

---

*Fin du rapport. Les constats décrivent les sources examinées à la date indiquée; toute nouvelle modification du dépôt requiert une nouvelle validation.*
