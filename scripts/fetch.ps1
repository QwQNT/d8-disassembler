param (
    [string]$V8Branch = "13.8.258.18"
)

$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $true
$env:GIT_CONFIG_COUNT = "1"
$env:GIT_CONFIG_KEY_0 = "core.longpaths"
$env:GIT_CONFIG_VALUE_0 = "true"

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$targetPath = Join-Path $projectRoot "target"
$v8Path = Join-Path $targetPath "v8"
$depotToolsPath = Join-Path $targetPath "depot_tools"

Write-Host "[*] Checking fetch environment" -ForegroundColor Cyan
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw "[!] Git was not found in PATH."
}
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    throw "[!] Python 3 was not found in PATH."
}

Write-Host "[*] Preparing target" -ForegroundColor Cyan
New-Item -ItemType Directory -Path $targetPath -Force | Out-Null

Write-Host "[*] Preparing depot_tools" -ForegroundColor Cyan
$env:DEPOT_TOOLS_WIN_TOOLCHAIN = "0"
if (-not (Test-Path $depotToolsPath)) {
    git -c core.longpaths=true clone https://chromium.googlesource.com/chromium/tools/depot_tools.git $depotToolsPath
}
if (-not ($env:Path -split ";" | Where-Object { $_ -eq $depotToolsPath })) {
    $env:Path = "$depotToolsPath;$env:Path"
}
if (-not (Get-Command fetch -ErrorAction SilentlyContinue)) {
    throw "[!] fetch was not found after adding depot_tools to PATH."
}
if (-not (Get-Command gclient -ErrorAction SilentlyContinue)) {
    throw "[!] gclient was not found after adding depot_tools to PATH."
}

Write-Host "[*] Preparing V8 $V8Branch" -ForegroundColor Cyan
if (-not (Test-Path $v8Path)) {
    try {
        Push-Location $targetPath
        fetch v8
    }
    finally {
        Pop-Location
    }
}
try {
    Push-Location $v8Path
    git -c core.longpaths=true checkout $V8Branch
}
finally {
    Pop-Location
}
try {
    Push-Location $targetPath
    gclient sync -v
}
finally {
    Pop-Location
}

Write-Host "[*] V8 source is ready: $v8Path" -ForegroundColor Cyan
