require "IKFRVP_Core"

IKFRVP.Profiles = IKFRVP.Profiles or {}

local Profiles = IKFRVP.Profiles

Profiles.definitions = {
    Compact = { hp = 78, mass = 955, class = "compact" },
    CompactSport = { hp = 145, mass = 1325, class = "sport" },
    Sedan = { hp = 170, mass = 1760, class = "standard" },
    ModernSedan = { hp = 125, mass = 1305, class = "standard" },
    Wagon = { hp = 165, mass = 1950, class = "standard" },
    Luxury = { hp = 225, mass = 1855, class = "sport" },
    Sport = { hp = 265, mass = 1485, class = "sport" },
    Race = { hp = 365, mass = 1540, class = "sport" },
    Offroad = { hp = 180, mass = 1515, class = "heavy" },
    Pickup = { hp = 165, mass = 2240, class = "heavy" },
    CrewPickup = { hp = 160, mass = 2355, class = "heavy" },
    SUV = { hp = 170, mass = 2225, class = "heavy" },
    Van = { hp = 115, mass = 2310, class = "heavy" },
    StepVan = { hp = 118, mass = 3260, class = "heavy" },
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

function Profiles.getProfile(profileId)
    local profile = Profiles.definitions[profileId]
    if not profile then
        return nil
    end
    profile.id = profileId
    if profile.hp and not profile.engineForce then
        -- 1.0.0: hp*10 for all. Heavy only: hp*12 for slightly stronger acceleration (minivans, trucks, SUVs).
        if profile.class == "heavy" then
            profile.engineForce = math.floor(profile.hp * 12 + 0.5)
        else
            profile.engineForce = profile.hp * 10
        end
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
    local fullName = IKFRVP.getScriptFullName(script)
    local profileId = Profiles.profileIdForScriptName(fullName)
    if profileId then
        return Profiles.getProfile(profileId), fullName
    end

    local name = IKFRVP.getScriptName(script)
    profileId = Profiles.profileIdForScriptName("Base." .. name)
    if profileId then
        return Profiles.getProfile(profileId), "Base." .. name
    end

    local lowerName = string.lower(fullName or name or "")
    if string.find(lowerName, "trailer", 1, true) then
        return Profiles.getProfile("TrailerCargo"), fullName
    end
    if string.find(lowerName, "sport", 1, true) then
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

    return nil, fullName
end

return Profiles
