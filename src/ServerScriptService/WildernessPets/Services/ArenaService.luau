local Players = game:GetService("Players")

local DataService = require(script.Parent.PlayerDataService)
local PetService = require(script.Parent.PetService)
local BattleService = require(script.Parent.BattleService)

local Service = {}

function Service:SetDefence(player, petId)
    local data = DataService:Get(player)
    local pet = PetService:Find(player, petId)

    if not data or not pet or pet.Dead then
        return false
    end

    data.DefencePetId = petId

    return true
end

function Service:GetDefence(player)
    local data = DataService:Get(player)

    if not data then
        return nil
    end

    return PetService:Find(player, data.DefencePetId)
end

function Service:GetPlayers()
    local result = {}

    for _, player in ipairs(Players:GetPlayers()) do
        local data = DataService:Get(player)

        if data then
            table.insert(result, {
                UserId = player.UserId,
                Name = player.Name,
                Rating = data.ArenaRating,
                DefencePetId = data.DefencePetId
            })
        end
    end

    return result
end

function Service:Attack(attacker, target)
    if attacker == target then
        return nil
    end

    local attackerData = DataService:Get(attacker)
    local targetData = DataService:Get(target)

    if not attackerData or not targetData then
        return nil
    end

    local attackingPet = PetService:GetBestPet(attacker)

    if not attackingPet then
        return nil
    end

    local defendingPet = PetService:Find(target, targetData.DefencePetId)

    if not defendingPet then
        defendingPet = PetService:GetBestPet(target)
    end

    if not defendingPet then
        return nil
    end

    local result = BattleService:Fight(attackingPet, defendingPet)

    attackingPet.Battles += 1
    defendingPet.Battles += 1

    if result.Winner == "A" then
        attackingPet.Wins += 1
        attackerData.ArenaWins += 1
        attackerData.WeeklyWins += 1
        attackerData.ArenaRating += 25

        -- Arena battles affect arena records only. Pet XP is reserved for
        -- defeating wild pets in overworld companion combat.
    else
        attackerData.ArenaLosses += 1
        attackerData.ArenaRating = math.max(0, attackerData.ArenaRating - 15)
    end

    return result
end

return Service
