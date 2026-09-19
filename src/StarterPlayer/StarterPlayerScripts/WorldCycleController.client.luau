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
local function visualClockHour(hour)
 -- Gameplay/world time continues at the normal rate. Only the rendered sun is
 -- eased behind the clock around dawn, then smoothly catches up by late morning.
 local dawnStart=4.5
 local dawnEnd=11.5
 if hour>=dawnStart and hour<=dawnEnd then
  local u=math.clamp((hour-dawnStart)/(dawnEnd-dawnStart),0,1)
  local lag=1.25*(math.sin(u*math.pi)^2)
  return (hour-lag)%24
 end
 return hour
end
RunService.RenderStepped:Connect(function(dt)
 local epoch=world:GetAttribute("CycleEpoch")
 if not epoch then return end
 local duration=world:GetAttribute("CycleDuration") or 720
 local hour=((world:GetAttribute("CycleStartHour") or 9)+(workspace:GetServerTimeNow()-epoch)*24/duration)%24
 local visualHour=visualClockHour(hour)
 Lighting.ClockTime=visualHour
 local sun=math.sin((visualHour-6)/24*math.pi*2)
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
local petAbilities=require(RS.WildernessPets.Shared.PetAbilities)
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
local homeTutorialStroke=Instance.new("UIStroke")
homeTutorialStroke.Name="TutorialHomeHighlight"
homeTutorialStroke.Color=Color3.fromRGB(255,213,92)
homeTutorialStroke.Thickness=4
homeTutorialStroke.Transparency=1
homeTutorialStroke.Parent=homeButton

local homeTutorialLabel=label(
 homeButton,
 "TutorialHomeLabel",
 "RETURN HOME",
 UDim2.new(.5,-65,0,-27),
 UDim2.fromOffset(130,20),
 11,
 Color3.fromRGB(255,220,120)
)
homeTutorialLabel.Font=Enum.Font.GothamBold
homeTutorialLabel.TextXAlignment=Enum.TextXAlignment.Center
homeTutorialLabel.Visible=false

local homeTutorialTween
local function setHomeTutorialHighlight(enabled)
 if homeTutorialTween then
  homeTutorialTween:Cancel()
  homeTutorialTween=nil
 end
 if enabled then
  homeTutorialStroke.Transparency=.08
  homeTutorialLabel.Visible=true
  homeTutorialTween=TweenService:Create(
   homeTutorialStroke,
   TweenInfo.new(.65,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),
   {Transparency=.68}
  )
  homeTutorialTween:Play()
 else
  homeTutorialStroke.Transparency=1
  homeTutorialLabel.Visible=false
 end
end

setHomeTutorialHighlight(player:GetAttribute("TutorialHomeGuide")==true)
player:GetAttributeChangedSignal("TutorialHomeGuide"):Connect(function()
 setHomeTutorialHighlight(player:GetAttribute("TutorialHomeGuide")==true)
end)

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

local captureGame

local collectionButton=Instance.new("TextButton")
collectionButton.Name="PetCollectionButton"
collectionButton.AnchorPoint=Vector2.new(0,1)
collectionButton.Position=UDim2.new(0,12,1,-82)
collectionButton.Size=UDim2.fromOffset(58,58)
collectionButton.BackgroundColor3=palette.slot
collectionButton.BorderSizePixel=0
collectionButton.Text="▦"
collectionButton.TextColor3=palette.text
collectionButton.Font=Enum.Font.GothamBold
collectionButton.TextSize=27
collectionButton.AutoButtonColor=true
collectionButton.Parent=hud
round(collectionButton,12)
border(collectionButton)

local collectionOpen=false
local collectionPanel
local collectionSpinners={}
local collectionSpinAngle=0

local rarityColors={
 Common=Color3.fromRGB(220,228,218),
 Uncommon=Color3.fromRGB(114,220,142),
 Rare=Color3.fromRGB(109,181,255),
 Epic=Color3.fromRGB(193,136,255),
 Legendary=Color3.fromRGB(255,204,89),
 Mythic=Color3.fromRGB(255,126,189),
 Limited=Color3.fromRGB(141,250,239),
 Ancient=Color3.fromRGB(255,130,77),
}

local function collectionRoster()
 local result={}
 for species,info in pairs(config.Pets or {}) do
  if info.Legacy~=true and info.SpawnMode~="Legacy" then
   table.insert(result,{Species=species,Info=info})
  end
 end
 table.sort(result,function(a,b)
  local ar=config.Rarities[a.Info.Rarity]
  local br=config.Rarities[b.Info.Rarity]
  local aRank=ar and tonumber(ar.Rank) or 99
  local bRank=br and tonumber(br.Rank) or 99
  if aRank==bRank then return a.Species<b.Species end
  return aRank<bRank
 end)
 return result
end

local function closeCollection()
 collectionOpen=false
 collectionSpinners={}
 if collectionPanel then collectionPanel:Destroy() collectionPanel=nil end
end

local function rewardText(reward)
 if not reward then return "Collection complete" end
 local parts={}
 local coins=math.max(0,math.floor(tonumber(reward.Coins) or 0))
 local gems=math.max(0,math.floor(tonumber(reward.Gems) or 0))
 if coins>0 then table.insert(parts,tostring(coins).." Coins") end
 if gems>0 then table.insert(parts,tostring(gems).." Gems") end
 return #parts>0 and table.concat(parts," + ") or "Reward"
end

local function addCollectionPreview(card,species,discovered)
 local viewport=Instance.new("ViewportFrame")
 viewport.Name="PetPreview"
 viewport.Position=UDim2.fromOffset(6,34)
 viewport.Size=UDim2.fromOffset(120,94)
 viewport.BackgroundColor3=discovered and Color3.fromRGB(31,38,42) or Color3.fromRGB(28,30,32)
 viewport.BorderSizePixel=0
 viewport.Ambient=discovered and Color3.fromRGB(190,190,190) or Color3.fromRGB(120,120,120)
 viewport.LightColor=discovered and Color3.fromRGB(255,240,220) or Color3.fromRGB(175,175,175)
 viewport.LightDirection=Vector3.new(-1,-1,-1)
 viewport.Parent=card
 round(viewport,8)

 local previews=RS.WildernessPets:FindFirstChild("PetPreviews")
 local template=previews and previews:FindFirstChild(species)
 if not template then return end

 local copy=template:Clone()
 for _,item in ipairs(copy:GetDescendants()) do
  if item:IsA("BillboardGui") or item:IsA("LuaSourceContainer") or item:IsA("ParticleEmitter") or item:IsA("Beam") or item:IsA("Trail") then
   item:Destroy()
  elseif item:IsA("BasePart") then
   item.Anchored=true item.CanCollide=false item.CanTouch=false item.CanQuery=false
   if not discovered then
    local source=item.Color
    local gray=math.clamp(.14+(source.R*.299+source.G*.587+source.B*.114)*.28,.14,.42)
    item.Color=Color3.new(gray,gray,gray)
    item.Material=Enum.Material.SmoothPlastic
   end
  end
 end

 local rootPart=copy.PrimaryPart or copy:FindFirstChildWhichIsA("BasePart",true)
 if not rootPart then copy:Destroy() return end
 copy.PrimaryPart=rootPart
 copy:PivotTo(CFrame.new())

 local worldModel=Instance.new("WorldModel")
 worldModel.Parent=viewport
 copy.Parent=worldModel

 local box,size=copy:GetBoundingBox()
 local focus=box.Position
 local distance=math.max(6,size.Magnitude*1.05)
 local camera=Instance.new("Camera")
 camera.FieldOfView=38
 camera.CFrame=CFrame.lookAt(
  focus+Vector3.new(0,math.max(.4,size.Y*.12),distance),
  focus
 )
 camera.Parent=viewport
 viewport.CurrentCamera=camera

 if discovered then table.insert(collectionSpinners,copy) end
end

local function showCollection()
 if captureGame then
  message("Finish your capture before opening the pet collection.")
  return
 end

 local mainUI=playerGui:FindFirstChild("WildernessPetsUI")
 if mainUI and mainUI:GetAttribute("InventoryOpen")==true then
  message("Close the current menu before opening the pet collection.")
  return
 end

 if collectionPanel then collectionPanel:Destroy() end
 collectionSpinners={}
 collectionSpinAngle=0

 local state=remotes.GetState:InvokeServer()
 if not state then
  collectionOpen=false
  message("Pet collection data is unavailable.")
  return
 end

 collectionOpen=true
 local discovered=type(state.PetCollection)=="table" and state.PetCollection or {}
 local claimed=type(state.CollectionRewardsClaimed)=="table" and state.CollectionRewardsClaimed or {}
 local roster=collectionRoster()
 local discoveredCount=0
 for _,entry in ipairs(roster) do
  if discovered[entry.Species]==true then discoveredCount+=1 end
 end

 local nextReward
 for _,reward in ipairs(config.CollectionMilestones or {}) do
  local required=math.max(0,math.floor(tonumber(reward.Required) or 0))
  if not claimed[tostring(required)] then nextReward=reward break end
 end

 collectionPanel=Instance.new("Frame")
 collectionPanel.Name="PetCollectionDatabase"
 collectionPanel.AnchorPoint=Vector2.new(.5,.5)
 collectionPanel.Position=UDim2.new(.5,0,.5,0)
 collectionPanel.Size=UDim2.fromOffset(900,640)
 collectionPanel.BackgroundColor3=palette.bg
 collectionPanel.BackgroundTransparency=.02
 collectionPanel.BorderSizePixel=0
 collectionPanel.Parent=hud
 round(collectionPanel,12)
 border(collectionPanel)

 local cameraSize=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280,720)
 local fit=Instance.new("UIScale")
 fit.Scale=math.min(1,(cameraSize.X-28)/900,(cameraSize.Y-34)/640)
 fit.Parent=collectionPanel

 local title=label(collectionPanel,"Title","PET COLLECTION DATABASE",UDim2.fromOffset(22,14),UDim2.fromOffset(650,30),22,palette.text)
 title.TextXAlignment=Enum.TextXAlignment.Left

 local closeButton=Instance.new("TextButton")
 closeButton.Name="Close"
 closeButton.Text="×"
 closeButton.Position=UDim2.fromOffset(842,12)
 closeButton.Size=UDim2.fromOffset(40,34)
 closeButton.BackgroundColor3=palette.slot
 closeButton.TextColor3=palette.text
 closeButton.Font=Enum.Font.GothamBold
 closeButton.TextSize=24
 closeButton.BorderSizePixel=0
 closeButton.Parent=collectionPanel
 round(closeButton,8)
 border(closeButton)
 closeButton.Activated:Connect(closeCollection)

 local progressCaption=label(
  collectionPanel,
  "ProgressCaption",
  tostring(discoveredCount).." / "..tostring(#roster).." species discovered",
  UDim2.fromOffset(22,54),
  UDim2.fromOffset(640,22),
  13,
  palette.text
 )
 progressCaption.TextXAlignment=Enum.TextXAlignment.Left

 local progressBack=Instance.new("Frame")
 progressBack.Name="ProgressBar"
 progressBack.Position=UDim2.fromOffset(22,82)
 progressBack.Size=UDim2.fromOffset(640,24)
 progressBack.BackgroundColor3=Color3.fromRGB(47,52,55)
 progressBack.BorderSizePixel=0
 progressBack.Parent=collectionPanel
 round(progressBack,6)

 local targetRequired=nextReward and math.max(1,math.floor(tonumber(nextReward.Required) or #roster)) or math.max(1,#roster)
 local fillAmount=math.clamp(discoveredCount/targetRequired,0,1)
 local progressFill=Instance.new("Frame")
 progressFill.Name="Fill"
 progressFill.Size=UDim2.fromScale(fillAmount,1)
 progressFill.BackgroundColor3=palette.gold
 progressFill.BorderSizePixel=0
 progressFill.Parent=progressBack
 round(progressFill,6)

 local milestoneText
 if nextReward then
  local required=math.max(0,math.floor(tonumber(nextReward.Required) or 0))
  milestoneText="Next milestone: "..tostring(required).." species  ·  "..rewardText(nextReward)
 else
  milestoneText="All collection milestones completed."
 end
 local rewardCaption=label(collectionPanel,"RewardCaption",milestoneText,UDim2.fromOffset(22,112),UDim2.fromOffset(640,22),12,palette.muted)
 rewardCaption.TextXAlignment=Enum.TextXAlignment.Left

 local collectButton=Instance.new("TextButton")
 collectButton.Name="CollectReward"
 collectButton.Position=UDim2.fromOffset(690,62)
 collectButton.Size=UDim2.fromOffset(182,54)
 collectButton.Text="COLLECT"
 collectButton.Font=Enum.Font.GothamBold
 collectButton.TextSize=15
 collectButton.BorderSizePixel=0
 collectButton.TextColor3=palette.text
 collectButton.Parent=collectionPanel
 round(collectButton,9)
 border(collectButton)

 local rewardReady=nextReward and discoveredCount>=math.max(0,math.floor(tonumber(nextReward.Required) or 0))
 collectButton.Active=rewardReady==true
 collectButton.AutoButtonColor=rewardReady==true
 collectButton.BackgroundColor3=rewardReady and Color3.fromRGB(92,78,48) or Color3.fromRGB(39,43,46)
 collectButton.TextColor3=rewardReady and palette.text or palette.muted
 collectButton.Activated:Connect(function()
  if rewardReady then
   collectButton.Active=false
   collectButton.AutoButtonColor=false
   remotes.Pets:FireServer("ClaimCollectionReward")
  end
 end)

 local list=Instance.new("ScrollingFrame")
 list.Name="PetGrid"
 list.Position=UDim2.fromOffset(20,150)
 list.Size=UDim2.fromOffset(860,466)
 list.BackgroundTransparency=1
 list.BorderSizePixel=0
 list.ScrollBarThickness=5
 list.ScrollBarImageColor3=palette.gold
 list.AutomaticCanvasSize=Enum.AutomaticSize.Y
 list.CanvasSize=UDim2.new()
 list.Parent=collectionPanel

 local grid=Instance.new("UIGridLayout")
 grid.CellSize=UDim2.fromOffset(132,138)
 grid.CellPadding=UDim2.fromOffset(9,9)
 grid.SortOrder=Enum.SortOrder.LayoutOrder
 grid.HorizontalAlignment=Enum.HorizontalAlignment.Center
 grid.Parent=list

 for index,entry in ipairs(roster) do
  local info=entry.Info
  local found=discovered[entry.Species]==true
  local card=Instance.new("Frame")
  card.Name="Pet_"..entry.Species
  card.LayoutOrder=index
  card.Size=UDim2.fromOffset(132,138)
  card.BackgroundColor3=palette.slot
  card.BorderSizePixel=0
  card.Parent=list
  round(card,8)

  local stroke=Instance.new("UIStroke")
  stroke.Color=found and (rarityColors[info.Rarity] or palette.gold) or Color3.fromRGB(88,94,96)
  stroke.Transparency=found and .28 or .58
  stroke.Thickness=1
  stroke.Parent=card

  local name=label(card,"PetName",entry.Species,UDim2.fromOffset(4,5),UDim2.fromOffset(124,25),11,found and palette.text or Color3.fromRGB(176,180,180))
  name.TextWrapped=true
  name.TextXAlignment=Enum.TextXAlignment.Center
  name.TextYAlignment=Enum.TextYAlignment.Center

  addCollectionPreview(card,entry.Species,found)

  local rarity=label(card,"Rarity",info.Rarity,UDim2.fromOffset(4,121),UDim2.fromOffset(124,14),9,found and (rarityColors[info.Rarity] or palette.muted) or palette.muted)
  rarity.TextXAlignment=Enum.TextXAlignment.Center
 end
end

collectionButton.Activated:Connect(showCollection)

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
-- Companion abilities use keys 3/4/5. Cooldowns are authoritative on
-- the server; the client only mirrors the remaining time for presentation.
local abilityButtons={}
local equippedAbilitySpecs={}
local abilityCooldownEnds={}
local function abilityIcon(name)
 local first=tostring(name):match("^%s*(%a)") or "?"
 local second=tostring(name):match("%s+(%a)")
 return first..(second or "")
end
local function abilityMessage(abilityInfo)
 local name=abilityInfo and abilityInfo.Name or "Ability"
 local description=petAbilities:GetDescription(abilityInfo)
 if description~="" then return name.." — "..description end
 return name
end
local function useAbility(slot)
 local abilityInfo=equippedAbilitySpecs[slot]
 if not abilityInfo then return end
 local remaining=math.max(0,(abilityCooldownEnds[slot] or 0)-workspace:GetServerTimeNow())
 if remaining>0 then
  message((abilityInfo.Name or "Ability").." ready in "..tostring(math.ceil(remaining)).."s")
  return
 end
 command("Ability"..tostring(slot))
end
local function rebuildAbilities()
 for _,b in ipairs(abilityButtons) do b:Destroy() end
 abilityButtons={}
 equippedAbilitySpecs={}
 equippedSpecies=player:GetAttribute("EquippedPetSpecies") or ""
 attackButton.Visible=equippedSpecies~=""
 if equippedSpecies~="" then
  local specs=petAbilities:Get(equippedSpecies) or {}
  equippedAbilitySpecs=specs
  for i,abilityInfo in ipairs(specs) do
   local name=abilityInfo.Name or ("Ability "..tostring(i))
   local description=petAbilities:GetDescription(abilityInfo)
   local cooldown=tonumber(abilityInfo.Cooldown) or 10
   local tip=name.." · "..description.." · Cooldown "..tostring(cooldown).."s"
   local slot=i
   local b=button("Ability"..i,tostring(i+2),abilityIcon(name),name,i+2,function()
    useAbility(slot)
   end,tip)
   b.BackgroundColor3=palette.slot
   b.Icon.TextColor3=palette.gold
   label(b,"Cooldown","",UDim2.fromOffset(25,1),UDim2.fromOffset(45,13),8,palette.muted)
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
targetPanel.AnchorPoint=Vector2.new(.5,0) targetPanel.Position=UDim2.new(.5,0,0,72)
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
 local creatureType=m:GetAttribute("CreatureType") or "Pet"
 local info=config.Pets[species] or (config.Mounts and config.Mounts[species]) or {}
 local hp=math.max(0,m:GetAttribute("Health") or info.Health or 0)
 local maximum=math.max(1,m:GetAttribute("MaxHealth") or info.Health or math.max(1,hp))
 local power=m:GetAttribute("Power") or info.Power or 1
 local defence=m:GetAttribute("Defence") or info.Defence or 1
 local rating=math.ceil((maximum*power*math.max(1,defence))/1000)
 targetName.Text=species
 if creatureType=="Mount" then
  targetDetails.Text=string.format("%s  ·  RIDEABLE MOUNT",m:GetAttribute("Rarity") or info.Rarity or "Common")
  healthBack.Visible=false
 else
  healthBack.Visible=true
  targetDetails.Text=string.format("Lv.%d  ·  %s  ·  Power %s",m:GetAttribute("Level") or 1,m:GetAttribute("Rarity") or info.Rarity or "Common",tostring(rating))
  healthText.Text=string.format("%d / %d HP",math.ceil(hp),math.ceil(maximum))
  healthFill.Size=UDim2.fromScale(math.clamp(hp/maximum,0,1),1)
 end
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

local function startCaptureGame(monster,challengeId,species,rarity,lassoName,zoneStart,zoneWidth,speed,startTime,duration,requiredHits,completedHits)
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

 local title=label(card,"Title","LASSO  ·  "..tostring(species).."  ·  "..tostring(rarity).."  ·  "..tostring(completedHits or 0).."/"..tostring(requiredHits or 3),UDim2.fromOffset(18,12),UDim2.fromOffset(524,24),15,palette.text)
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
  species=species,
  rarity=rarity,
  lassoName=lassoName,
  overlay=overlay,
  title=title,
  instruction=instruction,
  green=green,
  marker=marker,
  timer=timer,
  zoneStart=zoneStart,
  zoneWidth=zoneWidth,
  startTime=startTime,
  duration=duration,
  speed=speed,
  requiredHits=requiredHits or 3,
  completedHits=completedHits or 0,
  clicked=false,
  camera=savedCamera,
 }
 captureGame=state

 local function sliderPosition(atTime)
  local elapsedTime=math.max(0,atTime-state.startTime)
  local phase=(elapsedTime*state.speed)%2
  return phase<=1 and phase or 2-phase
 end

 state.renderConnection=RunService.RenderStepped:Connect(function()
  if captureGame~=state or not marker.Parent then return end
  local now=workspace:GetServerTimeNow()
  marker.Position=UDim2.fromScale(sliderPosition(now),0)
  local remaining=math.max(0,(state.startTime+state.duration)-now)
  timer.Text=state.clicked and "Checking lasso..." or string.format("%.1fs  ·  %s  ·  %d/%d",remaining,tostring(state.lassoName),state.completedHits,state.requiredHits)
 end)

 overlay.Activated:Connect(function()
  if captureGame~=state or state.clicked then return end
  state.clicked=true
  overlay.Active=false
  remotes.Capture:FireServer("Resolve",state.id,workspace:GetServerTimeNow())
 end)
end

local function advanceCaptureGame(challengeId,completedHits,requiredHits,zoneStart,zoneWidth,speed,startTime,duration)
 local state=captureGame
 if not state or state.id~=challengeId then return end

 state.completedHits=completedHits
 state.requiredHits=requiredHits
 state.zoneStart=zoneStart
 state.zoneWidth=zoneWidth
 state.speed=speed
 state.startTime=startTime
 state.duration=duration
 state.clicked=false

 if state.green and state.green.Parent then
  state.green.Position=UDim2.fromScale(zoneStart,0)
  state.green.Size=UDim2.fromScale(zoneWidth,1)
 end
 if state.title then
  state.title.Text="LASSO  ·  "..tostring(state.species).."  ·  "..tostring(state.rarity).."  ·  "..tostring(completedHits).."/"..tostring(requiredHits)
 end
 if state.instruction then
  state.instruction.Text="GOOD!  "..tostring(requiredHits-completedHits).." more  ·  click inside the next green zone"
 end
 if state.overlay then
  state.overlay.Active=true
 end
end

local function selectAt(position) local main=playerGui:FindFirstChild("WildernessPetsUI")
 if captureGame or collectionOpen then return end
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
  local questOwner=tonumber(candidate:GetAttribute("QuestOwnerUserId"))
  if questOwner and questOwner~=player.UserId then
   remotes.Game:FireServer("CombatSelect",nil)
   clearTarget()
  else
   remotes.Game:FireServer("CombatSelect",candidate)
  end
 else
  remotes.Game:FireServer("CombatSelect",nil)
  clearTarget()
 end
end
UIS.InputBegan:Connect(function(input,processed)
 if processed or UIS:GetFocusedTextBox() then return end
 if input.UserInputType==Enum.UserInputType.MouseButton1 then selectAt(UIS:GetMouseLocation()) return end
 if not player:GetAttribute("VillageReady") then return end
 if collectionOpen then return end
 local key=input.KeyCode
 if key==Enum.KeyCode.B then getOpenBag():Fire()
 elseif key==Enum.KeyCode.One then command("Lasso")
 elseif key==Enum.KeyCode.Two then command("Attack")
 elseif key==Enum.KeyCode.Three or key==Enum.KeyCode.Four or key==Enum.KeyCode.Five then
  if equippedSpecies~="" then
   local abilityIndex=key==Enum.KeyCode.Three and 1 or key==Enum.KeyCode.Four and 2 or 3
   useAbility(abilityIndex)
  end
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
  if kind then
   setHomeTutorialHighlight(false)
  end
  message(response or (kind and "Returned to your plot." or "You can't return to your plot yet."))
  return
 end
 if action~="Combat" then return end
 if kind=="Target" then setTarget((...))
 elseif kind=="ClearTarget" then clearTarget()
 elseif kind=="Reward" then local xp,rarity=... message("Victory  ·  +"..tostring(xp).." XP  ·  "..tostring(rarity or "Wild").." loot dropped") clearTarget()
 elseif kind=="Error" then message((...))
 elseif kind=="AbilityUsed" then
  local slot,feedback,cooldown=...
  slot=tonumber(slot)
  if slot then
   abilityCooldownEnds[slot]=workspace:GetServerTimeNow()+math.max(0,tonumber(cooldown) or 0)
  end
  message(tostring(feedback or "Ability used."))
 elseif kind=="Equipped" then
  abilityCooldownEnds={}
  rebuildAbilities()
  message(tostring((...)).." is ready.")
 elseif kind=="Unequipped" then rebuildAbilities()
 elseif kind=="PetDefeated" then
  rebuildAbilities()
  clearTarget()
  message(tostring((...)).." has fallen. Heal it at the Barn on your plot.")
 elseif kind=="CombatState" then local state=... if state=="Engaging" then message("Companion engaging your target") end
 end
end)
remotes.Pets.OnClientEvent:Connect(function(action,success,response,coinBalance,gemBalance)
 if action=="CollectionReward" then
  local feedback=response or (success and "Collection reward claimed." or "Collection reward unavailable.")
  if success and coinBalance~=nil and gemBalance~=nil then
   feedback=feedback.."  Balance: "..tostring(coinBalance).." Coins · "..tostring(gemBalance).." Gems"
  end
  message(feedback)
  if success and collectionOpen then task.defer(showCollection) end
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
   tonumber(args[10]) or 4.5,
   tonumber(args[11]) or 3,
   tonumber(args[12]) or 0
  )
 elseif action=="Progress" then
  advanceCaptureGame(
   args[1],
   tonumber(args[2]) or 1,
   tonumber(args[3]) or 3,
   tonumber(args[4]) or .2,
   tonumber(args[5]) or .2,
   tonumber(args[6]) or .8,
   tonumber(args[7]) or workspace:GetServerTimeNow(),
   tonumber(args[8]) or 4.5
  )
 elseif action=="Success" then
  local species=args[1] or "Pet"
  local imprint=tonumber(args[4])
  local creatureType=tostring(args[5] or "Pet")
  endCaptureGame(false)
  clearTarget()
  if imprint then
   message("Captured "..tostring(species).."  ·  "..(creatureType=="Mount" and "Mount" or "Pet").."  ·  Imprint "..tostring(imprint).."%")
  end
 elseif action=="Failed" then
  endCaptureGame(true)
  message("Missed — the creature broke free!")
 elseif action=="Error" then
  endCaptureGame(true)
  message(tostring(args[1] or "The lasso attempt failed."))
 end
end)
RunService.RenderStepped:Connect(function(dt)
 hud.Enabled=player:GetAttribute("VillageReady")==true

 local mainUI=playerGui:FindFirstChild("WildernessPetsUI")
 local panelOpen=(mainUI and mainUI:GetAttribute("InventoryOpen")==true) or collectionOpen
 bar.Visible=not panelOpen
 homeButton.Visible=not panelOpen
 collectionButton.Visible=not panelOpen
 if panelOpen then
  tooltip.Visible=false
  targetPanel.Visible=false
 elseif not captureGame and selectedTarget and selectedTarget.Parent and not selectedTarget:GetAttribute("Dead") and not selectedTarget:GetAttribute("Captured") then
  targetPanel.Visible=true
 end

 local currentServerTime=workspace:GetServerTimeNow()
 for index,b in ipairs(abilityButtons) do
  local remaining=math.max(0,(abilityCooldownEnds[index] or 0)-currentServerTime)
  local cooldownLabel=b:FindFirstChild("Cooldown")
  if cooldownLabel and cooldownLabel:IsA("TextLabel") then
   cooldownLabel.Text=remaining>0 and (tostring(math.ceil(remaining)).."s") or ""
  end
  b.BackgroundColor3=remaining>0 and Color3.fromRGB(31,34,38) or palette.slot
  if b:FindFirstChild("Icon") then
   b.Icon.TextColor3=remaining>0 and palette.muted or palette.gold
  end
 end

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

 if collectionOpen then
  collectionSpinAngle=(collectionSpinAngle+dt*.65)%(math.pi*2)
  for index=#collectionSpinners,1,-1 do
   local model=collectionSpinners[index]
   if model and model.Parent then
    model:PivotTo(CFrame.Angles(0,collectionSpinAngle,0))
   else
    table.remove(collectionSpinners,index)
   end
  end
 end
end)
