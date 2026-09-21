local input, outRoot = ...
local dm = fs.read(input)
local ss = assert(dm:FindFirstChild("ServerStorage"), "ServerStorage missing")
local wp = assert(ss:FindFirstChild("WildernessPets"), "WildernessPets missing")
local monsters = assert(wp:FindFirstChild("Monsters"), "Monsters missing")
local npcs = assert(wp:FindFirstChild("NPCs"), "NPCs missing")
local mdir = outRoot .. "/Monsters"
local ndir = outRoot .. "/NPCs"
fs.mkdir(outRoot)
fs.mkdir(mdir)
fs.mkdir(ndir)
local mcount,ncount=0,0
for _, child in ipairs(monsters:GetChildren()) do
    if child:IsA("Model") then
        local clone = child:Clone()
        clone.Parent = nil
        fs.write(mdir .. "/" .. child.Name .. ".rbxmx", clone)
        mcount = mcount + 1
    end
end
for _, child in ipairs(npcs:GetChildren()) do
    if child:IsA("Model") then
        local clone = child:Clone()
        clone.Parent = nil
        fs.write(ndir .. "/" .. child.Name .. ".rbxmx", clone)
        ncount = ncount + 1
    end
end
print("EXPORTED", mcount, ncount)