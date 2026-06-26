require "IK_MP_Core"
require "IK_MP_SandboxSync"
require "IK_MP_Compat"
require "IK_MP_Profiles"
require "IK_MP_Tune"
require "IK_MP_Debug"
require "IK_MP_Physics"
require "IK_MP_PhysicsMirror"
require "IK_MP_Trunk"
require "IK_MP_Tow"

IK_MP.Orchestrator = IK_MP.Orchestrator or {}

local O = IK_MP.Orchestrator
local C = IK_MP

O._clientArmed = false

function O.bootServer()
    if not C.isActiveHere() or not C.isEnabled() or not C.hasServerJvm() then
        return false
    end

    C.log("orchestrator server boot v" .. C.Version .. " [sandbox+physics+trunk+tow]")

    IK_MP.SandboxSync.bootServer()
    IK_MP.Compat.boot()
    IK_MP.Physics.boot()
    IK_MP.Trunk.bootServer()
    IK_MP.Tow.boot()
    C.logReleaseSummary()

    return true
end

-- Register network handlers before MP session is ready (remote clients need OnServerCommand).
function O.armClient()
    if not C.hasClientJvm() then
        return false
    end
    if O._clientArmed then
        return true
    end
    IK_MP.SandboxSync.bootClient()
    C.log("orchestrator client armed v" .. C.Version .. " side=" .. C.side() .. " mp=" .. tostring(C.isMultiplayerSession()))
    O._clientArmed = true
    return true
end

function O.bootClient()
    if not C.hasClientJvm() or not C.isActiveHere() then
        return false
    end
    if not O._clientArmed then
        O.armClient()
    end

    C.log("orchestrator client boot v" .. C.Version .. " [sandbox+physics+trunk+tow] side=" .. C.side())

    IK_MP.Compat.boot()
    IK_MP.Physics.boot()
    IK_MP.Trunk.bootClientMirror()
    IK_MP.Tow.boot()
    C.logReleaseSummary()

    return true
end

function O.boot()
    local ok = false
    if C.hasServerJvm() then
        ok = O.bootServer() or ok
    end
    if C.hasClientJvm() then
        ok = O.armClient() or ok
        ok = O.bootClient() or ok
    end
    return ok
end

return O


