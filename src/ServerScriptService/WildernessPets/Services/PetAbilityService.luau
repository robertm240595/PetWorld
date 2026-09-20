local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Root = ReplicatedStorage:WaitForChild("WildernessPets")
local GameRemote = Root.Remotes:WaitForChild("Game")
local Config = require(Root.Shared.Config)
local PetAbilities = require(Root.Shared.PetAbilities)
local EquipmentConfig = require(Root.Shared.EquipmentConfig)

local PetService = require(script.Parent.PetService)
local EquipmentRuntime = require(script.Parent.EquipmentRuntime)
local MonsterService = require(script.Parent.MonsterService)
local WorldBossRewardService = require(script.Parent.WorldBossRewardService)
local BossCombatService = require(script.Parent.BossCombatService)
local PetAnimator = require(script.Parent.Parent.Systems.PetAnimator)

local Service = {}

local cooldowns = {}
local petStates = {}
local equipmentAuraIds = {}
local targetStates = setmetatable({}, {__mode = "k"})
local rng = Random.new()

local function now()
    return os.clock()
end

local function livingTarget(target)
    return target
        and target:IsA("Model")
        and target.Parent
        and target:GetAttribute("Captured") ~= true
        and target:GetAttribute("Dead") ~= true
        and (tonumber(target:GetAttribute("Health")) or 0) > 0
end

local function targetPart(target)
    if not target then return nil end
    return target.PrimaryPart or target:FindFirstChildWhichIsA("BasePart", true)
end

local function petState(pet)
    local id = pet and tostring(pet.Id or "")
    if id == "" then return nil end

    local state = petStates[id]
    if not state then
        state = {
            Buffs = {},
            Shield = nil,
            Guard = nil,
            AvoidNextAttackUntil = 0,
            Harmful = {},
        }
        petStates[id] = state
    end
    return state
end

local function targetState(target)
    local state = targetStates[target]
    if not state then
        state = {
            Debuffs = {},
            Dots = {},
            Control = {},
        }
        targetStates[target] = state
    end
    return state
end

local function activeTimed(entry)
    return entry and (tonumber(entry.ExpiresAt) or 0) > now()
end

local function applyStrongestTimed(container, key, value, duration, source)
    value = math.max(0, tonumber(value) or 0)
    duration = math.max(0.05, tonumber(duration) or 0.05)

    local current = container[key]
    local expiresAt = now() + duration

    if activeTimed(current) then
        if value >= (tonumber(current.Value) or 0) then
            current.Value = value
            current.Source = source
        end
        current.ExpiresAt = math.max(tonumber(current.ExpiresAt) or 0, expiresAt)
        return current.Value, current.ExpiresAt
    end

    container[key] = {
        Value = value,
        ExpiresAt = expiresAt,
        Source = source,
    }
    return value, expiresAt
end

local function getTimedValue(container, key)
    local entry = container and container[key]
    if not activeTimed(entry) then
        if container then container[key] = nil end
        return 0
    end
    return math.max(0, tonumber(entry.Value) or 0)
end

local function getBaseDamage(pet)
    local level = math.max(1, tonumber(pet and pet.Level) or 1)
    local stats = PetService:GetEffectiveStats(pet)
    local power = math.max(1, tonumber(stats.Power) or 1)
    return math.max(1, power * (1 + (level - 1) * 0.06))
end

local function getControlDuration(target, family, baseDuration)
    local drConfig = PetAbilities.ControlDiminishingReturns or {}
    if not ((drConfig.Families or {})[family]) then
        return baseDuration
    end

    local state = targetState(target)
    local record = state.Control[family]
    local currentTime = now()
    local window = tonumber(drConfig.ResetAfter) or tonumber(drConfig.Window) or 20

    if not record or currentTime - (tonumber(record.LastAt) or 0) > window then
        record = {Count = 0, LastAt = currentTime}
        state.Control[family] = record
    end

    record.Count = math.max(0, tonumber(record.Count) or 0) + 1
    record.LastAt = currentTime

    local multipliers = drConfig.Multipliers or {1, 0.65, 0.4, 0.2}
    local tier = math.min(record.Count, #multipliers)
    local multiplier = tonumber(multipliers[tier]) or 0.2
    target:SetAttribute("StatusDR_" .. family, tier)
    target:SetAttribute("StatusDR_" .. family .. "_Until", workspace:GetServerTimeNow() + window)
    return math.max(0.1, baseDuration * multiplier)
end

local function applyDebuff(target, spec, sourceName)
    if not livingTarget(target) or type(spec) ~= "table" then return 0 end

    local statusType = tostring(spec.Type or "")
    if statusType == "" then return 0 end

    local duration = math.max(0.1, tonumber(spec.Duration) or 0.1)
    duration = getControlDuration(target, statusType, duration)

    local value = tonumber(spec.Value) or 0
    if statusType == "Blind" then
        value = math.max(value, tonumber(PetAbilities.BlindMissChance) or 0.80)
    elseif statusType == "Stun" then
        value = 1
    end

    local state = targetState(target)
    local appliedValue, expiresAt = applyStrongestTimed(
        state.Debuffs,
        statusType,
        value,
        duration,
        sourceName
    )

    target:SetAttribute(
        "Status_" .. statusType .. "_Until",
        workspace:GetServerTimeNow() + math.max(0, expiresAt - now())
    )
    target:SetAttribute("Status_" .. statusType .. "_Value", appliedValue)
    target:SetAttribute("Status_" .. statusType .. "_Source", tostring(sourceName or ""))
    return duration
end

local function damageRawTarget(player, target, damage)
    if not livingTarget(target) then return 0, false end

    damage = math.max(1, math.floor((tonumber(damage) or 0) + 0.5))
    local before = math.max(0, tonumber(target:GetAttribute("Health")) or 0)
    if before <= 0 then return 0, true end

    target:SetAttribute("LastHitUserId", player.UserId)

    local dealt
    if MonsterService:DamageMonster(target, damage) then
        dealt = math.min(before, damage)
    else
        local after = math.max(0, before - damage)
        target:SetAttribute("Health", after)
        dealt = before - after
    end

    if dealt > 0 and target:GetAttribute("WorldBoss") == true then
        WorldBossRewardService:RecordDamage(target, player, dealt)
    end
    if dealt > 0 and target:GetAttribute("BossAIManaged") == true then
        BossCombatService:RecordThreat(target, player, dealt)
    end

    return dealt, (tonumber(target:GetAttribute("Health")) or 0) <= 0
end

local function outgoingDamage(pet, target, rawDamage)
    local state = petState(pet)
    local powerBuff = getTimedValue(state and state.Buffs, "Power")
    local equipment = EquipmentConfig:GetBonuses(pet)

    local targetStatus = targetState(target)
    local sunder = getTimedValue(targetStatus.Debuffs, "Sunder")
    local expose = getTimedValue(targetStatus.Debuffs, "Expose")

    local defence = math.max(0, tonumber(target:GetAttribute("Defence")) or 0)
    defence *= math.max(0, 1 - sunder)

    -- Defence is intentionally capped so the new group-debuff system matters
    -- without making ordinary wild fights dramatically slower.
    local mitigation = math.min(0.45, defence * 0.003)

    local bossReduction = math.clamp(
        tonumber(target:GetAttribute("BossDamageReduction")) or 0,
        0,
        0.95
    )

    local bossDamage = target:GetAttribute("WorldBoss") == true
        and math.max(0, tonumber(equipment.BossDamage) or 0)
        or 0

    return math.max(
        1,
        rawDamage
            * (1 + powerBuff)
            * (1 - mitigation)
            * (1 + expose)
            * (1 - bossReduction)
            * (1 + bossDamage)
    )
end

function Service:DamageEnemy(player, pet, target, rawDamage)
    if not player or not pet or not livingTarget(target) then return 0, false end

    local damage = outgoingDamage(pet, target, math.max(1, tonumber(rawDamage) or 1))
    local dealt, killed = damageRawTarget(player, target, damage)

    if dealt > 0 then
        local equipment = EquipmentConfig:GetBonuses(pet)
        local lifesteal = math.max(0, tonumber(equipment.Lifesteal) or 0)
        if lifesteal > 0 and not pet.Dead then
            local stats = PetService:GetEffectiveStats(pet)
            local current = math.max(0, tonumber(pet.CurrentHealth) or stats.Health)
            local recovered = math.max(0, math.floor(dealt * lifesteal + 0.5))
            if recovered > 0 then
                pet.CurrentHealth = math.min(stats.Health, current + recovered)
            end
        end
    end

    return dealt, killed
end

function Service:DamageEnemyFlat(player, target, damage)
    if not player or not livingTarget(target) then return 0, false end

    local reduction = math.clamp(
        tonumber(target:GetAttribute("BossDamageReduction")) or 0,
        0,
        0.95
    )
    local adjusted = math.max(1, (tonumber(damage) or 1) * (1 - reduction))
    return damageRawTarget(player, target, adjusted)
end

local function applyDot(player, pet, target, spec, sourceName)
    if not livingTarget(target) or type(spec) ~= "table" then return end

    local dotType = tostring(spec.Type or "DamageOverTime")
    local scale = math.max(0, tonumber(spec.Scale) or 0)
    local equipment = EquipmentConfig:GetBonuses(pet)
    scale *= 1 + math.max(0, tonumber(equipment.DoTDamage) or 0)

    local duration = math.max(1, tonumber(spec.Duration) or 1)
    if scale <= 0 then return end

    local state = targetState(target)
    local current = state.Dots[dotType]
    local expiresAt = now() + duration
    local token

    if current and (tonumber(current.ExpiresAt) or 0) > now() then
        local previousScale = tonumber(current.Scale) or 0
        if scale >= previousScale then
            current.Scale = scale
            current.Player = player
            current.Pet = pet
            current.Source = sourceName
        end
        current.ExpiresAt = math.max(tonumber(current.ExpiresAt) or 0, expiresAt)
        current.Token = (tonumber(current.Token) or 0) + 1
        token = current.Token
    else
        current = {
            Scale = scale,
            ExpiresAt = expiresAt,
            Player = player,
            Pet = pet,
            Source = sourceName,
            Token = 1,
        }
        state.Dots[dotType] = current
        token = 1
    end

    target:SetAttribute(
        "Status_" .. dotType .. "_Until",
        workspace:GetServerTimeNow() + math.max(0, (tonumber(current.ExpiresAt) or expiresAt) - now())
    )
    target:SetAttribute("Status_" .. dotType .. "_Value", tonumber(current.Scale) or scale)
    target:SetAttribute("Status_" .. dotType .. "_Source", tostring(sourceName or ""))

    task.spawn(function()
        local last = now()
        while livingTarget(target) do
            local liveState = targetStates[target]
            local entry = liveState and liveState.Dots[dotType]
            if not entry or entry.Token ~= token then return end

            local currentTime = now()
            if currentTime >= (tonumber(entry.ExpiresAt) or 0) then
                liveState.Dots[dotType] = nil
                return
            end

            task.wait(1)
            if not livingTarget(target) then return end

            local nextState = targetStates[target]
            local nextEntry = nextState and nextState.Dots[dotType]
            if not nextEntry or nextEntry.Token ~= token then return end

            local elapsed = math.max(0.1, now() - last)
            last = now()
            local totalDuration = math.max(1, tonumber(spec.Duration) or 1)
            local tickRaw = getBaseDamage(pet)
                * math.max(0, tonumber(nextEntry.Scale) or scale)
                * math.min(elapsed, 1.25)
                / totalDuration

            Service:DamageEnemy(player, pet, target, tickRaw)
        end
    end)
end

local function setPetStatusAttribute(companion, prefix, statusType, value, duration, sourceName)
    if not companion or not companion.Parent then return end

    local key = tostring(prefix or "PetStatus") .. "_" .. tostring(statusType)
    companion:SetAttribute(key .. "_Until", workspace:GetServerTimeNow() + math.max(0.1, tonumber(duration) or 0.1))
    companion:SetAttribute(key .. "_Value", tonumber(value) or 0)
    companion:SetAttribute(key .. "_Source", tostring(sourceName or ""))
end

local function clearPetStatusAttributes(companion, prefix)
    if not companion or not companion.Parent then return end
    for name in pairs(companion:GetAttributes()) do
        if name:match("^" .. prefix .. "_") then
            companion:SetAttribute(name, nil)
        end
    end
end

local function applyBuff(pet, spec, sourceName, scale, companion)
    if not pet or type(spec) ~= "table" then return end

    local state = petState(pet)
    if not state then return end

    local value = math.max(0, tonumber(spec.Value) or 0) * (tonumber(scale) or 1)
    local duration = math.max(0.1, tonumber(spec.Duration) or 0.1)
    local appliedValue, expiresAt = applyStrongestTimed(
        state.Buffs,
        tostring(spec.Type),
        value,
        duration,
        sourceName
    )
    setPetStatusAttribute(
        companion,
        "PetStatus",
        tostring(spec.Type),
        appliedValue,
        math.max(0.1, expiresAt - now()),
        sourceName
    )
end

local function applyShield(pet, shieldSpec, scale, companion, sourceName)
    if not pet or type(shieldSpec) ~= "table" then return end

    local state = petState(pet)
    if not state then return end

    local stats = PetService:GetEffectiveStats(pet)
    local equipment = EquipmentConfig:GetBonuses(pet)
    local duration = math.max(0.1, tonumber(shieldSpec.Duration) or 0.1)
    local amount = math.max(
        1,
        stats.Health
            * math.max(0, tonumber(shieldSpec.Percent) or 0)
            * (tonumber(scale) or 1)
            * (1 + math.max(0, tonumber(equipment.ShieldPotency) or 0))
    )
    local expiresAt = now() + duration
    local reflect = math.max(0, tonumber(shieldSpec.ReflectPercent) or 0)
        * (1 + math.max(0, tonumber(equipment.ReflectStrength) or 0))

    local current = state.Shield
    if current and (tonumber(current.ExpiresAt) or 0) > now() then
        if amount >= (tonumber(current.Remaining) or 0) then
            current.Remaining = amount
            current.Maximum = amount
            current.ReflectPercent = reflect
        end
        current.ExpiresAt = math.max(tonumber(current.ExpiresAt) or 0, expiresAt)
    else
        state.Shield = {
            Remaining = amount,
            Maximum = amount,
            ReflectPercent = reflect,
            ExpiresAt = expiresAt,
        }
    end

    setPetStatusAttribute(companion, "PetStatus", "Shield", amount, duration, sourceName)
    if reflect > 0 then
        setPetStatusAttribute(companion, "PetStatus", "Reflect", reflect, duration, sourceName)
    end
end

local function applyGuard(pet, guardSpec, scale, companion, sourceName)
    if not pet or type(guardSpec) ~= "table" then return end

    local state = petState(pet)
    if not state then return end

    local equipment = EquipmentConfig:GetBonuses(pet)
    local duration = math.max(0.1, tonumber(guardSpec.Duration) or 0.1)
    local expiresAt = now() + duration
    local reduction = math.max(0, tonumber(guardSpec.DamageReductionPercent) or 0) * (tonumber(scale) or 1)
    local reflect = math.max(0, tonumber(guardSpec.ReflectPercent) or 0)
        * (tonumber(scale) or 1)
        * (1 + math.max(0, tonumber(equipment.ReflectStrength) or 0))

    local current = state.Guard
    if current and (tonumber(current.ExpiresAt) or 0) > now() then
        current.DamageReductionPercent = math.max(tonumber(current.DamageReductionPercent) or 0, reduction)
        current.ReflectPercent = math.max(tonumber(current.ReflectPercent) or 0, reflect)
        current.ExpiresAt = math.max(tonumber(current.ExpiresAt) or 0, expiresAt)
    else
        state.Guard = {
            DamageReductionPercent = reduction,
            ReflectPercent = reflect,
            ExpiresAt = expiresAt,
        }
    end

    if reduction > 0 then
        setPetStatusAttribute(companion, "PetStatus", "DamageReduction", reduction, duration, sourceName)
    end
    if reflect > 0 then
        setPetStatusAttribute(companion, "PetStatus", "Reflect", reflect, duration, sourceName)
    end
end

local function cleansePet(pet, mode, companion)
    local state = petState(pet)
    if not state then return end

    if mode == "All" then
        state.Harmful = {}
        clearPetStatusAttributes(companion, "PetDebuff")
        return
    end

    if mode == "DoT" then
        for key in pairs(state.Harmful) do
            if key == "Poison" or key == "Burn" or key == "Bleed" or key == "Frostbite" then
                state.Harmful[key] = nil
                if companion then
                    companion:SetAttribute("PetDebuff_" .. key .. "_Until", nil)
                    companion:SetAttribute("PetDebuff_" .. key .. "_Value", nil)
                    companion:SetAttribute("PetDebuff_" .. key .. "_Source", nil)
                end
            end
        end
        return
    end

    local key = next(state.Harmful)
    if key then
        state.Harmful[key] = nil
        if companion then
            companion:SetAttribute("PetDebuff_" .. key .. "_Until", nil)
            companion:SetAttribute("PetDebuff_" .. key .. "_Value", nil)
            companion:SetAttribute("PetDebuff_" .. key .. "_Source", nil)
        end
    end
end

function Service:ApplyPetDebuff(pet, companion, spec, sourceName)
    if not pet or type(spec) ~= "table" then return 0 end

    local statusType = tostring(spec.Type or "")
    if statusType == "" then return 0 end

    local state = petState(pet)
    if not state then return 0 end

    local equipment = EquipmentConfig:GetBonuses(pet)
    local resistance = math.clamp(
        tonumber(equipment.StatusResistance) or 0,
        0,
        tonumber(EquipmentConfig.StatCaps.StatusResistance) or 0.30
    )
    local duration = math.max(0.1, (tonumber(spec.Duration) or 0.1) * (1 - resistance))
    local value = math.max(0, tonumber(spec.Value) or 0)
    if statusType == "Blind" then
        value = math.max(value, tonumber(PetAbilities.BlindMissChance) or 0.80)
    end

    local appliedValue, expiresAt = applyStrongestTimed(
        state.Harmful,
        statusType,
        value,
        duration,
        sourceName
    )
    setPetStatusAttribute(
        companion,
        "PetDebuff",
        statusType,
        appliedValue,
        math.max(0.1, expiresAt - now()),
        sourceName
    )
    return duration
end

function Service:ApplyPetDot(pet, companion, spec, sourceName, onTick)
    if not pet or type(spec) ~= "table" or type(onTick) ~= "function" then return 0 end

    local statusType = tostring(spec.Type or "Poison")
    local equipment = EquipmentConfig:GetBonuses(pet)
    local resistance = math.clamp(
        tonumber(equipment.StatusResistance) or 0,
        0,
        tonumber(EquipmentConfig.StatCaps.StatusResistance) or 0.30
    )

    local perTick = math.max(0, tonumber(spec.PercentMaxHealth) or 0)
    local baseTicks = math.max(1, math.floor(tonumber(spec.Ticks) or 1))
    local ticks = math.max(1, math.ceil(baseTicks * (1 - resistance)))
    local interval = math.max(0.25, tonumber(spec.Interval) or 1)
    if perTick <= 0 then return 0 end

    local state = petState(pet)
    if not state then return 0 end

    local duration = ticks * interval
    local current = state.Harmful[statusType]
    local token

    if activeTimed(current) then
        current.Value = math.max(tonumber(current.Value) or 0, perTick)
        current.ExpiresAt = math.max(tonumber(current.ExpiresAt) or 0, now() + duration)
        current.Source = sourceName
        current.Token = (tonumber(current.Token) or 0) + 1
        token = current.Token
    else
        current = {
            Value = perTick,
            ExpiresAt = now() + duration,
            Source = sourceName,
            Token = 1,
        }
        state.Harmful[statusType] = current
        token = 1
    end

    setPetStatusAttribute(
        companion,
        "PetDebuff",
        statusType,
        current.Value,
        math.max(0.1, (tonumber(current.ExpiresAt) or (now() + duration)) - now()),
        sourceName
    )

    task.spawn(function()
        for _ = 1, ticks do
            task.wait(interval)

            local liveState = petState(pet)
            local entry = liveState and liveState.Harmful[statusType]
            if not entry or entry.Token ~= token or not activeTimed(entry) then return end
            if pet.Dead or (tonumber(pet.CurrentHealth) or 0) <= 0 then return end

            onTick(math.max(0, tonumber(entry.Value) or perTick))

            if pet.Dead or (tonumber(pet.CurrentHealth) or 0) <= 0 then return end
        end

        local liveState = petState(pet)
        local entry = liveState and liveState.Harmful[statusType]
        if entry and entry.Token == token then
            liveState.Harmful[statusType] = nil
        end
    end)

    return duration
end

function Service:RefreshEquipmentAuras(allSessions)
    local sources = {}
    local seen = {}

    for _, session in pairs(allSessions or {}) do
        if session
            and session.pet
            and not session.pet.Dead
            and session.companion
            and session.companion.Parent then
            table.insert(sources, session)
        end
    end

    local map = {
        AllyPowerAura = "Power",
        AllyDefenceAura = "Defence",
        AllyHealthAura = "Health",
        AllyAttackHasteAura = "AttackHaste",
    }

    for _, targetSession in ipairs(sources) do
        local targetPet = targetSession.pet
        local targetCompanion = targetSession.companion
        local targetPosition = targetCompanion:GetPivot().Position
        local best = {
            Power = 0,
            Defence = 0,
            Health = 0,
            AttackHaste = 0,
        }

        for _, sourceSession in ipairs(sources) do
            local sourceCompanion = sourceSession.companion
            local isSelf = sourceSession == targetSession
            local inRange = isSelf
                or (sourceCompanion:GetPivot().Position - targetPosition).Magnitude
                    <= (tonumber(EquipmentConfig.AuraRadius) or 25)

            if inRange then
                local sourceBonuses = EquipmentConfig:GetBonuses(sourceSession.pet)
                local scale = isSelf
                    and math.clamp(tonumber(EquipmentConfig.SelfAuraScale) or 0.50, 0, 1)
                    or 1

                for sourceStat, targetStat in pairs(map) do
                    best[targetStat] = math.max(
                        best[targetStat] or 0,
                        math.max(0, tonumber(sourceBonuses[sourceStat]) or 0) * scale
                    )
                end
            end
        end

        EquipmentRuntime:SetAuraBonuses(targetPet, best)

        local id = tostring(targetPet.Id or "")
        if id ~= "" then
            seen[id] = true
        end

        local stats = PetService:GetEffectiveStats(targetPet)
        if targetCompanion and targetCompanion.Parent then
            targetCompanion:SetAttribute("MaxHealth", stats.Health)
            targetCompanion:SetAttribute("Health", targetPet.CurrentHealth)
            targetCompanion:SetAttribute("EquipmentAuraPower", best.Power)
            targetCompanion:SetAttribute("EquipmentAuraDefence", best.Defence)
            targetCompanion:SetAttribute("EquipmentAuraHealth", best.Health)
            targetCompanion:SetAttribute("EquipmentAuraAttackHaste", best.AttackHaste)
        end
    end

    for id in pairs(equipmentAuraIds) do
        if not seen[id] then
            EquipmentRuntime:ClearId(id)
        end
    end
    equipmentAuraIds = seen
end

function Service:ClearEquipmentAura(pet)
    local id = pet and tostring(pet.Id or "") or ""
    if id ~= "" then
        EquipmentRuntime:ClearId(id)
        equipmentAuraIds[id] = nil
    end
end

function Service:GetPetAttackIntervalMultiplier(pet)
    local state = petState(pet)
    local equipment = EquipmentConfig:GetBonuses(pet)
    local aura = EquipmentRuntime:GetAuraBonuses(pet)

    local haste = getTimedValue(state and state.Buffs, "AttackHaste")
        + math.max(0, tonumber(equipment.AttackHaste) or 0)
        + math.max(0, tonumber(aura.AttackHaste) or 0)

    local slow = math.clamp(getTimedValue(state and state.Harmful, "AttackSlow"), 0, 0.75)
    return (1 / math.max(1, 1 + haste)) * (1 / math.max(0.25, 1 - slow))
end

function Service:PetAttackMisses(pet)
    local state = petState(pet)
    local blind = getTimedValue(state and state.Harmful, "Blind")
    if blind <= 0 then return false end
    return rng:NextNumber() < math.clamp(blind, 0, 0.95)
end

function Service:IsEnemyStunned(target)
    if not livingTarget(target) then return false end
    local state = targetState(target)
    return getTimedValue(state.Debuffs, "Stun") > 0
end

function Service:EnemyAttackMisses(target)
    if not livingTarget(target) then return true end

    local state = targetState(target)
    local blind = getTimedValue(state.Debuffs, "Blind")
    if blind <= 0 then return false end

    return rng:NextNumber() < math.clamp(blind, 0, 0.95)
end

function Service:GetEnemyAttackIntervalMultiplier(target)
    if not livingTarget(target) then return 1 end
    local state = targetState(target)
    local slow = math.clamp(getTimedValue(state.Debuffs, "AttackSlow"), 0, 0.75)
    return 1 / math.max(0.25, 1 - slow)
end

function Service:GetEnemyDamageMultiplier(target)
    if not livingTarget(target) then return 1 end
    local state = targetState(target)
    local weaken = math.clamp(getTimedValue(state.Debuffs, "Weaken"), 0, 0.75)
    return math.max(0.25, 1 - weaken)
end

function Service:ResolveIncomingPetDamage(pet, target, rawDamage)
    local state = petState(pet)
    if not state then return math.max(0, rawDamage), 0, false end

    if (tonumber(state.AvoidNextAttackUntil) or 0) > now() then
        state.AvoidNextAttackUntil = 0
        return 0, 0, true
    end

    local incoming = math.max(0, tonumber(rawDamage) or 0) * self:GetEnemyDamageMultiplier(target)
    local equipment = EquipmentConfig:GetBonuses(pet)

    if target and target:GetAttribute("WorldBoss") == true then
        incoming *= 1 - math.clamp(
            tonumber(equipment.BossDamageReduction) or 0,
            0,
            tonumber(EquipmentConfig.StatCaps.BossDamageReduction) or 0.20
        )
    end

    local reduction = getTimedValue(state.Buffs, "DamageReduction")
    local guard = state.Guard
    local guardReflect = 0

    if guard and (tonumber(guard.ExpiresAt) or 0) > now() then
        reduction = math.max(reduction, tonumber(guard.DamageReductionPercent) or 0)
        guardReflect = math.max(0, tonumber(guard.ReflectPercent) or 0)
    else
        state.Guard = nil
    end

    incoming *= math.max(0.05, 1 - math.clamp(reduction, 0, 0.80))

    local reflected = 0
    local shield = state.Shield
    if shield and (tonumber(shield.ExpiresAt) or 0) > now() and (tonumber(shield.Remaining) or 0) > 0 then
        local absorbed = math.min(incoming, tonumber(shield.Remaining) or 0)
        shield.Remaining = math.max(0, (tonumber(shield.Remaining) or 0) - absorbed)
        incoming -= absorbed
        reflected += absorbed * math.max(0, tonumber(shield.ReflectPercent) or 0)

        if shield.Remaining <= 0 then
            state.Shield = nil
        end
    else
        state.Shield = nil
    end

    reflected += incoming * guardReflect

    return math.max(0, math.floor(incoming + 0.5)), math.max(0, math.floor(reflected + 0.5)), false
end

function Service:GetCooldownRemaining(pet, slot)
    local petId = pet and tostring(pet.Id or "")
    if petId == "" then return 0 end

    local byPet = cooldowns[petId]
    local expiresAt = byPet and tonumber(byPet[slot]) or 0
    return math.max(0, expiresAt - now())
end

local function startCooldown(pet, slot, seconds)
    local petId = tostring(pet.Id)
    cooldowns[petId] = cooldowns[petId] or {}

    local equipment = EquipmentConfig:GetBonuses(pet)
    local reduction = math.clamp(
        tonumber(equipment.CooldownReduction) or 0,
        0,
        tonumber(EquipmentConfig.StatCaps.CooldownReduction) or 0.25
    )
    local actual = math.max(0.1, (tonumber(seconds) or 0.1) * (1 - reduction))
    cooldowns[petId][slot] = now() + actual
    return actual
end

local function enemyAbilityRequiresTarget(info)
    if info.DamageScale or info.Dot then return true end
    if type(info.Debuffs) == "table" and #info.Debuffs > 0 then return true end
    return false
end

local function applySelfEffects(pet, companion, info, scale)
    for _, spec in ipairs(info.Buffs or {}) do
        applyBuff(pet, spec, info.Name, scale, companion)
    end

    if info.Shield then
        applyShield(pet, info.Shield, scale, companion, info.Name)
    end

    if info.Guard then
        applyGuard(pet, info.Guard, scale, companion, info.Name)
    end

    if info.AvoidNextAttack then
        local duration = (info.Shield and info.Shield.Duration) or 7
        local state = petState(pet)
        state.AvoidNextAttackUntil = math.max(
            tonumber(state.AvoidNextAttackUntil) or 0,
            now() + duration
        )
        setPetStatusAttribute(companion, "PetStatus", "Evade", 1, duration, info.Name)
    end
end

local function applyAura(casterSession, info, allSessions)
    local companion = casterSession.companion
    if not companion or not companion.Parent then return 0 end

    local origin = companion:GetPivot().Position
    local radius = math.max(1, tonumber(info.Radius) or 25)
    local count = 0
    local engagedCount = 0
    local casterEquipment = EquipmentConfig:GetBonuses(casterSession.pet)
    local buffPotency = math.max(0, tonumber(casterEquipment.BuffPotency) or 0)

    for allyPlayer, session in pairs(allSessions or {}) do
        if session.pet
            and not session.pet.Dead
            and session.companion
            and session.companion.Parent then

            local distance = (session.companion:GetPivot().Position - origin).Magnitude
            if distance <= radius then
                local isSelf = session == casterSession
                if not isSelf or info.IncludeSelf == true then
                    local scale = isSelf and math.clamp(tonumber(info.SelfScale) or 1, 0, 1) or 1
                    scale *= 1 + buffPotency
                    applySelfEffects(session.pet, session.companion, info, scale)
                    count += 1
                    if not isSelf
                        and session.attacking
                        and casterSession.target
                        and session.target == casterSession.target then
                        engagedCount += 1
                    end

                    if not isSelf and typeof(allyPlayer) == "Instance" and allyPlayer:IsA("Player") then
                        GameRemote:FireClient(
                            allyPlayer,
                            "Combat",
                            "SupportBuff",
                            info.Name,
                            casterSession.pet and (casterSession.pet.Name or casterSession.pet.Species) or "An ally"
                        )
                    end
                end
            end
        end
    end

    return count, engagedCount
end

local function healPet(session, info)
    local pet = session.pet
    if not pet or pet.Dead then return 0 end

    local stats = PetService:GetEffectiveStats(pet)
    local equipment = EquipmentConfig:GetBonuses(pet)
    local current = math.max(0, tonumber(pet.CurrentHealth) or stats.Health)
    local amount = math.max(
        1,
        math.floor(
            stats.Health
                * math.max(0, tonumber(info.HealPercent) or 0)
                * (1 + math.max(0, tonumber(equipment.HealingPotency) or 0))
                + 0.5
        )
    )
    local healed = math.min(amount, math.max(0, stats.Health - current))

    pet.CurrentHealth = math.min(stats.Health, current + amount)
    if session.companion and session.companion.Parent then
        session.companion:SetAttribute("Health", pet.CurrentHealth)
        session.companion:SetAttribute("MaxHealth", stats.Health)
    end

    if info.Cleanse then
        cleansePet(pet, info.Cleanse, session.companion)
    end

    return healed
end

function Service:UseAbility(player, session, slot, allSessions)
    if slot ~= 1 and slot ~= 2 and slot ~= 3 then
        return false, "Invalid ability slot.", 0, false
    end
    if not session or not session.pet or not session.companion or not session.companion.Parent then
        return false, "Equip a companion first.", 0, false
    end

    local pet = session.pet
    if pet.Dead or (tonumber(pet.CurrentHealth) or 0) <= 0 then
        return false, "Your companion must be healed first.", 0, false
    end

    local kit = PetAbilities:Get(pet.Species)
    local info = kit and kit[slot]
    if not info then
        return false, "This pet does not have that ability.", 0, false
    end

    local remaining = self:GetCooldownRemaining(pet, slot)
    if remaining > 0 then
        return false, info.Name .. " is ready in " .. tostring(math.ceil(remaining)) .. "s.", remaining, false
    end

    if session.abilityBusy then
        return false, "Your companion is already using an ability.", 0, false
    end

    local target = session.target
    if enemyAbilityRequiresTarget(info) then
        if not livingTarget(target) then
            return false, "Select a living enemy first.", 0, false
        end

        local part = targetPart(target)
        if not part then return false, "That target cannot be reached.", 0, false end

        local distance = (part.Position - session.companion:GetPivot().Position).Magnitude
        if distance > 14 then
            return false, "Wait until your companion is closer to the target.", 0, false
        end
    end

    session.abilityBusy = true
    local killed = false
    local totalDamage = 0
    local summary = {}

    local ok, err = pcall(function()
        if info.AllyAura then
            local count, engagedCount = applyAura(session, info, allSessions)
            table.insert(summary, "affected " .. tostring(count) .. " allied pet" .. (count == 1 and "" or "s"))

            if target and target:GetAttribute("WorldBoss") == true and engagedCount > 0 then
                local maximum = math.max(1, tonumber(target:GetAttribute("MaxHealth")) or 1)
                local supportScore = maximum * 0.006 * engagedCount
                WorldBossRewardService:RecordSupport(target, player, supportScore)
                BossCombatService:RecordSupportThreat(target, player, supportScore)
            end
        else
            applySelfEffects(pet, session.companion, info, 1)
        end

        if info.HealPercent then
            local healed = healPet(session, info)
            table.insert(summary, "healed " .. tostring(healed) .. " HP")

            if target and target:GetAttribute("WorldBoss") == true and healed > 0 then
                local maximum = math.max(1, tonumber(target:GetAttribute("MaxHealth")) or 1)
                local supportScore = maximum * 0.003
                WorldBossRewardService:RecordSupport(target, player, supportScore)
                BossCombatService:RecordSupportThreat(target, player, supportScore)
            end
        end

        if enemyAbilityRequiresTarget(info) then
            local part = targetPart(target)

            if info.DamageScale and part then
                local damageScale = math.max(0, tonumber(info.DamageScale) or 0)
                if info.ExecuteDamageScale then
                    local hp = math.max(0, tonumber(target:GetAttribute("Health")) or 0)
                    local maximum = math.max(1, tonumber(target:GetAttribute("MaxHealth")) or hp)
                    if hp / maximum <= math.max(0, tonumber(info.ExecuteHealthPercent) or 0.30) then
                        damageScale = math.max(damageScale, tonumber(info.ExecuteDamageScale) or damageScale)
                    end
                end
                local equipment = EquipmentConfig:GetBonuses(pet)
                local raw = getBaseDamage(pet)
                    * damageScale
                    * (1 + math.max(0, tonumber(equipment.AbilityDamage) or 0))

                local dealt
                local function strike()
                    dealt, killed = Service:DamageEnemy(player, pet, target, raw)
                    totalDamage += dealt
                end

                local okAnimation, played = pcall(function()
                    return PetAnimator:PlayAttack(
                        session.companion,
                        part.Position,
                        0.55,
                        strike,
                        0.9
                    )
                end)
                if not okAnimation or played ~= true then
                    strike()
                end
            end

            local appliedDebuffCount = 0
            local equipment = EquipmentConfig:GetBonuses(pet)
            local debuffPotency = math.max(0, tonumber(equipment.DebuffPotency) or 0)

            for _, spec in ipairs(info.Debuffs or {}) do
                local appliedSpec = spec
                if type(spec) == "table"
                    and (
                        spec.Type == "Sunder"
                        or spec.Type == "Expose"
                        or spec.Type == "Weaken"
                        or spec.Type == "AttackSlow"
                    )
                    and debuffPotency > 0 then
                    appliedSpec = {}
                    for key, value in pairs(spec) do
                        appliedSpec[key] = value
                    end
                    appliedSpec.Value = math.max(0, tonumber(spec.Value) or 0)
                        * (1 + debuffPotency)
                end

                local appliedDuration = applyDebuff(target, appliedSpec, info.Name)
                if appliedDuration > 0 then
                    appliedDebuffCount += 1
                end
            end

            if target:GetAttribute("WorldBoss") == true and appliedDebuffCount > 0 then
                local maximum = math.max(1, tonumber(target:GetAttribute("MaxHealth")) or 1)
                local supportScore = maximum * 0.004 * appliedDebuffCount
                WorldBossRewardService:RecordSupport(target, player, supportScore)
                BossCombatService:RecordSupportThreat(target, player, supportScore)
            end

            if info.Dot then
                applyDot(player, pet, target, info.Dot, info.Name)
            end

            if info.LifeStealPercent and totalDamage > 0 then
                local stats = PetService:GetEffectiveStats(pet)
                local current = math.max(0, tonumber(pet.CurrentHealth) or stats.Health)
                local healAmount = math.max(1, math.floor(totalDamage * math.max(0, tonumber(info.LifeStealPercent) or 0) + 0.5))
                pet.CurrentHealth = math.min(stats.Health, current + healAmount)
                if session.companion and session.companion.Parent then
                    session.companion:SetAttribute("Health", pet.CurrentHealth)
                end
                table.insert(summary, "drained " .. tostring(healAmount) .. " HP")
            end
        end
    end)

    session.abilityBusy = false

    if not ok then
        warn("[WildernessPets] Ability " .. tostring(info.Name) .. ": " .. tostring(err))
        return false, "That ability failed to activate.", 0, false
    end

    local cooldown = startCooldown(
        pet,
        slot,
        math.max(0.1, tonumber(info.Cooldown) or 10)
    )

    if totalDamage > 0 then
        table.insert(summary, tostring(math.floor(totalDamage + 0.5)) .. " damage")
    end

    local message = info.Name
    if #summary > 0 then
        message ..= " — " .. table.concat(summary, " · ")
    end

    return true, message, cooldown, killed, info
end

function Service:PlayerRemoving(player)
    for _, pet in ipairs(PetService:GetPets(player) or {}) do
        local id = tostring(pet.Id or "")
        if id ~= "" then
            cooldowns[id] = nil
            petStates[id] = nil
            EquipmentRuntime:ClearId(id)
            equipmentAuraIds[id] = nil
        end
    end
end

return Service
