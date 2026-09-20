local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Root = ReplicatedStorage:WaitForChild("WildernessPets")
local Remotes = Root:WaitForChild("Remotes")
local TradeRemote = Remotes:WaitForChild("Trade")
local GetState = Remotes:WaitForChild("GetState")

local gui = Instance.new("ScreenGui")
gui.Name = "PlayerTradeUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 120
gui.Parent = playerGui

local activePanel
local currentSessionId
local currentPartnerName = ""
local selected = {}
local latestUpdate

local function round(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = parent
end

local function stroke(parent, color)
    local s = Instance.new("UIStroke")
    s.Color = color or Color3.fromRGB(110, 126, 148)
    s.Transparency = .35
    s.Thickness = 1
    s.Parent = parent
end

local function makeText(parent, value, position, size, textSize)
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Position = position or UDim2.new()
    label.Size = size or UDim2.fromOffset(200, 24)
    label.Font = Enum.Font.GothamMedium
    label.TextSize = textSize or 12
    label.TextColor3 = Color3.fromRGB(232, 235, 239)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextWrapped = true
    label.Text = tostring(value or "")
    label.Parent = parent
    return label
end

local function makeButton(parent, value, position, size)
    local button = Instance.new("TextButton")
    button.Position = position or UDim2.new()
    button.Size = size or UDim2.fromOffset(120, 36)
    button.BackgroundColor3 = Color3.fromRGB(48, 56, 67)
    button.BorderSizePixel = 0
    button.Font = Enum.Font.GothamBold
    button.TextSize = 11
    button.TextColor3 = Color3.fromRGB(240, 241, 244)
    button.Text = tostring(value or "")
    button.Parent = parent
    round(button, 7)
    return button
end

local function toast(message, good)
    local old = gui:FindFirstChild("TradeToast")
    if old then old:Destroy() end

    local label = makeText(
        gui,
        message,
        UDim2.new(.5, -260, 0, 92),
        UDim2.fromOffset(520, 48),
        12
    )
    label.Name = "TradeToast"
    label.BackgroundTransparency = .08
    label.BackgroundColor3 = Color3.fromRGB(24, 27, 32)
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextColor3 = good == false
        and Color3.fromRGB(240, 164, 154)
        or Color3.fromRGB(175, 228, 181)
    round(label, 8)
    stroke(label)

    task.delay(4, function()
        if label.Parent then label:Destroy() end
    end)
end

local function closePanel()
    if activePanel then
        activePanel:Destroy()
        activePanel = nil
    end
end

local openBrowser
local renderSession

local launcher = makeButton(
    gui,
    "TRADE  [T]",
    UDim2.new(1, -132, 0, 76),
    UDim2.fromOffset(112, 34)
)
launcher.Name = "TradeLauncher"
launcher.BackgroundColor3 = Color3.fromRGB(64, 78, 96)
stroke(launcher)

local function distanceTo(other)
    local a = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    local b = other.Character and other.Character:FindFirstChild("HumanoidRootPart")
    if not a or not b then return math.huge end
    return (a.Position - b.Position).Magnitude
end

openBrowser = function()
    if currentSessionId then
        if latestUpdate then renderSession(latestUpdate) end
        return
    end

    closePanel()

    local panel = Instance.new("Frame")
    panel.Name = "TradeBrowser"
    panel.AnchorPoint = Vector2.new(.5, .5)
    panel.Position = UDim2.fromScale(.5, .5)
    panel.Size = UDim2.fromOffset(520, 440)
    panel.BackgroundColor3 = Color3.fromRGB(25, 29, 35)
    panel.BorderSizePixel = 0
    panel.Parent = gui
    round(panel, 11)
    stroke(panel)
    activePanel = panel

    local title = makeText(panel, "PLAYER TRADING", UDim2.fromOffset(18, 14), UDim2.fromOffset(360, 28), 20)
    title.Font = Enum.Font.GothamBold

    local hint = makeText(
        panel,
        "Choose a nearby player. Trades are server-validated and both players must confirm the final offers.",
        UDim2.fromOffset(18, 48),
        UDim2.fromOffset(430, 44),
        11
    )
    hint.TextColor3 = Color3.fromRGB(179, 187, 197)

    local close = makeButton(panel, "×", UDim2.fromOffset(466, 12), UDim2.fromOffset(36, 32))
    close.TextSize = 19
    close.Activated:Connect(closePanel)

    local list = Instance.new("ScrollingFrame")
    list.Position = UDim2.fromOffset(18, 102)
    list.Size = UDim2.fromOffset(484, 318)
    list.BackgroundTransparency = 1
    list.BorderSizePixel = 0
    list.ScrollBarThickness = 5
    list.AutomaticCanvasSize = Enum.AutomaticSize.Y
    list.CanvasSize = UDim2.new()
    list.Parent = panel

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.Parent = list

    local found = 0
    for _, other in ipairs(Players:GetPlayers()) do
        if other ~= player and distanceTo(other) <= 35 then
            found += 1

            local row = Instance.new("Frame")
            row.Size = UDim2.fromOffset(470, 58)
            row.BackgroundColor3 = Color3.fromRGB(37, 43, 51)
            row.BorderSizePixel = 0
            row.Parent = list
            round(row, 8)

            local name = makeText(
                row,
                other.DisplayName .. "  (@" .. other.Name .. ")",
                UDim2.fromOffset(12, 8),
                UDim2.fromOffset(300, 20),
                13
            )
            name.Font = Enum.Font.GothamBold

            local distance = makeText(
                row,
                tostring(math.floor(distanceTo(other) + .5)) .. " studs away",
                UDim2.fromOffset(12, 31),
                UDim2.fromOffset(230, 18),
                10
            )
            distance.TextColor3 = Color3.fromRGB(174, 182, 191)

            local request = makeButton(row, "REQUEST", UDim2.fromOffset(352, 11), UDim2.fromOffset(104, 36))
            request.Activated:Connect(function()
                request.Active = false
                request.Text = "SENT"
                TradeRemote:FireServer("Request", other.UserId)
            end)
        end
    end

    if found == 0 then
        local empty = makeText(
            list,
            "No players are within 35 studs.
Move closer to another handler to trade.",
            UDim2.new(),
            UDim2.fromOffset(450, 72),
            14
        )
        empty.TextXAlignment = Enum.TextXAlignment.Center
        empty.TextColor3 = Color3.fromRGB(184, 190, 198)
    end
end

local function offerKey(asset)
    if asset.Kind == "Pet" or asset.Kind == "Mount" then
        return asset.Kind .. ":" .. tostring(asset.Id or "")
    end
    return "Inventory:" .. tostring(asset.Type or "") .. ":" .. tostring(asset.Name or "")
end

local function selectedOffer()
    local offer = {}
    for _, asset in pairs(selected) do
        table.insert(offer, asset)
    end
    table.sort(offer, function(a, b)
        return offerKey(a) < offerKey(b)
    end)
    return offer
end

local function assetDescription(asset)
    if asset.Kind == "Pet" then
        return "PET  ·  " .. tostring(asset.DisplayName or asset.Name or asset.Species)
            .. "  ·  " .. tostring(asset.Rarity or "")
    elseif asset.Kind == "Mount" then
        return "MOUNT  ·  " .. tostring(asset.DisplayName or asset.Name or asset.Species)
            .. "  ·  " .. tostring(asset.Rarity or "")
    elseif asset.Kind == "Equipment" then
        local stats = {}
        if type(asset.MainStat) == "table" then
            table.insert(
                stats,
                tostring(asset.MainStat.Name or "Stat")
                    .. " "
                    .. tostring(math.floor((tonumber(asset.MainStat.Value) or 0) * 1000 + 0.5) / 10)
                    .. "%"
            )
        end
        for _, sub in ipairs(asset.Substats or {}) do
            if type(sub) == "table" then
                table.insert(
                    stats,
                    tostring(sub.Name or "Stat")
                        .. " "
                        .. tostring(math.floor((tonumber(sub.Value) or 0) * 1000 + 0.5) / 10)
                        .. "%"
                )
            end
        end

        return "EQUIPMENT  ·  "
            .. tostring(asset.DisplayName or asset.Name or "Gear")
            .. "  ·  "
            .. tostring(asset.Rarity or "")
            .. " "
            .. tostring(asset.Quality or "")
            .. " Lv."
            .. tostring(asset.ItemLevel or 1)
            .. ((tonumber(asset.WorldforgeLevel) or 0) > 0
                and (" +" .. tostring(asset.WorldforgeLevel))
                or "")
            .. (#stats > 0 and ("  ·  " .. table.concat(stats, " / ")) or "")
    end

    return tostring(asset.Name or "Item")
        .. "  ·  x"
        .. tostring(asset.Quantity or 1)
end

local function buildTradeableAssets(state)
    local assets = {}

    for _, pet in ipairs(state.Pets or {}) do
        local blocked = pet.Favourite
            or pet.Dead
            or pet.Displayed
            or state.EquippedPetId == pet.Id
            or state.PodiumPetId == pet.Id
            or state.DefencePetId == pet.Id
            or pet.Tradeable == false

        if not blocked then
            table.insert(assets, {
                Kind = "Pet",
                Id = pet.Id,
                Name = pet.Name or pet.Species,
                DisplayName = pet.Name or pet.Species,
                Species = pet.Species,
                Rarity = pet.Rarity,
                Quantity = 1,
            })
        end
    end

    for _, mount in ipairs(state.Mounts or {}) do
        local blocked = mount.Favourite
            or state.EquippedMountId == mount.Id
            or mount.Tradeable == false

        if not blocked then
            table.insert(assets, {
                Kind = "Mount",
                Id = mount.Id,
                Name = mount.Name or mount.Species,
                DisplayName = mount.Name or mount.Species,
                Species = mount.Species,
                Rarity = mount.Rarity,
                Quantity = 1,
            })
        end
    end

    for _, item in ipairs(state.Equipment or {}) do
        if type(item) == "table"
            and item.Favourite ~= true
            and item.Tradeable ~= false then
            table.insert(assets, {
                Kind = "Equipment",
                Id = item.Id,
                Name = item.Name,
                DisplayName = item.Name,
                Rarity = item.Tier,
                Quality = item.Quality,
                Slot = item.Slot,
                ItemLevel = item.ItemLevel,
                WorldforgeLevel = item.WorldforgeLevel,
                BossUnique = item.BossUnique == true,
                MainStat = item.MainStat,
                Substats = item.Substats,
                Quantity = 1,
            })
        end
    end

    for _, item in ipairs(state.Inventory or {}) do
        if type(item) == "table"
            and (
                item.Type == "Loot"
                or item.Type == "BossPetToken"
                or item.Type == "BossMountToken"
            ) then
            table.insert(assets, {
                Kind = "Inventory",
                Type = item.Type,
                Name = item.Name,
                DisplayName = item.Name,
                Quantity = math.max(1, math.floor(tonumber(item.Quantity) or 1)),
            })
        end
    end

    table.sort(assets, function(a, b)
        local ak = tostring(a.Kind) .. tostring(a.Rarity or "") .. tostring(a.Name or "")
        local bk = tostring(b.Kind) .. tostring(b.Rarity or "") .. tostring(b.Name or "")
        return ak < bk
    end)

    return assets
end

renderSession = function(update)
    if type(update) ~= "table" then return end
    if not currentSessionId or update.SessionId ~= currentSessionId then return end

    latestUpdate = update
    closePanel()

    local state = GetState:InvokeServer()
    if not state then
        toast("Could not load your collection for trading.", false)
        TradeRemote:FireServer("Cancel")
        return
    end

    local panel = Instance.new("Frame")
    panel.Name = "ActiveTrade"
    panel.AnchorPoint = Vector2.new(.5, .5)
    panel.Position = UDim2.fromScale(.5, .5)
    panel.Size = UDim2.fromOffset(900, 590)
    panel.BackgroundColor3 = Color3.fromRGB(23, 27, 33)
    panel.BorderSizePixel = 0
    panel.Parent = gui
    round(panel, 12)
    stroke(panel)
    activePanel = panel

    local title = makeText(
        panel,
        "TRADE WITH " .. tostring(update.PartnerName or currentPartnerName),
        UDim2.fromOffset(18, 12),
        UDim2.fromOffset(610, 30),
        19
    )
    title.Font = Enum.Font.GothamBold

    local safety = makeText(
        panel,
        "Changing either offer removes both confirmations. Favourite pets, mounts and equipment cannot be traded.",
        UDim2.fromOffset(18, 44),
        UDim2.fromOffset(710, 30),
        10
    )
    safety.TextColor3 = Color3.fromRGB(179, 187, 197)

    local cancel = makeButton(panel, "CANCEL", UDim2.fromOffset(780, 14), UDim2.fromOffset(102, 34))
    cancel.BackgroundColor3 = Color3.fromRGB(88, 47, 49)
    cancel.Activated:Connect(function()
        TradeRemote:FireServer("Cancel")
    end)

    local availableTitle = makeText(panel, "YOUR TRADEABLE ASSETS", UDim2.fromOffset(18, 82), UDim2.fromOffset(410, 24), 12)
    availableTitle.Font = Enum.Font.GothamBold

    local available = Instance.new("ScrollingFrame")
    available.Position = UDim2.fromOffset(18, 112)
    available.Size = UDim2.fromOffset(430, 402)
    available.BackgroundColor3 = Color3.fromRGB(30, 35, 42)
    available.BackgroundTransparency = .2
    available.BorderSizePixel = 0
    available.ScrollBarThickness = 5
    available.AutomaticCanvasSize = Enum.AutomaticSize.Y
    available.CanvasSize = UDim2.new()
    available.Parent = panel
    round(available, 8)

    local availableLayout = Instance.new("UIListLayout")
    availableLayout.Padding = UDim.new(0, 6)
    availableLayout.Parent = available

    local assets = buildTradeableAssets(state)
    for _, asset in ipairs(assets) do
        local key = offerKey(asset)
        local chosen = selected[key] ~= nil

        local row = makeButton(
            available,
            (chosen and "✓  " or "   ") .. assetDescription(asset),
            UDim2.new(),
            UDim2.fromOffset(414, asset.Kind == "Equipment" and 58 or 42)
        )
        row.TextXAlignment = Enum.TextXAlignment.Left
        row.TextWrapped = true
        row.TextSize = asset.Kind == "Equipment" and 8 or 10
        row.BackgroundColor3 = chosen
            and Color3.fromRGB(60, 91, 73)
            or Color3.fromRGB(43, 50, 59)

        row.Activated:Connect(function()
            if selected[key] then
                selected[key] = nil
            else
                local count = 0
                for _ in pairs(selected) do count += 1 end
                if count >= 8 then
                    toast("A trade can contain at most 8 offered entries.", false)
                    return
                end
                selected[key] = asset
            end

            TradeRemote:FireServer("SetOffer", currentSessionId, selectedOffer())
        end)
    end

    if #assets == 0 then
        local empty = makeText(
            available,
            "Nothing currently tradeable.
Unequip/unfavourite creatures or equipment, or collect tradeable materials.",
            UDim2.new(),
            UDim2.fromOffset(410, 70),
            12
        )
        empty.TextXAlignment = Enum.TextXAlignment.Center
    end

    local function offerBox(titleText, offer, y, confirmed)
        local titleLabel = makeText(
            panel,
            titleText .. (confirmed and "  ✓ CONFIRMED" or ""),
            UDim2.fromOffset(470, y),
            UDim2.fromOffset(405, 24),
            12
        )
        titleLabel.Font = Enum.Font.GothamBold
        titleLabel.TextColor3 = confirmed
            and Color3.fromRGB(153, 226, 166)
            or Color3.fromRGB(230, 231, 234)

        local box = Instance.new("Frame")
        box.Position = UDim2.fromOffset(470, y + 29)
        box.Size = UDim2.fromOffset(412, 166)
        box.BackgroundColor3 = Color3.fromRGB(31, 36, 43)
        box.BorderSizePixel = 0
        box.Parent = panel
        round(box, 8)

        local list = Instance.new("ScrollingFrame")
        list.Position = UDim2.fromOffset(8, 8)
        list.Size = UDim2.fromOffset(396, 150)
        list.BackgroundTransparency = 1
        list.BorderSizePixel = 0
        list.ScrollBarThickness = 4
        list.AutomaticCanvasSize = Enum.AutomaticSize.Y
        list.CanvasSize = UDim2.new()
        list.Parent = box

        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 4)
        layout.Parent = list

        if #(offer or {}) == 0 then
            local empty = makeText(list, "Nothing offered", UDim2.new(), UDim2.fromOffset(380, 26), 11)
            empty.TextColor3 = Color3.fromRGB(149, 156, 166)
        else
            for _, asset in ipairs(offer or {}) do
                local row = makeText(
                    list,
                    "• " .. assetDescription(asset),
                    UDim2.new(),
                    UDim2.fromOffset(376, 24),
                    10
                )
                row.TextColor3 = Color3.fromRGB(211, 216, 222)
            end
        end
    end

    offerBox("YOUR OFFER", update.YourOffer, 82, update.YourConfirmed)
    offerBox(tostring(update.PartnerName or currentPartnerName) .. "'S OFFER", update.PartnerOffer, 292, update.PartnerConfirmed)

    local confirm = makeButton(
        panel,
        update.YourConfirmed and "CONFIRMED — WAITING" or "CONFIRM FINAL TRADE",
        UDim2.fromOffset(590, 535),
        UDim2.fromOffset(292, 40)
    )
    confirm.BackgroundColor3 = update.YourConfirmed
        and Color3.fromRGB(55, 75, 61)
        or Color3.fromRGB(73, 104, 76)
    confirm.Active = not update.YourConfirmed
    confirm.Activated:Connect(function()
        confirm.Active = false
        confirm.Text = "CONFIRMING..."
        TradeRemote:FireServer("Confirm", currentSessionId)
    end)
end

local function showRequest(data)
    if type(data) ~= "table" then return end

    local request = Instance.new("Frame")
    request.Name = "IncomingTradeRequest"
    request.AnchorPoint = Vector2.new(.5, 0)
    request.Position = UDim2.new(.5, 0, 0, 145)
    request.Size = UDim2.fromOffset(460, 120)
    request.BackgroundColor3 = Color3.fromRGB(29, 34, 41)
    request.BorderSizePixel = 0
    request.Parent = gui
    round(request, 10)
    stroke(request)

    local title = makeText(
        request,
        tostring(data.FromName or "A player") .. " wants to trade.",
        UDim2.fromOffset(16, 12),
        UDim2.fromOffset(420, 28),
        15
    )
    title.Font = Enum.Font.GothamBold

    local note = makeText(
        request,
        "You must remain within 35 studs.",
        UDim2.fromOffset(16, 43),
        UDim2.fromOffset(400, 20),
        10
    )
    note.TextColor3 = Color3.fromRGB(174, 181, 191)

    local accept = makeButton(request, "ACCEPT", UDim2.fromOffset(120, 76), UDim2.fromOffset(100, 32))
    accept.BackgroundColor3 = Color3.fromRGB(61, 101, 73)

    local decline = makeButton(request, "DECLINE", UDim2.fromOffset(240, 76), UDim2.fromOffset(100, 32))
    decline.BackgroundColor3 = Color3.fromRGB(97, 55, 57)

    accept.Activated:Connect(function()
        if request.Parent then request:Destroy() end
        TradeRemote:FireServer("Respond", data.RequestId, true)
    end)

    decline.Activated:Connect(function()
        if request.Parent then request:Destroy() end
        TradeRemote:FireServer("Respond", data.RequestId, false)
    end)

    task.delay(20, function()
        if request.Parent then request:Destroy() end
    end)
end

launcher.Activated:Connect(openBrowser)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.T then
        openBrowser()
    end
end)

TradeRemote.OnClientEvent:Connect(function(action, first, second)
    if action == "Request" then
        showRequest(first)

    elseif action == "Open" then
        local data = type(first) == "table" and first or {}
        currentSessionId = data.SessionId
        currentPartnerName = tostring(data.PartnerName or "Player")
        selected = {}
        latestUpdate = nil
        toast("Trade opened with " .. currentPartnerName .. ".", true)

    elseif action == "Update" then
        if type(first) == "table" then
            currentSessionId = first.SessionId
            currentPartnerName = tostring(first.PartnerName or currentPartnerName)
            latestUpdate = first

            -- The authoritative server offer may reject stale local selections.
            selected = {}
            for _, asset in ipairs(first.YourOffer or {}) do
                selected[offerKey(asset)] = asset
            end

            renderSession(first)
        end

    elseif action == "Result" then
        currentSessionId = nil
        currentPartnerName = ""
        latestUpdate = nil
        selected = {}
        closePanel()
        toast(second or "Trade completed.", true)

    elseif action == "Closed" then
        currentSessionId = nil
        currentPartnerName = ""
        latestUpdate = nil
        selected = {}
        closePanel()
        toast(second or "Trade closed.", false)

    elseif action == "Notice" then
        toast(first or "Trade update.", second ~= false)

    elseif action == "RequestExpired" then
        local request = gui:FindFirstChild("IncomingTradeRequest")
        if request then request:Destroy() end
    end
end)
