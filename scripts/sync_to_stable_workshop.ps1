# Dev (IKFRVP-v2) -> stable Steam Workshop upload folder (3724847841).
param(
    [string]$DevRoot = "C:\Users\mpass\Desktop\IKFRVP-v2",
    [string]$WorkshopRoot = "C:\Users\mpass\Zomboid\Workshop\IKappaID's True Real World Vehicle Physics"
)

$ErrorActionPreference = "Stop"

$srcContents = Join-Path $DevRoot "Contents"
$dstContents = Join-Path $WorkshopRoot "Contents"
$srcWorkshop = Join-Path $DevRoot "workshop-stable.txt"

if (-not (Test-Path -LiteralPath $srcContents)) { throw "Missing dev Contents" }
if (-not (Test-Path -LiteralPath $srcWorkshop)) { throw "Missing stable workshop metadata" }
if (-not (Test-Path -LiteralPath $WorkshopRoot)) { New-Item -ItemType Directory -Path $WorkshopRoot -Force | Out-Null }

if (Test-Path -LiteralPath $dstContents) { Remove-Item -LiteralPath $dstContents -Recurse -Force }
Copy-Item -LiteralPath $srcContents -Destination $dstContents -Recurse -Force
Copy-Item -LiteralPath $srcWorkshop -Destination (Join-Path $WorkshopRoot "workshop.txt") -Force

Write-Host "Synced stable 2.5.0 -> $WorkshopRoot"
