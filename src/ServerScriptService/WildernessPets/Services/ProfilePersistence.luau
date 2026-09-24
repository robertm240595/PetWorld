-- Atomic session ownership prevents two current-version servers saving one profile.
local Schema = require(script.Parent.ProfileSchema)
local Persistence = {}
Persistence.__index = Persistence
function Persistence.new(store, token, clock, sleep)
    return setmetatable({store=store, token=token, clock=clock or os.time,
        sleep=sleep or task.wait, lease=180}, Persistence)
end
function Persistence:Update(key, transform)
    local lastError
    for attempt=1,3 do
        local ok, result = pcall(function() return self.store:UpdateAsync(key, transform) end)
        if ok then return true, result end
        lastError = result
        if attempt < 3 then self.sleep(attempt) end
    end
    return false, nil, tostring(lastError)
end
function Persistence:Acquire(key)
    local reason
    local ok, result, err = self:Update(key, function(old, info)
        reason = nil
        if old ~= nil and type(old) ~= "table" then reason="InvalidProfile"; return nil end
        local lock = old and old._ProfileSession
        if type(lock) == "table" and lock.Token ~= self.token
            and (tonumber(lock.ExpiresAt) or 0) > self.clock() then
            reason="SessionLocked"; return nil
        end
        local valid, profile = pcall(Schema.Migrate, old)
        if not valid then reason="InvalidProfile: " .. tostring(profile); return nil end
        profile._ProfileSession = {Token=self.token, ExpiresAt=self.clock()+self.lease}
        return profile, info and info:GetUserIds(), info and info:GetMetadata()
    end)
    if not ok then return nil, "LoadFailed: " .. tostring(err) end
    if not result or not result._ProfileSession or result._ProfileSession.Token ~= self.token then
        return nil, reason or "SessionLocked"
    end
    self.expiresAt = result._ProfileSession.ExpiresAt
    result = Schema.Copy(result)
    result._ProfileSession = nil
    return result
end
function Persistence:Save(key, data, release)
    local snapshot = Schema.Copy(data)
    local reason
    local ok, result, err = self:Update(key, function(old, info)
        reason = nil
        if type(old) ~= "table" or type(old._ProfileSession) ~= "table"
            or old._ProfileSession.Token ~= self.token then
            -- A retry after a successful release may observe the already committed write.
            if release and type(old) == "table" and old._LastReleaseToken == self.token then
                return old, info and info:GetUserIds(), info and info:GetMetadata()
            end
            reason="SessionLost"; return nil
        end
        local nextData = Schema.Copy(snapshot)
        if release then nextData._ProfileSession = nil
        else nextData._ProfileSession = {Token=self.token, ExpiresAt=self.clock()+self.lease} end
        nextData._LastReleaseToken = release and self.token or nil
        nextData.LastSavedAt = self.clock()
        return nextData, info and info:GetUserIds(), info and info:GetMetadata()
    end)
    if not ok then return false, "SaveFailed: " .. tostring(err) end
    if result == nil then return false, reason or "SessionLost" end
    if result._ProfileSession then self.expiresAt = result._ProfileSession.ExpiresAt end
    return true
end
return Persistence
