local Players=game:GetService("Players")
local DataService=require(script.Parent.Parent.Services.PlayerDataService)
local PetService=require(script.Parent.Parent.Services.PetService)
local Animator=require(script.Parent.PetAnimator)
local plots=workspace:WaitForChild("WildernessPets"):WaitForChild("Plots")
local templates=game.ServerStorage.WildernessPets.Monsters
local refresh=script.Parent:FindFirstChild("PetDisplayRefresh")
if not refresh then refresh=Instance.new("BindableEvent") refresh.Name="PetDisplayRefresh" refresh.Parent=script.Parent end
local states={} local rng=Random.new(12091)

local function clear(player)
 local state=states[player]
 if state then
  for _,m in ipairs(state.models) do if m.Parent then m:Destroy() end end
  if state.podium and state.podium.Parent then
   for _,key in ipairs({"PetName","PetSpecies","PetRarity","PetLevel"}) do state.podium:SetAttribute(key,nil) end
  end
 end
 states[player]=nil
end

local function make(pet,plot,surface,limit,name,position)
 local template=templates:FindFirstChild(pet.Species)
 if not template then return nil end
 local m=template:Clone() m.Name=name
 for _,v in ipairs(m:GetDescendants()) do
  if v:IsA("BillboardGui") then v:Destroy()
  elseif v:IsA("BasePart") then v.Anchored=true v.CanCollide=false v.CanTouch=false v.CanQuery=false end
 end
 local size=m:GetExtentsSize()
 local maxSize=math.max(size.X,size.Y,size.Z)
 if maxSize>limit then m:ScaleTo(m:GetScale()*limit/maxSize) end
 m:SetAttribute("Species",pet.Species)
 m:SetAttribute("PetId",pet.Id)
 m:SetAttribute("Captured",false) m:SetAttribute("BeingCaptured",false) m:SetAttribute("InCombat",false) m:SetAttribute("Dead",false)
 m:SetAttribute("DisplayGroundY",surface)
 m.Parent=plot
 local r=Animator:_getRig(m)
 if not r then m:Destroy() return nil end
 r.base=CFrame.new(position.X,surface+r.clearance+.06,position.Z)*CFrame.Angles(0,rng:NextNumber()*math.pi*2,0)
 Animator:Stop(m)
 local gui=Instance.new("BillboardGui") gui.Name="PetName" gui.Size=UDim2.fromOffset(160,30) gui.MaxDistance=65 gui.AlwaysOnTop=false gui.SizeOffset=Vector2.new(0,0) gui.DistanceStep=0
 gui.StudsOffsetWorldSpace=Vector3.new(0,m:GetExtentsSize().Y*.55+.7,0) gui.Parent=m.PrimaryPart
 local label=Instance.new("TextLabel") label.BackgroundTransparency=1 label.Size=UDim2.fromScale(1,1) label.Font=Enum.Font.GothamSemibold label.TextSize=14 label.TextStrokeTransparency=.35 label.TextColor3=Color3.fromRGB(247,235,185)
 label.Text=pet.Name.."  Lv."..tostring(pet.Level) label.Parent=gui
 Animator:PlayIdle(m)
 return m
end

local function roam(m,area,podium)
 task.wait(rng:NextNumber(.2,1.5))
 local size=m:GetExtentsSize() local margin=math.max(size.X,size.Z)*.6+2
 local hx=math.max(1,area.Size.X/2-margin) local hz=math.max(1,area.Size.Z/2-margin)
 while m.Parent do
  local target
  for _=1,12 do
   local candidate=area.CFrame:PointToWorldSpace(Vector3.new(rng:NextNumber(-hx,hx),0,rng:NextNumber(-hz,hz)))
   if not podium or Vector2.new(candidate.X-podium.Position.X,candidate.Z-podium.Position.Z).Magnitude>podium.Size.X*.5+margin then target=candidate break end
  end
  if target then
   local start=m.PrimaryPart.Position local d=Vector3.new(target.X-start.X,0,target.Z-start.Z) local safe=true
   if podium and d.Magnitude>.01 then
    local along=math.clamp(Vector3.new(podium.Position.X-start.X,0,podium.Position.Z-start.Z):Dot(d)/d:Dot(d),0,1)
    local near=start+d*along
    safe=Vector2.new(near.X-podium.Position.X,near.Z-podium.Position.Z).Magnitude>podium.Size.X*.5+margin
   end
   if safe then Animator:PlayWalkTo(m,target) end
  end
  task.wait(rng:NextNumber(2,4))
 end
end

local function signature(p)
 return p and table.concat({p.Id,p.Name,p.Species,tostring(p.Level),tostring(p.XP),tostring(p.Rarity),tostring(p.Displayed),tostring(p.Dead),tostring(p.Imprint)},":") or ""
end

local function update(player)
 local data=DataService:Get(player)
 if not data then return end
 local plot=plots:FindFirstChild("Plot_"..tostring(data.SelectedPlot))
 if not plot or tonumber(plot:GetAttribute("OwnerUserId") or plot:GetAttribute("Owner"))~=player.UserId then clear(player) return end
 local best=PetService:GetBestPet(player)
 local displayed=PetService:GetDisplayed(player)

 while #displayed>10 do table.remove(displayed) end
 local podiumPet=PetService:Find(player,data.PodiumPetId)
 if podiumPet and (podiumPet.Id==data.EquippedPetId or podiumPet.Dead) then podiumPet=nil end
 local signatures={} for _,pet in ipairs(displayed) do table.insert(signatures,signature(pet)) end
 local sig=plot.Name.."|"..table.concat(signatures,";").."|P:"..signature(podiumPet)
 local previous=states[player]
 if previous and previous.signature==sig then return end
 clear(player)
 local state={signature=sig,models={}} states[player]=state
 local area=plot:FindFirstChild("PetRoamingArea") local land=plot:FindFirstChild("Land") local podium=plot:FindFirstChild("BestPetPodium")
 state.podium=podium
 if area and land then
  for index,pet in ipairs(displayed) do
   local angle=(index-1)*math.pi*2/math.max(1,#displayed)+rng:NextNumber(-.25,.25)
   local radius=math.min(area.Size.X,area.Size.Z)*.22+((index%3)*2)
   local pos=area.CFrame:PointToWorldSpace(Vector3.new(math.cos(angle)*radius,0,math.sin(angle)*radius))
   local name=index==1 and "DisplayedPet" or "DisplayedPet_"..tostring(index)
   local m=make(pet,plot,land.Position.Y+land.Size.Y/2,10,name,pos)
   if m then table.insert(state.models,m) task.spawn(roam,m,area,podium) end
  end
 end
 if podiumPet and podium then
  local m=make(podiumPet,plot,podium.Position.Y+podium.Size.Y/2,8,"PodiumPet",podium.Position)
  if m then table.insert(state.models,m) end
  podium:SetAttribute("PetName",podiumPet.Name) podium:SetAttribute("PetSpecies",podiumPet.Species) podium:SetAttribute("PetRarity",podiumPet.Rarity) podium:SetAttribute("PetLevel",podiumPet.Level)
 end
end

refresh.Event:Connect(function(player) if player and player.Parent then task.defer(update,player) end end)
Players.PlayerRemoving:Connect(clear)
task.spawn(function()
 while true do
  for _,player in ipairs(Players:GetPlayers()) do
   local ok,err=pcall(update,player)
   if not ok then warn("[WildernessPets] Pet display: "..tostring(err)) end
  end
  task.wait(1)
 end
end)
