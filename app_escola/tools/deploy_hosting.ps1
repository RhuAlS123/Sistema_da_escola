# Build web for release (fora do OneDrive — evita erro ao gravar shaders) e publica no Firebase Hosting.
# Pré-requisito: Node.js + uma vez `npm i -g firebase-tools` e `firebase login` neste PC.
# Uso (na pasta app_escola):  powershell -ExecutionPolicy Bypass -File tools\deploy_hosting.ps1

$ErrorActionPreference = "Stop"
$app = Split-Path $PSScriptRoot -Parent
Set-Location $app

$tempBuild = Join-Path $env:TEMP "flutter_escola_web_build"
$webOut = Join-Path $app "build\web"

Write-Host ">> flutter build web --release --output $tempBuild"
if (Test-Path $tempBuild) { Remove-Item -Recurse -Force $tempBuild }
flutter build web --release --output $tempBuild
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ">> Copiando para build\web (Firebase Hosting usa esta pasta)"
New-Item -ItemType Directory -Force -Path (Split-Path $webOut) | Out-Null
if (Test-Path $webOut) { Remove-Item -Recurse -Force $webOut }
robocopy $tempBuild $webOut /E /NFL /NDL /NJH /NJS | Out-Null

$firebase = Get-Command firebase -ErrorAction SilentlyContinue
if (-not $firebase) {
    Write-Host ""
    Write-Host "Firebase CLI nao encontrado. Instale com: npm install -g firebase-tools"
    Write-Host "Depois: firebase login"
    Write-Host "E rode de novo este script, ou manualmente na pasta app_escola: firebase deploy --only hosting"
    exit 1
}

Write-Host ">> firebase deploy --only hosting"
firebase deploy --only hosting
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ""
Write-Host "Publicado. URLs tipicas (projeto app-escola-fda78):"
Write-Host "  https://app-escola-fda78.web.app"
Write-Host "  https://app-escola-fda78.firebaseapp.com"
