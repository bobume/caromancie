#!/usr/bin/env pwsh
<#
Génère un bandeau horizontal à partir de `public/images/hero_caromancie.png`.
Nécessite ImageMagick (commande `magick`) dans le PATH.
Usage :
  cd 'C:/Users/Christophe/Desktop/caromancie'
  .\scripts\make_hero_horizontal.ps1
#>

$src = Join-Path $PSScriptRoot '..\public\images\hero_caromancie.png'
$outDir = Join-Path $PSScriptRoot '..\public\images'

if (-not (Test-Path $src)) {
    Write-Error "Fichier source introuvable : $src"
    exit 2
}

if (-not (Get-Command magick -ErrorAction SilentlyContinue)) {
    Write-Error "ImageMagick (commande 'magick') introuvable. Installez-le depuis https://imagemagick.org/"
    exit 3
}

Write-Host "Génération des bandeaux horizontaux à partir de : $src" -ForegroundColor Cyan

$pairs = @(
    @{ w=1600; h=600; ph=520; out='hero-1600.jpg' },
    @{ w=1200; h=450; ph=420; out='hero-1200.jpg' }
)

foreach ($p in $pairs) {
    $width = $p.w; $height = $p.h; $pH = $p.ph
    $out = Join-Path $outDir $p.out
    Write-Host " - création : $out ($width x $height)" -ForegroundColor Green

    & magick $src '-resize' "${width}x${height}^" '-gravity' 'center' '-extent' "${width}x${height}" '-blur' '0x8' '-modulate' '100,70' '(' $src '-resize' "x${pH}" ')' '-gravity' 'East' '-geometry' '+60+0' '-composite' $out

    if ($LASTEXITCODE -ne 0) {
        Write-Error "Échec lors de la génération de $out"
    } else {
        Write-Host "Fichier créé : $out" -ForegroundColor Yellow
    }
}

Write-Host "Terminé." -ForegroundColor Cyan
