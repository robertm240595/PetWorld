local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Root = ReplicatedStorage:WaitForChild("WildernessPets")
local LootRemote = Root.Remotes:WaitForChild("Loot")
local Config = require(Root.Shared.Config)

local DataService = require(script.Parent.PlayerDataService)
local PetService = require(script.Parent.PetService)
local MountService = require(script.Parent.MountService)

local Service = {}
local started = false
local lootFolder
local rng = Random.new()
local encounters = {}
local pouches = {}

local function rules()
    return Config.WorldBossRewardRules or {}
end

local function bossPetSpecies(bossSpecies)
    local info = Config.Pets and Config.Pets[bossSpecies]
    if info and info.SpawnMode == "WorldBoss" and info.Rarity == "Ancient" then
        return bossSpecies
    end
    return nil
end

local function rollAncientMount()
    local pool = rules().AncientMountPool or {}
    if #pool == 0 then return nil end
    return pool[rng:NextInteger(1, #pool)]
end

local function rewardRoll(bossSpecies, baseRewards)
    baseRewards = type(baseRewards) == "table" and baseRewards or {}
    local reward = {
        Coins = math.max(0, math.floor(tonumber(baseRewards.Coins) or 0)),
        Items = type(baseRewards.Items) == "table" and baseRewards.Items or {},
        AncientPet = nil,
        AncientMount = nil,
    }

    if rng:NextNumber() <= (tonumber(rules().AncientPetDropChance) or 0.0001) then
        reward.AncientPet = bossPetSpecies(bossSpecies)
    end
    if rng:NextNumber() <= (tonumber(rules().AncientMountDropChance) or 0.0001) then
        reward.AncientMount = rollAncientMount()
    end

    return reward
end

local function removePouch(record)
    if not record then return end
    pouches[record.Id] = nil
    if record.Model and record.Model.Parent then
        record.Model:Destroy()
    end
end

local function pouchVisual(position, player)
    local model = Instance.new("Model")
    model.Name = "WorldBossPouch"

    local pouch = Instance.new("Part")
    pouch.Name = "Pouch"
    pouch.Shape = Enum.PartType.Ball
    pouch.Size = Vector3.new(2.8, 3.0, 2.4)
    pouch.Color = Color3.fromRGB(64, 52, 78)
    pouch.Material = Enum.Material.Fabric
    pouch.Anchored = true
    pouch.CanCollide = false
    pouch.CanTouch = false
    pouch.CanQuery = true
    pouch.Position = position + Vector3.new(0, 1.45, 0)
    pouch.Parent = model

    local band = Instance.new("Part")
    band.Name = "AncientBand"
    band.Size = Vector3.new(2.0, .35, 2.0)
    band.Color = Color3.fromRGB(236, 174, 70)
    band.Material = Enum.Material.Neon
    band.Anchored = true
    band.CanCollide = false
    band.CanTouch = false
    band.CanQuery = false
    band.Position = position + Vector3.new(0, 2.35, 0)
    band.Parent = model

    local light = Instance.new("PointLight")
    light.Color = Color3.fromRGB(210, 160, 255)
    light.Brightness = 2
    light.Range = 12
    light.Parent = pouch

    local gui = Instance.new("BillboardGui")
    gui.Name = "LootLabel"
    gui.Size = UDim2.fromOffset(180, 38)
    gui.StudsOffsetWorldSpace = Vector3.new(0, 2.7, 0)
    gui.AlwaysOnTop = false
    gui.MaxDistance = 65
    gui.Parent = pouch

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.fromScale(1, 1)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 12
    label.TextStrokeTransparency = .3
    label.TextColor3 = Color3.fromRGB(244, 211, 132)
    label.Text = "WORLD BOSS POUCH"
    label.Parent = gui

    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "BossPouchPrompt"
    prompt.ActionText = "Open Pouch"
    prompt.ObjectText = "World Boss Reward"
    prompt.MaxActivationDistance = 12
    prompt.HoldDuration = .15
    prompt.RequiresLineOfSight = false
    prompt.Parent = pouch

    model.PrimaryPart = pouch
    model:SetAttribute("LootOwnerUserId", player.UserId)
    model:SetAttribute("WorldBossRewardPouch", true)
    return model, prompt
end

local function grantReward(player, record)
    local reward = record.Reward
    local granted = {}
    local data = DataService:Get(player)
    if not data then
        return false, "Player data is unavailable."
    end

    -- Validate both collection capacities before granting either ultra-rare
    -- reward. This keeps a pouch retry atomic if both 0.01% rolls hit.
    data.Pets = type(data.Pets) == "table" and data.Pets or {}
    data.Mounts = type(data.Mounts) == "table" and data.Mounts or {}
    if reward.AncientPet and #data.Pets >= math.max(1, tonumber(Config.MaxPets) or 60) then
        return false, "Your pet collection is full. Make space before opening this boss pouch."
    end
    if reward.AncientMount and #data.Mounts >= math.max(1, tonumber(Config.MaxMounts) or 40) then
        return false, "Your mount collection is full. Make space before opening this boss pouch."
    end

    if reward.AncientPet then
        local pet = PetService:Create(player, reward.AncientPet)
        if not pet then
            return false, "The Ancient pet reward could not be granted."
        end
        table.insert(granted, reward.AncientPet .. " Ancient pet")
    end

    if reward.AncientMount then
        local mount = MountService:Create(player, reward.AncientMount)
        if not mount then
            return false, "The Ancient mount reward could not be granted."
        end
        table.insert(granted, reward.AncientMount .. " Ancient mount")
    end

    -- Base rewards are deliberately caller-supplied. The future boss system
    -- can add its guaranteed Coins/materials without this dormant hook
    -- inventing boss economy values before the encounters are designed.
    if reward.Coins > 0 then
        DataService:AddCoins(player, reward.Coins)
        table.insert(granted, tostring(reward.Coins) .. " Coins")
    end

    if #granted == 0 then
        table.insert(granted, "No Ancient companion drop this time")
    end

    return true, table.concat(granted, "  ·  ")
end

local function createPouch(player, bossSpecies, position, baseRewards)
    local id = HttpService:GenerateGUID(false)
    local model, prompt = pouchVisual(position, player)
    model.Name = "WorldBossPouch_" .. id
    model:SetAttribute("WorldBossSpecies", bossSpecies)

    local record = {
        Id = id,
        OwnerUserId = player.UserId,
        Player = player,
        BossSpecies = bossSpecies,
        Reward = rewardRoll(bossSpecies, baseRewards),
        Model = model,
    }
    pouches[id] = record

    prompt.Triggered:Connect(function(triggeringPlayer)
        if triggeringPlayer ~= player or pouches[id] ~= record or not model.Parent then
            return
        end

        local root = triggeringPlayer.Character and triggeringPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not root or (root.Position - model.PrimaryPart.Position).Magnitude > 18 then
            return
        end

        local success, message = grantReward(triggeringPlayer, record)
        if success then
            removePouch(record)
            LootRemote:FireClient(triggeringPlayer, "BossReward", true, message)
        else
            LootRemote:FireClient(triggeringPlayer, "BossReward", false, message)
        end
    end)

    model.Parent = lootFolder
    task.delay(180, function()
        if pouches[id] == record then removePouch(record) end
    end)
end

function Service:RecordDamage(bossKey, bossSpecies, maxHealth, player, damage)
    if bossKey == nil or not player then return end
    maxHealth = tonumber(maxHealth)
    damage = tonumber(damage)
    if not maxHealth or maxHealth <= 0 or not damage or damage <= 0 then return end

    local encounter = encounters[bossKey]
    if not encounter then
        encounter = {
            BossSpecies = tostring(bossSpecies or ""),
            MaxHealth = maxHealth,
            DamageByUserId = {},
            Players = {},
        }
        encounters[bossKey] = encounter
    end

    encounter.MaxHealth = math.max(encounter.MaxHealth, maxHealth)
    encounter.BossSpecies = tostring(bossSpecies or encounter.BossSpecies)
    encounter.DamageByUserId[player.UserId] =
        (tonumber(encounter.DamageByUserId[player.UserId]) or 0) + damage
    encounter.Players[player.UserId] = player
end

function Service:ResolveBossDeath(bossKey, position, baseRewards)
    local encounter = encounters[bossKey]
    encounters[bossKey] = nil
    if not encounter or typeof(position) ~= "Vector3" then return 0 end

    local threshold = tonumber(rules().MinimumDamageFraction) or 0.10
    local eligible = 0

    for userId, damage in pairs(encounter.DamageByUserId) do
        local player = encounter.Players[userId]
        local fraction = (tonumber(damage) or 0) / math.max(1, encounter.MaxHealth)
        if player and player.Parent and fraction > threshold then
            eligible += 1
            local offset = Vector3.new((eligible - 1) * 2.5, 0, 0)
            createPouch(player, encounter.BossSpecies, position + offset, baseRewards)
        end
    end

    return eligible
end

function Service:PlayerRemoving(player)
    for _, encounter in pairs(encounters) do
        encounter.Players[player.UserId] = nil
    end

    local owned = {}
    for _, record in pairs(pouches) do
        if record.OwnerUserId == player.UserId then
            table.insert(owned, record)
        end
    end
    for _, record in ipairs(owned) do removePouch(record) end
end

function Service:Init()
    if started then return end
    started = true
    lootFolder = workspace:WaitForChild("WildernessPets"):WaitForChild("LootBags")
end

return Service
