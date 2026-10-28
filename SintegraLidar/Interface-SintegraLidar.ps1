# Configuration runtime. Aucun code de licence ni secret cryptographique n'est embarquÃ©.
$ValidLicenseCode = [Environment]::GetEnvironmentVariable('SINTEGRALIDAR_LICENSE_CODE')
$LicenseRegPath = [Environment]::GetEnvironmentVariable('SINTEGRALIDAR_LICENSE_REG_PATH')
$LicenseRegPathMachine = [Environment]::GetEnvironmentVariable('SINTEGRALIDAR_LICENSE_REG_PATH_MACHINE')
$DestDir = [Environment]::GetEnvironmentVariable('SINTEGRALIDAR_DESTINATION')
if ([string]::IsNullOrWhiteSpace($DestDir)) { $DestDir = 'C:\Program Files\SintegraLidar' }
$AppName = 'SintegraLidar'
$AppVersion = '1.0.0'
$DevName = 'Ventso Rajaomanjato'
$GitHubProfile = 'https://github.com/ventso00'
$TrialMaxLaunches = 3
$script:LogoBase64 = $null
# ===== PROTECTION ANTI-ANALYSE =====
# Détecte les environnements d'analyse et d'outils de décompilation
# Ces vérifications empêchent l'exécution dans des contextes d'analyse

# Vérification du débogueur
if ([System.Diagnostics.Debugger]::IsAttached) {
    Write-Error "Débogage détecté. Arrêt de l'exécution."
    exit 1
}

# Vérification des noms d'ordinateur suspects (environnements de test/analyse)
$suspiciousNames = @("DEBUG", "ANALYSIS", "PEKER", "TEST", "VMWARE", "VIRTUAL", "SANDBOX")
$computerName = $env:COMPUTERNAME
if ($suspiciousNames -contains $computerName.ToUpper()) {
    Write-Error "Nom d'ordinateur suspect détecté. Arrêt de l'exécution."
    exit 1
}

# Vérification des variables d'environnement d'analyse
$analysisEnvVars = @("DEBUG", "ANALYSIS_TOOL", "PEID", "ILDASM", "DOTPEEK")
foreach ($var in $analysisEnvVars) {
    if ([Environment]::GetEnvironmentVariable($var)) {
        Write-Error "Variable d'environnement d'analyse détectée: $var. Arrêt de l'exécution."
        exit 1
    }
}

# Vérification de la présence de fichiers d'outils de décompilation
$toolsPaths = @(
    "C:\Program Files\dotnet\dotpeck",
    "C:\Program Files\ILDasm",
    "C:\Program Files (x86)\ILDasm",
    "C:\Program Files\dotnet"
)
foreach ($path in $toolsPaths) {
    if (Test-Path $path -PathType Container) {
        Write-Error "Outil de décompilation détecté dans: $path. Arrêt de l'exécution."
        exit 1
    }
}

# Fin des protections anti-analyse

# Metadonnees mainteneur, sans valeur d'activation embarquee.
$DevName = 'Ventso Rajaomanjato'
$AppName = 'SintegraLidar'
$AppVersion = '1.0.0'
$GitHubProfile = 'https://github.com/ventso00'
$LogoBase64 = $null