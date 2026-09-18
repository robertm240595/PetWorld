local Config = require(game.ReplicatedStorage.WildernessPets.Shared.Config)

local DataService = require(script.Parent.PlayerDataService)
local PetService = require(script.Parent.PetService)

local Service = {}

function Service:BuyLasso(player, name)
    local item = Config.Lassos[name]
    local data = DataService:Get(player)

    if not item or not data then
        return false, "Lasso unavailable."
    end

    data.Inventory = type(data.Inventory) == "table" and data.Inventory or {}

    for _, owned in ipairs(data.Inventory) do
        if type(owned) == "table" and owned.Type == "Lasso" and owned.Name == name then
            data.Lasso = name
            return true, "Lasso equipped."
        end
    end

    if #data.Inventory >= (Config.MaxInventory or 25) then
        return false, "Your inventory is full."
    end

    local coinCost = item.Coins or 0
    local gemCost = item.Gems or 0

    if data.Coins < coinCost or data.Gems < gemCost then
        return false, "You cannot afford that lasso."
    end

    if coinCost > 0 then DataService:SpendCoins(player, coinCost) end
    if gemCost > 0 then DataService:SpendGems(player, gemCost) end

    table.insert(data.Inventory, {
        Type = "Lasso",
        Name = name,
        Quantity = 1
    })

    data.Lasso = name

    return true, "Lasso purchased and equipped."
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

    local value = self:GetPetSellValue(pet)
    if not value then
        return false, "This pet cannot be traded."
    end

    if data.DefencePetId == petId then data.DefencePetId = "" end
    if data.PodiumPetId == petId then data.PodiumPetId = "" end
    if data.EquippedPetId == petId then data.EquippedPetId = "" end

    for i, owned in ipairs(data.Pets) do
        if owned.Id == petId then
            table.remove(data.Pets, i)
            break
        end
    end

    -- Selling never grants pet XP. XP is awarded only by wild-pet combat kills.
    DataService:AddCoins(player, value)

    return value, "Sold " .. tostring(pet.Name or pet.Species) .. " for " .. tostring(value) .. " Coins."
end

return Service
