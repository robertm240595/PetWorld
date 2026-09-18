local Config = {}

Config.GameName = "Wilderness Pets"

Config.StartCoins = 500
Config.StartGems = 25

Config.MaxPets = 60
Config.MaxPetNameLength = 18
Config.MaxInventory = 25
Config.BeastTraderSellMultiplier = 1.35
-- First rename is free. Further renames spend gems; gem packs can later be sold for Robux.
Config.PetRenameGemCost = 50

Config.CaptureMinigame = {
    RoundDurationSeconds = 4.5,
    ClickClockTolerance = 0.65,
    LassoWidthBonusPerStrength = 0.001,
    MinGreenWidth = 0.07,
    MaxGreenWidth = 0.40,
    Rarities = {
        Common = {GreenWidth = 0.32, Speed = 0.70, Hits = 3},
        Uncommon = {GreenWidth = 0.28, Speed = 0.76, Hits = 4},
        Rare = {GreenWidth = 0.24, Speed = 0.83, Hits = 5},
        Epic = {GreenWidth = 0.20, Speed = 0.91, Hits = 6},
        Legendary = {GreenWidth = 0.16, Speed = 1.00, Hits = 7},
        Mythic = {GreenWidth = 0.13, Speed = 1.08, Hits = 8},
        Limited = {GreenWidth = 0.11, Speed = 1.14, Hits = 9},
        Ancient = {GreenWidth = 0.09, Speed = 1.22, Hits = 10}
    }
}

Config.PlotCount = 12
Config.PlotSize = 108
Config.PlotSpacing = 285

Config.WildMonsterCount = 36

Config.Rarities = {
    Common = {
        Rank = 1,
        CaptureDifficulty = 10,
        SellMultiplier = 1,
        Weight = 55
    },

    Uncommon = {
        Rank = 2,
        CaptureDifficulty = 23,
        SellMultiplier = 2,
        Weight = 25
    },

    Rare = {
        Rank = 3,
        CaptureDifficulty = 40,
        SellMultiplier = 5,
        Weight = 11
    },

    Epic = {
        Rank = 4,
        CaptureDifficulty = 58,
        SellMultiplier = 10,
        Weight = 5
    },

    Legendary = {
        Rank = 5,
        CaptureDifficulty = 74,
        SellMultiplier = 25,
        Weight = 2.5
    },

    Mythic = {
        Rank = 6,
        CaptureDifficulty = 86,
        SellMultiplier = 60,
        Weight = 1
    },

    Limited = {
        Rank = 7,
        CaptureDifficulty = 80,
        SellMultiplier = 75,
        Weight = 0.4
    },

    Ancient = {
        Rank = 8,
        CaptureDifficulty = 96,
        SellMultiplier = 150,
        Weight = 0.1
    }
}

Config.Lassos = {
    ["Rough Rope"] = {
        Strength = 15,
        Coins = 0,
        Gems = 0
    },

    ["Hunter's Lasso"] = {
        Strength = 30,
        Coins = 1000,
        Gems = 0
    },

    ["Iron Lasso"] = {
        Strength = 50,
        Coins = 5000,
        Gems = 0
    },

    ["Steel Lasso"] = {
        Strength = 70,
        Coins = 15000,
        Gems = 0
    },

    ["Mystic Lasso"] = {
        Strength = 90,
        Coins = 50000,
        Gems = 250
    },

    ["Ancient Lasso"] = {
        Strength = 125,
        Coins = 150000,
        Gems = 750
    }
}

Config.Pets = {
    Wolf = {
        Rarity = "Common",
        Health = 100,
        Power = 20,
        Defence = 12,
        SellValue = 50
    },

    Boar = {
        Rarity = "Common",
        Health = 125,
        Power = 17,
        Defence = 20,
        SellValue = 60
    },

    Fox = {
        Rarity = "Uncommon",
        Health = 110,
        Power = 28,
        Defence = 15,
        SellValue = 120
    },

    Bear = {
        Rarity = "Rare",
        Health = 220,
        Power = 45,
        Defence = 32,
        SellValue = 300
    },

    Griffin = {
        Rarity = "Epic",
        Health = 300,
        Power = 65,
        Defence = 45,
        SellValue = 800
    },

    Dragon = {
        Rarity = "Legendary",
        Health = 500,
        Power = 100,
        Defence = 70,
        SellValue = 2200
    },

    Leviathan = {
        Rarity = "Mythic",
        Health = 800,
        Power = 145,
        Defence = 100,
        SellValue = 6500
    },

    Starling = {
        Rarity = "Limited",
        Health = 650,
        Power = 160,
        Defence = 80,
        SellValue = 8000
    },

    AncientTitan = {
        Rarity = "Ancient",
        Health = 1200,
        Power = 210,
        Defence = 150,
        SellValue = 15000
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
    Gems = 250
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
