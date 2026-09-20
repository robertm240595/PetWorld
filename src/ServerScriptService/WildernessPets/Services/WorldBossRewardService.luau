local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Root = ReplicatedStorage:WaitForChild("WildernessPets")
local BossLootRemote = Root.Remotes:WaitForChild("BossLoot")
local Config = require(Root.Shared.Config)

local DataService = require(script.Parent.PlayerDataService)
local PetService = require(script.Parent.PetService)
local MountService = require(script.Parent.MountService)

local Service = {}
local started = false
local world
local folder
local rng = Random.new()
local contributions = setmetatable({}, {__mode = "k"})
local pouches = {}

local function bossPart(boss)
    if not boss or not boss.Parent then return nil end
    return boss.PrimaryPart or boss:FindFirstChildWhichIsA("BasePart", true)
end

local function playerRoot(player)
    local character = player.Character
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function chance(value)
    return rng:NextNumber() <= math.max(0, tonumber(value) or 0)
end

local function removePouch(record)
    if not record then return end
    pouches[record.Id] = nil
    if record.Model and record.Model.Parent then
        record.Model:Destroy()
    end
end

local function payload(record)
    return {
        PouchId = record.Id,
        BossSpecies = record.BossSpecies,
        PetReward = record.PetReward,
        MountReward = record.MountReward,
    }
end

local function pouchVisual(position, ownerUserId, bossSpecies)
    local model = Instance.new("Model")
    model.Name = "WorldBossPouch"

    local pouch = Instance.new("Part")
    pouch.Name = "Pouch"
    pouch.Shape = Enum.PartType.Ball
    pouch.Size = Vector3.new(2.5, 2.1, 2.1)
    pouch.Color = Color3.fromRGB(74, 55, 82)
    pouch.Material = Enum.Material.Fabric
    pouch.Anchored = true
    pouch.CanCollide = false
    pouch.CanTouch = false
    pouch.CanQuery = true
    pouch.Position = position + Vector3.new(0, 1.2, 0)
    pouch.Parent = model

    local band = Instance.new("Part")
    band.Name = "AncientBand"
    band.Size = Vector3.new(2.65, .32, 2.25)
    band.Color = Color3.fromRGB(235, 154, 72)
    band.Material = Enum.Material.Neon
    band.Anchored = true
    band.CanCollide = false
    band.CanTouch = false
    band.CanQuery = false
    band.CFrame = CFrame.new(position + Vector3.new(0, 1.35, 0))
    band.Parent = model

    local glow = Instance.new("PointLight")
    glow.Color = Color3.fromRGB(255, 152, 82)
    glow.Brightness = 1.8
    glow.Range = 10
    glow.Parent = pouch

    local label = Instance.new("BillboardGui")
    label.Name = "BossLootLabel"
    label.Size = UDim2.fromOffset(180, 40)
    label.StudsOffsetWorldSpace = Vector3.new(0, 2.2, 0)
    label.MaxDistance = 65
    label.AlwaysOnTop = false
    label.Parent = pouch

    local labelText = Instance.new("TextLabel")
    labelText.BackgroundTransparency = 1
    labelText.Size = UDim2.fromScale(1, 1)
    labelText.Font = Enum.Font.GothamBold
    labelText.TextSize = 13
    labelText.TextStrokeTransparency = .25
    labelText.TextColor3 = Color3.fromRGB(255, 195, 111)
    labelText.Text = "WORLD BOSS POUCH"
    labelText.Parent = label

    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "BossLootPrompt"
    prompt.ActionText = "Open Pouch"
    prompt.ObjectText = tostring(bossSpecies or "World Boss") .. " Spoils"
    prompt.MaxActivationDistance = 12
    prompt.HoldDuration = .15
    prompt.RequiresLineOfSight = false
    prompt.Parent = pouch

    model.PrimaryPart = pouch
    model:SetAttribute("BossLootOwnerUserId", ownerUserId)
    model:SetAttribute("BossSpecies", bossSpecies)
    return model, prompt
end

local function contributionEntry(boss, player)
    local entry = contributions[boss]
    if not entry then
        entry = {}
        contributions[boss] = entry
    end

    local record = entry[player]
    if type(record) ~= "table" then
        record = {
            Damage = math.max(0, tonumber(record) or 0),
            Support = 0,
        }
        entry[player] = record
    end

    return record
end

function Service:RecordDamage(boss, player, damage)
    if not boss or not boss.Parent or not player or not player.Parent then return end
    if boss:GetAttribute("WorldBoss") ~= true then return end

    damage = math.max(0, tonumber(damage) or 0)
    if damage <= 0 then return end

    local record = contributionEntry(boss, player)
    record.Damage += damage
end

function Service:RecordSupport(boss, player, score)
    if not boss or not boss.Parent or not player or not player.Parent then return end
    if boss:GetAttribute("WorldBoss") ~= true then return end

    score = math.max(0, tonumber(score) or 0)
    if score <= 0 then return end

    local maximum = math.max(1, tonumber(boss:GetAttribute("MaxHealth")) or 1)
    local record = contributionEntry(boss, player)

    -- Support can qualify a genuine support build for rewards, but cannot be
    -- spammed indefinitely to outweigh actual participation.
    record.Support = math.min(maximum * 0.35, record.Support + score)
end

function Service:GetContribution(boss, player)
    local entry = contributions[boss]
    local record = entry and entry[player]
    if type(record) ~= "table" then
        return math.max(0, tonumber(record) or 0), 0
    end
    return math.max(0, tonumber(record.Damage) or 0),
        math.max(0, tonumber(record.Support) or 0)
end

function Service:GetDamageShare(boss, player)
    local damage = self:GetContribution(boss, player)
    local maximum = math.max(1, tonumber(boss:GetAttribute("MaxHealth")) or 1)
    return damage / maximum
end

function Service:GetContributionShare(boss, player)
    local damage, support = self:GetContribution(boss, player)
    local maximum = math.max(1, tonumber(boss:GetAttribute("MaxHealth")) or 1)
    return (damage + support) / maximum
end

function Service:ResolveBossDeath(boss)
    if not boss or boss:GetAttribute("WorldBoss") ~= true then return 0 end
    if boss:GetAttribute("BossPouchesResolved") == true then return 0 end
    boss:SetAttribute("BossPouchesResolved", true)

    local part = bossPart(boss)
    local bossSpecies = tostring(boss:GetAttribute("Species") or boss.Name)
    local entry = contributions[boss] or {}
    local settings = Config.WorldBossRewards or {}
    local threshold = math.max(0, tonumber(settings.MinimumDamageShare) or .10)
    local maximum = math.max(1, tonumber(boss:GetAttribute("MaxHealth")) or 1)
    local created = 0
    local angleIndex = 0

    for player, record in pairs(entry) do
        local dealt = type(record) == "table"
            and math.max(0, tonumber(record.Damage) or 0)
            or math.max(0, tonumber(record) or 0)
        local support = type(record) == "table"
            and math.max(0, tonumber(record.Support) or 0)
            or 0
        local share = (dealt + support) / maximum

        if player.Parent and share >= threshold then
            angleIndex += 1
            local petReward
            local mountReward

            if chance(settings.AncientPetChance) then
                local mapped = settings.BossPetMap and settings.BossPetMap[bossSpecies]
                if mapped and Config.Pets[mapped] and Config.Pets[mapped].Rarity == "Ancient" then
                    petReward = mapped
                end
            end

            if chance(settings.AncientMountChance) then
                local pool = settings.AncientMountPool or {}
                if #pool > 0 then
                    local candidate = pool[rng:NextInteger(1, #pool)]
                    if Config.Mounts[candidate] and Config.Mounts[candidate].Rarity == "Ancient" then
                        mountReward = candidate
                    end
                end
            end

            local origin = part and part.Position or Vector3.new()
            local angle = (angleIndex - 1) * 1.35
            local position = origin + Vector3.new(math.cos(angle) * 5, 0, math.sin(angle) * 5)
            local id = HttpService:GenerateGUID(false)
            local model, prompt = pouchVisual(position, player.UserId, bossSpecies)
            model.Name = "BossLootPouch_" .. id

            local record = {
                Id = id,
                OwnerUserId = player.UserId,
                Player = player,
                BossSpecies = bossSpecies,
                PetReward = petReward,
                MountReward = mountReward,
                Model = model,
            }
            pouches[id] = record

            prompt.Triggered:Connect(function(triggeringPlayer)
                if triggeringPlayer.UserId ~= record.OwnerUserId then
                    BossLootRemote:FireClient(triggeringPlayer, "Error", "That world-boss pouch belongs to another player.")
                    return
                end
                if pouches[id] == record and model.Parent then
                    BossLootRemote:FireClient(triggeringPlayer, "Open", payload(record))
                end
            end)

            model.Parent = folder
            created += 1

            task.delay(120, function()
                if pouches[id] == record then removePouch(record) end
            end)
        end
    end

    contributions[boss] = nil
    return created
end

function Service:Collect(player, pouchId)
    local record = type(pouchId) == "string" and pouches[pouchId] or nil
    if not record or not record.Model or not record.Model.Parent then
        BossLootRemote:FireClient(player, "CollectResult", false, "That world-boss pouch is no longer available.")
        return
    end
    if record.OwnerUserId ~= player.UserId then
        BossLootRemote:FireClient(player, "CollectResult", false, "That world-boss pouch belongs to another player.")
        return
    end

    local root = playerRoot(player)
    local part = record.Model.PrimaryPart
    if not root or not part or (root.Position - part.Position).Magnitude > 20 then
        BossLootRemote:FireClient(player, "CollectResult", false, "Move closer to the world-boss pouch.")
        return
    end

    local data = DataService:Get(player)
    if not data then
        BossLootRemote:FireClient(player, "CollectResult", false, "Player data is unavailable.")
        return
    end

    if record.PetReward then
        data.Pets = type(data.Pets) == "table" and data.Pets or {}
        if #data.Pets >= (Config.MaxPets or 60) then
            BossLootRemote:FireClient(player, "CollectResult", false, "Your pet collection is full. Make room before claiming this Ancient pet.")
            return
        end
    end
    if record.MountReward then
        data.Mounts = type(data.Mounts) == "table" and data.Mounts or {}
        if #data.Mounts >= (Config.MaxMounts or 40) then
            BossLootRemote:FireClient(player, "CollectResult", false, "Your mount collection is full. Make room before claiming this Ancient mount.")
            return
        end
    end

    local grantedPet
    local grantedMount
    if record.PetReward then
        local pet = PetService:Create(player, record.PetReward, {
            Imprint = PetService:RollImprint(false),
        })
        if not pet then
            BossLootRemote:FireClient(player, "CollectResult", false, "The Ancient pet reward could not be stored.")
            return
        end
        grantedPet = pet.Species
    end
    if record.MountReward then
        local mount = MountService:Create(player, record.MountReward, {
            Imprint = PetService:RollImprint(false),
            AcquiredFrom = "WorldBoss",
        })
        if not mount then
            BossLootRemote:FireClient(player, "CollectResult", false, "The Ancient mount reward could not be stored.")
            return
        end
        grantedMount = mount.Species
    end

    removePouch(record)
    BossLootRemote:FireClient(player, "CollectResult", true, {
        BossSpecies = record.BossSpecies,
        PetReward = grantedPet,
        MountReward = grantedMount,
    })
end

function Service:PlayerRemoving(player)
    local remove = {}
    for _, record in pairs(pouches) do
        if record.OwnerUserId == player.UserId then
            table.insert(remove, record)
        end
    end
    for _, record in ipairs(remove) do removePouch(record) end

    for boss, entry in pairs(contributions) do
        entry[player] = nil
        if next(entry) == nil then contributions[boss] = nil end
    end
end

function Service:Init()
    if started then return end
    started = true

    world = workspace:WaitForChild("WildernessPets")
    local old = world:FindFirstChild("WorldBossLootPouches")
    if old then old:Destroy() end

    folder = Instance.new("Folder")
    folder.Name = "WorldBossLootPouches"
    folder.Parent = world

    BossLootRemote.OnServerEvent:Connect(function(player, action, value)
        if action == "Collect" then
            Service:Collect(player, value)
        end
    end)
end

return Service
