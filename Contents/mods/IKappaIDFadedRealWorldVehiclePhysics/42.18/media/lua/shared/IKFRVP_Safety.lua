-- Glitch guard: server-authoritative in MP. Only the host/server detects trips, reverts
-- sandbox, and re-tunes VehicleScripts. Clients mirror trip state via ModData + command.
require "IKFRVP_Core"

IKFRVP.Safety = IKFRVP.Safety or {}

local S = IKFRVP.Safety
local MOD_DATA_KEY = "IKFRVP_SafetyState"

S.tripped = S.tripped or false
S.tripReason = S.tripReason or nil

local PROBE_EVERY_TICKS = 12
local SINK_DROP_Z = 0.12
local SINK_WINDOW_TICKS = 28
local TILT_LIMIT = 0.38
local MONITOR_SPEED_KMH = 24
local JITTER_SAMPLES = 10
local JITTER_THRESHOLD = 0.028
local JITTER_HITS = 6
local RETUNE_COOLDOWN_TICKS = 900

local EXPERIMENTAL_SANDBOX_DEFAULTS = {
    HandlingPhysics = false,
    SteeringResponseMult = 1.0,
    SteeringClampMult = 1.0,
    WheelGripMult = 1.0,
    BodyRollMult = 1.0,
    SuspensionFirmness = 1.0,
}

local function playerState(player)
    S._players = S._players or {}
    local state = S._players[player]
    if not state then
        state = {
            ticks = 0,
            zHistory = {},
            zDropStart = nil,
            zDropStartZ = nil,
            jitterHits = 0,
            retuneCooldown = 0,
        }
        S._players[player] = state
    end
    return state
end

function S.refreshTripState()
    if not ModData or not ModData.getOrCreate then
        return
    end
    local stored = ModData.getOrCreate(MOD_DATA_KEY)
    if stored and stored.tripped == true then
        S.tripped = true
        S.tripReason = stored.reason or S.tripReason or "persisted"
    end
end

function S.blocksExperimental()
    S.refreshTripState()
    return S.tripped == true
end

function S.isMonitoringActive()
    if not IKFRVP.hasPhysicsAuthority() then
        return false
    end
    if not IKFRVP.isEnabled() or not IKFRVP.isGlitchGuardEnabled() or S.blocksExperimental() then
        return false
    end
    if not IKFRVP.boolOption("HandlingPhysics", false) then
        return false
    end
    return true
end

local function persistTrip(reason, vehicleName)
    if not ModData or not ModData.getOrCreate then
        return
    end
    local stored = ModData.getOrCreate(MOD_DATA_KEY)
    if not stored then
        return
    end
    stored.tripped = true
    stored.reason = tostring(reason or "unknown")
    stored.vehicle = tostring(vehicleName or "unknown")
    stored.version = IKFRVP.Version
    stored.at = stored.at or (getTimestampMs and getTimestampMs() or 0)
    if ModData.transmit then
        ModData.transmit(MOD_DATA_KEY)
    end
end

function S.mirrorRecommendedSandbox()
    local root = SandboxVars and SandboxVars.IKFRVP
    if not root then
        return
    end
    for key, value in pairs(EXPERIMENTAL_SANDBOX_DEFAULTS) do
        root[key] = value
    end
end

function S.applyRecommendedSandbox()
    if getSandboxOptions then
        local opts = getSandboxOptions()
        if opts and opts.getOptionByName then
            for key, value in pairs(EXPERIMENTAL_SANDBOX_DEFAULTS) do
                local opt = opts:getOptionByName("IKFRVP." .. key)
                if opt and opt.setValue then
                    opt:setValue(value)
                end
            end
            if opts.toLua then
                opts:toLua()
            end
        end
    end
    S.mirrorRecommendedSandbox()
end

function S.retuneWithoutExperimental()
    if not IKFRVP.hasPhysicsAuthority() then
        return
    end
    if not IKFRVP.Tuner or not IKFRVP.Tuner.processAllScripts then
        require "IKFRVP_Tuner"
    end
    if not IKFRVP.Tuner or not IKFRVP.Tuner.processAllScripts then
        return
    end
    IKFRVP.Tuner.appliedSignatures = {}
    IKFRVP.Tuner.processAllScripts("glitch-guard")
end

local function notifyClientsTrip(reason, vehicleName)
    if not IKFRVP.hasPhysicsAuthority() then
        return
    end
    if not sendServerCommand then
        return
    end
    sendServerCommand(IKFRVP.CommandModule, "GlitchGuardTripped", {
        reason = tostring(reason or "unknown"),
        vehicle = tostring(vehicleName or "unknown"),
        version = IKFRVP.Version,
    })
end

function S.applyClientTripMirror(args)
    S.tripped = true
    S.tripReason = args and args.reason or S.tripReason or "server-trip"
    S.mirrorRecommendedSandbox()
end

function S.trip(reason, vehicle)
    if not IKFRVP.hasPhysicsAuthority() then
        return
    end
    if S.tripped then
        return
    end
    S.tripped = true
    S.tripReason = tostring(reason or "physics-glitch")
    local vehicleName = vehicle and IKFRVP.getVehicleScriptName(vehicle) or "unknown"

    persistTrip(S.tripReason, vehicleName)
    S.applyRecommendedSandbox()
    S.retuneWithoutExperimental()
    notifyClientsTrip(S.tripReason, vehicleName)

    IKFRVP.log(
        "glitch-guard: experimental handling disabled ("
        .. S.tripReason
        .. " on "
        .. vehicleName
        .. "). Sandbox reset to recommended; vehicle scripts re-tuned without advanced handling."
    )
end

function S.readVehicleZ(vehicle)
    if vehicle and vehicle.getZ then
        return tonumber(vehicle:getZ())
    end
    return nil
end

local function pushZSample(state, z)
    local history = state.zHistory
    history[#history + 1] = z
    while #history > JITTER_SAMPLES do
        table.remove(history, 1)
    end
end

local function detectJitter(state)
    local history = state.zHistory
    if #history < JITTER_SAMPLES then
        return false
    end
    local hits = 0
    for index = 2, #history do
        if math.abs(history[index] - history[index - 1]) >= JITTER_THRESHOLD then
            hits = hits + 1
        end
    end
    return hits >= JITTER_HITS
end

local function detectSink(state, z, speedKmh)
    if speedKmh > MONITOR_SPEED_KMH then
        state.zDropStart = nil
        state.zDropStartZ = nil
        return false
    end
    if not state.zDropStart then
        state.zDropStart = 0
        state.zDropStartZ = z
        return false
    end
    state.zDropStart = state.zDropStart + 1
    if state.zDropStart < SINK_WINDOW_TICKS then
        return false
    end
    local startZ = state.zDropStartZ
    state.zDropStart = nil
    state.zDropStartZ = nil
    if startZ == nil then
        return false
    end
    return (z - startZ) <= -SINK_DROP_Z
end

local function detectTilt(vehicle)
    local tiltX, tiltZ = 0, 0
    if vehicle.getAngleX then
        tiltX = math.abs(vehicle:getAngleX() or 0)
    end
    if vehicle.getAngleZ then
        tiltZ = math.abs(vehicle:getAngleZ() or 0)
    end
    return tiltX >= TILT_LIMIT or tiltZ >= TILT_LIMIT
end

function S.probeVehicle(player, vehicle, brakeState)
    if not S.isMonitoringActive() or not vehicle then
        return
    end

    local state = playerState(player)
    if state.retuneCooldown > 0 then
        state.retuneCooldown = state.retuneCooldown - 1
    end

    state.ticks = state.ticks + 1
    if state.ticks < PROBE_EVERY_TICKS then
        return
    end
    state.ticks = 0

    local z = S.readVehicleZ(vehicle)
    if z == nil then
        return
    end

    local speedKmh = IKFRVP.readVehicleSpeedKmh(vehicle) or 0
    pushZSample(state, z)

    if detectTilt(vehicle) and speedKmh < MONITOR_SPEED_KMH then
        S.trip("extreme-tilt", vehicle)
        state.retuneCooldown = RETUNE_COOLDOWN_TICKS
        return
    end

    if detectSink(state, z, speedKmh) then
        S.trip("wheel-sink", vehicle)
        state.retuneCooldown = RETUNE_COOLDOWN_TICKS
        return
    end

    if speedKmh < 10 and detectJitter(state) then
        S.trip("suspension-jitter", vehicle)
        state.retuneCooldown = RETUNE_COOLDOWN_TICKS
    end
end

function S.onGameStart()
    S.refreshTripState()
    if S.tripped then
        if IKFRVP.isMultiplayerClient() then
            S.mirrorRecommendedSandbox()
            IKFRVP.log("glitch-guard: client synced — experimental handling disabled by server.")
            return
        end
        if IKFRVP.hasPhysicsAuthority() then
            S.applyRecommendedSandbox()
            S.retuneWithoutExperimental()
            IKFRVP.log("glitch-guard: session started with experimental handling disabled (previous glitch trip).")
        end
    end
end

function S.onReceiveGlobalModData(key, data)
    if key ~= MOD_DATA_KEY or not data then
        return
    end
    if data.tripped ~= true then
        return
    end
    S.tripped = true
    S.tripReason = data.reason or S.tripReason or "moddata"
    if IKFRVP.isMultiplayerClient() then
        S.mirrorRecommendedSandbox()
        IKFRVP.debug(
            "glitch-guard: moddata sync reason="
            .. tostring(S.tripReason)
            .. " vehicle="
            .. tostring(data.vehicle or "unknown")
        )
    end
end

function S.registerEvents()
    if S._installed then
        return
    end
    S.refreshTripState()
    if Events and Events.OnGameStart then
        Events.OnGameStart.Add(S.onGameStart)
    end
    if Events and Events.OnReceiveGlobalModData then
        Events.OnReceiveGlobalModData.Add(S.onReceiveGlobalModData)
    end
    S._installed = true
end

S.registerEvents()

return S
