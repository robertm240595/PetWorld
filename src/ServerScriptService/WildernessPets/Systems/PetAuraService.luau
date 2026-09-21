local Root = game.ReplicatedStorage:WaitForChild("WildernessPets")
local MasteryConfig = require(Root.Shared.MasteryConfig)

local Service = {}

local function clear(model)
    for _, child in ipairs(model:GetDescendants()) do
        if child.Name == "MasteryAuraAttachment" or child.Name == "MasteryAuraLight" then
            child:Destroy()
        end
    end
    local highlight = model:FindFirstChild("MasteryAuraHighlight")
    if highlight then highlight:Destroy() end
end

function Service:Apply(model, pet)
    if not model or not model.Parent or type(pet) ~= "table" then return end
    clear(model)
    local auraId = tostring(pet.SelectedAura or "None")
    if auraId == "None" or not MasteryConfig.IsUnlocked(pet.Level, auraId) then return end
    local aura = MasteryConfig.ById[auraId]
    if not aura then return end

    local root = model:FindFirstChild("body_geom", true) or model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
    if not root or not root:IsA("BasePart") then return end

    local highlight = Instance.new("Highlight")
    highlight.Name = "MasteryAuraHighlight"
    highlight.FillColor = aura.Color
    highlight.OutlineColor = aura.Color
    highlight.FillTransparency = 0.88
    highlight.OutlineTransparency = 0.45
    highlight.DepthMode = Enum.HighlightDepthMode.Occluded
    highlight.Parent = model

    local attachment = Instance.new("Attachment")
    attachment.Name = "MasteryAuraAttachment"
    attachment.Parent = root

    local particles = Instance.new("ParticleEmitter")
    particles.Name = "MasteryAuraParticles"
    particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    particles.Color = ColorSequence.new(aura.Color)
    particles.LightEmission = 0.7
    particles.Rate = tonumber(aura.Rate) or 6
    particles.Lifetime = NumberRange.new(0.8, 1.5)
    particles.Speed = NumberRange.new(0.4, 1.2)
    particles.SpreadAngle = Vector2.new(180, 180)
    particles.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.18),
        NumberSequenceKeypoint.new(1, 0),
    })
    particles.Parent = attachment

    if (tonumber(aura.RequiredLevel) or 0) >= 50 then
        local light = Instance.new("PointLight")
        light.Name = "MasteryAuraLight"
        light.Color = aura.Color
        light.Range = 8
        light.Brightness = 0.45
        light.Parent = root
    end
end

return Service
