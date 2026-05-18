-- WORK IN PROGRESS (3.0.0) — BROKEN — DO NOT USE FOR GAMEPLAY.
-- Manual transmission addon only; requires main IKFRVP 2.0.x (IKappaIDFadedRealWorldVehiclePhysics).
-- Lua-only: clutch, stall, rev-match, changeTransmission to hold gear. Vanilla still auto-shifts.
-- No pcall (main mod rule). No third-party native patches.

require "IKFRVP_MT_Config"
require "IKFRVP_Profiles"

IKFRVP.ManualTransmission = IKFRVP.ManualTransmission or {}

local MT = IKFRVP.ManualTransmission

MT._installed = false
MT._vehicleState = MT._vehicleState or {}

local TICKS_SHIFT_LOCK = 18
local CLUTCH_ENGAGE_THRESHOLD = 0.82
local CLUTCH_DISENGAGE_THRESHOLD = 0.18
local STALL_SPEED_KMH = 4.5
local STALL_RPM = 820
local REV_MATCH_TICKS = 14
local ENFORCE_INTERVAL = 8

local INDEX_REVERSE = 0
local INDEX_NEUTRAL = 1
local INDEX_FIRST = 2

-- changeTransmission requires TransmissionNumber enum objects (JavaDocs), not strings.
local function tnFromIndex(index)
    index = tonumber(index)
    if index == nil then
        return nil
    end
    if TransmissionNumber and TransmissionNumber.fromIndex then
        local tn = TransmissionNumber.fromIndex(index)
        if tn then
            return tn
        end
    end
    if not TransmissionNumber then
        return nil
    end
    if index == INDEX_REVERSE and TransmissionNumber.R then
        return TransmissionNumber.R
    end
    if index == INDEX_NEUTRAL and TransmissionNumber.N then
        return TransmissionNumber.N
    end
    if index >= INDEX_FIRST then
        local speedName = "Speed" .. tostring(index - INDEX_FIRST + 1)
        if TransmissionNumber[speedName] then
            return TransmissionNumber[speedName]
        end
    end
    return nil
end

local function indexFromSpeedName(name)
    if name == nil then
        return nil
    end
    name = tostring(name)
    if name == "R" then
        return INDEX_REVERSE
    end
    if name == "N" then
        return INDEX_NEUTRAL
    end
    local speed = string.match(name, "^Speed(%d+)$")
    if speed then
        return INDEX_FIRST + tonumber(speed) - 1
    end
    return nil
end

local function indexFromTn(tn)
    if tn == nil then
        return INDEX_NEUTRAL
    end
    local asNumber = tonumber(tn)
    if asNumber ~= nil then
        return asNumber
    end
    local mapped = indexFromSpeedName(tostring(tn))
    if mapped ~= nil then
        return mapped
    end
    if instanceof and instanceof(tn, "TransmissionNumber") and tn.getIndex then
        local index = tonumber(tn:getIndex())
        if index ~= nil then
            return index
        end
    end
    return INDEX_NEUTRAL
end

local function isDrivableVehicle(vehicle)
    if not vehicle then
        return false
    end
    local script = IKFRVP.getVehicleScript(vehicle)
    if not script or not IKFRVP.Profiles or not IKFRVP.Profiles.resolveProfile then
        return true
    end
    local profile = IKFRVP.Profiles.resolveProfile(script)
    if profile and profile.class == "trailer" then
        return false
    end
    return true
end

local function playerVehicle(player)
    if player and player.getVehicle then
        return player:getVehicle()
    end
    return nil
end

local function vehicleId(vehicle)
    if vehicle and vehicle.getId then
        local id = vehicle:getId()
        if id ~= nil then
            return tostring(id)
        end
    end
    return nil
end

local function gearRatioCount(vehicle)
    local script = IKFRVP.getVehicleScript(vehicle)
    if not script then
        return 4
    end
    if script.getGearRatioCount then
        local count = script:getGearRatioCount()
        if count and count > 0 then
            return count
        end
    end
    local raw = script.gearRatioCount
    if raw ~= nil then
        local count = tonumber(raw)
        if count and count > 0 then
            return count
        end
    end
    return 4
end

local function maxForwardIndex(count)
    return INDEX_FIRST + count - 1
end

local function clampIndex(index, count)
    local maxIdx = maxForwardIndex(count)
    if index < INDEX_REVERSE then
        return INDEX_REVERSE
    end
    if index > maxIdx then
        return maxIdx
    end
    return index
end

function MT.getState(vehicle)
    local id = vehicleId(vehicle)
    if not id then
        return nil
    end
    MT._vehicleState[id] = MT._vehicleState[id] or {
        selected = INDEX_NEUTRAL,
        clutch = 0,
        stalled = false,
        shiftLock = 0,
        revMatchTicks = 0,
        clutchEnginePower = nil,
        enforceCooldown = 0,
    }
    return MT._vehicleState[id]
end

function MT.clearState(vehicle)
    local id = vehicleId(vehicle)
    if id then
        MT._vehicleState[id] = nil
    end
end

function MT.isManagingEngine(vehicle)
    if not vehicle or not IKFRVP.isManualTransmissionEnabled() then
        return false
    end
    local state = MT.getState(vehicle)
    if not state then
        return false
    end
    if state.revMatchTicks and state.revMatchTicks > 0 then
        return true
    end
    return state.clutch >= CLUTCH_DISENGAGE_THRESHOLD
end

function MT.isClutchEngaged(vehicle)
    if not vehicle or not IKFRVP.isManualTransmissionEnabled() then
        return false
    end
    local state = MT.getState(vehicle)
    if not state then
        return false
    end
    return state.clutch >= CLUTCH_DISENGAGE_THRESHOLD
end

function MT.gearLabel(index)
    index = tonumber(index) or INDEX_NEUTRAL
    if index == INDEX_REVERSE then
        return "R"
    end
    if index == INDEX_NEUTRAL then
        return "N"
    end
    return tostring(index - INDEX_FIRST + 1)
end

function MT.readRpm(vehicle)
    local rpm = nil
    if vehicle and vehicle.getVehicleEngineRPM then
        rpm = tonumber(vehicle:getVehicleEngineRPM())
    end
    if rpm == nil and vehicle and vehicle.getEngineSpeed then
        rpm = tonumber(vehicle:getEngineSpeed())
    end
    if rpm == nil then
        return 0
    end
    return rpm
end

function MT.applyTransmissionIndex(vehicle, index)
    if not vehicle or not vehicle.changeTransmission then
        return false
    end
    local tn = tnFromIndex(index)
    if not tn then
        return false
    end
    vehicle:changeTransmission(tn)
    return true
end

function MT.currentTransmissionIndex(vehicle)
    if not vehicle then
        return INDEX_NEUTRAL
    end
    if vehicle.getTransmissionNumberEnum then
        local mapped = indexFromTn(vehicle:getTransmissionNumberEnum())
        if mapped ~= nil then
            return mapped
        end
    end
    if vehicle.getTransmissionNumberLetter then
        local mapped = indexFromSpeedName(vehicle:getTransmissionNumberLetter())
        if mapped ~= nil then
            return mapped
        end
    end
    if vehicle.getTransmissionNumber then
        local index = tonumber(vehicle:getTransmissionNumber())
        if index ~= nil then
            return index
        end
    end
    return INDEX_NEUTRAL
end

function MT.setClutch(vehicle, value)
    local state = MT.getState(vehicle)
    if not state or not vehicle then
        return
    end
    local oldClutch = state.clutch
    state.clutch = IKFRVP.clamp(value, 0, 1) or 0
    local wasEngaged = oldClutch >= CLUTCH_ENGAGE_THRESHOLD
    local nowEngaged = state.clutch >= CLUTCH_ENGAGE_THRESHOLD
    if nowEngaged and not wasEngaged then
        MT.applyTransmissionIndex(vehicle, INDEX_NEUTRAL)
    elseif not nowEngaged and wasEngaged and state.selected ~= INDEX_NEUTRAL and not state.stalled then
        MT.applyTransmissionIndex(vehicle, state.selected)
    end
end

function MT.selectGear(vehicle, index)
    local state = MT.getState(vehicle)
    if not state or not vehicle then
        return false
    end
    local count = gearRatioCount(vehicle)
    local speed = IKFRVP.readVehicleSpeedKmh(vehicle) or 0

    if index == INDEX_REVERSE and speed > 12 then
        return false
    end
    if index == INDEX_REVERSE and speed > 2 and state.selected ~= INDEX_REVERSE then
        return false
    end

    state.selected = clampIndex(index, count)
    state.shiftLock = TICKS_SHIFT_LOCK
    state.stalled = false
    if state.clutch < CLUTCH_ENGAGE_THRESHOLD then
        MT.applyTransmissionIndex(vehicle, state.selected)
    end
    return true
end

function MT.shiftUp(vehicle)
    local state = MT.getState(vehicle)
    if not state then
        return false
    end
    local count = gearRatioCount(vehicle)
    if state.selected == INDEX_REVERSE then
        return MT.selectGear(vehicle, INDEX_NEUTRAL)
    end
    if state.selected < INDEX_FIRST then
        return MT.selectGear(vehicle, INDEX_FIRST)
    end
    if state.selected >= maxForwardIndex(count) then
        return false
    end
    return MT.selectGear(vehicle, state.selected + 1)
end

function MT.shiftDown(vehicle)
    local state = MT.getState(vehicle)
    if not state then
        return false
    end
    if state.selected > INDEX_FIRST then
        if IKFRVP.isManualTransmissionRevMatchEnabled() then
            state.revMatchTicks = REV_MATCH_TICKS
        end
        return MT.selectGear(vehicle, state.selected - 1)
    end
    if state.selected == INDEX_FIRST then
        return MT.selectGear(vehicle, INDEX_NEUTRAL)
    end
    if state.selected == INDEX_NEUTRAL then
        return MT.selectGear(vehicle, INDEX_REVERSE)
    end
    return false
end

local function restoreEngineAfterClutch(vehicle, state)
    if not state.clutchEnginePower then
        return
    end
    local brakeRuntime = IKFRVP.BrakeRuntime
    if brakeRuntime and brakeRuntime.syncVehicleEngine then
        brakeRuntime.syncVehicleEngine(vehicle)
    end
    state.clutchEnginePower = nil
end

local function applyClutchEngineCut(vehicle, state)
    if not vehicle.setEngineFeature or not vehicle.getEnginePower then
        return
    end
    local script = IKFRVP.getVehicleScript(vehicle)
    if not script then
        return
    end
    local scriptForce = IKFRVP.readScriptNumber(script, "getEngineForce")
    if not scriptForce or scriptForce <= 0 then
        return
    end

    local quality = 100
    local loudness = 100
    if vehicle.getEngineQuality then
        local q = tonumber(vehicle:getEngineQuality())
        if q then
            quality = q
        end
    end
    if vehicle.getEngineLoudness then
        local l = tonumber(vehicle:getEngineLoudness())
        if l then
            loudness = l
        end
    end

    local coef = IKFRVP.getManualTransmissionClutchCoef()
    local engaged = 1 - state.clutch
    local cut = coef * engaged
    if cut < 0.08 then
        cut = 0.08
    end

    local qMod = math.max(0.6, math.min(quality, 100) * 1.6 / 100)
    if qMod > 1 then
        qMod = 1
    end
    local target = math.floor(scriptForce * qMod * cut + 0.5)
    if target < 8 then
        target = 8
    end

    vehicle:setEngineFeature(quality, loudness, target)
    if vehicle.transmitEngine then
        vehicle:transmitEngine()
    end
    state.clutchEnginePower = target
end

local function triggerStall(vehicle, state)
    state.stalled = true
    state.selected = INDEX_NEUTRAL
    MT.applyTransmissionIndex(vehicle, INDEX_NEUTRAL)
    if vehicle.engineDoStalling then
        vehicle:engineDoStalling()
    elseif vehicle.shutOff then
        vehicle:shutOff()
    end
    if vehicle.transmitEngine then
        vehicle:transmitEngine()
    end
    IKFRVP.debug("manual-transmission: engine stalled")
end

local function shouldStallOnEngage(vehicle, state)
    if not IKFRVP.isManualTransmissionStallingEnabled() then
        return false
    end
    if state.stalled then
        return false
    end
    if state.selected <= INDEX_NEUTRAL then
        return false
    end
    if not vehicle.isEngineRunning or not vehicle:isEngineRunning() then
        return false
    end
    local speed = IKFRVP.readVehicleSpeedKmh(vehicle) or 0
    local rpm = MT.readRpm(vehicle)
    return speed < STALL_SPEED_KMH and rpm < STALL_RPM
end

local function applyRevMatch(vehicle, state)
    if state.revMatchTicks <= 0 then
        return
    end
    if not vehicle.setEngineFeature then
        state.revMatchTicks = state.revMatchTicks - 1
        return
    end
    local script = IKFRVP.getVehicleScript(vehicle)
    if not script then
        state.revMatchTicks = state.revMatchTicks - 1
        return
    end
    local scriptForce = tonumber(IKFRVP.readScriptNumber(script, "getEngineForce"))
    if not scriptForce or scriptForce <= 0 then
        state.revMatchTicks = state.revMatchTicks - 1
        return
    end

    state.revMatchTicks = state.revMatchTicks - 1
    local quality = 100
    local loudness = 100
    if vehicle.getEngineQuality then
        quality = tonumber(vehicle:getEngineQuality()) or quality
    end
    if vehicle.getEngineLoudness then
        loudness = tonumber(vehicle:getEngineLoudness()) or loudness
    end
    local blend = (state.revMatchTicks + 1) / REV_MATCH_TICKS
    local boost = 1.0 + blend * 0.35
    local target = math.floor(scriptForce * boost + 0.5)
    vehicle:setEngineFeature(quality, loudness, target)
    if vehicle.transmitEngine then
        vehicle:transmitEngine()
    end
end

function MT.enforceTransmission(vehicle, state)
    if not vehicle or not state then
        return
    end
    local engagedIndex = tonumber(state.selected) or INDEX_NEUTRAL
    if state.clutch >= CLUTCH_ENGAGE_THRESHOLD then
        engagedIndex = INDEX_NEUTRAL
    end

    local live = MT.currentTransmissionIndex(vehicle)
    if live ~= engagedIndex then
        local applied = MT.applyTransmissionIndex(vehicle, engagedIndex)
        if applied and IKFRVP.isDebugLoggingEnabled() then
            IKFRVP.debug(
                "manual-transmission: enforce "
                .. MT.gearLabel(live)
                .. " -> "
                .. MT.gearLabel(engagedIndex)
            )
        end
    end
end

local function tickGearHold(vehicle, state)
    state.enforceCooldown = state.enforceCooldown + 1
    if state.enforceCooldown >= ENFORCE_INTERVAL then
        state.enforceCooldown = 0
        MT.enforceTransmission(vehicle, state)
    end
end

function MT.simulateVehicle(player, vehicle)
    if not vehicle or not IKFRVP.isManualTransmissionEnabled() then
        return
    end
    if not isDrivableVehicle(vehicle) then
        return
    end
    if not vehicle.isDriver or not vehicle:isDriver(player) then
        return
    end

    local state = MT.getState(vehicle)
    if not state then
        return
    end

    if state.stalled and vehicle.isEngineRunning and vehicle:isEngineRunning() then
        state.stalled = false
    end

    if state.shiftLock > 0 then
        state.shiftLock = state.shiftLock - 1
    end

    applyRevMatch(vehicle, state)

    if state.clutch >= CLUTCH_DISENGAGE_THRESHOLD then
        applyClutchEngineCut(vehicle, state)
        tickGearHold(vehicle, state)
        return
    end

    restoreEngineAfterClutch(vehicle, state)

    if state.clutch <= CLUTCH_DISENGAGE_THRESHOLD and shouldStallOnEngage(vehicle, state) then
        triggerStall(vehicle, state)
        return
    end

    tickGearHold(vehicle, state)
end

function MT.handleCommand(player, args)
    if not IKFRVP.isManualTransmissionEnabled() or type(args) ~= "table" then
        return
    end

    local vehicle = playerVehicle(player)
    if not vehicle and args.vehicle and getVehicleById then
        vehicle = getVehicleById(args.vehicle)
    end
    if not vehicle then
        return
    end
    if not isDrivableVehicle(vehicle) then
        return
    end
    if not vehicle.isDriver or not vehicle:isDriver(player) then
        return
    end

    local action = args.action
    if action == "clutch" then
        MT.setClutch(vehicle, tonumber(args.value) or 0)
        return
    end
    if action == "shiftUp" then
        MT.shiftUp(vehicle)
        return
    end
    if action == "shiftDown" then
        MT.shiftDown(vehicle)
        return
    end
    if action == "neutral" then
        MT.selectGear(vehicle, INDEX_NEUTRAL)
        return
    end
    if action == "reverse" then
        MT.selectGear(vehicle, INDEX_REVERSE)
    end
end

function MT.onEnterVehicle(player)
    if not IKFRVP.isManualTransmissionEnabled() then
        return
    end
    local vehicle = playerVehicle(player)
    if not vehicle then
        return
    end
    local state = MT.getState(vehicle)
    state.selected = INDEX_NEUTRAL
    state.clutch = 0
    state.stalled = false
    state.shiftLock = 0
    state.revMatchTicks = 0
    state.enforceCooldown = 0
    MT.applyTransmissionIndex(vehicle, INDEX_NEUTRAL)
    IKFRVP.debug("manual-transmission: entered vehicle, neutral engaged")
end

function MT.onExitVehicle(player)
    local vehicle = playerVehicle(player)
    if vehicle then
        MT.clearState(vehicle)
    end
end

function MT.onPlayerUpdate(player)
    if not IKFRVP.isManualTransmissionEnabled() or not player then
        return
    end
    if type(isServer) == "function" and not isServer() then
        return
    end
    local vehicle = playerVehicle(player)
    if not vehicle then
        return
    end
    MT.simulateVehicle(player, vehicle)
end

function MT.buildHudState(vehicle)
    local state = MT.getState(vehicle)
    if not state then
        return nil
    end
    return {
        gear = MT.gearLabel(state.selected),
        clutch = state.clutch,
        stalled = state.stalled,
        rpm = MT.readRpm(vehicle),
        live = MT.currentTransmissionIndex(vehicle),
    }
end

function MT.registerEvents()
    if MT._installed then
        return
    end
    if Events and Events.OnEnterVehicle then
        Events.OnEnterVehicle.Add(MT.onEnterVehicle)
    end
    if Events and Events.OnExitVehicle then
        Events.OnExitVehicle.Add(MT.onExitVehicle)
    end
    if Events and Events.OnPlayerUpdate then
        Events.OnPlayerUpdate.Add(MT.onPlayerUpdate)
    end
    if Events and Events.OnSwitchVehicleSeat then
        Events.OnSwitchVehicleSeat.Add(MT.onEnterVehicle)
    end
    MT._installed = true
end

MT.registerEvents()

return MT
