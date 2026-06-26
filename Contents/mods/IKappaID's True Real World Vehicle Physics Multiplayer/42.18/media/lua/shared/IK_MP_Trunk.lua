-- SP trunk authority (A/B). MP port spec: AUTHORITY.md section 5.3 — server apply + client mirror only.
require "IK_MP_Core"
require "IK_MP_Profiles"
require "IK_MP_TrunkRegistry"

IK_MP.Trunk = IK_MP.Trunk or {}

local T = IK_MP.Trunk
local C = IK_MP
local P = IK_MP.Profiles
local R = IK_MP.TrunkRegistry

T.TrunkBuild = "2026-05-29-trunk-2.5.0"
T._modTrunkScripts = nil
T._serverEventsRegistered = false
T._clientMirrorEventsRegistered = false
T._hooksInstalled = false
T._allowMutation = false
T._trunkMultSignature = nil
T._trunkPlayerTicks = nil
T._mirrorByVehicleId = {}
T._lastMirrorPushSig = {}
T._trunkSyncCooldown = {}
T._serverTrunkTuneCooldown = {}
local TRUNK_SYNC_COOLDOWN_TICKS = 90
local SERVER_TRUNK_TUNE_COOLDOWN = 60

local ORGANIZED_MULT = 1.3
local STATIONARY_SPEED_KMH = 1.0
local SERVER_TICK_INTERVAL = 180
local inCapacityHook = false

local origGetEffectiveCapacity = nil
local origGetCapacity = nil
local origGetMaxWeight = nil
local origHasRoomFor = nil
local origGetContentsWeight = nil
local origPartGetContainerCapacity = nil

local _baseByContainer = setmetatable({}, { __mode = "k" })
local _baseByPart = setmetatable({}, { __mode = "k" })
local _baseByItem = setmetatable({}, { __mode = "k" })
local _classifyCache = {}

-- Forward declarations (Kahlua: locals used before `local function` assignment stay nil).
local readItemBase
local readPartScriptBase

local function multIsUnity(mult)
    return math.abs(mult - 1.0) < 1e-6
end

local function scaledCapacity(base, mult)
    if base == nil or base <= 0 then
        return nil
    end
    if multIsUnity(mult) then
        return base
    end
    return math.max(1, math.floor(base * mult + 0.5))
end

local function trunkFeatureActive()
    return C.isActiveHere() and C.isEnabled() and C.isTrunkTuneEnabled()
end

local function shouldApply()
    return trunkFeatureActive()
end

local function absVehicleSpeedKmh(vehicle)
    if not vehicle or not vehicle.getCurrentSpeedKmHour then
        return 0
    end
    local speed = C.finiteNumber(vehicle:getCurrentSpeedKmHour()) or 0
    if speed < 0 then
        speed = -speed
    end
    return speed
end

local function vehicleIsSafeForCapacityApply(vehicle)
    return absVehicleSpeedKmh(vehicle) <= STATIONARY_SPEED_KMH
end

local function clearWeakTable(t)
    if not t then
        return
    end
    for key in pairs(t) do
        t[key] = nil
    end
end

local function containerVehicle(container)
    if not container then
        return nil
    end
    if container.getVehicle then
        local vehicle = container:getVehicle()
        if vehicle then
            return vehicle
        end
    end
    if container.getVehiclePart then
        local part = container:getVehiclePart()
        if part and part.getVehicle then
            return part:getVehicle()
        end
    end
    if container.getParent and instanceof then
        local parent = container:getParent()
        if parent and instanceof(parent, "BaseVehicle") then
            return parent
        end
        if parent and instanceof(parent, "VehiclePart") and parent.getVehicle then
            return parent:getVehicle()
        end
    end
    return nil
end

local function partIdLower(part)
    if not part or not part.getId then
        return ""
    end
    return string.lower(tostring(part:getId() or ""))
end

local function isGasolineContainer(container)
    if not container or not container.getContentType then
        return false
    end
    local ct = container:getContentType()
    if ct == nil then
        return false
    end
    return string.lower(tostring(ct)) == "gasoline"
end

local function partIsFluidOrExcluded(part)
    if not part then
        return true
    end
    local id = partIdLower(part)
    if id == "" then
        return false
    end
    if string.find(id, "glove", 1, true) then
        return true
    end
    if string.find(id, "gas", 1, true) and string.find(id, "tank", 1, true) then
        return true
    end
    if string.find(id, "muffler", 1, true) or string.find(id, "battery", 1, true) then
        return true
    end
    if string.find(id, "tire", 1, true) or string.find(id, "wheel", 1, true) then
        return true
    end
    if part.getContainerContentType then
        local ct = part:getContainerContentType()
        if ct and string.lower(tostring(ct)) == "gasoline" then
            return true
        end
    end
    return false
end

local function vehicleScriptFullName(vehicle)
    if not vehicle or not vehicle.getScript then
        return ""
    end
    local script = vehicle:getScript()
    return C.getScriptFullName(script) or ""
end

local function collectRosterScriptNames(into, rosterTable)
    if not into or not rosterTable then
        return
    end
    for _, names in pairs(rosterTable) do
        if type(names) == "table" then
            for i = 1, #names do
                local name = names[i]
                if type(name) == "string" and name ~= "" then
                    into[name] = true
                end
            end
        end
    end
end

function T.initTrunkScriptSets()
    if T._modTrunkScripts then
        return
    end
    T._modTrunkScripts = {}
    collectRosterScriptNames(T._modTrunkScripts, IK_MP_KI5_Roster)
    collectRosterScriptNames(T._modTrunkScripts, IK_MP_ATA_Roster)
    collectRosterScriptNames(T._modTrunkScripts, IK_MP_FHQ_Roster)
    collectRosterScriptNames(T._modTrunkScripts, IK_MP_Autotsar_Roster)
    collectRosterScriptNames(T._modTrunkScripts, IK_MP_Misc_Roster)
end

-- Physics vehicleMap includes KI5/FHQ rosters — trunk must not treat those as vanilla-only.
local function scriptUsesModTrunkRules(fullName)
    if not fullName or fullName == "" then
        return false
    end
    T.initTrunkScriptSets()
    return T._modTrunkScripts[fullName] == true
end

-- True vanilla only: in physics map but NOT in KI5/FHQ/ATA/Misc trunk rosters (CarNormal, Van, …).
local function scriptUsesVanillaTrunkOnly(fullName)
    if not fullName or fullName == "" or not P or not P.profileIdForScriptName then
        return false
    end
    if scriptUsesModTrunkRules(fullName) then
        return false
    end
    return P.profileIdForScriptName(fullName) ~= nil
end

function T.isVanillaTrunkVehicle(vehicle)
    return scriptUsesVanillaTrunkOnly(vehicleScriptFullName(vehicle))
end

function T.isModTrunkVehicle(vehicle)
    local fullName = vehicleScriptFullName(vehicle)
    if fullName == "" then
        return false
    end
    return scriptUsesModTrunkRules(fullName)
end

local function containerUsesVanillaTrunkPath(container)
    return T.isVanillaTrunkVehicle(containerVehicle(container))
end

-- Vanilla gate: strict TruckBed/Trunk/TrailerTrunk only (unchanged from working CarNormal path).
local function qualifiesVanillaTrunkTune(container, vehicle, part)
    if not container or not vehicle or isGasolineContainer(container) then
        return false
    end
    if partIsFluidOrExcluded(part) then
        return false
    end
    local typ = ""
    if container.getType then
        typ = tostring(container:getType() or "")
    end
    local partId = partIdLower(part)
    return R.matchesVanillaTrunkProfile(typ, partId, part)
end

-- Mod gate: registry names + script/item cargo capacity (KI5, Bushmaster, …).
local function qualifiesModTrunkTune(container, vehicle, part)
    if not container or not vehicle or isGasolineContainer(container) then
        return false
    end
    if partIsFluidOrExcluded(part) then
        return false
    end
    local typ = ""
    if container.getType then
        typ = tostring(container:getType() or "")
    end
    local ltyp = string.lower(typ)
    local partId = partIdLower(part)

    if part then
        if readPartScriptBase(part) then
            return true
        end
        if part.getInventoryItem then
            local item = part:getInventoryItem()
            if item and readItemBase(item) then
                return true
            end
        end
    end
    return R.matchesModTrunkProfile(typ, partId, part, ltyp)
end

function T.qualifiesForTrunkTune(container, vehicle, part)
    if scriptUsesVanillaTrunkOnly(vehicleScriptFullName(vehicle)) then
        return qualifiesVanillaTrunkTune(container, vehicle, part)
    end
    return qualifiesModTrunkTune(container, vehicle, part)
end

function T.partIsCargoStorage(part)
    if not part or partIsFluidOrExcluded(part) then
        return false
    end
    if not part.getItemContainer then
        return false
    end
    local container = part:getItemContainer()
    if not container then
        return false
    end
    local vehicle = part.getVehicle and part:getVehicle() or containerVehicle(container)
    return T.qualifiesForTrunkTune(container, vehicle, part)
end

function T.isCargoContainer(container)
    if not container or not containerVehicle(container) then
        return false
    end
    if isGasolineContainer(container) then
        return false
    end

    local vehicle = containerVehicle(container)
    local part = nil
    if container.getVehiclePart then
        part = container:getVehiclePart()
    end
    if not part and vehicle then
        part = T.findPartForContainer(vehicle, container)
    end

    return T.qualifiesForTrunkTune(container, vehicle, part)
end

local function readUnhookedEffectiveCapacity(container)
    if not container then
        return nil
    end
    inCapacityHook = true
    local value = nil
    if origGetEffectiveCapacity then
        value = origGetEffectiveCapacity(container, nil)
    elseif container.getCapacity then
        value = container:getCapacity()
    end
    inCapacityHook = false
    return C.finiteNumber(value)
end

local function readUnhookedCapacity(container)
    if not container then
        return nil
    end
    inCapacityHook = true
    local value = nil
    if origGetCapacity then
        value = origGetCapacity(container)
    elseif container.getCapacity then
        value = container:getCapacity()
    end
    inCapacityHook = false
    return C.finiteNumber(value)
end

readItemBase = function(item)
    if not item then
        return nil
    end
    local cached = _baseByItem[item]
    if cached and cached > 0 then
        return cached
    end
    if item.getScriptItem then
        local si = item:getScriptItem()
        if si then
            if si.getCapacity then
                local cap = C.finiteNumber(si:getCapacity())
                if cap and cap > 0 then
                    _baseByItem[item] = cap
                    return cap
                end
            end
            if si.getMaxCapacity then
                local cap = C.finiteNumber(si:getMaxCapacity())
                if cap and cap > 0 then
                    _baseByItem[item] = cap
                    return cap
                end
            end
            if si.MaxCapacity ~= nil then
                local cap = tonumber(si.MaxCapacity)
                if cap and cap > 0 then
                    _baseByItem[item] = cap
                    return cap
                end
            end
        end
    end
    if item.getMaxCapacity then
        local cap = C.finiteNumber(item:getMaxCapacity())
        if cap and cap > 0 then
            return cap
        end
    end
    return nil
end

readPartScriptBase = function(part)
    if not part or not part.getScriptPart then
        return nil
    end
    local sp = part:getScriptPart()
    if not sp or not sp.container then
        return nil
    end
    local cap = tonumber(sp.container.capacity)
    if cap and cap > 0 then
        return cap
    end
    if sp.getContainerCapacity then
        local c = C.finiteNumber(sp:getContainerCapacity())
        if c and c > 0 then
            return c
        end
    end
    return nil
end

local function rememberContainerBase(container, base)
    if container and base and base > 0 then
        _baseByContainer[container] = base
        if container.getModData then
            local md = container:getModData()
            if md then
                md.IK_MP_trunkBase = base
            end
        end
        return base
    end
    return nil
end

local function globalTrunkProfiles()
    if not ModData or not ModData.getOrCreate then
        return nil
    end
    local root = ModData.getOrCreate("IK_MP")
    if not root.trunkProfiles then
        root.trunkProfiles = {}
    end
    return root.trunkProfiles
end

local function syncTrunkMultSignature()
    local sig = C.formatNumber(C.trunkCapacityMult())
    if T._trunkMultSignature == sig then
        return false
    end
    T._trunkMultSignature = sig
    T._lastMirrorPushSig = {}
    local profiles = globalTrunkProfiles()
    if profiles then
        for key in pairs(profiles) do
            profiles[key] = nil
        end
    end
    clearWeakTable(_baseByContainer)
    clearWeakTable(_baseByPart)
    clearWeakTable(_baseByItem)
    return true
end

local function playerHasOrganized(chr)
    if not chr or not chr.hasTrait or not CharacterTrait then
        return false
    end
    return chr:hasTrait(CharacterTrait.ORGANIZED)
end

local function capacitiesMatch(live, target)
    if live == nil or target == nil then
        return false
    end
    return math.abs(live - target) < 0.5
end

local function vehicleTrunkModTable(vehicle)
    if not vehicle or not vehicle.getModData then
        return nil
    end
    local md = vehicle:getModData()
    if not md then
        return nil
    end
    if not md.IK_MP_trunk then
        md.IK_MP_trunk = {}
    end
    return md.IK_MP_trunk
end

local function profileKeyFor(vehicle, part)
    local scriptName = ""
    if vehicle and vehicle.getScript then
        local script = vehicle:getScript()
        scriptName = C.getScriptFullName(script) or ""
    end
    local partId = partIdLower(part)
    if partId == "" then
        partId = "cargo"
    end
    return scriptName .. "|" .. partId
end

local function buildAuthorityRecord(base, sandboxMult)
    if not base or base <= 0 then
        return nil
    end
    local valueA = scaledCapacity(base, sandboxMult)
    if not valueA then
        return nil
    end
    local valueB = math.max(1, math.floor(base * ORGANIZED_MULT * sandboxMult + 0.5))
    if valueB < valueA then
        valueB = valueA
    end
    return {
        base = base,
        sandboxMult = sandboxMult,
        valueA = valueA,
        valueB = valueB,
    }
end

local function syncRecordToContainer(container, record)
    if not container or not record or not container.getModData then
        return
    end
    local md = container:getModData()
    if not md then
        return
    end
    md.IK_MP_trunkBase = record.base
    md.IK_MP_valueA = record.valueA
    md.IK_MP_valueB = record.valueB
    md.IK_MP_sandboxMult = record.sandboxMult
    rememberContainerBase(container, record.base)
end

local function mirrorRecordFromTable(record)
    if not record then
        return nil
    end
    return {
        base = record.base,
        sandboxMult = record.sandboxMult,
        valueA = record.valueA,
        valueB = record.valueB,
    }
end

-- Push vehicle/part modData to MP clients after server authority writes.
local function transmitTrunkAuthority(vehicle, part)
    if not vehicle then
        return
    end
    if vehicle.transmitModData then
        vehicle:transmitModData()
    end
    if part then
        if vehicle.transmitPartItem then
            vehicle:transmitPartItem(part)
        end
        if vehicle.transmitPartModData then
            vehicle:transmitPartModData(part)
        end
        if part.transmitModData then
            part:transmitModData()
        end
    end
end

local function authorityMultForRecord(record)
    if record and record.sandboxMult then
        return record.sandboxMult
    end
    return C.trunkCapacityMult()
end

local function validateAuthorityRecord(record, sandboxMult)
    if not record or not record.base or record.base <= 0 then
        return nil
    end
    sandboxMult = sandboxMult or authorityMultForRecord(record)
    if not record.valueA or not record.valueB or record.sandboxMult == nil
        or math.abs((record.sandboxMult or 0) - sandboxMult) > 1e-4 then
        local rebuilt = buildAuthorityRecord(record.base, sandboxMult)
        if not rebuilt then
            return nil
        end
        record.base = rebuilt.base
        record.sandboxMult = rebuilt.sandboxMult
        record.valueA = rebuilt.valueA
        record.valueB = rebuilt.valueB
    end
    if record.valueB < record.valueA then
        record.valueB = record.valueA
    end
    return record
end

-- Vanilla base order (1.0.1 StableTrunkExpansion) — do not change for CarNormal-style vehicles.
local function resolveScriptBaseOnly(container, part)
    if not container then
        return nil
    end

    local cached = _baseByContainer[container]
    if cached and cached > 0 then
        return cached
    end

    if container.getModData then
        local md = container:getModData()
        if md and type(md.IK_MP_trunkBase) == "number" and md.IK_MP_trunkBase > 0 then
            return rememberContainerBase(container, md.IK_MP_trunkBase)
        end
    end

    if not part and container.getVehiclePart then
        part = container:getVehiclePart()
    end
    if not part then
        local vehicle = containerVehicle(container)
        if vehicle then
            part = T.findPartForContainer(vehicle, container)
        end
    end

    if part then
        local partB = _baseByPart[part]
        if partB and partB > 0 then
            return rememberContainerBase(container, partB)
        end
        local scriptB = readPartScriptBase(part)
        if scriptB then
            _baseByPart[part] = scriptB
            return rememberContainerBase(container, scriptB)
        end
        if part.getInventoryItem then
            local item = part:getInventoryItem()
            local itemB = readItemBase(item)
            if itemB then
                if item then
                    _baseByItem[item] = itemB
                end
                return rememberContainerBase(container, itemB)
            end
        end
    end

    return nil
end

-- Mod base order: trunk item MaxCapacity first, then part script container.capacity.
local function resolveCanonicalBase(container, part)
    if not container then
        return nil
    end

    if not part and container.getVehiclePart then
        part = container:getVehiclePart()
    end
    if not part then
        local vehicle = containerVehicle(container)
        if vehicle then
            part = T.findPartForContainer(vehicle, container)
        end
    end

    if part and part.getInventoryItem then
        local item = part:getInventoryItem()
        local itemB = readItemBase(item)
        if itemB and itemB > 0 then
            if item then
                _baseByItem[item] = itemB
            end
            _baseByPart[part] = itemB
            return rememberContainerBase(container, itemB)
        end
    end

    if part then
        local scriptB = readPartScriptBase(part)
        if scriptB and scriptB > 0 then
            _baseByPart[part] = scriptB
            return rememberContainerBase(container, scriptB)
        end
    end

    local cached = _baseByContainer[container]
    if cached and cached > 0 then
        return cached
    end

    return nil
end

local function resolveBaseForContainer(container, part)
    if containerUsesVanillaTrunkPath(container) then
        return resolveScriptBaseOnly(container, part)
    end
    return resolveCanonicalBase(container, part)
end

local function readAuthorityFromTable(tableRef, key)
    if not tableRef or not key then
        return nil
    end
    local record = tableRef[key]
    if type(record) ~= "table" then
        return nil
    end
    return validateAuthorityRecord(record, authorityMultForRecord(record))
end

local function readMirrorFromVehicleCache(vehicle, part)
    if not vehicle or not vehicle.getId then
        return nil
    end
    local vehicleId = vehicle:getId()
    if not vehicleId then
        return nil
    end
    local trunkTable = T._mirrorByVehicleId[vehicleId]
    if not trunkTable then
        return nil
    end
    local record = readAuthorityFromTable(trunkTable, profileKeyFor(vehicle, part))
    if record then
        return mirrorRecordFromTable(record)
    end
    return nil
end

local function mirrorPushSignature(vehicleId, trunkTable, mult)
    local count = 0
    if type(trunkTable) == "table" then
        for _ in pairs(trunkTable) do
            count = count + 1
        end
    end
    return tostring(vehicleId) .. "|" .. C.formatNumber(mult) .. "|" .. tostring(count)
end

local function pushTrunkMirrorToPlayer(player, vehicle)
    if not C.hasServerJvm() or not sendServerCommand or not player or not vehicle or not vehicle.getModData then
        return false
    end
    local vehicleId = vehicle.getId and vehicle:getId()
    if not vehicleId then
        return false
    end
    local md = vehicle:getModData()
    if not md or type(md.IK_MP_trunk) ~= "table" then
        return false
    end
    local mult = C.trunkCapacityMult()
    local sig = mirrorPushSignature(vehicleId, md.IK_MP_trunk, mult)
    local username = "?"
    if player.getUsername then
        username = tostring(player:getUsername())
    end
    local cacheKey = username .. "|" .. tostring(vehicleId)
    if T._lastMirrorPushSig[cacheKey] == sig then
        return false
    end
    sendServerCommand(player, C.ModId, "TrunkMirror", {
        vehicleId = vehicleId,
        trunk = md.IK_MP_trunk,
        sandboxMult = mult,
    })
    T._lastMirrorPushSig[cacheKey] = sig
    return true
end

local function pushTrunkMirrorForVehicle(vehicle, preferredPlayer)
    if not vehicle then
        return 0
    end
    local pushed = 0
    if preferredPlayer and pushTrunkMirrorToPlayer(preferredPlayer, vehicle) then
        pushed = pushed + 1
    end
    if not C.canQueryOnlinePlayers() then
        return pushed
    end
    local online = C.safeGetOnlinePlayers()
    if not online or not online.size then
        return pushed
    end
    for i = 0, online:size() - 1 do
        local p = online:get(i)
        if p and p ~= preferredPlayer and p.getVehicle then
            if p:getVehicle() == vehicle then
                if pushTrunkMirrorToPlayer(p, vehicle) then
                    pushed = pushed + 1
                end
            end
        end
    end
    return pushed
end

local function storeAuthority(vehicle, part, container, record)
    if not record or not record.base then
        return nil
    end
    local key = profileKeyFor(vehicle, part)
    record.profileKey = key

    local vehicleTable = vehicleTrunkModTable(vehicle)
    if vehicleTable then
        vehicleTable[key] = record
    end

    local profiles = globalTrunkProfiles()
    if profiles then
        profiles[key] = record
    end

    if container then
        syncRecordToContainer(container, record)
    end
    return record
end

-- Physical storage: sandbox mult only (valueA). Organized stays vanilla via getEffectiveCapacity.
function T.authorityTarget(record, chr)
    if not record then
        return nil
    end
    return record.valueA
end

-- Client mirror: server-written modData or explicit TrunkMirror command only.
function T.getMirrorRecord(container)
    if not container then
        return nil
    end

    if container.getModData then
        local md = container:getModData()
        if md and type(md.IK_MP_valueA) == "number" and md.IK_MP_valueA > 0 then
            return mirrorRecordFromTable({
                base = md.IK_MP_trunkBase,
                sandboxMult = md.IK_MP_sandboxMult,
                valueA = md.IK_MP_valueA,
                valueB = md.IK_MP_valueB,
            })
        end
    end

    local vehicle = containerVehicle(container)
    if vehicle then
        local part = nil
        if container.getVehiclePart then
            part = container:getVehiclePart()
        end
        if not part then
            part = T.findPartForContainer(vehicle, container)
        end
        local cached = readMirrorFromVehicleCache(vehicle, part)
        if cached then
            return cached
        end
        local vehicleTable = vehicleTrunkModTable(vehicle)
        local record = readAuthorityFromTable(vehicleTable, profileKeyFor(vehicle, part))
        if record then
            return mirrorRecordFromTable(record)
        end
    end

    return nil
end

function T.getDisplayRecord(container)
    if T._allowMutation then
        return T.getAuthorityRecord(container)
    end
    return T.getMirrorRecord(container)
end

function T.getAuthorityRecord(container)
    if not container then
        return nil
    end
    if not T._allowMutation then
        return T.getMirrorRecord(container)
    end

    local sandboxMult = C.trunkCapacityMult()
    if container.getModData then
        local md = container:getModData()
        if md and type(md.IK_MP_trunkBase) == "number" and md.IK_MP_trunkBase > 0 then
            if md.IK_MP_valueA == nil or md.IK_MP_valueB == nil then
                md.IK_MP_trunkBase = nil
                md.IK_MP_trunkTarget = nil
                md.IK_MP_trunkMult = nil
            else
                local record = {
                    base = md.IK_MP_trunkBase,
                    sandboxMult = md.IK_MP_sandboxMult or sandboxMult,
                    valueA = md.IK_MP_valueA,
                    valueB = md.IK_MP_valueB,
                }
                local scriptBase = resolveBaseForContainer(container, nil)
                if scriptBase and scriptBase > 0 and math.abs(scriptBase - record.base) > 1 then
                    record.base = scriptBase
                    record = validateAuthorityRecord(record, sandboxMult)
                    syncRecordToContainer(container, record)
                else
                    record = validateAuthorityRecord(record, sandboxMult)
                end
                if record then
                    rememberContainerBase(container, record.base)
                    return record
                end
            end
        end
    end

    local vehicle = containerVehicle(container)
    local part = nil
    if container.getVehiclePart then
        part = container:getVehiclePart()
    end
    if not part and vehicle then
        part = T.findPartForContainer(vehicle, container)
    end

    if vehicle then
        local key = profileKeyFor(vehicle, part)
        local vehicleTable = vehicleTrunkModTable(vehicle)
        local record = readAuthorityFromTable(vehicleTable, key)
        if record then
            syncRecordToContainer(container, record)
            return record
        end
        local profiles = globalTrunkProfiles()
        record = readAuthorityFromTable(profiles, key)
        if record then
            storeAuthority(vehicle, part, container, record)
            return record
        end
    end

    return nil
end

function T.ensureAuthority(container)
    if not T._allowMutation or not container then
        return nil
    end

    local existing = T.getAuthorityRecord(container)
    if existing then
        return existing
    end

    local sandboxMult = C.trunkCapacityMult()

    local vehicle = containerVehicle(container)
    if not vehicle then
        return nil
    end

    local part = nil
    if container.getVehiclePart then
        part = container:getVehiclePart()
    end
    if not part then
        part = T.findPartForContainer(vehicle, container)
    end

    local base = resolveBaseForContainer(container, part)
    if not base or base <= 0 then
        return nil
    end

    local record = buildAuthorityRecord(base, sandboxMult)
    if not record then
        return nil
    end

    return storeAuthority(vehicle, part, container, record)
end

local function applyItemCapacity(item, target)
    if not item or not target then
        return false
    end
    local changed = false
    if item.setMaxCapacity then
        item:setMaxCapacity(target)
        changed = true
    end
    if item.setItemCapacity and item.getItemCapacity then
        item:setItemCapacity(target)
        changed = true
    end
    if item.getItemContainer then
        local inner = item:getItemContainer()
        if inner and inner.setCapacity then
            inner:setCapacity(target)
            changed = true
        end
    end
    return changed
end

function T.applyContainerCapacity(container, player, source)
    if not T._allowMutation or not shouldApply() or not container or not T.isCargoContainer(container) then
        return false
    end
    if not container.setCapacity then
        return false
    end

    syncTrunkMultSignature()

    local record = T.ensureAuthority(container)
    if not record then
        return false
    end

    local target = record.valueA
    if not target then
        return false
    end

    local live = readUnhookedCapacity(container)
    local mdCheck = container.getModData and container:getModData() or nil
    local priorTarget = mdCheck and mdCheck.IK_MP_appliedTarget
    local multChanged = priorTarget ~= nil and not capacitiesMatch(priorTarget, target)
    if capacitiesMatch(live, target) and not multChanged then
        if container.getModData then
            local md = container:getModData()
            if md then
                md.IK_MP_appliedTarget = target
            end
        end
        return false
    end

    container:setCapacity(target)
    syncRecordToContainer(container, record)
    if container.getModData then
        local md = container:getModData()
        if md then
            md.IK_MP_appliedTarget = target
        end
    end

    local part = container.getVehiclePart and container:getVehiclePart() or nil
    local vehicle = containerVehicle(container)
    if not part and vehicle then
        part = T.findPartForContainer(vehicle, container)
    end
    if part then
        _baseByPart[part] = record.base
        if part.setContainerCapacity then
            part:setContainerCapacity(target)
        end
        if part.getInventoryItem then
            local item = part:getInventoryItem()
            if item then
                _baseByItem[item] = record.base
                applyItemCapacity(item, target)
            end
        end
        transmitTrunkAuthority(vehicle, part)
    elseif vehicle then
        transmitTrunkAuthority(vehicle, nil)
    end

    if C.isDebugLoggingEnabled() then
        local used = nil
        if container.getCapacityWeight then
            used = container:getCapacityWeight()
        end
        C.debug(
            "trunk-apply["
                .. tostring(source or "?")
                .. "]: script="
                .. tostring(vehicleScriptFullName(vehicle))
                .. " part="
                .. tostring(partIdLower(part))
                .. " base="
                .. C.formatNumber(record.base)
                .. " live="
                .. C.formatNumber(live)
                .. " target="
                .. C.formatNumber(target)
                .. " used="
                .. C.formatNumber(used)
        )
    end

    return true
end

function T.findPartForContainer(vehicle, container)
    if not vehicle or not container then
        return nil
    end
    if container.getVehiclePart then
        local direct = container:getVehiclePart()
        if direct then
            return direct
        end
    end
    if not vehicle.getPartCount or not vehicle.getPartByIndex then
        return nil
    end

    local function walk(part)
        if not part then
            return nil
        end
        if part.getItemContainer then
            local c = part:getItemContainer()
            if c == container then
                return part
            end
        end
        if part.getChildCount and part.getChild then
            local n = part:getChildCount()
            for i = 0, n - 1 do
                local found = walk(part:getChild(i))
                if found then
                    return found
                end
            end
        end
        return nil
    end

    local count = vehicle:getPartCount()
    for i = 0, count - 1 do
        local found = walk(vehicle:getPartByIndex(i))
        if found then
            return found
        end
    end
    return nil
end

local function applyPart(part, vehicle, player, source)
    if not part or not T.partIsCargoStorage(part) then
        return 0
    end
    local applied = 0
    if part.getItemContainer then
        local container = part:getItemContainer()
        if container and T.applyContainerCapacity(container, player, source) then
            applied = applied + 1
        end
    end
    return applied
end

local function visitPartTree(part, vehicle, appliedCounter, player, source)
    if not part then
        return
    end
    appliedCounter.n = appliedCounter.n + applyPart(part, vehicle, player, source)
    if part.getChildCount and part.getChild then
        local n = part:getChildCount()
        for i = 0, n - 1 do
            visitPartTree(part:getChild(i), vehicle, appliedCounter, player, source)
        end
    end
end

function T.vehicleFromInventoryPage(page)
    if not page then
        return nil
    end
    if page.vehicle then
        return page.vehicle
    end
    if not page.backpacks then
        return nil
    end
    for i = 1, #page.backpacks do
        local button = page.backpacks[i]
        local container = button and button.inventory
        if container then
            local vehicle = containerVehicle(container)
            if vehicle then
                return vehicle
            end
        end
    end
    return nil
end

function T.requestServerTrunkSync(vehicle, source)
    if not C.runsTrunkClientHooks() or not C.hasClientJvm() then
        return false
    end
    if not shouldApply() or not vehicle or not sendClientCommand then
        return false
    end
    local vehicleId = vehicle.getId and vehicle:getId()
    if not vehicleId then
        return false
    end
    source = source or "client"
    if source == "inventoryPage" and T._mirrorByVehicleId[vehicleId] then
        return false
    end
    local cooldown = T._trunkSyncCooldown[vehicleId] or 0
    if cooldown > 0 and source ~= "sandbox-sync" and source ~= "OnEnterVehicle" then
        return false
    end
    T._trunkSyncCooldown[vehicleId] = TRUNK_SYNC_COOLDOWN_TICKS
    sendClientCommand(C.ModId, "TrunkTune", {
        vehicleId = vehicleId,
        source = source,
    })
    if C.isDebugLoggingEnabled() then
        C.debug("trunk-sync-request: vehicleId=" .. tostring(vehicleId) .. " source=" .. source)
    end
    return true
end

function T.onClientMirrorTick()
    if not C.runsTrunkClientHooks() or not trunkFeatureActive() then
        return
    end
    for vehicleId, remaining in pairs(T._trunkSyncCooldown) do
        if remaining <= 1 then
            T._trunkSyncCooldown[vehicleId] = nil
        else
            T._trunkSyncCooldown[vehicleId] = remaining - 1
        end
    end
end

function T.tuneVehicle(vehicle, source, player)
    if not T._allowMutation or not shouldApply() or not vehicle or not vehicle.getPartCount then
        return 0
    end
    if not vehicleIsSafeForCapacityApply(vehicle) then
        if C.isDebugLoggingEnabled() then
            C.debug(
                "trunk-tune-skip["
                    .. tostring(source)
                    .. "]: moving speedKmh="
                    .. C.formatNumber(absVehicleSpeedKmh(vehicle))
            )
        end
        return 0
    end
    if not T._hooksInstalled then
        T.installHooks()
    end

    local counter = { n = 0 }
    local count = vehicle:getPartCount()
    for i = 0, count - 1 do
        visitPartTree(vehicle:getPartByIndex(i), vehicle, counter, player, source)
    end

    if counter.n > 0 then
        transmitTrunkAuthority(vehicle, nil)
        if C.isDebugLoggingEnabled() then
            C.debug("trunk-tune[" .. tostring(source) .. "]: applied=" .. counter.n)
        end
        local mirrorPushed = pushTrunkMirrorForVehicle(vehicle, player)
        if mirrorPushed > 0 and C.isDebugLoggingEnabled() then
            C.debug("trunk-mirror: pushed count=" .. tostring(mirrorPushed) .. " source=" .. tostring(source))
        end
    end
    return counter.n
end

function T.tuneFromInventoryPage(page)
    if not page or not page.backpacks then
        return
    end
    local player = nil
    if page.player ~= nil and getSpecificPlayer then
        player = getSpecificPlayer(page.player)
    end
    if not player and getPlayer then
        player = getPlayer()
    end

    local applied = 0
    for i = 1, #page.backpacks do
        local button = page.backpacks[i]
        local container = button and button.inventory
        if container and T.applyContainerCapacity(container, player, "inventoryPage") then
            applied = applied + 1
        end
    end
    if applied > 0 and C.isDebugLoggingEnabled() then
        C.debug("trunk-tune[inventoryPage]: applied=" .. applied)
    end
end

local function physicalCapacityForContainer(container, liveValue)
    if not container or not T.isCargoContainer(container) or not shouldApply() then
        return liveValue
    end
    local record = T.getDisplayRecord(container)
    if not record or not record.valueA then
        return liveValue
    end
    return record.valueA
end

-- Vanilla: let game apply Organized on scaled capacity (1.0.1 behavior).
local function effectiveCapacityVanilla(container, chr, liveValue)
    if not origGetEffectiveCapacity then
        return liveValue
    end
    inCapacityHook = true
    local value = origGetEffectiveCapacity(container, chr)
    inCapacityHook = false
    return value
end

-- Mod: valueA = stock * mult, valueB = stock * Organized * mult.
local function effectiveCapacityMod(container, chr, liveValue)
    local record = T.getDisplayRecord(container)
    if not record then
        return liveValue
    end
    if playerHasOrganized(chr) and record.valueB then
        return record.valueB
    end
    return record.valueA or liveValue
end

local function effectiveCapacityForContainer(container, chr, liveValue)
    if not container or not T.isCargoContainer(container) or not shouldApply() then
        return liveValue
    end
    if containerUsesVanillaTrunkPath(container) then
        return effectiveCapacityVanilla(container, chr, liveValue)
    end
    return effectiveCapacityMod(container, chr, liveValue)
end

local function partEffectiveCapacity(part, chr, liveBase)
    if not part or not T.partIsCargoStorage(part) or not shouldApply() then
        return liveBase
    end
    if part.getItemContainer then
        local container = part:getItemContainer()
        if container then
            return effectiveCapacityForContainer(container, chr, liveBase)
        end
    end
    return liveBase
end

local function callOrigHasRoomFor(self, ...)
    if not origHasRoomFor then
        return false
    end
    return origHasRoomFor(self, ...)
end

local function itemWeightForRoomCheck(item)
    if not item then
        return 0
    end
    if item.getActualWeight then
        local w = item:getActualWeight()
        if w ~= nil then
            return tonumber(w) or 0
        end
    end
    if item.getUnequippedWeight then
        local w = item:getUnequippedWeight()
        if w ~= nil then
            return tonumber(w) or 0
        end
    end
    if item.getWeight then
        local w = item:getWeight()
        if w ~= nil then
            return tonumber(w) or 0
        end
    end
    return 0
end

local function argIsInventoryItem(value)
    return value ~= nil and instanceof and instanceof(value, "InventoryItem")
end

local function hasRoomForScaled(self, ...)
    if not origGetMaxWeight or not origGetContentsWeight then
        return callOrigHasRoomFor(self, ...)
    end

    local argc = select("#", ...)
    local chr = select(1, ...)
    local a = select(2, ...)
    local b = select(3, ...)

    local player = chr
    if argc == 1 and argIsInventoryItem(chr) then
        player = nil
        a = chr
        chr = nil
    end

    inCapacityHook = true
    local baseMax = origGetMaxWeight(self)
    local contents = origGetContentsWeight(self) or 0
    inCapacityHook = false

    local scaledMax = effectiveCapacityForContainer(self, player, baseMax)
    if not scaledMax then
        return callOrigHasRoomFor(self, ...)
    end

    if argc >= 3 and not argIsInventoryItem(a) then
        local projectedTotal = tonumber(a) or 0
        return projectedTotal <= scaledMax + 0.001
    end

    if argc >= 2 and argIsInventoryItem(a) then
        return (contents + itemWeightForRoomCheck(a)) <= scaledMax + 0.001
    end

    if argc >= 2 and not argIsInventoryItem(a) then
        local projectedTotal = tonumber(a) or 0
        return projectedTotal <= scaledMax + 0.001
    end

    if argc == 1 and argIsInventoryItem(a) then
        return (contents + itemWeightForRoomCheck(a)) <= scaledMax + 0.001
    end

    return callOrigHasRoomFor(self, ...)
end

function T.installHooks()
    if T._hooksInstalled or not shouldApply() then
        return T._hooksInstalled
    end
    if not ItemContainer or not ItemContainer.class or not __classmetatables or not __classmetatables[ItemContainer.class] then
        return false
    end

    local idx = __classmetatables[ItemContainer.class].__index
    if not idx or not idx.getEffectiveCapacity then
        return false
    end

    origGetEffectiveCapacity = idx.getEffectiveCapacity
    origGetCapacity = idx.getCapacity

    idx.getEffectiveCapacity = function(self, chr)
        if inCapacityHook then
            return origGetEffectiveCapacity(self, chr)
        end
        if not T.isCargoContainer(self) or not shouldApply() then
            return origGetEffectiveCapacity(self, chr)
        end
        inCapacityHook = true
        local base = origGetEffectiveCapacity(self, chr)
        local result = effectiveCapacityForContainer(self, chr, base)
        inCapacityHook = false
        return result
    end

    if origGetCapacity then
        idx.getCapacity = function(self)
            if inCapacityHook then
                return origGetCapacity(self)
            end
            if not T.isCargoContainer(self) or not shouldApply() then
                return origGetCapacity(self)
            end
            -- Vanilla path: unchanged — physical capacity stays vanilla after setCapacity.
            if containerUsesVanillaTrunkPath(self) then
                return origGetCapacity(self)
            end
            inCapacityHook = true
            local base = origGetCapacity(self)
            local result = physicalCapacityForContainer(self, base)
            inCapacityHook = false
            return result or base
        end
    end

    if idx.getMaxWeight then
        origGetMaxWeight = idx.getMaxWeight
        idx.getMaxWeight = function(self)
            if inCapacityHook then
                return origGetMaxWeight(self)
            end
            if not T.isCargoContainer(self) or not shouldApply() then
                return origGetMaxWeight(self)
            end
            inCapacityHook = true
            local base = origGetMaxWeight(self)
            local result = physicalCapacityForContainer(self, base)
            inCapacityHook = false
            return result
        end
    end

    if idx.hasRoomFor and idx.getMaxWeight and idx.getContentsWeight then
        origHasRoomFor = idx.hasRoomFor
        origGetContentsWeight = idx.getContentsWeight
        idx.hasRoomFor = function(self, ...)
            if inCapacityHook or not T.isCargoContainer(self) or not shouldApply() then
                return callOrigHasRoomFor(self, ...)
            end
            return hasRoomForScaled(self, ...)
        end
    end

    if VehiclePart and VehiclePart.class and __classmetatables[VehiclePart.class] then
        local vidx = __classmetatables[VehiclePart.class].__index
        if vidx and vidx.getContainerCapacity then
            origPartGetContainerCapacity = vidx.getContainerCapacity
            vidx.getContainerCapacity = function(self, chr)
                if inCapacityHook then
                    return origPartGetContainerCapacity(self, chr)
                end
                inCapacityHook = true
                local base = origPartGetContainerCapacity(self, chr)
                local result = partEffectiveCapacity(self, chr, base)
                inCapacityHook = false
                return result
            end
        end
    end

    T._hooksInstalled = true
    C.log("trunk capacity hooks installed")
    return true
end

function T.onServerEnterVehicle(player)
    if not T._allowMutation or not player or not player.getVehicle then
        return
    end
    local vehicle = player:getVehicle()
    if vehicle then
        T.tuneVehicle(vehicle, "OnEnterVehicle", player)
    end
end

local function decayServerTrunkTuneCooldowns()
    for vehicleId, remaining in pairs(T._serverTrunkTuneCooldown) do
        if remaining <= 1 then
            T._serverTrunkTuneCooldown[vehicleId] = nil
        else
            T._serverTrunkTuneCooldown[vehicleId] = remaining - 1
        end
    end
end

function T.onServerTickTrunk(player)
    if not T._allowMutation or not trunkFeatureActive() or not player then
        return
    end
    decayServerTrunkTuneCooldowns()
    T._trunkPlayerTicks = T._trunkPlayerTicks or {}
    local ticks = (T._trunkPlayerTicks[player] or 0) + 1
    T._trunkPlayerTicks[player] = ticks
    if ticks < SERVER_TICK_INTERVAL then
        return
    end
    T._trunkPlayerTicks[player] = 0
    if not player.getVehicle then
        return
    end
    local vehicle = player:getVehicle()
    if not vehicle or not vehicleIsSafeForCapacityApply(vehicle) then
        return
    end
    T.tuneVehicle(vehicle, "OnPlayerUpdate", player)
end

function T.onClientMirrorGameStart()
    if shouldApply() then
        T.installHooks()
    end
end

function T.onClientMirrorEnterVehicle(player)
    if not player or not player.getVehicle then
        return
    end
    T.installHooks()
    local vehicle = player:getVehicle()
    if vehicle then
        T.requestServerTrunkSync(vehicle, "OnEnterVehicle")
    end
end

function T.onClientMirrorRefreshInventory(page, phase)
    if not trunkFeatureActive() then
        return
    end
    T.installHooks()
    if phase == "buttonsAdded" or phase == "end" or phase == nil then
        local vehicle = T.vehicleFromInventoryPage(page)
        if vehicle then
            T.requestServerTrunkSync(vehicle, "inventoryPage")
        end
    end
end

function T.registerServerEvents()
    if T._serverEventsRegistered or not T._allowMutation then
        return
    end
    if Events and Events.OnEnterVehicle then
        Events.OnEnterVehicle.Add(T.onServerEnterVehicle)
    end
    if Events and Events.OnPlayerUpdate then
        Events.OnPlayerUpdate.Add(T.onServerTickTrunk)
    end
    T._serverEventsRegistered = true
end

function T.registerClientMirrorEvents()
    if T._clientMirrorEventsRegistered or not C.runsTrunkClientHooks() then
        return
    end
    if Events and Events.OnGameStart then
        Events.OnGameStart.Add(T.onClientMirrorGameStart)
    end
    if Events and Events.OnEnterVehicle then
        Events.OnEnterVehicle.Add(T.onClientMirrorEnterVehicle)
    end
    if Events and Events.OnRefreshInventoryWindowContainers then
        Events.OnRefreshInventoryWindowContainers.Add(T.onClientMirrorRefreshInventory)
    end
    if Events and Events.OnTick then
        Events.OnTick.Add(T.onClientMirrorTick)
    end
    T._clientMirrorEventsRegistered = true
end

local function trunkReadyLog(suffix)
    local modCount = "lazy"
    if T._modTrunkScripts then
        modCount = 0
        for _ in pairs(T._modTrunkScripts) do
            modCount = modCount + 1
        end
    end
    C.log(
        "trunk module ready build="
            .. T.TrunkBuild
            .. " mult="
            .. C.formatNumber(C.trunkCapacityMult())
            .. " modTrunkScripts="
            .. tostring(modCount)
            .. " vanilla-trunk=strict mod-trunk=registry+script"
            .. (suffix or "")
    )
end

function T.bootServer()
    if not C.isActiveHere() or not C.hasServerJvm() then
        return false
    end
    T._allowMutation = true
    _classifyCache = {}
    if not trunkFeatureActive() then
        C.log("trunk module ready (sandbox trunk tune disabled)")
        return true
    end
    syncTrunkMultSignature()
    trunkReadyLog(" role=server-authority")
    T.installHooks()
    T.registerServerEvents()
    return true
end

function T.bootClientMirror()
    if not C.isActiveHere() or not C.runsTrunkClientHooks() then
        return false
    end
    if not trunkFeatureActive() then
        C.log("trunk module ready (client mirror, trunk tune disabled)")
        return true
    end
    trunkReadyLog(" role=client-mirror serverSandbox=" .. tostring(C.hasServerSandbox()))
    T.registerClientMirrorEvents()
    T.installHooks()
    return true
end

function T.boot()
    local ok = false
    if C.hasServerJvm() then
        ok = T.bootServer() or ok
    end
    if C.runsTrunkClientHooks() then
        ok = T.bootClientMirror() or ok
    end
    return ok
end

function T.handleServerCommand(module, command, player, args)
    if module ~= C.ModId or command ~= "TrunkTune" or not T._allowMutation then
        return
    end
    if not trunkFeatureActive() or not args or not args.vehicleId or not getVehicleById then
        return
    end
    local source = args.source or "TrunkTune"
    if source == "inventoryPage" then
        local cooldown = T._serverTrunkTuneCooldown[args.vehicleId] or 0
        if cooldown > 0 then
            return
        end
        T._serverTrunkTuneCooldown[args.vehicleId] = SERVER_TRUNK_TUNE_COOLDOWN
    end
    local vehicle = getVehicleById(args.vehicleId)
    if not vehicle then
        return
    end
    T.tuneVehicle(vehicle, source, player)
end

function T.handleClientCommand(module, command, args)
    if module ~= C.ModId or command ~= "TrunkMirror" then
        return false
    end
    if type(args) ~= "table" or not args.vehicleId or type(args.trunk) ~= "table" then
        return false
    end
    T._mirrorByVehicleId[args.vehicleId] = args.trunk
    if C.isDebugLoggingEnabled() then
        C.debug("trunk-mirror: cached vehicleId=" .. tostring(args.vehicleId))
    end
    return true
end

function T.onServerSandboxApplied()
    T._mirrorByVehicleId = {}
    T._lastMirrorPushSig = {}
    local multChanged = syncTrunkMultSignature()
    if not C.runsTrunkClientHooks() or not trunkFeatureActive() then
        return
    end
    T.installHooks()
    if not multChanged then
        return
    end
    local player = getPlayer and getPlayer() or nil
    if not player and getSpecificPlayer then
        player = getSpecificPlayer(0)
    end
    if player and player.getVehicle then
        local vehicle = player:getVehicle()
        if vehicle then
            T.requestServerTrunkSync(vehicle, "sandbox-sync")
        end
    end
end

return T


