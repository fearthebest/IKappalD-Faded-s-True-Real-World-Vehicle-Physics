-- Server -> remote client: apply server TuningRow (VehicleScript:Load) + Layer B instance stats.
require "IK_MP_Core"

IK_MP.PhysicsMirror = IK_MP.PhysicsMirror or {}

local M = IK_MP.PhysicsMirror
local C = IK_MP

M._rev = 0
M._lastPayloadSigByKey = {}
M._appliedScriptSigByVehicleId = {}

local function playerKey(player)
    if player and player.getUsername then
        return tostring(player:getUsername())
    end
    return "?"
end

local function attachTuningRow(vehicle, payload)
    if not vehicle or not payload or not IK_MP.Physics or not IK_MP.Physics.getMirrorRowForScript then
        return payload
    end
    if not vehicle.getScript then
        return payload
    end
    local script = vehicle:getScript()
    if not script then
        return payload
    end
    local row = IK_MP.Physics.getMirrorRowForScript(script)
    if not row or not row.payload or row.payload == "" or not row.loadName or row.loadName == "" then
        return payload
    end
    payload.scriptFullName = row.scriptFullName
    payload.scriptLoadName = row.loadName
    payload.loadPayload = row.payload
    payload.tuningSig = row.signature
    return payload
end

local function payloadSignature(vehicleId, payload)
    if not vehicleId or type(payload) ~= "table" then
        return ""
    end
    local parts = {
        tostring(vehicleId),
        C.formatNumber(payload.brakingForce),
        C.formatNumber(payload.engineForce),
        C.formatNumber(payload.enginePower),
        tostring(payload.tuningSig or ""),
    }
    return table.concat(parts, "|")
end

local function buildPayload(vehicle, fields)
    if not vehicle or not fields or not vehicle.getId then
        return nil
    end
    local vehicleId = vehicle:getId()
    if not vehicleId then
        return nil
    end
    local payload = {
        vehicleId = vehicleId,
    }
    if fields.brakingForce and fields.brakingForce > 0 then
        payload.brakingForce = fields.brakingForce
    end
    if fields.engineForce and fields.engineForce > 0 then
        payload.engineForce = fields.engineForce
        payload.enginePower = C.enginePowerFromScriptForce(vehicle, fields.engineForce)
    end
    return attachTuningRow(vehicle, payload)
end

function M.pushToPlayer(player, vehicle, fields)
    if not C.hasServerJvm() or not sendServerCommand or not player or not vehicle then
        return false
    end
    if not fields then
        if IK_MP.Physics and IK_MP.Physics.getTargetFields then
            fields = IK_MP.Physics.getTargetFields(vehicle)
        end
    end
    local payload = buildPayload(vehicle, fields)
    if not payload then
        return false
    end
    local vehicleId = payload.vehicleId
    local sig = payloadSignature(vehicleId, payload)
    local cacheKey = playerKey(player) .. "|" .. tostring(vehicleId)
    if M._lastPayloadSigByKey[cacheKey] == sig then
        return false
    end
    M._rev = (M._rev or 0) + 1
    payload.rev = M._rev
    sendServerCommand(player, C.ModId, "PhysicsMirror", payload)
    M._lastPayloadSigByKey[cacheKey] = sig
    if C.isDebugLoggingEnabled() then
        C.debug(
            "physics-mirror: pushed vehicleId="
                .. tostring(vehicleId)
                .. " tuning="
                .. tostring(payload.tuningSig ~= nil and payload.tuningSig ~= "")
                .. " rev="
                .. tostring(payload.rev)
        )
    end
    return true
end

function M.pushToVehicleDrivers(vehicle, fields)
    if not C.canQueryOnlinePlayers() then
        return 0
    end
    local online = C.safeGetOnlinePlayers()
    if not online or not online.size or online:size() == 0 then
        return 0
    end
    local pushed = 0
    for i = 0, online:size() - 1 do
        local player = online:get(i)
        if player and player.getVehicle then
            local pv = player:getVehicle()
            if pv == vehicle then
                if vehicle.isDriver and player.isDriving and vehicle:isDriver(player) and player:isDriving() then
                    if M.pushToPlayer(player, vehicle, fields) then
                        pushed = pushed + 1
                    end
                end
            end
        end
    end
    return pushed
end

function M.applyScriptRow(vehicle, args)
    if not C.clientExecutesServerMirror() or not vehicle or type(args) ~= "table" then
        return false
    end
    if not args.loadPayload or args.loadPayload == "" or not args.scriptLoadName or args.scriptLoadName == "" then
        return false
    end
    if not vehicle.getScript then
        return false
    end
    local script = vehicle:getScript()
    if not script or not script.Load then
        return false
    end
    local vehicleId = vehicle.getId and vehicle:getId()
    local tuningSig = args.tuningSig or (tostring(args.scriptFullName or "") .. "|" .. args.loadPayload)
    if vehicleId and M._appliedScriptSigByVehicleId[vehicleId] == tuningSig then
        return false
    end
    script:Load(args.scriptLoadName, args.loadPayload)
    if vehicleId then
        M._appliedScriptSigByVehicleId[vehicleId] = tuningSig
    end
    if C.isDebugLoggingEnabled() then
        C.debug(
            "physics-mirror: script-row vehicleId="
                .. tostring(vehicleId)
                .. " script="
                .. tostring(args.scriptFullName or args.scriptLoadName)
        )
    end
    return true
end

function M.applyToVehicle(vehicle, args)
    if not C.clientExecutesServerMirror() or not vehicle or type(args) ~= "table" then
        return false
    end
    if not C.isEnabled() then
        return false
    end

    local changed = M.applyScriptRow(vehicle, args)

    if args.brakingForce and vehicle.setBrakingForce and vehicle.getBrakingForce then
        local target = tonumber(args.brakingForce)
        local current = vehicle:getBrakingForce()
        if target and (current == nil or math.abs(current - target) > 0.05) then
            vehicle:setBrakingForce(target)
            changed = true
        end
    end

    local targetPower = tonumber(args.enginePower)
    if targetPower and vehicle.setEngineFeature and vehicle.getEnginePower then
        local current = vehicle:getEnginePower()
        if C.enginePowerNeedsUpdate(current, targetPower) then
            local quality = 100
            local loudness = 100
            if vehicle.getEngineQuality then
                local q = vehicle:getEngineQuality()
                if q then
                    quality = q
                end
            end
            if vehicle.getEngineLoudness then
                local l = vehicle:getEngineLoudness()
                if l then
                    loudness = l
                end
            end
            vehicle:setEngineFeature(quality, loudness, targetPower)
            if vehicle.transmitEngine then
                vehicle:transmitEngine()
            end
            changed = true
        end
    end

    if changed and C.isDebugLoggingEnabled() then
        C.debug(
            "physics-mirror: applied vehicleId="
                .. tostring(args.vehicleId)
                .. " brake="
                .. C.formatNumber(args.brakingForce)
                .. " enginePower="
                .. C.formatNumber(targetPower)
                .. " rev="
                .. tostring(args.rev or "?")
        )
    end
    return changed
end

function M.handleServerCommand(module, command, player, args)
    if module ~= C.ModId or command ~= "RequestPhysicsMirror" then
        return false
    end
    if not C.hasServerJvm() or not player then
        return true
    end
    local vehicle = nil
    if player.getVehicle then
        vehicle = player:getVehicle()
    end
    if not vehicle and type(args) == "table" and args.vehicleId and getVehicleById then
        vehicle = getVehicleById(args.vehicleId)
    end
    if not vehicle then
        return true
    end
    if type(args) == "table" and args.vehicleId and vehicle.getId then
        local vehicleId = vehicle:getId()
        if vehicleId and vehicleId ~= args.vehicleId then
            return true
        end
    end
    if IK_MP.Physics and IK_MP.Physics.syncVehicle then
        IK_MP.Physics.syncVehicle(vehicle, player)
    end
    M.pushToPlayer(player, vehicle, nil)
    if C.isDebugLoggingEnabled() then
        local source = type(args) == "table" and args.source or "RequestPhysicsMirror"
        C.debug(
            "physics-mirror: server handled request source="
                .. tostring(source)
                .. " vehicleId="
                .. tostring(vehicle.getId and vehicle:getId() or "?")
        )
    end
    return true
end

function M.requestMirrorFromServer(vehicle, source)
    if not C.isRemoteClient() or not sendClientCommand then
        return false
    end
    local args = { source = source or "client" }
    if vehicle and vehicle.getId then
        local vehicleId = vehicle:getId()
        if vehicleId then
            args.vehicleId = vehicleId
        end
    end
    sendClientCommand(C.ModId, "RequestPhysicsMirror", args)
    if C.isDebugLoggingEnabled() then
        C.debug(
            "physics-mirror: requested from server source="
                .. tostring(args.source)
                .. " vehicleId="
                .. tostring(args.vehicleId or "?")
        )
    end
    return true
end

function M.handleClientCommand(module, command, args)
    if module ~= C.ModId or command ~= "PhysicsMirror" then
        return false
    end
    if not C.clientExecutesServerMirror() or type(args) ~= "table" or not args.vehicleId then
        return false
    end
    if not getVehicleById then
        return false
    end
    local vehicle = getVehicleById(args.vehicleId)
    if not vehicle then
        return false
    end
    M.applyToVehicle(vehicle, args)
    return true
end

return M


