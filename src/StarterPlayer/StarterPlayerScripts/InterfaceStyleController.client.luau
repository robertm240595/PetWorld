local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local theme = {
    ink = Color3.fromRGB(4, 10, 18),
    panel = Color3.fromRGB(20, 31, 43),
    panel2 = Color3.fromRGB(29, 45, 61),
    accent = Color3.fromRGB(239, 190, 82),
    cyan = Color3.fromRGB(108, 210, 231),
    text = Color3.fromRGB(242, 247, 251),
    muted = Color3.fromRGB(157, 175, 191),
}

local function isQuestObject(object)
    local current = object
    while current and current ~= playerGui do
        if current.Name == "QuestHUD" then
            return true
        end
        current = current.Parent
    end
    return false
end

local function lowerName(object)
    return string.lower(object.Name or "")
end

local function isMeter(object)
    local name = lowerName(object)
    return string.find(name, "fill", 1, true)
        or string.find(name, "health", 1, true)
        or string.find(name, "progress", 1, true)
        or string.find(name, "cooldown", 1, true)
        or string.find(name, "bar", 1, true)
end

local function ensureCorner(object, radius)
    if not object:FindFirstChildOfClass("UICorner") then
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, radius or 8)
        corner.Parent = object
    end
end

local function ensureStroke(object, color, transparency)
    local stroke = object:FindFirstChild("UIThemeStroke")
    if not stroke then
        stroke = Instance.new("UIStroke")
        stroke.Name = "UIThemeStroke"
        stroke.Thickness = 1
        stroke.Parent = object
    end
    stroke.Color = color or theme.accent
    stroke.Transparency = transparency or .62
end

local function style(object)
    if not object:IsA("GuiObject") or isQuestObject(object) then
        return
    end

    local name = lowerName(object)
    if object:IsA("TextButton") then
        object.BackgroundColor3 = theme.panel2
        object.BackgroundTransparency = .08
        object.BorderSizePixel = 0
        object.AutoButtonColor = false
        object.TextColor3 = theme.text
        object.TextStrokeColor3 = theme.ink
        object.TextStrokeTransparency = .42
        object.Font = Enum.Font.GothamBold
        ensureCorner(object, 8)
        ensureStroke(object, theme.accent, .58)
    elseif object:IsA("ImageButton") then
        object.BackgroundColor3 = theme.panel2
        object.BackgroundTransparency = .08
        object.BorderSizePixel = 0
        object.AutoButtonColor = false
        ensureCorner(object, 8)
        ensureStroke(object, theme.accent, .58)
    elseif object:IsA("TextLabel") then
        local subdued = string.find(name, "detail", 1, true)
            or string.find(name, "subtitle", 1, true)
            or string.find(name, "description", 1, true)
            or string.find(name, "hint", 1, true)
            or string.find(name, "note", 1, true)
            or string.find(name, "meta", 1, true)
        local highlighted = string.find(name, "title", 1, true)
            or string.find(name, "header", 1, true)
            or string.find(name, "reward", 1, true)
        object.TextColor3 = highlighted and theme.accent or (subdued and theme.muted or theme.text)
        object.TextStrokeColor3 = theme.ink
        object.TextStrokeTransparency = .42
        if object.Font == Enum.Font.SourceSans or object.Font == Enum.Font.SourceSansBold then
            object.Font = Enum.Font.GothamMedium
        end
    elseif object:IsA("Frame") or object:IsA("ScrollingFrame") then
        if object.BackgroundTransparency < .99 and not isMeter(object) then
            object.BackgroundColor3 = theme.panel
            object.BackgroundTransparency = math.max(object.BackgroundTransparency, .12)
            object.BorderSizePixel = 0
            ensureCorner(object, 10)
            ensureStroke(object, theme.cyan, .76)
        end
        if object:IsA("ScrollingFrame") then
            object.ScrollBarThickness = math.min(object.ScrollBarThickness, 4)
            object.ScrollBarImageColor3 = theme.accent
            object.ScrollBarImageTransparency = .45
        end
    end
end

local function bindRoot(root)
    if not root:IsA("ScreenGui") or root.Name == "QuestHUD" then
        return
    end
    for _, object in ipairs(root:GetDescendants()) do
        style(object)
    end
    root.DescendantAdded:Connect(function(object)
        task.defer(style, object)
    end)
end

for _, root in ipairs(playerGui:GetChildren()) do
    bindRoot(root)
end

playerGui.ChildAdded:Connect(function(root)
    task.defer(bindRoot, root)
end)

local function applySafeZones()
    local boss = playerGui:FindFirstChild("BossEncounterHUD")
    local panel = boss and boss:FindFirstChild("BossPanel", true)
    if panel then
        panel.Position = UDim2.new(.5, 0, 0, 48)
    end
    local compass = playerGui:FindFirstChild("QuestHUD")
    local questCompass = compass and compass:FindFirstChild("QuestCompass")
    if questCompass then
        questCompass.Position = UDim2.new(.5, 0, 0, 0)
        questCompass.Size = UDim2.fromOffset(440, 30)
        local tracker = compass and compass:FindFirstChild("QuestTracker")
        if tracker then tracker.Position = UDim2.new(1, -18, 0, 190) end
    end
end

task.defer(applySafeZones)
playerGui.ChildAdded:Connect(function()
    task.defer(applySafeZones)
end)