-- Profile format is independent of the DataStore name; keep WildernessPets_V2.
local Config = require(game.ReplicatedStorage.WildernessPets.Shared.Config)
local Schema = {Version = 1, MaxCurrency = 9007199254740991}
local function newData()
    return {
        Coins = Config.StartCoins,
        Gems = Config.StartGems,
        Lasso = "Rough Rope",
        MaxLassoStrengthUnlocked = 15,
        LassoSkinsOwned = {},
        EquippedLassoSkin = "",
        Inventory = {
            {Type = "Lasso", Name = "Rough Rope", Quantity = 1}
        },
        InventoryCapacity = Config.MaxInventory or 25,
        BackpackName = "Starter Bag",
        LootInventory = {},
        PetBuyback = {},
        LassoBuyback = {},
        ActiveEffects = {
            XPBoostUntil = 0,
            XPBoostPercent = 0,
            SpeedBoostUntil = 0,
            PlayerSpeedMultiplier = 1,
            PetSpeedMultiplier = 1,
            NextCaptureTranquiliser = false,
            NextCaptureLuck = false
        },
        Pets = {},
        Mounts = {},
        MountCollection = {},
        PetCollection = {},
        CollectionRewardsClaimed = {},
        QuestProgress = {},
        Achievements = {},
        AuctionListings = {},
        AuctionStats = {Listed = 0, Sold = 0, Bought = 0, FeesPaid = 0},
        AuctionMailClaims = {},
        VillageUpgrades = {HealingBarn = 1, TrainingArea = 1, TrainingSlots = 1},
        TrainingAssignments = {},
        SelectedPlot = 0,
        DefencePetId = "",
        EquippedPetId = "",
        EquippedMountId = "",
        PodiumPetId = "",
        ArenaRating = 1000,
        ArenaWins = 0,
        ArenaLosses = 0,
        WeeklyWins = 0,
        LastWeeklyReward = 0
    }
end


function Schema.IsFinite(value)
    return type(value) == "number" and value == value and math.abs(value) < math.huge
end
function Schema.ValidAmount(value)
    return Schema.IsFinite(value) and value >= 0 and value <= Schema.MaxCurrency and value % 1 == 0
end
function Schema.Copy(value, seen)
    if type(value) ~= "table" then return value end
    seen = seen or {}
    assert(not seen[value], "Cyclic profile")
    seen[value] = true
    local result = {}
    for key, item in pairs(value) do result[key] = Schema.Copy(item, seen) end
    seen[value] = nil
    return result
end
function Schema.New()
    local data = newData()
    data.SchemaVersion = Schema.Version
    data.PlotState = {Version = 1, TemplateId = "starter", Decorations = {}, Upgrades = {}}
    data.PetMastery = {}
    data.DuelStats = {Wins = 0, Losses = 0, Draws = 0}
    data.PvPStats = {Wins = 0, Losses = 0}
    data.PurchaseReceipts = {}
    return data
end
function Schema.Migrate(saved)
    assert(saved == nil or type(saved) == "table", "Invalid profile")
    local data = saved and Schema.Copy(saved) or {}
    local version = data.SchemaVersion or 0
    assert(Schema.ValidAmount(version) and version <= Schema.Version, "Unsupported profile version")
    local function reconcile(target, template)
        for key, fallback in pairs(template) do
            if target[key] == nil then
                target[key] = Schema.Copy(fallback)
            elseif type(target[key]) ~= type(fallback) then
                error("Invalid profile field: " .. tostring(key))
            elseif type(fallback) == "table" then
                -- Arrays represent ownership; never insert starter items into existing arrays.
                if #fallback == 0 then reconcile(target[key], fallback) end
            elseif type(fallback) == "number" and not Schema.IsFinite(target[key]) then
                error("Non-finite profile field: " .. tostring(key))
            end
        end
    end
    local function validate(value, depth)
        assert(depth <= 30, "Profile nesting too deep")
        if type(value) == "table" then
            for key, item in pairs(value) do
                assert(type(key) == "string" or (Schema.ValidAmount(key) and key >= 1), "Invalid profile key")
                validate(item, depth + 1)
            end
        elseif type(value) == "number" then
            assert(Schema.IsFinite(value), "Non-finite profile value")
        else
            assert(type(value) == "string" or type(value) == "boolean", "Unsupported profile value")
        end
    end
    validate(data, 0)
    reconcile(data, Schema.New())
    assert(Schema.ValidAmount(data.Coins) and Schema.ValidAmount(data.Gems), "Invalid profile currency")
    for _,item in ipairs(data.Inventory) do
        assert(type(item)=="table" and type(item.Type)=="string" and type(item.Name)=="string", "Invalid inventory entry")
        assert(item.Quantity==nil or (Schema.ValidAmount(item.Quantity) and item.Quantity>=1), "Invalid inventory quantity")
    end
    for _,field in ipairs({"Pets","Mounts"}) do
        local ids={}
        for _,pet in ipairs(data[field]) do
            assert(type(pet)=="table" and type(pet.Species)=="string","Invalid owned creature")
            if pet.Id~=nil then
                assert(type(pet.Id)=="string" and not ids[pet.Id],"Invalid or duplicate creature ID")
                ids[pet.Id]=true
            end
        end
    end
    data.SchemaVersion = Schema.Version
    data._ProfileSession = nil
    return data
end
return Schema
