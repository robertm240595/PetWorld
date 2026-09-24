local Config=require(game.ReplicatedStorage.WildernessPets.Shared.Config)
local SkinConfig=require(game.ReplicatedStorage.WildernessPets.Shared.LassoSkinConfig)
return function(data)
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

    local validSkins = {}
    if type(data.LassoSkinsOwned) == "table" then
        for skinId, owned in pairs(data.LassoSkinsOwned) do
            if owned == true and SkinConfig.Get(skinId) then
                validSkins[skinId] = true
            end
        end
    end
    data.LassoSkinsOwned = validSkins
    data.EquippedLassoSkin = type(data.EquippedLassoSkin) == "string" and data.EquippedLassoSkin or ""
    if data.EquippedLassoSkin ~= "" and data.LassoSkinsOwned[data.EquippedLassoSkin] ~= true then
        data.EquippedLassoSkin = ""
    end

    if type(data.ActiveEffects) ~= "table" then
        data.ActiveEffects = {}
    end
    if type(data.Achievements) ~= "table" then data.Achievements = {} end
    if type(data.AuctionListings) ~= "table" then data.AuctionListings = {} end
    if type(data.AuctionStats) ~= "table" then data.AuctionStats = {} end
    if type(data.AuctionMailClaims) ~= "table" then data.AuctionMailClaims = {} end
    if type(data.VillageUpgrades) ~= "table" then data.VillageUpgrades = {} end
    if type(data.TrainingAssignments) ~= "table" then data.TrainingAssignments = {} end

    data.AuctionStats.Listed = math.max(0, math.floor(tonumber(data.AuctionStats.Listed) or 0))
    data.AuctionStats.Sold = math.max(0, math.floor(tonumber(data.AuctionStats.Sold) or 0))
    data.AuctionStats.Bought = math.max(0, math.floor(tonumber(data.AuctionStats.Bought) or 0))
    data.AuctionStats.FeesPaid = math.max(0, math.floor(tonumber(data.AuctionStats.FeesPaid) or 0))
    data.VillageUpgrades.HealingBarn = math.clamp(math.floor(tonumber(data.VillageUpgrades.HealingBarn) or 1), 1, 5)
    data.VillageUpgrades.TrainingArea = math.clamp(math.floor(tonumber(data.VillageUpgrades.TrainingArea) or 1), 1, 5)
    data.VillageUpgrades.TrainingSlots = math.clamp(math.floor(tonumber(data.VillageUpgrades.TrainingSlots) or 1), 1, 5)

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
            pet.Id = type(pet.Id) == "string" and pet.Id or game:GetService("HttpService"):GenerateGUID(false)
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

return data
end