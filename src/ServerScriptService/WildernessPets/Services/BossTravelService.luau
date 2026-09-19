local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Root = ReplicatedStorage:WaitForChild("WildernessPets")
local Remotes = Root:WaitForChild("Remotes")
local BossTravelRemote = Remotes:WaitForChild("BossTravel")
local QuestConfig = require(Root.Shared.QuestConfig)

local QuestService = require(script.Parent.QuestService)
local ActionLockService = require(script.Parent.ActionLockService)

local Service = {}
local started = false
local world
local travelWorld
local gates = {}
local touchDebounce = setmetatable({}, {__mode = "k"})

local ROCK = Color3.fromRGB(58, 60, 61)
local DARK_ROCK = Color3.fromRGB(31, 34, 35)
local DEEP_ROCK = Color3.fromRGB(20, 23, 25)

local function terrainPoint(x, z, fallbackY)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances = {workspace.Terrain}

    local hit = workspace:Raycast(
        Vector3.new(x, 420, z),
        Vector3.new(0, -850, 0),
        params
    )

    if hit and hit.Material ~= Enum.Material.Water then
        return hit.Position
    end

    return Vector3.new(x, fallbackY or 17, z)
end

local function basePart(parent, name, size, cframe, color, material, transparency)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.CFrame = cframe
    part.Color = color or ROCK
    part.Material = material or Enum.Material.Rock
    part.Transparency = transparency or 0
    part.Anchored = true
    part.CanCollide = true
    part.CanTouch = false
    part.CanQuery = true
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Parent = parent
    return part
end

local function meshRock(parent, name, size, cframe, color, material, transparency)
    local holder = Instance.new("Part")
    holder.Name = name
    holder.Size = Vector3.new(1, 1, 1)
    holder.CFrame = cframe
    holder.Color = color or ROCK
    holder.Material = material or Enum.Material.Rock
    holder.Transparency = transparency or 0
    holder.Anchored = true
    holder.CanCollide = false
    holder.CanTouch = false
    holder.CanQuery = false
    holder.CastShadow = true
    holder.Parent = parent

    local mesh = Instance.new("SpecialMesh")
    mesh.MeshType = Enum.MeshType.Sphere
    mesh.Scale = size
    mesh.Parent = holder

    return holder
end

local function meshWedge(parent, name, size, cframe, color, material)
    local holder = Instance.new("Part")
    holder.Name = name
    holder.Size = Vector3.new(1, 1, 1)
    holder.CFrame = cframe
    holder.Color = color
    holder.Material = material or Enum.Material.SmoothPlastic
    holder.Anchored = true
    holder.CanCollide = false
    holder.CanTouch = false
    holder.CanQuery = false
    holder.Parent = parent

    local mesh = Instance.new("SpecialMesh")
    mesh.MeshType = Enum.MeshType.Wedge
    mesh.Scale = size
    mesh.Parent = holder
    return holder
end

local function meshOrb(parent, name, size, cframe, color, material, transparency)
    return meshRock(
        parent,
        name,
        size,
        cframe,
        color,
        material or Enum.Material.SmoothPlastic,
        transparency
    )
end

local function pointLight(parent, color, brightness, range)
    local light = Instance.new("PointLight")
    light.Color = color
    light.Brightness = brightness
    light.Range = range
    light.Shadows = true
    light.Parent = parent
    return light
end

local function bossLabel(part, title, subtitle, color, distance)
    local gui = Instance.new("BillboardGui")
    gui.Name = "BossLabel"
    gui.Size = UDim2.fromOffset(360, 72)
    gui.StudsOffsetWorldSpace = Vector3.new(0, 9, 0)
    gui.MaxDistance = distance or 180
    gui.AlwaysOnTop = false
    gui.Parent = part

    local titleLabel = Instance.new("TextLabel")
    titleLabel.BackgroundTransparency = 1
    titleLabel.Size = UDim2.new(1, 0, 0, 40)
    titleLabel.Font = Enum.Font.GothamBlack
    titleLabel.TextSize = 24
    titleLabel.TextStrokeTransparency = .2
    titleLabel.TextColor3 = color
    titleLabel.Text = title
    titleLabel.Parent = gui

    local sub = Instance.new("TextLabel")
    sub.BackgroundTransparency = 1
    sub.Position = UDim2.fromOffset(0, 39)
    sub.Size = UDim2.new(1, 0, 0, 25)
    sub.Font = Enum.Font.GothamBold
    sub.TextSize = 12
    sub.TextStrokeTransparency = .3
    sub.TextColor3 = Color3.fromRGB(225, 225, 218)
    sub.Text = subtitle
    sub.Parent = gui
end

local function playerFromTouch(hit)
    if not hit or not hit.Parent then return nil end
    local character = hit:FindFirstAncestorOfClass("Model")
    if not character then return nil end
    return Players:GetPlayerFromCharacter(character)
end

local function characterReady(player)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not character or not humanoid or humanoid.Health <= 0 or not root then
        return nil
    end
    return character
end

local function sendBlocked(player, message)
    BossTravelRemote:FireClient(player, "Blocked", tostring(message or "That passage is not available yet."))
end

local function canTravelNow(player)
    if ActionLockService:IsActive(player) then
        return false, "Finish your current combat or capture before entering a boss cavern."
    end
    return true
end

local function transition(player, destination, arenaName, title, subtitle, questAction)
    local character = characterReady(player)
    if not character then return false end

    BossTravelRemote:FireClient(player, "FadeOut", title, subtitle)
    task.wait(.38)

    if not player.Parent then return false end
    character = characterReady(player)
    if not character then
        BossTravelRemote:FireClient(player, "FadeIn", title, subtitle)
        return false
    end

    character:PivotTo(destination)
    player:SetAttribute("BossArena", arenaName or "")

    task.defer(function()
        if not player.Parent then return end

        if questAction then
            QuestService:OnPlayerAction(player, questAction, {
                BossArena = arenaName,
            })
        end

        -- Refresh compass targets after both entry and return travel.
        QuestService:PushState(player)
    end)

    task.wait(.16)
    BossTravelRemote:FireClient(player, "FadeIn", title, subtitle)
    return true
end

local function makeTrigger(parent, name, cframe, size)
    local trigger = Instance.new("Part")
    trigger.Name = name
    trigger.Size = size or Vector3.new(16, 10, 6)
    trigger.CFrame = cframe
    trigger.Transparency = 1
    trigger.Anchored = true
    trigger.CanCollide = false
    trigger.CanQuery = false
    trigger.CanTouch = true
    trigger.Parent = parent
    return trigger
end

local function connectGate(trigger, gateId, checkAccess, destination, arenaName, title, subtitle, questAction, deniedDestination)
    gates[gateId] = trigger

    trigger.Touched:Connect(function(hit)
        local player = playerFromTouch(hit)
        if not player then return end

        local now = os.clock()
        local playerDebounce = touchDebounce[player]
        if not playerDebounce then
            playerDebounce = {}
            touchDebounce[player] = playerDebounce
        end
        if now < (playerDebounce[gateId] or 0) then return end
        playerDebounce[gateId] = now + 1.5

        local ready, readyMessage = canTravelNow(player)
        if not ready then
            sendBlocked(player, readyMessage)
            if deniedDestination then
                local character = characterReady(player)
                if character then character:PivotTo(deniedDestination) end
            end
            return
        end

        if checkAccess then
            local allowed, message = checkAccess(player)
            if not allowed then
                sendBlocked(player, message)
                if deniedDestination then
                    local character = characterReady(player)
                    if character then character:PivotTo(deniedDestination) end
                end
                return
            end
        end

        transition(
            player,
            destination,
            arenaName,
            title,
            subtitle,
            questAction
        )
    end)
end

local function makeRockArch(parent, origin, width, height, depth, color)
    for index = 0, 10 do
        local t = index / 10
        local angle = math.pi * t
        local x = math.cos(angle) * width * .5
        local y = math.sin(angle) * height
        local rockSize = Vector3.new(
            4.5 + (index % 3) * 1.1,
            5.2 + ((index + 1) % 3) * 1.4,
            depth + (index % 2) * 1.7
        )
        meshRock(
            parent,
            "ArchRock_" .. tostring(index),
            rockSize,
            origin * CFrame.new(x, y, 0)
                * CFrame.Angles(
                    math.rad((index * 13) % 28 - 14),
                    math.rad((index * 29) % 36 - 18),
                    math.rad((index * 17) % 24 - 12)
                ),
            color or ROCK
        )
    end
end

local function addTunnelRibs(parent, origin, length, width, height, color, accent)
    local steps = math.max(4, math.floor(length / 8))

    local floor = basePart(
        parent,
        "TunnelFloor",
        Vector3.new(width, 1.2, length + 8),
        origin * CFrame.new(0, -.6, -length * .5),
        Color3.fromRGB(35, 36, 36),
        Enum.Material.Slate
    )

    local leftCollision = basePart(
        parent,
        "TunnelLeftCollision",
        Vector3.new(2.2, height, length + 6),
        origin * CFrame.new(-width * .55, height * .45, -length * .5),
        DARK_ROCK,
        Enum.Material.Rock,
        1
    )
    leftCollision.CanQuery = false

    local rightCollision = basePart(
        parent,
        "TunnelRightCollision",
        Vector3.new(2.2, height, length + 6),
        origin * CFrame.new(width * .55, height * .45, -length * .5),
        DARK_ROCK,
        Enum.Material.Rock,
        1
    )
    rightCollision.CanQuery = false

    for index = 0, steps do
        local z = -(index / steps) * length
        local yaw = math.rad(((index * 23) % 18) - 9)
        local rib = origin * CFrame.new(0, 0, z) * CFrame.Angles(0, yaw, 0)

        meshRock(
            parent,
            "TunnelLeft_" .. tostring(index),
            Vector3.new(6.5, height * .78, 7.5),
            rib * CFrame.new(-width * .48, height * .35, 0)
                * CFrame.Angles(0, 0, math.rad(-12)),
            index % 2 == 0 and color or DARK_ROCK
        )
        meshRock(
            parent,
            "TunnelRight_" .. tostring(index),
            Vector3.new(6.5, height * .78, 7.5),
            rib * CFrame.new(width * .48, height * .35, 0)
                * CFrame.Angles(0, 0, math.rad(12)),
            index % 2 == 0 and DARK_ROCK or color
        )
        meshRock(
            parent,
            "TunnelRoof_" .. tostring(index),
            Vector3.new(width * .8, 5.5, 7.5),
            rib * CFrame.new(0, height * .82, 0)
                * CFrame.Angles(math.rad((index % 2 == 0) and 8 or -8), 0, 0),
            DARK_ROCK
        )

        if accent and index % 3 == 1 then
            local crystal = meshWedge(
                parent,
                "TunnelCrystal_" .. tostring(index),
                Vector3.new(1.2, 4.2, 1.4),
                rib * CFrame.new(
                    index % 2 == 0 and -width * .34 or width * .34,
                    2.1,
                    .5
                ) * CFrame.Angles(math.rad(-90), 0, math.rad(index * 19)),
                accent,
                Enum.Material.Neon
            )
            pointLight(crystal, accent, .45, 9)
        end
    end

    return floor
end

local function buildHollowfangDepthPassage()
    local settings = QuestConfig.World
    local ground = terrainPoint(settings.CaveXZ.X, settings.CaveXZ.Y, settings.CaveFallbackY)
    local caveEntrance = ground + Vector3.new(0, .15, 0)

    local model = Instance.new("Model")
    model.Name = "HollowfangDeepPassage"
    model.Parent = travelWorld

    local questWorld = world:FindFirstChild("QuestWorld")
    local originalCave = questWorld and questWorld:FindFirstChild("HollowfangCave")
    if originalCave then
        local oldBack = originalCave:FindFirstChild("BackWall")
        if oldBack and oldBack:IsA("BasePart") then
            oldBack.CanCollide = false
            oldBack.CanQuery = false
            oldBack.Transparency = 1
        end
    end

    local start = CFrame.new(caveEntrance + Vector3.new(0, 0, -22))
    addTunnelRibs(
        model,
        start,
        52,
        19,
        13,
        ROCK,
        Color3.fromRGB(158, 92, 62)
    )

    makeRockArch(
        model,
        CFrame.new(caveEntrance + Vector3.new(0, 0, 2)),
        21,
        12,
        7,
        ROCK
    )

    local warning = meshRock(
        model,
        "DeepFracture",
        Vector3.new(8, 1.2, 5),
        start * CFrame.new(0, .18, -36)
            * CFrame.Angles(0, math.rad(18), math.rad(8)),
        Color3.fromRGB(93, 55, 48),
        Enum.Material.Slate
    )
    warning.CanQuery = false

    local trigger = makeTrigger(
        model,
        "WyrmTravelThreshold",
        start * CFrame.new(0, 4.5, -46),
        Vector3.new(15, 9, 5)
    )

    return {
        Entrance = caveEntrance,
        Trigger = trigger,
        Denied = CFrame.new(caveEntrance + Vector3.new(0, 3.5, -28))
            * CFrame.Angles(0, math.rad(180), 0),
        Return = CFrame.new(caveEntrance + Vector3.new(0, 3.5, -18))
            * CFrame.Angles(0, math.rad(180), 0),
    }
end

local function buildWaterfallPassage()
    local settings = QuestConfig.World
    local xz = settings.WorldBossWaterfallXZ
    local ground = terrainPoint(xz.X, xz.Y, settings.CaveFallbackY)
    local base = ground + Vector3.new(0, .2, 0)

    local outward = Vector3.new(base.X, 0, base.Z)
    if outward.Magnitude < .01 then outward = Vector3.new(1, 0, -1) end
    outward = outward.Unit

    local frame = CFrame.lookAt(base, base + outward)

    local model = Instance.new("Model")
    model.Name = "NortheastWaterfallCave"
    model.Parent = travelWorld

    -- A broad organic rock face hides the opening from a distance.
    for index = -4, 4 do
        local x = index * 5.4
        local y = 6 + math.abs(index) * .65
        local z = ((index * index) % 3) * 1.1
        meshRock(
            model,
            "WaterfallCliff_" .. tostring(index),
            Vector3.new(9.5, 16 + (index % 2) * 2, 9),
            frame * CFrame.new(x, y, z)
                * CFrame.Angles(
                    math.rad((index * 7) % 20 - 10),
                    math.rad(index * 9),
                    math.rad(index * 5)
                ),
            index % 2 == 0 and ROCK or DARK_ROCK
        )
    end

    -- The water is visual only, allowing players to physically walk behind it.
    local water = basePart(
        model,
        "WaterCurtain",
        Vector3.new(15, 16, .6),
        frame * CFrame.new(0, 7, -1.1),
        Color3.fromRGB(119, 202, 226),
        Enum.Material.Glass,
        .34
    )
    water.CanCollide = false
    water.CanTouch = false
    water.CanQuery = false
    water.CastShadow = false

    local glow = Instance.new("SurfaceLight")
    glow.Face = Enum.NormalId.Front
    glow.Color = Color3.fromRGB(137, 213, 235)
    glow.Brightness = .7
    glow.Range = 18
    glow.Parent = water

    for index = 1, 8 do
        local mist = meshOrb(
            model,
            "Mist_" .. tostring(index),
            Vector3.new(3.5 + (index % 3), 1.2 + (index % 2), 2.2),
            frame * CFrame.new(
                -7 + index * 1.7,
                .8 + (index % 2) * .35,
                -2 + (index % 3) * .45
            ),
            Color3.fromRGB(198, 228, 235),
            Enum.Material.ForceField,
            .55
        )
        mist.CastShadow = false
    end

    makeRockArch(
        model,
        frame * CFrame.new(0, 0, -2.2),
        17,
        11,
        8,
        DARK_ROCK
    )

    addTunnelRibs(
        model,
        frame * CFrame.new(0, 0, -4),
        42,
        16,
        12,
        DARK_ROCK,
        Color3.fromRGB(83, 194, 174)
    )

    local trigger = makeTrigger(
        model,
        "WorldBossTravelThreshold",
        frame * CFrame.new(0, 4.2, -38),
        Vector3.new(13, 9, 5)
    )

    return {
        Entrance = base,
        Frame = frame,
        Trigger = trigger,
        Denied = frame * CFrame.new(0, 3.5, 7),
        Return = frame * CFrame.new(0, 3.5, 9),
    }
end

local function buildCavern(parent, name, center, radius, wallHeight, accent, worldBoss)
    local model = Instance.new("Model")
    model.Name = name
    model:SetAttribute("BossArena", true)
    model:SetAttribute("SharedArena", true)
    model.Parent = parent

    local centerFrame = CFrame.new(center)

    local floor = basePart(
        model,
        "CavernFloor",
        Vector3.new(radius * 2.2, 2.2, radius * 2.2),
        centerFrame * CFrame.new(0, -1.1, 0),
        Color3.fromRGB(30, 32, 33),
        Enum.Material.Slate
    )

    -- Large mesh rocks form a full ring, visually isolating the arena from the sky.
    local wallCount = worldBoss and 42 or 32
    for index = 1, wallCount do
        local angle = (index / wallCount) * math.pi * 2
        local ringRadius = radius + ((index % 4) - 2) * 3
        local x = math.cos(angle) * ringRadius
        local z = math.sin(angle) * ringRadius
        local size = Vector3.new(
            18 + (index % 3) * 5,
            wallHeight + (index % 5) * 6,
            20 + ((index + 1) % 4) * 4
        )
        meshRock(
            model,
            "WallRock_" .. tostring(index),
            size,
            centerFrame * CFrame.new(x, wallHeight * .35, z)
                * CFrame.Angles(
                    math.rad((index * 11) % 24 - 12),
                    -angle + math.rad(90),
                    math.rad((index * 7) % 20 - 10)
                ),
            index % 3 == 0 and DEEP_ROCK or DARK_ROCK
        )

        if index % 3 == 0 then
            meshRock(
                model,
                "CeilingRock_" .. tostring(index),
                Vector3.new(30, 13, 34),
                centerFrame * CFrame.new(
                    math.cos(angle) * radius * .64,
                    wallHeight * .95,
                    math.sin(angle) * radius * .64
                ) * CFrame.Angles(
                    math.rad(index * 5),
                    angle,
                    math.rad(index * 9)
                ),
                DEEP_ROCK
            )
        end
    end

    -- Flattened mesh slabs close most of the ceiling so these distant
    -- arenas still read as underground caverns instead of outdoor platforms.
    for index = 1, 5 do
        local angle = ((index - 1) / 5) * math.pi * 2
        local offset = Vector3.new(
            math.cos(angle) * radius * .28,
            wallHeight * 1.08 + (index % 2) * 2.5,
            math.sin(angle) * radius * .28
        )
        meshRock(
            model,
            "CeilingSlab_" .. tostring(index),
            Vector3.new(radius * .92, 16 + (index % 2) * 4, radius * .92),
            centerFrame * CFrame.new(offset)
                * CFrame.Angles(
                    math.rad((index * 7) % 12 - 6),
                    math.rad(index * 31),
                    math.rad((index * 11) % 10 - 5)
                ),
            DEEP_ROCK
        )
    end

    -- Hidden collision shell keeps players inside the playable cavern.
    for index = 1, 20 do
        local angle = (index / 20) * math.pi * 2
        local p = center + Vector3.new(
            math.cos(angle) * (radius + 4),
            wallHeight * .35,
            math.sin(angle) * (radius + 4)
        )
        local wall = basePart(
            model,
            "CollisionWall_" .. tostring(index),
            Vector3.new(20, wallHeight * 1.3, 4),
            CFrame.new(p) * CFrame.Angles(0, -angle + math.rad(90), 0),
            DARK_ROCK,
            Enum.Material.Rock,
            1
        )
        wall.CanQuery = false
    end

    -- Stalagmites, crystals and local lights give each cavern a distinct silhouette.
    for index = 1, (worldBoss and 18 or 12) do
        local angle = (index * 2.399963229728653) % (math.pi * 2)
        local r = radius * (.38 + ((index * 17) % 45) / 100)
        local x = math.cos(angle) * r
        local z = math.sin(angle) * r
        local h = 5 + (index % 5) * 2.2

        meshWedge(
            model,
            "Stalagmite_" .. tostring(index),
            Vector3.new(3 + (index % 2), h, 3 + ((index + 1) % 2)),
            centerFrame * CFrame.new(x, h * .45, z)
                * CFrame.Angles(math.rad(-90), 0, math.rad(index * 19)),
            index % 4 == 0 and accent or ROCK,
            index % 4 == 0 and Enum.Material.Neon or Enum.Material.Rock
        )
    end

    for index = 1, (worldBoss and 7 or 4) do
        local angle = (index / (worldBoss and 7 or 4)) * math.pi * 2
        local crystal = meshWedge(
            model,
            "GlowCrystal_" .. tostring(index),
            Vector3.new(worldBoss and 3.2 or 2.1, worldBoss and 11 or 7, worldBoss and 3.4 or 2.2),
            centerFrame
                * CFrame.new(
                    math.cos(angle) * radius * .72,
                    worldBoss and 5 or 3.2,
                    math.sin(angle) * radius * .72
                )
                * CFrame.Angles(math.rad(-90), 0, angle),
            accent,
            Enum.Material.Neon
        )
        pointLight(crystal, accent, worldBoss and 1.7 or 1.05, worldBoss and 32 or 22)
    end

    local arenaLightAnchor = basePart(
        model,
        "ArenaLightAnchor",
        Vector3.new(1, 1, 1),
        centerFrame * CFrame.new(0, wallHeight * .72, 0),
        accent,
        Enum.Material.Neon,
        1
    )
    arenaLightAnchor.CanCollide = false
    arenaLightAnchor.CanQuery = false
    pointLight(
        arenaLightAnchor,
        accent,
        worldBoss and 2.2 or 1.4,
        worldBoss and radius * 1.35 or radius
    )

    return model, floor
end

local function createWyrm(arena, center)
    local model = Instance.new("Model")
    model.Name = "HollowfangWyrm"
    model:SetAttribute("BossType", "MiniBoss")
    model:SetAttribute("BossId", "HollowfangWyrm")
    model:SetAttribute("DisplayName", "Hollowfang Wyrm")
    model:SetAttribute("CombatReady", false)
    model:SetAttribute("BossVisualOnly", true)
    model:SetAttribute("WorldBoss", false)
    model:SetAttribute("QuestNoCapture", true)
    model.Parent = arena

    local bodyColor = Color3.fromRGB(82, 55, 49)
    local underColor = Color3.fromRGB(121, 85, 67)
    local spineColor = Color3.fromRGB(180, 133, 87)
    local eyeColor = Color3.fromRGB(255, 124, 54)

    local segmentPositions = {}
    local segmentCount = 18
    for index = 1, segmentCount do
        local t = (index - 1) / (segmentCount - 1)
        local z = -44 + t * 80
        local x = math.sin(t * math.pi * 2.25) * (8.5 - t * 2)
        local y = 3.2 + math.sin(t * math.pi) * 2.3
        table.insert(segmentPositions, center + Vector3.new(x, y, z))
    end

    local primary
    for index, position in ipairs(segmentPositions) do
        local nextPosition = segmentPositions[math.min(index + 1, #segmentPositions)]
        local direction = nextPosition - position
        if direction.Magnitude < .01 then direction = Vector3.new(0, 0, 1) end

        local scale = 1 - ((index - 1) / segmentCount) * .34
        local segment = meshOrb(
            model,
            "Body_" .. tostring(index),
            Vector3.new(9.4 * scale, 7.0 * scale, 11.5 * scale),
            CFrame.lookAt(position, position + direction),
            index % 3 == 0 and underColor or bodyColor,
            Enum.Material.Slate
        )
        if not primary then primary = segment end

        if index % 2 == 0 and index < segmentCount - 1 then
            meshWedge(
                model,
                "Spine_" .. tostring(index),
                Vector3.new(1.7 * scale, 4.2 * scale, 2.4 * scale),
                CFrame.lookAt(
                    position + Vector3.new(0, 4.4 * scale, 0),
                    position + direction + Vector3.new(0, 4.4 * scale, 0)
                ) * CFrame.Angles(math.rad(-90), 0, 0),
                spineColor,
                Enum.Material.Slate
            )
        end
    end

    local headPosition = segmentPositions[#segmentPositions] + Vector3.new(0, 2.2, 4.3)
    local head = meshOrb(
        model,
        "Head",
        Vector3.new(12.5, 8.7, 15),
        CFrame.new(headPosition),
        bodyColor,
        Enum.Material.Slate
    )
    primary = primary or head

    local jaw = meshWedge(
        model,
        "Jaw",
        Vector3.new(9.5, 3.1, 10.5),
        CFrame.new(headPosition + Vector3.new(0, -2.1, 5.2))
            * CFrame.Angles(math.rad(180), 0, 0),
        underColor,
        Enum.Material.Slate
    )

    for sideIndex, side in ipairs({-1, 1}) do
        local eye = meshOrb(
            model,
            "Eye_" .. tostring(sideIndex),
            Vector3.new(1.15, 1.15, .8),
            CFrame.new(headPosition + Vector3.new(side * 4.1, 1.4, 6.1)),
            eyeColor,
            Enum.Material.Neon
        )
        pointLight(eye, eyeColor, .65, 9)

        meshWedge(
            model,
            "Horn_" .. tostring(sideIndex),
            Vector3.new(1.7, 5.6, 1.8),
            CFrame.new(headPosition + Vector3.new(side * 4.4, 4.2, -.5))
                * CFrame.Angles(math.rad(-65), 0, math.rad(side * 18)),
            spineColor,
            Enum.Material.Slate
        )
    end

    -- These are intentionally hidden until the future Wyrm-death script reveals
    -- the evidence that something much larger attacked it before Hollowfang.
    local gouges = Instance.new("Folder")
    gouges.Name = "PostDefeatGouges"
    gouges:SetAttribute("RevealAfterDefeat", true)
    gouges.Parent = model

    for index = 1, 3 do
        local mark = meshOrb(
            gouges,
            "Gouge_" .. tostring(index),
            Vector3.new(.55, 5.5, 12),
            CFrame.new(
                segmentPositions[13] + Vector3.new((index - 2) * 1.8, 2.2, 0)
            ) * CFrame.Angles(math.rad(12), math.rad(18), math.rad(-26)),
            Color3.fromRGB(34, 16, 14),
            Enum.Material.SmoothPlastic,
            1
        )
        mark:SetAttribute("DefeatEvidence", true)
    end

    model.PrimaryPart = primary
    bossLabel(head, "HOLLOWFANG WYRM", "MINI BOSS  ·  WOUNDED, CORNERED, DANGEROUS", Color3.fromRGB(232, 145, 91), 170)

    return model
end

local function createJormungdyrr(arena, center)
    local model = Instance.new("Model")
    model.Name = "Jormungdyrr"
    model:SetAttribute("BossType", "WorldBoss")
    model:SetAttribute("BossId", "Jormungdyrr")
    model:SetAttribute("DisplayName", "Jormungdyrr")
    -- Keep compatibility with the existing Ancient reward configuration.
    model:SetAttribute("Species", "Jörmungandr")
    model:SetAttribute("WorldBoss", true)
    model:SetAttribute("CombatReady", false)
    model:SetAttribute("BossVisualOnly", true)
    model:SetAttribute("QuestNoCapture", true)
    model.Parent = arena

    local scaleColor = Color3.fromRGB(39, 61, 48)
    local deepColor = Color3.fromRGB(20, 35, 29)
    local runeColor = Color3.fromRGB(128, 220, 118)
    local boneColor = Color3.fromRGB(185, 190, 151)

    local positions = {}
    local count = 32

    for index = 1, count do
        local t = (index - 1) / (count - 1)
        local turns = 2.35
        local angle = t * math.pi * 2 * turns
        local radius = 62 - t * 32
        local x = math.cos(angle) * radius
        local z = math.sin(angle) * radius
        local y = 6 + t * 8 + math.sin(t * math.pi * 5) * 1.4
        table.insert(positions, center + Vector3.new(x, y, z))
    end

    local primary
    for index, position in ipairs(positions) do
        local nextPosition = positions[math.min(index + 1, #positions)]
        local direction = nextPosition - position
        if direction.Magnitude < .01 then direction = Vector3.new(0, 0, 1) end

        local taper = 1 - ((index - 1) / count) * .28
        local segment = meshOrb(
            model,
            "WorldCoil_" .. tostring(index),
            Vector3.new(15.8 * taper, 11.7 * taper, 18.5 * taper),
            CFrame.lookAt(position, position + direction),
            index % 4 == 0 and deepColor or scaleColor,
            Enum.Material.Slate
        )
        if not primary then primary = segment end

        if index % 4 == 2 then
            local rune = meshOrb(
                model,
                "Rune_" .. tostring(index),
                Vector3.new(3.2, .75, 5.2),
                CFrame.lookAt(
                    position + Vector3.new(0, 6.1 * taper, 0),
                    position + direction + Vector3.new(0, 6.1 * taper, 0)
                ),
                runeColor,
                Enum.Material.Neon,
                .08
            )
            pointLight(rune, runeColor, .4, 11)
        end

        if index % 3 == 0 and index < count - 2 then
            meshWedge(
                model,
                "CrownSpine_" .. tostring(index),
                Vector3.new(2.3 * taper, 7.2 * taper, 3.1 * taper),
                CFrame.lookAt(
                    position + Vector3.new(0, 7 * taper, 0),
                    position + direction + Vector3.new(0, 7 * taper, 0)
                ) * CFrame.Angles(math.rad(-90), 0, 0),
                boneColor,
                Enum.Material.Slate
            )
        end
    end

    local headBase = center + Vector3.new(0, 18, 58)
    local neckStart = positions[#positions]
    local neckEnd = headBase + Vector3.new(0, -2, -11)
    local neckCount = 6

    for index = 1, neckCount do
        local t = index / (neckCount + 1)
        local position = neckStart:Lerp(neckEnd, t)
        local nextPosition = neckStart:Lerp(neckEnd, math.min(1, (index + 1) / (neckCount + 1)))
        local direction = nextPosition - position
        if direction.Magnitude < .01 then direction = Vector3.new(0, 0, 1) end

        local neck = meshOrb(
            model,
            "Neck_" .. tostring(index),
            Vector3.new(12.5 + t * 2.5, 9.5 + t * 1.8, 16),
            CFrame.lookAt(position, position + direction),
            index % 2 == 0 and deepColor or scaleColor,
            Enum.Material.Slate
        )

        if index % 2 == 0 then
            local crest = meshWedge(
                model,
                "NeckCrest_" .. tostring(index),
                Vector3.new(2.1, 6.5, 2.8),
                CFrame.lookAt(
                    position + Vector3.new(0, 6, 0),
                    position + direction + Vector3.new(0, 6, 0)
                ) * CFrame.Angles(math.rad(-90), 0, 0),
                boneColor,
                Enum.Material.Slate
            )
        end
    end

    local head = meshOrb(
        model,
        "Head",
        Vector3.new(23, 15, 30),
        CFrame.new(headBase),
        scaleColor,
        Enum.Material.Slate
    )

    local muzzle = meshWedge(
        model,
        "Muzzle",
        Vector3.new(16, 6.5, 18),
        CFrame.new(headBase + Vector3.new(0, -2.5, 11))
            * CFrame.Angles(math.rad(180), 0, 0),
        deepColor,
        Enum.Material.Slate
    )

    for sideIndex, side in ipairs({-1, 1}) do
        local eye = meshOrb(
            model,
            "WorldEye_" .. tostring(sideIndex),
            Vector3.new(2.1, 2.1, 1.3),
            CFrame.new(headBase + Vector3.new(side * 7.3, 2.5, 11.8)),
            runeColor,
            Enum.Material.Neon
        )
        pointLight(eye, runeColor, 1.15, 18)

        meshWedge(
            model,
            "CrownHorn_" .. tostring(sideIndex),
            Vector3.new(3.2, 11.5, 3.3),
            CFrame.new(headBase + Vector3.new(side * 7.1, 8.8, -1))
                * CFrame.Angles(math.rad(-58), 0, math.rad(side * 19)),
            boneColor,
            Enum.Material.Slate
        )
    end

    local brow = meshRock(
        model,
        "RuneCrown",
        Vector3.new(13, 3.2, 5),
        CFrame.new(headBase + Vector3.new(0, 7.6, 6)),
        runeColor,
        Enum.Material.Neon,
        .05
    )
    pointLight(brow, runeColor, 1.2, 20)

    model.PrimaryPart = primary or head
    bossLabel(head, "JORMUNGDYRR", "WORLD BOSS  ·  SHARED SERVER ENCOUNTER", Color3.fromRGB(158, 236, 132), 260)

    return model
end

local function buildWyrmArena()
    local center = QuestConfig.World.WyrmArenaCenter
    local arena = buildCavern(
        travelWorld,
        "HollowfangWyrmArena",
        center,
        105,
        48,
        Color3.fromRGB(188, 91, 65),
        false
    )

    local boss = createWyrm(arena, center + Vector3.new(0, 0, -8))

    local arrival = CFrame.lookAt(
        center + Vector3.new(0, 4, 76),
        center + Vector3.new(0, 5, 0)
    )
    local exitTrigger = makeTrigger(
        arena,
        "WyrmArenaReturnThreshold",
        CFrame.new(center + Vector3.new(0, 4.5, 96)),
        Vector3.new(18, 10, 6)
    )

    addTunnelRibs(
        arena,
        CFrame.new(center + Vector3.new(0, 0, 102))
            * CFrame.Angles(0, math.rad(180), 0),
        28,
        19,
        13,
        DARK_ROCK,
        Color3.fromRGB(157, 78, 58)
    )

    return {
        Model = arena,
        Boss = boss,
        Arrival = arrival,
        ExitTrigger = exitTrigger,
    }
end

local function buildWorldBossArena()
    local center = QuestConfig.World.WorldBossArenaCenter
    local arena = buildCavern(
        travelWorld,
        "JormungdyrrWorldBossArena",
        center,
        165,
        68,
        Color3.fromRGB(78, 190, 149),
        true
    )

    local boss = createJormungdyrr(arena, center + Vector3.new(0, 0, -18))

    local arrival = CFrame.lookAt(
        center + Vector3.new(0, 5, 132),
        center + Vector3.new(0, 8, 0)
    )
    local exitTrigger = makeTrigger(
        arena,
        "WorldBossArenaReturnThreshold",
        CFrame.new(center + Vector3.new(0, 5, 155)),
        Vector3.new(24, 12, 7)
    )

    addTunnelRibs(
        arena,
        CFrame.new(center + Vector3.new(0, 0, 166))
            * CFrame.Angles(0, math.rad(180), 0),
        36,
        24,
        16,
        DEEP_ROCK,
        Color3.fromRGB(83, 194, 174)
    )

    return {
        Model = arena,
        Boss = boss,
        Arrival = arrival,
        ExitTrigger = exitTrigger,
    }
end

local function canEnterWyrm(player)
    if QuestService:IsQuestCompleted(player, "HollowfangWyrm") then
        return true
    end

    if not QuestService:IsQuestCompleted(player, "HollowfangWeavers") then
        return false, "The deeper Hollowfang passage is still unsafe. Finish Rowan's Webs Below investigation first."
    end

    if not QuestService:IsQuestActive(player, "HollowfangWyrm") then
        return false, "The passage is open, but Rowan needs to brief you before you go deeper."
    end

    return true
end

local function canEnterWorldBoss(player)
    if not QuestService:IsQuestCompleted(player, "HollowfangWyrm") then
        return false, "Something seals the cave beyond the waterfall. Finish the Hollowfang Wyrm quest chain first."
    end
    return true
end

local function bindPlayer(player)
    player:SetAttribute("BossArena", "")

    player.CharacterAdded:Connect(function()
        -- Death/respawn returns through the normal plot flow, so clear stale
        -- arena state if a character is rebuilt.
        player:SetAttribute("BossArena", "")
    end)
end

function Service:PlayerRemoving(player)
    touchDebounce[player] = nil
end

function Service:Init()
    if started then return end
    started = true

    world = workspace:WaitForChild("WildernessPets")

    local old = world:FindFirstChild("BossTravelWorld")
    if old then old:Destroy() end

    travelWorld = Instance.new("Folder")
    travelWorld.Name = "BossTravelWorld"
    travelWorld.Parent = world

    local hollowfang = buildHollowfangDepthPassage()
    local waterfall = buildWaterfallPassage()
    local wyrmArena = buildWyrmArena()
    local worldBossArena = buildWorldBossArena()

    connectGate(
        hollowfang.Trigger,
        "EnterWyrm",
        canEnterWyrm,
        wyrmArena.Arrival,
        "Wyrm",
        "HOLLOWFANG DEPTHS",
        "The cave narrows, then opens into something far older.",
        "EnterWyrmArena",
        hollowfang.Denied
    )

    connectGate(
        wyrmArena.ExitTrigger,
        "ExitWyrm",
        nil,
        hollowfang.Return,
        "",
        "HOLLOWFANG CAVE",
        "You climb back toward the familiar tunnels.",
        nil,
        nil
    )

    connectGate(
        waterfall.Trigger,
        "EnterJormungdyrr",
        canEnterWorldBoss,
        worldBossArena.Arrival,
        "Jormungdyrr",
        "CAVE BEHIND THE FALLS",
        "The roar of the waterfall fades beneath a much deeper sound.",
        "EnterJormungdyrrArena",
        waterfall.Denied
    )

    connectGate(
        worldBossArena.ExitTrigger,
        "ExitJormungdyrr",
        nil,
        waterfall.Return,
        "",
        "NORTHEAST WATERFALL",
        "Cold spray reaches you again as you leave the hidden cavern.",
        nil,
        nil
    )

    for _, player in ipairs(Players:GetPlayers()) do
        bindPlayer(player)
    end
    Players.PlayerAdded:Connect(bindPlayer)
    Players.PlayerRemoving:Connect(function(player)
        Service:PlayerRemoving(player)
    end)
end

return Service
