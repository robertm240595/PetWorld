local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Root = ReplicatedStorage:WaitForChild("WildernessPets")
local ShopRemote = Root:WaitForChild("Remotes"):WaitForChild("Shop")

local Service = {}
local active = setmetatable({}, {__mode = "k"})
local registered = setmetatable({}, {__mode = "k"})
local started = false

local function normalized(name)
    return tostring(name or ""):lower():gsub("[^%w]", "")
end

local function isCandidate(instance)
    if not instance:IsA("Model") then return false end
    local name = normalized(instance.Name)
    return name == "lassokeeper" or name == "lassokeepernpc"
end

local function interactionPart(model)
    if not model or not model.Parent then return nil end
    if model.PrimaryPart then return model.PrimaryPart end
    for _, preferred in ipairs({"HumanoidRootPart","Head","torso_geom","body_geom","Torso"}) do
        local part = model:FindFirstChild(preferred, true)
        if part and part:IsA("BasePart") then return part end
    end
    return model:FindFirstChildWhichIsA("BasePart", true)
end

local function distance(player, model)
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    local part = interactionPart(model)
    if not root or not part then return math.huge end
    return (root.Position - part.Position).Magnitude
end

function Service:Register(model)
    if registered[model] or not isCandidate(model) then return false end
    local part = interactionPart(model)
    if not part then return false end

    registered[model] = true
    local prompt = part:FindFirstChild("LassoKeeperPrompt")
    if not prompt then
        prompt = Instance.new("ProximityPrompt")
        prompt.Name = "LassoKeeperPrompt"
        prompt.ActionText = "Browse Lassos"
        prompt.ObjectText = "Lasso Keeper"
        prompt.MaxActivationDistance = 12
        prompt.HoldDuration = 0.15
        prompt.RequiresLineOfSight = false
        prompt.Parent = part
    end

    prompt.Triggered:Connect(function(player)
        active[player] = {npc = model, expiresAt = os.clock() + 30}
        ShopRemote:FireClient(player, "OpenLassoKeeper")
    end)

    return true
end

function Service:CanTrade(player)
    local session = active[player]
    if not session or os.clock() > session.expiresAt then
        active[player] = nil
        return false, "Speak to the Lasso Keeper first."
    end
    if not session.npc or not session.npc.Parent then
        active[player] = nil
        return false, "The Lasso Keeper is unavailable."
    end
    if distance(player, session.npc) > 20 then
        return false, "Move closer to the Lasso Keeper."
    end
    session.expiresAt = os.clock() + 30
    return true
end

function Service:Init()
    if started then return end
    started = true

    local function scan(instance)
        if isCandidate(instance) then
            task.defer(function() Service:Register(instance) end)
        end
    end

    for _, instance in ipairs(workspace:GetDescendants()) do scan(instance) end
    workspace.DescendantAdded:Connect(scan)

    task.spawn(function()
        for _ = 1, 12 do
            task.wait(2)
            for _, instance in ipairs(workspace:GetDescendants()) do
                if isCandidate(instance) and not registered[instance] then
                    Service:Register(instance)
                end
            end
        end
    end)
end

Players.PlayerRemoving:Connect(function(player)
    active[player] = nil
end)

return Service
