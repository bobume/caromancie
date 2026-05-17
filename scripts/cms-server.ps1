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
  $Response.Headers["Cache-Control"] = "no-store, no-cache, must-revalidate, max-age=0"
  $Response.Headers["Pragma"] = "no-cache"
  $Response.Headers["Expires"] = "0"

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

function Get-SafeImageFileName {
  param([string]$FileName)

  $baseName = [System.IO.Path]::GetFileNameWithoutExtension($FileName)
  $extension = [System.IO.Path]::GetExtension($FileName).ToLowerInvariant()
  $allowedExtensions = @(".jpg", ".jpeg", ".png", ".webp", ".gif")

  if (-not $allowedExtensions.Contains($extension)) {
    return $null
  }

  $safeBase = ($baseName.ToLowerInvariant() -replace '[^a-z0-9]+', '-').Trim('-')
  if ([string]::IsNullOrWhiteSpace($safeBase)) {
    $safeBase = "image"
  }

  return "$safeBase-$(Get-Date -Format 'yyyyMMddHHmmss')$extension"
}

function Send-ImageUploadResult {
  param(
    [System.Net.HttpListenerRequest]$Request,
    [System.Net.HttpListenerResponse]$Response
  )

  if ($Request.ContentType -notmatch 'boundary=(.+)$') {
    Send-Text $Response 400 '{"ok":false,"message":"Image illisible : formulaire incomplet."}' "application/json; charset=utf-8"
    return
  }

  $boundary = $Matches[1].Trim('"')
  $bytes = New-Object byte[] $Request.ContentLength64
  $offset = 0
  while ($offset -lt $bytes.Length) {
    $read = $Request.InputStream.Read($bytes, $offset, $bytes.Length - $offset)
    if ($read -le 0) { break }
    $offset += $read
  }

  $latin1 = [System.Text.Encoding]::GetEncoding("iso-8859-1")
  $body = $latin1.GetString($bytes)
  $fileNameMatch = [regex]::Match($body, 'filename\*?=(?:"([^"]+)"|([^;\r\n]+))')
  if (-not $fileNameMatch.Success) {
    Send-Text $Response 400 '{"ok":false,"message":"Aucun fichier image recu."}' "application/json; charset=utf-8"
    return
  }

  $originalFileName = if ($fileNameMatch.Groups[1].Success) { $fileNameMatch.Groups[1].Value } else { $fileNameMatch.Groups[2].Value }
  if ($originalFileName.StartsWith("utf-8''", [System.StringComparison]::OrdinalIgnoreCase)) {
    $originalFileName = [System.Uri]::UnescapeDataString($originalFileName.Substring(7))
  }

  $safeFileName = Get-SafeImageFileName $originalFileName.Trim('"')
  if ($null -eq $safeFileName) {
    Send-Text $Response 400 '{"ok":false,"message":"Format image accepte : jpg, png, webp ou gif."}' "application/json; charset=utf-8"
    return
  }

  $headerEnd = $body.IndexOf("`r`n`r`n")
  if ($headerEnd -lt 0) {
    Send-Text $Response 400 '{"ok":false,"message":"Image illisible."}' "application/json; charset=utf-8"
    return
  }

  $contentStart = $headerEnd + 4
  $contentEnd = $body.IndexOf("`r`n--$boundary", $contentStart)
  if ($contentEnd -le $contentStart) {
    Send-Text $Response 400 '{"ok":false,"message":"Image vide ou incomplete."}' "application/json; charset=utf-8"
    return
  }

  $imageBytes = New-Object byte[] ($contentEnd - $contentStart)
  [Array]::Copy($bytes, $contentStart, $imageBytes, 0, $imageBytes.Length)

  $imagesPath = Join-Path (Join-Path $Root "public") "images"
  if (-not (Test-Path -LiteralPath $imagesPath -PathType Container)) {
    New-Item -ItemType Directory -Path $imagesPath | Out-Null
  }

  $targetPath = Join-Path $imagesPath $safeFileName
  [System.IO.File]::WriteAllBytes($targetPath, $imageBytes)

  $sitePath = "images/$safeFileName"
  Send-Text $Response 200 "{""ok"":true,""path"":""$sitePath""}" "application/json; charset=utf-8"
}

function Resolve-LocalPath {
  param([string]$UrlPath)

  if ($UrlPath -eq "/" -or $UrlPath -eq "/admin" -or $UrlPath -eq "/admin/") {
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

  if ($cleanPath -notlike "*\*" -and [System.IO.Path]::GetExtension($cleanPath).ToLowerInvariant() -eq ".html") {
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

    if ($request.HttpMethod -eq "POST" -and $request.Url.AbsolutePath -eq "/api/images") {
      Send-ImageUploadResult $request $response
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
