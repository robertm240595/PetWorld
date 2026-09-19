local QuestConfig = {}

QuestConfig.ObjectiveTypes = {
    Talk = "TALK",
    CaptureReturn = "CAPTURE & RETURN",
    Kill = "KILL",
    InspectPet = "SHOW PET",
    Action = "GAMEPLAY TASK",
    ItemTurnIn = "ITEM TURN-IN",
    MultiItemTurnIn = "MATERIAL TURN-IN",
    Spar = "CHALLENGE",
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
    LeatherTraderXZ = Vector2.new(-235, 165),
    NPCs = {
        Rowan = {Name = "Warden Rowan", XZ = Vector2.new(8, -18), Shirt = Color3.fromRGB(82,94,72), Accent = Color3.fromRGB(137,119,76)},
        Bram = {Name = "Quartermaster Bram", XZ = Vector2.new(-18, -10), Shirt = Color3.fromRGB(87,77,65), Accent = Color3.fromRGB(146,119,78)},
        Anya = {Name = "Beast Healer Anya", XZ = Vector2.new(-28, -4), Shirt = Color3.fromRGB(92,111,91), Accent = Color3.fromRGB(174,188,142)},
        Elara = {Name = "Astronomer Elara", XZ = Vector2.new(22, -7), Shirt = Color3.fromRGB(61,69,111), Accent = Color3.fromRGB(128,121,190)},
        Holt = {Name = "Trapper Holt", XZ = Vector2.new(-24, 10), Shirt = Color3.fromRGB(83,73,58), Accent = Color3.fromRGB(142,106,66)},
        Orin = {Name = "Sage Orin", XZ = Vector2.new(25, 12), Shirt = Color3.fromRGB(72,84,79), Accent = Color3.fromRGB(100,162,137)},
        Rook = {Name = "Captain Rook", XZ = Vector2.new(-6, 23), Shirt = Color3.fromRGB(69,76,86), Accent = Color3.fromRGB(136,146,157)},
        Vale = {Name = "Historian Vale", XZ = Vector2.new(13, 27), Shirt = Color3.fromRGB(94,72,93), Accent = Color3.fromRGB(163,119,160)},
    },
}

-- StarterWolves leads directly into BeastHandlingTutorial. All other village
-- chains are globally hidden until BeastHandlingTutorial is complete.
-- RequiredStrength uses the highest lasso tier ever acquired, so unlocked
-- quest tiers remain available even if a lasso is later sold.
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

    BeastHandlingTutorial = {
        Id = "BeastHandlingTutorial",
        Name = "Your First Companion",
        NPC = "Rowan",
        RequiredStrength = 0,
        Priority = 2,
        Prerequisite = "StarterWolves",
        TutorialGate = true,
        Intro = "Those Wolves proved you can use a lasso. Now you need to learn how to raise a beast of your own. Capture any wild beast you want to keep. I'll walk you through equipping it, naming it, fighting with it, improving it, and caring for it when a battle goes wrong.",
        CompleteText = "Now you're ready to work without me looking over your shoulder. The rest of the village has heard what you can do, and you'll find several people ready to offer you work.",
        Reward = {Coins = 2000, Gems = 0},
        Stages = {
            {Id="CaptureCompanion", Type="Action", Action="CapturePet", Required=1, Objective="Capture any wild beast to become your first companion.", Detail="Use your lasso on any accessible wild pet you want to keep."},
            {Id="EquipCompanion", Type="Action", Action="EquipPet", Required=1, Objective="Equip the beast you just captured.", Detail="Open your Backpack, select the captured beast, and equip it."},
            {Id="RenameCompanion", Type="Action", Action="RenamePet", Required=1, Objective="Give your new companion a name.", Detail="The Backpack will open and highlight the rename controls. The first rename is free."},
            {Id="FirstVictories", Type="Kill", Required=3, TutorialPetOnly=true, Objective="Use your named companion to defeat 3 wild pets.", Detail="Command your companion to attack wild creatures. Your tutorial companion must land the victories."},
            {Id="UpgradeCompanion", Type="Action", Action="UpgradePet", Required=1, Objective="Spend an upgrade point on your companion.", Detail="Rowan grants one tutorial upgrade point. The Backpack will highlight the stat upgrade buttons."},
            {Id="RowanChallenge", Type="Spar", Required=1, Objective="Defeat Rowan's veteran Wolf.", Detail="Rowan presents this as your final combat test. Command your companion to attack his veteran Wolf."},
            {Id="StartHealing", Type="Action", Action="StartHealing", Required=1, Objective="Place your defeated companion into your Pet Barn.", Detail="Rowan's lesson was deliberate: defeated pets must be healed at the Barn on your plot."},
            {Id="CollectHealing", Type="Action", Action="CollectHealed", Required=1, Objective="Wait for the healing timer, then collect your companion.", Detail="Barn healing continues in real time. Return when the timer reaches zero."},
            {Id="Report", Type="Talk", Objective="Return to Warden Rowan after your companion recovers.", Detail="Report back to finish the handling tutorial and unlock the village quest roster."},
        },
    },

    BiggerBag = {
        Id = "BiggerBag",
        Name = "We're Gonna Need a Bigger Bag",
        NPC = "Rowan",
        RequiredStrength = 0,
        Priority = 3,
        Prerequisite = "BeastHandlingTutorial",
        Special = "LeatherTrader",
        Intro = "You're ready for real field work now, but that little starter bag won't last long once you begin bringing back hides, claws and other useful materials. There's a leatherworker named Corvin living out in the western forest. Find his hut and tell him I sent you. If you can prove you're bringing useful materials home, he may be willing to make you something larger.",
        CompleteText = "Corvin works quietly, but nobody in the region makes stronger field gear. That new satchel should give you room to carry proper expedition supplies.",
        Reward = {Coins = 0, Gems = 0, Backpack = "Leather Satchel", Capacity = 30},
        Stages = {
            {
                Id = "FindTrader",
                Type = "Talk",
                Objective = "Find Leather Trader Corvin at his hut in the western forest.",
                Detail = "Follow the compass into the wild. Corvin lives outside the village beside a camp fire and tanning racks.",
            },
            {
                Id = "GatherHides",
                Type = "MultiItemTurnIn",
                Requirements = {
                    {Item = "Wolf Hide", Required = 2, SourceSpecies = "Wolf"},
                    {Item = "Hare Pelt", Required = 2, SourceSpecies = "Hare"},
                    {Item = "Coarse Boar Hide", Required = 2, SourceSpecies = "Boar"},
                },
                Objective = "Collect Common-pet hides and pelts for Corvin.",
                Detail = "Bring Corvin 2 Wolf Hides, 2 Hare Pelts and 2 Coarse Boar Hides from wild-pet loot bags.",
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
            {Id="BoarTusks", Type="ItemTurnIn", Item="Boar Tusk", SourceSpecies="Boar", Required=3, Objective="Collect 3 Boar Tusks from Boar loot bags.", Detail="Open the loot bags dropped by defeated Boars, collect the materials, then bring the tusks to Bram."},
            {Id="Raccoons", Type="Kill", Species="Raccoon", Required=3, Objective="Defeat 3 Raccoons stealing the scattered supplies.", Detail="Raccoons appear at night."},
            {Id="RaccoonPelts", Type="ItemTurnIn", Item="Raccoon Pelt", SourceSpecies="Raccoon", Required=2, Objective="Collect 2 Raccoon Pelts from Raccoon loot bags.", Detail="The pelts prove which animals were raiding the lost cargo."},
            {Id="Report", Type="Talk", Objective="Report back to Quartermaster Bram.", Detail="The road is clear. Return to the village."},
        },
    },

    BarnLesson = {
        Id = "BarnLesson",
        Name = "Care for the Fallen",
        NPC = "Anya",
        RequiredStrength = 0,
        Priority = 3,
        Prerequisite = "StarterWolves",
        Intro = "A good handler learns what to do when a companion falls. I don't want you discovering the Barn while panicking after a hard fight. When one of your pets is defeated, place it in your Pet Barn, let the healing finish, then collect it again.",
        CompleteText = "That's how you keep a beast safe after a hard battle. A strong team is one you know how to bring home.",
        Reward = {Coins = 2500, Gems = 0},
        Stages = {
            {Id="StartHealing", Type="Action", Action="StartHealing", Required=1, Objective="Place a defeated pet into your Pet Barn to begin healing.", Detail="A pet must be defeated before it can be placed in the Barn."},
            {Id="CollectHealing", Type="Action", Action="CollectHealed", Required=1, Objective="Wait for the Barn timer, then collect the healed pet.", Detail="The timer continues in real time."},
            {Id="Report", Type="Talk", Objective="Tell Beast Healer Anya the pet recovered safely."},
        },
    },

    MarketLessons = {
        Id = "MarketLessons",
        Name = "Know the Price",
        NPC = "Bram",
        RequiredStrength = 0,
        Priority = 4,
        Prerequisite = "CaravanTrouble",
        Intro = "Before you start funding expensive expeditions, learn how the animal market really works. Sell one non-favourite pet to the Beast Trader, then buy that same pet back. You'll see why a careless sale costs more to undo.",
        CompleteText = "Now you know the rule: selling is easy, changing your mind is expensive. Favourite anything you never want leaving your backpack.",
        Reward = {Coins = 3000, Gems = 0},
        Stages = {
            {Id="SellPet", Type="Action", Action="SellPet", Required=1, Objective="Sell 1 non-favourite pet to the Beast Trader.", Detail="Favourited pets are protected from selling."},
            {Id="BuybackPet", Type="Action", Action="BuybackPet", Required=1, Objective="Buy a pet back from the Beast Trader.", Detail="Buyback costs more than the original sale value."},
            {Id="Report", Type="Talk", Objective="Report back to Quartermaster Bram."},
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
            {Id="OwlFeathers", Type="ItemTurnIn", Item="Owl Feather", SourceSpecies="Barn Owl", Required=2, Objective="Collect 2 Owl Feathers from Barn Owl loot bags.", Detail="Elara wants the feathers to compare their strange night-time condition."},
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
        Prerequisite = "BiggerBag",
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

    RarityArchiveRare = {
        Id = "RarityArchiveRare",
        Name = "A Creature Worthy of Record",
        NPC = "Vale",
        RequiredStrength = 45,
        RequiredLasso = "Iron Lasso",
        Priority = 22,
        Prerequisite = "StarterWolves",
        Intro = "My archive is full of sketches copied from hunters who exaggerate everything. Show me a living Rare creature and I'll begin a proper field record. You keep the animal; I only need to study it.",
        CompleteText = "At last, a Rare specimen documented by a real handler. Come back when your lasso is strong enough for even greater creatures.",
        Reward = {Coins = 8000, Gems = 10},
        Stages = {
            {Id="Rare", Type="InspectPet", Rarity="Rare", Required=1, Objective="Show Historian Vale any Rare pet.", Detail="You keep the pet; Vale only inspects it."},
        },
    },

    RarityArchiveEpic = {
        Id = "RarityArchiveEpic",
        Name = "Beyond the Rare",
        NPC = "Vale",
        RequiredStrength = 65,
        RequiredLasso = "Steel Lasso",
        Priority = 31,
        Prerequisite = "RarityArchiveRare",
        Intro = "You've reached equipment I rarely see outside veteran expeditions. Bring me a living Epic creature and we'll add a new chapter to the archive.",
        CompleteText = "An Epic specimen, properly recorded. The archive is becoming something hunters will actually be able to trust.",
        Reward = {Coins = 18000, Gems = 25},
        Stages = {
            {Id="Epic", Type="InspectPet", Rarity="Epic", Required=1, Objective="Show Historian Vale any Epic pet.", Detail="Steel Lasso or better is required for Epic captures."},
        },
    },

    RarityArchiveLegendary = {
        Id = "RarityArchiveLegendary",
        Name = "A Living Legend",
        NPC = "Vale",
        RequiredStrength = 80,
        RequiredLasso = "Mystic Lasso",
        Priority = 40,
        Prerequisite = "RarityArchiveEpic",
        Intro = "This is the page I never expected to fill. If you truly command a Mystic Lasso, show me a living Legendary creature.",
        CompleteText = "A living legend, documented without rumour or exaggeration. Your name is going on the first page of this record.",
        Reward = {Coins = 50000, Gems = 75},
        Stages = {
            {Id="Legendary", Type="InspectPet", Rarity="Legendary", Required=1, Objective="Show Historian Vale any Legendary pet.", Detail="Mystic Lasso or better is required for Legendary captures."},
        },
    },

    RarityArchiveMythic = {
        Id = "RarityArchiveMythic",
        Name = "Beyond Legend",
        NPC = "Vale",
        RequiredStrength = 95,
        RequiredLasso = "Mystic Lasso",
        Priority = 41,
        Prerequisite = "RarityArchiveLegendary",
        Intro = "There is one final wilderness record I want before we start talking about creatures that belong to world-boss stories. Show me a living Mythic pet.",
        CompleteText = "A Mythic creature, alive and documented. Anything beyond this belongs to legends of world bosses and events — and we're not ready to write that chapter yet.",
        Reward = {Coins = 100000, Gems = 150},
        Stages = {
            {Id="Mythic", Type="InspectPet", Rarity="Mythic", Required=1, Objective="Show Historian Vale any Mythic pet.", Detail="Mystic Lasso is strong enough for Mythic captures."},
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
            {Id="DuskFangs", Type="ItemTurnIn", Item="Dusk Fang", SourceSpecies="Dusk Cobra", Required=2, Objective="Collect 2 Dusk Fangs from Dusk Cobra loot bags.", Detail="Rowan needs physical evidence that the cave disturbance is affecting Dusk Cobras."},
            {Id="Weavers", Type="Kill", Species="Void Weaver", Required=2, RequiredStrength=65, Objective="Defeat 2 Void Weavers linked to the Hollowfang disturbance."},
            {Id="VoidSilk", Type="ItemTurnIn", Item="Void Silk", SourceSpecies="Void Weaver", Required=1, Objective="Collect 1 Void Silk from a Void Weaver loot bag.", Detail="The silk is the final proof Rowan needs from the Hollowfang area."},
            {Id="Report", Type="Talk", Objective="Report the Hollowfang evidence to Warden Rowan."},
        },
    },
}

QuestConfig.NPCOrder = {"Rowan","Bram","Anya","Elara","Holt","Orin","Rook","Vale"}

return QuestConfig
