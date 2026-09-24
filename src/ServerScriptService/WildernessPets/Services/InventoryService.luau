local Config=require(game.ReplicatedStorage.WildernessPets.Shared.Config)
local DataService=require(script.Parent.PlayerDataService)
local Schema=require(script.Parent.ProfileSchema)
local Service={}
local function ensureInventory(data)
    data.Inventory=type(data.Inventory)=="table" and data.Inventory or {}
    return data.Inventory
end
local function inventoryCapacity(data)
    return math.max(tonumber(Config.MaxInventory) or 25,math.floor(tonumber(data.InventoryCapacity) or 25))
end
local function validItem(kind,name,quantity)
    return type(kind)=="string" and #kind>0 and #kind<=64
        and type(name)=="string" and #name>0 and #name<=256
        and Schema.ValidAmount(quantity) and quantity>=1
end
function Service:CountInventorySlots(player)
    local data = DataService:Get(player)
    if not data then return 0 end
    return #ensureInventory(data)
end

function Service:GetInventoryCapacity(player)
    local data = DataService:Get(player)
    if not data then return tonumber(Config.MaxInventory) or 25 end
    return inventoryCapacity(data)
end

function Service:AddInventoryItem(player, itemType, name, quantity)
    local data = DataService:Get(player)
    if not data then return false, "Inventory unavailable." end

    local inventory = ensureInventory(data)
    quantity = quantity == nil and 1 or quantity
    if not validItem(itemType,name,quantity) then return false, "Invalid inventory quantity or item." end

    for _, item in ipairs(inventory) do
        if type(item) == "table" and item.Type == itemType and item.Name == name then
            if not Schema.ValidAmount(item.Quantity) or quantity > Schema.MaxCurrency-item.Quantity then return false, "Invalid stack quantity." end
            item.Quantity += quantity
            return true
        end
    end

    if #inventory >= inventoryCapacity(data) then
        return false, "Your inventory is full (" .. tostring(#inventory) .. "/" .. tostring(inventoryCapacity(data)) .. ")."
    end

    table.insert(inventory, {
        Type = itemType,
        Name = name,
        Quantity = quantity
    })

    return true
end

function Service:CanAddInventoryBatch(player, entries)
    if type(entries) ~= "table" then return false, "Invalid rewards." end
    for _,entry in ipairs(entries) do
        if type(entry) ~= "table" or not validItem(entry.Type,entry.Name,entry.Quantity) then return false, "Invalid reward entry." end
    end
    local data = DataService:Get(player)
    if not data then return false, "Inventory unavailable." end

    local inventory = ensureInventory(data)
    local existing = {}
    for _, item in ipairs(inventory) do
        if type(item) == "table" then
            existing[tostring(item.Type) .. "\0" .. tostring(item.Name)] = true
        end
    end

    local additionalSlots = 0
    local pending = {}
    for _, entry in ipairs(entries or {}) do
        if type(entry) == "table" then
            local itemType = tostring(entry.Type or "")
            local name = tostring(entry.Name or "")
            local quantity = math.max(0, math.floor(tonumber(entry.Quantity) or 0))
            if itemType ~= "" and name ~= "" and quantity > 0 then
                local key = itemType .. "\0" .. name
                if not existing[key] and not pending[key] then
                    pending[key] = true
                    additionalSlots += 1
                end
            end
        end
    end

    if #inventory + additionalSlots > inventoryCapacity(data) then
        return false,
            "You need "
                .. tostring(additionalSlots)
                .. " free/compatible inventory slot"
                .. (additionalSlots == 1 and "" or "s")
                .. " for these rewards."
    end

    return true
end

function Service:AddInventoryBatch(player, entries)
    local allowed, message = self:CanAddInventoryBatch(player, entries)
    if not allowed then return false, message end

    local added = {}
    for _, entry in ipairs(entries or {}) do
        if type(entry) == "table" then
            local quantity = math.max(0, math.floor(tonumber(entry.Quantity) or 0))
            if quantity > 0 then
                local success, addMessage = self:AddInventoryItem(
                    player,
                    tostring(entry.Type or ""),
                    tostring(entry.Name or ""),
                    quantity
                )
                if not success then
                    for index = #added, 1, -1 do
                        local restore = added[index]
                        self:ConsumeInventoryItem(
                            player,
                            restore.Type,
                            restore.Name,
                            restore.Quantity
                        )
                    end
                    return false, addMessage or "Could not store all rewards."
                end
                table.insert(added, {
                    Type = tostring(entry.Type or ""),
                    Name = tostring(entry.Name or ""),
                    Quantity = quantity,
                })
            end
        end
    end

    return true
end

function Service:CountInventoryItem(player, itemType, name)
    local data = DataService:Get(player)
    if not data then return 0 end

    for _, item in ipairs(ensureInventory(data)) do
        if type(item) == "table" and item.Type == itemType and item.Name == name then
            return math.max(0, math.floor(tonumber(item.Quantity) or 0))
        end
    end

    return 0
end

function Service:ConsumeInventoryItem(player, itemType, name, quantity)
    local data = DataService:Get(player)
    if not data then return false end

    local inventory = ensureInventory(data)
    quantity = quantity == nil and 1 or quantity
    if not validItem(itemType,name,quantity) then return false, "Invalid inventory quantity or item." end

    for index, item in ipairs(inventory) do
        if type(item) == "table" and item.Type == itemType and item.Name == name then
            local current = math.max(0, math.floor(tonumber(item.Quantity) or 0))
            if current < quantity then return false end

            current -= quantity
            if current <= 0 then
                table.remove(inventory, index)
            else
                item.Quantity = current
            end
            return true
        end
    end

    return false
end

return Service
