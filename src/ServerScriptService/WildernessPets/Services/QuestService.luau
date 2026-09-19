local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Root = ReplicatedStorage:WaitForChild("WildernessPets")
local QuestRemote = Root.Remotes:WaitForChild("Quest")
local ShopRemote = Root.Remotes:WaitForChild("Shop")
local QuestConfig = require(Root.Shared.QuestConfig)
local Config = require(Root.Shared.Config)

local DataService = require(script.Parent.PlayerDataService)
local PetService = require(script.Parent.PetService)
local MountService = require(script.Parent.MountService)
local LootService = require(script.Parent.LootService)
local ShopService = require(script.Parent.ShopService)
local ModelFactory = require(script.Parent.Parent.Systems.PetModelFactory)
local Animator = require(script.Parent.Parent.Systems.PetAnimator)

local Service = {}
local started = false
local world
local questWorld
local caveModel
local caveEntrance
local caveInner
local leatherTraderModel
local leatherTraderPosition
local npcModels = {}
local personal = {}
local leatherTradeSessions = setmetatable({}, {__mode = "k"})

local QUEST_VERSION = 5

local function getRoot(player)
    local character = player.Character
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function near(player, position, range)
    local root = getRoot(player)
    return root and (root.Position - position).Magnitude <= (range or 18)
end

local function terrainPoint(x, z, fallbackY)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances = {workspace.Terrain}

    local hit = workspace:Raycast(
        Vector3.new(x, 350, z),
        Vector3.new(0, -700, 0),
        params
    )

    if hit and hit.Material ~= Enum.Material.Water then
        return hit.Position
    end

    return Vector3.new(x, fallbackY or 17, z)
end

local function makePart(parent, name, size, cframe, color, material, shape)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.CFrame = cframe
    p.Color = color
    p.Material = material or Enum.Material.SmoothPlastic
    p.Shape = shape or Enum.PartType.Block
    p.Anchored = true
    p.CanCollide = true
    p.CanTouch = false
    p.CanQuery = true
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = parent
    return p
end

local function billboard(part, title, subtitle, color)
    local gui = Instance.new("BillboardGui")
    gui.Name = "QuestNPCLabel"
    gui.Size = UDim2.fromOffset(220, 54)
    gui.StudsOffsetWorldSpace = Vector3.new(0, 3.8, 0)
    gui.MaxDistance = 70
    gui.AlwaysOnTop = false
    gui.Parent = part

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.BackgroundTransparency = 1
    titleLabel.Size = UDim2.new(1, 0, 0, 28)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 15
    titleLabel.TextStrokeTransparency = 0.35
    titleLabel.TextColor3 = color or Color3.fromRGB(245, 222, 151)
    titleLabel.Text = title
    titleLabel.Parent = gui

    local subLabel = Instance.new("TextLabel")
    subLabel.Name = "Subtitle"
    subLabel.BackgroundTransparency = 1
    subLabel.Position = UDim2.fromOffset(0, 28)
    subLabel.Size = UDim2.new(1, 0, 0, 20)
    subLabel.Font = Enum.Font.GothamMedium
    subLabel.TextSize = 11
    subLabel.TextStrokeTransparency = 0.45
    subLabel.TextColor3 = Color3.fromRGB(224, 226, 218)
    subLabel.Text = subtitle or "QUEST GIVER"
    subLabel.Parent = gui
end

local function makeNPC(parent, id, spec)
    local position = terrainPoint(spec.XZ.X, spec.XZ.Y, QuestConfig.World.CaveFallbackY)
    local model = Instance.new("Model")
    model.Name = "QuestNPC_" .. id
    model:SetAttribute("QuestNpcId", id)
    model:SetAttribute("QuestNPC", spec.Name)

    local root = makePart(
        model,
        "HumanoidRootPart",
        Vector3.new(2.2, 3.0, 1.3),
        CFrame.new(position + Vector3.new(0, 2.7, 0)),
        spec.Shirt,
        Enum.Material.SmoothPlastic
    )
    root.CanCollide = false
    root.Transparency = 1

    local torso = makePart(
        model,
        "Torso",
        Vector3.new(2.2, 3.0, 1.2),
        CFrame.new(position + Vector3.new(0, 2.8, 0)),
        spec.Shirt,
        Enum.Material.Fabric
    )
    torso.CanCollide = false

    local head = makePart(
        model,
        "Head",
        Vector3.new(1.8, 1.8, 1.8),
        CFrame.new(position + Vector3.new(0, 5.1, 0)),
        Color3.fromRGB(218, 179, 143),
        Enum.Material.SmoothPlastic,
        Enum.PartType.Ball
    )
    head.CanCollide = false

    local legLeft = makePart(model, "LeftLeg", Vector3.new(.8, 2.2, .9), CFrame.new(position + Vector3.new(-.55, .95, 0)), Color3.fromRGB(62, 68, 72), Enum.Material.Fabric)
    local legRight = makePart(model, "RightLeg", Vector3.new(.8, 2.2, .9), CFrame.new(position + Vector3.new(.55, .95, 0)), Color3.fromRGB(62, 68, 72), Enum.Material.Fabric)
    legLeft.CanCollide = false
    legRight.CanCollide = false

    local armLeft = makePart(model, "LeftArm", Vector3.new(.65, 2.6, .65), CFrame.new(position + Vector3.new(-1.45, 2.9, 0)), spec.Accent, Enum.Material.Fabric)
    local armRight = makePart(model, "RightArm", Vector3.new(.65, 2.6, .65), CFrame.new(position + Vector3.new(1.45, 2.9, 0)), spec.Accent, Enum.Material.Fabric)
    armLeft.CanCollide = false
    armRight.CanCollide = false

    model.PrimaryPart = root
    model.Parent = parent
    billboard(torso, spec.Name, "QUEST GIVER", Color3.fromRGB(245, 210, 110))

    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "QuestPrompt"
    prompt.ActionText = "Talk"
    prompt.ObjectText = spec.Name
    prompt.MaxActivationDistance = 12
    prompt.HoldDuration = 0
    prompt.RequiresLineOfSight = false
    prompt.Parent = torso

    prompt.Triggered:Connect(function(player)
        Service:TalkToNPC(player, id)
    end)

    npcModels[id] = model
    return model
end

local function addPrompt(part, objectText)
    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "QuestPrompt"
    prompt.ActionText = "Talk"
    prompt.ObjectText = objectText
    prompt.MaxActivationDistance = 12
    prompt.HoldDuration = 0
    prompt.RequiresLineOfSight = false
    prompt.Parent = part
    return prompt
end

local function sendDialogue(player, npcName, text, options)
    QuestRemote:FireClient(player, "Dialogue", {
        NPC = npcName,
        Text = text,
        Options = options or {},
    })
end

local function rewardText(reward)
    reward = reward or {}
    local parts = {}
    if (tonumber(reward.Coins) or 0) > 0 then
        table.insert(parts, tostring(math.floor(reward.Coins)) .. " Coins")
    end
    if (tonumber(reward.Gems) or 0) > 0 then
        table.insert(parts, tostring(math.floor(reward.Gems)) .. " Gems")
    end
    if type(reward.Backpack) == "string" and reward.Backpack ~= "" then
        table.insert(
            parts,
            tostring(reward.Backpack)
                .. " ("
                .. tostring(math.max(0, math.floor(tonumber(reward.Capacity) or 0)))
                .. " slots)"
        )
    end
    return table.concat(parts, " + ")
end

local function migrateQuestData(data)
    data.QuestProgress = type(data.QuestProgress) == "table" and data.QuestProgress or {}
    local old = data.QuestProgress

    if old.Version == QUEST_VERSION then
        old.Completed = type(old.Completed) == "table" and old.Completed or {}
        old.Quests = type(old.Quests) == "table" and old.Quests or {}
        old.ActiveQuestIds = type(old.ActiveQuestIds) == "table" and old.ActiveQuestIds or {}
        if type(old.ActiveQuestId) == "string" and old.ActiveQuestId ~= "" then
            old.ActiveQuestIds[old.ActiveQuestId] = true
            old.ActiveQuestId = nil
        end
        return old
    end

    local migrated = {
        Version = QUEST_VERSION,
        ActiveQuestIds = {},
        Completed = {},
        Quests = {},
    }

    local function importActive(id)
        if type(id) == "string" and id ~= "" and QuestConfig.Chains[id] then
            migrated.ActiveQuestIds[id] = true
        end
    end

    if old.Version == 4 then
        migrated.Completed = type(old.Completed) == "table" and old.Completed or {}
        migrated.Quests = type(old.Quests) == "table" and old.Quests or {}
        migrated.ActiveQuestIds = type(old.ActiveQuestIds) == "table" and old.ActiveQuestIds or {}
        if type(old.ActiveQuestId) == "string" and old.ActiveQuestId ~= "" then
            migrated.ActiveQuestIds[old.ActiveQuestId] = true
        end

        local tutorialState = migrated.Quests.BeastHandlingTutorial
        if type(tutorialState) == "table" then
            local oldIndex = math.max(1, math.floor(tonumber(tutorialState.StageIndex) or 1))
            if oldIndex >= 6 then
                tutorialState.StageIndex = oldIndex + 1
            end
        end

        data.QuestProgress = migrated
        return migrated
    end

    if old.Version == 3 then
        migrated.Completed = type(old.Completed) == "table" and old.Completed or {}
        migrated.Quests = type(old.Quests) == "table" and old.Quests or {}
        importActive(old.ActiveQuestId)
        for id, active in pairs(type(old.ActiveQuestIds) == "table" and old.ActiveQuestIds or {}) do
            if active == true then importActive(id) end
        end
        data.QuestProgress = migrated
        return migrated
    end

    if old.Version == 2 then
        migrated.Completed = type(old.Completed) == "table" and old.Completed or {}
        importActive(old.ActiveQuestId)

        local stageMaps = {
            CaravanTrouble = {[1]=1, [2]=3, [3]=5},
            MoonlightProblems = {[1]=1, [2]=2, [3]=4},
            HollowfangMystery = {[1]=1, [2]=3, [3]=5},
        }

        for questId, oldState in pairs(type(old.Quests) == "table" and old.Quests or {}) do
            if type(oldState) == "table" then
                local oldIndex = math.max(1, math.floor(tonumber(oldState.StageIndex) or 1))
                local map = stageMaps[questId]
                migrated.Quests[questId] = {
                    StageIndex = map and (map[oldIndex] or oldIndex) or oldIndex,
                    Count = math.max(0, math.floor(tonumber(oldState.Count) or 0)),
                    TargetPetId = oldState.TargetPetId,
                }
            end
        end

        data.QuestProgress = migrated
        return migrated
    end

    local legacy = old.HollowfangRescue
    if type(legacy) == "table" then
        local stage = legacy.Stage
        if stage == "WolfReturn" then
            importActive("StarterWolves")
            migrated.Quests.StarterWolves = {StageIndex = 1, Count = 0}
        elseif stage == "BearRescue" then
            migrated.Completed.StarterWolves = true
            importActive("HollowfangRescue")
            migrated.Quests.HollowfangRescue = {
                StageIndex = 1,
                Count = math.clamp(math.floor(tonumber(legacy.BearsKilled) or 0), 0, 3),
            }
        elseif stage == "BearCleared" then
            migrated.Completed.StarterWolves = true
            importActive("HollowfangRescue")
            migrated.Quests.HollowfangRescue = {StageIndex = 2, Count = 0}
        elseif stage == "Complete" then
            migrated.Completed.StarterWolves = true
            migrated.Completed.HollowfangRescue = true
        end
    end

    data.QuestProgress = migrated
    return migrated
end

local function questData(player)
    local data = DataService:Get(player)
    if not data then return nil, nil end
    return migrateQuestData(data), data
end

local function questState(root, questId)
    root.Quests = type(root.Quests) == "table" and root.Quests or {}
    local state = root.Quests[questId]
    if type(state) ~= "table" then
        state = {StageIndex = 1, Count = 0, TargetPetId = "", TargetMountId = ""}
        root.Quests[questId] = state
    end
    state.StageIndex = math.max(1, math.floor(tonumber(state.StageIndex) or 1))
    state.Count = math.max(0, math.floor(tonumber(state.Count) or 0))
    state.TargetPetId = type(state.TargetPetId) == "string" and state.TargetPetId or ""
    state.TargetMountId = type(state.TargetMountId) == "string" and state.TargetMountId or ""
    return state
end

local function strongestOwnedLasso(data)
    local strongest = 0
    local strongestName = "Rough Rope"

    local function consider(name)
        local info = type(name) == "string" and Config.Lassos[name] or nil
        local strength = info and tonumber(info.Strength) or 0
        if strength > strongest then
            strongest = strength
            strongestName = name
        end
    end

    consider(data and data.Lasso)
    for _, item in ipairs(data and data.Inventory or {}) do
        if type(item) == "table"
            and item.Type == "Lasso"
            and (tonumber(item.Quantity) or 0) > 0 then
            consider(item.Name)
        end
    end

    return strongest, strongestName
end

local function prerequisiteMet(root, chain)
    if not chain.Prerequisite then return true end
    return root.Completed[chain.Prerequisite] == true
end

local function progressionLassoStrength(data)
    local owned = strongestOwnedLasso(data)
    return math.max(owned, tonumber(data and data.MaxLassoStrengthUnlocked) or 0)
end

local function chainUnlocked(root, data, chain)
    if root.Completed[chain.Id] then return false end
    root.ActiveQuestIds = type(root.ActiveQuestIds) == "table" and root.ActiveQuestIds or {}
    if root.ActiveQuestIds[chain.Id] == true then return false end

    if chain.Id == "StarterWolves" then
        -- The first Rowan quest is available immediately.
    elseif chain.Id == "BeastHandlingTutorial" then
        if root.Completed.StarterWolves ~= true then return false end
    elseif root.Completed.BeastHandlingTutorial ~= true then
        return false
    end

    if not prerequisiteMet(root, chain) then return false end
    return progressionLassoStrength(data) >= math.max(0, tonumber(chain.RequiredStrength) or 0)
end

local function availableChainsForNPC(root, data, npcId)
    local result = {}
    for id, chain in pairs(QuestConfig.Chains) do
        if chain.NPC == npcId and chainUnlocked(root, data, chain) then
            table.insert(result, chain)
        end
    end
    table.sort(result, function(a, b)
        local ap = tonumber(a.Priority) or 999
        local bp = tonumber(b.Priority) or 999
        if ap == bp then return a.Id < b.Id end
        return ap < bp
    end)
    return result
end

local function npcName(npcId)
    local spec = QuestConfig.World.NPCs[npcId]
    return spec and spec.Name or tostring(npcId)
end

local function npcPosition(npcId)
    local model = npcModels[npcId]
    return model and model:GetPivot().Position or nil
end

local function currentPersonal(player)
    local state = personal[player]
    if not state then
        state = {Bears = {}, Mira = nil, SparPet = nil, MountHorse = nil}
        personal[player] = state
    end
    return state
end

local function destroyPersonal(player)
    local state = personal[player]
    if not state then return end
    for _, bear in ipairs(state.Bears or {}) do
        if bear and bear.Parent then bear:Destroy() end
    end
    if state.Mira and state.Mira.Parent then state.Mira:Destroy() end
    if state.SparPet and state.SparPet.Parent then state.SparPet:Destroy() end
    if state.MountHorse and state.MountHorse.Parent then state.MountHorse:Destroy() end
    personal[player] = nil
end

local function eligiblePets(player, stage)
    local _, data = questData(player)
    if not data then return {} end
    local result = {}

    for _, pet in ipairs(PetService:GetPets(player)) do
        local speciesMatches = not stage.Species or pet.Species == stage.Species
        if speciesMatches
            and not pet.Dead
            and not pet.Favourite
            and not pet.Displayed
            and pet.Id ~= data.EquippedPetId
            and pet.Id ~= data.PodiumPetId
            and pet.Id ~= data.DefencePetId then
            table.insert(result, pet)
        end
    end

    table.sort(result, function(a, b)
        local aLevel = tonumber(a.Level) or 1
        local bLevel = tonumber(b.Level) or 1
        if aLevel ~= bLevel then return aLevel < bLevel end
        local aImprint = tonumber(a.Imprint) or 20
        local bImprint = tonumber(b.Imprint) or 20
        if aImprint ~= bImprint then return aImprint < bImprint end
        return tostring(a.Id) < tostring(b.Id)
    end)

    return result
end

local function removeTurnInPets(player, stage)
    local _, data = questData(player)
    if not data then return false end

    local required = math.max(1, math.floor(tonumber(stage.Required) or 1))
    local eligible = eligiblePets(player, stage)
    if #eligible < required then return false end

    local selected = {}
    for index = 1, required do
        selected[eligible[index].Id] = true
    end

    for index = #data.Pets, 1, -1 do
        local pet = data.Pets[index]
        if selected[pet.Id] then
            table.remove(data.Pets, index)
        end
    end

    local refresh = script.Parent.Parent.Systems:FindFirstChild("PetDisplayRefresh")
    if refresh and refresh:IsA("BindableEvent") then
        refresh:Fire(player)
    end
    return true
end

local function inspectCount(player, stage)
    local count = 0
    for _, pet in ipairs(PetService:GetPets(player)) do
        local rarityMatches = not stage.Rarity or pet.Rarity == stage.Rarity
        local imprintMatches = not stage.MinimumImprint
            or (tonumber(pet.Imprint) or 0) >= tonumber(stage.MinimumImprint)
        if rarityMatches and imprintMatches and not pet.Dead then
            count += 1
        end
    end
    return count
end

local function multiItemProgress(player, stage)
    local total = 0
    local requiredTotal = 0
    local ready = true
    local parts = {}
    local firstMissing

    for _, requirement in ipairs(type(stage.Requirements) == "table" and stage.Requirements or {}) do
        local itemName = tostring(requirement.Item or "")
        local required = math.max(1, math.floor(tonumber(requirement.Required) or 1))
        local count = math.min(required, LootService:GetCount(player, itemName))
        total += count
        requiredTotal += required

        table.insert(parts, itemName .. " " .. tostring(count) .. "/" .. tostring(required))
        if count < required then
            ready = false
            firstMissing = firstMissing or requirement
        end
    end

    return total, requiredTotal, ready, parts, firstMissing
end

local function consumeMultiItems(player, stage)
    local _, _, ready = multiItemProgress(player, stage)
    if not ready then return false end

    for _, requirement in ipairs(type(stage.Requirements) == "table" and stage.Requirements or {}) do
        local itemName = tostring(requirement.Item or "")
        local required = math.max(1, math.floor(tonumber(requirement.Required) or 1))
        if not LootService:ConsumeItem(player, itemName, required) then
            return false
        end
    end
    return true
end

local function stageCount(player, state, stage)
    if stage.Type == "CaptureReturn" then
        return #eligiblePets(player, stage)
    elseif stage.Type == "InspectPet" then
        return inspectCount(player, stage)
    elseif stage.Type == "ItemTurnIn" then
        return LootService:GetCount(player, stage.Item)
    elseif stage.Type == "MultiItemTurnIn" then
        local total = multiItemProgress(player, stage)
        return total
    elseif stage.Type == "Kill" then
        return state.Count
    elseif stage.Type == "Talk" then
        return 0
    end
    return state.Count
end

local function activeQuestIds(root)
    root.ActiveQuestIds = type(root.ActiveQuestIds) == "table" and root.ActiveQuestIds or {}
    local ids = {}
    for id, active in pairs(root.ActiveQuestIds) do
        if active == true and QuestConfig.Chains[id] then
            table.insert(ids, id)
        end
    end
    table.sort(ids, function(a, b)
        local ac = QuestConfig.Chains[a]
        local bc = QuestConfig.Chains[b]
        local ap = tonumber(ac and ac.Priority) or 999
        local bp = tonumber(bc and bc.Priority) or 999
        if ap == bp then return a < b end
        return ap < bp
    end)
    return ids
end

local function chainStage(player, questId)
    local root, data = questData(player)
    if not root or type(questId) ~= "string" then return root, data, nil, nil, nil end
    root.ActiveQuestIds = type(root.ActiveQuestIds) == "table" and root.ActiveQuestIds or {}
    if root.ActiveQuestIds[questId] ~= true then return root, data, nil, nil, nil end

    local chain = QuestConfig.Chains[questId]
    if not chain then
        root.ActiveQuestIds[questId] = nil
        return root, data, nil, nil, nil
    end

    local state = questState(root, questId)
    local stage = chain.Stages[state.StageIndex]
    return root, data, chain, state, stage
end

local function activeChainEntries(player)
    local root, data = questData(player)
    local entries = {}
    if not root or not data then return root, data, entries end

    for _, questId in ipairs(activeQuestIds(root)) do
        local chain = QuestConfig.Chains[questId]
        local state = questState(root, questId)
        local stage = chain and chain.Stages[state.StageIndex] or nil
        if chain and stage then
            table.insert(entries, {
                Id = questId,
                Chain = chain,
                State = state,
                Stage = stage,
            })
        end
    end

    return root, data, entries
end

local function grantReward(player, chain)
    local reward = chain.Reward or {}
    local coins = math.max(0, math.floor(tonumber(reward.Coins) or 0))
    local gems = math.max(0, math.floor(tonumber(reward.Gems) or 0))
    local coinBalance
    local gemBalance

    if coins > 0 then coinBalance = DataService:AddCoins(player, coins) end
    if gems > 0 then gemBalance = DataService:AddGems(player, gems) end

    local backpackName
    local capacity
    if type(reward.Backpack) == "string" and reward.Backpack ~= "" then
        local upgraded = ShopService:UpgradeInventoryCapacity(player, reward.Backpack)
        if upgraded then
            backpackName = reward.Backpack
            capacity = ShopService:GetInventoryCapacity(player)
        end
    end

    QuestRemote:FireClient(player, "Reward", {
        Coins = coins,
        Gems = gems,
        CoinBalance = coinBalance,
        GemBalance = gemBalance,
        Backpack = backpackName,
        InventoryCapacity = capacity,
    })
end

local function questBearLabel(model, player)
    local root = model.PrimaryPart
    if not root then return end

    local gui = Instance.new("BillboardGui")
    gui.Name = "QuestBearLabel"
    gui.Size = UDim2.fromOffset(220, 32)
    gui.StudsOffsetWorldSpace = Vector3.new(0, model:GetExtentsSize().Y * .55 + .8, 0)
    gui.MaxDistance = 65
    gui.Parent = root

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.fromScale(1, 1)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 13
    label.TextStrokeTransparency = .35
    label.TextColor3 = Color3.fromRGB(255, 192, 110)
    label.Text = "HOLLOWFANG BEAR  ·  " .. player.DisplayName
    label.Parent = gui
end

local function spawnQuestBear(player, index, position)
    local model = ModelFactory:Create("Bear")
    if not model then return nil end

    model.Name = "QuestBear_" .. tostring(player.UserId) .. "_" .. tostring(index)
    for _, item in ipairs(model:GetDescendants()) do
        if item:IsA("BillboardGui") then
            item:Destroy()
        elseif item:IsA("BasePart") then
            item.Anchored = true
            item.CanCollide = false
            item.CanTouch = false
            item.CanQuery = true
        end
    end

    model:SetAttribute("Species", "Bear")
    model:SetAttribute("AnimationSpecies", "Bear")
    model:SetAttribute("Rarity", "Rare")
    model:SetAttribute("Level", 1)
    model:SetAttribute("Power", 28)
    model:SetAttribute("Defence", 18)
    model:SetAttribute("Health", 135)
    model:SetAttribute("MaxHealth", 135)
    model:SetAttribute("Captured", false)
    model:SetAttribute("BeingCaptured", false)
    model:SetAttribute("InCombat", false)
    model:SetAttribute("Dead", false)
    model:SetAttribute("QuestStationary", true)
    model:SetAttribute("QuestNoCapture", true)
    model:SetAttribute("QuestOwnerUserId", player.UserId)
    model:SetAttribute("QuestId", "HollowfangRescue")
    model:SetAttribute("QuestObjective", "HollowfangBears")

    local rig = Animator:_getRig(model)
    if not rig then
        model:Destroy()
        return nil
    end

    rig.base = CFrame.new(position + Vector3.new(0, rig.clearance + .06, 0))
        * CFrame.Angles(0, math.rad(180), 0)
    Animator:Stop(model)

    local wild = world:FindFirstChild("WildMonsters")
    if not wild then
        model:Destroy()
        return nil
    end

    model.Parent = wild
    questBearLabel(model, player)
    Animator:PlayIdle(model)

    local dying = false
    model:GetAttributeChangedSignal("Health"):Connect(function()
        if dying or not model.Parent then return end
        if (tonumber(model:GetAttribute("Health")) or 0) > 0 then return end
        dying = true
        model:SetAttribute("Dead", true)
        model:SetAttribute("InCombat", true)
        task.spawn(function()
            pcall(function() Animator:PlayFaint(model, .7) end)
            task.wait(.9)
            if model.Parent then model:Destroy() end
        end)
    end)

    return model
end

local function createMira(player, outside)
    local state = currentPersonal(player)
    if state.Mira and state.Mira.Parent then state.Mira:Destroy() end

    local position = outside and caveEntrance + Vector3.new(0, 0, 7) or caveInner
    local spec = {
        Name = "Scout Mira",
        XZ = Vector2.new(position.X, position.Z),
        Shirt = Color3.fromRGB(82, 104, 83),
        Accent = Color3.fromRGB(136, 162, 112),
    }

    local model = Instance.new("Model")
    model.Name = "ScoutMira_" .. tostring(player.UserId)
    model:SetAttribute("QuestOwnerUserId", player.UserId)
    model:SetAttribute("QuestNPC", "Scout Mira")
    model:SetAttribute("QuestMira", true)

    local root = makePart(model, "HumanoidRootPart", Vector3.new(2.2,3,1.3), CFrame.new(position + Vector3.new(0,2.7,0)), spec.Shirt)
    root.CanCollide = false
    root.Transparency = 1
    local torso = makePart(model, "Torso", Vector3.new(2.2,3,1.2), CFrame.new(position + Vector3.new(0,2.8,0)), spec.Shirt, Enum.Material.Fabric)
    torso.CanCollide = false
    local head = makePart(model, "Head", Vector3.new(1.8,1.8,1.8), CFrame.new(position + Vector3.new(0,5.1,0)), Color3.fromRGB(218,179,143), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
    head.CanCollide = false
    local leftLeg = makePart(model, "LeftLeg", Vector3.new(.8,2.2,.9), CFrame.new(position + Vector3.new(-.55,.95,0)), Color3.fromRGB(62,68,72), Enum.Material.Fabric)
    local rightLeg = makePart(model, "RightLeg", Vector3.new(.8,2.2,.9), CFrame.new(position + Vector3.new(.55,.95,0)), Color3.fromRGB(62,68,72), Enum.Material.Fabric)
    leftLeg.CanCollide = false
    rightLeg.CanCollide = false
    model.PrimaryPart = root
    model.Parent = questWorld

    billboard(torso, "Scout Mira", outside and "RESCUED SCOUT" or "TRAPPED SCOUT", Color3.fromRGB(170,228,160))
    local prompt = addPrompt(torso, "Scout Mira")
    prompt.Enabled = outside
    prompt.Triggered:Connect(function(triggeringPlayer)
        if triggeringPlayer == player then
            Service:TalkToMira(player)
        end
    end)

    state.Mira = model
    return model
end

local function moveMiraOutside(player)
    local state = currentPersonal(player)
    if not state.Mira or not state.Mira.Parent then
        createMira(player, true)
        return
    end

    state.Mira:PivotTo(CFrame.new(caveEntrance + Vector3.new(0, 2.7, 7)))
    local torso = state.Mira:FindFirstChild("Torso")
    local prompt = torso and torso:FindFirstChild("QuestPrompt")
    if prompt then prompt.Enabled = true end
    local gui = torso and torso:FindFirstChild("QuestNPCLabel")
    local subtitle = gui and gui:FindFirstChild("Subtitle")
    if subtitle then subtitle.Text = "RESCUED SCOUT" end
end

local function spawnBearObjective(player)
    local root, _, chain, state, stage = chainStage(player, "HollowfangRescue")
    if not root or not chain or chain.Id ~= "HollowfangRescue" or not stage or stage.Id ~= "Bears" then
        return
    end

    local current = currentPersonal(player)
    for _, bear in ipairs(current.Bears) do
        if bear and bear.Parent then bear:Destroy() end
    end
    current.Bears = {}

    if not current.Mira or not current.Mira.Parent then
        createMira(player, false)
    end

    local required = math.max(1, tonumber(stage.Required) or 3)
    local remaining = math.max(0, required - state.Count)
    local offsets = {
        Vector3.new(-12, 0, 20),
        Vector3.new(0, 0, 27),
        Vector3.new(12, 0, 20),
    }

    for index = 1, remaining do
        local rough = caveEntrance + offsets[index]
        local ground = terrainPoint(rough.X, rough.Z, rough.Y)
        local bear = spawnQuestBear(player, state.Count + index, ground)
        if bear then table.insert(current.Bears, bear) end
    end
end

local function spawnTutorialSpar(player)
    local _, _, chain, state, stage = chainStage(player, "BeastHandlingTutorial")
    if not chain or not state or not stage or stage.Id ~= "RowanChallenge" then return end

    local current = currentPersonal(player)
    if current.SparPet and current.SparPet.Parent then
        current.SparPet:Destroy()
    end

    local rowan = npcPosition("Rowan")
    if not rowan then return end
    local rough = rowan + Vector3.new(13, 0, -6)
    local ground = terrainPoint(rough.X, rough.Z, rough.Y)

    local model = ModelFactory:Create("Wolf")
    if not model then return end
    model.Name = "RowanVeteranWolf_" .. tostring(player.UserId)

    for _, item in ipairs(model:GetDescendants()) do
        if item:IsA("BillboardGui") then
            item:Destroy()
        elseif item:IsA("BasePart") then
            item.Anchored = true
            item.CanCollide = false
            item.CanTouch = false
            item.CanQuery = true
        end
    end

    model:SetAttribute("Species", "Wolf")
    model:SetAttribute("AnimationSpecies", "Wolf")
    model:SetAttribute("Rarity", "Legendary")
    model:SetAttribute("Level", 50)
    model:SetAttribute("Power", 100000)
    model:SetAttribute("Defence", 9999)
    model:SetAttribute("Health", 50000)
    model:SetAttribute("MaxHealth", 50000)
    model:SetAttribute("Captured", false)
    model:SetAttribute("BeingCaptured", false)
    model:SetAttribute("InCombat", false)
    model:SetAttribute("Dead", false)
    model:SetAttribute("QuestStationary", true)
    model:SetAttribute("QuestNoCapture", true)
    model:SetAttribute("QuestNoRewards", true)
    model:SetAttribute("QuestTutorialSpar", true)
    model:SetAttribute("QuestOwnerUserId", player.UserId)
    model:SetAttribute("QuestId", "BeastHandlingTutorial")
    model:SetAttribute("QuestObjective", "RowanChallenge")

    local rig = Animator:_getRig(model)
    if not rig then
        model:Destroy()
        return
    end

    rig.base = CFrame.new(ground + Vector3.new(0, rig.clearance + .06, 0))
        * CFrame.Angles(0, math.rad(180), 0)
    Animator:Stop(model)

    local wild = world:FindFirstChild("WildMonsters")
    if not wild then
        model:Destroy()
        return
    end

    model.Parent = wild

    local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
    if part then
        local gui = Instance.new("BillboardGui")
        gui.Name = "TutorialSparLabel"
        gui.Size = UDim2.fromOffset(240, 34)
        gui.StudsOffsetWorldSpace = Vector3.new(0, model:GetExtentsSize().Y * .55 + .8, 0)
        gui.MaxDistance = 75
        gui.Parent = part

        local label = Instance.new("TextLabel")
        label.BackgroundTransparency = 1
        label.Size = UDim2.fromScale(1, 1)
        label.Font = Enum.Font.GothamBold
        label.TextSize = 13
        label.TextStrokeTransparency = .3
        label.TextColor3 = Color3.fromRGB(255, 202, 105)
        label.Text = "ROWAN'S VETERAN WOLF"
        label.Parent = gui
    end

    current.SparPet = model
    Animator:PlayIdle(model)
end

local function spawnQuestMountHorse(player)
    local _, _, chain, state, stage = chainStage(player, "SaddleUp")
    if not chain or not state or not stage or stage.Id ~= "CaptureHorse" then return end

    local current = currentPersonal(player)
    if current.MountHorse and current.MountHorse.Parent then
        return current.MountHorse
    end

    local maeve = npcPosition("Maeve") or Vector3.new(34, 15, 21)
    local rough = maeve + Vector3.new(125, 0, 95)
    local ground = terrainPoint(rough.X, rough.Z, maeve.Y)

    local model = ModelFactory:Create("Horse")
    if not model then return end
    model.Name = "QuestHorse_" .. tostring(player.UserId)

    for _, item in ipairs(model:GetDescendants()) do
        if item:IsA("BillboardGui") then
            item:Destroy()
        elseif item:IsA("BasePart") then
            item.Anchored = true
            item.CanCollide = false
            item.CanTouch = false
            item.CanQuery = true
        end
    end

    model:SetAttribute("Species", "Horse")
    model:SetAttribute("AnimationSpecies", "ShadowStag")
    model:SetAttribute("Rarity", "Common")
    model:SetAttribute("CreatureType", "Mount")
    model:SetAttribute("Rideable", true)
    model:SetAttribute("Invulnerable", true)
    model:SetAttribute("Level", 1)
    model:SetAttribute("Power", 0)
    model:SetAttribute("Defence", 999999)
    model:SetAttribute("Health", 1)
    model:SetAttribute("MaxHealth", 1)
    model:SetAttribute("CaptureDifficulty", Config.Rarities.Common.CaptureDifficulty)
    model:SetAttribute("Captured", false)
    model:SetAttribute("BeingCaptured", false)
    model:SetAttribute("InCombat", false)
    model:SetAttribute("Dead", false)
    model:SetAttribute("QuestStationary", true)
    model:SetAttribute("QuestMountTutorial", true)
    model:SetAttribute("QuestPrivateCreature", true)
    model:SetAttribute("QuestOwnerUserId", player.UserId)
    model:SetAttribute("QuestId", "SaddleUp")
    model:SetAttribute("QuestObjective", "CaptureHorse")

    local rig = Animator:_getRig(model)
    if not rig then
        model:Destroy()
        return
    end
    rig.base = CFrame.new(ground + Vector3.new(0, rig.clearance + .06, 0))
        * CFrame.Angles(0, math.rad(160), 0)
    Animator:Stop(model)

    local wild = world:FindFirstChild("WildMonsters")
    if not wild then
        model:Destroy()
        return
    end

    local rootPart = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
    if rootPart then
        local gui = Instance.new("BillboardGui")
        gui.Name = "QuestMountLabel"
        gui.Size = UDim2.fromOffset(220, 38)
        gui.StudsOffsetWorldSpace = Vector3.new(0, model:GetExtentsSize().Y * .55 + .8, 0)
        gui.MaxDistance = 70
        gui.Parent = rootPart

        local text = Instance.new("TextLabel")
        text.BackgroundTransparency = 1
        text.Size = UDim2.fromScale(1, 1)
        text.Font = Enum.Font.GothamBold
        text.TextSize = 13
        text.TextStrokeTransparency = .3
        text.TextColor3 = Color3.fromRGB(245, 205, 118)
        text.Text = "MAEVE'S TRACKED HORSE"
        text.Parent = gui
    end

    model.Parent = wild
    current.MountHorse = model
    Animator:PlayIdle(model)
    return model
end

local function nearestWildTarget(player, stage)
    local root = getRoot(player)
    local folder = world and world:FindFirstChild("WildMonsters")
    if not root or not folder then return nil, nil end

    local bestModel
    local bestDistance = math.huge
    for _, model in ipairs(folder:GetChildren()) do
        if model:IsA("Model")
            and not model:GetAttribute("Dead")
            and not model:GetAttribute("Captured")
            and not model:GetAttribute("QuestOwnerUserId") then
            local wantedSpecies = stage.Species or stage.SourceSpecies
        local speciesMatches = not wantedSpecies or model:GetAttribute("Species") == wantedSpecies
            local rarityMatches = not stage.Rarity or model:GetAttribute("Rarity") == stage.Rarity
            local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
            if speciesMatches and rarityMatches and part then
                local distance = (root.Position - part.Position).Magnitude
                if distance < bestDistance then
                    bestDistance = distance
                    bestModel = model
                end
            end
        end
    end

    if not bestModel then return nil, nil end
    local part = bestModel.PrimaryPart or bestModel:FindFirstChildWhichIsA("BasePart", true)
    if not part then return nil, nil end
    return part.Position, tostring(bestModel:GetAttribute("Species") or stage.Species or stage.Rarity or "Quest target")
end

local function actionObjectiveTarget(player, stage)
    local action = stage and stage.Action
    if action == "StartHealing" or action == "CollectHealed" then
        local plots = world and world:FindFirstChild("Plots")
        if plots then
            for _, plot in ipairs(plots:GetChildren()) do
                local owner = tonumber(plot:GetAttribute("OwnerUserId") or plot:GetAttribute("Owner"))
                if owner == player.UserId then
                    local barn = plot:FindFirstChild("HealingBarn")
                    local promptPart = barn and barn:FindFirstChild("BarnPrompt")
                    if promptPart and promptPart:IsA("BasePart") then
                        return promptPart.Position, "Your Pet Barn"
                    end
                end
            end
        end
    elseif action == "CapturePet" then
        return nearestWildTarget(player, stage or {})
    elseif action == "SellPet" or action == "BuybackPet" then
        for _, instance in ipairs(workspace:GetDescendants()) do
            if instance:IsA("Model") then
                local normalized = instance.Name:lower():gsub("[^%w]", "")
                if normalized == "beasttrader"
                    or normalized == "beasttradernpc"
                    or normalized == "beastmaster"
                    or normalized == "beastmasternpc" then
                    local part = instance.PrimaryPart or instance:FindFirstChildWhichIsA("BasePart", true)
                    if part then return part.Position, "Beast Trader" end
                end
            end
        end
    end
    return nil, nil
end

local function stageReadyForNPC(player, chain, state, stage)
    if not stage then return false end
    if chain and chain.Special == "LeatherTrader" then
        return false
    end
    if chain and chain.Special == "MountTutorial" and stage.Id == "ReturnMounted" then
        local data = DataService:Get(player)
        return data ~= nil
            and state.TargetMountId ~= ""
            and data.EquippedMountId == state.TargetMountId
    end
    if stage.Type == "Talk" then
        return true
    elseif stage.Type == "CaptureReturn" then
        return stageCount(player, state, stage) >= math.max(1, tonumber(stage.Required) or 1)
    elseif stage.Type == "InspectPet" or stage.Type == "ItemTurnIn" then
        return stageCount(player, state, stage) >= math.max(1, tonumber(stage.Required) or 1)
    elseif stage.Type == "MultiItemTurnIn" then
        local _, _, ready = multiItemProgress(player, stage)
        return ready
    end
    return false
end

local function npcAvailability(player)
    local root, data, entries = activeChainEntries(player)
    local result = {}
    if not root or not data then return result end

    local tutorialComplete = root.Completed.BeastHandlingTutorial == true
    local strength = progressionLassoStrength(data)

    for _, npcId in ipairs(QuestConfig.NPCOrder) do
        local visible = npcId == "Rowan"

        if not visible then
            for _, entry in ipairs(entries) do
                if entry.Chain.NPC == npcId then
                    visible = true
                    break
                end
            end
        end

        if not visible and tutorialComplete then
            for _, chain in pairs(QuestConfig.Chains) do
                if chain.NPC == npcId then
                    local active = root.ActiveQuestIds and root.ActiveQuestIds[chain.Id] == true
                    if root.Completed[chain.Id]
                        or active
                        or (prerequisiteMet(root, chain)
                            and strength >= math.max(0, tonumber(chain.RequiredStrength) or 0)) then
                        visible = true
                        break
                    end
                end
            end
        end

        local marker
        for _, entry in ipairs(entries) do
            if entry.Chain.NPC == npcId
                and stageReadyForNPC(player, entry.Chain, entry.State, entry.Stage) then
                marker = "?"
                break
            end
        end

        if not marker then
            local available = availableChainsForNPC(root, data, npcId)
            if #available > 0 then marker = "!" end
        end

        result[npcId] = {
            Visible = visible,
            Marker = marker,
            Name = npcName(npcId),
        }
    end

    return result
end

function Service:GetClientState(player)
    local root, data, entries = activeChainEntries(player)
    if not root or not data then return nil end

    local payload = {
        Trackers = {},
        NPCs = npcAvailability(player),
        ActiveQuestIds = activeQuestIds(root),
        StrongestLassoStrength = strongestOwnedLasso(data),
        ProgressionLassoStrength = progressionLassoStrength(data),
        MiraMarker = false,
    }

    local function trackerFor(entry)
        local chain = entry.Chain
        local state = entry.State
        local stage = entry.Stage
        local required = math.max(1, math.floor(tonumber(stage.Required) or 1))
        local count = math.min(stageCount(player, state, stage), required)
        local targetPosition
        local targetLabel

        if chain.Special == "MountTutorial" then
            if stage.Id == "CaptureHorse" then
                local current = currentPersonal(player)
                local horse = current.MountHorse
                local part = horse and horse.Parent and (horse.PrimaryPart or horse:FindFirstChildWhichIsA("BasePart", true))
                if part then
                    targetPosition = part.Position
                    targetLabel = "Maeve's Tracked Horse"
                else
                    targetPosition = npcPosition("Maeve")
                    targetLabel = npcName("Maeve")
                end
            elseif stage.Id == "ReturnMounted" then
                targetPosition = npcPosition("Maeve")
                targetLabel = npcName("Maeve")
            end
        elseif chain.Special == "LeatherTrader" then
            if stage.Id == "FindTrader" then
                targetPosition = leatherTraderPosition
                targetLabel = "Leather Trader's Hut"
            elseif stage.Id == "GatherHides" then
                local _, _, ready, _, missing = multiItemProgress(player, stage)
                if ready then
                    targetPosition = leatherTraderPosition
                    targetLabel = "Leather Trader Corvin"
                elseif missing then
                    targetPosition, targetLabel = nearestWildTarget(player, {
                        Species = missing.SourceSpecies,
                    })
                end
            end
        elseif chain.Special == "Hollowfang" then
            if stage.Id == "Bears" then
                targetPosition = caveEntrance
                targetLabel = "Hollowfang Cave"
            elseif stage.Id == "FindMira" then
                targetPosition = caveEntrance + Vector3.new(0, 0, 7)
                targetLabel = "Scout Mira"
                payload.MiraMarker = true
            elseif stage.Id == "ReportRowan" then
                targetPosition = npcPosition("Rowan")
                targetLabel = npcName("Rowan")
            end
        elseif chain.Id == "BeastHandlingTutorial" and stage.Id == "RowanChallenge" then
            local current = currentPersonal(player)
            local spar = current.SparPet
            local part = spar and spar.Parent and (spar.PrimaryPart or spar:FindFirstChildWhichIsA("BasePart", true))
            if part then
                targetPosition = part.Position
                targetLabel = "Rowan's Veteran Wolf"
            else
                targetPosition = npcPosition("Rowan")
                targetLabel = npcName("Rowan")
            end
        elseif stage.Type == "Talk" then
            targetPosition = npcPosition(chain.NPC)
            targetLabel = npcName(chain.NPC)
        elseif (stage.Type == "CaptureReturn" or stage.Type == "InspectPet" or stage.Type == "ItemTurnIn") and count >= required then
            targetPosition = npcPosition(chain.NPC)
            targetLabel = npcName(chain.NPC)
        elseif stage.Type == "CaptureReturn" or stage.Type == "Kill" or stage.Type == "ItemTurnIn" then
            targetPosition, targetLabel = nearestWildTarget(player, stage)
        elseif stage.Type == "Action" then
            targetPosition, targetLabel = actionObjectiveTarget(player, stage)
        end

        local progressText
        local detailText = stage.Detail or ""
        if stage.Type == "MultiItemTurnIn" then
            local total, totalRequired, ready, parts = multiItemProgress(player, stage)
            progressText = ready
                and "READY TO DELIVER"
                or (tostring(total) .. " / " .. tostring(totalRequired) .. " MATERIALS")
            detailText = table.concat(parts, "  ·  ")
        elseif stage.Type == "Talk" then
            if chain.Id == "BeastHandlingTutorial" and stage.Id == "ReturnForChallenge" then
                progressText = "RETURN TO ROWAN"
            else
                progressText = chain.Special == "LeatherTrader" and "FIND CORVIN" or "READY TO REPORT"
            end
        elseif stage.Type == "Spar" then
            progressText = "CHALLENGE READY"
        else
            progressText = tostring(count) .. " / " .. tostring(required)
        end

        return {
            Chain = chain.Name,
            QuestId = chain.Id,
            Stage = stage.Id,
            Active = true,
            Title = chain.Name,
            ObjectiveType = stage.Type,
            ObjectiveTypeLabel = QuestConfig.ObjectiveTypes[stage.Type] or string.upper(stage.Type),
            Objective = stage.Objective or "",
            Detail = detailText,
            Progress = progressText,
            TargetPosition = targetPosition,
            TargetLabel = targetLabel,
            Reward = rewardText(chain.Reward),
        }
    end

    for _, entry in ipairs(entries) do
        table.insert(payload.Trackers, trackerFor(entry))
    end

    if #payload.Trackers == 0 then
        if root.Completed.StarterWolves ~= true then
            table.insert(payload.Trackers, {
                Chain = "Getting Started",
                QuestId = "TutorialTalk",
                Stage = "MeetRowan",
                Active = true,
                Title = "Getting Started",
                ObjectiveType = "Talk",
                ObjectiveTypeLabel = QuestConfig.ObjectiveTypes.Talk,
                Objective = "Speak to Warden Rowan in the centre village.",
                Detail = "Look for the gold ! above Warden Rowan.",
                Progress = "0 / 1",
                TargetPosition = npcPosition("Rowan"),
                TargetLabel = npcName("Rowan"),
                Reward = "",
            })
        elseif root.Completed.BeastHandlingTutorial ~= true then
            table.insert(payload.Trackers, {
                Chain = "Continue Your Training",
                QuestId = "TutorialLeadOn",
                Stage = "MeetRowan",
                Active = true,
                Title = "Continue Your Training",
                ObjectiveType = "Talk",
                ObjectiveTypeLabel = QuestConfig.ObjectiveTypes.Talk,
                Objective = "Return to Warden Rowan for your companion-handling lesson.",
                Detail = "Finish Rowan's handling tutorial before the rest of the village quest roster unlocks.",
                Progress = "READY",
                TargetPosition = npcPosition("Rowan"),
                TargetLabel = npcName("Rowan"),
                Reward = "",
            })
        end
    end

    return payload
end

function Service:PushState(player)
    local state = self:GetClientState(player)
    if state then
        QuestRemote:FireClient(player, "State", state)
    end
end

local function completeQuest(player, chain)
    local root = questData(player)
    if not root then return end
    root.ActiveQuestIds = type(root.ActiveQuestIds) == "table" and root.ActiveQuestIds or {}
    if root.ActiveQuestIds[chain.Id] ~= true then return end

    root.Completed[chain.Id] = true
    root.Quests[chain.Id] = nil
    root.ActiveQuestIds[chain.Id] = nil
    if chain.Id == "BeastHandlingTutorial" then
        player:SetAttribute("TutorialHomeGuide", false)
    end

    local current = personal[player]
    if chain.Id == "HollowfangRescue" and current and current.Mira and current.Mira.Parent then
        current.Mira:Destroy()
        current.Mira = nil
    elseif chain.Id == "BeastHandlingTutorial" and current and current.SparPet and current.SparPet.Parent then
        current.SparPet:Destroy()
        current.SparPet = nil
    end
    if chain.Id == "SaddleUp" and current and current.MountHorse and current.MountHorse.Parent then
        current.MountHorse:Destroy()
        current.MountHorse = nil
    end

    grantReward(player, chain)
    Service:PushState(player)

    local text = chain.CompleteText or "Quest complete."
    local options = {}

    if chain.Id == "StarterWolves" then
        local tutorial = QuestConfig.Chains.BeastHandlingTutorial
        text ..= "\n\nGood work with the Wolves. Before I send you to the rest of the village, I want to teach you how to handle a companion properly. " .. tutorial.Intro
        options = {
            {Text = "START COMPANION TRAINING", Action = "Accept:BeastHandlingTutorial"},
            {Text = "I'LL COME BACK", Action = "Close"},
        }
    elseif chain.Id == "BeastHandlingTutorial" then
        text ..= "\n\nFrom here on, you can accept several jobs at once. Open the QUESTS panel whenever you want to check each objective separately."
    end

    sendDialogue(
        player,
        chain.Special == "LeatherTrader" and "Leather Trader Corvin" or npcName(chain.NPC),
        text .. (rewardText(chain.Reward) ~= "" and ("\n\nReward: " .. rewardText(chain.Reward) .. ".") or ""),
        options
    )
end

local function advanceStage(player, chain, state)
    state.StageIndex += 1
    state.Count = 0
    local nextStage = chain.Stages[state.StageIndex]

    if not nextStage then
        completeQuest(player, chain)
        return
    end

    if chain.Special == "Hollowfang" and nextStage.Id == "FindMira" then
        moveMiraOutside(player)
        QuestRemote:FireClient(player, "Toast", "The last Hollowfang Bear falls. Scout Mira is coming out of the cave!")
    end

    if chain.Id == "SaddleUp" then
        if nextStage.Id == "EquipHorse" then
            QuestRemote:FireClient(player, "TutorialGuide", {
                Kind = "Mount",
                MountId = state.TargetMountId,
            })
        elseif nextStage.Id == "ReturnMounted" then
            QuestRemote:FireClient(player, "TutorialGuide", {Kind = "Clear"})
        end
    end

    if chain.Id == "BeastHandlingTutorial" then
        player:SetAttribute("TutorialHomeGuide", nextStage.Id == "StartHealing")
        if nextStage.Id == "RenameCompanion" then
            QuestRemote:FireClient(player, "TutorialGuide", {
                Kind = "Rename",
                PetId = state.TargetPetId,
            })
        elseif nextStage.Id == "UpgradeCompanion" then
            local pet = PetService:Find(player, state.TargetPetId)
            if pet then
                pet.UpgradePoints = math.max(1, tonumber(pet.UpgradePoints) or 0)
            end
            QuestRemote:FireClient(player, "TutorialGuide", {
                Kind = "Upgrade",
                PetId = state.TargetPetId,
            })
        elseif nextStage.Id == "RowanChallenge" then
            QuestRemote:FireClient(player, "TutorialGuide", {Kind = "Clear"})
            spawnTutorialSpar(player)
            sendDialogue(
                player,
                "Warden Rowan",
                "You've learned the basics. Now attack my veteran Wolf with your companion. Don't worry about winning — I want you to see what happens when you take a fight your beast isn't ready for.",
                {{Text="I'M READY",Action="Close"}}
            )
        elseif nextStage.Id == "StartHealing" then
            QuestRemote:FireClient(player, "TutorialGuide", {Kind = "Home", PetId = state.TargetPetId})
            local current = currentPersonal(player)
            if current.SparPet and current.SparPet.Parent then
                current.SparPet:Destroy()
                current.SparPet = nil
            end
            sendDialogue(
                player,
                "Warden Rowan",
                "That's enough. My Wolf was never a fair fight — that was the lesson. Your companion has fallen, but it isn't lost. Take it to the Pet Barn on your plot, start the healing timer, and collect it when recovery is complete.",
                {{Text="TAKE PET TO THE BARN",Action="Close"}}
            )
        else
            QuestRemote:FireClient(player, "TutorialGuide", {Kind = "Clear"})
        end
    end

    Service:PushState(player)
end

local function acceptQuest(player, questId)
    local root, data = questData(player)
    local chain = QuestConfig.Chains[questId]
    if not root or not data or not chain then return end

    root.ActiveQuestIds = type(root.ActiveQuestIds) == "table" and root.ActiveQuestIds or {}
    if root.ActiveQuestIds[questId] == true then
        sendDialogue(player, npcName(chain.NPC), "You already have that quest in your QUESTS panel.", {{Text="CLOSE",Action="Close"}})
        return
    end

    if not chainUnlocked(root, data, chain) then
        local requiredName = chain.RequiredLasso or "the required progression"
        sendDialogue(player, npcName(chain.NPC), "That quest is not available to you yet. Come back when you've reached " .. requiredName .. ".", {{Text="CLOSE",Action="Close"}})
        return
    end

    local model = npcModels[chain.NPC]
    if model and not near(player, model:GetPivot().Position, 18) then return end

    root.ActiveQuestIds[chain.Id] = true
    root.Quests[chain.Id] = {StageIndex = 1, Count = 0, TargetPetId = "", TargetMountId = ""}

    if chain.Special == "Hollowfang" then
        spawnBearObjective(player)
    elseif chain.Special == "MountTutorial" then
        spawnQuestMountHorse(player)
    end

    Service:PushState(player)
    sendDialogue(
        player,
        npcName(chain.NPC),
        chain.Special == "Hollowfang"
            and "Good. Take your best beast and head northeast. Follow the quest marker to Hollowfang Cave. Clear the Bears first; Mira cannot get out while they're at the entrance."
            or "Quest accepted. It has been added to your QUESTS panel.",
        {{Text="LET'S GO",Action="Close"}}
    )
end

local function offerQuest(player, chain)
    local requirement = ""
    if chain.RequiredLasso then
        requirement = "\n\nRequired equipment: " .. chain.RequiredLasso .. " or better."
    end
    sendDialogue(
        player,
        npcName(chain.NPC),
        chain.Intro .. requirement .. "\n\nReward: " .. rewardText(chain.Reward) .. ".",
        {
            {Text = "ACCEPT QUEST", Action = "Accept:" .. chain.Id},
            {Text = "NOT NOW", Action = "Close"},
        }
    )
end

function Service:TalkToNPC(player, npcId)
    local root, data, entries = activeChainEntries(player)
    local model = npcModels[npcId]
    if not root or not data or not model then return end
    if not near(player, model:GetPivot().Position, 16) then return end

    local relevant = {}
    for _, entry in ipairs(entries) do
        if entry.Chain.NPC == npcId then
            table.insert(relevant, entry)
        end
    end

    local ready
    for _, entry in ipairs(relevant) do
        if stageReadyForNPC(player, entry.Chain, entry.State, entry.Stage) then
            ready = entry
            break
        end
    end

    if ready then
        local chain = ready.Chain
        local state = ready.State
        local stage = ready.Stage

        if stage.Type == "CaptureReturn" then
            local count = stageCount(player, state, stage)
            local required = math.max(1, tonumber(stage.Required) or 1)
            sendDialogue(
                player,
                npcName(npcId),
                "You have what I asked for. I'll only take eligible animals that are healthy, unfavourited, and not assigned to another role.",
                {
                    {Text = "HAND OVER " .. tostring(required), Action = "TurnIn:" .. chain.Id},
                    {Text = "KEEP THEM FOR NOW", Action = "Close"},
                }
            )
            return
        elseif stage.Type == "ItemTurnIn" then
            local required = math.max(1, tonumber(stage.Required) or 1)
            sendDialogue(
                player,
                npcName(npcId),
                "You have the materials I need. Hand them over and I'll add them to the evidence for this job.",
                {
                    {Text = "HAND OVER " .. tostring(required) .. " " .. tostring(stage.Item), Action = "TurnInItems:" .. chain.Id},
                    {Text = "KEEP THEM FOR NOW", Action = "Close"},
                }
            )
            return
        elseif stage.Type == "InspectPet" then
            sendDialogue(
                player,
                npcName(npcId),
                "Yes — that's exactly the kind of beast I needed to examine. You keep it; I only need a closer look.",
                {
                    {Text = "SHOW PET", Action = "Inspect:" .. chain.Id},
                    {Text = "NOT YET", Action = "Close"},
                }
            )
            return
        elseif stage.Type == "Talk" then
            local body
            local buttonText
            if chain.Id == "BeastHandlingTutorial" and stage.Id == "ReturnForChallenge" then
                body = "I see you've put that upgrade point to work. Good. Bring your companion close — there's one last combat lesson I want to show you before I send you on village work."
                buttonText = "START THE FINAL LESSON"
            elseif chain.Special == "Hollowfang" and stage.Id == "ReportRowan" then
                body = "Mira is safe? Good. Tell me everything she saw inside Hollowfang."
                buttonText = "REPORT MIRA'S FINDINGS"
            else
                body = "You've finished this part of the job. Give me your report and we'll close it properly."
                buttonText = "REPORT BACK"
            end
            sendDialogue(
                player,
                npcName(npcId),
                body,
                {
                    {Text = buttonText, Action = "Talk:" .. chain.Id},
                    {Text = "NOT YET", Action = "Close"},
                }
            )
            return
        end
    end

    local available = availableChainsForNPC(root, data, npcId)
    if #available > 0 then
        offerQuest(player, available[1])
        return
    end

    if #relevant > 0 then
        local entry = relevant[1]
        local stage = entry.Stage
        local count = stageCount(player, entry.State, stage)
        local required = math.max(1, tonumber(stage.Required) or 1)
        sendDialogue(
            player,
            npcName(npcId),
            tostring(stage.Objective or "Keep working on this quest.")
                .. (stage.Type ~= "Talk" and ("\n\nProgress: " .. tostring(math.min(count, required)) .. "/" .. tostring(required)) or ""),
            {{Text="CLOSE",Action="Close"}}
        )
        return
    end

    if npcId == "Rowan" and root.Completed.StarterWolves and not root.Completed.BeastHandlingTutorial then
        local tutorial = QuestConfig.Chains.BeastHandlingTutorial
        offerQuest(player, tutorial)
        return
    end

    sendDialogue(player, npcName(npcId), "Nothing urgent for you right now. Keep improving your beasts and equipment; more work will open up as you're ready for it.", {{Text="CLOSE",Action="Close"}})
end

function Service:TalkToLeatherTrader(player)
    if not leatherTraderModel or not leatherTraderModel.Parent then return end
    if not near(player, leatherTraderModel:GetPivot().Position, 16) then return end

    local root = questData(player)
    if not root then return end

    local _, _, chain, state, stage = chainStage(player, "BiggerBag")
    if chain and state and stage then
        if stage.Id == "FindTrader" then
            sendDialogue(
                player,
                "Leather Trader Corvin",
                "Rowan sent you? Then he finally noticed that tiny starter bag of yours. I can make something better, but good leather doesn't appear by wishing for it. Bring me a few clean hides from the Common wildlife around here and I'll put together a proper field satchel.",
                {
                    {Text="WHAT DO YOU NEED?", Action="LeatherTraderFound"},
                    {Text="I'LL COME BACK", Action="Close"},
                }
            )
            return
        elseif stage.Id == "GatherHides" then
            local _, _, ready, parts = multiItemProgress(player, stage)
            if ready then
                sendDialogue(
                    player,
                    "Leather Trader Corvin",
                    "That's the lot. Good hides, too. Hand them over and I'll stitch the satchel while the fire is hot.",
                    {
                        {Text="HAND OVER MATERIALS", Action="LeatherTurnIn"},
                        {Text="KEEP THEM FOR NOW", Action="Close"},
                    }
                )
            else
                sendDialogue(
                    player,
                    "Leather Trader Corvin",
                    "You're not carrying everything yet. I need:\n\n" .. table.concat(parts, "\n") .. "\n\nBring the full bundle back to me.",
                    {{Text="CLOSE",Action="Close"}}
                )
            end
            return
        end
    end

    if root.Completed.BiggerBag == true then
        leatherTradeSessions[player] = {
            expiresAt = os.clock() + 30,
        }
        ShopRemote:FireClient(player, "OpenLeatherTrader")
        return
    end

    sendDialogue(
        player,
        "Leather Trader Corvin",
        "I keep to myself out here. If Warden Rowan has business with me, he'll send word.",
        {{Text="CLOSE",Action="Close"}}
    )
end

function Service:CanLeatherTrade(player)
    local root = questData(player)
    if not root or root.Completed.BiggerBag ~= true then
        return false, "Finish Corvin's leather-working quest first."
    end

    local session = leatherTradeSessions[player]
    if not session or os.clock() > session.expiresAt then
        leatherTradeSessions[player] = nil
        return false, "Speak to Leather Trader Corvin first."
    end
    if not leatherTraderModel or not leatherTraderModel.Parent then
        return false, "Leather Trader Corvin is unavailable."
    end
    if not near(player, leatherTraderModel:GetPivot().Position, 20) then
        return false, "Move closer to Leather Trader Corvin."
    end

    session.expiresAt = os.clock() + 30
    return true
end

function Service:TalkToMira(player)
    local _, _, chain, state, stage = chainStage(player, "HollowfangRescue")
    local current = personal[player]
    if not chain or not state or not stage or not current or not current.Mira or not current.Mira.Parent then return end
    if current.Mira:GetAttribute("QuestOwnerUserId") ~= player.UserId then return end
    if not near(player, current.Mira:GetPivot().Position, 16) then return end

    if stage.Id == "FindMira" then
        sendDialogue(
            player,
            "Scout Mira",
            "You actually made it. Listen carefully: those Bears weren't hunting me — they were trying to get away from something deeper inside Hollowfang. I found fresh gouges in the stone, far too large for a Bear, and scales caught between the rocks. I need Rowan to hear this before anyone else goes into those tunnels.",
            {
                {Text = "I'LL REPORT THIS TO ROWAN", Action = "MiraReport"},
                {Text = "NOT YET", Action = "Close"},
            }
        )
    elseif stage.Id == "ReportRowan" then
        sendDialogue(player, "Scout Mira", "Please get my findings to Rowan. Whatever frightened those Bears may still be below us.", {{Text="CLOSE",Action="Close"}})
    end
end

function Service:HandleAction(player, action)
    if type(action) ~= "string" then return end
    if action == "Close" then return end

    local acceptId = action:match("^Accept:(.+)$")
    if acceptId then
        acceptQuest(player, acceptId)
        return
    end

    if action == "LeatherTraderFound" then
        local _, _, chain, state, stage = chainStage(player, "BiggerBag")
        if not chain or not state or not stage or stage.Id ~= "FindTrader" then return end
        if not leatherTraderModel or not near(player, leatherTraderModel:GetPivot().Position, 16) then return end
        advanceStage(player, chain, state)
        sendDialogue(
            player,
            "Leather Trader Corvin",
            "Bring me 2 Wolf Hides, 2 Hare Pelts and 2 Coarse Boar Hides. Open the loot bags you want, take only the materials worth carrying, and come back when you've got the full bundle.",
            {{Text="I'LL GET THEM",Action="Close"}}
        )
        return
    end

    if action == "LeatherTurnIn" then
        local _, _, chain, state, stage = chainStage(player, "BiggerBag")
        if not chain or not state or not stage or stage.Id ~= "GatherHides" then return end
        if not leatherTraderModel or not near(player, leatherTraderModel:GetPivot().Position, 16) then return end
        if not consumeMultiItems(player, stage) then
            sendDialogue(player, "Leather Trader Corvin", "You're missing part of the material bundle.", {{Text="CLOSE",Action="Close"}})
            Service:PushState(player)
            return
        end
        advanceStage(player, chain, state)
        return
    end

    local turnInId = action:match("^TurnIn:(.+)$")
    if turnInId then
        local _, _, chain, state, stage = chainStage(player, turnInId)
        if not chain or not state or not stage or stage.Type ~= "CaptureReturn" then return end
        local model = npcModels[chain.NPC]
        if model and not near(player, model:GetPivot().Position, 16) then return end
        if not removeTurnInPets(player, stage) then
            sendDialogue(player, npcName(chain.NPC), "I can't take the requested animals yet. Make sure enough eligible pets are free in your backpack.", {{Text="CLOSE",Action="Close"}})
            Service:PushState(player)
            return
        end
        advanceStage(player, chain, state)
        return
    end

    local itemTurnInId = action:match("^TurnInItems:(.+)$")
    if itemTurnInId then
        local _, _, chain, state, stage = chainStage(player, itemTurnInId)
        if not chain or not state or not stage or stage.Type ~= "ItemTurnIn" then return end
        local model = npcModels[chain.NPC]
        if model and not near(player, model:GetPivot().Position, 16) then return end
        local required = math.max(1, math.floor(tonumber(stage.Required) or 1))
        if LootService:GetCount(player, stage.Item) < required
            or not LootService:ConsumeItem(player, stage.Item, required) then
            sendDialogue(player, npcName(chain.NPC), "You don't have enough of the requested material yet.", {{Text="CLOSE",Action="Close"}})
            Service:PushState(player)
            return
        end
        advanceStage(player, chain, state)
        return
    end

    local inspectId = action:match("^Inspect:(.+)$")
    if inspectId then
        local _, _, chain, state, stage = chainStage(player, inspectId)
        if not chain or not state or not stage or stage.Type ~= "InspectPet" then return end
        local model = npcModels[chain.NPC]
        if model and not near(player, model:GetPivot().Position, 16) then return end
        if stageCount(player, state, stage) < math.max(1, tonumber(stage.Required) or 1) then return end
        advanceStage(player, chain, state)
        return
    end

    local talkId = action:match("^Talk:(.+)$")
    if talkId then
        local _, _, chain, state, stage = chainStage(player, talkId)
        if not chain or not state or not stage or stage.Type ~= "Talk" then return end
        local model = npcModels[chain.NPC]
        if model and not near(player, model:GetPivot().Position, 16) then return end
        advanceStage(player, chain, state)
        return
    end

    if action == "MiraReport" then
        local _, _, chain, state, stage = chainStage(player, "HollowfangRescue")
        if not chain or not state or not stage or stage.Id ~= "FindMira" then return end
        local current = personal[player]
        if not current or not current.Mira or not current.Mira.Parent or not near(player, current.Mira:GetPivot().Position, 16) then return end
        advanceStage(player, chain, state)
        sendDialogue(
            player,
            "Scout Mira",
            "Tell Rowan exactly this: the Bears were fleeing deeper tunnels, the stone is freshly gouged, and I found scales where no scaled beast should be. I'll follow once I've caught my breath.",
            {{Text="REPORT TO ROWAN",Action="Close"}}
        )
    end
end

function Service:OnMonsterKilled(player, target, petId)
    if not player or not target then return false end

    local _, _, entries = activeChainEntries(player)
    local progressed = false

    for _, entry in ipairs(entries) do
        local chain = entry.Chain
        local state = entry.State
        local stage = entry.Stage

        if stage.Type == "Kill" then
            local matches = true

            if chain.Id == "BeastHandlingTutorial" and stage.TutorialPetOnly then
                matches = state.TargetPetId ~= ""
                    and state.TargetPetId == petId
                    and target:GetAttribute("QuestOwnerUserId") == nil
            elseif chain.Special == "Hollowfang" then
                matches = target:GetAttribute("QuestId") == chain.Id
                    and target:GetAttribute("QuestObjective") == "HollowfangBears"
                    and tonumber(target:GetAttribute("QuestOwnerUserId")) == player.UserId
                    and not target:GetAttribute("KillRecorded_" .. chain.Id)
                if matches then
                    target:SetAttribute("KillRecorded_" .. chain.Id, true)
                end
            else
                local species = target:GetAttribute("Species")
                local rarity = target:GetAttribute("Rarity")
                if stage.Species and species ~= stage.Species then matches = false end
                if stage.Rarity and rarity ~= stage.Rarity then matches = false end
            end

            if matches then
                state.Count = math.min(
                    math.max(1, tonumber(stage.Required) or 1),
                    state.Count + 1
                )
                progressed = true

                QuestRemote:FireClient(
                    player,
                    "Toast",
                    (stage.Species or stage.Rarity or "Quest target")
                        .. " progress  ·  "
                        .. tostring(state.Count)
                        .. "/"
                        .. tostring(stage.Required or 1)
                )

                if state.Count >= math.max(1, tonumber(stage.Required) or 1) then
                    advanceStage(player, chain, state)
                end
            end
        end
    end

    if progressed then Service:PushState(player) end
    return progressed
end

function Service:OnPlayerAction(player, actionName, details)
    if type(actionName) ~= "string" then return false end
    details = type(details) == "table" and details or {}

    local _, _, entries = activeChainEntries(player)
    local progressed = false

    for _, entry in ipairs(entries) do
        local chain = entry.Chain
        local state = entry.State
        local stage = entry.Stage

        if stage.Type == "Action" and stage.Action == actionName then
            local matches = true

            if chain.Id == "BeastHandlingTutorial" then
                local petId = type(details.PetId) == "string" and details.PetId or ""
                if actionName == "CapturePet" then
                    local pet = petId ~= "" and PetService:Find(player, petId) or nil
                    local requiredRarity = stage.Rarity
                    if not pet or (requiredRarity and pet.Rarity ~= requiredRarity) then
                        matches = false
                    else
                        state.TargetPetId = petId
                    end
                elseif actionName == "EquipPet"
                    or actionName == "RenamePet"
                    or actionName == "UpgradePet"
                    or actionName == "StartHealing"
                    or actionName == "CollectHealed" then
                    matches = state.TargetPetId ~= "" and petId == state.TargetPetId
                end
            elseif chain.Id == "SaddleUp" then
                local mountId = type(details.MountId) == "string" and details.MountId or ""
                if actionName == "CaptureMount" then
                    local mount = mountId ~= "" and MountService:Find(player, mountId) or nil
                    matches = mount ~= nil
                        and mount.Species == "Horse"
                        and details.QuestMount == true
                    if matches then
                        state.TargetMountId = mountId
                        local current = currentPersonal(player)
                        if current.MountHorse and current.MountHorse.Parent then
                            current.MountHorse = nil
                        end
                    end
                elseif actionName == "EquipMount" then
                    matches = state.TargetMountId ~= "" and mountId == state.TargetMountId
                end
            end

            if matches then
                state.Count = math.min(
                    math.max(1, tonumber(stage.Required) or 1),
                    state.Count + 1
                )
                progressed = true

                if state.Count >= math.max(1, tonumber(stage.Required) or 1) then
                    advanceStage(player, chain, state)
                else
                    Service:PushState(player)
                end
            end
        end
    end

    return progressed
end

function Service:OnCompanionDefeated(player, target, petId)
    local _, _, chain, state, stage = chainStage(player, "BeastHandlingTutorial")
    if not chain or not state or not stage or stage.Id ~= "RowanChallenge" then return false end
    if state.TargetPetId == "" or state.TargetPetId ~= petId then return false end
    if not target or target:GetAttribute("QuestTutorialSpar") ~= true then return false end
    if tonumber(target:GetAttribute("QuestOwnerUserId")) ~= player.UserId then return false end

    state.Count = 1
    advanceStage(player, chain, state)
    return true
end

function Service:GetTutorialHealingSeconds(player, petId)
    local root, _, chain, state = chainStage(player, "BeastHandlingTutorial")
    if not root or not chain or not state then return nil end
    if root.Completed.BeastHandlingTutorial == true then return nil end
    if state.TargetPetId == "" or state.TargetPetId ~= petId then return nil end
    return 0
end

function Service:IsQuestMonsterAllowed(player, target)
    local owner = target and tonumber(target:GetAttribute("QuestOwnerUserId"))
    return owner == nil or owner == player.UserId
end

function Service:PlayerReady(player)
    local root = questData(player)
    if not root then return end

    destroyPersonal(player)

    local _, _, hollowfang, _, hollowStage = chainStage(player, "HollowfangRescue")
    if hollowfang and hollowStage then
        if hollowStage.Id == "Bears" then
            spawnBearObjective(player)
        elseif hollowStage.Id == "FindMira" or hollowStage.Id == "ReportRowan" then
            createMira(player, true)
        end
    end

    local _, _, mountQuest, mountState, mountStage = chainStage(player, "SaddleUp")
    if mountQuest and mountStage then
        if mountStage.Id == "CaptureHorse" then
            spawnQuestMountHorse(player)
        elseif mountStage.Id == "EquipHorse" then
            task.defer(function()
                if player.Parent then
                    QuestRemote:FireClient(player, "TutorialGuide", {Kind="Mount", MountId=mountState.TargetMountId})
                end
            end)
        end
    end

    local _, _, tutorial, tutorialState, tutorialStage = chainStage(player, "BeastHandlingTutorial")
    player:SetAttribute(
        "TutorialHomeGuide",
        tutorial ~= nil and tutorialStage ~= nil and tutorialStage.Id == "StartHealing"
    )
    if tutorial and tutorialStage then
        if tutorialStage.Id == "RowanChallenge" then
            spawnTutorialSpar(player)
        elseif tutorialStage.Id == "RenameCompanion" then
            task.defer(function()
                if player.Parent then
                    QuestRemote:FireClient(player, "TutorialGuide", {Kind="Rename", PetId=tutorialState.TargetPetId})
                end
            end)
        elseif tutorialStage.Id == "UpgradeCompanion" then
            task.defer(function()
                if player.Parent then
                    QuestRemote:FireClient(player, "TutorialGuide", {Kind="Upgrade", PetId=tutorialState.TargetPetId})
                end
            end)
        elseif tutorialStage.Id == "StartHealing" then
            task.defer(function()
                if player.Parent then
                    QuestRemote:FireClient(player, "TutorialGuide", {Kind="Home", PetId=tutorialState.TargetPetId})
                end
            end)
        end
    end

    task.defer(function()
        if player.Parent then Service:PushState(player) end
    end)
end

function Service:PlayerRemoving(player)
    destroyPersonal(player)
    leatherTradeSessions[player] = nil
end

local function buildCave()
    local settings = QuestConfig.World
    local baseGround = terrainPoint(settings.CaveXZ.X, settings.CaveXZ.Y, settings.CaveFallbackY)
    caveEntrance = baseGround + Vector3.new(0, .15, 0)
    caveInner = caveEntrance + Vector3.new(0, 0, -18)

    caveModel = Instance.new("Model")
    caveModel.Name = "HollowfangCave"
    caveModel.Parent = questWorld

    local rock = Color3.fromRGB(70, 70, 67)
    local darkRock = Color3.fromRGB(48, 49, 48)

    makePart(caveModel, "CaveFloor", Vector3.new(28, 1.2, 42), CFrame.new(caveEntrance + Vector3.new(0, -.45, -10)), darkRock, Enum.Material.Slate)
    makePart(caveModel, "LeftWall", Vector3.new(8, 13, 34), CFrame.new(caveEntrance + Vector3.new(-10, 5.8, -9)) * CFrame.Angles(0, 0, math.rad(-5)), rock, Enum.Material.Rock)
    makePart(caveModel, "RightWall", Vector3.new(8, 13, 34), CFrame.new(caveEntrance + Vector3.new(10, 5.8, -9)) * CFrame.Angles(0, 0, math.rad(5)), rock, Enum.Material.Rock)
    makePart(caveModel, "Roof", Vector3.new(23, 6, 28), CFrame.new(caveEntrance + Vector3.new(0, 12, -11)), darkRock, Enum.Material.Rock)
    makePart(caveModel, "BackWall", Vector3.new(22, 12, 5), CFrame.new(caveEntrance + Vector3.new(0, 5.5, -28)), darkRock, Enum.Material.Rock)

    for index, spec in ipairs({
        {-8, 5, 1, 6, 11, 6},
        {8, 5, 1, 6, 11, 6},
        {-5, 10, -1, 7, 5, 6},
        {5, 10, -1, 7, 5, 6},
        {0, 12, -2, 8, 4, 7},
    }) do
        makePart(
            caveModel,
            "EntranceRock" .. tostring(index),
            Vector3.new(spec[4], spec[5], spec[6]),
            CFrame.new(caveEntrance + Vector3.new(spec[1], spec[2], spec[3]))
                * CFrame.Angles(math.rad(index * 7), math.rad(index * 19), math.rad(index * 5)),
            index % 2 == 0 and rock or darkRock,
            Enum.Material.Rock
        )
    end

    local sign = makePart(
        caveModel,
        "CaveSign",
        Vector3.new(8, 1.6, .45),
        CFrame.new(caveEntrance + Vector3.new(0, 4, 5)),
        Color3.fromRGB(82, 61, 42),
        Enum.Material.Wood
    )
    sign.CanCollide = false

    local surface = Instance.new("SurfaceGui")
    surface.Face = Enum.NormalId.Front
    surface.CanvasSize = Vector2.new(500, 100)
    surface.Parent = sign

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.fromScale(1, 1)
    label.Font = Enum.Font.GothamBold
    label.TextScaled = true
    label.TextColor3 = Color3.fromRGB(235, 220, 184)
    label.Text = "HOLLOWFANG CAVE"
    label.Parent = surface
end

local function buildLeatherTraderArea()
    local settings = QuestConfig.World
    local ground = terrainPoint(settings.LeatherTraderXZ.X, settings.LeatherTraderXZ.Y, settings.CaveFallbackY)
    leatherTraderPosition = ground + Vector3.new(0, .15, 0)

    local area = Instance.new("Model")
    area.Name = "LeatherTraderCamp"
    area.Parent = questWorld

    local wood = Color3.fromRGB(92, 66, 43)
    local darkWood = Color3.fromRGB(65, 47, 34)
    local hide = Color3.fromRGB(149, 112, 75)

    local hutCenter = leatherTraderPosition + Vector3.new(0, 0, -12)
    makePart(area, "HutFloor", Vector3.new(18,1,14), CFrame.new(hutCenter + Vector3.new(0,.3,0)), darkWood, Enum.Material.WoodPlanks)
    makePart(area, "HutBack", Vector3.new(18,10,1), CFrame.new(hutCenter + Vector3.new(0,5,-6.5)), wood, Enum.Material.WoodPlanks)
    makePart(area, "HutLeft", Vector3.new(1,10,14), CFrame.new(hutCenter + Vector3.new(-8.5,5,0)), wood, Enum.Material.WoodPlanks)
    makePart(area, "HutRight", Vector3.new(1,10,14), CFrame.new(hutCenter + Vector3.new(8.5,5,0)), wood, Enum.Material.WoodPlanks)
    makePart(area, "HutRoof", Vector3.new(20,1.2,16), CFrame.new(hutCenter + Vector3.new(0,10.2,0)) * CFrame.Angles(0,0,math.rad(4)), darkWood, Enum.Material.WoodPlanks)

    local fireCenter = leatherTraderPosition + Vector3.new(-5, .5, 5)
    for i=1,3 do
        local log = makePart(
            area,
            "FireLog"..tostring(i),
            Vector3.new(5,.55,.65),
            CFrame.new(fireCenter) * CFrame.Angles(0, math.rad((i-1)*60), math.rad(90)),
            darkWood,
            Enum.Material.Wood
        )
        log.CanCollide = false
    end
    local flame = makePart(area,"CampFlame",Vector3.new(1.5,2.8,1.5),CFrame.new(fireCenter+Vector3.new(0,1.5,0)),Color3.fromRGB(255,132,44),Enum.Material.Neon,Enum.PartType.Ball)
    flame.CanCollide=false
    flame.CanQuery=false
    local light=Instance.new("PointLight")
    light.Color=Color3.fromRGB(255,170,80)
    light.Brightness=2
    light.Range=18
    light.Parent=flame

    for rackIndex, xOffset in ipairs({7, 12}) do
        local base = leatherTraderPosition + Vector3.new(xOffset,0,2)
        local left = makePart(area,"Rack"..rackIndex.."Left",Vector3.new(.5,6,.5),CFrame.new(base+Vector3.new(-2,3,0)),wood,Enum.Material.Wood)
        local right = makePart(area,"Rack"..rackIndex.."Right",Vector3.new(.5,6,.5),CFrame.new(base+Vector3.new(2,3,0)),wood,Enum.Material.Wood)
        local top = makePart(area,"Rack"..rackIndex.."Top",Vector3.new(4.5,.45,.45),CFrame.new(base+Vector3.new(0,5.6,0)),wood,Enum.Material.Wood)
        left.CanCollide=false right.CanCollide=false top.CanCollide=false
        local hanging = makePart(area,"Rack"..rackIndex.."Hide",Vector3.new(3.1,3.8,.25),CFrame.new(base+Vector3.new(0,3.3,0)),hide,Enum.Material.Fabric)
        hanging.CanCollide=false
    end

    local model = Instance.new("Model")
    model.Name = "LeatherTrader"
    model:SetAttribute("LeatherTrader", true)

    local seated = leatherTraderPosition + Vector3.new(0,0,4)
    local root = makePart(model,"HumanoidRootPart",Vector3.new(2,2,1),CFrame.new(seated+Vector3.new(0,2,0)),Color3.new(),Enum.Material.SmoothPlastic)
    root.Transparency=1 root.CanCollide=false
    local torso=makePart(model,"Torso",Vector3.new(2.3,2.8,1.2),CFrame.new(seated+Vector3.new(0,2.7,0)),Color3.fromRGB(100,72,52),Enum.Material.Fabric)
    torso.CanCollide=false
    local head=makePart(model,"Head",Vector3.new(1.8,1.8,1.8),CFrame.new(seated+Vector3.new(0,4.8,0)),Color3.fromRGB(207,164,127),Enum.Material.SmoothPlastic,Enum.PartType.Ball)
    head.CanCollide=false
    local leg1=makePart(model,"LeftLeg",Vector3.new(.75,2.2,.8),CFrame.new(seated+Vector3.new(-.65,1.1,1.0))*CFrame.Angles(math.rad(55),0,0),Color3.fromRGB(61,57,52),Enum.Material.Fabric)
    local leg2=makePart(model,"RightLeg",Vector3.new(.75,2.2,.8),CFrame.new(seated+Vector3.new(.65,1.1,1.0))*CFrame.Angles(math.rad(55),0,0),Color3.fromRGB(61,57,52),Enum.Material.Fabric)
    leg1.CanCollide=false leg2.CanCollide=false
    model.PrimaryPart=root
    model.Parent=area
    billboard(torso,"Leather Trader Corvin","LEATHERWORKER",Color3.fromRGB(228,190,116))

    local prompt=Instance.new("ProximityPrompt")
    prompt.Name="LeatherTraderPrompt"
    prompt.ActionText="Talk"
    prompt.ObjectText="Leather Trader Corvin"
    prompt.MaxActivationDistance=12
    prompt.HoldDuration=.1
    prompt.RequiresLineOfSight=false
    prompt.Parent=torso
    prompt.Triggered:Connect(function(player)
        Service:TalkToLeatherTrader(player)
    end)

    leatherTraderModel=model
end

local function buildNPCs()
    for _, npcId in ipairs(QuestConfig.NPCOrder) do
        local spec = QuestConfig.World.NPCs[npcId]
        if spec then
            makeNPC(questWorld, npcId, spec)
        end
    end
end

local function buildStablemasterDisplay()
    local maeve = npcModels.Maeve
    if not maeve or not maeve.Parent then return end

    local horse = ModelFactory:Create("Horse")
    if not horse then return end
    horse.Name = "MaeveDisplayHorse"
    horse:SetAttribute("StablemasterDisplayHorse", true)

    for _, item in ipairs(horse:GetDescendants()) do
        if item:IsA("BillboardGui") then
            item:Destroy()
        elseif item:IsA("BasePart") then
            item.Anchored = true
            item.CanCollide = false
            item.CanTouch = false
            item.CanQuery = false
        end
    end

    local base = maeve:GetPivot().Position + Vector3.new(6, 0, 1)
    local ground = terrainPoint(base.X, base.Z, base.Y)
    horse.Parent = maeve
    horse:PivotTo(CFrame.new(ground + Vector3.new(0, horse:GetExtentsSize().Y * .45, 0))
        * CFrame.Angles(0, math.rad(-110), 0))

    local torso = maeve:FindFirstChild("Torso")
    local horsePart = horse.PrimaryPart or horse:FindFirstChildWhichIsA("BasePart", true)
    if torso and horsePart then
        local a0 = Instance.new("Attachment")
        a0.Name = "StablemasterLassoStart"
        a0.Position = Vector3.new(1.0, .6, 0)
        a0.Parent = torso

        local a1 = Instance.new("Attachment")
        a1.Name = "StablemasterLassoHorse"
        a1.Position = Vector3.new(0, .8, 1.3)
        a1.Parent = horsePart

        local rope = Instance.new("Beam")
        rope.Name = "StablemasterLasso"
        rope.Attachment0 = a0
        rope.Attachment1 = a1
        rope.Width0 = .12
        rope.Width1 = .10
        rope.Color = ColorSequence.new(Color3.fromRGB(154, 111, 68))
        rope.FaceCamera = true
        rope.Parent = maeve
    end
end

function Service:Init()
    if started then return end
    started = true

    world = workspace:WaitForChild("WildernessPets")
    local old = world:FindFirstChild("QuestWorld")
    if old then old:Destroy() end

    questWorld = Instance.new("Folder")
    questWorld.Name = "QuestWorld"
    questWorld.Parent = world

    buildCave()
    buildLeatherTraderArea()
    buildNPCs()
    buildStablemasterDisplay()

    QuestRemote.OnServerEvent:Connect(function(player, action, value)
        if action == "RequestState" then
            Service:PushState(player)
        elseif action == "Action" and type(value) == "string" then
            Service:HandleAction(player, value)
        end
    end)
end

return Service
