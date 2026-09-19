local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Root = ReplicatedStorage:WaitForChild("WildernessPets")
local LootRemote = Root.Remotes:WaitForChild("Loot")
local world = workspace:WaitForChild("WildernessPets")
local lootFolder = world:WaitForChild("LootBags")

local gui = Instance.new("ScreenGui")
gui.Name = "WildLootUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 110
gui.Parent = playerGui

local panel
local statusLabel

local function round(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 9)
    corner.Parent = parent
end

local function outline(parent, transparency)
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(196, 159, 87)
    stroke.Transparency = transparency or .3
    stroke.Thickness = 1
    stroke.Parent = parent
end

local function label(parent, value, position, size, textSize, color)
    local text = Instance.new("TextLabel")
    text.BackgroundTransparency = 1
    text.Position = position
    text.Size = size
    text.Font = Enum.Font.GothamMedium
    text.TextSize = textSize or 13
    text.TextColor3 = color or Color3.fromRGB(239, 232, 213)
    text.Text = value or ""
    text.Parent = parent
    return text
end

local function closePanel()
    if panel then
        panel:Destroy()
        panel = nil
        statusLabel = nil
    end
end

local function makeButton(parent, value, position, size)
    local button = Instance.new("TextButton")
    button.Position = position
    button.Size = size
    button.BackgroundColor3 = Color3.fromRGB(84, 70, 43)
    button.BorderSizePixel = 0
    button.TextColor3 = Color3.fromRGB(250, 240, 210)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 12
    button.Text = value
    button.Parent = parent
    round(button, 7)
    outline(button, .4)
    return button
end

local function showLoot(data)
    if type(data) ~= "table" or type(data.BagId) ~= "string" then return end
    closePanel()

    panel = Instance.new("Frame")
    panel.Name = "LootWindow"
    panel.AnchorPoint = Vector2.new(.5, .5)
    panel.Position = UDim2.new(.5, 0, .5, 45)
    panel.Size = UDim2.fromOffset(470, 320)
    panel.BackgroundColor3 = Color3.fromRGB(25, 29, 31)
    panel.BackgroundTransparency = .03
    panel.BorderSizePixel = 0
    panel.Parent = gui
    round(panel, 12)
    outline(panel, .18)

    local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
    local scale = Instance.new("UIScale")
    scale.Scale = math.min(1, (viewport.X - 24) / 470, (viewport.Y - 70) / 320)
    scale.Parent = panel

    local title = label(
        panel,
        tostring(data.Species or "Wild") .. " LOOT",
        UDim2.fromOffset(20, 15),
        UDim2.fromOffset(350, 28),
        20,
        Color3.fromRGB(245, 210, 126)
    )
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left

    local rarity = label(
        panel,
        tostring(data.Rarity or "Common"),
        UDim2.fromOffset(20, 44),
        UDim2.fromOffset(300, 20),
        11,
        Color3.fromRGB(167, 177, 180)
    )
    rarity.TextXAlignment = Enum.TextXAlignment.Left

    local close = makeButton(panel, "×", UDim2.new(1, -48, 0, 12), UDim2.fromOffset(34, 31))
    close.TextSize = 20
    close.Activated:Connect(closePanel)

    local slots = math.max(0, tonumber(data.InventorySlots) or 0)
    local capacity = math.max(1, tonumber(data.InventoryCapacity) or 25)
    local capacityLabel = label(
        panel,
        "Inventory  " .. tostring(slots) .. "/" .. tostring(capacity) .. " slots",
        UDim2.fromOffset(20, 65),
        UDim2.fromOffset(410, 20),
        10,
        Color3.fromRGB(158, 169, 170)
    )
    capacityLabel.TextXAlignment = Enum.TextXAlignment.Left

    local contents = Instance.new("Frame")
    contents.Name = "Contents"
    contents.Position = UDim2.fromOffset(20, 91)
    contents.Size = UDim2.fromOffset(430, 170)
    contents.BackgroundColor3 = Color3.fromRGB(35, 40, 42)
    contents.BorderSizePixel = 0
    contents.Parent = panel
    round(contents, 9)

    local coins = math.max(0, tonumber(data.Coins) or 0)
    local rowIndex = 0

    if coins > 0 then
        rowIndex += 1
        local coinRow = Instance.new("TextButton")
        coinRow.Name = "Coins"
        coinRow.Position = UDim2.fromOffset(15, 10)
        coinRow.Size = UDim2.fromOffset(400, 42)
        coinRow.BackgroundColor3 = Color3.fromRGB(59, 54, 38)
        coinRow.BorderSizePixel = 0
        coinRow.AutoButtonColor = true
        coinRow.Text = ""
        coinRow.Parent = contents
        round(coinRow, 7)
        outline(coinRow, .55)

        local coinText = label(
            coinRow,
            "Coins  ·  +" .. tostring(coins),
            UDim2.fromOffset(10, 0),
            UDim2.fromOffset(270, 42),
            14,
            Color3.fromRGB(245, 210, 100)
        )
        coinText.Font = Enum.Font.GothamBold
        coinText.TextXAlignment = Enum.TextXAlignment.Left

        local takeText = label(
            coinRow,
            "CLICK TO TAKE",
            UDim2.fromOffset(280, 0),
            UDim2.fromOffset(108, 42),
            9,
            Color3.fromRGB(133, 205, 146)
        )
        takeText.Font = Enum.Font.GothamBold
        takeText.TextXAlignment = Enum.TextXAlignment.Right

        coinRow.Activated:Connect(function()
            coinRow.Active = false
            coinRow.AutoButtonColor = false
            takeText.Text = "TAKING..."
            LootRemote:FireServer("Collect", {
                BagId = data.BagId,
                Items = {},
                TakeCoins = true,
            })
        end)
    end

    local items = type(data.Items) == "table" and data.Items or {}
    for index, item in ipairs(items) do
        local itemName = tostring(item.Name or "Material")
        local y = 10 + rowIndex * 52
        rowIndex += 1

        local row = Instance.new("TextButton")
        row.Name = "LootItem" .. tostring(index)
        row.Position = UDim2.fromOffset(15, y)
        row.Size = UDim2.fromOffset(400, 44)
        row.BackgroundColor3 = Color3.fromRGB(43, 48, 50)
        row.BorderSizePixel = 0
        row.AutoButtonColor = true
        row.Text = ""
        row.Parent = contents
        round(row, 7)

        local itemText = label(
            row,
            itemName .. "  ×" .. tostring(math.max(1, tonumber(item.Quantity) or 1)),
            UDim2.fromOffset(10, 0),
            UDim2.fromOffset(270, 44),
            12,
            Color3.fromRGB(220, 225, 210)
        )
        itemText.TextXAlignment = Enum.TextXAlignment.Left

        local takeText = label(
            row,
            "CLICK TO TAKE",
            UDim2.fromOffset(280, 0),
            UDim2.fromOffset(108, 44),
            9,
            Color3.fromRGB(133, 205, 146)
        )
        takeText.Font = Enum.Font.GothamBold
        takeText.TextXAlignment = Enum.TextXAlignment.Right

        row.Activated:Connect(function()
            row.Active = false
            row.AutoButtonColor = false
            takeText.Text = "TAKING..."
            LootRemote:FireServer("Collect", {
                BagId = data.BagId,
                Items = {itemName},
                TakeCoins = false,
            })
        end)
    end

    if coins <= 0 and #items == 0 then
        local none = label(
            contents,
            "This loot bag is empty.",
            UDim2.fromOffset(15, 56),
            UDim2.fromOffset(400, 30),
            12,
            Color3.fromRGB(157, 166, 168)
        )
        none.TextXAlignment = Enum.TextXAlignment.Center
    end

    statusLabel = label(
        panel,
        "Click only the loot you want to pick up. Anything untouched stays in the bag.",
        UDim2.fromOffset(20, 273),
        UDim2.fromOffset(430, 30),
        10,
        Color3.fromRGB(158, 169, 170)
    )
    statusLabel.TextWrapped = true
    statusLabel.TextXAlignment = Enum.TextXAlignment.Center
end

local toastToken = 0
local function toast(message, good)
    toastToken += 1
    local token = toastToken

    local notice = gui:FindFirstChild("LootNotice")
    if not notice then
        notice = label(
            gui,
            "",
            UDim2.new(.5, -235, 0, 92),
            UDim2.fromOffset(470, 36),
            12,
            Color3.fromRGB(239, 232, 213)
        )
        notice.Name = "LootNotice"
        notice.BackgroundColor3 = Color3.fromRGB(25, 29, 31)
        notice.BackgroundTransparency = .06
        notice.TextWrapped = true
        round(notice, 8)
        outline(notice, .5)
    end

    notice.TextColor3 = good and Color3.fromRGB(157, 231, 165) or Color3.fromRGB(240, 167, 157)
    notice.Text = tostring(message or "")
    notice.Visible = true

    task.delay(4, function()
        if token == toastToken and notice.Parent then
            notice.Visible = false
        end
    end)
end

local function configureBag(model)
    if not model:IsA("Model") then return end
    local owner = tonumber(model:GetAttribute("LootOwnerUserId"))
    local mine = owner == player.UserId

    for _, item in ipairs(model:GetDescendants()) do
        if item:IsA("BasePart") then
            item.LocalTransparencyModifier = mine and 0 or 1
        elseif item:IsA("ProximityPrompt") then
            item.Enabled = mine
        elseif item:IsA("BillboardGui") then
            item.Enabled = mine
        elseif item:IsA("PointLight") then
            item.Enabled = mine
        end
    end
end

for _, child in ipairs(lootFolder:GetChildren()) do
    configureBag(child)
end

lootFolder.ChildAdded:Connect(function(child)
    task.defer(function()
        configureBag(child)
    end)
end)

LootRemote.OnClientEvent:Connect(function(action, first, second)
    if action == "Open" then
        showLoot(first)
    elseif action == "CollectResult" then
        local success = first == true
        if success then
            local payload = second
            local itemCount = 0
            local itemName
            if type(payload) == "table" and type(payload.Items) == "table" then
                for _, item in ipairs(payload.Items) do
                    itemCount += math.max(1, tonumber(item.Quantity) or 1)
                    itemName = itemName or item.Name
                end
            end
            local coins = type(payload) == "table" and tonumber(payload.Coins) or 0
            local message
            if (coins or 0) > 0 then
                message = "Collected +" .. tostring(coins) .. " Coins"
            elseif itemCount > 0 then
                message = "Collected " .. tostring(itemName or "loot")
                    .. (itemCount > 1 and (" ×" .. tostring(itemCount)) or "")
            else
                message = "Loot updated."
            end
            toast(message, true)

            if type(payload) == "table" and type(payload.Remaining) == "table" then
                showLoot(payload.Remaining)
            else
                closePanel()
            end
        else
            if statusLabel and statusLabel.Parent then
                statusLabel.Text = tostring(second or "Could not collect this loot.")
                statusLabel.TextColor3 = Color3.fromRGB(240, 167, 157)
            end
            toast(second or "Could not collect this loot.", false)
        end
    elseif action == "Error" then
        toast(first or "That loot is unavailable.", false)
    end
end)
