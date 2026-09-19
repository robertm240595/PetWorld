local PetAbilities = {}

PetAbilities.Effects = {
    QuickStrike = {
        Description = "A fast single-target strike for 120% Power.",
        DamageScale = 1.20,
    },
    HeavyStrike = {
        Description = "A heavy single-target strike for 165% Power.",
        DamageScale = 1.65,
    },
    MultiStrike = {
        Description = "Three rapid hits at 65% Power each.",
        DamageScale = 0.65,
        Hits = 3,
    },
    BleedStrike = {
        Description = "Deals 120% Power and inflicts a bleed worth 35% Power over 5 seconds.",
        DamageScale = 1.20,
        DamageOverTimeScale = 0.35,
        Duration = 5,
    },
    BurnStrike = {
        Description = "Deals 120% Power and burns the target for 40% Power over 5 seconds.",
        DamageScale = 1.20,
        DamageOverTimeScale = 0.40,
        Duration = 5,
    },
    PoisonStrike = {
        Description = "Deals 105% Power and poisons the target for 55% Power over 7 seconds.",
        DamageScale = 1.05,
        DamageOverTimeScale = 0.55,
        Duration = 7,
    },
    ShockStrike = {
        Description = "Deals 125% Power and briefly shocks the target.",
        DamageScale = 1.25,
        StunSeconds = 0.65,
    },
    StunStrike = {
        Description = "Deals 110% Power and stuns the target for 1.2 seconds.",
        DamageScale = 1.10,
        StunSeconds = 1.20,
    },
    RootStrike = {
        Description = "Deals 110% Power and roots the target for 2 seconds.",
        DamageScale = 1.10,
        RootSeconds = 2,
    },
    SlowStrike = {
        Description = "Deals 115% Power and slows the target by 30% for 4 seconds.",
        DamageScale = 1.15,
        SlowPercent = 0.30,
        Duration = 4,
    },
    AreaStrike = {
        Description = "Hits nearby enemies for 115% Power.",
        DamageScale = 1.15,
        Radius = 12,
    },
    AreaBurn = {
        Description = "Hits nearby enemies for 100% Power and burns them for 35% Power over 5 seconds.",
        DamageScale = 1.00,
        DamageOverTimeScale = 0.35,
        Duration = 5,
        Radius = 12,
    },
    AreaShock = {
        Description = "Hits nearby enemies for 105% Power and briefly shocks them.",
        DamageScale = 1.05,
        StunSeconds = 0.55,
        Radius = 12,
    },
    AreaStun = {
        Description = "Hits nearby enemies for 95% Power and stuns them for 1 second.",
        DamageScale = 0.95,
        StunSeconds = 1,
        Radius = 12,
    },
    SelfHeal = {
        Description = "Restores 25% of the pet's maximum Health.",
        HealPercent = 0.25,
    },
    GreaterHeal = {
        Description = "Restores 40% of the pet's maximum Health.",
        HealPercent = 0.40,
    },
    CleanseHeal = {
        Description = "Restores 20% maximum Health and removes one harmful status effect.",
        HealPercent = 0.20,
        Cleanse = true,
    },
    LifeDrain = {
        Description = "Deals 115% Power and heals for 50% of the damage dealt.",
        DamageScale = 1.15,
        LifeStealPercent = 0.50,
    },
    ShieldSelf = {
        Description = "Grants a shield equal to 25% maximum Health for 8 seconds.",
        ShieldPercent = 0.25,
        Duration = 8,
    },
    DefenceBuff = {
        Description = "Raises Defence by 30% for 8 seconds.",
        DefencePercent = 0.30,
        Duration = 8,
    },
    PowerBuff = {
        Description = "Raises Power by 25% for 8 seconds.",
        PowerPercent = 0.25,
        Duration = 8,
    },
    SpeedBuff = {
        Description = "Raises movement speed by 25% for 8 seconds.",
        SpeedPercent = 0.25,
        Duration = 8,
    },
    ReflectGuard = {
        Description = "Reduces incoming damage by 20% and reflects 25% of received damage for 6 seconds.",
        DamageReductionPercent = 0.20,
        ReflectPercent = 0.25,
        Duration = 6,
    },
    ExecuteStrike = {
        Description = "Deals 125% Power, increased to 190% Power against targets below 30% Health.",
        DamageScale = 1.25,
        ExecuteDamageScale = 1.90,
        ExecuteHealthPercent = 0.30,
    },
}

local function ability(name, effect)
    return {
        Name = name,
        Effect = effect,
    }
end

PetAbilities.Pets = {
    ["Wolf"] = {
        ability("Lick Wounds", "SelfHeal"),
        ability("Pack Howl", "PowerBuff"),
        ability("Rending Bite", "BleedStrike"),
    },
    ["Boar"] = {
        ability("Tusk Rush", "StunStrike"),
        ability("Bristle Guard", "DefenceBuff"),
        ability("Mudbreaker", "AreaStrike"),
    },
    ["Fox"] = {
        ability("Quick Pounce", "QuickStrike"),
        ability("Cunning Feint", "SpeedBuff"),
        ability("Foxfire Nip", "BurnStrike"),
    },
    ["Hare"] = {
        ability("Springbound Kick", "HeavyStrike"),
        ability("Burrow Breather", "SelfHeal"),
        ability("Fleetfoot Dash", "SpeedBuff"),
    },
    ["Hedgehog"] = {
        ability("Quill Burst", "AreaStrike"),
        ability("Curl Up", "ShieldSelf"),
        ability("Prickle Charge", "StunStrike"),
    },
    ["Moon Bat"] = {
        ability("Sonic Burst", "StunStrike"),
        ability("Night Veil", "DefenceBuff"),
        ability("Siphon Bite", "LifeDrain"),
    },
    ["Raccoon"] = {
        ability("Scavenger Swipe", "QuickStrike"),
        ability("Trashcan Trick", "StunStrike"),
        ability("Nimble Paws", "SpeedBuff"),
    },
    ["Badger"] = {
        ability("Burrow Bash", "HeavyStrike"),
        ability("Stubborn Hide", "DefenceBuff"),
        ability("Settle In", "SelfHeal"),
    },
    ["Opossum"] = {
        ability("Feign Fall", "ShieldSelf"),
        ability("Tail Snap", "QuickStrike"),
        ability("Second Wind", "SelfHeal"),
    },
    ["Field Mouse"] = {
        ability("Nibble Flurry", "MultiStrike"),
        ability("Hideaway", "ShieldSelf"),
        ability("Squeak Rally", "SpeedBuff"),
    },

    ["River Otter"] = {
        ability("Current Slide", "QuickStrike"),
        ability("River Mend", "SelfHeal"),
        ability("Whirlpool Tail", "AreaStrike"),
    },
    ["Red Panda"] = {
        ability("Bamboo Balm", "SelfHeal"),
        ability("Canopy Tumble", "QuickStrike"),
        ability("Crimson Claws", "BleedStrike"),
    },
    ["Mountain Goat"] = {
        ability("Cliffside Charge", "StunStrike"),
        ability("Granite Hooves", "DefenceBuff"),
        ability("Highground Rally", "PowerBuff"),
    },
    ["Lynx"] = {
        ability("Groom Wounds", "SelfHeal"),
        ability("Silent Pounce", "HeavyStrike"),
        ability("Snowclaw Rend", "BleedStrike"),
    },
    ["Peacock"] = {
        ability("Fan Flash", "StunStrike"),
        ability("Royal Display", "PowerBuff"),
        ability("Featherstorm", "AreaStrike"),
    },
    ["Barn Owl"] = {
        ability("Silent Talons", "HeavyStrike"),
        ability("Moonwatch", "ShieldSelf"),
        ability("Hoot of Focus", "PowerBuff"),
    },
    ["Porcupine"] = {
        ability("Quill Volley", "BleedStrike"),
        ability("Spined Guard", "DefenceBuff"),
        ability("Backlash Barbs", "ReflectGuard"),
    },
    ["Pangolin"] = {
        ability("Scale Curl", "ShieldSelf"),
        ability("Rolling Ram", "StunStrike"),
        ability("Antsnare Tongue", "LifeDrain"),
    },
    ["Lantern Gecko"] = {
        ability("Glowmend", "SelfHeal"),
        ability("Sticky Ambush", "RootStrike"),
        ability("Lantern Flare", "BurnStrike"),
    },
    ["Glow Beetle"] = {
        ability("Luminous Shell", "ShieldSelf"),
        ability("Spark Ram", "ShockStrike"),
        ability("Beacon Pulse", "PowerBuff"),
    },

    ["Bear"] = {
        ability("Bear Swipe", "HeavyStrike"),
        ability("Thick Hide", "DefenceBuff"),
        ability("Ground Slam", "AreaStun"),
    },
    ["Thunder Ram"] = {
        ability("Thunderhead Charge", "ShockStrike"),
        ability("Storm Fleece", "ShieldSelf"),
        ability("Rolling Thunder", "AreaShock"),
    },
    ["Jade Tortoise"] = {
        ability("Jade Shell", "ShieldSelf"),
        ability("Tidal Snap", "HeavyStrike"),
        ability("Emerald Renewal", "GreaterHeal"),
    },
    ["Sunscale Raptor"] = {
        ability("Solar Talon", "BurnStrike"),
        ability("Suncrest Rush", "SpeedBuff"),
        ability("Scorching Screech", "AreaBurn"),
    },
    ["Shadow Stag"] = {
        ability("Antler Rush", "StunStrike"),
        ability("Moon Ward", "ShieldSelf"),
        ability("Forest Call", "PowerBuff"),
    },
    ["Crystal Scorpion"] = {
        ability("Prism Sting", "PoisonStrike"),
        ability("Crystal Carapace", "DefenceBuff"),
        ability("Shardtail Sweep", "AreaStrike"),
    },
    ["Moon Moth"] = {
        ability("Lunar Dust", "SlowStrike"),
        ability("Moonwing Mend", "SelfHeal"),
        ability("Dreamflash", "StunStrike"),
    },
    ["Dusk Cobra"] = {
        ability("Venom Fang", "PoisonStrike"),
        ability("Twilight Coil", "RootStrike"),
        ability("Hooded Hypnosis", "StunStrike"),
    },

    ["Griffin"] = {
        ability("Dive Bomb", "HeavyStrike"),
        ability("Wing Buffet", "AreaStrike"),
        ability("Sky Cry", "PowerBuff"),
    },
    ["Kirin"] = {
        ability("Sacred Hoof", "HeavyStrike"),
        ability("Cloudveil Ward", "ShieldSelf"),
        ability("Fortune Chime", "CleanseHeal"),
    },
    ["Ember Salamander"] = {
        ability("Ember Spit", "BurnStrike"),
        ability("Molten Skin", "ReflectGuard"),
        ability("Cinder Renewal", "SelfHeal"),
    },
    ["Storm Roc"] = {
        ability("Tempest Dive", "ShockStrike"),
        ability("Gale Guard", "ShieldSelf"),
        ability("Lightning Cry", "AreaShock"),
    },
    ["Manticore"] = {
        ability("Venom Barb", "PoisonStrike"),
        ability("Lionheart Roar", "PowerBuff"),
        ability("Winged Maul", "HeavyStrike"),
    },
    ["Basilisk"] = {
        ability("Petrifying Gaze", "StunStrike"),
        ability("Venom Crown", "PoisonStrike"),
        ability("Scale Fortress", "DefenceBuff"),
    },
    ["Nightmare Steed"] = {
        ability("Dread Gallop", "StunStrike"),
        ability("Shadow Mane", "ShieldSelf"),
        ability("Terror Whinny", "AreaStun"),
    },
    ["Void Weaver"] = {
        ability("Voidbite", "LifeDrain"),
        ability("Web of Silence", "RootStrike"),
        ability("Phase Carapace", "ReflectGuard"),
    },

    ["Phoenix"] = {
        ability("Rebirth Flame", "GreaterHeal"),
        ability("Solar Plume", "AreaBurn"),
        ability("Ashen Reprisal", "ReflectGuard"),
    },
    ["Unicorn"] = {
        ability("Purity Touch", "CleanseHeal"),
        ability("Prismatic Charge", "HeavyStrike"),
        ability("Sanctuary Horn", "ShieldSelf"),
    },
    ["Celestial Lion"] = {
        ability("Starclaw", "HeavyStrike"),
        ability("Sovereign Roar", "PowerBuff"),
        ability("Astral Aegis", "ShieldSelf"),
    },
    ["Cerberus"] = {
        ability("Triple Fang", "MultiStrike"),
        ability("Gatekeeper Guard", "DefenceBuff"),
        ability("Hellhowl", "AreaBurn"),
    },
    ["Chimera"] = {
        ability("Triune Assault", "MultiStrike"),
        ability("Serpent Tail", "PoisonStrike"),
        ability("Chimera's Resolve", "PowerBuff"),
    },
    ["Abyss Hydra"] = {
        ability("Many-Maw Frenzy", "MultiStrike"),
        ability("Abyssal Regrowth", "GreaterHeal"),
        ability("Drowning Venom", "PoisonStrike"),
    },

    ["Solar Dragon"] = {
        ability("Sunfire Breath", "BurnStrike"),
        ability("Solar Ascendance", "PowerBuff"),
        ability("Corona Crash", "AreaBurn"),
    },
    ["Worldroot Colossus"] = {
        ability("Rootquake", "AreaStun"),
        ability("Ancient Bark", "ShieldSelf"),
        ability("Verdant Renewal", "GreaterHeal"),
    },
    ["Leviathan"] = {
        ability("Tidal Surge", "AreaStrike"),
        ability("Undertow", "RootStrike"),
        ability("Deep Guard", "DefenceBuff"),
    },
    ["Astral Serpent"] = {
        ability("Comet Coil", "HeavyStrike"),
        ability("Starvenom", "PoisonStrike"),
        ability("Nebula Shedding", "CleanseHeal"),
    },

    ["Frostbell Reindeer"] = {
        ability("Sleighbell Rush", "StunStrike"),
        ability("Winter's Grace", "CleanseHeal"),
        ability("Aurora Antlers", "AreaShock"),
    },
    ["Pumpkin Imp"] = {
        ability("Trick-or-Claw", "QuickStrike"),
        ability("Gourd Guard", "ShieldSelf"),
        ability("Lantern Cackle", "AreaBurn"),
    },
    ["Bloom Jackalope"] = {
        ability("Petal Pounce", "QuickStrike"),
        ability("Spring Sap", "GreaterHeal"),
        ability("Thornhorn Bloom", "BleedStrike"),
    },
    ["Starfall Starling"] = {
        ability("Star Volley", "MultiStrike"),
        ability("Constellation Song", "CleanseHeal"),
        ability("Meteor Flight", "SpeedBuff"),
    },

    ["Kraken"] = {
        ability("Tentacle Cataclysm", "AreaStrike"),
        ability("Maelstrom Grip", "RootStrike"),
        ability("Abyssal Renewal", "GreaterHeal"),
    },
    ["Jörmungandr"] = {
        ability("Worldcoil Crush", "HeavyStrike"),
        ability("Midgard Venom", "PoisonStrike"),
        ability("Ragnarok Scale", "ReflectGuard"),
    },
    ["Fenrir"] = {
        ability("Godfang Rend", "BleedStrike"),
        ability("Gleipnir Break", "ExecuteStrike"),
        ability("Moon-Eater Howl", "PowerBuff"),
    },
    ["Gaia Titan"] = {
        ability("Continental Stomp", "AreaStun"),
        ability("Worldstone Bulwark", "ShieldSelf"),
        ability("Gaia's Bloom", "GreaterHeal"),
    },

    -- Legacy species remain readable for previously owned pets.
    ["Dragon"] = {
        ability("Flame Breath", "BurnStrike"),
        ability("Wing Storm", "AreaStrike"),
        ability("Dragon Roar", "PowerBuff"),
    },
    ["Starling"] = {
        ability("Radiant Volley", "MultiStrike"),
        ability("Healing Song", "SelfHeal"),
        ability("Radiant Flight", "SpeedBuff"),
    },
    ["AncientTitan"] = {
        ability("Titan Stomp", "AreaStun"),
        ability("Stone Guard", "DefenceBuff"),
        ability("Earth Shatter", "AreaStrike"),
    },
    ["MoonBat"] = {
        ability("Echo Burst", "StunStrike"),
        ability("Dark Veil", "DefenceBuff"),
        ability("Leech Bite", "LifeDrain"),
    },
    ["ShadowStag"] = {
        ability("Oldwood Rush", "StunStrike"),
        ability("Eclipse Ward", "ShieldSelf"),
        ability("Wildwood Call", "PowerBuff"),
    },
    ["Nightfang"] = {
        ability("Nightfang Bite", "BleedStrike"),
        ability("Darkpack Howl", "PowerBuff"),
        ability("Moonlit Recovery", "SelfHeal"),
    },
    ["Dusktail"] = {
        ability("Dusk Pounce", "QuickStrike"),
        ability("Twilight Feint", "SpeedBuff"),
        ability("Violet Foxfire", "BurnStrike"),
    },
    ["EclipseGriffin"] = {
        ability("Eclipse Dive", "HeavyStrike"),
        ability("Umbral Buffet", "AreaStrike"),
        ability("Darksky Cry", "PowerBuff"),
    },
    ["VoidDragon"] = {
        ability("Void Breath", "BurnStrike"),
        ability("Rift Wing", "AreaStrike"),
        ability("Abyss Roar", "PowerBuff"),
    },
    ["AbyssLeviathan"] = {
        ability("Abyss Surge", "AreaStrike"),
        ability("Black Undertow", "RootStrike"),
        ability("Trench Guard", "DefenceBuff"),
    },
    ["AstralStarling"] = {
        ability("Astral Volley", "MultiStrike"),
        ability("Starlight Song", "CleanseHeal"),
        ability("Comet Flight", "SpeedBuff"),
    },
    ["ObsidianTitan"] = {
        ability("Obsidian Stomp", "AreaStun"),
        ability("Basalt Guard", "DefenceBuff"),
        ability("Volcanic Shatter", "AreaStrike"),
    },
}

function PetAbilities:Get(species)
    return self.Pets[species]
end

function PetAbilities:GetEffect(abilityInfo)
    if type(abilityInfo) ~= "table" then return nil end
    return self.Effects[abilityInfo.Effect]
end

function PetAbilities:GetDescription(abilityInfo)
    local effect = self:GetEffect(abilityInfo)
    return effect and effect.Description or ""
end

return PetAbilities
