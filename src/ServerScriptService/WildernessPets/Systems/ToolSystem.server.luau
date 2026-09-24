local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local VisualService = require(script.Parent.LassoVisualService)
local sourceTool = ServerStorage.WildernessPets:FindFirstChild("Lasso")

if not sourceTool then
    return
end

local function refreshTool(player, tool)
    if not tool or not tool:IsA("Tool") or tool.Name ~= "Lasso" then
        return
    end

    if tool:GetAttribute("LassoVisualRefreshBound") ~= true then
        tool:SetAttribute("LassoVisualRefreshBound", true)

        -- The Tool can receive its first visual while still in Backpack, before
        -- the character's LeftHand is guaranteed to be available. Rebuild once
        -- equipped so the grip/secondary-motion anchor is always the real hand.
        tool.Equipped:Connect(function()
            task.delay(0.05, function()
                if tool.Parent and player.Character and tool:IsDescendantOf(player.Character) then
                    VisualService:AttachTool(player, tool)
                end
            end)
        end)
    end

    VisualService:AttachTool(player, tool)
end

local function refresh(player)
    local backpack = player:FindFirstChildOfClass("Backpack")
    local character = player.Character

    if backpack then
        refreshTool(player, backpack:FindFirstChild("Lasso"))
    end
    if character then
        refreshTool(player, character:FindFirstChild("Lasso"))
    end
end

local function give(player)
    local backpack = player:WaitForChild("Backpack")
    local character = player.Character
    local existing = backpack:FindFirstChild("Lasso")
        or (character and character:FindFirstChild("Lasso"))

    if existing then
        refreshTool(player, existing)
        return existing
    end

    local clone = sourceTool:Clone()
    clone.Parent = backpack
    refreshTool(player, clone)
    return clone
end

local function bind(player)
    player.CharacterAdded:Connect(function()
        task.wait(1)
        give(player)
    end)

    player:GetAttributeChangedSignal("EquippedLassoName"):Connect(function()
        refresh(player)
    end)
    player:GetAttributeChangedSignal("EquippedLassoSkin"):Connect(function()
        refresh(player)
    end)

    if player.Character then
        task.defer(function()
            give(player)
        end)
    end
end

Players.PlayerAdded:Connect(bind)

for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(bind, player)
end
