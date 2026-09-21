local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local Root = ReplicatedStorage:WaitForChild("WildernessPets")
local Remotes = Root:WaitForChild("Remotes")
local Remote = Remotes:WaitForChild("Auction")
local Query = Remotes:WaitForChild("AuctionQuery")
local GetState = Remotes:WaitForChild("GetState")

local gui = Instance.new("ScreenGui")
gui.Name = "AuctionHouseUI"
gui.ResetOnSpawn = false
gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
gui.DisplayOrder = 129
gui.Parent = player:WaitForChild("PlayerGui")

local colors = {
    bg = Color3.fromRGB(27, 31, 36),
    panel = Color3.fromRGB(40, 46, 53),
    panel2 = Color3.fromRGB(51, 59, 67),
    gold = Color3.fromRGB(225, 188, 104),
    text = Color3.fromRGB(240, 238, 226),
    muted = Color3.fromRGB(177, 183, 184),
    green = Color3.fromRGB(100, 188, 118),
    red = Color3.fromRGB(161, 83, 75),
}

local panel
local modalPanels = {
    ProgressionUI = "ProgressionPanel",
    VillageProgressionUI = "VillagePanel",
    AuctionHouseUI = "AuctionPanel",
}

local function activeCustomModal()
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then return false end
    for guiName, panelName in pairs(modalPanels) do
        local screen = playerGui:FindFirstChild(guiName)
        local frame = screen and screen:FindFirstChild(panelName)
        if frame and frame.Parent then return true end
    end
    return false
end

local function beginModal()
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then return false end
    local main = playerGui:FindFirstChild("WildernessPetsUI")
    if main and main:GetAttribute("InventoryOpen") == true and not activeCustomModal() then
        return false
    end
    for guiName, panelName in pairs(modalPanels) do
        if guiName ~= gui.Name then
            local screen = playerGui:FindFirstChild(guiName)
            local other = screen and screen:FindFirstChild(panelName)
            if other then other:Destroy() end
        end
    end
    if main then main:SetAttribute("InventoryOpen", true) end
    return true
end

local function endModal()
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui or activeCustomModal() then return end
    local main = playerGui:FindFirstChild("WildernessPetsUI")
    if main then main:SetAttribute("InventoryOpen", false) end
end

local snapshot
local tab = "Browse"

local function round(obj, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = obj
end

local function stroke(obj)
    local s = Instance.new("UIStroke")
    s.Color = Color3.fromRGB(112, 96, 67)
    s.Transparency = 0.38
    s.Parent = obj
end

local function label(parent, textValue, pos, size, textSize)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Position = pos
    l.Size = size
    l.Text = textValue
    l.TextColor3 = colors.text
    l.Font = Enum.Font.Gotham
    l.TextSize = textSize or 13
    l.TextWrapped = true
    l.Parent = parent
    return l
end

local function button(parent, textValue, pos, size)
    local b = Instance.new("TextButton")
    b.Position = pos
    b.Size = size
    b.BackgroundColor3 = colors.panel2
    b.BorderSizePixel = 0
    b.Text = textValue
    b.TextColor3 = colors.text
    b.Font = Enum.Font.GothamBold
    b.TextSize = 12
    b.Parent = parent
    round(b, 7)
    stroke(b)
    return b
end

local function input(parent, textValue, pos, size)
    local box = Instance.new("TextBox")
    box.Position = pos
    box.Size = size
    box.BackgroundColor3 = Color3.fromRGB(32, 37, 43)
    box.BorderSizePixel = 0
    box.Text = textValue
    box.PlaceholderColor3 = colors.muted
    box.TextColor3 = colors.text
    box.Font = Enum.Font.Gotham
    box.TextSize = 12
    box.ClearTextOnFocus = false
    box.Parent = parent
    round(box, 6)
    stroke(box)
    return box
end

local function scrolling(parent, pos, size)
    local f = Instance.new("ScrollingFrame")
    f.Position = pos
    f.Size = size
    f.BackgroundTransparency = 1
    f.BorderSizePixel = 0
    f.ScrollBarThickness = 5
    f.AutomaticCanvasSize = Enum.AutomaticSize.Y
    f.CanvasSize = UDim2.new()
    f.Parent = parent
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 7)
    layout.Parent = f
    return f
end

local function close()
    local wasOpen = panel ~= nil and panel.Parent ~= nil
    if panel then panel:Destroy(); panel = nil end
    if wasOpen then endModal() end
end

local render

local function buildBase()
    close()
    if not beginModal() then return false end
    panel = Instance.new("Frame")
    panel.Name = "AuctionPanel"
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.Position = UDim2.fromScale(0.5, 0.5)
    panel.Size = UDim2.fromOffset(820, 570)
    panel.BackgroundColor3 = colors.bg
    panel.BorderSizePixel = 0
    panel.Parent = gui
    round(panel, 12)
    stroke(panel)

    local scale = Instance.new("UIScale")
    local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280,720)
    scale.Scale = math.min(1, (vp.X - 24) / 820, (vp.Y - 40) / 570)
    scale.Parent = panel

    local title = label(panel, "GLOBAL AUCTION HOUSE", UDim2.fromOffset(22, 14), UDim2.fromOffset(640, 34), 22)
    title.TextColor3 = colors.gold
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    local fee = math.floor(((snapshot and snapshot.FeeRate) or 0.01) * 100 + 0.5)
    local subtitle = label(panel, "Listings are shared across all live servers. Seller fee: " .. tostring(fee) .. "%.", UDim2.fromOffset(24, 47), UDim2.fromOffset(630, 22), 11)
    subtitle.TextColor3 = colors.muted
    subtitle.TextXAlignment = Enum.TextXAlignment.Left

    local x = button(panel, "×", UDim2.fromOffset(764, 12), UDim2.fromOffset(38, 34))
    x.TextSize = 22
    x.Activated:Connect(close)

    for i, name in ipairs({"Browse", "Sell", "My Listings", "Mail"}) do
        local b = button(panel, string.upper(name), UDim2.fromOffset(22 + (i-1)*156, 78), UDim2.fromOffset(146, 38))
        b.BackgroundColor3 = tab == name and Color3.fromRGB(91, 77, 51) or colors.panel2
        b.Activated:Connect(function()
            tab = name
            local ok, state = pcall(function() return Query:InvokeServer() end)
            if ok and type(state) == "table" then snapshot = state end
            render()
        end)
    end
    local refresh = button(panel, "REFRESH", UDim2.new(1, -126, 0, 78), UDim2.fromOffset(104, 38))
    refresh.Activated:Connect(function()
        local ok, state = pcall(function() return Query:InvokeServer() end)
        if ok and type(state) == "table" then snapshot = state; render() end
    end)
    return true
end

local function emptyMessage(parent, message)
    local l = label(parent, message, UDim2.fromOffset(30, 150), UDim2.new(1, -60, 0, 80), 14)
    l.TextColor3 = colors.muted
end

local function renderBrowse()
    local list = scrolling(panel, UDim2.fromOffset(22, 132), UDim2.fromOffset(776, 414))
    local rows = snapshot and snapshot.Browse or {}
    if #rows == 0 then emptyMessage(list, "No active listings right now.") return end
    for _, listing in ipairs(rows) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -8, 0, 68)
        row.BackgroundColor3 = colors.panel
        row.BorderSizePixel = 0
        row.Parent = list
        round(row, 7)
        local title = label(row, tostring(listing.ItemName) .. "  ×" .. tostring(listing.Quantity), UDim2.fromOffset(14, 8), UDim2.fromOffset(400, 24), 14)
        title.Font = Enum.Font.GothamBold
        title.TextXAlignment = Enum.TextXAlignment.Left
        local seller = label(row, "Seller: " .. tostring(listing.SellerName or "Unknown"), UDim2.fromOffset(14, 34), UDim2.fromOffset(360, 20), 10)
        seller.TextColor3 = colors.muted
        seller.TextXAlignment = Enum.TextXAlignment.Left
        local price = label(row, tostring(listing.Price) .. " COINS", UDim2.new(1, -300, 0, 18), UDim2.fromOffset(155, 28), 13)
        price.TextColor3 = colors.gold
        price.Font = Enum.Font.GothamBold
        local buy = button(row, "BUY", UDim2.new(1, -125, 0, 17), UDim2.fromOffset(108, 34))
        if tonumber(listing.SellerUserId) == player.UserId then
            buy.Text = "YOUR LISTING"
            buy.Active = false
            buy.BackgroundTransparency = 0.45
        else
            buy.Activated:Connect(function() Remote:FireServer("Buy", listing.Id) end)
        end
    end
end

local function tradeableInventory()
    local ok, state = pcall(function() return GetState:InvokeServer() end)
    if not ok or type(state) ~= "table" then return {} end
    local list = {}
    for _, item in ipairs(state.Inventory or {}) do
        if type(item) == "table" and (item.Type == "Loot" or item.Type == "BossPetToken" or item.Type == "BossMountToken") then
            table.insert(list, item)
        end
    end
    return list
end

local function renderSell()
    local info = label(panel, "Choose tradeable loot, set quantity and total sale price. Items leave your inventory when listed.", UDim2.fromOffset(24, 130), UDim2.fromOffset(740, 30), 12)
    info.TextColor3 = colors.muted
    info.TextXAlignment = Enum.TextXAlignment.Left
    local list = scrolling(panel, UDim2.fromOffset(22, 168), UDim2.fromOffset(776, 378))
    local items = tradeableInventory()
    if #items == 0 then emptyMessage(list, "You have no tradeable loot to list.") return end
    for _, item in ipairs(items) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -8, 0, 70)
        row.BackgroundColor3 = colors.panel
        row.BorderSizePixel = 0
        row.Parent = list
        round(row, 7)
        local title = label(row, tostring(item.Name) .. "  ·  Owned: " .. tostring(item.Quantity or 1), UDim2.fromOffset(14, 10), UDim2.fromOffset(310, 24), 13)
        title.Font = Enum.Font.GothamBold
        title.TextXAlignment = Enum.TextXAlignment.Left
        local qty = input(row, "1", UDim2.fromOffset(330, 18), UDim2.fromOffset(72, 34))
        qty.PlaceholderText = "Qty"
        local price = input(row, "100", UDim2.fromOffset(414, 18), UDim2.fromOffset(135, 34))
        price.PlaceholderText = "Price"
        local sell = button(row, "LIST", UDim2.new(1, -125, 0, 18), UDim2.fromOffset(108, 34))
        sell.Activated:Connect(function()
            Remote:FireServer("List", item.Type, item.Name, tonumber(qty.Text), tonumber(price.Text))
        end)
    end
end

local function renderMine()
    local list = scrolling(panel, UDim2.fromOffset(22, 132), UDim2.fromOffset(776, 414))
    local rows = snapshot and snapshot.MyListings or {}
    if #rows == 0 then emptyMessage(list, "You have no active auction listings.") return end
    for _, listing in ipairs(rows) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -8, 0, 62)
        row.BackgroundColor3 = colors.panel
        row.BorderSizePixel = 0
        row.Parent = list
        round(row, 7)
        local title = label(row, tostring(listing.ItemName) .. " ×" .. tostring(listing.Quantity) .. "  ·  " .. tostring(listing.Price) .. " Coins", UDim2.fromOffset(14, 10), UDim2.fromOffset(500, 38), 13)
        title.Font = Enum.Font.GothamBold
        title.TextXAlignment = Enum.TextXAlignment.Left
        local cancel = button(row, "CANCEL", UDim2.new(1, -125, 0, 14), UDim2.fromOffset(108, 34))
        cancel.BackgroundColor3 = colors.red
        cancel.Activated:Connect(function() Remote:FireServer("Cancel", listing.Id) end)
    end
end

local function renderMail()
    local info = label(panel, "Sales, purchases and expired/cancelled listings are delivered here—even if the seller was offline.", UDim2.fromOffset(24, 130), UDim2.fromOffset(740, 30), 12)
    info.TextColor3 = colors.muted
    info.TextXAlignment = Enum.TextXAlignment.Left
    local list = scrolling(panel, UDim2.fromOffset(22, 168), UDim2.fromOffset(776, 378))
    local rows = snapshot and snapshot.Mail or {}
    if #rows == 0 then emptyMessage(list, "Your auction mailbox is empty.") return end
    for _, entry in ipairs(rows) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -8, 0, 64)
        row.BackgroundColor3 = colors.panel
        row.BorderSizePixel = 0
        row.Parent = list
        round(row, 7)
        local reward = entry.Kind == "Coins"
            and (tostring(entry.Coins or 0) .. " Coins")
            or (tostring(entry.ItemName or "Item") .. " ×" .. tostring(entry.Quantity or 1))
        local title = label(row, reward, UDim2.fromOffset(14, 7), UDim2.fromOffset(430, 24), 13)
        title.Font = Enum.Font.GothamBold
        title.TextXAlignment = Enum.TextXAlignment.Left
        local subject = label(row, tostring(entry.Subject or "Auction mail"), UDim2.fromOffset(14, 31), UDim2.fromOffset(500, 20), 10)
        subject.TextColor3 = colors.muted
        subject.TextXAlignment = Enum.TextXAlignment.Left
        local claim = button(row, "CLAIM", UDim2.new(1, -125, 0, 15), UDim2.fromOffset(108, 34))
        claim.BackgroundColor3 = colors.green
        claim.Activated:Connect(function() Remote:FireServer("Claim", entry.Id) end)
    end
end

render = function()
    if not snapshot then return end
    if not buildBase() then return end
    if tab == "Sell" then renderSell()
    elseif tab == "My Listings" then renderMine()
    elseif tab == "Mail" then renderMail()
    else renderBrowse() end
end

local function toast(message, ok)
    local t = label(gui, tostring(message or ""), UDim2.new(0.5, -250, 0, 112), UDim2.fromOffset(500, 40), 12)
    t.Name = "AuctionToast"
    t.BackgroundTransparency = 0.05
    t.BackgroundColor3 = ok and Color3.fromRGB(48, 77, 56) or Color3.fromRGB(92, 49, 47)
    t.Font = Enum.Font.GothamBold
    round(t, 7)
    task.delay(4, function() if t.Parent then t:Destroy() end end)
end

Remote.OnClientEvent:Connect(function(action, a, b, c)
    if action == "Open" then
        snapshot = a
        tab = "Browse"
        render()
    elseif action == "Result" then
        local ok, message, state = a, b, c
        if type(state) == "table" then snapshot = state end
        if panel then render() end
        toast(message, ok)
    elseif action == "MailCount" then
        -- The physical mailbox is the deliberate entry point; no permanent HUD badge needed yet.
    end
end)
