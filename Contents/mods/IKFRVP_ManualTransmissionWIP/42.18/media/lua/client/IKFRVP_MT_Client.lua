-- WORK IN PROGRESS (3.0.0) — BROKEN — client input and HUD for manual transmission addon.

require "IKFRVP_MT_Config"
require "IKFRVP_ManualTransmission"

if type(isServer) == "function" and isServer() and not isClient() then
    return
end

IKFRVP.ManualTransmissionClient = IKFRVP.ManualTransmissionClient or {}

local C = IKFRVP.ManualTransmissionClient
local MT = IKFRVP.ManualTransmission

local KEY_LSHIFT = (Keyboard and Keyboard.KEY_LSHIFT) or 42
local KEY_SPACE = (Keyboard and Keyboard.KEY_SPACE) or 57
local KEY_COMMA = (Keyboard and Keyboard.KEY_COMMA) or 51
local KEY_PERIOD = (Keyboard and Keyboard.KEY_PERIOD) or 52
local KEY_R = (Keyboard and Keyboard.KEY_R) or 19
local KEY_N = (Keyboard and Keyboard.KEY_N) or 49

C._installed = false
C._lastClutch = -1

local function isShiftDown()
    if isKeyDown then
        return isKeyDown(KEY_LSHIFT)
    end
    return false
end

local function playerVehicle(player)
    if player and player.getVehicle then
        return player:getVehicle()
    end
    return nil
end

local function getLocalPlayer()
    if getPlayer then
        return getPlayer()
    end
    return nil
end

local function sendMtCommand(vehicle, action, value)
    local player = getLocalPlayer()
    if not player then
        return
    end

    local args = { action = action }
    if vehicle and vehicle.getId then
        args.vehicle = vehicle:getId()
    end
    if value ~= nil then
        args.value = value
    end

    local isMpClient = type(isClient) == "function" and isClient()
        and type(isServer) == "function" and not isServer()

    if isMpClient and sendClientCommand then
        sendClientCommand(IKFRVP.CommandModule, "ManualTransmission", args)
        if MT and MT.handleCommand then
            MT.handleCommand(player, args)
        end
        return
    end

    if MT and MT.handleCommand then
        MT.handleCommand(player, args)
    end
end

local function syncClutch(vehicle, pressed)
    local value = pressed and 1 or 0
    if value == C._lastClutch then
        return
    end
    C._lastClutch = value
    sendMtCommand(vehicle, "clutch", value)
end

function C.onKeyPressed(key)
    if not IKFRVP.isManualTransmissionEnabled() then
        return
    end
    if not isShiftDown() then
        return
    end

    local player = getLocalPlayer()
    local vehicle = playerVehicle(player)
    if not vehicle then
        return
    end

    if key == KEY_PERIOD then
        sendMtCommand(vehicle, "shiftUp", nil)
        return
    end
    if key == KEY_COMMA then
        sendMtCommand(vehicle, "shiftDown", nil)
        return
    end
    if key == KEY_N then
        sendMtCommand(vehicle, "neutral", nil)
        return
    end
    if key == KEY_R then
        sendMtCommand(vehicle, "reverse", nil)
    end
end

function C.onPlayerUpdate(player)
    if not IKFRVP.isManualTransmissionEnabled() or not player then
        return
    end
    if player ~= getLocalPlayer() then
        return
    end

    local vehicle = playerVehicle(player)
    if not vehicle then
        C._lastClutch = -1
        return
    end

    local clutchPressed = isShiftDown() and isKeyDown and isKeyDown(KEY_SPACE)
    syncClutch(vehicle, clutchPressed)
end

function C.drawHud()
    if not IKFRVP.isManualTransmissionEnabled() or not IKFRVP.isManualTransmissionHudEnabled() then
        return
    end
    local player = getLocalPlayer()
    local vehicle = playerVehicle(player)
    if not vehicle or not MT or not MT.buildHudState then
        return
    end

    local hud = MT.buildHudState(vehicle)
    if not hud then
        return
    end

    local core = getCore and getCore() or nil
    local height = 720
    if core and core.getScreenHeight then
        height = tonumber(core:getScreenHeight()) or height
    end

    local rpm = tonumber(hud.rpm) or 0
    local clutchPct = math.floor((tonumber(hud.clutch) or 0) * 100 + 0.5)
    local liveIndex = tonumber(hud.live)
    local liveLabel = liveIndex and MT.gearLabel(liveIndex) or "?"
    local line1 = "MT WIP " .. tostring(hud.gear or "N")
        .. " (live " .. tostring(liveLabel) .. ")"
        .. "  RPM " .. tostring(math.floor(rpm + 0.5))
        .. "  Clutch " .. tostring(clutchPct) .. "%"
    local line2 = "Shift+L: < , >   Clutch: Shift+Space   N / R  (broken — do not use)"

    if hud.stalled then
        line1 = line1 .. "  STALLED"
    end

    local tm = getTextManager and getTextManager() or nil
    if not tm or not tm.DrawString then
        return
    end

    local font = UIFont and UIFont.Medium or nil
    local y = height - 72
    tm:DrawString(font, 24, y, line1, 0.92, 0.94, 1, 1)
    tm:DrawString(font, 24, y + 22, line2, 0.75, 0.78, 0.85, 1)
end

function C.registerEvents()
    if C._installed then
        return
    end
    if Events and Events.OnKeyPressed then
        Events.OnKeyPressed.Add(C.onKeyPressed)
    end
    if Events and Events.OnPlayerUpdate then
        Events.OnPlayerUpdate.Add(C.onPlayerUpdate)
    end
    if Events and Events.OnPostUIDraw then
        Events.OnPostUIDraw.Add(C.drawHud)
    end
    C._installed = true
end

C.registerEvents()

return C
