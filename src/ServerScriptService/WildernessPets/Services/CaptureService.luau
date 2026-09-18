local PetAnimator = require(script.Parent.Parent.Systems.PetAnimator)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local HttpService = game:GetService("HttpService")

local Root = ReplicatedStorage:WaitForChild("WildernessPets")
local Remotes = Root:WaitForChild("Remotes")
local CaptureRemote = Remotes:WaitForChild("Capture")

local Services = script.Parent
local DataService = require(Services:WaitForChild("PlayerDataService"))
local PetService = require(Services:WaitForChild("PetService"))
local ActionLockService = require(Services:WaitForChild("ActionLockService"))
local Config = require(Root:WaitForChild("Shared"):WaitForChild("Config"))

local CaptureService = {}

local MAX_RANGE = 42
local COOLDOWN = 1.35
local FAILURE_DAMAGE = 999999

local lastAttempt = {}
local challenges = setmetatable({}, {__mode = "k"})
local rng = Random.new()

local function serverNow()
	return workspace:GetServerTimeNow()
end

local function getMonsterFolder()
	local world = workspace:FindFirstChild("WildernessPets")
	return world and world:FindFirstChild("WildMonsters") or nil
end

local function getCharacterRoot(player)
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") or nil
end

local function getHumanoid(player)
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid") or nil
end

local function getPlayerData(player)
	if DataService.Get then
		return DataService:Get(player)
	end
	return nil
end

local function getLassoName(player)
	local data = getPlayerData(player)
	if data and type(data.Lasso) == "string" then
		return data.Lasso
	end
	local attribute = player:GetAttribute("Lasso") or player:GetAttribute("LassoName")
	if type(attribute) == "string" then
		return attribute
	end
	return "Rough Rope"
end

local function getLassoStats(player)
	local lassoName = getLassoName(player)
	local lassos = Config.Lassos or {}
	local stats = lassos[lassoName]
	if not stats then
		for name, info in pairs(lassos) do
			if tostring(name):lower() == tostring(lassoName):lower() then
				lassoName = name
				stats = info
				break
			end
		end
	end
	stats = stats or {Strength = 15}
	return lassoName, tonumber(stats.Strength or stats.Power or stats.CaptureStrength) or 15
end

local function getMonsterInfo(monster)
	local species = monster:GetAttribute("Species") or monster:GetAttribute("Monster") or monster.Name
	local rarity = monster:GetAttribute("Rarity") or "Common"
	local difficulty = monster:GetAttribute("CaptureDifficulty")
	local rarityData = Config.Rarities and Config.Rarities[rarity]
	if not difficulty and rarityData then
		difficulty = rarityData.CaptureDifficulty or rarityData.Difficulty or rarityData.LassoDifficulty
	end
	return tostring(species), tostring(rarity), tonumber(difficulty) or 20
end

local function getPosition(instance)
	if instance:IsA("Model") then
		local part = instance.PrimaryPart
			or instance:FindFirstChild("HumanoidRootPart")
			or instance:FindFirstChildWhichIsA("BasePart", true)
		return part and part.Position or nil
	elseif instance:IsA("BasePart") then
		return instance.Position
	end
	return nil
end

local function getMonsterPart(monster)
	if not monster then return nil end
	if monster:IsA("BasePart") then return monster end
	if monster:IsA("Model") then
		return monster.PrimaryPart
			or monster:FindFirstChild("HumanoidRootPart")
			or monster:FindFirstChildWhichIsA("BasePart", true)
	end
	return nil
end

local function isValidMonster(monster)
	if typeof(monster) ~= "Instance" then return false end
	local folder = getMonsterFolder()
	if not folder or monster.Parent ~= folder then return false end
	if not monster:IsA("Model") and not monster:IsA("BasePart") then return false end
	if monster:GetAttribute("Dead")
		or monster:GetAttribute("Captured")
		or monster:GetAttribute("BeingCaptured")
		or monster:GetAttribute("InCombat") then
		return false
	end
	return getMonsterPart(monster) ~= nil
end

local function createRopeEffect(player, monster)
	local character = player.Character
	if not character then return end

	local hand = character:FindFirstChild("RightHand")
		or character:FindFirstChild("Right Arm")
		or character:FindFirstChild("HumanoidRootPart")
	local target = getMonsterPart(monster)
	if not hand or not target then return end

	local a0 = Instance.new("Attachment")
	a0.Name = "LassoStart"
	a0.Parent = hand

	local a1 = Instance.new("Attachment")
	a1.Name = "LassoTarget"
	a1.Parent = target

	local beam = Instance.new("Beam")
	beam.Name = "LassoRope"
	beam.Attachment0 = a0
	beam.Attachment1 = a1
	beam.Width0 = 0.16
	beam.Width1 = 0.10
	beam.FaceCamera = true
	beam.LightEmission = 0.1
	beam.Parent = hand

	Debris:AddItem(beam, 1.2)
	Debris:AddItem(a0, 1.2)
	Debris:AddItem(a1, 1.2)
end

local function createCapturedPet(player, species)
	if PetService.Create then
		return PetService:Create(player, species)
	end
	return nil
end

local function challengeSettings(rarity, lassoStrength, difficulty)
	local minigame = Config.CaptureMinigame or {}
	local raritySettings = (minigame.Rarities or {})[rarity] or {}
	local width = tonumber(raritySettings.GreenWidth) or 0.24
	local speed = tonumber(raritySettings.Speed) or 0.85
	local bonusRate = tonumber(minigame.LassoWidthBonusPerStrength) or 0.001
	local bonus = math.clamp((lassoStrength - difficulty) * bonusRate, -0.04, 0.08)
	width = math.clamp(
		width + bonus,
		tonumber(minigame.MinGreenWidth) or 0.07,
		tonumber(minigame.MaxGreenWidth) or 0.40
	)
	return width, speed, tonumber(minigame.DurationSeconds) or 8, tonumber(minigame.ClickClockTolerance) or 0.65
end

local function sliderPosition(challenge, atTime)
	local elapsed = math.max(0, atTime - challenge.startTime)
	local phase = (elapsed * challenge.speed) % 2
	if phase <= 1 then
		return phase
	end
	return 2 - phase
end

local function clearMonsterCaptureState(player, monster)
	if monster and monster.Parent then
		monster:SetAttribute("BeingCaptured", false)
		if monster:GetAttribute("CaptureOwnerUserId") == player.UserId then
			monster:SetAttribute("CaptureOwnerUserId", nil)
		end
	end
end

local function finishFailure(player, challenge, reason)
	local monster = challenge.monster
	if not monster or not monster.Parent then
		ActionLockService:End(player, "Capture")
		return false, reason or "The creature escaped."
	end

	clearMonsterCaptureState(player, monster)
	monster:SetAttribute("InCombat", true)
	monster:SetAttribute("CombatOwnerUserId", player.UserId)

	CaptureRemote:FireClient(
		player,
		"Failed",
		challenge.species,
		challenge.rarity,
		challenge.lassoName,
		reason or "Missed"
	)

	local originalCharacter = player.Character
	local function liveTarget()
		if player.Character ~= originalCharacter then return nil end
		local humanoid = getHumanoid(player)
		if not humanoid or humanoid.Health <= 0 then return nil end
		return getCharacterRoot(player)
	end

	local ok, err = pcall(function()
		if PetAnimator:ChaseTarget(monster, liveTarget, 8) then
			local target = liveTarget()
			if target then
				PetAnimator:PlayAttack(monster, target.Position, 0.75, function()
					local currentTarget = liveTarget()
					local humanoid = getHumanoid(player)
					if currentTarget and humanoid and PetAnimator:CanMeleeHit(monster, currentTarget) then
						humanoid:TakeDamage(FAILURE_DAMAGE)
					end
				end, 0.75)
			end
		end
	end)

	if monster.Parent then
		monster:SetAttribute("InCombat", false)
		if monster:GetAttribute("CombatOwnerUserId") == player.UserId then
			monster:SetAttribute("CombatOwnerUserId", nil)
		end
		PetAnimator:PlayIdle(monster)
	end

	ActionLockService:End(player, "Capture")

	if not ok then
		warn("[WildernessPets] Capture retaliation: " .. tostring(err))
	end
	return false, reason or "The " .. challenge.species .. " broke free!", true
end

function CaptureService:Resolve(player, challengeId, clickTime, timedOut)
	local challenge = challenges[player]
	if not challenge or challenge.id ~= challengeId or challenge.resolving then
		return false, "That lasso attempt is no longer active."
	end
	challenge.resolving = true
	challenges[player] = nil

	local monster = challenge.monster
	if not monster or not monster.Parent or monster:GetAttribute("Dead") or monster:GetAttribute("Captured") then
		clearMonsterCaptureState(player, monster)
		ActionLockService:End(player, "Capture")
		CaptureRemote:FireClient(player, "Error", "The creature escaped before the lasso landed.")
		return false, "The creature escaped."
	end

	local success = false
	local reason = timedOut and "Time ran out" or "Missed the green zone"

	if not timedOut and type(clickTime) == "number" then
		local now = serverNow()
		local tolerance = challenge.clockTolerance
		local clockIsReasonable = math.abs(clickTime - now) <= tolerance
			and clickTime >= challenge.startTime - 0.10
			and clickTime <= challenge.deadline + tolerance

		if clockIsReasonable then
			local slider = sliderPosition(challenge, clickTime)
			success = slider >= challenge.zoneStart and slider <= challenge.zoneStart + challenge.zoneWidth
		end
	end

	if not success then
		return finishFailure(player, challenge, reason)
	end

	monster:SetAttribute("Captured", true)
	clearMonsterCaptureState(player, monster)

	local pet = createCapturedPet(player, challenge.species)
	if not pet then
		monster:SetAttribute("Captured", false)
		PetAnimator:PlayIdle(monster)
		ActionLockService:End(player, "Capture")
		CaptureRemote:FireClient(player, "Error", "Your pet could not be saved. Try again.")
		return false, "Pet could not be saved.", true
	end

	player:SetAttribute("CombatTarget", "")

	CaptureRemote:FireClient(
		player,
		"Success",
		challenge.species,
		challenge.rarity,
		challenge.lassoName
	)

	monster:Destroy()

	local refreshEvent = Services.Parent.Systems:FindFirstChild("PetDisplayRefresh")
	if refreshEvent and refreshEvent:IsA("BindableEvent") then
		refreshEvent:Fire(player)
	end

	ActionLockService:End(player, "Capture")
	return true, "Captured " .. challenge.species .. "!", true
end

function CaptureService:Capture(player, monster)
	if not player or not player:IsA("Player") then
		return false, "Invalid player."
	end
	if challenges[player] then
		return false, "Finish your current lasso attempt first."
	end

	local attemptTime = os.clock()
	if lastAttempt[player] and attemptTime - lastAttempt[player] < COOLDOWN then
		return false, "Slow down!"
	end

	local humanoid = getHumanoid(player)
	if not humanoid or humanoid.Health <= 0 then
		return false, "You are defeated."
	end
	if not isValidMonster(monster) then
		return false, "Invalid target."
	end

	local playerRoot = getCharacterRoot(player)
	local monsterPosition = getPosition(monster)
	if not playerRoot or not monsterPosition then
		return false, "Target unavailable."
	end
	if (playerRoot.Position - monsterPosition).Magnitude > MAX_RANGE then
		return false, "Too far away!"
	end

	lastAttempt[player] = attemptTime

	local species, rarity, difficulty = getMonsterInfo(monster)
	local lassoName, lassoStrength = getLassoStats(player)
	local zoneWidth, speed, duration, clockTolerance = challengeSettings(rarity, lassoStrength, difficulty)
	local zoneStart = rng:NextNumber(0.03, math.max(0.03, 0.97 - zoneWidth))
	local startTime = serverNow() + 0.40

	local challenge = {
		id = HttpService:GenerateGUID(false),
		monster = monster,
		species = species,
		rarity = rarity,
		lassoName = lassoName,
		zoneStart = zoneStart,
		zoneWidth = zoneWidth,
		speed = speed,
		startTime = startTime,
		deadline = startTime + duration,
		clockTolerance = clockTolerance,
		resolving = false,
	}
	challenges[player] = challenge

	ActionLockService:Begin(player, "Capture")
	createRopeEffect(player, monster)
	monster:SetAttribute("BeingCaptured", true)
	monster:SetAttribute("CaptureOwnerUserId", player.UserId)

	pcall(function()
		PetAnimator:PlayStruggle(monster, math.min(duration, 1.2))
	end)

	CaptureRemote:FireClient(
		player,
		"Challenge",
		monster,
		challenge.id,
		species,
		rarity,
		lassoName,
		zoneStart,
		zoneWidth,
		speed,
		startTime,
		duration
	)

	task.delay(duration + 1.4, function()
		local current = challenges[player]
		if current and current.id == challenge.id and not current.resolving then
			CaptureService:Resolve(player, challenge.id, nil, true)
		end
	end)

	return true, "Lasso challenge started.", true
end

CaptureRemote.OnServerEvent:Connect(function(player, action, ...)
	local args = {...}

	if action == "Throw" then
		local monster = args[1]
		local ok, success, message, alreadyNotified = pcall(function()
			return CaptureService:Capture(player, monster)
		end)
		if not ok then
			warn("[WildernessPets] Capture start error: " .. tostring(success))
			CaptureRemote:FireClient(player, "Error", "The lasso could not start. Please try again.")
		elseif not success and not alreadyNotified then
			CaptureRemote:FireClient(player, "Error", message or "Unable to capture this creature.")
		end

	elseif action == "Resolve" then
		local challengeId = args[1]
		local clickTime = tonumber(args[2])
		local ok, err = pcall(function()
			CaptureService:Resolve(player, challengeId, clickTime, false)
		end)
		if not ok then
			warn("[WildernessPets] Capture resolve error: " .. tostring(err))
			local challenge = challenges[player]
			if challenge then
				challenges[player] = nil
				clearMonsterCaptureState(player, challenge.monster)
				ActionLockService:End(player, "Capture")
			end
			CaptureRemote:FireClient(player, "Error", "The lasso attempt could not finish. Please try again.")
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	local challenge = challenges[player]
	if challenge then
		clearMonsterCaptureState(player, challenge.monster)
	end
	challenges[player] = nil
	lastAttempt[player] = nil
end)

return CaptureService
