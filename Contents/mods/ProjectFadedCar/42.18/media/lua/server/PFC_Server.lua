if isClient() then return end

ProjectFadedCarServer = ProjectFadedCarServer or {}
local Server = ProjectFadedCarServer
local PFC = ProjectFadedCar

print("[ProjectFadedCar] Server module loaded")

local function sendResult(player, ok, message, vehicle, hazard)
    if isServer() and sendServerCommand and player then
        local payload = { ok = ok == true, message = tostring(message or "") }
        if hazard then payload.hazard = hazard end
        if vehicle and vehicle.getId then
            payload.vehicle = vehicle:getId()
            payload.snapshot = PFC.snapshotForNetwork(vehicle)
        end
        sendServerCommand(player, PFC.MODULE_ID, "ServiceResult", payload)
    end
end

local function validArgs(args)
    return type(args) == "table" and type(args.vehicle) == "number"
end

local function getTargetVehicle(args)
    if not validArgs(args) or not getVehicleById then return nil end
    return getVehicleById(args.vehicle)
end

function Server.handleInit(player, args)
    local vehicle = getTargetVehicle(args)
    if not PFC.canReachEngine(player, vehicle) then return end
    local _, engine = PFC.seedVehicle(vehicle, false)
    PFC.transmitEngineModData(vehicle, engine)
    if isServer() and sendServerCommand and player and vehicle then
        sendServerCommand(player, PFC.MODULE_ID, "VehicleSnapshot", {
            vehicle = vehicle:getId(),
            snapshot = PFC.snapshotForNetwork(vehicle),
        })
    end
end

function Server.handleService(player, args)
    if type(args) ~= "table" then return end
    if type(args.action) ~= "string" or type(args.target) ~= "string" then return end

    local vehicle = getTargetVehicle(args)
    if not PFC.canReachEngine(player, vehicle) then
        sendResult(player, false, "too-far", vehicle)
        return
    end

    local blocked, reason = PFC.serviceBlocked(vehicle)
    if blocked then
        sendResult(player, false, reason, vehicle)
        return
    end

    local ok, message, hazard = PFC.applyService(vehicle, player, args.action, args.target)
    sendResult(player, ok, message, vehicle, hazard)
end

function Server.handleTuneVehicle(player, args)
    if type(args) ~= "table" then return end
    if type(args.key) ~= "string" then return end

    local vehicle = getTargetVehicle(args)
    if not PFC.canReachEngine(player, vehicle) then
        sendResult(player, false, "too-far", vehicle)
        return
    end

    local blocked, reason = PFC.serviceBlocked(vehicle)
    if blocked then
        sendResult(player, false, reason, vehicle)
        return
    end

    local ok, message = PFC.applyVehicleTune(vehicle, player, args.key, args.value)
    sendResult(player, ok, message, vehicle)
end

function Server.handleCraftSupply(player, args)
    if type(args) ~= "table" or type(args.supply) ~= "string" then return end
    local ok, message = PFC.craftSupply(player, args.supply)
    if isServer() and sendServerCommand and player then
        sendServerCommand(player, PFC.MODULE_ID, "CraftResult", { ok = ok == true, message = tostring(message or "") })
    end
end

local function sendPhysicsBridgeResult(player, ok, message, action, vehicle, status)
    if not (isServer() and sendServerCommand and player) then return end
    sendServerCommand(player, PFC.MODULE_ID, "PhysicsBridgeResult", {
        ok = ok == true,
        message = tostring(message or ""),
        action = tostring(action or ""),
        vehicle = vehicle and vehicle.getId and vehicle:getId() or -1,
        status = status,
    })
end

function Server.handlePhysicsBridge(player, args)
    if type(args) ~= "table" then return end
    local action = tostring(args.action or "status")
    local vehicle = getTargetVehicle(args)

    if action == "syncVehicle" and not PFC.canReachEngine(player, vehicle) then
        local status = PFC.IKFRVPBridge and PFC.IKFRVPBridge.status(vehicle) or nil
        sendPhysicsBridgeResult(player, false, "too-far", action, vehicle, status)
        return
    end

    if not PFC.IKFRVPBridge or not PFC.IKFRVPBridge.performAction then
        sendPhysicsBridgeResult(player, false, "physics-unavailable", action, vehicle, nil)
        return
    end

    local ok, message, status = PFC.IKFRVPBridge.performAction(action, player, vehicle)
    sendPhysicsBridgeResult(player, ok, message, action, vehicle, status)
end

local function onClientCommand(module, command, player, args)
    if module ~= PFC.MODULE_ID then return end
    if not PFC.enabled() then return end

    if command == "InitVehicle" then
        Server.handleInit(player, args)
    elseif command == "ServiceVehicle" then
        Server.handleService(player, args)
    elseif command == "TuneVehicle" then
        Server.handleTuneVehicle(player, args)
    elseif command == "CraftSupply" then
        Server.handleCraftSupply(player, args)
    elseif command == "PhysicsBridge" then
        Server.handlePhysicsBridge(player, args)
    end
end

local function patchVehicleEngineUpdate()
    if not Vehicles or not Vehicles.Update or not Vehicles.Update.Engine or Vehicles.__pfc_engine_update_patched then return end
    local original = Vehicles.Update.Engine
    Vehicles.Update.Engine = function(vehicle, part, elapsedMinutes)
        original(vehicle, part, elapsedMinutes)
        if PFC.enabled() and part and part.getId and part:getId() == "Engine" then
            PFC.degradeVehicle(vehicle, elapsedMinutes)
            PFC.applyFailureEffects(vehicle, elapsedMinutes)
        end
    end
    Vehicles.__pfc_engine_update_patched = true
    print("[ProjectFadedCar] Server vehicle update patch installed")
end

if Events and Events.OnClientCommand then
    Events.OnClientCommand.Add(onClientCommand)
end

if Events and Events.OnGameStart then
    Events.OnGameStart.Add(patchVehicleEngineUpdate)
end
if Events and Events.OnServerStarted then
    Events.OnServerStarted.Add(patchVehicleEngineUpdate)
end
patchVehicleEngineUpdate()
