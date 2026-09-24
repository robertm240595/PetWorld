local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Cosmetic secondary motion for the held lasso coil.
--
-- The visible rope loops are Motor6D-connected to a hidden grip anchor welded
-- to the player's left hand. This controller poses those motors locally so the
-- top stays fixed in the palm while the bundle hangs toward world gravity,
-- lags behind movement and gives a small damped bounce when the player stops.
--
-- Keeping this cosmetic avoids raw-physics tangling and cannot influence
-- character movement or capture mechanics.

local VELOCITY_TO_LAG = 0.016
local HAND_SWING_TO_LAG = 0.0055
local MAX_SIDE_LAG = 0.27
local MAX_FORWARD_LAG = 0.31
local MAX_HAND_SWING_LAG = 0.10
local SPRING_STIFFNESS = 32
local SPRING_DAMPING = 6.2

local states = setmetatable({}, {__mode = "k"})

local function clampDt(dt)
    return math.clamp(dt, 1 / 240, 1 / 30)
end

local function springAxis(position, velocity, target, dt)
    local acceleration = ((target - position) * SPRING_STIFFNESS)
        - (velocity * SPRING_DAMPING)
    velocity += acceleration * dt
    position += velocity * dt
    return position, velocity
end

local function findVisual(character)
    local tool = character:FindFirstChild("Lasso")
    if tool then
        local visual = tool:FindFirstChild("LassoVisual")
        if visual and visual:GetAttribute("SecondaryMotionMode") == "ProceduralGravity" then
            return visual
        end
    end

    local passive = character:FindFirstChild("EquippedLassoDisplay")
    if passive and passive:GetAttribute("SecondaryMotionMode") == "ProceduralGravity" then
        return passive
    end

    return nil
end

local function getState(visual)
    local state = states[visual]
    if state then
        return state
    end

    state = {
        lagX = 0,
        lagZ = 0,
        velocityX = 0,
        velocityZ = 0,
        lastGripPosition = nil,
    }
    states[visual] = state
    return state
end

local function horizontalRight(root)
    local right = Vector3.new(root.CFrame.RightVector.X, 0, root.CFrame.RightVector.Z)
    if right.Magnitude < 0.001 then
        return Vector3.xAxis
    end
    return right.Unit
end

local function updateVisual(character, visual, dt)
    local root = character:FindFirstChild("HumanoidRootPart")
    local grip = visual:FindFirstChild("LassoGripAnchor", true)
    if not root or not grip or not grip:IsA("BasePart") then
        return
    end

    local state = getState(visual)
    local localVelocity = root.CFrame:VectorToObjectSpace(root.AssemblyLinearVelocity)

    -- Add the hand's motion relative to the character root. This captures the
    -- arm swing of a run, so the coil visibly lags behind the wrist instead of
    -- behaving like a perfectly rigid prop.
    local gripVelocity = Vector3.zero
    if state.lastGripPosition then
        gripVelocity = (grip.Position - state.lastGripPosition) / dt
    end
    state.lastGripPosition = grip.Position

    local relativeGripVelocity = gripVelocity - root.AssemblyLinearVelocity
    local localGripVelocity = root.CFrame:VectorToObjectSpace(relativeGripVelocity)

    local handLagX = math.clamp(
        -localGripVelocity.X * HAND_SWING_TO_LAG,
        -MAX_HAND_SWING_LAG,
        MAX_HAND_SWING_LAG
    )
    local handLagZ = math.clamp(
        -localGripVelocity.Z * HAND_SWING_TO_LAG,
        -MAX_HAND_SWING_LAG,
        MAX_HAND_SWING_LAG
    )

    local targetX = math.clamp(
        (-localVelocity.X * VELOCITY_TO_LAG) + handLagX,
        -MAX_SIDE_LAG,
        MAX_SIDE_LAG
    )
    local targetZ = math.clamp(
        (-localVelocity.Z * VELOCITY_TO_LAG) + handLagZ,
        -MAX_FORWARD_LAG,
        MAX_FORWARD_LAG
    )

    state.lagX, state.velocityX = springAxis(
        state.lagX,
        state.velocityX,
        targetX,
        dt
    )
    state.lagZ, state.velocityZ = springAxis(
        state.lagZ,
        state.velocityZ,
        targetZ,
        dt
    )

    local baseRight = horizontalRight(root)

    for _, child in ipairs(grip:GetChildren()) do
        if child:IsA("Motor6D") and child.Name == "LassoSecondaryJoint" then
            local loop = child.Part1
            local index = tonumber(child:GetAttribute("LoopIndex")) or 3
            local tilt = math.rad(
                tonumber(child:GetAttribute("AuthoredTiltDegrees")) or 0
            )
            if loop and loop:IsA("BasePart") then
                local gripAttachment = grip:FindFirstChild(
                    string.format("LassoGripAttachment_%02d", index)
                )
                local ropeAttachment = loop:FindFirstChild("LassoRopeTopAttachment")

                if gripAttachment and ropeAttachment
                    and gripAttachment:IsA("Attachment")
                    and ropeAttachment:IsA("Attachment") then

                    -- Tiny per-loop variation gives the bundle a soft/flaccid
                    -- read without allowing the loops to separate or tangle.
                    local flex = 1 + ((index - 3) * 0.025)
                    local lagLocal = Vector3.new(
                        state.lagX * flex,
                        0,
                        state.lagZ * flex
                    )
                    local lagWorld = root.CFrame:VectorToWorldSpace(lagLocal)
                    lagWorld = Vector3.new(lagWorld.X, 0, lagWorld.Z)

                    local down = (Vector3.new(0, -1, 0) + lagWorld).Unit

                    local xAxis = baseRight - (down * baseRight:Dot(down))
                    if xAxis.Magnitude < 0.001 then
                        xAxis = Vector3.xAxis
                    else
                        xAxis = xAxis.Unit
                    end
                    local yAxis = down:Cross(xAxis).Unit

                    -- Preserve each loop's subtle authored offset around the
                    -- gravity axis while all loops share the same soft motion.
                    local cosTilt = math.cos(tilt)
                    local sinTilt = math.sin(tilt)
                    local tiltedX = (xAxis * cosTilt) + (yAxis * sinTilt)
                    local tiltedY = (-xAxis * sinTilt) + (yAxis * cosTilt)

                    local rotation = CFrame.fromMatrix(
                        Vector3.zero,
                        tiltedX,
                        tiltedY,
                        down
                    )

                    local targetWorld = CFrame.new(gripAttachment.WorldPosition)
                        * rotation
                        * CFrame.new(-ropeAttachment.Position)

                    child.Transform = child.C0:Inverse()
                        * child.Part0.CFrame:Inverse()
                        * targetWorld
                        * child.C1
                end
            end
        end
    end
end

RunService.RenderStepped:Connect(function(dt)
    dt = clampDt(dt)

    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        if character then
            local visual = findVisual(character)
            if visual then
                updateVisual(character, visual, dt)
            end
        end
    end
end)
