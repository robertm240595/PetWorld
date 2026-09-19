local QuestConfig = {}

QuestConfig.ObjectiveTypes = {
    Talk = "TALK",
    CaptureReturn = "CAPTURE & RETURN",
    Kill = "KILL",
    InspectPet = "SHOW PET",
    ItemTurnIn = "ITEM TURN-IN",
}

QuestConfig.LassoTiers = {
    Starter = {Strength = 0, Name = "Rough Rope"},
    Uncommon = {Strength = 25, Name = "Hunter's Lasso"},
    Rare = {Strength = 45, Name = "Iron Lasso"},
    Epic = {Strength = 65, Name = "Steel Lasso"},
    Legendary = {Strength = 80, Name = "Mystic Lasso"},
    Mythic = {Strength = 95, Name = "Mystic Lasso"},
    Ancient = {Strength = 125, Name = "Ancient Lasso"},
}

QuestConfig.World = {
    CaveXZ = Vector2.new(390, -390),
    CaveFallbackY = 17,
    NPCs = {
        Rowan = {Name = "Warden Rowan", XZ = Vector2.new(8, -18), Shirt = Color3.fromRGB(82,94,72), Accent = Color3.fromRGB(137,119,76)},
        Bram = {Name = "Quartermaster Bram", XZ = Vector2.new(-18, -10), Shirt = Color3.fromRGB(87,77,65), Accent = Color3.fromRGB(146,119,78)},
        Elara = {Name = "Astronomer Elara", XZ = Vector2.new(22, -7), Shirt = Color3.fromRGB(61,69,111), Accent = Color3.fromRGB(128,121,190)},
        Holt = {Name = "Trapper Holt", XZ = Vector2.new(-24, 10), Shirt = Color3.fromRGB(83,73,58), Accent = Color3.fromRGB(142,106,66)},
        Orin = {Name = "Sage Orin", XZ = Vector2.new(25, 12), Shirt = Color3.fromRGB(72,84,79), Accent = Color3.fromRGB(100,162,137)},
        Rook = {Name = "Captain Rook", XZ = Vector2.new(-6, 23), Shirt = Color3.fromRGB(69,76,86), Accent = Color3.fromRGB(136,146,157)},
        Vale = {Name = "Historian Vale", XZ = Vector2.new(13, 27), Shirt = Color3.fromRGB(94,72,93), Accent = Color3.fromRGB(163,119,160)},
    },
}

-- All chains except the starter tutorial require StarterWolves to be complete.
-- RequiredStrength is checked against the strongest lasso the player OWNS, not
-- merely the currently equipped lasso.
QuestConfig.Chains = {
    StarterWolves = {
        Id = "StarterWolves",
        Name = "A Better Answer",
        NPC = "Rowan",
        RequiredStrength = 0,
        Priority = 1,
        Intro = "Welcome to the village. Before you head too far into the wilds, I need your help with a problem close to home. Wolf packs have been pushed toward the roads and have started raiding supply carts. I won't order a cull if we can solve it another way. Capture five Wolves alive and bring them back to me. We'll relocate the pack and train the calmer animals as road sentries.",
        AcceptText = "Bring me five healthy Wolves. Keep any favourite or active companions out of the hand-in; I won't take a beast you mean to keep.",
        CompleteText = "Excellent work. Five animals moved without needless bloodshed, and the road crews will have new sentries once they're settled.",
        Reward = {Coins = 750, Gems = 0},
        Stages = {
            {
                Id = "ReturnWolves",
                Type = "CaptureReturn",
                Species = "Wolf",
                Required = 5,
                Objective = "Capture and return 5 Wolves to Warden Rowan.",
                Detail = "Healthy, unfavourited Wolves free in your backpack count toward the hand-in.",
            },
        },
    },

    CaravanTrouble = {
        Id = "CaravanTrouble",
        Name = "The Lost Caravan",
        NPC = "Bram",
        RequiredStrength = 0,
        Priority = 2,
        Prerequisite = "StarterWolves",
        Intro = "Rowan says you can handle yourself. Good. One of my supply caravans limped home with half its crates missing. Boars scattered the team on the south road, and Raccoons have been carrying off anything they can drag. Clear the route so I can send a recovery cart.",
        CompleteText = "That's the road open again. You've saved me more supplies than you know.",
        Reward = {Coins = 1200, Gems = 0},
        Stages = {
            {Id="Boars", Type="Kill", Species="Boar", Required=5, Objective="Defeat 5 Boars threatening the caravan route.", Detail="Any wild Boar defeated by your companion counts."},
            {Id="Raccoons", Type="Kill", Species="Raccoon", Required=3, Objective="Defeat 3 Raccoons stealing the scattered supplies.", Detail="Raccoons appear at night."},
            {Id="Report", Type="Talk", Objective="Report back to Quartermaster Bram.", Detail="The road is clear. Return to the village."},
        },
    },

    MoonlightProblems = {
        Id = "MoonlightProblems",
        Name = "Moonlight Problems",
        NPC = "Elara",
        RequiredStrength = 25,
        RequiredLasso = "Hunter's Lasso",
        Priority = 10,
        Prerequisite = "StarterWolves",
        Intro = "The night sky has been strange, and the animals are reacting before my instruments do. I need living Moon Bats to compare their behaviour, then I need you to quiet the Barn Owls circling my observation posts.",
        CompleteText = "The readings match the animals' behaviour exactly. Something is shifting after sunset.",
        Reward = {Coins = 4000, Gems = 5},
        Stages = {
            {Id="MoonBats", Type="CaptureReturn", Species="Moon Bat", Required=3, Objective="Capture and return 3 Moon Bats to Astronomer Elara.", Detail="Moon Bats are active at night."},
            {Id="BarnOwls", Type="Kill", Species="Barn Owl", Required=3, Objective="Defeat 3 Barn Owls around the night wilderness.", Detail="Barn Owls are Uncommon nocturnal creatures."},
            {Id="Report", Type="Talk", Objective="Return to Astronomer Elara with your findings."},
        },
    },

    MissingTrapper = {
        Id = "MissingTrapper",
        Name = "The Missing Trapper",
        NPC = "Holt",
        RequiredStrength = 25,
        RequiredLasso = "Hunter's Lasso",
        Priority = 11,
        Prerequisite = "StarterWolves",
        Intro = "A trapper from my crew missed two check-ins. His last note said Lynx were stalking the ridge and making it impossible to move safely. Capture three alive for relocation. If they're removed from the trail, my people can search the ridge without starting another fight.",
        CompleteText = "Good. With those Lynx off the ridge, my search team can move. I'll take it from here.",
        Reward = {Coins = 5000, Gems = 5},
        Stages = {
            {Id="Lynx", Type="CaptureReturn", Species="Lynx", Required=3, Objective="Capture and return 3 Lynx to Trapper Holt.", Detail="Lynx are Uncommon. Hunter's Lasso or better is required."},
        },
    },

    ImprintersSecret = {
        Id = "ImprintersSecret",
        Name = "The Imprinter's Secret",
        NPC = "Orin",
        RequiredStrength = 25,
        RequiredLasso = "Hunter's Lasso",
        Priority = 12,
        Prerequisite = "StarterWolves",
        Intro = "A capture is only the beginning of a bond. Bring me a beast with a strong imprint and I'll show you what that number really means.",
        CompleteText = "Now you understand: two beasts of the same species can have very different potential. Watch the bond, not only the rarity.",
        Reward = {Coins = 6000, Gems = 10},
        Stages = {
            {Id="Imprint50", Type="InspectPet", MinimumImprint=50, Required=1, Objective="Show Sage Orin any pet with at least 50% imprint.", Detail="You keep the pet; Orin only inspects it."},
            {Id="Imprint70", Type="InspectPet", MinimumImprint=70, Required=1, Objective="Show Sage Orin any pet with at least 70% imprint.", Detail="Higher imprint means stronger base stats."},
        },
    },

    HollowfangRescue = {
        Id = "HollowfangRescue",
        Name = "The Hollowfang Report",
        NPC = "Rowan",
        RequiredStrength = 45,
        RequiredLasso = "Iron Lasso",
        Priority = 20,
        Prerequisite = "StarterWolves",
        Special = "Hollowfang",
        Intro = "I have another urgent report. Scout Mira went northeast to Hollowfang Cave to investigate frightened wildlife and never returned. Three Bears have the entrance blocked. Take your best beast and save Scout Mira!",
        CompleteText = "Mira's findings confirm this is bigger than a few frightened Bears. I'll send word to the outer posts and keep Hollowfang under watch.",
        Reward = {Coins = 7500, Gems = 10},
        Stages = {
            {Id="Bears", Type="Kill", Species="Bear", Required=3, Objective="Defeat the 3 Hollowfang Bears outside the cave.", Detail="Follow the quest marker northeast to Hollowfang Cave."},
            {Id="FindMira", Type="Talk", Objective="Speak to Scout Mira outside Hollowfang Cave.", Detail="The entrance is clear. Find out what Mira discovered."},
            {Id="ReportRowan", Type="Talk", Objective="Report Scout Mira's findings to Warden Rowan.", Detail="Mira saw signs that something deeper in the cave frightened the Bears."},
        },
    },

    ChampionWilds = {
        Id = "ChampionWilds",
        Name = "Champion of the Wilds",
        NPC = "Rook",
        RequiredStrength = 45,
        RequiredLasso = "Iron Lasso",
        Priority = 21,
        Prerequisite = "StarterWolves",
        Intro = "A strong lasso tells me you've reached dangerous country. Now I want to know whether your companion can survive it. Prove your team can handle escalating threats without folding.",
        CompleteText = "That's the standard I expect from a field team. You and your beast can handle the dangerous routes now.",
        Reward = {Coins = 15000, Gems = 20},
        Stages = {
            {Id="CommonKills", Type="Kill", Rarity="Common", Required=5, Objective="Defeat 5 Common wild pets with your companion."},
            {Id="UncommonKills", Type="Kill", Rarity="Uncommon", Required=3, Objective="Defeat 3 Uncommon wild pets with your companion."},
            {Id="RareKill", Type="Kill", Rarity="Rare", Required=1, Objective="Defeat 1 Rare wild pet with your companion."},
            {Id="Report", Type="Talk", Objective="Report your victories to Captain Rook."},
        },
    },

    RarityArchive = {
        Id = "RarityArchive",
        Name = "A Creature Worthy of Legend",
        NPC = "Vale",
        RequiredStrength = 45,
        RequiredLasso = "Iron Lasso",
        Priority = 22,
        Prerequisite = "StarterWolves",
        Intro = "My archive is full of sketches copied from hunters who exaggerate everything. I want records from a real handler. Show me living examples as your equipment improves; you keep every creature.",
        CompleteText = "At last, records I can trust. The archive will carry your name beside these entries.",
        Reward = {Coins = 35000, Gems = 40},
        Stages = {
            {Id="Rare", Type="InspectPet", Rarity="Rare", Required=1, RequiredStrength=45, Objective="Show Historian Vale any Rare pet.", Detail="Iron Lasso or better is required to reach this stage."},
            {Id="Epic", Type="InspectPet", Rarity="Epic", Required=1, RequiredStrength=65, Objective="Show Historian Vale any Epic pet.", Detail="This chapter unlocks when you own a Steel Lasso or better."},
            {Id="Legendary", Type="InspectPet", Rarity="Legendary", Required=1, RequiredStrength=80, Objective="Show Historian Vale any Legendary pet.", Detail="This chapter unlocks when you own a Mystic Lasso or better."},
        },
    },

    HollowfangMystery = {
        Id = "HollowfangMystery",
        Name = "Beneath Hollowfang",
        NPC = "Rowan",
        RequiredStrength = 65,
        RequiredLasso = "Steel Lasso",
        Priority = 30,
        Prerequisite = "HollowfangRescue",
        Intro = "Mira's report has been bothering me. The Bears weren't hunting her; they were fleeing deeper tunnels. If you're willing, go back into dangerous country and hunt the creatures gathering around Hollowfang. I want to know whether the disturbance is spreading.",
        CompleteText = "Dusk Cobras and Void Weavers together near Hollowfang is no coincidence. Whatever is below that cave is changing the whole area. We'll need a larger expedition later.",
        Reward = {Coins = 50000, Gems = 60},
        Stages = {
            {Id="Cobras", Type="Kill", Species="Dusk Cobra", Required=3, Objective="Defeat 3 Dusk Cobras while investigating the Hollowfang disturbance."},
            {Id="Weavers", Type="Kill", Species="Void Weaver", Required=2, RequiredStrength=65, Objective="Defeat 2 Void Weavers linked to the Hollowfang disturbance."},
            {Id="Report", Type="Talk", Objective="Report the Hollowfang evidence to Warden Rowan."},
        },
    },
}

QuestConfig.NPCOrder = {"Rowan","Bram","Elara","Holt","Orin","Rook","Vale"}

return QuestConfig
