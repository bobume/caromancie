param(
  [int]$Port = 4321
)

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$DataPath = Join-Path $Root "data\site.json"
$BuildScript = Join-Path $Root "scripts\build-site.ps1"
$PublishScript = Join-Path $Root "scripts\publish.sh"

function ConvertTo-JsonString {
  param([string]$Value)

  if ($null -eq $Value) {
    return ""
  }

  return $Value.Replace("\", "\\").Replace('"', '\"').Replace("`r", "\r").Replace("`n", "\n")
}

function Send-Text {
  param(
    [System.Net.HttpListenerResponse]$Response,
    [int]$Status,
    [string]$Body,
    [string]$ContentType = "text/plain; charset=utf-8"
  )

  $bytes = [System.Text.Encoding]::UTF8.GetBytes($Body)
  $Response.StatusCode = $Status
  $Response.ContentType = $ContentType
  $Response.ContentLength64 = $bytes.Length
  $Response.OutputStream.Write($bytes, 0, $bytes.Length)
  $Response.OutputStream.Close()
}

function Send-File {
  param(
    [System.Net.HttpListenerResponse]$Response,
    [string]$Path
  )

  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
    Send-Text $Response 404 "Fichier introuvable"
    return
  }

  $extension = [System.IO.Path]::GetExtension($Path).ToLowerInvariant()
  $contentTypes = @{
    ".css" = "text/css; charset=utf-8"
    ".html" = "text/html; charset=utf-8"
    ".js" = "text/javascript; charset=utf-8"
    ".json" = "application/json; charset=utf-8"
    ".png" = "image/png"
    ".jpg" = "image/jpeg"
    ".jpeg" = "image/jpeg"
    ".webp" = "image/webp"
    ".svg" = "image/svg+xml"
  }

  $Response.StatusCode = 200
  $Response.ContentType = if ($contentTypes.ContainsKey($extension)) { $contentTypes[$extension] } else { "application/octet-stream" }

  $stream = [System.IO.File]::OpenRead($Path)
  try {
    $Response.ContentLength64 = $stream.Length
    $buffer = New-Object byte[] 65536
    while (($read = $stream.Read($buffer, 0, $buffer.Length)) -gt 0) {
      $Response.OutputStream.Write($buffer, 0, $read)
    }
  }
  finally {
    $stream.Close()
    $Response.OutputStream.Close()
  }
}

function Resolve-LocalPath {
  param([string]$UrlPath)

  if ($UrlPath -eq "/" -or $UrlPath -eq "/admin") {
    return Join-Path $Root "admin\index.html"
  }

  if ($UrlPath -eq "/preview" -or $UrlPath -eq "/site") {
    return Join-Path $Root "public\index.html"
  }

  $cleanPath = [System.Uri]::UnescapeDataString($UrlPath.TrimStart("/")).Replace("/", "\")
  $firstSegment = $cleanPath.Split("\")[0]

  if ($firstSegment -eq "images") {
    $fullPath = [System.IO.Path]::GetFullPath((Join-Path (Join-Path $Root "public") $cleanPath))
    if (-not $fullPath.StartsWith((Join-Path $Root "public"), [System.StringComparison]::OrdinalIgnoreCase)) {
      return $null
    }

    return $fullPath
  }

  if ($firstSegment -ne "admin" -and $firstSegment -ne "public") {
    return $null
  }

  $fullPath = [System.IO.Path]::GetFullPath((Join-Path $Root $cleanPath))
  if (-not $fullPath.StartsWith($Root, [System.StringComparison]::OrdinalIgnoreCase)) {
    return $null
  }

  return $fullPath
}

function Get-GitBashPath {
  $candidates = @(
    "C:\Program Files\Git\bin\bash.exe",
    "C:\Program Files\Git\usr\bin\bash.exe",
    "C:\Program Files (x86)\Git\bin\bash.exe",
    "bash"
  )

  foreach ($candidate in $candidates) {
    if ($candidate -eq "bash") {
      $command = Get-Command "bash" -ErrorAction SilentlyContinue
      if ($null -ne $command) {
        return $command.Source
      }
    }
    elseif (Test-Path -LiteralPath $candidate -PathType Leaf) {
      return $candidate
    }
  }

  return $null
}

function Send-PublishResult {
  param([System.Net.HttpListenerResponse]$Response)

  $bashPath = Get-GitBashPath
  if ($null -eq $bashPath) {
    Send-Text $Response 500 '{"ok":false,"message":"Git Bash est introuvable. Ouvre Git Bash et lance scripts/publish.sh."}' "application/json; charset=utf-8"
    return
  }

  if (-not (Test-Path -LiteralPath $PublishScript -PathType Leaf)) {
    Send-Text $Response 500 '{"ok":false,"message":"Le script scripts/publish.sh est introuvable."}' "application/json; charset=utf-8"
    return
  }

  Push-Location $Root
  try {
    $output = & $bashPath $PublishScript 2>&1 | Out-String
    $exitCode = $LASTEXITCODE
  }
  finally {
    Pop-Location
  }

  if ($exitCode -ne 0) {
    $message = ConvertTo-JsonString "L'envoi vers GitHub a echoue. $output"
    Send-Text $Response 500 "{""ok"":false,""message"":""$message""}" "application/json; charset=utf-8"
    return
  }

  Send-Text $Response 200 '{"ok":true,"message":"Envoye vers GitHub. Verifie ensuite GitHub Actions / Cloudflare Pages."}' "application/json; charset=utf-8"
}

& $BuildScript -Root $Root

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$Port/")
$listener.Start()

Write-Host ""
Write-Host "Atelier Caromancie prêt : http://localhost:$Port"
Write-Host "Garde cette fenêtre ouverte pendant que tu modifies le site."
Write-Host "Pour arrêter : Ctrl + C"
Write-Host ""

while ($listener.IsListening) {
  $context = $listener.GetContext()
  $request = $context.Request
  $response = $context.Response

  try {
    if ($request.HttpMethod -eq "GET" -and $request.Url.AbsolutePath -eq "/api/site") {
      Send-File $response $DataPath
      continue
    }

    if ($request.HttpMethod -eq "POST" -and $request.Url.AbsolutePath -eq "/api/site") {
      $reader = New-Object System.IO.StreamReader($request.InputStream, [System.Text.Encoding]::UTF8)
      $body = $reader.ReadToEnd()
      $reader.Close()

      $null = $body | ConvertFrom-Json
      Set-Content -LiteralPath $DataPath -Value $body -Encoding UTF8
      & $BuildScript -Root $Root

      Send-Text $response 200 '{"ok":true}' "application/json; charset=utf-8"
      continue
    }

    if ($request.HttpMethod -eq "POST" -and $request.Url.AbsolutePath -eq "/api/publish") {
      Send-PublishResult $response
      continue
    }

    if ($request.HttpMethod -ne "GET") {
      Send-Text $response 405 "Méthode non autorisée"
      continue
    }

    $filePath = Resolve-LocalPath $request.Url.AbsolutePath
    if ($null -eq $filePath) {
      Send-Text $response 404 "Page introuvable"
      continue
    }

    Send-File $response $filePath
  }
  catch {
    $message = $_.Exception.Message.Replace('"', '\"')
    Send-Text $response 500 "{""ok"":false,""message"":""$message""}" "application/json; charset=utf-8"
  }
}
