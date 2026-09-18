local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Root = ReplicatedStorage:WaitForChild("WildernessPets")
local ShopRemote = Root:WaitForChild("Remotes"):WaitForChild("Shop")

local Service = {}
local active = setmetatable({}, {__mode = "k"})
local registered = setmetatable({}, {__mode = "k"})
local started = false

local function normalized(name)
	return tostring(name or ""):lower():gsub("[^%w]", "")
end

local function isTraderCandidate(instance)
	if not instance:IsA("Model") then
		return false
	end

	local name = normalized(instance.Name)
	return name:find("beasttrader", 1, true) ~= nil
		or name:find("beastmaster", 1, true) ~= nil
end

local function getInteractionPart(model)
	if not model or not model.Parent then return nil end
	if model.PrimaryPart then return model.PrimaryPart end

	for _, preferred in ipairs({"HumanoidRootPart", "Head", "body_geom", "Body"}) do
		local part = model:FindFirstChild(preferred, true)
		if part and part:IsA("BasePart") then
			return part
		end
	end

	return model:FindFirstChildWhichIsA("BasePart", true)
end

local function distanceToTrader(player, model)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local part = getInteractionPart(model)
	if not root or not part then
		return math.huge
	end
	return (root.Position - part.Position).Magnitude
end

function Service:Register(model)
	if registered[model] or not isTraderCandidate(model) then
		return false
	end

	local part = getInteractionPart(model)
	if not part then
		return false
	end

	registered[model] = true

	local prompt = part:FindFirstChild("BeastTraderPrompt")
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.Name = "BeastTraderPrompt"
		prompt.ActionText = "Trade Beasts"
		prompt.ObjectText = "Beast Trader"
		prompt.MaxActivationDistance = 12
		prompt.HoldDuration = 0.15
		prompt.RequiresLineOfSight = false
		prompt.Parent = part
	end

	prompt.Triggered:Connect(function(player)
		if not player or not player.Parent then return end
		active[player] = {
			trader = model,
			expiresAt = os.clock() + 30,
		}
		ShopRemote:FireClient(player, "OpenBeastTrader")
	end)

	return true
end

function Service:CanTrade(player)
	local session = active[player]
	if not session or os.clock() > session.expiresAt then
		active[player] = nil
		return false, "Speak to the Beast Trader first."
	end

	local trader = session.trader
	if not trader or not trader.Parent then
		active[player] = nil
		return false, "The Beast Trader is unavailable."
	end

	if distanceToTrader(player, trader) > 20 then
		return false, "Move closer to the Beast Trader."
	end

	session.expiresAt = os.clock() + 30
	return true
end

function Service:Close(player)
	active[player] = nil
end

function Service:Init()
	if started then return end
	started = true

	local function scan(instance)
		if isTraderCandidate(instance) then
			task.defer(function()
				Service:Register(instance)
			end)
		end
	end

	for _, instance in ipairs(workspace:GetDescendants()) do
		scan(instance)
	end

	workspace.DescendantAdded:Connect(scan)

	-- Some maps are assembled shortly after the server scripts start.
	task.spawn(function()
		for _ = 1, 12 do
			task.wait(2)
			for _, instance in ipairs(workspace:GetDescendants()) do
				if isTraderCandidate(instance) and not registered[instance] then
					Service:Register(instance)
				end
			end
		end
	end)
end

Players.PlayerRemoving:Connect(function(player)
	active[player] = nil
end)

return Service
