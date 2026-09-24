local RemoteGuard = require(game.ServerScriptService.WildernessPets.Services.RemoteGuard)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Root = ReplicatedStorage:WaitForChild("WildernessPets")
local Remotes = Root:WaitForChild("Remotes")

local PartyInviteRemote = Remotes:WaitForChild("PartyInvite")
local PartyActionRemote = Remotes:WaitForChild("PartyAction")
local PartyStateRemote = Remotes:WaitForChild("PartyState")

local Service = {}
local started = false

local MAX_PARTY_SIZE = 6
local INVITE_LIFETIME = 30
local RATE_LIMIT_COOLDOWN = 1.5

-- partyKey -> { key, leader, members = {Player}, createdAt }
local parties = {}
-- Player -> partyKey
local playerParty = setmetatable({}, { __mode = "k" })
-- targetUserId -> { from = Player, partyKey = string, expiresAt = number }
local pendingInvites = {}
-- Player -> os.clock of last remote action
local rateLimits = setmetatable({}, { __mode = "k" })

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------

local function getPartyForPlayer(player)
    local key = playerParty[player]
    return key and parties[key] or nil
end

local function isMember(party, player)
    for _, member in ipairs(party.members) do
        if member == player then
            return true
        end
    end
    return false
end

local function removeMemberFromParty(party, player)
    for i, member in ipairs(party.members) do
        if member == player then
            table.remove(party.members, i)
            return true
        end
    end
    return false
end

local function broadcastPartyState(party, action, extra)
    if not party then return end
    for _, member in ipairs(party.members) do
        if member and member.Parent then
            local memberList = {}
            for _, m in ipairs(party.members) do
                if m and m.Parent then
                    table.insert(memberList, {
                        UserId = m.UserId,
                        Name = m.Name,
                        DisplayName = m.DisplayName,
                        IsLeader = m == party.leader,
                    })
                end
            end
            PartyStateRemote:FireClient(member, action, {
                PartyKey = party.key,
                Members = memberList,
                LeaderUserId = party.leader and party.leader.UserId or 0,
                Extra = extra,
            })
        end
    end
end

local function disbandParty(party, reason)
    if not party then return end
    local key = party.key
    for _, member in ipairs(party.members) do
        playerParty[member] = nil
    end
    parties[key] = nil
    for _, member in ipairs(party.members) do
        if member and member.Parent then
            PartyStateRemote:FireClient(member, "Disbanded", {
                PartyKey = key,
                Reason = reason or "Party disbanded.",
            })
        end
    end
end

local function transferLeadership(party, newLeader)
    if not party then return end
    party.leader = newLeader
    broadcastPartyState(party, "LeaderChanged", {
        NewLeaderUserId = newLeader.UserId,
        NewLeaderName = newLeader.Name,
    })
end

local function checkRateLimit(player)
    local now = os.clock()
    local last = rateLimits[player]
    if last and (now - last) < RATE_LIMIT_COOLDOWN then
        return false
    end
    rateLimits[player] = now
    return true
end

local function clearInvitesFor(player)
    local toRemove = {}
    for targetUserId, invite in pairs(pendingInvites) do
        if invite.from == player then
            table.insert(toRemove, targetUserId)
        end
    end
    for _, targetUserId in ipairs(toRemove) do
        local invite = pendingInvites[targetUserId]
        pendingInvites[targetUserId] = nil
        local target = Players:GetPlayerByUserId(targetUserId)
        if target and target.Parent then
            PartyStateRemote:FireClient(target, "InviteExpired", {
                FromUserId = player.UserId,
            })
        end
    end
end

local function clearInvitesTo(player)
    local userId = player.UserId
    local invite = pendingInvites[userId]
    if invite then
        pendingInvites[userId] = nil
    end
end

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

function Service:GetParty(player)
    local party = getPartyForPlayer(player)
    return party and party.key or nil
end

function Service:GetMembers(player)
    local party = getPartyForPlayer(player)
    if not party then return {} end
    local result = {}
    for _, member in ipairs(party.members) do
        if member and member.Parent then
            table.insert(result, member)
        end
    end
    return result
end

function Service:ArePartyMembers(a, b)
    local keyA = playerParty[a]
    local keyB = playerParty[b]
    return keyA ~= nil and keyA == keyB
end

function Service:IsLeader(player)
    local party = getPartyForPlayer(player)
    return party ~= nil and party.leader == player
end

function Service:GetPartyKey(player)
    return playerParty[player]
end

function Service:Invite(player, targetUserId)
    if not checkRateLimit(player) then
        return false, "Slow down."
    end

    local target = Players:GetPlayerByUserId(tonumber(targetUserId) or 0)
    if not target or target == player then
        return false, "That player is unavailable."
    end

    -- Sender must not already be in a different party than target
    local senderParty = getPartyForPlayer(player)
    if senderParty and #senderParty.members >= MAX_PARTY_SIZE then
        return false, "Your party is full."
    end

    -- Target must not already be in a party
    if playerParty[target] then
        return false, "That player is already in a party."
    end

    -- No duplicate invites
    local existingInvite = pendingInvites[target.UserId]
    if existingInvite and existingInvite.from == player then
        return false, "You already invited that player."
    end

    -- If sender has no party, create one
    if not senderParty then
        local key = HttpService:GenerateGUID(false)
        senderParty = {
            key = key,
            leader = player,
            members = { player },
            createdAt = os.clock(),
        }
        parties[key] = senderParty
        playerParty[player] = key
        broadcastPartyState(senderParty, "Created")
    end

    -- Store invite
    pendingInvites[target.UserId] = {
        from = player,
        partyKey = senderParty.key,
        expiresAt = os.clock() + INVITE_LIFETIME,
    }

    -- Notify target
    PartyStateRemote:FireClient(target, "InviteReceived", {
        FromUserId = player.UserId,
        FromName = player.Name,
        FromDisplayName = player.DisplayName,
        PartyKey = senderParty.key,
        PartySize = #senderParty.members,
        MaxSize = MAX_PARTY_SIZE,
    })

    -- Auto-expire
    task.delay(INVITE_LIFETIME, function()
        local invite = pendingInvites[target.UserId]
        if invite and invite.from == player and invite.partyKey == senderParty.key then
            pendingInvites[target.UserId] = nil
            if player and player.Parent then
                PartyStateRemote:FireClient(player, "InviteExpired", {
                    TargetUserId = target.UserId,
                })
            end
            if target and target.Parent then
                PartyStateRemote:FireClient(target, "InviteExpired", {
                    FromUserId = player.UserId,
                })
            end
        end
    end)

    return true, "Invite sent to " .. target.Name .. "."
end

function Service:Accept(player)
    if not checkRateLimit(player) then
        return false, "Slow down."
    end

    -- Must not already be in a party
    if playerParty[player] then
        return false, "You are already in a party."
    end

    local invite = pendingInvites[player.UserId]
    if not invite then
        return false, "No pending invite."
    end

    -- Check expiry
    if os.clock() > invite.expiresAt then
        pendingInvites[player.UserId] = nil
        return false, "That invite has expired."
    end

    -- Validate inviter still exists and party still exists
    if not invite.from or not invite.from.Parent then
        pendingInvites[player.UserId] = nil
        return false, "The inviting player left."
    end

    local party = parties[invite.partyKey]
    if not party then
        pendingInvites[player.UserId] = nil
        return false, "That party no longer exists."
    end

    if #party.members >= MAX_PARTY_SIZE then
        pendingInvites[player.UserId] = nil
        return false, "That party is now full."
    end

    -- Accept
    pendingInvites[player.UserId] = nil
    table.insert(party.members, player)
    playerParty[player] = party.key

    broadcastPartyState(party, "MemberJoined", {
        JoinedUserId = player.UserId,
        JoinedName = player.Name,
    })

    return true, "You joined the party."
end

function Service:Decline(player)
    if not checkRateLimit(player) then
        return false, "Slow down."
    end

    local invite = pendingInvites[player.UserId]
    if not invite then
        return false, "No pending invite."
    end

    pendingInvites[player.UserId] = nil

    if invite.from and invite.from.Parent then
        PartyStateRemote:FireClient(invite.from, "InviteDeclined", {
            TargetUserId = player.UserId,
            TargetName = player.Name,
        })
    end

    return true, "Invite declined."
end

function Service:Leave(player)
    if not checkRateLimit(player) then
        return false, "Slow down."
    end

    local party = getPartyForPlayer(player)
    if not party then
        return false, "You are not in a party."
    end

    removeMemberFromParty(party, player)
    playerParty[player] = nil
    clearInvitesFor(player)
    clearInvitesTo(player)

    -- If only one member left, disband
    if #party.members <= 1 then
        disbandParty(party, "Not enough members to continue.")
        return true, "You left the party."
    end

    -- If leader left, transfer leadership
    if party.leader == player then
        transferLeadership(party, party.members[1])
    end

    broadcastPartyState(party, "MemberLeft", {
        LeftUserId = player.UserId,
        LeftName = player.Name,
    })

    PartyStateRemote:FireClient(player, "Left", {
        PartyKey = party.key,
    })

    return true, "You left the party."
end

function Service:Kick(player, targetUserId)
    if not checkRateLimit(player) then
        return false, "Slow down."
    end

    local party = getPartyForPlayer(player)
    if not party then
        return false, "You are not in a party."
    end

    if party.leader ~= player then
        return false, "Only the leader can kick members."
    end

    local target = Players:GetPlayerByUserId(tonumber(targetUserId) or 0)
    if not target or target == player then
        return false, "Invalid target."
    end

    if not isMember(party, target) then
        return false, "That player is not in your party."
    end

    removeMemberFromParty(party, target)
    playerParty[target] = nil
    clearInvitesFor(target)
    clearInvitesTo(target)

    -- If only one member left after kick, disband
    if #party.members <= 1 then
        disbandParty(party, "Not enough members to continue.")
        return true, target.Name .. " was kicked."
    end

    broadcastPartyState(party, "MemberKicked", {
        KickedUserId = target.UserId,
        KickedName = target.Name,
    })

    if target and target.Parent then
        PartyStateRemote:FireClient(target, "Kicked", {
            PartyKey = party.key,
        })
    end

    return true, target.Name .. " was kicked from the party."
end

function Service:PlayerRemoving(player)
    local party = getPartyForPlayer(player)
    if not party then
        clearInvitesFor(player)
        clearInvitesTo(player)
        return
    end

    removeMemberFromParty(party, player)
    playerParty[player] = nil
    clearInvitesFor(player)
    clearInvitesTo(player)

    if #party.members <= 1 then
        disbandParty(party, "Not enough members to continue.")
        return
    end

    if party.leader == player then
        transferLeadership(party, party.members[1])
    end

    broadcastPartyState(party, "MemberLeft", {
        LeftUserId = player.UserId,
        LeftName = player.Name,
    })
end

function Service:Init()
    if started then return end
    started = true

    RemoteGuard.Connect(PartyInviteRemote, "PartyInvite", function(player, action, ...)
        local args = { ... }

        if action == "Invite" then
            local success, message = Service:Invite(player, args[1])
            PartyInviteRemote:FireClient(player, "InviteResult", success, message)

        elseif action == "Accept" then
            local success, message = Service:Accept(player)
            PartyInviteRemote:FireClient(player, "AcceptResult", success, message)

        elseif action == "Decline" then
            local success, message = Service:Decline(player)
            PartyInviteRemote:FireClient(player, "DeclineResult", success, message)
        end
    end)

    RemoteGuard.Connect(PartyActionRemote, "PartyAction", function(player, action, ...)
        local args = { ... }

        if action == "Leave" then
            local success, message = Service:Leave(player)
            PartyActionRemote:FireClient(player, "LeaveResult", success, message)

        elseif action == "Kick" then
            local success, message = Service:Kick(player, args[1])
            PartyActionRemote:FireClient(player, "KickResult", success, message)
        end
    end)
end

return Service