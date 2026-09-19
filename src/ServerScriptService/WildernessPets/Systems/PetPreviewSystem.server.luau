local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.WildernessPets.Shared.Config)
local ModelFactory = require(script.Parent.PetModelFactory)

local root = ReplicatedStorage:WaitForChild("WildernessPets")

local previews = root:FindFirstChild("PetPreviews")
if previews then
    previews:Destroy()
end

previews = Instance.new("Folder")
previews.Name = "PetPreviews"
previews.Parent = root

local speciesNames = {}
for species in pairs(Config.Pets) do
    table.insert(speciesNames, species)
end
table.sort(speciesNames)

for _, species in ipairs(speciesNames) do
    local copy = ModelFactory:Create(species)
    if copy then
        copy.Name = species

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
