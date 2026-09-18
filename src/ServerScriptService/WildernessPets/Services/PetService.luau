local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")
local RunService = game:GetService("RunService")
local Config = require(game.ReplicatedStorage.WildernessPets.Shared.Config)
local DataService = require(script.Parent.PlayerDataService)

local Service = {}
local rng = Random.new()

local function nowUnix()
    return os.time()
end

local function ensurePetDefaults(pet)
    if type(pet) ~= "table" then return pet end

    pet.Favourite = pet.Favourite == true
    pet.Dead = pet.Dead == true
    pet.HealReadyAt = tonumber(pet.HealReadyAt) or 0
    pet.RenameCount = math.max(0, tonumber(pet.RenameCount) or 0)
    pet.Imprint = math.clamp(math.floor(tonumber(pet.Imprint) or 20), 20, 100)
    pet.Level = math.max(1, math.floor(tonumber(pet.Level) or 1))
    pet.XP = math.max(0, math.floor(tonumber(pet.XP) or 0))
    pet.Health = math.max(1, math.floor(tonumber(pet.Health) or 1))
    pet.Power = math.max(1, math.floor(tonumber(pet.Power) or 1))
    pet.Defence = math.max(0, math.floor(tonumber(pet.Defence) or 0))
    pet.UpgradePoints = math.max(0, math.floor(tonumber(pet.UpgradePoints) or 0))
    pet.Battles = math.max(0, math.floor(tonumber(pet.Battles) or 0))
    pet.Wins = math.max(0, math.floor(tonumber(pet.Wins) or 0))
    pet.Displayed = pet.Displayed == true

    if pet.Dead then
        pet.CurrentHealth = 0
        pet.Displayed = false
    else
        pet.CurrentHealth = math.clamp(
            tonumber(pet.CurrentHealth) or pet.Health,
            0,
            pet.Health
        )
        if pet.CurrentHealth <= 0 then
            pet.CurrentHealth = pet.Health
        end
    end

    return pet
end

function Service:GetPets(player)
    local data = DataService:Get(player)
    if not data then return {} end
    data.Pets = type(data.Pets) == "table" and data.Pets or {}
    for _, pet in ipairs(data.Pets) do
        ensurePetDefaults(pet)
    end
    return data.Pets
end

function Service:RollImprint(lucky)
    local imprinting = Config.Imprinting or {}
    local minimum = tonumber(imprinting.Min) or 20
    local maximum = tonumber(imprinting.Max) or 100
    local exponent = tonumber(imprinting.CurveExponent) or 2.25
    local rolls = lucky and math.max(2, math.floor(tonumber(imprinting.LuckRolls) or 3)) or 1

    local best = minimum
    for _ = 1, rolls do
        local roll = rng:NextNumber()
        local value = minimum + math.floor((roll ^ exponent) * (maximum - minimum) + 0.5)
        best = math.max(best, value)
    end

    return math.clamp(best, minimum, maximum)
end

function Service:Create(player, species, options)
    local data = DataService:Get(player)
    local template = Config.Pets[species]
    if not data or not template then return nil end
    data.Pets = type(data.Pets) == "table" and data.Pets or {}
    if #data.Pets >= (Config.MaxPets or 60) then return nil end

    options = type(options) == "table" and options or {}
    local imprint = math.clamp(
        math.floor(tonumber(options.Imprint) or self:RollImprint(options.Lucky == true)),
        tonumber((Config.Imprinting or {}).Min) or 20,
        tonumber((Config.Imprinting or {}).Max) or 100
    )
    local multiplier = 1 + imprint / 100

    local health = math.max(1, math.floor((tonumber(template.Health) or 1) * multiplier + 0.5))
    local power = math.max(1, math.floor((tonumber(template.Power) or 1) * multiplier + 0.5))
    local defence = math.max(0, math.floor((tonumber(template.Defence) or 0) * multiplier + 0.5))

    local pet = {
        Id = HttpService:GenerateGUID(false),
        Species = species,
        Name = species,
        Rarity = template.Rarity,
        Level = 1,
        XP = 0,
        Imprint = imprint,
        Health = health,
        CurrentHealth = health,
        Power = power,
        Defence = defence,
        UpgradePoints = 0,
        Battles = 0,
        Wins = 0,
        Displayed = false,
        Favourite = false,
        Dead = false,
        HealReadyAt = 0,
        RenameCount = 0
    }

    table.insert(data.Pets, pet)
    return pet
end

function Service:Find(player, petId)
    for _, pet in ipairs(self:GetPets(player)) do
        if pet.Id == petId then
            return ensurePetDefaults(pet)
        end
    end
end

function Service:RefreshHealing(player)
    local changed = false
    local currentTime = nowUnix()

    for _, pet in ipairs(self:GetPets(player)) do
        if pet.Dead and pet.HealReadyAt > 0 and pet.HealReadyAt <= currentTime then
            pet.Dead = false
            pet.HealReadyAt = 0
            pet.CurrentHealth = pet.Health
            changed = true
        end
    end

    return changed
end

function Service:GetHealingSeconds(pet)
    if not pet then return 0 end
    local rarity = Config.Rarities[pet.Rarity]
    local rank = rarity and tonumber(rarity.Rank) or 1
    return math.max(1, math.floor((Config.HealingBaseSeconds or 30) * math.max(1, pet.Level or 1) * math.max(1, rank)))
end

function Service:StartHealing(player, petId)
    self:RefreshHealing(player)
    local pet = self:Find(player, petId)
    if not pet then return false, "Pet not found." end
    if not pet.Dead then return false, "That pet is not dead." end
    if pet.HealReadyAt > nowUnix() then
        return false, "That pet is already healing."
    end

    local seconds = self:GetHealingSeconds(pet)
    pet.HealReadyAt = nowUnix() + seconds
    return true, "Healing started.", seconds
end

function Service:ReviveNow(player, petId)
    local pet = self:Find(player, petId)
    if not pet then return false, "Pet not found." end
    if not pet.Dead then return false, "That pet does not need reviving." end
    if pet.HealReadyAt <= nowUnix() then
        return false, "Place the pet in your Barn first."
    end

    pet.Dead = false
    pet.HealReadyAt = 0
    pet.CurrentHealth = pet.Health
    return true, "Pet revived."
end

function Service:MarkDead(player, petId)
    local data = DataService:Get(player)
    local pet = self:Find(player, petId)
    if not data or not pet then return false end

    pet.Dead = true
    pet.CurrentHealth = 0
    pet.Displayed = false
    pet.HealReadyAt = 0

    if data.EquippedPetId == petId then data.EquippedPetId = "" end
    if data.PodiumPetId == petId then data.PodiumPetId = "" end
    if data.DefencePetId == petId then data.DefencePetId = "" end

    return true
end

function Service:SetFavourite(player, petId, favourite)
    local pet = self:Find(player, petId)
    if not pet then return false, "Pet not found." end
    pet.Favourite = favourite == true
    return true, pet.Favourite and "Pet favourited." or "Pet removed from favourites."
end

function Service:AddXP(player, petId, amount)
    local pet = self:Find(player, petId)
    local data = DataService:Get(player)
    if not pet or not data or pet.Dead then return false end

    amount = math.max(0, math.floor(tonumber(amount) or 0))

    local effects = type(data.ActiveEffects) == "table" and data.ActiveEffects or {}
    if (tonumber(effects.XPBoostUntil) or 0) > nowUnix() then
        amount = math.floor(amount * (1 + math.max(0, tonumber(effects.XPBoostPercent) or 0)) + 0.5)
    end

    pet.XP += amount
    local leveled = 0

    while pet.XP >= pet.Level * 100 do
        pet.XP -= pet.Level * 100
        pet.Level += 1
        pet.UpgradePoints += 1
        leveled += 1
    end

    return true, leveled, amount
end

function Service:SetDisplayed(player, petId, displayed)
    self:RefreshHealing(player)
    local pet = self:Find(player, petId)
    if not pet then return false, "Pet not found." end
    if pet.Dead then return false, "Dead pets must be healed at your Barn first." end

    if displayed then
        local count = 0
        for _, other in ipairs(self:GetPets(player)) do
            if other.Displayed and not other.Dead then count += 1 end
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
    self:RefreshHealing(player)
    local result = {}
    local data = DataService:Get(player)
    if not data then return result end

    for _, pet in ipairs(self:GetPets(player)) do
        if pet.Displayed
            and not pet.Dead
            and pet.Id ~= data.EquippedPetId
            and pet.Id ~= data.PodiumPetId then
            table.insert(result, pet)
        end
    end

    return result
end

function Service:SetPodium(player, petId)
    self:RefreshHealing(player)
    local data = DataService:Get(player)
    local pet = self:Find(player, petId)
    if not data or not pet then return false, "Pet not found." end
    if pet.Dead then return false, "Dead pets cannot be placed on the podium." end

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
    if not pet or pet.Dead or pet.UpgradePoints <= 0 then return false end

    if stat == "Health" then
        pet.Health += 25
        pet.CurrentHealth = math.min(pet.Health, (pet.CurrentHealth or pet.Health) + 25)
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
    self:RefreshHealing(player)
    local best

    for _, pet in ipairs(self:GetPets(player)) do
        if not pet.Dead then
            if not best then
                best = pet
            else
                local a = pet.Power + pet.Health + pet.Defence
                local b = best.Power + best.Health + best.Defence
                if a > b then best = pet end
            end
        end
    end

    return best
end

return Service
