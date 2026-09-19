local Config=require(game.ReplicatedStorage.WildernessPets.Shared.Config)
local Animator=require(script.Parent.Parent.Systems.PetAnimator)
local ModelFactory=require(script.Parent.Parent.Systems.PetModelFactory)
local WildArea=require(script.Parent.Parent.Systems.WildArea)
local Players=game:GetService("Players")
local Service={}
local rng=Random.new()
local slots={}
local started=false
local world,folder
local function now() return workspace:GetServerTimeNow() end
function Service:GetHour(at)
 local epoch=world and world:GetAttribute("CycleEpoch") or now()
 return (Config.WorldCycle.StartHour+( (at or now())-epoch)*24/Config.WorldCycle.DurationSeconds)%24
end
function Service:IsNight(at)
 local hour=self:GetHour(at)
 return hour>=Config.WorldCycle.NightStart or hour<Config.WorldCycle.NightEnd
end
function Service:GetPool(night)
 local pool={}
 for name,info in pairs(Config.Pets) do
  if info.SpawnMode=="Wild"
   and info.TimeOfDay==(night and "Night" or "Day")
   and ModelFactory:CanCreate(name) then
   pool[info.Rarity]=pool[info.Rarity] or {}
   table.insert(pool[info.Rarity],name)
  end
 end
 for _,names in pairs(pool) do table.sort(names) end
 return pool
end
function Service:GetRarity(night,random)
 local pool=self:GetPool(night==nil and self:IsNight() or night)
 local total=0 local ordered={}
 for rarity,names in pairs(pool) do
  local info=Config.Rarities[rarity]
  if #names>0 and info and info.Weight>0 then total+=info.Weight table.insert(ordered,rarity) end
 end
 table.sort(ordered,function(a,b) return Config.Rarities[a].Rank<Config.Rarities[b].Rank end)
 if total==0 then return nil end
 local roll=(random or rng):NextNumber()*total
 for _,rarity in ipairs(ordered) do
  roll-=Config.Rarities[rarity].Weight
  if roll<0 then return rarity end
 end
 return ordered[#ordered]
end
function Service:GetSpecies(rarity,night,random)
 local pool=self:GetPool(night==nil and self:IsNight() or night)
 local names=pool[rarity]
 if not names or #names==0 then return nil end
 return names[(random or rng):NextInteger(1,#names)]
end
function Service:GetMountPool(night)
 local pool={}
 for name,info in pairs(Config.Mounts or {}) do
  if info.SpawnMode=="Wild"
   and info.TimeOfDay==(night and "Night" or "Day")
   and ModelFactory:CanCreate(name) then
   pool[info.Rarity]=pool[info.Rarity] or {}
   table.insert(pool[info.Rarity],name)
  end
 end
 for _,names in pairs(pool) do table.sort(names) end
 return pool
end

function Service:GetSpawnChoice(night,random)
 local roller=random or rng
 local petPool=self:GetPool(night)
 local mountPool=self:GetMountPool(night)
 local choices={}
 local total=0

 for rarity,names in pairs(petPool) do
  local rarityInfo=Config.Rarities[rarity]
  local weight=rarityInfo and tonumber(rarityInfo.Weight) or 0
  if #names>0 and weight>0 then
   total+=weight
   table.insert(choices,{Kind="Pet",Rarity=rarity,Names=names,Weight=weight})
  end
 end

 for rarity,names in pairs(mountPool) do
  local weight=tonumber((Config.MountRarityWeights or {})[rarity]) or 0
  if #names>0 and weight>0 then
   total+=weight
   table.insert(choices,{Kind="Mount",Rarity=rarity,Names=names,Weight=weight})
  end
 end

 if total<=0 then return nil end
 local roll=roller:NextNumber()*total
 table.sort(choices,function(a,b)
  local ar=(Config.Rarities[a.Rarity] and Config.Rarities[a.Rarity].Rank) or 99
  local br=(Config.Rarities[b.Rarity] and Config.Rarities[b.Rarity].Rank) or 99
  if ar==br then return a.Kind<b.Kind end
  return ar<br
 end)

 for _,choice in ipairs(choices) do
  roll-=choice.Weight
  if roll<0 then
   return choice.Kind,choice.Names[roller:NextInteger(1,#choice.Names)],choice.Rarity
  end
 end

 local last=choices[#choices]
 return last.Kind,last.Names[roller:NextInteger(1,#last.Names)],last.Rarity
end

local function nearPlayer(pos,radius)
 for _,player in Players:GetPlayers() do
  local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
  if root and (root.Position-pos).Magnitude<radius then return true end
 end
 return false
end
local function spawnPosition()
 local params=RaycastParams.new()
 params.FilterType=Enum.RaycastFilterType.Include
 params.FilterDescendantsInstances={workspace.Terrain}

 local spawn=Config.WildSpawn or {}
 local minRadius=math.max(0,tonumber(spawn.MinRadius) or 175)
 local attempts=math.max(20,math.floor(tonumber(spawn.Attempts) or 120))

 for _=1,attempts do
  -- Sample the full accessible wilderness rectangle instead of a circular
  -- 640-stud ring. Runtime perimeter detection keeps these points inside the
  -- map's invisible barrier walls when those walls are present.
  local x,z=WildArea:RandomXZ(rng,minRadius)
  if x and z then
   local safe=true

   for _,plot in world.Plots:GetChildren() do
    local land=plot:FindFirstChild("Land")
    if land then
     local p=land.CFrame:PointToObjectSpace(Vector3.new(x,land.Position.Y,z))
     if math.abs(p.X)<land.Size.X/2+24 and math.abs(p.Z)<land.Size.Z/2+24 then
      safe=false
      break
     end
    end
   end

   if safe then
    local hit=workspace:Raycast(Vector3.new(x,350,z),Vector3.new(0,-750,0),params)
    if hit
     and hit.Normal.Y>.78
     and hit.Material~=Enum.Material.Water
     and WildArea:ContainsXZ(hit.Position.X,hit.Position.Z)
     and not nearPlayer(hit.Position,Config.Respawn.SafePlayerRadius) then
     return hit.Position
    end
   end
  end
 end

 return nil
end
local rarityColors={Common=Color3.fromRGB(220,228,218),Uncommon=Color3.fromRGB(114,220,142),Rare=Color3.fromRGB(109,181,255),Epic=Color3.fromRGB(193,136,255),Legendary=Color3.fromRGB(255,204,89),Mythic=Color3.fromRGB(255,126,189),Limited=Color3.fromRGB(141,250,239),Ancient=Color3.fromRGB(255,130,77)}
local function label(model,info)
 local gui=Instance.new("BillboardGui")
 gui.Name="CreatureLabel" gui.Size=UDim2.fromOffset(190,62) gui.MaxDistance=65 gui.AlwaysOnTop=false
 gui.StudsOffsetWorldSpace=Vector3.new(0,model:GetExtentsSize().Y*.55+.8,0)
 gui.Parent=model.PrimaryPart

 local text=Instance.new("TextLabel")
 text.Name="CreatureName"
 text.Position=UDim2.fromOffset(0,0) text.Size=UDim2.new(1,0,0,26) text.BackgroundTransparency=1
 text.Font=Enum.Font.GothamSemibold text.TextSize=15 text.TextStrokeTransparency=.35
 text.TextColor3=rarityColors[info.Rarity] or Color3.new(1,1,1)
 local isMount=model:GetAttribute("CreatureType")=="Mount"
 text.Text=model:GetAttribute("Species").."  ·  "..info.Rarity..(isMount and "  ·  MOUNT" or "")
 text.Parent=gui

 local healthBack=Instance.new("Frame")
 healthBack.Name="HealthBack" healthBack.Position=UDim2.fromOffset(12,31) healthBack.Size=UDim2.fromOffset(166,12)
 healthBack.BackgroundColor3=Color3.fromRGB(58,34,34) healthBack.BorderSizePixel=0 healthBack.Parent=gui
 local backCorner=Instance.new("UICorner") backCorner.CornerRadius=UDim.new(0,4) backCorner.Parent=healthBack

 local fill=Instance.new("Frame")
 fill.Name="Fill" fill.Size=UDim2.fromScale(1,1) fill.BackgroundColor3=Color3.fromRGB(82,183,101) fill.BorderSizePixel=0 fill.Parent=healthBack
 local fillCorner=Instance.new("UICorner") fillCorner.CornerRadius=UDim.new(0,4) fillCorner.Parent=fill

 local value=Instance.new("TextLabel")
 value.Name="Value" value.Position=UDim2.fromOffset(0,45) value.Size=UDim2.new(1,0,0,15)
 value.BackgroundTransparency=1 value.Font=Enum.Font.GothamMedium value.TextSize=10 value.TextStrokeTransparency=.45
 value.TextColor3=Color3.fromRGB(242,232,206) value.Parent=gui

 local function updateHealth()
  if not model.Parent and not model:GetAttribute("Health") then return end
  if model:GetAttribute("CreatureType")=="Mount" then
   healthBack.Visible=false
   value.Text="RIDEABLE  ·  LASSO TO CAPTURE"
   return
  end
  healthBack.Visible=true
  local hp=math.max(0,tonumber(model:GetAttribute("Health")) or 0)
  local maximum=math.max(1,tonumber(model:GetAttribute("MaxHealth")) or hp)
  fill.Size=UDim2.fromScale(math.clamp(hp/maximum,0,1),1)
  value.Text=tostring(math.ceil(hp)).." / "..tostring(math.ceil(maximum)).." HP"
 end

 model:GetAttributeChangedSignal("Health"):Connect(updateHealth)
 model:GetAttributeChangedSignal("MaxHealth"):Connect(updateHealth)
 updateHealth()
end
local function watchDeath(model)
 local dying=false
 local function die()
  if dying or not model.Parent or model:GetAttribute("Captured") then return end
  if not model:GetAttribute("Dead") and (model:GetAttribute("Health") or 1)>0 then return end
  dying=true model:SetAttribute("Dead",true) model:SetAttribute("InCombat",true)
  task.spawn(function()
   local ok,err=pcall(function() Animator:PlayFaint(model,.7) end)
   if not ok then warn("[WildernessPets] Death animation: "..tostring(err)) end
   if model.Parent then model:Destroy() end
  end)
 end
 model:GetAttributeChangedSignal("Health"):Connect(die)
 model:GetAttributeChangedSignal("Dead"):Connect(die)
 local humanoid=model:FindFirstChildOfClass("Humanoid")
 if humanoid then humanoid.Died:Connect(function() model:SetAttribute("Dead",true) end) end
end
function Service:DamageMonster(model,amount)
 if not folder or model.Parent~=folder or model:GetAttribute("Captured") or model:GetAttribute("Dead") then return false end
 if type(amount)~="number" or amount~=amount or amount<=0 or amount==math.huge then return false end
 model:SetAttribute("Health",math.max(0,(model:GetAttribute("Health") or 0)-amount))
 return true
end
function Service:SpawnSlot(index)
 local slot=slots[index]
 if not slot or slot.model and slot.model.Parent then return false end
 local night=self:IsNight()
 local creatureType,name,rarity=self:GetSpawnChoice(night)
 if not name or not rarity then return false end
 local pos=spawnPosition()
 if not pos then slot.readyAt=now()+3 return false end
 local model=ModelFactory:Create(name)
 local info=creatureType=="Mount" and (Config.Mounts or {})[name] or Config.Pets[name]
 if not model or not info then slot.readyAt=now()+5 return false end
 model.Name=name.."_"..index
 for _,p in model:GetDescendants() do if p:IsA("BasePart") then p.Anchored=true p.CanCollide=false p.CanQuery=true end end
 model:SetAttribute("Species",name)
 model:SetAttribute("CreatureType",creatureType)
 model:SetAttribute("AnimationSpecies",info.AnimationSpecies or name)
 model:SetAttribute("Rarity",info.Rarity)
 model:SetAttribute("SpawnPeriod",night and "Night" or "Day")
 model:SetAttribute("SpawnSlot",index)
 model:SetAttribute("CaptureDifficulty",Config.Rarities[info.Rarity].CaptureDifficulty)
 model:SetAttribute("Level",1)
 local rarityRank=(Config.Rarities[info.Rarity] and Config.Rarities[info.Rarity].Rank) or 1
 local health=creatureType=="Mount" and (120+rarityRank*65) or (tonumber(info.Health) or 100)
 local power=creatureType=="Mount" and 0 or (tonumber(info.Power) or 1)
 local defence=creatureType=="Mount" and 0 or (tonumber(info.Defence) or 0)
 model:SetAttribute("Power",power)
 model:SetAttribute("Defence",defence)
 model:SetAttribute("PowerRating",creatureType=="Mount" and 0 or math.ceil((health*power*math.max(1,defence))/1000))
 model:SetAttribute("Health",health) model:SetAttribute("MaxHealth",health)
 model:SetAttribute("QuestNoCombat",creatureType=="Mount")
 model:SetAttribute("Captured",false) model:SetAttribute("BeingCaptured",false)
 model:SetAttribute("InCombat",false) model:SetAttribute("Dead",false)
 local rig=Animator:_getRig(model)
 if not rig then model:Destroy() return false end
 rig.base=CFrame.new(pos+Vector3.new(0,rig.clearance+.06,0))*CFrame.Angles(0,rng:NextNumber()*math.pi*2,0)
 Animator:Stop(model)
 slot.model=model slot.readyAt=math.huge
 label(model,info)
 watchDeath(model)
 model.Parent=folder
 return true
end
function Service:Init()
 if started then return end started=true
 world=workspace:WaitForChild("WildernessPets")
 folder=world:WaitForChild("WildMonsters")
 world:SetAttribute("CycleEpoch",now())
 world:SetAttribute("CycleDuration",Config.WorldCycle.DurationSeconds)
 world:SetAttribute("CycleStartHour",Config.WorldCycle.StartHour)
 world:SetAttribute("IsNight",self:IsNight())
 local barrierInsetApplied=WildArea:InsetPerimeter()
 world:SetAttribute("WildBarrierInsetApplied",barrierInsetApplied)
 local bounds=WildArea:GetBounds(true)
 world:SetAttribute("WildBoundsDetected",bounds.DetectedBarrierBounds==true)
 world:SetAttribute("WildBoundsMinX",bounds.MinX)
 world:SetAttribute("WildBoundsMaxX",bounds.MaxX)
 world:SetAttribute("WildBoundsMinZ",bounds.MinZ)
 world:SetAttribute("WildBoundsMaxZ",bounds.MaxZ)
 -- Replace the editor's static population once; respawns thereafter own one slot each.
 for _,m in folder:GetChildren() do if m:IsA("Model") then m:Destroy() end end
 for i=1,Config.WildMonsterCount do slots[i]={model=nil,readyAt=now()} end
 folder.ChildRemoved:Connect(function(model)
  local index=model:GetAttribute("SpawnSlot")
  local slot=index and slots[index]
  if slot and slot.model==model then
   slot.model=nil
   slot.readyAt=now()+rng:NextNumber(Config.Respawn.MinSeconds,Config.Respawn.MaxSeconds)
  end
 end)
 for i=1,#slots do self:SpawnSlot(i) end
 task.spawn(function()
  local nextTransition=now()
  while world.Parent do
   local night=self:IsNight()
   world:SetAttribute("IsNight",night)
   world:SetAttribute("WorldHour",self:GetHour())
   for i,slot in ipairs(slots) do
    if not slot.model and now()>=slot.readyAt then
     local ok,err=pcall(function() self:SpawnSlot(i) end)
     if not ok then slot.readyAt=now()+5 warn("[WildernessPets] Spawn: "..tostring(err)) end
    end
   end
   if now()>=nextTransition then
    for _,slot in ipairs(slots) do
     local m=slot.model
     if m and m.Parent and m:GetAttribute("SpawnPeriod")~=(night and "Night" or "Day")
       and not m:GetAttribute("BeingCaptured") and not m:GetAttribute("InCombat")
       and not nearPlayer(m.PrimaryPart.Position,55) then
      m:Destroy()
      break
     end
    end
    nextTransition=now()+Config.Respawn.TransitionInterval
   end
   task.wait(.5)
  end
 end)
end
return Service
