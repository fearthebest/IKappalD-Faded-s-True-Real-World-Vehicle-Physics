# Copy publish package from Desktop IKFRVP-v2 -> Zomboid mods folder (local playtest).
param(
    [string]$SourceRoot = "C:\Users\mpass\Desktop\IKFRVP-v2",
    [string]$GameModsRoot = "C:\Users\mpass\Zomboid\mods\IKFRVP-v2",
    [switch]$MirrorExtra
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $SourceRoot)) {
    throw "Path not found: $SourceRoot"
}
if (-not (Test-Path -LiteralPath $GameModsRoot)) {
    New-Item -ItemType Directory -Path $GameModsRoot -Force | Out-Null
}

$items = @(
    @{ Name = "workshop.txt"; IsDir = $false },
    @{ Name = "Contents"; IsDir = $true }
)

foreach ($item in $items) {
    $src = Join-Path $SourceRoot $item.Name
    $dst = Join-Path $GameModsRoot $item.Name
    if (-not (Test-Path -LiteralPath $src)) {
        throw "Missing source: $src"
    }
    if ($item.IsDir) {
        if (Test-Path -LiteralPath $dst) {
            Remove-Item -LiteralPath $dst -Recurse -Force
        }
        Copy-Item -LiteralPath $src -Destination $dst -Recurse -Force
    } else {
        Copy-Item -LiteralPath $src -Destination $dst -Force
    }
    Write-Host ("Synced {0}" -f $item.Name)
}

if ($MirrorExtra) {
    $preview = Join-Path $SourceRoot "preview.png"
    if (Test-Path -LiteralPath $preview) {
        Copy-Item -LiteralPath $preview -Destination (Join-Path $GameModsRoot "preview.png") -Force
        Write-Host "Synced preview.png"
    }
}

Write-Host "In-game mods folder updated: $GameModsRoot"
