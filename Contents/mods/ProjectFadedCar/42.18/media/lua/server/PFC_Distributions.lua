if isClient() then return end

ProjectFadedCarDistributions = ProjectFadedCarDistributions or {}

local PFC_DIST = ProjectFadedCarDistributions

local function addProc(bucket, item, weight)
    if not ProceduralDistributions or not ProceduralDistributions.list then return end
    local dist = ProceduralDistributions.list[bucket]
    if not dist or type(dist.items) ~= "table" then return end
    table.insert(dist.items, item)
    table.insert(dist.items, weight)
end

local function addMany(buckets, items)
    for _, bucket in ipairs(buckets) do
        for _, entry in ipairs(items) do
            addProc(bucket, entry[1], entry[2])
        end
    end
end

function PFC_DIST.addLoot()
    if PFC_DIST.done then return end
    PFC_DIST.done = true

    local coreKits = {
        { "ProjectFadedCar.EngineServiceKit", 1.2 },
        { "ProjectFadedCar.RadiatorServiceKit", 1.0 },
        { "ProjectFadedCar.WaterPumpKit", 0.8 },
        { "ProjectFadedCar.OilFilterServiceKit", 1.4 },
        { "ProjectFadedCar.OilPanServiceKit", 0.7 },
        { "ProjectFadedCar.HeadGasketSet", 0.6 },
        { "ProjectFadedCar.CylinderHeadServiceKit", 0.4 },
        { "ProjectFadedCar.RotatingAssemblyKit", 0.3 },
        { "ProjectFadedCar.SparkPlugSet", 1.4 },
        { "ProjectFadedCar.IgnitionServicePack", 1.4 },
        { "ProjectFadedCar.DriveBelt", 1.6 },
        { "ProjectFadedCar.AlternatorServiceKit", 1.0 },
        { "ProjectFadedCar.StarterServiceKit", 1.0 },
        { "ProjectFadedCar.TransmissionServiceKit", 0.8 },
        { "ProjectFadedCar.TorqueConverterKit", 0.5 },
        { "ProjectFadedCar.BrakeAssistKit", 0.6 },
        { "ProjectFadedCar.SteeringPumpKit", 0.6 },
        { "ProjectFadedCar.ClimateControlKit", 0.5 },
    }

    local fluids = {
        { "ProjectFadedCar.FreshMotorOil", 2.4 },
        { "ProjectFadedCar.CoolantMix", 1.8 },
        { "ProjectFadedCar.TransmissionFluid", 1.3 },
    }

    addMany({ "GarageMechanics", "MechanicShelfTools", "CarSupplyTools" }, coreKits)
    addMany({ "GarageMechanics", "MechanicShelfTools", "CarSupplyGasCans", "CarSupplyTools" }, fluids)

    addMany({ "MechanicShelfElectric" }, {
        { "ProjectFadedCar.IgnitionServicePack", 2.0 },
        { "ProjectFadedCar.SparkPlugSet", 2.0 },
        { "ProjectFadedCar.AlternatorServiceKit", 1.8 },
        { "ProjectFadedCar.StarterServiceKit", 1.8 },
        { "ProjectFadedCar.ClimateControlKit", 0.8 },
    })

    addMany({ "CrateMechanics", "CrateTools", "ToolStoreTools" }, coreKits)
    addMany({ "CrateMechanics", "CrateTools", "ToolStoreTools" }, fluids)

    addMany({ "GasStorageMechanics", "GasStorageCombo" }, {
        { "ProjectFadedCar.FreshMotorOil", 2.8 },
        { "ProjectFadedCar.CoolantMix", 2.0 },
        { "ProjectFadedCar.TransmissionFluid", 1.5 },
        { "ProjectFadedCar.DriveBelt", 1.0 },
        { "ProjectFadedCar.OilFilterServiceKit", 1.2 },
        { "ProjectFadedCar.SparkPlugSet", 0.9 },
        { "ProjectFadedCar.EngineServiceKit", 0.6 },
    })

    addMany({ "BarnTools", "CrateFarming", "ToolCabinetFarming", "ToolStoreFarming" }, {
        { "ProjectFadedCar.DriveBelt", 0.8 },
        { "ProjectFadedCar.FreshMotorOil", 0.8 },
        { "ProjectFadedCar.CoolantMix", 0.6 },
        { "ProjectFadedCar.EngineServiceKit", 0.4 },
        { "ProjectFadedCar.RadiatorServiceKit", 0.3 },
        { "ProjectFadedCar.WaterPumpKit", 0.3 },
        { "ProjectFadedCar.OilFilterServiceKit", 0.5 },
        { "ProjectFadedCar.SparkPlugSet", 0.4 },
    })
end

if Events and Events.OnPreDistributionMerge then
    Events.OnPreDistributionMerge.Add(PFC_DIST.addLoot)
else
    PFC_DIST.addLoot()
end
