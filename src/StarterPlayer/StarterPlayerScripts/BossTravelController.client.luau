local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local remote = ReplicatedStorage
    :WaitForChild("WildernessPets")
    :WaitForChild("Remotes")
    :WaitForChild("BossTravel")

local gui = Instance.new("ScreenGui")
gui.Name = "BossTravelTransition"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 1000
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")

local blackout = Instance.new("Frame")
blackout.Name = "Blackout"
blackout.Size = UDim2.fromScale(1, 1)
blackout.BackgroundColor3 = Color3.fromRGB(7, 8, 9)
blackout.BackgroundTransparency = 1
blackout.BorderSizePixel = 0
blackout.Parent = gui

local title = Instance.new("TextLabel")
title.Name = "Title"
title.AnchorPoint = Vector2.new(.5, .5)
title.Position = UDim2.fromScale(.5, .47)
title.Size = UDim2.new(.8, 0, 0, 54)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBlack
title.TextSize = 28
title.TextColor3 = Color3.fromRGB(235, 229, 211)
title.TextStrokeTransparency = .5
title.TextTransparency = 1
title.Text = ""
title.Parent = blackout

local subtitle = Instance.new("TextLabel")
subtitle.Name = "Subtitle"
subtitle.AnchorPoint = Vector2.new(.5, 0)
subtitle.Position = UDim2.new(.5, 0, .52, 0)
subtitle.Size = UDim2.new(.76, 0, 0, 52)
subtitle.BackgroundTransparency = 1
subtitle.Font = Enum.Font.GothamMedium
subtitle.TextSize = 14
subtitle.TextWrapped = true
subtitle.TextColor3 = Color3.fromRGB(179, 185, 181)
subtitle.TextTransparency = 1
subtitle.Text = ""
subtitle.Parent = blackout

local toast = Instance.new("TextLabel")
toast.Name = "TravelMessage"
toast.AnchorPoint = Vector2.new(.5, 0)
toast.Position = UDim2.new(.5, 0, .12, 0)
toast.Size = UDim2.new(0, 560, 0, 56)
toast.BackgroundColor3 = Color3.fromRGB(32, 35, 38)
toast.BackgroundTransparency = 1
toast.BorderSizePixel = 0
toast.Font = Enum.Font.GothamBold
toast.TextSize = 14
toast.TextWrapped = true
toast.TextColor3 = Color3.fromRGB(238, 220, 176)
toast.TextTransparency = 1
toast.Visible = false
toast.Parent = gui

local toastCorner = Instance.new("UICorner")
toastCorner.CornerRadius = UDim.new(0, 9)
toastCorner.Parent = toast

local toastStroke = Instance.new("UIStroke")
toastStroke.Color = Color3.fromRGB(165, 135, 84)
toastStroke.Transparency = .35
toastStroke.Thickness = 1
toastStroke.Parent = toast

local transitionToken = 0
local toastToken = 0

local function playTween(instance, duration, properties)
    local tween = TweenService:Create(
        instance,
        TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        properties
    )
    tween:Play()
    return tween
end

local function fadeOut(titleText, subtitleText)
    transitionToken += 1
    local token = transitionToken

    gui.Enabled = true
    toast.Visible = false

    title.Text = tostring(titleText or "")
    subtitle.Text = tostring(subtitleText or "")

    blackout.BackgroundTransparency = 1
    title.TextTransparency = 1
    subtitle.TextTransparency = 1

    playTween(blackout, .28, {BackgroundTransparency = 0})
    task.wait(.08)

    if transitionToken ~= token then return end
    playTween(title, .22, {TextTransparency = 0})
    playTween(subtitle, .22, {TextTransparency = .05})
end

local function fadeIn()
    transitionToken += 1
    local token = transitionToken

    playTween(title, .18, {TextTransparency = 1})
    playTween(subtitle, .18, {TextTransparency = 1})
    local tween = playTween(blackout, .34, {BackgroundTransparency = 1})

    tween.Completed:Connect(function()
        if transitionToken ~= token then return end
        if not toast.Visible then
            gui.Enabled = false
        end
    end)
end

local function showBlocked(message)
    toastToken += 1
    local token = toastToken

    gui.Enabled = true
    toast.Visible = true
    toast.Text = tostring(message or "That passage is not available yet.")
    toast.BackgroundTransparency = 1
    toast.TextTransparency = 1

    playTween(toast, .16, {
        BackgroundTransparency = .12,
        TextTransparency = 0,
    })

    task.delay(3.2, function()
        if toastToken ~= token then return end

        local tween = playTween(toast, .22, {
            BackgroundTransparency = 1,
            TextTransparency = 1,
        })

        tween.Completed:Connect(function()
            if toastToken ~= token then return end
            toast.Visible = false
            if blackout.BackgroundTransparency >= .99 then
                gui.Enabled = false
            end
        end)
    end)
end

remote.OnClientEvent:Connect(function(action, a, b)
    if action == "FadeOut" then
        task.spawn(fadeOut, a, b)
    elseif action == "FadeIn" then
        fadeIn()
    elseif action == "Blocked" then
        showBlocked(a)
    end
end)
