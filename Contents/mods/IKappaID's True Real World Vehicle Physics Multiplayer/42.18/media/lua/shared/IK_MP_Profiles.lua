require "IK_MP_Core"

IK_MP.Profiles = IK_MP.Profiles or {}

local Profiles = IK_MP.Profiles

-- Community baseline (B42.18): engineForce = hp * ENGINE_FORCE_PER_HP.
-- Pass 4 (parking / crawl): script steeringClamp/grip + runtime park-assist targets (IKappaID_BrakeRuntime).
-- Sport/Luxury/Race/CompactSport use class 70% assist; other profiles have per-id targets in BrakeRuntime.
-- Pass 3 (acceleration): class/profile power mults + runtime setEngineFeature (IKappaID_BrakeRuntime).
-- Pass 2 (brakes): target stop-time model + runtime setBrakingForce (see IKappaID_BrakeRuntime).
-- Further power: sandbox PowerScale, EngineTorqueMult, per-class EngineMult.

Profiles.ENGINE_FORCE_PER_HP = 11.4
-- brakeRetainMul lengthens target stop time (<1 = longer). wheelFriction untouched for grip.
Profiles.definitions = {
    Compact = { hp = 115, mass = 955, class = "compact", brakeRetainMul = 0.82 },
    CompactSport = { hp = 160, mass = 1325, class = "sport", brakeRetainMul = 1.00 },
    Sedan = { hp = 205, mass = 1760, class = "standard", brakeRetainMul = 0.88 },
    ModernSedan = { hp = 205, mass = 1305, class = "standard", brakeRetainMul = 0.86 },
    Wagon = { hp = 225, mass = 1950, class = "standard", brakeRetainMul = 0.86 },
    Luxury = { hp = 260, mass = 1855, class = "sport", brakeRetainMul = 1.00 },
    Sport = { hp = 310, mass = 1485, class = "sport", brakeRetainMul = 1.00 },
    Race = { hp = 403, mass = 1540, class = "sport", brakeRetainMul = 0.96 },
    Offroad = { hp = 165, mass = 1515, class = "heavy", brakeRetainMul = 0.90 },
    Pickup = { hp = 155, mass = 2240, class = "heavy", brakeRetainMul = 0.88 },
    CrewPickup = { hp = 176, mass = 2355, class = "heavy", brakeRetainMul = 0.86 },
    SUV = { hp = 187, mass = 2225, class = "heavy", brakeRetainMul = 0.86 },
    Van = { hp = 200, mass = 2310, class = "heavy", brakeRetainMul = 0.58 },
    StepVan = { hp = 175, mass = 3260, class = "heavy", brakeRetainMul = 0.55 },
    CommercialVan = { hp = 285, mass = 3450, class = "heavy", brakeRetainMul = 0.62 },
    HeavyTruck = { hp = 580, mass = 9200, class = "heavy", brakeRetainMul = 0.72 },
    MilitaryAPC = { hp = 260, mass = 5500, class = "heavy", brakeRetainMul = 0.72 },
    TrailerLight = { mass = 520, class = "trailer" },
    TrailerCargo = { mass = 955, class = "trailer" },
    TrailerHeavy = { mass = 1490, class = "trailer" },
}

Profiles.vehicleMap = Profiles.vehicleMap or {}

local function assign(profileId, names)
    for i = 1, #names do
        Profiles.vehicleMap[names[i]] = profileId
    end
end

assign("Sedan", {
    "Base.CarNormal",
    "Base.CarNormalBurnt",
    "Base.CarNormalSmashedFront",
    "Base.CarNormalSmashedLeft",
    "Base.CarNormalSmashedRear",
    "Base.CarNormalSmashedRight",
    "Base.NormalCarBurntPolice",
    "Base.CarLightsBulletinSheriff",
    "Base.CarLightsKST",
    "Base.CarLightsLouisvilleCounty",
    "Base.CarLightsMuldraughPolice",
    "Base.CarLightsPolice",
    "Base.CarLightsRanger",
    "Base.CarLightsSmashedFront",
    "Base.CarLightsSmashedLeft",
    "Base.CarLightsSmashedRear",
    "Base.CarLightsSmashedRight",
    "Base.CarTaxi",
    "Base.CarTaxi2",
    "Base.TaxiBurnt",
})

assign("Luxury", {
    "Base.CarLuxury",
    "Base.CarLuxurySmashedFront",
    "Base.CarLuxurySmashedLeft",
    "Base.CarLuxurySmashedRear",
    "Base.CarLuxurySmashedRight",
    "Base.LuxuryCarBurnt",
})

assign("Wagon", {
    "Base.CarStationWagon",
    "Base.CarStationWagon2",
    "Base.CarStationWagonSmashedFront",
    "Base.CarStationWagonSmashedLeft",
    "Base.CarStationWagonSmashedRear",
    "Base.CarStationWagonSmashedRight",
})

assign("ModernSedan", {
    "Base.ModernCar",
    "Base.ModernCarBurnt",
    "Base.ModernCarSmashedFront",
    "Base.ModernCarSmashedLeft",
    "Base.ModernCarSmashedRear",
    "Base.ModernCarSmashedRight",
    "Base.ModernCarLightsCityLouisvillePD",
    "Base.ModernCarLightsMeadeSheriff",
    "Base.ModernCarLightsWestPoint",
    "Base.ModernCar02",
    "Base.ModernCar02Burnt",
    "Base.ModernCar02SmashedFront",
    "Base.ModernCar02SmashedLeft",
    "Base.ModernCar02SmashedRear",
    "Base.ModernCar02SmashedRight",
})

assign("Offroad", {
    "Base.OffRoad",
    "Base.OffRoadBurnt",
    "Base.OffRoadSmashedFront",
    "Base.OffRoadSmashedLeft",
    "Base.OffRoadSmashedRear",
    "Base.OffRoadSmashedRight",
})

assign("Pickup", {
    "Base.PickUpTruck",
    "Base.PickUpTruck_Camo",
    "Base.PickupBurnt",
    "Base.PickupSpecialBurnt",
    "Base.PickUpTruckSmashedFront",
    "Base.PickUpTruckSmashedLeft",
    "Base.PickUpTruckSmashedRear",
    "Base.PickUpTruckSmashedRight",
    "Base.PickUpTruckJPLandscaping",
    "Base.PickUpTruckLightsAirport",
    "Base.PickUpTruckLightsAirportSecurity",
    "Base.PickUpTruckLightsFire",
    "Base.PickUpTruckLightsFossoil",
    "Base.PickUpTruckLightsRanger",
    "Base.PickUpTruckMccoy",
})

assign("CrewPickup", {
    "Base.PickUpVan",
    "Base.PickUpVan_Camo",
    "Base.PickUpVanBrickingIt",
    "Base.PickUpVanBuilder",
    "Base.PickUpVanCallowayLandscaping",
    "Base.PickUpVanHeltonMetalWorking",
    "Base.PickUpVanKimbleKonstruction",
    "Base.PickUpVanLightsCarpenter",
    "Base.PickUpVanLightsFire",
    "Base.PickUpVanLightsFossoil",
    "Base.PickUpVanLightsKentuckyLumber",
    "Base.PickUpVanLightsLouisvilleCounty",
    "Base.PickUpVanLightsPolice",
    "Base.PickUpVanLightsRanger",
    "Base.PickUpVanLightsStatePolice",
    "Base.PickUpVanMarchRidgeConstruction",
    "Base.PickUpVanMccoy",
    "Base.PickUpVanMetalworker",
    "Base.PickUpVanWeldingbyCamille",
    "Base.PickUpVanYingsWood",
})

assign("Race", {
    "Base.RaceCar12",
    "Base.RaceCar34",
    "Base.RaceCar58",
})

assign("Compact", {
    "Base.SmallCar",
    "Base.CarSmallSmashedFront",
    "Base.CarSmallSmashedLeft",
    "Base.CarSmallSmashedRear",
    "Base.CarSmallSmashedRight",
})

assign("CompactSport", {
    "Base.SmallCar02",
    "Base.CarSmall02SmashedFront",
    "Base.CarSmall02SmashedLeft",
    "Base.CarSmall02SmashedRear",
    "Base.CarSmall02SmashedRight",
})

assign("Sport", {
    "Base.SportsCar",
    "Base.SportsCar_ez",
    "Base.SportsCarBurnt",
})

assign("StepVan", {
    "Base.StepVan",
    "Base.StepVan_Blacksmith",
    "Base.StepVan_Butchers",
    "Base.StepVan_Cereal",
    "Base.StepVan_Citr8",
    "Base.StepVan_CompleteRepairShop",
    "Base.StepVan_Florist",
    "Base.StepVan_Genuine_Beer",
    "Base.StepVan_Glass",
    "Base.StepVan_Heralds",
    "Base.StepVan_HuangsLaundry",
    "Base.StepVan_Jorgensen",
    "Base.StepVan_LouisvilleMotorShop",
    "Base.StepVan_LouisvilleSWAT",
    "Base.StepVan_MarineBites",
    "Base.StepVan_Masonry",
    "Base.StepVan_Mechanic",
    "Base.StepVan_MobileLibrary",
    "Base.StepVan_Plonkies",
    "Base.StepVan_Propane",
    "Base.StepVan_RandisPlants",
    "Base.StepVan_Scarlet",
    "Base.StepVan_SmartKut",
    "Base.StepVan_SouthEasternHosp",
    "Base.StepVan_SouthEasternPaint",
    "Base.StepVan_USL",
    "Base.StepVan_Zippee",
    "Base.StepVanAirportCatering",
    "Base.StepVanMail",
    "Base.StepVanMailSmashedFront",
    "Base.StepVanMailSmashedLeft",
    "Base.StepVanMailSmashedRear",
    "Base.StepVanMailSmashedRight",
    "Base.StepVanSmashedFront",
    "Base.StepVanSmashedLeft",
    "Base.StepVanSmashedRear",
    "Base.StepVanSmashedRight",
})

assign("SUV", {
    "Base.SUV",
    "Base.SUVBurnt",
    "Base.SUVSmashedFront",
    "Base.SUVSmashedLeft",
    "Base.SUVSmashedRear",
    "Base.SUVSmashedRight",
})

assign("Van", {
    "Base.Van",
    "Base.Van_Blacksmith",
    "Base.Van_BugWipers",
    "Base.Van_Charlemange_Beer",
    "Base.Van_CraftSupplies",
    "Base.Van_Glass",
    "Base.Van_HeritageTailors",
    "Base.Van_KnoxDisti",
    "Base.Van_Leather",
    "Base.Van_LectroMax",
    "Base.Van_Locksmith",
    "Base.Van_Masonry",
    "Base.Van_MassGenFac",
    "Base.Van_Perfick_Potato",
    "Base.Van_Transit",
    "Base.Van_VoltMojo",
    "Base.Ambulance",
    "Base.VanAmbulance",
    "Base.VanBeckmans",
    "Base.VanBrewsterHarbin",
    "Base.VanBuilder",
    "Base.VanBurnt",
    "Base.VanCarpenter",
    "Base.VanCoastToCoast",
    "Base.VanDeerValley",
    "Base.VanFossoil",
    "Base.VanGardener",
    "Base.VanGardenGods",
    "Base.VanGreenes",
    "Base.VanJohnMcCoy",
    "Base.VanJonesFabrication",
    "Base.VanKerrHomes",
    "Base.VanKnobCreekGas",
    "Base.VanKnoxCom",
    "Base.VanKorshunovs",
    "Base.VanLouisvilleLandscaping",
    "Base.VanMail",
    "Base.VanMccoy",
    "Base.VanMechanic",
    "Base.VanMeltingPointMetal",
    "Base.VanMetalheads",
    "Base.VanMetalworker",
    "Base.VanMicheles",
    "Base.VanMobileMechanics",
    "Base.VanMooreMechanics",
    "Base.VanOldMill",
    "Base.VanOvoFarm",
    "Base.VanPennSHam",
    "Base.VanPlattAuto",
    "Base.VanPluggedInElectrics",
    "Base.VanRadio",
    "Base.VanRadio_3N",
    "Base.VanRadioBurnt",
    "Base.VanRiversideFabrication",
    "Base.VanRosewoodworking",
    "Base.VanSchwabSheetMetal",
    "Base.VanSeats",
    "Base.VanSeats_Creature",
    "Base.VanSeats_LadyDelighter",
    "Base.VanSeats_Mural",
    "Base.VanSeats_Prison",
    "Base.VanSeats_Space",
    "Base.VanSeats_Trippy",
    "Base.VanSeats_Valkyrie",
    "Base.VanSeatsAirportShuttle",
    "Base.VanSeatsBurnt",
    "Base.VanSpiffo",
    "Base.VanTreyBaines",
    "Base.VanUncloggers",
    "Base.VanUtility",
    "Base.VanWPCarpentry",
})

assign("TrailerCargo", {
    "Base.Trailer",
    "Base.TrailerCover",
})

assign("TrailerHeavy", {
    "Base.Trailer_Horsebox",
    "Base.Trailer_Livestock",
})

assign("TrailerLight", {
    "Base.TrailerAdvert",
})

local function mergeRoster(rosterTable)
    if not rosterTable then
        return
    end
    for profileId, names in pairs(rosterTable) do
        assign(profileId, names)
    end
end

if not IK_MP_KI5_Roster then
    require "IK_MP_Profiles_KI5"
end
mergeRoster(IK_MP_KI5_Roster)

if not IK_MP_ATA_Roster then
    require "IK_MP_Profiles_ATA"
end
mergeRoster(IK_MP_ATA_Roster)

if not IK_MP_Autotsar_Roster then
    require "IK_MP_Profiles_Autotsar"
end
mergeRoster(IK_MP_Autotsar_Roster)

if not IK_MP_FHQ_Roster then
    require "IK_MP_Profiles_FHQ"
end
mergeRoster(IK_MP_FHQ_Roster)

if not IK_MP_Misc_Roster then
    require "IK_MP_Profiles_Misc"
end
mergeRoster(IK_MP_Misc_Roster)

if not IK_MP_rSemiTruck_Roster then
    require "IK_MP_Profiles_rSemiTruck"
end
mergeRoster(IK_MP_rSemiTruck_Roster)

function Profiles.getProfile(profileId)
    local profile = Profiles.definitions[profileId]
    if not profile then
        return nil
    end
    profile.id = profileId
    if profile.hp then
        profile.engineForce = math.floor(profile.hp * Profiles.ENGINE_FORCE_PER_HP + 0.5)
    end
    return profile
end

function Profiles.profileIdForScriptName(scriptName)
    if not scriptName or scriptName == "" then
        return nil
    end
    return Profiles.vehicleMap[scriptName]
end

function Profiles.resolveProfile(script)
    local fullName = IK_MP.getScriptFullName(script)
    local profileId = Profiles.profileIdForScriptName(fullName)
    if profileId then
        return Profiles.getProfile(profileId), fullName
    end

    local name = IK_MP.getScriptName(script)
    profileId = Profiles.profileIdForScriptName("Base." .. name)
    if profileId then
        return Profiles.getProfile(profileId), "Base." .. name
    end

    local lowerName = string.lower(fullName or name or "")
    -- W900 / rSemiTruck (3409472393) — before generic truck/trailer fallbacks
    if string.find(lowerName, "semitruck", 1, true) then
        return Profiles.getProfile("HeavyTruck"), fullName
    end
    if string.find(lowerName, "semitrailer", 1, true) then
        return Profiles.getProfile("TrailerHeavy"), fullName
    end
    if string.find(lowerName, "trailertsmega", 1, true) or string.find(lowerName, "semitrailercartrailer", 1, true) then
        return Profiles.getProfile("TrailerHeavy"), fullName
    end
    -- Autotsar Trailers (3402493701) — before generic trailer fallback
    if string.find(lowerName, "trailergenerator", 1, true) then
        return Profiles.getProfile("TrailerHeavy"), fullName
    end
    if string.find(lowerName, "trailerfirst", 1, true) or string.find(lowerName, "trailersecond", 1, true)
        or string.find(lowerName, "trailerkbac", 1, true) or string.find(lowerName, "trailerhome", 1, true) then
        return Profiles.getProfile("TrailerCargo"), fullName
    end
    if string.find(lowerName, "trailer", 1, true) then
        return Profiles.getProfile("TrailerCargo"), fullName
    end
    if string.find(lowerName, "sport", 1, true) then
        return Profiles.getProfile("Sport"), fullName
    end
    -- ATA Tuning Atelier — before generic van/truck (ATA_VanDeRumba contains "van")
    if string.find(lowerName, "ata_vanderumba", 1, true) or string.find(lowerName, "atavanderumba", 1, true) then
        return Profiles.getProfile("Van"), fullName
    end
    if string.find(lowerName, "atajeep", 1, true) then
        return Profiles.getProfile("Offroad"), fullName
    end
    if string.find(lowerName, "atasamara", 1, true) then
        return Profiles.getProfile("Compact"), fullName
    end
    if string.find(lowerName, "ataschoolbus", 1, true) or string.find(lowerName, "ataprisonbus", 1, true)
        or string.find(lowerName, "ataarmybus", 1, true) then
        return Profiles.getProfile("CommercialVan"), fullName
    end
    if string.find(lowerName, "atabmwe36", 1, true) then
        if string.find(lowerName, "m3", 1, true) then
            return Profiles.getProfile("Sport"), fullName
        end
        return Profiles.getProfile("ModernSedan"), fullName
    end
    if string.find(lowerName, "atadodge", 1, true) then
        return Profiles.getProfile("Sport"), fullName
    end
    if string.find(lowerName, "atadelorean", 1, true) then
        return Profiles.getProfile("Sport"), fullName
    end
    if string.find(lowerName, "van", 1, true) then
        return Profiles.getProfile("Van"), fullName
    end
    if string.find(lowerName, "pickup", 1, true) or string.find(lowerName, "truck", 1, true) then
        return Profiles.getProfile("Pickup"), fullName
    end
    if string.find(lowerName, "suv", 1, true) then
        return Profiles.getProfile("SUV"), fullName
    end
    if string.find(lowerName, "atamustang", 1, true) then
        return Profiles.getProfile("Sport"), fullName
    end
    if string.find(lowerName, "atapete", 1, true) or string.find(lowerName, "petyarbuilt", 1, true) then
        return Profiles.getProfile("HeavyTruck"), fullName
    end
    if string.find(lowerName, "ata_luton", 1, true) or string.find(lowerName, "ataluton", 1, true) then
        return Profiles.getProfile("CommercialVan"), fullName
    end
    if string.find(lowerName, "isocontainer", 1, true) then
        return Profiles.getProfile("TrailerHeavy"), fullName
    end
    if string.find(lowerName, "tatra815", 1, true) then
        return Profiles.getProfile("HeavyTruck"), fullName
    end
    if string.find(lowerName, "commando", 1, true) or string.find(lowerName, "bushmaster", 1, true) then
        return Profiles.getProfile("MilitaryAPC"), fullName
    end
    if string.find(lowerName, "mankat", 1, true) or string.find(lowerName, "m923", 1, true) then
        return Profiles.getProfile("HeavyTruck"), fullName
    end
    -- fhqwhgads' Motorious Zone (2791656602) — prefix fallback for variants not on roster
    if string.find(lowerName, "fhq", 1, true) then
        if string.find(lowerName, "trailer", 1, true) then
            return Profiles.getProfile("TrailerCargo"), fullName
        end
        if string.find(lowerName, "f1", 1, true) or string.find(lowerName, "diablo", 1, true)
            or string.find(lowerName, "mclaren", 1, true) or string.find(lowerName, "gt40", 1, true)
            or string.find(lowerName, "250gto", 1, true) then
            return Profiles.getProfile("Race"), fullName
        end
        if string.find(lowerName, "mustang", 1, true) or string.find(lowerName, "impreza", 1, true)
            or string.find(lowerName, "celica", 1, true) or string.find(lowerName, "rx7", 1, true)
            or string.find(lowerName, "supra", 1, true) then
            return Profiles.getProfile("Sport"), fullName
        end
        if string.find(lowerName, "w140", 1, true) or string.find(lowerName, "v140", 1, true)
            or string.find(lowerName, "lexus", 1, true) then
            return Profiles.getProfile("Luxury"), fullName
        end
        if string.find(lowerName, "van", 1, true) or string.find(lowerName, "vwt", 1, true)
            or string.find(lowerName, "econoline", 1, true) then
            return Profiles.getProfile("Van"), fullName
        end
        if string.find(lowerName, "m715", 1, true) or string.find(lowerName, "pickup", 1, true) then
            return Profiles.getProfile("Pickup"), fullName
        end
        if string.find(lowerName, "sidekick", 1, true) or string.find(lowerName, "lm002", 1, true) then
            return Profiles.getProfile("SUV"), fullName
        end
        return Profiles.getProfile("ModernSedan"), fullName
    end

    return nil, fullName
end

return Profiles


