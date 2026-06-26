-- Per vehicle-class sandbox bias helpers (compact / standard / sport / heavy).
-- Used by MP and SP tune/handling; option names must match sandbox-options.txt.
IK_ClassBias = IK_ClassBias or {}

local B = IK_ClassBias

local CLASS_CAP = {
    compact = "Compact",
    standard = "Standard",
    sport = "Sport",
    heavy = "Heavy",
}

local CLASS_ORDER = { "compact", "standard", "sport", "heavy" }

B.SIGNATURE_SUFFIXES = {
    "PowerBias",
    "AccelBias",
    "BrakeBias",
    "GripBias",
    "MassBias",
    "SteeringBias",
    "RollBias",
    "SuspensionBias",
}

function B.normalizeClass(className)
    if className == "sport" or className == "standard" or className == "compact" or className == "heavy" then
        return className
    end
    return "standard"
end

function B.classForProfile(profile)
    if not profile then
        return "standard"
    end
    return B.normalizeClass(profile.class)
end

function B.bias(core, cls, suffix)
    if not core or not suffix then
        return 1.0
    end
    cls = B.normalizeClass(cls)
    local cap = CLASS_CAP[cls] or "Standard"
    return core.numberOption(cap .. suffix, 1.0, 0.50, 2.0)
end

function B.biasForProfile(core, profile, suffix)
    return B.bias(core, B.classForProfile(profile), suffix)
end

function B.appendSignatureParts(core, parts)
    if not core or type(parts) ~= "table" then
        return
    end
    for i = 1, #CLASS_ORDER do
        local cls = CLASS_ORDER[i]
        for j = 1, #B.SIGNATURE_SUFFIXES do
            parts[#parts + 1] = core.formatNumber(B.bias(core, cls, B.SIGNATURE_SUFFIXES[j]))
        end
    end
    if core.brakeCreepMult then
        parts[#parts + 1] = core.formatNumber(core.brakeCreepMult())
    end
end

return B


