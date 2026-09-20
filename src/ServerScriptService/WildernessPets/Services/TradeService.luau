local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Root = ReplicatedStorage:WaitForChild("WildernessPets")
local TradeRemote = Root.Remotes:WaitForChild("Trade")
local Config = require(Root.Shared.Config)

local DataService = require(script.Parent.PlayerDataService)
local PetService = require(script.Parent.PetService)
local MountService = require(script.Parent.MountService)
local ShopService = require(script.Parent.ShopService)
local WildforgeService = require(script.Parent.WildforgeService)

local Service = {}
local started = false

local sessionsByPlayer = {}
local sessionsById = {}
local requestsById = {}

local REQUEST_LIFETIME = 20
local TRADE_DISTANCE = 35
local MAX_OFFERS = 8

local TRADEABLE_INVENTORY_TYPES = {
    Loot = true,
    BossPetToken = true,
    BossMountToken = true,
}

local function deepClone(value)
    if type(value) ~= "table" then return value end
    local copy = {}
    for key, item in pairs(value) do
        copy[deepClone(key)] = deepClone(item)
    end
    return copy
end

local function playerRoot(player)
    local character = player and player.Character
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function playersClose(a, b)
    local rootA = playerRoot(a)
    local rootB = playerRoot(b)
    return rootA
        and rootB
        and (rootA.Position - rootB.Position).Magnitude <= TRADE_DISTANCE
end

local function sessionFor(player)
    local sessionId = sessionsByPlayer[player]
    return sessionId and sessionsById[sessionId] or nil
end

local function inventoryKey(itemType, name)
    return tostring(itemType) .. "\0" .. tostring(name)
end

local function assetKey(asset)
    if type(asset) ~= "table" then return "" end
    local kind = tostring(asset.Kind or "")
    if kind == "Pet" or kind == "Mount" or kind == "Equipment" then
        return kind .. ":" .. tostring(asset.Id or "")
    elseif kind == "Inventory" then
        return kind
            .. ":"
            .. tostring(asset.Type or "")
            .. ":"
            .. tostring(asset.Name or "")
    end
    return ""
end

local function cloneAssetSummary(asset)
    local copy = {}
    for _, key in ipairs({
        "Kind",
        "Id",
        "Type",
        "Name",
        "Quantity",
        "Species",
        "Rarity",
        "DisplayName",
        "Quality",
        "Slot",
        "ItemLevel",
        "WorldforgeLevel",
        "BossUnique",
        "MainStat",
        "Substats",
    }) do
        copy[key] = asset[key]
    end
    return copy
end

local function validatePet(player, petId)
    local data = DataService:Get(player)
    local pet = PetService:Find(player, tostring(petId or ""))
    if not data or not pet then return nil, "Pet not found." end

    if pet.Tradeable == false then
        return nil, "That pet cannot be traded."
    end
    if pet.Favourite then
        return nil, "Favourite pets cannot be traded."
    end
    if pet.Dead then
        return nil, "Dead or healing pets cannot be traded."
    end
    if pet.Displayed then
        return nil, "Remove that pet from your plot before trading it."
    end
    if data.EquippedPetId == pet.Id then
        return nil, "Unequip that companion before trading it."
    end
    if data.PodiumPetId == pet.Id then
        return nil, "Remove that pet from the podium before trading it."
    end
    if data.DefencePetId == pet.Id then
        return nil, "Remove that pet from village defence before trading it."
    end
    if type(pet.Equipment) == "table" and next(pet.Equipment) ~= nil then
        return nil, "Unequip all Wildforge equipment from that pet before trading it."
    end

    return {
        Kind = "Pet",
        Id = pet.Id,
        Name = tostring(pet.Name or pet.Species),
        DisplayName = tostring(pet.Name or pet.Species),
        Species = tostring(pet.Species),
        Rarity = tostring(pet.Rarity or ""),
        Quantity = 1,
    }
end

local function validateMount(player, mountId)
    local data = DataService:Get(player)
    local mount = MountService:Find(player, tostring(mountId or ""))
    if not data or not mount then return nil, "Mount not found." end

    if mount.Tradeable == false then
        return nil, "That mount cannot be traded."
    end
    if mount.Favourite then
        return nil, "Favourite mounts cannot be traded."
    end
    if data.EquippedMountId == mount.Id then
        return nil, "Unequip that mount before trading it."
    end

    return {
        Kind = "Mount",
        Id = mount.Id,
        Name = tostring(mount.Name or mount.Species),
        DisplayName = tostring(mount.Name or mount.Species),
        Species = tostring(mount.Species),
        Rarity = tostring(mount.Rarity or ""),
        Quantity = 1,
    }
end

local function validateInventory(player, itemType, name, quantity)
    itemType = tostring(itemType or "")
    name = tostring(name or "")
    if not TRADEABLE_INVENTORY_TYPES[itemType] then
        return nil, "That inventory item cannot be traded."
    end

    quantity = math.max(1, math.floor(tonumber(quantity) or 1))
    local owned = ShopService:CountInventoryItem(player, itemType, name)
    if owned < quantity then
        return nil, "You no longer own enough of that item."
    end

    return {
        Kind = "Inventory",
        Type = itemType,
        Name = name,
        DisplayName = name,
        Quantity = quantity,
    }
end

local function validateEquipment(player, itemId)
    local data = DataService:Get(player)
    if not data then return nil, "Player data is unavailable." end

    data.Equipment = type(data.Equipment) == "table" and data.Equipment or {}
    for _, item in ipairs(data.Equipment) do
        if type(item) == "table" and item.Id == tostring(itemId or "") then
            if item.Tradeable == false then
                return nil, "That equipment cannot be traded."
            end
            if item.Favourite then
                return nil, "Favourite equipment cannot be traded."
            end

            return {
                Kind = "Equipment",
                Id = tostring(item.Id),
                Name = tostring(item.Name or "Equipment"),
                DisplayName = tostring(item.Name or "Equipment"),
                Rarity = tostring(item.Tier or "Common"),
                Quality = tostring(item.Quality or "Crude"),
                Slot = tostring(item.Slot or ""),
                ItemLevel = math.max(1, math.floor(tonumber(item.ItemLevel) or 1)),
                WorldforgeLevel = math.max(0, math.floor(tonumber(item.WorldforgeLevel) or 0)),
                BossUnique = item.BossUnique == true,
                MainStat = deepClone(item.MainStat),
                Substats = deepClone(item.Substats),
                Quantity = 1,
            }
        end
    end

    return nil, "Unequipped equipment not found."
end

local function validateOffer(player, offer)
    if type(offer) ~= "table" then
        return nil, "Invalid trade offer."
    end

    local result = {}
    local seen = {}

    for _, requested in ipairs(offer) do
        if #result >= MAX_OFFERS then
            return nil, "A trade can contain at most " .. tostring(MAX_OFFERS) .. " offered entries."
        end

        local kind = tostring(requested.Kind or "")
        local asset
        local message

        if kind == "Pet" then
            asset, message = validatePet(player, requested.Id)
        elseif kind == "Mount" then
            asset, message = validateMount(player, requested.Id)
        elseif kind == "Inventory" then
            asset, message = validateInventory(
                player,
                requested.Type,
                requested.Name,
                requested.Quantity
            )
        elseif kind == "Equipment" then
            asset, message = validateEquipment(player, requested.Id)
        else
            return nil, "Unknown trade asset."
        end

        if not asset then
            return nil, message or "That trade asset is unavailable."
        end

        local key = assetKey(asset)
        if key == "" or seen[key] then
            return nil, "Duplicate trade entries are not allowed."
        end
        seen[key] = true
        table.insert(result, asset)
    end

    return result
end

local function offerCounts(offer)
    local pets = 0
    local mounts = 0
    local equipment = 0
    local inventory = {}

    for _, asset in ipairs(offer or {}) do
        if asset.Kind == "Pet" then
            pets += 1
        elseif asset.Kind == "Mount" then
            mounts += 1
        elseif asset.Kind == "Equipment" then
            equipment += 1
        elseif asset.Kind == "Inventory" then
            inventory[inventoryKey(asset.Type, asset.Name)] = {
                Type = asset.Type,
                Name = asset.Name,
                Quantity = math.max(1, math.floor(tonumber(asset.Quantity) or 1)),
            }
        end
    end

    return pets, mounts, equipment, inventory
end

local function resultingInventorySlots(data, outgoing, incoming)
    local amounts = {}

    for _, item in ipairs(data.Inventory or {}) do
        if type(item) == "table" then
            local key = inventoryKey(item.Type, item.Name)
            amounts[key] = {
                Type = tostring(item.Type or ""),
                Name = tostring(item.Name or ""),
                Quantity = math.max(0, math.floor(tonumber(item.Quantity) or 0)),
            }
        end
    end

    for key, item in pairs(outgoing or {}) do
        local current = amounts[key]
        if not current or current.Quantity < item.Quantity then
            return nil
        end
        current.Quantity -= item.Quantity
        if current.Quantity <= 0 then
            amounts[key] = nil
        end
    end

    for key, item in pairs(incoming or {}) do
        local current = amounts[key]
        if current then
            current.Quantity += item.Quantity
        else
            amounts[key] = deepClone(item)
        end
    end

    local count = 0
    for _ in pairs(amounts) do count += 1 end
    return count
end

local function validateCapacity(playerA, offerA, playerB, offerB)
    local dataA = DataService:Get(playerA)
    local dataB = DataService:Get(playerB)
    if not dataA or not dataB then
        return false, "Player data is unavailable."
    end

    local petsA, mountsA, equipmentA, invA = offerCounts(offerA)
    local petsB, mountsB, equipmentB, invB = offerCounts(offerB)

    local newPetsA = #(dataA.Pets or {}) - petsA + petsB
    local newPetsB = #(dataB.Pets or {}) - petsB + petsA
    if newPetsA > (Config.MaxPets or 60) then
        return false, playerA.Name .. " does not have enough pet collection space."
    end
    if newPetsB > (Config.MaxPets or 60) then
        return false, playerB.Name .. " does not have enough pet collection space."
    end

    local newEquipmentA = WildforgeService:GetEquipmentCount(playerA) - equipmentA + equipmentB
    local newEquipmentB = WildforgeService:GetEquipmentCount(playerB) - equipmentB + equipmentA
    if newEquipmentA > (Config.MaxEquipment or 100) then
        return false, playerA.Name .. " does not have enough equipment storage."
    end
    if newEquipmentB > (Config.MaxEquipment or 100) then
        return false, playerB.Name .. " does not have enough equipment storage."
    end

    local newMountsA = #(dataA.Mounts or {}) - mountsA + mountsB
    local newMountsB = #(dataB.Mounts or {}) - mountsB + mountsA
    if newMountsA > (Config.MaxMounts or 40) then
        return false, playerA.Name .. " does not have enough mount collection space."
    end
    if newMountsB > (Config.MaxMounts or 40) then
        return false, playerB.Name .. " does not have enough mount collection space."
    end

    local slotsA = resultingInventorySlots(dataA, invA, invB)
    local slotsB = resultingInventorySlots(dataB, invB, invA)
    if not slotsA or not slotsB then
        return false, "An offered inventory item changed before confirmation."
    end

    if slotsA > ShopService:GetInventoryCapacity(playerA) then
        return false, playerA.Name .. " does not have enough inventory space."
    end
    if slotsB > ShopService:GetInventoryCapacity(playerB) then
        return false, playerB.Name .. " does not have enough inventory space."
    end

    return true
end

local function removePet(data, petId)
    for index, pet in ipairs(data.Pets or {}) do
        if type(pet) == "table" and pet.Id == petId then
            return table.remove(data.Pets, index)
        end
    end
end

local function removeMount(data, mountId)
    for index, mount in ipairs(data.Mounts or {}) do
        if type(mount) == "table" and mount.Id == mountId then
            return table.remove(data.Mounts, index)
        end
    end
end

local function removeEquipment(data, itemId)
    data.Equipment = type(data.Equipment) == "table" and data.Equipment or {}
    for index, item in ipairs(data.Equipment) do
        if type(item) == "table" and item.Id == itemId then
            return table.remove(data.Equipment, index)
        end
    end
end

local function removeInventory(data, itemType, name, quantity)
    for index, item in ipairs(data.Inventory or {}) do
        if type(item) == "table"
            and item.Type == itemType
            and item.Name == name then
            local current = math.max(0, math.floor(tonumber(item.Quantity) or 0))
            if current < quantity then return false end

            current -= quantity
            if current <= 0 then
                table.remove(data.Inventory, index)
            else
                item.Quantity = current
            end
            return true
        end
    end
    return false
end

local function addInventory(data, itemType, name, quantity)
    for _, item in ipairs(data.Inventory or {}) do
        if type(item) == "table"
            and item.Type == itemType
            and item.Name == name then
            item.Quantity = math.max(0, tonumber(item.Quantity) or 0) + quantity
            return
        end
    end

    table.insert(data.Inventory, {
        Type = itemType,
        Name = name,
        Quantity = quantity,
    })
end

local function transferOffer(sourceData, targetData, offer)
    for _, asset in ipairs(offer or {}) do
        if asset.Kind == "Pet" then
            local pet = removePet(sourceData, asset.Id)
            if not pet then error("Pet changed during trade.") end
            pet.Displayed = false
            pet.Favourite = false
            table.insert(targetData.Pets, pet)

            local info = Config.Pets[pet.Species]
            if info and info.Legacy ~= true and info.SpawnMode ~= "Legacy" then
                targetData.PetCollection = type(targetData.PetCollection) == "table"
                    and targetData.PetCollection
                    or {}
                targetData.PetCollection[pet.Species] = true
            end

        elseif asset.Kind == "Mount" then
            local mount = removeMount(sourceData, asset.Id)
            if not mount then error("Mount changed during trade.") end
            mount.Favourite = false
            table.insert(targetData.Mounts, mount)
            targetData.MountCollection = type(targetData.MountCollection) == "table"
                and targetData.MountCollection
                or {}
            targetData.MountCollection[mount.Species] = true

        elseif asset.Kind == "Equipment" then
            local item = removeEquipment(sourceData, asset.Id)
            if not item then error("Equipment changed during trade.") end
            item.Favourite = false
            item.EquippedPetId = nil
            targetData.Equipment = type(targetData.Equipment) == "table"
                and targetData.Equipment
                or {}
            table.insert(targetData.Equipment, item)

        elseif asset.Kind == "Inventory" then
            local quantity = math.max(1, math.floor(tonumber(asset.Quantity) or 1))
            if not removeInventory(sourceData, asset.Type, asset.Name, quantity) then
                error("Inventory changed during trade.")
            end
            addInventory(targetData, asset.Type, asset.Name, quantity)
        end
    end
end

local function broadcast(session)
    if not session then return end

    for _, player in ipairs({session.A, session.B}) do
        if player and player.Parent then
            local partner = player == session.A and session.B or session.A
            local ownOffer = player == session.A and session.OfferA or session.OfferB
            local partnerOffer = player == session.A and session.OfferB or session.OfferA
            local ownConfirmed = player == session.A and session.ConfirmedA or session.ConfirmedB
            local partnerConfirmed = player == session.A and session.ConfirmedB or session.ConfirmedA

            local ownSummary = {}
            for _, asset in ipairs(ownOffer or {}) do
                table.insert(ownSummary, cloneAssetSummary(asset))
            end
            local partnerSummary = {}
            for _, asset in ipairs(partnerOffer or {}) do
                table.insert(partnerSummary, cloneAssetSummary(asset))
            end

            TradeRemote:FireClient(player, "Update", {
                SessionId = session.Id,
                PartnerUserId = partner and partner.UserId or 0,
                PartnerName = partner and partner.Name or "Player",
                YourOffer = ownSummary,
                PartnerOffer = partnerSummary,
                YourConfirmed = ownConfirmed == true,
                PartnerConfirmed = partnerConfirmed == true,
            })
        end
    end
end

local function closeSession(session, message, success)
    if not session then return end

    sessionsById[session.Id] = nil
    if session.A then sessionsByPlayer[session.A] = nil end
    if session.B then sessionsByPlayer[session.B] = nil end

    for _, player in ipairs({session.A, session.B}) do
        if player and player.Parent then
            TradeRemote:FireClient(
                player,
                success and "Result" or "Closed",
                success == true,
                message or (success and "Trade completed." or "Trade closed.")
            )
        end
    end
end

local function completeTrade(session)
    if not session or session.Completing then return end
    session.Completing = true

    local offerA, messageA = validateOffer(session.A, session.OfferA)
    local offerB, messageB = validateOffer(session.B, session.OfferB)
    if not offerA then
        session.Completing = false
        closeSession(session, messageA or "The first offer changed.", false)
        return
    end
    if not offerB then
        session.Completing = false
        closeSession(session, messageB or "The second offer changed.", false)
        return
    end
    if #offerA == 0 and #offerB == 0 then
        session.Completing = false
        closeSession(session, "A trade must contain at least one item, pet or mount.", false)
        return
    end
    if not playersClose(session.A, session.B) then
        session.Completing = false
        closeSession(session, "Players moved too far apart to complete the trade.", false)
        return
    end

    local capacityOk, capacityMessage = validateCapacity(
        session.A,
        offerA,
        session.B,
        offerB
    )
    if not capacityOk then
        session.Completing = false
        closeSession(session, capacityMessage, false)
        return
    end

    local dataA = DataService:Get(session.A)
    local dataB = DataService:Get(session.B)
    if not dataA or not dataB then
        session.Completing = false
        closeSession(session, "Player data became unavailable.", false)
        return
    end

    local snapshotA = {
        Pets = deepClone(dataA.Pets),
        Mounts = deepClone(dataA.Mounts),
        Equipment = deepClone(dataA.Equipment),
        Inventory = deepClone(dataA.Inventory),
        PetCollection = deepClone(dataA.PetCollection),
        MountCollection = deepClone(dataA.MountCollection),
    }
    local snapshotB = {
        Pets = deepClone(dataB.Pets),
        Mounts = deepClone(dataB.Mounts),
        Equipment = deepClone(dataB.Equipment),
        Inventory = deepClone(dataB.Inventory),
        PetCollection = deepClone(dataB.PetCollection),
        MountCollection = deepClone(dataB.MountCollection),
    }

    local ok, err = pcall(function()
        transferOffer(dataA, dataB, offerA)
        transferOffer(dataB, dataA, offerB)
    end)

    if not ok then
        dataA.Pets = snapshotA.Pets
        dataA.Mounts = snapshotA.Mounts
        dataA.Equipment = snapshotA.Equipment
        dataA.Inventory = snapshotA.Inventory
        dataA.PetCollection = snapshotA.PetCollection
        dataA.MountCollection = snapshotA.MountCollection

        dataB.Pets = snapshotB.Pets
        dataB.Mounts = snapshotB.Mounts
        dataB.Equipment = snapshotB.Equipment
        dataB.Inventory = snapshotB.Inventory
        dataB.PetCollection = snapshotB.PetCollection
        dataB.MountCollection = snapshotB.MountCollection

        warn("[WildernessPets] Trade rollback: " .. tostring(err))
        session.Completing = false
        closeSession(session, "The trade changed during completion and was rolled back safely.", false)
        return
    end

    closeSession(session, "Trade completed successfully.", true)
end

function Service:Request(player, targetUserId)
    if sessionFor(player) then
        return false, "Finish your current trade first."
    end

    local target = Players:GetPlayerByUserId(tonumber(targetUserId) or 0)
    if not target or target == player then
        return false, "That player is unavailable."
    end
    if sessionFor(target) then
        return false, "That player is already trading."
    end
    if not playersClose(player, target) then
        return false, "Move within " .. tostring(TRADE_DISTANCE) .. " studs to trade."
    end

    for _, request in pairs(requestsById) do
        if request.From == player and request.To == target then
            return false, "A trade request is already pending."
        end
    end

    local id = HttpService:GenerateGUID(false)
    requestsById[id] = {
        Id = id,
        From = player,
        To = target,
        ExpiresAt = os.clock() + REQUEST_LIFETIME,
    }

    TradeRemote:FireClient(target, "Request", {
        RequestId = id,
        FromUserId = player.UserId,
        FromName = player.Name,
    })

    task.delay(REQUEST_LIFETIME, function()
        local request = requestsById[id]
        if request then
            requestsById[id] = nil
            if request.From and request.From.Parent then
                TradeRemote:FireClient(request.From, "Notice", "Trade request expired.")
            end
            if request.To and request.To.Parent then
                TradeRemote:FireClient(request.To, "RequestExpired", id)
            end
        end
    end)

    return true, "Trade request sent to " .. target.Name .. "."
end

function Service:Respond(player, requestId, accepted)
    local request = requestsById[tostring(requestId or "")]
    if not request or request.To ~= player then
        return false, "That trade request is no longer available."
    end

    requestsById[request.Id] = nil

    if not accepted then
        if request.From and request.From.Parent then
            TradeRemote:FireClient(request.From, "Notice", player.Name .. " declined the trade.")
        end
        return true, "Trade declined."
    end

    if not request.From or not request.From.Parent then
        return false, "The requesting player left."
    end
    if sessionFor(request.From) or sessionFor(player) then
        return false, "One of the players is already trading."
    end
    if not playersClose(request.From, player) then
        return false, "Move closer together before accepting the trade."
    end

    local session = {
        Id = HttpService:GenerateGUID(false),
        A = request.From,
        B = player,
        OfferA = {},
        OfferB = {},
        ConfirmedA = false,
        ConfirmedB = false,
        Completing = false,
    }

    sessionsById[session.Id] = session
    sessionsByPlayer[session.A] = session.Id
    sessionsByPlayer[session.B] = session.Id

    TradeRemote:FireClient(session.A, "Open", {
        SessionId = session.Id,
        PartnerUserId = session.B.UserId,
        PartnerName = session.B.Name,
    })
    TradeRemote:FireClient(session.B, "Open", {
        SessionId = session.Id,
        PartnerUserId = session.A.UserId,
        PartnerName = session.A.Name,
    })

    broadcast(session)
    return true, "Trade opened."
end

function Service:SetOffer(player, sessionId, requestedOffer)
    local session = sessionFor(player)
    if not session or session.Id ~= tostring(sessionId or "") then
        return false, "Trade session unavailable."
    end
    if session.Completing then
        return false, "Trade is already completing."
    end

    local offer, message = validateOffer(player, requestedOffer)
    if not offer then return false, message end

    if player == session.A then
        session.OfferA = offer
    else
        session.OfferB = offer
    end

    session.ConfirmedA = false
    session.ConfirmedB = false
    broadcast(session)
    return true
end

function Service:Confirm(player, sessionId)
    local session = sessionFor(player)
    if not session or session.Id ~= tostring(sessionId or "") then
        return false, "Trade session unavailable."
    end
    if session.Completing then
        return false, "Trade is already completing."
    end

    if player == session.A then
        session.ConfirmedA = true
    else
        session.ConfirmedB = true
    end

    broadcast(session)

    if session.ConfirmedA and session.ConfirmedB then
        completeTrade(session)
    end

    return true
end

function Service:Cancel(player, message)
    local session = sessionFor(player)
    if session then
        closeSession(session, message or (player.Name .. " cancelled the trade."), false)
        return true
    end

    for id, request in pairs(requestsById) do
        if request.From == player or request.To == player then
            requestsById[id] = nil
            local other = request.From == player and request.To or request.From
            if other and other.Parent then
                TradeRemote:FireClient(other, "Notice", "Trade request cancelled.")
            end
        end
    end

    return false
end

function Service:PlayerRemoving(player)
    self:Cancel(player, player.Name .. " left the game.")
end

function Service:Init()
    if started then return end
    started = true

    TradeRemote.OnServerEvent:Connect(function(player, action, ...)
        local args = {...}

        if action == "Request" then
            local success, message = Service:Request(player, args[1])
            TradeRemote:FireClient(player, "Notice", message, success)

        elseif action == "Respond" then
            local success, message = Service:Respond(player, args[1], args[2] == true)
            TradeRemote:FireClient(player, "Notice", message, success)

        elseif action == "SetOffer" then
            local success, message = Service:SetOffer(player, args[1], args[2])
            if not success then
                TradeRemote:FireClient(player, "Notice", message, false)
            end

        elseif action == "Confirm" then
            local success, message = Service:Confirm(player, args[1])
            if not success then
                TradeRemote:FireClient(player, "Notice", message, false)
            end

        elseif action == "Cancel" then
            Service:Cancel(player)
        end
    end)
end

return Service
