# SaryTany — documentation du dépôt

Ce dépôt regroupe plusieurs utilitaires Windows d’installation et de configuration Bentley/SaryTany. Le client **SarytanyAssistant** (.NET/WPF) est le point d’entrée intégré le plus récent; les dossiers `ConfigurationPc`, `Installation Terra`, `Micro` et `SintegraLidar` contiennent des sources PowerShell et des ressources spécialisées. Ce snapshot ne contient aucun exécutable compilé. Ces composants ne constituent pas encore un seul produit cohérent : leurs fonctions, versions et niveaux de validation diffèrent.

## Documentation

- [Rapport d’analyse technique, architecture, modes d’emploi, risques et plan de remise à niveau](docs/ANALYSE-TECHNIQUE.md)
- Les documentations métier existantes se trouvent dans `Installation Terra/docs/` et `Micro/` (à comparer au code réel : certaines informations sont périmées).

Cette copie destinée à GitHub est un **snapshot source assaini** : elle ne contient aucun historique Git antérieur, aucun exécutable compilé et pas le dossier obsolète `Installation Terra/_archive/`. Les sources de licence ont été modifiées pour ne plus embarquer leurs codes ou empreintes.

## Résumé opérationnel

| Composant | Rôle | Source principale |
|---|---|---|
| `SarytanyAssistant/` | Application WPF unifiée : déploiement de profils Bentley, suite Bentley, configuration PC/domaine, Terra et SintegraLidar | `SarytanyAssistant/SarytanyAssistant.csproj` |
| `ConfigurationPc/` | Ancienne interface PowerShell de déploiement et de configuration poste | `ConfigurationPc/Install-Bentley-GUI.ps1` et `ConfigurationPc/src/` |
| `Installation Terra/` | Installation guidée de PowerDraft/Terra et configuration de TerraScan | `Installation Terra/src/main.ps1` |
| `Micro/` | Installateur Bentley Suite PowerShell autonome/historique | `Micro/Install-BentleySuite.ps1` |
| `SintegraLidar/` | Sources PowerShell de l’installateur graphique et de son moteur | `SintegraLidar/Interface-SintegraLidar.ps1`, `SintegraLidar/Install-SintegraLidar.ps1` |

## Configuration locale des licences

Les valeurs d’activation ne sont pas versionnées. Configurez-les uniquement sur les postes autorisés, à l’extérieur du dépôt : `SARYTANY_APP_LICENSE_CODE` pour l’application WPF, `SARYTANY_CONFIG_LICENSE_CODE` pour ConfigurationPc, `SARYTANY_BENTLEY_LICENSE_CODE` pour l’installateur Micro, `SINTEGRALIDAR_LICENSE_CODE` pour Sintegra et `POWERDRAFT_ACTIVATION` pour Terra (ou une empreinte locale dans `%LOCALAPPDATA%\PowerDraftSetup\activation.dat`). Si la configuration manque, les portes de licence échouent par défaut. Ne committez jamais ces variables, un fichier `.env`, `activation.dat` ou une empreinte d’un code faible.

## Construire l’application WPF

Prérequis déclarés par le projet : Windows, SDK .NET 10 et runtime Windows Desktop correspondant pour lancer un build framework-dependent. Depuis PowerShell, à la racine :

```powershell
dotnet restore .\SarytanyAssistant\SarytanyAssistant.csproj
dotnet build .\SarytanyAssistant\SarytanyAssistant.csproj -c Release
```

La reconstruction demandée a été tentée, mais la restauration NuGet a échoué lors de la négociation TLS avec `api.nuget.org`; `dotnet build --no-restore` échoue donc faute de `obj/project.assets.json`. Aucune conclusion positive ou négative sur la compilabilité du code n’est tirée. `ps2exe` n’est pas installé et son téléchargement depuis PowerShell Gallery a également échoué sur la connexion TLS : aucun nouvel `.exe` n’a été produit, et les binaires existants n’ont pas été remplacés. La publication autonome, la signature et l’installation sur un poste propre restent à valider.

Les sources PowerShell peuvent être analysées sans exécuter leurs opérations système avec `System.Management.Automation.Language.Parser` (exemple dans le rapport). **Ne lancez pas les installateurs sur un poste de production pour les tester** : plusieurs actions touchent au pare-feu, à Defender, au registre, au domaine, au PATH ou installent des exécutables en élévation.

## Avertissement de sécurité

L’application demande actuellement les droits administrateur via son manifeste. Certaines opérations désactivent automatiquement Windows Defender et les trois profils du pare-feu, et l’intégration Sintegra applique un contrôle d’accès `Full Control` à « Tout le monde » sur son dossier d’installation. Les installateurs proviennent d’un dossier sélectionné par l’utilisateur et aucune vérification cryptographique des fichiers n’est décrite. **N’utilisez pas ces fonctions dans un environnement sensible avant correction et revue des risques détaillés dans le rapport technique.**

## Statut de l’audit

L’audit initial est une revue statique du dépôt présent sur le poste. Pour cette copie assainie, le dossier d’archive Terra a été omis et les deux sources Sintegra ont été corrigées; les **23 scripts PowerShell inclus passent maintenant l’analyse syntaxique**. Leur exécution n’a pas été testée. Le build WPF reste non vérifié, car l’accès TLS à NuGet a échoué; aucun `.exe` n’est inclus dans ce snapshot source.

**Mainteneur renseigné :** Ventso Rajaomanjato — [GitHub @ventso00](https://github.com/ventso00).
