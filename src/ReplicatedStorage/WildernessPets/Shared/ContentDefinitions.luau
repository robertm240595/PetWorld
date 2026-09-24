-- Stable IDs use existing saved keys. Change DisplayName, never a published Id.
local Shared = script.Parent
local Config = require(Shared.Config)
local Abilities = require(Shared.PetAbilities)
local Quests = require(Shared.QuestConfig)
local Achievements = require(Shared.AchievementConfig)
local Skins = require(Shared.LassoSkinConfig)
local Mastery = require(Shared.MasteryConfig)
local Village = require(Shared.VillageConfig)
local Definitions = {Version=1, Categories={}}
local function add(category, key, source)
    local group = Definitions.Categories[category] or {}
    Definitions.Categories[category] = group
    local id = category .. "/" .. tostring(key)
    assert(not group[id], "Duplicate content ID: " .. id)
    group[id] = table.freeze({
        Id=id, LegacyKey=key, DisplayName=source.Name or source.Title or tostring(key),
        Rarity=source.Rarity, Gameplay=source,
        Presentation=table.freeze({
            Model=source.Model or source.ModelId,
            Generator=(category=="Pets" or category=="Mounts" or category=="Bosses") and "PetModelFactory" or nil,
            AnimationSpecies=source.AnimationSpecies,
            Icon=source.Icon or source.IconId,
            Animations=source.Animations, Audio=source.Audio,
            -- Unauthored media stays absent; do not invent asset IDs.
        }),
    })
end
local sources={Pets=Config.Pets,Mounts=Config.Mounts,Lassos=Config.Lassos,
    Rarities=Config.Rarities,LassoSkins=Skins.Skins,Quests=Quests.Chains,
    Achievements=Achievements.ById,Mastery=Mastery.ById,Backpacks=Config.Backpacks,Potions=Config.Potions}
for category,entries in pairs(sources) do for key,source in pairs(entries) do add(category,key,source) end end
for species,slots in pairs(Abilities.Pets) do
    for slot,source in ipairs(slots) do add("Abilities",species.."/"..slot,source) end
end
for species,source in pairs(Config.Pets) do
    if source.SpawnMode=="WorldBoss" or source.SpawnMode=="MiniBoss" or source.Boss then add("Bosses",species,source) end
end
for _,reward in ipairs(Config.CollectionMilestones or {}) do add("Rewards","collection/"..reward.Required,reward) end
for _,quest in pairs(Quests.Chains) do
    if quest.Reward then add("Rewards","quest/"..quest.Id,quest.Reward) end
end
for _,category in ipairs({"Lassos","Backpacks","Potions"}) do
    for key,source in pairs(sources[category]) do
        add("Shops",category.."/"..key,{Name=source.Name or key,Coins=source.Coins or 0,Gems=source.Gems or 0,
            ContentId=category.."/"..key,QuestReward=source.QuestReward==true})
    end
end
for key,source in pairs(require(Shared.BossDefinitions)) do
    add("Bosses",key,source)
    for _,phase in ipairs(source.Phases) do add("BossPhases",key.."/"..phase.Id,phase) end
end
Definitions.Products=require(Shared.ProductDefinitions)
Definitions.Roles=table.freeze({
    Tank=table.freeze({Id="role/tank",DisplayName="Tank"}),
    DPS=table.freeze({Id="role/dps",DisplayName="DPS"}),
    Healer=table.freeze({Id="role/healer",DisplayName="Healer"}),
    Support=table.freeze({Id="role/support",DisplayName="Support"}),
    Control=table.freeze({Id="role/control",DisplayName="Control"}),
    Hybrid=table.freeze({Id="role/hybrid",DisplayName="Hybrid"}),
})
Definitions.Training=Village
Definitions.WorldBossRewards=Config.WorldBossRewards
Definitions.Duels=table.freeze({Enabled=false,RequiresConsent=true})
function Definitions.Get(category, idOrLegacyKey)
    local group=Definitions.Categories[category]
    if not group or type(idOrLegacyKey)~="string" then return nil end
    return group[idOrLegacyKey] or group[category.."/"..idOrLegacyKey]
end
function Definitions.Validate()
    local count=0
    for category,entries in pairs(Definitions.Categories) do
        for id,entry in pairs(entries) do
            assert(id==entry.Id and type(entry.DisplayName)=="string","Invalid content definition")
            if entry.Rarity then assert(Config.Rarities[entry.Rarity],"Unknown rarity: "..id) end
            count+=1
        end
    end
    for species in pairs(Abilities.Pets) do assert(Config.Pets[species],"Ability species missing: "..species) end
    return count
end
return Definitions
