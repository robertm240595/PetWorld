local Data=require(script.Parent.PlayerDataService)
local Definitions=require(game.ReplicatedStorage.WildernessPets.Shared.ContentDefinitions)
local AuraConfig=require(game.ReplicatedStorage.WildernessPets.Shared.MasteryConfig)
local Service={}
function Service:GetUnlocked(level) return AuraConfig.GetUnlocked(level) end
function Service:IsUnlocked(level,id) return AuraConfig.IsUnlocked(level,id) end
function Service:GetState(player,petId)
    local data=Data:Get(player); if not data then return nil end
    for _,pet in ipairs(data.Pets) do if pet.Id==petId then
        return {PetId=petId,Level=pet.Level,SelectedAura=pet.SelectedAura or "None",
            UnlockedAuras=AuraConfig.GetUnlocked(pet.Level),
            RoleProgress=data.PetMastery[petId] or {},Roles=Definitions.Roles}
    end end
    return nil
end
return Service
