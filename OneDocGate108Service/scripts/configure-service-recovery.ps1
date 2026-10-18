param(
    [string]$ServiceName = "OneDocGate108Service"
)

$ErrorActionPreference = "Stop"

$service = Get-Service -Name $ServiceName -ErrorAction Stop

# Démarrage automatique différé : laisse le réseau et HFSQL devenir
# disponibles avant le lancement du connecteur.
& sc.exe config $ServiceName start= delayed-auto | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw "Impossible de configurer le démarrage automatique du service."
}

# Trois redémarrages automatiques espacés de 60 secondes. Le compteur des
# échecs est remis à zéro après une journée de fonctionnement stable.
& sc.exe failure $ServiceName reset= 86400 actions= restart/60000/restart/60000/restart/60000 | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw "Impossible de configurer la récupération automatique du service."
}

& sc.exe failureflag $ServiceName 1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw "Impossible d'activer les actions sur les arrêts en erreur."
}

Write-Host "Récupération configurée pour le service '$($service.Name)'."
Get-CimInstance Win32_Service -Filter "Name='$ServiceName'" |
    Select-Object Name, State, StartMode, StartName
