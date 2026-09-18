local Animator = require(script.Parent.Parent.Systems.PetAnimator)
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
   local templates=game.ServerStorage.WildernessPets.Monsters
   if not arena or not templates:FindFirstChild(petA.Species) or not templates:FindFirstChild(petB.Species) then return end
   folder=Instance.new("Folder") folder.Name="ArenaAnimation" folder.Parent=world
   local models={}
   for index,pet in {petA,petB} do
    local m=templates[pet.Species]:Clone()
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
 local hpA,hpB=petA.Health,petB.Health
 local turn=1
 local hits={}
 while hpA>0 and hpB>0 and turn<=100 do
  hpB-=damage(petA,petB)
  table.insert(hits,{side=1})
  if hpB<=0 then break end
  hpA-=damage(petB,petA)
  table.insert(hits,{side=2})
  if hpA<=0 then break end
  turn+=1
 end
 local winner=hpA>hpB and "A" or "B"
 replay(petA,petB,hits,winner)
 return {Winner=winner,Turns=turn}
end
return Service
