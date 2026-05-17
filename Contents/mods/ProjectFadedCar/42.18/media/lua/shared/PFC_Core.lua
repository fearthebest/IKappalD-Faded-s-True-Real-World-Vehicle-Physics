ProjectFadedCar = ProjectFadedCar or {}

local PFC = ProjectFadedCar
PFC.MODULE_ID = "ProjectFadedCar"
PFC.VERSION = 2
PFC.STORE_KEY = "PFC"
PFC.SALVAGED_ENGINE_ITEM = "ProjectFadedCar.SalvagedEngine"

PFC.ENGINE_SWAP_INSTALL_REQUIREMENTS = {
    { fullType = "Base.EngineParts", count = 2 },
}

PFC.WRECK_RESTORE_REQUIREMENTS = {
    { fullType = "Base.EngineParts", count = 6 },
    { fullType = "Base.SheetMetal", count = 4 },
    { fullType = "Base.SmallSheetMetal", count = 6 },
    { fullType = "Base.ElectronicsScrap", count = 4 },
}

PFC.WRECK_RESTORE_MAPPINGS = {
    PickupBurnt = "Base.PickUpTruck",
    PickupSpecialBurnt = "Base.PickUpTruck",
    PickUpVanLightsBurnt = "Base.PickUpVan",
    TaxiBurnt = "Base.CarTaxi",
    AmbulanceBurnt = "Base.VanAmbulance",
    NormalCarBurntPolice = "Base.CarLightsPolice",
    LuxuryCarBurnt = "Base.CarLuxury",
    RaceCarBurnt = "Base.RaceCar12",
    PickUpTruckLights = "Base.PickUpTruck",
    PickUpVanLights = "Base.PickUpVan",
    CarLights = "Base.CarNormal",
}

PFC.WRECK_SUFFIXES = {
    "SmashedFront",
    "SmashedRear",
    "SmashedLeft",
    "SmashedRight",
    "Burnt",
}

print("[ProjectFadedCar] Shared module loaded")

PFC.PARTS = {
    { id = "radiator", labelKey = "IGUI_PFC_Part_Radiator", item = "ProjectFadedCar.RadiatorServiceKit", base = 72, wear = 0.010, skill = 2 },
    { id = "waterPump", labelKey = "IGUI_PFC_Part_WaterPump", item = "ProjectFadedCar.WaterPumpKit", base = 70, wear = 0.010, skill = 3 },
    { id = "oilSystem", labelKey = "IGUI_PFC_Part_OilSystem", item = "ProjectFadedCar.EngineServiceKit", base = 70, wear = 0.016, skill = 2 },
    { id = "oilFilter", labelKey = "IGUI_PFC_Part_OilFilter", item = "ProjectFadedCar.OilFilterServiceKit", base = 76, wear = 0.020, skill = 1 },
    { id = "oilPan", labelKey = "IGUI_PFC_Part_OilPan", item = "ProjectFadedCar.OilPanServiceKit", base = 74, wear = 0.008, skill = 2 },
    { id = "headGasket", labelKey = "IGUI_PFC_Part_HeadGasket", item = "ProjectFadedCar.HeadGasketSet", base = 70, wear = 0.012, skill = 4 },
    { id = "cylinderHead", labelKey = "IGUI_PFC_Part_CylinderHead", item = "ProjectFadedCar.CylinderHeadServiceKit", base = 72, wear = 0.010, skill = 5 },
    { id = "rotatingAssembly", labelKey = "IGUI_PFC_Part_RotatingAssembly", item = "ProjectFadedCar.RotatingAssemblyKit", base = 69, wear = 0.009, skill = 5 },
    { id = "sparkPlugs", labelKey = "IGUI_PFC_Part_SparkPlugs", item = "ProjectFadedCar.SparkPlugSet", base = 74, wear = 0.013, skill = 2 },
    { id = "ignition", labelKey = "IGUI_PFC_Part_Ignition", item = "ProjectFadedCar.IgnitionServicePack", base = 74, wear = 0.011, skill = 2 },
    { id = "beltDrive", labelKey = "IGUI_PFC_Part_BeltDrive", item = "ProjectFadedCar.DriveBelt", alternates = { "ProjectFadedCar.BeltAndPulleyKit" }, base = 68, wear = 0.014, skill = 1 },
    { id = "alternator", labelKey = "IGUI_PFC_Part_Alternator", item = "ProjectFadedCar.AlternatorServiceKit", base = 73, wear = 0.010, skill = 3 },
    { id = "starter", labelKey = "IGUI_PFC_Part_Starter", item = "ProjectFadedCar.StarterServiceKit", base = 73, wear = 0.007, skill = 3 },
    { id = "transmission", labelKey = "IGUI_PFC_Part_Transmission", item = "ProjectFadedCar.TransmissionServiceKit", base = 76, wear = 0.008, skill = 4 },
    { id = "torqueConverter", labelKey = "IGUI_PFC_Part_TorqueConverter", item = "ProjectFadedCar.TorqueConverterKit", base = 74, wear = 0.007, skill = 4 },
    { id = "brakeAssist", labelKey = "IGUI_PFC_Part_BrakeAssist", item = "ProjectFadedCar.BrakeAssistKit", base = 77, wear = 0.006, skill = 3 },
    { id = "steeringPump", labelKey = "IGUI_PFC_Part_SteeringPump", item = "ProjectFadedCar.SteeringPumpKit", base = 76, wear = 0.007, skill = 3 },
    { id = "climateControl", labelKey = "IGUI_PFC_Part_ClimateControl", item = "ProjectFadedCar.ClimateControlKit", base = 78, wear = 0.005, skill = 2 },
}

PFC.FLUIDS = {
    { id = "oilLevel", labelKey = "IGUI_PFC_Fluid_Oil", item = "ProjectFadedCar.FreshMotorOil", add = 38, wear = 0.018 },
    { id = "coolantLevel", labelKey = "IGUI_PFC_Fluid_Coolant", item = "ProjectFadedCar.CoolantMix", add = 35, wear = 0.014 },
    { id = "transmissionFluid", labelKey = "IGUI_PFC_Fluid_Transmission", item = "ProjectFadedCar.TransmissionFluid", add = 42, wear = 0.006 },
}

PFC.SUPPLIES = {
    { id = "EngineServiceKit", labelKey = "IGUI_PFC_Supply_EngineServiceKit", input = "Base.EngineParts", output = "ProjectFadedCar.EngineServiceKit" },
    { id = "RadiatorServiceKit", labelKey = "IGUI_PFC_Supply_RadiatorServiceKit", input = "Base.EngineParts", output = "ProjectFadedCar.RadiatorServiceKit" },
    { id = "WaterPumpKit", labelKey = "IGUI_PFC_Supply_WaterPumpKit", input = "Base.EngineParts", output = "ProjectFadedCar.WaterPumpKit" },
    { id = "OilFilterServiceKit", labelKey = "IGUI_PFC_Supply_OilFilterServiceKit", input = "Base.EngineParts", output = "ProjectFadedCar.OilFilterServiceKit" },
    { id = "OilPanServiceKit", labelKey = "IGUI_PFC_Supply_OilPanServiceKit", input = "Base.EngineParts", output = "ProjectFadedCar.OilPanServiceKit" },
    { id = "HeadGasketSet", labelKey = "IGUI_PFC_Supply_HeadGasketSet", input = "Base.EngineParts", output = "ProjectFadedCar.HeadGasketSet" },
    { id = "CylinderHeadServiceKit", labelKey = "IGUI_PFC_Supply_CylinderHeadServiceKit", input = "Base.EngineParts", output = "ProjectFadedCar.CylinderHeadServiceKit" },
    { id = "RotatingAssemblyKit", labelKey = "IGUI_PFC_Supply_RotatingAssemblyKit", input = "Base.EngineParts", output = "ProjectFadedCar.RotatingAssemblyKit" },
    { id = "SparkPlugSet", labelKey = "IGUI_PFC_Supply_SparkPlugSet", input = "Base.EngineParts", output = "ProjectFadedCar.SparkPlugSet" },
    { id = "IgnitionServicePack", labelKey = "IGUI_PFC_Supply_IgnitionServicePack", input = "Base.EngineParts", output = "ProjectFadedCar.IgnitionServicePack" },
    { id = "DriveBelt", labelKey = "IGUI_PFC_Supply_DriveBelt", input = "Base.EngineParts", output = "ProjectFadedCar.DriveBelt" },
    { id = "BeltAndPulleyKit", labelKey = "IGUI_PFC_Supply_BeltAndPulleyKit", input = "Base.EngineParts", output = "ProjectFadedCar.BeltAndPulleyKit" },
    { id = "AlternatorServiceKit", labelKey = "IGUI_PFC_Supply_AlternatorServiceKit", input = "Base.EngineParts", output = "ProjectFadedCar.AlternatorServiceKit" },
    { id = "StarterServiceKit", labelKey = "IGUI_PFC_Supply_StarterServiceKit", input = "Base.EngineParts", output = "ProjectFadedCar.StarterServiceKit" },
    { id = "TransmissionServiceKit", labelKey = "IGUI_PFC_Supply_TransmissionServiceKit", input = "Base.EngineParts", output = "ProjectFadedCar.TransmissionServiceKit" },
    { id = "TorqueConverterKit", labelKey = "IGUI_PFC_Supply_TorqueConverterKit", input = "Base.EngineParts", output = "ProjectFadedCar.TorqueConverterKit" },
    { id = "BrakeAssistKit", labelKey = "IGUI_PFC_Supply_BrakeAssistKit", input = "Base.EngineParts", output = "ProjectFadedCar.BrakeAssistKit" },
    { id = "SteeringPumpKit", labelKey = "IGUI_PFC_Supply_SteeringPumpKit", input = "Base.EngineParts", output = "ProjectFadedCar.SteeringPumpKit" },
    { id = "ClimateControlKit", labelKey = "IGUI_PFC_Supply_ClimateControlKit", input = "Base.EngineParts", output = "ProjectFadedCar.ClimateControlKit" },
    { id = "FreshMotorOil", labelKey = "IGUI_PFC_Supply_FreshMotorOil", input = "Base.PetrolCan", output = "ProjectFadedCar.FreshMotorOil" },
    { id = "TransmissionFluid", labelKey = "IGUI_PFC_Supply_TransmissionFluid", input = "Base.PetrolCan", output = "ProjectFadedCar.TransmissionFluid" },
    { id = "CoolantMix", labelKey = "IGUI_PFC_Supply_CoolantMix", input = "Base.WaterBottle", output = "ProjectFadedCar.CoolantMix" },
}

function PFC.text(key, fallback)
    if getText then
        local value = getText(key)
        if value and value ~= key then return value end
    end
    return fallback or key
end

function PFC.sandbox()
    return SandboxVars and SandboxVars.ProjectFadedCar or {}
end

function PFC.enabled()
    return PFC.sandbox().EnableProjectFadedCar ~= false
end

function PFC.dashboardEnabled()
    return PFC.enabled() and PFC.sandbox().EnableDashboard ~= false
end

function PFC.floatingButtonEnabled()
    return PFC.enabled() and PFC.sandbox().EnableFloatingEngineButton ~= false
end

function PFC.engineBayEnabled()
    return PFC.enabled() and PFC.sandbox().EnableEngineBayPanel ~= false
end

function PFC.vanillaGuiSkinEnabled()
    return PFC.enabled() and PFC.sandbox().EnableVanillaGuiSkin ~= false
end

function PFC.virtualWearEnabled()
    return PFC.enabled() and PFC.sandbox().EnableVirtualWear ~= false
end

function PFC.failureEffectsEnabled()
    return PFC.enabled() and PFC.sandbox().EnableFailureEffects ~= false
end

function PFC.serviceHazardsEnabled()
    return PFC.enabled() and PFC.sandbox().EnableServiceHazards ~= false
end

function PFC.requireEngineOff()
    return PFC.sandbox().RequireEngineOff ~= false
end

function PFC.autoOpenWithMechanics()
    return PFC.sandbox().AutoOpenEngineBayWithMechanics ~= false
end

function PFC.isVehicleEngineRunning(vehicle)
    return vehicle and vehicle.isEngineRunning and vehicle:isEngineRunning() == true
end

function PFC.serviceBlocked(vehicle)
    if PFC.requireEngineOff() and PFC.isVehicleEngineRunning(vehicle) then
        return true, "engine-running"
    end
    return false, ""
end

function PFC.wearRate()
    local value = tonumber(PFC.sandbox().WearRateMultiplier) or 1.0
    return PFC.clamp(value, 0.0, 5.0)
end

function PFC.serviceRestorePercent()
    local value = tonumber(PFC.sandbox().ServiceRestorePercent) or 85
    return math.floor(PFC.clamp(value, 35, 100))
end

function PFC.failureSeverity()
    local value = tonumber(PFC.sandbox().FailureEffectSeverity) or 1
    return math.floor(PFC.clamp(value, 1, 3))
end

function PFC.serviceHazardChance()
    local value = tonumber(PFC.sandbox().ServiceHazardChance) or 8
    return math.floor(PFC.clamp(value, 0, 100))
end

function PFC.serviceFireChance()
    local value = tonumber(PFC.sandbox().ServiceFireChance) or 4
    return math.floor(PFC.clamp(value, 0, 100))
end

function PFC.clamp(value, minValue, maxValue)
    value = tonumber(value) or minValue
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value
end

function PFC.round(value)
    return math.floor((tonumber(value) or 0) + 0.5)
end

function PFC.rollChance(percent)
    percent = PFC.clamp(percent or 0, 0, 100)
    if percent <= 0 then return false end
    if percent >= 100 then return true end
    if ZombRand then return ZombRand(10000) < percent * 100 end
    return math.random() * 100 < percent
end

function PFC.hasActiveMod(modId)
    if not getActivatedMods then return false end
    local mods = getActivatedMods()
    return mods and mods.contains and mods:contains(modId) or false
end

function PFC.isCSRActive()
    return PFC.hasActiveMod("CommonSenseReborn")
end

function PFC.csrCompatMode()
    return PFC.sandbox().EnableCSRCompatMode ~= false and PFC.isCSRActive()
end

function PFC.physicsBridgeEnabled()
    return PFC.enabled() and PFC.sandbox().EnableIKFRVPBridge ~= false
end

function PFC.engineSwapsEnabled()
    return PFC.enabled() and PFC.sandbox().EnableEngineSwaps ~= false
end

function PFC.wreckRestorationEnabled()
    return PFC.enabled() and PFC.sandbox().EnableWreckRestoration ~= false
end

function PFC.engineSwapMechanicsLevel()
    local value = tonumber(PFC.sandbox().EngineSwapMechanicsLevel) or 5
    return math.floor(PFC.clamp(value, 0, 10))
end

function PFC.wreckRestoreMechanicsLevel()
    local value = tonumber(PFC.sandbox().WreckRestoreMechanicsLevel) or 6
    return math.floor(PFC.clamp(value, 0, 10))
end

function PFC.wreckRestoreMetalWeldingLevel()
    local value = tonumber(PFC.sandbox().WreckRestoreMetalWeldingLevel) or 4
    return math.floor(PFC.clamp(value, 0, 10))
end

function PFC.wreckRestoreMaterialsRequired()
    return PFC.sandbox().WreckRestoreRequireMaterials ~= false
end

function PFC.ensureStoreDefaults(store)
    if not store then return nil end
    store.parts = store.parts or {}
    store.history = store.history or {}
    store.tuning = store.tuning or {}
    store.oilQuality = PFC.clamp(store.oilQuality or 70, 0, 100)
    store.engineHeat = PFC.clamp(store.engineHeat or 70, 0, 180)
    store.lastHazardHour = tonumber(store.lastHazardHour) or 0
    store.lastRunHour = tonumber(store.lastRunHour) or 0
    store.effectCooldown = tonumber(store.effectCooldown) or 0
    store.tuning.towAssist = math.floor(PFC.clamp(store.tuning.towAssist or 100, 75, 125))
    store.csrBridge = store.csrBridge or {}
    store.csrBridge.mod = "ProjectFadedCar"
    store.csrBridge.towAssist = store.tuning.towAssist
    local driveline = (PFC.partCondition(store, "transmission", 100) + PFC.partCondition(store, "torqueConverter", 100) + PFC.partCondition(store, "brakeAssist", 100)) / 3
    store.csrBridge.effectiveTowAssist = math.floor(store.tuning.towAssist * PFC.clamp(driveline / 100, 0.45, 1.05))
    store.csrBridge.version = PFC.VERSION
    return store
end

function PFC.getEnginePart(vehicle)
    if not vehicle or not vehicle.getPartById then return nil end
    return vehicle:getPartById("Engine")
end

function PFC.transmitEngineModData(vehicle, engine)
    if not vehicle or not engine then return end
    if vehicle.transmitPartModData then
        vehicle:transmitPartModData(engine)
    elseif engine.transmitModData then
        engine:transmitModData()
    end
end

function PFC.canReachEngine(player, vehicle)
    if not player or not vehicle then return false end
    if player.getVehicle and player:getVehicle() == vehicle then return true end
    local engine = PFC.getEnginePart(vehicle)
    if engine and engine.getArea and vehicle.isInArea then
        local area = engine:getArea()
        if area and vehicle:isInArea(area, player) then return true end
    end
    if player.DistToSquared and vehicle.getX and vehicle.getY then
        return player:DistToSquared(vehicle:getX(), vehicle:getY()) <= 25
    end
    return false
end

function PFC.getStore(vehicle)
    local engine = PFC.getEnginePart(vehicle)
    if not engine or not engine.getModData then return nil, nil end
    local modData = engine:getModData()
    if type(modData[PFC.STORE_KEY]) ~= "table" then
        modData[PFC.STORE_KEY] = {}
        if engine.transmitModData then engine:transmitModData() end
        if vehicle and vehicle.transmitPartModData then vehicle:transmitPartModData(engine) end
    end
    return modData[PFC.STORE_KEY], engine
end

function PFC.peekStore(vehicle)
    local engine = PFC.getEnginePart(vehicle)
    if not engine or not engine.getModData then return nil, nil end
    local modData = engine:getModData()
    local store = modData[PFC.STORE_KEY]
    if type(store) ~= "table" then return nil, engine end
    return store, engine
end

function PFC.getPartSpec(partId)
    for _, spec in ipairs(PFC.PARTS) do
        if spec.id == partId then return spec end
    end
    return nil
end

function PFC.getFluidSpec(fluidId)
    for _, spec in ipairs(PFC.FLUIDS) do
        if spec.id == fluidId then return spec end
    end
    return nil
end

function PFC.getSupplySpec(supplyId)
    for _, spec in ipairs(PFC.SUPPLIES) do
        if spec.id == supplyId then return spec end
    end
    return nil
end

function PFC.partCondition(store, partId, fallback)
    if not store or type(store.parts) ~= "table" then return PFC.clamp(fallback or 100, 0, 100) end
    return PFC.clamp(store.parts[partId] or fallback or 100, 0, 100)
end

function PFC.setPartCondition(store, partId, value)
    if not store then return end
    store.parts = store.parts or {}
    store.parts[partId] = PFC.clamp(value, 0, 100)
end

function PFC.adjustPartCondition(store, partId, delta)
    PFC.setPartCondition(store, partId, PFC.partCondition(store, partId, 100) + (tonumber(delta) or 0))
end

function PFC.damageRandomSystem(store, ids, amount)
    if not store or not ids or #ids == 0 then return nil end
    local valid = {}
    for _, id in ipairs(ids) do
        if PFC.getPartSpec(id) then table.insert(valid, id) end
    end
    if #valid == 0 then return nil end
    local index = ZombRand and (ZombRand(#valid) + 1) or math.random(1, #valid)
    local partId = valid[index]
    PFC.adjustPartCondition(store, partId, -(amount or 1))
    return partId
end

function PFC.mechanicsLevel(player)
    if player and player.getPerkLevel and Perks and Perks.Mechanics then
        return tonumber(player:getPerkLevel(Perks.Mechanics)) or 0
    end
    return 0
end

function PFC.metalWeldingLevel(player)
    if player and player.getPerkLevel and Perks and Perks.MetalWelding then
        return tonumber(player:getPerkLevel(Perks.MetalWelding)) or 0
    end
    return 0
end

function PFC.coolIdleEngine(store, vehicle)
    if not store or PFC.isVehicleEngineRunning(vehicle) then return false end
    local heat = tonumber(store.engineHeat) or 70
    local lastRun = tonumber(store.lastRunHour) or 0
    if heat <= 70 or lastRun <= 0 or not getGameTime then return false end
    local idleHours = math.max(0, getGameTime():getWorldAgeHours() - lastRun)
    if idleHours <= 0 then return false end
    local cooled = PFC.clamp(heat - (idleHours * 85), 45, 180)
    if PFC.round(cooled) == PFC.round(heat) then return false end
    store.engineHeat = cooled
    return true
end

local function randomRange(minValue, maxValue)
    if ZombRand then
        return minValue + ZombRand(maxValue - minValue + 1)
    end
    return minValue + math.random(maxValue - minValue)
end

function PFC.seedVehicle(vehicle, force)
    local store, engine = PFC.getStore(vehicle)
    if not store or not engine then return nil end
    local hasAllParts = type(store.parts) == "table"
    if hasAllParts then
        for _, spec in ipairs(PFC.PARTS) do
            if store.parts[spec.id] == nil then
                hasAllParts = false
                break
            end
        end
    end
    if store.version == PFC.VERSION and hasAllParts and not force then
        PFC.ensureStoreDefaults(store)
        PFC.coolIdleEngine(store, vehicle)
        return store, engine
    end

    local engineCondition = 65
    if engine.getCondition then
        engineCondition = tonumber(engine:getCondition()) or engineCondition
    end

    store.version = PFC.VERSION
    store.parts = store.parts or {}
    for _, spec in ipairs(PFC.PARTS) do
        local spread = randomRange(-12, 10)
        local seeded = PFC.clamp(math.min(engineCondition, spec.base) + spread, 8, 100)
        if not store.parts[spec.id] or force then
            store.parts[spec.id] = PFC.round(seeded)
        end
    end

    store.oilLevel = store.oilLevel or PFC.clamp(engineCondition + randomRange(-18, 12), 8, 100)
    store.coolantLevel = store.coolantLevel or PFC.clamp(engineCondition + randomRange(-14, 16), 8, 100)
    store.transmissionFluid = store.transmissionFluid or PFC.clamp(engineCondition + randomRange(-12, 10), 8, 100)
    store.oilQuality = store.oilQuality or PFC.clamp(engineCondition + randomRange(-10, 18), 10, 100)
    store.engineHeat = store.engineHeat or PFC.clamp(68 + randomRange(-8, 8), 45, 95)
    store.lastServiceHour = store.lastServiceHour or 0
    store.lastWearHour = store.lastWearHour or 0
    store.lastRunHour = store.lastRunHour or 0
    store.lastHazardHour = store.lastHazardHour or 0
    store.history = store.history or {}
    store.effectCooldown = store.effectCooldown or 0
    store.warning = store.warning or ""
    PFC.ensureStoreDefaults(store)
    PFC.coolIdleEngine(store, vehicle)
    return store, engine
end

function PFC.averageCondition(store)
    if not store or type(store.parts) ~= "table" then return 0 end
    local total = 0
    local count = 0
    for _, spec in ipairs(PFC.PARTS) do
        total = total + PFC.clamp(store.parts[spec.id] or 0, 0, 100)
        count = count + 1
    end
    if count == 0 then return 0 end
    return total / count
end

function PFC.worstPart(store)
    if not store or type(store.parts) ~= "table" then return nil, 100 end
    local worstSpec = nil
    local worstValue = 100
    for _, spec in ipairs(PFC.PARTS) do
        local value = PFC.clamp(store.parts[spec.id] or 0, 0, 100)
        if value < worstValue then
            worstValue = value
            worstSpec = spec
        end
    end
    return worstSpec, worstValue
end

function PFC.diagnosticCode(store)
    if not store then return "unknown" end
    local worstSpec, worstValue = PFC.worstPart(store)
    if (tonumber(store.engineHeat) or 0) > 125 then return "heat", "heat", tonumber(store.engineHeat) or 0 end
    if (tonumber(store.oilLevel) or 0) < 15 then return "oil", "oil", tonumber(store.oilLevel) or 0 end
    if (tonumber(store.oilQuality) or 0) < 18 then return "oilQuality", "oilQuality", tonumber(store.oilQuality) or 0 end
    if (tonumber(store.coolantLevel) or 0) < 15 then return "coolant", "coolant", tonumber(store.coolantLevel) or 0 end
    if (tonumber(store.transmissionFluid) or 0) < 15 then return "transmissionFluid", "transmissionFluid", tonumber(store.transmissionFluid) or 0 end
    if worstSpec and worstValue < 25 then return worstSpec.id, worstSpec.id, worstValue end
    if PFC.averageCondition(store) < 45 then return "wear", "wear", PFC.averageCondition(store) end
    return "ok", "", 100
end

function PFC.diagnosticLabel(code)
    local labels = {
        ok = "IGUI_PFC_Diagnostic_OK",
        oil = "IGUI_PFC_Diagnostic_Oil",
        coolant = "IGUI_PFC_Diagnostic_Coolant",
        transmissionFluid = "IGUI_PFC_Diagnostic_TransmissionFluid",
        oilQuality = "IGUI_PFC_Diagnostic_OilQuality",
        heat = "IGUI_PFC_Diagnostic_Heat",
        wear = "IGUI_PFC_Diagnostic_Wear",
        radiator = "IGUI_PFC_Diagnostic_Radiator",
        waterPump = "IGUI_PFC_Diagnostic_WaterPump",
        oilSystem = "IGUI_PFC_Diagnostic_OilSystem",
        oilFilter = "IGUI_PFC_Diagnostic_OilFilter",
        oilPan = "IGUI_PFC_Diagnostic_OilPan",
        headGasket = "IGUI_PFC_Diagnostic_HeadGasket",
        cylinderHead = "IGUI_PFC_Diagnostic_CylinderHead",
        rotatingAssembly = "IGUI_PFC_Diagnostic_RotatingAssembly",
        sparkPlugs = "IGUI_PFC_Diagnostic_SparkPlugs",
        ignition = "IGUI_PFC_Diagnostic_Ignition",
        beltDrive = "IGUI_PFC_Diagnostic_BeltDrive",
        alternator = "IGUI_PFC_Diagnostic_Alternator",
        starter = "IGUI_PFC_Diagnostic_Starter",
        transmission = "IGUI_PFC_Diagnostic_Transmission",
        torqueConverter = "IGUI_PFC_Diagnostic_TorqueConverter",
        brakeAssist = "IGUI_PFC_Diagnostic_BrakeAssist",
        steeringPump = "IGUI_PFC_Diagnostic_SteeringPump",
        climateControl = "IGUI_PFC_Diagnostic_ClimateControl",
    }
    return labels[code or "ok"] or "IGUI_PFC_Diagnostic_Unknown"
end

function PFC.recordHistory(store, action, target)
    if not store then return end
    store.history = store.history or {}
    local hour = getGameTime and getGameTime():getWorldAgeHours() or 0
    table.insert(store.history, 1, {
        hour = math.floor(hour),
        action = tostring(action or ""),
        target = tostring(target or ""),
    })
    while #store.history > 6 do
        table.remove(store.history)
    end
end

function PFC.getSnapshot(vehicle)
    local store, engine = PFC.peekStore(vehicle)
    if not store or store.version ~= PFC.VERSION or type(store.parts) ~= "table" then
        if isClient and isClient() then return nil end
        store, engine = PFC.seedVehicle(vehicle, false)
    end
    if not store then return nil end
    local engineCondition = engine and engine.getCondition and engine:getCondition() or 0
    local worstSpec, worstValue = PFC.worstPart(store)
    local code = PFC.diagnosticCode(store)
    return {
        store = store,
        engineCondition = engineCondition,
        average = PFC.averageCondition(store),
        worstPart = worstSpec,
        worstValue = worstValue,
        diagnosticCode = code,
        csr = PFC.csrCompatMode(),
        vehicleLabel = PFC.getVehicleLabel(vehicle),
    }
end

function PFC.getVehicleLabel(vehicle)
    if not vehicle then return PFC.text("IGUI_PFC_Vehicle", "Vehicle") end
    local script = vehicle.getScript and vehicle:getScript() or nil
    if script and script.getName then
        local name = script:getName()
        if name and name ~= "" then return tostring(name) end
    end
    if vehicle.getScriptName then
        local name = vehicle:getScriptName()
        if name and name ~= "" then return tostring(name) end
    end
    return PFC.text("IGUI_PFC_Vehicle", "Vehicle")
end

function PFC.vehicleSpeed(vehicle)
    if vehicle and vehicle.getCurrentSpeedKmHour then
        return math.abs(tonumber(vehicle:getCurrentSpeedKmHour()) or 0)
    end
    return 0
end

function PFC.vehicleMass(vehicle)
    local script = vehicle and vehicle.getScript and vehicle:getScript() or nil
    if script and script.getMass then
        return tonumber(script:getMass()) or 0
    end
    return 0
end

function PFC.copyStore(store)
    if not store then return nil end
    local copy = {
        version = store.version,
        oilLevel = store.oilLevel,
        oilQuality = store.oilQuality,
        coolantLevel = store.coolantLevel,
        transmissionFluid = store.transmissionFluid,
        engineHeat = store.engineHeat,
        lastServiceHour = store.lastServiceHour,
        lastWearHour = store.lastWearHour,
        lastRunHour = store.lastRunHour,
        lastHazardHour = store.lastHazardHour,
        effectCooldown = store.effectCooldown,
        warning = store.warning or "",
        parts = {},
        tuning = {},
        csrBridge = {},
        engineSwap = {},
        history = {},
    }
    for _, spec in ipairs(PFC.PARTS) do
        copy.parts[spec.id] = store.parts and store.parts[spec.id] or nil
    end
    if type(store.tuning) == "table" then
        copy.tuning.towAssist = store.tuning.towAssist
    end
    if type(store.csrBridge) == "table" then
        copy.csrBridge.mod = store.csrBridge.mod
        copy.csrBridge.version = store.csrBridge.version
        copy.csrBridge.towAssist = store.csrBridge.towAssist
        copy.csrBridge.effectiveTowAssist = store.csrBridge.effectiveTowAssist
        copy.csrBridge.updatedHour = store.csrBridge.updatedHour
    end
    if type(store.engineSwap) == "table" then
        copy.engineSwap.sourceScript = store.engineSwap.sourceScript
        copy.engineSwap.installedHour = store.engineSwap.installedHour
        copy.engineSwap.quality = store.engineSwap.quality
        copy.engineSwap.power = store.engineSwap.power
        copy.engineSwap.loudness = store.engineSwap.loudness
    end
    if type(store.history) == "table" then
        for i = 1, math.min(#store.history, 6) do
            local entry = store.history[i]
            if type(entry) == "table" then
                copy.history[i] = {
                    hour = entry.hour,
                    action = entry.action,
                    target = entry.target,
                }
            end
        end
    end
    return copy
end

function PFC.snapshotForNetwork(vehicle)
    local snapshot = PFC.getSnapshot(vehicle)
    if not snapshot then return nil end
    return {
        store = PFC.copyStore(snapshot.store),
        engineCondition = snapshot.engineCondition,
        average = snapshot.average,
        diagnosticCode = snapshot.diagnosticCode,
        vehicleLabel = snapshot.vehicleLabel,
    }
end

function PFC.degradeVehicle(vehicle, elapsedMinutes)
    if not PFC.virtualWearEnabled() then return false end
    if not vehicle or not vehicle.isEngineRunning or not vehicle:isEngineRunning() then return false end
    elapsedMinutes = tonumber(elapsedMinutes) or 0
    if elapsedMinutes <= 0 then return false end

    local store, engine = PFC.seedVehicle(vehicle, false)
    if not store or not engine then return false end

    local multiplier = PFC.wearRate()
    if multiplier <= 0 then return false end

    local changed = false
    local parts = store.parts or {}
    local radiator = PFC.partCondition(store, "radiator", 100)
    local waterPump = PFC.partCondition(store, "waterPump", 100)
    local oilSystem = PFC.partCondition(store, "oilSystem", 100)
    local oilFilter = PFC.partCondition(store, "oilFilter", 100)
    local oilPan = PFC.partCondition(store, "oilPan", 100)
    local headGasket = PFC.partCondition(store, "headGasket", 100)
    local beltDrive = PFC.partCondition(store, "beltDrive", 100)
    local rotatingAssembly = PFC.partCondition(store, "rotatingAssembly", 100)
    local cylinderHead = PFC.partCondition(store, "cylinderHead", 100)
    local transmission = PFC.partCondition(store, "transmission", 100)
    local torqueConverter = PFC.partCondition(store, "torqueConverter", 100)

    local oilLevel = PFC.clamp(store.oilLevel or 0, 0, 100)
    local coolantLevel = PFC.clamp(store.coolantLevel or 0, 0, 100)
    local transmissionFluid = PFC.clamp(store.transmissionFluid or 0, 0, 100)
    local oilQuality = PFC.clamp(store.oilQuality or 70, 0, 100)
    local speed = PFC.vehicleSpeed(vehicle)

    local coolingWeakness = 0
    coolingWeakness = coolingWeakness + (100 - radiator) * 0.0035
    coolingWeakness = coolingWeakness + (100 - waterPump) * 0.0040
    coolingWeakness = coolingWeakness + math.max(0, 30 - beltDrive) * 0.012
    coolingWeakness = coolingWeakness + math.max(0, 35 - coolantLevel) * 0.018
    coolingWeakness = coolingWeakness + math.max(0, 45 - headGasket) * 0.006

    local oilWeakness = math.max(0, 35 - oilLevel) * 0.020 + math.max(0, 35 - oilQuality) * 0.010 + math.max(0, 45 - oilSystem) * 0.006
    local targetHeat = 84 + (coolingWeakness * 70) + (oilWeakness * 25) + math.min(18, speed * 0.055)
    local heat = PFC.clamp(store.engineHeat or 70, 35, 180)
    local heatStep = PFC.clamp(elapsedMinutes * 0.035, 0, 1)
    local newHeat = heat + ((targetHeat - heat) * heatStep)
    if PFC.round(newHeat) ~= PFC.round(heat) then changed = true end
    store.engineHeat = PFC.clamp(newHeat, 35, 180)

    local heatPenalty = store.engineHeat > 105 and ((store.engineHeat - 105) / 75) or 0
    local fluidPenalty = 0
    if oilLevel < 25 then fluidPenalty = fluidPenalty + 0.8 end
    if oilQuality < 25 then fluidPenalty = fluidPenalty + 0.5 end
    if coolantLevel < 25 then fluidPenalty = fluidPenalty + 0.7 end
    if transmissionFluid < 25 then fluidPenalty = fluidPenalty + 0.4 end

    for _, spec in ipairs(PFC.PARTS) do
        local before = PFC.clamp(store.parts[spec.id] or spec.base, 0, 100)
        local loadPenalty = 0
        if spec.id == "radiator" or spec.id == "waterPump" or spec.id == "headGasket" or spec.id == "cylinderHead" then
            loadPenalty = loadPenalty + heatPenalty
        end
        if spec.id == "oilSystem" or spec.id == "oilFilter" or spec.id == "oilPan" or spec.id == "rotatingAssembly" then
            loadPenalty = loadPenalty + oilWeakness
        end
        if spec.id == "transmission" or spec.id == "torqueConverter" then
            loadPenalty = loadPenalty + (speed > 25 and math.min(0.8, speed / 120) or 0)
        end
        if spec.id == "alternator" and beltDrive < 35 then
            loadPenalty = loadPenalty + 0.35
        end
        local loss = elapsedMinutes * spec.wear * multiplier * (1 + heatPenalty + fluidPenalty + loadPenalty)
        local after = PFC.clamp(before - loss, 0, 100)
        if PFC.round(after) ~= PFC.round(before) then changed = true end
        store.parts[spec.id] = after
    end

    local oilLoss = elapsedMinutes * multiplier * (0.010 + math.max(0, 45 - oilPan) * 0.0009 + math.max(0, 45 - oilSystem) * 0.0007 + math.max(0, 40 - headGasket) * 0.0006)
    local coolantLoss = elapsedMinutes * multiplier * (0.008 + math.max(0, 45 - radiator) * 0.0008 + math.max(0, 45 - waterPump) * 0.0008 + math.max(0, 40 - headGasket) * 0.0009)
    local atfLoss = elapsedMinutes * multiplier * (0.004 + math.max(0, 45 - transmission) * 0.00045 + math.max(0, 45 - torqueConverter) * 0.00055)
    local qualityLoss = elapsedMinutes * multiplier * (0.012 + math.max(0, 100 - oilFilter) * 0.0007 + math.max(0, 100 - rotatingAssembly) * 0.00025 + math.max(0, 100 - cylinderHead) * 0.00020 + heatPenalty * 0.06)

    local nextOil = PFC.clamp(oilLevel - oilLoss, 0, 100)
    local nextCoolant = PFC.clamp(coolantLevel - coolantLoss, 0, 100)
    local nextAtf = PFC.clamp(transmissionFluid - atfLoss, 0, 100)
    local nextQuality = PFC.clamp(oilQuality - qualityLoss, 0, 100)

    if PFC.round(nextOil) ~= PFC.round(oilLevel) then changed = true end
    if PFC.round(nextCoolant) ~= PFC.round(coolantLevel) then changed = true end
    if PFC.round(nextAtf) ~= PFC.round(transmissionFluid) then changed = true end
    if PFC.round(nextQuality) ~= PFC.round(oilQuality) then changed = true end
    store.oilLevel = nextOil
    store.coolantLevel = nextCoolant
    store.transmissionFluid = nextAtf
    store.oilQuality = nextQuality

    local hour = getGameTime and getGameTime():getWorldAgeHours() or 0
    store.lastRunHour = hour

    local average = PFC.averageCondition(store)
    if store.engineHeat > 122 and PFC.rollChance(math.min(18, (store.engineHeat - 118) * 0.25)) then
        PFC.damageRandomSystem(store, { "radiator", "waterPump", "headGasket", "cylinderHead", "sparkPlugs" }, 1)
        changed = true
    end

    if average < 35 or store.oilLevel < 12 or store.oilQuality < 12 or store.coolantLevel < 10 or store.engineHeat > 135 then
        local engineCondition = engine:getCondition()
        if engineCondition > 0 and PFC.rollChance(4 + math.max(0, 18 - store.oilLevel) + math.max(0, 18 - store.oilQuality) + math.max(0, store.engineHeat - 130) * 0.30) then
            engine:setCondition(math.max(0, engineCondition - 1))
            if vehicle.transmitPartCondition then vehicle:transmitPartCondition(engine) end
            changed = true
        end
    end

    local _, warning = PFC.diagnosticCode(store)
    store.warning = warning or ""
    PFC.ensureStoreDefaults(store)

    if changed then PFC.transmitEngineModData(vehicle, engine) end
    return changed
end

function PFC.applyFailureEffects(vehicle, elapsedMinutes)
    if not PFC.failureEffectsEnabled() then return false end
    if not vehicle or not vehicle.isEngineRunning or not vehicle:isEngineRunning() then return false end

    local store, engine = PFC.seedVehicle(vehicle, false)
    if not store or not engine then return false end

    elapsedMinutes = tonumber(elapsedMinutes) or 0
    if elapsedMinutes <= 0 then return false end

    local severity = PFC.failureSeverity()
    local changed = false
    local parts = store.parts or {}
    local oil = PFC.clamp(store.oilLevel or 0, 0, 100)
    local oilQuality = PFC.clamp(store.oilQuality or 100, 0, 100)
    local coolant = PFC.clamp(store.coolantLevel or 0, 0, 100)
    local alternator = PFC.clamp(parts.alternator or 100, 0, 100)
    local starter = PFC.clamp(parts.starter or 100, 0, 100)
    local belt = PFC.clamp(parts.beltDrive or 100, 0, 100)
    local transmission = PFC.clamp(parts.transmission or 100, 0, 100)
    local torqueConverter = PFC.clamp(parts.torqueConverter or 100, 0, 100)
    local ignition = PFC.clamp(parts.ignition or 100, 0, 100)
    local sparkPlugs = PFC.clamp(parts.sparkPlugs or 100, 0, 100)
    local average = PFC.averageCondition(store)

    if VehicleUtils and VehicleUtils.chargeBattery then
        local batteryDrain = 0
        if alternator < 35 then batteryDrain = batteryDrain + (35 - alternator) * 0.0000015 * elapsedMinutes * severity end
        if belt < 25 then batteryDrain = batteryDrain + (25 - belt) * 0.0000010 * elapsedMinutes * severity end
        if batteryDrain > 0 then
            VehicleUtils.chargeBattery(vehicle, -batteryDrain)
            changed = true
        end
    end

    local damageChance = 0
    if oil < 10 then damageChance = damageChance + (10 - oil) * severity end
    if oilQuality < 10 then damageChance = damageChance + (10 - oilQuality) * severity end
    if coolant < 8 then damageChance = damageChance + (8 - coolant) * severity end
    if (store.engineHeat or 0) > 130 then damageChance = damageChance + ((store.engineHeat or 0) - 130) * 0.4 end
    if average < 25 then damageChance = damageChance + math.floor((25 - average) * 0.75) end
    if transmission < 12 and vehicle.getCurrentSpeedKmHour and math.abs(vehicle:getCurrentSpeedKmHour()) > 20 then
        damageChance = damageChance + (12 - transmission)
    end
    if torqueConverter < 12 and PFC.vehicleSpeed(vehicle) > 20 then
        damageChance = damageChance + (12 - torqueConverter)
    end

    if damageChance > 0 and PFC.rollChance(math.min(25, damageChance)) then
        local current = engine:getCondition()
        if current > 0 then
            engine:setCondition(math.max(0, current - severity))
            if vehicle.transmitPartCondition then vehicle:transmitPartCondition(engine) end
            changed = true
        end
    end

    local canStall = severity >= 2
    if canStall and vehicle.shutOff then
        local stallChance = 0
        if oil <= 2 then stallChance = stallChance + 8 end
        if coolant <= 2 then stallChance = stallChance + 6 end
        if belt <= 3 then stallChance = stallChance + 5 end
        if starter <= 0 then stallChance = stallChance + 2 end
        if ignition < 8 then stallChance = stallChance + 3 end
        if sparkPlugs < 8 then stallChance = stallChance + 4 end
        if torqueConverter < 5 then stallChance = stallChance + 3 end
        if stallChance > 0 and PFC.rollChance(stallChance) then
            vehicle:shutOff()
            store.warning = "stall"
            changed = true
        end
    end

    if changed then PFC.transmitEngineModData(vehicle, engine) end
    return changed
end

function PFC.itemSearchTypes(fullType)
    if not fullType then return {} end
    fullType = tostring(fullType)
    local types = { fullType }
    local baseType = string.match(fullType, "^Base%.(.+)$")
    if baseType and baseType ~= fullType then
        table.insert(types, baseType)
    end
    return types
end

function PFC.findItem(player, fullType)
    if not player or not fullType then return nil end
    local inv = player:getInventory()
    if not inv or not inv.getFirstTypeRecurse then return nil end
    for _, searchType in ipairs(PFC.itemSearchTypes(fullType)) do
        local item = inv:getFirstTypeRecurse(searchType)
        if item then return item end
    end
    return nil
end

function PFC.countItem(player, fullType)
    if not player or not fullType then return 0 end
    local inv = player:getInventory()
    if not inv then return 0 end
    for _, searchType in ipairs(PFC.itemSearchTypes(fullType)) do
        if inv.getItemCountRecurse then
            local count = tonumber(inv:getItemCountRecurse(searchType)) or 0
            if count > 0 then return count end
        end
        if inv.getNumberOfItem then
            local count = tonumber(inv:getNumberOfItem(searchType, false, true)) or 0
            if count > 0 then return count end
        end
    end
    return PFC.findItem(player, fullType) and 1 or 0
end

function PFC.hasItem(player, fullType)
    return PFC.findItem(player, fullType) ~= nil
end

function PFC.hasUsableBlowTorch(player)
    local item = PFC.findItem(player, "Base.BlowTorch")
    if not item then return false end
    if item.getCurrentUses then
        return (tonumber(item:getCurrentUses()) or 0) >= 10
    end
    return true
end

function PFC.hasItems(player, requirements)
    if type(requirements) ~= "table" then return true end
    for _, requirement in ipairs(requirements) do
        local count = tonumber(requirement.count) or 1
        if PFC.countItem(player, requirement.fullType) < count then
            return false, requirement.fullType
        end
    end
    return true
end

function PFC.removeItemObject(item)
    if not item or not item.getContainer then return false end
    local container = item:getContainer()
    if container then
        container:DoRemoveItem(item)
        if sendRemoveItemFromContainer then
            sendRemoveItemFromContainer(container, item)
        end
        return true, item
    end
    return false
end

function PFC.consumeItem(player, fullType)
    local item = PFC.findItem(player, fullType)
    if not item then return false end
    return PFC.removeItemObject(item), item
end

function PFC.consumeItems(player, fullType, count)
    count = math.max(1, tonumber(count) or 1)
    local consumed = {}
    for _ = 1, count do
        local ok = PFC.consumeItem(player, fullType)
        if not ok then
            for _, consumedType in ipairs(consumed) do
                PFC.addItem(player, consumedType)
            end
            return false
        end
        table.insert(consumed, fullType)
    end
    return true
end

function PFC.consumeRequirements(player, requirements)
    local consumed = {}
    if type(requirements) ~= "table" then return true, consumed end
    for _, requirement in ipairs(requirements) do
        local fullType = requirement.fullType
        local count = math.max(1, tonumber(requirement.count) or 1)
        for _ = 1, count do
            local ok = PFC.consumeItem(player, fullType)
            if not ok then
                for _, consumedType in ipairs(consumed) do
                    PFC.addItem(player, consumedType)
                end
                return false, consumed
            end
            table.insert(consumed, fullType)
        end
    end
    return true, consumed
end

function PFC.refundConsumed(player, consumed)
    if type(consumed) ~= "table" then return end
    for _, fullType in ipairs(consumed) do
        PFC.addItem(player, fullType)
    end
end

function PFC.consumeServiceItem(player, spec)
    if not spec then return false end
    local consumed = PFC.consumeItem(player, spec.item)
    if consumed then return true end
    if type(spec.alternates) == "table" then
        for _, fullType in ipairs(spec.alternates) do
            consumed = PFC.consumeItem(player, fullType)
            if consumed then return true end
        end
    end
    return false
end

function PFC.addItem(player, fullType)
    if not player or not fullType then return false end
    local inv = player:getInventory()
    if not inv or not inv.AddItem then return false end
    local item = inv:AddItem(fullType)
    if item and sendAddItemToContainer then
        sendAddItemToContainer(inv, item)
    end
    return item ~= nil, item
end

function PFC.craftSupply(player, supplyId)
    local spec = PFC.getSupplySpec(supplyId)
    if not spec then return false, "bad-supply" end
    local consumed = PFC.consumeItem(player, spec.input)
    if not consumed and spec.input == "Base.EngineParts" then
        consumed = PFC.consumeItem(player, "EngineParts")
    end
    if not consumed then return false, "missing-item" end
    if not PFC.addItem(player, spec.output) then return false, "add-failed" end
    if addXp and player and Perks and Perks.Mechanics then
        addXp(player, Perks.Mechanics, 1)
    end
    return true, "ok"
end

function PFC.getVehicleScriptFullName(vehicle)
    if not vehicle then return "" end
    local script = vehicle.getScript and vehicle:getScript() or nil
    if script and script.getFullName then
        local name = script:getFullName()
        if name and name ~= "" then return tostring(name) end
    end
    if vehicle.getScriptName then
        local name = vehicle:getScriptName()
        if name and name ~= "" then return tostring(name) end
    end
    return ""
end

local function splitScriptName(scriptName)
    scriptName = tostring(scriptName or "")
    local prefix, name = string.match(scriptName, "^(.-%.)([^%.]+)$")
    if not name then return "", scriptName end
    return prefix or "", name
end

local function addCandidate(candidates, seen, prefix, name)
    if not name or name == "" then return end
    local candidate = tostring(name)
    if not string.find(candidate, "%.") and prefix and prefix ~= "" then
        candidate = prefix .. candidate
    end
    if not seen[candidate] then
        seen[candidate] = true
        table.insert(candidates, candidate)
    end
end

function PFC.findVehicleScript(scriptName)
    if not scriptName or scriptName == "" or not getScriptManager then return nil end
    local manager = getScriptManager()
    if not manager or not manager.getAllVehicleScripts then return nil end
    local scripts = manager:getAllVehicleScripts()
    if not scripts then return nil end
    for i = 1, scripts:size() do
        local script = scripts:get(i - 1)
        local fullName = script and script.getFullName and script:getFullName() or ""
        local name = script and script.getName and script:getName() or ""
        if fullName == scriptName or name == scriptName then
            return script
        end
    end
    return nil
end

function PFC.getRestoredVehicleScript(vehicle)
    local scriptName = PFC.getVehicleScriptFullName(vehicle)
    if scriptName == "" then return nil, "" end
    local prefix, name = splitScriptName(scriptName)
    local candidates = {}
    local seen = {}

    local mapped = PFC.WRECK_RESTORE_MAPPINGS[name]
    if mapped then addCandidate(candidates, seen, prefix, mapped) end

    for _, suffix in ipairs(PFC.WRECK_SUFFIXES) do
        if string.sub(name, -#suffix) == suffix then
            local root = string.sub(name, 1, #name - #suffix)
            local rootMapped = PFC.WRECK_RESTORE_MAPPINGS[root]
            if rootMapped then addCandidate(candidates, seen, prefix, rootMapped) end
            addCandidate(candidates, seen, prefix, root)
        end
    end

    for _, candidate in ipairs(candidates) do
        local script = PFC.findVehicleScript(candidate)
        local partCount = script and script.getPartCount and tonumber(script:getPartCount()) or 0
        if script and partCount > 0 then
            local fullName = script.getFullName and script:getFullName() or candidate
            return tostring(fullName), script
        end
    end

    return nil, scriptName
end

function PFC.isWreckVehicle(vehicle)
    return PFC.getRestoredVehicleScript(vehicle) ~= nil
end

function PFC.getEngineFeatureSnapshot(vehicle, engine)
    local script = vehicle and vehicle.getScript and vehicle:getScript() or nil
    local condition = engine and engine.getCondition and tonumber(engine:getCondition()) or 0
    local quality = vehicle and vehicle.getEngineQuality and tonumber(vehicle:getEngineQuality()) or nil
    local loudness = vehicle and vehicle.getEngineLoudness and tonumber(vehicle:getEngineLoudness()) or nil
    local power = vehicle and vehicle.getEnginePower and tonumber(vehicle:getEnginePower()) or nil

    if quality == nil and script and script.getEngineQuality then
        quality = tonumber(script:getEngineQuality())
    end
    if loudness == nil and script and script.getEngineLoudness then
        loudness = tonumber(script:getEngineLoudness())
    end
    if power == nil and script and script.getEngineForce then
        power = tonumber(script:getEngineForce())
    end

    return {
        condition = PFC.clamp(condition, 0, 100),
        quality = PFC.clamp(quality or condition, 0, 100),
        loudness = loudness or 100,
        power = power or 0,
        sourceScript = PFC.getVehicleScriptFullName(vehicle),
    }
end

function PFC.applyEngineFeature(vehicle, feature)
    if not vehicle or not vehicle.setEngineFeature then return false end
    feature = feature or {}
    local script = vehicle.getScript and vehicle:getScript() or nil
    local quality = PFC.clamp(feature.quality or feature.condition or 0, 0, 100)
    local loudness = tonumber(feature.loudness)
    if loudness == nil and script and script.getEngineLoudness then
        loudness = tonumber(script:getEngineLoudness())
    end
    local power = tonumber(feature.power)
    if power == nil and script and script.getEngineForce then
        local modifier = PFC.clamp(quality / 100, 0.35, 1.25)
        power = (tonumber(script:getEngineForce()) or 0) * modifier
    end

    vehicle:setEngineFeature(quality, loudness or 100, power or 0)
    if vehicle.transmitEngine then vehicle:transmitEngine() end
    return true
end

function PFC.syncPhysicsAfterVehicleChange(vehicle)
    if not PFC.physicsBridgeEnabled() or not vehicle then
        return
    end
    if IKFRVP and IKFRVP.Bridge and IKFRVP.Bridge.onCompanionVehicleChanged then
        IKFRVP.Bridge.onCompanionVehicleChanged(vehicle, "ProjectFadedCar")
        return
    end
    if PFC.IKFRVPBridge and PFC.IKFRVPBridge.isLoaded and PFC.IKFRVPBridge.isLoaded() and PFC.IKFRVPBridge.syncVehicle then
        PFC.IKFRVPBridge.syncVehicle(vehicle)
    end
end

function PFC.writeSalvagedEngineData(item, feature, store)
    if not item or not item.getModData then return false end
    local modData = item:getModData()
    modData.PFC_SalvagedEngine = true
    modData.pfcVersion = PFC.VERSION
    modData.condition = PFC.clamp(feature and feature.condition or 0, 0, 100)
    modData.quality = PFC.clamp(feature and feature.quality or modData.condition, 0, 100)
    modData.loudness = tonumber(feature and feature.loudness) or 100
    modData.power = tonumber(feature and feature.power) or 0
    modData.sourceScript = tostring(feature and feature.sourceScript or "")
    modData.store = PFC.copyStore(store)
    if item.setCondition then item:setCondition(modData.condition) end
    return true
end

function PFC.readSalvagedEngineData(item)
    if not item or not item.getModData then return nil end
    local modData = item:getModData()
    if modData.PFC_SalvagedEngine ~= true then return nil end
    return modData
end

function PFC.findSalvagedEngine(player)
    local item = PFC.findItem(player, PFC.SALVAGED_ENGINE_ITEM)
    if not item then return nil, nil end
    return item, PFC.readSalvagedEngineData(item)
end

function PFC.canPullEngine(player, vehicle)
    if not PFC.engineSwapsEnabled() then return false, "engine-swap-disabled" end
    if not PFC.canReachEngine(player, vehicle) then return false, "too-far" end
    local blocked, reason = PFC.serviceBlocked(vehicle)
    if blocked then return false, reason end
    if PFC.mechanicsLevel(player) < PFC.engineSwapMechanicsLevel() then return false, "low-mechanics" end
    if not PFC.hasItem(player, "Base.Wrench") then return false, "missing-wrench" end
    local engine = PFC.getEnginePart(vehicle)
    if not engine then return false, "missing-engine" end
    if engine.getCondition and (tonumber(engine:getCondition()) or 0) <= 0 then return false, "empty-engine" end
    return true, "ok"
end

function PFC.pullEngine(vehicle, player)
    local canPull, reason = PFC.canPullEngine(player, vehicle)
    if not canPull then return false, reason end

    local store, engine = PFC.seedVehicle(vehicle, false)
    if not store or not engine then return false, "missing-engine" end

    local feature = PFC.getEngineFeatureSnapshot(vehicle, engine)
    local inv = player and player.getInventory and player:getInventory() or nil
    if not inv or not inv.AddItem then return false, "add-failed" end
    local item = inv:AddItem(PFC.SALVAGED_ENGINE_ITEM)
    if not item then return false, "add-failed" end
    PFC.writeSalvagedEngineData(item, feature, store)
    if sendAddItemToContainer then sendAddItemToContainer(inv, item) end

    engine:setCondition(0)
    if vehicle.transmitPartCondition then vehicle:transmitPartCondition(engine) end
    PFC.applyEngineFeature(vehicle, { quality = 0, loudness = feature.loudness, power = 0 })

    for _, spec in ipairs(PFC.PARTS) do
        PFC.setPartCondition(store, spec.id, 0)
    end
    store.oilLevel = 0
    store.coolantLevel = 0
    store.transmissionFluid = 0
    store.oilQuality = 0
    store.engineHeat = 70
    store.warning = "engine-pulled"
    PFC.recordHistory(store, "pull-engine", feature.sourceScript)
    PFC.ensureStoreDefaults(store)
    PFC.transmitEngineModData(vehicle, engine)
    PFC.syncPhysicsAfterVehicleChange(vehicle)

    if addXp and player and Perks and Perks.Mechanics then
        addXp(player, Perks.Mechanics, 4)
    end
    return true, "engine-pulled"
end

function PFC.canInstallEngine(player, vehicle)
    if not PFC.engineSwapsEnabled() then return false, "engine-swap-disabled" end
    if not PFC.canReachEngine(player, vehicle) then return false, "too-far" end
    local blocked, reason = PFC.serviceBlocked(vehicle)
    if blocked then return false, reason end
    if PFC.mechanicsLevel(player) < PFC.engineSwapMechanicsLevel() then return false, "low-mechanics" end
    if not PFC.hasItem(player, "Base.Wrench") then return false, "missing-wrench" end
    if not PFC.getEnginePart(vehicle) then return false, "missing-engine" end
    local engineItem, data = PFC.findSalvagedEngine(player)
    if not engineItem or not data then return false, "missing-salvaged-engine" end
    local hasRequirements = PFC.hasItems(player, PFC.ENGINE_SWAP_INSTALL_REQUIREMENTS)
    if not hasRequirements then return false, "missing-engine-swap-materials" end
    return true, "ok"
end

function PFC.installEngine(vehicle, player)
    local canInstall, reason = PFC.canInstallEngine(player, vehicle)
    if not canInstall then return false, reason end

    local engineItem, data = PFC.findSalvagedEngine(player)
    if not engineItem or not data then return false, "missing-salvaged-engine" end
    local engine = PFC.getEnginePart(vehicle)
    if not engine or not engine.getModData then return false, "missing-engine" end

    local consumedOk, consumed = PFC.consumeRequirements(player, PFC.ENGINE_SWAP_INSTALL_REQUIREMENTS)
    if not consumedOk then return false, "missing-engine-swap-materials" end
    if not PFC.removeItemObject(engineItem) then
        PFC.refundConsumed(player, consumed)
        return false, "missing-salvaged-engine"
    end

    local condition = PFC.clamp(data.condition or 35, 1, 100)
    engine:setCondition(condition)
    if vehicle.transmitPartCondition then vehicle:transmitPartCondition(engine) end
    PFC.applyEngineFeature(vehicle, data)

    local modData = engine:getModData()
    if type(data.store) == "table" then
        modData[PFC.STORE_KEY] = PFC.copyStore(data.store)
    else
        modData[PFC.STORE_KEY] = {}
    end

    local store = modData[PFC.STORE_KEY]
    if not store or type(store) ~= "table" then
        store = {}
        modData[PFC.STORE_KEY] = store
    end
    store.version = PFC.VERSION
    if type(store.parts) ~= "table" then
        store.parts = {}
        for _, spec in ipairs(PFC.PARTS) do
            store.parts[spec.id] = PFC.clamp(condition + randomRange(-10, 8), 5, 100)
        end
    end
    store.oilLevel = PFC.clamp(store.oilLevel or condition, 0, 100)
    store.coolantLevel = PFC.clamp(store.coolantLevel or condition, 0, 100)
    store.transmissionFluid = PFC.clamp(store.transmissionFluid or condition, 0, 100)
    store.oilQuality = PFC.clamp(store.oilQuality or condition, 0, 100)
    store.engineHeat = PFC.clamp(store.engineHeat or 70, 45, 120)
    store.engineSwap = {
        sourceScript = tostring(data.sourceScript or ""),
        installedHour = getGameTime and getGameTime():getWorldAgeHours() or 0,
        quality = data.quality,
        power = data.power,
        loudness = data.loudness,
    }
    store.warning = ""
    PFC.recordHistory(store, "install-engine", data.sourceScript)
    PFC.ensureStoreDefaults(store)
    PFC.transmitEngineModData(vehicle, engine)
    PFC.syncPhysicsAfterVehicleChange(vehicle)

    if addXp and player and Perks and Perks.Mechanics then
        addXp(player, Perks.Mechanics, 5)
    end
    return true, "engine-installed"
end

function PFC.canRestoreWreck(player, vehicle)
    if not PFC.wreckRestorationEnabled() then return false, "wreck-restore-disabled" end
    if not PFC.canReachEngine(player, vehicle) then return false, "too-far" end
    local blocked, reason = PFC.serviceBlocked(vehicle)
    if blocked then return false, reason end
    if PFC.mechanicsLevel(player) < PFC.wreckRestoreMechanicsLevel() then return false, "low-mechanics" end
    if PFC.metalWeldingLevel(player) < PFC.wreckRestoreMetalWeldingLevel() then return false, "low-welding" end
    if not PFC.hasUsableBlowTorch(player) then return false, "missing-torch" end
    if not PFC.hasItem(player, "Base.WeldingMask") then return false, "missing-mask" end
    local targetScript = PFC.getRestoredVehicleScript(vehicle)
    if not targetScript then return false, "not-wreck" end
    if PFC.wreckRestoreMaterialsRequired() then
        local hasRequirements = PFC.hasItems(player, PFC.WRECK_RESTORE_REQUIREMENTS)
        if not hasRequirements then return false, "missing-wreck-materials" end
    end
    return true, "ok", targetScript
end

function PFC.roughRestoreVehicleParts(vehicle, targetCondition)
    if not vehicle or not vehicle.getPartCount or not vehicle.getPartByIndex then return end
    for i = 1, vehicle:getPartCount() do
        local part = vehicle:getPartByIndex(i - 1)
        if part and part.setCondition then
            local id = part.getId and tostring(part:getId()) or ""
            local condition = targetCondition + randomRange(-12, 14)
            if id == "Engine" then
                condition = targetCondition
            elseif string.find(id, "Window") or string.find(id, "Windshield") then
                condition = targetCondition + randomRange(-20, 10)
            elseif string.find(id, "Door") or string.find(id, "Hood") or string.find(id, "Trunk") then
                condition = targetCondition + randomRange(-15, 18)
            end
            part:setCondition(PFC.clamp(condition, 18, 82))
            if vehicle.transmitPartCondition then vehicle:transmitPartCondition(part) end
        end
    end
    local gasTank = vehicle.getPartById and vehicle:getPartById("GasTank") or nil
    if gasTank and gasTank.setContainerContentAmount then
        gasTank:setContainerContentAmount(0)
        if vehicle.transmitPartModData then vehicle:transmitPartModData(gasTank) end
    end
end

function PFC.restoreWreck(vehicle, player)
    local canRestore, reason, targetScript = PFC.canRestoreWreck(player, vehicle)
    if not canRestore then return false, reason end
    if not vehicle.setScriptName or not vehicle.scriptReloaded then return false, "restore-unavailable" end

    local consumed = {}
    if PFC.wreckRestoreMaterialsRequired() then
        local consumedOk
        consumedOk, consumed = PFC.consumeRequirements(player, PFC.WRECK_RESTORE_REQUIREMENTS)
        if not consumedOk then return false, "missing-wreck-materials" end
    end

    local oldScript = PFC.getVehicleScriptFullName(vehicle)
    if not targetScript or targetScript == "" then
        PFC.refundConsumed(player, consumed)
        return false, "restore-failed"
    end

    vehicle:setScriptName(targetScript)
    vehicle:scriptReloaded(true)
    if vehicle.repair then
        vehicle:repair()
    end

    local condition = PFC.clamp(38 + (PFC.mechanicsLevel(player) * 2) + randomRange(-4, 6), 35, 68)
    PFC.roughRestoreVehicleParts(vehicle, condition)

    local store, engine = PFC.seedVehicle(vehicle, true)
    if store and engine then
        engine:setCondition(condition)
        if vehicle.transmitPartCondition then vehicle:transmitPartCondition(engine) end
        for _, spec in ipairs(PFC.PARTS) do
            store.parts[spec.id] = PFC.clamp(condition + randomRange(-12, 10), 18, 85)
        end
        store.oilLevel = PFC.clamp(condition + randomRange(-18, 12), 8, 85)
        store.coolantLevel = PFC.clamp(condition + randomRange(-18, 12), 8, 85)
        store.transmissionFluid = PFC.clamp(condition + randomRange(-14, 14), 8, 85)
        store.oilQuality = PFC.clamp(condition + randomRange(-20, 10), 5, 80)
        store.engineHeat = 70
        store.warning = ""
        store.restoredFromScript = oldScript
        PFC.recordHistory(store, "restore-wreck", oldScript)
        PFC.ensureStoreDefaults(store)
        PFC.transmitEngineModData(vehicle, engine)
    end

    PFC.syncPhysicsAfterVehicleChange(vehicle)
    if addXp and player and Perks then
        if Perks.Mechanics then addXp(player, Perks.Mechanics, 8) end
        if Perks.MetalWelding then addXp(player, Perks.MetalWelding, 5) end
    end
    return true, "wreck-restored"
end

function PFC.serviceFailureChance(player, spec, store)
    if not spec then return 0 end
    local required = tonumber(spec.skill) or 1
    local level = PFC.mechanicsLevel(player)
    local chance
    if level < required then
        chance = 34 + ((required - level) * 9)
    else
        chance = 16 - ((level - required) * 3)
    end
    if PFC.averageCondition(store) < 35 then chance = chance + 6 end
    if (store and tonumber(store.engineHeat) or 70) > 105 then chance = chance + 4 end
    return math.floor(PFC.clamp(chance, 2, 80))
end

function PFC.getHazardSquare(vehicle, player)
    local square = nil
    if vehicle and vehicle.getSquare then square = vehicle:getSquare() end
    if not square and player and player.getSquare then square = player:getSquare() end
    return square
end

function PFC.applyHazardInjury(player, hazard)
    if not player or not hazard or not player.getBodyDamage then return end
    local bodyDamage = player:getBodyDamage()
    if not bodyDamage or not BodyPartType then return end

    local partType = BodyPartType.Hand_R
    if ZombRand and ZombRand(2) == 0 then partType = BodyPartType.Hand_L end
    local bodyPart = bodyDamage:getBodyPart(partType)
    if not bodyPart then return end

    local severity = tonumber(hazard.severity) or 1
    if hazard.outcome == "fire" or hazard.outcome == "smoke" then
        local burn = 8 + (severity * 8)
        if ZombRand then burn = burn + ZombRand(8) end
        if bodyPart.getBurnTime and bodyPart.setBurnTime then
            bodyPart:setBurnTime(math.max(bodyPart:getBurnTime(), burn))
        end
        if bodyPart.setNeedBurnWash then bodyPart:setNeedBurnWash(true) end
    elseif hazard.outcome == "spark" and bodyPart.setScratched and PFC.rollChance(30 + severity * 10) then
        bodyPart:setScratched(true, false)
    end
end

function PFC.emitServiceHazard(vehicle, player, hazard)
    if not hazard then return nil end

    local square = PFC.getHazardSquare(vehicle, player)
    if square then
        local x, y, z = square:getX(), square:getY(), square:getZ()
        if addSound then
            addSound(player, x, y, z, hazard.outcome == "fire" and 18 or 10, hazard.outcome == "spark" and 4 or 8)
        end
        if IsoFireManager and getCell then
            if hazard.outcome == "spark" then
                IsoFireManager.StartSmoke(getCell(), square, true, 30, 80)
            elseif hazard.outcome == "smoke" then
                IsoFireManager.StartSmoke(getCell(), square, true, 90, 260)
            elseif hazard.outcome == "fire" then
                IsoFireManager.StartSmoke(getCell(), square, true, 120, 360)
                IsoFireManager.StartFire(getCell(), square, true, 35 + (hazard.severity * 10), 160 + (hazard.severity * 90))
            end
        end
    end

    if hazard.outcome == "fire" or hazard.outcome == "smoke" or hazard.injury == true then
        PFC.applyHazardInjury(player, hazard)
    end

    return hazard
end

function PFC.buildServiceHazard(vehicle, player, store, spec, action, targetId, failed)
    if not PFC.serviceHazardsEnabled() then return nil end
    if not store then return nil end

    local severity = PFC.failureSeverity()
    local heat = PFC.clamp(store.engineHeat or 70, 0, 180)
    local risk = PFC.serviceHazardChance()
    local hour = getGameTime and getGameTime():getWorldAgeHours() or 0
    local recentlyRan = (tonumber(store.lastRunHour) or 0) > 0 and (hour - (tonumber(store.lastRunHour) or 0)) < 0.35

    if failed then risk = risk + 20 end
    if PFC.isVehicleEngineRunning(vehicle) then risk = risk + 35 end
    if recentlyRan then risk = risk + 10 end
    if heat > 100 then risk = risk + (heat - 100) * 0.35 end
    if (store.oilLevel or 100) < 25 then risk = risk + (25 - (store.oilLevel or 100)) * 0.7 end
    if (store.coolantLevel or 100) < 25 then risk = risk + (25 - (store.coolantLevel or 100)) * 0.6 end
    if (store.oilQuality or 100) < 25 then risk = risk + (25 - (store.oilQuality or 100)) * 0.4 end
    if PFC.averageCondition(store) < 35 then risk = risk + (35 - PFC.averageCondition(store)) * 0.35 end

    local hotTargets = {
        ignition = true,
        sparkPlugs = true,
        alternator = true,
        starter = true,
        oilSystem = true,
        oilFilter = true,
        oilPan = true,
        headGasket = true,
        beltDrive = true,
    }
    if hotTargets[targetId] then risk = risk + 8 end

    if spec and (PFC.mechanicsLevel(player) < (spec.skill or 1)) then
        risk = risk + ((spec.skill or 1) - PFC.mechanicsLevel(player)) * 6
    end

    risk = PFC.clamp(risk, 0, 95)
    if not PFC.rollChance(risk) then return nil end

    local fireChance = PFC.serviceFireChance() + math.floor(risk / 24)
    if failed then fireChance = fireChance + 2 end
    if heat > 115 then fireChance = fireChance + math.floor((heat - 115) / 6) end

    local outcome = "spark"
    if risk >= 25 and PFC.rollChance(35 + severity * 8) then outcome = "smoke" end
    if risk >= 45 and PFC.rollChance(fireChance) then outcome = "fire" end

    local hazard = {
        outcome = outcome,
        risk = math.floor(risk),
        severity = severity,
        target = tostring(targetId or ""),
        action = tostring(action or ""),
        injury = outcome == "fire" or (outcome == "smoke" and PFC.rollChance(25 + severity * 8)) or false,
    }
    store.lastHazardHour = hour
    store.warning = outcome
    return hazard
end

function PFC.applyService(vehicle, player, action, targetId)
    if action == "pullEngine" then
        return PFC.pullEngine(vehicle, player)
    elseif action == "installEngine" then
        return PFC.installEngine(vehicle, player)
    elseif action == "restoreWreck" then
        return PFC.restoreWreck(vehicle, player)
    end

    local store, engine = PFC.seedVehicle(vehicle, false)
    if not store or not engine then return false, "missing-engine" end

    local hazardSpec = nil
    local failedService = false
    local resultMessage = "ok"

    if action == "replacePart" then
        local spec = PFC.getPartSpec(targetId)
        if not spec then return false, "bad-part" end
        hazardSpec = spec
        local consumed = PFC.consumeServiceItem(player, spec)
        if not consumed then return false, "missing-item" end

        local failChance = PFC.serviceFailureChance(player, spec, store)
        failedService = PFC.rollChance(failChance)
        local restore = PFC.serviceRestorePercent()
        if failedService then
            local before = PFC.partCondition(store, spec.id, spec.base)
            local partial = math.max(before + 8, restore - (18 + (PFC.failureSeverity() * 6)))
            store.parts[spec.id] = PFC.clamp(partial, 0, 100)
            PFC.damageRandomSystem(store, { spec.id, "ignition", "oilSystem", "beltDrive" }, PFC.failureSeverity())
            resultMessage = "service-risk"
        else
            store.parts[spec.id] = restore
        end
        store.lastServiceHour = getGameTime and getGameTime():getWorldAgeHours() or 0
        PFC.recordHistory(store, failedService and "repair-risk" or action, spec.id)
    elseif action == "addFluid" then
        local spec = PFC.getFluidSpec(targetId)
        if not spec then return false, "bad-fluid" end
        hazardSpec = spec
        local consumed = PFC.consumeItem(player, spec.item)
        if not consumed then return false, "missing-item" end
        store[spec.id] = PFC.clamp((tonumber(store[spec.id]) or 0) + spec.add, 0, 100)
        if spec.id == "oilLevel" then
            store.oilQuality = PFC.clamp((tonumber(store.oilQuality) or 0) + math.floor(spec.add * 0.65), 0, 100)
        elseif spec.id == "coolantLevel" then
            store.engineHeat = PFC.clamp((tonumber(store.engineHeat) or 70) - 8, 35, 180)
        end
        store.lastServiceHour = getGameTime and getGameTime():getWorldAgeHours() or 0
        PFC.recordHistory(store, action, spec.id)
    elseif action == "tuneEngine" then
        local consumed = PFC.consumeItem(player, "Base.EngineParts")
        if not consumed then
            consumed = PFC.consumeItem(player, "EngineParts")
        end
        if not consumed then return false, "missing-item" end
        hazardSpec = { id = "engine", skill = 4 }
        failedService = PFC.rollChance(PFC.serviceFailureChance(player, hazardSpec, store))
        local average = PFC.averageCondition(store)
        local current = engine:getCondition()
        local tuneLift = failedService and 1 or 4
        local target = math.min(100, math.max(current, math.floor((current + average) / 2) + tuneLift))
        engine:setCondition(target)
        for _, spec in ipairs(PFC.PARTS) do
            local before = PFC.clamp(store.parts[spec.id] or spec.base, 0, 100)
            local lift = failedService and math.max(1, math.floor((100 - before) * 0.03)) or math.max(3, math.floor((100 - before) * 0.10))
            store.parts[spec.id] = PFC.clamp(before + lift, 0, 100)
        end
        if failedService then
            PFC.damageRandomSystem(store, { "ignition", "sparkPlugs", "oilSystem", "beltDrive" }, PFC.failureSeverity())
            resultMessage = "service-risk"
        end
        if vehicle.transmitPartCondition then vehicle:transmitPartCondition(engine) end
        store.lastServiceHour = getGameTime and getGameTime():getWorldAgeHours() or 0
        PFC.recordHistory(store, failedService and "tune-risk" or action, "engine")
    else
        return false, "bad-action"
    end

    local hazard = PFC.buildServiceHazard(vehicle, player, store, hazardSpec, action, targetId, failedService)
    if hazard then
        PFC.emitServiceHazard(vehicle, player, hazard)
        if hazard.outcome == "fire" then
            local current = engine:getCondition()
            if current > 0 then
                engine:setCondition(math.max(0, current - (3 * PFC.failureSeverity())))
                if vehicle.transmitPartCondition then vehicle:transmitPartCondition(engine) end
            end
            resultMessage = "service-fire"
        elseif hazard.outcome == "smoke" then
            PFC.damageRandomSystem(store, { tostring(targetId or "ignition"), "ignition", "oilSystem", "sparkPlugs" }, PFC.failureSeverity())
            resultMessage = "service-smoke"
        elseif resultMessage == "ok" then
            resultMessage = "service-spark"
        end
    else
        store.warning = ""
    end

    PFC.transmitEngineModData(vehicle, engine)
    if addXp and player and Perks and Perks.Mechanics then
        addXp(player, Perks.Mechanics, failedService and 1 or 2)
    end
    return true, resultMessage, hazard
end

function PFC.applyVehicleTune(vehicle, player, key, value)
    if key ~= "towAssist" then return false, "bad-tune" end
    local store, engine = PFC.seedVehicle(vehicle, false)
    if not store or not engine then return false, "missing-engine" end
    PFC.ensureStoreDefaults(store)

    value = math.floor(PFC.clamp(value, 75, 125))
    local driveline = (PFC.partCondition(store, "transmission", 100) + PFC.partCondition(store, "torqueConverter", 100) + PFC.partCondition(store, "brakeAssist", 100)) / 3
    local effectiveTow = math.floor(value * PFC.clamp(driveline / 100, 0.45, 1.05))
    store.tuning.towAssist = value
    store.csrBridge.mod = "ProjectFadedCar"
    store.csrBridge.version = PFC.VERSION
    store.csrBridge.towAssist = value
    store.csrBridge.effectiveTowAssist = effectiveTow
    store.csrBridge.updatedHour = getGameTime and getGameTime():getWorldAgeHours() or 0
    store.lastServiceHour = getGameTime and getGameTime():getWorldAgeHours() or 0
    PFC.recordHistory(store, "tune", key .. "=" .. tostring(value))

    PFC.transmitEngineModData(vehicle, engine)
    return true, "ok"
end

PFC.API = PFC.API or {}
PFC.API.version = PFC.VERSION
PFC.API.getSnapshot = PFC.getSnapshot
PFC.API.canReachEngine = PFC.canReachEngine
PFC.API.canPullEngine = PFC.canPullEngine
PFC.API.canInstallEngine = PFC.canInstallEngine
PFC.API.canRestoreWreck = PFC.canRestoreWreck
PFC.API.getVehicleTune = function(vehicle, key)
    local store = PFC.peekStore(vehicle)
    PFC.ensureStoreDefaults(store)
    if not store or not store.tuning then return nil end
    return store.tuning[key or "towAssist"]
end
PFC.API.openServicePanel = function(playerObj, vehicle)
    if ProjectFadedCarClient and ProjectFadedCarClient.openServicePanel then
        ProjectFadedCarClient.openServicePanel(playerObj, vehicle)
        return true
    end
    return false
end
