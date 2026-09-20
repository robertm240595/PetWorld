local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Root = ReplicatedStorage:WaitForChild("WildernessPets")
local PetAnimator = require(script.Parent.Parent.Systems.PetAnimator)

local Service = {}

local callbacks = {}
local threat = setmetatable({}, {__mode = "k"})
local tokens = setmetatable({}, {__mode = "k"})
local nextBasicAt = setmetatable({}, {__mode = "k"})
local nextSpecialAt = setmetatable({}, {__mode = "k"})
local lastSoloHealAt = setmetatable({}, {__mode = "k"})
local lastThreatDecayAt = setmetatable({}, {__mode = "k"})
local respawnScheduled = setmetatable({}, {__mode = "k"})
local started = false
local wildMonsters
local rng = Random.new()

local function serverNow()
    return workspace:GetServerTimeNow()
end

local function clockNow()
    return os.clock()
end

local function bossPart(boss)
    if not boss or not boss.Parent then return nil end
    return boss.PrimaryPart or boss:FindFirstChildWhichIsA("BasePart", true)
end

local function isBoss(model)
    return model
        and model:IsA("Model")
        and model.Parent == wildMonsters
        and model:GetAttribute("BossAIManaged") == true
end

local function livingBoss(boss)
    return isBoss(boss)
        and boss:GetAttribute("Dead") ~= true
        and (tonumber(boss:GetAttribute("Health")) or 0) > 0
end

local function threatTable(boss)
    local data = threat[boss]
    if not data then
        data = setmetatable({}, {__mode = "k"})
        threat[boss] = data
    end
    return data
end

function Service:Configure(newCallbacks)
    callbacks = type(newCallbacks) == "table" and newCallbacks or {}
end

function Service:RecordThreat(boss, player, amount)
    if not isBoss(boss) or not player or not player.Parent then return end
    amount = math.max(0, tonumber(amount) or 0)
    if amount <= 0 then return end

    local data = threatTable(boss)
    data[player] = math.max(0, tonumber(data[player]) or 0) + amount
end

function Service:RecordSupportThreat(boss, player, amount)
    self:RecordThreat(boss, player, math.max(0, tonumber(amount) or 0) * 0.55)
end

local function activeCombatants(boss)
    if type(callbacks.GetCombatants) ~= "function" then return {} end
    local ok, result = pcall(callbacks.GetCombatants, boss)
    if not ok or type(result) ~= "table" then return {} end

    local active = {}
    for _, record in ipairs(result) do
        local player = record.Player
        local session = record.Session
        if player
            and player.Parent
            and session
            and session.pet
            and not session.pet.Dead
            and session.companion
            and session.companion.Parent
            and session.target == boss
            and session.attacking then
            table.insert(active, record)
        end
    end

    return active
end

local function decayThreat(boss)
    local current = clockNow()
    if current - (lastThreatDecayAt[boss] or 0) < 2 then return end
    lastThreatDecayAt[boss] = current

    local data = threatTable(boss)
    for player, value in pairs(data) do
        if not player.Parent then
            data[player] = nil
        else
            data[player] = math.max(0, (tonumber(value) or 0) * 0.96)
        end
    end
end

local function topThreatTarget(boss, active)
    local data = threatTable(boss)
    local best
    local bestValue = -math.huge

    for _, record in ipairs(active) do
        local value = tonumber(data[record.Player]) or 0
        if value > bestValue then
            best = record
            bestValue = value
        end
    end

    return best or active[1]
end

local function sortedByThreat(boss, active)
    local data = threatTable(boss)
    local copy = table.clone(active)
    table.sort(copy, function(a, b)
        return (tonumber(data[a.Player]) or 0) > (tonumber(data[b.Player]) or 0)
    end)
    return copy
end

local function setTelegraph(boss, name, seconds, targetUserId)
    boss:SetAttribute("BossTelegraph", tostring(name or ""))
    boss:SetAttribute("BossTelegraphUntil", serverNow() + math.max(0.1, tonumber(seconds) or 0.1))
    boss:SetAttribute("BossTelegraphTargetUserId", tonumber(targetUserId) or 0)
end

local function clearTelegraph(boss)
    if boss and boss.Parent then
        boss:SetAttribute("BossTelegraph", "")
        boss:SetAttribute("BossTelegraphUntil", 0)
        boss:SetAttribute("BossTelegraphTargetUserId", 0)
    end
end

local function bossPowerMultiplier(boss)
    local multiplier = math.max(0.1, tonumber(boss:GetAttribute("BossPowerMultiplier")) or 1)
    if boss:GetAttribute("BossEnraged") == true then
        multiplier *= 1.25
    end
    return multiplier
end

local function damageCompanion(record, boss, scale, attackName, effects)
    if not record or type(callbacks.DamageCompanion) ~= "function" then return false end

    local adjustedScale = math.max(0, tonumber(scale) or 1) * bossPowerMultiplier(boss)
    local ok, result = pcall(
        callbacks.DamageCompanion,
        record.Player,
        boss,
        adjustedScale,
        attackName,
        effects
    )

    return ok and result == true
end

local function playBossAttack(boss, record, duration, onImpact)
    local companion = record
        and record.Session
        and record.Session.companion

    local targetPart = companion and companion.PrimaryPart
    if not targetPart then
        if onImpact then onImpact() end
        return
    end

    local ok = pcall(function()
        PetAnimator:PlayAttack(
            boss,
            targetPart.Position,
            duration or 0.8,
            onImpact,
            1.3
        )
    end)

    if not ok and onImpact then
        onImpact()
    end
end

local function basicAttack(boss, active)
    local target = topThreatTarget(boss, active)
    if not target then return end

    local name = boss:GetAttribute("BossId") == "Jormungdyrr"
        and "Worldcoil Bite"
        or "Wyrm Bite"

    setTelegraph(boss, name, 0.55, target.Player.UserId)
    task.wait(0.35)
    if not livingBoss(boss) then return end

    playBossAttack(boss, target, 0.72, function()
        damageCompanion(target, boss, 1.0, name)
    end)

    clearTelegraph(boss)
end

local function wyrmSpecial(boss, active)
    local target = topThreatTarget(boss, active)
    if not target then return end

    local roll = rng:NextInteger(1, 3)

    if roll == 1 then
        setTelegraph(boss, "Fang Crush", 1.1, target.Player.UserId)
        task.wait(1.1)
        if not livingBoss(boss) then return end

        playBossAttack(boss, target, 0.75, function()
            damageCompanion(target, boss, 1.45, "Fang Crush")
        end)

    elseif roll == 2 then
        setTelegraph(boss, "Venom Rake", 1.0, target.Player.UserId)
        task.wait(1.0)
        if not livingBoss(boss) then return end

        playBossAttack(boss, target, 0.72, function()
            damageCompanion(target, boss, 0.75, "Venom Rake", {
                Dot = {
                    Type = "Poison",
                    PercentMaxHealth = 0.035,
                    Ticks = 4,
                    Interval = 1.25,
                },
            })
        end)

    else
        setTelegraph(boss, "Cave Quake", 1.35, target.Player.UserId)
        task.wait(1.35)
        if not livingBoss(boss) then return end

        damageCompanion(target, boss, 0.90, "Cave Quake", {
            PetDebuff = {
                Type = "AttackSlow",
                Value = 0.35,
                Duration = 5,
            },
        })
    end

    clearTelegraph(boss)
end

local function worldBossSpecial(boss, active)
    local target = topThreatTarget(boss, active)
    if not target then return end

    local roll = rng:NextInteger(1, 5)

    if roll == 1 then
        setTelegraph(boss, "Worldcoil Slam", 1.45, target.Player.UserId)
        task.wait(1.45)
        if not livingBoss(boss) then return end

        playBossAttack(boss, target, 0.85, function()
            damageCompanion(target, boss, 1.55, "Worldcoil Slam")
        end)

    elseif roll == 2 then
        setTelegraph(boss, "Venom Breath", 1.55, 0)
        task.wait(1.55)
        if not livingBoss(boss) then return end

        local ordered = sortedByThreat(boss, active)
        for index = 1, math.min(3, #ordered) do
            damageCompanion(ordered[index], boss, 0.65, "Venom Breath", {
                Dot = {
                    Type = "Poison",
                    PercentMaxHealth = 0.025,
                    Ticks = 5,
                    Interval = 1.35,
                },
            })
        end

    elseif roll == 3 then
        setTelegraph(boss, "Tail Crush", 1.6, 0)
        task.wait(1.6)
        if not livingBoss(boss) then return end

        local ordered = sortedByThreat(boss, active)
        for index = 1, math.min(3, #ordered) do
            damageCompanion(ordered[index], boss, 1.05, "Tail Crush", {
                PetDebuff = {
                    Type = "AttackSlow",
                    Value = 0.45,
                    Duration = 4,
                },
            })
        end

    elseif roll == 4 then
        setTelegraph(boss, "Devourer Gaze", 1.2, target.Player.UserId)
        task.wait(1.2)
        if not livingBoss(boss) then return end

        damageCompanion(target, boss, 0.35, "Devourer Gaze", {
            PetDebuff = {
                Type = "Blind",
                Value = 0.80,
                Duration = 6,
            },
        })

    else
        setTelegraph(boss, "Ragnarok Roar", 1.3, 0)
        task.wait(1.3)
        if not livingBoss(boss) then return end

        boss:SetAttribute("BossPowerMultiplier", 1.40)
        boss:SetAttribute("BossPowerBuffUntil", serverNow() + 10)

        task.delay(10, function()
            if boss.Parent
                and (tonumber(boss:GetAttribute("BossPowerBuffUntil")) or 0) <= serverNow() then
                boss:SetAttribute("BossPowerMultiplier", 1)
            end
        end)
    end

    clearTelegraph(boss)
end

local function clearBossStatuses(boss)
    for name in pairs(boss:GetAttributes()) do
        if name:match("^Status_")
            or name:match("^StatusDR_") then
            boss:SetAttribute(name, nil)
        end
    end
end

local function resetWorldBoss(boss)
    if not boss or not boss.Parent then return end

    clearBossStatuses(boss)
    threat[boss] = nil
    respawnScheduled[boss] = nil
    nextBasicAt[boss] = clockNow() + 2
    nextSpecialAt[boss] = clockNow() + 7

    local maximum = math.max(1, tonumber(boss:GetAttribute("MaxHealth")) or 1)
    boss:SetAttribute("Health", maximum)
    boss:SetAttribute("Dead", false)
    boss:SetAttribute("BossPouchesResolved", false)
    boss:SetAttribute("BossEnraged", false)
    boss:SetAttribute("BossSoloWard", false)
    boss:SetAttribute("BossDamageReduction", 0)
    boss:SetAttribute("BossPowerMultiplier", 1)
    boss:SetAttribute("BossPowerBuffUntil", 0)
    boss:SetAttribute("BossRespawnAt", 0)
    boss:SetAttribute("ActiveParticipants", 0)
    boss:SetAttribute("InCombat", false)
    clearTelegraph(boss)

    for _, item in ipairs(boss:GetDescendants()) do
        if item:IsA("BasePart") then
            item.Transparency = item:GetAttribute("OriginalTransparency")
                or item.Transparency
        end
    end
end

local function scheduleRespawn(boss)
    if respawnScheduled[boss] then return end
    respawnScheduled[boss] = true

    local seconds = math.max(30, tonumber(boss:GetAttribute("RespawnSeconds")) or 180)
    boss:SetAttribute("BossRespawnAt", serverNow() + seconds)
    boss:SetAttribute("ActiveParticipants", 0)
    boss:SetAttribute("BossSoloWard", false)
    boss:SetAttribute("BossDamageReduction", 0)
    clearTelegraph(boss)

    task.delay(seconds, function()
        if boss.Parent then
            resetWorldBoss(boss)
        end
    end)
end

local function updateSoloWard(boss, active)
    if boss:GetAttribute("BossId") ~= "Jormungdyrr" then
        boss:SetAttribute("BossSoloWard", false)
        boss:SetAttribute("BossDamageReduction", 0)
        return
    end

    local solo = #active < 2
    boss:SetAttribute("BossSoloWard", solo)
    boss:SetAttribute("BossDamageReduction", solo and 0.85 or 0)

    if not solo then return end

    local current = clockNow()
    if current - (lastSoloHealAt[boss] or 0) < 2 then return end
    lastSoloHealAt[boss] = current

    local maximum = math.max(1, tonumber(boss:GetAttribute("MaxHealth")) or 1)
    local health = math.max(0, tonumber(boss:GetAttribute("Health")) or 0)
    if health < maximum then
        boss:SetAttribute("Health", math.min(maximum, health + maximum * 0.02))
    end
end

local function updateEnrage(boss)
    if boss:GetAttribute("BossId") ~= "Jormungdyrr" then return end

    local maximum = math.max(1, tonumber(boss:GetAttribute("MaxHealth")) or 1)
    local health = math.max(0, tonumber(boss:GetAttribute("Health")) or 0)
    local enraged = health / maximum <= 0.30

    if enraged and boss:GetAttribute("BossEnraged") ~= true then
        boss:SetAttribute("BossEnraged", true)
        boss:SetAttribute("BossPhase", "ENRAGED")
    elseif not enraged and boss:GetAttribute("BossEnraged") == true then
        boss:SetAttribute("BossEnraged", false)
        boss:SetAttribute("BossPhase", "HUNTING")
    end
end

local function runBoss(boss)
    tokens[boss] = (tokens[boss] or 0) + 1
    local token = tokens[boss]

    nextBasicAt[boss] = clockNow() + 1.5
    nextSpecialAt[boss] = clockNow() + 5

    task.spawn(function()
        while boss.Parent == wildMonsters
            and tokens[boss] == token do

            local health = math.max(0, tonumber(boss:GetAttribute("Health")) or 0)
            if health <= 0 or boss:GetAttribute("Dead") == true then
                boss:SetAttribute("Dead", true)
                boss:SetAttribute("InCombat", false)

                if boss:GetAttribute("WorldBoss") == true then
                    scheduleRespawn(boss)
                end

                task.wait(0.5)
                continue
            end

            local active = activeCombatants(boss)
            boss:SetAttribute("ActiveParticipants", #active)

            if #active == 0 then
                boss:SetAttribute("InCombat", false)
                boss:SetAttribute("BossSoloWard", false)
                boss:SetAttribute("BossDamageReduction", 0)
                clearTelegraph(boss)
                task.wait(0.35)
                continue
            end

            boss:SetAttribute("InCombat", true)
            if boss:GetAttribute("BossPhase") == nil then
                boss:SetAttribute("BossPhase", "HUNTING")
            end

            decayThreat(boss)
            updateSoloWard(boss, active)
            updateEnrage(boss)

            local current = clockNow()
            local enraged = boss:GetAttribute("BossEnraged") == true

            if current >= (nextSpecialAt[boss] or 0) then
                nextSpecialAt[boss] = current + (enraged and 6.5 or 8.5)

                if boss:GetAttribute("BossId") == "Jormungdyrr" then
                    worldBossSpecial(boss, active)
                else
                    wyrmSpecial(boss, active)
                end

                nextBasicAt[boss] = clockNow() + 1.2

            elseif current >= (nextBasicAt[boss] or 0) then
                nextBasicAt[boss] = current + (enraged and 1.6 or 2.25)
                basicAttack(boss, active)
            end

            task.wait(0.12)
        end
    end)
end

local function watchBoss(model)
    if not isBoss(model) then return end

    for _, item in ipairs(model:GetDescendants()) do
        if item:IsA("BasePart") and item:GetAttribute("OriginalTransparency") == nil then
            item:SetAttribute("OriginalTransparency", item.Transparency)
        end
    end

    runBoss(model)
end

function Service:Init()
    if started then return end
    started = true

    local world = workspace:WaitForChild("WildernessPets")
    wildMonsters = world:WaitForChild("WildMonsters")

    for _, model in ipairs(wildMonsters:GetChildren()) do
        watchBoss(model)
    end

    wildMonsters.ChildAdded:Connect(function(child)
        task.defer(function()
            if child.Parent == wildMonsters then
                watchBoss(child)
            end
        end)
    end)
end

function Service:PlayerRemoving(player)
    for _, data in pairs(threat) do
        data[player] = nil
    end
end

return Service
