local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local tool = ServerStorage.WildernessPets:FindFirstChild("Lasso")

if not tool then
    return
end

local function give(player)
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

for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(function()
        if player.Character then
            give(player)
        end

        player.CharacterAdded:Connect(function()
            task.wait(1)
            give(player)
        end)
    end)
end
