param(
  [int]$RecentLimitSeconds = 1800
)

$Root = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Set-Location $Root

function Get-FriendlyName {
  param(
    [string]$Name,
    [string]$Email
  )

  $identity = "$Name <$Email>".ToLowerInvariant()

  if ($identity -match "arnaud" -or $identity -match "bobume") {
    return "Arnaud"
  }

  if ($identity -match "carole" -or $identity -match "caromancie") {
    return "Carole"
  }

  return $Name
}

function Test-BotIdentity {
  param(
    [string]$Name,
    [string]$Email
  )

  $identity = "$Name <$Email>".ToLowerInvariant()
  return (
    $identity -match "\[bot\]" -or
    $identity -match "github-actions"
  )
}

function Format-Age {
  param([int]$Seconds)

  if ($Seconds -lt 60) {
    return "il y a $Seconds seconde(s)"
  }

  if ($Seconds -lt 3600) {
    return "il y a $([math]::Floor($Seconds / 60)) minute(s)"
  }

  if ($Seconds -lt 86400) {
    return "il y a $([math]::Floor($Seconds / 3600)) heure(s)"
  }

  return "il y a $([math]::Floor($Seconds / 86400)) jour(s)"
}

Write-Host "Verification de la synchro avec GitHub..."

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
  Write-Host "Git n'est pas disponible sur cet ordinateur."
  exit 1
}

git rev-parse --is-inside-work-tree *> $null
if ($LASTEXITCODE -ne 0) {
  Write-Host "Ce dossier n'est pas un depot Git."
  exit 1
}

$branch = (git rev-parse --abbrev-ref HEAD).Trim()
$upstream = (git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>$null)

if ([string]::IsNullOrWhiteSpace($upstream)) {
  $upstream = "origin/$branch"
}

Write-Host "Branche locale: $branch"
Write-Host "Reference GitHub: $upstream"
Write-Host ""

git fetch --quiet origin
if ($LASTEXITCODE -ne 0) {
  Write-Host "Impossible de contacter GitHub pour le moment."
  Write-Host "Verifie la connexion internet, puis relance ce script."
  exit 1
}

git rev-parse --verify $upstream *> $null
if ($LASTEXITCODE -ne 0) {
  Write-Host "La reference GitHub '$upstream' est introuvable."
  exit 1
}

$latestCommit = (git rev-parse $upstream).Trim()
$latestGitAuthor = (git log -1 --format='%an' $latestCommit).Trim()
$latestGitEmail = (git log -1 --format='%ae' $latestCommit).Trim()
$latestGitSubject = (git log -1 --format='%s' $latestCommit).Trim()
$latestGitTimestamp = [int64](git log -1 --format='%ct' $latestCommit)
$humanCommit = $null

foreach ($commitHash in (git rev-list -n 30 $upstream)) {
  $commitAuthor = (git log -1 --format='%an' $commitHash).Trim()
  $commitEmail = (git log -1 --format='%ae' $commitHash).Trim()

  if (-not (Test-BotIdentity -Name $commitAuthor -Email $commitEmail)) {
    $humanCommit = $commitHash
    break
  }
}

if ([string]::IsNullOrWhiteSpace($humanCommit)) {
  $humanCommit = $latestCommit
}

$latestAuthor = (git log -1 --format='%an' $humanCommit).Trim()
$latestEmail = (git log -1 --format='%ae' $humanCommit).Trim()
$latestSubject = (git log -1 --format='%s' $humanCommit).Trim()
$latestTimestamp = [int64](git log -1 --format='%ct' $humanCommit)
$nowTimestamp = [DateTimeOffset]::Now.ToUnixTimeSeconds()
$ageSeconds = [int]($nowTimestamp - $latestTimestamp)

if ($ageSeconds -lt 0) {
  $ageSeconds = 0
}

$latestPerson = Get-FriendlyName -Name $latestAuthor -Email $latestEmail
$latestGitPerson = Get-FriendlyName -Name $latestGitAuthor -Email $latestGitEmail

if ($humanCommit -ne $latestCommit) {
  $gitAgeSeconds = [int]($nowTimestamp - $latestGitTimestamp)
  if ($gitAgeSeconds -lt 0) {
    $gitAgeSeconds = 0
  }

  Write-Host "Derniere modification automatique sur GitHub:"
  Write-Host "- $(Format-Age -Seconds $gitAgeSeconds) par $latestGitPerson"
  Write-Host "- $latestGitSubject"
  Write-Host ""
}

Write-Host "Derniere modification humaine sur GitHub:"
Write-Host "- $(Format-Age -Seconds $ageSeconds) par $latestPerson"
Write-Host "- $latestSubject"
Write-Host ""

$counts = (git rev-list --left-right --count "HEAD...$upstream").Trim() -split "\s+"
$ahead = [int]$counts[0]
$behind = [int]$counts[1]

if ($behind -gt 0) {
  Write-Host "Action recommandee: faire 'git pull' avant de travailler."
  Write-Host "Ton ordinateur a $behind commit(s) de retard sur GitHub."
} else {
  Write-Host "Synchro: ton ordinateur est a jour avec GitHub."
}

if ($ahead -gt 0) {
  Write-Host "Attention: tu as $ahead commit(s) local(aux) non envoye(s) sur GitHub."
}

if ($ageSeconds -lt $RecentLimitSeconds) {
  Write-Host "Indice: modification tres recente. $latestPerson travaille peut-etre encore."
}

$localStatus = git status --short
if (-not [string]::IsNullOrWhiteSpace($localStatus)) {
  Write-Host ""
  Write-Host "Attention: il y a des changements locaux non commit."
  $localStatus
}
