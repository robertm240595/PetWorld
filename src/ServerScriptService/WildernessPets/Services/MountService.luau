[Reading 297 lines from start (total: 297 lines, 0 remaining)]

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Config = require(ReplicatedStorage.WildernessPets.Shared.Config)
local DataService = require(script.Parent.PlayerDataService)
local ModelFactory = require(script.Parent.Parent.Systems.PetModelFactory)

local Service = {}
local started = false
local world
local folder
local sessions = setmetatable({}, {__mode = "k"})

local function mountInfo(species)
    return type(species) == "string" and Config.Mounts and Config.Mounts[species] or nil
end

local function characterParts(player)
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    return character, root, humanoid
end

local function potionSpeedMultiplier(data)
    local effects = data and data.ActiveEffects
    if type(effects) == "table" and (tonumber(effects.SpeedBoostUntil) or 0) > os.time() then
        return math.max(1, tonumber(effects.PlayerSpeedMultiplier) or 1)
    end
    return 1
end

local function applyMovement(player)
    local data = DataService:Get(player)
    local _, _, humanoid = characterParts(player)
    if not data or not humanoid then return end

    local testSpeed = player:GetAttribute("TestWalkSpeed")
    if RunService:IsStudio() and type(testSpeed) == "number" then
        humanoid.WalkSpeed = math.clamp(testSpeed, 0, 300)
        return
    end

    local mountMultiplier = math.max(1, tonumber(player:GetAttribute("MountSpeedMultiplier")) or 1)
    humanoid.WalkSpeed = 16 * potionSpeedMultiplier(data) * mountMultiplier
end

local function clearSession(player)
    local session = sessions[player]
    sessions[player] = nil

    if session and session.Model and session.Model.Parent then
        session.Model:Destroy()
    end

    local _, _, humanoid = characterParts(player)
    if humanoid and session and session.BaseHipHeight ~= nil then
        humanoid.HipHeight = session.BaseHipHeight
    end

    player:SetAttribute("MountSpeedMultiplier", 1)
    player:SetAttribute("EquippedMountId", "")
    player:SetAttribute("EquippedMountSpecies", "")
    applyMovement(player)
end

local function ensureMountDefaults(mount)
    if type(mount) ~= "table" then return mount end

    local info = mountInfo(mount.Species)
    mount.Favourite = mount.Favourite == true
    mount.Tradeable = mount.Tradeable ~= false
        and (not info or info.Tradeable ~= false)
    mount.VendorSellable = false

    return mount
end

function Service:GetMounts(player)
    local data = DataService:Get(player)
    if not data then return {} end
    data.Mounts = type(data.Mounts) == "table" and data.Mounts or {}

    for _, mount in ipairs(data.Mounts) do
        ensureMountDefaults(mount)
    end

    return data.Mounts
end

function Service:Find(player, mountId)
    if type(mountId) ~= "string" then return nil end
    for _, mount in ipairs(self:GetMounts(player)) do
        if type(mount) == "table" and mount.Id == mountId then
            return mount
        end
    end
    return nil
end

function Service:Create(player, species, options)
    local data = DataService:Get(player)
    local info = mountInfo(species)
    if not data or not info then return nil, "Mount species unavailable." end

    data.Mounts = type(data.Mounts) == "table" and data.Mounts or {}
    if #data.Mounts >= math.max(1, tonumber(Config.MaxMounts) or 40) then
        return nil, "Your mount collection is full."
    end

    options = type(options) == "table" and options or {}
    local imprint = math.clamp(math.floor(tonumber(options.Imprint) or 20), 20, 100)

    local mount = {
        Id = HttpService:GenerateGUID(false),
        Species = species,
        Name = species,
        Rarity = info.Rarity,
        Imprint = imprint,
        AcquiredFrom = options.AcquiredFrom or "Capture",
        Favourite = false,
        Tradeable = info.Tradeable ~= false,
        VendorSellable = false,
    }
    table.insert(data.Mounts, mount)

    data.MountCollection = type(data.MountCollection) == "table" and data.MountCollection or {}
    data.MountCollection[species] = true

    return mount
end

function Service:SetFavourite(player, mountId, favourite)
    local mount = self:Find(player, mountId)
    if not mount then return false, "Mount not found." end

    mount.Favourite = favourite == true
    return true, mount.Favourite
        and "Mount added to favourites."
        or "Mount removed from favourites."
end

function Service:Unequip(player)
    local data = DataService:Get(player)
    if data then data.EquippedMountId = "" end
    clearSession(player)
    return true, "Mount unequipped."
end

local function createMountedVisual(player, mount)
    local info = mountInfo(mount.Species)
    local character, root, humanoid = characterParts(player)
    if not info or not character or not root or not humanoid then
        return nil, "Character is not ready."
    end

    local model = ModelFactory:Create(mount.Species)
    if not model or not model.PrimaryPart then
        if model then model:Destroy() end
        return nil, "No mount model is available."
    end

    model.Name = "Mounted_" .. tostring(player.UserId)
    model:SetAttribute("RideableMount", true)
    model:SetAttribute("OwnerUserId", player.UserId)
    model:SetAttribute("MountId", mount.Id)
    model:SetAttribute("Species", mount.Species)
    model:SetAttribute("Rarity", mount.Rarity or info.Rarity)

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

    model.Parent = folder

    local extents = model:GetExtentsSize()
    local rideLift = math.clamp(extents.Y * 0.48, 1.8, 4.8)
    local visualDrop = math.clamp(extents.Y * 0.37 + 1.4, 2.2, 5.4)

    local session = {
        Mount = mount,
        Model = model,
        BaseHipHeight = humanoid.HipHeight,
        RideLift = rideLift,
        VisualDrop = visualDrop,
    }
    sessions[player] = session

    humanoid.HipHeight = session.BaseHipHeight + rideLift
    player:SetAttribute("MountSpeedMultiplier", math.max(1, tonumber(info.SpeedMultiplier) or 1.25))
    player:SetAttribute("EquippedMountId", mount.Id)
    player:SetAttribute("EquippedMountSpecies", mount.Species)
    applyMovement(player)

    return session
end

function Service:Equip(player, mountId)
    local data = DataService:Get(player)
    local mount = self:Find(player, mountId)
    if not data or not mount then return false, "Mount not found." end

    clearSession(player)
    local session, message = createMountedVisual(player, mount)
    if not session then
        data.EquippedMountId = ""
        return false, message or "Could not equip mount."
    end

    data.EquippedMountId = mount.Id
    return true, tostring(mount.Name or mount.Species) .. " equipped."
end

function Service:Restore(player)
    local data = DataService:Get(player)
    if not data then return end

    local mountId = type(data.EquippedMountId) == "string" and data.EquippedMountId or ""
    if mountId == "" then
        player:SetAttribute("MountSpeedMultiplier", 1)
        player:SetAttribute("EquippedMountId", "")
        player:SetAttribute("EquippedMountSpecies", "")
        applyMovement(player)
        return
    end

    local mount = self:Find(player, mountId)
    if not mount then
        data.EquippedMountId = ""
        clearSession(player)
        return
    end

    clearSession(player)
    createMountedVisual(player, mount)
    data.EquippedMountId = mount.Id
end

function Service:ApplyMovement(player)
    applyMovement(player)
end

function Service:PlayerRemoving(player)
    local session = sessions[player]
    sessions[player] = nil
    if session and session.Model and session.Model.Parent then
        session.Model:Destroy()
    end
end

function Service:Init()
    if started then return end
    started = true

    world = workspace:WaitForChild("WildernessPets")
    local old = world:FindFirstChild("MountedCreatures")
    if old then old:Destroy() end

    folder = Instance.new("Folder")
    folder.Name = "MountedCreatures"
    folder.Parent = world

    RunService.Heartbeat:Connect(function()
        for player, session in pairs(sessions) do
            local model = session.Model
            local _, root, humanoid = characterParts(player)

            if not player.Parent or not model or not model.Parent or not root or not humanoid or humanoid.Health <= 0 then
                if model and model.Parent then model:Destroy() end
                sessions[player] = nil
            else
                local look = root.CFrame.LookVector
                local flatLook = Vector3.new(look.X, 0, look.Z)
                if flatLook.Magnitude < 0.01 then flatLook = Vector3.new(0,0,-1) end
                flatLook = flatLook.Unit

                local basePosition = root.Position - Vector3.new(0, session.VisualDrop, 0)
                model:PivotTo(
                    CFrame.lookAt(
                        basePosition,
                        basePosition + flatLook
                    )
                )
            end
        end
    end)
end

return Service

[executed on device: DESKTOP-2DRH662 (dca896b2-d00d-4b2d-b53d-d5e192cf74e5)]