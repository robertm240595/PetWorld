local EquipmentConfig = {}

EquipmentConfig.MaxEquipment = 100
EquipmentConfig.Slots = {"Harness", "Charm", "Sigil"}
EquipmentConfig.AuraRadius = 25
EquipmentConfig.SelfAuraScale = 0.50

EquipmentConfig.MaxWorldforgeLevel = 5
EquipmentConfig.WorldforgeStatPerLevel = 0.03
EquipmentConfig.SalvageReturn = 0.35
EquipmentConfig.SmithSellReturn = 0.25

EquipmentConfig.TierOrder = {
    "Common",
    "Uncommon",
    "Rare",
    "Epic",
    "Legendary",
    "Mythic",
    "Limited",
}

EquipmentConfig.Tiers = {
    Common = {Rank = 1, Coins = 250, Primary = 5, Secondary = 3},
    Uncommon = {Rank = 2, Coins = 700, Primary = 6, Secondary = 4},
    Rare = {Rank = 3, Coins = 1800, Primary = 7, Secondary = 4},
    Epic = {Rank = 4, Coins = 5000, Primary = 8, Secondary = 5},
    Legendary = {Rank = 5, Coins = 14000, Primary = 10, Secondary = 6},
    Mythic = {Rank = 6, Coins = 35000, Primary = 12, Secondary = 7},
    -- Limited uses the Mythic stat budget but consumes seasonal Limited loot.
    Limited = {Rank = 6, Coins = 45000, Primary = 12, Secondary = 7},
}

EquipmentConfig.Investments = {
    [1] = {
        Id = 1,
        Label = "STANDARD",
        MaterialMultiplier = 1.00,
        CoinMultiplier = 1.00,
        LevelWeights = {65, 30, 5, 0, 0},
    },
    [2] = {
        Id = 2,
        Label = "REINFORCED",
        MaterialMultiplier = 1.50,
        CoinMultiplier = 1.25,
        LevelWeights = {0, 50, 35, 15, 0},
    },
    [3] = {
        Id = 3,
        Label = "HEAVY INVESTMENT",
        MaterialMultiplier = 2.00,
        CoinMultiplier = 1.60,
        LevelWeights = {0, 0, 45, 40, 15},
    },
    [4] = {
        Id = 4,
        Label = "MAXIMUM INVESTMENT",
        MaterialMultiplier = 3.00,
        CoinMultiplier = 2.20,
        LevelWeights = {0, 0, 0, 40, 60},
    },
}

EquipmentConfig.QualityOrder = {
    "Crude",
    "Tempered",
    "Fine",
    "Masterwork",
    "Perfect",
}

EquipmentConfig.Qualities = {
    Crude = {MinScore = 0, MaxScore = 49, MinMultiplier = 0.78, MaxMultiplier = 0.84},
    Tempered = {MinScore = 50, MaxScore = 74, MinMultiplier = 0.85, MaxMultiplier = 0.91},
    Fine = {MinScore = 75, MaxScore = 89, MinMultiplier = 0.92, MaxMultiplier = 0.96},
    Masterwork = {MinScore = 90, MaxScore = 99, MinMultiplier = 0.97, MaxMultiplier = 1.00},
    Perfect = {MinScore = 100, MaxScore = 100, MinMultiplier = 1.07, MaxMultiplier = 1.07},
    Ancient = {MinScore = 100, MaxScore = 100, MinMultiplier = 1.12, MaxMultiplier = 1.18},
}

-- Hard caps apply only to equipment contributions. Temporary abilities may
-- exceed these values.
EquipmentConfig.StatCaps = {
    Power = 0.40,
    Health = 0.50,
    Defence = 0.40,
    AttackHaste = 0.35,
    CooldownReduction = 0.25,
    AbilityDamage = 0.30,
    HealingPotency = 0.30,
    ShieldPotency = 0.30,
    DoTDamage = 0.35,
    Lifesteal = 0.12,
    ReflectStrength = 0.20,
    BossDamage = 0.30,
    BossDamageReduction = 0.20,
    DebuffPotency = 0.20,
    StatusResistance = 0.30,
    AllyPowerAura = 0.05,
    AllyDefenceAura = 0.05,
    AllyHealthAura = 0.05,
    AllyAttackHasteAura = 0.05,
    BuffPotency = 0.20,
}

EquipmentConfig.StatLabels = {
    Power = "Power",
    Health = "Max Health",
    Defence = "Defence",
    AttackHaste = "Attack Haste",
    CooldownReduction = "Cooldown Reduction",
    AbilityDamage = "Ability Damage",
    HealingPotency = "Healing Potency",
    ShieldPotency = "Shield Potency",
    DoTDamage = "Damage-over-Time",
    Lifesteal = "Lifesteal",
    ReflectStrength = "Reflect Strength",
    BossDamage = "Boss Damage",
    BossDamageReduction = "Boss Damage Reduction",
    DebuffPotency = "Debuff Potency",
    StatusResistance = "Status Resistance",
    AllyPowerAura = "Nearby Ally Power",
    AllyDefenceAura = "Nearby Ally Defence",
    AllyHealthAura = "Nearby Ally Health",
    AllyAttackHasteAura = "Nearby Ally Attack Haste",
    BuffPotency = "Active Buff Potency",
}

EquipmentConfig.StatBases = {
    Power = {
        Main = {0.05, 0.07, 0.09, 0.12, 0.15, 0.18},
        Sub = {0.025, 0.035, 0.045, 0.055, 0.070, 0.085},
    },
    Health = {
        Main = {0.08, 0.11, 0.15, 0.19, 0.24, 0.30},
        Sub = {0.04, 0.055, 0.070, 0.090, 0.110, 0.135},
    },
    Defence = {
        Main = {0.05, 0.07, 0.09, 0.12, 0.15, 0.18},
        Sub = {0.025, 0.035, 0.045, 0.055, 0.070, 0.085},
    },
    AttackHaste = {
        Main = {0.04, 0.055, 0.070, 0.085, 0.100, 0.120},
        Sub = {0.020, 0.027, 0.035, 0.043, 0.050, 0.060},
    },
    CooldownReduction = {
        Main = {0.025, 0.035, 0.045, 0.055, 0.065, 0.080},
        Sub = {0.012, 0.018, 0.023, 0.028, 0.033, 0.040},
    },
    AbilityDamage = {
        Main = {0.04, 0.055, 0.070, 0.090, 0.110, 0.140},
        Sub = {0.020, 0.027, 0.035, 0.045, 0.055, 0.070},
    },
    HealingPotency = {
        Main = {0.05, 0.070, 0.090, 0.120, 0.150, 0.180},
        Sub = {0.025, 0.035, 0.045, 0.060, 0.075, 0.090},
    },
    ShieldPotency = {
        Main = {0.05, 0.070, 0.090, 0.120, 0.150, 0.180},
        Sub = {0.025, 0.035, 0.045, 0.060, 0.075, 0.090},
    },
    DoTDamage = {
        Main = {0.05, 0.070, 0.100, 0.130, 0.170, 0.210},
        Sub = {0.025, 0.035, 0.050, 0.065, 0.085, 0.105},
    },
    Lifesteal = {
        Main = {0.015, 0.020, 0.030, 0.040, 0.050, 0.060},
        Sub = {0.008, 0.010, 0.015, 0.020, 0.025, 0.030},
    },
    ReflectStrength = {
        Main = {0.025, 0.035, 0.050, 0.065, 0.080, 0.100},
        Sub = {0.012, 0.018, 0.025, 0.032, 0.040, 0.050},
    },
    BossDamage = {
        Main = {0.04, 0.060, 0.080, 0.100, 0.130, 0.160},
        Sub = {0.020, 0.030, 0.040, 0.050, 0.065, 0.080},
    },
    BossDamageReduction = {
        Main = {0.025, 0.035, 0.050, 0.065, 0.080, 0.100},
        Sub = {0.012, 0.018, 0.025, 0.032, 0.040, 0.050},
    },
    DebuffPotency = {
        Main = {0.030, 0.040, 0.055, 0.070, 0.085, 0.100},
        Sub = {0.015, 0.020, 0.028, 0.035, 0.043, 0.050},
    },
    StatusResistance = {
        Main = {0.04, 0.055, 0.070, 0.090, 0.110, 0.140},
        Sub = {0.020, 0.027, 0.035, 0.045, 0.055, 0.070},
    },
    AllyPowerAura = {
        Main = {0.015, 0.020, 0.025, 0.030, 0.040, 0.050},
        Sub = {0.008, 0.010, 0.013, 0.016, 0.020, 0.025},
    },
    AllyDefenceAura = {
        Main = {0.015, 0.020, 0.025, 0.030, 0.040, 0.050},
        Sub = {0.008, 0.010, 0.013, 0.016, 0.020, 0.025},
    },
    AllyHealthAura = {
        Main = {0.015, 0.020, 0.025, 0.030, 0.040, 0.050},
        Sub = {0.008, 0.010, 0.013, 0.016, 0.020, 0.025},
    },
    AllyAttackHasteAura = {
        Main = {0.015, 0.020, 0.025, 0.030, 0.040, 0.050},
        Sub = {0.008, 0.010, 0.013, 0.016, 0.020, 0.025},
    },
    BuffPotency = {
        Main = {0.030, 0.045, 0.060, 0.080, 0.100, 0.120},
        Sub = {0.015, 0.023, 0.030, 0.040, 0.050, 0.060},
    },
}

EquipmentConfig.SubstatPool = {
    "Power",
    "Health",
    "Defence",
    "AttackHaste",
    "CooldownReduction",
    "AbilityDamage",
    "HealingPotency",
    "ShieldPotency",
    "DoTDamage",
    "Lifesteal",
    "ReflectStrength",
    "BossDamage",
    "BossDamageReduction",
    "DebuffPotency",
    "StatusResistance",
    "AllyPowerAura",
    "AllyDefenceAura",
    "AllyHealthAura",
    "AllyAttackHasteAura",
    "BuffPotency",
}

EquipmentConfig.Blueprints = {
    IronhideHarness = {
        Name = "Ironhide Harness",
        Slot = "Harness",
        MainStat = "Health",
        MaterialGroups = {"Structural", "Offensive"},
        Description = "A broad hide-and-plate harness built around maximum Health.",
    },
    BastionHarness = {
        Name = "Bastion Harness",
        Slot = "Harness",
        MainStat = "Defence",
        MaterialGroups = {"Structural", "Arcane"},
        Description = "Layered protection focused on Defence.",
    },
    WarhideHarness = {
        Name = "Warhide Harness",
        Slot = "Harness",
        MainStat = "Power",
        MaterialGroups = {"Structural", "Offensive"},
        Description = "A lighter battle harness that trades bulk for Power.",
    },
    GuardianHarness = {
        Name = "Guardian Harness",
        Slot = "Harness",
        MainStat = "BossDamageReduction",
        MaterialGroups = {"Structural", "Arcane"},
        Description = "Reinforced specifically for surviving world-boss attacks.",
    },
    ThornbackHarness = {
        Name = "Thornback Harness",
        Slot = "Harness",
        MainStat = "ReflectStrength",
        MaterialGroups = {"Structural", "Offensive"},
        Description = "Turns part of an enemy's aggression back against it.",
    },
    WardenHarness = {
        Name = "Warden Harness",
        Slot = "Harness",
        MainStat = "StatusResistance",
        MaterialGroups = {"Structural", "Arcane"},
        Description = "Resists poison, Blind, slows and other harmful statuses.",
    },
    LifebondHarness = {
        Name = "Lifebond Harness",
        Slot = "Harness",
        MainStat = "AllyHealthAura",
        MaterialGroups = {"Structural", "Arcane"},
        Description = "Raises the maximum Health of nearby allied pets.",
    },
    PackguardHarness = {
        Name = "Packguard Harness",
        Slot = "Harness",
        MainStat = "AllyDefenceAura",
        MaterialGroups = {"Structural", "Offensive"},
        Description = "Improves the Defence of nearby allied pets.",
    },
    BulwarkHarness = {
        Name = "Bulwark Harness",
        Slot = "Harness",
        MainStat = "ShieldPotency",
        MaterialGroups = {"Structural", "Arcane"},
        Description = "Strengthens shields created by the equipped pet.",
    },
    BloodguardHarness = {
        Name = "Bloodguard Harness",
        Slot = "Harness",
        MainStat = "Lifesteal",
        MaterialGroups = {"Structural", "Offensive"},
        Description = "Recovers a portion of damage dealt as Health.",
    },

    RuneboundCharm = {
        Name = "Runebound Charm",
        Slot = "Charm",
        MainStat = "CooldownReduction",
        MaterialGroups = {"Arcane", "Structural"},
        Description = "Reduces the cooldown of the pet's active abilities.",
    },
    MenderCharm = {
        Name = "Mender Charm",
        Slot = "Charm",
        MainStat = "HealingPotency",
        MaterialGroups = {"Arcane", "Structural"},
        Description = "Increases healing performed by the equipped pet.",
    },
    WardkeeperCharm = {
        Name = "Wardkeeper Charm",
        Slot = "Charm",
        MainStat = "ShieldPotency",
        MaterialGroups = {"Arcane", "Structural"},
        Description = "Increases shields created by the equipped pet.",
    },
    PackmasterCharm = {
        Name = "Packmaster Charm",
        Slot = "Charm",
        MainStat = "BuffPotency",
        MaterialGroups = {"Arcane", "Offensive"},
        Description = "Strengthens active ally buffs such as Pack Howl.",
    },
    FocusCharm = {
        Name = "Focus Charm",
        Slot = "Charm",
        MainStat = "AbilityDamage",
        MaterialGroups = {"Arcane", "Offensive"},
        Description = "Increases direct damage caused by active abilities.",
    },
    WarcallerCharm = {
        Name = "Warcaller Charm",
        Slot = "Charm",
        MainStat = "AllyPowerAura",
        MaterialGroups = {"Arcane", "Offensive"},
        Description = "Passively raises nearby allied pets' Power.",
    },
    TempoCharm = {
        Name = "Tempo Charm",
        Slot = "Charm",
        MainStat = "AllyAttackHasteAura",
        MaterialGroups = {"Arcane", "Offensive"},
        Description = "Passively raises nearby allied pets' Attack Haste.",
    },
    HexbinderCharm = {
        Name = "Hexbinder Charm",
        Slot = "Charm",
        MainStat = "DebuffPotency",
        MaterialGroups = {"Arcane", "Offensive"},
        Description = "Strengthens Sunder, Expose, Weaken and Attack Slow.",
    },
    SoulbindCharm = {
        Name = "Soulbind Charm",
        Slot = "Charm",
        MainStat = "Lifesteal",
        MaterialGroups = {"Arcane", "Offensive"},
        Description = "Converts a portion of dealt damage into Health.",
    },
    WorldwatchCharm = {
        Name = "Worldwatch Charm",
        Slot = "Charm",
        MainStat = "BossDamage",
        MaterialGroups = {"Arcane", "Structural"},
        Description = "Increases damage dealt to world bosses.",
    },

    PredatorSigil = {
        Name = "Predator Sigil",
        Slot = "Sigil",
        MainStat = "Power",
        MaterialGroups = {"Offensive", "Arcane"},
        Description = "A direct offensive sigil built around Power.",
    },
    QuickfangSigil = {
        Name = "Quickfang Sigil",
        Slot = "Sigil",
        MainStat = "AttackHaste",
        MaterialGroups = {"Offensive", "Arcane"},
        Description = "Speeds up the pet's basic attack cycle.",
    },
    VenomweaveSigil = {
        Name = "Venomweave Sigil",
        Slot = "Sigil",
        MainStat = "DoTDamage",
        MaterialGroups = {"Offensive", "Arcane"},
        Description = "Strengthens bleed, burn, poison and other damage-over-time effects.",
    },
    BreakerSigil = {
        Name = "Breaker Sigil",
        Slot = "Sigil",
        MainStat = "DebuffPotency",
        MaterialGroups = {"Offensive", "Structural"},
        Description = "Improves non-control combat debuffs against enemies.",
    },
    TitanhunterSigil = {
        Name = "Titanhunter Sigil",
        Slot = "Sigil",
        MainStat = "BossDamage",
        MaterialGroups = {"Offensive", "Structural"},
        Description = "Specialised for repeated world-boss hunts.",
    },
    SpellfangSigil = {
        Name = "Spellfang Sigil",
        Slot = "Sigil",
        MainStat = "AbilityDamage",
        MaterialGroups = {"Offensive", "Arcane"},
        Description = "Makes direct active-ability strikes hit harder.",
    },
    MirrorfangSigil = {
        Name = "Mirrorfang Sigil",
        Slot = "Sigil",
        MainStat = "ReflectStrength",
        MaterialGroups = {"Offensive", "Structural"},
        Description = "Strengthens damage reflected by shields and guards.",
    },
    IronfangSigil = {
        Name = "Ironfang Sigil",
        Slot = "Sigil",
        MainStat = "Defence",
        MaterialGroups = {"Offensive", "Structural"},
        Description = "Adds Defence without occupying the Harness slot.",
    },
    WarcrySigil = {
        Name = "Warcry Sigil",
        Slot = "Sigil",
        MainStat = "AllyPowerAura",
        MaterialGroups = {"Offensive", "Arcane"},
        Description = "Passively raises the Power of nearby allied pets.",
    },
    EnduranceSigil = {
        Name = "Endurance Sigil",
        Slot = "Sigil",
        MainStat = "StatusResistance",
        MaterialGroups = {"Offensive", "Structural"},
        Description = "Reduces the impact of harmful status effects.",
    },
}

EquipmentConfig.BlueprintOrder = {
    "IronhideHarness",
    "BastionHarness",
    "WarhideHarness",
    "GuardianHarness",
    "ThornbackHarness",
    "WardenHarness",
    "LifebondHarness",
    "PackguardHarness",
    "BulwarkHarness",
    "BloodguardHarness",

    "RuneboundCharm",
    "MenderCharm",
    "WardkeeperCharm",
    "PackmasterCharm",
    "FocusCharm",
    "WarcallerCharm",
    "TempoCharm",
    "HexbinderCharm",
    "SoulbindCharm",
    "WorldwatchCharm",

    "PredatorSigil",
    "QuickfangSigil",
    "VenomweaveSigil",
    "BreakerSigil",
    "TitanhunterSigil",
    "SpellfangSigil",
    "MirrorfangSigil",
    "IronfangSigil",
    "WarcrySigil",
    "EnduranceSigil",
}

EquipmentConfig.WorldforgeSources = {
    ["Jörmungandr"] = {
        Primary = "World Serpent Scale",
        Secondary = "Ragnarok Venom",
    },
    Kraken = {
        Primary = "Kraken Tentacle",
        Secondary = "Abyssal Ink",
    },
    Fenrir = {
        Primary = "Fenrir Fang",
        Secondary = "Moon-Eater Pelt",
    },
    ["Gaia Titan"] = {
        Primary = "Gaia Stone",
        Secondary = "Primordial Heartwood",
    },
}

EquipmentConfig.WorldforgeCosts = {
    [1] = {Primary = 2, Secondary = 0, Coins = 5000},
    [2] = {Primary = 3, Secondary = 1, Coins = 10000},
    [3] = {Primary = 4, Secondary = 1, Coins = 20000},
    [4] = {Primary = 5, Secondary = 2, Coins = 35000},
    [5] = {Primary = 6, Secondary = 3, Coins = 50000},
}

EquipmentConfig.BossUniques = {
    ["Jörmungandr"] = {
        Id = "RagnarokCharm",
        Name = "Ragnarok Charm",
        Slot = "Charm",
    },
    Kraken = {
        Id = "AbyssalHarness",
        Name = "Abyssal Harness",
        Slot = "Harness",
    },
    Fenrir = {
        Id = "GleipnirSigil",
        Name = "Gleipnir Sigil",
        Slot = "Sigil",
    },
    ["Gaia Titan"] = {
        Id = "WorldrootHarness",
        Name = "Worldroot Harness",
        Slot = "Harness",
    },
}

EquipmentConfig.BossMainStatPool = {
    "Power",
    "Health",
    "Defence",
    "AttackHaste",
    "CooldownReduction",
    "AbilityDamage",
    "HealingPotency",
    "ShieldPotency",
    "DoTDamage",
    "Lifesteal",
    "ReflectStrength",
    "BossDamage",
    "BossDamageReduction",
    "DebuffPotency",
    "StatusResistance",
    "AllyPowerAura",
    "AllyDefenceAura",
    "AllyHealthAura",
    "AllyAttackHasteAura",
    "BuffPotency",
}

function EquipmentConfig:GetMaterialGroup(itemName)
    local name = tostring(itemName or ""):lower()

    if name:find("fang", 1, true)
        or name:find("claw", 1, true)
        or name:find("talon", 1, true)
        or name:find("tusk", 1, true)
        or name:find("horn", 1, true)
        or name:find("antler", 1, true)
        or name:find("hoof", 1, true)
        or name:find("stinger", 1, true)
        or name:find("barb", 1, true)
        or name:find("quill", 1, true)
        or name:find("venom", 1, true)
        or name:find("sunfire", 1, true) then
        return "Offensive"
    end

    if name:find("hide", 1, true)
        or name:find("pelt", 1, true)
        or name:find("fur", 1, true)
        or name:find("fleece", 1, true)
        or name:find("mane", 1, true)
        or name:find("velvet", 1, true)
        or name:find("scale", 1, true)
        or name:find("shell", 1, true)
        or name:find("carapace", 1, true)
        or name:find("plate", 1, true)
        or name:find("bark", 1, true)
        or name:find("stone", 1, true)
        or name:find("seed", 1, true)
        or name:find("petal", 1, true) then
        return "Structural"
    end

    return "Arcane"
end

function EquipmentConfig:GetTierRank(tier)
    local info = self.Tiers[tier]
    return info and info.Rank or nil
end

function EquipmentConfig:GetRecipe(blueprintId, tier, investmentId)
    local blueprint = self.Blueprints[blueprintId]
    local tierInfo = self.Tiers[tier]
    local investment = self.Investments[tonumber(investmentId) or 1]
    if not blueprint or not tierInfo or not investment then return nil end

    return {
        BlueprintId = blueprintId,
        Blueprint = blueprint,
        Tier = tier,
        InvestmentId = investment.Id,
        PrimaryGroup = blueprint.MaterialGroups[1],
        SecondaryGroup = blueprint.MaterialGroups[2],
        PrimaryCount = math.max(1, math.ceil(tierInfo.Primary * investment.MaterialMultiplier)),
        SecondaryCount = math.max(1, math.ceil(tierInfo.Secondary * investment.MaterialMultiplier)),
        Coins = math.max(0, math.floor(tierInfo.Coins * investment.CoinMultiplier + 0.5)),
    }
end

function EquipmentConfig:GetQuality(score)
    score = math.clamp(math.floor(tonumber(score) or 0), 0, 100)

    for _, qualityName in ipairs(self.QualityOrder) do
        local quality = self.Qualities[qualityName]
        if score >= quality.MinScore and score <= quality.MaxScore then
            local alpha = quality.MaxScore > quality.MinScore
                and ((score - quality.MinScore) / (quality.MaxScore - quality.MinScore))
                or 1

            return qualityName,
                quality.MinMultiplier + (quality.MaxMultiplier - quality.MinMultiplier) * alpha
        end
    end

    return "Crude", self.Qualities.Crude.MinMultiplier
end

function EquipmentConfig:GetBaseStat(statName, tier, substat)
    local profile = self.StatBases[statName]
    local tierInfo = self.Tiers[tier]
    if not profile or not tierInfo then return 0 end

    local list = substat and profile.Sub or profile.Main
    return tonumber(list[tierInfo.Rank]) or 0
end

function EquipmentConfig:RollItemLevel(random, investmentId)
    local investment = self.Investments[tonumber(investmentId) or 1] or self.Investments[1]
    local roll = random:NextNumber() * 100
    local cumulative = 0

    for level, weight in ipairs(investment.LevelWeights) do
        cumulative += weight
        if roll <= cumulative then
            return level
        end
    end

    return 1
end

function EquipmentConfig:FormatStat(statName, value)
    return (self.StatLabels[statName] or tostring(statName))
        .. " +"
        .. tostring(math.floor((tonumber(value) or 0) * 1000 + 0.5) / 10)
        .. "%"
end

local function addStat(result, statName, value)
    if not EquipmentConfig.StatCaps[statName] then return end
    result[statName] = (result[statName] or 0) + math.max(0, tonumber(value) or 0)
end

function EquipmentConfig:GetItemStats(item)
    local result = {}
    if type(item) ~= "table" then return result end

    local worldforgeLevel = math.clamp(
        math.floor(tonumber(item.WorldforgeLevel) or 0),
        0,
        self.MaxWorldforgeLevel
    )
    local multiplier = 1 + worldforgeLevel * self.WorldforgeStatPerLevel

    if type(item.MainStat) == "table" then
        addStat(
            result,
            tostring(item.MainStat.Name or ""),
            (tonumber(item.MainStat.Value) or 0) * multiplier
        )
    end

    for _, stat in ipairs(item.Substats or {}) do
        if type(stat) == "table" then
            addStat(
                result,
                tostring(stat.Name or ""),
                (tonumber(stat.Value) or 0) * multiplier
            )
        end
    end

    return result
end

function EquipmentConfig:GetBonuses(pet)
    local result = {}
    for statName in pairs(self.StatCaps) do result[statName] = 0 end

    if type(pet) ~= "table" then return result end

    local equipped = type(pet.Equipment) == "table" and pet.Equipment or {}
    for _, slotName in ipairs(self.Slots) do
        local item = equipped[slotName]
        for statName, value in pairs(self:GetItemStats(item)) do
            result[statName] += value
        end
    end

    for statName, cap in pairs(self.StatCaps) do
        result[statName] = math.clamp(result[statName] or 0, 0, cap)
    end

    return result
end

return EquipmentConfig
