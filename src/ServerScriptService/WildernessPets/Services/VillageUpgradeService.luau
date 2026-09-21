local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Root = ReplicatedStorage:WaitForChild("WildernessPets")
local VillageConfig = require(Root.Shared.VillageConfig)
local DataService = require(script.Parent.PlayerDataService)
local PetService = require(script.Parent.PetService)
local ModelFactory = require(script.Parent.Parent.Systems.PetModelFactory)
local Animator = require(script.Parent.Parent.Systems.PetAnimator)
local PetAuraService = require(script.Parent.Parent.Systems.PetAuraService)

local Service = {}
local started = false
local sessions = setmetatable({}, {__mode = "k"})
local lastTrainingTick = setmetatable({}, {__mode = "k"})

local function ensureRemote(name, className)
    local remotes = Root:WaitForChild("Remotes")
    local remote = remotes:FindFirstChild(name)
    if not remote then
        remote = Instance.new(className)
        remote.Name = name
        remote.Parent = remotes
    end
    return remote
end

local Remote = ensureRemote("VillageProgression", "RemoteEvent")
local Query = ensureRemote("VillageProgressionQuery", "RemoteFunction")

local function ensureData(data)
    if not data then return nil end
    data.VillageUpgrades = type(data.VillageUpgrades) == "table" and data.VillageUpgrades or {}
    data.VillageUpgrades.HealingBarn = math.clamp(math.floor(tonumber(data.VillageUpgrades.HealingBarn) or 1), 1, #VillageConfig.HealingBarn)
    data.VillageUpgrades.TrainingArea = math.clamp(math.floor(tonumber(data.VillageUpgrades.TrainingArea) or 1), 1, #VillageConfig.TrainingArea)
    data.VillageUpgrades.TrainingSlots = math.clamp(
        math.floor(tonumber(data.VillageUpgrades.TrainingSlots) or VillageConfig.StartTrainingSlots),
        VillageConfig.StartTrainingSlots,
        VillageConfig.MaxTrainingSlots
    )
    data.TrainingAssignments = type(data.TrainingAssignments) == "table" and data.TrainingAssignments or {}
    return data
end

local function getPlots()
    local world = workspace:FindFirstChild("WildernessPets")
    return world and world:FindFirstChild("Plots")
end

local function getOwnedPlot(player)
    local plots = getPlots()
    if not plots then return nil end
    for _, plot in ipairs(plots:GetChildren()) do
        local owner = tonumber(plot:GetAttribute("OwnerUserId") or plot:GetAttribute("Owner"))
        if owner == player.UserId then return plot end
    end
    return nil
end

local function part(parent, name, size, cf, color, material)
    local p = Instance.new("Part")
    p.Name = name
    p.Anchored = true
    p.CanCollide = true
    p.Size = size
    p.CFrame = cf
    p.Color = color
    p.Material = material or Enum.Material.WoodPlanks
    p.Parent = parent
    return p
end

local function addSign(base, textValue)
    local gui = Instance.new("SurfaceGui")
    gui.Face = Enum.NormalId.Top
    gui.AlwaysOnTop = false
    gui.Parent = base
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.fromScale(1, 1)
    label.Text = textValue
    label.Font = Enum.Font.GothamBold
    label.TextScaled = true
    label.TextColor3 = Color3.fromRGB(245, 225, 175)
    label.TextStrokeTransparency = 0.45
    label.Parent = gui
end

local function buildPlotFeatures(plot)
    if plot:FindFirstChild("VillageProgression") then
        return plot.VillageProgression
    end
    local land = plot:FindFirstChild("Land", true)
    if not land or not land:IsA("BasePart") then return nil end

    local model = Instance.new("Model")
    model.Name = "VillageProgression"
    model.Parent = plot

    local base = land.CFrame * CFrame.new(-land.Size.X * 0.28, land.Size.Y / 2 + 0.3, -land.Size.Z * 0.28)
    local training = part(
        model,
        "TrainingArea",
        Vector3.new(22, 0.6, 18),
        base,
        Color3.fromRGB(70, 104, 68),
        Enum.Material.Grass
    )
    training.CanCollide = true
    addSign(training, "PET TRAINING")

    local railsColor = Color3.fromRGB(105, 75, 48)
    for _, z in ipairs({-8.5, 8.5}) do
        local rail = part(model, "TrainingRail", Vector3.new(22, 1.1, 0.5), base * CFrame.new(0, 1, z), railsColor)
        rail.CanCollide = false
    end
    for _, x in ipairs({-10.5, 10.5}) do
        local rail = part(model, "TrainingRail", Vector3.new(0.5, 1.1, 18), base * CFrame.new(x, 1, 0), railsColor)
        rail.CanCollide = false
    end

    local promptPart = part(
        model,
        "TrainingPrompt",
        Vector3.new(4, 1, 3),
        base * CFrame.new(0, 1, 10.5),
        Color3.fromRGB(217, 184, 112)
    )
    promptPart.Transparency = 1
    promptPart.CanCollide = false
    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "Manage Training"
    prompt.ObjectText = "Pet Training Area"
    prompt.HoldDuration = 0.1
    prompt.MaxActivationDistance = 12
    prompt.RequiresLineOfSight = false
    prompt.Parent = promptPart

    local kiosk = part(
        model,
        "UpgradeKiosk",
        Vector3.new(5, 4, 2),
        base * CFrame.new(-14, 2, 0),
        Color3.fromRGB(101, 70, 45)
    )
    kiosk.CanCollide = true
    local upgradePrompt = Instance.new("ProximityPrompt")
    upgradePrompt.ActionText = "Village Upgrades"
    upgradePrompt.ObjectText = "Village Workbench"
    upgradePrompt.HoldDuration = 0.1
    upgradePrompt.MaxActivationDistance = 12
    upgradePrompt.RequiresLineOfSight = false
    upgradePrompt.Parent = kiosk

    local displayFolder = Instance.new("Folder")
    displayFolder.Name = "TrainingPets"
    displayFolder.Parent = model

    local function open(player, tab)
        local owner = tonumber(plot:GetAttribute("OwnerUserId") or plot:GetAttribute("Owner"))
        if owner ~= player.UserId then return end
        sessions[player] = {plot = plot, expiresAt = os.clock() + 900}
        Remote:FireClient(player, "Open", Service:GetState(player), tab)
    end
    prompt.Triggered:Connect(function(player) open(player, "Training") end)
    upgradePrompt.Triggered:Connect(function(player) open(player, "Upgrades") end)
    return model
end

local function sessionValid(player)
    local session = sessions[player]
    if not session or os.clock() > session.expiresAt then
        sessions[player] = nil
        return false
    end
    local plot = getOwnedPlot(player)
    if not plot or plot ~= session.plot then return false end
    session.expiresAt = os.clock() + 900
    return true
end

local function assignedSet(data)
    local set = {}
    for _, petId in ipairs(data.TrainingAssignments) do
        set[tostring(petId)] = true
    end
    return set
end

function Service:GetState(player)
    local data = ensureData(DataService:Get(player))
    if not data then return nil end
    local healingLevel = data.VillageUpgrades.HealingBarn
    local trainingLevel = data.VillageUpgrades.TrainingArea
    local slots = data.VillageUpgrades.TrainingSlots
    local healing = VillageConfig.GetHealing(healingLevel)
    local training = VillageConfig.GetTraining(trainingLevel)
    local nextSlotCost = VillageConfig.TrainingSlotGemCosts[slots + 1]
    local pets = {}
    local assigned = assignedSet(data)
    for _, pet in ipairs(PetService:GetPets(player)) do
        table.insert(pets, {
            Id = pet.Id,
            Name = pet.Name,
            Species = pet.Species,
            Level = pet.Level,
            XP = pet.XP,
            Dead = pet.Dead == true,
            Assigned = assigned[pet.Id] == true,
        })
    end
    return {
        HealingLevel = healingLevel,
        HealingSpeed = healing.Speed,
        HealingUpgradeCoins = healing.UpgradeCoins,
        TrainingLevel = trainingLevel,
        TrainingInterval = training.Interval,
        TrainingXP = training.XP,
        TrainingUpgradeCoins = training.UpgradeCoins,
        TrainingSlots = slots,
        MaxTrainingSlots = VillageConfig.MaxTrainingSlots,
        NextSlotGemCost = nextSlotCost,
        TrainingAssignments = data.TrainingAssignments,
        Pets = pets,
    }
end

local function canAssign(data, pet)
    if pet.Dead then return false, "Dead or healing pets cannot train." end
    if data.EquippedPetId == pet.Id then return false, "Unequip that companion first." end
    if data.PodiumPetId == pet.Id then return false, "Remove that pet from the podium first." end
    if data.DefencePetId == pet.Id then return false, "Remove that pet from village defence first." end
    if pet.Displayed then return false, "Remove that pet from roaming display first." end
    return true
end

function Service:Assign(player, petId)
    local data = ensureData(DataService:Get(player))
    if not data then return false, "Player data unavailable." end
    local pet = PetService:Find(player, tostring(petId or ""))
    if not pet then return false, "Pet not found." end
    local set = assignedSet(data)
    if set[pet.Id] then return true, "Pet is already training." end
    local allowed, message = canAssign(data, pet)
    if not allowed then return false, message end
    if #data.TrainingAssignments >= data.VillageUpgrades.TrainingSlots then
        return false, "All training slots are occupied."
    end
    table.insert(data.TrainingAssignments, pet.Id)
    lastTrainingTick[player] = lastTrainingTick[player] or os.time()
    self:RefreshVisuals(player)
    return true, tostring(pet.Name) .. " started training."
end

function Service:Remove(player, petId)
    local data = ensureData(DataService:Get(player))
    if not data then return false, "Player data unavailable." end
    petId = tostring(petId or "")
    for index, assignedId in ipairs(data.TrainingAssignments) do
        if tostring(assignedId) == petId then
            table.remove(data.TrainingAssignments, index)
            self:RefreshVisuals(player)
            return true, "Pet removed from training."
        end
    end
    return false, "That pet is not training."
end

function Service:Upgrade(player, kind)
    local data = ensureData(DataService:Get(player))
    if not data then return false, "Player data unavailable." end
    local field, levels
    if kind == "HealingBarn" then
        field, levels = "HealingBarn", VillageConfig.HealingBarn
    elseif kind == "TrainingArea" then
        field, levels = "TrainingArea", VillageConfig.TrainingArea
    else
        return false, "Unknown upgrade."
    end
    local level = data.VillageUpgrades[field]
    local current = levels[level]
    if not current or not current.UpgradeCoins then return false, "That upgrade is already maxed." end
    local cost = math.max(0, math.floor(tonumber(current.UpgradeCoins) or 0))
    if not DataService:SpendCoins(player, cost) then return false, "Not enough Coins." end
    data.VillageUpgrades[field] = math.min(#levels, level + 1)
    return true, field .. " upgraded to level " .. tostring(data.VillageUpgrades[field]) .. "."
end

function Service:BuyTrainingSlot(player)
    local data = ensureData(DataService:Get(player))
    if not data then return false, "Player data unavailable." end
    local slots = data.VillageUpgrades.TrainingSlots
    if slots >= VillageConfig.MaxTrainingSlots then return false, "Training slots are maxed." end
    local cost = math.max(0, math.floor(tonumber(VillageConfig.TrainingSlotGemCosts[slots + 1]) or 0))
    if cost <= 0 then return false, "No slot upgrade is available." end
    if not DataService:SpendGems(player, cost) then return false, "Not enough Gems." end
    data.VillageUpgrades.TrainingSlots = slots + 1
    return true, "Training slot unlocked."
end

function Service:RefreshVisuals(player)
    local plot = getOwnedPlot(player)
    if not plot then return end
    local feature = buildPlotFeatures(plot)
    local folder = feature and feature:FindFirstChild("TrainingPets")
    local pad = feature and feature:FindFirstChild("TrainingArea")
    if not folder or not pad then return end
    folder:ClearAllChildren()
    local data = ensureData(DataService:Get(player))
    if not data then return end
    for index, petId in ipairs(data.TrainingAssignments) do
        local pet = PetService:Find(player, petId)
        if pet and not pet.Dead then
            local model = ModelFactory:Create(pet.Species)
            if model then
                model.Name = "Training_" .. tostring(pet.Id)
                for _, item in ipairs(model:GetDescendants()) do
                    if item:IsA("BillboardGui") or item:IsA("LuaSourceContainer") then item:Destroy()
                    elseif item:IsA("BasePart") then
                        item.Anchored = true
                        item.CanCollide = false
                        item.CanTouch = false
                        item.CanQuery = false
                    end
                end
                model.Parent = folder
                local rig = Animator:_getRig(model)
                if rig then
                    local x = ((index - 1) % 3 - 1) * 5
                    local z = math.floor((index - 1) / 3) * 5 - 2
                    rig.base = pad.CFrame * CFrame.new(x, pad.Size.Y / 2 + rig.clearance + 0.06, z)
                    Animator:Stop(model)
                    Animator:PlayIdle(model)
                    PetAuraService:Apply(model, pet)
                else
                    model:Destroy()
                end
            end
        end
    end
end

function Service:PlayerReady(player)
    local data = ensureData(DataService:Get(player))
    if not data then return end
    lastTrainingTick[player] = os.time()
    task.defer(function()
        task.wait(1)
        if player.Parent then self:RefreshVisuals(player) end
    end)
end

function Service:PlayerRemoving(player)
    sessions[player] = nil
    lastTrainingTick[player] = nil
end

local function awardTraining(player, now)
    local data = ensureData(DataService:Get(player))
    if not data then return end
    local last = lastTrainingTick[player] or now
    local config = VillageConfig.GetTraining(data.VillageUpgrades.TrainingArea)
    local interval = math.max(60, math.floor(tonumber(config.Interval) or 900))
    local elapsed = math.max(0, now - last)
    local ticks = math.floor(elapsed / interval)
    if ticks <= 0 then return end
    lastTrainingTick[player] = last + ticks * interval
    local gain = ticks * math.max(1, math.floor(tonumber(config.XP) or 1))
    local changed = false
    local kept = {}
    for _, petId in ipairs(data.TrainingAssignments) do
        local pet = PetService:Find(player, petId)
        if pet and not pet.Dead then
            table.insert(kept, petId)
            local ok = PetService:AddXP(player, petId, gain, true)
            if ok then changed = true end
        end
    end
    data.TrainingAssignments = kept
    if changed then
        self:RefreshVisuals(player)
        Remote:FireClient(player, "TrainingTick", gain, self:GetState(player))
    end
end

function Service:DebugAdvanceTraining(player, seconds)
    if not RunService:IsStudio() then return false, "Studio only." end
    local now = os.time()
    local amount = math.max(1, math.floor(tonumber(seconds) or 900))
    lastTrainingTick[player] = (lastTrainingTick[player] or now) - amount
    awardTraining(player, now)
    return true, "Training clock advanced by " .. tostring(amount) .. " seconds."
end

function Service:Init()
    if started then return end
    started = true
    local plots = getPlots()
    if plots then
        for _, plot in ipairs(plots:GetChildren()) do buildPlotFeatures(plot) end
        plots.ChildAdded:Connect(function(plot) task.defer(buildPlotFeatures, plot) end)
    end
    Query.OnServerInvoke = function(player)
        if not getOwnedPlot(player) then return nil end
        return self:GetState(player)
    end
    Remote.OnServerEvent:Connect(function(player, action, ...)
        if not sessionValid(player) then
            Remote:FireClient(player, "Result", false, "Use your village workbench or training area first.")
            return
        end
        local args = {...}
        local ok, message = false, "Unknown action."
        if action == "UpgradeHealing" then ok, message = self:Upgrade(player, "HealingBarn")
        elseif action == "UpgradeTraining" then ok, message = self:Upgrade(player, "TrainingArea")
        elseif action == "BuyTrainingSlot" then ok, message = self:BuyTrainingSlot(player)
        elseif action == "Assign" then ok, message = self:Assign(player, args[1])
        elseif action == "Remove" then ok, message = self:Remove(player, args[1])
        end
        Remote:FireClient(player, "Result", ok, message, self:GetState(player))
    end)
    Players.PlayerRemoving:Connect(function(player) self:PlayerRemoving(player) end)
    task.spawn(function()
        while true do
            task.wait(30)
            local now = os.time()
            for _, player in ipairs(Players:GetPlayers()) do
                pcall(awardTraining, player, now)
            end
        end
    end)
end

return Service
