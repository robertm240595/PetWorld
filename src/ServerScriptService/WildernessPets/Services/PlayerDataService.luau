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
        MaxLassoStrengthUnlocked = 15,
        Inventory = {
            {Type = "Lasso", Name = "Rough Rope", Quantity = 1}
        },
        InventoryCapacity = Config.MaxInventory or 25,
        BackpackName = "Starter Bag",
        LootInventory = {},
        PetBuyback = {},
        LassoBuyback = {},
        ActiveEffects = {
            XPBoostUntil = 0,
            XPBoostPercent = 0,
            SpeedBoostUntil = 0,
            PlayerSpeedMultiplier = 1,
            PetSpeedMultiplier = 1,
            NextCaptureTranquiliser = false,
            NextCaptureLuck = false
        },
        Pets = {},
        Mounts = {},
        MountCollection = {},
        PetCollection = {},
        CollectionRewardsClaimed = {},
        QuestProgress = {},
        SelectedPlot = 0,
        DefencePetId = "",
        EquippedPetId = "",
        EquippedMountId = "",
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
    if type(data.LootInventory) ~= "table" then
        data.LootInventory = {}
    end

    data.InventoryCapacity = math.max(
        tonumber(Config.MaxInventory) or 25,
        math.floor(tonumber(data.InventoryCapacity) or tonumber(Config.MaxInventory) or 25)
    )
    data.BackpackName = type(data.BackpackName) == "string" and data.BackpackName or "Starter Bag"

    -- Migrate the previous unlimited material dictionary into ordinary,
    -- slot-limited stackable Loot inventory entries without deleting any
    -- previously collected material.
    local migratedLoot = {}
    for itemName, quantity in pairs(data.LootInventory) do
        local amount = math.max(0, math.floor(tonumber(quantity) or 0))
        if type(itemName) == "string" and itemName ~= "" and amount > 0 then
            migratedLoot[itemName] = (migratedLoot[itemName] or 0) + amount
        end
    end

    for _, item in ipairs(data.Inventory) do
        if type(item) == "table" then
            item.Quantity = math.max(1, math.floor(tonumber(item.Quantity) or 1))
            if item.Type == "Loot" and type(item.Name) == "string" then
                migratedLoot[item.Name] = (migratedLoot[item.Name] or 0) + item.Quantity
                item._MergedLegacyLoot = true
            end
        end
    end

    for index = #data.Inventory, 1, -1 do
        local item = data.Inventory[index]
        if type(item) == "table" and item._MergedLegacyLoot then
            table.remove(data.Inventory, index)
        end
    end

    local lootNames = {}
    for itemName in pairs(migratedLoot) do table.insert(lootNames, itemName) end
    table.sort(lootNames)
    for _, itemName in ipairs(lootNames) do
        table.insert(data.Inventory, {
            Type = "Loot",
            Name = itemName,
            Quantity = migratedLoot[itemName],
        })
    end
    data.LootInventory = {}
    if type(data.Pets) ~= "table" then
        data.Pets = {}
    end
    if type(data.Mounts) ~= "table" then
        data.Mounts = {}
    end
    if type(data.MountCollection) ~= "table" then
        data.MountCollection = {}
    end
    if type(data.PetCollection) ~= "table" then
        data.PetCollection = {}
    end
    if type(data.CollectionRewardsClaimed) ~= "table" then
        data.CollectionRewardsClaimed = {}
    end
    if type(data.QuestProgress) ~= "table" then
        data.QuestProgress = {}
    end
    if type(data.PetBuyback) ~= "table" then
        data.PetBuyback = {}
    end
    if type(data.LassoBuyback) ~= "table" then
        data.LassoBuyback = {}
    end
    if type(data.ActiveEffects) ~= "table" then
        data.ActiveEffects = {}
    end

    data.Coins = math.max(0, math.floor(tonumber(data.Coins) or tonumber(Config.StartCoins) or 0))
    data.Gems = math.max(0, math.floor(tonumber(data.Gems) or tonumber(Config.StartGems) or 0))

    data.ActiveEffects.XPBoostUntil = tonumber(data.ActiveEffects.XPBoostUntil) or 0
    data.ActiveEffects.XPBoostPercent = tonumber(data.ActiveEffects.XPBoostPercent) or 0
    data.ActiveEffects.SpeedBoostUntil = tonumber(data.ActiveEffects.SpeedBoostUntil) or 0
    data.ActiveEffects.PlayerSpeedMultiplier = tonumber(data.ActiveEffects.PlayerSpeedMultiplier) or 1
    data.ActiveEffects.PetSpeedMultiplier = tonumber(data.ActiveEffects.PetSpeedMultiplier) or 1
    data.ActiveEffects.NextCaptureTranquiliser = data.ActiveEffects.NextCaptureTranquiliser == true
    data.ActiveEffects.NextCaptureLuck = data.ActiveEffects.NextCaptureLuck == true

    local function seedCollection(species)
        local info = type(species) == "string" and Config.Pets[species] or nil
        if info and info.Legacy ~= true and info.SpawnMode ~= "Legacy" then
            data.PetCollection[species] = true
        end
    end

    -- Migrate existing profiles into the lifetime collection database.
    for _, pet in ipairs(data.Pets) do
        if type(pet) == "table" then
            seedCollection(pet.Species)
        end
    end
    for _, entry in ipairs(data.PetBuyback) do
        if type(entry) == "table" and type(entry.Pet) == "table" then
            seedCollection(entry.Pet.Species)
        end
    end

    for _, mount in ipairs(data.Mounts) do
        if type(mount) == "table" and type(mount.Species) == "string" and Config.Mounts[mount.Species] then
            mount.Id = type(mount.Id) == "string" and mount.Id or game:GetService("HttpService"):GenerateGUID(false)
            mount.Name = type(mount.Name) == "string" and mount.Name or mount.Species
            mount.Rarity = tostring(mount.Rarity or Config.Mounts[mount.Species].Rarity or "Common")
            mount.Imprint = math.clamp(math.floor(tonumber(mount.Imprint) or 20), 20, 100)
            data.MountCollection[mount.Species] = true
        end
    end
    data.EquippedMountId = type(data.EquippedMountId) == "string" and data.EquippedMountId or ""

    local equippedLasso = type(data.Lasso) == "string" and data.Lasso or "Rough Rope"
    data.Lasso = equippedLasso

    local unlockedStrength = math.max(0, tonumber(data.MaxLassoStrengthUnlocked) or 0)
    local function noteLasso(name)
        local info = type(name) == "string" and Config.Lassos[name] or nil
        unlockedStrength = math.max(unlockedStrength, tonumber(info and info.Strength) or 0)
    end
    noteLasso(equippedLasso)
    for _, item in ipairs(data.Inventory) do
        if type(item) == "table" and item.Type == "Lasso" and (tonumber(item.Quantity) or 0) > 0 then
            noteLasso(item.Name)
        end
    end
    data.MaxLassoStrengthUnlocked = unlockedStrength

    local ownsEquippedLasso = false
    for _, item in ipairs(data.Inventory) do
        if type(item) == "table" and item.Type == "Lasso" and item.Name == equippedLasso then
            item.Quantity = math.max(1, tonumber(item.Quantity) or 1)
            ownsEquippedLasso = true
            break
        end
    end

    if not ownsEquippedLasso and #data.Inventory < data.InventoryCapacity then
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
    if not data then return nil end

    local value = math.max(0, math.floor(tonumber(amount) or 0))
    data.Coins = math.max(0, math.floor(tonumber(data.Coins) or 0)) + value
    syncLeaderstats(player)
    return data.Coins
end

function Service:AddGems(player, amount)
    local data = self:Get(player)
    if not data then return nil end

    local value = math.max(0, math.floor(tonumber(amount) or 0))
    data.Gems = math.max(0, math.floor(tonumber(data.Gems) or 0)) + value
    syncLeaderstats(player)
    return data.Gems
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
