local RemoteGuard = require(game.ServerScriptService.WildernessPets.Services.RemoteGuard)
local PetAnimator = require(script.Parent.Parent.Systems.PetAnimator)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Root = ReplicatedStorage:WaitForChild("WildernessPets")
local Remotes = Root:WaitForChild("Remotes")
local CaptureRemote = Remotes:WaitForChild("Capture")

local Services = script.Parent
local DataService = require(Services:WaitForChild("PlayerDataService"))
local PetService = require(Services:WaitForChild("PetService"))
local MountService = require(Services:WaitForChild("MountService"))
local ActionLockService = require(Services:WaitForChild("ActionLockService"))
local QuestService = require(Services:WaitForChild("QuestService"))
local Config = require(Root:WaitForChild("Shared"):WaitForChild("Config"))
local Motion = require(Root.Shared.LassoMotion)

local CaptureService = {}

local MAX_RANGE = tonumber(Config.LassoRange) or 42
local COOLDOWN = 1.35
local FAILURE_DAMAGE = 999999

local lastAttempt = {}
local challenges = setmetatable({}, {__mode = "k"})
local activeRopeEffects = setmetatable({}, {__mode = "k"})
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

-- Replicate a compact presentation state. Every client renders the same rope
-- and arm choreography from the server clock; no per-frame networked parts.
local function clearRopeEffect(player)
    activeRopeEffects[player] = nil
    local character = player.Character
    if character then
        character:SetAttribute("LassoPhase", "Idle")
        local target = character:FindFirstChild("LassoTarget")
        if target then target.Value = nil end
    end
end

local function createRopeEffect(player, monster, requiredHits, started)
    local character = player.Character
    if not character then return end
    local target = character:FindFirstChild("LassoTarget")
    if not target then
        target = Instance.new("ObjectValue")
        target.Name = "LassoTarget"
        target.Parent = character
    end
    target.Value = monster
    character:SetAttribute("LassoHits", 0)
    character:SetAttribute("LassoRequiredHits", requiredHits)
    character:SetAttribute("LassoCastStart", started)
    character:SetAttribute("LassoPhase", "Casting")
    activeRopeEffects[player] = {character = character, started = started}
end

local function tightenRopeEffect(player)
    local effect = activeRopeEffects[player]
    if effect and effect.character.Parent then
        effect.character:SetAttribute("LassoHits", (effect.character:GetAttribute("LassoHits") or 0) + 1)
        effect.character:SetAttribute("LassoTugTime", serverNow())
    end
end

local function finishRopeEffect(player, success)
    local effect = activeRopeEffects[player]
    if not effect then return end
    activeRopeEffects[player] = nil
    local character = effect.character
    if not character.Parent then return end
    character:SetAttribute("LassoFinishTime", serverNow())
    character:SetAttribute("LassoPhase", success and "Success" or "Failed")
    task.delay(Motion.Recovery + 0.15, function()
        if character.Parent and character:GetAttribute("LassoCastStart") == effect.started then
            character:SetAttribute("LassoPhase", "Idle")
            local target = character:FindFirstChild("LassoTarget")
            if target then target.Value = nil end
        end
    end)
end

local function createCapturedCreature(player, creatureType, species, imprint)
	if creatureType == "Mount" then
		return MountService:Create(player, species, {
			Imprint = imprint,
			AcquiredFrom = "Capture",
		})
	end
	if PetService.Create then
		return PetService:Create(player, species, {Imprint = imprint})
	end
	return nil
end

local function challengeSettings(rarity, lassoStrength, difficulty)
	local minigame = Config.CaptureMinigame or {}
	local raritySettings = (minigame.Rarities or {})[rarity] or {}
	local width = tonumber(raritySettings.GreenWidth) or 0.24
	local speed = tonumber(raritySettings.Speed) or 0.85
	local requiredHits = math.max(3, math.floor(tonumber(raritySettings.Hits) or 3))
	local bonusRate = tonumber(minigame.LassoWidthBonusPerStrength) or 0.001
	local bonus = math.clamp((lassoStrength - difficulty) * bonusRate, -0.04, 0.08)
	width = math.clamp(
		width + bonus,
		tonumber(minigame.MinGreenWidth) or 0.07,
		tonumber(minigame.MaxGreenWidth) or 0.40
	)

	local reductionRate = tonumber(minigame.LassoSpeedReductionPerStrength) or 0
	local minSpeedMultiplier = tonumber(minigame.MinSpeedMultiplier) or 0.55
	local speedMultiplier = math.clamp(
		1 - math.max(0, lassoStrength - 15) * reductionRate,
		minSpeedMultiplier,
		1
	)
	speed *= speedMultiplier

	return width, speed, requiredHits, tonumber(minigame.RoundDurationSeconds) or 4.5, tonumber(minigame.ClickClockTolerance) or 0.65
end

local function sliderPosition(challenge, atTime)
	local elapsed = math.max(0, atTime - challenge.startTime)
	local phase = (elapsed * challenge.speed) % 2
	if phase <= 1 then
		return phase
	end
	return 2 - phase
end

local function randomZoneStart(width)
	return rng:NextNumber(0.03, math.max(0.03, 0.97 - width))
end

local function scheduleRoundTimeout(player, challenge)
	local id = challenge.id
	local round = challenge.round
	local delaySeconds = math.max(0.2, challenge.deadline - serverNow() + 0.8)

	task.delay(delaySeconds, function()
		local current = challenges[player]
		if current and current.id == id and current.round == round and not current.resolving then
			CaptureService:Resolve(player, id, nil, true, round)
		end
	end)
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
        finishRopeEffect(player, false)
		ActionLockService:End(player, "Capture")
		return false, reason or "The creature escaped."
	end

    finishRopeEffect(player, false)
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

function CaptureService:Resolve(player, challengeId, clickTime, timedOut, roundToken)
	local challenge = challenges[player]
	if not challenge or challenge.id ~= challengeId or challenge.resolving then
		return false, "That lasso attempt is no longer active."
	end

	if not timedOut and not challenge.ready then
		return false, "Wait for the rope to land."
	end

	if timedOut and roundToken and roundToken ~= challenge.round then
		return false, "Stale lasso round."
	end

	challenge.resolving = true

	local monster = challenge.monster
	if not monster or not monster.Parent or monster:GetAttribute("Dead") or monster:GetAttribute("Captured") then
		challenges[player] = nil
        finishRopeEffect(player, false)
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
		challenges[player] = nil
		return finishFailure(player, challenge, reason)
	end

	challenge.hits += 1

	if challenge.hits < challenge.requiredHits then
        tightenRopeEffect(player)
		challenge.round += 1
		challenge.zoneStart = randomZoneStart(challenge.zoneWidth)
		challenge.startTime = serverNow() + 0.25
		challenge.deadline = challenge.startTime + challenge.roundDuration
		challenge.resolving = false

		CaptureRemote:FireClient(
			player,
			"Progress",
			challenge.id,
			challenge.hits,
			challenge.requiredHits,
			challenge.zoneStart,
			challenge.zoneWidth,
			challenge.speed,
			challenge.startTime,
			challenge.roundDuration
		)

		scheduleRoundTimeout(player, challenge)
		return true, "Lasso hold " .. tostring(challenge.hits) .. "/" .. tostring(challenge.requiredHits) .. ".", true
	end

	challenges[player] = nil
	monster:SetAttribute("Captured", true)
	clearMonsterCaptureState(player, monster)

	local data = getPlayerData(player)
	local activeEffects = data and data.ActiveEffects or {}
	local lucky = activeEffects and activeEffects.NextCaptureLuck == true
	local imprint = PetService:RollImprint(lucky)
	local creatureType = tostring(challenge.creatureType or monster:GetAttribute("CreatureType") or "Pet")
	local captured, createMessage = createCapturedCreature(player, creatureType, challenge.species, imprint)
	if not captured then
        finishRopeEffect(player, false)
		monster:SetAttribute("Captured", false)
		PetAnimator:PlayIdle(monster)
		ActionLockService:End(player, "Capture")
		local label = creatureType == "Mount" and "mount" or "pet"
		CaptureRemote:FireClient(player, "Error", createMessage or ("Your " .. label .. " could not be saved. Try again."))
		return false, (createMessage or (label .. " could not be saved.")), true
	end

	if lucky and activeEffects then
		activeEffects.NextCaptureLuck = false
	end

	if creatureType == "Mount" then
		QuestService:OnPlayerAction(player, "CaptureMount", {
			MountId = captured.Id,
			Species = captured.Species,
			QuestId = monster:GetAttribute("QuestId"),
		})
	else
		QuestService:OnPlayerAction(player, "CapturePet", {PetId = captured.Id})
	end
	player:SetAttribute("CombatTarget", "")

    finishRopeEffect(player, true)

	CaptureRemote:FireClient(
		player,
		"Success",
		challenge.species,
		challenge.rarity,
		challenge.lassoName,
		imprint,
		creatureType
	)

	monster:Destroy()

	local refreshEvent = Services.Parent.Systems:FindFirstChild("PetDisplayRefresh")
	if refreshEvent and refreshEvent:IsA("BindableEvent") then
		refreshEvent:Fire(player)
	end

	-- Capturing grants no pet XP. Pet XP is awarded only by combat kills.
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

	local data = getPlayerData(player)
	if not data then
		return false, "Player collection unavailable."
	end

	local creatureType = tostring(monster and monster:GetAttribute("CreatureType") or "Pet")
	if creatureType == "Mount" then
		data.Mounts = type(data.Mounts) == "table" and data.Mounts or {}
		if #data.Mounts >= (Config.MaxMounts or 40) then
			return false, "Your mount collection is full (" .. tostring(Config.MaxMounts or 40) .. "/" .. tostring(Config.MaxMounts or 40) .. ")."
		end
	else
		data.Pets = type(data.Pets) == "table" and data.Pets or {}
		if #data.Pets >= (Config.MaxPets or 60) then
			return false, "Your pet backpack is full (" .. tostring(Config.MaxPets or 60) .. "/" .. tostring(Config.MaxPets or 60) .. ")."
		end
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
	if monster:GetAttribute("QuestNoCapture") then
		return false, "This quest creature must be defeated, not captured."
	end
	local questOwner = tonumber(monster:GetAttribute("QuestOwnerUserId"))
	if questOwner and questOwner ~= player.UserId then
		return false, "That quest creature belongs to another player's objective."
	end

	local playerRoot = getCharacterRoot(player)
	local monsterPosition = getPosition(monster)
	if not playerRoot or not monsterPosition then
		return false, "Target unavailable."
	end
	if (playerRoot.Position - monsterPosition).Magnitude > MAX_RANGE then
		return false, "Too far away!"
	end

	local species, rarity, difficulty = getMonsterInfo(monster)
	local lassoName, lassoStrength = getLassoStats(player)
	local minimumStrength = tonumber((Config.RarityMinLassoStrength or {})[rarity]) or 0

	if lassoStrength < minimumStrength then
		return false,
			tostring(lassoName)
			.. " is too weak to capture "
			.. tostring(rarity)
			.. (creatureType == "Mount" and " mounts" or " pets")
			.. ". Use a lasso with at least "
			.. tostring(minimumStrength)
			.. " Strength."
	end

	lastAttempt[player] = attemptTime

	local zoneWidth, speed, requiredHits, roundDuration, clockTolerance = challengeSettings(rarity, lassoStrength, difficulty)

	local activeEffects = type(data.ActiveEffects) == "table" and data.ActiveEffects or {}
	if activeEffects.NextCaptureTranquiliser then
		local tranquiliser = Config.Potions and Config.Potions["Tranquiliser Potion"]
		speed *= math.max(0.1, tonumber(tranquiliser and tranquiliser.SpeedMultiplier) or 0.5)
		activeEffects.NextCaptureTranquiliser = false
	end

	local zoneStart = randomZoneStart(zoneWidth)
	local castStarted = serverNow() + 0.12
	local startTime = castStarted + Motion.ReadyTime

	local challenge = {
		id = HttpService:GenerateGUID(false),
		monster = monster,
		species = species,
		rarity = rarity,
		creatureType = creatureType,
		lassoName = lassoName,
		zoneStart = zoneStart,
		zoneWidth = zoneWidth,
		speed = speed,
		requiredHits = requiredHits,
		hits = 0,
		round = 1,
		roundDuration = roundDuration,
		startTime = startTime,
		deadline = startTime + roundDuration,
		clockTolerance = clockTolerance,
		resolving = false,
		character = player.Character,
		ready = false,
	}
	challenges[player] = challenge

	ActionLockService:Begin(player, "Capture")
	createRopeEffect(player, monster, requiredHits, castStarted)
	monster:SetAttribute("BeingCaptured", true)
	monster:SetAttribute("CaptureOwnerUserId", player.UserId)

	pcall(function()
		PetAnimator:PlayStruggle(monster, math.min(roundDuration, 1.2))
	end)

	task.delay(math.max(0, castStarted + Motion.LandTime - serverNow()), function()
		if challenges[player] ~= challenge or not monster.Parent then return end
		challenge.ready = true
		if player.Character then player.Character:SetAttribute("LassoPhase", "Holding") end
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
		roundDuration,
		requiredHits,
		0
	)
	end)

	scheduleRoundTimeout(player, challenge)

	return true, "Lasso challenge started.", true
end

RemoteGuard.Connect(CaptureRemote, "Capture", function(player, action, ...)
	local args = {...}

	if action == "Throw" then
		local monster = args[1]
		local ok, success, message, alreadyNotified = pcall(function()
			return CaptureService:Capture(player, monster)
		end)
		if not ok then
            finishRopeEffect(player, false)
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
            finishRopeEffect(player, false)
			warn("[WildernessPets] Capture resolve error: " .. tostring(err))
			local challenge = challenges[player]
			if challenge then
				challenges[player] = nil
				clearMonsterCaptureState(player, challenge.monster)
			else
				local folder = getMonsterFolder()
				if folder then
					for _, monster in ipairs(folder:GetChildren()) do
						if monster:GetAttribute("CaptureOwnerUserId") == player.UserId then
							clearMonsterCaptureState(player, monster)
							monster:SetAttribute("InCombat", false)
							if monster:GetAttribute("CombatOwnerUserId") == player.UserId then
								monster:SetAttribute("CombatOwnerUserId", nil)
							end
							pcall(function() PetAnimator:PlayIdle(monster) end)
						end
					end
				end
			end
			ActionLockService:End(player, "Capture")
			CaptureRemote:FireClient(player, "Error", "The lasso attempt could not finish. Please try again.")
		end
	end
end)

-- Cancel cleanly on death, respawn, target removal, or walking beyond the tether.
RunService.Heartbeat:Connect(function()
    for player, challenge in pairs(challenges) do
        local humanoid = getHumanoid(player)
        local root = getCharacterRoot(player)
        local targetPosition = challenge.monster.Parent and getPosition(challenge.monster)
        if player.Character ~= challenge.character or not humanoid or humanoid.Health <= 0
            or not root or not targetPosition or (root.Position-targetPosition).Magnitude > MAX_RANGE + 10 then
            challenges[player] = nil
            finishRopeEffect(player, false)
            clearMonsterCaptureState(player, challenge.monster)
            ActionLockService:End(player, "Capture")
            CaptureRemote:FireClient(player, "Error", "The lasso was released.")
        end
    end
end)

Players.PlayerRemoving:Connect(function(player)
    clearRopeEffect(player)
	local challenge = challenges[player]
	if challenge then
		clearMonsterCaptureState(player, challenge.monster)
	end
	challenges[player] = nil
	lastAttempt[player] = nil
end)

return CaptureService
