param (
    [int]$Jobs = 4
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
$buildName = "out.gn\x64.release"
$buildPath = Join-Path $v8Path $buildName
$argsSource = Join-Path $PSScriptRoot "args.gn"
$argsTarget = Join-Path $buildPath "args.gn"

Write-Host "[*] Checking build environment" -ForegroundColor Cyan
if (-not (Test-Path (Join-Path $v8Path ".git"))) {
    throw "[!] '$v8Path' is not a V8 checkout."
}
if (-not (Test-Path (Join-Path $depotToolsPath ".git"))) {
    throw "[!] '$depotToolsPath' is not a depot_tools checkout."
}
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    throw "[!] Python 3 was not found in PATH."
}
if (-not (Get-Command cl -ErrorAction SilentlyContinue)) {
    throw "[!] MSVC cl.exe was not found in PATH. Run this script from a Visual Studio Developer PowerShell."
}
if (-not (Test-Path $argsSource)) {
    throw "[!] Missing GN args template: $argsSource"
}
$env:DEPOT_TOOLS_WIN_TOOLCHAIN = "0"
if (-not ($env:Path -split ";" | Where-Object { $_ -eq $depotToolsPath })) {
    $env:Path = "$depotToolsPath;$env:Path"
}
if (-not (Get-Command gn -ErrorAction SilentlyContinue)) {
    throw "[!] gn was not found after adding depot_tools to PATH."
}
if (-not (Get-Command ninja -ErrorAction SilentlyContinue)) {
    throw "[!] ninja was not found after adding depot_tools to PATH."
}

Write-Host "[*] Building D8 -- -j $Jobs" -ForegroundColor Cyan
New-Item -ItemType Directory -Path $buildPath -Force | Out-Null
Copy-Item -Path $argsSource -Destination $argsTarget -Force
try {
    Push-Location $v8Path
    gn gen $buildName
    ninja -C $buildName -j $Jobs d8
}
finally {
    Pop-Location
}

Write-Host "[*] D8 build output: $(Join-Path $v8Path $buildName)" -ForegroundColor Cyan
