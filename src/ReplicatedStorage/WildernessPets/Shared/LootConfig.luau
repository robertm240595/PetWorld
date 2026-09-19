local LootConfig = {}

LootConfig.BagLifetimeSeconds = 120
LootConfig.CollectDistance = 20

LootConfig.RarityChances = {
    Common = {Primary = 0.70, Secondary = 0.38},
    Uncommon = {Primary = 0.60, Secondary = 0.30},
    Rare = {Primary = 0.50, Secondary = 0.24},
    Epic = {Primary = 0.40, Secondary = 0.18},
    Legendary = {Primary = 0.30, Secondary = 0.12},
    Mythic = {Primary = 0.22, Secondary = 0.08},
    Limited = {Primary = 0.18, Secondary = 0.06},
    Ancient = {Primary = 0.14, Secondary = 0.05},
}

LootConfig.CoinMultipliers = {
    Common = {Min = 0.80, Max = 1.25},
    Uncommon = {Min = 0.85, Max = 1.30},
    Rare = {Min = 0.90, Max = 1.35},
    Epic = {Min = 0.95, Max = 1.40},
    Legendary = {Min = 1.00, Max = 1.50},
    Mythic = {Min = 1.10, Max = 1.60},
    Limited = {Min = 1.15, Max = 1.70},
    Ancient = {Min = 1.25, Max = 1.85},
}

LootConfig.Drops = {
    ["Wolf"] = {Primary = "Wolf Fang", Secondary = "Wolf Hide"},
    ["Boar"] = {Primary = "Boar Tusk", Secondary = "Coarse Boar Hide"},
    ["Fox"] = {Primary = "Fox Tail Fur", Secondary = "Fox Fang"},
    ["Hare"] = {Primary = "Hare Pelt", Secondary = "Lucky Hare Foot"},
    ["Hedgehog"] = {Primary = "Hedgehog Quill", Secondary = "Bristled Hide"},
    ["Moon Bat"] = {Primary = "Moon Bat Wing", Secondary = "Echo Fang"},
    ["Raccoon"] = {Primary = "Raccoon Pelt", Secondary = "Bandit Claw"},
    ["Badger"] = {Primary = "Badger Claw", Secondary = "Striped Hide"},
    ["Opossum"] = {Primary = "Opossum Tail", Secondary = "Opossum Pelt"},
    ["Field Mouse"] = {Primary = "Mouse Whiskers", Secondary = "Soft Mouse Fur"},

    ["River Otter"] = {Primary = "Otter Pelt", Secondary = "River Otter Whisker"},
    ["Red Panda"] = {Primary = "Red Panda Fur", Secondary = "Ringed Tail Tuft"},
    ["Mountain Goat"] = {Primary = "Mountain Goat Horn", Secondary = "Mountain Fleece"},
    ["Lynx"] = {Primary = "Lynx Claw", Secondary = "Lynx Pelt"},
    ["Peacock"] = {Primary = "Peacock Feather", Secondary = "Prismatic Eye Feather"},
    ["Barn Owl"] = {Primary = "Owl Feather", Secondary = "Owl Talon"},
    ["Porcupine"] = {Primary = "Porcupine Quill", Secondary = "Barbed Quill"},
    ["Pangolin"] = {Primary = "Pangolin Scale", Secondary = "Scale Plate"},
    ["Lantern Gecko"] = {Primary = "Gecko Scale", Secondary = "Lantern Gland"},
    ["Glow Beetle"] = {Primary = "Glow Beetle Shell", Secondary = "Luminous Dust"},

    ["Bear"] = {Primary = "Bear Claw", Secondary = "Bear Hide"},
    ["Thunder Ram"] = {Primary = "Thunder Horn", Secondary = "Charged Fleece"},
    ["Jade Tortoise"] = {Primary = "Jade Shell Fragment", Secondary = "Tortoise Scale"},
    ["Sunscale Raptor"] = {Primary = "Sunscale Talon", Secondary = "Solar Crest Feather"},
    ["Shadow Stag"] = {Primary = "Shadow Antler", Secondary = "Night Velvet"},
    ["Crystal Scorpion"] = {Primary = "Crystal Stinger", Secondary = "Prism Carapace"},
    ["Moon Moth"] = {Primary = "Moon Moth Wing", Secondary = "Lunar Dust"},
    ["Dusk Cobra"] = {Primary = "Dusk Fang", Secondary = "Twilight Scale"},

    ["Griffin"] = {Primary = "Griffin Talon", Secondary = "Griffin Feather"},
    ["Kirin"] = {Primary = "Kirin Horn Shard", Secondary = "Sacred Mane"},
    ["Ember Salamander"] = {Primary = "Ember Scale", Secondary = "Molten Gland"},
    ["Storm Roc"] = {Primary = "Storm Feather", Secondary = "Tempest Talon"},
    ["Manticore"] = {Primary = "Manticore Barb", Secondary = "Manticore Mane"},
    ["Basilisk"] = {Primary = "Basilisk Fang", Secondary = "Petrified Scale"},
    ["Nightmare Steed"] = {Primary = "Nightmare Mane", Secondary = "Dread Hoof"},
    ["Void Weaver"] = {Primary = "Void Silk", Secondary = "Void Fang"},

    ["Phoenix"] = {Primary = "Phoenix Feather", Secondary = "Rebirth Ember"},
    ["Unicorn"] = {
        Primary = "Unicorn Horn",
        Secondary = "Rainbow Mane",
        PrimaryChance = 0.20,
        SecondaryChance = 0.10,
    },
    ["Celestial Lion"] = {Primary = "Celestial Claw", Secondary = "Star Mane"},
    ["Cerberus"] = {Primary = "Cerberus Fang", Secondary = "Infernal Mane"},
    ["Chimera"] = {Primary = "Chimera Horn", Secondary = "Chimera Scale"},
    ["Abyss Hydra"] = {Primary = "Hydra Fang", Secondary = "Abyss Scale"},

    ["Solar Dragon"] = {Primary = "Solar Dragon Scale", Secondary = "Sunfire Core"},
    ["Worldroot Colossus"] = {Primary = "Worldroot Bark", Secondary = "Heartwood Core"},
    ["Leviathan"] = {Primary = "Leviathan Scale", Secondary = "Deepsea Pearl"},
    ["Astral Serpent"] = {Primary = "Astral Scale", Secondary = "Star Venom"},

    ["Frostbell Reindeer"] = {Primary = "Frostbell Antler", Secondary = "Winter Bell"},
    ["Pumpkin Imp"] = {Primary = "Imp Horn", Secondary = "Cursed Pumpkin Seed"},
    ["Bloom Jackalope"] = {Primary = "Bloom Antler", Secondary = "Spring Petal"},
    ["Starfall Starling"] = {Primary = "Starfall Feather", Secondary = "Fallen Star Shard"},

    ["Kraken"] = {Primary = "Kraken Tentacle", Secondary = "Abyssal Ink"},
    ["Jörmungandr"] = {Primary = "World Serpent Scale", Secondary = "Ragnarok Venom"},
    ["Fenrir"] = {Primary = "Fenrir Fang", Secondary = "Moon-Eater Pelt"},
    ["Gaia Titan"] = {Primary = "Gaia Stone", Secondary = "Primordial Heartwood"},
}

function LootConfig:GetDrop(species)
    return self.Drops[species]
end

function LootConfig:GetChances(species, rarity)
    local drop = self.Drops[species]
    local defaults = self.RarityChances[rarity] or self.RarityChances.Common
    return drop and (tonumber(drop.PrimaryChance) or defaults.Primary) or defaults.Primary,
        drop and (tonumber(drop.SecondaryChance) or defaults.Secondary) or defaults.Secondary
end

return LootConfig
