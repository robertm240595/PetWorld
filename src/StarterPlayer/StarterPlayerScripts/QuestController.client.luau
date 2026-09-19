local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Root = ReplicatedStorage:WaitForChild("WildernessPets")
local QuestRemote = Root.Remotes:WaitForChild("Quest")
local world = workspace:WaitForChild("WildernessPets")

local palette = {
    bg = Color3.fromRGB(22,27,31),
    panel = Color3.fromRGB(37,44,47),
    gold = Color3.fromRGB(180,151,90),
    text = Color3.fromRGB(242,232,206),
    muted = Color3.fromRGB(152,163,164),
    green = Color3.fromRGB(133,205,146),
}

local gui = Instance.new("ScreenGui")
gui.Name = "QuestHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 100
gui.Parent = playerGui

local function round(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = parent
end

local function stroke(parent, transparency)
    local s = Instance.new("UIStroke")
    s.Color = palette.gold
    s.Transparency = transparency or .35
    s.Thickness = 1
    s.Parent = parent
end

local function makeLabel(parent, name, textValue, position, size, textSize, color)
    local label = Instance.new("TextLabel")
    label.Name = name
    label.Text = textValue or ""
    label.Position = position
    label.Size = size
    label.BackgroundTransparency = 1
    label.TextColor3 = color or palette.text
    label.Font = Enum.Font.GothamMedium
    label.TextSize = textSize or 13
    label.Parent = parent
    return label
end

local currentState
local currentNpcState = {}
local trackerHidden = false
local dialogueFrame

------------------------------------------------------------
-- COMPASS: absolute top-centre, above all quest/target UI
------------------------------------------------------------

local compass = Instance.new("Frame")
compass.Name = "QuestCompass"
compass.AnchorPoint = Vector2.new(.5, 0)
compass.Position = UDim2.new(.5, 0, 0, 2)
compass.Size = UDim2.fromOffset(440, 36)
compass.BackgroundColor3 = palette.bg
compass.BackgroundTransparency = .08
compass.BorderSizePixel = 0
compass.ClipsDescendants = true
compass.Parent = gui
round(compass, 8)
stroke(compass, .48)

local compassStrip = Instance.new("Frame")
compassStrip.Name = "Strip"
compassStrip.Position = UDim2.fromOffset(12, 0)
compassStrip.Size = UDim2.new(1, -24, 1, 0)
compassStrip.BackgroundTransparency = 1
compassStrip.ClipsDescendants = true
compassStrip.Parent = compass

local cardinals = {}
for name, bearing in pairs({N=0,E=90,S=180,W=270}) do
    local label = makeLabel(
        compassStrip,
        name,
        name,
        UDim2.fromOffset(0, 3),
        UDim2.fromOffset(34, 19),
        13,
        name == "N" and palette.gold or palette.text
    )
    label.AnchorPoint = Vector2.new(.5, 0)
    label.Font = Enum.Font.GothamBold
    label.TextXAlignment = Enum.TextXAlignment.Center
    cardinals[name] = {Label=label, Bearing=bearing}
end

local centerMark = Instance.new("Frame")
centerMark.Name = "FacingMark"
centerMark.AnchorPoint = Vector2.new(.5, 0)
centerMark.Position = UDim2.new(.5, 0, 0, 2)
centerMark.Size = UDim2.fromOffset(2, 27)
centerMark.BackgroundColor3 = palette.gold
centerMark.BackgroundTransparency = .4
centerMark.BorderSizePixel = 0
centerMark.Parent = compass

local questMarker = makeLabel(
    compass,
    "QuestMarker",
    "◆",
    UDim2.fromOffset(0, -3),
    UDim2.fromOffset(26, 23),
    18,
    Color3.fromRGB(255, 207, 91)
)
questMarker.AnchorPoint = Vector2.new(.5, 0)
questMarker.Font = Enum.Font.GothamBold
questMarker.TextXAlignment = Enum.TextXAlignment.Center
questMarker.Visible = false

local questDistance = makeLabel(
    compass,
    "QuestDistance",
    "",
    UDim2.fromOffset(0, 19),
    UDim2.fromOffset(72, 13),
    9,
    palette.muted
)
questDistance.AnchorPoint = Vector2.new(.5, 0)
questDistance.TextXAlignment = Enum.TextXAlignment.Center
questDistance.Visible = false

local compassTargetName = makeLabel(
    gui,
    "CompassTargetName",
    "",
    UDim2.new(.5, -150, 0, 39),
    UDim2.fromOffset(300, 16),
    10,
    palette.muted
)
compassTargetName.TextXAlignment = Enum.TextXAlignment.Center

local function angleDelta(target, current)
    return ((target - current + 540) % 360) - 180
end

local function cameraHeading()
    local camera = workspace.CurrentCamera
    if not camera then return 0 end
    local look = camera.CFrame.LookVector
    local heading = math.deg(math.atan2(look.X, -look.Z))
    if heading < 0 then heading += 360 end
    return heading
end

------------------------------------------------------------
-- QUEST TRACKER: right side below stats/target areas
------------------------------------------------------------

local tracker = Instance.new("Frame")
tracker.Name = "QuestTracker"
tracker.AnchorPoint = Vector2.new(1, 0)
tracker.Position = UDim2.new(1, -18, 0, 190)
tracker.Size = UDim2.fromOffset(335, 160)
tracker.BackgroundColor3 = palette.bg
tracker.BackgroundTransparency = .05
tracker.BorderSizePixel = 0
tracker.Visible = false
tracker.Parent = gui
round(tracker, 10)
stroke(tracker, .45)

local trackerHeader = makeLabel(
    tracker,
    "Header",
    "QUEST TRACKER",
    UDim2.fromOffset(13, 7),
    UDim2.fromOffset(265, 22),
    12,
    palette.gold
)
trackerHeader.Font = Enum.Font.GothamBold
trackerHeader.TextXAlignment = Enum.TextXAlignment.Left

local hideButton = Instance.new("TextButton")
hideButton.Name = "HideQuest"
hideButton.Position = UDim2.new(1, -36, 0, 5)
hideButton.Size = UDim2.fromOffset(30, 25)
hideButton.BackgroundColor3 = palette.panel
hideButton.BorderSizePixel = 0
hideButton.Text = "–"
hideButton.TextColor3 = palette.text
hideButton.Font = Enum.Font.GothamBold
hideButton.TextSize = 18
hideButton.Parent = tracker
round(hideButton, 6)

local trackerBody = Instance.new("Frame")
trackerBody.Name = "Body"
trackerBody.Position = UDim2.fromOffset(10, 34)
trackerBody.Size = UDim2.new(1, -20, 1, -42)
trackerBody.BackgroundTransparency = 1
trackerBody.Parent = tracker

local typeBadge = makeLabel(trackerBody,"Type","",UDim2.fromOffset(0,0),UDim2.fromOffset(115,20),10,palette.gold)
typeBadge.BackgroundColor3 = Color3.fromRGB(49,48,41)
typeBadge.BackgroundTransparency = .1
typeBadge.TextXAlignment = Enum.TextXAlignment.Center
round(typeBadge, 5)

local questTitle = makeLabel(trackerBody,"Title","",UDim2.fromOffset(125,-1),UDim2.fromOffset(180,22),13,palette.text)
questTitle.Font = Enum.Font.GothamBold
questTitle.TextXAlignment = Enum.TextXAlignment.Left

local objective = makeLabel(trackerBody,"Objective","",UDim2.fromOffset(0,28),UDim2.fromOffset(310,42),12,palette.text)
objective.TextWrapped = true
objective.TextXAlignment = Enum.TextXAlignment.Left
objective.TextYAlignment = Enum.TextYAlignment.Top

local progress = makeLabel(trackerBody,"Progress","",UDim2.fromOffset(0,74),UDim2.fromOffset(145,20),11,palette.green)
progress.Font = Enum.Font.GothamBold
progress.TextXAlignment = Enum.TextXAlignment.Left

local reward = makeLabel(trackerBody,"Reward","",UDim2.fromOffset(150,74),UDim2.fromOffset(160,20),10,palette.gold)
reward.TextXAlignment = Enum.TextXAlignment.Right

local detail = makeLabel(trackerBody,"Detail","",UDim2.fromOffset(0,96),UDim2.fromOffset(310,34),9,palette.muted)
detail.TextWrapped = true
detail.TextXAlignment = Enum.TextXAlignment.Left
detail.TextYAlignment = Enum.TextYAlignment.Top

hideButton.Activated:Connect(function()
    trackerHidden = not trackerHidden
    trackerBody.Visible = not trackerHidden
    tracker.Size = trackerHidden and UDim2.fromOffset(150, 34) or UDim2.fromOffset(335, 160)
    trackerHeader.Text = trackerHidden and "QUEST" or "QUEST TRACKER"
    trackerHeader.Size = trackerHidden and UDim2.fromOffset(95, 22) or UDim2.fromOffset(265, 22)
    hideButton.Text = trackerHidden and "+" or "–"
end)

------------------------------------------------------------
-- TOASTS / DIALOGUE
------------------------------------------------------------

local toast = makeLabel(
    gui,
    "QuestToast",
    "",
    UDim2.new(.5, -260, 0, 184),
    UDim2.fromOffset(520, 38),
    13,
    palette.text
)
toast.BackgroundColor3 = palette.bg
toast.BackgroundTransparency = .08
toast.TextWrapped = true
toast.Visible = false
round(toast, 8)
stroke(toast, .55)

local toastToken = 0
local function showToast(message)
    toastToken += 1
    local token = toastToken
    toast.Text = tostring(message or "")
    toast.Visible = true
    task.delay(4.5, function()
        if token == toastToken then toast.Visible = false end
    end)
end

local function closeDialogue()
    if dialogueFrame then
        dialogueFrame:Destroy()
        dialogueFrame = nil
    end
end

local function showDialogue(data)
    closeDialogue()
    if type(data) ~= "table" then return end

    dialogueFrame = Instance.new("Frame")
    dialogueFrame.Name = "QuestDialogue"
    dialogueFrame.AnchorPoint = Vector2.new(.5, 1)
    dialogueFrame.Position = UDim2.new(.5, 0, 1, -110)
    dialogueFrame.Size = UDim2.fromOffset(700, 250)
    dialogueFrame.BackgroundColor3 = palette.bg
    dialogueFrame.BackgroundTransparency = .02
    dialogueFrame.BorderSizePixel = 0
    dialogueFrame.Parent = gui
    round(dialogueFrame, 12)
    stroke(dialogueFrame, .25)

    local fit = Instance.new("UIScale")
    local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280,720)
    fit.Scale = math.min(1, (viewport.X-30)/700, (viewport.Y-80)/600)
    fit.Parent = dialogueFrame

    local npc = makeLabel(dialogueFrame,"NPC",tostring(data.NPC or "Quest"),UDim2.fromOffset(20,14),UDim2.fromOffset(590,28),20,palette.gold)
    npc.Font = Enum.Font.GothamBold
    npc.TextXAlignment = Enum.TextXAlignment.Left

    local body = makeLabel(dialogueFrame,"Body",tostring(data.Text or ""),UDim2.fromOffset(20,52),UDim2.fromOffset(660,118),13,palette.text)
    body.TextWrapped = true
    body.TextXAlignment = Enum.TextXAlignment.Left
    body.TextYAlignment = Enum.TextYAlignment.Top

    local close = Instance.new("TextButton")
    close.Name = "Close"
    close.Position = UDim2.new(1, -45, 0, 11)
    close.Size = UDim2.fromOffset(32, 30)
    close.BackgroundColor3 = palette.panel
    close.BorderSizePixel = 0
    close.Text = "×"
    close.TextColor3 = palette.text
    close.Font = Enum.Font.GothamBold
    close.TextSize = 20
    close.Parent = dialogueFrame
    round(close, 7)
    close.Activated:Connect(closeDialogue)

    local options = type(data.Options) == "table" and data.Options or {}
    local visibleOptions = {}
    for _, option in ipairs(options) do
        if type(option) == "table" and type(option.Text) == "string" then
            table.insert(visibleOptions, option)
        end
    end

    local totalWidth = math.min(660, #visibleOptions * 230 + math.max(0,#visibleOptions-1)*10)
    local startX = (700-totalWidth)/2
    for index, option in ipairs(visibleOptions) do
        local width = #visibleOptions <= 2 and math.floor((totalWidth - math.max(0,#visibleOptions-1)*10)/math.max(1,#visibleOptions)) or 210
        local action = Instance.new("TextButton")
        action.Name = "QuestOption" .. tostring(index)
        action.Position = UDim2.fromOffset(startX + (index-1)*(width+10), 188)
        action.Size = UDim2.fromOffset(width, 44)
        action.BackgroundColor3 = index == 1 and Color3.fromRGB(82,72,47) or palette.panel
        action.BorderSizePixel = 0
        action.Text = option.Text
        action.TextColor3 = palette.text
        action.Font = Enum.Font.GothamBold
        action.TextSize = 11
        action.TextWrapped = true
        action.Parent = dialogueFrame
        round(action, 8)
        stroke(action, .35)

        local actionName = option.Action
        action.Activated:Connect(function()
            if actionName == "Close" or not actionName then
                closeDialogue()
                return
            end
            for _, sibling in ipairs(dialogueFrame and dialogueFrame:GetChildren() or {}) do
                if sibling:IsA("GuiButton") then sibling.Active = false end
            end
            QuestRemote:FireServer("Action", actionName)
            closeDialogue()
        end)
    end
end

------------------------------------------------------------
-- LOCAL NPC VISIBILITY + QUEST MARKERS
------------------------------------------------------------

local function ensureMarker(model, symbol)
    local marker = model:FindFirstChild("LocalQuestMarker", true)
    if marker and not marker:IsA("BillboardGui") then marker:Destroy() marker=nil end

    if not marker then
        local part = model:FindFirstChild("Head") or model:FindFirstChild("Torso") or model.PrimaryPart
        if not part or not part:IsA("BasePart") then return end

        marker = Instance.new("BillboardGui")
        marker.Name = "LocalQuestMarker"
        marker.Size = UDim2.fromOffset(46, 46)
        marker.StudsOffsetWorldSpace = Vector3.new(0, 5.4, 0)
        marker.AlwaysOnTop = true
        marker.MaxDistance = 100
        marker.Parent = part

        local text = Instance.new("TextLabel")
        text.Name = "Symbol"
        text.BackgroundTransparency = 1
        text.Size = UDim2.fromScale(1,1)
        text.Font = Enum.Font.GothamBlack
        text.TextSize = 34
        text.TextStrokeTransparency = .15
        text.TextColor3 = Color3.fromRGB(255,207,91)
        text.Parent = marker
    end

    local text = marker:FindFirstChild("Symbol")
    if text then
        text.Text = symbol or ""
        text.TextColor3 = symbol == "?" and Color3.fromRGB(143,215,255) or Color3.fromRGB(255,207,91)
    end
    marker.Enabled = symbol ~= nil and symbol ~= ""
end

local function setLocalModelVisible(model, visible)
    for _, item in ipairs(model:GetDescendants()) do
        if item:IsA("BasePart") then
            if item.Name ~= "HumanoidRootPart" then
                item.LocalTransparencyModifier = visible and 0 or 1
            end
        elseif item:IsA("BillboardGui") and item.Name == "QuestNPCLabel" then
            item.Enabled = visible
        elseif item:IsA("ProximityPrompt") then
            item.Enabled = visible
        end
    end
end

local function applyNpcState(npcs, miraMarker)
    currentNpcState = type(npcs) == "table" and npcs or {}
    local questWorld = world:FindFirstChild("QuestWorld")
    if not questWorld then return end

    for _, model in ipairs(questWorld:GetChildren()) do
        if model:IsA("Model") then
            local npcId = model:GetAttribute("QuestNpcId")
            if npcId then
                local info = currentNpcState[npcId] or {}
                local visible = info.Visible == true
                setLocalModelVisible(model, visible)
                ensureMarker(model, visible and info.Marker or nil)
            elseif model:GetAttribute("QuestMira") then
                local owner = tonumber(model:GetAttribute("QuestOwnerUserId"))
                local visible = owner == player.UserId
                setLocalModelVisible(model, visible)
                ensureMarker(model, visible and miraMarker and "?" or nil)
            end
        end
    end
end

------------------------------------------------------------
-- STATE
------------------------------------------------------------

local function applyTracker(state)
    currentState = state
    if type(state) ~= "table" then
        tracker.Visible = false
        questMarker.Visible = false
        questDistance.Visible = false
        compassTargetName.Text = ""
        return
    end

    tracker.Visible = true
    trackerBody.Visible = not trackerHidden
    tracker.Size = trackerHidden and UDim2.fromOffset(150,34) or UDim2.fromOffset(335,160)
    trackerHeader.Text = trackerHidden and "QUEST" or "QUEST TRACKER"
    trackerHeader.Size = trackerHidden and UDim2.fromOffset(95,22) or UDim2.fromOffset(265,22)
    hideButton.Text = trackerHidden and "+" or "–"

    questTitle.Text = tostring(state.Title or state.Chain or "Quest")
    objective.Text = tostring(state.Objective or "")
    progress.Text = tostring(state.Progress or "")
    reward.Text = state.Reward and state.Reward ~= "" and ("Reward: " .. tostring(state.Reward)) or ""
    typeBadge.Text = tostring(state.ObjectiveTypeLabel or state.ObjectiveType or "QUEST")
    detail.Text = tostring(state.Detail or "")
end

QuestRemote.OnClientEvent:Connect(function(action, value)
    if action == "State" and type(value) == "table" then
        applyTracker(value.Tracker)
        applyNpcState(value.NPCs, value.MiraMarker == true)
    elseif action == "Dialogue" then
        showDialogue(value)
    elseif action == "Toast" then
        showToast(value)
    elseif action == "Reward" and type(value) == "table" then
        local parts = {}
        if (tonumber(value.Coins) or 0) > 0 then table.insert(parts, "+" .. tostring(value.Coins) .. " Coins") end
        if (tonumber(value.Gems) or 0) > 0 then table.insert(parts, "+" .. tostring(value.Gems) .. " Gems") end
        local message = table.concat(parts, "  ·  ")
        if value.CoinBalance ~= nil then message ..= "  ·  Coins " .. tostring(value.CoinBalance) end
        if value.GemBalance ~= nil then message ..= "  ·  Gems " .. tostring(value.GemBalance) end
        showToast(message)
    end
end)

------------------------------------------------------------
-- LIVE COMPASS + STATE REFRESH
------------------------------------------------------------

RunService.RenderStepped:Connect(function()
    gui.Enabled = player:GetAttribute("VillageReady") == true
    if not gui.Enabled then return end

    local heading = cameraHeading()
    local width = compassStrip.AbsoluteSize.X
    if width <= 0 then width = 416 end
    local center = width * .5
    local pixelsPerDegree = width / 190

    for _, entry in pairs(cardinals) do
        local diff = angleDelta(entry.Bearing, heading)
        entry.Label.Visible = math.abs(diff) <= 100
        if entry.Label.Visible then
            entry.Label.Position = UDim2.fromOffset(center + diff * pixelsPerDegree, 4)
        end
    end

    local target = currentState and currentState.TargetPosition
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if typeof(target) == "Vector3" and root then
        local delta = target - root.Position
        local horizontal = Vector3.new(delta.X, 0, delta.Z)
        if horizontal.Magnitude > 1 then
            local bearing = math.deg(math.atan2(horizontal.X, -horizontal.Z))
            if bearing < 0 then bearing += 360 end
            local diff = angleDelta(bearing, heading)
            local visible = math.abs(diff) <= 78
            questMarker.Visible = visible
            questDistance.Visible = visible
            compassTargetName.Text = visible and tostring(currentState.TargetLabel or "Quest Objective") or ""
            if visible then
                local x = 220 + diff * (195 / 78)
                questMarker.Position = UDim2.fromOffset(x, -3)
                questDistance.Position = UDim2.fromOffset(x, 19)
                questDistance.Text = tostring(math.floor(horizontal.Magnitude + .5)) .. " studs"
            end
        else
            questMarker.Visible = true
            questDistance.Visible = true
            questMarker.Position = UDim2.fromOffset(220, -3)
            questDistance.Position = UDim2.fromOffset(220, 19)
            questDistance.Text = "HERE"
            compassTargetName.Text = tostring(currentState.TargetLabel or "Quest Objective")
        end
    else
        questMarker.Visible = false
        questDistance.Visible = false
        compassTargetName.Text = ""
    end
end)

task.spawn(function()
    while gui.Parent do
        if player:GetAttribute("VillageReady") == true then
            QuestRemote:FireServer("RequestState")
        end
        task.wait(1)
    end
end)

player:GetAttributeChangedSignal("VillageReady"):Connect(function()
    if player:GetAttribute("VillageReady") == true then
        task.defer(function()
            QuestRemote:FireServer("RequestState")
        end)
    else
        closeDialogue()
    end
end)

local questWorld = world:WaitForChild("QuestWorld")
questWorld.ChildAdded:Connect(function()
    task.defer(function()
        applyNpcState(currentNpcState, currentState and currentState.Stage == "FindMira")
    end)
end)
