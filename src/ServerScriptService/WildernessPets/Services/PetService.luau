local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")
local RunService = game:GetService("RunService")
local Config = require(game.ReplicatedStorage.WildernessPets.Shared.Config)
local DataService = require(script.Parent.PlayerDataService)
local Service = {}

function Service:GetPets(player)
    local data = DataService:Get(player)
    return data and data.Pets or {}
end

function Service:Create(player, species)
    local data = DataService:Get(player)
    local template = Config.Pets[species]
    if not data or not template then return nil end
    if #data.Pets >= Config.MaxPets then return nil end
    local pet = {
        Id = HttpService:GenerateGUID(false),
        Species = species,
        Name = species,
        Rarity = template.Rarity,
        Level = 1,
        XP = 0,
        Health = template.Health,
        Power = template.Power,
        Defence = template.Defence,
        UpgradePoints = 0,
        Battles = 0,
        Wins = 0,
        Displayed = false,
        RenameCount = 0
    }
    table.insert(data.Pets, pet)
    return pet
end

function Service:Find(player, petId)
    local data = DataService:Get(player)
    if not data then return nil end
    for _, pet in ipairs(data.Pets) do
        if pet.Id == petId then return pet end
    end
end

function Service:AddXP(player, petId, amount)
    local pet = self:Find(player, petId)
    if not pet then return false end
    amount = math.max(0, math.floor(tonumber(amount) or 0))
    pet.XP += amount
    local leveled = 0
    while pet.XP >= pet.Level * 100 do
        pet.XP -= pet.Level * 100
        pet.Level += 1
        pet.UpgradePoints += 1
        leveled += 1
    end
    return true, leveled
end

function Service:SetDisplayed(player, petId, displayed)
    local pet = self:Find(player, petId)
    if not pet then return false, "Pet not found." end
    if displayed then
        local count = 0
        for _, other in ipairs(self:GetPets(player)) do
            if other.Displayed then count += 1 end
        end
        if not pet.Displayed and count >= 10 then
            return false, "Your plot can host 10 roaming pets."
        end
    end
    local data = DataService:Get(player)
    if displayed and data.PodiumPetId == petId then data.PodiumPetId = "" end
    pet.Displayed = displayed == true
    return true
end

function Service:GetDisplayed(player)
    local result = {}
    for _, pet in ipairs(self:GetPets(player)) do
        local data = DataService:Get(player)
        if pet.Displayed and pet.Id ~= data.EquippedPetId and pet.Id ~= data.PodiumPetId then table.insert(result, pet) end
    end
    return result
end

function Service:SetPodium(player, petId)
    local data = DataService:Get(player)
    local pet = self:Find(player, petId)
    if not data or not pet then return false, "Pet not found." end
    pet.Displayed = false
    data.PodiumPetId = petId
    return true
end

function Service:Rename(player, petId, name)
    local pet = self:Find(player, petId)
    if not pet then return false, "Pet not found." end

    name = tostring(name or "")
    name = name:gsub("^%s+", ""):gsub("%s+$", "")
    name = string.sub(name, 1, Config.MaxPetNameLength)

    if name == "" then
        return false, "Enter a name first."
    end
    if name == pet.Name then
        return false, "Choose a different name."
    end

    local filteredName = name
    if not RunService:IsStudio() then
        local ok, result = pcall(function()
            local filterResult = TextService:FilterStringAsync(name, player.UserId)
            return filterResult:GetNonChatStringForBroadcastAsync()
        end)
        if not ok or type(result) ~= "string" or result == "" then
            return false, "That name could not be used. Try another."
        end
        filteredName = string.sub(result, 1, Config.MaxPetNameLength)
    end

    local renameCount = math.max(0, tonumber(pet.RenameCount) or 0)
    local cost = renameCount >= 1 and math.max(0, tonumber(Config.PetRenameGemCost) or 0) or 0

    if cost > 0 and not DataService:SpendGems(player, cost) then
        return false, "You need " .. tostring(cost) .. " Gems to rename this pet again."
    end

    pet.Name = filteredName
    pet.RenameCount = renameCount + 1

    if cost > 0 then
        return true, "Pet renamed for " .. tostring(cost) .. " Gems.", cost
    end
    return true, "Pet renamed. Your first rename was free.", 0
end

function Service:Upgrade(player, petId, stat)
    local pet = self:Find(player, petId)
    if not pet or pet.UpgradePoints <= 0 then return false end
    if stat == "Health" then
        pet.Health += 25
    elseif stat == "Power" then
        pet.Power += 5
    elseif stat == "Defence" then
        pet.Defence += 5
    else
        return false
    end
    pet.UpgradePoints -= 1
    return true
end

function Service:GetBestPet(player)
    local pets = self:GetPets(player)
    local best
    for _, pet in ipairs(pets) do
        if not best then
            best = pet
        else
            local a = pet.Power + pet.Health + pet.Defence
            local b = best.Power + best.Health + best.Defence
            if a > b then best = pet end
        end
    end
    return best
end

return Service
