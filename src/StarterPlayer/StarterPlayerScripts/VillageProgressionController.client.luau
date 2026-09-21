local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local Root = ReplicatedStorage:WaitForChild("WildernessPets")
local Remotes = Root:WaitForChild("Remotes")
local Remote = Remotes:WaitForChild("VillageProgression")

local gui = Instance.new("ScreenGui")
gui.Name = "VillageProgressionUI"
gui.ResetOnSpawn = false
gui.Enabled = true
gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
gui.DisplayOrder = 128
gui.Parent = player:WaitForChild("PlayerGui")

local colors = {
    bg = Color3.fromRGB(28, 33, 38),
    panel = Color3.fromRGB(40, 47, 53),
    button = Color3.fromRGB(67, 79, 83),
    gold = Color3.fromRGB(225, 188, 104),
    text = Color3.fromRGB(240, 238, 226),
    muted = Color3.fromRGB(178, 184, 183),
    green = Color3.fromRGB(101, 190, 119),
}

local panel
local modalPanels = {
    ProgressionUI = "ProgressionPanel",
    VillageProgressionUI = "VillagePanel",
    AuctionHouseUI = "AuctionPanel",
}

local function activeCustomModal()
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then return false end
    for guiName, panelName in pairs(modalPanels) do
        local screen = playerGui:FindFirstChild(guiName)
        local frame = screen and screen:FindFirstChild(panelName)
        if frame and frame.Parent then return true end
    end
    return false
end

local function beginModal()
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then return false end
    local main = playerGui:FindFirstChild("WildernessPetsUI")
    if main and main:GetAttribute("InventoryOpen") == true and not activeCustomModal() then
        return false
    end
    for guiName, panelName in pairs(modalPanels) do
        if guiName ~= gui.Name then
            local screen = playerGui:FindFirstChild(guiName)
            local other = screen and screen:FindFirstChild(panelName)
            if other then other:Destroy() end
        end
    end
    if main then main:SetAttribute("InventoryOpen", true) end
    return true
end

local function endModal()
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui or activeCustomModal() then return end
    local main = playerGui:FindFirstChild("WildernessPetsUI")
    if main then main:SetAttribute("InventoryOpen", false) end
end

local currentState
local currentTab = "Upgrades"

local function round(obj, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = obj
end

local function stroke(obj)
    local s = Instance.new("UIStroke")
    s.Color = Color3.fromRGB(118, 101, 69)
    s.Transparency = 0.35
    s.Parent = obj
end

local function label(parent, textValue, pos, size, textSize)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Position = pos
    l.Size = size
    l.Text = textValue
    l.TextColor3 = colors.text
    l.Font = Enum.Font.Gotham
    l.TextSize = textSize or 13
    l.TextWrapped = true
    l.Parent = parent
    return l
end

local function button(parent, textValue, pos, size)
    local b = Instance.new("TextButton")
    b.Position = pos
    b.Size = size
    b.BackgroundColor3 = colors.button
    b.BorderSizePixel = 0
    b.Text = textValue
    b.TextColor3 = colors.text
    b.Font = Enum.Font.GothamBold
    b.TextSize = 12
    b.Parent = parent
    round(b, 7)
    stroke(b)
    return b
end

local function close()
    local wasOpen = panel ~= nil and panel.Parent ~= nil
    if panel then panel:Destroy(); panel = nil end
    if wasOpen then endModal() end
end

local function secondsText(seconds)
    seconds = math.max(0, math.floor(tonumber(seconds) or 0))
    if seconds >= 60 then
        return tostring(math.floor(seconds / 60)) .. " min"
    end
    return tostring(seconds) .. " sec"
end

local render

local function basePanel()
    close()
    if not beginModal() then return false end
    panel = Instance.new("Frame")
    panel.Name = "VillagePanel"
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.Position = UDim2.fromScale(0.5, 0.5)
    panel.Size = UDim2.fromOffset(760, 540)
    panel.BackgroundColor3 = colors.bg
    panel.BorderSizePixel = 0
    panel.Parent = gui
    round(panel, 12)
    stroke(panel)

    local scale = Instance.new("UIScale")
    local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280,720)
    scale.Scale = math.min(1, (vp.X - 24) / 760, (vp.Y - 40) / 540)
    scale.Parent = panel

    local title = label(panel, "VILLAGE DEVELOPMENT", UDim2.fromOffset(22, 14), UDim2.fromOffset(600, 32), 22)
    title.Font = Enum.Font.GothamBold
    title.TextColor3 = colors.gold
    title.TextXAlignment = Enum.TextXAlignment.Left
    local x = button(panel, "×", UDim2.fromOffset(704, 12), UDim2.fromOffset(38, 34))
    x.TextSize = 22
    x.Activated:Connect(close)

    for i, tab in ipairs({"Upgrades", "Training"}) do
        local b = button(panel, string.upper(tab), UDim2.fromOffset(22 + (i-1)*150, 58), UDim2.fromOffset(140, 38))
        b.BackgroundColor3 = currentTab == tab and Color3.fromRGB(92, 78, 52) or colors.button
        b.Activated:Connect(function()
            currentTab = tab
            render()
        end)
    end
    return true
end

local function upgradeCard(parent, y, name, detail, level, maxLevel, cost, action)
    local card = Instance.new("Frame")
    card.Position = UDim2.fromOffset(22, y)
    card.Size = UDim2.fromOffset(716, 145)
    card.BackgroundColor3 = colors.panel
    card.BorderSizePixel = 0
    card.Parent = parent
    round(card, 9)

    local title = label(card, name .. "  ·  LEVEL " .. tostring(level) .. "/" .. tostring(maxLevel), UDim2.fromOffset(16, 12), UDim2.fromOffset(480, 26), 16)
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    local desc = label(card, detail, UDim2.fromOffset(16, 44), UDim2.fromOffset(500, 70), 12)
    desc.TextColor3 = colors.muted
    desc.TextXAlignment = Enum.TextXAlignment.Left
    desc.TextYAlignment = Enum.TextYAlignment.Top

    local text = cost and ("UPGRADE\n" .. tostring(cost) .. " COINS") or "MAX LEVEL"
    local b = button(card, text, UDim2.new(1, -176, 0, 40), UDim2.fromOffset(155, 56))
    b.TextWrapped = true
    if cost then
        b.Activated:Connect(function() Remote:FireServer(action) end)
    else
        b.Active = false
        b.BackgroundTransparency = 0.45
    end
end

local function renderUpgrades()
    local s = currentState or {}
    upgradeCard(
        panel, 112, "HEALING BARN",
        "Improves how quickly defeated pets recover. Current recovery speed: " .. string.format("%.2fx", tonumber(s.HealingSpeed) or 1) .. ".",
        s.HealingLevel or 1, 5, s.HealingUpgradeCoins, "UpgradeHealing"
    )
    upgradeCard(
        panel, 275, "PET TRAINING AREA",
        "Passively grants " .. tostring(s.TrainingXP or 1) .. " XP every " .. secondsText(s.TrainingInterval or 900) .. " to each assigned pet while you are in-game.",
        s.TrainingLevel or 1, 5, s.TrainingUpgradeCoins, "UpgradeTraining"
    )
    local slotText = "Training slots: " .. tostring(s.TrainingSlots or 1) .. "/" .. tostring(s.MaxTrainingSlots or 5)
    local info = label(panel, slotText, UDim2.fromOffset(28, 445), UDim2.fromOffset(360, 30), 14)
    info.Font = Enum.Font.GothamBold
    info.TextXAlignment = Enum.TextXAlignment.Left
    local cost = s.NextSlotGemCost
    local slotButton = button(panel, cost and ("UNLOCK SLOT  ·  " .. tostring(cost) .. " GEMS") or "SLOTS MAXED", UDim2.fromOffset(470, 438), UDim2.fromOffset(260, 42))
    if cost then
        slotButton.Activated:Connect(function() Remote:FireServer("BuyTrainingSlot") end)
    else
        slotButton.Active = false
        slotButton.BackgroundTransparency = 0.45
    end
end

local function renderTraining()
    local s = currentState or {}
    local summary = label(
        panel,
        tostring(s.TrainingSlots or 1) .. " slots  ·  +" .. tostring(s.TrainingXP or 1) .. " XP every " .. secondsText(s.TrainingInterval or 900),
        UDim2.fromOffset(24, 108), UDim2.fromOffset(700, 28), 13
    )
    summary.TextColor3 = colors.gold
    summary.TextXAlignment = Enum.TextXAlignment.Left

    local list = Instance.new("ScrollingFrame")
    list.Position = UDim2.fromOffset(22, 145)
    list.Size = UDim2.fromOffset(716, 370)
    list.BackgroundTransparency = 1
    list.BorderSizePixel = 0
    list.ScrollBarThickness = 5
    list.AutomaticCanvasSize = Enum.AutomaticSize.Y
    list.CanvasSize = UDim2.new()
    list.Parent = panel
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 7)
    layout.Parent = list

    for _, pet in ipairs(s.Pets or {}) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -8, 0, 58)
        row.BackgroundColor3 = pet.Assigned and Color3.fromRGB(45, 75, 54) or colors.panel
        row.BorderSizePixel = 0
        row.Parent = list
        round(row, 7)
        local name = label(row, tostring(pet.Name) .. "  ·  " .. tostring(pet.Species) .. "  ·  Lv." .. tostring(pet.Level), UDim2.fromOffset(14, 8), UDim2.fromOffset(480, 22), 13)
        name.Font = Enum.Font.GothamBold
        name.TextXAlignment = Enum.TextXAlignment.Left
        local status = label(row, pet.Dead and "Unavailable · healing required" or (pet.Assigned and "Training" or "Available"), UDim2.fromOffset(14, 31), UDim2.fromOffset(430, 18), 10)
        status.TextColor3 = pet.Assigned and colors.green or colors.muted
        status.TextXAlignment = Enum.TextXAlignment.Left
        local action = button(row, pet.Assigned and "REMOVE" or "TRAIN", UDim2.new(1, -125, 0, 13), UDim2.fromOffset(108, 32))
        if pet.Dead then
            action.Active = false
            action.BackgroundTransparency = 0.5
        else
            action.Activated:Connect(function()
                Remote:FireServer(pet.Assigned and "Remove" or "Assign", pet.Id)
            end)
        end
    end
end

render = function()
    if not currentState then return end
    if not basePanel() then return end
    if currentTab == "Training" then renderTraining() else renderUpgrades() end
end

Remote.OnClientEvent:Connect(function(action, a, b, c)
    if action == "Open" then
        currentState = a
        currentTab = b or "Upgrades"
        render()
    elseif action == "Result" then
        local ok, message, state = a, b, c
        if type(state) == "table" then currentState = state end
        if panel then render() end
        if message and message ~= "" then
            local toast = label(gui, tostring(message), UDim2.new(0.5, -220, 0, 110), UDim2.fromOffset(440, 38), 12)
            toast.Name = "VillageToast"
            toast.BackgroundTransparency = 0.05
            toast.BackgroundColor3 = ok and Color3.fromRGB(47,76,55) or Color3.fromRGB(91,50,48)
            toast.Font = Enum.Font.GothamBold
            round(toast, 7)
            task.delay(4, function() if toast.Parent then toast:Destroy() end end)
        end
    elseif action == "TrainingTick" then
        currentState = c or currentState
        if panel and currentTab == "Training" then render() end
    end
end)
