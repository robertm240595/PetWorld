local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(game.ServerScriptService.WildernessPets.Services.PlayerDataService)

local ROOT = "WildernessPets"

local rsRoot =
	ReplicatedStorage:WaitForChild(ROOT)

local remotes =
	rsRoot:WaitForChild("Remotes")

local villageRemote =
	remotes:WaitForChild("VillageSelection")

local world =
	workspace:WaitForChild(ROOT)

local plotsFolder =
	world:WaitForChild("Plots")

------------------------------------------------------------
-- GET PLOTS
------------------------------------------------------------

local function getPlots()

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

			local aNumber =
				tonumber(
					string.match(
						a.Name,
						"%d+"
					)
				) or 0

			local bNumber =
				tonumber(
					string.match(
						b.Name,
						"%d+"
					)
				) or 0

			return aNumber < bNumber
		end
	)

	return plots
end

local function getPlotNumber(plot)

	return tonumber(
		string.match(
			plot.Name,
			"%d+"
		)
	)
end

------------------------------------------------------------
-- IMPORTANT:
-- ONLY CURRENT PLAYERS COUNT AS OWNERS
------------------------------------------------------------

local function getLiveOwner(plot)

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

	if not ownerId
		or ownerId == 0
	then
		return nil
	end

	local player =
		Players:GetPlayerByUserId(
			ownerId
		)

	if player then
		return player
	end

	-- Stale owner. Clear it.
	plot:SetAttribute(
		"OwnerUserId",
		nil
	)

	plot:SetAttribute(
		"Owner",
		nil
	)

	plot:SetAttribute(
		"OwnerName",
		nil
	)

	plot:SetAttribute(
		"OwnerDisplayName",
		nil
	)

	return nil
end

------------------------------------------------------------
-- CLEAR STALE OWNERS ON SERVER START
------------------------------------------------------------

for _, plot in ipairs(
	getPlots()
) do

	local owner =
		getLiveOwner(plot)

	if owner then

		print(
			"[WildernessPets] "
			.. plot.Name
			.. " occupied by "
			.. owner.Name
		)

	else

		-- Explicitly clear anything left over.
		plot:SetAttribute(
			"OwnerUserId",
			nil
		)

		plot:SetAttribute(
			"Owner",
			nil
		)

		plot:SetAttribute(
			"OwnerName",
			nil
		)

		plot:SetAttribute(
			"OwnerDisplayName",
			nil
		)
	end
end

------------------------------------------------------------
-- FIND PLOT
------------------------------------------------------------

local function findPlot(number)

	number = tonumber(number)

	if not number then
		return nil
	end

	for _, plot in ipairs(
		getPlots()
	) do

		if getPlotNumber(plot)
			== number
		then
			return plot
		end
	end

	return nil
end

------------------------------------------------------------
-- FIND PLAYER'S CURRENT PLOT
------------------------------------------------------------

local function getPlayerPlot(player)

	for _, plot in ipairs(
		getPlots()
	) do

		local owner =
			getLiveOwner(plot)

		if owner
			and owner.UserId
				== player.UserId
		then
			return plot
		end
	end

	return nil
end

------------------------------------------------------------
-- SPAWN
------------------------------------------------------------

local function getSpawn(plot)

	local spawn =
		plot:FindFirstChild(
			"Spawn",
			true
		)

	if spawn
		and spawn:IsA("BasePart")
	then
		return spawn
	end

	spawn =
		plot:FindFirstChild(
			"SpawnLocation",
			true
		)

	if spawn
		and spawn:IsA("BasePart")
	then
		return spawn
	end

	for _, item in ipairs(
		plot:GetDescendants()
	) do

		if item:IsA("SpawnLocation") then
			return item
		end
	end

	-- Final fallback.
	local land =
		plot:FindFirstChild(
			"Land",
			true
		)

	if land
		and land:IsA("BasePart")
	then
		return land
	end

	return nil
end

local function teleportPlayer(
	player,
	plot
)

	local character =
		player.Character

	if not character then
		return false
	end

	local root =
		character:FindFirstChild(
			"HumanoidRootPart"
		)

	local spawn =
		getSpawn(plot)

	if not root
		or not spawn
	then
		return false
	end

	root.CFrame =
		spawn.CFrame
		+ Vector3.new(
			0,
			5,
			0
		)

	return true
end

------------------------------------------------------------
-- CLAIM VILLAGE
------------------------------------------------------------

villageRemote.OnServerEvent:Connect(
	function(
		player,
		action,
		plotNumber
	)

		if action ~= "SelectVillage" then
			return
		end

		plotNumber =
			tonumber(plotNumber)

		if not plotNumber then

			villageRemote:FireClient(
				player,
				"Error",
				"Invalid village."
			)

			return
		end

		local plot =
			findPlot(plotNumber)

		if not plot then

			villageRemote:FireClient(
				player,
				"Error",
				"Village "
				.. tostring(plotNumber)
				.. " does not exist."
			)

			return
		end

		----------------------------------------------------
		-- Does player already own a village?
		----------------------------------------------------

		local existing =
			getPlayerPlot(player)

		if existing then

			local existingNumber =
				getPlotNumber(existing)

			local data = DataService:Get(player)
			if data then
				data.SelectedPlot = existingNumber
			end

			player:SetAttribute(
				"SelectedPlot",
				existingNumber
			)

			player:SetAttribute(
				"HasVillage",
				true
			)

			player:SetAttribute(
				"VillageReady",
				true
			)

			teleportPlayer(
				player,
				existing
			)

			villageRemote:FireClient(
				player,
				"Success",
				existingNumber
			)

			return
		end

		----------------------------------------------------
		-- Is requested plot ACTUALLY occupied?
		----------------------------------------------------

		local currentOwner =
			getLiveOwner(plot)

		if currentOwner
			and currentOwner ~= player
		then

			villageRemote:FireClient(
				player,
				"Error",
				"That village is already occupied."
			)

			return
		end

		----------------------------------------------------
		-- CLAIM
		----------------------------------------------------

		plot:SetAttribute(
			"OwnerUserId",
			player.UserId
		)

		plot:SetAttribute(
			"Owner",
			player.UserId
		)

		plot:SetAttribute(
			"OwnerName",
			player.Name
		)

		plot:SetAttribute(
			"OwnerDisplayName",
			player.DisplayName
		)

		local data = DataService:Get(player)
		if data then
			data.SelectedPlot = plotNumber
		end

		player:SetAttribute(
			"SelectedPlot",
			plotNumber
		)

		player:SetAttribute(
			"HasVillage",
			true
		)

		player:SetAttribute(
			"VillageReady",
			true
		)

		----------------------------------------------------
		-- SPAWN
		----------------------------------------------------

		local spawn =
			getSpawn(plot)

		if spawn
			and spawn:IsA(
				"SpawnLocation"
			)
		then

			spawn.Enabled = true
			spawn.Neutral = false
			spawn.AllowTeamChangeOnTouch = false
		end

		task.wait(0.15)

		teleportPlayer(
			player,
			plot
		)

		villageRemote:FireClient(
			player,
			"Success",
			plotNumber
		)

		print(
			"[WildernessPets] "
			.. player.Name
			.. " claimed Village "
			.. tostring(plotNumber)
		)
	end
)

------------------------------------------------------------
-- RELEASE VILLAGE
------------------------------------------------------------

Players.PlayerRemoving:Connect(
	function(player)

		for _, plot in ipairs(
			getPlots()
		) do

			local owner =
				getLiveOwner(plot)

			if owner
				and owner.UserId
					== player.UserId
			then

				plot:SetAttribute(
					"OwnerUserId",
					nil
				)

				plot:SetAttribute(
					"Owner",
					nil
				)

				plot:SetAttribute(
					"OwnerName",
					nil
				)

				plot:SetAttribute(
					"OwnerDisplayName",
					nil
				)

				print(
					"[WildernessPets] Released "
					.. plot.Name
				)
			end
		end
	end
)

------------------------------------------------------------
-- CHARACTER RESPAWN
------------------------------------------------------------

Players.PlayerAdded:Connect(
	function(player)

		player.CharacterAdded:Connect(
			function()

				task.wait(0.5)

				local plot =
					getPlayerPlot(player)

				if plot then

					teleportPlayer(
						player,
						plot
					)

				end
			end
		)
	end
)

print(
	"[WildernessPets] Village ownership fix loaded."
)
