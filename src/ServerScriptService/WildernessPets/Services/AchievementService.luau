local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Root = ReplicatedStorage:WaitForChild("WildernessPets")
local Config = require(Root.Shared.AchievementConfig)
local DataService = require(script.Parent.PlayerDataService)

local Service = {}
local started = false

local function ensureRemote()
    local remotes = Root:WaitForChild("Remotes")
    local remote = remotes:FindFirstChild("Achievement")
    if not remote then
        remote = Instance.new("RemoteEvent")
        remote.Name = "Achievement"
        remote.Parent = remotes
    end
    return remote
end

local Remote = ensureRemote()

local function countTrue(map)
    local count = 0
    if type(map) == "table" then
        for _, value in pairs(map) do
            if value == true then count += 1 end
        end
    end
    return count
end

local function completedMap(data)
    local root = type(data.QuestProgress) == "table" and data.QuestProgress or {}
    return type(root.Completed) == "table" and root.Completed or {}
end

local function conditionMet(data, condition)
    local kind = tostring(condition.Type or "")
    local value = tonumber(condition.Value) or 0
    if kind == "PetsOwned" then
        return type(data.Pets) == "table" and #data.Pets >= value
    elseif kind == "UniquePets" then
        return countTrue(data.PetCollection) >= value
    elseif kind == "MountsOwned" then
        return type(data.Mounts) == "table" and #data.Mounts >= value
    elseif kind == "LassoStrength" then
        return (tonumber(data.MaxLassoStrengthUnlocked) or 0) >= value
    elseif kind == "QuestsCompleted" then
        return countTrue(completedMap(data)) >= value
    elseif kind == "QuestCompleted" then
        return completedMap(data)[tostring(condition.Id or "")] == true
    elseif kind == "ArenaWins" then
        return (tonumber(data.ArenaWins) or 0) >= value
    elseif kind == "PetLevel" then
        for _, pet in ipairs(type(data.Pets) == "table" and data.Pets or {}) do
            if (tonumber(pet.Level) or 1) >= value then return true end
        end
    end
    return false
end

function Service:Evaluate(player)
    local data = DataService:Get(player)
    if not data then return {} end
    data.Achievements = type(data.Achievements) == "table" and data.Achievements or {}
    local unlocked = {}
    for _, achievement in ipairs(Config.List) do
        if not data.Achievements[achievement.Id] and conditionMet(data, achievement.Condition or {}) then
            data.Achievements[achievement.Id] = os.time()
            local reward = math.max(0, math.floor(tonumber(achievement.Gems) or 0))
            if reward > 0 then DataService:AddGems(player, reward) end
            table.insert(unlocked, achievement.Id)
            Remote:FireClient(player, "Unlocked", {
                Id = achievement.Id,
                Name = achievement.Name,
                Gems = reward,
            })
        end
    end
    return unlocked
end

function Service:GetState(player)
    self:Evaluate(player)
    local data = DataService:Get(player)
    local completed = data and data.Achievements or {}
    local state = {}
    for _, achievement in ipairs(Config.List) do
        table.insert(state, {
            Id = achievement.Id,
            Name = achievement.Name,
            Description = achievement.Description,
            Gems = achievement.Gems,
            Completed = completed[achievement.Id] ~= nil,
            CompletedAt = tonumber(completed[achievement.Id]) or 0,
        })
    end
    return state
end

function Service:PlayerReady(player)
    task.defer(function()
        task.wait(1)
        if player.Parent then self:Evaluate(player) end
    end)
end

function Service:Init()
    if started then return end
    started = true
    task.spawn(function()
        while true do
            task.wait(10)
            for _, player in ipairs(Players:GetPlayers()) do
                pcall(function() self:Evaluate(player) end)
            end
        end
    end)
end

return Service
