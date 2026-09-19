local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Root = ReplicatedStorage:WaitForChild("WildernessPets")
local LootRemote = Root.Remotes:WaitForChild("Loot")
local Config = require(Root.Shared.Config)
local LootConfig = require(Root.Shared.LootConfig)

local DataService = require(script.Parent.PlayerDataService)
local ShopService = require(script.Parent.ShopService)

local Service = {}
local started = false
local world
local folder
local rng = Random.new()
local bags = {}

local function playerRoot(player)
    local character = player.Character
    return character and character:FindFirstChild("HumanoidRootPart")
end

function Service:GetCount(player, itemName)
    return ShopService:CountInventoryItem(player, "Loot", itemName)
end

function Service:AddItem(player, itemName, quantity)
    if type(itemName) ~= "string" or itemName == "" then return false, "Invalid loot item." end
    return ShopService:AddInventoryItem(player, "Loot", itemName, quantity)
end

function Service:ConsumeItem(player, itemName, quantity)
    return ShopService:ConsumeInventoryItem(player, "Loot", itemName, quantity)
end

local function randomCoins(baseCoins, rarity)
    baseCoins = math.max(1, math.floor(tonumber(baseCoins) or 1))
    local range = LootConfig.CoinMultipliers[rarity] or LootConfig.CoinMultipliers.Common
    local minimum = math.max(1, math.floor(baseCoins * (tonumber(range.Min) or .8)))
    local maximum = math.max(minimum, math.ceil(baseCoins * (tonumber(range.Max) or 1.25)))
    return rng:NextInteger(minimum, maximum)
end

function Service:Roll(species, rarity, baseCoins)
    local drop = LootConfig:GetDrop(species)
    local items = {}

    if drop then
        local primaryChance, secondaryChance = LootConfig:GetChances(species, rarity)
        if rng:NextNumber() <= primaryChance then
            table.insert(items, {
                Name = drop.Primary,
                Quantity = 1,
                Chance = primaryChance,
            })
        end
        if rng:NextNumber() <= secondaryChance then
            table.insert(items, {
                Name = drop.Secondary,
                Quantity = 1,
                Chance = secondaryChance,
            })
        end
    end

    return {
        Coins = randomCoins(baseCoins, rarity),
        Items = items,
    }
end

local function bagVisual(position, rarity)
    local model = Instance.new("Model")
    model.Name = "LootBag"

    local sack = Instance.new("Part")
    sack.Name = "Sack"
    sack.Shape = Enum.PartType.Ball
    sack.Size = Vector3.new(2.2, 2.4, 1.9)
    sack.Color = Color3.fromRGB(132, 93, 55)
    sack.Material = Enum.Material.Fabric
    sack.Anchored = true
    sack.CanCollide = false
    sack.CanTouch = false
    sack.CanQuery = true
    sack.Position = position + Vector3.new(0, 1.15, 0)
    sack.Parent = model

    local tie = Instance.new("Part")
    tie.Name = "Tie"
    tie.Shape = Enum.PartType.Cylinder
    tie.Size = Vector3.new(.32, .85, .32)
    tie.Color = Color3.fromRGB(221, 190, 107)
    tie.Material = Enum.Material.SmoothPlastic
    tie.Anchored = true
    tie.CanCollide = false
    tie.CanTouch = false
    tie.CanQuery = false
    tie.CFrame = CFrame.new(position + Vector3.new(0, 2.25, 0))
        * CFrame.Angles(0, 0, math.rad(90))
    tie.Parent = model

    local glow = Instance.new("PointLight")
    glow.Name = "LootGlow"
    glow.Brightness = rarity == "Mythic" and 2.2
        or rarity == "Legendary" and 1.8
        or rarity == "Epic" and 1.4
        or rarity == "Rare" and 1.1
        or .75
    glow.Range = 8
    glow.Color = Color3.fromRGB(255, 214, 125)
    glow.Parent = sack

    local label = Instance.new("BillboardGui")
    label.Name = "LootLabel"
    label.Size = UDim2.fromOffset(130, 34)
    label.StudsOffsetWorldSpace = Vector3.new(0, 2.1, 0)
    label.MaxDistance = 55
    label.AlwaysOnTop = false
    label.Parent = sack

    local labelText = Instance.new("TextLabel")
    labelText.BackgroundTransparency = 1
    labelText.Size = UDim2.fromScale(1, 1)
    labelText.Font = Enum.Font.GothamBold
    labelText.TextSize = 13
    labelText.TextStrokeTransparency = .35
    labelText.TextColor3 = Color3.fromRGB(255, 225, 151)
    labelText.Text = "LOOT BAG"
    labelText.Parent = label

    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "LootPrompt"
    prompt.ActionText = "Open Loot"
    prompt.ObjectText = "Loot Bag"
    prompt.MaxActivationDistance = 12
    prompt.HoldDuration = .15
    prompt.RequiresLineOfSight = false
    prompt.Parent = sack

    model.PrimaryPart = sack
    return model, prompt
end

local function clientPayload(record)
    local items = {}
    for _, item in ipairs(record.Items or {}) do
        table.insert(items, {
            Name = item.Name,
            Quantity = item.Quantity,
        })
    end
    return {
        BagId = record.Id,
        Species = record.Species,
        Rarity = record.Rarity,
        Coins = math.max(0, tonumber(record.Coins) or 0),
        Items = items,
        InventorySlots = ShopService:CountInventorySlots(record.Player),
        InventoryCapacity = ShopService:GetInventoryCapacity(record.Player),
    }
end

local function removeBag(record)
    if not record then return end
    bags[record.Id] = nil
    if record.Model and record.Model.Parent then
        record.Model:Destroy()
    end
end

function Service:SpawnBag(player, target, baseCoins)
    if not player or not target then return nil end

    local species = tostring(target:GetAttribute("Species") or "")
    local rarity = tostring(target:GetAttribute("Rarity") or "Common")
    if species == "" or not LootConfig:GetDrop(species) then return nil end

    local part = target.PrimaryPart or target:FindFirstChildWhichIsA("BasePart", true)
    if not part then return nil end

    local rolled = self:Roll(species, rarity, baseCoins)
    local id = HttpService:GenerateGUID(false)
    local model, prompt = bagVisual(part.Position, rarity)

    model.Name = "LootBag_" .. id
    model:SetAttribute("LootBagId", id)
    model:SetAttribute("LootOwnerUserId", player.UserId)
    model:SetAttribute("LootSpecies", species)
    model:SetAttribute("LootRarity", rarity)

    local record = {
        Id = id,
        OwnerUserId = player.UserId,
        Player = player,
        Species = species,
        Rarity = rarity,
        Coins = rolled.Coins,
        Items = rolled.Items,
        Model = model,
        CreatedAt = os.clock(),
    }
    bags[id] = record

    prompt.ObjectText = species .. " Loot"
    prompt.Triggered:Connect(function(triggeringPlayer)
        if triggeringPlayer.UserId ~= record.OwnerUserId then
            LootRemote:FireClient(triggeringPlayer, "Error", "That loot belongs to another player.")
            return
        end
        if bags[id] ~= record or not model.Parent then return end
        LootRemote:FireClient(triggeringPlayer, "Open", clientPayload(record))
    end)

    -- Replicate only after ownership, contents, and prompt handling are ready.
    model.Parent = folder

    task.delay(math.max(1, tonumber(LootConfig.BagLifetimeSeconds) or 30), function()
        if bags[id] == record then
            removeBag(record)
        end
    end)

    return id
end

function Service:Collect(player, bagId, selectedNames)
    local record = type(bagId) == "string" and bags[bagId] or nil
    if not record or not record.Model or not record.Model.Parent then
        LootRemote:FireClient(player, "CollectResult", false, "That loot bag is no longer available.")
        return
    end
    if record.OwnerUserId ~= player.UserId then
        LootRemote:FireClient(player, "CollectResult", false, "That loot belongs to another player.")
        return
    end

    local root = playerRoot(player)
    local part = record.Model.PrimaryPart
    if not root or not part
        or (root.Position - part.Position).Magnitude > math.max(12, tonumber(LootConfig.CollectDistance) or 20) then
        LootRemote:FireClient(player, "CollectResult", false, "Move closer to the loot bag.")
        return
    end

    local data = DataService:Get(player)
    if not data then
        LootRemote:FireClient(player, "CollectResult", false, "Player data is unavailable.")
        return
    end

    selectedNames = type(selectedNames) == "table" and selectedNames or {}
    local selected = {}
    for _, name in ipairs(selectedNames) do
        if type(name) == "string" then selected[name] = true end
    end

    local picked = {}
    local newSlots = 0
    for _, item in ipairs(record.Items or {}) do
        if selected[item.Name] then
            table.insert(picked, item)
            if ShopService:CountInventoryItem(player, "Loot", item.Name) <= 0 then
                newSlots += 1
            end
        end
    end

    local usedSlots = ShopService:CountInventorySlots(player)
    local capacity = ShopService:GetInventoryCapacity(player)
    if usedSlots + newSlots > capacity then
        LootRemote:FireClient(
            player,
            "CollectResult",
            false,
            "Those selected materials need " .. tostring(newSlots)
                .. " new inventory slot(s), but your bag is "
                .. tostring(usedSlots) .. "/" .. tostring(capacity) .. "."
        )
        return
    end

    for _, item in ipairs(picked) do
        local added, reason = self:AddItem(player, item.Name, item.Quantity)
        if not added then
            LootRemote:FireClient(player, "CollectResult", false, reason or "Inventory changed before loot could be collected.")
            return
        end
    end

    if #picked > 0 then
        local pickedSet = {}
        for _, item in ipairs(picked) do pickedSet[item.Name] = true end
        local remaining = {}
        for _, item in ipairs(record.Items or {}) do
            if not pickedSet[item.Name] then table.insert(remaining, item) end
        end
        record.Items = remaining
    end

    local collectedCoins = math.max(0, math.floor(tonumber(record.Coins) or 0))
    local balance
    if collectedCoins > 0 then
        balance = DataService:AddCoins(player, collectedCoins)
        record.Coins = 0
    end

    local collectedItems = {}
    for _, item in ipairs(picked) do
        table.insert(collectedItems, {Name=item.Name, Quantity=item.Quantity})
    end

    local bagEmpty = (tonumber(record.Coins) or 0) <= 0 and #(record.Items or {}) == 0
    local remainingPayload = bagEmpty and nil or clientPayload(record)
    if bagEmpty then removeBag(record) end

    LootRemote:FireClient(player, "CollectResult", true, {
        BagId = bagId,
        Coins = collectedCoins,
        Items = collectedItems,
        CoinBalance = balance,
        Remaining = remainingPayload,
        InventorySlots = ShopService:CountInventorySlots(player),
        InventoryCapacity = ShopService:GetInventoryCapacity(player),
    })
end

function Service:PlayerRemoving(player)
    local owned = {}
    for _, record in pairs(bags) do
        if record.OwnerUserId == player.UserId then
            table.insert(owned, record)
        end
    end
    for _, record in ipairs(owned) do
        removeBag(record)
    end
end

function Service:Init()
    if started then return end
    started = true

    world = workspace:WaitForChild("WildernessPets")
    local old = world:FindFirstChild("LootBags")
    if old then old:Destroy() end

    folder = Instance.new("Folder")
    folder.Name = "LootBags"
    folder.Parent = world

    LootRemote.OnServerEvent:Connect(function(player, action, value)
        if action == "Collect" then
            local payload = type(value) == "table" and value or {}
            Service:Collect(player, payload.BagId, payload.Items)
        end
    end)
end

return Service
