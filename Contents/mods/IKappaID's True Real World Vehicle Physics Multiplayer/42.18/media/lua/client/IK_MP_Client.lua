-- Remote client + listen-host client JVM: mirror trunk UI; server owns capacity.

if type(isServer) == "function" and isServer() and type(isClient) == "function" and not isClient() then

    return

end



require "IK_MP_Core"

require "IK_MP_Bootstrap"

require "IK_MP_SandboxSync"

require "IK_MP_PhysicsMirror"

require "IK_MP_Orchestrator"

require "IK_MP_Trunk"



local function onServerCommand(module, command, args)

    if IK_MP.SandboxSync.handleClientCommand(module, command, args) then

        return

    end

    if IK_MP.PhysicsMirror.handleClientCommand(module, command, args) then

        return

    end

    if IK_MP.Trunk.handleClientCommand then

        IK_MP.Trunk.handleClientCommand(module, command, args)

    end

end



if type(isClient) == "function" and isClient() then

    if Events and Events.OnServerCommand then

        Events.OnServerCommand.Add(onServerCommand)

    end

    IK_MP.Bootstrap.init()

else

    if type(IK_MP) == "table" and IK_MP.debug then
        IK_MP.debug("client entry skipped (not client JVM)")
    end

end



return true



