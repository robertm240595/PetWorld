local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Theme = require(ReplicatedStorage:WaitForChild("WildernessPets"):WaitForChild("Shared"):WaitForChild("UITheme"))
local C = Theme.Colors

local excluded = {QuestHUD=true}
local function inExcluded(object)
    local current=object
    while current and current~=playerGui do
        if excluded[current.Name] then return true end
        current=current.Parent
    end
    return false
end
local function lower(object) return string.lower(object.Name or "") end
local function meter(object)
    local n=lower(object)
    return n:find("fill",1,true) or n:find("health",1,true) or n:find("progress",1,true) or n:find("cooldown",1,true)
end

local function style(object)
    if not object:IsA("GuiObject") or inExcluded(object) or object:GetAttribute("KeepVisualStyle") then return end
    local n=lower(object)
    if object:IsA("TextButton") then
        Theme.Button(object, object:GetAttribute("Selected")==true)
        object.TextStrokeColor3=C.LeatherDark
        object.TextStrokeTransparency=.45
    elseif object:IsA("ImageButton") then
        object.BorderSizePixel=0
        object.BackgroundColor3=C.Leather
        object.BackgroundTransparency=.04
        Theme.Corner(object,7); Theme.Stroke(object,C.GoldDark,1,.08)
    elseif object:IsA("TextLabel") then
        local heading=n:find("title",1,true) or n:find("header",1,true)
        local muted=n:find("detail",1,true) or n:find("subtitle",1,true) or n:find("description",1,true) or n:find("hint",1,true)
        object.TextColor3=heading and C.Gold or (muted and C.ParchmentDark or object.TextColor3)
        object.TextStrokeColor3=C.LeatherDark
        object.TextStrokeTransparency=.48
        if object.Font==Enum.Font.SourceSans or object.Font==Enum.Font.SourceSansBold then object.Font=Enum.Font.GothamMedium end
    elseif object:IsA("Frame") or object:IsA("ScrollingFrame") then
        if object.BackgroundTransparency<.99 and not meter(object) then
            object.BorderSizePixel=0
            if n:find("panel",1,true) or n:find("backpack",1,true) or n:find("collection",1,true) or n:find("shop",1,true) then
                object.BackgroundColor3=C.Parchment
                object.BackgroundTransparency=.02
                Theme.Corner(object,10); Theme.Stroke(object,C.GoldDark,2,.08)
            else
                object.BackgroundColor3=C.Inset
                object.BackgroundTransparency=math.max(object.BackgroundTransparency,.05)
                Theme.Corner(object,8); Theme.Stroke(object,C.GoldDark,1,.35)
            end
        end
        if object:IsA("ScrollingFrame") then
            object.ScrollBarThickness=math.min(object.ScrollBarThickness,5)
            object.ScrollBarImageColor3=C.Gold
        end
    end
end

local function bindRoot(root)
    if not root:IsA("ScreenGui") or excluded[root.Name] then return end
    for _,o in ipairs(root:GetDescendants()) do style(o) end
    root.DescendantAdded:Connect(function(o) task.defer(style,o) end)
end
for _,root in ipairs(playerGui:GetChildren()) do bindRoot(root) end
playerGui.ChildAdded:Connect(function(root) task.defer(bindRoot,root) end)

local function safeZones()
    local boss=playerGui:FindFirstChild("BossEncounterHUD")
    local panel=boss and boss:FindFirstChild("BossPanel",true)
    if panel then panel.Position=UDim2.new(.5,0,0,48) end
    local q=playerGui:FindFirstChild("QuestHUD")
    local compass=q and q:FindFirstChild("QuestCompass")
    if compass then
        compass.Position=UDim2.new(.5,0,0,0)
        compass.Size=UDim2.fromOffset(440,30)
        local tracker=q:FindFirstChild("QuestTracker")
        if tracker then tracker.Position=UDim2.new(0,18,0,178) end
    end
end
task.defer(safeZones)
playerGui.ChildAdded:Connect(function() task.defer(safeZones) end)
