local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local Root = ReplicatedStorage:WaitForChild("WildernessPets")
local Config = require(Root.Shared.AuctionConfig)
local DataService = require(script.Parent.PlayerDataService)
local ShopService = require(script.Parent.ShopService)

local Service = {}
local started = false
local sessions = setmetatable({}, {__mode = "k"})
local browseCache = {At = 0, Rows = {}}

local useStores = not RunService:IsStudio()
local ListingStore = useStores and DataStoreService:GetDataStore("WildernessPets_AuctionListings_V1") or nil
local IndexStore = useStores and DataStoreService:GetOrderedDataStore("WildernessPets_AuctionIndex_V1") or nil
local MailStore = useStores and DataStoreService:GetDataStore("WildernessPets_AuctionMailbox_V1") or nil
local studioListings = {}
local studioMail = {}

local function ensureRemote(name, className)
    local remotes = Root:WaitForChild("Remotes")
    local remote = remotes:FindFirstChild(name)
    if not remote then
        remote = Instance.new(className)
        remote.Name = name
        remote.Parent = remotes
    end
    return remote
end

local Remote = ensureRemote("Auction", "RemoteEvent")
local Query = ensureRemote("AuctionQuery", "RemoteFunction")

local function ensurePlayerData(data)
    if not data then return nil end
    data.AuctionListings = type(data.AuctionListings) == "table" and data.AuctionListings or {}
    data.AuctionStats = type(data.AuctionStats) == "table" and data.AuctionStats or {
        Listed = 0,
        Sold = 0,
        Bought = 0,
        FeesPaid = 0,
    }
    data.AuctionMailClaims = type(data.AuctionMailClaims) == "table" and data.AuctionMailClaims or {}
    return data
end

local function getPlots()
    local world = workspace:FindFirstChild("WildernessPets")
    return world and world:FindFirstChild("Plots")
end

local function getOwnedPlot(player)
    local plots = getPlots()
    if not plots then return nil end
    for _, plot in ipairs(plots:GetChildren()) do
        local owner = tonumber(plot:GetAttribute("OwnerUserId") or plot:GetAttribute("Owner"))
        if owner == player.UserId then return plot end
    end
    return nil
end

local function mailKey(userId)
    return "User_" .. tostring(userId)
end

local function listingKey(id)
    return "Listing_" .. tostring(id)
end

local function normalizeMail(box)
    box = type(box) == "table" and box or {}
    box.Entries = type(box.Entries) == "table" and box.Entries or {}
    return box
end

local function queueMail(userId, entry)
    if type(entry) ~= "table" or not entry.Id then return false end
    entry.CreatedAt = tonumber(entry.CreatedAt) or os.time()
    if not useStores then
        local box = normalizeMail(studioMail[userId])
        studioMail[userId] = box
        for _, existing in ipairs(box.Entries) do
            if existing.Id == entry.Id then return true end
        end
        table.insert(box.Entries, entry)
        return true
    end
    local ok = pcall(function()
        MailStore:UpdateAsync(mailKey(userId), function(old)
            local box = normalizeMail(old)
            for _, existing in ipairs(box.Entries) do
                if existing.Id == entry.Id then return box end
            end
            table.insert(box.Entries, entry)
            while #box.Entries > 150 do table.remove(box.Entries, 1) end
            return box
        end)
    end)
    return ok
end

local function getMail(userId)
    if not useStores then
        return normalizeMail(studioMail[userId])
    end
    local ok, result = pcall(function()
        return MailStore:GetAsync(mailKey(userId))
    end)
    return ok and normalizeMail(result) or {Entries = {}}
end

local function removeMailEntry(userId, entryId)
    if not useStores then
        local box = normalizeMail(studioMail[userId])
        for index = #box.Entries, 1, -1 do
            if box.Entries[index].Id == entryId then
                table.remove(box.Entries, index)
            end
        end
        return true
    end
    return pcall(function()
        MailStore:UpdateAsync(mailKey(userId), function(old)
            local box = normalizeMail(old)
            for index = #box.Entries, 1, -1 do
                if box.Entries[index].Id == entryId then
                    table.remove(box.Entries, index)
                end
            end
            return box
        end)
    end)
end

local function getListing(id)
    if not useStores then return studioListings[id] end
    local ok, result = pcall(function()
        return ListingStore:GetAsync(listingKey(id))
    end)
    return ok and result or nil
end

local function setListing(id, value)
    if not useStores then
        studioListings[id] = value
        return true
    end
    local ok = pcall(function()
        ListingStore:SetAsync(listingKey(id), value)
    end)
    return ok
end

local function updateListing(id, transform)
    if not useStores then
        local old = studioListings[id]
        local new = transform(old)
        studioListings[id] = new
        return true, new
    end
    local ok, result = pcall(function()
        return ListingStore:UpdateAsync(listingKey(id), transform)
    end)
    return ok, result
end

local function addIndex(listing)
    if not useStores then return true end
    return pcall(function()
        IndexStore:SetAsync(listing.Id, tonumber(listing.CreatedAt) or os.time())
    end)
end

local function removeIndex(id)
    if not useStores then return true end
    return pcall(function() IndexStore:RemoveAsync(id) end)
end

local function addListingId(data, id)
    for _, existing in ipairs(data.AuctionListings) do
        if existing == id then return end
    end
    table.insert(data.AuctionListings, id)
end

local function removeListingId(data, id)
    for index = #data.AuctionListings, 1, -1 do
        if data.AuctionListings[index] == id then table.remove(data.AuctionListings, index) end
    end
end

local function listingSummary(listing)
    if type(listing) ~= "table" then return nil end
    return {
        Id = listing.Id,
        SellerUserId = listing.SellerUserId,
        SellerName = listing.SellerName,
        ItemType = listing.ItemType,
        ItemName = listing.ItemName,
        Quantity = listing.Quantity,
        Price = listing.Price,
        CreatedAt = listing.CreatedAt,
        ExpiresAt = listing.ExpiresAt,
        State = listing.State,
    }
end

local function expireListing(listing)
    if not listing or listing.State ~= "Active" or (tonumber(listing.ExpiresAt) or 0) > os.time() then
        return listing
    end
    local ok, result = updateListing(listing.Id, function(current)
        if type(current) ~= "table" or current.State ~= "Active" then return current end
        if (tonumber(current.ExpiresAt) or 0) > os.time() then return current end
        current.State = "Expired"
        current.ClosedAt = os.time()
        return current
    end)
    if ok and result and result.State == "Expired" then
        queueMail(result.SellerUserId, {
            Id = "Return_" .. result.Id,
            Kind = "Item",
            ItemType = result.ItemType,
            ItemName = result.ItemName,
            Quantity = result.Quantity,
            Subject = "Expired auction listing",
        })
        removeIndex(result.Id)
        browseCache.At = 0
    end
    return result or listing
end

local function browseListings()
    if os.clock() - browseCache.At < 8 then return browseCache.Rows end
    local rows = {}
    if not useStores then
        for _, listing in pairs(studioListings) do
            listing = expireListing(listing)
            if listing and listing.State == "Active" then table.insert(rows, listingSummary(listing)) end
        end
        table.sort(rows, function(a, b) return a.CreatedAt > b.CreatedAt end)
        while #rows > Config.PageSize do table.remove(rows) end
    else
        local ok, pages = pcall(function()
            return IndexStore:GetSortedAsync(false, Config.PageSize)
        end)
        if ok and pages then
            for _, indexRow in ipairs(pages:GetCurrentPage()) do
                local listing = getListing(tostring(indexRow.key))
                if listing then
                    listing = expireListing(listing)
                    if listing and listing.State == "Active" then
                        table.insert(rows, listingSummary(listing))
                    end
                end
            end
        end
    end
    browseCache = {At = os.clock(), Rows = rows}
    return rows
end

local function reconcilePlayer(player)
    local data = ensurePlayerData(DataService:Get(player))
    if not data then return end
    local kept = {}
    for _, id in ipairs(data.AuctionListings) do
        local listing = getListing(id)
        if listing then
            listing = expireListing(listing)
            if listing.State == "Active" then table.insert(kept, id) end
        end
    end
    data.AuctionListings = kept
end

function Service:GetMyListings(player)
    local data = ensurePlayerData(DataService:Get(player))
    if not data then return {} end
    reconcilePlayer(player)
    local rows = {}
    for _, id in ipairs(data.AuctionListings) do
        local listing = getListing(id)
        if listing and listing.State == "Active" then table.insert(rows, listingSummary(listing)) end
    end
    table.sort(rows, function(a, b) return a.CreatedAt > b.CreatedAt end)
    return rows
end

function Service:GetMailbox(player)
    local box = getMail(player.UserId)
    local entries = {}
    for _, entry in ipairs(box.Entries) do
        table.insert(entries, {
            Id = entry.Id,
            Kind = entry.Kind,
            Coins = entry.Coins,
            ItemType = entry.ItemType,
            ItemName = entry.ItemName,
            Quantity = entry.Quantity,
            Subject = entry.Subject,
            CreatedAt = entry.CreatedAt,
        })
    end
    table.sort(entries, function(a, b) return (a.CreatedAt or 0) > (b.CreatedAt or 0) end)
    return entries
end

function Service:GetSnapshot(player)
    return {
        Browse = browseListings(),
        MyListings = self:GetMyListings(player),
        Mail = self:GetMailbox(player),
        FeeRate = Config.FeeRate,
        MinPrice = Config.MinPrice,
        MaxPrice = Config.MaxPrice,
        MaxListings = Config.MaxListingsPerPlayer,
    }
end

local function buildMailbox(plot)
    local existing = plot:FindFirstChild("AuctionMailbox")
    if existing then return existing end
    local land = plot:FindFirstChild("Land", true)
    if not land or not land:IsA("BasePart") then return nil end
    local box = Instance.new("Model")
    box.Name = "AuctionMailbox"
    box.Parent = plot
    local base = land.CFrame * CFrame.new(land.Size.X * 0.34, land.Size.Y / 2 + 2.4, land.Size.Z * 0.30)

    local post = Instance.new("Part")
    post.Name = "Post"
    post.Anchored = true
    post.CanCollide = true
    post.Size = Vector3.new(1, 4.8, 1)
    post.CFrame = base
    post.Material = Enum.Material.WoodPlanks
    post.Color = Color3.fromRGB(105, 72, 44)
    post.Parent = box

    local chest = Instance.new("Part")
    chest.Name = "Mailbox"
    chest.Anchored = true
    chest.CanCollide = true
    chest.Size = Vector3.new(4, 2.4, 2.6)
    chest.CFrame = base * CFrame.new(0, 2.3, 0)
    chest.Material = Enum.Material.WoodPlanks
    chest.Color = Color3.fromRGB(58, 76, 86)
    chest.Parent = box

    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "Auction House"
    prompt.ObjectText = "Trading Mailbox"
    prompt.HoldDuration = 0.1
    prompt.MaxActivationDistance = 12
    prompt.RequiresLineOfSight = false
    prompt.Parent = chest

    prompt.Triggered:Connect(function(player)
        local owner = tonumber(plot:GetAttribute("OwnerUserId") or plot:GetAttribute("Owner"))
        if owner ~= player.UserId then return end
        sessions[player] = {plot = plot, expiresAt = os.clock() + 1200}
        reconcilePlayer(player)
        Remote:FireClient(player, "Open", Service:GetSnapshot(player))
    end)
    return box
end

local function sessionValid(player)
    local session = sessions[player]
    if not session or os.clock() > session.expiresAt then
        sessions[player] = nil
        return false
    end
    local plot = getOwnedPlot(player)
    if not plot or plot ~= session.plot then return false end
    session.expiresAt = os.clock() + 1200
    return true
end

function Service:CreateListing(player, itemType, itemName, quantity, price)
    local data = ensurePlayerData(DataService:Get(player))
    if not data then return false, "Player data unavailable." end
    reconcilePlayer(player)
    if #data.AuctionListings >= Config.MaxListingsPerPlayer then
        return false, "You have reached your auction listing limit."
    end
    itemType, itemName = tostring(itemType or ""), tostring(itemName or "")
    if not Config.TradeableInventoryTypes[itemType] then return false, "That item cannot be auctioned." end
    quantity = math.max(1, math.floor(tonumber(quantity) or 1))
    price = math.floor(tonumber(price) or 0)
    if price < Config.MinPrice or price > Config.MaxPrice then
        return false, "Price must be between " .. tostring(Config.MinPrice) .. " and " .. tostring(Config.MaxPrice) .. " Coins."
    end
    if ShopService:CountInventoryItem(player, itemType, itemName) < quantity then
        return false, "You do not own enough of that item."
    end
    if not ShopService:ConsumeInventoryItem(player, itemType, itemName, quantity) then
        return false, "Could not remove the item from your inventory."
    end

    local id = HttpService:GenerateGUID(false)
    local now = os.time()
    local listing = {
        Id = id,
        SellerUserId = player.UserId,
        SellerName = player.DisplayName,
        ItemType = itemType,
        ItemName = itemName,
        Quantity = quantity,
        Price = price,
        CreatedAt = now,
        ExpiresAt = now + Config.ListingDurationSeconds,
        State = "Active",
    }
    if not setListing(id, listing) or not addIndex(listing) then
        ShopService:AddInventoryItem(player, itemType, itemName, quantity)
        if useStores then pcall(function() ListingStore:RemoveAsync(listingKey(id)) end) end
        return false, "The auction service is busy. Your item was returned."
    end
    addListingId(data, id)
    data.AuctionStats.Listed = (tonumber(data.AuctionStats.Listed) or 0) + 1
    browseCache.At = 0
    return true, "Listing created."
end

function Service:CancelListing(player, id)
    local data = ensurePlayerData(DataService:Get(player))
    if not data then return false, "Player data unavailable." end
    id = tostring(id or "")
    local ok, listing = updateListing(id, function(current)
        if type(current) ~= "table" or current.State ~= "Active" then return current end
        if tonumber(current.SellerUserId) ~= player.UserId then return current end
        current.State = "Cancelled"
        current.ClosedAt = os.time()
        return current
    end)
    if not ok or not listing or listing.State ~= "Cancelled" or tonumber(listing.SellerUserId) ~= player.UserId then
        return false, "That listing can no longer be cancelled."
    end
    local mailed = queueMail(player.UserId, {
        Id = "Return_" .. listing.Id,
        Kind = "Item",
        ItemType = listing.ItemType,
        ItemName = listing.ItemName,
        Quantity = listing.Quantity,
        Subject = "Cancelled auction listing",
    })
    if not mailed then return false, "Mailbox service is unavailable; try again shortly." end
    removeIndex(id)
    removeListingId(data, id)
    browseCache.At = 0
    return true, "Listing cancelled. The item is in your mailbox."
end

function Service:BuyListing(player, id)
    local data = ensurePlayerData(DataService:Get(player))
    if not data then return false, "Player data unavailable." end
    id = tostring(id or "")
    local original = getListing(id)
    if not original or original.State ~= "Active" then return false, "That listing is no longer available." end
    original = expireListing(original)
    if original.State ~= "Active" then return false, "That listing has expired." end
    if tonumber(original.SellerUserId) == player.UserId then return false, "You cannot buy your own listing." end
    local price = math.max(0, math.floor(tonumber(original.Price) or 0))
    if (tonumber(data.Coins) or 0) < price then return false, "Not enough Coins." end

    local ok, reserved = updateListing(id, function(current)
        if type(current) ~= "table" or current.State ~= "Active" then return current end
        if (tonumber(current.ExpiresAt) or 0) <= os.time() then return current end
        current.State = "Processing"
        current.BuyerUserId = player.UserId
        current.ProcessingAt = os.time()
        return current
    end)
    if not ok or not reserved or reserved.State ~= "Processing" or tonumber(reserved.BuyerUserId) ~= player.UserId then
        return false, "Another player bought that listing first."
    end

    if not DataService:SpendCoins(player, price) then
        updateListing(id, function(current)
            if current and current.State == "Processing" and tonumber(current.BuyerUserId) == player.UserId then
                current.State = "Active"
                current.BuyerUserId = nil
                current.ProcessingAt = nil
            end
            return current
        end)
        return false, "Not enough Coins."
    end

    local fee = math.max(1, math.floor(price * Config.FeeRate))
    local sellerNet = math.max(0, price - fee)
    local sellerMail = queueMail(reserved.SellerUserId, {
        Id = "Sale_" .. id,
        Kind = "Coins",
        Coins = sellerNet,
        Subject = tostring(reserved.ItemName) .. " sold for " .. tostring(price) .. " Coins (" .. tostring(fee) .. " fee)",
    })
    local buyerMail = queueMail(player.UserId, {
        Id = "Purchase_" .. id,
        Kind = "Item",
        ItemType = reserved.ItemType,
        ItemName = reserved.ItemName,
        Quantity = reserved.Quantity,
        Subject = "Auction purchase",
    })
    if not sellerMail or not buyerMail then
        if sellerMail then removeMailEntry(reserved.SellerUserId, "Sale_" .. id) end
        if buyerMail then removeMailEntry(player.UserId, "Purchase_" .. id) end
        DataService:AddCoins(player, price)
        updateListing(id, function(current)
            if current and current.State == "Processing" and tonumber(current.BuyerUserId) == player.UserId then
                current.State = "Active"
                current.BuyerUserId = nil
                current.ProcessingAt = nil
            end
            return current
        end)
        return false, "Mailbox delivery failed. Your Coins were refunded."
    end

    updateListing(id, function(current)
        if current and current.State == "Processing" and tonumber(current.BuyerUserId) == player.UserId then
            current.State = "Sold"
            current.ClosedAt = os.time()
            current.Fee = fee
            current.SellerNet = sellerNet
        end
        return current
    end)
    removeIndex(id)
    data.AuctionStats.Bought = (tonumber(data.AuctionStats.Bought) or 0) + 1
    browseCache.At = 0
    return true, "Purchase complete. Collect it from your mailbox."
end

function Service:ClaimMail(player, entryId)
    local data = ensurePlayerData(DataService:Get(player))
    if not data then return false, "Player data unavailable." end
    entryId = tostring(entryId or "")
    local box = getMail(player.UserId)
    local target
    for _, entry in ipairs(box.Entries) do
        if tostring(entry.Id) == entryId then target = entry break end
    end
    if not target then return false, "That mail has already been claimed." end
    if data.AuctionMailClaims[entryId] then
        removeMailEntry(player.UserId, entryId)
        return true, "Mail already delivered."
    end

    if target.Kind == "Coins" then
        DataService:AddCoins(player, math.max(0, math.floor(tonumber(target.Coins) or 0)))
    elseif target.Kind == "Item" then
        local ok, message = ShopService:AddInventoryItem(
            player,
            tostring(target.ItemType or ""),
            tostring(target.ItemName or ""),
            math.max(1, math.floor(tonumber(target.Quantity) or 1))
        )
        if not ok then return false, message or "Your inventory is full." end
    else
        return false, "Unknown mailbox entry."
    end

    data.AuctionMailClaims[entryId] = true
    DataService:Save(player)
    if not removeMailEntry(player.UserId, entryId) then
        return true, "Reward delivered; mailbox will refresh shortly."
    end
    return true, "Mail claimed."
end

function Service:PlayerReady(player)
    local data = ensurePlayerData(DataService:Get(player))
    if not data then return end
    task.defer(function()
        task.wait(1)
        if player.Parent then
            reconcilePlayer(player)
            Remote:FireClient(player, "MailCount", #self:GetMailbox(player))
        end
    end)
end

function Service:PlayerRemoving(player)
    sessions[player] = nil
end

function Service:Init()
    if started then return end
    started = true
    local plots = getPlots()
    if plots then
        for _, plot in ipairs(plots:GetChildren()) do buildMailbox(plot) end
        plots.ChildAdded:Connect(function(plot) task.defer(buildMailbox, plot) end)
    end
    Query.OnServerInvoke = function(player, action)
        if not sessionValid(player) then return nil end
        if action == "Browse" then return browseListings()
        elseif action == "MyListings" then return self:GetMyListings(player)
        elseif action == "Mail" then return self:GetMailbox(player)
        else return self:GetSnapshot(player) end
    end
    Remote.OnServerEvent:Connect(function(player, action, ...)
        if not sessionValid(player) then
            Remote:FireClient(player, "Result", false, "Use your Auction Mailbox first.")
            return
        end
        local args = {...}
        local ok, message = false, "Unknown auction action."
        if action == "List" then ok, message = self:CreateListing(player, args[1], args[2], args[3], args[4])
        elseif action == "Buy" then ok, message = self:BuyListing(player, args[1])
        elseif action == "Cancel" then ok, message = self:CancelListing(player, args[1])
        elseif action == "Claim" then ok, message = self:ClaimMail(player, args[1])
        end
        Remote:FireClient(player, "Result", ok, message, self:GetSnapshot(player))
    end)
    Players.PlayerRemoving:Connect(function(player) self:PlayerRemoving(player) end)
end

return Service
