local MasteryConfig = {}

MasteryConfig.Auras = {
    {Id = "None", Name = "No Aura", RequiredLevel = 1, Color = Color3.fromRGB(255,255,255), Rate = 0},
    {Id = "Glimmer", Name = "Glimmer", RequiredLevel = 5, Color = Color3.fromRGB(150,220,255), Rate = 4},
    {Id = "Ember", Name = "Ember", RequiredLevel = 15, Color = Color3.fromRGB(255,142,72), Rate = 6},
    {Id = "Verdant", Name = "Verdant", RequiredLevel = 30, Color = Color3.fromRGB(105,235,145), Rate = 7},
    {Id = "Arcane", Name = "Arcane", RequiredLevel = 50, Color = Color3.fromRGB(190,115,255), Rate = 9},
    {Id = "Celestial", Name = "Celestial", RequiredLevel = 75, Color = Color3.fromRGB(130,185,255), Rate = 11},
    {Id = "Ancient", Name = "Ancient Crown", RequiredLevel = 100, Color = Color3.fromRGB(255,210,90), Rate = 14},
}

MasteryConfig.ById = {}
for _, aura in ipairs(MasteryConfig.Auras) do
    MasteryConfig.ById[aura.Id] = aura
end

function MasteryConfig.IsUnlocked(level, auraId)
    local aura = MasteryConfig.ById[tostring(auraId or "None")]
    if not aura then return false end
    return math.max(1, math.floor(tonumber(level) or 1)) >= aura.RequiredLevel
end

function MasteryConfig.GetUnlocked(level)
    local list = {}
    for _, aura in ipairs(MasteryConfig.Auras) do
        if MasteryConfig.IsUnlocked(level, aura.Id) then
            table.insert(list, aura)
        end
    end
    return list
end

return MasteryConfig
