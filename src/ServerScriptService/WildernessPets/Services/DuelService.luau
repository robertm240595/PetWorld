-- Phase 1 contract only. Consent, combat and UI are implemented in the PvP phase.
local Definitions=require(game.ReplicatedStorage.WildernessPets.Shared.ContentDefinitions)
local Data=require(script.Parent.PlayerDataService)
local Service={}
function Service:IsEnabled() return Definitions.Duels.Enabled end
function Service:GetStats(player)
    local data=Data:Get(player)
    if not data then return nil end
    return table.clone(data.DuelStats)
end
function Service:Request(player,target)
    if not self:IsEnabled() then return false,"Duels are not available yet." end
    return false,"Duel combat is not configured."
end
return Service
