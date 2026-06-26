require "IK_SP_Core"
require "IK_SP_Compat"
require "IK_SP_Profiles"
require "IK_SP_Tune"
require "IK_SP_Debug"
require "IK_SP_Physics"
require "IK_SP_Trunk"
require "IK_SP_Tow"

IK_SP.Orchestrator = IK_SP.Orchestrator or {}

local O = IK_SP.Orchestrator
local C = IK_SP

function O.boot()
    if not C.isActiveHere() then
        return false
    end
    if not C.isEnabled() then
        C.log("orchestrator inactive (sandbox disabled)")
        return false
    end

    C.log("orchestrator boot v" .. C.Version .. " [physics+trunk+tow]")
    C.log("release " .. C.Version .. " (" .. C.ReleaseMilestone .. "): singleplayer physics + trunk + tow")

    IK_SP.Compat.boot()
    IK_SP.Physics.boot()
    IK_SP.Trunk.boot()
    IK_SP.Tow.boot()

    return true
end

return O


