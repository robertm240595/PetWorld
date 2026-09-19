local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Root = ReplicatedStorage:WaitForChild("WildernessPets")
local ShopRemote = Root.Remotes:WaitForChild("Shop")
local Config = require(Root.Shared.Config)
local LootConfig = require(Root.Shared.LootConfig)
local QuestConfig = require(Root.Shared.QuestConfig)

local DataService = require(script.Parent.PlayerDataService)
local ShopService = require(script.Parent.ShopService)

local Service = {}
local started = false
local world
local traderModel
local active = setmetatable({}, {__mode = "k"})

local function terrainPoint(x, z, fallbackY)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances = {workspace.Terrain}

    local hit = workspace:Raycast(
        Vector3.new(x, 250, z),
        Vector3.new(0, -500, 0),
        params
    )

    if hit and hit.Material ~= Enum.Material.Water then
        return hit.Position
    end

    return Vector3.new(x, fallbackY or 17, z)
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
    part.CanCollide = name == "StallCounter" or name == "StallPost"
    part.CanTouch = false
    part.CanQuery = true
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Parent = parent
    return part
end

local function addBillboard(part)
    local gui = Instance.new("BillboardGui")
    gui.Name = "LootTraderLabel"
    gui.Size = UDim2.fromOffset(240, 58)
    gui.StudsOffsetWorldSpace = Vector3.new(0, 4.1, 0)
    gui.MaxDistance = 75
    gui.AlwaysOnTop = false
    gui.Parent = part

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1, 0, 0, 31)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.TextStrokeTransparency = .35
    title.TextColor3 = Color3.fromRGB(236, 198, 116)
    title.Text = "MATERIAL TRADER"
    title.Parent = gui

    local subtitle = Instance.new("TextLabel")
    subtitle.BackgroundTransparency = 1
    subtitle.Position = UDim2.fromOffset(0, 30)
    subtitle.Size = UDim2.new(1, 0, 0, 21)
    subtitle.Font = Enum.Font.GothamMedium
    subtitle.TextSize = 11
    subtitle.TextStrokeTransparency = .45
    subtitle.TextColor3 = Color3.fromRGB(224, 226, 218)
    subtitle.Text = "BUYS WILD LOOT"
    subtitle.Parent = gui
end

local function buildTrader()
    local settings = QuestConfig.World
    local xz = settings.LootTraderXZ or Vector2.new(39, -2)
    local ground = terrainPoint(xz.X, xz.Y, settings.CaveFallbackY)
    local base = ground + Vector3.new(0, .1, 0)

    local model = Instance.new("Model")
    model.Name = "MaterialTraderNPC"

    local root = makePart(
        model,
        "HumanoidRootPart",
        Vector3.new(2, 2, 1),
        CFrame.new(base + Vector3.new(0, 2.2, 0)),
        Color3.fromRGB(80, 72, 63),
        Enum.Material.SmoothPlastic
    )
    root.Transparency = 1
    root.CanCollide = false

    local torso = makePart(
        model,
        "Torso",
        Vector3.new(2.5, 3, 1.3),
        CFrame.new(base + Vector3.new(0, 3.3, 0)),
        Color3.fromRGB(95, 82, 60),
        Enum.Material.Fabric
    )
    torso.CanCollide = false

    local head = makePart(
        model,
        "Head",
        Vector3.new(1.75, 1.75, 1.75),
        CFrame.new(base + Vector3.new(0, 5.65, 0)),
        Color3.fromRGB(201, 158, 122),
        Enum.Material.SmoothPlastic,
        Enum.PartType.Ball
    )
    head.CanCollide = false

    local apron = makePart(
        model,
        "TraderApron",
        Vector3.new(2.1, 2.5, .3),
        CFrame.new(base + Vector3.new(0, 3.05, -.78)),
        Color3.fromRGB(92, 63, 42),
        Enum.Material.Fabric
    )
    apron.CanCollide = false

    for _, side in ipairs({-1, 1}) do
        local arm = makePart(
            model,
            side < 0 and "LeftArm" or "RightArm",
            Vector3.new(.65, 2.6, .65),
            CFrame.new(base + Vector3.new(side * 1.5, 3.25, 0)),
            Color3.fromRGB(127, 100, 66),
            Enum.Material.Fabric
        )
        arm.CanCollide = false

        local leg = makePart(
            model,
            side < 0 and "LeftLeg" or "RightLeg",
            Vector3.new(.8, 2.2, .9),
            CFrame.new(base + Vector3.new(side * .58, 1.15, 0)),
            Color3.fromRGB(55, 58, 61),
            Enum.Material.Fabric
        )
        leg.CanCollide = false
    end

    local stall = Instance.new("Model")
    stall.Name = "MaterialTraderStall"
    stall.Parent = model

    makePart(
        stall,
        "StallCounter",
        Vector3.new(9, 1.1, 3.2),
        CFrame.new(base + Vector3.new(0, 2.1, -3.4)),
        Color3.fromRGB(104, 73, 45),
        Enum.Material.WoodPlanks
    )

    for _, side in ipairs({-1, 1}) do
        makePart(
            stall,
            "StallPost",
            Vector3.new(.55, 6.3, .55),
            CFrame.new(base + Vector3.new(side * 4, 3.2, -4.4)),
            Color3.fromRGB(85, 61, 43),
            Enum.Material.Wood
        )
    end

    makePart(
        stall,
        "Canopy",
        Vector3.new(9.4, .4, 4.2),
        CFrame.new(base + Vector3.new(0, 6.1, -3.7))
            * CFrame.Angles(math.rad(-5), 0, 0),
        Color3.fromRGB(116, 88, 54),
        Enum.Material.Fabric
    ).CanCollide = false

    for index, offset in ipairs({
        Vector3.new(-3.1, .8, -2.0),
        Vector3.new(3.0, .65, -2.25),
        Vector3.new(2.0, .55, -5.2),
    }) do
        local crate = makePart(
            stall,
            "LootCrate_" .. tostring(index),
            Vector3.new(1.8, 1.4, 1.8),
            CFrame.new(base + offset)
                * CFrame.Angles(0, math.rad(index * 17), 0),
            Color3.fromRGB(122, 87, 50),
            Enum.Material.WoodPlanks
        )
        crate.CanCollide = false
    end

    local sack = makePart(
        stall,
        "HideBundle",
        Vector3.new(2.2, 1.2, 1.7),
        CFrame.new(base + Vector3.new(-1.2, 2.85, -3.3))
            * CFrame.Angles(0, math.rad(18), math.rad(10)),
        Color3.fromRGB(137, 108, 77),
        Enum.Material.Fabric,
        Enum.PartType.Ball
    )
    sack.CanCollide = false

    model.PrimaryPart = root
    model.Parent = world
    addBillboard(torso)

    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "MaterialTraderPrompt"
    prompt.ActionText = "Sell Loot"
    prompt.ObjectText = "Material Trader"
    prompt.MaxActivationDistance = 12
    prompt.HoldDuration = .15
    prompt.RequiresLineOfSight = false
    prompt.Parent = torso

    prompt.Triggered:Connect(function(player)
        if not player or not player.Parent then return end

        active[player] = {
            expiresAt = os.clock() + 45,
        }

        ShopRemote:FireClient(player, "OpenLootTrader")
    end)

    traderModel = model
end

local function distanceToTrader(player)
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    local part = traderModel and traderModel.PrimaryPart

    if not root or not part then
        return math.huge
    end

    return (root.Position - part.Position).Magnitude
end

function Service:CanTrade(player)
    local session = active[player]
    if not session or os.clock() > session.expiresAt then
        active[player] = nil
        return false, "Speak to the Material Trader first."
    end

    if not traderModel or not traderModel.Parent then
        active[player] = nil
        return false, "The Material Trader is unavailable."
    end

    if distanceToTrader(player) > 20 then
        return false, "Move closer to the Material Trader."
    end

    session.expiresAt = os.clock() + 45
    return true
end

function Service:GetSellValue(itemName)
    return LootConfig:GetTraderValue(itemName, Config.Pets)
end

function Service:Sell(player, itemName, quantity)
    local allowed, message = self:CanTrade(player)
    if not allowed then return false, message, 0 end

    local unitValue = self:GetSellValue(itemName)
    if not unitValue then
        return false, "That item is not wild-creature loot.", 0
    end

    local owned = ShopService:CountInventoryItem(player, "Loot", itemName)
    if owned <= 0 then
        return false, "You do not have any " .. tostring(itemName) .. ".", 0
    end

    quantity = math.max(1, math.floor(tonumber(quantity) or 1))
    quantity = math.min(quantity, owned)

    if not ShopService:ConsumeInventoryItem(player, "Loot", itemName, quantity) then
        return false, "Your inventory changed before the sale completed.", 0
    end

    local total = unitValue * quantity
    local balance = DataService:AddCoins(player, total)

    if balance == nil then
        ShopService:AddInventoryItem(player, "Loot", itemName, quantity)
        return false, "The Coin payment could not be completed.", 0
    end

    return true,
        "Sold " .. tostring(quantity) .. "x " .. tostring(itemName)
            .. " for " .. tostring(total) .. " Coins.",
        total
end

function Service:SellAll(player)
    local allowed, message = self:CanTrade(player)
    if not allowed then return false, message, 0 end

    local data = DataService:Get(player)
    if not data then return false, "Inventory unavailable.", 0 end

    local toSell = {}
    local total = 0

    for _, item in ipairs(data.Inventory or {}) do
        if type(item) == "table" and item.Type == "Loot" then
            local value = self:GetSellValue(item.Name)
            local quantity = math.max(0, math.floor(tonumber(item.Quantity) or 0))

            if value and quantity > 0 then
                table.insert(toSell, {
                    Name = item.Name,
                    Quantity = quantity,
                    Value = value,
                })
                total += value * quantity
            end
        end
    end

    if #toSell == 0 or total <= 0 then
        return false, "You do not have any sellable wild loot.", 0
    end

    local removed = {}
    for _, item in ipairs(toSell) do
        if ShopService:ConsumeInventoryItem(player, "Loot", item.Name, item.Quantity) then
            table.insert(removed, item)
        else
            for _, restore in ipairs(removed) do
                ShopService:AddInventoryItem(player, "Loot", restore.Name, restore.Quantity)
            end
            return false, "Your inventory changed before the bulk sale completed.", 0
        end
    end

    local balance = DataService:AddCoins(player, total)
    if balance == nil then
        for _, restore in ipairs(removed) do
            ShopService:AddInventoryItem(player, "Loot", restore.Name, restore.Quantity)
        end
        return false, "The Coin payment could not be completed.", 0
    end

    return true,
        "Sold all wild loot for " .. tostring(total) .. " Coins.",
        total
end

function Service:Close(player)
    active[player] = nil
end

function Service:PlayerRemoving(player)
    active[player] = nil
end

function Service:Init()
    if started then return end
    started = true

    world = workspace:WaitForChild("WildernessPets")

    local old = world:FindFirstChild("MaterialTraderNPC")
    if old then old:Destroy() end

    buildTrader()
end

Players.PlayerRemoving:Connect(function(player)
    Service:PlayerRemoving(player)
end)

return Service
