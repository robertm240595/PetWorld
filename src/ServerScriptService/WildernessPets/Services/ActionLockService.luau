local Players = game:GetService("Players")

local Service = {}

local COOLDOWN_SECONDS = 15
local states = setmetatable({}, {__mode = "k"})

local function now()
	return workspace:GetServerTimeNow()
end

local function getState(player)
	local state = states[player]
	if not state then
		state = {
			active = {},
			blockedUntil = 0,
		}
		states[player] = state
	end
	return state
end

local function hasActiveAction(state)
	for _, active in pairs(state.active) do
		if active then
			return true
		end
	end
	return false
end

local function publish(player, state)
	if not player or not player.Parent then
		return
	end
	player:SetAttribute("HomeTeleportActionActive", hasActiveAction(state))
	player:SetAttribute("HomeTeleportBlockedUntil", state.blockedUntil or 0)
end

function Service:Initialize(player)
	local state = getState(player)
	publish(player, state)
end

function Service:Begin(player, reason)
	if not player then
		return
	end
	local state = getState(player)
	state.active[tostring(reason or "Action")] = true
	publish(player, state)
end

function Service:End(player, reason)
	if not player then
		return
	end
	local state = getState(player)
	local key = tostring(reason or "Action")
	if not state.active[key] then
		publish(player, state)
		return
	end
	state.active[key] = nil
	state.blockedUntil = math.max(state.blockedUntil or 0, now() + COOLDOWN_SECONDS)
	publish(player, state)
end

function Service:Touch(player)
	if not player then
		return
	end
	local state = getState(player)
	state.blockedUntil = math.max(state.blockedUntil or 0, now() + COOLDOWN_SECONDS)
	publish(player, state)
end

function Service:AllowReturnHomeNow(player)
	if not player then
		return
	end
	local state = getState(player)
	state.blockedUntil = now()
	publish(player, state)
end

function Service:GetRemaining(player)
	local state = getState(player)
	return math.max(0, (state.blockedUntil or 0) - now())
end

function Service:IsActive(player)
	return hasActiveAction(getState(player))
end

function Service:CanReturnHome(player)
	local state = getState(player)
	if hasActiveAction(state) then
		return false, "You can't return to your plot while in combat or capturing.", 0
	end
	local remaining = math.max(0, (state.blockedUntil or 0) - now())
	if remaining > 0 then
		return false, "Return to plot available in " .. tostring(math.ceil(remaining)) .. "s.", remaining
	end
	return true, "Ready.", 0
end

Players.PlayerRemoving:Connect(function(player)
	states[player] = nil
end)

return Service
