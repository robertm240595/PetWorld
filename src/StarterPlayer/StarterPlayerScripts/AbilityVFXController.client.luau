local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local world = workspace:WaitForChild("WildernessPets")
local companions = world:WaitForChild("Companions")
local GameRemote = ReplicatedStorage
    :WaitForChild("WildernessPets")
    :WaitForChild("Remotes")
    :WaitForChild("Game")

local function companionFor(userId)
    for _, model in ipairs(companions:GetChildren()) do
        if tonumber(model:GetAttribute("OwnerUserId")) == userId then
            return model
        end
    end
end

local function pulse(model, supportive)
    if not model or not model.Parent then return end
    local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
    if not part then return end

    local orb = Instance.new("Part")
    orb.Name = "AbilityPulse"
    orb.Shape = Enum.PartType.Ball
    orb.Size = Vector3.new(1.5, 1.5, 1.5)
    orb.CFrame = part.CFrame
    orb.Anchored = true
    orb.CanCollide = false
    orb.CanTouch = false
    orb.CanQuery = false
    orb.CastShadow = false
    orb.Material = Enum.Material.Neon
    orb.Color = supportive
        and Color3.fromRGB(105, 205, 178)
        or Color3.fromRGB(236, 174, 83)
    orb.Transparency = 0.55
    orb.Parent = workspace

    local size = math.max(5, model:GetExtentsSize().Magnitude * 0.75)
    local tween = TweenService:Create(
        orb,
        TweenInfo.new(0.48, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {
            Size = Vector3.new(size, size, size),
            Transparency = 1,
        }
    )
    tween:Play()
    Debris:AddItem(orb, 0.6)

    local highlight = Instance.new("Highlight")
    highlight.Name = "AbilityFlash"
    highlight.Adornee = model
    highlight.DepthMode = Enum.HighlightDepthMode.Occluded
    highlight.FillColor = orb.Color
    highlight.OutlineColor = orb.Color
    highlight.FillTransparency = 0.45
    highlight.OutlineTransparency = 0.15
    highlight.Parent = model

    TweenService:Create(
        highlight,
        TweenInfo.new(0.42, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {
            FillTransparency = 1,
            OutlineTransparency = 1,
        }
    ):Play()
    Debris:AddItem(highlight, 0.5)
end

GameRemote.OnClientEvent:Connect(function(action, kind)
    if action ~= "Combat" then return end

    if kind == "AbilityUsed" then
        pulse(companionFor(player.UserId), false)
    elseif kind == "SupportBuff" then
        pulse(companionFor(player.UserId), true)
    end
end)
