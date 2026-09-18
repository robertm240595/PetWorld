local Config = {}

Config.GameName = "Wilderness Pets"

Config.StartCoins = 500
Config.StartGems = 0

Config.MaxPets = 60
Config.MaxPetNameLength = 18
Config.MaxInventory = 25
Config.BeastTraderSellMultiplier = 1.10
Config.WildKillCoinRatio = 0.15
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

Config.WildMonsterCount = 64
Config.WildSpawn = {
    MinRadius = 190,
    MaxRadius = 640,
    Attempts = 90,
    RoamMinDistance = 45,
    RoamMaxDistance = 120
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

Config.Pets = {
    Wolf = {
        Rarity = "Common",
        Health = 100,
        Power = 20,
        Defence = 12,
        SellValue = 35
    },

    Boar = {
        Rarity = "Common",
        Health = 125,
        Power = 17,
        Defence = 20,
        SellValue = 40
    },

    Fox = {
        Rarity = "Uncommon",
        Health = 110,
        Power = 28,
        Defence = 15,
        SellValue = 60
    },

    Bear = {
        Rarity = "Rare",
        Health = 220,
        Power = 45,
        Defence = 32,
        SellValue = 100
    },

    Griffin = {
        Rarity = "Epic",
        Health = 300,
        Power = 65,
        Defence = 45,
        SellValue = 175
    },

    Dragon = {
        Rarity = "Legendary",
        Health = 500,
        Power = 100,
        Defence = 70,
        SellValue = 300
    },

    Leviathan = {
        Rarity = "Mythic",
        Health = 800,
        Power = 145,
        Defence = 100,
        SellValue = 500
    },

    Starling = {
        Rarity = "Limited",
        Health = 650,
        Power = 160,
        Defence = 80,
        SellValue = 650
    },

    AncientTitan = {
        Rarity = "Ancient",
        Health = 1200,
        Power = 210,
        Defence = 150,
        SellValue = 1000
    }
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


-- World cycle and population tuning.
Config.WorldCycle = {DurationSeconds=720, StartHour=9, NightStart=18, NightEnd=6}
Config.Respawn = {MinSeconds=10, MaxSeconds=20, SafePlayerRadius=45, TransitionInterval=4}
Config.NightVariants = {
 Nightfang={Base="Wolf",Rarity="Common",Color=Color3.fromRGB(91,104,158)},
 Dusktail={Base="Fox",Rarity="Uncommon",Color=Color3.fromRGB(146,107,185)},
 EclipseGriffin={Base="Griffin",Rarity="Epic",Color=Color3.fromRGB(135,131,188)},
 VoidDragon={Base="Dragon",Rarity="Legendary",Color=Color3.fromRGB(123,92,175)},
 AbyssLeviathan={Base="Leviathan",Rarity="Mythic",Color=Color3.fromRGB(65,146,171)},
 AstralStarling={Base="Starling",Rarity="Limited",Color=Color3.fromRGB(162,144,235)},
 ObsidianTitan={Base="AncientTitan",Rarity="Ancient",Color=Color3.fromRGB(101,110,144)},
}
for name,v in pairs(Config.NightVariants) do
 local original=Config.Pets[v.Base]
 Config.Pets[name]={Rarity=v.Rarity,Health=math.floor(original.Health*1.1),Power=math.floor(original.Power*1.08),Defence=original.Defence,SellValue=math.floor(original.SellValue*1.1),TimeOfDay="Night",AnimationSpecies=v.Base}
end
Config.Pets.MoonBat={Rarity="Common",Health=85,Power=23,Defence=9,SellValue=55,TimeOfDay="Night",AnimationSpecies="MoonBat"}
Config.Pets.ShadowStag={Rarity="Rare",Health=200,Power=49,Defence=29,SellValue=330,TimeOfDay="Night",AnimationSpecies="ShadowStag"}
for _,info in pairs(Config.Pets) do info.TimeOfDay=info.TimeOfDay or "Day" end

return Config
