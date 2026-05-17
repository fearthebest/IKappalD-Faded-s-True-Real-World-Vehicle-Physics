if isServer() then return end

ProjectFadedCarClient = ProjectFadedCarClient or {}
local Client = ProjectFadedCarClient
local PFC = ProjectFadedCar

print("[ProjectFadedCar] Client module loaded")

function Client.requestVehicleInit(vehicle)
    if not vehicle or not PFC.enabled() then return end
    if isClient() then
        sendClientCommand(PFC.MODULE_ID, "InitVehicle", { vehicle = vehicle:getId() })
    else
        PFC.seedVehicle(vehicle, false)
    end
end

function Client.hasItem(playerObj, fullType)
    if not playerObj or not fullType then return false end
    local inv = playerObj:getInventory()
    return inv and inv.getFirstTypeRecurse and inv:getFirstTypeRecurse(fullType) ~= nil
end

function Client.hasServiceItem(playerObj, spec)
    if not spec then return false end
    if Client.hasItem(playerObj, spec.item) then return true end
    if type(spec.alternates) == "table" then
        for _, fullType in ipairs(spec.alternates) do
            if Client.hasItem(playerObj, fullType) then return true end
        end
    end
    return false
end

function Client.queueService(playerObj, vehicle, action, target, duration)
    if not playerObj or not vehicle or not PFC_ServiceAction or not ISTimedActionQueue then return end
    ISTimedActionQueue.add(PFC_ServiceAction:new(playerObj, vehicle, action, target, duration or 180))
end

function Client.requestCraftSupply(playerObj, supplyId)
    if not playerObj or not supplyId then return end
    if isClient() then
        sendClientCommand(PFC.MODULE_ID, "CraftSupply", { supply = supplyId })
    else
        PFC.craftSupply(playerObj, supplyId)
    end
end

function Client.requestTune(playerObj, vehicle, key, value)
    if not playerObj or not vehicle or not key then return end
    if isClient() then
        sendClientCommand(PFC.MODULE_ID, "TuneVehicle", {
            vehicle = vehicle:getId(),
            key = key,
            value = value,
        })
    else
        PFC.applyVehicleTune(vehicle, playerObj, key, value)
    end
end

function Client.getActiveVehicle(playerObj)
    if playerObj and playerObj.getVehicle then
        local vehicle = playerObj:getVehicle()
        if vehicle then return vehicle end
    end
    if Client.lastMechanicsVehicle and PFC.canReachEngine and PFC.canReachEngine(playerObj, Client.lastMechanicsVehicle) then
        return Client.lastMechanicsVehicle
    end
    return nil
end

function Client.openServicePanel(playerObj, vehicle)
    if not playerObj or not PFC.engineBayEnabled() then return end
    vehicle = vehicle or Client.getActiveVehicle(playerObj)
    if not vehicle then return end
    Client.requestVehicleInit(vehicle)
    if PFC_ServicePanel and PFC_ServicePanel.open then
        PFC_ServicePanel.open(playerObj:getPlayerNum(), vehicle)
    end
end

local function findVehicleById(vehicleId)
    if type(vehicleId) ~= "number" then return nil end
    if getVehicleById then
        local vehicle = getVehicleById(vehicleId)
        if vehicle then return vehicle end
    end
    if PFC_ServicePanel and PFC_ServicePanel.instance then
        local vehicle = PFC_ServicePanel.instance.vehicle
        if vehicle and vehicle.getId and vehicle:getId() == vehicleId then return vehicle end
    end
    return nil
end

function Client.applySnapshot(vehicleId, snapshot)
    if type(snapshot) ~= "table" or type(snapshot.store) ~= "table" then return end
    local vehicle = findVehicleById(vehicleId)
    local engine = vehicle and PFC.getEnginePart(vehicle) or nil
    if not engine or not engine.getModData then return end

    local modData = engine:getModData()
    modData[PFC.STORE_KEY] = snapshot.store
    if vehicle.transmitPartModData then
        vehicle:transmitPartModData(engine)
    elseif engine.transmitModData then
        engine:transmitModData()
    end
    if snapshot.engineCondition and engine.setCondition then
        engine:setCondition(snapshot.engineCondition)
    end
end

function Client.applyPhysicsBridgeStatus(status)
    if PFC.IKFRVPBridge and type(status) == "table" then
        PFC.IKFRVPBridge.storeStatus(status)
    end
end

function Client.requestPhysicsBridge(action, playerObj, vehicle)
    if not PFC.IKFRVPBridge then return end
    action = tostring(action or "status")
    vehicle = vehicle or Client.getActiveVehicle(playerObj)

    if action == "status" then
        PFC.IKFRVPBridge.requestNativeStatus(vehicle)
    end

    if isClient() then
        sendClientCommand(PFC.MODULE_ID, "PhysicsBridge", {
            action = action,
            vehicle = vehicle and vehicle.getId and vehicle:getId() or -1,
        })
        return
    end

    local ok, message, status = PFC.IKFRVPBridge.performAction(action, playerObj, vehicle)
    Client.applyPhysicsBridgeStatus(status)
    Client.showPhysicsBridgeOutcome(ok, message)
end

local function haloColor(kind)
    if not HaloTextHelper then return nil end
    if kind == "good" then
        if HaloTextHelper.getGoodColor then return HaloTextHelper.getGoodColor() end
        if HaloTextHelper.getColorGreen then return HaloTextHelper.getColorGreen() end
    elseif kind == "bad" then
        if HaloTextHelper.getBadColor then return HaloTextHelper.getBadColor() end
        if HaloTextHelper.getColorRed then return HaloTextHelper.getColorRed() end
    elseif kind == "white" then
        if HaloTextHelper.getColorWhite then return HaloTextHelper.getColorWhite() end
    end
    return nil
end

local function addHalo(player, text, color)
    if not player or not HaloTextHelper or not HaloTextHelper.addText then return end
    if color then
        HaloTextHelper.addText(player, tostring(text or ""), "[br/]", color)
    else
        HaloTextHelper.addText(player, tostring(text or ""))
    end
end

function Client.showPhysicsBridgeOutcome(ok, message)
    local player = getPlayer and getPlayer() or nil
    if not player or not HaloTextHelper then return end

    local key = "IGUI_PFC_Error_" .. tostring(message or "physics-failed")
    local fallback = "Physics bridge failed"
    local color = haloColor("bad")

    if ok then
        key = "IGUI_PFC_" .. tostring(message or "physics-status")
        fallback = "Physics bridge updated"
        color = haloColor("good")
    end

    addHalo(player, PFC.text(key, fallback), color)
end

function Client.showServiceOutcome(ok, message, hazard)
    local player = getPlayer and getPlayer() or nil
    if not player or not HaloTextHelper then return end

    if type(hazard) == "table" and hazard.outcome then
        local key = "IGUI_PFC_Hazard_" .. tostring(hazard.outcome)
        local fallback = "Engine bay hazard"
        if hazard.outcome == "spark" then fallback = "Sparks from the engine bay" end
        if hazard.outcome == "smoke" then fallback = "Smoke from the engine bay" end
        if hazard.outcome == "fire" then fallback = "Engine bay fire" end
        local color = haloColor("bad")
        if hazard.outcome == "spark" then color = haloColor("white") end
        addHalo(player, PFC.text(key, fallback), color)
        return
    end

    if ok then
        local key = "IGUI_PFC_" .. tostring(message or "ServiceComplete")
        addHalo(player, PFC.text(key, PFC.text("IGUI_PFC_ServiceComplete", "Service complete")), haloColor("good"))
    else
        local key = "IGUI_PFC_Error_" .. tostring(message or "failed")
        addHalo(player, PFC.text(key, "Service failed"), haloColor("bad"))
    end
end

local function onServiceResult(args)
    if not args then return end
    if args.vehicle and args.snapshot then
        Client.applySnapshot(args.vehicle, args.snapshot)
    end
    Client.showServiceOutcome(args.ok, args.message, args.hazard)
end

local function onServerCommand(module, command, args)
    if PFC.IKFRVPBridge and module == PFC.IKFRVPBridge.COMMAND_MODULE and command == "Status" then
        local status = PFC.IKFRVPBridge.status(nil)
        if type(args) == "table" then
            for key, value in pairs(args) do
                status[key] = value
            end
        end
        PFC.IKFRVPBridge.storeStatus(status)
        return
    end

    if module ~= PFC.MODULE_ID then return end
    if command == "ServiceResult" then
        onServiceResult(args)
    elseif command == "CraftResult" then
        onServiceResult(args)
    elseif command == "VehicleSnapshot" then
        if args and args.vehicle and args.snapshot then
            Client.applySnapshot(args.vehicle, args.snapshot)
        end
    elseif command == "PhysicsBridgeResult" then
        if args and args.status then
            Client.applyPhysicsBridgeStatus(args.status)
        end
        Client.showPhysicsBridgeOutcome(args and args.ok, args and args.message)
    end
end

local function normalizeSelectedItems(items)
    local result = {}
    if not items then return result end
    for _, entry in ipairs(items) do
        if type(entry) == "table" and entry.items then
            for _, stackedItem in ipairs(entry.items) do
                table.insert(result, stackedItem)
            end
        else
            table.insert(result, entry)
        end
    end
    return result
end

local function itemMatchesInput(item, inputType)
    if not item or not item.getFullType then return false end
    local fullType = item:getFullType()
    if fullType == inputType then return true end
    if inputType == "Base.EngineParts" and item.getType and item:getType() == "EngineParts" then return true end
    return false
end

local function selectionHasInput(normalized, inputType)
    for _, item in ipairs(normalized) do
        if itemMatchesInput(item, inputType) then return true end
    end
    return false
end

local function onInventoryContext(playerIndex, context, items)
    if not PFC.enabled() then return end
    if not ISContextMenu or not context then return end

    local playerObj = getSpecificPlayer and getSpecificPlayer(playerIndex) or getPlayer()
    if not playerObj then return end

    local normalized = normalizeSelectedItems(items)
    if #normalized == 0 then return end

    local hasAnySupply = false
    for _, spec in ipairs(PFC.SUPPLIES) do
        if selectionHasInput(normalized, spec.input) then
            hasAnySupply = true
            break
        end
    end
    if not hasAnySupply then return end

    local root = context:addOption(PFC.text("ContextMenu_PFC_AssembleSupplies", "Project Faded Car"))
    local menu = ISContextMenu:getNew(context)
    context:addSubMenu(root, menu)

    for _, spec in ipairs(PFC.SUPPLIES) do
        if selectionHasInput(normalized, spec.input) then
            local label = PFC.text(spec.labelKey, spec.id)
            menu:addOption(label, playerObj, Client.requestCraftSupply, spec.id)
        end
    end
end

local function patchMechanicsMenu()
    if not ISVehicleMechanics or ISVehicleMechanics.__pfc_context_patched then return end
    local original = ISVehicleMechanics.doPartContextMenu
    if type(original) ~= "function" then return end

    ISVehicleMechanics.doPartContextMenu = function(self, part, x, y)
        original(self, part, x, y)
        if not PFC.engineBayEnabled() then return end
        if not part or not part.getId or part:getId() ~= "Engine" then return end
        if not self.context or not self.vehicle then return end

        local playerObj = self.chr or self.character
        Client.lastMechanicsVehicle = self.vehicle
        if PFC.autoOpenWithMechanics and PFC.autoOpenWithMechanics() then
            local now = getTimestampMs and getTimestampMs() or 0
            local vehicleId = self.vehicle.getId and self.vehicle:getId() or 0
            if Client.lastAutoEngineVehicle ~= vehicleId or now - (Client.lastAutoEngineMs or 0) > 1200 then
                Client.lastAutoEngineVehicle = vehicleId
                Client.lastAutoEngineMs = now
                Client.openServicePanel(playerObj, self.vehicle)
            end
        end

        local option = self.context:addOption(PFC.text("ContextMenu_PFC_OpenEngineBay", "Open The Shop"), playerObj, Client.openServicePanel, self.vehicle)
        if option then
            option.iconTexture = getTexture and getTexture("Item_EngineParts") or nil
        end
    end

    ISVehicleMechanics.__pfc_context_patched = true
    print("[ProjectFadedCar] Client mechanics menu patch installed")
end

local function patchVehicleMenu()
    if not ISVehicleMenu or ISVehicleMenu.__pfc_context_patched then return end
    local original = ISVehicleMenu.FillMenuOutsideVehicle
    if type(original) ~= "function" then return end

    ISVehicleMenu.FillMenuOutsideVehicle = function(playerIndex, context, vehicle, test)
        original(playerIndex, context, vehicle, test)
        if test or not PFC.engineBayEnabled() or not context or not vehicle then return end
        local playerObj = getSpecificPlayer and getSpecificPlayer(playerIndex) or getPlayer()
        if not playerObj then return end
        if not (PFC.getEnginePart(vehicle) or (PFC.getRestoredVehicleScript and PFC.getRestoredVehicleScript(vehicle))) then return end

        Client.lastMechanicsVehicle = vehicle
        local option = context:addOption(PFC.text("ContextMenu_PFC_OpenEngineBay", "Open The Shop"), playerObj, Client.openServicePanel, vehicle)
        if option then
            option.iconTexture = getTexture and getTexture("Item_EngineParts") or nil
        end
    end

    ISVehicleMenu.__pfc_context_patched = true
    print("[ProjectFadedCar] Client vehicle menu patch installed")
end

if Events and Events.OnServerCommand then
    Events.OnServerCommand.Add(onServerCommand)
end
if Events and Events.OnFillInventoryObjectContextMenu then
    Events.OnFillInventoryObjectContextMenu.Add(onInventoryContext)
end
if Events and Events.OnGameStart then
    Events.OnGameStart.Add(patchMechanicsMenu)
    Events.OnGameStart.Add(patchVehicleMenu)
end
patchMechanicsMenu()
patchVehicleMenu()
