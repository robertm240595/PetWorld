local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Root = ReplicatedStorage:WaitForChild("WildernessPets")
local Config = require(Root.Shared.Config)
local SkinConfig = require(Root.Shared.LassoSkinConfig)

local LassoVisuals = {}

-- Albedo from the premium master rope. Beam UV wrapping lets the thrown loop
-- retain visible twisted-rope detail instead of reading as a flat coloured line.
local ROPE_BEAM_TEXTURE = "rbxassetid://127914268489051"

local MATERIALS = {
    Fabric = Enum.Material.Fabric,
    Metal = Enum.Material.Metal,
    Neon = Enum.Material.Neon,
    Wood = Enum.Material.Wood,
    Ice = Enum.Material.Ice,
    Glass = Enum.Material.Glass,
    SmoothPlastic = Enum.Material.SmoothPlastic,
    Plastic = Enum.Material.Plastic,
}

local TIER_STYLES = {
    ["Rough Rope"] = {
        RopeColor = Color3.fromRGB(156, 108, 61),
        AccentColor = Color3.fromRGB(190, 139, 82),
        Material = Enum.Material.Fabric,
        Reflectance = 0,
        Glow = 0,
        BeamLight = 0.04,
        BeamWidth = 0.145,
        TextureColor = Color3.fromRGB(150, 101, 56),
        TextureTransparency = 0.24,
    },
    ["Hunter's Lasso"] = {
        RopeColor = Color3.fromRGB(112, 74, 44),
        AccentColor = Color3.fromRGB(153, 101, 58),
        Material = Enum.Material.Fabric,
        Reflectance = 0,
        Glow = 0,
        BeamLight = 0.05,
        BeamWidth = 0.14,
        TextureColor = Color3.fromRGB(103, 66, 38),
        TextureTransparency = 0.20,
    },
    ["Iron Lasso"] = {
        RopeColor = Color3.fromRGB(100, 104, 110),
        AccentColor = Color3.fromRGB(143, 148, 154),
        Material = Enum.Material.Fabric,
        Reflectance = 0.03,
        Glow = 0,
        BeamLight = 0.07,
        BeamWidth = 0.14,
        TextureColor = Color3.fromRGB(91, 95, 101),
        TextureTransparency = 0.16,
    },
    ["Steel Lasso"] = {
        RopeColor = Color3.fromRGB(211, 220, 229),
        AccentColor = Color3.fromRGB(249, 252, 255),
        Material = Enum.Material.Metal,
        Reflectance = 0.34,
        Glow = 0,
        BeamLight = 0.20,
        BeamWidth = 0.13,
        BeamHighlight = Color3.fromRGB(250, 252, 255),
        TextureColor = Color3.fromRGB(222, 229, 235),
        TextureTransparency = 0.12,
    },
    ["Mystic Lasso"] = {
        RopeColor = Color3.fromRGB(62, 27, 108),
        AccentColor = Color3.fromRGB(168, 86, 220),
        Material = Enum.Material.Fabric,
        Reflectance = 0,
        Glow = 0,
        BeamLight = 0.76,
        BeamWidth = 0.13,
        BeamHighlight = Color3.fromRGB(228, 164, 255),
        TextureColor = Color3.fromRGB(83, 38, 136),
        TextureTransparency = 0.12,
        HeldParticleRate = 14,
        HeldParticleLightEmission = 0.25,
    },
    ["Ancient Lasso"] = {
        RopeColor = Color3.fromRGB(142, 91, 18),
        AccentColor = Color3.fromRGB(229, 174, 55),
        Material = Enum.Material.Metal,
        Reflectance = 0.14,
        Glow = 1.05,
        BeamLight = 0.94,
        BeamWidth = 0.135,
        BeamHighlight = Color3.fromRGB(255, 218, 112),
        ParticleRate = 10,
        HeldParticleRate = 14,
        HeldParticleLightEmission = 0.85,
        HideTexture = true,
    },
}

local function classify(part)
    local name = string.lower(part.Name)
    if string.find(name, "rope", 1, true)
        or string.find(name, "cord", 1, true)
        or string.find(name, "coil", 1, true)
        or string.find(name, "tail", 1, true)
        or string.find(name, "loop", 1, true)
        or string.find(name, "tip", 1, true)
        or string.find(name, "end", 1, true) then
        return "Rope"
    end
    return "Primary"
end

local function cloneStyle(style)
    local result = {}
    for key, value in pairs(style or {}) do
        result[key] = value
    end
    return result
end

function LassoVisuals.GetStyle(tierName, skinId)
    local tier = Config.Lassos[tierName] or Config.Lassos["Rough Rope"] or {}
    local skin = SkinConfig.Get(skinId)

    if skin then
        local material = MATERIALS[skin.Material] or Enum.Material.SmoothPlastic
        return {
            PrimaryColor = skin.PrimaryColor,
            AccentColor = skin.AccentColor,
            RopeColor = skin.RopeColor,
            Material = material,
            Reflectance = material == Enum.Material.Metal and 0.12 or 0,
            Glow = math.max(0, tonumber(skin.Glow) or 0),
            BeamLight = math.max(0.06, tonumber(skin.Glow) or 0),
            BeamWidth = 0.135,
            BeamTexture = ROPE_BEAM_TEXTURE,
        }
    end

    local preset = cloneStyle(TIER_STYLES[tierName] or TIER_STYLES["Rough Rope"])
    local base = tier.DisplayColor
    if typeof(base) ~= "Color3" then
        base = preset.RopeColor or Color3.fromRGB(126, 88, 50)
    end

    preset.RopeColor = preset.RopeColor or base
    preset.PrimaryColor = preset.PrimaryColor or preset.RopeColor
    preset.AccentColor = preset.AccentColor or base:Lerp(Color3.new(1, 1, 1), 0.25)
    preset.Material = preset.Material or MATERIALS[tostring(tier.DisplayMaterial or "Fabric")] or Enum.Material.Fabric
    preset.Reflectance = tonumber(preset.Reflectance) or 0
    preset.Glow = math.max(0, tonumber(preset.Glow) or 0)
    preset.BeamLight = math.max(0, tonumber(preset.BeamLight) or 0.04)
    preset.BeamWidth = math.max(0.05, tonumber(preset.BeamWidth) or 0.135)
    preset.BeamTexture = preset.BeamTexture or ROPE_BEAM_TEXTURE
    return preset
end

local function clearEffects(part)
    for _, child in ipairs(part:GetChildren()) do
        if child.Name == "LassoCosmeticGlow"
            or child.Name == "AncientLassoMotes"
            or child.Name == "LassoTierMotes" then
            child:Destroy()
        end
    end
end

local function addHeldParticles(part, style, particleRate)
    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "LassoTierMotes"
    emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    emitter.Color = ColorSequence.new(style.AccentColor)
    emitter.LightEmission = math.clamp(
        tonumber(style.HeldParticleLightEmission) or 0.6,
        0,
        1
    )
    emitter.Rate = particleRate
    emitter.Lifetime = NumberRange.new(0.35, 0.75)
    emitter.Speed = NumberRange.new(0.15, 0.6)
    emitter.SpreadAngle = Vector2.new(180, 180)
    emitter.Drag = 2
    emitter.Rotation = NumberRange.new(0, 360)
    emitter.RotSpeed = NumberRange.new(-35, 35)
    emitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.10),
        NumberSequenceKeypoint.new(0.45, 0.055),
        NumberSequenceKeypoint.new(1, 0),
    })
    emitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.2),
        NumberSequenceKeypoint.new(0.65, 0.42),
        NumberSequenceKeypoint.new(1, 1),
    })
    emitter.Parent = part
end

function LassoVisuals.Apply(model, tierName, skinId)
    if not model then
        return
    end

    local style = LassoVisuals.GetStyle(tierName, skinId)
    local lightCount = 0
    local particleAdded = false

    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") then
            clearEffects(descendant)

            local role = classify(descendant)

            -- The shared held coil has real twisted/braided geometry, so it does
            -- not need the generated albedo baked into the source MeshPart. That
            -- albedo was washing every tier toward white and hiding the intended
            -- brown/grey/purple/gold finishes. Clear it only on the held clone so
            -- tier colour and Roblox material define the visible surface.
            if model:GetAttribute("SharedHeldLasso") == true
                and descendant:IsA("MeshPart") then
                descendant.TextureID = ""
            end

            descendant.Color = role == "Rope" and style.RopeColor or style.PrimaryColor
            descendant.Material = style.Material
            descendant.Reflectance = style.Reflectance

            -- The held model has one shared geometry and shared surface-detail
            -- texture. Re-tint that texture per tier; Ancient deliberately hides
            -- it so the rope reads as one solid luminous gold material.
            for _, child in ipairs(descendant:GetChildren()) do
                if child:IsA("Texture") and child.Name == "RopeSurfaceTexture" then
                    child.Color3 = style.TextureColor or style.RopeColor
                    child.Transparency = style.HideTexture == true
                        and 1
                        or math.clamp(tonumber(style.TextureTransparency) or 0.18, 0, 1)
                end
            end

            if style.Glow > 0 and lightCount < 2 then
                local light = Instance.new("PointLight")
                light.Name = "LassoCosmeticGlow"
                light.Color = style.AccentColor
                light.Brightness = style.Glow
                light.Range = 4.5 + style.Glow * 3
                light.Shadows = false
                light.Parent = descendant
                lightCount += 1
            end

            if not skinId or skinId == "" then
                local partName = string.lower(descendant.Name)
                local heldParticleRate = tonumber(
                    style.HeldParticleRate or style.ParticleRate
                ) or 0
                if heldParticleRate > 0 and not particleAdded
                    and (
                        string.find(partName, "coil", 1, true)
                        or string.find(partName, "loop", 1, true)
                    ) then
                    addHeldParticles(descendant, style, heldParticleRate)
                    particleAdded = true
                end
            end
        end
    end
end

function LassoVisuals.FindRopeEnd(model)
    if not model then
        return nil
    end

    local fallback
    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") then
            fallback = fallback or descendant
            local name = string.lower(descendant.Name)
            if string.find(name, "rope", 1, true)
                and (string.find(name, "end", 1, true) or string.find(name, "tip", 1, true)) then
                return descendant
            end
        end
    end

    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") then
            local name = string.lower(descendant.Name)
            if string.find(name, "rope", 1, true)
                or string.find(name, "coil", 1, true)
                or string.find(name, "tail", 1, true) then
                return descendant
            end
        end
    end
    return fallback
end

return LassoVisuals
