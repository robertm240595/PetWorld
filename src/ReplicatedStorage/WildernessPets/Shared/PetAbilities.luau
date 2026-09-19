local PetAbilities = {}

PetAbilities.BlindMissChance = 0.80
PetAbilities.ControlDiminishingReturns = {
    Window = 20,
    ResetAfter = 20,
    Multipliers = {1.00, 0.65, 0.40, 0.20},
    Families = {
        Stun = true,
        Blind = true,
        AttackSlow = true,
        Root = true,
    },
}

local function ability(name, kind, cooldown, data)
    local result = {
        Name = name,
        Kind = kind,
        Cooldown = cooldown,
    }
    for key, value in pairs(data or {}) do
        result[key] = value
    end
    return result
end

local function attack(name, scale, cooldown, data)
    data = data or {}
    data.DamageScale = scale
    return ability(name, "Attack", cooldown or 6, data)
end

local function utility(name, cooldown, data)
    return ability(name, "Utility", cooldown or 12, data or {})
end

local function heal(name, percent, cooldown, data)
    data = data or {}
    data.HealPercent = percent
    return ability(name, "Heal", cooldown or 18, data)
end

local function debuff(t, value, duration)
    return {Type = t, Value = value, Duration = duration}
end

local function buff(t, value, duration)
    return {Type = t, Value = value, Duration = duration}
end

local function dot(t, scale, duration)
    return {Type = t, Scale = scale, Duration = duration}
end

PetAbilities.Pets = {
    ["Wolf"] = {
        attack("Rending Bite", 1.45, 6, {Dot = dot("Bleed", 0.35, 5)}),
        utility("Pack Howl", 16, {
            Radius = 25,
            AllyAura = true,
            IncludeSelf = true,
            SelfScale = 0.50,
            Buffs = {
                buff("AttackHaste", 0.20, 8),
                buff("Power", 0.10, 8),
            },
        }),
        heal("Lick Wounds", 0.25, 18),
    },
    ["Boar"] = {
        attack("Tusk Gore", 1.50, 6),
        utility("Battering Tusks", 12, {Debuffs = {debuff("Sunder", 0.15, 6)}}),
        attack("Mudbreaker", 1.70, 16, {Debuffs = {debuff("Stun", 1, 1.0)}}),
    },
    ["Fox"] = {
        attack("Quick Pounce", 1.45, 5.5),
        utility("Trickster's Glare", 13, {Debuffs = {debuff("Blind", 0.80, 3)}}),
        attack("Foxfire Bite", 1.60, 15, {Dot = dot("Burn", 0.45, 5)}),
    },
    ["Hare"] = {
        attack("Spring Kick", 1.45, 5.5),
        utility("Rapid Heart", 14, {Buffs = {buff("AttackHaste", 0.30, 8)}}),
        heal("Burrow Breather", 0.25, 17),
    },
    ["Hedgehog"] = {
        attack("Needle Rush", 1.45, 6, {Dot = dot("Bleed", 0.30, 5)}),
        utility("Curl Up", 16, {
            Shield = {Percent = 0.25, Duration = 8, ReflectPercent = 0.30},
        }),
        attack("Quill Impale", 1.65, 15, {Debuffs = {debuff("Sunder", 0.15, 6)}}),
    },
    ["Moon Bat"] = {
        attack("Night Fang", 1.50, 6),
        utility("Sonic Confusion", 14, {Debuffs = {debuff("Blind", 0.80, 3)}}),
        attack("Blood Echo", 1.40, 16, {LifeStealPercent = 0.50}),
    },
    ["Raccoon"] = {
        attack("Scavenger Swipe", 1.45, 5.5),
        utility("Pocket Sand", 13, {Debuffs = {debuff("Blind", 0.80, 3)}}),
        attack("Trashcan Trick", 1.65, 15, {Debuffs = {debuff("Stun", 1, 1.0)}}),
    },
    ["Badger"] = {
        attack("Burrow Bash", 1.55, 6),
        utility("Relentless Claws", 14, {Buffs = {buff("AttackHaste", 0.25, 8)}}),
        heal("Settle In", 0.28, 18),
    },
    ["Opossum"] = {
        attack("Tail Lash", 1.40, 5.5),
        utility("Play Dead", 16, {
            AvoidNextAttack = true,
            Shield = {Percent = 0.20, Duration = 7},
        }),
        heal("Second Wind", 0.30, 18),
    },
    ["Field Mouse"] = {
        attack("Needle Bite", 1.35, 5),
        utility("Distracting Squeak", 13, {Debuffs = {debuff("Weaken", 0.15, 6)}}),
        utility("Swarm Instinct", 15, {Buffs = {buff("AttackHaste", 0.35, 8)}}),
    },

    ["River Otter"] = {
        attack("Current Bite", 1.50, 5.5),
        utility("Slippery Target", 13, {Debuffs = {debuff("Blind", 0.80, 3)}}),
        heal("River Mend", 0.28, 17, {Cleanse = "DoT"}),
    },
    ["Red Panda"] = {
        attack("Crimson Claw", 1.50, 6, {Dot = dot("Bleed", 0.35, 5)}),
        utility("Bark Strip", 12, {Debuffs = {debuff("Sunder", 0.12, 7)}}),
        heal("Bamboo Balm", 0.28, 18),
    },
    ["Mountain Goat"] = {
        attack("Cliff Charge", 1.60, 6),
        utility("Cracked Armour", 12, {Debuffs = {debuff("Sunder", 0.20, 6)}}),
        attack("Summit Smash", 1.75, 17, {Debuffs = {debuff("Stun", 1, 1.5)}}),
    },
    ["Lynx"] = {
        attack("Silent Pounce", 1.60, 6),
        utility("Snowstep", 13, {
            Dot = dot("Frostbite", 0.65, 6),
            Debuffs = {debuff("AttackSlow", 0.15, 6)},
        }),
        utility("Predator's Mark", 15, {Debuffs = {debuff("Expose", 0.15, 7)}}),
    },
    ["Peacock"] = {
        attack("Talon Pierce", 1.55, 6),
        utility("Dazzling Fan", 14, {Debuffs = {debuff("Blind", 0.80, 4)}}),
        utility("Royal Challenge", 15, {Debuffs = {debuff("Expose", 0.15, 7)}}),
    },
    ["Barn Owl"] = {
        attack("Silent Talons", 1.60, 6),
        utility("Hunter's Mark", 14, {Debuffs = {debuff("Expose", 0.12, 8)}}),
        utility("Nocturnal Focus", 17, {
            Radius = 30,
            AllyAura = true,
            IncludeSelf = true,
            SelfScale = 0.60,
            Buffs = {
                buff("AttackHaste", 0.25, 8),
                buff("Power", 0.12, 8),
            },
        }),
    },
    ["Porcupine"] = {
        attack("Quill Shot", 1.55, 6, {Dot = dot("Bleed", 0.40, 5)}),
        utility("Spined Guard", 16, {
            Guard = {DamageReductionPercent = 0.15, ReflectPercent = 0.25, Duration = 8},
        }),
        attack("Armour Piercer", 1.70, 15, {Debuffs = {debuff("Sunder", 0.20, 7)}}),
    },
    ["Pangolin"] = {
        attack("Rolling Strike", 1.55, 6),
        utility("Scale Fortress", 16, {Shield = {Percent = 0.30, Duration = 8}}),
        attack("Crushing Roll", 1.75, 15, {Debuffs = {debuff("Sunder", 0.20, 7)}}),
    },
    ["Lantern Gecko"] = {
        attack("Glowbite", 1.55, 6, {Dot = dot("Burn", 0.40, 5)}),
        utility("Sticky Resin", 14, {Debuffs = {debuff("AttackSlow", 0.25, 5)}}),
        heal("Glowmend", 0.30, 18),
    },
    ["Glow Beetle"] = {
        attack("Spark Ram", 1.55, 6),
        utility("Flashburst", 14, {Debuffs = {debuff("Blind", 0.80, 4)}}),
        utility("Static Brand", 15, {Debuffs = {debuff("Expose", 0.15, 7)}}),
    },

    ["Bear"] = {
        attack("Mauling Swipe", 1.70, 6),
        utility("Rend Armour", 13, {Debuffs = {debuff("Sunder", 0.22, 7)}}),
        attack("Skullbreaker", 1.90, 18, {Debuffs = {debuff("Stun", 1, 2.0)}}),
    },
    ["Thunder Ram"] = {
        attack("Storm Charge", 1.70, 6, {Dot = dot("Shock", 0.40, 5)}),
        utility("Static Wool", 16, {
            Guard = {DamageReductionPercent = 0.10, ReflectPercent = 0.30, Duration = 8},
        }),
        attack("Thunderclap Horns", 1.90, 18, {Debuffs = {debuff("Stun", 1, 2.0)}}),
    },
    ["Jade Tortoise"] = {
        attack("Tidal Snap", 1.65, 6),
        utility("Jade Bastion", 17, {Shield = {Percent = 0.35, Duration = 9}}),
        heal("Emerald Renewal", 0.40, 20),
    },
    ["Sunscale Raptor"] = {
        attack("Solar Talon", 1.70, 6, {Dot = dot("Burn", 0.50, 5)}),
        utility("Scorching Mark", 14, {Debuffs = {debuff("Sunder", 0.18, 7)}}),
        attack("Predatory Flare", 1.95, 17, {Debuffs = {debuff("Expose", 0.12, 6)}}),
    },
    ["Shadow Stag"] = {
        attack("Shadow Antler", 1.70, 6),
        utility("Veil of Dusk", 15, {Debuffs = {debuff("Blind", 0.80, 5)}}),
        attack("Moonlit Fracture", 1.90, 17, {Debuffs = {debuff("Sunder", 0.20, 7)}}),
    },
    ["Crystal Scorpion"] = {
        attack("Prism Sting", 1.70, 6, {Dot = dot("Poison", 0.55, 7)}),
        utility("Corrosive Venom", 14, {Debuffs = {debuff("Sunder", 0.22, 8)}}),
        attack("Crystal Spear", 1.95, 18, {Debuffs = {debuff("Stun", 1, 2.0)}}),
    },
    ["Moon Moth"] = {
        attack("Dreamsting", 1.60, 6, {Dot = dot("Dreamrot", 0.55, 6)}),
        utility("Lunar Powder", 15, {Debuffs = {debuff("Blind", 0.80, 5)}}),
        heal("Moonwing Mend", 0.32, 19, {Cleanse = "One"}),
    },
    ["Dusk Cobra"] = {
        attack("Venom Fang", 1.75, 6, {Dot = dot("Poison", 0.60, 7)}),
        utility("Constriction", 14, {Debuffs = {debuff("AttackSlow", 0.30, 6)}}),
        utility("Hypnotic Hood", 17, {
            Debuffs = {
                debuff("Blind", 0.80, 6),
                debuff("Expose", 0.10, 6),
            },
        }),
    },

    ["Griffin"] = {
        attack("Skyfall Talons", 1.80, 6),
        utility("Battle Screech", 15, {Buffs = {buff("AttackHaste", 0.30, 8)}}),
        attack("Armour Ripper", 2.05, 18, {Debuffs = {debuff("Sunder", 0.22, 8)}}),
    },
    ["Kirin"] = {
        attack("Sacred Hoof", 1.80, 6),
        utility("Blessed Presence", 18, {
            Radius = 32,
            AllyAura = true,
            IncludeSelf = true,
            SelfScale = 0.75,
            Buffs = {buff("DamageReduction", 0.20, 7)},
        }),
        heal("Fortune Chime", 0.35, 20, {Cleanse = "One"}),
    },
    ["Ember Salamander"] = {
        attack("Molten Bite", 1.75, 6, {Dot = dot("Burn", 0.55, 6)}),
        utility("Molten Skin", 17, {
            Guard = {DamageReductionPercent = 0.15, ReflectPercent = 0.35, Duration = 8},
        }),
        heal("Cinder Renewal", 0.35, 19),
    },
    ["Storm Roc"] = {
        attack("Tempest Talon", 1.85, 6, {Dot = dot("Shock", 0.50, 5)}),
        utility("Storm Eye", 15, {Debuffs = {debuff("Blind", 0.80, 5)}}),
        utility("Thunder Brand", 17, {Debuffs = {debuff("Expose", 0.18, 8)}}),
    },
    ["Manticore"] = {
        attack("Lion Maul", 1.85, 6),
        utility("Barbed Hide", 17, {
            Guard = {DamageReductionPercent = 0.12, ReflectPercent = 0.30, Duration = 8},
        }),
        attack("Venom Barb", 2.00, 18, {
            Dot = dot("Poison", 0.60, 7),
            Debuffs = {debuff("Sunder", 0.18, 7)},
        }),
    },
    ["Basilisk"] = {
        attack("Stonefang", 1.85, 6, {Dot = dot("Poison", 0.50, 7)}),
        utility("Petrifying Gaze", 18, {Debuffs = {debuff("Stun", 1, 2.5)}}),
        utility("Ancient Venom", 17, {
            Dot = dot("Poison", 0.85, 8),
            Debuffs = {debuff("Weaken", 0.20, 7)},
        }),
    },
    ["Nightmare Steed"] = {
        attack("Dread Hoof", 1.85, 6),
        utility("Terror Gaze", 16, {Debuffs = {debuff("Blind", 0.80, 6)}}),
        utility("Nightmare Brand", 17, {Debuffs = {debuff("Expose", 0.20, 8)}}),
    },
    ["Void Weaver"] = {
        attack("Voidbite", 1.80, 6, {LifeStealPercent = 0.25}),
        utility("Void Web", 15, {Debuffs = {debuff("AttackSlow", 0.35, 7)}}),
        attack("Essence Drain", 1.65, 18, {LifeStealPercent = 0.60}),
    },

    ["Phoenix"] = {
        attack("Solar Talon", 2.00, 6, {Dot = dot("Burn", 0.65, 6)}),
        utility("Ashen Curse", 16, {Debuffs = {debuff("Expose", 0.20, 8)}}),
        heal("Rebirth Flame", 0.45, 22, {Cleanse = "DoT"}),
    },
    ["Unicorn"] = {
        attack("Prismatic Charge", 1.95, 6),
        utility("Sanctuary Light", 19, {
            Radius = 34,
            AllyAura = true,
            IncludeSelf = true,
            SelfScale = 0.75,
            Buffs = {buff("DamageReduction", 0.25, 8)},
        }),
        heal("Purity Touch", 0.40, 21, {Cleanse = "All"}),
    },
    ["Celestial Lion"] = {
        attack("Starclaw", 2.00, 6),
        utility("Sovereign Roar", 19, {
            Radius = 35,
            AllyAura = true,
            IncludeSelf = true,
            SelfScale = 0.65,
            Buffs = {
                buff("AttackHaste", 0.25, 9),
                buff("Power", 0.15, 9),
            },
        }),
        attack("Celestial Judgment", 2.20, 19, {Debuffs = {debuff("Sunder", 0.25, 8)}}),
    },
    ["Cerberus"] = {
        attack("Threefold Bite", 2.00, 6),
        utility("Gatekeeper's Snarl", 16, {
            Debuffs = {
                debuff("Weaken", 0.25, 8),
                debuff("Sunder", 0.15, 8),
            },
        }),
        attack("Hellfang Execution", 2.20, 19, {Dot = dot("Burn", 0.65, 6)}),
    },
    ["Chimera"] = {
        attack("Triune Maul", 2.00, 6),
        utility("Serpent's Corrosion", 16, {
            Dot = dot("Poison", 0.50, 7),
            Debuffs = {debuff("Sunder", 0.20, 8)},
        }),
        utility("Bestial Frenzy", 20, {
            Radius = 35,
            AllyAura = true,
            IncludeSelf = true,
            SelfScale = 0.70,
            Buffs = {
                buff("AttackHaste", 0.30, 9),
                buff("Power", 0.10, 9),
            },
        }),
    },
    ["Abyss Hydra"] = {
        attack("Hydra Fang", 2.05, 6, {Dot = dot("Poison", 0.60, 7)}),
        utility("Many-Headed Fury", 16, {Buffs = {buff("AttackHaste", 0.40, 9)}}),
        heal("Abyssal Regrowth", 0.45, 22),
    },

    ["Solar Dragon"] = {
        attack("Sunfire Bite", 2.15, 6, {Dot = dot("Burn", 0.75, 7)}),
        utility("Solar Exposure", 17, {Debuffs = {debuff("Expose", 0.22, 9)}}),
        attack("Dragonfire Rupture", 2.35, 21, {Debuffs = {debuff("Stun", 1, 3.0)}}),
    },
    ["Worldroot Colossus"] = {
        attack("Rootcrusher", 2.10, 6),
        utility("Crushing Roots", 17, {Debuffs = {debuff("Sunder", 0.30, 9)}}),
        heal("Verdant Renewal", 0.45, 22),
    },
    ["Leviathan"] = {
        attack("Abyssal Bite", 2.15, 6),
        utility("Crushing Pressure", 17, {
            Debuffs = {
                debuff("AttackSlow", 0.35, 8),
                debuff("Sunder", 0.20, 8),
            },
        }),
        attack("Depthbreaker", 2.35, 21, {Debuffs = {debuff("Stun", 1, 3.0)}}),
    },
    ["Astral Serpent"] = {
        attack("Comet Fang", 2.10, 6),
        utility("Starblind", 17, {Debuffs = {debuff("Blind", 0.80, 7)}}),
        heal("Nebula Shedding", 0.38, 21, {Cleanse = "All"}),
    },

    ["Frostbell Reindeer"] = {
        attack("Frosthorn Charge", 2.05, 6, {Dot = dot("Frostbite", 0.65, 7)}),
        utility("Chilling Bells", 17, {Debuffs = {debuff("AttackSlow", 0.35, 8)}}),
        heal("Winter's Grace", 0.38, 21, {Cleanse = "One"}),
    },
    ["Pumpkin Imp"] = {
        attack("Trick-or-Claw", 2.05, 6, {Dot = dot("Burn", 0.60, 6)}),
        utility("Smoke Bomb", 17, {Debuffs = {debuff("Blind", 0.80, 7)}}),
        utility("Hexed Lantern", 18, {Debuffs = {debuff("Expose", 0.22, 8)}}),
    },
    ["Bloom Jackalope"] = {
        attack("Thornhorn Strike", 2.05, 6, {Dot = dot("Bleed", 0.60, 6)}),
        utility("Briar Curse", 17, {Debuffs = {debuff("Sunder", 0.25, 8)}}),
        heal("Spring Sap", 0.45, 22),
    },
    ["Starfall Starling"] = {
        attack("Meteor Peck", 2.10, 6),
        utility("Astral Chorus", 20, {
            Radius = 38,
            AllyAura = true,
            IncludeSelf = true,
            SelfScale = 0.70,
            Buffs = {buff("AttackHaste", 0.35, 9)},
        }),
        heal("Constellation Song", 0.40, 22, {Cleanse = "One"}),
    },

    ["Kraken"] = {
        attack("Tentacle Crush", 2.25, 6),
        utility("Crushing Grip", 18, {
            Debuffs = {
                debuff("Sunder", 0.30, 9),
                debuff("AttackSlow", 0.25, 9),
            },
        }),
        heal("Abyssal Renewal", 0.45, 23),
    },
    ["Jörmungandr"] = {
        attack("Worldcoil Crush", 2.35, 6),
        utility("Midgard Venom", 19, {
            Dot = dot("Poison", 0.90, 10),
            Debuffs = {debuff("Sunder", 0.30, 10)},
        }),
        utility("Ragnarok Scale", 22, {
            Guard = {DamageReductionPercent = 0.40, ReflectPercent = 0.45, Duration = 10},
        }),
    },
    ["Fenrir"] = {
        attack("Godfang Rend", 2.35, 6, {Dot = dot("Bleed", 0.90, 8)}),
        utility("Moon-Eater Howl", 21, {
            Radius = 42,
            AllyAura = true,
            IncludeSelf = true,
            SelfScale = 0.75,
            Buffs = {
                buff("AttackHaste", 0.45, 10),
                buff("Power", 0.25, 10),
            },
        }),
        attack("Gleipnir Break", 1.85, 20, {
            ExecuteDamageScale = 2.60,
            ExecuteHealthPercent = 0.30,
        }),
    },
    ["Gaia Titan"] = {
        attack("Continental Fist", 2.30, 6),
        utility("Tectonic Sunder", 20, {Debuffs = {debuff("Sunder", 0.35, 10)}}),
        attack("Worldbreaker", 2.50, 24, {Debuffs = {debuff("Stun", 1, 5.0)}}),
    },
}

-- Legacy names remain functional for older saved pets without returning to
-- the normal spawn pool.
PetAbilities.Pets.Dragon = PetAbilities.Pets["Solar Dragon"]
PetAbilities.Pets.Starling = PetAbilities.Pets["Starfall Starling"]
PetAbilities.Pets.AncientTitan = PetAbilities.Pets["Gaia Titan"]
PetAbilities.Pets.MoonBat = PetAbilities.Pets["Moon Bat"]
PetAbilities.Pets.ShadowStag = PetAbilities.Pets["Shadow Stag"]
PetAbilities.Pets.Nightfang = PetAbilities.Pets.Wolf
PetAbilities.Pets.Dusktail = PetAbilities.Pets.Fox
PetAbilities.Pets.EclipseGriffin = PetAbilities.Pets.Griffin
PetAbilities.Pets.VoidDragon = PetAbilities.Pets["Solar Dragon"]
PetAbilities.Pets.AbyssLeviathan = PetAbilities.Pets.Leviathan
PetAbilities.Pets.AstralStarling = PetAbilities.Pets["Starfall Starling"]
PetAbilities.Pets.ObsidianTitan = PetAbilities.Pets["Gaia Titan"]

local function percent(value)
    return tostring(math.floor((tonumber(value) or 0) * 100 + 0.5)) .. "%"
end

local function duration(value)
    local seconds = tonumber(value) or 0
    if seconds == math.floor(seconds) then
        return tostring(math.floor(seconds)) .. "s"
    end
    return string.format("%.1fs", seconds)
end

function PetAbilities:Get(species)
    return self.Pets[species]
end

function PetAbilities:GetDescription(info)
    if type(info) ~= "table" then return "" end

    local parts = {}

    if info.DamageScale then
        local scale = info.DamageScale
        if info.ExecuteDamageScale then
            table.insert(
                parts,
                percent(scale) .. " Power damage; becomes "
                    .. percent(info.ExecuteDamageScale)
                    .. " below "
                    .. percent(info.ExecuteHealthPercent)
                    .. " enemy HP"
            )
        else
            table.insert(parts, percent(scale) .. " Power damage")
        end
    end

    if info.Dot then
        table.insert(
            parts,
            tostring(info.Dot.Type)
                .. " for "
                .. percent(info.Dot.Scale)
                .. " Power over "
                .. duration(info.Dot.Duration)
        )
    end

    for _, effect in ipairs(info.Debuffs or {}) do
        if effect.Type == "Stun" then
            table.insert(parts, "stuns for " .. duration(effect.Duration))
        elseif effect.Type == "Blind" then
            table.insert(parts, "80% miss chance for " .. duration(effect.Duration))
        elseif effect.Type == "Sunder" then
            table.insert(parts, "-" .. percent(effect.Value) .. " enemy Defence for " .. duration(effect.Duration))
        elseif effect.Type == "Expose" then
            table.insert(parts, "+" .. percent(effect.Value) .. " damage taken for " .. duration(effect.Duration))
        elseif effect.Type == "Weaken" then
            table.insert(parts, "-" .. percent(effect.Value) .. " enemy damage for " .. duration(effect.Duration))
        elseif effect.Type == "AttackSlow" then
            table.insert(parts, "-" .. percent(effect.Value) .. " enemy attack speed for " .. duration(effect.Duration))
        elseif effect.Type == "Root" then
            table.insert(parts, "roots for " .. duration(effect.Duration))
        end
    end

    if info.AllyAura then
        local aura = {}
        for _, effect in ipairs(info.Buffs or {}) do
            if effect.Type == "AttackHaste" then
                table.insert(aura, "+" .. percent(effect.Value) .. " Attack Haste")
            elseif effect.Type == "Power" then
                table.insert(aura, "+" .. percent(effect.Value) .. " Power")
            elseif effect.Type == "DamageReduction" then
                table.insert(aura, percent(effect.Value) .. " damage reduction")
            end
        end
        if #aura > 0 then
            table.insert(
                parts,
                table.concat(aura, " and ")
                    .. " to allied pets within "
                    .. tostring(info.Radius or 25)
                    .. " studs"
            )
        end
    elseif info.Buffs then
        for _, effect in ipairs(info.Buffs) do
            if effect.Type == "AttackHaste" then
                table.insert(parts, "+" .. percent(effect.Value) .. " Attack Haste for " .. duration(effect.Duration))
            elseif effect.Type == "Power" then
                table.insert(parts, "+" .. percent(effect.Value) .. " Power for " .. duration(effect.Duration))
            elseif effect.Type == "DamageReduction" then
                table.insert(parts, percent(effect.Value) .. " damage reduction for " .. duration(effect.Duration))
            end
        end
    end

    if info.Shield then
        local text = "shield for " .. percent(info.Shield.Percent) .. " max HP"
        if (tonumber(info.Shield.ReflectPercent) or 0) > 0 then
            text ..= " and reflects " .. percent(info.Shield.ReflectPercent) .. " absorbed damage"
        end
        table.insert(parts, text .. " for " .. duration(info.Shield.Duration))
    end

    if info.Guard then
        local guard = {}
        if (tonumber(info.Guard.DamageReductionPercent) or 0) > 0 then
            table.insert(guard, percent(info.Guard.DamageReductionPercent) .. " damage reduction")
        end
        if (tonumber(info.Guard.ReflectPercent) or 0) > 0 then
            table.insert(guard, percent(info.Guard.ReflectPercent) .. " reflect")
        end
        if #guard > 0 then
            table.insert(parts, table.concat(guard, " + ") .. " for " .. duration(info.Guard.Duration))
        end
    end

    if info.AvoidNextAttack then
        table.insert(parts, "the next enemy attack misses")
    end

    if info.HealPercent then
        table.insert(parts, "heals " .. percent(info.HealPercent) .. " max HP")
    end

    if info.Cleanse then
        table.insert(parts, info.Cleanse == "All" and "cleanses all harmful effects" or "cleanses a harmful effect")
    end

    if info.LifeStealPercent then
        table.insert(parts, "heals for " .. percent(info.LifeStealPercent) .. " of damage dealt")
    end

    if #parts == 0 then
        return "Unique companion ability."
    end

    return table.concat(parts, " · ")
end

return PetAbilities
