local Players = game:GetService("Players")

local source = script.Parent.Parent
local tool = game:GetService("StarterGui"):FindFirstChild("Lasso")

local function give(player)
    if not tool then return end

    local backpack = player:WaitForChild("Backpack")

    if not backpack:FindFirstChild("Lasso") then
        tool:Clone().Parent = backpack
    end
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(1)
        give(player)
    end)
end)
