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
    LootTraderXZ = Vector2.new(39, -2),
    MountQuestXZ = Vector2.new(250, 95),

    -- Boss-travel landmarks remain in the same Roblox place. The arenas are
    -- deliberately far outside the normal wilderness so they cannot be seen
    -- from the main map.
    WorldBossWaterfallXZ = Vector2.new(545, -535),
    WyrmArenaCenter = Vector3.new(0, 140, 12000),
    WorldBossArenaCenter = Vector3.new(15000, 190, -15000),

    NPCs = {
        Rowan = {Name = "Warden Rowan", XZ = Vector2.new(8, -18), Shirt = Color3.fromRGB(82,94,72), Accent = Color3.fromRGB(137,119,76)},
        Bram = {Name = "Quartermaster Bram", XZ = Vector2.new(-18, -10), Shirt = Color3.fromRGB(87,77,65), Accent = Color3.fromRGB(146,119,78)},
        Anya = {Name = "Beast Healer Anya", XZ = Vector2.new(-28, -4), Shirt = Color3.fromRGB(92,111,91), Accent = Color3.fromRGB(174,188,142)},
        Elara = {Name = "Astronomer Elara", XZ = Vector2.new(22, -7), Shirt = Color3.fromRGB(61,69,111), Accent = Color3.fromRGB(128,121,190)},
        Holt = {Name = "Trapper Holt", XZ = Vector2.new(-24, 10), Shirt = Color3.fromRGB(83,73,58), Accent = Color3.fromRGB(142,106,66)},
        Orin = {Name = "Sage Orin", XZ = Vector2.new(25, 12), Shirt = Color3.fromRGB(72,84,79), Accent = Color3.fromRGB(100,162,137)},
        Rook = {Name = "Captain Rook", XZ = Vector2.new(-6, 23), Shirt = Color3.fromRGB(69,76,86), Accent = Color3.fromRGB(136,146,157)},
        Vale = {Name = "Historian Vale", XZ = Vector2.new(13, 27), Shirt = Color3.fromRGB(94,72,93), Accent = Color3.fromRGB(163,119,160)},
        Maeve = {Name = "Stablemaster Maeve", XZ = Vector2.new(31, 18), Shirt = Color3.fromRGB(103,78,57), Accent = Color3.fromRGB(198,151,88)},
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
            {Id="CaptureCompanion", Type="Action", Action="CapturePet", Rarity="Common", Required=1, Objective="Capture a Common wild beast to become your first companion.", Detail="Your Rough Rope can handle Common wildlife. Follow the compass to a Common creature and capture one you want to keep."},
            {Id="EquipCompanion", Type="Action", Action="EquipPet", Required=1, Objective="Equip the beast you just captured.", Detail="Open your Backpack, select the captured beast, and equip it."},
            {Id="RenameCompanion", Type="Action", Action="RenamePet", Required=1, Objective="Give your new companion a name.", Detail="The Backpack will open and highlight the rename controls. The first rename is free."},
            {Id="FirstVictories", Type="Kill", Required=3, TutorialPetOnly=true, Objective="Use your named companion to defeat 3 wild pets.", Detail="Command your companion to attack wild creatures. Your tutorial companion must land the victories."},
            {Id="UpgradeCompanion", Type="Action", Action="UpgradePet", Required=1, Objective="Spend an upgrade point on your companion.", Detail="Rowan grants one tutorial upgrade point. The Backpack will open and highlight the stat upgrade buttons."},
            {Id="ReturnForChallenge", Type="Talk", Objective="Return to Warden Rowan after upgrading your companion.", Detail="You've improved your companion. Head back to Rowan before beginning his final combat lesson."},
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
                    {Item = "Wolf Hide", Required = 3, SourceSpecies = "Wolf"},
                    {Item = "Hare Pelt", Required = 3, SourceSpecies = "Hare"},
                    {Item = "Coarse Boar Hide", Required = 3, SourceSpecies = "Boar"},
                },
                Objective = "Collect Common-pet hides and pelts for Corvin.",
                Detail = "Bring Corvin 3 Wolf Hides, 3 Hare Pelts and 3 Coarse Boar Hides from wild-pet loot bags.",
            },
        },
    },

    CaravanTrouble = {
        Id = "CaravanTrouble",
        Name = "The Lost Caravan: Broken Road",
        NPC = "Bram",
        RequiredStrength = 0,
        Priority = 4,
        Prerequisite = "BeastHandlingTutorial",
        Intro = "One of my supply caravans limped home with half its crates missing. Boars have torn up the south road and scattered the recovery crews. Clear enough of them that I can move a cart safely, then bring me tusks from the animals responsible so I know the route really is open.",
        CompleteText = "Good. That's enough pressure taken off the south road for my people to move again. But the missing cargo has attracted another problem.",
        Reward = {Coins = 3000, Gems = 0},
        Stages = {
            {Id="Boars", Type="Kill", Species="Boar", Required=10, Objective="Defeat 10 Boars threatening the caravan route.", Detail="Any wild Boar defeated by your companion counts."},
            {Id="BoarTusks", Type="ItemTurnIn", Item="Boar Tusk", SourceSpecies="Boar", Required=5, Objective="Collect 5 Boar Tusks from Boar loot bags.", Detail="Bring the tusks to Bram as proof the south road has been cleared."},
            {Id="Report", Type="Talk", Objective="Return to Quartermaster Bram with the Boar Tusks.", Detail="Hand in the first caravan job before Bram offers the next problem."},
        },
    },

    CaravanRecovery = {
        Id = "CaravanRecovery",
        Name = "The Lost Caravan: Scavengers",
        NPC = "Bram",
        RequiredStrength = 0,
        Priority = 5,
        Prerequisite = "CaravanTrouble",
        Intro = "While you were clearing the road, Raccoons found the scattered crates. They're carrying off straps, food and anything else they can drag. Thin them out and bring me pelts so I can identify which group has been raiding the cargo.",
        CompleteText = "That's the last of the caravan trouble handled. The recovery carts can finish the job from here.",
        Reward = {Coins = 4000, Gems = 2},
        Stages = {
            {Id="Raccoons", Type="Kill", Species="Raccoon", Required=6, Objective="Defeat 6 Raccoons stealing the scattered supplies.", Detail="Raccoons appear at night."},
            {Id="RaccoonPelts", Type="ItemTurnIn", Item="Raccoon Pelt", SourceSpecies="Raccoon", Required=4, Objective="Collect 4 Raccoon Pelts from Raccoon loot bags.", Detail="Bring the pelts to Bram as proof the scavengers have been driven off."},
            {Id="Report", Type="Talk", Objective="Return to Quartermaster Bram with the Raccoon Pelts."},
        },
    },

    BarnLesson = {
        Id = "BarnLesson",
        Name = "Prove Your Bond",
        NPC = "Anya",
        RequiredStrength = 25,
        RequiredLasso = "Hunter's Lasso",
        Priority = 8,
        Prerequisite = "BeastHandlingTutorial",
        Intro = "Rowan has already taught you how to care for a fallen companion. I want to see something different: whether you can read your beast well enough to keep it standing against stronger wildlife. Take one of your pets into the field and defeat five Uncommon creatures.",
        CompleteText = "Good. Healing matters, but avoiding a needless defeat matters more. You're starting to understand what your companion can actually handle.",
        Reward = {Coins = 5000, Gems = 5},
        Stages = {
            {Id="UncommonChallenge", Type="Kill", Rarity="Uncommon", Required=5, Objective="Defeat 5 Uncommon wild pets with your companion.", Detail="Your companion must defeat the creatures. Mounts do not count."},
            {Id="Report", Type="Talk", Objective="Return to Beast Healer Anya after defeating 5 Uncommon creatures."},
        },
    },

    MarketLessons = {
        Id = "MarketLessons",
        Name = "Know the Price",
        NPC = "Bram",
        RequiredStrength = 0,
        Priority = 6,
        Prerequisite = "CaravanRecovery",
        Intro = "Before you start funding expensive expeditions, learn how the animal market really works. Sell one non-favourite pet to the Beast Trader, then buy that same pet back. You'll see why a careless sale costs more to undo.",
        CompleteText = "Now you know the rule: selling is easy, changing your mind is expensive. Favourite anything you never want leaving your backpack.",
        Reward = {Coins = 3000, Gems = 0},
        Stages = {
            {Id="SellPet", Type="Action", Action="SellPet", Required=1, Objective="Sell 1 non-favourite pet to the Beast Trader.", Detail="Favourited pets are protected from selling."},
            {Id="BuybackPet", Type="Action", Action="BuybackPet", Required=1, Objective="Buy a pet back from the Beast Trader.", Detail="Buyback costs more than the original sale value."},
            {Id="Report", Type="Talk", Objective="Report back to Quartermaster Bram."},
        },
    },

    FirstMount = {
        Id = "FirstMount",
        Name = "Born to Ride",
        NPC = "Maeve",
        RequiredStrength = 25,
        RequiredLasso = "Hunter's Lasso",
        Priority = 9,
        Prerequisite = "BeastHandlingTutorial",
        Special = "FirstMount",
        Intro = "That Hunter's Lasso tells me you're ready to handle something faster than a fighting beast. Rideable creatures are exceptionally rare, and they're not battle companions. I've tracked a young Trail Horse into the eastern wilderness. Capture it alive, then I'll show you how to ride.",
        CompleteText = "Good seat, good hands, and the horse trusts you. From now on, keep an eye out for rideable creatures in the wild — even the Common ones are rarer than most hunters will ever see.",
        Reward = {Coins = 4000, Gems = 0},
        Stages = {
            {
                Id = "CaptureHorse",
                Type = "Action",
                Action = "CaptureMount",
                Species = "Trail Horse",
                Required = 1,
                Objective = "Capture Maeve's Trail Horse in the eastern wilderness.",
                Detail = "Follow the compass. This quest horse is visible only to you and uses the normal lasso minigame.",
            },
            {
                Id = "EquipHorse",
                Type = "Action",
                Action = "EquipMount",
                Required = 1,
                Objective = "Open your Backpack, choose MOUNTS, and equip the Trail Horse.",
                Detail = "Mounts are travel companions and cannot fight.",
            },
            {
                Id = "Report",
                Type = "Talk",
                Objective = "Return to Stablemaster Maeve while your mount is equipped.",
                Detail = "Ride back to Maeve to finish your first mount lesson.",
            },
        },
    },

    MoonlightProblems = {
        Id = "MoonlightProblems",
        Name = "Moonlight Problems: Living Signals",
        NPC = "Elara",
        RequiredStrength = 25,
        RequiredLasso = "Hunter's Lasso",
        Priority = 10,
        Prerequisite = "BeastHandlingTutorial",
        Intro = "The night sky has been strange, and Moon Bats are reacting before my instruments do. I need five living specimens so I can compare their behaviour over several nights.",
        CompleteText = "Five consistent readings. The bats are responding to the same disturbance. Now I need evidence from the predators circling my observation posts.",
        Reward = {Coins = 4500, Gems = 5},
        Stages = {
            {Id="MoonBats", Type="CaptureReturn", Species="Moon Bat", Required=5, Objective="Capture and return 5 Moon Bats to Astronomer Elara.", Detail="Moon Bats are Common nocturnal creatures."},
        },
    },

    MoonlightOwls = {
        Id = "MoonlightOwls",
        Name = "Moonlight Problems: Feathers in the Dark",
        NPC = "Elara",
        RequiredStrength = 25,
        RequiredLasso = "Hunter's Lasso",
        Priority = 11,
        Prerequisite = "MoonlightProblems",
        Intro = "The bats confirm something is wrong after sunset. Barn Owls have started circling my observation posts far more aggressively than usual. Drive them back and bring me feathers so I can compare them with the bat readings.",
        CompleteText = "The feathers show the same strange night-time pattern. Something is shifting across the whole nocturnal food chain.",
        Reward = {Coins = 6000, Gems = 8},
        Stages = {
            {Id="BarnOwls", Type="Kill", Species="Barn Owl", Required=6, Objective="Defeat 6 Barn Owls around the night wilderness.", Detail="Barn Owls are Uncommon nocturnal creatures."},
            {Id="OwlFeathers", Type="ItemTurnIn", Item="Owl Feather", SourceSpecies="Barn Owl", Required=4, Objective="Collect 4 Owl Feathers from Barn Owl loot bags.", Detail="Elara wants physical evidence from the affected owls."},
            {Id="Report", Type="Talk", Objective="Return to Astronomer Elara with the Owl Feathers."},
        },
    },

    MissingTrapper = {
        Id = "MissingTrapper",
        Name = "The Missing Trapper",
        NPC = "Holt",
        RequiredStrength = 25,
        RequiredLasso = "Hunter's Lasso",
        Priority = 12,
        Prerequisite = "BeastHandlingTutorial",
        Intro = "A trapper from my crew missed two check-ins. His last note said Lynx were stalking the ridge and making it impossible to move safely. Capture five alive for relocation. If they're removed from the trail, my people can search the ridge without starting another fight.",
        CompleteText = "Good. With those Lynx off the ridge, my search team can move. I'll take it from here.",
        Reward = {Coins = 5000, Gems = 5},
        Stages = {
            {Id="Lynx", Type="CaptureReturn", Species="Lynx", Required=5, Objective="Capture and return 5 Lynx to Trapper Holt.", Detail="Lynx are Uncommon. Hunter's Lasso or better is required."},
        },
    },

    ImprintersSecret = {
        Id = "ImprintersSecret",
        Name = "The Imprinter's Secret",
        NPC = "Orin",
        RequiredStrength = 25,
        RequiredLasso = "Hunter's Lasso",
        Priority = 13,
        Prerequisite = "BeastHandlingTutorial",
        Intro = "A capture is only the beginning of a bond. Bring me a beast with a respectable imprint and I'll show you why two animals of the same species can have very different potential.",
        CompleteText = "That's a strong bond. Now that you know what to look for, come back when you find an exceptional imprint.",
        Reward = {Coins = 3500, Gems = 5},
        Stages = {
            {Id="Imprint50", Type="InspectPet", MinimumImprint=50, Required=1, Objective="Show Sage Orin any pet with at least 50% imprint.", Detail="You keep the pet; Orin only inspects it."},
        },
    },

    ImprintersMastery = {
        Id = "ImprintersMastery",
        Name = "The Imprinter's Secret: Exceptional Bond",
        NPC = "Orin",
        RequiredStrength = 25,
        RequiredLasso = "Hunter's Lasso",
        Priority = 14,
        Prerequisite = "ImprintersSecret",
        Intro = "You've seen what a good imprint looks like. Now show me a truly exceptional bond — seventy percent or better.",
        CompleteText = "There it is. That is the kind of imprint worth building a serious team around. Watch the bond, not only the rarity.",
        Reward = {Coins = 7000, Gems = 12},
        Stages = {
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
        Name = "Champion of the Wilds I",
        NPC = "Rook",
        RequiredStrength = 45,
        RequiredLasso = "Iron Lasso",
        Priority = 21,
        Prerequisite = "BeastHandlingTutorial",
        Intro = "An Iron Lasso gets you into dangerous country, but equipment doesn't prove your companion can handle it. Start with endurance: defeat ten Common wild pets, then report back to me.",
        CompleteText = "Ten clean victories. Good. Common wildlife no longer tests your team, so we'll raise the standard.",
        Reward = {Coins = 5000, Gems = 0},
        Stages = {
            {Id="CommonKills", Type="Kill", Rarity="Common", Required=10, Objective="Defeat 10 Common wild pets with your companion."},
            {Id="Report", Type="Talk", Objective="Return to Captain Rook after defeating 10 Common wild pets."},
        },
    },

    ChampionWildsUncommon = {
        Id = "ChampionWildsUncommon",
        Name = "Champion of the Wilds II",
        NPC = "Rook",
        RequiredStrength = 45,
        RequiredLasso = "Iron Lasso",
        Priority = 22,
        Prerequisite = "ChampionWilds",
        Intro = "Now fight creatures that push back harder. Defeat five Uncommon wild pets with your companion, then return for assessment.",
        CompleteText = "That's the difference I wanted to see. Your companion can stay composed against stronger wildlife.",
        Reward = {Coins = 8000, Gems = 5},
        Stages = {
            {Id="UncommonKills", Type="Kill", Rarity="Uncommon", Required=5, Objective="Defeat 5 Uncommon wild pets with your companion."},
            {Id="Report", Type="Talk", Objective="Return to Captain Rook after defeating 5 Uncommon wild pets."},
        },
    },

    ChampionWildsRare = {
        Id = "ChampionWildsRare",
        Name = "Champion of the Wilds III",
        NPC = "Rook",
        RequiredStrength = 45,
        RequiredLasso = "Iron Lasso",
        Priority = 23,
        Prerequisite = "ChampionWildsUncommon",
        Intro = "One last test. Rare wildlife can punish a weak team quickly. Defeat two Rare wild pets with your companion and come back in one piece.",
        CompleteText = "That's the standard I expect from a field team. You've completed every challenge I have for you.",
        Reward = {Coins = 15000, Gems = 15},
        Stages = {
            {Id="RareKills", Type="Kill", Rarity="Rare", Required=2, Objective="Defeat 2 Rare wild pets with your companion."},
            {Id="Report", Type="Talk", Objective="Return to Captain Rook after defeating 2 Rare wild pets."},
        },
    },

    RarityArchiveRare = {
        Id = "RarityArchiveRare",
        Name = "A Creature Worthy of Record",
        NPC = "Vale",
        RequiredStrength = 45,
        RequiredLasso = "Iron Lasso",
        Priority = 24,
        Prerequisite = "BeastHandlingTutorial",
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
        Name = "Beneath Hollowfang: Venom in the Stone",
        NPC = "Rowan",
        RequiredStrength = 65,
        RequiredLasso = "Steel Lasso",
        Priority = 30,
        Prerequisite = "HollowfangRescue",
        Intro = "Mira's report has been bothering me. The Bears weren't hunting her; they were fleeing deeper tunnels. Dusk Cobras have begun gathering around Hollowfang in numbers that make no sense. Clear them out and bring me physical evidence before we risk going deeper.",
        CompleteText = "These fangs confirm it. The Cobras aren't simply nesting there — something below Hollowfang is forcing predators into the same territory.",
        Reward = {Coins = 28000, Gems = 25},
        Stages = {
            {Id="Cobras", Type="Kill", Species="Dusk Cobra", Required=5, Objective="Defeat 5 Dusk Cobras while investigating the Hollowfang disturbance."},
            {Id="DuskFangs", Type="ItemTurnIn", Item="Dusk Fang", SourceSpecies="Dusk Cobra", Required=3, Objective="Collect 3 Dusk Fangs from Dusk Cobra loot bags.", Detail="Bring Rowan enough physical evidence to compare the affected Cobras."},
            {Id="Report", Type="Talk", Objective="Return the Dusk Fang evidence to Warden Rowan."},
        },
    },

    HollowfangWeavers = {
        Id = "HollowfangWeavers",
        Name = "Beneath Hollowfang: Webs Below",
        NPC = "Rowan",
        RequiredStrength = 65,
        RequiredLasso = "Steel Lasso",
        Priority = 31,
        Prerequisite = "HollowfangMystery",
        Intro = "The fangs were bad enough. Now scouts are finding Void Silk around the same rock fractures. Hunt the Void Weavers moving toward Hollowfang and bring me enough silk to confirm they're coming from the same source.",
        CompleteText = "Cobras and Void Weavers driven into the same cave system is no coincidence. This is enough evidence. The next trip into Hollowfang won't be a survey — we'll be going after whatever is causing it.",
        Reward = {Coins = 38000, Gems = 45},
        Stages = {
            {Id="Weavers", Type="Kill", Species="Void Weaver", Required=4, RequiredStrength=65, Objective="Defeat 4 Void Weavers linked to the Hollowfang disturbance."},
            {Id="VoidSilk", Type="ItemTurnIn", Item="Void Silk", SourceSpecies="Void Weaver", Required=2, Objective="Collect 2 Void Silk from Void Weaver loot bags.", Detail="Rowan needs enough silk to compare multiple nests around Hollowfang."},
            {Id="Report", Type="Talk", Objective="Return the Void Silk evidence to Warden Rowan."},
        },
    },

    HollowfangWyrm = {
        Id = "HollowfangWyrm",
        Name = "Beneath Hollowfang: The Wounded Wyrm",
        NPC = "Rowan",
        RequiredStrength = 65,
        RequiredLasso = "Steel Lasso",
        Priority = 32,
        Prerequisite = "HollowfangWeavers",
        Intro = "The evidence is finally consistent. Whatever is below Hollowfang drove Bears, Cobras and Void Weavers out of the same tunnels. Go back to the cave and push deeper than Mira could. If there is a creature hiding down there, find out what frightened it badly enough to take refuge beneath our feet.",
        CompleteText = "Those gouges were already in the Wyrm before you reached it? Then Hollowfang was never the source of the disturbance — it was shelter. I've heard old rumours from the northeast watch: something enormous has been moving near the falls. Search the northeast corner of the wilds. They say there is a cave hidden behind the waterfall.",
        Reward = {Coins = 0, Gems = 0},
        Stages = {
            {Id="EnterDepths", Type="Action", Action="EnterWyrmArena", Required=1, Objective="Enter the deepest chamber of Hollowfang Cave.", Detail="Walk beyond Mira's old refuge. The newly opened passage continues much farther underground."},
            {Id="DefeatWyrm", Type="Action", Action="DefeatWyrm", Required=1, Objective="Defeat the wounded Wyrm with your companion.", Detail="Attack the Wyrm with your companion. Its body bears enormous old gouges from something far larger."},
            {Id="Report", Type="Talk", Objective="Return to Warden Rowan after defeating the Wyrm.", Detail="Tell Rowan about the enormous gouges already carved into the Wyrm's hide."},
        },
    },

    WorldBossTrail = {
        Id = "WorldBossTrail",
        Name = "The Cave Behind the Falls",
        NPC = "Rowan",
        RequiredStrength = 65,
        RequiredLasso = "Steel Lasso",
        Priority = 33,
        Prerequisite = "HollowfangWyrm",
        Intro = "Those old reports all point northeast. Find the waterfall near the edge of the wilds and look behind the falling water. If the rumours are true, the cave there leads to whatever drove the Wyrm into Hollowfang. Do not expect to face it alone.",
        CompleteText = "So the old stories were true. Jormungdyrr was what drove the Wyrm into Hollowfang. The village will remember the handlers who stood together against it — and the relics it leaves behind may be rarer than anything we have ever catalogued.",
        Reward = {Coins = 0, Gems = 0},
        Stages = {
            {Id="FindWaterfall", Type="Action", Action="EnterJormungdyrrArena", Required=1, Objective="Find the hidden cave behind the northeast waterfall.", Detail="Search the northeast corner of the world. Walk through the waterfall and follow the cave inward. The passage leads to a shared world-boss arena."},
            {Id="DefeatJormungdyrr", Type="Action", Action="DefeatJormungdyrr", Required=1, Objective="Defeat Jormungdyrr with other handlers.", Detail="Jormungdyrr is protected against solo attempts. Gather other handlers, combine support abilities and contribute meaningfully to the shared fight."},
            {Id="ReportVictory", Type="Talk", Objective="Return to Warden Rowan after defeating Jormungdyrr.", Detail="Tell Rowan what was hiding beyond the waterfall and what happened in the cavern."},
        },
    },
}

QuestConfig.NPCOrder = {"Rowan","Bram","Anya","Elara","Holt","Orin","Rook","Vale","Maeve"}

return QuestConfig
