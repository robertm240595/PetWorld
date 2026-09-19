local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Root = ReplicatedStorage:WaitForChild("WildernessPets")
local QuestRemote = Root.Remotes:WaitForChild("Quest")
local QuestConfig = require(Root.Shared.QuestConfig)
local Config = require(Root.Shared.Config)

local DataService = require(script.Parent.PlayerDataService)
local PetService = require(script.Parent.PetService)
local ModelFactory = require(script.Parent.Parent.Systems.PetModelFactory)
local Animator = require(script.Parent.Parent.Systems.PetAnimator)

local Service = {}
local started = false
local world
local questWorld
local caveModel
local caveEntrance
local caveInner
local npcModels = {}
local personal = {}

local QUEST_VERSION = 2

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
    return table.concat(parts, " + ")
end

local function migrateQuestData(data)
    data.QuestProgress = type(data.QuestProgress) == "table" and data.QuestProgress or {}
    local old = data.QuestProgress
    if old.Version == QUEST_VERSION then
        old.Completed = type(old.Completed) == "table" and old.Completed or {}
        old.Quests = type(old.Quests) == "table" and old.Quests or {}
        old.ActiveQuestId = type(old.ActiveQuestId) == "string" and old.ActiveQuestId or ""
        return old
    end

    local migrated = {
        Version = QUEST_VERSION,
        ActiveQuestId = "",
        Completed = {},
        Quests = {},
    }

    local legacy = old.HollowfangRescue
    if type(legacy) == "table" then
        local stage = legacy.Stage
        if stage == "WolfReturn" then
            migrated.ActiveQuestId = "StarterWolves"
            migrated.Quests.StarterWolves = {StageIndex = 1, Count = 0}
        elseif stage == "BearRescue" then
            migrated.Completed.StarterWolves = true
            migrated.ActiveQuestId = "HollowfangRescue"
            migrated.Quests.HollowfangRescue = {
                StageIndex = 1,
                Count = math.clamp(math.floor(tonumber(legacy.BearsKilled) or 0), 0, 3),
            }
        elseif stage == "BearCleared" then
            migrated.Completed.StarterWolves = true
            migrated.ActiveQuestId = "HollowfangRescue"
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
        state = {StageIndex = 1, Count = 0}
        root.Quests[questId] = state
    end
    state.StageIndex = math.max(1, math.floor(tonumber(state.StageIndex) or 1))
    state.Count = math.max(0, math.floor(tonumber(state.Count) or 0))
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

local function chainUnlocked(root, data, chain)
    if root.Completed[chain.Id] then return false end
    if not prerequisiteMet(root, chain) then return false end
    local strength = strongestOwnedLasso(data)
    return strength >= math.max(0, tonumber(chain.RequiredStrength) or 0)
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
        state = {Bears = {}, Mira = nil}
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

local function stageCount(player, state, stage)
    if stage.Type == "CaptureReturn" then
        return #eligiblePets(player, stage)
    elseif stage.Type == "InspectPet" then
        return inspectCount(player, stage)
    elseif stage.Type == "Kill" then
        return state.Count
    elseif stage.Type == "Talk" then
        return 0
    end
    return state.Count
end

local function currentChainStage(player)
    local root, data = questData(player)
    if not root or root.ActiveQuestId == "" then return root, data, nil, nil, nil end

    local chain = QuestConfig.Chains[root.ActiveQuestId]
    if not chain then
        root.ActiveQuestId = ""
        return root, data, nil, nil, nil
    end

    local state = questState(root, chain.Id)
    local stage = chain.Stages[state.StageIndex]
    if not stage then
        return root, data, chain, state, nil
    end

    return root, data, chain, state, stage
end

local function grantReward(player, chain)
    local reward = chain.Reward or {}
    local coins = math.max(0, math.floor(tonumber(reward.Coins) or 0))
    local gems = math.max(0, math.floor(tonumber(reward.Gems) or 0))
    local coinBalance
    local gemBalance

    if coins > 0 then coinBalance = DataService:AddCoins(player, coins) end
    if gems > 0 then gemBalance = DataService:AddGems(player, gems) end

    QuestRemote:FireClient(player, "Reward", {
        Coins = coins,
        Gems = gems,
        CoinBalance = coinBalance,
        GemBalance = gemBalance,
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
    local root, _, chain, state, stage = currentChainStage(player)
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

local function stageReadyForNPC(player, chain, state, stage)
    if not stage then return false end
    if stage.Type == "Talk" then
        return true
    elseif stage.Type == "CaptureReturn" then
        return stageCount(player, state, stage) >= math.max(1, tonumber(stage.Required) or 1)
    elseif stage.Type == "InspectPet" then
        return stageCount(player, state, stage) >= math.max(1, tonumber(stage.Required) or 1)
    end
    return false
end

local function npcAvailability(player)
    local root, data, activeChain, activeState, activeStage = currentChainStage(player)
    local result = {}
    if not root or not data then return result end

    local starterComplete = root.Completed.StarterWolves == true
    local strength = strongestOwnedLasso(data)

    for _, npcId in ipairs(QuestConfig.NPCOrder) do
        local visible = npcId == "Rowan"
        if not visible and starterComplete then
            for _, chain in pairs(QuestConfig.Chains) do
                if chain.NPC == npcId then
                    if root.Completed[chain.Id]
                        or (prerequisiteMet(root, chain)
                            and strength >= math.max(0, tonumber(chain.RequiredStrength) or 0)) then
                        visible = true
                        break
                    end
                end
            end
        end

        local marker
        if activeChain then
            if activeChain.NPC == npcId and stageReadyForNPC(player, activeChain, activeState, activeStage) then
                marker = "?"
            end
        else
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
    local root, data, chain, state, stage = currentChainStage(player)
    if not root or not data then return nil end

    local payload = {
        Tracker = nil,
        NPCs = npcAvailability(player),
        ActiveQuestId = root.ActiveQuestId,
        StrongestLassoStrength = strongestOwnedLasso(data),
        MiraMarker = false,
    }

    if not chain or not stage then
        return payload
    end

    local required = math.max(1, math.floor(tonumber(stage.Required) or 1))
    local count = math.min(stageCount(player, state, stage), required)
    local targetPosition
    local targetLabel

    if chain.Special == "Hollowfang" then
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
    elseif stage.Type == "Talk" then
        targetPosition = npcPosition(chain.NPC)
        targetLabel = npcName(chain.NPC)
    elseif (stage.Type == "CaptureReturn" or stage.Type == "InspectPet") and count >= required then
        targetPosition = npcPosition(chain.NPC)
        targetLabel = npcName(chain.NPC)
    end

    local progressText
    if stage.Type == "Talk" then
        progressText = "READY TO REPORT"
    else
        progressText = tostring(count) .. " / " .. tostring(required)
    end

    payload.Tracker = {
        Chain = chain.Name,
        QuestId = chain.Id,
        Stage = stage.Id,
        Active = true,
        Title = chain.Name,
        ObjectiveType = stage.Type,
        ObjectiveTypeLabel = QuestConfig.ObjectiveTypes[stage.Type] or string.upper(stage.Type),
        Objective = stage.Objective or "",
        Detail = stage.Detail or "",
        Progress = progressText,
        TargetPosition = targetPosition,
        TargetLabel = targetLabel,
        Reward = rewardText(chain.Reward),
    }

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
    if not root or root.ActiveQuestId ~= chain.Id then return end

    root.Completed[chain.Id] = true
    root.Quests[chain.Id] = nil
    root.ActiveQuestId = ""

    if chain.Id == "HollowfangRescue" then
        local current = personal[player]
        if current and current.Mira and current.Mira.Parent then
            current.Mira:Destroy()
            current.Mira = nil
        end
    end

    grantReward(player, chain)
    Service:PushState(player)

    local text = chain.CompleteText
    local options = {}

    if chain.Id == "StarterWolves" then
        local _, data = questData(player)
        local hollowfang = QuestConfig.Chains.HollowfangRescue
        local strength = strongestOwnedLasso(data)
        if strength >= (hollowfang.RequiredStrength or 45) then
            text ..= "\n\nBefore you go, I have another urgent report. " .. hollowfang.Intro
            options = {
                {Text = "TAKE YOUR BEST BEAST — SAVE MIRA", Action = "Accept:HollowfangRescue"},
                {Text = "NOT NOW", Action = "Close"},
            }
        else
            text ..= "\n\nBefore you go: Scout Mira is missing near Hollowfang Cave. I need someone to save her, but the Bears there are Rare and dangerous. Come back when you own an Iron Lasso or better. When you're ready, take your best beast and save Scout Mira."
            options = {
                {Text = "I'LL COME BACK PREPARED", Action = "Close"},
            }
        end
    end

    sendDialogue(
        player,
        npcName(chain.NPC),
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

    Service:PushState(player)
end

local function acceptQuest(player, questId)
    local root, data = questData(player)
    local chain = QuestConfig.Chains[questId]
    if not root or not data or not chain then return end
    if root.ActiveQuestId ~= "" then
        sendDialogue(player, npcName(chain.NPC), "Finish your current quest before taking another job.", {{Text="CLOSE",Action="Close"}})
        return
    end
    if not chainUnlocked(root, data, chain) then
        local requiredName = chain.RequiredLasso or "a stronger lasso"
        sendDialogue(player, npcName(chain.NPC), "You're not equipped for this job yet. Come back when you own " .. requiredName .. " or better.", {{Text="CLOSE",Action="Close"}})
        return
    end

    local model = npcModels[chain.NPC]
    if model and not near(player, model:GetPivot().Position, 18) then return end

    root.ActiveQuestId = chain.Id
    root.Quests[chain.Id] = {StageIndex = 1, Count = 0}

    if chain.Special == "Hollowfang" then
        destroyPersonal(player)
        spawnBearObjective(player)
    end

    Service:PushState(player)
    sendDialogue(
        player,
        npcName(chain.NPC),
        chain.Special == "Hollowfang"
            and "Good. Take your best beast and head northeast. Follow the quest marker to Hollowfang Cave. Clear the Bears first; Mira cannot get out while they're at the entrance."
            or "It's yours. Check the quest tracker for your first objective.",
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
    local root, data, chain, state, stage = currentChainStage(player)
    local model = npcModels[npcId]
    if not root or not data or not model then return end
    if not near(player, model:GetPivot().Position, 16) then return end

    if chain then
        if chain.NPC ~= npcId then
            sendDialogue(
                player,
                npcName(npcId),
                "You already have an active quest. Finish that job first, then come back and we'll talk.",
                {{Text="CLOSE",Action="Close"}}
            )
            return
        end

        if stage.Type == "CaptureReturn" then
            local count = stageCount(player, state, stage)
            local required = math.max(1, tonumber(stage.Required) or 1)
            if count >= required then
                sendDialogue(
                    player,
                    npcName(npcId),
                    "You have what I asked for. I'll only take eligible animals that are healthy, unfavourited, and not assigned to another role.",
                    {
                        {Text = "HAND OVER " .. tostring(required), Action = "TurnIn:" .. chain.Id},
                        {Text = "KEEP THEM FOR NOW", Action = "Close"},
                    }
                )
            else
                sendDialogue(
                    player,
                    npcName(npcId),
                    "You're making progress. You currently have " .. tostring(count) .. " of " .. tostring(required) .. " eligible " .. tostring(stage.Species or "pets") .. ".",
                    {{Text="CLOSE",Action="Close"}}
                )
            end
            return
        end

        if stage.Type == "InspectPet" then
            local count = stageCount(player, state, stage)
            if count >= math.max(1, tonumber(stage.Required) or 1) then
                sendDialogue(
                    player,
                    npcName(npcId),
                    "Yes — that's exactly the kind of beast I needed to examine. You keep it; I only need a closer look.",
                    {
                        {Text = "SHOW PET", Action = "Inspect:" .. chain.Id},
                        {Text = "NOT YET", Action = "Close"},
                    }
                )
            else
                sendDialogue(player, npcName(npcId), "You don't have a suitable pet for this step yet. Check the quest tracker for the requirement.", {{Text="CLOSE",Action="Close"}})
            end
            return
        end

        if stage.Type == "Talk" then
            if chain.Special == "Hollowfang" and stage.Id == "ReportRowan" then
                sendDialogue(
                    player,
                    npcName(npcId),
                    "Mira is safe? Good. Tell me everything she saw inside Hollowfang.",
                    {
                        {Text = "REPORT MIRA'S FINDINGS", Action = "Talk:" .. chain.Id},
                        {Text = "NOT YET", Action = "Close"},
                    }
                )
            else
                sendDialogue(
                    player,
                    npcName(npcId),
                    "You've finished the field work. Give me your report and we'll close this job properly.",
                    {
                        {Text = "REPORT BACK", Action = "Talk:" .. chain.Id},
                        {Text = "NOT YET", Action = "Close"},
                    }
                )
            end
            return
        end

        sendDialogue(
            player,
            npcName(npcId),
            stage.Objective or "Keep working on the objective in your quest tracker.",
            {{Text="CLOSE",Action="Close"}}
        )
        return
    end

    local available = availableChainsForNPC(root, data, npcId)
    if #available > 0 then
        offerQuest(player, available[1])
        return
    end

    if npcId == "Rowan" and root.Completed.StarterWolves then
        local hollowfang = QuestConfig.Chains.HollowfangRescue
        if not root.Completed.HollowfangRescue then
            local strength = strongestOwnedLasso(data)
            if strength < hollowfang.RequiredStrength then
                sendDialogue(
                    player,
                    npcName(npcId),
                    "Scout Mira is still on my mind. Hollowfang is Rare-pet country, so I won't send you there under-equipped. Come back when you own an Iron Lasso or better.",
                    {{Text="CLOSE",Action="Close"}}
                )
                return
            end
        end
    end

    sendDialogue(player, npcName(npcId), "Nothing urgent for you right now. Keep improving your beasts and equipment; more work will open up as you're ready for it.", {{Text="CLOSE",Action="Close"}})
end

function Service:TalkToMira(player)
    local root, _, chain, state, stage = currentChainStage(player)
    local current = personal[player]
    if not root or not chain or chain.Id ~= "HollowfangRescue" or not current or not current.Mira or not current.Mira.Parent then return end
    if current.Mira:GetAttribute("QuestOwnerUserId") ~= player.UserId then return end
    if not near(player, current.Mira:GetPivot().Position, 16) then return end

    if stage and stage.Id == "FindMira" then
        sendDialogue(
            player,
            "Scout Mira",
            "You actually made it. Listen carefully: those Bears weren't hunting me — they were trying to get away from something deeper inside Hollowfang. I found fresh gouges in the stone, far too large for a Bear, and scales caught between the rocks. I need Rowan to hear this before anyone else goes into those tunnels.",
            {
                {Text = "I'LL REPORT THIS TO ROWAN", Action = "MiraReport"},
                {Text = "NOT YET", Action = "Close"},
            }
        )
    elseif stage and stage.Id == "ReportRowan" then
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

    local root, _, chain, state, stage = currentChainStage(player)
    if not root or not chain or not state or not stage then return end

    local turnInId = action:match("^TurnIn:(.+)$")
    if turnInId then
        if turnInId ~= chain.Id or stage.Type ~= "CaptureReturn" then return end
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

    local inspectId = action:match("^Inspect:(.+)$")
    if inspectId then
        if inspectId ~= chain.Id or stage.Type ~= "InspectPet" then return end
        local model = npcModels[chain.NPC]
        if model and not near(player, model:GetPivot().Position, 16) then return end
        if stageCount(player, state, stage) < math.max(1, tonumber(stage.Required) or 1) then return end
        advanceStage(player, chain, state)
        return
    end

    local talkId = action:match("^Talk:(.+)$")
    if talkId then
        if talkId ~= chain.Id or stage.Type ~= "Talk" then return end
        local model = npcModels[chain.NPC]
        if model and not near(player, model:GetPivot().Position, 16) then return end
        advanceStage(player, chain, state)
        return
    end

    if action == "MiraReport" then
        if chain.Id ~= "HollowfangRescue" or stage.Id ~= "FindMira" then return end
        local current = personal[player]
        if not current or not current.Mira or not current.Mira.Parent or not near(player, current.Mira:GetPivot().Position, 16) then return end
        advanceStage(player, chain, state)
        sendDialogue(
            player,
            "Scout Mira",
            "Tell Rowan exactly this: the Bears were fleeing deeper tunnels, the stone is freshly gouged, and I found scales where no scaled beast should be. I'll follow once I've caught my breath.",
            {{Text="REPORT TO ROWAN",Action="Close"}}
        )
        return
    end
end

function Service:OnMonsterKilled(player, target)
    if not player or not target then return false end

    local root, _, chain, state, stage = currentChainStage(player)
    if not root or not chain or not state or not stage or stage.Type ~= "Kill" then
        return false
    end

    if chain.Special == "Hollowfang" then
        if target:GetAttribute("KillRecorded") then return false end
        if target:GetAttribute("QuestId") ~= chain.Id
            or target:GetAttribute("QuestObjective") ~= "HollowfangBears"
            or tonumber(target:GetAttribute("QuestOwnerUserId")) ~= player.UserId then
            return false
        end
        target:SetAttribute("KillRecorded", true)
    else
        local species = target:GetAttribute("Species")
        local rarity = target:GetAttribute("Rarity")
        if stage.Species and species ~= stage.Species then return false end
        if stage.Rarity and rarity ~= stage.Rarity then return false end
    end

    state.Count = math.min(
        math.max(1, tonumber(stage.Required) or 1),
        state.Count + 1
    )

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
    else
        Service:PushState(player)
    end
    return true
end

function Service:IsQuestMonsterAllowed(player, target)
    local owner = target and tonumber(target:GetAttribute("QuestOwnerUserId"))
    return owner == nil or owner == player.UserId
end

function Service:PlayerReady(player)
    local root = questData(player)
    if not root then return end

    destroyPersonal(player)
    local _, _, chain, _, stage = currentChainStage(player)
    if chain and chain.Id == "HollowfangRescue" and stage then
        if stage.Id == "Bears" then
            spawnBearObjective(player)
        elseif stage.Id == "FindMira" or stage.Id == "ReportRowan" then
            createMira(player, true)
        end
    end

    task.defer(function()
        if player.Parent then Service:PushState(player) end
    end)
end

function Service:PlayerRemoving(player)
    destroyPersonal(player)
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

local function buildNPCs()
    for _, npcId in ipairs(QuestConfig.NPCOrder) do
        local spec = QuestConfig.World.NPCs[npcId]
        if spec then
            makeNPC(questWorld, npcId, spec)
        end
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
    buildNPCs()

    QuestRemote.OnServerEvent:Connect(function(player, action, value)
        if action == "RequestState" then
            Service:PushState(player)
        elseif action == "Action" and type(value) == "string" then
            Service:HandleAction(player, value)
        end
    end)
end

return Service
