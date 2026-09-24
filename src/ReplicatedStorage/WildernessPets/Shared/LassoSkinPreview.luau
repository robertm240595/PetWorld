local LassoVisuals = require(script.Parent.LassoVisuals)

local Preview = {}

function Preview.Make(parent, template, tierName, skinId, owned)
    if not template then return nil end

    local viewport = Instance.new("ViewportFrame")
    viewport.Name = "SkinPreview"
    viewport.Position = UDim2.fromOffset(6, 6)
    viewport.Size = UDim2.fromOffset(90, 90)
    viewport.BackgroundColor3 = Color3.fromRGB(27, 30, 36)
    viewport.BorderSizePixel = 0
    viewport.Ambient = Color3.fromRGB(175, 175, 185)
    viewport.LightColor = Color3.fromRGB(255, 240, 220)
    viewport.LightDirection = Vector3.new(-1, -1, -1)
    viewport.ZIndex = 22
    viewport.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = viewport

    local world = Instance.new("WorldModel")
    world.Parent = viewport

    local model = template:Clone()
    model.Parent = world
    LassoVisuals.Apply(model, tierName, skinId)

    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored = true
            part.CanCollide = false
            if owned == false then
                part.Transparency = math.max(part.Transparency, 0.42)
            end
        end
    end

    model:PivotTo(CFrame.Angles(math.rad(-8), math.rad(-32), math.rad(8)))
    local size = model:GetExtentsSize()
    local distance = math.max(3.5, size.Magnitude * 0.95)

    local camera = Instance.new("Camera")
    camera.FieldOfView = 38
    camera.CFrame = CFrame.lookAt(
        Vector3.new(distance, distance * 0.45, distance),
        Vector3.zero
    )
    camera.Parent = viewport
    viewport.CurrentCamera = camera

    return viewport
end

return Preview
