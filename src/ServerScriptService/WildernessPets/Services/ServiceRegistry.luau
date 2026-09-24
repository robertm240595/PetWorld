-- Canonical names resolve existing implementations; no duplicate startup or player lifecycle.
local modules={
    PlayerDataService="PlayerDataService",InventoryService="InventoryService",
    PetService="PetService",TrainingService="TrainingService",MasteryService="MasteryService",
    CombatService="PetAbilityService",CaptureService="CaptureService",BossService="BossCombatService",
    MountService="MountService",PlotService="PlotService",TradeService="TradeService",
    PartyService="PartyService",DuelService="DuelService",ShopService="ShopService",
    QuestService="QuestService",AchievementService="AchievementService"}
local Registry={}
function Registry.Get(name)
    local moduleName=modules[name]; assert(moduleName,"Unknown service: "..tostring(name))
    return require(script.Parent[moduleName])
end
function Registry.Validate()
    local names={}
    for name,moduleName in pairs(modules) do
        assert(script.Parent:FindFirstChild(moduleName),"Missing service: "..name)
        table.insert(names,name)
    end
    table.sort(names);return names
end
return Registry
