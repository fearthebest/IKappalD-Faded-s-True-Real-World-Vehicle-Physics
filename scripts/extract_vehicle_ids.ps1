# Extract Project Zomboid vehicle script IDs from installed Workshop/local mods.
# Workshop pages list mod titles, NOT script names — parse installed files under each workshop ID.
#
# Usage (from repository scripts/ folder):
#   .\extract_vehicle_ids.ps1 -CollectionId 3652192243 -OutFile "$env:USERPROFILE\Downloads\VehicleIDKI5.txt"
#   .\extract_vehicle_ids.ps1 -CollectionUrl "https://steamcommunity.com/sharedfiles/filedetails/?id=3652192243"
#   .\extract_vehicle_ids.ps1 -ModPattern '^\d{2}|^TrailerKI5|^63'
# Then: .\gen_ki5.ps1 -InputFile "$env:USERPROFILE\Downloads\VehicleIDKI5.txt"
#
# Collection 3652192243 = "KI5's temp B42.13+ MP collection" (81 workshop items).
# Subscribe in Steam first, then run this — Steam installs each item under:
#   workshop\content\108600\<workshopItemId>\

param(
    [string]$WorkshopRoot = 'C:\Program Files (x86)\Steam\steamapps\workshop\content\108600',
    [string]$CollectionId = '',
    [string]$CollectionUrl = '',
    [string[]]$ModPaths = @(),
    [string]$ModPattern = '',
    [string]$OutFile = '',
    [string]$MissingReportFile = '',
    [switch]$IncludeAllMods,
    [switch]$PreferB42 = $true,
    [switch]$FetchCollectionFromWeb = $true
)

$VehicleLine = [regex]::new('^\s*vehicle\s+([A-Za-z0-9_]+)\s*\{?\s*$', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
$ModuleLine = [regex]::new('^\s*module\s+([A-Za-z0-9_]+)\s*$', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
$B42Folder = [regex]::new('^42\.\d+')
$WorkshopIdInUrl = [regex]::new('(?:filedetails/\?id=|/id/)(\d+)')
# KI5 ids often start with a year digit (93fordF150, 78lamboCountach).
$ValidVehicleId = [regex]::new('^[A-Za-z0-9][A-Za-z0-9_]*$')

function Test-ValidVehicleScriptId {
    param([string]$Name)
    if (-not $Name -or $Name.Length -lt 2) { return $false }
    if (-not $ValidVehicleId.IsMatch($Name)) { return $false }
    if ($Name -match '^(?i)https?') { return $false }
    if ($Name -match '^(?i)(collection|module)$') { return $false }
    return $true
}

function Get-CollectionWorkshopIds {
    param([string]$Id, [bool]$UseWeb)
    $ids = [System.Collections.Generic.HashSet[string]]::new()
    if ($UseWeb) {
        try {
            $uri = "https://steamcommunity.com/sharedfiles/filedetails/?id=$Id"
            $html = (Invoke-WebRequest -Uri $uri -UseBasicParsing).Content
            foreach ($m in [regex]::Matches($html, 'filedetails/\?id=(\d+)')) {
                $wid = $m.Groups[1].Value
                if ($wid -ne $Id) { [void]$ids.Add($wid) }
            }
        } catch {
            Write-Warning "Could not fetch collection page: $_"
        }
    }
    return $ids
}

function Get-ModRootsFromWorkshopIds {
    param([System.Collections.Generic.HashSet[string]]$WorkshopIds, [string]$Root)
    $roots = [System.Collections.Generic.List[string]]::new()
    foreach ($wid in ($WorkshopIds | Sort-Object)) {
        $itemDir = Join-Path $Root $wid
        if (-not (Test-Path -LiteralPath $itemDir)) { continue }
        $modsDir = Join-Path $itemDir 'mods'
        if (Test-Path -LiteralPath $modsDir) {
            Get-ChildItem -LiteralPath $modsDir -Directory -ErrorAction SilentlyContinue |
                ForEach-Object { [void]$roots.Add($_.FullName) }
        } else {
            [void]$roots.Add($itemDir)
        }
    }
    return $roots
}

function Get-ModRoots {
    param([string]$Root)
    $roots = [System.Collections.Generic.List[string]]::new()
    if (-not (Test-Path -LiteralPath $Root)) { return $roots }
    Get-ChildItem -LiteralPath $Root -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $itemDir = $_.FullName
        $modsDir = Join-Path $itemDir 'mods'
        if (Test-Path -LiteralPath $modsDir) {
            Get-ChildItem -LiteralPath $modsDir -Directory | ForEach-Object { [void]$roots.Add($_.FullName) }
        } else {
            [void]$roots.Add($itemDir)
        }
    }
    return $roots
}

function Get-VehicleScriptFiles {
    param([string]$ModRoot)
    $candidates = @()
    if ($PreferB42) {
        Get-ChildItem -LiteralPath $ModRoot -Directory -ErrorAction SilentlyContinue |
            Where-Object { $B42Folder.IsMatch($_.Name) } |
            Sort-Object { [version]($_.Name -replace '^42\.','42.') } -Descending |
            ForEach-Object {
                $veh = Join-Path $_.FullName 'media\scripts\vehicles'
                if (Test-Path -LiteralPath $veh) { $candidates += $veh }
            }
    }
    $defaultVeh = Join-Path $ModRoot 'media\scripts\vehicles'
    if (Test-Path -LiteralPath $defaultVeh) { $candidates += $defaultVeh }
    $candidates | Select-Object -Unique
}

function Read-VehiclesFromFile {
    param([string]$Path)
    $module = 'Base'
    $found = [System.Collections.Generic.List[string]]::new()
    foreach ($line in [System.IO.File]::ReadLines($Path)) {
        $m = $ModuleLine.Match($line)
        if ($m.Success) {
            $module = $m.Groups[1].Value
            continue
        }
        if ($line -match '(?i)template\s+vehicle') { continue }
        $v = $VehicleLine.Match($line)
        if ($v.Success) {
            $name = $v.Groups[1].Value
            if (Test-ValidVehicleScriptId $name) {
                [void]$found.Add("$module.$name")
            }
        }
    }
    return $found
}

if ($CollectionUrl -and -not $CollectionId) {
    $m = $WorkshopIdInUrl.Match($CollectionUrl)
    if ($m.Success) { $CollectionId = $m.Groups[1].Value }
}

$collectionIds = $null
if ($CollectionId) {
    $collectionIds = Get-CollectionWorkshopIds -Id $CollectionId -UseWeb:$FetchCollectionFromWeb
    Write-Host "Collection $CollectionId : $($collectionIds.Count) workshop items in page"
}

$modRoots = [System.Collections.Generic.List[string]]::new()
foreach ($p in $ModPaths) {
    if ($p -and (Test-Path -LiteralPath $p)) { [void]$modRoots.Add((Resolve-Path -LiteralPath $p).Path) }
}

if ($modRoots.Count -eq 0 -and $collectionIds -and $collectionIds.Count -gt 0) {
    foreach ($r in (Get-ModRootsFromWorkshopIds -WorkshopIds $collectionIds -Root $WorkshopRoot)) {
        [void]$modRoots.Add($r)
    }
}

if ($modRoots.Count -eq 0) {
    foreach ($r in (Get-ModRoots -Root $WorkshopRoot)) {
        if ($IncludeAllMods) {
            [void]$modRoots.Add($r)
        } elseif ($ModPattern -and (Split-Path $r -Leaf) -match $ModPattern) {
            [void]$modRoots.Add($r)
        } elseif (-not $ModPattern -and -not $CollectionId) {
            if ((Split-Path $r -Leaf) -match '^\d{2}|^TrailerKI5|^63') {
                [void]$modRoots.Add($r)
            }
        }
    }
}

$installedCollection = [System.Collections.Generic.List[string]]::new()
$missingCollection = [System.Collections.Generic.List[string]]::new()
if ($collectionIds) {
    foreach ($wid in ($collectionIds | Sort-Object)) {
        $path = Join-Path $WorkshopRoot $wid
        if (Test-Path -LiteralPath $path) {
            [void]$installedCollection.Add($wid)
        } else {
            [void]$missingCollection.Add($wid)
        }
    }
    Write-Host "Installed from collection: $($installedCollection.Count) / $($collectionIds.Count)"
    if ($missingCollection.Count -gt 0) {
        Write-Host "Missing (subscribe in Steam, then launch game to download): $($missingCollection.Count)"
    }
}

$byMod = [ordered]@{}
$all = [System.Collections.Generic.HashSet[string]]::new()

foreach ($modRoot in ($modRoots | Sort-Object -Unique)) {
    $modName = Split-Path $modRoot -Leaf
    $vehDir = Get-VehicleScriptFiles -ModRoot $modRoot
    if (-not $vehDir) { continue }
    $ids = [System.Collections.Generic.HashSet[string]]::new()
    foreach ($dir in $vehDir) {
        Get-ChildItem -LiteralPath $dir -Filter '*.txt' -File -ErrorAction SilentlyContinue | ForEach-Object {
            foreach ($id in (Read-VehiclesFromFile -Path $_.FullName)) {
                [void]$ids.Add($id)
                [void]$all.Add($id)
            }
        }
    }
    if ($ids.Count -gt 0) {
        $byMod[$modName] = ($ids | Sort-Object)
    }
}

if ($all.Count -eq 0) {
    Write-Error "No vehicles found. Subscribe to the collection in Steam, launch PZ once to download, then re-run."
    exit 1
}

$lines = [System.Collections.Generic.List[string]]::new()
if ($CollectionId) {
    [void]$lines.Add("# KI5 collection $CollectionId")
    [void]$lines.Add("# https://steamcommunity.com/sharedfiles/filedetails/?id=$CollectionId")
}
foreach ($entry in $byMod.GetEnumerator()) {
    [void]$lines.Add('')
    [void]$lines.Add("# $($entry.Key)")
    $shortIds = $entry.Value | ForEach-Object {
        if ($_ -match '^Base\.(.+)$') { $matches[1] } else { $_ }
    } | Where-Object { Test-ValidVehicleScriptId $_ }
    if ($shortIds.Count -gt 0) {
        [void]$lines.Add(($shortIds -join ', '))
    }
}
$text = ($lines -join [Environment]::NewLine).TrimStart()

Write-Host "Mods with vehicles: $($byMod.Count)"
Write-Host "Unique vehicles: $($all.Count)"

if ($OutFile) {
    $utf8 = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($OutFile, $text, $utf8)
    Write-Host "Wrote $OutFile"
} else {
    Write-Output $text
}

if ($MissingReportFile -and $missingCollection.Count -gt 0) {
    $report = @(
        "# Not installed locally - subscribe on Steam collection page",
        "# Collection: https://steamcommunity.com/sharedfiles/filedetails/?id=$CollectionId",
        ''
    ) + ($missingCollection | ForEach-Object { "https://steamcommunity.com/sharedfiles/filedetails/?id=$_" })
    $utf8 = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($MissingReportFile, ($report -join [Environment]::NewLine), $utf8)
    Write-Host "Wrote missing list: $MissingReportFile"
}
