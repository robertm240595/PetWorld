local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(ReplicatedStorage.WildernessPets.Shared.Config)

local sourceTool = ServerStorage:WaitForChild("WildernessPets"):WaitForChild("Lasso")
local sourceHandle = sourceTool:WaitForChild("Handle")

local materialMap = {
    Fabric = Enum.Material.Fabric,
    Metal = Enum.Material.Metal,
    Neon = Enum.Material.Neon,
    Wood = Enum.Material.Wood,
    Plastic = Enum.Material.SmoothPlastic
}

local function removeDisplay(character)
    local existing = character and character:FindFirstChild("EquippedLassoDisplay")
    if existing then
        existing:Destroy()
    end
end

local function mountDisplay(player, character)
    if not character or not character.Parent then return end

    removeDisplay(character)

    local lassoName = player:GetAttribute("EquippedLassoName")
    if type(lassoName) ~= "string" or lassoName == "" then
        lassoName = "Rough Rope"
    end

    local info = Config.Lassos[lassoName]
    if not info then return end

    local torso = character:FindFirstChild("UpperTorso")
        or character:FindFirstChild("Torso")
        or character:FindFirstChild("HumanoidRootPart")

    if not torso or not torso:IsA("BasePart") then
        torso = character:WaitForChild("HumanoidRootPart", 5)
    end
    if not torso or not torso:IsA("BasePart") then return end

    local display = sourceHandle:Clone()
    display.Name = "EquippedLassoDisplay"
    display.Anchored = false
    display.CanCollide = false
    display.CanTouch = false
    display.CanQuery = false
    display.Massless = true
    display.CastShadow = true

    if typeof(info.DisplayColor) == "Color3" then
        display.Color = info.DisplayColor
    end

    local materialName = tostring(info.DisplayMaterial or "Fabric")
    display.Material = materialMap[materialName] or Enum.Material.Fabric

    display:SetAttribute("LassoName", lassoName)
    display:SetAttribute("CollectibleDisplay", true)
    display.Parent = character

    local isR15 = torso.Name == "UpperTorso"
    local offset

    if isR15 then
        offset = CFrame.new(1.15, -0.15, 0.58)
            * CFrame.Angles(math.rad(18), math.rad(-8), math.rad(72))
    else
        offset = CFrame.new(1.15, -0.35, 0.62)
            * CFrame.Angles(math.rad(18), math.rad(-8), math.rad(72))
    end

    display.CFrame = torso.CFrame * offset

    local weld = Instance.new("WeldConstraint")
    weld.Name = "LassoDisplayWeld"
    weld.Part0 = torso
    weld.Part1 = display
    weld.Parent = display

    if display.Material == Enum.Material.Neon then
        local light = Instance.new("PointLight")
        light.Name = "CollectibleGlow"
        light.Brightness = 0.45
        light.Range = 5
        light.Color = display.Color
        light.Parent = display
    end
end

local function bindPlayer(player)
    local function refresh()
        local character = player.Character
        if character then
            task.defer(function()
                mountDisplay(player, character)
            end)
        end
    end

    player.CharacterAdded:Connect(function(character)
        task.wait(0.25)
        mountDisplay(player, character)
    end)

    player:GetAttributeChangedSignal("EquippedLassoName"):Connect(refresh)

    if player.Character then
        refresh()
    end
end

Players.PlayerAdded:Connect(bindPlayer)

for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(bindPlayer, player)
end
