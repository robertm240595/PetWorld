local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Root = ReplicatedStorage:WaitForChild("WildernessPets")
local LassoVisuals = require(Root.Shared.LassoVisuals)

local VisualService = {}

-- All lasso tiers share one compact silhouette in-hand. Generated meshes can
-- arrive on different axes and at very different scales, so normalize the longest
-- dimension and rotate that dominant axis vertically before mounting.
local HANDHELD_LONGEST_AXIS = 1.22

local function modelsFolder()
    return Root:FindFirstChild("LassoModels")
end

local function preparePart(part)
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.Massless = true
    part.CastShadow = true
end

local function normalizeHandheldScale(model)
    local size = model:GetExtentsSize()
    if size.X <= 0 or size.Y <= 0 or size.Z <= 0 then
        return
    end

    local dominantAxis = "Y"
    local longest = size.Y
    if size.X > longest then
        dominantAxis = "X"
        longest = size.X
    end
    if size.Z > longest then
        dominantAxis = "Z"
        longest = size.Z
    end

    local currentScale = model:GetScale()
    local scaleFactor = HANDHELD_LONGEST_AXIS / math.max(longest, 0.001)
    model:ScaleTo(math.max(0.01, currentScale * scaleFactor))

    -- The premium source coil is intentionally compact but can arrive too narrow.
    -- Widen only the horizontal silhouette so the rope bundle reads clearly in
    -- third person while preserving its hand-sized height and rope thickness.
    if dominantAxis == "Y" then
        local boxCFrame, scaledSize = model:GetBoundingBox()
        local desiredRatio = 0.48
        local currentRatio = scaledSize.X / math.max(scaledSize.Y, 0.001)
        if currentRatio < desiredRatio then
            local widthFactor = math.min(1.6, desiredRatio / math.max(currentRatio, 0.001))
            for _, descendant in ipairs(model:GetDescendants()) do
                if descendant:IsA("BasePart") then
                    local relative = boxCFrame:ToObjectSpace(descendant.CFrame)
                    local position = relative.Position
                    descendant.Size = Vector3.new(
                        descendant.Size.X * widthFactor,
                        descendant.Size.Y,
                        descendant.Size.Z
                    )
                    descendant.CFrame = boxCFrame
                        * CFrame.new(position.X * widthFactor, position.Y, position.Z)
                        * relative.Rotation
                end
            end
        end
    end

    model:SetAttribute("NormalizedHandheldScale", model:GetScale())
    model:SetAttribute("HandheldDominantAxis", dominantAxis)
end

local function dominantAxisRotation(model)
    local axis = model:GetAttribute("HandheldDominantAxis")
    if axis == "X" then
        return CFrame.Angles(0, 0, math.rad(90))
    elseif axis == "Z" then
        return CFrame.Angles(math.rad(90), 0, 0)
    end
    return CFrame.identity
end

local function sharedLoopParts(model)
    local parts = {}
    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BasePart")
            and string.find(string.lower(descendant.Name), "rope_loop_", 1, true) then
            table.insert(parts, descendant)
        end
    end
    table.sort(parts, function(a, b)
        return a.Name < b.Name
    end)
    return parts
end

local function topPointForLoop(part)
    -- The shared oval mesh is authored with its long direction on local Z.
    -- Pick whichever Z endpoint is physically highest after mounting so this
    -- remains correct even when the loop has a small authored tilt.
    local negativeLocal = Vector3.new(0, 0, -part.Size.Z * 0.5)
    local positiveLocal = Vector3.new(0, 0, part.Size.Z * 0.5)
    local negativeWorld = part.CFrame:PointToWorldSpace(negativeLocal)
    local positiveWorld = part.CFrame:PointToWorldSpace(positiveLocal)

    if negativeWorld.Y >= positiveWorld.Y then
        return negativeWorld, negativeLocal
    end
    return positiveWorld, positiveLocal
end

local function alignSharedGrip(model, mountCFrame)
    -- Start from the same authored orientation that produced the approved oval,
    -- then translate the actual top of the outer rope loop into the player's
    -- palm. This replaces the old bounding-box-center placement that put the
    -- hand in the empty middle of the hoop.
    model:PivotTo(mountCFrame * CFrame.Angles(math.rad(90), 0, 0))

    local primary = model.PrimaryPart
        or model:FindFirstChild("rope_loop_01_geom", true)
        or model:FindFirstChildWhichIsA("BasePart", true)
    if not primary or not primary:IsA("BasePart") then
        return
    end

    local topWorld = topPointForLoop(primary)
    local translation = mountCFrame.Position - topWorld
    model:PivotTo(CFrame.new(translation) * model:GetPivot())
end

local function mountSharedSecondaryMotion(model, anchor, mountCFrame)
    alignSharedGrip(model, mountCFrame)

    local gripAnchor = Instance.new("Part")
    gripAnchor.Name = "LassoGripAnchor"
    gripAnchor.Size = Vector3.new(0.12, 0.12, 0.12)
    gripAnchor.Transparency = 1
    gripAnchor.CastShadow = false
    gripAnchor.Anchored = false
    gripAnchor.CanCollide = false
    gripAnchor.CanTouch = false
    gripAnchor.CanQuery = false
    gripAnchor.Massless = true
    gripAnchor.CFrame = mountCFrame
    gripAnchor.Parent = model

    local gripWeld = Instance.new("WeldConstraint")
    gripWeld.Name = "LassoGripWeld"
    gripWeld.Part0 = anchor
    gripWeld.Part1 = gripAnchor
    gripWeld.Parent = gripAnchor

    local authoredTilts = {5, -3, 2, -2.5, 1}
    local loops = sharedLoopParts(model)
    for index, part in ipairs(loops) do
        local topWorld, topLocal = topPointForLoop(part)

        local handAttachment = Instance.new("Attachment")
        handAttachment.Name = string.format("LassoGripAttachment_%02d", index)
        handAttachment.CFrame = gripAnchor.CFrame:ToObjectSpace(CFrame.new(topWorld))
        handAttachment.Parent = gripAnchor

        local ropeAttachment = Instance.new("Attachment")
        ropeAttachment.Name = "LassoRopeTopAttachment"
        ropeAttachment.CFrame = CFrame.new(topLocal)
        ropeAttachment.Parent = part

        -- Motor6D keeps the rope cosmetic and stable while allowing the client
        -- secondary-motion controller to pose each loop independently. Unlike
        -- raw rigid-body constraints this cannot tangle, explode or influence
        -- the character's movement.
        local joint = Instance.new("Motor6D")
        joint.Name = "LassoSecondaryJoint"
        joint.Part0 = gripAnchor
        joint.Part1 = part
        joint.C0 = gripAnchor.CFrame:ToObjectSpace(part.CFrame)
        joint.C1 = CFrame.identity
        joint:SetAttribute("LoopIndex", index)
        joint:SetAttribute("AuthoredTiltDegrees", authoredTilts[index] or 0)
        joint.Parent = gripAnchor

        part.Anchored = false
        part.Massless = true
    end

    -- Any future non-loop decorative pieces stay rigidly attached to the grip;
    -- only the rope loops receive procedural loose motion.
    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BasePart")
            and descendant ~= gripAnchor
            and not string.find(string.lower(descendant.Name), "rope_loop_", 1, true) then
            local weld = Instance.new("WeldConstraint")
            weld.Name = "LassoVisualWeld"
            weld.Part0 = gripAnchor
            weld.Part1 = descendant
            weld.Parent = descendant
            descendant.Anchored = false
        end
    end

    model:SetAttribute("SecondaryMotionEnabled", true)
    model:SetAttribute("SecondaryMotionMode", "ProceduralGravity")
    return model
end

function VisualService:Clone(tierName, skinId)
    local folder = modelsFolder()
    -- The equipped/held lasso always uses one shared coil geometry. Tier identity
    -- comes entirely from LassoVisuals (colour, material, texture treatment,
    -- glow and particles). The legacy tier models remain available to the cast
    -- effect so the approved rope-to-pet visual is not disturbed.
    local template = folder and (
        folder:FindFirstChild("Shared Lasso Coil")
        or folder:FindFirstChild(tierName)
    )
    if not template or not template:IsA("Model") then
        return nil
    end

    local model = template:Clone()
    if template.Name == "Shared Lasso Coil" then
        model:SetAttribute("SharedHeldLasso", true)
    end
    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") then
            preparePart(descendant)
        end
    end

    normalizeHandheldScale(model)
    LassoVisuals.Apply(model, tierName, skinId)
    model:SetAttribute("LassoTier", tierName)
    model:SetAttribute("LassoSkin", skinId or "")
    return model
end

function VisualService:Mount(parent, anchor, tierName, skinId, name, targetCFrame)
    if not anchor or not anchor:IsA("BasePart") then
        return nil
    end

    local model = self:Clone(tierName, skinId)
    if not model then
        return nil
    end

    model.Name = name or "LassoVisual"
    model.Parent = parent

    local mountCFrame = targetCFrame or anchor.CFrame

    if model:GetAttribute("SharedHeldLasso") == true then
        return mountSharedSecondaryMotion(model, anchor, mountCFrame)
    end

    local mountRotation = dominantAxisRotation(model)
    model:PivotTo(mountCFrame * mountRotation)

    local boxCFrame, boxSize = model:GetBoundingBox()
    local desiredCenter = mountCFrame:PointToWorldSpace(
        Vector3.new(0, -boxSize.Y * 0.46, 0.035)
    )
    local translation = desiredCenter - boxCFrame.Position
    model:PivotTo(CFrame.new(translation) * model:GetPivot())

    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") then
            local weld = Instance.new("WeldConstraint")
            weld.Name = "LassoVisualWeld"
            weld.Part0 = anchor
            weld.Part1 = descendant
            weld.Parent = descendant
            descendant.Anchored = false
        end
    end

    return model
end

function VisualService:AttachTool(player, tool)
    if not tool or not tool:IsA("Tool") then
        return nil
    end

    local old = tool:FindFirstChild("LassoVisual")
    if old then
        old:Destroy()
    end

    local handle = tool:FindFirstChild("Handle")
    if not handle or not handle:IsA("BasePart") then
        return nil
    end

    local tierName = player:GetAttribute("EquippedLassoName")
    if type(tierName) ~= "string" or tierName == "" then
        tierName = "Rough Rope"
    end

    local skinId = player:GetAttribute("EquippedLassoSkin")
    if type(skinId) ~= "string" then
        skinId = ""
    end

    local character = player.Character
    local visibleHand = character and (
        character:FindFirstChild("LeftHand")
        or character:FindFirstChild("Left Arm")
    )

    if character and (not visibleHand or not visibleHand:IsA("BasePart")) then
        visibleHand = character:WaitForChild("LeftHand", 0.75)
            or character:FindFirstChild("Left Arm")
    end

    local anchor = (visibleHand and visibleHand:IsA("BasePart")) and visibleHand or handle
    local gripCFrame = anchor.CFrame
    if anchor.Name == "Left Arm" then
        gripCFrame = anchor.CFrame * CFrame.new(0, -0.86, -0.02)
    elseif anchor.Name == "LeftHand" then
        gripCFrame = anchor.CFrame * CFrame.new(0, -0.025, -0.025)
    end
    gripCFrame *= CFrame.Angles(0, math.rad(-5), math.rad(4))

    local model = self:Mount(tool, anchor, tierName, skinId, "LassoVisual", gripCFrame)
    if model then
        handle.Transparency = 1
        handle.CastShadow = false
    else
        handle.Transparency = 0
        handle.CastShadow = true
    end

    return model
end

return VisualService
