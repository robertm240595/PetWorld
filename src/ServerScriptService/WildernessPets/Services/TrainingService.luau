-- Single training entry point; existing workbench sessions and timing remain authoritative.
local Village=require(script.Parent.VillageUpgradeService)
local Service={}
function Service:GetState(player) return Village:GetState(player) end
function Service:Assign(player,petId) return Village:Assign(player,petId) end
function Service:Remove(player,petId) return Village:Remove(player,petId) end
function Service:BuySlot(player) return Village:BuyTrainingSlot(player) end
return Service
