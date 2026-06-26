require "IK_SP_Core"
require "IK_SP_Compat"

IK_SP.Tow = IK_SP.Tow or {}

local W = IK_SP.Tow
local C = IK_SP
local Compat = IK_SP.Compat

W._eventsRegistered = false
W._tickEvery = 2
W._zeroVec = nil
W._debugImpulseTick = 0
W._speedByVehicle = setmetatable({}, { __mode = "k" })

local DECEL_DROP_KMH = 1.25
local COAST_DOWN_PRIOR_KMH = 12.0
local FORCE_CAP_MASS_MULT = 2.2

-- Assist tapers to zero near ~50 km/h. Curve power >1 cuts mid-range snap (natural acceleration).
local SPEED_TAPER_ONSET_KMH = 8
local SPEED_TAPER_RANGE_KMH = 42
local SPEED_CURVE_POWER = 2.0
local CRAWL_BOOST_CEILING_KMH = 12

local function getGameTimeMultiplier()
    if not getGameTime then
        return 1.0
    end
    local gt = getGameTime()
    if not gt or not gt.getMultiplier then
        return 1.0
    end
    local delta = C.finiteNumber(gt:getMultiplier())
    if not delta or delta <= 0 then
        return 1.0
    end
    return math.min(delta, 5.0)
end

local function absSpeedKmh(vehicle)
    if not vehicle or not vehicle.getCurrentSpeedKmHour then
        return 0
    end
    local speed = C.finiteNumber(vehicle:getCurrentSpeedKmHour()) or 0
    return math.abs(speed)
end

function W.isGasPedalPressed(vehicle)
    if vehicle and vehicle.isGasPedalPressed then
        return vehicle:isGasPedalPressed() == true
    end
    return true
end

function W.trackSpeed(vehicle)
    if not vehicle then
        return nil
    end
    local speed = absSpeedKmh(vehicle)
    local entry = W._speedByVehicle[vehicle]
    if not entry then
        entry = { last = speed, prev = speed }
        W._speedByVehicle[vehicle] = entry
        return entry
    end
    entry.prev = entry.last
    entry.last = speed
    return entry
end

function W.isDecelerating(vehicle)
    local entry = W._speedByVehicle[vehicle]
    if not entry then
        return false
    end
    return (entry.prev - entry.last) >= DECEL_DROP_KMH
end

function W.coastDownDampening(vehicle, speed)
    local entry = W._speedByVehicle[vehicle]
    if not entry or speed >= COAST_DOWN_PRIOR_KMH then
        return 1.0
    end
    if entry.prev > 18 and speed < 10 then
        return 0.35
    end
    if entry.prev > 12 and speed < 6 then
        return 0.5
    end
    return 1.0
end

function W.applyDriveGates(vehicle, mode, speedFactor)
    W.trackSpeed(vehicle)
    if not W.isGasPedalPressed(vehicle) then
        return 0, "no_gas"
    end

    local speed = absSpeedKmh(vehicle)

    if W.isDecelerating(vehicle) then
        speedFactor = speedFactor * 0.2
    end

    speedFactor = speedFactor * W.coastDownDampening(vehicle, speed)

    if speedFactor <= 0 then
        return 0, "damped"
    end
    return speedFactor, nil
end

-- CSR skips gear <= 0; IKappaID assists reverse (gear < 0) and forward (gear > 0), not neutral.
function W.getTransmissionGear(vehicle)
    if not vehicle or not vehicle.getTransmissionNumber then
        return nil
    end
    return vehicle:getTransmissionNumber()
end

function W.getDriveMode(vehicle)
    local gear = W.getTransmissionGear(vehicle)
    if gear == nil then
        return "forward"
    end
    if gear < 0 then
        return "reverse"
    end
    if gear == 0 then
        return "neutral"
    end
    return "forward"
end

function W.computeSpeedFactor(vehicle, mode)
    local speed = absSpeedKmh(vehicle)
    local linear = math.max(0, 1 - (math.max(0, speed - SPEED_TAPER_ONSET_KMH) / SPEED_TAPER_RANGE_KMH))
    if linear <= 0 then
        return 0
    end

    local taper = linear ^ SPEED_CURVE_POWER

    local boost = C.towLowSpeedBoost()
    if boost > 1.0 and speed < CRAWL_BOOST_CEILING_KMH then
        local crawlBlend = 1 - (speed / CRAWL_BOOST_CEILING_KMH)
        taper = taper * (1 + (boost - 1) * crawlBlend)
    end

    if mode == "forward" then
        local softness = C.towAccelSoftness()
        if softness and softness > 0 and softness < 1 then
            taper = taper * softness
        end
    end

    return taper
end

function W.computeLoadRatio(vehicle, towed)
    local mass = C.finiteNumber(vehicle:getMass())
    local towedMass = C.finiteNumber(towed:getMass())
    if not mass or mass <= 0 then
        return nil
    end
    towedMass = towedMass or mass
    local cap = C.towMaxLoadRatio()
    if not cap or cap <= 0 then
        cap = 3.0
    end
    return math.min(towedMass / mass, cap)
end

function W.buildAssistContext(vehicle)
    if not vehicle then
        return nil
    end

    local mode = W.getDriveMode(vehicle)
    if mode == "neutral" then
        return nil
    end
    if mode == "reverse" and not C.isReverseTowAssistEnabled() then
        return nil
    end

    local factor = C.towAssistFactor()
    if not factor or factor <= 0 then
        return nil
    end
    if mode == "reverse" then
        factor = factor * C.towReverseAssistMult()
        if not factor or factor <= 0 then
            return nil
        end
    end

    if Compat.applyPFCTowAssistFactor then
        factor = Compat.applyPFCTowAssistFactor(vehicle, factor)
        if not factor or factor <= 0 then
            return nil
        end
    end

    local speedFactor = W.computeSpeedFactor(vehicle, mode)
    if speedFactor <= 0 then
        return nil
    end

    local gateReason
    speedFactor, gateReason = W.applyDriveGates(vehicle, mode, speedFactor)
    if speedFactor <= 0 then
        return nil
    end

    local towed = vehicle:getVehicleTowing()
    if not towed then
        return nil
    end

    local loadRatio = W.computeLoadRatio(vehicle, towed)
    if not loadRatio then
        return nil
    end

    local mass = C.finiteNumber(vehicle:getMass())
    if not mass or mass <= 0 then
        return nil
    end

    local dirSign = mode == "reverse" and -1 or 1
    return {
        mode = mode,
        towed = towed,
        factor = factor,
        speedFactor = speedFactor,
        loadRatio = loadRatio,
        mass = mass,
        dirSign = dirSign,
        speedKmh = absSpeedKmh(vehicle),
        gasPedal = W.isGasPedalPressed(vehicle),
        gateReason = gateReason,
        gear = W.getTransmissionGear(vehicle),
    }
end

function W.applyTowImpulse(vehicle)
    if not vehicle or not C.isTowAssistEnabled() then
        return false
    end
    local skip = Compat.shouldSkipTowAssist()
    if skip then
        return false
    end
    if not vehicle.getVehicleTowing or not vehicle.addImpulse or not vehicle.getForwardVector then
        return false
    end

    local ctx = W.buildAssistContext(vehicle)
    if not ctx then
        return false
    end

    local dir = Vector3f and Vector3f.new() or nil
    if not dir then
        return false
    end
    vehicle:getForwardVector(dir)

    local delta = getGameTimeMultiplier()
    local forceMag = ctx.mass * ctx.factor * ctx.loadRatio * delta * ctx.speedFactor
    local forceCap = ctx.mass * ctx.factor * FORCE_CAP_MASS_MULT * delta
    if forceCap and forceCap > 0 and forceMag > forceCap then
        forceMag = forceCap
    end
    local sign = ctx.dirSign
    local force = Vector3f.new(dir:x() * forceMag * sign, dir:y() * forceMag * sign, dir:z() * forceMag * sign)

    if not W._zeroVec and Vector3f then
        W._zeroVec = Vector3f.new()
    end
    if W._zeroVec and W._zeroVec.set then
        W._zeroVec:set(0, 0, 0)
        vehicle:addImpulse(force, W._zeroVec)
    else
        vehicle:addImpulse(force, dir)
    end

    W._lastApply = {
        mode = ctx.mode,
        loadRatio = ctx.loadRatio,
        speedFactor = ctx.speedFactor,
        speedKmh = ctx.speedKmh,
        forceMag = forceMag,
        gasPedal = ctx.gasPedal,
        gateReason = ctx.gateReason,
        gear = ctx.gear,
    }
    return true
end

function W.debugTickImpulse(vehicle)
    if not C.isDebugLoggingEnabled() or not W._lastApply then
        return
    end
    W._debugImpulseTick = (W._debugImpulseTick or 0) + 1
    if W._debugImpulseTick < 300 then
        return
    end
    W._debugImpulseTick = 0
    local a = W._lastApply
    local towed = vehicle and vehicle.getVehicleTowing and vehicle:getVehicleTowing() or nil
    local towedName = "?"
    if towed and towed.getScript then
        local script = towed:getScript()
        if script then
            towedName = C.getScriptFullName(script)
        end
    end
    C.log(
        "tow impulse mode="
        .. tostring(a.mode)
        .. " loadRatio="
        .. C.formatNumber(a.loadRatio)
        .. " speedKmh="
        .. C.formatNumber(a.speedKmh)
        .. " gear="
        .. tostring(a.gear)
        .. " speedFactor="
        .. C.formatNumber(a.speedFactor)
        .. " forceMag="
        .. C.formatNumber(a.forceMag)
        .. " gas="
        .. tostring(a.gasPedal)
        .. " gate="
        .. tostring(a.gateReason or "ok")
        .. " trailer="
        .. towedName
    )
end

function W.onPlayerUpdate(player)
    if not C.isActiveHere() or not C.isEnabled() or not C.isTowAssistEnabled() then
        return
    end
    if Compat.shouldSkipTowAssist() then
        return
    end
    if not player or not player.isDriving or not player:isDriving() then
        return
    end
    if not player.getVehicle then
        return
    end
    local vehicle = player:getVehicle()
    if not vehicle then
        return
    end

    W._playerTicks = W._playerTicks or {}
    local ticks = (W._playerTicks[player] or 0) + 1
    W._playerTicks[player] = ticks
    if ticks < W._tickEvery then
        return
    end
    W._playerTicks[player] = 0

    if W.applyTowImpulse(vehicle) then
        W.debugTickImpulse(vehicle)
    end
end

function W.dumpTowState(vehicle, tag)
    if not C.isDebugLoggingEnabled() then
        return
    end
    tag = tag or "tow"
    local D = IK_SP.Debug
    if not D then
        return
    end
    D.separator("TOW " .. tag)
    D.line("TowBuild", C.TowBuild)
    D.line("IKappaID_EnableTowAssist", C.isTowAssistEnabled())
    D.line("CSR_EnableTowAssist", Compat.isCSRTowAssistSandboxOn())
    D.line("YieldTowToCSR", C.yieldTowToCSR())
    D.line("CSR_present", Compat.isCSRPresent())
    D.line("CSR_tow_active", Compat.isCSRTowAssistSandboxOn())
    D.line("yielding", Compat.shouldYieldTowToCSR())
    D.line("RCP_active", Compat.isRCPActive and Compat.isRCPActive() or false)
    D.line("PSC_active", Compat.isPSCActive and Compat.isPSCActive() or false)
    D.line("tow_blocked_physics_mod", Compat.blocksTowImpulseForPhysicsMods and Compat.blocksTowImpulseForPhysicsMods() or false)
    local skip, skipReason = Compat.shouldSkipTowAssist()
    D.line("tow_skip", tostring(skip))
    D.line("tow_skip_reason", skipReason or "n/a")
    if Compat.getCSRMechanicTowFactor then
        D.line("CSR_mech_factor_ref", C.formatNumber(Compat.getCSRMechanicTowFactor(vehicle)))
    end
    if Compat.isPFCPresent and Compat.isPFCPresent() then
        D.line("PFC_bridge_enabled", Compat.isPFCBridgeEnabled and Compat.isPFCBridgeEnabled() or false)
        local pfcPct, pfcSrc = Compat.getPFCTowAssistPercent(vehicle)
        D.line("PFC_tow_percent", C.formatNumber(pfcPct))
        D.line("PFC_tow_source", pfcSrc or "n/a")
    end
    D.line("TowAssistFactor", C.formatNumber(C.towAssistFactor()))
    D.line("EnableReverseTowAssist", C.isReverseTowAssistEnabled())
    D.line("TowReverseAssistMult", C.formatNumber(C.towReverseAssistMult()))
    D.line("TowLowSpeedBoost", C.formatNumber(C.towLowSpeedBoost()))
    D.line("TowAccelSoftness", C.formatNumber(C.towAccelSoftness()))
    D.line("TowMaxLoadRatio", C.formatNumber(C.towMaxLoadRatio()))
    if not vehicle then
        D.line("vehicle", "nil")
        D.sectionEnd()
        return
    end
    D.line("driveMode", W.getDriveMode(vehicle))
    D.line("gear", tostring(W.getTransmissionGear(vehicle)))
    if vehicle.getTransmissionNumberLetter then
        D.line("gearLetter", tostring(vehicle:getTransmissionNumberLetter()))
    end
    D.line("speedKmh", C.formatNumber(vehicle.getCurrentSpeedKmHour and vehicle:getCurrentSpeedKmHour() or nil))
    local towed = vehicle.getVehicleTowing and vehicle:getVehicleTowing() or nil
    if towed and towed.getScript then
        local script = towed:getScript()
        D.line("towedScript", script and C.getScriptFullName(script) or "?")
        D.line("towedMass", C.formatNumber(towed.getMass and towed:getMass() or nil))
    else
        D.line("towed", "none")
    end
    local ctx = W.buildAssistContext(vehicle)
    if ctx then
        D.line("wouldAssist", true)
        D.line("ctx.loadRatio", C.formatNumber(ctx.loadRatio))
        D.line("ctx.speedFactor", C.formatNumber(ctx.speedFactor))
        D.line("ctx.gasPedal", tostring(ctx.gasPedal))
        D.line("ctx.gateReason", tostring(ctx.gateReason or "ok"))
    else
        D.line("wouldAssist", false)
        W.trackSpeed(vehicle)
        D.line("gasPedal", tostring(W.isGasPedalPressed(vehicle)))
        if W.isDecelerating(vehicle) then
            D.line("decelerating", true)
        end
    end
    D.sectionEnd()
end

function W.onEnterVehicle(player)
    if not C.isEnabled() or not C.isDebugLoggingEnabled() then
        return
    end
    if not player or not player.getVehicle then
        return
    end
    local vehicle = player:getVehicle()
    if not vehicle then
        return
    end
    if not vehicle.getVehicleTowing or not vehicle:getVehicleTowing() then
        return
    end
    W.dumpTowState(vehicle, "OnEnterVehicle")
end

function W.registerEvents()
    if W._eventsRegistered or not C.isActiveHere() then
        return
    end
    if not C.isTowAssistEnabled() or Compat.shouldSkipTowAssist() then
        W._eventsRegistered = true
        return
    end
    if Events and Events.OnPlayerUpdate then
        Events.OnPlayerUpdate.Add(W.onPlayerUpdate)
    end
    if Events and Events.OnEnterVehicle then
        Events.OnEnterVehicle.Add(W.onEnterVehicle)
    end
    W._eventsRegistered = true
end

function W.boot()
    if not C.isActiveHere() then
        return false
    end
    local skip, skipReason = Compat.shouldSkipTowAssist()
    C.log(
        "tow module ready build="
        .. tostring(C.TowBuild)
        .. " factor="
        .. C.formatNumber(C.towAssistFactor())
        .. " reverse="
        .. tostring(C.isReverseTowAssistEnabled())
        .. " crawlBoost="
        .. C.formatNumber(C.towLowSpeedBoost())
        .. " accelSoft="
        .. C.formatNumber(C.towAccelSoftness())
        .. " maxLoad="
        .. C.formatNumber(C.towMaxLoadRatio())
        .. " tow_skip="
        .. tostring(skip)
        .. " reason="
        .. tostring(skipReason or "none")
    )
    W.registerEvents()
    return true
end

return W


