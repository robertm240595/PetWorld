local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(script.Parent.PlayerDataService)
local PetService = require(script.Parent.PetService)
local Animator = require(script.Parent.Parent.Systems.PetAnimator)
local ModelFactory = require(script.Parent.Parent.Systems.PetModelFactory)
local Config = require(game.ReplicatedStorage.WildernessPets.Shared.Config)

local Root = ReplicatedStorage:WaitForChild("WildernessPets")
local ShopRemote = Root:WaitForChild("Remotes"):WaitForChild("Shop")

local Service = {}
local sessions = setmetatable({}, {__mode = "k"})
local started = false

local function getPlots()
    local world = workspace:FindFirstChild("WildernessPets")
    return world and world:FindFirstChild("Plots")
end

local function getOwnedPlot(player)
    local plots = getPlots()
    if not plots then return nil end
    for _, plot in ipairs(plots:GetChildren()) do
        local owner = tonumber(plot:GetAttribute("OwnerUserId") or plot:GetAttribute("Owner"))
        if owner == player.UserId then
            return plot
        end
    end
    return nil
end

local function barnPart(parent, name, size, cframe, color)
    local part = Instance.new("Part")
    part.Name = name
    part.Anchored = true
    part.CanCollide = true
    part.Size = size
    part.CFrame = cframe
    part.Color = color
    part.Material = Enum.Material.WoodPlanks
    part.Parent = parent
    return part
end

local function buildBarn(plot)
    local existing = plot:FindFirstChild("HealingBarn")
    if existing then return existing end

    local land = plot:FindFirstChild("Land", true)
    if not land or not land:IsA("BasePart") then return nil end

    local barn = Instance.new("Model")
    barn.Name = "HealingBarn"
    barn.Parent = plot

    local baseFrame = land.CFrame
        * CFrame.new(land.Size.X * 0.30, land.Size.Y / 2 + 0.55, -land.Size.Z * 0.30)

    local red = Color3.fromRGB(130, 64, 52)
    local dark = Color3.fromRGB(88, 48, 39)
    local pale = Color3.fromRGB(222, 201, 162)

    local floor = barnPart(barn, "Floor", Vector3.new(18, 1, 14), baseFrame, dark)
    floor.CanCollide = true

    barnPart(barn, "BackWall", Vector3.new(18, 8, 1), baseFrame * CFrame.new(0, 4.5, -6.5), red)
    barnPart(barn, "LeftWall", Vector3.new(1, 8, 13), baseFrame * CFrame.new(-8.5, 4.5, 0), red)
    barnPart(barn, "RightWall", Vector3.new(1, 8, 13), baseFrame * CFrame.new(8.5, 4.5, 0), red)
    barnPart(barn, "FrontLeft", Vector3.new(5.5, 8, 1), baseFrame * CFrame.new(-6.25, 4.5, 6.5), red)
    barnPart(barn, "FrontRight", Vector3.new(5.5, 8, 1), baseFrame * CFrame.new(6.25, 4.5, 6.5), red)

    local roofLeft = barnPart(
        barn,
        "RoofLeft",
        Vector3.new(10.5, 1, 15.5),
        baseFrame * CFrame.new(-4.4, 9, 0) * CFrame.Angles(0, 0, math.rad(-25)),
        dark
    )
    roofLeft.CanCollide = false

    local roofRight = barnPart(
        barn,
        "RoofRight",
        Vector3.new(10.5, 1, 15.5),
        baseFrame * CFrame.new(4.4, 9, 0) * CFrame.Angles(0, 0, math.rad(25)),
        dark
    )
    roofRight.CanCollide = false

    local sign = barnPart(barn, "BarnSign", Vector3.new(6, 2, 0.5), baseFrame * CFrame.new(0, 7.5, 6.7), pale)
    sign.CanCollide = false

    local signGui = Instance.new("SurfaceGui")
    signGui.Face = Enum.NormalId.Front
    signGui.Parent = sign

    local signText = Instance.new("TextLabel")
    signText.BackgroundTransparency = 1
    signText.Size = UDim2.fromScale(1, 1)
    signText.Text = "PET BARN"
    signText.Font = Enum.Font.GothamBold
    signText.TextScaled = true
    signText.TextColor3 = Color3.fromRGB(67, 42, 31)
    signText.Parent = signGui

    local promptPart = barnPart(barn, "BarnPrompt", Vector3.new(5, 1, 2), baseFrame * CFrame.new(0, 1, 7.2), pale)
    promptPart.Transparency = 1
    promptPart.CanCollide = false

    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "HealingBarnPrompt"
    prompt.ActionText = "Heal Pets"
    prompt.ObjectText = "Pet Barn"
    prompt.MaxActivationDistance = 12
    prompt.HoldDuration = 0.15
    prompt.RequiresLineOfSight = false
    prompt.Parent = promptPart

    local healingFolder = Instance.new("Folder")
    healingFolder.Name = "HealingPets"
    healingFolder.Parent = barn

    prompt.Triggered:Connect(function(player)
        local owner = tonumber(plot:GetAttribute("OwnerUserId") or plot:GetAttribute("Owner"))
        if owner ~= player.UserId then return end
        sessions[player] = {barn = barn, expiresAt = os.clock() + 3600}
        Service:RefreshVisuals(player)
        ShopRemote:FireClient(player, "OpenBarn")
    end)

    return barn
end

function Service:GetBarn(player)
    local plot = getOwnedPlot(player)
    if not plot then return nil end
    return plot:FindFirstChild("HealingBarn") or buildBarn(plot)
end

function Service:CanUse(player)
    local session = sessions[player]
    if not session or os.clock() > session.expiresAt then
        sessions[player] = nil
        return false, "Use the Pet Barn on your plot first."
    end

    local barn = session.barn
    if not barn or not barn.Parent then
        sessions[player] = nil
        return false, "Your Pet Barn is unavailable."
    end

    local promptPart = barn:FindFirstChild("BarnPrompt")
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not promptPart or not root or (root.Position - promptPart.Position).Magnitude > 22 then
        return false, "Move closer to your Pet Barn."
    end

    local plot = barn.Parent
    local owner = tonumber(plot:GetAttribute("OwnerUserId") or plot:GetAttribute("Owner"))
    if owner ~= player.UserId then
        return false, "That is not your Pet Barn."
    end

    session.expiresAt = os.clock() + 3600
    return true
end

function Service:RefreshVisuals(player)
    local barn = self:GetBarn(player)
    if not barn then return end

    local folder = barn:FindFirstChild("HealingPets")
    if not folder then return end
    folder:ClearAllChildren()

    local floor = barn:FindFirstChild("Floor")
    if not floor or not floor:IsA("BasePart") then return end

    local slot = 0
    for _, pet in ipairs(PetService:GetPets(player)) do
        if pet.Dead and (tonumber(pet.HealReadyAt) or 0) > 0 then
            slot += 1
            if slot > 3 then break end

            local petInfo = Config.Pets[pet.Species]
            local model = ModelFactory:Create(pet.Species)
            if model then
                model.Name = "Healing_" .. tostring(pet.Id)
                for _, item in ipairs(model:GetDescendants()) do
                    if item:IsA("BillboardGui") or item:IsA("LuaSourceContainer") then
                        item:Destroy()
                    elseif item:IsA("BasePart") then
                        item.Anchored = true
                        item.CanCollide = false
                        item.CanTouch = false
                        item.CanQuery = false
                    end
                end
                model:SetAttribute("Species", pet.Species)
                model:SetAttribute("AnimationSpecies", (petInfo and petInfo.AnimationSpecies) or pet.Species)
                model.Parent = folder

                local rig = Animator:_getRig(model)
                if rig then
                    local x = (slot - 2) * 5
                    rig.base = floor.CFrame * CFrame.new(x, floor.Size.Y / 2 + rig.clearance + 0.08, 0)
                    Animator:Stop(model)
                    task.spawn(function()
                        Animator:PlayFaint(model, 0.5)
                    end)
                end

                if model.PrimaryPart then
                    local gui = Instance.new("BillboardGui")
                    gui.Size = UDim2.fromOffset(150, 28)
                    gui.StudsOffsetWorldSpace = Vector3.new(0, model:GetExtentsSize().Y * 0.5 + 0.6, 0)
                    gui.MaxDistance = 45
                    gui.Parent = model.PrimaryPart

                    local label = Instance.new("TextLabel")
                    label.BackgroundTransparency = 1
                    label.Size = UDim2.fromScale(1, 1)
                    label.Font = Enum.Font.GothamSemibold
                    label.TextSize = 12
                    label.TextStrokeTransparency = 0.4
                    local ready = (tonumber(pet.HealReadyAt) or 0) <= os.time()
                    label.TextColor3 = ready
                        and Color3.fromRGB(150, 235, 158)
                        or Color3.fromRGB(245, 225, 190)
                    label.Text = tostring(pet.Name)
                        .. (ready and "  ·  READY TO COLLECT" or "  ·  HEALING")
                    label.Parent = gui
                end
            end
        end
    end
end

function Service:Init()
    if started then return end
    started = true

    local plots = getPlots()
    if not plots then return end

    for _, plot in ipairs(plots:GetChildren()) do
        buildBarn(plot)
    end

    plots.ChildAdded:Connect(function(plot)
        task.defer(function()
            buildBarn(plot)
        end)
    end)
end

Players.PlayerRemoving:Connect(function(player)
    sessions[player] = nil
end)

return Service
