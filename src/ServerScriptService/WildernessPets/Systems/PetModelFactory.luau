local ServerStorage = game:GetService("ServerStorage")
local Config = require(game.ReplicatedStorage.WildernessPets.Shared.Config)

local Factory = {}

local function monsterTemplates()
    local root = ServerStorage:FindFirstChild("WildernessPets")
    return root and root:FindFirstChild("Monsters")
end

local function part(model, name, size, position, color, material, shape)
    local item = Instance.new("Part")
    item.Name = name
    item.Size = size
    item.CFrame = CFrame.new(position)
    item.Color = color
    item.Material = material or Enum.Material.SmoothPlastic
    item.Shape = shape or Enum.PartType.Block
    item.Anchored = true
    item.CanCollide = false
    item.CanTouch = false
    item.CanQuery = false
    item.CastShadow = true
    item.TopSurface = Enum.SurfaceType.Smooth
    item.BottomSurface = Enum.SurfaceType.Smooth
    item.Parent = model
    return item
end

local function ball(model, name, size, position, color, material)
    return part(model, name, size, position, color, material, Enum.PartType.Ball)
end

local function body(model, color)
    return part(model, "body_geom", Vector3.new(3.2, 2.0, 4.2), Vector3.new(0, 2.0, 0), color)
end

local function quadruped(model, color, accent)
    local root = body(model, color)
    ball(model, "head_geom", Vector3.new(2.0, 1.8, 2.0), Vector3.new(0, 2.55, 2.75), color)
    part(model, "muzzle_geom", Vector3.new(1.4, 0.9, 1.3), Vector3.new(0, 2.25, 3.7), accent)
    for _, spec in ipairs({
        {"leg_front_left", -1.0, 0.75, 1.25},
        {"leg_front_right", 1.0, 0.75, 1.25},
        {"leg_rear_left", -1.0, 0.75, -1.25},
        {"leg_rear_right", 1.0, 0.75, -1.25},
    }) do
        part(model, spec[1], Vector3.new(0.7, 1.7, 0.75), Vector3.new(spec[2], spec[3], spec[4]), color)
    end
    part(model, "tail_geom", Vector3.new(0.55, 0.55, 2.2), Vector3.new(0, 2.15, -3.0), accent)
    return root
end

local function bird(model, color, accent)
    local root = ball(model, "body_geom", Vector3.new(2.6, 2.8, 3.3), Vector3.new(0, 2.3, 0), color)
    ball(model, "head_geom", Vector3.new(1.7, 1.7, 1.7), Vector3.new(0, 3.05, 2.0), color)
    part(model, "beak_geom", Vector3.new(0.65, 0.5, 1.0), Vector3.new(0, 2.95, 3.2), accent)
    part(model, "wing_left", Vector3.new(2.6, 0.35, 2.7), Vector3.new(-2.0, 2.35, -0.05), accent)
    part(model, "wing_right", Vector3.new(2.6, 0.35, 2.7), Vector3.new(2.0, 2.35, -0.05), accent)
    part(model, "leg_left", Vector3.new(0.35, 1.25, 0.35), Vector3.new(-0.55, 0.8, 0.15), accent)
    part(model, "leg_right", Vector3.new(0.35, 1.25, 0.35), Vector3.new(0.55, 0.8, 0.15), accent)
    part(model, "tail_geom", Vector3.new(1.5, 0.4, 2.3), Vector3.new(0, 2.1, -2.6), color)
    return root
end

local function bat(model, color, accent)
    local root = ball(model, "body_geom", Vector3.new(2.0, 2.3, 2.4), Vector3.new(0, 2.6, 0), color)
    ball(model, "head_geom", Vector3.new(1.4, 1.4, 1.4), Vector3.new(0, 2.9, 1.7), color)
    part(model, "wing_left", Vector3.new(3.4, 0.25, 2.5), Vector3.new(-2.5, 2.55, -0.1), accent)
    part(model, "wing_right", Vector3.new(3.4, 0.25, 2.5), Vector3.new(2.5, 2.55, -0.1), accent)
    part(model, "leg_left", Vector3.new(0.3, 0.8, 0.3), Vector3.new(-0.45, 1.45, -0.2), color)
    part(model, "leg_right", Vector3.new(0.3, 0.8, 0.3), Vector3.new(0.45, 1.45, -0.2), color)
    return root
end

local function lizard(model, color, accent)
    local root = part(model, "body_geom", Vector3.new(3.0, 1.25, 4.2), Vector3.new(0, 1.35, 0), color)
    ball(model, "head_geom", Vector3.new(1.8, 1.25, 2.0), Vector3.new(0, 1.55, 2.8), color)
    for _, spec in ipairs({
        {"leg_front_left", -1.45, 0.6, 1.2},
        {"leg_front_right", 1.45, 0.6, 1.2},
        {"leg_rear_left", -1.45, 0.6, -1.2},
        {"leg_rear_right", 1.45, 0.6, -1.2},
    }) do
        part(model, spec[1], Vector3.new(1.2, 0.4, 0.45), Vector3.new(spec[2], spec[3], spec[4]), accent)
    end
    part(model, "tail_geom", Vector3.new(0.8, 0.8, 3.2), Vector3.new(0, 1.25, -3.6), color)
    return root
end

local function serpent(model, color, accent)
    local root = part(model, "body_geom", Vector3.new(2.1, 1.45, 3.0), Vector3.new(0, 1.25, 0), color)
    ball(model, "head_geom", Vector3.new(2.0, 1.6, 2.2), Vector3.new(0, 1.55, 2.7), accent)
    for index = 1, 4 do
        local z = -2.0 - (index - 1) * 1.6
        part(model, "tail_" .. tostring(index), Vector3.new(1.8 - index * 0.18, 1.1 - index * 0.08, 1.8), Vector3.new(0, 1.15, z), color)
    end
    return root
end

local function turtle(model, color, accent)
    local root = ball(model, "body_geom", Vector3.new(3.8, 1.8, 4.6), Vector3.new(0, 1.55, 0), accent)
    ball(model, "head_geom", Vector3.new(1.5, 1.2, 1.7), Vector3.new(0, 1.45, 3.0), color)
    for _, spec in ipairs({
        {"leg_front_left", -1.8, 0.65, 1.25},
        {"leg_front_right", 1.8, 0.65, 1.25},
        {"leg_rear_left", -1.8, 0.65, -1.25},
        {"leg_rear_right", 1.8, 0.65, -1.25},
    }) do
        part(model, spec[1], Vector3.new(1.25, 0.45, 0.85), Vector3.new(spec[2], spec[3], spec[4]), color)
    end
    part(model, "tail_geom", Vector3.new(0.45, 0.45, 1.2), Vector3.new(0, 1.1, -2.8), color)
    return root
end

local function raptor(model, color, accent)
    local root = part(model, "body_geom", Vector3.new(2.4, 1.7, 3.6), Vector3.new(0, 2.1, 0), color)
    ball(model, "head_geom", Vector3.new(1.5, 1.35, 1.8), Vector3.new(0, 2.8, 2.6), color)
    part(model, "leg_rear_left", Vector3.new(0.55, 2.1, 0.65), Vector3.new(-0.75, 0.9, -0.6), accent)
    part(model, "leg_rear_right", Vector3.new(0.55, 2.1, 0.65), Vector3.new(0.75, 0.9, -0.6), accent)
    part(model, "arm_left", Vector3.new(0.35, 0.35, 1.4), Vector3.new(-1.2, 2.15, 1.0), accent)
    part(model, "arm_right", Vector3.new(0.35, 0.35, 1.4), Vector3.new(1.2, 2.15, 1.0), accent)
    part(model, "tail_geom", Vector3.new(0.7, 0.7, 4.0), Vector3.new(0, 2.0, -3.3), color)
    return root
end

local function beetle(model, color, accent)
    local root = ball(model, "body_geom", Vector3.new(2.8, 1.7, 3.6), Vector3.new(0, 1.55, 0), color)
    ball(model, "head_geom", Vector3.new(1.6, 1.25, 1.5), Vector3.new(0, 1.5, 2.3), accent)
    for i = 1, 3 do
        local z = 1.2 - (i - 1) * 1.2
        part(model, "leg_left_" .. i, Vector3.new(1.6, 0.3, 0.3), Vector3.new(-1.65, 0.8, z), accent)
        part(model, "leg_right_" .. i, Vector3.new(1.6, 0.3, 0.3), Vector3.new(1.65, 0.8, z), accent)
    end
    part(model, "wing_left", Vector3.new(1.2, 0.25, 2.8), Vector3.new(-0.7, 2.3, -0.1), accent)
    part(model, "wing_right", Vector3.new(1.2, 0.25, 2.8), Vector3.new(0.7, 2.3, -0.1), accent)
    return root
end

local function arachnid(model, color, accent)
    local root = ball(model, "body_geom", Vector3.new(2.6, 1.8, 2.9), Vector3.new(0, 1.45, -0.5), color)
    ball(model, "head_geom", Vector3.new(1.9, 1.5, 1.9), Vector3.new(0, 1.45, 1.6), accent)
    for i = 1, 4 do
        local z = 1.2 - (i - 1) * 0.8
        part(model, "leg_left_" .. i, Vector3.new(2.2, 0.28, 0.28), Vector3.new(-1.85, 0.75, z), color)
        part(model, "leg_right_" .. i, Vector3.new(2.2, 0.28, 0.28), Vector3.new(1.85, 0.75, z), color)
    end
    return root
end

local function scorpion(model, color, accent)
    local root = arachnid(model, color, accent)
    part(model, "claw_left", Vector3.new(1.2, 0.5, 1.4), Vector3.new(-1.6, 1.2, 2.5), accent)
    part(model, "claw_right", Vector3.new(1.2, 0.5, 1.4), Vector3.new(1.6, 1.2, 2.5), accent)
    for index = 1, 3 do
        part(model, "tail_" .. index, Vector3.new(0.65, 0.65, 1.4), Vector3.new(0, 1.3 + index * 0.55, -2.1 - index * 0.85), color)
    end
    part(model, "tail_stinger", Vector3.new(0.45, 0.45, 0.9), Vector3.new(0, 3.2, -5.0), accent)
    return root
end

local function hydra(model, color, accent)
    local root = part(model, "body_geom", Vector3.new(3.8, 2.3, 4.2), Vector3.new(0, 2.2, 0), color)
    for index, x in ipairs({-1.4, 0, 1.4}) do
        part(model, "neck_" .. index, Vector3.new(0.8, 1.8, 0.8), Vector3.new(x, 3.4, 1.6), color)
        ball(model, "head_" .. index, Vector3.new(1.35, 1.2, 1.6), Vector3.new(x, 4.5, 2.3), accent)
    end
    for _, spec in ipairs({
        {"leg_front_left", -1.1, 0.8, 1.1},
        {"leg_front_right", 1.1, 0.8, 1.1},
        {"leg_rear_left", -1.1, 0.8, -1.1},
        {"leg_rear_right", 1.1, 0.8, -1.1},
    }) do
        part(model, spec[1], Vector3.new(0.75, 1.8, 0.75), Vector3.new(spec[2], spec[3], spec[4]), color)
    end
    part(model, "tail_geom", Vector3.new(0.8, 0.8, 3.2), Vector3.new(0, 2.1, -3.5), accent)
    return root
end

local function titan(model, color, accent)
    local root = part(model, "body_geom", Vector3.new(4.0, 4.0, 2.8), Vector3.new(0, 4.0, 0), color)
    ball(model, "head_geom", Vector3.new(2.5, 2.5, 2.5), Vector3.new(0, 7.0, 0.6), accent)
    part(model, "leg_left", Vector3.new(1.25, 3.5, 1.5), Vector3.new(-1.2, 1.75, 0), color)
    part(model, "leg_right", Vector3.new(1.25, 3.5, 1.5), Vector3.new(1.2, 1.75, 0), color)
    part(model, "arm_left", Vector3.new(1.1, 3.7, 1.1), Vector3.new(-2.8, 4.0, 0), accent)
    part(model, "arm_right", Vector3.new(1.1, 3.7, 1.1), Vector3.new(2.8, 4.0, 0), accent)
    return root
end

local function kraken(model, color, accent)
    local root = ball(model, "body_geom", Vector3.new(4.5, 4.0, 4.5), Vector3.new(0, 3.8, 0), color)
    ball(model, "head_geom", Vector3.new(3.0, 2.5, 3.0), Vector3.new(0, 5.6, 1.3), accent)
    for index = 1, 6 do
        local angle = (index - 1) * math.pi * 2 / 6
        local x = math.cos(angle) * 2.6
        local z = math.sin(angle) * 2.6 - 0.8
        part(model, "tail_tentacle_" .. index, Vector3.new(0.7, 0.7, 4.0), Vector3.new(x, 1.6, z), index % 2 == 0 and accent or color)
    end
    return root
end

local function imp(model, color, accent)
    local root = part(model, "body_geom", Vector3.new(2.2, 2.8, 1.8), Vector3.new(0, 2.3, 0), color)
    ball(model, "head_geom", Vector3.new(1.9, 1.8, 1.9), Vector3.new(0, 4.3, 0.5), accent)
    part(model, "leg_left", Vector3.new(0.55, 1.7, 0.55), Vector3.new(-0.55, 0.85, 0), color)
    part(model, "leg_right", Vector3.new(0.55, 1.7, 0.55), Vector3.new(0.55, 0.85, 0), color)
    part(model, "arm_left", Vector3.new(0.45, 1.7, 0.45), Vector3.new(-1.35, 2.4, 0), color)
    part(model, "arm_right", Vector3.new(0.45, 1.7, 0.45), Vector3.new(1.35, 2.4, 0), color)
    part(model, "tail_geom", Vector3.new(0.35, 0.35, 2.3), Vector3.new(0, 2.0, -1.8), accent)
    return root
end

local builders = {
    Quadruped = quadruped,
    Bird = bird,
    Bat = bat,
    Lizard = lizard,
    Serpent = serpent,
    Turtle = turtle,
    Raptor = raptor,
    Beetle = beetle,
    Arachnid = arachnid,
    Scorpion = scorpion,
    Hydra = hydra,
    Titan = titan,
    Kraken = kraken,
    Imp = imp,
}

local function addFeature(model, feature, accent)
    local neon = Enum.Material.Neon
    if feature == "horns" or feature == "antlers" then
        part(model, "horn_left", Vector3.new(0.3, 1.5, 0.3), Vector3.new(-0.65, 3.75, 3.0), accent, neon)
        part(model, "horn_right", Vector3.new(0.3, 1.5, 0.3), Vector3.new(0.65, 3.75, 3.0), accent, neon)
        if feature == "antlers" then
            part(model, "antler_left", Vector3.new(0.9, 0.22, 0.22), Vector3.new(-1.0, 4.15, 3.0), accent, neon)
            part(model, "antler_right", Vector3.new(0.9, 0.22, 0.22), Vector3.new(1.0, 4.15, 3.0), accent, neon)
        end
    elseif feature == "ears" then
        part(model, "ear_left", Vector3.new(0.45, 1.0, 0.4), Vector3.new(-0.55, 3.75, 2.7), accent)
        part(model, "ear_right", Vector3.new(0.45, 1.0, 0.4), Vector3.new(0.55, 3.75, 2.7), accent)
    elseif feature == "tusks" then
        part(model, "tusk_left", Vector3.new(0.25, 0.25, 0.9), Vector3.new(-0.55, 2.0, 4.25), Color3.fromRGB(234, 224, 194))
        part(model, "tusk_right", Vector3.new(0.25, 0.25, 0.9), Vector3.new(0.55, 2.0, 4.25), Color3.fromRGB(234, 224, 194))
    elseif feature == "spikes" or feature == "plates" or feature == "crystal" then
        for index = 1, 4 do
            part(model, "spike_" .. index, Vector3.new(0.35, 0.9 + index * 0.08, 0.35), Vector3.new(0, 3.1, -1.8 + index * 1.0), accent, feature == "crystal" and neon or Enum.Material.SmoothPlastic)
        end
    elseif feature == "mane" then
        ball(model, "mane_geom", Vector3.new(2.6, 2.4, 2.0), Vector3.new(0, 2.7, 2.2), accent)
    elseif feature == "mask" or feature == "stripe" then
        part(model, "marking_geom", Vector3.new(1.9, 0.18, 1.0), Vector3.new(0, 3.0, 3.65), accent, neon)
    elseif feature == "wings" then
        part(model, "wing_left", Vector3.new(3.6, 0.35, 3.0), Vector3.new(-2.6, 2.8, -0.2), accent, neon)
        part(model, "wing_right", Vector3.new(3.6, 0.35, 3.0), Vector3.new(2.6, 2.8, -0.2), accent, neon)
    elseif feature == "glow" then
        ball(model, "glow_core", Vector3.new(1.0, 1.0, 1.0), Vector3.new(0, 3.1, 0), accent, neon)
    elseif feature == "crest" or feature == "flame" or feature == "crown" then
        for index = -1, 1 do
            part(model, "crest_" .. tostring(index), Vector3.new(0.35, 1.1 + math.abs(index) * 0.25, 0.35), Vector3.new(index * 0.55, 4.0, 2.5), accent, neon)
        end
    elseif feature == "fan" then
        for index = -2, 2 do
            part(model, "tail_fan_" .. tostring(index), Vector3.new(0.45, 2.0, 1.2), Vector3.new(index * 0.7, 2.5 + math.abs(index) * 0.1, -2.5), accent, neon)
        end
    elseif feature == "hood" then
        part(model, "hood_left", Vector3.new(1.0, 1.6, 0.35), Vector3.new(-1.2, 1.8, 2.2), accent)
        part(model, "hood_right", Vector3.new(1.0, 1.6, 0.35), Vector3.new(1.2, 1.8, 2.2), accent)
    end
end

local function addRarityAccents(model, rarity, accent)
    local rarityInfo = Config.Rarities[rarity]
    local rank = rarityInfo and tonumber(rarityInfo.Rank) or 1
    if rank >= 4 then
        part(model, "rarity_accent_left", Vector3.new(0.25, 1.1, 1.6), Vector3.new(-1.7, 2.7, 0), accent, Enum.Material.Neon)
        part(model, "rarity_accent_right", Vector3.new(0.25, 1.1, 1.6), Vector3.new(1.7, 2.7, 0), accent, Enum.Material.Neon)
    end
    if rank >= 6 then
        ball(model, "rarity_core", Vector3.new(0.7, 0.7, 0.7), Vector3.new(0, 3.8, 0), accent, Enum.Material.Neon)
    end
    if rank >= 8 then
        for index = -1, 1 do
            part(model, "ancient_crown_" .. tostring(index), Vector3.new(0.3, 1.6, 0.3), Vector3.new(index * 0.8, 5.0, 0.4), accent, Enum.Material.Neon)
        end
    end
end

local function buildPlaceholder(species, info)
    local visual = info.Visual
    if type(visual) ~= "table" then return nil end

    local model = Instance.new("Model")
    model.Name = species

    local color = visual.Color or Color3.fromRGB(130, 130, 130)
    local accent = visual.Accent or color
    local builder = builders[visual.Archetype] or quadruped
    local root = builder(model, color, accent)
    model.PrimaryPart = root

    addFeature(model, visual.Feature, accent)
    addRarityAccents(model, info.Rarity, accent)

    local scale = math.clamp(tonumber(visual.Scale) or 1, 0.45, 2.5)
    model:ScaleTo(scale)
    model:SetAttribute("PlaceholderModel", true)
    return model
end

function Factory:CanCreate(species)
    local info = Config.Pets[species]
    if not info then return false end

    local templates = monsterTemplates()
    local templateName = info.TemplateSpecies or species
    if templates and templates:FindFirstChild(templateName) then
        return true
    end

    return type(info.Visual) == "table"
end

function Factory:Create(species)
    local info = Config.Pets[species]
    if not info then return nil end

    local templates = monsterTemplates()
    local templateName = info.TemplateSpecies or species
    local template = templates and templates:FindFirstChild(templateName)
    local model

    if template and template:IsA("Model") then
        model = template:Clone()
        model.Name = species
    else
        model = buildPlaceholder(species, info)
    end

    if model then
        model:SetAttribute("Species", species)
        model:SetAttribute("Rarity", info.Rarity)
        model:SetAttribute("AnimationSpecies", info.AnimationSpecies or species)
        model:SetAttribute("SpawnMode", info.SpawnMode)
    end

    return model
end

return Factory
