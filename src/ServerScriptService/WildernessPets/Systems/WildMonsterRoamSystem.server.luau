local PetAnimator = require(script.Parent.PetAnimator)
local Config = require(game.ReplicatedStorage.WildernessPets.Shared.Config)
--[[
    WildMonsterRoamSystem
    Makes wild, uncaptured monsters roam freely around the map.
    Each monster wanders to random positions within the wilderness area.
    Roaming pauses when a monster is being captured or has been captured.
--]]

local WildMonsters = workspace:WaitForChild("WildernessPets"):WaitForChild("WildMonsters")

-- Map bounds for roaming (wilderness area outside town)
local spawnTuning = Config.WildSpawn or {}
local mapRadius = math.max(300, tonumber(spawnTuning.MaxRadius) or 640)
local MAP_MIN_X = -mapRadius
local MAP_MAX_X = mapRadius
local MAP_MIN_Z = -mapRadius
local MAP_MAX_Z = mapRadius

-- Keep monsters distributed outside the town/plot hub instead of collapsing inward.
local TOWN_CENTER_RADIUS = math.max(120, (tonumber(spawnTuning.MinRadius) or 190) - 20)

-- Roaming parameters
local ROAM_RADIUS = math.max(80, tonumber(spawnTuning.RoamMaxDistance) or 120)
local MIN_ROAM_RADIUS = math.max(25, tonumber(spawnTuning.RoamMinDistance) or 45)
local MOVE_STEPS = 24            -- movement interpolation steps
local MOVE_STEP_DELAY = 0.08     -- seconds between steps
local MIN_PAUSE = 1.5            -- min pause at destination
local MAX_PAUSE = 4.5            -- max pause at destination
local GROUND_Y = 17              -- fixed Y height for monsters

local activeCoroutines = {}

------------------------------------------------------------
-- Pick a valid roaming target near the monster's current position
------------------------------------------------------------
local function pickRoamTarget(currentPos)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances = {workspace.Terrain}

    for _ = 1, 12 do
        local angle = math.random() * math.pi * 2
        local distance = math.random(MIN_ROAM_RADIUS, ROAM_RADIUS)
        local targetX = currentPos.X + math.cos(angle) * distance
        local targetZ = currentPos.Z + math.sin(angle) * distance

        targetX = math.clamp(targetX, MAP_MIN_X, MAP_MAX_X)
        targetZ = math.clamp(targetZ, MAP_MIN_Z, MAP_MAX_Z)

        local distFromCenter = math.sqrt(targetX * targetX + targetZ * targetZ)
        if distFromCenter >= TOWN_CENTER_RADIUS then
            local hit = workspace:Raycast(
                Vector3.new(targetX, 300, targetZ),
                Vector3.new(0, -650, 0),
                params
            )

            if hit and hit.Normal.Y > 0.65 and hit.Material ~= Enum.Material.Water then
                return hit.Position
            end
        end
    end

    return Vector3.new(currentPos.X, GROUND_Y, currentPos.Z)
end

------------------------------------------------------------
-- Roaming coroutine for a single monster
------------------------------------------------------------
local function roamMonster(monster)
    PetAnimator:_getRig(monster)
    local grounded = PetAnimator:GroundPosition(monster, monster.PrimaryPart.Position)
    monster:PivotTo(CFrame.new(grounded) * monster.PrimaryPart.CFrame.Rotation)
    -- Initialize after grounding so the cached base is correct.
    local rig = PetAnimator:_getRig(monster)
    rig.base = monster.PrimaryPart.CFrame
    PetAnimator:PlayIdle(monster)
    -- Wait a random initial delay so monsters don't all move in sync
    task.wait(math.random(0, 3))

    while monster and monster.Parent do
        -- Stop roaming if captured or being captured
        if monster:GetAttribute("Dead") or monster:GetAttribute("Captured") or monster:GetAttribute("BeingCaptured") or monster:GetAttribute("InCombat") then
            -- Wait and check again periodically until the monster is destroyed or freed
            while monster and monster.Parent do
                if not monster:GetAttribute("Dead") and not monster:GetAttribute("Captured") and not monster:GetAttribute("BeingCaptured") and not monster:GetAttribute("InCombat") then
                    break
                end
                task.wait(0.5)
            end
        end

        if not monster or not monster.Parent then
            break
        end

        local currentPos = monster:GetPivot().Position
        local target = pickRoamTarget(currentPos)

        local running = math.random() < 0.25
        local valid = PetAnimator:MoveTo(monster, target, running)

        if valid and monster and monster.Parent then
            -- Pause at destination
            task.wait(math.random(MIN_PAUSE * 10, MAX_PAUSE * 10) / 10)
        end
    end
end

------------------------------------------------------------
-- Start roaming for a monster
------------------------------------------------------------
local function startRoaming(monster)
    if not monster:IsA("Model") then
        return
    end
    if not monster.PrimaryPart then
        -- Try to find a primary part
        local part = monster:FindFirstChildWhichIsA("BasePart", true)
        if part then
            monster.PrimaryPart = part
        else
            return
        end
    end

    -- Don't start duplicate coroutines
    if activeCoroutines[monster] then
        return
    end

    activeCoroutines[monster] = task.spawn(function()
        roamMonster(monster)
        activeCoroutines[monster] = nil
    end)
end

------------------------------------------------------------
-- Initialize roaming for all existing wild monsters
------------------------------------------------------------
for _, monster in ipairs(WildMonsters:GetChildren()) do
    startRoaming(monster)
end

------------------------------------------------------------
-- Handle monsters added later (e.g. respawns)
------------------------------------------------------------
WildMonsters.ChildAdded:Connect(function(monster)
    task.wait(0.5) -- let the monster fully initialize
    startRoaming(monster)
end)

WildMonsters.ChildRemoved:Connect(function(monster)
    activeCoroutines[monster] = nil
end)

print("[WildernessPets] Wild Monster Roam System loaded for " .. #WildMonsters:GetChildren() .. " monsters.")
