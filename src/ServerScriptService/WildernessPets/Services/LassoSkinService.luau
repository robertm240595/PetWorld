local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Root = ReplicatedStorage:WaitForChild("WildernessPets")
local PetsRemote = Root.Remotes:WaitForChild("Pets")
local Config = require(Root.Shared.Config)
local SkinConfig = require(Root.Shared.LassoSkinConfig)
local DataService = require(script.Parent.PlayerDataService)

local Service = {}
local rng = Random.new()
local processedTargets = setmetatable({}, {__mode = "k"})

local function ensureOwned(data)
    data.LassoSkinsOwned = type(data.LassoSkinsOwned) == "table" and data.LassoSkinsOwned or {}
    return data.LassoSkinsOwned
end

function Service:Equip(player, skinId)
    local data = DataService:Get(player)
    local skin = SkinConfig.Get(skinId)
    if not data or not skin then
        return false, "That lasso skin does not exist."
    end

    local owned = ensureOwned(data)
    if owned[skinId] ~= true then
        return false, "You have not collected that lasso skin."
    end

    data.EquippedLassoSkin = skinId
    player:SetAttribute("EquippedLassoSkin", skinId)
    return true, skin.Name .. " equipped."
end

function Service:Unequip(player)
    local data = DataService:Get(player)
    if not data then
        return false, "Player data unavailable."
    end

    data.EquippedLassoSkin = ""
    player:SetAttribute("EquippedLassoSkin", "")
    return true, "Base lasso appearance restored."
end

function Service:RollDrop(player, target)
    if typeof(target) ~= "Instance" or processedTargets[target] then
        return nil
    end
    if target:GetAttribute("LassoSkinDropProcessed") == true then
        return nil
    end

    local species = tostring(target:GetAttribute("Species") or "")
    if not Config.Pets[species]
        or target:GetAttribute("WorldBoss") == true
        or target:GetAttribute("QuestNoRewards") == true then
        return nil
    end

    processedTargets[target] = true
    target:SetAttribute("LassoSkinDropProcessed", true)

    local roll = rng:NextNumber()
    local threshold = 0
    local rarity

    for _, candidate in ipairs(SkinConfig.DropOrder) do
        threshold += math.max(0, tonumber(SkinConfig.DropRates[candidate]) or 0)
        if roll < threshold then
            rarity = candidate
            break
        end
    end

    if not rarity then
        return nil
    end

    local pool = SkinConfig.ByRarity[rarity] or {}
    if #pool == 0 then
        return nil
    end

    local skinId = pool[rng:NextInteger(1, #pool)]
    local skin = SkinConfig.Get(skinId)
    local data = DataService:Get(player)
    if not data or not skin then
        return nil
    end

    local owned = ensureOwned(data)
    if owned[skinId] == true then
        -- Ownership is intentionally boolean. Duplicate rolls do not stack,
        -- reroll, or convert to currency, keeping the published odds stable
        -- and avoiding a repeat-farming economy exploit.
        return {
            SkinId = skinId,
            Rarity = rarity,
            Duplicate = true,
        }
    end

    owned[skinId] = true
    PetsRemote:FireClient(player, "LassoSkinDrop", skinId, skin.Name, rarity)

    return {
        SkinId = skinId,
        Rarity = rarity,
        Duplicate = false,
    }
end

return Service

