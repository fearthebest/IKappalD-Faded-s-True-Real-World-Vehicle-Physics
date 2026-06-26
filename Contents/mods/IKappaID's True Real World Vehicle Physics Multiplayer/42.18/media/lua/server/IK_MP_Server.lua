-- Dedicated / listen-server JVM: trunk authority + physics script tune.
if type(isClient) == "function" and isClient()
    and type(isServer) == "function" and not isServer() then
    return
end

require "IK_MP_Core"
require "IK_MP_Bootstrap"
require "IK_MP_SandboxSync"
require "IK_MP_Orchestrator"
require "IK_MP_PhysicsMirror"
require "IK_MP_Trunk"

local function onClientCommand(module, command, player, args)
    if IK_MP.SandboxSync.handleServerCommand(module, command, player, args) then
        return
    end
    if IK_MP.PhysicsMirror.handleServerCommand(module, command, player, args) then
        return
    end
    IK_MP.Trunk.handleServerCommand(module, command, player, args)
end

if type(isServer) == "function" and isServer() then
    if Events and Events.OnClientCommand then
        Events.OnClientCommand.Add(onClientCommand)
    end
    if IK_MP.SandboxSync and IK_MP.SandboxSync.armServer then
        IK_MP.SandboxSync.armServer()
    end
    IK_MP.Bootstrap.init()
else
    IK_MP.debug("server entry skipped (not server JVM)")
end

return true


