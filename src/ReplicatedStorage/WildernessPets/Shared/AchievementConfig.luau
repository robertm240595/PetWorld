local AchievementConfig = {}

AchievementConfig.List = {
    {
        Id = "FirstCapture",
        Name = "First Catch",
        Description = "Capture your first pet.",
        Gems = 5,
        Condition = {Type = "PetsOwned", Value = 1},
    },
    {
        Id = "Collector10",
        Name = "Growing Collection",
        Description = "Discover 10 different pet species.",
        Gems = 10,
        Condition = {Type = "UniquePets", Value = 10},
    },
    {
        Id = "Collector25",
        Name = "Field Naturalist",
        Description = "Discover 25 different pet species.",
        Gems = 25,
        Condition = {Type = "UniquePets", Value = 25},
    },
    {
        Id = "Collector50",
        Name = "Master Collector",
        Description = "Discover 50 different pet species.",
        Gems = 60,
        Condition = {Type = "UniquePets", Value = 50},
    },
    {
        Id = "FirstMount",
        Name = "Born to Ride",
        Description = "Own your first mount.",
        Gems = 10,
        Condition = {Type = "MountsOwned", Value = 1},
    },
    {
        Id = "SteelHandler",
        Name = "Steel Handler",
        Description = "Acquire Steel Lasso strength or better.",
        Gems = 20,
        Condition = {Type = "LassoStrength", Value = 70},
    },
    {
        Id = "MysticHandler",
        Name = "Mystic Handler",
        Description = "Acquire Mystic Lasso strength or better.",
        Gems = 45,
        Condition = {Type = "LassoStrength", Value = 100},
    },
    {
        Id = "AncientHandler",
        Name = "Ancient Handler",
        Description = "Acquire the Ancient Lasso.",
        Gems = 125,
        Condition = {Type = "LassoStrength", Value = 135},
    },
    {
        Id = "Questing5",
        Name = "Village Regular",
        Description = "Complete 5 quest chains.",
        Gems = 15,
        Condition = {Type = "QuestsCompleted", Value = 5},
    },
    {
        Id = "Questing15",
        Name = "Wilderness Veteran",
        Description = "Complete 15 quest chains.",
        Gems = 50,
        Condition = {Type = "QuestsCompleted", Value = 15},
    },
    {
        Id = "ArenaWinner",
        Name = "First Arena Win",
        Description = "Win an arena battle.",
        Gems = 15,
        Condition = {Type = "ArenaWins", Value = 1},
    },
    {
        Id = "Mastery25",
        Name = "Bonded Companion",
        Description = "Raise any pet to level 25.",
        Gems = 20,
        Condition = {Type = "PetLevel", Value = 25},
    },
    {
        Id = "Mastery50",
        Name = "Mastered Companion",
        Description = "Raise any pet to level 50.",
        Gems = 50,
        Condition = {Type = "PetLevel", Value = 50},
    },
    {
        Id = "WyrmVictor",
        Name = "Beneath Hollowfang",
        Description = "Complete the Wounded Wyrm quest.",
        Gems = 75,
        Condition = {Type = "QuestCompleted", Id = "HollowfangWyrm"},
    },
    {
        Id = "WorldBossVictor",
        Name = "Fall of Jormungdyrr",
        Description = "Complete the Jormungdyrr world-boss quest.",
        Gems = 200,
        Condition = {Type = "QuestCompleted", Id = "WorldBossTrail"},
    },
}

AchievementConfig.ById = {}
for _, achievement in ipairs(AchievementConfig.List) do
    AchievementConfig.ById[achievement.Id] = achievement
end

return AchievementConfig
