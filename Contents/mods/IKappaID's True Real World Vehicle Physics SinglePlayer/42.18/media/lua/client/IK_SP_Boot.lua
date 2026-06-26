-- Singleplayer entry: client JVM only, not multiplayer.
if type(isServer) == "function" and isServer() and type(isClient) == "function" and not isClient() then
    return
end

require "IK_SP_Core"
require "IK_SP_Orchestrator"

if type(IK_SP) ~= "table" then
    return true
end

if IK_SP.isActiveHere() then
    IK_SP.Orchestrator.boot()
elseif type(IK_SP) == "table" and IK_SP.debug and not IK_SP.isSinglePlayerSession() then
    IK_SP.debug("client boot skipped (multiplayer session — use Multiplayer sub-mod)")
end

return true
