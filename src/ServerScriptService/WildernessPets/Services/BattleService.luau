local Animator = require(script.Parent.Parent.Systems.PetAnimator)
local ModelFactory = require(script.Parent.Parent.Systems.PetModelFactory)
local PetService = require(script.Parent.PetService)
local EquipmentConfig = require(game.ReplicatedStorage.WildernessPets.Shared.EquipmentConfig)
local Service = {}
local displaying = false
local function damage(attacker, defender)
 local amount=math.max(1,attacker.Power-defender.Defence*.45)
 if math.random()<.08 then amount*=2 end
 return math.floor(amount)
end
-- Combat calculation remains immediate; this replays the same hits visually.
local function replay(petA,petB,hits,winner)
 if displaying then return end
 displaying=true
 task.spawn(function()
  local folder
  local ok,err=pcall(function()
   local world=workspace:FindFirstChild("WildernessPets")
   local arena=world and world:FindFirstChild("Arena")
   if not arena or not ModelFactory:CanCreate(petA.Species) or not ModelFactory:CanCreate(petB.Species) then return end
   folder=Instance.new("Folder") folder.Name="ArenaAnimation" folder.Parent=world
   local models={}
   for index,pet in {petA,petB} do
    local m=ModelFactory:Create(pet.Species)
    if not m then return end
    m.Name=index==1 and "Attacker" or "Defender"
    m:SetAttribute("Species",pet.Species)
    m.Parent=folder
    local r=Animator:_getRig(m)
    local floor=arena.ArenaFloor
    local pos=floor.Position+Vector3.new(index==1 and -10 or 10,floor.Size.Y/2+r.clearance+.06,0)
    r.base=CFrame.new(pos)*CFrame.Angles(0,index==1 and math.pi/2 or -math.pi/2,0)
    Animator:Stop(m)
    Animator:PlayIdle(m)
    models[index]=m
   end
   for _,hit in hits do
    if not folder.Parent then return end
    local attacker=models[hit.side]
    local defender=models[3-hit.side]
    Animator:PlayAttack(attacker,defender.PrimaryPart.Position,.65,function()
     task.spawn(function() Animator:PlayHit(defender,.22) end)
    end)
    Animator:PlayIdle(attacker)
    Animator:PlayIdle(defender)
    task.wait(.10)
   end
   local win=winner=="A" and 1 or 2
   Animator:PlayFaint(models[3-win],.6)
   Animator:PlayVictory(models[win],.8)
   task.wait(1)
  end)
  if folder then folder:Destroy() end
  displaying=false
  if not ok then warn("[CreatureAnimation] Arena replay: "..tostring(err)) end
 end)
end
function Service:Fight(petA,petB)
 if not petA or not petB then return nil end

 local statsA=PetService:GetEffectiveStats(petA)
 local statsB=PetService:GetEffectiveStats(petB)
 local gearA=EquipmentConfig:GetBonuses(petA)
 local gearB=EquipmentConfig:GetBonuses(petB)

 local hpA,hpB=statsA.Health,statsB.Health
 local intervalA=1/math.max(1,1+(tonumber(gearA.AttackHaste) or 0))
 local intervalB=1/math.max(1,1+(tonumber(gearB.AttackHaste) or 0))
 local nextA,nextB=0,0
 local actions=0
 local hits={}

 while hpA>0 and hpB>0 and actions<200 do
  if nextA<=nextB then
   local dealt=damage(statsA,statsB)
   hpB-=dealt
   local steal=math.max(0,tonumber(gearA.Lifesteal) or 0)
   if steal>0 then hpA=math.min(statsA.Health,hpA+math.floor(dealt*steal+.5)) end
   table.insert(hits,{side=1})
   nextA+=intervalA
  else
   local dealt=damage(statsB,statsA)
   hpA-=dealt
   local steal=math.max(0,tonumber(gearB.Lifesteal) or 0)
   if steal>0 then hpB=math.min(statsB.Health,hpB+math.floor(dealt*steal+.5)) end
   table.insert(hits,{side=2})
   nextB+=intervalB
  end
  actions+=1
 end

 local winner=hpA>hpB and "A" or "B"
 replay(petA,petB,hits,winner)
 return {Winner=winner,Turns=actions}
end
return Service
