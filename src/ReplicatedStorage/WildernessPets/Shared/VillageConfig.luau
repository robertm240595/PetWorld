local VillageConfig = {}

VillageConfig.HealingBarn = {
    [1] = {Speed = 1.00, UpgradeCoins = 10000},
    [2] = {Speed = 1.25, UpgradeCoins = 35000},
    [3] = {Speed = 1.60, UpgradeCoins = 100000},
    [4] = {Speed = 2.10, UpgradeCoins = 250000},
    [5] = {Speed = 3.00, UpgradeCoins = nil},
}

VillageConfig.TrainingArea = {
    [1] = {Interval = 15 * 60, XP = 1, UpgradeCoins = 25000},
    [2] = {Interval = 12 * 60, XP = 1, UpgradeCoins = 75000},
    [3] = {Interval = 9 * 60, XP = 1, UpgradeCoins = 200000},
    [4] = {Interval = 6 * 60, XP = 1, UpgradeCoins = 500000},
    [5] = {Interval = 4 * 60, XP = 1, UpgradeCoins = nil},
}

VillageConfig.StartTrainingSlots = 1
VillageConfig.MaxTrainingSlots = 5
VillageConfig.TrainingSlotGemCosts = {
    [2] = 150,
    [3] = 300,
    [4] = 600,
    [5] = 1000,
}

function VillageConfig.GetHealing(level)
    return VillageConfig.HealingBarn[math.clamp(math.floor(tonumber(level) or 1), 1, #VillageConfig.HealingBarn)]
end

function VillageConfig.GetTraining(level)
    return VillageConfig.TrainingArea[math.clamp(math.floor(tonumber(level) or 1), 1, #VillageConfig.TrainingArea)]
end

return VillageConfig
