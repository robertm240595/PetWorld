local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player =
	Players.LocalPlayer

local camera =
	workspace.CurrentCamera

local ROOT =
	"WildernessPets"

local rsRoot =
	ReplicatedStorage:WaitForChild(
		ROOT
	)

local remotes =
	rsRoot:WaitForChild(
		"Remotes"
	)

local villageRemote =
	remotes:WaitForChild(
		"VillageSelection"
	)

local world =
	workspace:WaitForChild(
		ROOT
	)

local plotsFolder =
	world:WaitForChild(
		"Plots"
	)

local monstersFolder =
	world:FindFirstChild(
		"WildMonsters"
	)

------------------------------------------------------------
-- UI
------------------------------------------------------------

local gui
local status

local chosen = false
local spectating = false
local currentMonster
local spectateTime = 0

------------------------------------------------------------
-- EXISTING HUD
------------------------------------------------------------

local function getMainGui()

	local playerGui =
		player:WaitForChild(
			"PlayerGui"
		)

	return playerGui:FindFirstChild(
		"WildernessPetsUI"
	)
end

local function hideHUD()

	local main =
		getMainGui()

	if main then
		main.Enabled = false
	end
end

local function showHUD()

	local main =
		getMainGui()

	if main then
		main.Enabled = true
	end
end

------------------------------------------------------------
-- FREEZE PLAYER
------------------------------------------------------------

local function freezePlayer()

	local character =
		player.Character

	if not character then
		return
	end

	local humanoid =
		character:FindFirstChildOfClass(
			"Humanoid"
		)

	if humanoid then

		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
		humanoid.AutoRotate = false

	end
end

local function unfreezePlayer()

	local character =
		player.Character

	if not character then
		return
	end

	local humanoid =
		character:FindFirstChildOfClass(
			"Humanoid"
		)

	if humanoid then

		humanoid.WalkSpeed = 16
		humanoid.JumpPower = 50
		humanoid.AutoRotate = true

	end
end

------------------------------------------------------------
-- MONSTER CAMERA
------------------------------------------------------------

local function getPart(object)

	if not object then
		return nil
	end

	if object:IsA("BasePart") then
		return object
	end

	if object:IsA("Model") then

		if object.PrimaryPart then
			return object.PrimaryPart
		end

		return object:FindFirstChildWhichIsA(
			"BasePart",
			true
		)
	end

	return nil
end

local function getRandomMonster()

	if not monstersFolder then
		return nil
	end

	local list = {}

	for _, monster in ipairs(
		monstersFolder:GetChildren()
	) do

		if (
			monster:IsA("Model")
			or monster:IsA("BasePart")
		)
		and not monster:GetAttribute(
			"Captured"
		)
		then

			if getPart(monster) then

				table.insert(
					list,
					monster
				)

			end
		end
	end

	if #list == 0 then
		return nil
	end

	return list[
		math.random(
			1,
			#list
		)
	]
end

local function lookAtMonster(
	monster
)

	local part =
		getPart(monster)

	if not part then
		return
	end

	currentMonster =
		monster

	camera.CameraType =
		Enum.CameraType.Scriptable
end

local function startSpectate()

	spectating = true
	spectateTime = 0

	freezePlayer()

	local monster =
		getRandomMonster()

	if monster then
		lookAtMonster(monster)
	end
end

local function stopSpectate()

	spectating = false
	currentMonster = nil

	unfreezePlayer()

	camera.CameraType =
		Enum.CameraType.Custom

	local character =
		player.Character

	local humanoid =
		character
		and character:FindFirstChildOfClass(
			"Humanoid"
		)

	if humanoid then

		camera.CameraSubject =
			humanoid

	end
end

------------------------------------------------------------
-- GET LIVE VILLAGE OWNER
------------------------------------------------------------

local function getLiveOwner(
	plot
)

	local ownerId =
		plot:GetAttribute(
			"OwnerUserId"
		)

	if ownerId == nil then

		ownerId =
			plot:GetAttribute(
				"Owner"
			)

	end

	ownerId =
		tonumber(ownerId)

	if not ownerId then
		return nil
	end

	return Players:GetPlayerByUserId(
		ownerId
	)
end

------------------------------------------------------------
-- CREATE GUI
------------------------------------------------------------

local function createGui()

	local playerGui =
		player:WaitForChild(
			"PlayerGui"
		)

	local old =
		playerGui:FindFirstChild(
			"VillageSelection"
		)

	if old then
		old:Destroy()
	end

	gui =
		Instance.new("ScreenGui")

	gui.Name =
		"VillageSelection"

	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 5000

	gui.Parent =
		playerGui

	----------------------------------------------------------
	-- TITLE
	----------------------------------------------------------

	local title =
		Instance.new("TextLabel")

	title.AnchorPoint =
		Vector2.new(
			0.5,
			0
		)

	title.Position =
		UDim2.new(
			0.5,
			0,
			0.06,
			0
		)

	title.Size =
		UDim2.fromOffset(
			700,
			50
		)

	title.BackgroundTransparency =
		1

	title.Text =
		"CHOOSE YOUR VILLAGE"

	title.TextColor3 =
		Color3.new(
			1,
			1,
			1
		)

	title.TextStrokeTransparency =
		0.3

	title.Font =
		Enum.Font.GothamBlack

	title.TextSize =
		34

	title.Parent =
		gui

	----------------------------------------------------------
	-- SUBTITLE
	----------------------------------------------------------

	local subtitle =
		Instance.new("TextLabel")

	subtitle.AnchorPoint =
		Vector2.new(
			0.5,
			0
		)

	subtitle.Position =
		UDim2.new(
			0.5,
			0,
			0.125,
			0
		)

	subtitle.Size =
		UDim2.fromOffset(
			700,
			30
		)

	subtitle.BackgroundTransparency =
		1

	subtitle.Text =
		"Select an available village to begin"

	subtitle.TextColor3 =
		Color3.new(
			1,
			1,
			1
		)

	subtitle.TextStrokeTransparency =
		0.45

	subtitle.Font =
		Enum.Font.Gotham

	subtitle.TextSize =
		17

	subtitle.Parent =
		gui

	----------------------------------------------------------
	-- BUTTON HOLDER
	----------------------------------------------------------

	local holder =
		Instance.new("Frame")

	holder.AnchorPoint =
		Vector2.new(
			0.5,
			0.5
		)

	holder.Position =
		UDim2.new(
			0.5,
			0,
			0.55,
			0
		)

	holder.Size =
		UDim2.fromOffset(
			650,
			370
		)

	holder.BackgroundTransparency =
		1

	holder.Parent =
		gui

	local grid =
		Instance.new(
			"UIGridLayout"
		)

	grid.CellSize =
		UDim2.fromOffset(
			195,
			48
		)

	grid.CellPadding =
		UDim2.fromOffset(
			10,
			8
		)

	grid.HorizontalAlignment =
		Enum.HorizontalAlignment.Center

	grid.VerticalAlignment =
		Enum.VerticalAlignment.Center

	grid.Parent =
		holder

	----------------------------------------------------------
	-- STATUS
	----------------------------------------------------------

	status =
		Instance.new("TextLabel")

	status.AnchorPoint =
		Vector2.new(
			0.5,
			1
		)

	status.Position =
		UDim2.new(
			0.5,
			0,
			0.94,
			0
		)

	status.Size =
		UDim2.fromOffset(
			750,
			35
		)

	status.BackgroundTransparency =
		1

	status.Text =
		""

	status.TextColor3 =
		Color3.new(
			1,
			1,
			1
		)

	status.TextStrokeTransparency =
		0.35

	status.Font =
		Enum.Font.GothamBold

	status.TextSize =
		17

	status.Parent =
		gui

	----------------------------------------------------------
	-- PLOTS
	----------------------------------------------------------

	local plots = {}

	for _, plot in ipairs(
		plotsFolder:GetChildren()
	) do

		if plot:IsA("Model")
			or plot:IsA("Folder")
		then

			table.insert(
				plots,
				plot
			)

		end
	end

	table.sort(
		plots,
		function(a,b)

			local aNum =
				tonumber(
					string.match(
						a.Name,
						"%d+"
					)
				) or 0

			local bNum =
				tonumber(
					string.match(
						b.Name,
						"%d+"
					)
				) or 0

			return aNum < bNum
		end
	)

	for _, plot in ipairs(
		plots
	) do

		local number =
			tonumber(
				string.match(
					plot.Name,
					"%d+"
				)
			)

		if number then

			-- IMPORTANT:
			-- Only an actual Player currently in
			-- this server makes the village taken.

			local owner =
				getLiveOwner(plot)

			local taken =
				owner ~= nil
				and owner ~= player

			local button =
				Instance.new(
					"TextButton"
				)

			button.Name =
				"Village_"
				.. tostring(number)

			button.Size =
				UDim2.fromOffset(
					195,
					48
				)

			button.BackgroundTransparency =
				1

			button.BorderSizePixel =
				0

			button.Text =
				taken
				and (
					"Village "
					.. tostring(number)
					.. " • TAKEN"
				)
				or (
					"Village "
					.. tostring(number)
				)

			button.TextColor3 =
				taken
				and Color3.fromRGB(
					150,
					150,
					150
				)
				or Color3.new(
					1,
					1,
					1
				)

			button.TextStrokeTransparency =
				0.35

			button.Font =
				Enum.Font.GothamBold

			button.TextSize =
				19

			button.Parent =
				holder

			if taken then

				button.Active =
					false

				button.AutoButtonColor =
					false

			else

				button.MouseButton1Click:Connect(
					function()

						if chosen then
							return
						end

						chosen = true

						status.Text =
							"Claiming Village "
							.. tostring(number)
							.. "..."

						villageRemote:FireServer(
							"SelectVillage",
							number
						)
					end
				)
			end
		end
	end
end

------------------------------------------------------------
-- SERVER RESPONSE
------------------------------------------------------------

villageRemote.OnClientEvent:Connect(
	function(
		action,
		value
	)

		if action == "Success" then

			chosen = true

			if gui then
				gui:Destroy()
				gui = nil
			end

			stopSpectate()

			showHUD()

			task.wait(0.2)

			local character =
				player.Character

			if character then

				local humanoid =
					character:FindFirstChildOfClass(
						"Humanoid"
					)

				if humanoid then

					camera.CameraType =
						Enum.CameraType.Custom

					camera.CameraSubject =
						humanoid

				end
			end

		elseif action == "Error" then

			chosen = false

			if status then
				status.Text =
					tostring(value)
			end
		end
	end
)

------------------------------------------------------------
-- SPECTATE LOOP
------------------------------------------------------------

RunService.RenderStepped:Connect(
	function(dt)

		if not spectating
			or chosen
		then
			return
		end

		spectateTime += dt

		if not currentMonster
			or not currentMonster.Parent
		then

			local monster =
				getRandomMonster()

			if monster then
				lookAtMonster(monster)
			end

			spectateTime = 0

			return
		end

		local part =
			getPart(currentMonster)

		if not part then

			local monster =
				getRandomMonster()

			if monster then
				lookAtMonster(monster)
			end

			spectateTime = 0

			return
		end

		------------------------------------------------------
		-- New monster every 3 seconds
		------------------------------------------------------

		if spectateTime >= 3 then

			local monster =
				getRandomMonster()

			if monster then
				lookAtMonster(monster)
			end

			spectateTime = 0

			return
		end

		local target =
			part.Position

		local angle =
			math.rad(
				(spectateTime * 18) % 360
			)

		local distance = 22

		local desired =
			target
			+ Vector3.new(
				math.cos(angle)
					* distance,

				9,

				math.sin(angle)
					* distance
			)

		camera.CFrame =
			camera.CFrame:Lerp(
				CFrame.lookAt(
					desired,
					target
					+ Vector3.new(
						0,
						2,
						0
					)
				),
				math.clamp(
					dt * 4,
					0,
					1
				)
			)
	end
)

------------------------------------------------------------
-- CHARACTER
------------------------------------------------------------

player.CharacterAdded:Connect(
	function()

		task.wait(0.3)

		if not chosen
			and not player:GetAttribute(
				"VillageReady"
			)
		then

			hideHUD()
			freezePlayer()

		end
	end
)

------------------------------------------------------------
-- START
------------------------------------------------------------

if player:GetAttribute(
	"VillageReady"
) then

	chosen = true
	showHUD()

else

	chosen = false

	hideHUD()

	createGui()

	task.wait(0.2)

	startSpectate()

end

print(
	"[WildernessPets] Village selector fixed."
)
