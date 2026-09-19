local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Root = ReplicatedStorage:WaitForChild("WildernessPets")
local Config = require(Root.Shared.Config)

local DataService = require(script.Parent.PlayerDataService)
local ModelFactory = require(script.Parent.Parent.Systems.PetModelFactory)

local Service = {}
local sessions = {}
local started = false
local mountedFolder

local function ensureDefaults(mount)
    if type(mount) ~= "table" then return mount end
    mount.Id = type(mount.Id) == "string" and mount.Id or HttpService:GenerateGUID(false)
    mount.Species = tostring(mount.Species or "")
    mount.Name = type(mount.Name) == "string" and mount.Name ~= "" and mount.Name or mount.Species
    local info = Config.Mounts and Config.Mounts[mount.Species]
    mount.Rarity = tostring(mount.Rarity or (info and info.Rarity) or "Common")
    mount.Speed = math.max(16, tonumber(mount.Speed) or tonumber(info and info.Speed) or 22)
    mount.CapturedAt = tonumber(mount.CapturedAt) or os.time()
    return mount
end

function Service:GetMounts(player)
    local data = DataService:Get(player)
    if not data then return {} end
    data.Mounts = type(data.Mounts) == "table" and data.Mounts or {}
    for _, mount in ipairs(data.Mounts) do
        ensureDefaults(mount)
    end
    return data.Mounts
end

function Service:Find(player, mountId)
    for _, mount in ipairs(self:GetMounts(player)) do
        if mount.Id == mountId then
            return ensureDefaults(mount)
        end
    end
end

function Service:Create(player, species, options)
    local data = DataService:Get(player)
    local info = Config.Mounts and Config.Mounts[species]
    if not data or not info then return nil end

    data.Mounts = type(data.Mounts) == "table" and data.Mounts or {}
    if #data.Mounts >= math.max(1, tonumber(Config.MaxMounts) or 40) then
        return nil
    end

    options = type(options) == "table" and options or {}
    local mount = {
        Id = HttpService:GenerateGUID(false),
        Species = species,
        Name = species,
        Rarity = info.Rarity,
        Speed = tonumber(info.Speed) or 22,
        CapturedAt = os.time(),
        QuestMount = options.QuestMount == true,
    }
    table.insert(data.Mounts, mount)

    data.MountCollection = type(data.MountCollection) == "table" and data.MountCollection or {}
    data.MountCollection[species] = true
    return mount
end

local function playerRoot(player)
    local character = player.Character
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function humanoid(player)
    local character = player.Character
    return character and character:FindFirstChildOfClass("Humanoid")
end

local function destroySession(player)
    local session = sessions[player]
    if not session then return end

    if session.model and session.model.Parent then
        session.model:Destroy()
    end

    local hum = humanoid(player)
    if hum then
        local originalHip = tonumber(session.originalHipHeight)
        if originalHip then hum.HipHeight = originalHip end
        local originalWalk = tonumber(session.originalWalkSpeed)
        if originalWalk then hum.WalkSpeed = originalWalk end
    end

    sessions[player] = nil
end

local function speedMultiplier(player)
    local data = DataService:Get(player)
    local active = data and data.ActiveEffects
    if type(active) == "table" and (tonumber(active.SpeedBoostUntil) or 0) > os.time() then
        return math.max(1, tonumber(active.PlayerSpeedMultiplier) or 1)
    end
    return 1
end

local function spawnRide(player, mount)
    local root = playerRoot(player)
    local hum = humanoid(player)
    if not root or not hum then return nil, "Character is not ready." end

    local model = ModelFactory:Create(mount.Species)
    if not model then return nil, "No mount model exists for " .. tostring(mount.Species) .. "." end

    model.Name = "Mounted_" .. tostring(player.UserId)
    model:SetAttribute("Mounted", true)
    model:SetAttribute("OwnerUserId", player.UserId)
    model:SetAttribute("MountId", mount.Id)
    model:SetAttribute("CreatureType", "Mount")
    model:SetAttribute("Rideable", true)

    for _, item in ipairs(model:GetDescendants()) do
        if item:IsA("BillboardGui") then
            item:Destroy()
        elseif item:IsA("BasePart") then
            item.Anchored = true
            item.CanCollide = false
            item.CanTouch = false
            item.CanQuery = false
        end
    end

    model.Parent = mountedFolder

    local height = math.max(2, model:GetExtentsSize().Y)
    local seatLift = math.clamp(height * 0.42, 2.0, 4.5)
    local originalHip = hum.HipHeight
    local originalWalk = hum.WalkSpeed

    hum.HipHeight = originalHip + seatLift
    hum.WalkSpeed = math.max(originalWalk, mount.Speed * speedMultiplier(player))

    local session = {
        model = model,
        mount = mount,
        originalHipHeight = originalHip,
        originalWalkSpeed = originalWalk,
        seatLift = seatLift,
    }
    sessions[player] = session
    return session
end

function Service:Equip(player, mountId)
    local data = DataService:Get(player)
    local mount = self:Find(player, mountId)
    if not data or not mount then return false, "Mount not found." end

    destroySession(player)
    local session, err = spawnRide(player, mount)
    if not session then return false, err end

    data.EquippedMountId = mount.Id
    player:SetAttribute("EquippedMountId", mount.Id)
    player:SetAttribute("EquippedMountSpecies", mount.Species)
    player:SetAttribute("Mounted", true)
    return true, "Mounted " .. tostring(mount.Name or mount.Species) .. "."
end

function Service:Unequip(player)
    local data = DataService:Get(player)
    destroySession(player)
    if data then data.EquippedMountId = "" end
    player:SetAttribute("EquippedMountId", "")
    player:SetAttribute("EquippedMountSpecies", "")
    player:SetAttribute("Mounted", false)
    return true, "Mount unequipped."
end

function Service:Refresh(player)
    local data = DataService:Get(player)
    if not data then return end

    local mountId = type(data.EquippedMountId) == "string" and data.EquippedMountId or ""
    if mountId == "" then
        self:Unequip(player)
        return
    end

    local mount = self:Find(player, mountId)
    if not mount then
        self:Unequip(player)
        return
    end

    destroySession(player)
    task.defer(function()
        if player.Parent and player.Character then
            spawnRide(player, mount)
        end
    end)
end

function Service:PlayerReady(player)
    local data = DataService:Get(player)
    if not data then return end
    data.Mounts = type(data.Mounts) == "table" and data.Mounts or {}
    data.MountCollection = type(data.MountCollection) == "table" and data.MountCollection or {}
    data.EquippedMountId = type(data.EquippedMountId) == "string" and data.EquippedMountId or ""

    player:SetAttribute("EquippedMountId", data.EquippedMountId)
    local mount = self:Find(player, data.EquippedMountId)
    player:SetAttribute("EquippedMountSpecies", mount and mount.Species or "")
    player:SetAttribute("Mounted", false)

    player.CharacterAdded:Connect(function()
        task.wait(.25)
        if player.Parent then
            Service:Refresh(player)
        end
    end)

    if data.EquippedMountId ~= "" then
        task.defer(function()
            if player.Parent then Service:Refresh(player) end
        end)
    end
end

function Service:PlayerRemoving(player)
    destroySession(player)
end

function Service:Init()
    if started then return end
    started = true

    local world = workspace:WaitForChild("WildernessPets")
    local old = world:FindFirstChild("MountedCreatures")
    if old then old:Destroy() end

    mountedFolder = Instance.new("Folder")
    mountedFolder.Name = "MountedCreatures"
    mountedFolder.Parent = world

    RunService.Heartbeat:Connect(function()
        for player, session in pairs(sessions) do
            local model = session.model
            local root = playerRoot(player)
            local hum = humanoid(player)

            if not player.Parent or not model or not model.Parent or not root or not hum or hum.Health <= 0 then
                destroySession(player)
            else
                local mount = session.mount
                hum.WalkSpeed = math.max(
                    tonumber(session.originalWalkSpeed) or 16,
                    (tonumber(mount.Speed) or 22) * speedMultiplier(player)
                )

                local velocity = root.AssemblyLinearVelocity
                local moving = Vector3.new(velocity.X, 0, velocity.Z).Magnitude > 1.5
                local bob = moving and math.sin(workspace:GetServerTimeNow() * 9) * .12 or 0
                local offset = math.max(1.6, session.seatLift * .82)
                local facing = CFrame.new(root.Position - Vector3.new(0, offset - bob, 0))
                    * CFrame.Angles(0, math.atan2(-root.CFrame.LookVector.X, -root.CFrame.LookVector.Z), 0)
                model:PivotTo(facing)
            end
        end
    end)
end

return Service
