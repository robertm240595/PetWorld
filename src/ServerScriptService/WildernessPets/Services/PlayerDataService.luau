local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local Config = require(game.ReplicatedStorage.WildernessPets.Shared.Config)
local SkinConfig = require(game.ReplicatedStorage.WildernessPets.Shared.LassoSkinConfig)

-- Unpublished Studio places cannot access DataStoreService. In that case,
-- keep player data in memory for the current test session instead.
local Store = nil
local useDataStore = not RunService:IsStudio()

if useDataStore then
    Store = DataStoreService:GetDataStore("WildernessPets_V2")
end

local Service = {}
Service.Data = {}

local Schema = require(script.Parent.ProfileSchema)
local Persistence = require(script.Parent.ProfilePersistence)
local HttpService = game:GetService("HttpService")
local sessions, loading, saving, released = {}, {}, {}, {}
local closing = false

local function makeLeaderstats(player, data)
    local ls = Instance.new("Folder")
    ls.Name = "leaderstats"
    ls.Parent = player

    local coins = Instance.new("IntValue")
    coins.Name = "Coins"
    coins.Value = data.Coins
    coins.Parent = ls

    local gems = Instance.new("IntValue")
    gems.Name = "Gems"
    gems.Value = data.Gems
    gems.Parent = ls

    local rating = Instance.new("IntValue")
    rating.Name = "ArenaRating"
    rating.Value = data.ArenaRating
    rating.Parent = ls
end

local function syncLeaderstats(player)
    local data = Service.Data[player]
    if not data then return end

    local ls = player:FindFirstChild("leaderstats")
    if not ls then return end

    if ls:FindFirstChild("Coins") then
        ls.Coins.Value = data.Coins
    end

    if ls:FindFirstChild("Gems") then
        ls.Gems.Value = data.Gems
    end

    if ls:FindFirstChild("ArenaRating") then
        ls.ArenaRating.Value = data.ArenaRating
    end
end

function Service:Load(player)
    if self.Data[player] then return self.Data[player] end
    if loading[player] or closing then return nil end
    loading[player] = true
    player:SetAttribute("ProfileStatus", "Loading")
    local data, err
    if useDataStore and Store then
        local session = Persistence.new(Store, game.JobId .. ":" .. HttpService:GenerateGUID(false))
        data, err = session:Acquire("Player_" .. player.UserId)
        if data then sessions[player] = session end
    else
        data = Schema.New()
    end
    if not data then
        loading[player] = nil
        player:SetAttribute("ProfileStatus", "LoadFailed")
        warn("[PlayerData] Load refused for " .. player.UserId .. ": " .. tostring(err))
        player:Kick("Your saved progress could not be safely loaded. Please rejoin shortly.")
        return nil
    end
    if player.Parent ~= Players or closing then
        if sessions[player] then sessions[player]:Save("Player_" .. player.UserId, data, true) end
        sessions[player], loading[player] = nil, nil
        return nil
    end
    local normalizer = require(script.Parent.ProfileNormalizer)
    local normalized, result = pcall(normalizer, Schema.Copy(data))
    if not normalized then
        loading[player] = nil
        if sessions[player] then sessions[player]:Save("Player_" .. player.UserId, data, true) end
        sessions[player] = nil
        player:SetAttribute("ProfileStatus", "LoadFailed")
        warn("[PlayerData] Profile normalization failed for " .. player.UserId .. ": " .. tostring(result))
        player:Kick("Your saved progress needs attention. Please rejoin shortly.")
        return nil
    end
    data = result
    self.Data[player] = data

    makeLeaderstats(player, data)
    loading[player] = nil
    released[player] = nil
    player:SetAttribute("ProfileStatus", useDataStore and "Ready" or "StudioSession")

    return data
end

function Service:Get(player)
    if released[player] or closing then return nil end
    local session = sessions[player]
    if session and session.expiresAt and session.expiresAt <= os.time() then
        released[player] = true
        player:Kick("Saving is temporarily unavailable. Please rejoin to protect your progress.")
        return nil
    end
    return self.Data[player]
end

function Service:Save(player, release)
    while saving[player] do task.wait(.05) end
    local profile = self.Data[player]
    if not profile or released[player] then return false, "ProfileNotLoaded" end
    if not useDataStore then return true, "StudioSession" end
    local session = sessions[player]
    if not session then return false, "SessionMissing" end
    saving[player] = true
    local callOk, ok, reason = pcall(session.Save, session, "Player_" .. player.UserId, profile, release)
    saving[player] = nil
    if not callOk then reason, ok = tostring(ok), false end
    if ok then
        player:SetAttribute("LastProfileSave", os.time())
        player:SetAttribute("ProfileStatus", release and "Released" or "Ready")
        if release then released[player] = true end
    else
        player:SetAttribute("ProfileStatus", "SaveFailed")
        warn("[PlayerData] Save failed for " .. player.UserId .. ": " .. tostring(reason))
        if reason == "SessionLost" then
            released[player] = true
            player:Kick("Your profile session changed. Please rejoin to protect your progress.")
        end
    end
    return ok, reason
end

function Service:AddCoins(player, amount)
    local profile = self:Get(player)
    if not profile or not Schema.ValidAmount(amount) then return nil end
    if not Schema.ValidAmount(profile.Coins) or amount > Schema.MaxCurrency - profile.Coins then return nil end
    profile.Coins += amount
    syncLeaderstats(player)
    return profile.Coins
end

function Service:AddGems(player, amount)
    local profile = self:Get(player)
    if not profile or not Schema.ValidAmount(amount) then return nil end
    if not Schema.ValidAmount(profile.Gems) or amount > Schema.MaxCurrency - profile.Gems then return nil end
    profile.Gems += amount
    syncLeaderstats(player)
    return profile.Gems
end

function Service:SpendCoins(player, amount)
    local profile = self:Get(player)
    if not profile or not Schema.ValidAmount(amount) or not Schema.ValidAmount(profile.Coins)
        or profile.Coins < amount then return false end
    profile.Coins -= amount
    syncLeaderstats(player)
    return true
end

function Service:SpendGems(player, amount)
    local profile = self:Get(player)
    if not profile or not Schema.ValidAmount(amount) or not Schema.ValidAmount(profile.Gems)
        or profile.Gems < amount then return false end
    profile.Gems -= amount
    syncLeaderstats(player)
    return true
end

function Service:Cleanup(player)
    local ok = self:Save(player, true)
    if ok or released[player] or not self.Data[player] then
        self.Data[player], sessions[player], released[player] = nil, nil, nil
    else
        -- Keep the profile available for autosave/shutdown retries after a disconnect.
        warn("[PlayerData] Retaining unsaved profile for retry: " .. player.UserId)
    end
end

task.spawn(function()
    while not closing do
        task.wait(45)
        if closing then break end
        for player in pairs(Service.Data) do
            task.spawn(function()
                if player.Parent == Players then Service:Save(player)
                else Service:Cleanup(player) end
            end)
            task.wait(.2)
        end
    end
end)

game:BindToClose(function()
    closing = true
    local pending = 0
    for player in pairs(Service.Data) do
        pending += 1
        task.spawn(function()
            Service:Cleanup(player)
            pending -= 1
        end)
    end
    local deadline = os.clock() + 25
    while (pending > 0 or next(loading) ~= nil) and os.clock() < deadline do task.wait(.1) end
end)

return Service
