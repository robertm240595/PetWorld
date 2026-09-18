local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local root = ReplicatedStorage:WaitForChild("WildernessPets")
local source = ServerStorage:WaitForChild("WildernessPets"):WaitForChild("Monsters")

local previews = root:FindFirstChild("PetPreviews")
if previews then
    previews:Destroy()
end

previews = Instance.new("Folder")
previews.Name = "PetPreviews"
previews.Parent = root

for _, template in ipairs(source:GetChildren()) do
    if template:IsA("Model") then
        local copy = template:Clone()
        copy.Name = template.Name

        for _, item in ipairs(copy:GetDescendants()) do
            if item:IsA("LuaSourceContainer")
                or item:IsA("BillboardGui")
                or item:IsA("ParticleEmitter")
                or item:IsA("Beam")
                or item:IsA("Trail") then
                item:Destroy()
            elseif item:IsA("BasePart") then
                item.Anchored = true
                item.CanCollide = false
                item.CanTouch = false
                item.CanQuery = false
            end
        end

        copy.Parent = previews
    end
end
