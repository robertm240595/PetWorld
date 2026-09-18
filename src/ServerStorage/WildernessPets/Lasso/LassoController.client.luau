local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local tool = script.Parent

local Root = ReplicatedStorage:WaitForChild("WildernessPets")
local Remotes = Root:WaitForChild("Remotes")
local CaptureRemote = Remotes:WaitForChild("Capture")

local MAX_CLIENT_RANGE = 42
local COOLDOWN = 1.35

local mouse
local busy = false

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

tool.Equipped:Connect(function(m)
	mouse = m
	showMessage("Lasso equipped — click a wild monster!")
end)

tool.Unequipped:Connect(function()
	mouse = nil
	busy = false
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

	CaptureRemote:FireServer("Throw", monster)

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
		local species = args[3] or "Monster"
		local rarity = args[4] or "Common"
		showMessage(
			"Steady... stop the marker in the green zone!  "
			.. tostring(species) .. " [" .. tostring(rarity) .. "]"
		)

	elseif action == "Progress" then
		busy = true

	elseif action == "Success" then
		busy = false
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
