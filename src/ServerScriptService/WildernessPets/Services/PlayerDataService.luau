local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local Config = require(game.ReplicatedStorage.WildernessPets.Shared.Config)

-- Unpublished Studio places cannot access DataStoreService. In that case,
-- keep player data in memory for the current test session instead.
local Store = nil
local useDataStore = not RunService:IsStudio()

if useDataStore then
    Store = DataStoreService:GetDataStore("WildernessPets_V2")
end

local Service = {}
Service.Data = {}

local function newData()
    return {
        Coins = Config.StartCoins,
        Gems = Config.StartGems,
        Lasso = "Rough Rope",
        Inventory = {
            {Type = "Lasso", Name = "Rough Rope", Quantity = 1}
        },
        Pets = {},
        SelectedPlot = 0,
        DefencePetId = "",
        EquippedPetId = "",
        PodiumPetId = "",
        ArenaRating = 1000,
        ArenaWins = 0,
        ArenaLosses = 0,
        WeeklyWins = 0,
        LastWeeklyReward = 0
    }
end

local function makeLeaderstats(player, data)
    local ls = Instance.new("Folder")
    ls.Name = "leaderstats"
    ls.Parent = player

    local coins = Instance.new("IntValue")
    coins.Name = "Coins"
    coins.Value = data.Coins
    coins.Parent = ls

    local gems = Instance.new("IntValue")
    gems.Name = "Gems"
    gems.Value = data.Gems
    gems.Parent = ls

    local rating = Instance.new("IntValue")
    rating.Name = "ArenaRating"
    rating.Value = data.ArenaRating
    rating.Parent = ls
end

local function syncLeaderstats(player)
    local data = Service.Data[player]
    if not data then return end

    local ls = player:FindFirstChild("leaderstats")
    if not ls then return end

    if ls:FindFirstChild("Coins") then
        ls.Coins.Value = data.Coins
    end

    if ls:FindFirstChild("Gems") then
        ls.Gems.Value = data.Gems
    end

    if ls:FindFirstChild("ArenaRating") then
        ls.ArenaRating.Value = data.ArenaRating
    end
end

function Service:Load(player)
    local data = newData()

    if useDataStore and Store then
        local success, saved = pcall(function()
            return Store:GetAsync("Player_" .. player.UserId)
        end)

        if success and type(saved) == "table" then
            for k, v in pairs(saved) do
                data[k] = v
            end
        end
    end

    if type(data.Inventory) ~= "table" then
        data.Inventory = {}
    end

    local equippedLasso = type(data.Lasso) == "string" and data.Lasso or "Rough Rope"
    data.Lasso = equippedLasso

    local ownsEquippedLasso = false
    for _, item in ipairs(data.Inventory) do
        if type(item) == "table" and item.Type == "Lasso" and item.Name == equippedLasso then
            item.Quantity = math.max(1, tonumber(item.Quantity) or 1)
            ownsEquippedLasso = true
            break
        end
    end

    if not ownsEquippedLasso and #data.Inventory < (Config.MaxInventory or 25) then
        table.insert(data.Inventory, {
            Type = "Lasso",
            Name = equippedLasso,
            Quantity = 1
        })
    end

    self.Data[player] = data

    makeLeaderstats(player, data)

    return data
end

function Service:Get(player)
    return self.Data[player]
end

function Service:Save(player)
    local data = self.Data[player]
    if not data then return end

    if not useDataStore or not Store then
        return
    end

    pcall(function()
        Store:UpdateAsync("Player_" .. player.UserId, function()
            return data
        end)
    end)
end

function Service:AddCoins(player, amount)
    local data = self:Get(player)
    if not data then return end

    data.Coins += amount
    syncLeaderstats(player)
end

function Service:AddGems(player, amount)
    local data = self:Get(player)
    if not data then return end

    data.Gems += amount
    syncLeaderstats(player)
end

function Service:SpendCoins(player, amount)
    local data = self:Get(player)
    if not data or data.Coins < amount then
        return false
    end

    data.Coins -= amount
    syncLeaderstats(player)

    return true
end

function Service:SpendGems(player, amount)
    local data = self:Get(player)
    if not data or data.Gems < amount then
        return false
    end

    data.Gems -= amount
    syncLeaderstats(player)

    return true
end

function Service:Cleanup(player)
    self:Save(player)
    self.Data[player] = nil
end

-- GameServer owns the player lifecycle so each profile is loaded and cleaned up once.

game:BindToClose(function()
    for _, player in ipairs(Players:GetPlayers()) do
        Service:Save(player)
    end
end)

return Service
