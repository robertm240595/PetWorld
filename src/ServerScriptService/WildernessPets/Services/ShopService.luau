local Config = require(game.ReplicatedStorage.WildernessPets.Shared.Config)

local DataService = require(script.Parent.PlayerDataService)
local PetService = require(script.Parent.PetService)

local Service = {}

function Service:BuyLasso(player, name)
    local item = Config.Lassos[name]
    local data = DataService:Get(player)

    if not item or not data then
        return false
    end

    local coinCost = item.Coins or 0
    local gemCost = item.Gems or 0

    if data.Coins < coinCost or data.Gems < gemCost then
        return false
    end

    DataService:SpendCoins(player, coinCost)
    DataService:SpendGems(player, gemCost)

    data.Lasso = name

    return true
end

function Service:SellPet(player, petId)
    local data = DataService:Get(player)
    local pet = PetService:Find(player, petId)

    if not data or not pet then
        return false
    end

    local template = Config.Pets[pet.Species]
    if not template then
        return false
    end

    local rarity = Config.Rarities[pet.Rarity]

    local value = math.floor(
        template.SellValue *
        rarity.SellMultiplier *
        (1 + ((pet.Level - 1) * 0.10))
    )

    for i, owned in ipairs(data.Pets) do
        if owned.Id == petId then
            table.remove(data.Pets, i)
            break
        end
    end

    DataService:AddCoins(player, value)

    return value
end

return Service
