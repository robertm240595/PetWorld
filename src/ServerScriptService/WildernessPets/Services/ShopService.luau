local Config = require(game.ReplicatedStorage.WildernessPets.Shared.Config)

local DataService = require(script.Parent.PlayerDataService)
local PetService = require(script.Parent.PetService)

local Service = {}

local function ensureInventory(data)
    data.Inventory = type(data.Inventory) == "table" and data.Inventory or {}
    return data.Inventory
end

local function ensureBuybacks(data)
    data.PetBuyback = type(data.PetBuyback) == "table" and data.PetBuyback or {}
    data.LassoBuyback = type(data.LassoBuyback) == "table" and data.LassoBuyback or {}
end

local function cloneFlatTable(source)
    local copy = {}
    for key, value in pairs(source or {}) do
        copy[key] = value
    end
    return copy
end

function Service:CountInventorySlots(player)
    local data = DataService:Get(player)
    if not data then return 0 end
    return #ensureInventory(data)
end

function Service:AddInventoryItem(player, itemType, name, quantity)
    local data = DataService:Get(player)
    if not data then return false, "Inventory unavailable." end

    local inventory = ensureInventory(data)
    quantity = math.max(1, math.floor(tonumber(quantity) or 1))

    for _, item in ipairs(inventory) do
        if type(item) == "table" and item.Type == itemType and item.Name == name then
            item.Quantity = math.max(0, tonumber(item.Quantity) or 0) + quantity
            return true
        end
    end

    if #inventory >= (Config.MaxInventory or 25) then
        return false, "Your inventory is full."
    end

    table.insert(inventory, {
        Type = itemType,
        Name = name,
        Quantity = quantity
    })

    return true
end

function Service:CountInventoryItem(player, itemType, name)
    local data = DataService:Get(player)
    if not data then return 0 end

    for _, item in ipairs(ensureInventory(data)) do
        if type(item) == "table" and item.Type == itemType and item.Name == name then
            return math.max(0, math.floor(tonumber(item.Quantity) or 0))
        end
    end

    return 0
end

function Service:ConsumeInventoryItem(player, itemType, name, quantity)
    local data = DataService:Get(player)
    if not data then return false end

    local inventory = ensureInventory(data)
    quantity = math.max(1, math.floor(tonumber(quantity) or 1))

    for index, item in ipairs(inventory) do
        if type(item) == "table" and item.Type == itemType and item.Name == name then
            local current = math.max(0, math.floor(tonumber(item.Quantity) or 0))
            if current < quantity then return false end

            current -= quantity
            if current <= 0 then
                table.remove(inventory, index)
            else
                item.Quantity = current
            end
            return true
        end
    end

    return false
end

function Service:BuyLasso(player, name)
    local item = Config.Lassos[name]
    local data = DataService:Get(player)

    if not item or not data then
        return false, "Lasso unavailable."
    end

    local inventory = ensureInventory(data)

    for _, owned in ipairs(inventory) do
        if type(owned) == "table" and owned.Type == "Lasso" and owned.Name == name then
            data.Lasso = name
            return true, "Lasso equipped."
        end
    end

    if #inventory >= (Config.MaxInventory or 25) then
        return false, "Your inventory is full."
    end

    local coinCost = math.max(0, tonumber(item.Coins) or 0)
    local gemCost = math.max(0, tonumber(item.Gems) or 0)

    if data.Coins < coinCost or data.Gems < gemCost then
        return false, "You cannot afford that lasso."
    end

    if coinCost > 0 and not DataService:SpendCoins(player, coinCost) then
        return false, "Not enough Coins."
    end
    if gemCost > 0 and not DataService:SpendGems(player, gemCost) then
        if coinCost > 0 then DataService:AddCoins(player, coinCost) end
        return false, "Not enough Gems."
    end

    table.insert(inventory, {
        Type = "Lasso",
        Name = name,
        Quantity = 1
    })

    data.Lasso = name
    return true, "Lasso purchased and equipped."
end

function Service:EquipLasso(player, name)
    local data = DataService:Get(player)
    if not data then
        return false, "Inventory unavailable."
    end

    for _, owned in ipairs(ensureInventory(data)) do
        if type(owned) == "table" and owned.Type == "Lasso" and owned.Name == name then
            data.Lasso = name
            return true, tostring(name) .. " equipped."
        end
    end

    return false, "You do not own that lasso."
end

function Service:SellLasso(player, name)
    local data = DataService:Get(player)
    local config = Config.Lassos[name]
    if not data or not config then return false, "Lasso unavailable." end

    ensureBuybacks(data)
    local inventory = ensureInventory(data)

    local lassoCount = 0
    local foundIndex
    for index, item in ipairs(inventory) do
        if type(item) == "table" and item.Type == "Lasso" then
            lassoCount += 1
            if item.Name == name then foundIndex = index end
        end
    end

    if not foundIndex then return false, "You do not own that lasso." end
    if lassoCount <= 1 then return false, "You must keep at least one lasso." end

    local coins = math.max(0, tonumber(config.Coins) or 0)
    local gems = math.max(0, tonumber(config.Gems) or 0)

    table.remove(inventory, foundIndex)

    if data.Lasso == name then
        for _, item in ipairs(inventory) do
            if type(item) == "table" and item.Type == "Lasso" then
                data.Lasso = item.Name
                break
            end
        end
    end

    DataService:AddCoins(player, coins)
    DataService:AddGems(player, gems)

    table.insert(data.LassoBuyback, 1, {
        Name = name,
        Coins = math.ceil(coins * (Config.LassoBuybackMultiplier or 1)),
        Gems = math.ceil(gems * (Config.LassoBuybackMultiplier or 1)),
        SoldAt = os.time()
    })
    while #data.LassoBuyback > 10 do table.remove(data.LassoBuyback) end

    return true, "Sold " .. name .. " for its full purchase value.", coins, gems
end

function Service:BuybackLasso(player, index)
    local data = DataService:Get(player)
    if not data then return false, "Player data unavailable." end

    ensureBuybacks(data)
    local entry = data.LassoBuyback[tonumber(index)]
    if not entry then return false, "That buyback is no longer available." end

    local inventory = ensureInventory(data)
    if #inventory >= (Config.MaxInventory or 25) then
        return false, "Your inventory is full."
    end

    for _, item in ipairs(inventory) do
        if type(item) == "table" and item.Type == "Lasso" and item.Name == entry.Name then
            return false, "You already own that lasso."
        end
    end

    local coins = math.max(0, tonumber(entry.Coins) or 0)
    local gems = math.max(0, tonumber(entry.Gems) or 0)

    if data.Coins < coins or data.Gems < gems then
        return false, "You cannot afford that buyback."
    end

    if coins > 0 and not DataService:SpendCoins(player, coins) then return false, "Not enough Coins." end
    if gems > 0 and not DataService:SpendGems(player, gems) then
        if coins > 0 then DataService:AddCoins(player, coins) end
        return false, "Not enough Gems."
    end

    table.insert(inventory, {Type = "Lasso", Name = entry.Name, Quantity = 1})
    data.Lasso = entry.Name
    table.remove(data.LassoBuyback, tonumber(index))

    return true, tostring(entry.Name) .. " bought back and equipped."
end

function Service:GetPetSellValue(pet)
    if not pet then return nil end

    local template = Config.Pets[pet.Species]
    local rarity = Config.Rarities[pet.Rarity]
    if not template or not rarity then return nil end

    return math.floor(
        template.SellValue
        * rarity.SellMultiplier
        * (1 + ((math.max(1, tonumber(pet.Level) or 1) - 1) * 0.10))
        * (tonumber(Config.BeastTraderSellMultiplier) or 1)
    )
end

function Service:SellPet(player, petId)
    local data = DataService:Get(player)
    local pet = PetService:Find(player, petId)

    if not data or not pet then
        return false, "Pet not found."
    end
    if pet.Favourite then
        return false, "Favourite pets cannot be sold. Remove the favourite first."
    end

    local value = self:GetPetSellValue(pet)
    if not value then
        return false, "This pet cannot be traded."
    end

    ensureBuybacks(data)

    if data.DefencePetId == petId then data.DefencePetId = "" end
    if data.PodiumPetId == petId then data.PodiumPetId = "" end
    if data.EquippedPetId == petId then data.EquippedPetId = "" end

    local soldPet
    for index, owned in ipairs(data.Pets) do
        if owned.Id == petId then
            soldPet = cloneFlatTable(owned)
            table.remove(data.Pets, index)
            break
        end
    end

    if not soldPet then
        return false, "Pet not found."
    end

    local buybackPrice = math.max(value + 1, math.ceil(value * (tonumber(Config.BeastTraderBuybackMultiplier) or 1.25)))
    table.insert(data.PetBuyback, 1, {
        Pet = soldPet,
        SoldFor = value,
        BuybackPrice = buybackPrice,
        SoldAt = os.time()
    })
    while #data.PetBuyback > 10 do table.remove(data.PetBuyback) end

    -- Selling never grants pet XP. XP is awarded only by wild-pet combat kills.
    DataService:AddCoins(player, value)

    return value, "Sold " .. tostring(pet.Name or pet.Species) .. " for " .. tostring(value) .. " Coins."
end

function Service:BuybackPet(player, index)
    local data = DataService:Get(player)
    if not data then return false, "Player data unavailable." end

    ensureBuybacks(data)
    local numericIndex = tonumber(index)
    local entry = numericIndex and data.PetBuyback[numericIndex]
    if not entry or type(entry.Pet) ~= "table" then
        return false, "That pet is no longer available for buyback."
    end

    if #data.Pets >= (Config.MaxPets or 60) then
        return false, "Your pet backpack is full."
    end

    local price = math.max(0, tonumber(entry.BuybackPrice) or 0)
    if data.Coins < price then
        return false, "You need " .. tostring(price) .. " Coins to buy this pet back."
    end

    if not DataService:SpendCoins(player, price) then
        return false, "Not enough Coins."
    end

    local pet = cloneFlatTable(entry.Pet)
    pet.Displayed = false
    table.insert(data.Pets, pet)
    table.remove(data.PetBuyback, numericIndex)

    return true, "Bought " .. tostring(pet.Name or pet.Species) .. " back for " .. tostring(price) .. " Coins.", pet
end

return Service
