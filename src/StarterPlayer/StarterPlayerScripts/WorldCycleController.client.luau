local Lighting=game:GetService("Lighting")
local RunService=game:GetService("RunService")
local TweenService=game:GetService("TweenService")
local Players=game:GetService("Players")
local world=workspace:WaitForChild("WildernessPets")
local sky=Lighting:FindFirstChildOfClass("Sky")
if not sky then sky=Instance.new("Sky") sky.Parent=Lighting end
sky.CelestialBodiesShown=true sky.SunAngularSize=12 sky.MoonAngularSize=10 sky.StarCount=2200
Lighting.GeographicLatitude=20
local grade=Instance.new("ColorCorrectionEffect") grade.Name="WorldCycleGrade" grade.Parent=Lighting
local gui=Instance.new("ScreenGui") gui.Name="WorldClock" gui.ResetOnSpawn=false gui.DisplayOrder=2
gui.Parent=Players.LocalPlayer:WaitForChild("PlayerGui")
local text=Instance.new("TextLabel")
text.AnchorPoint=Vector2.new(1,0) text.Position=UDim2.new(1,-18,0,8) text.Size=UDim2.fromOffset(210,28)
text.BackgroundColor3=Color3.fromRGB(20,27,43) text.BackgroundTransparency=.22
text.TextColor3=Color3.fromRGB(240,239,222) text.Font=Enum.Font.GothamMedium text.TextSize=14
text.Parent=gui
local corner=Instance.new("UICorner") corner.CornerRadius=UDim.new(0,10) corner.Parent=text
local elapsed=0
RunService.RenderStepped:Connect(function(dt)
 local epoch=world:GetAttribute("CycleEpoch")
 if not epoch then return end
 local duration=world:GetAttribute("CycleDuration") or 720
 local hour=((world:GetAttribute("CycleStartHour") or 9)+(workspace:GetServerTimeNow()-epoch)*24/duration)%24
 Lighting.ClockTime=hour
 local sun=math.sin((hour-6)/24*math.pi*2)
 local daylight=math.clamp((sun+.12)/.38,0,1)
 daylight=daylight*daylight*(3-2*daylight)
 local dusk=math.exp(-(sun/.20)^2)
 Lighting.Brightness=.7+daylight*2.1
 Lighting.Ambient=Color3.fromRGB(40,46,78):Lerp(Color3.fromRGB(112,110,107),daylight)
 Lighting.OutdoorAmbient=Color3.fromRGB(61,74,111):Lerp(Color3.fromRGB(142,145,151),daylight)
 Lighting.ExposureCompensation=-.15+daylight*.15
 grade.TintColor=Color3.fromRGB(180,201,255):Lerp(Color3.new(1,1,1),daylight):Lerp(Color3.fromRGB(255,215,182),dusk*.25)
 grade.Saturation=-.10+daylight*.13
 elapsed+=dt
 if elapsed>.25 then
  elapsed=0
  local minutes=math.floor(hour*60)%1440
  text.Text=string.format("%s  ·  %02d:%02d",(hour>=18 or hour<6) and "NIGHT" or "DAY",math.floor(minutes/60),minutes%60)
 end
end)

-- Unified action bar and creature target frame.
local UIS=game:GetService("UserInputService")
local StarterGui=game:GetService("StarterGui")
local RS=game:GetService("ReplicatedStorage")
local player=Players.LocalPlayer
local remotes=RS.WildernessPets.Remotes
local config=require(RS.WildernessPets.Shared.Config)
local playerGui=player:WaitForChild("PlayerGui")
local backpack=player:WaitForChild("Backpack")
local wild=world:WaitForChild("WildMonsters")
local palette={bg=Color3.fromRGB(22,27,31),slot=Color3.fromRGB(37,44,47),gold=Color3.fromRGB(180,151,90),text=Color3.fromRGB(242,232,206),muted=Color3.fromRGB(152,163,164)}
local hud=Instance.new("ScreenGui")
hud.Name="CompanionHUD" hud.ResetOnSpawn=false hud.DisplayOrder=15 hud.Parent=playerGui
local function round(o,r)
 local c=Instance.new("UICorner") c.CornerRadius=UDim.new(0,r or 8) c.Parent=o
end
local function border(o)
 local st=Instance.new("UIStroke") st.Color=palette.gold st.Transparency=.35 st.Thickness=1 st.Parent=o
end
local function label(parent,name,txt,pos,size,fontSize,color)
 local t=Instance.new("TextLabel") t.Name=name t.Text=txt t.Position=pos t.Size=size
 t.BackgroundTransparency=1 t.TextColor3=color or palette.text t.Font=Enum.Font.GothamMedium t.TextSize=fontSize or 14 t.Parent=parent
 return t
end
local openBag
local function getOpenBag()
 local current=playerGui:FindFirstChild("OpenPetBackpack")
 if current and current:IsA("BindableEvent") then
  openBag=current
  return current
 end
 if current then current:Destroy() end
 current=Instance.new("BindableEvent")
 current.Name="OpenPetBackpack"
 current.Parent=playerGui
 openBag=current
 return current
end
getOpenBag()

local bar=Instance.new("Frame") bar.Name="ActionBar" bar.AnchorPoint=Vector2.new(.5,1)
bar.Position=UDim2.new(.5,0,1,-18) bar.Size=UDim2.fromOffset(480,84)
bar.BackgroundColor3=palette.bg bar.BorderSizePixel=0 bar.Parent=hud round(bar,12) border(bar)
local layout=Instance.new("UIListLayout") layout.FillDirection=Enum.FillDirection.Horizontal
layout.Padding=UDim.new(0,7) layout.HorizontalAlignment=Enum.HorizontalAlignment.Center layout.VerticalAlignment=Enum.VerticalAlignment.Center layout.SortOrder=Enum.SortOrder.LayoutOrder layout.Parent=bar
local scale=Instance.new("UIScale") scale.Parent=bar
local notice=label(hud,"Notice","",UDim2.new(.5,-250,1,-142),UDim2.fromOffset(500,40),15)
notice.TextWrapped=true
local noticeToken=0
local function message(value)
 noticeToken+=1 local token=noticeToken notice.Text=tostring(value or "")
 task.delay(4,function() if token==noticeToken then notice.Text="" end end)
end
local homeButton=Instance.new("TextButton")
homeButton.Name="HomeButton"
homeButton.AnchorPoint=Vector2.new(0,1)
homeButton.Position=UDim2.new(0,12,1,-12)
homeButton.Size=UDim2.fromOffset(58,58)
homeButton.BackgroundColor3=palette.slot
homeButton.BorderSizePixel=0
homeButton.Text="⌂"
homeButton.TextColor3=palette.text
homeButton.Font=Enum.Font.GothamBold
homeButton.TextSize=31
homeButton.AutoButtonColor=true
homeButton.Parent=hud
round(homeButton,12)
border(homeButton)
local homeCooldown=label(homeButton,"Cooldown","",UDim2.new(0,0,1,-16),UDim2.new(1,0,0,13),9,palette.muted)
homeCooldown.TextXAlignment=Enum.TextXAlignment.Center
homeButton.Activated:Connect(function()
 local active=player:GetAttribute("HomeTeleportActionActive")==true
 local blockedUntil=tonumber(player:GetAttribute("HomeTeleportBlockedUntil")) or 0
 local remaining=math.max(0,math.ceil(blockedUntil-workspace:GetServerTimeNow()))
 if active then
  message("You can't return to your plot during combat or a capture.")
  return
 end
 if remaining>0 then
  message("Return to plot available in "..tostring(remaining).."s.")
  return
 end
 remotes.Game:FireServer("ReturnToPlot")
end)

local tooltip=label(hud,"Tooltip","",UDim2.new(.5,-235,1,-193),UDim2.fromOffset(470,44),13)
tooltip.BackgroundColor3=palette.bg tooltip.BackgroundTransparency=.05 tooltip.Visible=false tooltip.TextWrapped=true round(tooltip)
local function button(name,key,icon,title,order,callback,tip)
 local b=Instance.new("TextButton") b.Name=name b.Text="" b.Size=UDim2.fromOffset(70,66) b.LayoutOrder=order
 b.BackgroundColor3=palette.slot b.BorderSizePixel=0 b.Parent=bar round(b,7) border(b)
 label(b,"Key",key,UDim2.fromOffset(6,2),UDim2.fromOffset(16,17),12,palette.gold)
 label(b,"Icon",icon,UDim2.fromOffset(8,9),UDim2.fromOffset(54,27),23,palette.gold)
 local caption=label(b,"Caption",title,UDim2.fromOffset(3,36),UDim2.fromOffset(64,27),11)
 caption.TextWrapped=true
 b.Activated:Connect(function() tooltip.Visible=false callback() end)
 b.MouseEnter:Connect(function() tooltip.Text=tip or title tooltip.Visible=true end)
 b.MouseLeave:Connect(function() tooltip.Visible=false end)
 return b
end
local equippedSpecies=""
local function command(action)
 if action~="Lasso" and equippedSpecies=="" then message("Equip a companion from your backpack first.") return end
 remotes.Game:FireServer("CombatAction",action)
end
local bagButton=button("Backpack","B","","Backpack",0,function() getOpenBag():Fire() end,"Backpack · collected pets and carried items")
local bagBody=Instance.new("Frame") bagBody.Size=UDim2.fromOffset(23,23) bagBody.Position=UDim2.fromOffset(24,12) bagBody.BackgroundColor3=palette.gold bagBody.BorderSizePixel=0 bagBody.Parent=bagButton round(bagBody,5)
local handle=Instance.new("Frame") handle.Size=UDim2.fromOffset(11,8) handle.Position=UDim2.fromOffset(6,-5) handle.BackgroundColor3=palette.gold handle.BorderSizePixel=0 handle.Parent=bagBody round(handle,3)
local pocket=Instance.new("Frame") pocket.Size=UDim2.fromOffset(15,8) pocket.Position=UDim2.fromOffset(4,12) pocket.BackgroundColor3=palette.slot pocket.BorderSizePixel=0 pocket.Parent=bagBody round(pocket,2)
button("Lasso","1","◎","Lasso",1,function() command("Lasso") end,"Throw your lasso at the selected creature. Your companion stays passive.")
local attackButton=button("Attack","2","⚔","Attack",2,function() command("Attack") end,"Command your companion to approach and automatically attack your selected target.")
-- Species skill names are previews; their separate gameplay implementations are pending.
local skillNames={
 Wolf={"Lick Wounds","Pack Howl","Rending Bite"},Boar={"Charge","Iron Hide","Tusk Sweep"},
 Bear={"Bear Swipe","Thick Hide","Ground Slam"},Fox={"Quick Pounce","Cunning Feint","Foxfire"},
 Griffin={"Dive Bomb","Wing Buffet","Sky Cry"},Dragon={"Flame Breath","Wing Storm","Dragon Roar"},
 Leviathan={"Tidal Surge","Undertow","Deep Guard"},Starling={"Star Volley","Healing Song","Radiant Flight"},
 AncientTitan={"Titan Stomp","Stone Guard","Earth Shatter"},MoonBat={"Sonic Burst","Night Veil","Leech Bite"},
 ShadowStag={"Antler Rush","Moon Ward","Forest Call"}
}
local abilityButtons={}
local function rebuildAbilities()
 for _,b in ipairs(abilityButtons) do b:Destroy() end abilityButtons={}
 equippedSpecies=player:GetAttribute("EquippedPetSpecies") or ""
 attackButton.Visible=equippedSpecies~=""
 if equippedSpecies~="" then
  local info=config.Pets[equippedSpecies]
  local base=info and info.AnimationSpecies or equippedSpecies
  local names=skillNames[base] or {"Creature Strike","Creature Guard","Creature Spirit"}
  for i,name in ipairs(names) do
   local b=button("Ability"..i,tostring(i+2),name:sub(1,1)..(name:match("%s(%a)") or ""),name,i+2,function()
    message(name.." is not unlocked yet — abilities are coming next.")
   end,name.." · "..equippedSpecies.." skill · Coming soon")
   b.BackgroundColor3=Color3.fromRGB(31,34,38)
   b.Icon.TextColor3=palette.muted
   label(b,"Pending","SOON",UDim2.fromOffset(29,1),UDim2.fromOffset(37,13),8,palette.muted)
   table.insert(abilityButtons,b)
  end
 end
end
player:GetAttributeChangedSignal("EquippedPetSpecies"):Connect(rebuildAbilities)
rebuildAbilities()

-- The custom bar replaces Roblox's default item strip. Preserve the actual tools.
task.spawn(function()
 for _=1,10 do
  local ok=pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack,false) end)
  if ok then break end task.wait(.2)
 end
end)
local toolButtons={}
local function refreshTools()
 for _,b in ipairs(toolButtons) do b:Destroy() end toolButtons={}
 local toolsSeen={} local carried={}
 for _,container in ipairs({backpack,player.Character}) do
  if container then for _,tool in ipairs(container:GetChildren()) do
   if tool:IsA("Tool") then
    if tool.Name=="Lasso" then tool.ManualActivationOnly=true
    elseif not toolsSeen[tool.Name] then toolsSeen[tool.Name]=true table.insert(carried,tool) end
   end
  end end
 end
 table.sort(carried,function(a,b) return a.Name<b.Name end)
 for i,tool in ipairs(carried) do
  local key=i<=4 and tostring(i+5) or ""
  local b=button("Item_"..tool.Name,key,"◇",tool.Name,i+5,function()
   local h=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
   if h then if tool.Parent==player.Character then h:UnequipTools() else h:EquipTool(tool) end end
  end,"Equip "..tool.Name)
  if tool.TextureId~="" then
   b.Icon.Visible=false local icon=Instance.new("ImageLabel") icon.BackgroundTransparency=1
   icon.Image=tool.TextureId icon.Size=UDim2.fromOffset(28,28) icon.Position=UDim2.fromOffset(21,9) icon.Parent=b
  end
  table.insert(toolButtons,b)
 end
end
backpack.ChildAdded:Connect(refreshTools) backpack.ChildRemoved:Connect(refreshTools)
local characterConnections={}
local function characterAdded(c)
 for _,conn in ipairs(characterConnections) do conn:Disconnect() end characterConnections={}
 table.insert(characterConnections,c.ChildAdded:Connect(refreshTools))
 table.insert(characterConnections,c.ChildRemoved:Connect(refreshTools))
 refreshTools()
end
player.CharacterAdded:Connect(characterAdded)
if player.Character then characterAdded(player.Character) end

local targetPanel=Instance.new("Frame") targetPanel.Name="CreatureTarget"
targetPanel.AnchorPoint=Vector2.new(.5,0) targetPanel.Position=UDim2.new(.5,0,0,8)
targetPanel.Size=UDim2.fromOffset(390,100) targetPanel.BackgroundColor3=palette.bg targetPanel.BorderSizePixel=0
targetPanel.Visible=false targetPanel.Parent=hud round(targetPanel,12) border(targetPanel)
local portrait=Instance.new("ViewportFrame") portrait.Name="FacePortrait" portrait.Position=UDim2.fromOffset(8,8)
portrait.Size=UDim2.fromOffset(84,84) portrait.BackgroundColor3=Color3.fromRGB(45,52,52)
portrait.Ambient=Color3.fromRGB(210,205,195) portrait.LightColor=Color3.fromRGB(255,238,207)
portrait.LightDirection=Vector3.new(-1,-1,-1) portrait.Parent=targetPanel round(portrait,9)
local targetName=label(targetPanel,"CreatureName","",UDim2.fromOffset(104,10),UDim2.fromOffset(249,23),17)
targetName.TextXAlignment=Enum.TextXAlignment.Left
local targetDetails=label(targetPanel,"Stats","",UDim2.fromOffset(104,34),UDim2.fromOffset(276,19),11,palette.gold)
targetDetails.TextXAlignment=Enum.TextXAlignment.Left
local healthBack=Instance.new("Frame") healthBack.Name="HealthBar" healthBack.Position=UDim2.fromOffset(104,59)
healthBack.Size=UDim2.fromOffset(272,23) healthBack.BackgroundColor3=Color3.fromRGB(48,35,34) healthBack.BorderSizePixel=0 healthBack.Parent=targetPanel round(healthBack,5)
local healthFill=Instance.new("Frame") healthFill.Name="Fill" healthFill.Size=UDim2.fromScale(1,1)
healthFill.BackgroundColor3=Color3.fromRGB(80,153,106) healthFill.BorderSizePixel=0 healthFill.Parent=healthBack round(healthFill,5)
local healthText=label(healthBack,"Value","",UDim2.fromScale(0,0),UDim2.fromScale(1,1),12)
healthText.ZIndex=3
local close=Instance.new("TextButton") close.Name="ClearTarget" close.Text="×" close.Size=UDim2.fromOffset(25,25)
close.Position=UDim2.new(1,-29,0,5) close.TextColor3=palette.muted close.TextSize=21 close.BackgroundTransparency=1 close.Parent=targetPanel
local selectedTarget,highlight
local targetConnections={}
local function clearTarget()
 for _,connection in ipairs(targetConnections) do connection:Disconnect() end targetConnections={}
 selectedTarget=nil targetPanel.Visible=false
 if highlight then highlight:Destroy() highlight=nil end
 portrait:ClearAllChildren()
end
close.Activated:Connect(function() remotes.Game:FireServer("CombatSelect",nil) clearTarget() end)
local function updateTarget()
 local m=selectedTarget
 if not m or not m.Parent or m:GetAttribute("Dead") or m:GetAttribute("Captured") then clearTarget() return end
 local species=m:GetAttribute("Species") or m.Name
 local info=config.Pets[species] or {}
 local hp=math.max(0,m:GetAttribute("Health") or info.Health or 0)
 local maximum=math.max(1,m:GetAttribute("MaxHealth") or info.Health or hp)
 local power=m:GetAttribute("Power") or info.Power or 1
 local defence=m:GetAttribute("Defence") or info.Defence or 1
 local rating=math.ceil((maximum*power*defence)/1000)
 targetName.Text=species
 targetDetails.Text=string.format("Lv.%d  ·  %s  ·  Power %s",m:GetAttribute("Level") or 1,m:GetAttribute("Rarity") or info.Rarity or "Common",tostring(rating))
 healthText.Text=string.format("%d / %d HP",math.ceil(hp),math.ceil(maximum))
 healthFill.Size=UDim2.fromScale(math.clamp(hp/maximum,0,1),1)
end
local function setTarget(m)
 clearTarget()
 if typeof(m)~="Instance" or m.Parent~=wild then return end
 selectedTarget=m targetPanel.Visible=true
 highlight=Instance.new("Highlight") highlight.Name="SelectedCreature" highlight.Adornee=m
 highlight.FillColor=palette.gold highlight.FillTransparency=.88 highlight.OutlineColor=palette.gold
 highlight.DepthMode=Enum.HighlightDepthMode.Occluded highlight.Parent=hud
 local ok,copy=pcall(function() return m:Clone() end)
 if ok and copy then
  for _,d in ipairs(copy:GetDescendants()) do
   if d:IsA("LuaSourceContainer") or d:IsA("BillboardGui") or d:IsA("ParticleEmitter") or d:IsA("Beam") or d:IsA("Trail") then d:Destroy()
   elseif d:IsA("BasePart") then d.Anchored=true d.CanCollide=false end
  end
  local worldModel=Instance.new("WorldModel") worldModel.Parent=portrait copy.Parent=worldModel
  local head
  for _,d in ipairs(copy:GetDescendants()) do
   if d:IsA("BasePart") and (d.Name:lower():find("head") or d.Parent.Name:lower():find("head")) then head=d break end
  end
  head=head or copy.PrimaryPart or copy:FindFirstChildWhichIsA("BasePart",true)
  if head then
   local camera=Instance.new("Camera") camera.FieldOfView=35 camera.Parent=portrait portrait.CurrentCamera=camera
   local root=copy.PrimaryPart or head
   local distance=math.max(head.Size.X,head.Size.Y,head.Size.Z)*2.1
   local point=head.Position+Vector3.new(0,head.Size.Y*.05,0)
   camera.CFrame=CFrame.lookAt(point+root.CFrame.ZVector*distance+root.CFrame.RightVector*distance*.3+Vector3.new(0,distance*.15,0),point)
  end
 end
 for _,name in ipairs({"Health","MaxHealth","Power","Defence","Level","Dead","Captured"}) do
  table.insert(targetConnections,m:GetAttributeChangedSignal(name):Connect(updateTarget))
 end
 table.insert(targetConnections,m.AncestryChanged:Connect(updateTarget))
 updateTarget()
end

local captureGame
local function endCaptureGame(keepTarget)
 local state=captureGame
 if not state then return end
 captureGame=nil
 if state.renderConnection then state.renderConnection:Disconnect() end
 if state.overlay and state.overlay.Parent then state.overlay:Destroy() end

 local camera=workspace.CurrentCamera
 if camera and state.camera then
  camera.CameraType=Enum.CameraType.Scriptable
  camera.CFrame=state.camera.cframe
  camera.FieldOfView=state.camera.fieldOfView
  camera.CameraType=state.camera.cameraType
  if state.camera.subject and state.camera.subject.Parent then
   camera.CameraSubject=state.camera.subject
  else
   local humanoid=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
   if humanoid then camera.CameraSubject=humanoid end
  end
 end

 if keepTarget and selectedTarget and selectedTarget.Parent and not selectedTarget:GetAttribute("Captured") and not selectedTarget:GetAttribute("Dead") then
  targetPanel.Visible=true
 else
  targetPanel.Visible=false
 end
end

local function startCaptureGame(monster,challengeId,species,rarity,lassoName,zoneStart,zoneWidth,speed,startTime,duration)
 if captureGame then endCaptureGame(true) end

 local camera=workspace.CurrentCamera
 if not camera or typeof(monster)~="Instance" or not monster.Parent then return end
 local part=monster.PrimaryPart or monster:FindFirstChild("HumanoidRootPart") or monster:FindFirstChildWhichIsA("BasePart",true)
 if not part then return end

 local savedCamera={
  cameraType=camera.CameraType,
  subject=camera.CameraSubject,
  cframe=camera.CFrame,
  fieldOfView=camera.FieldOfView,
 }

 local overlay=Instance.new("TextButton")
 overlay.Name="CaptureMinigame"
 overlay.Text=""
 overlay.AutoButtonColor=false
 overlay.Modal=true
 overlay.Active=true
 overlay.Size=UDim2.fromScale(1,1)
 overlay.BackgroundColor3=Color3.new(0,0,0)
 overlay.BackgroundTransparency=.58
 overlay.BorderSizePixel=0
 overlay.ZIndex=80
 overlay.Parent=hud

 local card=Instance.new("Frame")
 card.Name="CaptureCard"
 card.AnchorPoint=Vector2.new(.5,1)
 card.Position=UDim2.new(.5,0,1,-118)
 card.Size=UDim2.fromOffset(560,132)
 card.BackgroundColor3=palette.bg
 card.BackgroundTransparency=.03
 card.BorderSizePixel=0
 card.ZIndex=81
 card.Parent=overlay
 round(card,12)
 border(card)

 local title=label(card,"Title","LASSO  ·  "..tostring(species).."  ·  "..tostring(rarity),UDim2.fromOffset(18,12),UDim2.fromOffset(524,24),15,palette.text)
 title.ZIndex=82
 title.TextXAlignment=Enum.TextXAlignment.Center
 local instruction=label(card,"Instruction","CLICK when the marker is inside the green zone",UDim2.fromOffset(18,38),UDim2.fromOffset(524,20),12,palette.muted)
 instruction.ZIndex=82
 instruction.TextXAlignment=Enum.TextXAlignment.Center

 local track=Instance.new("Frame")
 track.Name="Track"
 track.Position=UDim2.fromOffset(35,70)
 track.Size=UDim2.fromOffset(490,28)
 track.BackgroundColor3=Color3.fromRGB(55,58,62)
 track.BorderSizePixel=0
 track.ClipsDescendants=true
 track.ZIndex=82
 track.Parent=card
 round(track,6)

 local green=Instance.new("Frame")
 green.Name="GreenZone"
 green.Position=UDim2.fromScale(zoneStart,0)
 green.Size=UDim2.fromScale(zoneWidth,1)
 green.BackgroundColor3=Color3.fromRGB(80,170,95)
 green.BorderSizePixel=0
 green.ZIndex=83
 green.Parent=track

 local marker=Instance.new("Frame")
 marker.Name="Marker"
 marker.AnchorPoint=Vector2.new(.5,0)
 marker.Position=UDim2.fromScale(0,0)
 marker.Size=UDim2.fromOffset(5,28)
 marker.BackgroundColor3=Color3.fromRGB(255,240,190)
 marker.BorderSizePixel=0
 marker.ZIndex=84
 marker.Parent=track

 local timer=label(card,"Timer","",UDim2.fromOffset(18,103),UDim2.fromOffset(524,18),11,palette.muted)
 timer.ZIndex=82
 timer.TextXAlignment=Enum.TextXAlignment.Center

 local targetPos=part.Position
 local offset=camera.CFrame.Position-targetPos
 if offset.Magnitude<2 then offset=Vector3.new(0,4,10) end
 local extent=monster:IsA("Model") and monster:GetExtentsSize().Magnitude or part.Size.Magnitude
 local distance=math.clamp(extent*1.35,8,15)
 local cameraPos=targetPos+offset.Unit*distance+Vector3.new(0,math.clamp(extent*.12,1,3),0)
 local focus=targetPos+Vector3.new(0,math.clamp(extent*.08,.5,2),0)
 camera.CameraType=Enum.CameraType.Scriptable
 TweenService:Create(
  camera,
  TweenInfo.new(.32,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),
  {CFrame=CFrame.lookAt(cameraPos,focus),FieldOfView=38}
 ):Play()

 targetPanel.Visible=false

 local state={
  id=challengeId,
  overlay=overlay,
  marker=marker,
  timer=timer,
  startTime=startTime,
  duration=duration,
  speed=speed,
  clicked=false,
  camera=savedCamera,
 }
 captureGame=state

 local function sliderPosition(atTime)
  local elapsedTime=math.max(0,atTime-startTime)
  local phase=(elapsedTime*speed)%2
  return phase<=1 and phase or 2-phase
 end

 state.renderConnection=RunService.RenderStepped:Connect(function()
  if captureGame~=state or not marker.Parent then return end
  local now=workspace:GetServerTimeNow()
  marker.Position=UDim2.fromScale(sliderPosition(now),0)
  local remaining=math.max(0,(startTime+duration)-now)
  timer.Text=state.clicked and "Checking lasso..." or string.format("%.1fs  ·  %s",remaining,tostring(lassoName))
 end)

 overlay.Activated:Connect(function()
  if captureGame~=state or state.clicked then return end
  state.clicked=true
  overlay.Active=false
  remotes.Capture:FireServer("Resolve",challengeId,workspace:GetServerTimeNow())
 end)
end

local function selectAt(position) local main=playerGui:FindFirstChild("WildernessPetsUI")
 if captureGame then return end
 if main and main:GetAttribute("InventoryOpen") then return end

 if not player:GetAttribute("VillageReady") then return end
 for _,o in ipairs(playerGui:GetGuiObjectsAtPosition(position.X,position.Y)) do
  if o:IsA("GuiButton") or o:IsA("ScrollingFrame") or (o.Active and o.BackgroundTransparency<1) then return end
 end
 local camera=workspace.CurrentCamera
 if not camera then return end
 local ray=camera:ViewportPointToRay(position.X,position.Y)
 local params=RaycastParams.new() params.FilterType=Enum.RaycastFilterType.Exclude
 local exclude={}
 if player.Character then table.insert(exclude,player.Character) end
 local companions=world:FindFirstChild("Companions") if companions then table.insert(exclude,companions) end
 params.FilterDescendantsInstances=exclude
 local hit=workspace:Raycast(ray.Origin,ray.Direction*600,params)
 local candidate=hit and hit.Instance
 -- Resolve segmented mesh children all the way to the wild creature root.
 while candidate and candidate.Parent~=wild do candidate=candidate.Parent end
 if candidate and candidate:IsA("Model") then
  remotes.Game:FireServer("CombatSelect",candidate)
 else
  remotes.Game:FireServer("CombatSelect",nil)
  clearTarget()
 end
end
UIS.InputBegan:Connect(function(input,processed)
 if processed or UIS:GetFocusedTextBox() then return end
 if input.UserInputType==Enum.UserInputType.MouseButton1 then selectAt(UIS:GetMouseLocation()) return end
 if not player:GetAttribute("VillageReady") then return end
 local key=input.KeyCode
 if key==Enum.KeyCode.B then getOpenBag():Fire()
 elseif key==Enum.KeyCode.One then command("Lasso")
 elseif key==Enum.KeyCode.Two then command("Attack")
 elseif key==Enum.KeyCode.Three or key==Enum.KeyCode.Four or key==Enum.KeyCode.Five then
  if equippedSpecies~="" then message("Your companion's unique abilities are coming next.") end
 else
  local map={[Enum.KeyCode.Six]=1,[Enum.KeyCode.Seven]=2,[Enum.KeyCode.Eight]=3,[Enum.KeyCode.Nine]=4}
  local index=map[key]
  if index then
   local carried={}
   for _,container in ipairs({backpack,player.Character}) do if container then for _,tool in ipairs(container:GetChildren()) do if tool:IsA("Tool") and tool.Name~="Lasso" then table.insert(carried,tool) end end end end
   table.sort(carried,function(a,b) return a.Name<b.Name end)
   local h=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
   if h and carried[index] then if carried[index].Parent==player.Character then h:UnequipTools() else h:EquipTool(carried[index]) end end
  end
 end
end)
UIS.TouchTapInWorld:Connect(function(position,processed) if not processed then selectAt(position) end end)
remotes.Game.OnClientEvent:Connect(function(action,kind,...)
 if action=="HomeTeleport" then
  local response=(...)
  message(response or (kind and "Returned to your plot." or "You can't return to your plot yet."))
  return
 end
 if action~="Combat" then return end
 if kind=="Target" then setTarget((...))
 elseif kind=="ClearTarget" then clearTarget()
 elseif kind=="Reward" then local xp,coins=... message("Victory  ·  +"..tostring(xp).." XP  ·  +"..tostring(coins).." coins") clearTarget()
 elseif kind=="Error" then message((...))
 elseif kind=="Equipped" then rebuildAbilities() message(tostring((...)).." is ready.")
 elseif kind=="Unequipped" then rebuildAbilities()
 elseif kind=="CombatState" then local state=... if state=="Engaging" then message("Companion engaging your target") end
 end
end)
remotes.Capture.OnClientEvent:Connect(function(action,...)
 local args={...}
 if action=="Challenge" then
  startCaptureGame(
   args[1],
   args[2],
   args[3],
   args[4],
   args[5],
   tonumber(args[6]) or .2,
   tonumber(args[7]) or .2,
   tonumber(args[8]) or .8,
   tonumber(args[9]) or workspace:GetServerTimeNow(),
   tonumber(args[10]) or 8
  )
 elseif action=="Success" then
  endCaptureGame(false)
  clearTarget()
 elseif action=="Failed" then
  endCaptureGame(true)
  message("Missed — the creature broke free!")
 elseif action=="Error" then
  endCaptureGame(true)
  message(tostring(args[1] or "The lasso attempt failed."))
 end
end)
RunService.RenderStepped:Connect(function()
 hud.Enabled=player:GetAttribute("VillageReady")==true
 local width=18
 for _,b in ipairs(bar:GetChildren()) do if b:IsA("GuiButton") and b.Visible then width+=77 end end
 bar.Size=UDim2.fromOffset(width,84)
 local viewport=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280,720)
 scale.Scale=math.min(1,(viewport.X-24)/width)
 local homeActive=player:GetAttribute("HomeTeleportActionActive")==true
 local homeBlockedUntil=tonumber(player:GetAttribute("HomeTeleportBlockedUntil")) or 0
 local homeRemaining=math.max(0,math.ceil(homeBlockedUntil-workspace:GetServerTimeNow()))
 homeCooldown.Text=homeActive and "BUSY" or (homeRemaining>0 and (tostring(homeRemaining).."s") or "")
 homeButton.BackgroundColor3=(homeActive or homeRemaining>0) and Color3.fromRGB(31,34,38) or palette.slot
 homeButton.TextColor3=(homeActive or homeRemaining>0) and palette.muted or palette.text
end)
