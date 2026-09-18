-- Species-aware procedural animation for the existing segmented meshes.
-- +Z is the authored forward direction. No uploaded animation assets required.
local A = {}
local RunService = game:GetService("RunService")
local rigs = setmetatable({}, {__mode="k"})
local tau = math.pi*2
local profiles = {
 Wolf={walk=7,run=19,stride=3.4,bob=.10,tail=.16,attack="bite"},
 Fox={walk=5,run=15,stride=1.8,bob=.08,tail=.26,attack="pounce"},
 Boar={walk=5,run=15,stride=2.8,bob=.07,tail=.06,attack="charge"},
 Bear={walk=4,run=12,stride=3.7,bob=.12,tail=.03,attack="swipe"},
 Griffin={walk=5,run=14,stride=4,bob=.12,tail=.10,attack="pounce"},
 Dragon={walk=5,run=14,stride=4.5,bob=.13,tail=.13,attack="bite"},
 Leviathan={walk=4,run=11,stride=7,bob=.12,tail=.20,attack="coil"},
 Starling={walk=4,run=10,stride=2.2,bob=.12,tail=.05,attack="peck"},
 AncientTitan={walk=3,run=8,stride=6,bob=.14,tail=.04,attack="stomp"},
}
profiles.MoonBat={walk=5,run=13,stride=3,bob=.10,tail=.04,attack="pounce",hover=.8}
profiles.ShadowStag={walk=5,run=18,stride=3.5,bob=.07,tail=.06,attack="charge"}
local function smooth(x) x=math.clamp(x,0,1) return x*x*(3-2*x) end
local function species(m) return m:GetAttribute("AnimationSpecies") or m:GetAttribute("Species") or m.Name:match("^([^_]+)") end
function A:GetProfile(m) return profiles[species(m)] or profiles.Wolf end
function A:_getRig(m)
 if rigs[m] then return rigs[m] end
 local root=m:FindFirstChild("body_geom",true) or m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart",true)
 if not root then return end
 m.PrimaryPart=root
 local profile=table.clone(self:GetProfile(m))
 local scale=m:GetScale()
 for _,key in {"walk","run","stride","bob","hover"} do if profile[key] then profile[key]*=scale end end
 local r={root=root,base=root.CFrame,parts={},gen=0,phase=math.random()*tau,profile=profile,scale=scale,species=species(m),clearance=0}
 for _,p in m:GetDescendants() do
  if p:IsA("BasePart") then
   local off=root.CFrame:ToObjectSpace(p.CFrame)
   local n=p.Name:lower()
   local kind=n:find("leg") and "leg" or n:find("tail") and "tail" or n:find("head") and "head" or n:find("wing") and "wing" or "body"
   local side=off.X>=0 and 1 or -1
   local rear=n:find("rear") or n:find("back")
   local hinge=off.Position
   if kind=="leg" then hinge+=Vector3.new(0,p.Size.Y*.43,0)
   elseif kind=="head" then hinge+=Vector3.new(0,-p.Size.Y*.22,-p.Size.Z*.28)
   elseif kind=="tail" then hinge+=Vector3.new(0,p.Size.Y*.12,p.Size.Z*.35)
   elseif kind=="wing" then hinge+=Vector3.new(-side*p.Size.X*.40,p.Size.Y*.2,0) end
   table.insert(r.parts,{part=p,offset=off,kind=kind,side=side,rear=rear,hinge=CFrame.new(hinge)})
   local extent=math.abs(off.RightVector.Y)*p.Size.X/2+math.abs(off.UpVector.Y)*p.Size.Y/2+math.abs(off.LookVector.Y)*p.Size.Z/2
   r.clearance=math.max(r.clearance,extent-off.Y)
  end
 end
 r.clearance+=profile.hover or 0
 rigs[m]=r
 return r
end
function A:GroundPosition(m,pos)
 local r=self:_getRig(m) if not r then return pos end
 local displayY=m:GetAttribute("DisplayGroundY")
 if displayY then return Vector3.new(pos.X,displayY+r.clearance+.06,pos.Z) end
 local params=RaycastParams.new()
 local exclude={m}
 for _,player in game:GetService("Players"):GetPlayers() do if player.Character then table.insert(exclude,player.Character) end end
 local world=workspace:FindFirstChild("WildernessPets")
 if world then
  for _,n in {"WildMonsters","Plots","ArenaAnimation"} do local f=world:FindFirstChild(n) if f then table.insert(exclude,f) end end
 end
 params.FilterType=Enum.RaycastFilterType.Exclude
 params.FilterDescendantsInstances=exclude
 local hit=workspace:Raycast(Vector3.new(pos.X,pos.Y+30,pos.Z),Vector3.new(0,-150,0),params)
 if hit and hit.Normal.Y>.65 then return Vector3.new(pos.X,hit.Position.Y+r.clearance+.06,pos.Z) end
 return pos
end
function A:_pose(r,base,t,weight,running,action,power)
 local p=r.profile
 local amp=weight or 0
 local k=power or 0
 local heavy=r.species=="Bear" or r.species=="AncientTitan" or r.species=="Boar"
 local bob=(1-math.cos(t*2))*p.bob*(running and .65 or .3)*amp
 local breath=math.sin(t*.45)*.015*r.scale*(1-amp)
 local pitch=math.sin(t*2)*(running and .035 or .010)*amp
 local roll=math.sin(t)*.016*amp
 local yaw=0 local lift=0
 if r.species=="Leviathan" then yaw=math.sin(t)*.035*amp bob=math.sin(t*2)*p.bob*.35*amp end
 if r.species=="MoonBat" then bob=math.sin(t*1.5)*.09*r.scale pitch=-.06*amp end
 if action=="attack" then
  if p.attack=="pounce" then lift=math.sin(k*math.pi)*math.min(r.clearance*.25,1)*r.scale pitch=-k*.12
  elseif p.attack=="swipe" then pitch=-k*.15 roll=k*.08
  elseif p.attack=="stomp" then lift=math.sin(k*math.pi)*.35*r.scale pitch=-k*.045
  elseif p.attack=="coil" then yaw=k*.12
  else pitch=k*.07 end
 elseif action=="hit" then pitch=-k*.10
 elseif action=="victory" then lift=math.sin(k*math.pi)*math.min(r.clearance*.25,.8*r.scale)
 elseif action=="faint" then roll=k*1.35 lift=-k*r.clearance*.2
 elseif action=="struggle" then yaw=math.sin(t*3)*.045 roll=math.sin(t*2)*.02 end
 local body=base*CFrame.new(0,bob+breath+lift,0)*CFrame.Angles(pitch,yaw,roll)
 for _,i in r.parts do
  if i.part.Parent then
   local x,y,z=0,0,0 local drop=0
   if i.kind=="leg" then
    -- Four-beat walking; paired fore/hind galloping with a small left/right delay.
    local offset
    if running then offset=(i.rear and .50 or 0)+(i.side<0 and .06 or 0)
    else offset=(i.rear and .5 or 0)+(i.side<0 and .75 or .25) end
    if r.species=="Starling" then offset=i.side<0 and .5 or 0 end
    local phase=(t/tau+offset)%1
    local stance=running and .42 or .68
    local length=math.max(.2,(i.hinge.Y-i.offset.Y)+i.part.Size.Y*.5)
    local stride=p.stride*(running and 1.5 or 1)
    local angle=math.asin(math.clamp(stride*stance/(2*length),.12,heavy and .38 or .5))
    local swing=0
    if phase<stance then
     x=(-angle+2*angle*phase/stance)*amp
    else
     local u=(phase-stance)/(1-stance)
     x=(angle-2*angle*smooth(u))*amp
     swing=math.sin(u*math.pi)*(running and .12 or .055)*length*amp
    end
    -- Compensate body bounce and arc lift during stance so paws stay near the floor.
    drop=-bob-breath-length*(1-math.cos(x))+swing
    drop=math.clamp(drop,-length*.10,length*.18)
    if action=="attack" and not i.rear then
     if p.attack=="swipe" then x-=k*(i.side>0 and .65 or .12) z+=k*i.side*.10
     elseif p.attack=="stomp" or p.attack=="pounce" then x-=k*.3 end
    end
    if r.species=="MoonBat" then x=.12+.06*math.sin(t) drop=0 end
   elseif i.kind=="tail" then
    y=math.sin(t*.65-.7)*p.tail*(.3+amp*.5)
    x=running and -.04*amp or 0
   elseif i.kind=="head" then
    x=-pitch*.65+math.sin(t*.6)*.010*(1-amp)
    y=-yaw*.6+math.sin(t*.33)*.035*(1-amp)
    if action=="attack" then x+=k*(p.attack=="peck" and .32 or p.attack=="charge" and .18 or .09) end
   elseif i.kind=="wing" then
    if r.species=="MoonBat" then
     z=i.side*(.18+math.sin(t*2.2)*.48)
    else
     z=i.side*(math.sin(t*.8)*.015+amp*.045*math.sin(t)+k*.18)
    end
   end
   i.part.CFrame=body*CFrame.new(0,drop,0)*i.hinge*CFrame.Angles(x,y,z)*i.hinge:Inverse()*i.offset
  end
 end
end
function A:Stop(m)
 local r=rigs[m] if not r then return end
 r.gen+=1
 for _,i in r.parts do if i.part.Parent then i.part.CFrame=r.base*i.offset end end
 m:SetAttribute("AnimationState","Stopped")
end
function A:PlayIdle(m)
 local r=self:_getRig(m) if not r then return end
 r.gen+=1 local token=r.gen
 m:SetAttribute("AnimationState","Idle")
 task.spawn(function()
  local previous=os.clock()
  while m.Parent and r.root.Parent and r.gen==token do
   local now=os.clock() r.phase+=(now-previous)*1.4 previous=now
   self:_pose(r,r.base,r.phase,0,false)
   task.wait(1/30)
  end
 end)
end
function A:MoveTo(m,target,running,duration)
 local r=self:_getRig(m) if not r then return false end
 r.gen+=1 local token=r.gen
 local start=r.base
 target=self:GroundPosition(m,target)
 local direction=Vector3.new(target.X-start.X,0,target.Z-start.Z)
 local distance=direction.Magnitude
 if distance<.05 then self:PlayIdle(m) return true end
 local face=CFrame.lookAt(Vector3.zero,-direction.Unit)
 local speed=running and r.profile.run or r.profile.walk
 duration=math.max(.1,duration or distance/speed*1.2)
 m:SetAttribute("AnimationState",running and "Run" or "Walk")
 local began=os.clock() local previous=0
 while true do
  if not m.Parent or not r.root.Parent or r.gen~=token then return false end
  if m:GetAttribute("Dead") or m:GetAttribute("BeingCaptured") or m:GetAttribute("Captured") or m:GetAttribute("InCombat") then self:Stop(m) return false end
  local u=math.clamp((os.clock()-began)/duration,0,1)
  local alpha=smooth(u)
  r.phase+=(alpha-previous)*distance/(r.profile.stride*(running and 1.5 or 1))*tau previous=alpha
  local pos=start.Position:Lerp(target,alpha)
  local rotation=start.Rotation:Lerp(face,smooth(math.min(u*5,1)))
  r.base=CFrame.new(pos)*rotation
  local blend=smooth(math.min(u*8,(1-u)*8,1))
  self:_pose(r,r.base,r.phase,blend,running)
  if u>=1 then break end
  task.wait(1/30)
 end
 self:PlayIdle(m) return true
end
function A:PlayWalkTo(m,target,duration) return self:MoveTo(m,target,false,duration) end
function A:PlayRunTo(m,target,duration) return self:MoveTo(m,target,true,duration) end
function A:_action(m,kind,duration,target,onImpact,maxLunge)
 local r=self:_getRig(m) if not r then return false end
 r.gen+=1 local token=r.gen
 local start=r.base
 local face=start.Rotation local distance=0
 if target then
  local dir=Vector3.new(target.X-start.X,0,target.Z-start.Z)
  if dir.Magnitude>.01 then face=CFrame.lookAt(Vector3.zero,-dir.Unit) distance=math.min(dir.Magnitude*.35,r.profile.attack=="charge" and 5 or 2.5) end
 end
 if maxLunge then distance=math.min(distance,maxLunge) end
 m:SetAttribute("AnimationState",kind)
 local began=os.clock() local fired=false
 while true do
  if not m.Parent or not r.root.Parent or r.gen~=token then return false end
  local u=math.clamp((os.clock()-began)/math.max(duration,.05),0,1)
  -- Anticipation, fast contact, then a slower recovery.
  local k=u<.25 and -.18*smooth(u/.25) or u<.45 and -.18+1.18*smooth((u-.25)/.20) or 1-smooth((u-.45)/.55)
  local base=CFrame.new(start.Position)*start.Rotation:Lerp(face,smooth(math.min(u*5,1)))
  if kind=="attack" then base+=face.ZVector*distance*k
  elseif kind=="hit" then base-=start.ZVector*math.sin(u*math.pi)*.35 end
  self:_pose(r,base,r.phase+u*tau,0,false,kind,kind=="faint" and smooth(u) or kind=="victory" and u or k)
  if u>=.45 and not fired then fired=true if onImpact then onImpact() end end
  if u>=1 then break end
  task.wait(1/30)
 end
 if kind=="attack" then r.base=CFrame.new(start.Position)*face end
 if kind~="faint" then self:Stop(m) end
 return true
end
function A:PlayAttack(m,target,duration,onImpact,maxLunge) return self:_action(m,"attack",duration or .75,target,onImpact,maxLunge) end
function A:PlayHit(m,duration) return self:_action(m,"hit",duration or .3) end
function A:PlayStruggle(m,duration) return self:_action(m,"struggle",duration or .75) end
function A:PlayCaptured(m,duration) return self:_action(m,"victory",duration or .4) end
function A:PlayFaint(m,duration) return self:_action(m,"faint",duration or .7) end
function A:PlayVictory(m,duration) local ok=self:_action(m,"victory",duration or .8) if ok then self:PlayIdle(m) end return ok end

-- Capture retaliation follows the live target; it never teleports to a saved position.
function A:CanMeleeHit(m,target)
 if not target or not target.Parent then return false end
 local r=self:_getRig(m) if not r then return false end
 local closest, gap= nil, math.huge
 for _,i in r.parts do
  if i.part.Parent and i.kind~="tail" and i.kind~="wing" then
   local p=i.part
   local q=p.CFrame:PointToObjectSpace(target.Position)
   local h=p.Size/2
   local point=p.CFrame:PointToWorldSpace(Vector3.new(math.clamp(q.X,-h.X,h.X),math.clamp(q.Y,-h.Y,h.Y),math.clamp(q.Z,-h.Z,h.Z)))
   local d=(point-target.Position).Magnitude
   if d<gap then closest=point gap=d end
  end
 end
 if gap>2.5 or not closest then return false end
 local params=RaycastParams.new()
 params.FilterType=Enum.RaycastFilterType.Exclude
 params.FilterDescendantsInstances={m,target.Parent}
 local delta=target.Position-closest
 local hit=delta.Magnitude>.01 and workspace:Raycast(closest,delta,params)
 return not hit
end
function A:ChaseTarget(m,getTarget,timeout)
 local r=self:_getRig(m) if not r then return false end
 r.gen+=1 local token=r.gen
 local start=r.base.Position
 local began=os.clock() local previous=began local speed=0
 local reach=2
 for _,i in r.parts do
  if i.kind=="head" or i.kind=="body" then
   reach=math.max(reach,i.offset.Z+i.part.Size.Z*.5+1.0)
  end
 end
 reach=math.clamp(reach,2.5,12)
 m:SetAttribute("AnimationState","Run")
 local params=RaycastParams.new()
 params.FilterType=Enum.RaycastFilterType.Exclude
 while os.clock()-began<(timeout or 8) do
  if not m.Parent or not r.root.Parent or token~=r.gen then return false end
  if m:GetAttribute("Dead") or m:GetAttribute("Captured") or m:GetAttribute("BeingCaptured") then break end
  local target=getTarget()
  if not target or not target.Parent then break end
  local delta=Vector3.new(target.Position.X-r.base.X,0,target.Position.Z-r.base.Z)
  if (target.Position-start).Magnitude>90 then break end
  if delta.Magnitude<=reach and self:CanMeleeHit(m,target) then self:Stop(m) return true end
  if delta.Magnitude<.05 then break end
  local now=os.clock() local dt=math.clamp(now-previous,0,.10) previous=now
  speed=math.min(r.profile.run,speed+r.profile.run*3*dt)
  local step=math.min(speed*dt,math.max(0,delta.Magnitude-1))
  local direction=delta.Unit
  local world=workspace:FindFirstChild("WildernessPets")
  params.FilterDescendantsInstances={world and world:FindFirstChild("WildMonsters") or m,target.Parent}
  local obstacle=workspace:Raycast(r.base.Position,direction*(step+1),params)
  if obstacle then break end
  local nextPos=self:GroundPosition(m,r.base.Position+direction*step)
  if math.abs(nextPos.Y-r.base.Y)>3 then break end
  local face=CFrame.lookAt(Vector3.zero,-direction)
  r.base=CFrame.new(nextPos)*r.base.Rotation:Lerp(face,1-math.exp(-10*dt))
  r.phase+=step/(r.profile.stride*1.5)*tau
  self:_pose(r,r.base,r.phase,math.min(1,speed/r.profile.run),true)
  task.wait(1/30)
 end
 if m.Parent and r.root.Parent and r.gen==token then self:Stop(m) end
 return false
end

return A
