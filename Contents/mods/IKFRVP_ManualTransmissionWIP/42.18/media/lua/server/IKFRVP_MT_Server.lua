require "IKFRVP_MT_Config"
require "IKFRVP_ManualTransmission"

if type(isClient) == "function" and isClient() and not isServer() then
    return
end

local function onClientCommand(module, command, player, args)
    if module ~= IKFRVP.CommandModule then
        return
    end
    if command == "ManualTransmission" then
        if IKFRVP.ManualTransmission and IKFRVP.ManualTransmission.handleCommand then
            IKFRVP.ManualTransmission.handleCommand(player, args)
        end
    end
end

if Events and Events.OnClientCommand then
    Events.OnClientCommand.Add(onClientCommand)
end
