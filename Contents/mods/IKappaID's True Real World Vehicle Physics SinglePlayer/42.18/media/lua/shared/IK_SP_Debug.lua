require "IK_SP_Core"

IK_SP.Debug = IK_SP.Debug or {}

local D = IK_SP.Debug
local C = IK_SP

D._skipCounts = D._skipCounts or {}
D._sessionPasses = 0

local SEP_CHAR = "="
local SEP_WIDTH = 72

local PROBE_SCRIPTS = {
    ["Base.CarNormal"] = true,
    ["Base.SportsCar"] = true,
    ["Base.StepVan"] = true,
    ["Base.Van"] = true,
    ["Base.Trailer"] = true,
}

local function enabled()
    return C.isDebugLoggingEnabled()
end

function D.separator(title)
    if not enabled() then
        return
    end
    local line = SEP_CHAR:rep(SEP_WIDTH)
    C.log(line)
    C.log(SEP_CHAR:rep(3) .. " IKappaID SP DEBUG: " .. tostring(title) .. " " .. SEP_CHAR:rep(3))
    C.log(line)
end

function D.sectionEnd()
    if not enabled() then
        return
    end
    C.log(SEP_CHAR:rep(SEP_WIDTH))
end

function D.line(label, value)
    if not enabled() then
        return
    end
    C.log("  " .. tostring(label) .. " = " .. tostring(value))
end

function D.resetSkipCounts()
    D._skipCounts = {}
end

function D.recordSkip(reason)
    if not reason then
        reason = "unknown"
    end
    D._skipCounts[reason] = (D._skipCounts[reason] or 0) + 1
end

function D.formatSkipCounts()
    local parts = {}
    for reason, count in pairs(D._skipCounts) do
        parts[#parts + 1] = tostring(reason) .. "=" .. tostring(count)
    end
    table.sort(parts)
    if #parts == 0 then
        return "(none)"
    end
    return table.concat(parts, ", ")
end

function D.dumpSandbox()
    D.line("Enabled", C.isEnabled())
    D.line("ProfileTune", C.isProfileTuneEnabled())
    D.line("PowerMult", C.formatNumber(C.powerMult()))
    D.line("AccelerationMult", C.formatNumber(C.accelerationMult()))
    D.line("SportPowerBias", C.formatNumber(C.sportPowerBias()))
    D.line("HeavyPowerBias", C.formatNumber(C.heavyPowerBias()))
    D.line("BrakeMult", C.formatNumber(C.brakeMult()))
    D.line("BrakeStopTimeMult", C.formatNumber(C.brakeStopTimeMult()))
    D.line("MassMult", C.formatNumber(C.massMult()))
    D.line("MassUpliftMult", C.formatNumber(C.massUpliftMult()))
    D.line("HandlingTune", C.isHandlingTuneEnabled())
    D.line("SuspensionFirmness", C.formatNumber(C.suspensionFirmness()))
    D.line("WheelGripMult", C.formatNumber(C.wheelGripMult()))
    D.line("SteeringResponseMult", C.formatNumber(C.steeringResponseMult()))
    D.line("SteeringClampMult", C.formatNumber(C.steeringClampMult()))
    D.line("BodyRollMult", C.formatNumber(C.bodyRollMult()))
    D.line("feelSignature", C.physicsFeelSignature())
    D.line("TrunkTune", C.isTrunkTuneEnabled())
    D.line("TrunkCapacityMult", C.formatNumber(C.trunkCapacityMult()))
    D.line("TowBuild", C.TowBuild or "n/a")
    D.line("IKappaID_EnableTowAssist", C.isTowAssistEnabled())
    if IK_SP.Compat then
        D.line("CSR_EnableTowAssist", IK_SP.Compat.isCSRTowAssistSandboxOn())
    end
    D.line("TowAssistFactor", C.formatNumber(C.towAssistFactor()))
    D.line("EnableReverseTowAssist", C.isReverseTowAssistEnabled())
    D.line("TowReverseAssistMult", C.formatNumber(C.towReverseAssistMult()))
    D.line("TowLowSpeedBoost", C.formatNumber(C.towLowSpeedBoost()))
    D.line("TowAccelSoftness", C.formatNumber(C.towAccelSoftness()))
    D.line("TowMaxLoadRatio", C.formatNumber(C.towMaxLoadRatio()))
    D.line("YieldTowToCSR", C.yieldTowToCSR())
    if IK_SP.Compat then
        local Compat = IK_SP.Compat
        D.line("CSR_present", Compat.isCSRPresent())
        D.line("CSR_tow_active", Compat.isCSRTowAssistSandboxOn())
        D.line("tow_yielding", Compat.shouldYieldTowToCSR())
        D.line("RCP_active", Compat.isRCPActive())
        D.line("PSC_active", Compat.isPSCActive())
        D.line("tow_blocked_physics_mod", Compat.blocksTowImpulseForPhysicsMods())
        local skip, skipReason = Compat.shouldSkipTowAssist()
        D.line("tow_skip", tostring(skip))
        D.line("tow_skip_reason", skipReason or "n/a")
        D.line("PFC_present", Compat.isPFCPresent())
        D.line("PFC_bridge_enabled", Compat.isPFCBridgeEnabled())
    end
end

function D.dumpBaseline(baseline, prefix)
    prefix = prefix or "script"
    if not baseline then
        D.line(prefix .. ".baseline", "nil")
        return
    end
    D.line(prefix .. ".mass", C.formatNumber(baseline.mass))
    D.line(prefix .. ".engineForce", C.formatNumber(baseline.engineForce))
    D.line(prefix .. ".brakingForce", C.formatNumber(baseline.brakingForce))
    D.line(prefix .. ".stoppingMovementForce", C.formatNumber(baseline.stoppingMovementForce))
    D.line(prefix .. ".suspensionStiffness", C.formatNumber(baseline.suspensionStiffness))
    D.line(prefix .. ".suspensionDamping", C.formatNumber(baseline.suspensionDamping))
    D.line(prefix .. ".suspensionCompression", C.formatNumber(baseline.suspensionCompression))
    D.line(prefix .. ".wheelFriction", C.formatNumber(baseline.wheelFriction))
    D.line(prefix .. ".steeringClamp", C.formatNumber(baseline.steeringClamp))
    D.line(prefix .. ".steeringIncrement", C.formatNumber(baseline.steeringIncrement))
    D.line(prefix .. ".rollInfluence", C.formatNumber(baseline.rollInfluence))
end

function D.dumpPlan(plan, baseline)
    if not plan then
        D.line("plan", "nil")
        return
    end
    D.line("script", plan.scriptName)
    D.line("mode", plan.mode)
    D.line("profileId", plan.profileId or "n/a")
    D.line("profileClass", plan.profileClass or "n/a")
    if plan.fields then
        D.line("target.mass", C.formatNumber(plan.fields.mass))
        D.line("target.engineForce", C.formatNumber(plan.fields.engineForce))
        D.line("target.brakingForce", C.formatNumber(plan.fields.brakingForce))
        D.line("target.stoppingMovementForce", C.formatNumber(plan.fields.stoppingMovementForce))
        D.line("target.suspensionStiffness", C.formatNumber(plan.fields.suspensionStiffness))
        D.line("target.suspensionDamping", C.formatNumber(plan.fields.suspensionDamping))
        D.line("target.suspensionCompression", C.formatNumber(plan.fields.suspensionCompression))
        D.line("target.wheelFriction", C.formatNumber(plan.fields.wheelFriction))
        D.line("target.steeringClamp", C.formatNumber(plan.fields.steeringClamp))
        D.line("target.steeringIncrement", C.formatNumber(plan.fields.steeringIncrement))
        D.line("target.rollInfluence", C.formatNumber(plan.fields.rollInfluence))
    end
    D.line("payload", plan.payload or "n/a")
    if baseline then
        D.dumpBaseline(baseline, "vanilla")
    end
end

function D.dumpLiveVehicle(vehicle, tag)
    if not vehicle then
        D.line(tag .. ".vehicle", "nil")
        return
    end
    local script = vehicle.getScript and vehicle:getScript() or nil
    local scriptName = script and C.getScriptFullName(script) or "?"
    D.line(tag .. ".script", scriptName)
    if vehicle.getBrakingForce then
        D.line(tag .. ".live.brakingForce", C.formatNumber(vehicle:getBrakingForce()))
    end
    if vehicle.getEnginePower then
        D.line(tag .. ".live.enginePower", C.formatNumber(vehicle:getEnginePower()))
    end
    if vehicle.getCurrentSpeedKmHour then
        D.line(tag .. ".speedKmh", C.formatNumber(vehicle:getCurrentSpeedKmHour()))
    end
end

function D.probeScriptIfWatched(script, source, applied, skipReason)
    if not enabled() or not script then
        return
    end
    local fullName = C.getScriptFullName(script)
    if not PROBE_SCRIPTS[fullName] then
        return
    end
    D.separator("PROBE " .. fullName .. " @" .. tostring(source))
    D.line("applied", applied and "yes" or "no")
    D.line("skipReason", skipReason or "n/a")
    if IK_SP.Tune and IK_SP.Tune.readBaseline then
        D.dumpBaseline(IK_SP.Tune.readBaseline(script), "vanilla")
    end
    if IK_SP.Tune and IK_SP.Tune.buildPlan then
        D.dumpPlan(IK_SP.Tune.buildPlan(script))
    end
    D.sectionEnd()
end

function D.flushTunePass(source, stats)
    if not enabled() then
        D.resetSkipCounts()
        return
    end

    D._sessionPasses = D._sessionPasses + 1
    D.separator("TUNE PASS #" .. D._sessionPasses .. " [" .. tostring(source) .. "]")
    D.dumpSandbox()
    D.line("seen", stats and stats.seen or 0)
    D.line("applied", stats and stats.applied or 0)
    D.line("profiled", stats and stats.profiled or 0)
    D.line("generic", stats and stats.generic or 0)
    D.line("unchanged", stats and stats.unchanged or 0)
    D.line("skipReasons", D.formatSkipCounts())
    D.sectionEnd()
    D.resetSkipCounts()
end

function D.enterVehicle(player, vehicle)
    if not enabled() or not vehicle then
        return
    end
    local script = vehicle.getScript and vehicle:getScript() or nil
    local scriptName = script and C.getScriptFullName(script) or "?"
    D.separator("ENTER VEHICLE " .. scriptName)
    D.dumpSandbox()
    if script and IK_SP.Tune then
        D.dumpBaseline(IK_SP.Tune.readBaseline(script), "vanilla")
        D.dumpPlan(IK_SP.Tune.buildPlan(script))
    end
    if IK_SP.Physics and IK_SP.Physics.getTargetFields then
        local fields = IK_SP.Physics.getTargetFields(vehicle)
        if fields then
            D.line("cachedTarget.mass", C.formatNumber(fields.mass))
            D.line("cachedTarget.engineForce", C.formatNumber(fields.engineForce))
            D.line("cachedTarget.brakingForce", C.formatNumber(fields.brakingForce))
        end
    end
    D.dumpLiveVehicle(vehicle, "enter")
    D.sectionEnd()
end

function D.syncVehicle(vehicle, changed, fields)
    if not enabled() or not changed or not vehicle then
        return
    end
    local script = vehicle.getScript and vehicle:getScript() or nil
    local scriptName = script and C.getScriptFullName(script) or "?"
    D.separator("SYNC VEHICLE " .. scriptName)
    if fields then
        D.line("sync.brakingForce", C.formatNumber(fields.brakingForce))
        D.line("sync.engineForce", C.formatNumber(fields.engineForce))
    end
    D.dumpLiveVehicle(vehicle, "afterSync")
    D.sectionEnd()
end

return D


