local Config = {}

Config.GameName = "Wilderness Pets"

Config.StartCoins = 500
Config.StartGems = 0

Config.MaxPets = 60
Config.MaxMounts = 40
Config.MaxPetNameLength = 18
Config.MaxInventory = 25
Config.Backpacks = {
    ["Starter Bag"] = {Capacity = 25, Coins = 0, Gems = 0},
    ["Leather Satchel"] = {Capacity = 30, Coins = 0, Gems = 0, QuestReward = true},
    ["Trail Pack"] = {Capacity = 40, Coins = 15000, Gems = 0},
    ["Ranger Pack"] = {Capacity = 50, Coins = 50000, Gems = 0},
    ["Expedition Pack"] = {Capacity = 60, Coins = 150000, Gems = 0},
    ["Oversized Backpack"] = {Capacity = 80, Coins = 0, Gems = 1500, Premium = true},
}
Config.BackpackOrder = {
    "Trail Pack",
    "Ranger Pack",
    "Expedition Pack",
    "Oversized Backpack",
}
Config.BeastTraderSellMultiplier = 1.10
Config.WildKillCoinRatio = 0.15
Config.PetSellLevelBonusPerLevel = 0.025
Config.PetSellLevelBonusCap = 1.50
Config.BeastTraderBuybackMultiplier = 1.25
Config.LassoBuybackMultiplier = 1.0
Config.AttackCommandRange = 50
Config.LassoRange = 42
Config.HealingBaseSeconds = 30

Config.Imprinting = {
    Min = 20,
    Max = 100,
    CurveExponent = 2.25,
    LuckRolls = 3
}

Config.Combat = {
    WildAttackInterval = 1.05,
    WildDamageDefenceScale = 0.45
}

-- First rename is free. Further renames spend gems; gem packs can later be sold for Robux.
Config.PetRenameGemCost = 50

Config.CaptureMinigame = {
    RoundDurationSeconds = 4.5,
    ClickClockTolerance = 0.65,
    LassoWidthBonusPerStrength = 0.0007,
    LassoSpeedReductionPerStrength = 0.0028,
    MinSpeedMultiplier = 0.62,
    MinGreenWidth = 0.045,
    MaxGreenWidth = 0.32,
    Rarities = {
        Common = {GreenWidth = 0.25, Speed = 0.80, Hits = 3},
        Uncommon = {GreenWidth = 0.20, Speed = 0.90, Hits = 4},
        Rare = {GreenWidth = 0.16, Speed = 1.02, Hits = 5},
        Epic = {GreenWidth = 0.13, Speed = 1.15, Hits = 6},
        Legendary = {GreenWidth = 0.105, Speed = 1.28, Hits = 7},
        Mythic = {GreenWidth = 0.08, Speed = 1.42, Hits = 8},
        Limited = {GreenWidth = 0.065, Speed = 1.55, Hits = 9},
        Ancient = {GreenWidth = 0.05, Speed = 1.68, Hits = 10}
    }
}

Config.PlotCount = 12
Config.PlotSize = 108
Config.PlotSpacing = 285

Config.WildMonsterCount = 160
Config.WildSpawn = {
    MinRadius = 175,
    MaxRadius = 640,
    FallbackHalfExtent = 640,
    BarrierInset = 45,
    BoundaryMargin = 22,
    Attempts = 150,
    RoamMinDistance = 60,
    RoamMaxDistance = 165
}

Config.Rarities = {
    Common = {
        Rank = 1,
        CaptureDifficulty = 18,
        SellMultiplier = 1.00,
        Weight = 78
    },

    Uncommon = {
        Rank = 2,
        CaptureDifficulty = 32,
        SellMultiplier = 1.35,
        Weight = 17
    },

    Rare = {
        Rank = 3,
        CaptureDifficulty = 50,
        SellMultiplier = 1.80,
        Weight = 3.8
    },

    Epic = {
        Rank = 4,
        CaptureDifficulty = 68,
        SellMultiplier = 2.50,
        Weight = 0.9
    },

    Legendary = {
        Rank = 5,
        CaptureDifficulty = 82,
        SellMultiplier = 4.00,
        Weight = 0.22
    },

    Mythic = {
        Rank = 6,
        CaptureDifficulty = 98,
        SellMultiplier = 6.00,
        Weight = 0.06
    },

    Limited = {
        Rank = 7,
        CaptureDifficulty = 112,
        SellMultiplier = 8.00,
        Weight = 0.015
    },

    Ancient = {
        Rank = 8,
        CaptureDifficulty = 130,
        SellMultiplier = 12.00,
        Weight = 0.005
    }
}

Config.RarityMinLassoStrength = {
    Common = 0,
    Uncommon = 25,
    Rare = 45,
    Epic = 65,
    Legendary = 80,
    Mythic = 95,
    Limited = 115,
    Ancient = 125
}

Config.Lassos = {
    ["Rough Rope"] = {
        Strength = 15,
        Coins = 0,
        Gems = 0,
        DisplayColor = Color3.fromRGB(117, 82, 52),
        DisplayMaterial = "Fabric"
    },

    ["Hunter's Lasso"] = {
        Strength = 30,
        Coins = 2500,
        Gems = 0,
        DisplayColor = Color3.fromRGB(177, 126, 72),
        DisplayMaterial = "Fabric"
    },

    ["Iron Lasso"] = {
        Strength = 50,
        Coins = 12500,
        Gems = 0,
        DisplayColor = Color3.fromRGB(116, 121, 126),
        DisplayMaterial = "Metal"
    },

    ["Steel Lasso"] = {
        Strength = 70,
        Coins = 50000,
        Gems = 0,
        DisplayColor = Color3.fromRGB(190, 201, 210),
        DisplayMaterial = "Metal"
    },

    ["Mystic Lasso"] = {
        Strength = 100,
        Coins = 150000,
        Gems = 0,
        DisplayColor = Color3.fromRGB(151, 102, 232),
        DisplayMaterial = "Neon"
    },

    ["Ancient Lasso"] = {
        Strength = 135,
        Coins = 0,
        Gems = 1500,
        DisplayColor = Color3.fromRGB(232, 183, 74),
        DisplayMaterial = "Neon"
    }
}

Config.Potions = {
    ["XP Tonic"] = {
        Coins = 1200,
        Type = "XPBoost",
        Percent = 0.25,
        Duration = 900,
        Description = "+25% pet XP from wild-pet kills for 15 minutes."
    },
    ["Vitality Elixir"] = {
        Coins = 1800,
        Type = "TimedStatBoost",
        Stat = "Health",
        Percent = 0.20,
        Duration = 1800,
        Description = "+20% maximum Health for the selected pet for 30 minutes."
    },
    ["Power Elixir"] = {
        Coins = 1800,
        Type = "TimedStatBoost",
        Stat = "Power",
        Percent = 0.20,
        Duration = 1800,
        Description = "+20% Power for the selected pet for 30 minutes."
    },
    ["Defence Elixir"] = {
        Coins = 1800,
        Type = "TimedStatBoost",
        Stat = "Defence",
        Percent = 0.20,
        Duration = 1800,
        Description = "+20% Defence for the selected pet for 30 minutes."
    },
    ["Battle Health Potion"] = {
        Coins = 900,
        Type = "BattleHeal",
        Percent = 0.35,
        Description = "Restores 35% of your equipped pet's current maximum Health during battle."
    },
    ["Instant Revive Potion"] = {
        Coins = 3500,
        Type = "InstantRevive",
        Description = "Instantly revives a dead pet that has been placed in its Barn."
    },
    ["Tranquiliser Potion"] = {
        Coins = 2200,
        Type = "Tranquiliser",
        SpeedMultiplier = 0.50,
        Description = "Halves the lasso minigame speed on your next capture attempt."
    },
    ["Swiftness Potion"] = {
        Coins = 1800,
        Type = "SpeedBoost",
        PlayerMultiplier = 1.25,
        PetMultiplier = 1.25,
        Duration = 900,
        Description = "+25% player and equipped-pet movement speed for 15 minutes."
    },
    ["Luck Potion"] = {
        Coins = 2800,
        Type = "Luck",
        Description = "Improves your imprint roll on your next successful capture."
    }
}

Config.Pets = {}

local function addPet(name, rarity, health, power, defence, sellValue, options)
    options = options or {}
    Config.Pets[name] = {
        Rarity = rarity,
        Health = health,
        Power = power,
        Defence = defence,
        SellValue = sellValue,
        SpawnMode = options.SpawnMode or "Wild",
        TimeOfDay = options.TimeOfDay,
        AnimationSpecies = options.AnimationSpecies or name,
        TemplateSpecies = options.TemplateSpecies,
        Legacy = options.Legacy == true,
        Event = options.Event,
        WorldBoss = options.WorldBoss,
        Visual = options.Visual
    }
end

addPet("Wolf", "Common", 100, 20, 12, 35, {SpawnMode = "Wild", TimeOfDay = "Day", AnimationSpecies = "Wolf", Visual = {Archetype = "Quadruped", Color = Color3.fromRGB(120, 126, 132), Accent = Color3.fromRGB(220, 220, 220), Scale = 1.00, Feature = "mane"}})
addPet("Boar", "Common", 125, 17, 20, 40, {SpawnMode = "Wild", TimeOfDay = "Day", AnimationSpecies = "Boar", Visual = {Archetype = "Quadruped", Color = Color3.fromRGB(102, 72, 52), Accent = Color3.fromRGB(168, 126, 84), Scale = 1.05, Feature = "tusks"}})
addPet("Fox", "Common", 95, 24, 11, 38, {SpawnMode = "Wild", TimeOfDay = "Day", AnimationSpecies = "Fox", Visual = {Archetype = "Quadruped", Color = Color3.fromRGB(201, 104, 48), Accent = Color3.fromRGB(245, 215, 170), Scale = 0.90, Feature = "tail"}})
addPet("Hare", "Common", 82, 22, 9, 34, {SpawnMode = "Wild", TimeOfDay = "Day", AnimationSpecies = "Fox", Visual = {Archetype = "Quadruped", Color = Color3.fromRGB(176, 157, 132), Accent = Color3.fromRGB(235, 224, 205), Scale = 0.75, Feature = "ears"}})
addPet("Hedgehog", "Common", 110, 18, 18, 39, {SpawnMode = "Wild", TimeOfDay = "Day", AnimationSpecies = "Boar", Visual = {Archetype = "Quadruped", Color = Color3.fromRGB(105, 82, 65), Accent = Color3.fromRGB(188, 163, 123), Scale = 0.70, Feature = "spikes"}})
addPet("Moon Bat", "Common", 85, 23, 9, 40, {SpawnMode = "Wild", TimeOfDay = "Night", AnimationSpecies = "MoonBat", TemplateSpecies = "MoonBat", Visual = {Archetype = "Bat", Color = Color3.fromRGB(70, 78, 112), Accent = Color3.fromRGB(151, 164, 235), Scale = 0.80, Feature = "ears"}})
addPet("Raccoon", "Common", 105, 21, 14, 38, {SpawnMode = "Wild", TimeOfDay = "Night", AnimationSpecies = "Fox", Visual = {Archetype = "Quadruped", Color = Color3.fromRGB(93, 97, 102), Accent = Color3.fromRGB(210, 214, 220), Scale = 0.85, Feature = "mask"}})
addPet("Badger", "Common", 120, 19, 19, 41, {SpawnMode = "Wild", TimeOfDay = "Night", AnimationSpecies = "Boar", Visual = {Archetype = "Quadruped", Color = Color3.fromRGB(72, 75, 79), Accent = Color3.fromRGB(228, 228, 220), Scale = 0.90, Feature = "stripe"}})
addPet("Opossum", "Common", 92, 20, 10, 35, {SpawnMode = "Wild", TimeOfDay = "Night", AnimationSpecies = "Fox", Visual = {Archetype = "Quadruped", Color = Color3.fromRGB(146, 138, 132), Accent = Color3.fromRGB(226, 202, 196), Scale = 0.80, Feature = "tail"}})
addPet("Field Mouse", "Common", 78, 18, 8, 32, {SpawnMode = "Wild", TimeOfDay = "Night", AnimationSpecies = "Fox", Visual = {Archetype = "Quadruped", Color = Color3.fromRGB(134, 112, 91), Accent = Color3.fromRGB(219, 184, 165), Scale = 0.62, Feature = "ears"}})
addPet("River Otter", "Uncommon", 130, 29, 18, 58, {SpawnMode = "Wild", TimeOfDay = "Day", AnimationSpecies = "Fox", Visual = {Archetype = "Quadruped", Color = Color3.fromRGB(91, 74, 58), Accent = Color3.fromRGB(167, 131, 96), Scale = 0.90, Feature = "tail"}})
addPet("Red Panda", "Uncommon", 118, 31, 16, 60, {SpawnMode = "Wild", TimeOfDay = "Day", AnimationSpecies = "Fox", Visual = {Archetype = "Quadruped", Color = Color3.fromRGB(181, 78, 51), Accent = Color3.fromRGB(242, 220, 198), Scale = 0.88, Feature = "mask"}})
addPet("Mountain Goat", "Uncommon", 150, 28, 26, 64, {SpawnMode = "Wild", TimeOfDay = "Day", AnimationSpecies = "Boar", Visual = {Archetype = "Quadruped", Color = Color3.fromRGB(190, 185, 169), Accent = Color3.fromRGB(99, 83, 69), Scale = 1.00, Feature = "horns"}})
addPet("Lynx", "Uncommon", 128, 34, 17, 62, {SpawnMode = "Wild", TimeOfDay = "Day", AnimationSpecies = "Wolf", Visual = {Archetype = "Quadruped", Color = Color3.fromRGB(166, 140, 110), Accent = Color3.fromRGB(72, 64, 58), Scale = 0.95, Feature = "ears"}})
addPet("Peacock", "Uncommon", 112, 33, 14, 61, {SpawnMode = "Wild", TimeOfDay = "Day", AnimationSpecies = "Starling", Visual = {Archetype = "Bird", Color = Color3.fromRGB(54, 121, 105), Accent = Color3.fromRGB(83, 171, 231), Scale = 0.95, Feature = "fan"}})
addPet("Barn Owl", "Uncommon", 105, 32, 13, 60, {SpawnMode = "Wild", TimeOfDay = "Night", AnimationSpecies = "Starling", Visual = {Archetype = "Bird", Color = Color3.fromRGB(168, 140, 103), Accent = Color3.fromRGB(234, 223, 194), Scale = 0.90, Feature = "crest"}})
addPet("Porcupine", "Uncommon", 145, 27, 28, 65, {SpawnMode = "Wild", TimeOfDay = "Night", AnimationSpecies = "Boar", Visual = {Archetype = "Quadruped", Color = Color3.fromRGB(96, 80, 64), Accent = Color3.fromRGB(224, 214, 193), Scale = 0.85, Feature = "spikes"}})
addPet("Pangolin", "Uncommon", 155, 25, 30, 66, {SpawnMode = "Wild", TimeOfDay = "Night", AnimationSpecies = "Boar", Visual = {Archetype = "Lizard", Color = Color3.fromRGB(133, 100, 69), Accent = Color3.fromRGB(207, 170, 117), Scale = 0.90, Feature = "plates"}})
addPet("Lantern Gecko", "Uncommon", 108, 35, 12, 63, {SpawnMode = "Wild", TimeOfDay = "Night", AnimationSpecies = "Fox", Visual = {Archetype = "Lizard", Color = Color3.fromRGB(54, 123, 87), Accent = Color3.fromRGB(119, 255, 180), Scale = 0.75, Feature = "glow"}})
addPet("Glow Beetle", "Uncommon", 100, 30, 24, 62, {SpawnMode = "Wild", TimeOfDay = "Night", AnimationSpecies = "MoonBat", Visual = {Archetype = "Beetle", Color = Color3.fromRGB(41, 61, 70), Accent = Color3.fromRGB(114, 255, 199), Scale = 0.68, Feature = "glow"}})
addPet("Bear", "Rare", 220, 45, 32, 100, {SpawnMode = "Wild", TimeOfDay = "Day", AnimationSpecies = "Bear", Visual = {Archetype = "Quadruped", Color = Color3.fromRGB(105, 78, 56), Accent = Color3.fromRGB(174, 137, 99), Scale = 1.20, Feature = "mane"}})
addPet("Thunder Ram", "Rare", 205, 52, 37, 112, {SpawnMode = "Wild", TimeOfDay = "Day", AnimationSpecies = "Boar", Visual = {Archetype = "Quadruped", Color = Color3.fromRGB(112, 118, 129), Accent = Color3.fromRGB(108, 190, 255), Scale = 1.05, Feature = "horns"}})
addPet("Jade Tortoise", "Rare", 245, 39, 44, 108, {SpawnMode = "Wild", TimeOfDay = "Day", AnimationSpecies = "Boar", Visual = {Archetype = "Turtle", Color = Color3.fromRGB(58, 115, 82), Accent = Color3.fromRGB(104, 201, 141), Scale = 1.00, Feature = "shell"}})
addPet("Sunscale Raptor", "Rare", 180, 55, 28, 115, {SpawnMode = "Wild", TimeOfDay = "Day", AnimationSpecies = "Dragon", Visual = {Archetype = "Raptor", Color = Color3.fromRGB(183, 105, 46), Accent = Color3.fromRGB(255, 204, 84), Scale = 1.00, Feature = "crest"}})
addPet("Shadow Stag", "Rare", 200, 49, 29, 120, {SpawnMode = "Wild", TimeOfDay = "Night", AnimationSpecies = "ShadowStag", TemplateSpecies = "ShadowStag", Visual = {Archetype = "Quadruped", Color = Color3.fromRGB(53, 57, 74), Accent = Color3.fromRGB(123, 98, 180), Scale = 1.08, Feature = "antlers"}})
addPet("Crystal Scorpion", "Rare", 175, 54, 36, 118, {SpawnMode = "Wild", TimeOfDay = "Night", AnimationSpecies = "Boar", Visual = {Archetype = "Scorpion", Color = Color3.fromRGB(74, 105, 138), Accent = Color3.fromRGB(139, 221, 255), Scale = 0.95, Feature = "crystal"}})
addPet("Moon Moth", "Rare", 165, 51, 24, 110, {SpawnMode = "Wild", TimeOfDay = "Night", AnimationSpecies = "MoonBat", Visual = {Archetype = "Bird", Color = Color3.fromRGB(88, 76, 116), Accent = Color3.fromRGB(190, 173, 255), Scale = 0.88, Feature = "glow"}})
addPet("Dusk Cobra", "Rare", 190, 53, 30, 116, {SpawnMode = "Wild", TimeOfDay = "Night", AnimationSpecies = "Leviathan", Visual = {Archetype = "Serpent", Color = Color3.fromRGB(65, 58, 78), Accent = Color3.fromRGB(183, 91, 207), Scale = 1.00, Feature = "hood"}})
addPet("Griffin", "Epic", 300, 65, 45, 175, {SpawnMode = "Wild", TimeOfDay = "Day", AnimationSpecies = "Griffin", Visual = {Archetype = "Quadruped", Color = Color3.fromRGB(179, 133, 70), Accent = Color3.fromRGB(245, 221, 151), Scale = 1.18, Feature = "wings"}})
addPet("Kirin", "Epic", 285, 72, 47, 185, {SpawnMode = "Wild", TimeOfDay = "Day", AnimationSpecies = "ShadowStag", Visual = {Archetype = "Quadruped", Color = Color3.fromRGB(224, 211, 176), Accent = Color3.fromRGB(94, 224, 204), Scale = 1.10, Feature = "horns"}})
addPet("Ember Salamander", "Epic", 260, 76, 40, 180, {SpawnMode = "Wild", TimeOfDay = "Day", AnimationSpecies = "Dragon", Visual = {Archetype = "Lizard", Color = Color3.fromRGB(156, 61, 39), Accent = Color3.fromRGB(255, 139, 65), Scale = 1.00, Feature = "glow"}})
addPet("Storm Roc", "Epic", 280, 74, 42, 188, {SpawnMode = "Wild", TimeOfDay = "Day", AnimationSpecies = "Griffin", Visual = {Archetype = "Bird", Color = Color3.fromRGB(83, 101, 121), Accent = Color3.fromRGB(141, 206, 255), Scale = 1.25, Feature = "crest"}})
addPet("Manticore", "Epic", 320, 70, 48, 190, {SpawnMode = "Wild", TimeOfDay = "Night", AnimationSpecies = "Griffin", Visual = {Archetype = "Quadruped", Color = Color3.fromRGB(104, 64, 74), Accent = Color3.fromRGB(222, 111, 125), Scale = 1.15, Feature = "wings"}})
addPet("Basilisk", "Epic", 305, 75, 46, 192, {SpawnMode = "Wild", TimeOfDay = "Night", AnimationSpecies = "Dragon", Visual = {Archetype = "Serpent", Color = Color3.fromRGB(61, 100, 72), Accent = Color3.fromRGB(149, 226, 113), Scale = 1.12, Feature = "crest"}})
addPet("Nightmare Steed", "Epic", 295, 73, 44, 186, {SpawnMode = "Wild", TimeOfDay = "Night", AnimationSpecies = "ShadowStag", Visual = {Archetype = "Quadruped", Color = Color3.fromRGB(45, 45, 55), Accent = Color3.fromRGB(177, 74, 215), Scale = 1.18, Feature = "mane"}})
addPet("Void Weaver", "Epic", 250, 78, 38, 184, {SpawnMode = "Wild", TimeOfDay = "Night", AnimationSpecies = "MoonBat", Visual = {Archetype = "Arachnid", Color = Color3.fromRGB(48, 41, 65), Accent = Color3.fromRGB(140, 91, 221), Scale = 1.00, Feature = "glow"}})
addPet("Phoenix", "Legendary", 430, 108, 58, 300, {SpawnMode = "Wild", TimeOfDay = "Day", AnimationSpecies = "Griffin", Visual = {Archetype = "Bird", Color = Color3.fromRGB(212, 75, 36), Accent = Color3.fromRGB(255, 214, 74), Scale = 1.25, Feature = "flame"}})
addPet("Unicorn", "Legendary", 410, 96, 70, 290, {SpawnMode = "Wild", TimeOfDay = "Day", AnimationSpecies = "ShadowStag", Visual = {Archetype = "Quadruped", Color = Color3.fromRGB(228, 226, 223), Accent = Color3.fromRGB(168, 121, 255), Scale = 1.15, Feature = "horns"}})
addPet("Celestial Lion", "Legendary", 500, 102, 74, 315, {SpawnMode = "Wild", TimeOfDay = "Day", AnimationSpecies = "Bear", Visual = {Archetype = "Quadruped", Color = Color3.fromRGB(192, 151, 66), Accent = Color3.fromRGB(255, 235, 150), Scale = 1.25, Feature = "mane"}})
addPet("Cerberus", "Legendary", 520, 110, 72, 325, {SpawnMode = "Wild", TimeOfDay = "Night", AnimationSpecies = "Wolf", Visual = {Archetype = "Hydra", Color = Color3.fromRGB(58, 49, 60), Accent = Color3.fromRGB(221, 87, 95), Scale = 1.25, Feature = "heads"}})
addPet("Chimera", "Legendary", 470, 114, 68, 320, {SpawnMode = "Wild", TimeOfDay = "Night", AnimationSpecies = "Griffin", Visual = {Archetype = "Quadruped", Color = Color3.fromRGB(89, 67, 62), Accent = Color3.fromRGB(191, 94, 156), Scale = 1.28, Feature = "wings"}})
addPet("Abyss Hydra", "Legendary", 540, 112, 78, 335, {SpawnMode = "Wild", TimeOfDay = "Night", AnimationSpecies = "Dragon", Visual = {Archetype = "Hydra", Color = Color3.fromRGB(42, 72, 82), Accent = Color3.fromRGB(75, 212, 222), Scale = 1.30, Feature = "heads"}})
addPet("Solar Dragon", "Mythic", 820, 155, 105, 520, {SpawnMode = "Wild", TimeOfDay = "Day", AnimationSpecies = "Dragon", Visual = {Archetype = "Quadruped", Color = Color3.fromRGB(191, 77, 41), Accent = Color3.fromRGB(255, 220, 91), Scale = 1.45, Feature = "wings"}})
addPet("Worldroot Colossus", "Mythic", 900, 138, 120, 540, {SpawnMode = "Wild", TimeOfDay = "Day", AnimationSpecies = "AncientTitan", Visual = {Archetype = "Titan", Color = Color3.fromRGB(90, 102, 70), Accent = Color3.fromRGB(133, 214, 107), Scale = 1.55, Feature = "crown"}})
addPet("Leviathan", "Mythic", 800, 145, 100, 500, {SpawnMode = "Wild", TimeOfDay = "Night", AnimationSpecies = "Leviathan", Visual = {Archetype = "Serpent", Color = Color3.fromRGB(41, 91, 115), Accent = Color3.fromRGB(89, 205, 224), Scale = 1.50, Feature = "crest"}})
addPet("Astral Serpent", "Mythic", 760, 165, 92, 530, {SpawnMode = "Wild", TimeOfDay = "Night", AnimationSpecies = "Leviathan", Visual = {Archetype = "Serpent", Color = Color3.fromRGB(67, 55, 110), Accent = Color3.fromRGB(186, 155, 255), Scale = 1.42, Feature = "glow"}})
addPet("Frostbell Reindeer", "Limited", 680, 150, 92, 650, {SpawnMode = "Event", AnimationSpecies = "ShadowStag", Event = "Winter", Visual = {Archetype = "Quadruped", Color = Color3.fromRGB(211, 223, 230), Accent = Color3.fromRGB(112, 209, 255), Scale = 1.20, Feature = "antlers"}})
addPet("Pumpkin Imp", "Limited", 620, 170, 82, 640, {SpawnMode = "Event", AnimationSpecies = "Fox", Event = "Halloween", Visual = {Archetype = "Imp", Color = Color3.fromRGB(116, 59, 38), Accent = Color3.fromRGB(255, 137, 48), Scale = 1.00, Feature = "horns"}})
addPet("Bloom Jackalope", "Limited", 650, 155, 88, 645, {SpawnMode = "Event", AnimationSpecies = "Fox", Event = "Spring", Visual = {Archetype = "Quadruped", Color = Color3.fromRGB(187, 154, 139), Accent = Color3.fromRGB(244, 145, 186), Scale = 0.95, Feature = "antlers"}})
addPet("Starfall Starling", "Limited", 640, 165, 80, 650, {SpawnMode = "Event", AnimationSpecies = "Starling", Event = "Starfall", Visual = {Archetype = "Bird", Color = Color3.fromRGB(76, 87, 143), Accent = Color3.fromRGB(198, 180, 255), Scale = 1.05, Feature = "glow"}})
addPet("Kraken", "Ancient", 1350, 225, 160, 1000, {SpawnMode = "WorldBoss", AnimationSpecies = "Leviathan", WorldBoss = "Kraken", Visual = {Archetype = "Kraken", Color = Color3.fromRGB(46, 78, 98), Accent = Color3.fromRGB(89, 204, 226), Scale = 1.60, Feature = "crown"}})
addPet("Jörmungandr", "Ancient", 1450, 235, 170, 1050, {SpawnMode = "WorldBoss", AnimationSpecies = "Leviathan", WorldBoss = "Jörmungandr", Visual = {Archetype = "Serpent", Color = Color3.fromRGB(55, 84, 68), Accent = Color3.fromRGB(172, 216, 115), Scale = 1.70, Feature = "crown"}})
addPet("Fenrir", "Ancient", 1300, 240, 150, 1025, {SpawnMode = "WorldBoss", AnimationSpecies = "Wolf", WorldBoss = "Fenrir", Visual = {Archetype = "Quadruped", Color = Color3.fromRGB(75, 82, 95), Accent = Color3.fromRGB(175, 204, 255), Scale = 1.55, Feature = "mane"}})
addPet("Gaia Titan", "Ancient", 1500, 210, 180, 1100, {SpawnMode = "WorldBoss", AnimationSpecies = "AncientTitan", WorldBoss = "Gaia Titan", Visual = {Archetype = "Titan", Color = Color3.fromRGB(91, 78, 58), Accent = Color3.fromRGB(137, 203, 112), Scale = 1.75, Feature = "crown"}})

-- Preserve already-owned retired species without allowing them back into normal wild spawning.
addPet("Dragon", "Legendary", 500, 100, 70, 300, {SpawnMode = "Legacy", AnimationSpecies = "Dragon", TemplateSpecies = "Dragon", Legacy = true})
addPet("Starling", "Limited", 650, 160, 80, 650, {SpawnMode = "Legacy", AnimationSpecies = "Starling", TemplateSpecies = "Starling", Legacy = true})
addPet("AncientTitan", "Ancient", 1200, 210, 150, 1000, {SpawnMode = "Legacy", AnimationSpecies = "AncientTitan", TemplateSpecies = "AncientTitan", Legacy = true})
addPet("MoonBat", "Common", 85, 23, 9, 40, {SpawnMode = "Legacy", AnimationSpecies = "MoonBat", TemplateSpecies = "MoonBat", Legacy = true})
addPet("ShadowStag", "Rare", 200, 49, 29, 120, {SpawnMode = "Legacy", AnimationSpecies = "ShadowStag", TemplateSpecies = "ShadowStag", Legacy = true})
addPet("Nightfang", "Common", 110, 22, 12, 39, {SpawnMode = "Legacy", AnimationSpecies = "Wolf", TemplateSpecies = "Nightfang", Legacy = true})
addPet("Dusktail", "Uncommon", 121, 30, 15, 66, {SpawnMode = "Legacy", AnimationSpecies = "Fox", TemplateSpecies = "Dusktail", Legacy = true})
addPet("EclipseGriffin", "Epic", 330, 70, 45, 192, {SpawnMode = "Legacy", AnimationSpecies = "Griffin", TemplateSpecies = "EclipseGriffin", Legacy = true})
addPet("VoidDragon", "Legendary", 550, 108, 70, 330, {SpawnMode = "Legacy", AnimationSpecies = "Dragon", TemplateSpecies = "VoidDragon", Legacy = true})
addPet("AbyssLeviathan", "Mythic", 880, 156, 100, 550, {SpawnMode = "Legacy", AnimationSpecies = "Leviathan", TemplateSpecies = "AbyssLeviathan", Legacy = true})
addPet("AstralStarling", "Limited", 715, 173, 80, 715, {SpawnMode = "Legacy", AnimationSpecies = "Starling", TemplateSpecies = "AstralStarling", Legacy = true})
addPet("ObsidianTitan", "Ancient", 1320, 226, 150, 1100, {SpawnMode = "Legacy", AnimationSpecies = "AncientTitan", TemplateSpecies = "ObsidianTitan", Legacy = true})

Config.MountMinLassoStrength = 25

-- Mount rarity rolls are absolute per wilderness slot refresh. Common mounts
-- are deliberately around the same order of rarity as a Legendary wild pet;
-- every higher tier becomes sharply harder to see.
Config.MountWildSpawnChances = {
    Common = 0.0022,
    Uncommon = 0.0006,
    Rare = 0.00015,
    Epic = 0.00004,
    Legendary = 0.00001,
    Mythic = 0.0000025,
    Limited = 0,
    Ancient = 0,
}

Config.Mounts = {}

local function addMount(name, rarity, speed, options)
    options = options or {}
    Config.Mounts[name] = {
        Rarity = rarity,
        Speed = speed,
        SpawnMode = options.SpawnMode or "Wild",
        TimeOfDay = options.TimeOfDay,
        AnimationSpecies = options.AnimationSpecies or name,
        TemplateSpecies = options.TemplateSpecies,
        Event = options.Event,
        WorldBoss = options.WorldBoss,
        Visual = options.Visual,
    }
end

addMount("Horse", "Common", 24, {SpawnMode="Wild", TimeOfDay="Day", AnimationSpecies="ShadowStag", Visual={Archetype="Quadruped", Color=Color3.fromRGB(132,91,58), Accent=Color3.fromRGB(65,45,33), Scale=1.10, Feature="mane"}})
addMount("Mule", "Common", 23, {SpawnMode="Wild", TimeOfDay="Night", AnimationSpecies="ShadowStag", Visual={Archetype="Quadruped", Color=Color3.fromRGB(128,113,93), Accent=Color3.fromRGB(70,60,51), Scale=1.05, Feature="ears"}})

addMount("Zebra", "Uncommon", 25, {SpawnMode="Wild", TimeOfDay="Day", AnimationSpecies="ShadowStag", Visual={Archetype="Quadruped", Color=Color3.fromRGB(223,222,213), Accent=Color3.fromRGB(49,49,51), Scale=1.10, Feature="stripe"}})
addMount("Elk", "Uncommon", 25, {SpawnMode="Wild", TimeOfDay="Night", AnimationSpecies="ShadowStag", Visual={Archetype="Quadruped", Color=Color3.fromRGB(138,99,61), Accent=Color3.fromRGB(219,190,133), Scale=1.15, Feature="antlers"}})

addMount("War Boar", "Rare", 27, {SpawnMode="Wild", TimeOfDay="Day", AnimationSpecies="Boar", Visual={Archetype="Quadruped", Color=Color3.fromRGB(91,65,51), Accent=Color3.fromRGB(184,144,94), Scale=1.25, Feature="tusks"}})
addMount("Dune Camel", "Rare", 27, {SpawnMode="Wild", TimeOfDay="Night", AnimationSpecies="ShadowStag", Visual={Archetype="Quadruped", Color=Color3.fromRGB(194,151,96), Accent=Color3.fromRGB(119,86,52), Scale=1.22, Feature="mane"}})

addMount("Nightmare Courser", "Epic", 29, {SpawnMode="Wild", TimeOfDay="Night", AnimationSpecies="ShadowStag", Visual={Archetype="Quadruped", Color=Color3.fromRGB(48,43,58), Accent=Color3.fromRGB(183,73,220), Scale=1.20, Feature="flame"}})
addMount("Storm Elk", "Epic", 29, {SpawnMode="Wild", TimeOfDay="Day", AnimationSpecies="ShadowStag", Visual={Archetype="Quadruped", Color=Color3.fromRGB(80,95,112), Accent=Color3.fromRGB(119,202,255), Scale=1.22, Feature="antlers"}})

addMount("Silver Unicorn", "Legendary", 31, {SpawnMode="Wild", TimeOfDay="Day", AnimationSpecies="ShadowStag", Visual={Archetype="Quadruped", Color=Color3.fromRGB(220,224,229), Accent=Color3.fromRGB(185,130,255), Scale=1.18, Feature="horns"}})
addMount("Sunmane Lion", "Legendary", 31, {SpawnMode="Wild", TimeOfDay="Night", AnimationSpecies="Bear", Visual={Archetype="Quadruped", Color=Color3.fromRGB(188,129,54), Accent=Color3.fromRGB(255,221,112), Scale=1.23, Feature="mane"}})

addMount("Solar Kirin", "Mythic", 34, {SpawnMode="Wild", TimeOfDay="Day", AnimationSpecies="ShadowStag", Visual={Archetype="Quadruped", Color=Color3.fromRGB(221,190,122), Accent=Color3.fromRGB(255,221,84), Scale=1.24, Feature="crown"}})
addMount("Astral Drake", "Mythic", 34, {SpawnMode="Wild", TimeOfDay="Night", AnimationSpecies="Dragon", Visual={Archetype="Quadruped", Color=Color3.fromRGB(69,62,116), Accent=Color3.fromRGB(177,155,255), Scale=1.28, Feature="wings"}})

addMount("Frostbell Sleighdeer", "Limited", 32, {SpawnMode="Event", Event="Winter", AnimationSpecies="ShadowStag", Visual={Archetype="Quadruped", Color=Color3.fromRGB(212,225,233), Accent=Color3.fromRGB(111,211,255), Scale=1.20, Feature="antlers"}})
addMount("Pumpkin Charger", "Limited", 32, {SpawnMode="Event", Event="Halloween", AnimationSpecies="ShadowStag", Visual={Archetype="Quadruped", Color=Color3.fromRGB(88,55,43), Accent=Color3.fromRGB(255,133,47), Scale=1.20, Feature="flame"}})

addMount("Moonfang Warg", "Ancient", 38, {SpawnMode="WorldBoss", WorldBoss="AncientPool", AnimationSpecies="Wolf", Visual={Archetype="Quadruped", Color=Color3.fromRGB(68,76,91), Accent=Color3.fromRGB(179,207,255), Scale=1.42, Feature="mane"}})
addMount("Worldcoil Drake", "Ancient", 38, {SpawnMode="WorldBoss", WorldBoss="AncientPool", AnimationSpecies="Dragon", Visual={Archetype="Quadruped", Color=Color3.fromRGB(55,86,67), Accent=Color3.fromRGB(185,224,118), Scale=1.45, Feature="wings"}})

Config.MountRosterCounts = {
    Common = 2,
    Uncommon = 2,
    Rare = 2,
    Epic = 2,
    Legendary = 2,
    Mythic = 2,
    Limited = 2,
    Ancient = 2,
}

-- Reserved for the future world-boss combat implementation. The reward
-- service should only create a personal pouch for players who contributed
-- strictly more than 10% of the boss's maximum Health in damage.
Config.WorldBossRewardRules = {
    MinimumDamageFraction = 0.10,
    AncientPetDropChance = 0.0001,
    AncientMountDropChance = 0.0001,
    AncientMountPool = {"Moonfang Warg", "Worldcoil Drake"},
    SuggestedBossMounts = {
        Kraken = "Tidebreaker Manta",
        ["Jörmungandr"] = "Worldcoil Drake",
        Fenrir = "Moonfang Warg",
        ["Gaia Titan"] = "Stoneback Mammoth",
    },
}

Config.RobuxPets = {
    ["Celestial Wolf"] = {
        Species = "Wolf",
        ProductId = 0
    },

    ["Void Dragon"] = {
        Species = "Dragon",
        ProductId = 0
    }
}

Config.WeeklyReward = {
    Coins = 5000,
    Gems = 0
}

Config.CollectionMilestones = {
    {Required = 5, Coins = 500, Gems = 0},
    {Required = 10, Coins = 1500, Gems = 0},
    {Required = 20, Coins = 5000, Gems = 10},
    {Required = 30, Coins = 10000, Gems = 20},
    {Required = 40, Coins = 20000, Gems = 35},
    {Required = 46, Coins = 30000, Gems = 50},
    {Required = 50, Coins = 50000, Gems = 75},
    {Required = 54, Coins = 100000, Gems = 150}
}


-- World cycle and population tuning.
Config.WorldCycle = {DurationSeconds=720, StartHour=9, NightStart=18, NightEnd=6}
Config.Respawn = {MinSeconds=10, MaxSeconds=20, SafePlayerRadius=45, TransitionInterval=4}
Config.PetRosterCounts = {
    Common = {Total = 10, Day = 5, Night = 5},
    Uncommon = {Total = 10, Day = 5, Night = 5},
    Rare = {Total = 8, Day = 4, Night = 4},
    Epic = {Total = 8, Day = 4, Night = 4},
    Legendary = {Total = 6, Day = 3, Night = 3},
    Mythic = {Total = 4, Day = 2, Night = 2},
    Limited = {Total = 4, SpawnMode = "Event"},
    Ancient = {Total = 4, SpawnMode = "WorldBoss"}
}

return Config
