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

    local template = Config.Pets[pet.Species]
    pet.Tradeable = pet.Tradeable ~= false
        and (not template or template.Tradeable ~= false)
    pet.VendorSellable = pet.VendorSellable ~= false
        and (not template or template.VendorSellable ~= false)

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

    pet.HealthBoostUntil = tonumber(pet.HealthBoostUntil) or 0
    pet.HealthBoostPercent = math.max(0, tonumber(pet.HealthBoostPercent) or 0)
    pet.PowerBoostUntil = tonumber(pet.PowerBoostUntil) or 0
    pet.PowerBoostPercent = math.max(0, tonumber(pet.PowerBoostPercent) or 0)
    pet.DefenceBoostUntil = tonumber(pet.DefenceBoostUntil) or 0
    pet.DefenceBoostPercent = math.max(0, tonumber(pet.DefenceBoostPercent) or 0)

    if pet.Dead then
        pet.CurrentHealth = 0
        pet.Displayed = false
    else
        local currentHealth = tonumber(pet.CurrentHealth)
        if currentHealth == nil then
            currentHealth = pet.Health
        end
        pet.CurrentHealth = math.max(0, currentHealth)
    end

    return pet
end

local function timedMultiplier(untilTime, percent, atTime)
    if (tonumber(untilTime) or 0) > atTime then
        return 1 + math.max(0, tonumber(percent) or 0)
    end
    return 1
end

function Service:GetEffectiveStats(pet, atTime)
    if type(pet) ~= "table" then
        return {Health = 1, Power = 1, Defence = 0}
    end

    ensurePetDefaults(pet)
    atTime = tonumber(atTime) or nowUnix()

    local effectiveHealth = math.max(
        1,
        math.floor(
            pet.Health
            * timedMultiplier(pet.HealthBoostUntil, pet.HealthBoostPercent, atTime)
            + 0.5
        )
    )
    local effectivePower = math.max(
        1,
        math.floor(
            pet.Power
            * timedMultiplier(pet.PowerBoostUntil, pet.PowerBoostPercent, atTime)
            + 0.5
        )
    )
    local effectiveDefence = math.max(
        0,
        math.floor(
            pet.Defence
            * timedMultiplier(pet.DefenceBoostUntil, pet.DefenceBoostPercent, atTime)
            + 0.5
        )
    )

    if not pet.Dead then
        pet.CurrentHealth = math.clamp(
            tonumber(pet.CurrentHealth) or effectiveHealth,
            0,
            effectiveHealth
        )
    end

    return {
        Health = effectiveHealth,
        Power = effectivePower,
        Defence = effectiveDefence
    }
end

function Service:GetPets(player)
    local data = DataService:Get(player)
    if not data then return {} end

    data.Pets = type(data.Pets) == "table" and data.Pets or {}
    for _, pet in ipairs(data.Pets) do
        ensurePetDefaults(pet)
        self:GetEffectiveStats(pet)
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
        AcquiredFrom = options.AcquiredFrom or "Capture",
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
        Tradeable = template.Tradeable ~= false,
        VendorSellable = template.VendorSellable ~= false,
        Dead = false,
        HealReadyAt = 0,
        RenameCount = 0,
        HealthBoostUntil = 0,
        HealthBoostPercent = 0,
        PowerBoostUntil = 0,
        PowerBoostPercent = 0,
        DefenceBoostUntil = 0,
        DefenceBoostPercent = 0
    }

    table.insert(data.Pets, pet)

    if template.Legacy ~= true and template.SpawnMode ~= "Legacy" then
        data.PetCollection = type(data.PetCollection) == "table" and data.PetCollection or {}
        data.PetCollection[species] = true
    end

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
    -- Healing no longer auto-collects pets. A completed timer means the pet is
    -- ready at the Barn, but it stays unavailable until the owner returns.
    for _, pet in ipairs(self:GetPets(player)) do
        ensurePetDefaults(pet)
    end
    return false
end

function Service:IsHealingReady(pet)
    if not pet then return false end
    ensurePetDefaults(pet)
    return pet.Dead
        and pet.HealReadyAt > 0
        and pet.HealReadyAt <= nowUnix()
end

function Service:GetHealingSeconds(pet)
    if not pet then return 0 end
    local rarity = Config.Rarities[pet.Rarity]
    local rank = rarity and tonumber(rarity.Rank) or 1

    return math.max(
        1,
        math.floor(
            (Config.HealingBaseSeconds or 30)
            * math.max(1, pet.Level or 1)
            * math.max(1, rank)
        )
    )
end

function Service:StartHealing(player, petId, overrideSeconds)
    local pet = self:Find(player, petId)
    if not pet then return false, "Pet not found." end
    if not pet.Dead then return false, "That pet is not dead." end

    if pet.HealReadyAt > 0 then
        if pet.HealReadyAt <= nowUnix() then
            return false, "That pet is healed. Collect it from the Barn."
        end
        return false, "That pet is already healing."
    end

    local seconds
    if overrideSeconds ~= nil then
        seconds = math.max(0, math.floor(tonumber(overrideSeconds) or 0))
    else
        seconds = self:GetHealingSeconds(pet)
    end

    pet.HealReadyAt = nowUnix() + seconds
    if seconds <= 0 then
        return true, "Healing complete. Collect your pet from the Barn.", 0
    end
    return true, "Healing started.", seconds
end

function Service:CollectHealed(player, petId)
    local pet = self:Find(player, petId)
    if not pet then return false, "Pet not found." end
    if not pet.Dead then return false, "That pet has already been collected." end
    if pet.HealReadyAt <= 0 then return false, "Place the pet in your Barn first." end
    if pet.HealReadyAt > nowUnix() then
        return false, "That pet is still healing."
    end

    pet.Dead = false
    pet.HealReadyAt = 0
    local stats = self:GetEffectiveStats(pet)
    pet.CurrentHealth = stats.Health

    return true, tostring(pet.Name or pet.Species) .. " has been collected from the Barn."
end

function Service:ReviveNow(player, petId)
    local pet = self:Find(player, petId)
    if not pet then return false, "Pet not found." end
    if not pet.Dead then return false, "That pet does not need reviving." end
    if pet.HealReadyAt <= 0 then
        return false, "Place the pet in your Barn first."
    end
    if pet.HealReadyAt <= nowUnix() then
        return false, "That pet is already healed. Collect it from the Barn instead."
    end

    pet.Dead = false
    pet.HealReadyAt = 0
    local stats = self:GetEffectiveStats(pet)
    pet.CurrentHealth = stats.Health

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
        amount = math.floor(
            amount
            * (1 + math.max(0, tonumber(effects.XPBoostPercent) or 0))
            + 0.5
        )
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
    local pet = self:Find(player, petId)
    if not pet then return false, "Pet not found." end
    if pet.Dead then return false, "Dead pets must be collected from your Barn first." end

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
    if displayed and data.PodiumPetId == petId then
        data.PodiumPetId = ""
    end

    pet.Displayed = displayed == true
    return true
end

function Service:GetDisplayed(player)
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
        local stats = self:GetEffectiveStats(pet)
        pet.CurrentHealth = math.min(
            stats.Health,
            (tonumber(pet.CurrentHealth) or pet.Health) + 25
        )
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
    local best

    for _, pet in ipairs(self:GetPets(player)) do
        if not pet.Dead then
            local stats = self:GetEffectiveStats(pet)
            if not best then
                best = pet
            else
                local bestStats = self:GetEffectiveStats(best)
                local a = stats.Power + stats.Health + stats.Defence
                local b = bestStats.Power + bestStats.Health + bestStats.Defence
                if a > b then best = pet end
            end
        end
    end

    return best
end

return Service
