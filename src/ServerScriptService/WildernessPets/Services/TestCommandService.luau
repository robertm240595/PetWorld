local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Root = ReplicatedStorage:WaitForChild("WildernessPets")
local Config = require(Root.Shared.Config)
local LootConfig = require(Root.Shared.LootConfig)
local LassoSkinConfig = require(Root.Shared.LassoSkinConfig)
local PetsRemote = Root.Remotes:WaitForChild("Pets")

local DataService = require(script.Parent.PlayerDataService)
local LassoSkinService = require(script.Parent.LassoSkinService)
local ShopService = require(script.Parent.ShopService)
local PetService = require(script.Parent.PetService)
local MountService = require(script.Parent.MountService)
local QuestService = require(script.Parent.QuestService)
local VillageUpgradeService = require(script.Parent.VillageUpgradeService)

local Service = {}
local bound = setmetatable({}, {__mode = "k"})

local PREFIX = ";"
local MAX_TEST_SPEED = 300
local MAX_GRANT_QUANTITY = 999

local function trim(value)
    return tostring(value or ""):match("^%s*(.-)%s*$") or ""
end

local function lower(value)
    return string.lower(trim(value))
end

local function notify(player, message)
    PetsRemote:FireClient(player, "TestCommand", true, "[TEST] " .. tostring(message))
end

local function fail(player, message)
    PetsRemote:FireClient(player, "TestCommand", false, "[TEST] " .. tostring(message))
end

local function canonicalName(dictionary, requested)
    local wanted = lower(requested)
    if wanted == "" then return nil end

    for name in pairs(dictionary or {}) do
        if lower(name) == wanted then
            return name
        end
    end
    return nil
end

local function canonicalSkinId(requested)
    local wanted = lower(requested)
    if wanted == "" then return nil end

    for skinId, info in pairs(LassoSkinConfig.Skins or {}) do
        if lower(skinId) == wanted or lower(info and info.Name) == wanted then
            return skinId
        end
    end
    return nil
end

local function lootNames()
    local names = {}
    for _, drop in pairs(LootConfig.Drops or {}) do
        if type(drop) == "table" then
            if type(drop.Primary) == "string" and drop.Primary ~= "" then
                names[drop.Primary] = true
            end
            if type(drop.Secondary) == "string" and drop.Secondary ~= "" then
                names[drop.Secondary] = true
            end
        end
    end
    return names
end

local LOOT_NAMES = lootNames()

local function splitTrailingNumber(raw)
    raw = trim(raw)
    local prefix, number = raw:match("^(.-)%s+(%d+)$")
    if prefix and number then
        return trim(prefix), math.clamp(math.floor(tonumber(number) or 1), 1, MAX_GRANT_QUANTITY)
    end
    return raw, 1
end

local function splitOptionalImprint(raw)
    raw = trim(raw)
    local prefix, number = raw:match("^(.-)%s+(%d+)$")
    if prefix and number then
        return trim(prefix), math.clamp(math.floor(tonumber(number) or 20), 20, 100)
    end
    return raw, nil
end

local function grantInventoryItem(player, requested, quantity)
    local lasso = canonicalName(Config.Lassos, requested)
    if lasso then
        if ShopService:CountInventoryItem(player, "Lasso", lasso) > 0 then
            local equipped, message = ShopService:EquipLasso(player, lasso)
            if equipped then
                QuestService:PushState(player)
                return true, lasso .. " was already owned and is now equipped."
            end
            return false, message or "Could not equip that lasso."
        end

        local added, reason = ShopService:AddInventoryItem(player, "Lasso", lasso, 1)
        if not added then return false, reason end

        local data = DataService:Get(player)
        local info = Config.Lassos[lasso]
        if data then
            data.MaxLassoStrengthUnlocked = math.max(
                tonumber(data.MaxLassoStrengthUnlocked) or 0,
                tonumber(info and info.Strength) or 0
            )
        end

        local equipped, equipMessage = ShopService:EquipLasso(player, lasso)
        QuestService:PushState(player)
        if not equipped then
            return true, lasso .. " added to inventory. " .. tostring(equipMessage or "")
        end
        return true, lasso .. " added and equipped."
    end

    local potion = canonicalName(Config.Potions, requested)
    if potion then
        local added, reason = ShopService:AddInventoryItem(player, "Potion", potion, quantity)
        if not added then return false, reason end
        return true, tostring(quantity) .. "x " .. potion .. " added to inventory."
    end

    local loot = canonicalName(LOOT_NAMES, requested)
    if loot then
        local added, reason = ShopService:AddInventoryItem(player, "Loot", loot, quantity)
        if not added then return false, reason end
        return true, tostring(quantity) .. "x " .. loot .. " added to inventory."
    end

    return false, "Unknown inventory item '" .. tostring(requested) .. "'. Use exact loot, potion, or lasso names."
end

local function grantAllLassos(player)
    local data = DataService:Get(player)
    if not data then
        return false, "Player data unavailable."
    end

    data.Inventory = type(data.Inventory) == "table" and data.Inventory or {}

    local ordered = {}
    local missing = 0
    for name, info in pairs(Config.Lassos or {}) do
        table.insert(ordered, {
            Name = name,
            Strength = tonumber(info and info.Strength) or 0,
        })
        if ShopService:CountInventoryItem(player, "Lasso", name) <= 0 then
            missing += 1
        end
    end

    table.sort(ordered, function(a, b)
        if a.Strength == b.Strength then
            return a.Name < b.Name
        end
        return a.Strength < b.Strength
    end)

    if #ordered == 0 then
        return false, "No lasso tiers are configured."
    end

    -- Studio helper commands should always be able to grant their requested
    -- test items, even if the player's normal bag happens to be full.
    local neededCapacity = #data.Inventory + missing
    data.InventoryCapacity = math.max(
        tonumber(data.InventoryCapacity) or tonumber(Config.MaxInventory) or 25,
        neededCapacity
    )

    local added = 0
    local highestStrength = tonumber(data.MaxLassoStrengthUnlocked) or 0
    for _, entry in ipairs(ordered) do
        if ShopService:CountInventoryItem(player, "Lasso", entry.Name) <= 0 then
            local ok, reason = ShopService:AddInventoryItem(player, "Lasso", entry.Name, 1)
            if not ok then
                return false, reason or ("Could not grant " .. entry.Name .. ".")
            end
            added += 1
        end
        highestStrength = math.max(highestStrength, entry.Strength)
    end

    data.MaxLassoStrengthUnlocked = highestStrength

    local strongest = ordered[#ordered].Name
    local equipped, equipMessage = ShopService:EquipLasso(player, strongest)
    QuestService:PushState(player)

    if not equipped then
        return false, equipMessage or "All lassos were granted, but the strongest could not be equipped."
    end

    return true, "All " .. tostring(#ordered) .. " lassos acquired"
        .. (added > 0 and (" (" .. tostring(added) .. " new)") or " (already owned)")
        .. ". " .. strongest .. " equipped."
end

local function grantLassoSkin(player, requested)
    local skinId = canonicalSkinId(requested)
    local info = skinId and LassoSkinConfig.Get(skinId)
    local data = DataService:Get(player)
    if not skinId or not info then
        return false, "Unknown lasso skin '" .. tostring(requested) .. "'."
    end
    if not data then
        return false, "Player data unavailable."
    end

    data.LassoSkinsOwned = type(data.LassoSkinsOwned) == "table" and data.LassoSkinsOwned or {}
    local alreadyOwned = data.LassoSkinsOwned[skinId] == true
    data.LassoSkinsOwned[skinId] = true

    local equipped, message = LassoSkinService:Equip(player, skinId)
    if not equipped then
        return false, message or "Could not equip that lasso skin."
    end

    return true, info.Name .. (alreadyOwned and " was already owned and is now equipped." or " added and equipped.")
end

local function setSpeed(player, raw)
    local value = lower(raw)
    if value == "reset" or value == "normal" or value == "default" then
        player:SetAttribute("TestWalkSpeed", nil)
        MountService:ApplyMovement(player)
        return true, "speed override cleared. Normal mount/potion speed restored."
    end

    local numeric = tonumber(trim(raw))
    if not numeric then
        return false, "Usage: ;speed <0-" .. tostring(MAX_TEST_SPEED) .. "> or ;speed reset"
    end

    numeric = math.clamp(numeric, 0, MAX_TEST_SPEED)
    player:SetAttribute("TestWalkSpeed", numeric)
    MountService:ApplyMovement(player)
    return true, "WalkSpeed set to " .. tostring(numeric) .. "."
end

local function givePet(player, raw)
    local requested, imprint = splitOptionalImprint(raw)
    local species = canonicalName(Config.Pets, requested)
    if not species then
        return false, "Unknown pet species '" .. tostring(requested) .. "'."
    end

    local info = Config.Pets[species]
    if info and info.Legacy == true then
        return false, "Legacy pet species cannot be granted with test commands."
    end

    local options = {AcquiredFrom = "TestCommand"}
    if imprint then options.Imprint = imprint end
    local pet = PetService:Create(player, species, options)
    if not pet then
        return false, "Could not add " .. species .. ". Your pet collection may be full."
    end

    return true, species .. " added to Pets"
        .. (imprint and (" at " .. tostring(imprint) .. "% imprint.") or ".")
end

local function giveMount(player, raw)
    local requested, imprint = splitOptionalImprint(raw)
    local species = canonicalName(Config.Mounts, requested)
    if not species then
        return false, "Unknown mount species '" .. tostring(requested) .. "'."
    end

    local mount, reason = MountService:Create(player, species, {
        Imprint = imprint,
        AcquiredFrom = "TestCommand",
    })
    if not mount then
        return false, reason or ("Could not add " .. species .. ".")
    end

    return true, species .. " added to Mounts"
        .. (imprint and (" at " .. tostring(imprint) .. "% imprint.") or ".")
end

local function addCurrency(player, kind, raw)
    local amount = math.floor(tonumber(trim(raw)) or 0)
    if amount <= 0 then
        return false, "Usage: ;" .. kind .. " <positive amount>"
    end
    amount = math.min(amount, 100000000)

    local balance
    if kind == "coins" then
        balance = DataService:AddCoins(player, amount)
    else
        balance = DataService:AddGems(player, amount)
    end

    if balance == nil then
        return false, "Could not update " .. kind .. "."
    end
    return true, "+" .. tostring(amount) .. " " .. kind .. " · balance " .. tostring(balance) .. "."
end

local function setBag(player, raw)
    local name = canonicalName(Config.Backpacks, raw)
    if not name then
        return false, "Unknown backpack '" .. tostring(trim(raw)) .. "'."
    end

    local data = DataService:Get(player)
    local info = Config.Backpacks[name]
    if not data or not info then return false, "Backpack unavailable." end

    local target = math.max(
        tonumber(Config.MaxInventory) or 25,
        math.floor(tonumber(info.Capacity) or 0)
    )

    if target <= (tonumber(data.InventoryCapacity) or tonumber(Config.MaxInventory) or 25) then
        data.BackpackName = name
        return true, name .. " selected. Current capacity is already " .. tostring(data.InventoryCapacity) .. "."
    end

    local ok, message = ShopService:UpgradeInventoryCapacity(player, name)
    if not ok then return false, message end
    return true, message
end

local function addPetXP(player, raw)
    local amount = math.max(1, math.floor(tonumber(trim(raw)) or 0))
    if amount <= 0 then return false, "Usage: ;petxp <positive amount>" end
    amount = math.min(amount, 10000000)

    local data = DataService:Get(player)
    if not data or type(data.Pets) ~= "table" or #data.Pets == 0 then
        return false, "Give yourself a pet first."
    end

    local petId = type(data.EquippedPetId) == "string" and data.EquippedPetId or ""
    if petId == "" then petId = tostring(data.Pets[1].Id or "") end
    local pet = PetService:Find(player, petId)
    if not pet then return false, "Could not find a test pet." end

    local ok = PetService:AddXP(player, petId, amount, true)
    if not ok then return false, "Could not add pet XP." end
    return true, "+" .. tostring(amount) .. " XP to " .. tostring(pet.Name or pet.Species) .. " · Lv." .. tostring(pet.Level) .. "."
end
local function killTestPet(player)
    local data = DataService:Get(player)
    if not data or type(data.Pets) ~= "table" or #data.Pets == 0 then
        return false, "Give yourself a pet first."
    end
    local petId = type(data.EquippedPetId) == "string" and data.EquippedPetId or ""
    if petId == "" then petId = tostring(data.Pets[1].Id or "") end
    local pet = PetService:Find(player, petId)
    if not pet then return false, "Could not find a test pet." end
    pet.Dead = true
    pet.CurrentHealth = 0
    pet.HealReadyAt = 0
    return true, tostring(pet.Name or pet.Species) .. " marked defeated for Barn testing."
end

local function advanceTraining(player, raw)
    local seconds = math.max(1, math.floor(tonumber(trim(raw)) or 900))
    seconds = math.min(seconds, 86400)
    return VillageUpgradeService:DebugAdvanceTraining(player, seconds)
end

local function helpText()
    return ";help = acquire all lassos | ;speed 50 | ;give Wolf Hide 5 | ;giveskin Meadow Twine | ;givepet Wolf 100 | ;petxp 5000 | ;killpet | ;traintick 900 | ;givemount Trail Horse 100 | ;coins 5000 | ;gems 100 | ;bag Trail Pack"
end

function Service:Handle(player, message)
    if not RunService:IsStudio() then return false end
    if type(message) ~= "string" or string.sub(message, 1, #PREFIX) ~= PREFIX then return false end

    local body = trim(string.sub(message, #PREFIX + 1))
    local command, rest = body:match("^(%S+)%s*(.*)$")
    command = lower(command)
    rest = trim(rest)

    local ok, response
    if command == "help" then
        ok, response = grantAllLassos(player)
    elseif command == "commands" then
        ok, response = true, helpText()
    elseif command == "speed" then
        ok, response = setSpeed(player, rest)
    elseif command == "give" or command == "item" then
        local requested, quantity = splitTrailingNumber(rest)
        if requested == "" then
            ok, response = false, "Usage: ;give <loot/potion/lasso name> [quantity]"
        else
            ok, response = grantInventoryItem(player, requested, quantity)
        end
    elseif command == "giveskin" or command == "skin" then
        if rest == "" then
            ok, response = false, "Usage: ;giveskin <skin id or name>"
        else
            ok, response = grantLassoSkin(player, rest)
        end
    elseif command == "givepet" or command == "pet" then
        ok, response = givePet(player, rest)
    elseif command == "givemount" or command == "mount" then
        ok, response = giveMount(player, rest)
    elseif command == "petxp" or command == "xp" then
        ok, response = addPetXP(player, rest)
    elseif command == "killpet" then
        ok, response = killTestPet(player)
    elseif command == "traintick" then
        ok, response = advanceTraining(player, rest)
    elseif command == "coins" then
        ok, response = addCurrency(player, "coins", rest)
    elseif command == "gems" then
        ok, response = addCurrency(player, "gems", rest)
    elseif command == "bag" or command == "backpack" then
        ok, response = setBag(player, rest)
    else
        ok, response = false, "Unknown test command. Type ;help."
    end

    if ok then
        notify(player, response)
    else
        fail(player, response)
    end
    return true
end

function Service:BindPlayer(player)
    if not RunService:IsStudio() or bound[player] then return end

    bound[player] = player.Chatted:Connect(function(message)
        Service:Handle(player, message)
    end)

    notify(player, "Studio test commands enabled. Type ;help in chat.")
end

function Service:PlayerRemoving(player)
    local connection = bound[player]
    if connection then connection:Disconnect() end
    bound[player] = nil
end

return Service
