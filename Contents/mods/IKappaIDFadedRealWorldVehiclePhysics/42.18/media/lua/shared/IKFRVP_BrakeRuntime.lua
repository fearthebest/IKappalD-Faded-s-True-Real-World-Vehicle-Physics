-- Pass 2–4 runtime (JavaDocs BaseVehicle only — no scriptReloaded, no per-instance Load).
-- Docs: https://pz-wiki-modding.github.io/PZ-API-Docs/index.html
--       https://demiurgequantified.github.io/ProjectZomboidJavaDocs/
--
-- Layer A — VehicleScript (IKFRVP_Tuner at init): steeringClamp, wheelFriction, engineForce, …
-- Layer B — BaseVehicle each tick: setBrakingForce, setEngineFeature (park assist when cornering on).

require "IKFRVP_Core"
require "IKFRVP_Profiles"

IKFRVP.BrakeRuntime = IKFRVP.BrakeRuntime or {}

local R = IKFRVP.BrakeRuntime

R._installed = false
R._syncTickInterval = 45

local PARK_ASSIST_SPEED_KMH = 14
local PARK_ASSIST_STEER_FRAC = 0.65
local PARK_ASSIST_RELEASE_TICKS = 18
local PARK_ASSIST_REF_MASS = 1485

local PROFILE_PARK_ASSIST_SPEED_KMH = {
    Van = 20,
    StepVan = 20,
    Pickup = 18,
    CrewPickup = 18,
    SUV = 18,
    Wagon = 16,
}

local PROFILE_PARK_ASSIST_POWER_CAP = {
    Van = 0.90,
    StepVan = 0.92,
}

local PARK_ASSIST_POWER_MUL = {
    sport = 0.70,
}

local PROFILE_PARK_ASSIST_TARGET_MUL = {
    Compact     = 0.64,
    Sedan       = 0.62,
    ModernSedan = 0.62,
    Wagon       = 0.65,
    Offroad     = 0.66,
    Pickup      = 0.68,
    CrewPickup  = 0.68,
    SUV         = 0.68,
    Van         = 0.80,
    StepVan     = 0.78,
}

local function playerVehicle(player)
    if player and player.getVehicle then
        return player:getVehicle()
    end
    return nil
end

local function assistClassKey(cls)
    if cls == "compact" or cls == "sport" or cls == "heavy" then
        return cls
    end
    return "standard"
end

local function vehicleProfile(vehicle)
    if not vehicle or not vehicle.getScript then
        return nil
    end
    local script = vehicle:getScript()
    if not script or not IKFRVP.Profiles or not IKFRVP.Profiles.resolveProfile then
        return nil
    end
    return IKFRVP.Profiles.resolveProfile(script)
end

local function enginePowerFromScriptForce(vehicle, scriptForce)
    local q = 100
    if vehicle.getEngineQuality then
        local ok, value = pcall(function()
            return vehicle:getEngineQuality()
        end)
        if ok and value then
            q = value
        end
    end
    local qualityBoosted = q * 1.6
    if qualityBoosted > 100 then
        qualityBoosted = 100
    end
    local qualityModifier = math.max(0.6, qualityBoosted / 100)
    return math.floor(scriptForce * qualityModifier + 0.5)
end

local function parkAssistSpeedKmh(profile)
    if profile and profile.id and PROFILE_PARK_ASSIST_SPEED_KMH[profile.id] then
        return PROFILE_PARK_ASSIST_SPEED_KMH[profile.id]
    end
    return PARK_ASSIST_SPEED_KMH
end

local function tunedScriptMass(profile, script)
    if script then
        local scriptMass = IKFRVP.readScriptNumber(script, "getMass")
        if scriptMass and scriptMass > 0 then
            return scriptMass
        end
    end
    return profile and profile.mass
end

local function parkAssistPowerMul(profile, script, speedKmh)
    local mul
    if profile and profile.id and PROFILE_PARK_ASSIST_TARGET_MUL[profile.id] then
        mul = PROFILE_PARK_ASSIST_TARGET_MUL[profile.id]
    else
        local cls = assistClassKey(profile and profile.class or "standard")
        mul = PARK_ASSIST_POWER_MUL[cls] or 0.62
    end
    local mass = tunedScriptMass(profile, script)
    if mass and mass > PARK_ASSIST_REF_MASS * 1.12 then
        local massBoost = math.sqrt(mass / PARK_ASSIST_REF_MASS)
        mul = mul * math.min(1.15, massBoost)
    end
    local cap = 0.85
    if profile and profile.id and PROFILE_PARK_ASSIST_POWER_CAP[profile.id] then
        cap = PROFILE_PARK_ASSIST_POWER_CAP[profile.id]
    end
    return math.max(0.38, math.min(cap, mul))
end

function R.getTargetEngineForce(scriptFullName, script)
    if scriptFullName and IKFRVP.Tuner and IKFRVP.Tuner.engineTargets then
        local stored = IKFRVP.Tuner.engineTargets[scriptFullName]
        if stored and stored > 0 then
            return stored
        end
    end
    if script then
        return IKFRVP.readScriptNumber(script, "getEngineForce")
    end
    return nil
end

function R.getTargetBrakingForce(scriptFullName, script)
    if scriptFullName and IKFRVP.Tuner and IKFRVP.Tuner.brakeTargets then
        local stored = IKFRVP.Tuner.brakeTargets[scriptFullName]
        if stored and stored > 0 then
            return stored
        end
    end
    if script then
        return IKFRVP.readScriptNumber(script, "getBrakingForce")
    end
    return nil
end

local function applyEnginePower(vehicle, power)
    local quality = 100
    local loudness = 100
    if vehicle.getEngineQuality then
        local okQ, value = pcall(function()
            return vehicle:getEngineQuality()
        end)
        if okQ and value then
            quality = value
        end
    end
    if vehicle.getEngineLoudness then
        local okL, value = pcall(function()
            return vehicle:getEngineLoudness()
        end)
        if okL and value then
            loudness = value
        end
    end
    local enginePower = math.floor(power + 0.5)
    vehicle:setEngineFeature(quality, loudness, enginePower)
    if vehicle.transmitEngine then
        pcall(function()
            vehicle:transmitEngine()
        end)
    end
    return enginePower
end

function R.updateParkingTractionAssist(vehicle, state)
    if not IKFRVP.isCorneringTuningEnabled() or not vehicle then
        return false
    end
    if not vehicle.getScript or not vehicle.setEngineFeature or not vehicle.getEnginePower then
        return false
    end

    local script = vehicle:getScript()
    if not script then
        return false
    end

    local profile = vehicleProfile(vehicle)
    if profile and profile.class == "trailer" then
        return false
    end

    local scriptFullName = IKFRVP.getScriptFullName(script)
    local scriptForce = R.getTargetEngineForce(scriptFullName, script)
    if not scriptForce or scriptForce <= 0 then
        return false
    end

    local fullPower = enginePowerFromScriptForce(vehicle, scriptForce)
    local speedKmh = IKFRVP.readVehicleSpeedKmh(vehicle) or 999
    local assistMul = parkAssistPowerMul(profile, script, speedKmh)
    local assistPower = math.floor(fullPower * assistMul + 0.5)
    local steerFrac = IKFRVP.readVehicleSteerFraction(vehicle) or 0
    local speedGate = parkAssistSpeedKmh(profile)
    local shouldAssist = speedKmh < speedGate
        and steerFrac >= PARK_ASSIST_STEER_FRAC
        and IKFRVP.isVehicleAcceleratorPressed(vehicle)

    if shouldAssist then
        state.parkAssistReleaseTicks = 0
        local okSet, err = pcall(function()
            applyEnginePower(vehicle, assistPower)
        end)
        if not okSet then
            IKFRVP.debug("park-assist-fail: " .. tostring(scriptFullName) .. " " .. tostring(err))
        end
        if not state.parkAssistActive and IKFRVP.isDebugLoggingEnabled() then
            IKFRVP.debug(
                "park-assist-on: "
                .. tostring(scriptFullName)
                .. " speed="
                .. IKFRVP.formatNumber(speedKmh)
                .. " steerFrac="
                .. IKFRVP.formatNumber(steerFrac)
                .. " power="
                .. tostring(assistPower)
                .. "/"
                .. tostring(fullPower)
                .. " mul="
                .. IKFRVP.formatNumber(assistMul)
            )
        end
        state.parkAssistActive = true
        return true
    end

    if state.parkAssistActive then
        state.parkAssistReleaseTicks = (state.parkAssistReleaseTicks or 0) + 1
        if state.parkAssistReleaseTicks < PARK_ASSIST_RELEASE_TICKS then
            pcall(function()
                applyEnginePower(vehicle, assistPower)
            end)
            return true
        end
        local okSet, err = pcall(function()
            applyEnginePower(vehicle, fullPower)
        end)
        if not okSet then
            IKFRVP.debug("park-assist-off-fail: " .. tostring(scriptFullName) .. " " .. tostring(err))
        elseif IKFRVP.isDebugLoggingEnabled() then
            IKFRVP.debug("park-assist-off: " .. tostring(scriptFullName))
        end
        state.parkAssistActive = false
        state.parkAssistReleaseTicks = 0
        return true
    end

    return false
end

function R.syncVehicleBrakes(vehicle)
    if not vehicle or not IKFRVP.isEnabled() then
        return false
    end
    if not vehicle.getScript or not vehicle.setBrakingForce or not vehicle.getBrakingForce then
        return false
    end

    local script = vehicle:getScript()
    if not script then
        return false
    end

    local scriptFullName = IKFRVP.getScriptFullName(script)
    local target = R.getTargetBrakingForce(scriptFullName, script)
    if not target or target <= 0 then
        return false
    end

    local okGet, current = pcall(function()
        return vehicle:getBrakingForce()
    end)
    if not okGet or current == nil then
        return false
    end

    if math.abs(current - target) < 0.45 then
        return false
    end

    local okSet, err = pcall(function()
        vehicle:setBrakingForce(target)
    end)
    if not okSet then
        IKFRVP.debug("brake-sync-fail: " .. tostring(scriptFullName) .. " " .. tostring(err))
        return false
    end
    return true
end

function R.syncVehicleEngine(vehicle)
    if not vehicle or not IKFRVP.isEnabled() then
        return false
    end
    if not vehicle.getScript or not vehicle.setEngineFeature or not vehicle.getEnginePower then
        return false
    end

    local script = vehicle:getScript()
    if not script then
        return false
    end

    local scriptFullName = IKFRVP.getScriptFullName(script)
    local scriptForce = R.getTargetEngineForce(scriptFullName, script)
    if not scriptForce or scriptForce <= 0 then
        return false
    end

    local targetPower = enginePowerFromScriptForce(vehicle, scriptForce)
    local okGet, current = pcall(function()
        return vehicle:getEnginePower()
    end)
    if not okGet or current == nil then
        return false
    end

    if math.abs(current - targetPower) < math.max(12, targetPower * 0.04) then
        return false
    end

    local okSet, err = pcall(function()
        applyEnginePower(vehicle, targetPower)
    end)
    if not okSet then
        IKFRVP.debug("engine-sync-fail: " .. tostring(scriptFullName) .. " " .. tostring(err))
        return false
    end
    return true
end

function R.syncVehiclePhysics(vehicle, state)
    local brake = R.syncVehicleBrakes(vehicle)
    local engine = false
    if not state or not state.parkAssistActive then
        engine = R.syncVehicleEngine(vehicle)
    end
    return brake or engine
end

function R.onEnterVehicle(player)
    if not IKFRVP.isEnabled() then
        return
    end
    local vehicle = playerVehicle(player)
    if not vehicle then
        return
    end
    R._playerState = R._playerState or {}
    R._playerState[player] = {
        ticks = R._syncTickInterval,
        vehicle = vehicle,
        parkAssistActive = false,
        parkAssistReleaseTicks = 0,
    }
    R.syncVehicleBrakes(vehicle)
    R.syncVehicleEngine(vehicle)
    if IKFRVP.isDebugLoggingEnabled() then
        IKFRVP.logLiveManeuverProbe(vehicle, "enter")
    end
end

function R.onPlayerUpdate(player)
    if not IKFRVP.isEnabled() or not player then
        return
    end
    local vehicle = playerVehicle(player)
    if not vehicle then
        return
    end

    R._playerState = R._playerState or {}
    local state = R._playerState[player]
    if not state then
        state = { ticks = 0, vehicle = nil, parkAssistActive = false, parkAssistReleaseTicks = 0 }
        R._playerState[player] = state
    end

    if state.vehicle ~= vehicle then
        state.vehicle = vehicle
        state.ticks = R._syncTickInterval
        state.parkAssistActive = false
        state.parkAssistReleaseTicks = 0
        R.syncVehicleBrakes(vehicle)
        R.syncVehicleEngine(vehicle)
    end

    R.updateParkingTractionAssist(vehicle, state)

    state.ticks = state.ticks + 1
    if state.ticks >= R._syncTickInterval then
        state.ticks = 0
        R.syncVehiclePhysics(vehicle, state)
    end
end

function R.registerEvents()
    if R._installed then
        return
    end
    if Events and Events.OnEnterVehicle then
        Events.OnEnterVehicle.Add(R.onEnterVehicle)
    end
    if Events and Events.OnPlayerUpdate then
        Events.OnPlayerUpdate.Add(R.onPlayerUpdate)
    end
    R._installed = true
end

R.registerEvents()

return R
