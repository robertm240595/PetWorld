-- MeshVisualEffects: Adds visual effects to all mesh models in the town
-- Huts get warm lantern lights, fountain gets water particles + glow, NPCs get subtle ambient sparkles

local Town = workspace:FindFirstChild("WildernessPets")
if not Town then return end

local MapTown = Town:FindFirstChild("Map") and Town.Map:FindFirstChild("Town")
local NPCsFolder = Town:FindFirstChild("NPCs")
if not MapTown then return end

-- Helper: get the highest Y point of a model by scanning its MeshParts
local function getTopPosition(model)
	local topY = -math.huge
	local topPos = nil
	for _, desc in ipairs(model:GetDescendants()) do
		if desc:IsA("BasePart") then
			local pos = desc.Position
			if pos.Y > topY then
				topY = pos.Y
				topPos = pos
			end
		end
	end
	if not topPos then
		local pivot = model:GetPivot()
		topPos = pivot.Position
	end
	return topPos
end

-- Helper: get the center position of a model
local function getCenterPosition(model)
	local pivot = model:GetPivot()
	return pivot.Position
end

-- Helper: get all MeshParts in a model
local function getMeshParts(model)
	local parts = {}
	for _, desc in ipairs(model:GetDescendants()) do
		if desc:IsA("MeshPart") then
			table.insert(parts, desc)
		end
	end
	return parts
end

-- === FOUNTAIN EFFECTS ===
local function setupFountain(fountainModel)
	local centerPos = getCenterPosition(fountainModel)
	local topPos = getTopPosition(fountainModel)
	
	-- Find the main mesh part to attach effects to
	local meshParts = getMeshParts(fountainModel)
	local mainPart = meshParts[1]
	if not mainPart then return end
	
	-- Attach a PointLight for warm glow at the top of the fountain
	local glowLight = Instance.new("PointLight")
	glowLight.Name = "FountainGlow"
	glowLight.Color = Color3.fromRGB(100, 180, 255)
	glowLight.Brightness = 2
	glowLight.Range = 20
	glowLight.Enabled = true
	glowLight.Parent = mainPart
	
	-- Attach a subtle blue neon highlight to the mesh
	mainPart.Material = Enum.Material.Glass
	
	-- Create water particle emitter
	local waterParticles = Instance.new("ParticleEmitter")
	waterParticles.Name = "WaterSplash"
	waterParticles.Texture = "rbxassetid://241876918" -- water drop texture
	waterParticles.Color = ColorSequence.new(Color3.fromRGB(150, 200, 255))
	waterParticles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(1, 0.1),
	})
	waterParticles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(1, 1),
	})
	waterParticles.Lifetime = NumberRange.new(1.5, 2.5)
	waterParticles.Rate = 30
	waterParticles.Speed = NumberRange.new(2, 5)
	waterParticles.SpreadAngle = Vector2.new(45, 45)
	waterParticles.Rotation = NumberRange.new(0, 360)
	waterParticles.RotSpeed = NumberRange.new(50, 100)
	waterParticles.Acceleration = Vector3.new(0, -8, 0) -- gravity pulls water down
	waterParticles.EmissionDirection = Enum.NormalId.Top
	waterParticles.LightEmission = 0.5
	waterParticles.Enabled = true
	waterParticles.Parent = mainPart
	
	-- Create a gentle mist effect around the fountain base
	local mistAttachment = Instance.new("Attachment")
	mistAttachment.Name = "MistAttachment"
	mistAttachment.Position = Vector3.new(0, 0, 0)
	mistAttachment.Parent = mainPart
	
	local mistParticles = Instance.new("ParticleEmitter")
	mistParticles.Name = "FountainMist"
	mistParticles.Texture = "rbxassetid://241876918"
	mistParticles.Color = ColorSequence.new(Color3.fromRGB(200, 220, 255))
	mistParticles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 2),
		NumberSequenceKeypoint.new(1, 4),
	})
	mistParticles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.8),
		NumberSequenceKeypoint.new(0.5, 0.5),
		NumberSequenceKeypoint.new(1, 1),
	})
	mistParticles.Lifetime = NumberRange.new(3, 5)
	mistParticles.Rate = 8
	mistParticles.Speed = NumberRange.new(0.5, 1.5)
	mistParticles.SpreadAngle = Vector2.new(180, 180)
	mistParticles.Acceleration = Vector3.new(0, 1, 0) -- mist rises slowly
	mistParticles.LightEmission = 0.3
	mistParticles.Enabled = true
	mistParticles.Parent = mistAttachment
	
	print("[MeshVisualEffects] Fountain effects applied")
end

-- === HUT EFFECTS ===
local function setupHut(hutModel, hutName)
	local meshParts = getMeshParts(hutModel)
	local mainPart = meshParts[1]
	if not mainPart then return end
	
	-- Check if a PointLight already exists (some huts had one from generation)
	local existingLight = mainPart:FindFirstChildOfClass("PointLight")
	if existingLight then
		-- Enhance existing light to be warm and cozy
		existingLight.Name = "HutLanternLight"
		existingLight.Color = Color3.fromRGB(255, 180, 100)
		existingLight.Brightness = 1.5
		existingLight.Range = 18
		existingLight.Enabled = true
	else
		-- Create warm lantern light
	local lanternLight = Instance.new("PointLight")
		lanternLight.Name = "HutLanternLight"
		lanternLight.Color = Color3.fromRGB(255, 180, 100)
		lanternLight.Brightness = 1.5
		lanternLight.Range = 18
		lanternLight.Enabled = true
		lanternLight.Parent = mainPart
	end
	
	-- Add subtle smoke from chimney area (top of hut)
	local smokeAttachment = Instance.new("Attachment")
	smokeAttachment.Name = "SmokeAttachment"
	smokeAttachment.Position = Vector3.new(0, 2, 0) -- offset upward
	smokeAttachment.Parent = mainPart
	
	local smokeParticles = Instance.new("ParticleEmitter")
	smokeParticles.Name = "ChimneySmoke"
	smokeParticles.Texture = "rbxassetid://241876918"
	smokeParticles.Color = ColorSequence.new(Color3.fromRGB(150, 150, 150))
	smokeParticles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(1, 2),
	})
	smokeParticles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(1, 1),
	})
	smokeParticles.Lifetime = NumberRange.new(4, 6)
	smokeParticles.Rate = 5
	smokeParticles.Speed = NumberRange.new(0.5, 1)
	smokeParticles.SpreadAngle = Vector2.new(15, 15)
	smokeParticles.Acceleration = Vector3.new(0, 2, 0) -- smoke rises
	smokeParticles.LightEmission = 0.1
	smokeParticles.Enabled = true
	smokeParticles.Parent = smokeAttachment
	
	print("[MeshVisualEffects] Hut effects applied to " .. hutName)
end

-- === NPC EFFECTS ===
local function setupNPC(npcModel, npcName)
	local meshParts = getMeshParts(npcModel)
	if #meshParts == 0 then return end
	
	-- Find the torso or head part for the main glow
	local mainPart = nil
	for _, part in ipairs(meshParts) do
		if string.find(string.lower(part.Name), "torso") or string.find(string.lower(part.Name), "body") then
			mainPart = part
			break
		end
	end
	if not mainPart then mainPart = meshParts[1] end
	
	-- Add a soft ambient light around the NPC
	local ambientLight = Instance.new("PointLight")
	ambientLight.Name = "NPCAmbientLight"
	-- Different color per NPC for variety
	local npcColors = {
		["LassoKeeperNPC"] = Color3.fromRGB(255, 200, 100), -- warm amber
		["PetMerchantNPC"] = Color3.fromRGB(150, 200, 255), -- soft blue
		["ArenaMasterNPC"] = Color3.fromRGB(255, 100, 100), -- warm red
		["BeastTraderNPC"] = Color3.fromRGB(100, 255, 150), -- emerald green
	}
	ambientLight.Color = npcColors[npcName] or Color3.fromRGB(255, 220, 180)
	ambientLight.Brightness = 0.8
	ambientLight.Range = 8
	ambientLight.Enabled = true
	ambientLight.Parent = mainPart
	
	-- Add subtle sparkle particles around the NPC
	local sparkleAttachment = Instance.new("Attachment")
	sparkleAttachment.Name = "SparkleAttachment"
	sparkleAttachment.Parent = mainPart
	
	local sparkleParticles = Instance.new("ParticleEmitter")
	sparkleParticles.Name = "NPCSparkles"
	sparkleParticles.Texture = "rbxassetid://241876918"
	sparkleParticles.Color = ColorSequence.new(npcColors[npcName] or Color3.fromRGB(255, 220, 180))
	sparkleParticles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.15),
		NumberSequenceKeypoint.new(1, 0.05),
	})
	sparkleParticles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.8),
		NumberSequenceKeypoint.new(0.5, 0.3),
		NumberSequenceKeypoint.new(1, 1),
	})
	sparkleParticles.Lifetime = NumberRange.new(2, 3)
	sparkleParticles.Rate = 3
	sparkleParticles.Speed = NumberRange.new(0.3, 0.8)
	sparkleParticles.SpreadAngle = Vector2.new(180, 180)
	sparkleParticles.Acceleration = Vector3.new(0, 0.5, 0)
	sparkleParticles.LightEmission = 0.8
	sparkleParticles.Enabled = true
	sparkleParticles.Parent = sparkleAttachment
	
	print("[MeshVisualEffects] NPC effects applied to " .. npcName)
end

-- === APPLY ALL EFFECTS ===

-- Fountain
local fountain = MapTown:FindFirstChild("TownFountain")
if fountain then
	setupFountain(fountain)
end

-- Huts
local hutNames = {"LassoKeeperHut", "PetMerchantHut", "ArenaMasterHut", "BeastTraderHut"}
for _, hutName in ipairs(hutNames) do
	local hut = MapTown:FindFirstChild(hutName)
	if hut then
		setupHut(hut, hutName)
	end
end

-- NPCs
if NPCsFolder then
	local npcNames = {"LassoKeeperNPC", "PetMerchantNPC", "ArenaMasterNPC", "BeastTraderNPC"}
	for _, npcName in ipairs(npcNames) do
		local npc = NPCsFolder:FindFirstChild(npcName)
		if npc then
			setupNPC(npc, npcName)
		end
	end
end

print("[MeshVisualEffects] All visual effects applied successfully")