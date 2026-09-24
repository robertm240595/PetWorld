local SkinConfig = {}

SkinConfig.DropRates = {
    Common = 0.05,
    Rare = 0.03,
    Epic = 0.02,
    Legendary = 0.01,
    Mythic = 0.001,
    Ancient = 0.0001,
}

SkinConfig.DropOrder = {
    "Ancient",
    "Mythic",
    "Legendary",
    "Epic",
    "Rare",
    "Common",
}

SkinConfig.DisplayOrder = {
    "Common",
    "Rare",
    "Epic",
    "Legendary",
    "Mythic",
    "Ancient",
}

SkinConfig.RarityColors = {
    Common = Color3.fromRGB(176, 190, 164),
    Rare = Color3.fromRGB(93, 173, 230),
    Epic = Color3.fromRGB(181, 104, 232),
    Legendary = Color3.fromRGB(245, 183, 72),
    Mythic = Color3.fromRGB(237, 91, 201),
    Ancient = Color3.fromRGB(255, 220, 117),
}

SkinConfig.Skins = {
    MeadowTwine = {
        Name = "Meadow Twine",
        Rarity = "Common",
        PrimaryColor = Color3.fromRGB(92, 71, 45),
        AccentColor = Color3.fromRGB(91, 146, 76),
        RopeColor = Color3.fromRGB(176, 156, 105),
        Material = "Fabric",
    },
    EmberStitch = {
        Name = "Ember Stitch",
        Rarity = "Common",
        PrimaryColor = Color3.fromRGB(61, 55, 52),
        AccentColor = Color3.fromRGB(223, 115, 49),
        RopeColor = Color3.fromRGB(171, 78, 43),
        Material = "Fabric",
    },

    FrostbiteCord = {
        Name = "Frostbite Cord",
        Rarity = "Rare",
        PrimaryColor = Color3.fromRGB(67, 92, 122),
        AccentColor = Color3.fromRGB(142, 226, 247),
        RopeColor = Color3.fromRGB(197, 239, 250),
        Material = "Ice",
    },
    VerdantRune = {
        Name = "Verdant Rune",
        Rarity = "Rare",
        PrimaryColor = Color3.fromRGB(39, 92, 65),
        AccentColor = Color3.fromRGB(116, 224, 139),
        RopeColor = Color3.fromRGB(80, 170, 104),
        Material = "SmoothPlastic",
    },
    ArcanePulse = {
        Name = "Arcane Pulse",
        Rarity = "Epic",
        PrimaryColor = Color3.fromRGB(75, 49, 123),
        AccentColor = Color3.fromRGB(177, 112, 255),
        RopeColor = Color3.fromRGB(115, 211, 255),
        Material = "Neon",
        Glow = 0.28,
    },

    CrimsonComet = {
        Name = "Crimson Comet",
        Rarity = "Epic",
        PrimaryColor = Color3.fromRGB(111, 35, 42),
        AccentColor = Color3.fromRGB(244, 137, 67),
        RopeColor = Color3.fromRGB(225, 62, 67),
        Material = "Metal",
        Glow = 0.20,
    },
    SolarFlare = {
        Name = "Solar Flare",
        Rarity = "Legendary",
        PrimaryColor = Color3.fromRGB(135, 82, 30),
        AccentColor = Color3.fromRGB(255, 205, 78),
        RopeColor = Color3.fromRGB(255, 130, 54),
        Material = "Neon",
        Glow = 0.38,
    },
    StormCrown = {
        Name = "Storm Crown",
        Rarity = "Legendary",
        PrimaryColor = Color3.fromRGB(44, 60, 91),
        AccentColor = Color3.fromRGB(122, 218, 255),
        RopeColor = Color3.fromRGB(203, 238, 255),
        Material = "Metal",
        Glow = 0.34,
    },

    VoidBloom = {
        Name = "Void Bloom",
        Rarity = "Mythic",
        PrimaryColor = Color3.fromRGB(47, 31, 73),
        AccentColor = Color3.fromRGB(240, 88, 211),
        RopeColor = Color3.fromRGB(141, 82, 238),
        Material = "Neon",
        Glow = 0.48,
    },
    CelestialTide = {
        Name = "Celestial Tide",
        Rarity = "Mythic",
        PrimaryColor = Color3.fromRGB(32, 57, 91),
        AccentColor = Color3.fromRGB(104, 237, 223),
        RopeColor = Color3.fromRGB(155, 176, 255),
        Material = "Neon",
        Glow = 0.48,
    },
    WorldrootGold = {
        Name = "Worldroot Gold",
        Rarity = "Ancient",
        PrimaryColor = Color3.fromRGB(91, 68, 38),
        AccentColor = Color3.fromRGB(233, 195, 81),
        RopeColor = Color3.fromRGB(98, 205, 137),
        Material = "Wood",
        Glow = 0.58,
    },

    FirstlightRelic = {
        Name = "Firstlight Relic",
        Rarity = "Ancient",
        PrimaryColor = Color3.fromRGB(220, 210, 177),
        AccentColor = Color3.fromRGB(255, 225, 122),
        RopeColor = Color3.fromRGB(205, 244, 255),
        Material = "Neon",
        Glow = 0.62,
    },
}

SkinConfig.Order = {
    "MeadowTwine", "EmberStitch",
    "FrostbiteCord", "VerdantRune",
    "ArcanePulse", "CrimsonComet",
    "SolarFlare", "StormCrown",
    "VoidBloom", "CelestialTide",
    "WorldrootGold", "FirstlightRelic",
}

SkinConfig.ByRarity = {}
for _, rarity in ipairs(SkinConfig.DisplayOrder) do
    SkinConfig.ByRarity[rarity] = {}
end

for _, skinId in ipairs(SkinConfig.Order) do
    local skin = SkinConfig.Skins[skinId]
    if skin and SkinConfig.ByRarity[skin.Rarity] then
        table.insert(SkinConfig.ByRarity[skin.Rarity], skinId)
    end
end

function SkinConfig.Get(skinId)
    return type(skinId) == "string" and SkinConfig.Skins[skinId] or nil
end

return SkinConfig
