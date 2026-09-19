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
local rowan
local caveModel
local caveEntrance
local caveInner
local personal = {}

local STAGE_NOT_STARTED = "NotStarted"
local STAGE_WOLVES = "WolfReturn"
local STAGE_BEARS = "BearRescue"
local STAGE_BEAR_CLEARED = "BearCleared"
local STAGE_COMPLETE = "Complete"

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
    subLabel.Text = subtitle or ""
    subLabel.Parent = gui
end

local function makeNPC(parent, name, position, shirtColor, accentColor)
    local model = Instance.new("Model")
    model.Name = name

    local root = makePart(
        model,
        "HumanoidRootPart",
        Vector3.new(2.2, 3.0, 1.3),
        CFrame.new(position + Vector3.new(0, 2.7, 0)),
        shirtColor,
        Enum.Material.SmoothPlastic
    )
    root.CanCollide = false
    root.Transparency = 1

    local torso = makePart(
        model,
        "Torso",
        Vector3.new(2.2, 3.0, 1.2),
        CFrame.new(position + Vector3.new(0, 2.8, 0)),
        shirtColor,
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

    local armLeft = makePart(model, "LeftArm", Vector3.new(.65, 2.6, .65), CFrame.new(position + Vector3.new(-1.45, 2.9, 0)), accentColor, Enum.Material.Fabric)
    local armRight = makePart(model, "RightArm", Vector3.new(.65, 2.6, .65), CFrame.new(position + Vector3.new(1.45, 2.9, 0)), accentColor, Enum.Material.Fabric)
    armLeft.CanCollide = false
    armRight.CanCollide = false

    model.PrimaryPart = root
    model.Parent = parent
    return model, torso
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

local function ensureProgress(player)
    local data = DataService:Get(player)
    if not data then return nil end

    data.QuestProgress = type(data.QuestProgress) == "table" and data.QuestProgress or {}
    local progress = data.QuestProgress[QuestConfig.Chain.Id]
    if type(progress) ~= "table" then
        progress = {
            Stage = STAGE_NOT_STARTED,
            BearsKilled = 0,
        }
        data.QuestProgress[QuestConfig.Chain.Id] = progress
    end

    local valid = {
        [STAGE_NOT_STARTED] = true,
        [STAGE_WOLVES] = true,
        [STAGE_BEARS] = true,
        [STAGE_BEAR_CLEARED] = true,
        [STAGE_COMPLETE] = true,
    }
    if not valid[progress.Stage] then progress.Stage = STAGE_NOT_STARTED end
    progress.BearsKilled = math.clamp(
        math.floor(tonumber(progress.BearsKilled) or 0),
        0,
        QuestConfig.Chain.BearQuest.Required
    )

    return progress
end

local function availableWolfPets(player)
    local data = DataService:Get(player)
    if not data then return {} end

    local result = {}
    for _, pet in ipairs(PetService:GetPets(player)) do
        if pet.Species == QuestConfig.Chain.WolfQuest.Species
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

local function removeWolfTurnIn(player, count)
    local data = DataService:Get(player)
    if not data then return false end

    local eligible = availableWolfPets(player)
    if #eligible < count then return false end

    local chosen = {}
    for index = 1, count do
        chosen[eligible[index].Id] = true
    end

    for index = #data.Pets, 1, -1 do
        local pet = data.Pets[index]
        if chosen[pet.Id] then
            table.remove(data.Pets, index)
        end
    end

    local refresh = script.Parent.Parent.Systems:FindFirstChild("PetDisplayRefresh")
    if refresh and refresh:IsA("BindableEvent") then
        refresh:Fire(player)
    end
    return true
end

local function sendDialogue(player, npcName, text, actionText, action)
    QuestRemote:FireClient(player, "Dialogue", {
        NPC = npcName,
        Text = text,
        ActionText = actionText,
        Action = action,
    })
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

local function questBearLabel(model, player)
    local root = model.PrimaryPart
    if not root then return end

    local gui = Instance.new("BillboardGui")
    gui.Name = "QuestBearLabel"
    gui.Size = UDim2.fromOffset(210, 32)
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
    model:SetAttribute("QuestId", QuestConfig.Chain.Id)
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

    local position = outside and caveEntrance + Vector3.new(0, 0, 7)
        or caveInner

    local model, torso = makeNPC(
        questWorld,
        "ScoutMira_" .. tostring(player.UserId),
        position,
        Color3.fromRGB(82, 104, 83),
        Color3.fromRGB(136, 162, 112)
    )
    model:SetAttribute("QuestOwnerUserId", player.UserId)
    model:SetAttribute("QuestNPC", "Scout Mira")

    billboard(
        torso,
        "Scout Mira",
        outside and "RESCUED SCOUT" or "TRAPPED SCOUT",
        Color3.fromRGB(170, 228, 160)
    )

    local prompt = addPrompt(torso, "Scout Mira")
    prompt.Enabled = outside
    prompt.Triggered:Connect(function(triggeringPlayer)
        if triggeringPlayer ~= player then return end
        Service:TalkToMira(player)
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
    local progress = ensureProgress(player)
    if not progress or progress.Stage ~= STAGE_BEARS then return end

    local state = currentPersonal(player)
    for _, bear in ipairs(state.Bears) do
        if bear and bear.Parent then bear:Destroy() end
    end
    state.Bears = {}

    if not state.Mira or not state.Mira.Parent then
        createMira(player, false)
    end

    local remaining = math.max(0, QuestConfig.Chain.BearQuest.Required - progress.BearsKilled)
    local offsets = {
        Vector3.new(-12, 0, 20),
        Vector3.new(0, 0, 27),
        Vector3.new(12, 0, 20),
    }

    for index = 1, remaining do
        local rough = caveEntrance + offsets[index]
        local ground = terrainPoint(rough.X, rough.Z, rough.Y)
        local bear = spawnQuestBear(player, progress.BearsKilled + index, ground)
        if bear then table.insert(state.Bears, bear) end
    end
end

function Service:GetClientState(player)
    local progress = ensureProgress(player)
    if not progress then return nil end

    local chain = QuestConfig.Chain
    if progress.Stage == STAGE_NOT_STARTED then
        return {
            Chain = chain.Name,
            Stage = progress.Stage,
            Active = true,
            Title = "New Quest",
            ObjectiveType = "Talk",
            ObjectiveTypeLabel = QuestConfig.ObjectiveTypes.Talk,
            Objective = "Speak to Warden Rowan in the centre village.",
            Progress = "0 / 1",
            TargetPosition = rowan and rowan:GetPivot().Position or nil,
            TargetLabel = chain.QuestGiver,
        }
    end

    if progress.Stage == STAGE_WOLVES then
        local count = #availableWolfPets(player)
        local required = chain.WolfQuest.Required
        return {
            Chain = chain.Name,
            Stage = progress.Stage,
            Active = true,
            Title = chain.WolfQuest.Title,
            ObjectiveType = chain.WolfQuest.ObjectiveType,
            ObjectiveTypeLabel = QuestConfig.ObjectiveTypes[chain.WolfQuest.ObjectiveType],
            Objective = "Capture and return " .. tostring(required) .. " Wolves to Warden Rowan.",
            Detail = "Only healthy Wolves free in your backpack can be handed over. Favourited/equipped/displayed Wolves stay protected.",
            Progress = tostring(math.min(count, required)) .. " / " .. tostring(required),
            TargetPosition = count >= required and (rowan and rowan:GetPivot().Position or nil) or nil,
            TargetLabel = count >= required and chain.QuestGiver or nil,
            Reward = tostring(chain.WolfQuest.RewardCoins) .. " Coins",
        }
    end

    if progress.Stage == STAGE_BEARS then
        local required = chain.BearQuest.Required
        return {
            Chain = chain.Name,
            Stage = progress.Stage,
            Active = true,
            Title = chain.BearQuest.Title,
            ObjectiveType = chain.BearQuest.ObjectiveType,
            ObjectiveTypeLabel = QuestConfig.ObjectiveTypes[chain.BearQuest.ObjectiveType],
            Objective = "Defeat the " .. tostring(required) .. " Bears outside " .. chain.CaveName .. ".",
            Detail = "Follow the quest diamond on your compass northeast. The orange-labelled quest Bears cannot be captured.",
            Progress = tostring(progress.BearsKilled) .. " / " .. tostring(required),
            TargetPosition = caveEntrance,
            TargetLabel = chain.CaveName,
            Reward = tostring(chain.BearQuest.RewardCoins) .. " Coins",
        }
    end

    if progress.Stage == STAGE_BEAR_CLEARED then
        return {
            Chain = chain.Name,
            Stage = progress.Stage,
            Active = true,
            Title = chain.BearQuest.Title,
            ObjectiveType = "Talk",
            ObjectiveTypeLabel = QuestConfig.ObjectiveTypes.Talk,
            Objective = "Speak to Scout Mira outside " .. chain.CaveName .. ".",
            Detail = "The cave entrance is safe. Mira has come out.",
            Progress = "3 / 3",
            TargetPosition = caveEntrance + Vector3.new(0, 0, 7),
            TargetLabel = chain.RescueNPC,
            Reward = tostring(chain.BearQuest.RewardCoins) .. " Coins",
        }
    end

    return {
        Chain = chain.Name,
        Stage = STAGE_COMPLETE,
        Active = false,
        Completed = true,
        Title = chain.Name,
        ObjectiveType = "Talk",
        ObjectiveTypeLabel = "COMPLETE",
        Objective = chain.BearQuest.Complete,
        Progress = "COMPLETE",
    }
end

function Service:PushState(player)
    local state = self:GetClientState(player)
    if state then QuestRemote:FireClient(player, "State", state) end
end

function Service:TalkToRowan(player)
    local progress = ensureProgress(player)
    if not progress or not rowan then return end
    if not near(player, rowan:GetPivot().Position, 16) then return end

    local chain = QuestConfig.Chain
    if progress.Stage == STAGE_NOT_STARTED then
        sendDialogue(
            player,
            chain.QuestGiver,
            chain.WolfQuest.Intro,
            "ACCEPT QUEST",
            "AcceptWolfQuest"
        )
    elseif progress.Stage == STAGE_WOLVES then
        local count = #availableWolfPets(player)
        if count >= chain.WolfQuest.Required then
            sendDialogue(
                player,
                chain.QuestGiver,
                "You brought all five alive. I'll take the five lowest-level eligible Wolves so any favourites or active companions stay safely yours.",
                "HAND OVER 5 WOLVES",
                "TurnInWolves"
            )
        else
            sendDialogue(
                player,
                chain.QuestGiver,
                chain.WolfQuest.Progress
                    .. "\n\nReady to hand over: "
                    .. tostring(count)
                    .. "/"
                    .. tostring(chain.WolfQuest.Required)
                    .. ".",
                nil,
                nil
            )
        end
    elseif progress.Stage == STAGE_BEARS then
        sendDialogue(player, chain.QuestGiver, chain.BearQuest.Intro, nil, nil)
    elseif progress.Stage == STAGE_BEAR_CLEARED then
        sendDialogue(player, chain.QuestGiver, "The cave is clear? Find Mira at the entrance and make sure she's fit to travel.", nil, nil)
    else
        sendDialogue(player, chain.QuestGiver, "Mira made it back. Hollowfang is quiet for now, but I doubt that is the end of the story.", nil, nil)
    end
end

function Service:TalkToMira(player)
    local progress = ensureProgress(player)
    local state = personal[player]
    if not progress or not state or not state.Mira or not state.Mira.Parent then return end
    if state.Mira:GetAttribute("QuestOwnerUserId") ~= player.UserId then return end
    if not near(player, state.Mira:GetPivot().Position, 16) then return end

    if progress.Stage == STAGE_BEAR_CLEARED then
        sendDialogue(
            player,
            QuestConfig.Chain.RescueNPC,
            QuestConfig.Chain.BearQuest.Rescue,
            "HELP MIRA TO SAFETY",
            "CompleteRescue"
        )
    elseif progress.Stage == STAGE_BEARS then
        sendDialogue(player, QuestConfig.Chain.RescueNPC, "I can't get past them! Clear the Bears outside first!", nil, nil)
    end
end

function Service:HandleAction(player, action)
    local progress = ensureProgress(player)
    if not progress then return end

    local chain = QuestConfig.Chain

    if action == "AcceptWolfQuest" then
        if progress.Stage ~= STAGE_NOT_STARTED or not rowan or not near(player, rowan:GetPivot().Position, 16) then return end
        progress.Stage = STAGE_WOLVES
        self:PushState(player)
        sendDialogue(player, chain.QuestGiver, "Bring them back alive. When you have five available Wolves, the compass will point you back to me.", nil, nil)
        return
    end

    if action == "TurnInWolves" then
        if progress.Stage ~= STAGE_WOLVES or not rowan or not near(player, rowan:GetPivot().Position, 16) then return end
        if not removeWolfTurnIn(player, chain.WolfQuest.Required) then
            sendDialogue(player, chain.QuestGiver, "I still need five available, healthy Wolves. Put away any displayed/equipped ones and unfavourite only the animals you intend to hand over.", nil, nil)
            self:PushState(player)
            return
        end

        local balance = DataService:AddCoins(player, chain.WolfQuest.RewardCoins)
        QuestRemote:FireClient(player, "Reward", {
            Coins = chain.WolfQuest.RewardCoins,
            Balance = balance,
        })
        progress.Stage = STAGE_BEARS
        progress.BearsKilled = 0
        spawnBearObjective(player)
        self:PushState(player)
        sendDialogue(
            player,
            chain.QuestGiver,
            chain.WolfQuest.TurnIn
                .. "\n\n+"
                .. tostring(chain.WolfQuest.RewardCoins)
                .. " Coins.\n\n"
                .. chain.BearQuest.Intro
                .. (balance and ("\n\nCoin balance: " .. tostring(balance)) or ""),
            nil,
            nil
        )
        return
    end

    if action == "CompleteRescue" then
        local state = personal[player]
        if progress.Stage ~= STAGE_BEAR_CLEARED
            or not state
            or not state.Mira
            or not state.Mira.Parent
            or not near(player, state.Mira:GetPivot().Position, 16) then
            return
        end

        local balance = DataService:AddCoins(player, chain.BearQuest.RewardCoins)
        QuestRemote:FireClient(player, "Reward", {
            Coins = chain.BearQuest.RewardCoins,
            Balance = balance,
        })
        progress.Stage = STAGE_COMPLETE
        self:PushState(player)
        sendDialogue(
            player,
            chain.RescueNPC,
            chain.BearQuest.Rescue
                .. "\n\n+"
                .. tostring(chain.BearQuest.RewardCoins)
                .. " Coins."
                .. (balance and ("\nCoin balance: " .. tostring(balance)) or "")
                .. "\n\n"
                .. chain.BearQuest.Complete,
            nil,
            nil
        )

        task.delay(1, function()
            local current = personal[player]
            if current and current.Mira and current.Mira.Parent then current.Mira:Destroy() end
            if current then current.Mira = nil end
        end)
        return
    end
end

function Service:OnMonsterKilled(player, target)
    if not player or not target or target:GetAttribute("KillRecorded") then return false end
    if target:GetAttribute("QuestId") ~= QuestConfig.Chain.Id
        or target:GetAttribute("QuestObjective") ~= "HollowfangBears"
        or tonumber(target:GetAttribute("QuestOwnerUserId")) ~= player.UserId then
        return false
    end

    local progress = ensureProgress(player)
    if not progress or progress.Stage ~= STAGE_BEARS then return false end

    target:SetAttribute("KillRecorded", true)
    progress.BearsKilled = math.min(
        QuestConfig.Chain.BearQuest.Required,
        progress.BearsKilled + 1
    )

    if progress.BearsKilled >= QuestConfig.Chain.BearQuest.Required then
        progress.Stage = STAGE_BEAR_CLEARED
        moveMiraOutside(player)
        QuestRemote:FireClient(player, "Toast", "The last Bear falls. Scout Mira is coming out of Hollowfang Cave!")
    else
        QuestRemote:FireClient(
            player,
            "Toast",
            "Hollowfang Bear defeated  ·  "
                .. tostring(progress.BearsKilled)
                .. "/"
                .. tostring(QuestConfig.Chain.BearQuest.Required)
        )
    end

    self:PushState(player)
    return true
end

function Service:IsQuestMonsterAllowed(player, target)
    local owner = target and tonumber(target:GetAttribute("QuestOwnerUserId"))
    return owner == nil or owner == player.UserId
end

function Service:PlayerReady(player)
    local progress = ensureProgress(player)
    if not progress then return end

    destroyPersonal(player)
    if progress.Stage == STAGE_BEARS then
        spawnBearObjective(player)
    elseif progress.Stage == STAGE_BEAR_CLEARED then
        createMira(player, true)
    end

    task.defer(function()
        if player.Parent then self:PushState(player) end
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

local function buildRowan()
    local settings = QuestConfig.World
    local ground = terrainPoint(settings.RowanXZ.X, settings.RowanXZ.Y, settings.CaveFallbackY)
    local model, torso = makeNPC(
        questWorld,
        "WardenRowan",
        ground,
        Color3.fromRGB(82, 94, 72),
        Color3.fromRGB(137, 119, 76)
    )
    billboard(torso, "Warden Rowan", "QUEST WARDEN", Color3.fromRGB(245, 210, 110))
    local prompt = addPrompt(torso, "Warden Rowan")
    prompt.Triggered:Connect(function(player)
        Service:TalkToRowan(player)
    end)
    rowan = model
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
    buildRowan()

    QuestRemote.OnServerEvent:Connect(function(player, action, value)
        if action == "RequestState" then
            Service:PushState(player)
        elseif action == "Action" and type(value) == "string" then
            Service:HandleAction(player, value)
        end
    end)
end

return Service
