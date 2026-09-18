-- Visual effects for town mesh models (huts, fountain, NPCs)
-- Uses a helper that works with MeshPart instances

local town = workspace:FindFirstChild("WildernessPets") and workspace.WildernessPets.Map:FindFirstChild("Town")
local npcs = workspace:FindFirstChild("WildernessPets") and workspace.WildernessPets.NPCs

if not town or not npcs then
	return
end

-- Helper: find the highest point of a model by checking all BasePart descendants
local function getTopPart(model)
	local topPart = nil
	local topY = -math.huge
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			local partTop = part.Position.Y + (part.Size.Y / 2)
			if partTop > topY then
				topY = partTop
				topPart = part
			end
		end
	end
	return topPart, topY
end

-- Helper: find a central part of a model for light attachment
local function getCenterPart(model)
	local bestPart = nil
	local bestDist = math.huge
	local pivot = model:GetPivot()
	local center = pivot.Position
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			local dist = (part.Position - center).Magnitude
			if dist < bestDist then
				bestDist = dist
				bestPart = part
			end
		end
	end
	return bestPart
end

-- ============================================
-- HUT EFFECTS: Warm lantern lights + chimney smoke
-- ============================================

local hutConfigs = {
	{model = town:FindFirstChild("LassoKeeperHut"), lightColor = Color3.fromRGB(255, 180, 100), smokeColor = Color3.fromRGB(200, 180, 160)},
	{model = town:FindFirstChild("PetMerchantHut"), lightColor = Color3.fromRGB(255, 200, 120), smokeColor = Color3.fromRGB(220, 200, 180)},
	{model = town:FindFirstChild("ArenaMasterHut"), lightColor = Color3.fromRGB(255, 100, 80), smokeColor = Color3.fromRGB(180, 160, 140)},
	{model = town:FindFirstChild("BeastTraderHut"), lightColor = Color3.fromRGB(255, 170, 90), smokeColor = Color3.fromRGB(160, 140, 120)},
}

for _, config in ipairs(hutConfigs) do
	if config.model then
		-- Warm PointLight at center of hut
		local centerPart = getCenterPart(config.model)
		if centerPart then
			local light = Instance.new("PointLight")
			light.Color = config.lightColor
			light.Brightness = 2
			light.Range = 30
			light.Shadows = true
			light.Parent = centerPart
		end

		-- Chimney smoke from the top of the hut
		local topPart, topY = getTopPart(config.model)
		if topPart then
			local attachment = Instance.new("Attachment")
			attachment.Name = "SmokeAttachment"
			attachment.Position = Vector3.new(0, topPart.Size.Y / 2, 0)
			attachment.Parent = topPart

			local smoke = Instance.new("ParticleEmitter")
			smoke.Name = "ChimneySmoke"
			smoke.Texture = "rbxassetid://243660364"
			smoke.Color = ColorSequence.new(config.smokeColor)
			smoke.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.3),
				NumberSequenceKeypoint.new(1, 1),
			})
			smoke.Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(1, 6),
			})
			smoke.Lifetime = NumberRange.new(3, 5)
			smoke.Rate = 8
			smoke.Speed = NumberRange.new(2, 4)
			smoke.SpreadAngle = Vector2.new(15, 15)
			smoke.Rotation = NumberRange.new(0, 360)
			smoke.RotSpeed = NumberRange.new(-10, 10)
			smoke.Parent = attachment
		end
	end
end

-- ============================================
-- FOUNTAIN EFFECTS: Water glow + splash particles
-- ============================================

local fountain = town:FindFirstChild("TownFountain")
if fountain then
	local centerPart = getCenterPart(fountain)
	local topPart, topY = getTopPart(fountain)

	-- Blue water glow PointLight
	if centerPart then
		local waterLight = Instance.new("PointLight")
		waterLight.Color = Color3.fromRGB(100, 180, 255)
		waterLight.Brightness = 3
		waterLight.Range = 35
		waterLight.Shadows = true
		waterLight.Parent = centerPart
	end

	-- Water splash particles from the top
	if topPart then
		local attachment = Instance.new("Attachment")
		attachment.Name = "WaterSplash"
		attachment.Position = Vector3.new(0, topPart.Size.Y / 2, 0)
		attachment.Parent = topPart

		local splash = Instance.new("ParticleEmitter")
		splash.Name = "WaterSplash"
		splash.Texture = "rbxassetid://243660364"
		splash.Color = ColorSequence.new(Color3.fromRGB(150, 200, 255))
		splash.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.2),
			NumberSequenceKeypoint.new(1, 1),
		})
		splash.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 2),
			NumberSequenceKeypoint.new(1, 0.5),
		})
		splash.Lifetime = NumberRange.new(1, 2)
		splash.Rate = 20
		splash.Speed = NumberRange.new(3, 6)
		splash.SpreadAngle = Vector2.new(45, 45)
		splash.Acceleration = Vector3.new(0, -10, 0)
		splash.Parent = attachment
	end

	-- Sparkle particles around the fountain base
	for _, part in fountain:GetDescendants() do
		if part:IsA("BasePart") then
			local sparkle = Instance.new("ParticleEmitter")
			sparkle.Name = "WaterSparkle"
			sparkle.Texture = "rbxassetid://241876375"
			sparkle.Color = ColorSequence.new(Color3.fromRGB(150, 200, 255))
			sparkle.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.7),
				NumberSequenceKeypoint.new(1, 1),
			})
			sparkle.Size = NumberSequence.new(0.4)
			sparkle.Lifetime = NumberRange.new(1, 2)
			sparkle.Rate = 3
			sparkle.Speed = NumberRange.new(1, 2)
			sparkle.LightEmission = 0.8
			sparkle.Parent = part
		end
	end
end

-- ============================================
-- NPC EFFECTS: Subtle glow beneath each NPC
-- ============================================

local npcConfigs = {
	{model = npcs:FindFirstChild("LassoKeeperNPC"), color = Color3.fromRGB(255, 200, 100)},
	{model = npcs:FindFirstChild("PetMerchantNPC"), color = Color3.fromRGB(150, 255, 200)},
	{model = npcs:FindFirstChild("ArenaMasterNPC"), color = Color3.fromRGB(255, 100, 100)},
	{model = npcs:FindFirstChild("BeastTraderNPC"), color = Color3.fromRGB(200, 150, 100)},
}

for _, config in ipairs(npcConfigs) do
	if config.model then
		local centerPart = getCenterPart(config.model)
		if centerPart then
			local glow = Instance.new("PointLight")
			glow.Color = config.color
			glow.Brightness = 1.5
			glow.Range = 12
			glow.Shadows = false
			glow.Parent = centerPart
		end
	end
end
