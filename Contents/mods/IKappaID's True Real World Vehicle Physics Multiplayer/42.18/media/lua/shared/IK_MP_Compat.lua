require "IK_MP_Core"

--[[
    Optional-mod detection only — no require() of CSR/RCP Lua.
]]

IK_MP.Compat = IK_MP.Compat or {}

local K = IK_MP.Compat
local C = IK_MP

function K.isModActive(modId)
    if not modId or not getActivatedMods then
        return false
    end
    local mods = getActivatedMods()
    if not mods or not mods.contains then
        return false
    end
    return mods:contains(modId)
end

function K.isCSRPresent()
    return K.isModActive("CommonSenseReborn")
end

function K.isCSRTowAssistSandboxOn()
    if not K.isCSRPresent() then
        return false
    end
    if not SandboxVars or not SandboxVars.CommonSenseReborn then
        return false
    end
    return SandboxVars.CommonSenseReborn.EnableTowAssist == true
end

function K.shouldYieldTowToCSR()
    -- CSR tow assist is single-player oriented; yielding in MP leaves no working tow on dedicated servers.
    if C.isMultiplayerSession() then
        return false
    end
    if not C.yieldTowToCSR() then
        return false
    end
    return K.isCSRTowAssistSandboxOn()
end

-- Same mod IDs CSR uses to avoid stacking vanilla-calibrated impulses on Java physics replacers.
function K.isRCPActive()
    return K.isModActive("RealisticCarPhysics")
end

function K.isPSCActive()
    return K.isModActive("ProjectSummerCar")
end

function K.blocksTowImpulseForPhysicsMods()
    return K.isRCPActive() or K.isPSCActive()
end

function K.shouldSkipTowAssist()
    if K.blocksTowImpulseForPhysicsMods() then
        return true, "physics_mod"
    end
    if K.shouldYieldTowToCSR() then
        return true, "csr_yield"
    end
    return false, nil
end

function K.publishGlobalShim()
    _G.IKappaID = _G.IKappaID or {}
    _G.IKappaID.Version = C.Version
    _G.IKappaID.ModId = C.ModId
    _G.IKappaID.Branch = C.Branch
    _G.IKappaID.isActiveHere = C.isActiveHere
    _G.IKappaID.isEnabled = C.isEnabled
    _G.IKappaID.isProfileTuningEnabled = C.isProfileTuneEnabled
    _G.IKappaID.isDebugLoggingEnabled = C.isDebugLoggingEnabled
    _G.IKappaID.isCSRActive = K.isCSRPresent
    _G.IKappaID.sandboxRoot = function()
        return C.sandbox()
    end
    _G.IKappaID.option = function(name, fallback)
        local root = C.sandbox()
        if root and root[name] ~= nil then
            return root[name]
        end
        return fallback
    end
    _G.IKappaID.numberOption = function(name, fallback)
        return C.numberOption(name, fallback)
    end
    _G.IKappaID.readScriptNumber = C.readScriptNumber
    _G.IKappaID.getScriptFullName = C.getScriptFullName
    if IK_MP.Profiles then
        _G.IKappaID.Profiles = IK_MP.Profiles
    end
    if IK_MP.Physics and IK_MP.Physics.syncVehicle then
        _G.IKappaID.syncVehicle = IK_MP.Physics.syncVehicle
    end
    if IK_MP.Physics and IK_MP.Physics.tuneAllScripts then
        _G.IKappaID.tuneAllScripts = IK_MP.Physics.tuneAllScripts
    end
    if IK_MP.Tune and IK_MP.Tune.tuneAllScripts then
        _G.IKappaID.Tuner = IK_MP.Tune
    end
    _G.IKappaID.BrakeRuntime = {
        syncVehiclePhysics = function(vehicle, _)
            if IK_MP.Physics and IK_MP.Physics.syncVehicle then
                return IK_MP.Physics.syncVehicle(vehicle) == true
            end
            return false
        end,
        syncVehicleBrakes = function(vehicle)
            if IK_MP.Physics and IK_MP.Physics.syncVehicle then
                return IK_MP.Physics.syncVehicle(vehicle) == true
            end
            return false
        end,
        syncVehicleEngine = function(vehicle)
            if IK_MP.Physics and IK_MP.Physics.syncVehicle then
                return IK_MP.Physics.syncVehicle(vehicle) == true
            end
            return false
        end,
    }
    -- Backward compatibility shim
    _G.IKappaID = _G.IKappaID
end

function K.boot()
    if not C.isActiveHere() then
        return false
    end
    K.publishGlobalShim()
    if C.isDebugLoggingEnabled() then
        C.log(
            "compat: CSR="
            .. tostring(K.isCSRPresent())
            .. " CSR_tow="
            .. tostring(K.isCSRTowAssistSandboxOn())
            .. " yield_tow="
            .. tostring(K.shouldYieldTowToCSR())
            .. " RCP="
            .. tostring(K.isRCPActive())
            .. " PSC="
            .. tostring(K.isPSCActive())
            .. " tow_blocked="
            .. tostring(K.blocksTowImpulseForPhysicsMods())
            .. " IK_shim="
            .. tostring(_G.IKappaID ~= nil)
        )
    end
    return true
end

return K

