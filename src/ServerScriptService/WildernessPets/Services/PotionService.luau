local Config = require(game.ReplicatedStorage.WildernessPets.Shared.Config)

local DataService = require(script.Parent.PlayerDataService)
local PetService = require(script.Parent.PetService)
local ShopService = require(script.Parent.ShopService)

local Service = {}

local function effects(data)
    data.ActiveEffects = type(data.ActiveEffects) == "table" and data.ActiveEffects or {}
    return data.ActiveEffects
end

local function applyWalkSpeed(player)
    local data = DataService:Get(player)
    if not data then return end

    local active = effects(data)
    local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    if (tonumber(active.SpeedBoostUntil) or 0) > os.time() then
        humanoid.WalkSpeed = 16 * math.max(1, tonumber(active.PlayerSpeedMultiplier) or 1)
    else
        active.SpeedBoostUntil = 0
        active.PlayerSpeedMultiplier = 1
        active.PetSpeedMultiplier = 1
        humanoid.WalkSpeed = 16
    end
end

function Service:ApplyCharacterEffects(player)
    applyWalkSpeed(player)
end

function Service:BuyPotion(player, name)
    local item = Config.Potions and Config.Potions[name]
    local data = DataService:Get(player)
    if not item or not data then
        return false, "Potion unavailable."
    end

    local cost = math.max(0, tonumber(item.Coins) or 0)
    if data.Coins < cost then
        return false, "You need " .. tostring(cost) .. " Coins."
    end

    local added, reason = ShopService:AddInventoryItem(player, "Potion", name, 1)
    if not added then
        return false, reason or "Your inventory is full."
    end

    if cost > 0 and not DataService:SpendCoins(player, cost) then
        ShopService:ConsumeInventoryItem(player, "Potion", name, 1)
        return false, "Not enough Coins."
    end

    return true, tostring(name) .. " added to your inventory."
end

function Service:UsePotion(player, name, petId, context)
    local item = Config.Potions and Config.Potions[name]
    local data = DataService:Get(player)

    if not item or not data then
        return false, "Potion unavailable."
    end
    if ShopService:CountInventoryItem(player, "Potion", name) <= 0 then
        return false, "You do not own that potion."
    end

    context = type(context) == "table" and context or {}
    local active = effects(data)
    local itemType = item.Type

    if itemType == "XPBoost" then
        local duration = math.max(1, math.floor(tonumber(item.Duration) or 900))
        local currentUntil = math.max(os.time(), tonumber(active.XPBoostUntil) or 0)
        active.XPBoostUntil = currentUntil + duration
        active.XPBoostPercent = math.max(0, tonumber(item.Percent) or 0.25)

    elseif itemType == "SpeedBoost" then
        local duration = math.max(1, math.floor(tonumber(item.Duration) or 900))
        local currentUntil = math.max(os.time(), tonumber(active.SpeedBoostUntil) or 0)

        active.SpeedBoostUntil = currentUntil + duration
        active.PlayerSpeedMultiplier = math.max(1, tonumber(item.PlayerMultiplier) or 1.25)
        active.PetSpeedMultiplier = math.max(1, tonumber(item.PetMultiplier) or 1.25)

    elseif itemType == "Tranquiliser" then
        if active.NextCaptureTranquiliser then
            return false, "A tranquiliser is already prepared for your next capture."
        end
        active.NextCaptureTranquiliser = true

    elseif itemType == "Luck" then
        if active.NextCaptureLuck then
            return false, "A luck boost is already prepared for your next successful capture."
        end
        active.NextCaptureLuck = true

    elseif itemType == "TimedStatBoost" then
        local pet = PetService:Find(player, petId)
        if not pet then
            return false, "Select a pet first."
        end
        if pet.Dead then
            return false, "Dead pets must be collected from the Barn before using stat elixirs."
        end

        local duration = math.max(1, math.floor(tonumber(item.Duration) or 1800))
        local percent = math.max(0, tonumber(item.Percent) or 0.20)
        local stat = tostring(item.Stat or "")

        local untilField
        local percentField

        if stat == "Health" then
            untilField = "HealthBoostUntil"
            percentField = "HealthBoostPercent"
        elseif stat == "Power" then
            untilField = "PowerBoostUntil"
            percentField = "PowerBoostPercent"
        elseif stat == "Defence" then
            untilField = "DefenceBoostUntil"
            percentField = "DefenceBoostPercent"
        else
            return false, "Potion stat is invalid."
        end

        local before = PetService:GetEffectiveStats(pet)
        local currentUntil = math.max(os.time(), tonumber(pet[untilField]) or 0)

        pet[untilField] = currentUntil + duration
        pet[percentField] = percent

        local after = PetService:GetEffectiveStats(pet)

        if stat == "Health" then
            local gainedMaximum = math.max(0, after.Health - before.Health)
            pet.CurrentHealth = math.min(
                after.Health,
                (tonumber(pet.CurrentHealth) or before.Health) + gainedMaximum
            )
        end

    elseif itemType == "BattleHeal" then
        if not context.InCombat then
            return false, "Battle Health Potions can only be used while your equipped pet is fighting."
        end

        local pet = PetService:Find(player, petId)
        if not pet or pet.Dead then
            return false, "Your equipped pet cannot be healed."
        end

        local stats = PetService:GetEffectiveStats(pet)
        local current = math.max(0, tonumber(pet.CurrentHealth) or stats.Health)

        if current >= stats.Health then
            return false, "Your pet is already at full Health."
        end

        local heal = math.max(
            1,
            math.floor(stats.Health * math.max(0, tonumber(item.Percent) or 0.35) + 0.5)
        )
        pet.CurrentHealth = math.min(stats.Health, current + heal)

    elseif itemType == "InstantRevive" then
        if not context.BarnAllowed then
            return false, "Use an Instant Revive Potion at your Barn."
        end

        local ok, message = PetService:ReviveNow(player, petId)
        if not ok then return false, message end

    else
        return false, "That potion cannot be used yet."
    end

    if not ShopService:ConsumeInventoryItem(player, "Potion", name, 1) then
        return false, "Potion inventory changed before it could be used."
    end

    if itemType == "SpeedBoost" then
        applyWalkSpeed(player)

        local expiresAt = tonumber(active.SpeedBoostUntil) or os.time()
        task.delay(math.max(1, expiresAt - os.time() + 1), function()
            if player and player.Parent then
                applyWalkSpeed(player)
            end
        end)
    end

    return true, tostring(name) .. " used."
end

return Service
