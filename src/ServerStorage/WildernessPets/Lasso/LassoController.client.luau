local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local tool = script.Parent

local Root = ReplicatedStorage:WaitForChild("WildernessPets")
local Remotes = Root:WaitForChild("Remotes")
local CaptureRemote = Remotes:WaitForChild("Capture")

local MAX_CLIENT_RANGE = 42
local COOLDOWN = 1.35

local mouse
local busy = false
local castSerial = 0
local tugSerial = 0
local lastCastMotionAt = -math.huge
local toolAnimationConnection

local function findAnimationJoint(character, ...)
    local wanted = {...}
    local motorFallback

    for _, descendant in ipairs(character:GetDescendants()) do
        if descendant:IsA("AnimationConstraint") or descendant:IsA("Motor6D") then
            for _, name in ipairs(wanted) do
                if descendant.Name == name then
                    if descendant:IsA("AnimationConstraint") then
                        return descendant
                    end
                    motorFallback = motorFallback or descendant
                end
            end
        end
    end

    return motorFallback
end

local function smoothstep(t)
    t = math.clamp(t, 0, 1)
    return t * t * (3 - 2 * t)
end

local function phaseCFrame(t, a, b, fromCF, toCF)
    if t <= a then
        return fromCF
    end
    if t >= b then
        return toCF
    end
    return fromCF:Lerp(toCF, smoothstep((t - a) / (b - a)))
end

local function layerTransform(joint, offset)
    if joint and joint.Parent then
        -- Animator writes Transform before PreSimulation. Multiplying our
        -- procedural offset here layers the lasso motion on top of walk/idle
        -- animation and works for both AnimationConstraint and Motor6D rigs.
        joint.Transform = offset * joint.Transform
    end
end

local function playCastMotion()
    local character = player.Character
    if not character then
        return
    end

    local rightShoulder = findAnimationJoint(character, "RightShoulder", "Right Shoulder")
    if not rightShoulder then
        return
    end

    local rightElbow = findAnimationJoint(character, "RightElbow", "Right Elbow")
    local waist = findAnimationJoint(character, "Waist", "RootJoint", "Root Joint")

    lastCastMotionAt = os.clock()
    castSerial += 1
    local token = castSerial
    local started = os.clock()
    local duration = 0.74

    -- Calibrated against the Avatar Joint Upgrade R15 rig used by this game.
    -- Wind-up: hand high and wide. Release: high and forward. Follow-through:
    -- arm extends toward the target before smoothly returning to locomotion.
    local shoulderWindup = CFrame.Angles(math.rad(-30), 0, math.rad(70))
    local shoulderRelease = CFrame.Angles(math.rad(95), math.rad(-8), math.rad(18))
    local shoulderFollow = CFrame.Angles(math.rad(48), math.rad(8), math.rad(-12))

    local elbowWindup = CFrame.Angles(math.rad(16), 0, 0)
    local elbowRelease = CFrame.Angles(math.rad(5), 0, 0)

    local waistWindup = CFrame.Angles(math.rad(-3), math.rad(-16), math.rad(-3))
    local waistRelease = CFrame.Angles(math.rad(2), math.rad(12), math.rad(2))
    local waistFollow = CFrame.Angles(0, math.rad(6), 0)

    local connection
    connection = RunService.PreSimulation:Connect(function()
        if token ~= castSerial or not rightShoulder.Parent then
            connection:Disconnect()
            return
        end

        local t = math.clamp((os.clock() - started) / duration, 0, 1)

        local shoulder
        local elbow
        local torso

        if t < 0.32 then
            shoulder = phaseCFrame(t, 0, 0.32, CFrame.identity, shoulderWindup)
            elbow = phaseCFrame(t, 0, 0.32, CFrame.identity, elbowWindup)
            torso = phaseCFrame(t, 0, 0.32, CFrame.identity, waistWindup)
        elseif t < 0.52 then
            shoulder = phaseCFrame(t, 0.32, 0.52, shoulderWindup, shoulderRelease)
            elbow = phaseCFrame(t, 0.32, 0.52, elbowWindup, elbowRelease)
            torso = phaseCFrame(t, 0.32, 0.52, waistWindup, waistRelease)
        elseif t < 0.78 then
            shoulder = phaseCFrame(t, 0.52, 0.78, shoulderRelease, shoulderFollow)
            elbow = phaseCFrame(t, 0.52, 0.78, elbowRelease, CFrame.identity)
            torso = phaseCFrame(t, 0.52, 0.78, waistRelease, waistFollow)
        else
            shoulder = phaseCFrame(t, 0.78, 1, shoulderFollow, CFrame.identity)
            elbow = CFrame.identity
            torso = phaseCFrame(t, 0.78, 1, waistFollow, CFrame.identity)
        end

        layerTransform(rightShoulder, shoulder)
        if rightElbow then
            layerTransform(rightElbow, elbow)
        end
        if waist then
            layerTransform(waist, torso)
        end

        if t >= 1 then
            connection:Disconnect()
        end
    end)
end

local function playTightenMotion(strength)
    local character = player.Character
    if not character then
        return
    end

    local rightShoulder = findAnimationJoint(character, "RightShoulder", "Right Shoulder")
    if not rightShoulder then
        return
    end

    local rightElbow = findAnimationJoint(character, "RightElbow", "Right Elbow")
    local leftShoulder = findAnimationJoint(character, "LeftShoulder", "Left Shoulder")
    local waist = findAnimationJoint(character, "Waist", "RootJoint", "Root Joint")

    strength = math.clamp(tonumber(strength) or 1, 0.7, 1.35)
    tugSerial += 1
    local token = tugSerial
    local started = os.clock()
    local duration = 0.34

    local shoulderPull = CFrame.Angles(
        math.rad(-34 * strength),
        math.rad(10 * strength),
        math.rad(-28 * strength)
    )
    local elbowPull = CFrame.Angles(math.rad(36 * strength), 0, 0)
    local leftBrace = CFrame.Angles(
        math.rad(-8 * strength),
        math.rad(-5 * strength),
        math.rad(9 * strength)
    )
    local waistPull = CFrame.Angles(
        math.rad(-4 * strength),
        math.rad(-10 * strength),
        math.rad(-2 * strength)
    )

    local connection
    connection = RunService.PreSimulation:Connect(function()
        if token ~= tugSerial or not rightShoulder.Parent then
            connection:Disconnect()
            return
        end

        local t = math.clamp((os.clock() - started) / duration, 0, 1)
        local pulse = math.sin(t * math.pi)
        local eased = smoothstep(pulse)

        layerTransform(rightShoulder, CFrame.identity:Lerp(shoulderPull, eased))
        if rightElbow then
            layerTransform(rightElbow, CFrame.identity:Lerp(elbowPull, eased))
        end
        if leftShoulder then
            layerTransform(leftShoulder, CFrame.identity:Lerp(leftBrace, eased))
        end
        if waist then
            layerTransform(waist, CFrame.identity:Lerp(waistPull, eased))
        end

        if t >= 1 then
            connection:Disconnect()
        end
    end)
end

------------------------------------------------------------
-- Simple client feedback
------------------------------------------------------------

local function getGui()
	local playerGui = player:FindFirstChildOfClass("PlayerGui")
	if not playerGui then
		return nil
	end

	local gui = playerGui:FindFirstChild("WildernessPetsUI")
	if not gui then
		return nil
	end

	return gui
end

local function showMessage(text)
	local gui = getGui()
	if not gui then
		return
	end

	local existing = gui:FindFirstChild("CaptureMessage")

	if existing then
		existing:Destroy()
	end

	local label = Instance.new("TextLabel")
	label.Name = "CaptureMessage"
	label.AnchorPoint = Vector2.new(0.5, 0)
	label.Position = UDim2.new(0.5, 0, 0.10, 0)
	label.Size = UDim2.fromOffset(460, 55)
	label.BackgroundTransparency = 0.15
	label.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 22
	label.TextWrapped = true
	label.Text = text
	label.ZIndex = 100
	label.Parent = gui

	task.delay(2.4, function()
		if label and label.Parent then
			label:Destroy()
		end
	end)
end

------------------------------------------------------------
-- Equipped
------------------------------------------------------------

local function isDefaultToolHoldTrack(track)
    if not track then
        return false
    end

    local animation = track.Animation
    local animationId = animation and animation.AnimationId or ""
    return track.Name == "ToolNoneAnim"
        or string.find(animationId, "507768375", 1, true) ~= nil
end

local function stopDefaultToolHoldTrack(track)
    if isDefaultToolHoldTrack(track) then
        track:Stop(0.05)
    end
end

local function beginToolAnimationSuppression()
    if toolAnimationConnection then
        toolAnimationConnection:Disconnect()
        toolAnimationConnection = nil
    end

    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
    if not animator then
        return
    end

    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
        stopDefaultToolHoldTrack(track)
    end

    toolAnimationConnection = animator.AnimationPlayed:Connect(function(track)
        if isDefaultToolHoldTrack(track) then
            task.defer(stopDefaultToolHoldTrack, track)
        end
    end)
end

local function endToolAnimationSuppression()
    if toolAnimationConnection then
        toolAnimationConnection:Disconnect()
        toolAnimationConnection = nil
    end
end

tool.Equipped:Connect(function(m)
	mouse = m
    beginToolAnimationSuppression()
	showMessage("Lasso equipped - click a wild monster!")
end)

tool.Unequipped:Connect(function()
	mouse = nil
	busy = false
    castSerial += 1
    tugSerial += 1
    endToolAnimationSuppression()
end)

------------------------------------------------------------
-- Throw
------------------------------------------------------------

tool.Activated:Connect(function()
	if busy then
		return
	end

	if not mouse then
		return
	end

	local target = mouse.Target

	if not target then
		showMessage("Aim at a wild monster.")
		return
	end

	local monstersFolder =
		workspace:FindFirstChild("WildernessPets")
		and workspace.WildernessPets:FindFirstChild("WildMonsters")

	if not monstersFolder then
		return
	end

	local monster = target

	while monster and monster.Parent ~= monstersFolder do
		monster = monster.Parent
	end

	if not monster or monster.Parent ~= monstersFolder then
		showMessage("That isn't a wild monster.")
		return
	end

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")

	if not root then
		return
	end

	local targetPosition

	if monster:IsA("Model") then
		if monster.PrimaryPart then
			targetPosition = monster.PrimaryPart.Position
		else
			local part = monster:FindFirstChildWhichIsA("BasePart", true)
			targetPosition = part and part.Position
		end
	elseif monster:IsA("BasePart") then
		targetPosition = monster.Position
	end

	if not targetPosition then
		return
	end

	if (root.Position - targetPosition).Magnitude > MAX_CLIENT_RANGE then
		showMessage("You're too far away!")
		return
	end

	busy = true
    playCastMotion()

    -- Release the rope near the peak of the wind-up instead of firing it before
    -- the character has visibly moved. This keeps the arm and rope in sync.
    task.delay(0.24, function()
        if busy and monster and monster.Parent then
            CaptureRemote:FireServer("Throw", monster)
        end
    end)

	task.delay(60, function()
		-- Safety release if a server response is interrupted.
		busy = false
	end)
end)

------------------------------------------------------------
-- Server feedback
------------------------------------------------------------

CaptureRemote.OnClientEvent:Connect(function(action, ...)
	local args = {...}

	if action == "Challenge" then
		busy = true
        if os.clock() - lastCastMotionAt > 0.75 then
            playCastMotion()
        end
		local species = args[3] or "Monster"
		local rarity = args[4] or "Common"
		showMessage(
			"Steady... stop the marker in the green zone!  "
			.. tostring(species) .. " [" .. tostring(rarity) .. "]"
		)

	elseif action == "Progress" then
		busy = true
        playTightenMotion(1)

	elseif action == "Success" then
		busy = false
        playTightenMotion(1.18)
		local species = args[1] or "Monster"
		local rarity = args[2] or "Common"

		showMessage(
			"🎉 CAPTURED! "
			.. tostring(species)
			.. " [" .. tostring(rarity) .. "]"
		)

	elseif action == "Failed" then
		busy = false
		local species = args[1] or "Monster"

		showMessage(
			"💥 " .. tostring(species)
			.. " broke free and is chasing you!"
		)

	elseif action == "Error" then
		busy = false
		showMessage(tostring(args[1] or "Something went wrong."))
	end
end)
