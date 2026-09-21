local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local Root = ReplicatedStorage:WaitForChild("WildernessPets")
local Remotes = Root:WaitForChild("Remotes")
local GetState = Remotes:WaitForChild("GetState")
local PetsRemote = Remotes:WaitForChild("Pets")
local AchievementRemote = Remotes:WaitForChild("Achievement")
local MasteryConfig = require(Root.Shared.MasteryConfig)

local palette = {
    bg = Color3.fromRGB(27, 31, 36),
    panel = Color3.fromRGB(38, 44, 51),
    panel2 = Color3.fromRGB(49, 57, 65),
    gold = Color3.fromRGB(224, 188, 105),
    text = Color3.fromRGB(239, 237, 225),
    muted = Color3.fromRGB(177, 183, 184),
    green = Color3.fromRGB(101, 190, 119),
}

local gui = Instance.new("ScreenGui")
gui.Name = "ProgressionUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
gui.DisplayOrder = 126
gui.Parent = player:WaitForChild("PlayerGui")

local function round(obj, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = obj
end

local function stroke(obj, transparency)
    local s = Instance.new("UIStroke")
    s.Color = Color3.fromRGB(110, 96, 68)
    s.Transparency = transparency or 0.35
    s.Thickness = 1
    s.Parent = obj
end

local function label(parent, textValue, size, position, textSize)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Size = size
    l.Position = position
    l.Text = textValue
    l.TextColor3 = palette.text
    l.Font = Enum.Font.Gotham
    l.TextSize = textSize or 14
    l.TextWrapped = true
    l.Parent = parent
    return l
end

local function button(parent, textValue, size, position)
    local b = Instance.new("TextButton")
    b.Size = size
    b.Position = position
    b.BackgroundColor3 = palette.panel2
    b.BorderSizePixel = 0
    b.Text = textValue
    b.TextColor3 = palette.text
    b.Font = Enum.Font.GothamBold
    b.TextSize = 12
    b.Parent = parent
    round(b, 7)
    stroke(b, 0.45)
    return b
end

local achievementsButton = button(gui, "ACHIEVEMENTS", UDim2.fromOffset(112, 34), UDim2.fromOffset(12, 116))
local masteryButton = button(gui, "PET MASTERY", UDim2.fromOffset(112, 34), UDim2.fromOffset(12, 156))

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

local latestState
local selectedPetId

local function close()
    local wasOpen = panel ~= nil and panel.Parent ~= nil
    if panel then panel:Destroy(); panel = nil end
    if wasOpen then endModal() end
end

local function refreshState()
    local ok, result = pcall(function() return GetState:InvokeServer() end)
    if ok and type(result) == "table" then latestState = result end
    return latestState
end

local function makePanel(title)
    close()
    if not beginModal() then return nil end
    panel = Instance.new("Frame")
    panel.Name = "ProgressionPanel"
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.Position = UDim2.fromScale(0.5, 0.5)
    panel.Size = UDim2.fromOffset(760, 540)
    panel.BackgroundColor3 = palette.bg
    panel.BorderSizePixel = 0
    panel.Parent = gui
    round(panel, 12)
    stroke(panel, 0.2)
    local scale = Instance.new("UIScale")
    local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280,720)
    scale.Scale = math.min(1, (viewport.X - 24) / 760, (viewport.Y - 40) / 540)
    scale.Parent = panel
    local titleLabel = label(panel, title, UDim2.fromOffset(650, 36), UDim2.fromOffset(22, 14), 22)
    titleLabel.TextColor3 = palette.gold
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    local x = button(panel, "×", UDim2.fromOffset(38, 34), UDim2.fromOffset(704, 12))
    x.TextSize = 22
    x.Activated:Connect(close)
    return panel
end

local function scrolling(parent, pos, size)
    local f = Instance.new("ScrollingFrame")
    f.Position = pos
    f.Size = size
    f.BackgroundTransparency = 1
    f.BorderSizePixel = 0
    f.ScrollBarThickness = 5
    f.AutomaticCanvasSize = Enum.AutomaticSize.Y
    f.CanvasSize = UDim2.new()
    f.Parent = parent
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 7)
    layout.Parent = f
    return f
end

local function openAchievements()
    local state = refreshState()
    local p = makePanel("ACHIEVEMENTS")
    if not p then return end
    local info = label(p, "Complete milestones across capturing, quests, collection, arena and mastery to earn Gems.", UDim2.fromOffset(700, 36), UDim2.fromOffset(24, 54), 13)
    info.TextColor3 = palette.muted
    info.TextXAlignment = Enum.TextXAlignment.Left
    local list = scrolling(p, UDim2.fromOffset(22, 96), UDim2.fromOffset(716, 420))
    for _, achievement in ipairs(state and state.Achievements or {}) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -8, 0, 68)
        row.BackgroundColor3 = achievement.Completed and Color3.fromRGB(44, 72, 52) or palette.panel
        row.BorderSizePixel = 0
        row.Parent = list
        round(row, 8)
        local title = label(row, (achievement.Completed and "✓  " or "○  ") .. tostring(achievement.Name), UDim2.fromOffset(490, 24), UDim2.fromOffset(14, 8), 14)
        title.Font = Enum.Font.GothamBold
        title.TextXAlignment = Enum.TextXAlignment.Left
        local desc = label(row, tostring(achievement.Description), UDim2.fromOffset(530, 28), UDim2.fromOffset(14, 32), 11)
        desc.TextColor3 = palette.muted
        desc.TextXAlignment = Enum.TextXAlignment.Left
        local reward = label(row, "+" .. tostring(achievement.Gems or 0) .. " GEMS", UDim2.fromOffset(135, 30), UDim2.new(1, -150, 0, 18), 12)
        reward.TextColor3 = palette.gold
        reward.Font = Enum.Font.GothamBold
    end
end

local function openMastery()
    local state = refreshState()
    local p = makePanel("PET MASTERY & AURAS")
    if not p then return end
    local hint = label(p, "Pet levels unlock cosmetic auras. Auras do not change combat stats.", UDim2.fromOffset(700, 30), UDim2.fromOffset(24, 54), 13)
    hint.TextColor3 = palette.muted
    hint.TextXAlignment = Enum.TextXAlignment.Left

    local petList = scrolling(p, UDim2.fromOffset(22, 92), UDim2.fromOffset(300, 420))
    local auraList = scrolling(p, UDim2.fromOffset(340, 92), UDim2.fromOffset(398, 420))

    local function renderAuras(pet)
        for _, child in ipairs(auraList:GetChildren()) do
            if child:IsA("GuiObject") then child:Destroy() end
        end
        if not pet then
            local empty = label(auraList, "Select a pet to view its unlocked auras.", UDim2.new(1, -10, 0, 60), UDim2.new(), 13)
            empty.TextColor3 = palette.muted
            return
        end
        local heading = label(auraList, tostring(pet.Name) .. "  ·  Lv." .. tostring(pet.Level), UDim2.new(1, -10, 0, 34), UDim2.new(), 15)
        heading.Font = Enum.Font.GothamBold
        heading.TextColor3 = palette.gold
        for _, aura in ipairs(MasteryConfig.Auras) do
            local unlocked = (tonumber(pet.Level) or 1) >= aura.RequiredLevel
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, -8, 0, 54)
            row.BackgroundColor3 = unlocked and palette.panel or Color3.fromRGB(31,34,38)
            row.BorderSizePixel = 0
            row.Parent = auraList
            round(row, 7)
            local name = label(row, aura.Name, UDim2.fromOffset(210, 24), UDim2.fromOffset(12, 6), 13)
            name.TextXAlignment = Enum.TextXAlignment.Left
            local req = label(row, unlocked and ("Unlocked · Lv." .. aura.RequiredLevel) or ("Unlocks at Lv." .. aura.RequiredLevel), UDim2.fromOffset(210, 20), UDim2.fromOffset(12, 28), 10)
            req.TextColor3 = unlocked and palette.green or palette.muted
            req.TextXAlignment = Enum.TextXAlignment.Left
            local use = button(row, pet.SelectedAura == aura.Id and "EQUIPPED" or "USE", UDim2.fromOffset(105, 32), UDim2.new(1, -116, 0, 11))
            use.Active = unlocked
            use.AutoButtonColor = unlocked
            use.BackgroundTransparency = unlocked and 0 or 0.55
            if unlocked then
                use.Activated:Connect(function()
                    PetsRemote:FireServer("SetAura", pet.Id, aura.Id)
                end)
            end
        end
    end

    for _, pet in ipairs(state and state.Pets or {}) do
        local b = button(petList, tostring(pet.Name) .. "  ·  Lv." .. tostring(pet.Level), UDim2.new(1, -8, 0, 46), UDim2.new())
        b.TextXAlignment = Enum.TextXAlignment.Left
        b.Activated:Connect(function()
            selectedPetId = pet.Id
            renderAuras(pet)
        end)
        if not selectedPetId then selectedPetId = pet.Id end
    end
    local selected
    for _, pet in ipairs(state and state.Pets or {}) do if pet.Id == selectedPetId then selected = pet break end end
    renderAuras(selected)
end

achievementsButton.Activated:Connect(openAchievements)
masteryButton.Activated:Connect(openMastery)

PetsRemote.OnClientEvent:Connect(function(action)
    if action == "Updated" and panel and panel.Parent and panel:FindFirstChildWhichIsA("UIScale") then
        task.defer(function()
            if selectedPetId then openMastery() end
        end)
    end
end)

AchievementRemote.OnClientEvent:Connect(function(action, data)
    if action ~= "Unlocked" or type(data) ~= "table" then return end
    local toast = label(gui, "ACHIEVEMENT UNLOCKED  ·  " .. tostring(data.Name) .. "  ·  +" .. tostring(data.Gems or 0) .. " Gems", UDim2.fromOffset(520, 42), UDim2.new(0.5, -260, 0, 118), 13)
    toast.Name = "AchievementToast"
    toast.BackgroundTransparency = 0.08
    toast.BackgroundColor3 = palette.panel
    toast.Font = Enum.Font.GothamBold
    toast.TextColor3 = palette.gold
    round(toast, 8)
    stroke(toast, 0.25)
    task.delay(5, function() if toast.Parent then toast:Destroy() end end)
end)
