local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Root = ReplicatedStorage:WaitForChild("WildernessPets")
local ForgeRemote = Root.Remotes:WaitForChild("Forge")

local Config = require(Root.Shared.Config)
local QuestConfig = require(Root.Shared.QuestConfig)
local LootConfig = require(Root.Shared.LootConfig)
local EquipmentConfig = require(Root.Shared.EquipmentConfig)

local DataService = require(script.Parent.PlayerDataService)
local PetService = require(script.Parent.PetService)
local ShopService = require(script.Parent.ShopService)

local Service = {}
local rng = Random.new()
local started = false
local world
local smithModel
local active = setmetatable({}, {__mode = "k"})
local forgeSessions = setmetatable({}, {__mode = "k"})

local function nowServer()
    return workspace:GetServerTimeNow()
end

local function makePart(parent, name, size, cframe, color, material, shape)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.CFrame = cframe
    part.Color = color
    part.Material = material or Enum.Material.SmoothPlastic
    part.Shape = shape or Enum.PartType.Block
    part.Anchored = true
    part.CanCollide = true
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Parent = parent
    return part
end

local function terrainPoint(x, z, fallbackY)
    local origin = Vector3.new(x, 500, z)
    local result = workspace:Raycast(origin, Vector3.new(0, -1000, 0))
    if result then return result.Position end
    return Vector3.new(x, fallbackY or 17, z)
end

local function addBillboard(part)
    local gui = Instance.new("BillboardGui")
    gui.Name = "WildforgeLabel"
    gui.Size = UDim2.fromOffset(220, 62)
    gui.StudsOffsetWorldSpace = Vector3.new(0, 4.3, 0)
    gui.MaxDistance = 80
    gui.AlwaysOnTop = false
    gui.Parent = part

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1, 0, 0, 32)
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 16
    title.TextStrokeTransparency = .25
    title.TextColor3 = Color3.fromRGB(246, 179, 75)
    title.Text = "WILDFORGE SMITH"
    title.Parent = gui

    local subtitle = Instance.new("TextLabel")
    subtitle.BackgroundTransparency = 1
    subtitle.Position = UDim2.fromOffset(0, 30)
    subtitle.Size = UDim2.new(1, 0, 0, 24)
    subtitle.Font = Enum.Font.GothamBold
    subtitle.TextSize = 10
    subtitle.TextStrokeTransparency = .45
    subtitle.TextColor3 = Color3.fromRGB(220, 224, 226)
    subtitle.Text = "FORGE · EQUIP · WORLDFORGE"
    subtitle.Parent = gui
end

local function buildSmith()
    local settings = QuestConfig.World
    local xz = settings.WildforgeSmithXZ or Vector2.new(-43, 18)
    local ground = terrainPoint(xz.X, xz.Y, settings.CaveFallbackY)
    local base = ground + Vector3.new(0, .08, 0)

    local model = Instance.new("Model")
    model.Name = "WildforgeSmithNPC"

    local root = makePart(
        model,
        "HumanoidRootPart",
        Vector3.new(2, 2, 1),
        CFrame.new(base + Vector3.new(0, 2.15, 0)),
        Color3.fromRGB(50, 50, 50)
    )
    root.Transparency = 1
    root.CanCollide = false

    local torso = makePart(
        model,
        "Torso",
        Vector3.new(2.6, 3.1, 1.4),
        CFrame.new(base + Vector3.new(0, 3.35, 0)),
        Color3.fromRGB(66, 70, 75),
        Enum.Material.Fabric
    )
    torso.CanCollide = false

    local head = makePart(
        model,
        "Head",
        Vector3.new(1.8, 1.8, 1.8),
        CFrame.new(base + Vector3.new(0, 5.7, 0)),
        Color3.fromRGB(191, 147, 111),
        Enum.Material.SmoothPlastic,
        Enum.PartType.Ball
    )
    head.CanCollide = false

    local apron = makePart(
        model,
        "ForgeApron",
        Vector3.new(2.15, 2.6, .28),
        CFrame.new(base + Vector3.new(0, 3.1, -.82)),
        Color3.fromRGB(61, 47, 38),
        Enum.Material.Leather
    )
    apron.CanCollide = false

    for _, side in ipairs({-1, 1}) do
        local arm = makePart(
            model,
            side < 0 and "LeftArm" or "RightArm",
            Vector3.new(.68, 2.7, .68),
            CFrame.new(base + Vector3.new(side * 1.55, 3.3, 0)),
            Color3.fromRGB(76, 79, 82),
            Enum.Material.Fabric
        )
        arm.CanCollide = false

        local leg = makePart(
            model,
            side < 0 and "LeftLeg" or "RightLeg",
            Vector3.new(.82, 2.2, .92),
            CFrame.new(base + Vector3.new(side * .58, 1.15, 0)),
            Color3.fromRGB(45, 46, 49),
            Enum.Material.Fabric
        )
        leg.CanCollide = false
    end

    local forge = Instance.new("Model")
    forge.Name = "WildforgeStation"
    forge.Parent = model

    local anvilBase = makePart(
        forge,
        "AnvilBase",
        Vector3.new(2.8, 2.4, 2.5),
        CFrame.new(base + Vector3.new(-3.6, 1.25, -2.4)),
        Color3.fromRGB(57, 60, 63),
        Enum.Material.Metal
    )

    local anvilTop = makePart(
        forge,
        "AnvilTop",
        Vector3.new(4.4, .75, 2.2),
        CFrame.new(base + Vector3.new(-3.25, 2.75, -2.4)),
        Color3.fromRGB(92, 97, 101),
        Enum.Material.Metal
    )
    anvilTop.CanCollide = false

    local furnace = makePart(
        forge,
        "Furnace",
        Vector3.new(4.2, 4.1, 3.5),
        CFrame.new(base + Vector3.new(4.0, 2.05, -2.9)),
        Color3.fromRGB(76, 60, 48),
        Enum.Material.Brick
    )

    local fire = makePart(
        forge,
        "ForgeFire",
        Vector3.new(2.1, 1.55, .25),
        CFrame.new(base + Vector3.new(4.0, 2.2, -4.68)),
        Color3.fromRGB(255, 111, 36),
        Enum.Material.Neon
    )
    fire.CanCollide = false
    local light = Instance.new("PointLight")
    light.Color = Color3.fromRGB(255, 133, 56)
    light.Brightness = 2.5
    light.Range = 14
    light.Parent = fire

    local rack = makePart(
        forge,
        "MaterialRack",
        Vector3.new(7.5, .8, 2.5),
        CFrame.new(base + Vector3.new(.5, .5, -6.0)),
        Color3.fromRGB(93, 66, 43),
        Enum.Material.WoodPlanks
    )
    rack.CanCollide = false

    for index = 1, 5 do
        local ingot = makePart(
            forge,
            "Ingot_" .. tostring(index),
            Vector3.new(1.1, .28, .55),
            CFrame.new(base + Vector3.new(-2.4 + index * 1.0, 1.05, -5.9)),
            Color3.fromRGB(118 + index * 6, 122 + index * 5, 126 + index * 4),
            Enum.Material.Metal
        )
        ingot.CanCollide = false
    end

    model.PrimaryPart = root
    model.Parent = world
    addBillboard(torso)

    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "WildforgePrompt"
    prompt.ActionText = "Use Wildforge"
    prompt.ObjectText = "Wildforge Smith"
    prompt.MaxActivationDistance = 12
    prompt.HoldDuration = .15
    prompt.RequiresLineOfSight = false
    prompt.Parent = torso

    prompt.Triggered:Connect(function(player)
        if not player or not player.Parent then return end
        active[player] = {ExpiresAt = os.clock() + 120}
        ForgeRemote:FireClient(player, "Open")
    end)

    smithModel = model
end

local function playerRoot(player)
    local character = player.Character
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function distanceToSmith(player)
    local root = playerRoot(player)
    local smith = smithModel and smithModel.PrimaryPart
    if not root or not smith then return math.huge end
    return (root.Position - smith.Position).Magnitude
end

function Service:CanUseSmith(player)
    local record = active[player]
    if not record or os.clock() > (record.ExpiresAt or 0) then
        active[player] = nil
        return false, "Speak to the Wildforge Smith first."
    end
    if not smithModel or not smithModel.Parent then
        return false, "The Wildforge Smith is unavailable."
    end
    if distanceToSmith(player) > 24 then
        return false, "Move closer to the Wildforge Smith."
    end

    record.ExpiresAt = os.clock() + 120
    return true
end

local function ensureEquipmentList(data)
    data.Equipment = type(data.Equipment) == "table" and data.Equipment or {}
    return data.Equipment
end

local function normalizeStat(stat)
    if type(stat) ~= "table" then return nil end
    local name = tostring(stat.Name or "")
    if not EquipmentConfig.StatCaps[name] then return nil end
    return {
        Name = name,
        Value = math.max(0, tonumber(stat.Value) or 0),
    }
end

local function normalizeItem(item)
    if type(item) ~= "table" then return nil end

    item.Id = type(item.Id) == "string" and item.Id or HttpService:GenerateGUID(false)
    item.Name = tostring(item.Name or "Forged Equipment")
    item.Slot = tostring(item.Slot or "Charm")
    item.Tier = tostring(item.Tier or "Common")
    item.ItemLevel = math.clamp(math.floor(tonumber(item.ItemLevel) or 1), 1, 5)
    item.Quality = tostring(item.Quality or "Crude")
    item.ForgeScore = math.clamp(math.floor(tonumber(item.ForgeScore) or 0), 0, 100)
    item.WorldforgeLevel = math.clamp(
        math.floor(tonumber(item.WorldforgeLevel) or 0),
        0,
        EquipmentConfig.MaxWorldforgeLevel
    )
    item.Favourite = item.Favourite == true
    item.Tradeable = item.Tradeable ~= false
    item.VendorSellable = item.VendorSellable ~= false and item.BossUnique ~= true
    item.BossUnique = item.BossUnique == true
    item.MainStat = normalizeStat(item.MainStat) or {Name = "Power", Value = 0}
    item.Substats = type(item.Substats) == "table" and item.Substats or {}
    item.MaterialsUsed = type(item.MaterialsUsed) == "table" and item.MaterialsUsed or {}
    item.SmithSellValue = math.max(0, math.floor(tonumber(item.SmithSellValue) or 0))

    local clean = {}
    for _, stat in ipairs(item.Substats) do
        local normalized = normalizeStat(stat)
        if normalized then table.insert(clean, normalized) end
    end
    item.Substats = clean

    return item
end

function Service:GetEquipment(player)
    local data = DataService:Get(player)
    if not data then return {} end

    local list = ensureEquipmentList(data)
    for _, item in ipairs(list) do
        normalizeItem(item)
    end
    for _, pet in ipairs(PetService:GetPets(player)) do
        pet.Equipment = type(pet.Equipment) == "table" and pet.Equipment or {}
        for _, slotName in ipairs(EquipmentConfig.Slots) do
            if pet.Equipment[slotName] then
                normalizeItem(pet.Equipment[slotName])
            end
        end
    end

    return list
end

function Service:GetEquipmentCount(player)
    local data = DataService:Get(player)
    if not data then return 0 end

    local count = #ensureEquipmentList(data)
    for _, pet in ipairs(PetService:GetPets(player)) do
        local equipped = type(pet.Equipment) == "table" and pet.Equipment or {}
        for _, slotName in ipairs(EquipmentConfig.Slots) do
            if type(equipped[slotName]) == "table" then
                count += 1
            end
        end
    end
    return count
end

function Service:CanAddEquipment(player)
    return self:GetEquipmentCount(player) < (tonumber(Config.MaxEquipment) or EquipmentConfig.MaxEquipment)
end

function Service:AddEquipment(player, item, allowOverflow)
    local data = DataService:Get(player)
    item = normalizeItem(item)
    if not data or not item then return false, "Equipment unavailable." end

    if not allowOverflow and not self:CanAddEquipment(player) then
        return false, "Your equipment storage is full."
    end

    table.insert(ensureEquipmentList(data), item)
    return true, item
end

local function findUnequipped(data, itemId)
    for index, item in ipairs(ensureEquipmentList(data)) do
        if type(item) == "table" and item.Id == itemId then
            return normalizeItem(item), index
        end
    end
end

function Service:FindEquipment(player, itemId)
    local data = DataService:Get(player)
    if not data then return nil end

    local item, index = findUnequipped(data, itemId)
    if item then return item, nil, nil, index end

    for _, pet in ipairs(PetService:GetPets(player)) do
        local equipped = type(pet.Equipment) == "table" and pet.Equipment or {}
        for _, slotName in ipairs(EquipmentConfig.Slots) do
            local candidate = equipped[slotName]
            if type(candidate) == "table" and candidate.Id == itemId then
                return normalizeItem(candidate), pet, slotName, nil
            end
        end
    end
end

function Service:Equip(player, petId, itemId)
    local allowed, message = self:CanUseSmith(player)
    if not allowed then return false, message end

    local data = DataService:Get(player)
    local pet = PetService:Find(player, tostring(petId or ""))
    if not data or not pet then return false, "Pet not found." end
    if data.EquippedPetId == pet.Id then
        return false, "Unequip that companion before changing its equipment."
    end

    local item, index = findUnequipped(data, tostring(itemId or ""))
    if not item or not index then return false, "Equipment not found." end

    pet.Equipment = type(pet.Equipment) == "table" and pet.Equipment or {}
    local slot = item.Slot
    if not table.find(EquipmentConfig.Slots, slot) then
        return false, "That equipment has an invalid slot."
    end

    local old = pet.Equipment[slot]
    table.remove(data.Equipment, index)

    if old then
        old.EquippedPetId = nil
        table.insert(data.Equipment, old)
    end

    item.EquippedPetId = pet.Id
    pet.Equipment[slot] = item

    return true,
        tostring(item.Name)
            .. " equipped to "
            .. tostring(pet.Name or pet.Species)
            .. (old and ("; " .. tostring(old.Name) .. " returned to storage.") or ".")
end

function Service:Unequip(player, petId, slotName)
    local allowed, message = self:CanUseSmith(player)
    if not allowed then return false, message end

    local data = DataService:Get(player)
    local pet = PetService:Find(player, tostring(petId or ""))
    if not data or not pet then return false, "Pet not found." end
    if data.EquippedPetId == pet.Id then
        return false, "Unequip that companion before changing its equipment."
    end

    slotName = tostring(slotName or "")
    pet.Equipment = type(pet.Equipment) == "table" and pet.Equipment or {}
    local item = pet.Equipment[slotName]
    if not item then return false, "Nothing is equipped in that slot." end

    item.EquippedPetId = nil
    pet.Equipment[slotName] = nil
    table.insert(ensureEquipmentList(data), item)

    return true, tostring(item.Name) .. " returned to equipment storage."
end

function Service:SetFavourite(player, itemId, favourite)
    local allowed, message = self:CanUseSmith(player)
    if not allowed then return false, message end

    local item = self:FindEquipment(player, tostring(itemId or ""))
    if not item then return false, "Equipment not found." end

    item.Favourite = favourite == true
    return true,
        item.Favourite
            and (tostring(item.Name) .. " added to favourites.")
            or (tostring(item.Name) .. " removed from favourites.")
end

local function lootRarity(itemName)
    local _, _, rarity = LootConfig:GetTraderValue(itemName, Config.Pets)
    return rarity
end

local function planMaterialGroup(player, groupName, tier, needed, excluded)
    local data = DataService:Get(player)
    if not data then return nil end

    excluded = excluded or {}
    local candidates = {}

    for _, item in ipairs(data.Inventory or {}) do
        if type(item) == "table"
            and item.Type == "Loot"
            and math.max(0, tonumber(item.Quantity) or 0) > 0
            and lootRarity(item.Name) == tier
            and EquipmentConfig:GetMaterialGroup(item.Name) == groupName then

            local already = tonumber(excluded[item.Name]) or 0
            local available = math.max(0, math.floor(tonumber(item.Quantity) or 0) - already)
            if available > 0 then
                table.insert(candidates, {
                    Name = item.Name,
                    Available = available,
                    UnitValue = tonumber((LootConfig:GetTraderValue(item.Name, Config.Pets))) or 0,
                })
            end
        end
    end

    table.sort(candidates, function(a, b)
        if a.UnitValue == b.UnitValue then
            return a.Name < b.Name
        end
        return a.UnitValue < b.UnitValue
    end)

    local remaining = needed
    local plan = {}
    for _, candidate in ipairs(candidates) do
        if remaining <= 0 then break end
        local take = math.min(candidate.Available, remaining)
        table.insert(plan, {Name = candidate.Name, Quantity = take})
        excluded[candidate.Name] = (excluded[candidate.Name] or 0) + take
        remaining -= take
    end

    if remaining > 0 then return nil end
    return plan
end

local function combinePlans(first, second)
    local combined = {}
    local lookup = {}

    for _, plan in ipairs({first or {}, second or {}}) do
        for _, entry in ipairs(plan) do
            local existing = lookup[entry.Name]
            if existing then
                existing.Quantity += entry.Quantity
            else
                local copy = {Name = entry.Name, Quantity = entry.Quantity}
                lookup[entry.Name] = copy
                table.insert(combined, copy)
            end
        end
    end

    return combined
end

local function planRecipeMaterials(player, recipe)
    local excluded = {}
    local primary = planMaterialGroup(
        player,
        recipe.PrimaryGroup,
        recipe.Tier,
        recipe.PrimaryCount,
        excluded
    )
    if not primary then
        return nil,
            "You need "
                .. tostring(recipe.PrimaryCount)
                .. " "
                .. tostring(recipe.Tier)
                .. " "
                .. tostring(recipe.PrimaryGroup)
                .. " materials."
    end

    local secondary = planMaterialGroup(
        player,
        recipe.SecondaryGroup,
        recipe.Tier,
        recipe.SecondaryCount,
        excluded
    )
    if not secondary then
        return nil,
            "You need "
                .. tostring(recipe.SecondaryCount)
                .. " "
                .. tostring(recipe.Tier)
                .. " "
                .. tostring(recipe.SecondaryGroup)
                .. " materials."
    end

    return combinePlans(primary, secondary)
end

local function restoreMaterials(player, plan)
    for _, entry in ipairs(plan or {}) do
        ShopService:AddInventoryItem(player, "Loot", entry.Name, entry.Quantity)
    end
end

local function consumeMaterials(player, plan)
    local consumed = {}

    for _, entry in ipairs(plan or {}) do
        local ok = ShopService:ConsumeInventoryItem(
            player,
            "Loot",
            entry.Name,
            entry.Quantity
        )
        if not ok then
            restoreMaterials(player, consumed)
            return false
        end
        table.insert(consumed, {
            Name = entry.Name,
            Quantity = entry.Quantity,
        })
    end

    return true
end

local function roundStat(value)
    return math.max(0, math.floor((tonumber(value) or 0) * 2000 + 0.5) / 2000)
end

local function chooseUniqueStats(pool, excluded, count)
    local available = {}
    for _, statName in ipairs(pool) do
        if not excluded[statName] then
            table.insert(available, statName)
        end
    end

    local chosen = {}
    for _ = 1, math.min(count, #available) do
        local index = rng:NextInteger(1, #available)
        local statName = table.remove(available, index)
        excluded[statName] = true
        table.insert(chosen, statName)
    end
    return chosen
end

local function makeForgedItem(session, forgeScore)
    local blueprint = session.Recipe.Blueprint
    local qualityName, qualityMultiplier = EquipmentConfig:GetQuality(forgeScore)
    local itemLevel = EquipmentConfig:RollItemLevel(rng, session.Recipe.InvestmentId)
    local levelMultiplier = 1 + (itemLevel - 1) * 0.08

    local mainValue = EquipmentConfig:GetBaseStat(
        blueprint.MainStat,
        session.Recipe.Tier,
        false
    )
        * qualityMultiplier
        * levelMultiplier
        * rng:NextNumber(0.985, 1.015)

    local substatCount = qualityName == "Perfect" and 3 or 2
    local excluded = {[blueprint.MainStat] = true}
    local subNames = chooseUniqueStats(
        EquipmentConfig.SubstatPool,
        excluded,
        substatCount
    )
    local substats = {}

    for _, statName in ipairs(subNames) do
        local value = EquipmentConfig:GetBaseStat(
            statName,
            session.Recipe.Tier,
            true
        )
            * qualityMultiplier
            * levelMultiplier
            * rng:NextNumber(0.85, 1.15)

        table.insert(substats, {
            Name = statName,
            Value = roundStat(value),
        })
    end

    return normalizeItem({
        Id = HttpService:GenerateGUID(false),
        BlueprintId = session.Recipe.BlueprintId,
        Name = blueprint.Name,
        Slot = blueprint.Slot,
        Tier = session.Recipe.Tier,
        ItemLevel = itemLevel,
        Quality = qualityName,
        ForgeScore = forgeScore,
        MainStat = {
            Name = blueprint.MainStat,
            Value = roundStat(mainValue),
        },
        Substats = substats,
        WorldforgeLevel = 0,
        Favourite = false,
        Tradeable = true,
        VendorSellable = true,
        BossUnique = false,
        MaterialsUsed = session.Materials,
        ForgeCostCoins = session.Recipe.Coins,
        SmithSellValue = math.max(
            25,
            math.floor(
                session.Recipe.Coins
                    * EquipmentConfig.SmithSellReturn
                    * qualityMultiplier
                    + 0.5
            )
        ),
    })
end

local function trianglePosition(timeValue, startAt, period, offset)
    local phase = ((timeValue - startAt) / period + offset) % 2
    return phase <= 1 and phase or (2 - phase)
end

local function scoreHeat(session, clickAt)
    if clickAt < session.StartAt or clickAt > session.StartAt + 4.1 then
        return 0
    end

    local position = trianglePosition(
        clickAt,
        session.StartAt,
        session.HeatPeriod,
        session.HeatOffset
    )
    local distance = math.abs(position - 0.5)

    if distance <= 0.025 then return 100 end
    return math.clamp(math.floor((1 - distance / 0.50) * 100 + 0.5), 0, 99)
end

local function scoreTimed(clickAt, targetAt, perfectWindow, missWindow)
    local delta = math.abs(clickAt - targetAt)
    if delta <= perfectWindow then return 100 end
    return math.clamp(
        math.floor((1 - (delta - perfectWindow) / (missWindow - perfectWindow)) * 100 + 0.5),
        0,
        99
    )
end

local function forgeScore(session)
    local values = {
        session.Scores.Heat or 0,
        session.Scores.Hammer1 or 0,
        session.Scores.Hammer2 or 0,
        session.Scores.Hammer3 or 0,
        session.Scores.Quench or 0,
    }

    local total = 0
    local perfect = true
    for _, value in ipairs(values) do
        total += value
        if value < 97 then perfect = false end
    end

    if perfect then return 100 end
    return math.clamp(math.floor(total / #values + 0.5), 0, 99)
end

local function safeSessionPayload(session)
    return {
        Id = session.Id,
        BlueprintId = session.Recipe.BlueprintId,
        BlueprintName = session.Recipe.Blueprint.Name,
        Tier = session.Recipe.Tier,
        InvestmentId = session.Recipe.InvestmentId,
        StartAt = session.StartAt,
        HeatPeriod = session.HeatPeriod,
        HeatOffset = session.HeatOffset,
        HammerTargets = session.HammerTargets,
        QuenchTarget = session.QuenchTarget,
        EndAt = session.EndAt,
    }
end

function Service:FinishForge(player, sessionId)
    local session = forgeSessions[player]
    if not session or session.Id ~= tostring(sessionId or "") then
        return false, "That forge session is no longer active."
    end
    if session.Finished then return false, "That item has already been forged." end

    session.Finished = true
    local score = forgeScore(session)
    local item = makeForgedItem(session, score)

    local added = self:AddEquipment(player, item, true)
    forgeSessions[player] = nil

    if not added then
        -- Crafting can never be lost. If storage changed during the minigame,
        -- preserve the finished item even if it temporarily exceeds the cap.
        local data = DataService:Get(player)
        if data then
            table.insert(ensureEquipmentList(data), item)
            added = true
        end
    end

    if not added then
        restoreMaterials(player, session.Materials)
        DataService:AddCoins(player, session.Recipe.Coins)
        return false, "The forge could not store the finished item; your materials were refunded."
    end

    ForgeRemote:FireClient(player, "ForgeFinished", item)
    return true, item
end

function Service:BeginForge(player, blueprintId, tier, investmentId)
    local allowed, message = self:CanUseSmith(player)
    if not allowed then return false, message end
    if forgeSessions[player] then
        return false, "Finish your current forge first."
    end
    if not self:CanAddEquipment(player) then
        return false, "Your equipment storage is full."
    end

    local recipe = EquipmentConfig:GetRecipe(
        tostring(blueprintId or ""),
        tostring(tier or ""),
        tonumber(investmentId) or 1
    )
    if not recipe then return false, "That Wildforge recipe is invalid." end

    local data = DataService:Get(player)
    if not data then return false, "Player data is unavailable." end
    if (tonumber(data.Coins) or 0) < recipe.Coins then
        return false, "You need " .. tostring(recipe.Coins) .. " Coins for this forge."
    end

    local materialPlan, planMessage = planRecipeMaterials(player, recipe)
    if not materialPlan then return false, planMessage end

    if not consumeMaterials(player, materialPlan) then
        return false, "Your materials changed before the forge began."
    end

    if not DataService:SpendCoins(player, recipe.Coins) then
        restoreMaterials(player, materialPlan)
        return false, "You no longer have enough Coins."
    end

    local startAt = nowServer() + 1.2
    local session = {
        Id = HttpService:GenerateGUID(false),
        Recipe = recipe,
        Materials = materialPlan,
        StartAt = startAt,
        HeatPeriod = rng:NextNumber(1.35, 1.65),
        HeatOffset = rng:NextNumber(0, 1),
        HammerTargets = {
            startAt + 5.10,
            startAt + 6.35,
            startAt + 7.60,
        },
        QuenchTarget = startAt + 10.30,
        EndAt = startAt + 11.80,
        Scores = {},
        HammerDone = {},
        Finished = false,
    }

    forgeSessions[player] = session
    ForgeRemote:FireClient(player, "ForgeStarted", safeSessionPayload(session))

    task.delay(math.max(0.5, session.EndAt - nowServer() + 0.5), function()
        if forgeSessions[player] == session and not session.Finished then
            Service:FinishForge(player, session.Id)
        end
    end)

    return true, "The forge is hot."
end

function Service:RecordForgeInput(player, sessionId, stage, index, clientTime)
    local session = forgeSessions[player]
    if not session or session.Id ~= tostring(sessionId or "") or session.Finished then
        return false
    end

    local serverTime = nowServer()
    local clickAt = tonumber(clientTime) or serverTime
    if math.abs(clickAt - serverTime) > 0.55 then
        clickAt = serverTime
    end

    stage = tostring(stage or "")
    local score
    local key

    if stage == "Heat" then
        if session.Scores.Heat ~= nil then return false end
        key = "Heat"
        score = scoreHeat(session, clickAt)

    elseif stage == "Hammer" then
        index = math.clamp(math.floor(tonumber(index) or 0), 1, 3)
        key = "Hammer" .. tostring(index)
        if session.Scores[key] ~= nil then return false end
        score = scoreTimed(clickAt, session.HammerTargets[index], 0.09, 0.55)

    elseif stage == "Quench" then
        if session.Scores.Quench ~= nil then return false end
        key = "Quench"
        score = scoreTimed(clickAt, session.QuenchTarget, 0.10, 0.70)
    else
        return false
    end

    session.Scores[key] = score
    ForgeRemote:FireClient(player, "InputScored", stage, index, score)

    if stage == "Quench" then
        task.defer(function()
            if forgeSessions[player] == session and not session.Finished then
                Service:FinishForge(player, session.Id)
            end
        end)
    end

    return true
end

function Service:SellEquipment(player, itemId)
    local allowed, message = self:CanUseSmith(player)
    if not allowed then return false, message end

    local data = DataService:Get(player)
    if not data then return false, "Player data unavailable." end

    local item, index = findUnequipped(data, tostring(itemId or ""))
    if not item or not index then
        return false, "Unequip that item before selling it."
    end
    if item.Favourite then return false, "Favourite equipment cannot be sold." end
    if item.VendorSellable == false or item.BossUnique then
        return false, "World-boss equipment is player-trade only."
    end

    local value = math.max(1, math.floor(tonumber(item.SmithSellValue) or 1))
    table.remove(data.Equipment, index)
    DataService:AddCoins(player, value)

    return true, "Sold " .. tostring(item.Name) .. " for " .. tostring(value) .. " Coins."
end

function Service:SalvageEquipment(player, itemId)
    local allowed, message = self:CanUseSmith(player)
    if not allowed then return false, message end

    local data = DataService:Get(player)
    if not data then return false, "Player data unavailable." end

    local item, index = findUnequipped(data, tostring(itemId or ""))
    if not item or not index then
        return false, "Unequip that item before salvaging it."
    end
    if item.Favourite then return false, "Favourite equipment cannot be salvaged." end
    if item.BossUnique then
        return false, "World-boss unique equipment cannot be salvaged."
    end

    local returns = {}
    for _, material in ipairs(item.MaterialsUsed or {}) do
        local quantity = math.floor(
            math.max(0, tonumber(material.Quantity) or 0)
                * EquipmentConfig.SalvageReturn
        )
        if quantity > 0 then
            table.insert(returns, {
                Type = "Loot",
                Name = tostring(material.Name),
                Quantity = quantity,
            })
        end
    end

    if #returns == 0 and item.MaterialsUsed and item.MaterialsUsed[1] then
        table.insert(returns, {
            Type = "Loot",
            Name = tostring(item.MaterialsUsed[1].Name),
            Quantity = 1,
        })
    end

    local capacityOk, capacityMessage = ShopService:CanAddInventoryBatch(player, returns)
    if not capacityOk then return false, capacityMessage end

    table.remove(data.Equipment, index)
    local added, addMessage = ShopService:AddInventoryBatch(player, returns)
    if not added then
        table.insert(data.Equipment, index, item)
        return false, addMessage or "Could not return salvage materials."
    end

    return true, "Salvaged " .. tostring(item.Name) .. " and recovered part of its materials."
end

function Service:Worldforge(player, itemId, bossSpecies)
    local allowed, message = self:CanUseSmith(player)
    if not allowed then return false, message end

    bossSpecies = tostring(bossSpecies or "Jörmungandr")
    local source = EquipmentConfig.WorldforgeSources[bossSpecies]
    if not source then return false, "That world-boss tempering source is unavailable." end

    local item, equippedPet = self:FindEquipment(player, tostring(itemId or ""))
    if not item then return false, "Equipment not found." end
    if item.Favourite then
        -- Favourite items may be upgraded; the favourite is only a destructive/trade lock.
    end
    if equippedPet then
        local data = DataService:Get(player)
        if data and data.EquippedPetId == equippedPet.Id then
            return false, "Unequip that companion before Worldforging its equipment."
        end
    end

    local current = math.clamp(
        math.floor(tonumber(item.WorldforgeLevel) or 0),
        0,
        EquipmentConfig.MaxWorldforgeLevel
    )
    if current >= EquipmentConfig.MaxWorldforgeLevel then
        return false, "That item is already Worldforged +5."
    end

    local nextLevel = current + 1
    local cost = EquipmentConfig.WorldforgeCosts[nextLevel]
    if not cost then return false, "That Worldforge upgrade is unavailable." end

    local primaryOwned = ShopService:CountInventoryItem(player, "Loot", source.Primary)
    local secondaryOwned = ShopService:CountInventoryItem(player, "Loot", source.Secondary)
    if primaryOwned < cost.Primary then
        return false,
            "You need "
                .. tostring(cost.Primary)
                .. " "
                .. tostring(source.Primary)
                .. "."
    end
    if secondaryOwned < cost.Secondary then
        return false,
            "You need "
                .. tostring(cost.Secondary)
                .. " "
                .. tostring(source.Secondary)
                .. "."
    end

    local data = DataService:Get(player)
    if not data or (tonumber(data.Coins) or 0) < cost.Coins then
        return false, "You need " .. tostring(cost.Coins) .. " Coins."
    end

    if not ShopService:ConsumeInventoryItem(player, "Loot", source.Primary, cost.Primary) then
        return false, "Your world-boss materials changed."
    end

    if cost.Secondary > 0
        and not ShopService:ConsumeInventoryItem(player, "Loot", source.Secondary, cost.Secondary) then
        ShopService:AddInventoryItem(player, "Loot", source.Primary, cost.Primary)
        return false, "Your world-boss materials changed."
    end

    if not DataService:SpendCoins(player, cost.Coins) then
        ShopService:AddInventoryItem(player, "Loot", source.Primary, cost.Primary)
        if cost.Secondary > 0 then
            ShopService:AddInventoryItem(player, "Loot", source.Secondary, cost.Secondary)
        end
        return false, "You no longer have enough Coins."
    end

    item.WorldforgeLevel = nextLevel
    item.WorldforgeSource = bossSpecies

    return true,
        tostring(item.Name)
            .. " is now Worldforged +"
            .. tostring(nextLevel)
            .. ". All of its rolled stats gained another 3%."
end

function Service:CreateBossUnique(bossSpecies)
    bossSpecies = tostring(bossSpecies or "")
    local unique = EquipmentConfig.BossUniques[bossSpecies]
    if not unique then return nil end

    local mainName = EquipmentConfig.BossMainStatPool[
        rng:NextInteger(1, #EquipmentConfig.BossMainStatPool)
    ]

    local excluded = {[mainName] = true}
    local subNames = chooseUniqueStats(
        EquipmentConfig.SubstatPool,
        excluded,
        3
    )

    local function ancientValue(statName, substat)
        local base = EquipmentConfig:GetBaseStat(statName, "Mythic", substat)
        local value = base
            * 1.35
            * rng:NextNumber(
                EquipmentConfig.Qualities.Ancient.MinMultiplier,
                EquipmentConfig.Qualities.Ancient.MaxMultiplier
            )
        local cap = EquipmentConfig.StatCaps[statName] or value
        return roundStat(math.min(value, cap))
    end

    local subs = {}
    for _, statName in ipairs(subNames) do
        table.insert(subs, {
            Name = statName,
            Value = ancientValue(statName, true),
        })
    end

    return normalizeItem({
        Id = HttpService:GenerateGUID(false),
        BlueprintId = unique.Id,
        Name = unique.Name,
        Slot = unique.Slot,
        Tier = "Ancient",
        ItemLevel = 5,
        Quality = "Ancient",
        ForgeScore = 100,
        MainStat = {
            Name = mainName,
            Value = ancientValue(mainName, false),
        },
        Substats = subs,
        WorldforgeLevel = 0,
        Favourite = false,
        Tradeable = true,
        VendorSellable = false,
        BossUnique = true,
        BossSpecies = bossSpecies,
        MaterialsUsed = {},
        ForgeCostCoins = 0,
        SmithSellValue = 0,
    })
end

function Service:GetWorldforgeCost(item, bossSpecies)
    if type(item) ~= "table" then return nil end
    local nextLevel = math.clamp(
        math.floor(tonumber(item.WorldforgeLevel) or 0) + 1,
        1,
        EquipmentConfig.MaxWorldforgeLevel
    )
    local cost = EquipmentConfig.WorldforgeCosts[nextLevel]
    local source = EquipmentConfig.WorldforgeSources[bossSpecies or "Jörmungandr"]
    if not cost or not source then return nil end

    return {
        NextLevel = nextLevel,
        Primary = source.Primary,
        PrimaryCount = cost.Primary,
        Secondary = source.Secondary,
        SecondaryCount = cost.Secondary,
        Coins = cost.Coins,
    }
end

function Service:PlayerRemoving(player)
    local session = forgeSessions[player]
    if session and not session.Finished then
        Service:FinishForge(player, session.Id)
    end
    forgeSessions[player] = nil
    active[player] = nil
end

function Service:Init()
    if started then return end
    started = true

    world = workspace:WaitForChild("WildernessPets")

    local old = world:FindFirstChild("WildforgeSmithNPC")
    if old then old:Destroy() end

    buildSmith()

    ForgeRemote.OnServerEvent:Connect(function(player, action, ...)
        local args = {...}

        if action == "BeginForge" then
            local success, message = Service:BeginForge(
                player,
                args[1],
                args[2],
                args[3]
            )
            if not success then
                ForgeRemote:FireClient(player, "Error", message)
            end

        elseif action == "ForgeInput" then
            Service:RecordForgeInput(
                player,
                args[1],
                args[2],
                args[3],
                args[4]
            )

        elseif action == "Equip" then
            local success, message = Service:Equip(player, args[1], args[2])
            ForgeRemote:FireClient(player, "EquipmentResult", success, message)

        elseif action == "Unequip" then
            local success, message = Service:Unequip(player, args[1], args[2])
            ForgeRemote:FireClient(player, "EquipmentResult", success, message)

        elseif action == "Favourite" then
            local success, message = Service:SetFavourite(player, args[1], args[2] == true)
            ForgeRemote:FireClient(player, "EquipmentResult", success, message)

        elseif action == "Sell" then
            local success, message = Service:SellEquipment(player, args[1])
            ForgeRemote:FireClient(player, "EquipmentResult", success, message)

        elseif action == "Salvage" then
            local success, message = Service:SalvageEquipment(player, args[1])
            ForgeRemote:FireClient(player, "EquipmentResult", success, message)

        elseif action == "Worldforge" then
            local success, message = Service:Worldforge(player, args[1], args[2])
            ForgeRemote:FireClient(player, "EquipmentResult", success, message)
        end
    end)
end

return Service
