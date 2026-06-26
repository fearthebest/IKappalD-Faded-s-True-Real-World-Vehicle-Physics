-- KI5 vehicle pack — B42 only (mod targets 42.18+). Do NOT roster B41 legacy packs.
-- Allowlist sources: collection 3652192243 (KI5 B42 MP), 3414495781 (B42.12 Kiurio).
-- NOT scraped from https://steamcommunity.com/id/KI5/myworkshopfiles/ (includes B41 items).
-- Regenerate: tools/ki5_roster_audit.py + tools/ki5_b41_guard.py (reject B41-only workshop layout).
-- Total vehicles: 448
-- Plain global table: PZ Kahlua cannot compile UTF-8 BOM or top-level return here.
IK_MP_KI5_Roster = {
    Compact = {
        "Base.63beetle", "Base.63beetleBuggy", "Base.63beetleHP", "Base.69mini",
        "Base.69miniIJ", "Base.69miniMrB", "Base.69miniPS", "Base.69miniUnionJack",
        "Base.91geoMetro", "Base.96saturnSL2"
    },

    CompactSport = {
        "Base.70fordEscortCoupe", "Base.70fordEscortRS", "Base.87toyotaMR2", "Base.87toyotaMR2c",
        "Base.90bmwE30m3", "Base.91nissan240sx", "Base.91nissan240sx2", "Base.95impreza",
        "Base.95imprezalhd", "Base.96lancerEVO", "Base.96lancerEVOlhd"
    },

    Sedan = {
        "Base.59meteor", "Base.70fordEscortSedan", "Base.85buickLeSabreCoupe", "Base.85buickLeSabreSedan",
        "Base.85chevyCapriceCoupe", "Base.85chevyCapriceSedan", "Base.85chevyImpalaSedanAirport", "Base.85chevyImpalaSedanBCS",
        "Base.85chevyImpalaSedanCLPD", "Base.85chevyImpalaSedanFD", "Base.85chevyImpalaSedanKSP", "Base.85chevyImpalaSedanLCPD",
        "Base.85chevyImpalaSedanMCS", "Base.85chevyImpalaSedanMPD", "Base.85chevyImpalaSedanPD", "Base.85chevyImpalaSedanPDu",
        "Base.85chevyImpalaSedanPrison", "Base.85chevyImpalaSedanRanger", "Base.85chevyImpalaSedanTaxi", "Base.85chevyImpalaSedanWPPD",
        "Base.85oldsmobileDelta88Coupe", "Base.85oldsmobileDelta88Sedan", "Base.85pontiacParisienneSedan", "Base.89volvo244sedan",
        "Base.90bmwE30cabrio", "Base.90bmwE30sedan2", "Base.90bmwE30sedan4", "Base.90bmwE30touring",
        "Base.91fordLTD", "Base.91fordLTDksp", "Base.91fordLTDksp2", "Base.91fordLTDpd",
        "Base.91fordLTDranger", "Base.91fordLTDtaxi", "Base.91fordLTDunmarked", "Base.92fordCV",
        "Base.92fordCVPI", "Base.92fordCVPI2", "Base.92fordCVPI2ksp", "Base.92fordCVPI2kspst",
        "Base.92fordCVPI2so", "Base.92fordCVPI2sup", "Base.92fordCVPIfd", "Base.92fordCVPIpdu",
        "Base.92fordCVPItaxi", "Base.92fordCVPIunmarked", "Base.93fordTaurus", "Base.99fordCVPI",
        "Base.99fordCVPIunmarked"
    },

    Wagon = {
        "Base.70fordEscortWagon", "Base.85buickLeSabreWagon", "Base.85buickLeSabreWagon2", "Base.85chevyCapriceWagon",
        "Base.85chevyCapriceWagon2", "Base.85oldsmobileDelta88Wagon", "Base.85oldsmobileDelta88Wagon2", "Base.85pontiacParisienneWagon",
        "Base.85pontiacParisienneWagon2", "Base.86fordE150mesmerWagon", "Base.89volvo245wagon", "Base.91fordLTDwagon",
        "Base.93fordTaurusWagon", "Base.98stagea260RS", "Base.98stagea260RSlhd"
    },

    Luxury = {
        "Base.84buickElectraCoupe", "Base.84buickElectraSedan", "Base.84cadillacDeVilleCoupe", "Base.84cadillacDeVilleSedan"
    },

    Sport = {
        "Base.65banshee400", "Base.65bansheeSprint", "Base.65bansheeXP", "Base.66pontiacGTO",
        "Base.66pontiacGTOconv", "Base.66pontiacLeMans", "Base.66pontiacLeMansConv", "Base.67gt500",
        "Base.67gt500e", "Base.68firebird350", "Base.68firebird400", "Base.68firebirdRamAir",
        "Base.68firebirdRamAirCustom", "Base.69camaroRS", "Base.69camaroSS", "Base.69charger440",
        "Base.69charger500", "Base.69chargerDaytona", "Base.69chargerDemon", "Base.69chargerRT", "Base.70barracuda",
        "Base.70barracudaAAR", "Base.70cuda", "Base.70dodgeBG", "Base.70dodgeOP",
        "Base.70dodgePD", "Base.70dodgeRT", "Base.70dodgeTA", "Base.70roadRunner",
        "Base.73fordFalconPS", "Base.73fordFalconPSlhd", "Base.73fordFalconXBGT", "Base.73fordFalconXBGTlhd",
        "Base.75grandPrixHurst", "Base.75grandPrixLJ", "Base.75grandPrixSJ", "Base.77firebird",
        "Base.77firebirdES", "Base.77firebirdFR", "Base.77firebirdTA", "Base.78lamboCountachLP400",
        "Base.78lamboCountachLP400S", "Base.78lamboCountachLP400Scb", "Base.79camaro", "Base.79camaroGhost",
        "Base.79camaroRS", "Base.79camaroZ28", "Base.81deloreanDMC12", "Base.81deloreanDMC12BTTF",
        "Base.82firebird", "Base.82firebirdKARR", "Base.82firebirdKITT", "Base.82firebirdSE",
        "Base.82firebirdTA", "Base.82porsche911rwb", "Base.82porsche911sc", "Base.82porsche911targa",
        "Base.82porsche911turbo", "Base.84corvetteC4", "Base.87buickRegalGNX", "Base.87buickRegalTurboT",
        "Base.87buickRegalTurboTfbi", "Base.89volvo242turbo", "Base.92nissanGTR", "Base.92nissanGTRlhd",
        "Base.93corvetteC4", "Base.93fordTaurusSHO", "Base.93mustangGT", "Base.93mustangSSP",
        "Base.93mustangSSPksp", "Base.93mustangSSPksp2", "Base.93mustangSSPkspCol", "Base.93mustangSSPpd",
        "Base.93mustangSSPpd2", "Base.93mustangSSPunmarked", "Base.93mustangSVTcobraR"
    },

    Offroad = {
        "Base.84mercLWB2", "Base.84mercLWB4", "Base.84mercLWB4M", "Base.84mercSWB",
        "Base.89defender110", "Base.89defender110utility", "Base.89defender130", "Base.89defender90",
        "Base.89defender90utility", "Base.89defenderWolf", "Base.89fordBronco", "Base.89fordBroncoPD",
        "Base.89fordBroncoRanger", "Base.92jeepYJjp", "Base.92jeepYJranger", "Base.92jeepYJs",
        "Base.92jeepYJse"
    },

    Pickup = {
        "Base.49powerWagon", "Base.49powerWagonMP", "Base.49powerWagonPA", "Base.49powerWagonPD",
        "Base.76chevyC30CCwrecker", "Base.76chevyC30SCwrecker", "Base.76chevyK10", "Base.76chevyK10fd",
        "Base.76chevyK10spirit", "Base.76chevyK20", "Base.76chevyK20BigRed", "Base.76chevyK20fd",
        "Base.76chevyK20utility", "Base.76chevyK30CC", "Base.76chevyK30CCdually", "Base.76chevyK30CCduallyS",
        "Base.76chevyK30CCfd", "Base.76chevyK30CCutility", "Base.76chevyK30CCwrecker", "Base.76chevyK30SCdually",
        "Base.76chevyK30SCwrecker", "Base.82jeepJ10", "Base.82jeepJ10pd", "Base.82jeepJ10ranger",
        "Base.82jeepJ10t", "Base.88chevyS10", "Base.88toyotaHiluxSC", "Base.88toyotaHiluxXC",
        "Base.88toyotaHiluxXCS", "Base.91fordRangerPD", "Base.91fordRangerRanger", "Base.91fordRangerSC",
        "Base.91fordRangerSClong", "Base.91fordRangerXC", "Base.91fordRangerXClong", "Base.93chevySilveradoAirport",
        "Base.93chevySilveradoCC", "Base.93chevySilveradoCCdually", "Base.93chevySilveradoCClong", "Base.93chevySilveradoCClongfd",
        "Base.93chevySilveradoK3500flatbed", "Base.93chevySilveradoK3500lvLandscaping", "Base.93chevySilveradoK3500mechanic", "Base.93chevySilveradoK3500wrecker",
        "Base.93chevySilveradoMcCoyWoodworking", "Base.93chevySilveradoPennSham", "Base.93chevySilveradoPoliceBCS", "Base.93chevySilveradoPoliceMCS",
        "Base.93chevySilveradoRiversideFab", "Base.93chevySilveradoSC", "Base.93chevySilveradoSCdually", "Base.93chevySilveradoSClong",
        "Base.93chevySilveradoSClongFossoil", "Base.93chevySilveradoStoneworksMasonry", "Base.93chevySilveradoUncloggers", "Base.93chevySilveradoVoltMojo",
        "Base.93chevySilveradoWpCarpentry", "Base.93chevySilveradoXC", "Base.93chevySilveradoXCdually", "Base.93chevySilveradoXClong",
        "Base.93chevySilveradoXClongMcCoy", "Base.93chevySilveradoXClongRanger", "Base.93fordF150", "Base.93fordF150S",
        "Base.93fordF250", "Base.93fordF350", "Base.93fordF350dually", "Base.93fordF350fd",
        "Base.93fordF350pd", "Base.93fordF350so", "Base.93fordF350utility", "Base.93fordF350utilityDpw",
        "Base.93fordF350utilityFd"
    },

    SUV = {
        "Base.04vwTouran", "Base.84jeepXJ2", "Base.84jeepXJ4", "Base.84jeepXJksp",
        "Base.84jeepXJpd", "Base.84jeepXJranger", "Base.86chevyK5blazer", "Base.86chevyK5ksp",
        "Base.86chevyK5pd", "Base.86chevyM1008", "Base.86chevyM1009", "Base.86chevyM1009mp",
        "Base.86chevyM1010", "Base.86chevyM1028", "Base.86chevyM1031", "Base.87chevySuburban",
        "Base.87chevySuburbanCUCV", "Base.87chevySuburbanOP", "Base.87fordF700swat", "Base.89trooper",
        "Base.89trooperOP", "Base.89trooperRS", "Base.90fordF350SWAT", "Base.91range",
        "Base.91range2", "Base.92amgeneralM998", "Base.92amgeneralM998Burnt", "Base.93chevySuburban",
        "Base.93chevySuburbanAirportSec", "Base.93chevySuburbanDually", "Base.93chevySuburbanPoliceBCS", "Base.93chevySuburbanPoliceCLPD",
        "Base.93chevySuburbanPoliceLCPD", "Base.93chevySuburbanPoliceMCS", "Base.93chevySuburbanPoliceMPD", "Base.93chevySuburbanPoliceWPPD",
        "Base.93chevySuburbanPrison", "Base.93chevySuburbanfbi", "Base.93chevySuburbanfd", "Base.93chevySuburbanksp",
        "Base.93chevySuburbanpd", "Base.93chevySuburbanpdu"
    },

    Van = {
        "Base.59ambulance", "Base.63Type2Van", "Base.63Type2VanApocalypse", "Base.63Type2VanHippie",
        "Base.63Type2VanMilitary", "Base.86fordE150", "Base.86fordE150LBMWradio", "Base.86fordE150LVairportShuttle",
        "Base.86fordE150McCoyWoodworking", "Base.86fordE150beckmansBuilding", "Base.86fordE150blacksmith", "Base.86fordE150brewster",
        "Base.86fordE150brushAndClay", "Base.86fordE150bugWipers", "Base.86fordE150ccconstruction", "Base.86fordE150creatureCruiser",
        "Base.86fordE150deerValley", "Base.86fordE150dnd", "Base.86fordE150fossoil", "Base.86fordE150greenes",
        "Base.86fordE150heritageTailors", "Base.86fordE150jones", "Base.86fordE150kerrHomes", "Base.86fordE150knobCreek",
        "Base.86fordE150knoxDistilery", "Base.86fordE150knoxTelecom", "Base.86fordE150korshunovs", "Base.86fordE150ksp",
        "Base.86fordE150kyTransit", "Base.86fordE150leatherwork", "Base.86fordE150lectromax", "Base.86fordE150locksmith",
        "Base.86fordE150long", "Base.86fordE150longW", "Base.86fordE150lvLandscaping", "Base.86fordE150massGenfac",
        "Base.86fordE150mccoy", "Base.86fordE150med", "Base.86fordE150meltingPointMetal", "Base.86fordE150metalheads",
        "Base.86fordE150michelesWoodshop", "Base.86fordE150mm", "Base.86fordE150mobileMechanics", "Base.86fordE150mooresMechanics",
        "Base.86fordE150oVoFarms", "Base.86fordE150oldMillWaterCompany", "Base.86fordE150pd", "Base.86fordE150pennSham",
        "Base.86fordE150perfick", "Base.86fordE150plattAutoRepair", "Base.86fordE150pluggedInElectrics", "Base.86fordE150postal",
        "Base.86fordE150quantumVessel", "Base.86fordE150riversideFab", "Base.86fordE150rosewoodWorking", "Base.86fordE150schwab",
        "Base.86fordE150slide", "Base.86fordE150slideSpiffo", "Base.86fordE150so", "Base.86fordE150stoneworksMasonry",
        "Base.86fordE150tasteTheBrew", "Base.86fordE150theGardenGods", "Base.86fordE150theLadyDelighter", "Base.86fordE150treyBaines",
        "Base.86fordE150uncloggers", "Base.86fordE150valkyriesSpear", "Base.86fordE150voltMojo", "Base.86fordE150wpCarpentry",
        "Base.86fordE150zenith", "Base.89dodgeCaravan", "Base.89dodgeCaravanLE", "Base.89dodgeCaravanNomad",
        "Base.90fordF350ambulance", "Base.97bushAmbulance", "Base.ECTO1", "Base.ECTO1Burnt"
    },

    StepVan = {
        "Base.85chevyStepVan", "Base.85chevyStepVanBlacksmith", "Base.85chevyStepVanButchers", "Base.85chevyStepVanCitrusWave",
        "Base.85chevyStepVanDelirosPlonkies", "Base.85chevyStepVanFlorist", "Base.85chevyStepVanGenuine", "Base.85chevyStepVanHerald",
        "Base.85chevyStepVanJorgensen", "Base.85chevyStepVanLibrary", "Base.85chevyStepVanLvAirportCatering", "Base.85chevyStepVanLvMotorshop",
        "Base.85chevyStepVanMarineBites", "Base.85chevyStepVanMasonry", "Base.85chevyStepVanMrHuangsLaundry", "Base.85chevyStepVanPostal",
        "Base.85chevyStepVanPropane", "Base.85chevyStepVanRandys", "Base.85chevyStepVanSWAT", "Base.85chevyStepVanScarletOak",
        "Base.85chevyStepVanSeHospitality", "Base.85chevyStepVanSePaintingServices", "Base.85chevyStepVanSmartCut", "Base.85chevyStepVanSunBallz",
        "Base.85chevyStepVanTheCompleteRepair", "Base.85chevyStepVanTimelessGlass", "Base.85chevyStepVanUsLogistics", "Base.85chevyStepVanZippeeMarket"
    },

    CommercialVan = {
        "Base.86oshkoshFRTR55", "Base.86oshkoshKYFD", "Base.86oshkoshP19ABurnt", "Base.86oshkoshUSMC",
        "Base.87fordB700military", "Base.87fordB700prison", "Base.87fordB700school", "Base.87fordF700bank",
        "Base.87fordF700box", "Base.90pierceArrow", "Base.93fordElgin", "Base.93fordElginSpec"
    },

    HeavyTruck = {
        "Base.78amgeneralM35A2", "Base.78amgeneralM35A2Burnt", "Base.78amgeneralM49A2C", "Base.78amgeneralM50A3",
        "Base.78amgeneralM62", "Base.80manKat1"
    },

    MilitaryAPC = {
        "Base.67commando", "Base.67commandoBurnt", "Base.67commandoPolice", "Base.67commandoT50",
        "Base.97bushmaster", "Base.cobbM540", "Base.lockMartM577"
    },

    TrailerCargo = {
        "Base.Trailer54FlyingCloud22", "Base.Trailer61Bambi16", "Base.Trailer87Scamp13", "Base.Trailer87Scamp16",
        "Base.Trailer89defender", "Base.TrailerKI5cargoMedium", "Base.TrailerKI5cargoSmall", "Base.TrailerKI5utilityMedium",
        "Base.TrailerKI5utilitySmall", "Base.TrailerM101A2cargo", "Base.TrailerM101A3cargo"
    },

    TrailerHeavy = {
        "Base.TrailerKI5cargoLarge", "Base.TrailerKI5livestock", "Base.TrailerKI5utilityLarge", "Base.TrailerM1082",
        "Base.TrailerM1082tarp", "Base.TrailerM1095", "Base.TrailerM1095tarp", "Base.isoContainer2",
        "Base.isoContainer3tanker", "Base.isoContainer4", "Base.isoContainer5"
    },

}


