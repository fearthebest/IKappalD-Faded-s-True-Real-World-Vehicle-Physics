-- Deferred boot: dedicated servers often load Lua before isMultiplayer() is true.
require "IK_MP_Core"

IK_MP.Bootstrap = IK_MP.Bootstrap or {}

local B = IK_MP.Bootstrap
local C = IK_MP

B._serverBooted = false
B._clientBooted = false
B._clientArmed = false
B._eventsRegistered = false
B._deferTicks = 0
B._DEFER_MAX = 600

function B.isMpSessionReady()
    return C.isMultiplayerSession()
end

function B.tryBootServer()
    if B._serverBooted or not C.hasServerJvm() then
        return false
    end
    if not B.isMpSessionReady() then
        return false
    end
    if not IK_MP.Orchestrator or not IK_MP.Orchestrator.bootServer then
        return false
    end
    if IK_MP.Orchestrator.bootServer() then
        B._serverBooted = true
        C.log("bootstrap: server modules armed")
        return true
    end
    return false
end

function B.tryArmClient()
    if B._clientArmed or not C.hasClientJvm() then
        return false
    end
    if not IK_MP.Orchestrator or not IK_MP.Orchestrator.armClient then
        return false
    end
    if IK_MP.Orchestrator.armClient() then
        B._clientArmed = true
        return true
    end
    return false
end

function B.tryBootClient()
    if B._clientBooted or not C.hasClientJvm() then
        return false
    end
    B.tryArmClient()
    if not B.isMpSessionReady() then
        return false
    end
    if not IK_MP.Orchestrator or not IK_MP.Orchestrator.bootClient then
        return false
    end
    if IK_MP.Orchestrator.bootClient() then
        B._clientBooted = true
        C.log("bootstrap: client modules armed")
        return true
    end
    return false
end

function B.tryBootAll()
    local ok = false
    ok = B.tryBootServer() or ok
    ok = B.tryArmClient() or ok
    ok = B.tryBootClient() or ok
    return ok
end

function B.onGameStart()
    B.tryBootAll()
end

function B.onConnected()
    B.tryBootAll()
end

function B.onTick()
    if B._serverBooted and (B._clientBooted or not C.hasClientJvm()) then
        return
    end
    if not C.hasServerJvm() and not C.hasClientJvm() then
        return
    end
    B._deferTicks = B._deferTicks + 1
    if B._deferTicks > B._DEFER_MAX then
        return
    end
    if B._deferTicks == 1 or B._deferTicks == 30 or B._deferTicks == 120 or B._deferTicks % 120 == 0 then
        B.tryBootAll()
    end
end

function B.registerEvents()
    if B._eventsRegistered then
        return
    end
    if Events and Events.OnGameStart then
        Events.OnGameStart.Add(B.onGameStart)
    end
    if Events and Events.OnConnected then
        Events.OnConnected.Add(B.onConnected)
    end
    if Events and Events.OnTick then
        Events.OnTick.Add(B.onTick)
    end
    B._eventsRegistered = true
end

function B.init()
    B.registerEvents()
    B.tryArmClient()
    if B.isMpSessionReady() then
        B.tryBootAll()
    else
        C.log("bootstrap: waiting for multiplayer session (deferred boot)")
    end
end

return B


