local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Root = ReplicatedStorage:WaitForChild("WildernessPets")
local QuestRemote = Root.Remotes:WaitForChild("Quest")
local world = workspace:WaitForChild("WildernessPets")
local wild = world:WaitForChild("WildMonsters")

local palette = {
    bg = Color3.fromRGB(22,27,31),
    panel = Color3.fromRGB(37,44,47),
    panel2 = Color3.fromRGB(47,54,57),
    gold = Color3.fromRGB(180,151,90),
    text = Color3.fromRGB(242,232,206),
    muted = Color3.fromRGB(152,163,164),
    green = Color3.fromRGB(133,205,146),
    blue = Color3.fromRGB(143,215,255),
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

local function stroke(parent, transparency, color)
    local s = Instance.new("UIStroke")
    s.Color = color or palette.gold
    s.Transparency = transparency or .35
    s.Thickness = 1
    s.Parent = parent
    return s
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

local currentTrackers = {}
local currentNpcState = {}
local focusedQuestId
local expanded = {}
local trackerHidden = false
local dialogueFrame

------------------------------------------------------------
-- COMPASS
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

local function focusedTracker()
    for _, tracker in ipairs(currentTrackers) do
        if tracker.QuestId == focusedQuestId then
            return tracker
        end
    end
    return currentTrackers[1]
end

------------------------------------------------------------
-- COLLAPSIBLE QUEST LIST
------------------------------------------------------------

local trackerFrame = Instance.new("Frame")
trackerFrame.Name = "QuestTracker"
trackerFrame.AnchorPoint = Vector2.new(1, 0)
trackerFrame.Position = UDim2.new(1, -18, 0, 190)
trackerFrame.Size = UDim2.fromOffset(355, 390)
trackerFrame.BackgroundColor3 = palette.bg
trackerFrame.BackgroundTransparency = .04
trackerFrame.BorderSizePixel = 0
trackerFrame.Visible = false
trackerFrame.Parent = gui
round(trackerFrame, 10)
stroke(trackerFrame, .43)

local trackerHeader = makeLabel(
    trackerFrame,
    "Header",
    "QUESTS",
    UDim2.fromOffset(13, 7),
    UDim2.fromOffset(290, 22),
    12,
    palette.gold
)
trackerHeader.Font = Enum.Font.GothamBold
trackerHeader.TextXAlignment = Enum.TextXAlignment.Left

local hideButton = Instance.new("TextButton")
hideButton.Name = "HideQuests"
hideButton.Position = UDim2.new(1, -36, 0, 5)
hideButton.Size = UDim2.fromOffset(30, 25)
hideButton.BackgroundColor3 = palette.panel
hideButton.BorderSizePixel = 0
hideButton.Text = "–"
hideButton.TextColor3 = palette.text
hideButton.Font = Enum.Font.GothamBold
hideButton.TextSize = 18
hideButton.Parent = trackerFrame
round(hideButton, 6)

local questList = Instance.new("ScrollingFrame")
questList.Name = "QuestList"
questList.Position = UDim2.fromOffset(10, 36)
questList.Size = UDim2.new(1, -20, 1, -46)
questList.BackgroundTransparency = 1
questList.BorderSizePixel = 0
questList.ScrollBarThickness = 4
questList.AutomaticCanvasSize = Enum.AutomaticSize.Y
questList.CanvasSize = UDim2.new()
questList.Parent = trackerFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 7)
listLayout.Parent = questList

local function rebuildQuestList()
    for _, child in ipairs(questList:GetChildren()) do
        if child ~= listLayout then child:Destroy() end
    end

    trackerFrame.Visible = #currentTrackers > 0
    trackerHeader.Text = "QUESTS  ·  " .. tostring(#currentTrackers)
    if #currentTrackers == 0 then
        questMarker.Visible = false
        questDistance.Visible = false
        compassTargetName.Text = ""
        return
    end

    local focusStillExists = false
    for _, tracker in ipairs(currentTrackers) do
        if tracker.QuestId == focusedQuestId then
            focusStillExists = true
            break
        end
    end
    if not focusStillExists then
        focusedQuestId = currentTrackers[1].QuestId
    end

    if trackerHidden then
        questList.Visible = false
        trackerFrame.Size = UDim2.fromOffset(150, 34)
        trackerHeader.Text = "QUESTS  ·  " .. tostring(#currentTrackers)
        trackerHeader.Size = UDim2.fromOffset(105, 22)
        hideButton.Text = "+"
        return
    end

    questList.Visible = true
    trackerFrame.Size = UDim2.fromOffset(355, 390)
    trackerHeader.Size = UDim2.fromOffset(290, 22)
    hideButton.Text = "–"

    for index, tracker in ipairs(currentTrackers) do
        local questId = tostring(tracker.QuestId or ("Quest" .. tostring(index)))
        if expanded[questId] == nil then
            expanded[questId] = index == 1
        end

        local isOpen = expanded[questId] == true
        local isFocused = focusedQuestId == questId
        local row = Instance.new("Frame")
        row.Name = "Quest_" .. questId
        row.Size = UDim2.fromOffset(331, isOpen and 158 or 44)
        row.BackgroundColor3 = isFocused and Color3.fromRGB(47, 53, 50) or palette.panel
        row.BorderSizePixel = 0
        row.Parent = questList
        round(row, 8)
        stroke(row, isFocused and .20 or .72, isFocused and palette.gold or palette.muted)

        local head = Instance.new("TextButton")
        head.Name = "QuestHeader"
        head.Size = UDim2.new(1, 0, 0, 44)
        head.BackgroundTransparency = 1
        head.BorderSizePixel = 0
        head.Text = (isOpen and "▼  " or "▶  ") .. tostring(tracker.Title or tracker.Chain or "Quest")
        head.TextColor3 = isFocused and palette.gold or palette.text
        head.Font = Enum.Font.GothamBold
        head.TextSize = 12
        head.TextXAlignment = Enum.TextXAlignment.Left
        head.Parent = row

        local pad = Instance.new("UIPadding")
        pad.PaddingLeft = UDim.new(0, 10)
        pad.PaddingRight = UDim.new(0, 70)
        pad.Parent = head

        local prog = makeLabel(
            row,
            "HeaderProgress",
            tostring(tracker.Progress or ""),
            UDim2.new(1, -82, 0, 11),
            UDim2.fromOffset(70, 20),
            10,
            palette.green
        )
        prog.TextXAlignment = Enum.TextXAlignment.Right
        prog.Font = Enum.Font.GothamBold

        head.Activated:Connect(function()
            focusedQuestId = questId
            expanded[questId] = not isOpen
            rebuildQuestList()
        end)

        if isOpen then
            local badge = makeLabel(
                row,
                "Type",
                tostring(tracker.ObjectiveTypeLabel or tracker.ObjectiveType or "QUEST"),
                UDim2.fromOffset(10, 49),
                UDim2.fromOffset(125, 20),
                9,
                palette.gold
            )
            badge.BackgroundColor3 = Color3.fromRGB(52, 50, 40)
            badge.BackgroundTransparency = .1
            badge.TextXAlignment = Enum.TextXAlignment.Center
            round(badge, 5)

            local rewardText = tracker.Reward and tracker.Reward ~= ""
                and ("Reward: " .. tostring(tracker.Reward))
                or ""
            local reward = makeLabel(
                row,
                "Reward",
                rewardText,
                UDim2.fromOffset(145, 50),
                UDim2.fromOffset(175, 18),
                9,
                palette.gold
            )
            reward.TextXAlignment = Enum.TextXAlignment.Right

            local objective = makeLabel(
                row,
                "Objective",
                tostring(tracker.Objective or ""),
                UDim2.fromOffset(10, 76),
                UDim2.fromOffset(311, 39),
                11,
                palette.text
            )
            objective.TextWrapped = true
            objective.TextXAlignment = Enum.TextXAlignment.Left
            objective.TextYAlignment = Enum.TextYAlignment.Top

            local detail = makeLabel(
                row,
                "Detail",
                tostring(tracker.Detail or ""),
                UDim2.fromOffset(10, 119),
                UDim2.fromOffset(311, 31),
                9,
                palette.muted
            )
            detail.TextWrapped = true
            detail.TextXAlignment = Enum.TextXAlignment.Left
            detail.TextYAlignment = Enum.TextYAlignment.Top
        end
    end
end

hideButton.Activated:Connect(function()
    trackerHidden = not trackerHidden
    rebuildQuestList()
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
        local width = #visibleOptions <= 2
            and math.floor((totalWidth - math.max(0,#visibleOptions-1)*10)/math.max(1,#visibleOptions))
            or 210
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
            QuestRemote:FireServer("Action", actionName)
            closeDialogue()
        end)
    end
end

------------------------------------------------------------
-- NPC / PERSONAL QUEST VISIBILITY
------------------------------------------------------------

local function ensureMarker(model, symbol)
    local marker = model:FindFirstChild("LocalQuestMarker", true)
    if marker and not marker:IsA("BillboardGui") then
        marker:Destroy()
        marker = nil
    end

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

        local markerText = Instance.new("TextLabel")
        markerText.Name = "Symbol"
        markerText.BackgroundTransparency = 1
        markerText.Size = UDim2.fromScale(1,1)
        markerText.Font = Enum.Font.GothamBlack
        markerText.TextSize = 34
        markerText.TextStrokeTransparency = .15
        markerText.Parent = marker
    end

    local markerText = marker:FindFirstChild("Symbol")
    if markerText then
        markerText.Text = symbol or ""
        markerText.TextColor3 = symbol == "?" and palette.blue or Color3.fromRGB(255,207,91)
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

local function trackerStage(questId, stageId)
    for _, tracker in ipairs(currentTrackers) do
        if tracker.QuestId == questId and (not stageId or tracker.Stage == stageId) then
            return tracker
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
                local miraTalkable = visible and (
                    trackerStage("HollowfangRescue","FindMira")
                    or trackerStage("HollowfangRescue","ReportRowan")
                )
                for _, item in ipairs(model:GetDescendants()) do
                    if item:IsA("ProximityPrompt") then
                        item.Enabled = miraTalkable ~= nil
                    end
                end
                ensureMarker(model, visible and miraMarker and "?" or nil)
            end
        end
    end
end

local function configureOwnedQuestMonster(model)
    if not model:IsA("Model") or model:GetAttribute("QuestTutorialSpar") ~= true then return end
    local visible = tonumber(model:GetAttribute("QuestOwnerUserId")) == player.UserId
    for _, item in ipairs(model:GetDescendants()) do
        if item:IsA("BasePart") then
            item.LocalTransparencyModifier = visible and 0 or 1
        elseif item:IsA("BillboardGui") then
            item.Enabled = visible
        end
    end
end

for _, model in ipairs(wild:GetChildren()) do
    configureOwnedQuestMonster(model)
end
wild.ChildAdded:Connect(function(model)
    task.defer(function()
        configureOwnedQuestMonster(model)
    end)
end)

------------------------------------------------------------
-- REMOTE STATE
------------------------------------------------------------

QuestRemote.OnClientEvent:Connect(function(action, value)
    if action == "State" and type(value) == "table" then
        currentTrackers = type(value.Trackers) == "table" and value.Trackers or {}
        rebuildQuestList()
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
-- LIVE COMPASS
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

    local tracker = focusedTracker()
    local target = tracker and tracker.TargetPosition
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
            compassTargetName.Text = visible and tostring(tracker.TargetLabel or "Quest Objective") or ""
            if visible then
                local x = 220 + diff * (195 / 78)
                questMarker.Position = UDim2.fromOffset(x, -3)
                questDistance.Position = UDim2.fromOffset(x, 19)
                local metres = math.max(1, math.floor(horizontal.Magnitude / 5 + .5))
                questDistance.Text = tostring(metres) .. " m"
            end
        else
            questMarker.Visible = true
            questDistance.Visible = true
            questMarker.Position = UDim2.fromOffset(220, -3)
            questDistance.Position = UDim2.fromOffset(220, 19)
            questDistance.Text = "HERE"
            compassTargetName.Text = tostring(tracker.TargetLabel or "Quest Objective")
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
        applyNpcState(currentNpcState, trackerStage("HollowfangRescue","FindMira") ~= nil)
    end)
end)
