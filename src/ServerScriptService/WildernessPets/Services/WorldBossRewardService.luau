local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Root = ReplicatedStorage:WaitForChild("WildernessPets")
local BossLootRemote = Root.Remotes:WaitForChild("BossLoot")
local Config = require(Root.Shared.Config)
local LootConfig = require(Root.Shared.LootConfig)

local PetService = require(script.Parent.PetService)
local MountService = require(script.Parent.MountService)
local QuestService = require(script.Parent.QuestService)
local ShopService = require(script.Parent.ShopService)

local Service = {}
local started = false
local world
local folder
local rng = Random.new()
local contributions = setmetatable({}, {__mode = "k"})
local pouches = {}

local PET_TOKEN_SUFFIX = " Pet Relic"
local MOUNT_TOKEN_SUFFIX = " Mount Relic"

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

local function tokenName(species, kind)
    if kind == "Pet" then
        return tostring(species) .. PET_TOKEN_SUFFIX
    end
    return tostring(species) .. MOUNT_TOKEN_SUFFIX
end

local function speciesFromToken(name, kind)
    if type(name) ~= "string" then return nil end
    local suffix = kind == "Pet" and PET_TOKEN_SUFFIX or MOUNT_TOKEN_SUFFIX
    if #name <= #suffix or name:sub(-#suffix) ~= suffix then return nil end
    return name:sub(1, #name - #suffix)
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
        PetItemName = record.PetReward and tokenName(record.PetReward, "Pet") or nil,
        MountReward = record.MountReward,
        MountItemName = record.MountReward and tokenName(record.MountReward, "Mount") or nil,
        Materials = record.Materials or {},
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
    label.Size = UDim2.fromOffset(190, 44)
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

function Service:ResetBoss(boss)
    if boss then
        contributions[boss] = nil
    end
end

local function rollMaterials(bossSpecies, settings)
    local result = {}
    local drop = LootConfig:GetDrop(bossSpecies)
    if not drop then return result end

    if type(drop.Primary) == "string" and drop.Primary ~= "" then
        table.insert(result, {
            Type = "Loot",
            Name = drop.Primary,
            Quantity = rng:NextInteger(
                math.max(1, math.floor(tonumber(settings.PrimaryMaterialMin) or 2)),
                math.max(1, math.floor(tonumber(settings.PrimaryMaterialMax) or 4))
            ),
        })
    end

    if type(drop.Secondary) == "string"
        and drop.Secondary ~= ""
        and chance(settings.SecondaryMaterialChance or 0.35) then
        table.insert(result, {
            Type = "Loot",
            Name = drop.Secondary,
            Quantity = rng:NextInteger(
                math.max(1, math.floor(tonumber(settings.SecondaryMaterialMin) or 1)),
                math.max(1, math.floor(tonumber(settings.SecondaryMaterialMax) or 2))
            ),
        })
    end

    return result
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

    for player, contribution in pairs(entry) do
        local dealt = type(contribution) == "table"
            and math.max(0, tonumber(contribution.Damage) or 0)
            or math.max(0, tonumber(contribution) or 0)
        local support = type(contribution) == "table"
            and math.max(0, tonumber(contribution.Support) or 0)
            or 0
        local share = (dealt + support) / maximum

        if player.Parent and share >= 0.01 then
            QuestService:OnPlayerAction(player, "DefeatJormungdyrr", {
                Target = boss,
                BossId = boss:GetAttribute("BossId"),
                Species = bossSpecies,
                Damage = dealt,
                Support = support,
            })
        end

        if player.Parent and share >= threshold then
            angleIndex += 1

            local petReward
            local mountReward

            if chance(settings.AncientPetChance) then
                local mapped = settings.BossPetMap and settings.BossPetMap[bossSpecies]
                if mapped
                    and Config.Pets[mapped]
                    and Config.Pets[mapped].Rarity == "Ancient"
                    and Config.Pets[mapped].SpawnMode == "WorldBoss" then
                    petReward = mapped
                end
            end

            if chance(settings.AncientMountChance) then
                local pool = settings.AncientMountPool or {}
                if #pool > 0 then
                    local candidate = pool[rng:NextInteger(1, #pool)]
                    if Config.Mounts[candidate]
                        and Config.Mounts[candidate].Rarity == "Ancient"
                        and Config.Mounts[candidate].SpawnMode == "WorldBoss" then
                        mountReward = candidate
                    end
                end
            end

            local materials = rollMaterials(bossSpecies, settings)
            local origin = part and part.Position or Vector3.new()
            local angle = (angleIndex - 1) * 1.35
            local position = origin + Vector3.new(math.cos(angle) * 5, 0, math.sin(angle) * 5)
            local id = HttpService:GenerateGUID(false)
            local model, prompt = pouchVisual(position, player.UserId, bossSpecies)
            model.Name = "BossLootPouch_" .. id

            local pouchRecord = {
                Id = id,
                OwnerUserId = player.UserId,
                Player = player,
                BossSpecies = bossSpecies,
                PetReward = petReward,
                MountReward = mountReward,
                Materials = materials,
                Model = model,
            }
            pouches[id] = pouchRecord

            prompt.Triggered:Connect(function(triggeringPlayer)
                if triggeringPlayer.UserId ~= pouchRecord.OwnerUserId then
                    BossLootRemote:FireClient(
                        triggeringPlayer,
                        "Error",
                        "That world-boss pouch belongs to another player."
                    )
                    return
                end

                if pouches[id] == pouchRecord and model.Parent then
                    BossLootRemote:FireClient(triggeringPlayer, "Open", payload(pouchRecord))
                end
            end)

            model.Parent = folder
            created += 1

            task.delay(
                math.max(30, tonumber(settings.PouchLifetimeSeconds) or 180),
                function()
                    if pouches[id] == pouchRecord then
                        removePouch(pouchRecord)
                    end
                end
            )
        end
    end

    contributions[boss] = nil
    return created
end

local function rewardInventoryEntries(record)
    local entries = {}

    for _, material in ipairs(record.Materials or {}) do
        if type(material) == "table" then
            table.insert(entries, {
                Type = "Loot",
                Name = tostring(material.Name or ""),
                Quantity = math.max(1, math.floor(tonumber(material.Quantity) or 1)),
            })
        end
    end

    if record.PetReward then
        table.insert(entries, {
            Type = "BossPetToken",
            Name = tokenName(record.PetReward, "Pet"),
            Quantity = 1,
        })
    end

    if record.MountReward then
        table.insert(entries, {
            Type = "BossMountToken",
            Name = tokenName(record.MountReward, "Mount"),
            Quantity = 1,
        })
    end

    return entries
end

function Service:Collect(player, pouchId)
    local record = type(pouchId) == "string" and pouches[pouchId] or nil
    if not record or not record.Model or not record.Model.Parent then
        BossLootRemote:FireClient(
            player,
            "CollectResult",
            false,
            "That world-boss pouch is no longer available."
        )
        return
    end

    if record.OwnerUserId ~= player.UserId then
        BossLootRemote:FireClient(
            player,
            "CollectResult",
            false,
            "That world-boss pouch belongs to another player."
        )
        return
    end

    local root = playerRoot(player)
    local part = record.Model.PrimaryPart
    if not root or not part or (root.Position - part.Position).Magnitude > 20 then
        BossLootRemote:FireClient(
            player,
            "CollectResult",
            false,
            "Move closer to the world-boss pouch."
        )
        return
    end

    local entries = rewardInventoryEntries(record)
    local success, message = ShopService:AddInventoryBatch(player, entries)
    if not success then
        BossLootRemote:FireClient(player, "CollectResult", false, message)
        return
    end

    local result = payload(record)
    result.StoredItems = entries

    removePouch(record)
    BossLootRemote:FireClient(player, "CollectResult", true, result)
end

function Service:UseRewardItem(player, itemType, itemName)
    if itemType ~= "BossPetToken" and itemType ~= "BossMountToken" then
        return false, "That item is not a creature relic."
    end

    if ShopService:CountInventoryItem(player, itemType, itemName) <= 0 then
        return false, "You no longer own that relic."
    end

    if itemType == "BossPetToken" then
        local species = speciesFromToken(itemName, "Pet")
        local info = species and Config.Pets[species]
        if not info
            or info.Rarity ~= "Ancient"
            or info.SpawnMode ~= "WorldBoss" then
            return false, "That Ancient pet relic is invalid."
        end

        if #PetService:GetPets(player) >= (Config.MaxPets or 60) then
            return false, "Your pet collection is full."
        end

        if not ShopService:ConsumeInventoryItem(player, itemType, itemName, 1) then
            return false, "The relic could not be consumed."
        end

        local pet = PetService:Create(player, species, {
            Imprint = PetService:RollImprint(false),
            AcquiredFrom = "WorldBossRelic",
        })

        if not pet then
            ShopService:AddInventoryItem(player, itemType, itemName, 1)
            return false, "The Ancient pet could not be added to your collection."
        end

        pet.VendorSellable = false
        pet.Tradeable = true
        pet.Favourite = false

        return true,
            tostring(species)
                .. " has joined your pet collection. It cannot be sold to vendors, but it can be traded while unfavourited.",
            {
                Kind = "Pet",
                Species = species,
                Id = pet.Id,
            }
    end

    local species = speciesFromToken(itemName, "Mount")
    local info = species and Config.Mounts[species]
    if not info
        or info.Rarity ~= "Ancient"
        or info.SpawnMode ~= "WorldBoss" then
        return false, "That Ancient mount relic is invalid."
    end

    if #MountService:GetMounts(player) >= (Config.MaxMounts or 40) then
        return false, "Your mount collection is full."
    end

    if not ShopService:ConsumeInventoryItem(player, itemType, itemName, 1) then
        return false, "The relic could not be consumed."
    end

    local mount = MountService:Create(player, species, {
        Imprint = PetService:RollImprint(false),
        AcquiredFrom = "WorldBossRelic",
    })

    if not mount then
        ShopService:AddInventoryItem(player, itemType, itemName, 1)
        return false, "The Ancient mount could not be added to your collection."
    end

    mount.VendorSellable = false
    mount.Tradeable = true
    mount.Favourite = false

    return true,
        tostring(species)
            .. " has joined your mount collection. Mounts cannot be sold to vendors, but they can be traded while unfavourited.",
        {
            Kind = "Mount",
            Species = species,
            Id = mount.Id,
        }
end

function Service:PlayerRemoving(player)
    local remove = {}
    for _, record in pairs(pouches) do
        if record.OwnerUserId == player.UserId then
            table.insert(remove, record)
        end
    end
    for _, record in ipairs(remove) do
        removePouch(record)
    end

    for boss, entry in pairs(contributions) do
        entry[player] = nil
        if next(entry) == nil then
            contributions[boss] = nil
        end
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

    BossLootRemote.OnServerEvent:Connect(function(player, action, first, second)
        if action == "Collect" then
            Service:Collect(player, first)
        elseif action == "UseRewardItem" then
            local success, message, result = Service:UseRewardItem(
                player,
                tostring(first or ""),
                tostring(second or "")
            )
            BossLootRemote:FireClient(player, "UseResult", success, message, result)
        end
    end)
end

return Service
