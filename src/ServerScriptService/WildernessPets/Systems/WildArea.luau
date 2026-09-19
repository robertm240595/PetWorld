local Config = require(game.ReplicatedStorage.WildernessPets.Shared.Config)

local WildArea = {}

local cachedBounds
local cacheAt = 0
local CACHE_SECONDS = 10

local function fallbackBounds()
    local spawn = Config.WildSpawn or {}
    local half = math.max(
        300,
        tonumber(spawn.FallbackHalfExtent)
            or tonumber(spawn.MaxRadius)
            or 640
    )
    return {
        MinX = -half,
        MaxX = half,
        MinZ = -half,
        MaxZ = half,
        DetectedBarrierBounds = false,
    }
end

local function looksLikePerimeter(part)
    if not part:IsA("BasePart") then return false end
    if not part.Anchored or not part.CanCollide then return false end

    local normalized = part.Name:lower():gsub("[^%w]", "")
    local named = normalized:find("barrier", 1, true)
        or normalized:find("boundary", 1, true)
        or normalized:find("border", 1, true)
        or normalized:find("perimeter", 1, true)

    local horizontalLong = math.max(part.Size.X, part.Size.Z)
    local horizontalShort = math.min(part.Size.X, part.Size.Z)
    local invisibleWall = part.Transparency >= 0.95
        and part.Size.Y >= 12
        and horizontalLong >= 120
        and horizontalShort <= 50

    local namedPerimeter = named ~= nil
        and part.Size.Y >= 8
        and horizontalLong >= 120

    return namedPerimeter or invisibleWall
end

function WildArea:GetBounds(force)
    local now = os.clock()
    if not force and cachedBounds and now - cacheAt < CACHE_SECONDS then
        return cachedBounds
    end

    local bounds = fallbackBounds()
    local spawn = Config.WildSpawn or {}
    local margin = math.max(8, tonumber(spawn.BoundaryMargin) or 18)

    local east
    local west
    local north
    local south

    for _, item in ipairs(workspace:GetDescendants()) do
        if looksLikePerimeter(item) then
            local p = item.Position
            local farFromHub = math.max(math.abs(p.X), math.abs(p.Z)) >= 250
            if farFromHub then
                if math.abs(p.X) >= math.abs(p.Z) then
                    if p.X > 0 and (not east or p.X < east) then
                        east = p.X
                    elseif p.X < 0 and (not west or p.X > west) then
                        west = p.X
                    end
                else
                    if p.Z > 0 and (not south or p.Z < south) then
                        south = p.Z
                    elseif p.Z < 0 and (not north or p.Z > north) then
                        north = p.Z
                    end
                end
            end
        end
    end

    if east and west and south and north then
        local minX = west + margin
        local maxX = east - margin
        local minZ = north + margin
        local maxZ = south - margin

        if maxX - minX >= 500 and maxZ - minZ >= 500 then
            bounds = {
                MinX = minX,
                MaxX = maxX,
                MinZ = minZ,
                MaxZ = maxZ,
                DetectedBarrierBounds = true,
            }
        end
    end

    cachedBounds = bounds
    cacheAt = now
    return bounds
end

function WildArea:RandomXZ(random, minCenterRadius)
    local bounds = self:GetBounds()
    local rng = random or Random.new()
    local minRadius = math.max(0, tonumber(minCenterRadius) or 0)

    for _ = 1, 20 do
        local x = rng:NextNumber(bounds.MinX, bounds.MaxX)
        local z = rng:NextNumber(bounds.MinZ, bounds.MaxZ)
        if math.sqrt(x*x + z*z) >= minRadius then
            return x, z
        end
    end

    return nil, nil
end

function WildArea:ClampXZ(x, z)
    local bounds = self:GetBounds()
    return math.clamp(x, bounds.MinX, bounds.MaxX),
        math.clamp(z, bounds.MinZ, bounds.MaxZ)
end

function WildArea:ContainsXZ(x, z)
    local bounds = self:GetBounds()
    return x >= bounds.MinX and x <= bounds.MaxX
        and z >= bounds.MinZ and z <= bounds.MaxZ
end

return WildArea
