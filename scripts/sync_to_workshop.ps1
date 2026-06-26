# Canonical source -> Workshop packing folder (Steam upload / in-game enable).
param(
    [string]$SourceRoot = "C:\Users\mpass\Desktop\MyProjectZomboid\My Mods\IKappaID's True Real World Vehicle Physics\StableAfterReboot\IKappaID's True Real World Vehicle Physics",
    [string]$WorkshopRoot = "C:\Users\mpass\Zomboid\Workshop\IKappaID's True Real World Vehicle Physics"
)

$ErrorActionPreference = "Stop"

$srcContents = Join-Path $SourceRoot "Contents"
$dstContents = Join-Path $WorkshopRoot "Contents"

if (-not (Test-Path -LiteralPath $srcContents)) {
    throw "Missing dev Contents: $srcContents"
}
if (-not (Test-Path -LiteralPath $WorkshopRoot)) {
    New-Item -ItemType Directory -Path $WorkshopRoot -Force | Out-Null
}

if (Test-Path -LiteralPath $dstContents) {
    Remove-Item -LiteralPath $dstContents -Recurse -Force
}
Copy-Item -LiteralPath $srcContents -Destination $dstContents -Recurse -Force

foreach ($leaf in @("workshop.txt", "preview.png")) {
    $srcFile = Join-Path $SourceRoot $leaf
    if (-not (Test-Path -LiteralPath $srcFile)) {
        throw "Missing upload file: $srcFile"
    }
    Copy-Item -LiteralPath $srcFile -Destination (Join-Path $WorkshopRoot $leaf) -Force
}

Write-Host "Synced Contents + workshop.txt + preview.png -> $WorkshopRoot"
Write-Host "Enable in-game from Workshop folder (not Zomboid\mods)."
