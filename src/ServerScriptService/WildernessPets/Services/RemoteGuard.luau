local Players=game:GetService("Players")
local Data=require(script.Parent.PlayerDataService)
local Schema=require(script.Parent.ProfileSchema)
local Guard={Contracts={["Pets"]={["Rename"]={"string","string"},["Upgrade"]={"string","string"},["Favourite"]={"string","boolean"},["SetAura"]={"string","string"},["Display"]={"string"},["Hide"]={"string"},["Podium"]={"string"},["Equip"]={"string"},["Unequip"]={},["EquipMount"]={"string"},["UnequipMount"]={},["FavouriteMount"]={"string","boolean"},["EquipLassoSkin"]={"string"},["UnequipLassoSkin"]={},["ClaimCollectionReward"]={}},["Shop"]={["BuyLasso"]={"string"},["SellLasso"]={"string"},["BuybackLasso"]={"integer"},["EquipLasso"]={"string"},["SellPet"]={"string"},["BuybackPet"]={"integer"},["SellLootItem"]={"table"},["SellAllLoot"]={},["BuyBackpack"]={"string"},["BuyPotion"]={"string"},["UsePotion"]={"string","string?"},["StartHealing"]={"string"},["CollectHealed"]={"string"}},["Arena"]={["SetDefence"]={"string"},["GetOpponents"]={},["Attack"]={"integer"}},["Game"]={["CombatSelect"]={"target?"},["CombatAction"]={"string"},["ReturnToPlot"]={}},["Capture"]={["Throw"]={"target"},["Resolve"]={"string","number"}},["Quest"]={["RequestState"]={},["Action"]={"string"}},["Trade"]={["Request"]={"integer"},["Respond"]={"string","boolean"},["SetOffer"]={"string","table"},["Confirm"]={"string"},["Cancel"]={}},["Loot"]={["Collect"]={"table"}},["BossLoot"]={["Collect"]={"string"},["UseRewardItem"]={"string","string"}},["PartyInvite"]={["Invite"]={"integer"},["Accept"]={},["Decline"]={}},["PartyAction"]={["Leave"]={},["Kick"]={"integer"}},["VillageSelection"]={["SelectVillage"]={"integer"}},["Auction"]={["List"]={"string","string","integer","integer"},["Buy"]={"string"},["Cancel"]={"string"},["Claim"]={"string"}},["VillageUpgrade"]={["UpgradeHealing"]={},["UpgradeTraining"]={},["BuyTrainingSlot"]={},["Assign"]={"string"},["Remove"]={"string"}}},Rejected=0,Errors=0,Bindings={}}
local buckets=setmetatable({},{__mode="k"})
local busy=setmetatable({},{__mode="k"})
local function bounded(value, depth, budget, seen)
    budget.n+=1
    if budget.n>256 or depth>5 then return false end
    local kind=typeof(value)
    if kind=="nil" or kind=="boolean" then return true end
    if kind=="number" then return Schema.IsFinite(value) end
    if kind=="string" then return #value<=512 and utf8.len(value)~=nil end
    if kind=="Instance" then return value:IsA("Model") and value:IsDescendantOf(workspace) end
    if kind~="table" or seen[value] then return false end
    seen[value]=true
    for key,item in pairs(value) do
        if (type(key)~="string" and type(key)~="number") or not bounded(key,depth+1,budget,seen)
            or not bounded(item,depth+1,budget,seen) then return false end
    end
    seen[value]=nil
    return true
end
function Guard.Validate(channel, action, ...)
    local contract=Guard.Contracts[channel] and Guard.Contracts[channel][action]
    if not contract then return false end
    local args=table.pack(...)
    if args.n>#contract or not bounded(args,0,{n=0},{}) then return false end
    for i,expected in ipairs(contract) do
        local optional=string.sub(expected,-1)=="?"
        if optional then expected=string.sub(expected,1,-2) end
        local value=args[i]
        if value==nil then if not optional then return false end
        elseif expected=="integer" then if not Schema.ValidAmount(value) then return false end
        elseif expected=="target" then
            local world=workspace:FindFirstChild("WildernessPets")
            local monsters=world and world:FindFirstChild("WildMonsters")
            if typeof(value)~="Instance" or not value:IsA("Model") or not monsters or not value:IsDescendantOf(monsters) then return false end
        elseif type(value)~=expected then return false end
    end
    return true
end
function Guard.Allow(player, channel)
    if not Data:Get(player) or player:GetAttribute("ProfileStatus")=="Released" then return false end
    local perPlayer=buckets[player] or {}; buckets[player]=perPlayer
    local now=os.clock()
    local bucket=perPlayer[channel] or {tokens=20,at=now}; perPlayer[channel]=bucket
    bucket.tokens=math.min(20,bucket.tokens+(now-bucket.at)*8); bucket.at=now
    if bucket.tokens<1 then return false end
    bucket.tokens-=1
    return true
end
function Guard.Connect(remote, channel, callback)
    Guard.Bindings[remote:GetFullName()]=channel
    return remote.OnServerEvent:Connect(function(player,action,...)
        if type(action)~="string" or not Guard.Allow(player,channel) or not Guard.Validate(channel,action,...) then
            Guard.Rejected+=1; return
        end
        local active=busy[player] or {}; busy[player]=active
        -- Serialize yielding economy operations across menus for this player.
        local key=(channel=="Trade" or channel=="Shop" or channel=="Pets" or channel=="Auction") and "Economy" or channel
        if active[key] then Guard.Rejected+=1; return end
        active[key]=true
        local ok,err=pcall(callback,player,action,...)
        active[key]=nil
        if not ok then Guard.Errors+=1; warn("[RemoteGuard] "..channel..": "..tostring(err)) end
    end)
end
Players.PlayerRemoving:Connect(function(player) buckets[player]=nil; busy[player]=nil end)
return Guard
