local QuestConfig = {}

QuestConfig.ObjectiveTypes = {
    Talk = "TALK",
    CaptureReturn = "CAPTURE & RETURN",
    Kill = "KILL",
    ItemTurnIn = "ITEM TURN-IN",
}

QuestConfig.Chain = {
    Id = "HollowfangRescue",
    Name = "Hollowfang Rescue",
    QuestGiver = "Warden Rowan",
    RescueNPC = "Scout Mira",
    CaveName = "Hollowfang Cave",

    WolfQuest = {
        Title = "A Better Answer",
        Species = "Wolf",
        Required = 5,
        RewardCoins = 750,
        ObjectiveType = "CaptureReturn",
        Intro = "The road packs have been driven too close to the village. They've started raiding supply carts, but I won't order a cull if we can avoid it. Capture five Wolves alive and bring them to me. We'll move them to the outer watch and train the calmer ones as road sentries.",
        Progress = "Bring me five healthy Wolves that are free in your backpack. Favourited, displayed, equipped, podium, defence, or dead pets stay protected and cannot be handed over.",
        TurnIn = "Good work. These five will be handled properly — no cages in the market and no needless killing.",
    },

    BearQuest = {
        Title = "The Hollowfang Report",
        Species = "Bear",
        Required = 3,
        RewardCoins = 1500,
        ObjectiveType = "Kill",
        Intro = "A runner just brought bad news. Scout Mira went northeast to Hollowfang Cave after reports of frightened wildlife, and she hasn't returned. Bears have her pinned inside. Follow your compass to the cave and clear the three Bears at the entrance.",
        Progress = "Defeat the three quest Bears outside Hollowfang Cave. They are blocking Scout Mira's only safe way out.",
        Rescue = "You made it. Those bears weren't hunting — they were terrified of something deeper in the cave. I can get back to the village now. Tell Rowan I'll make a full report.",
        Complete = "Scout Mira is safe. The claw marks she found deeper inside Hollowfang Cave may lead to a larger threat later.",
    },
}

QuestConfig.World = {
    RowanXZ = Vector2.new(8, -18),
    CaveXZ = Vector2.new(390, -390),
    CaveFallbackY = 17,
}

return QuestConfig
