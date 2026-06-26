# Dev Contents/mods -> Desktop\mods (flat layout for in-game playtest).
param(
    [string]$DevRoot = "C:\Users\mpass\Desktop\IKFRVP-v2",
    [string]$DesktopMods = "C:\Users\mpass\Desktop\mods"
)

$ErrorActionPreference = "Stop"

$srcMods = Join-Path $DevRoot "Contents\mods"
if (-not (Test-Path -LiteralPath $srcMods)) {
    throw "Missing: $srcMods"
}
if (-not (Test-Path -LiteralPath $DesktopMods)) {
    New-Item -ItemType Directory -Path $DesktopMods -Force | Out-Null
}

Get-ChildItem -LiteralPath $srcMods -Directory | ForEach-Object {
    $dst = Join-Path $DesktopMods $_.Name
    if (Test-Path -LiteralPath $dst) {
        Remove-Item -LiteralPath $dst -Recurse -Force
    }
    Copy-Item -LiteralPath $_.FullName -Destination $dst -Recurse -Force
    Write-Host ("Synced {0}" -f $_.Name)
}

Write-Host "Playtest folder: $DesktopMods"
