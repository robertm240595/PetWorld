local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Root = ReplicatedStorage:WaitForChild("WildernessPets")
local QuestRemote = Root.Remotes:WaitForChild("Quest")

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
gui.DisplayOrder = 18
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
local trackerHidden = false
local dialogueFrame

------------------------------------------------------------
-- COMPASS
------------------------------------------------------------

local compass = Instance.new("Frame")
compass.Name = "QuestCompass"
compass.AnchorPoint = Vector2.new(.5, 0)
compass.Position = UDim2.new(.5, 0, 0, 8)
compass.Size = UDim2.fromOffset(440, 38)
compass.BackgroundColor3 = palette.bg
compass.BackgroundTransparency = .10
compass.BorderSizePixel = 0
compass.ClipsDescendants = true
compass.Parent = gui
round(compass, 9)
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
        UDim2.fromOffset(0, 4),
        UDim2.fromOffset(34, 20),
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
centerMark.Size = UDim2.fromOffset(2, 28)
centerMark.BackgroundColor3 = palette.gold
centerMark.BackgroundTransparency = .4
centerMark.BorderSizePixel = 0
centerMark.Parent = compass

local questMarker = makeLabel(
    compass,
    "QuestMarker",
    "◆",
    UDim2.fromOffset(0, -2),
    UDim2.fromOffset(26, 24),
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
    UDim2.fromOffset(0, 20),
    UDim2.fromOffset(72, 14),
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
    UDim2.new(.5, -150, 0, 48),
    UDim2.fromOffset(300, 18),
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
-- QUEST TRACKER
------------------------------------------------------------

local tracker = Instance.new("Frame")
tracker.Name = "QuestTracker"
tracker.AnchorPoint = Vector2.new(1, 0)
tracker.Position = UDim2.new(1, -18, 0, 47)
tracker.Size = UDim2.fromOffset(335, 160)
tracker.BackgroundColor3 = palette.bg
tracker.BackgroundTransparency = .05
tracker.BorderSizePixel = 0
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

local typeBadge = makeLabel(
    trackerBody,
    "Type",
    "",
    UDim2.fromOffset(0, 0),
    UDim2.fromOffset(115, 20),
    10,
    palette.gold
)
typeBadge.BackgroundColor3 = Color3.fromRGB(49, 48, 41)
typeBadge.BackgroundTransparency = .1
typeBadge.TextXAlignment = Enum.TextXAlignment.Center
round(typeBadge, 5)

local questTitle = makeLabel(
    trackerBody,
    "Title",
    "",
    UDim2.fromOffset(125, -1),
    UDim2.fromOffset(180, 22),
    13,
    palette.text
)
questTitle.Font = Enum.Font.GothamBold
questTitle.TextXAlignment = Enum.TextXAlignment.Left

local objective = makeLabel(
    trackerBody,
    "Objective",
    "",
    UDim2.fromOffset(0, 28),
    UDim2.fromOffset(310, 42),
    12,
    palette.text
)
objective.TextWrapped = true
objective.TextXAlignment = Enum.TextXAlignment.Left
objective.TextYAlignment = Enum.TextYAlignment.Top

local progress = makeLabel(
    trackerBody,
    "Progress",
    "",
    UDim2.fromOffset(0, 74),
    UDim2.fromOffset(145, 20),
    11,
    palette.green
)
progress.Font = Enum.Font.GothamBold
progress.TextXAlignment = Enum.TextXAlignment.Left

local reward = makeLabel(
    trackerBody,
    "Reward",
    "",
    UDim2.fromOffset(150, 74),
    UDim2.fromOffset(160, 20),
    10,
    palette.gold
)
reward.TextXAlignment = Enum.TextXAlignment.Right

local detail = makeLabel(
    trackerBody,
    "Detail",
    "",
    UDim2.fromOffset(0, 96),
    UDim2.fromOffset(310, 34),
    9,
    palette.muted
)
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
    UDim2.new(.5, -260, 0, 78),
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
        if token == toastToken then
            toast.Visible = false
        end
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
    dialogueFrame.Position = UDim2.new(.5, 0, 1, -116)
    dialogueFrame.Size = UDim2.fromOffset(650, 220)
    dialogueFrame.BackgroundColor3 = palette.bg
    dialogueFrame.BackgroundTransparency = .02
    dialogueFrame.BorderSizePixel = 0
    dialogueFrame.Parent = gui
    round(dialogueFrame, 12)
    stroke(dialogueFrame, .25)

    local npc = makeLabel(
        dialogueFrame,
        "NPC",
        tostring(data.NPC or "Quest"),
        UDim2.fromOffset(20, 14),
        UDim2.fromOffset(500, 28),
        20,
        palette.gold
    )
    npc.Font = Enum.Font.GothamBold
    npc.TextXAlignment = Enum.TextXAlignment.Left

    local body = makeLabel(
        dialogueFrame,
        "Body",
        tostring(data.Text or ""),
        UDim2.fromOffset(20, 50),
        UDim2.fromOffset(610, 105),
        13,
        palette.text
    )
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

    if type(data.Action) == "string" and data.Action ~= "" then
        local action = Instance.new("TextButton")
        action.Name = "QuestAction"
        action.AnchorPoint = Vector2.new(1, 1)
        action.Position = UDim2.new(1, -20, 1, -16)
        action.Size = UDim2.fromOffset(215, 42)
        action.BackgroundColor3 = Color3.fromRGB(82, 72, 47)
        action.BorderSizePixel = 0
        action.Text = tostring(data.ActionText or "CONTINUE")
        action.TextColor3 = palette.text
        action.Font = Enum.Font.GothamBold
        action.TextSize = 12
        action.Parent = dialogueFrame
        round(action, 8)
        stroke(action, .28)

        local actionName = data.Action
        action.Activated:Connect(function()
            action.Active = false
            action.AutoButtonColor = false
            QuestRemote:FireServer("Action", actionName)
            closeDialogue()
        end)
    end
end

------------------------------------------------------------
-- STATE
------------------------------------------------------------

local function applyState(state)
    if type(state) ~= "table" then return end
    currentState = state

    questTitle.Text = tostring(state.Title or state.Chain or "Quest")
    objective.Text = tostring(state.Objective or "")
    progress.Text = tostring(state.Progress or "")
    reward.Text = state.Reward and ("Reward: " .. tostring(state.Reward)) or ""
    typeBadge.Text = tostring(state.ObjectiveTypeLabel or state.ObjectiveType or "QUEST")
    detail.Text = tostring(state.Detail or "")

    if state.Completed then
        typeBadge.Text = "COMPLETE"
        typeBadge.TextColor3 = palette.green
        progress.TextColor3 = palette.green
    else
        typeBadge.TextColor3 = palette.gold
        progress.TextColor3 = palette.green
    end
end

QuestRemote.OnClientEvent:Connect(function(action, value)
    if action == "State" then
        applyState(value)
    elseif action == "Dialogue" then
        showDialogue(value)
    elseif action == "Toast" then
        showToast(value)
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
            entry.Label.Position = UDim2.fromOffset(center + diff * pixelsPerDegree, 5)
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
                questMarker.Position = UDim2.fromOffset(x, -2)
                questDistance.Position = UDim2.fromOffset(x, 20)
                questDistance.Text = tostring(math.floor(horizontal.Magnitude + .5)) .. " studs"
            end
        else
            questMarker.Visible = true
            questDistance.Visible = true
            questMarker.Position = UDim2.fromOffset(220, -2)
            questDistance.Position = UDim2.fromOffset(220, 20)
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
