-- Two-handed lasso presentation. Gameplay stays server-authoritative.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("WildernessPets"):WaitForChild("Shared")
local Styles = require(Shared:WaitForChild("LassoVisuals"))
local Rope = require(Shared:WaitForChild("LassoRopeGeometry"))
local Coil = require(Shared:WaitForChild("LassoCoilSimulation"))
local Motion = require(Shared:WaitForChild("LassoMotion"))
local states = {}
local TAU = math.pi*2
local function smooth(t) t=math.clamp(t,0,1) return t*t*(3-2*t) end
local function makePart(parent,name)
    local p=Instance.new("Part")
    p.Name=name p.Size=Vector3.new(.1,.1,.1) p.Transparency=1
    p.Anchored=true p.CanCollide=false p.CanTouch=false p.CanQuery=false p.CastShadow=false
    p.Parent=parent return p
end
local function ik(character,side)
    local hand=character:FindFirstChild(side.."Hand")
    local arm=character:FindFirstChild(side.."UpperArm")
    local root=character:FindFirstChild("HumanoidRootPart")
    local humanoid=character:FindFirstChildOfClass("Humanoid")
    if not hand or not arm or not root or not humanoid then return end
    local target=Instance.new("Attachment")
    target.Name="Lasso"..side.."Pose" target.Parent=root
    local pole=Instance.new("Attachment")
    pole.Name="Lasso"..side.."Elbow"
    pole.Position=Vector3.new(side=="Right" and 1.4 or -1.4,-.8,.2)
    pole.Parent=root
    local control=Instance.new("IKControl")
    control.Name="Lasso"..side.."IK"
    control.Type=Enum.IKControlType.Position
    control.ChainRoot=arm control.EndEffector=hand control.Target=target control.Pole=pole
    control.Priority=20 control.SmoothTime=.035 control.Weight=1
    control.Parent=humanoid
    return {control=control,target=target,pole=pole}
end
local function restoreHeldMesh(s)
    for _,entry in ipairs(s.hidden or {}) do
        if entry.object.Parent then entry.object[entry.property]=entry.value end
    end
    s.hidden={}
    s.hiddenVisuals={}
end
local function hideOneHeldMesh(s,visual)
    if not visual then return end
    local firstHide=not s.hiddenVisuals[visual]
    s.hiddenVisuals[visual]=true
    for _,v in ipairs(visual:GetDescendants()) do
        local property
        if v:IsA("BasePart") and v.Name~="GripBinding" then property="LocalTransparencyModifier"
        elseif v:IsA("Light") or v:IsA("ParticleEmitter") then property="Enabled" end
        if property then
            if firstHide then
                table.insert(s.hidden,{object=v,property=property,value=v[property]})
            end
            -- Reapply every frame: passive displays can be refreshed after
            -- the new renderer has mounted.
            v[property]=property=="LocalTransparencyModifier" and 1 or false
        end
    end
end
local function hideLegacyHeldMeshes(s,character)
    s.hiddenVisuals=s.hiddenVisuals or {}
    local tool=character:FindFirstChild("Lasso")
    hideOneHeldMesh(s,tool and tool:FindFirstChild("LassoVisual"))
    hideOneHeldMesh(s,character:FindFirstChild("EquippedLassoDisplay"))
end
local function destroy(s)
    restoreHeldMesh(s)
    s.folder:Destroy()
    for _,rig in pairs(s.iks) do
        rig.control:Destroy() rig.target:Destroy() rig.pole:Destroy()
    end
end
local function create(player,character)
    local folder=Instance.new("Folder")
    folder.Name="LassoPresentation_"..player.UserId folder.Parent=workspace
    local style=Styles.GetStyle(player:GetAttribute("EquippedLassoName") or "Rough Rope",player:GetAttribute("EquippedLassoSkin"))
    local s={player=player,character=character,folder=folder,style=style,iks={},hidden={},hiddenVisuals={},lag=Vector3.zero,
        lagVelocity=Vector3.zero,ratio=0,phase="Idle",lastHits=0}
    s.loop=Rope.new(folder,style,48,true)
    s.coil=Coil.new(folder,style)
    s.feed=Rope.new(folder,style,12,false)
    s.line=Rope.new(folder,style,18,false)
    s.knot=makePart(folder,"HondaKnot")
    s.knot.Shape=Enum.PartType.Ball
    s.knot.Size=Vector3.new(.17,.19,.17)
    s.knot.Transparency=0 s.knot.Color=style.AccentColor s.knot.Material=style.Material
    local glow=Instance.new("PointLight")
    glow.Color=style.AccentColor glow.Range=3.5 glow.Brightness=style.Glow*.45
    glow.Parent=s.knot s.light=glow
    local emitter=Instance.new("ParticleEmitter")
    emitter.Name="LassoMotes" emitter.Texture="rbxasset://textures/particles/sparkles_main.dds"
    emitter.Color=ColorSequence.new(style.AccentColor)
    emitter.LightEmission=1 emitter.Rate=style.ParticleRate or 0
    emitter.Lifetime=NumberRange.new(.3,.65) emitter.Speed=NumberRange.new(.15,.5)
    emitter.SpreadAngle=Vector2.new(180,180)
    emitter.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,.055),NumberSequenceKeypoint.new(1,0)})
    emitter.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.2),NumberSequenceKeypoint.new(1,1)})
    emitter.Parent=s.knot s.emitter=emitter
    for _,joint in ipairs(character:GetDescendants()) do
        if joint.Name=="Waist" and (joint:IsA("Motor6D") or joint:IsA("AnimationConstraint")) then
            s.waist=joint
            if joint:IsA("AnimationConstraint") then break end
        end
    end
    s.iks.Right=ik(character,"Right")
    s.iks.Left=ik(character,"Left")
    s.key=tostring(player:GetAttribute("EquippedLassoName")).."/"..tostring(player:GetAttribute("EquippedLassoSkin"))
    return s
end
local function hasLasso(player,character)
    if character and character:FindFirstChild("Lasso") then return true end
    local backpack=player:FindFirstChildOfClass("Backpack")
    if backpack and backpack:FindFirstChild("Lasso") then return true end
    return type(player:GetAttribute("EquippedLassoName"))=="string"
        and player:GetAttribute("EquippedLassoName")~=""
end
local function pose(s,now)
    local c=s.character
    local root=c:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local head=c:FindFirstChild("Head")
    local headHeight=head and root.CFrame:PointToObjectSpace(head.Position).Y or 1.6
    local top=math.clamp(headHeight+.68,1.8,3.1)
    local phase=c:GetAttribute("LassoPhase") or "Idle"
    local elapsed=now-(c:GetAttribute("LassoCastStart") or now)
    local idle=Vector3.new(1.05,-.15,-.64)
    local overhead=Vector3.new(.62,top,-.2)
    local right=idle
    local left=Vector3.new(-1.10,-.48,-.42)
    if phase=="Casting" then
        if elapsed<Motion.Raise then
            right=idle:Lerp(overhead,smooth(elapsed/Motion.Raise))
        elseif elapsed<Motion.Raise+Motion.Revolution then
            local a=math.clamp((elapsed-Motion.Raise)/Motion.Revolution,0,1)*TAU
            right=Vector3.new(.62+.40*math.sin(a),top+.06*math.sin(a*2),-.60+.40*math.cos(a))
        else
            right=overhead:Lerp(Vector3.new(.95,.65,-1.50),smooth((elapsed-Motion.Raise-Motion.Revolution)/Motion.Release))
        end
        left=Vector3.new(-.95,-.10,-.68)
    elseif phase=="Holding" then
        local tug=math.sin(math.clamp((now-(c:GetAttribute("LassoTugTime") or 0))/.34,0,1)*math.pi)
        right=Vector3.new(.98,.15,-1.12):Lerp(Vector3.new(.85,.35,-.48),tug)
        left=Vector3.new(-.90,-.1,-.65)
    elseif phase=="Success" or phase=="Failed" then
        right=Vector3.new(.95,.3,-1.05):Lerp(idle,smooth((now-(c:GetAttribute("LassoFinishTime") or now))/Motion.Recovery))
    end
    for side,rig in pairs(s.iks) do
        rig.target.Position=side=="Right" and right or left
        rig.pole.Position = side=="Right" and phase=="Casting"
            and Vector3.new(1.6,top*.55,.1)
            or Vector3.new(side=="Right" and 1.4 or -1.4,-.8,.2)
    end
    s.phase=phase s.elapsed=elapsed s.top=top
end
local function curve(a,b,sag,count)
    local points={}
    for i=0,count do
        local t=i/count
        points[i+1]=a:Lerp(b,t)+Vector3.new(0,-4*sag*t*(1-t),0)
    end
    return points
end
local function render(s,dt,now)
    local c=s.character
    local root=c:FindFirstChild("HumanoidRootPart")
    local hand=c:FindFirstChild("RightHand") or c:FindFirstChild("Right Arm")
    local left=c:FindFirstChild("LeftHand") or c:FindFirstChild("Left Arm")
    if not root or not hand or not left then return end
    local targetValue=c:FindFirstChild("LassoTarget")
    local target=targetValue and targetValue.Value
    if target and target.Parent then
        local cf,size
        if target:IsA("Model") then cf,size=target:GetBoundingBox() else cf,size=target.CFrame,target.Size end
        s.targetCF=cf s.targetSize=size
    end
    local phase=s.phase
    local elapsed=s.elapsed
    local rightGrip=hand.Position+Vector3.new(0,-.06,0)
    local leftGrip=left.Position+Vector3.new(0,-.06,0)
    local targetLag=-root.AssemblyLinearVelocity*.019
    targetLag+=root.CFrame.RightVector*(math.sin(now*1.7)*.025)+root.CFrame.LookVector*(math.sin(now*1.3)*.020)
    if s.lastHand then
        local relative=(rightGrip-s.lastHand)/math.max(dt,.001)-root.AssemblyLinearVelocity
        targetLag+=relative*-.006
    end
    s.lastHand=rightGrip
    if targetLag.Magnitude>.43 then targetLag=targetLag.Unit*.43 end
    local step=math.min(dt,1/30)
    s.lagVelocity+=(targetLag-s.lag)*27*step-s.lagVelocity*6.8*step
    s.lag+=s.lagVelocity*step
    local down=(Vector3.new(0,-1,0)+s.lag).Unit
    local x=root.CFrame.RightVector
    x=(x-down*x:Dot(down)).Unit
    local z=x:Cross(down).Unit
    local idleCF=CFrame.fromMatrix(rightGrip+down*.72,x,-down,-z)
    local cf=idleCF
    local rx,ry=.52,.72
    local fade=0
    local startFlight=Motion.Raise+Motion.Revolution+Motion.Release
    if phase=="Casting" then
        local spinT=math.clamp((elapsed-Motion.Raise)/Motion.Revolution,0,1)
        local a=spinT*TAU
        local spinCF=root.CFrame*CFrame.new(.4+math.sin(a)*.28,s.top+.32,-.55+math.cos(a)*.28)*CFrame.Angles(-math.pi/2,0,a)
        if elapsed<Motion.Raise then
            cf=idleCF:Lerp(spinCF,smooth(elapsed/Motion.Raise))
            rx=.52+1.08*smooth(elapsed/Motion.Raise) ry=.72+.60*smooth(elapsed/Motion.Raise)
        elseif elapsed<startFlight then
            cf=spinCF rx=1.60 ry=1.32
            s.releaseCF=cf
        elseif s.targetCF then
            local t=smooth((elapsed-startFlight)/Motion.Flight)
            local origin=s.releaseCF or spinCF
            local dest=s.targetCF*CFrame.Angles(math.pi/2,0,0)
            local arc=Vector3.new(0,math.sin(t*math.pi)*2.0,0)
            cf=origin:Lerp(dest,t)+arc
            rx=1.60+(math.max(.6,s.targetSize.X*.58)-1.60)*t
            ry=1.32+(math.max(.5,s.targetSize.Z*.58)-1.32)*t
        end
    elseif phase=="Holding" and s.targetCF then
        local hits=c:GetAttribute("LassoHits") or 0
        local required=c:GetAttribute("LassoRequiredHits") or 3
        local ratio=hits/math.max(1,required)
        s.ratio+=(ratio-s.ratio)*math.min(1,dt*14)
        local scale=1.16-.30*s.ratio
        rx=math.max(.6,s.targetSize.X*.5)*scale
        ry=math.max(.5,s.targetSize.Z*.5)*scale
        cf=s.targetCF*CFrame.Angles(math.pi/2,0,0)
        if hits>s.lastHits then s.emitter:Emit(5) end
        s.lastHits=hits
    elseif (phase=="Success" or phase=="Failed") and s.lastCF then
        local t=smooth((now-(c:GetAttribute("LassoFinishTime") or now))/Motion.Recovery)
        local start=s.finishCF or s.lastCF
        if not s.finishCF then
            s.finishCF=s.lastCF s.finishRX=s.lastRX s.finishRY=s.lastRY
            if phase=="Success" then s.emitter:Emit(24) end
        end
        cf=start:Lerp(idleCF,t)
        rx=s.finishRX+(.52-s.finishRX)*t
        ry=s.finishRY+(.72-s.finishRY)*t
        s.ratio=0
    else
        s.ratio=0 s.lastHits=0 s.releaseCF=nil s.finishCF=nil
    end
    if phase=="Casting" or phase=="Holding" then s.finishCF=nil end
    s.lastCF=cf s.lastRX=rx s.lastRY=ry
    local points={}
    -- A rope loop flexes as tension travels around it: the trailing edge lags,
    -- the oval breathes and the rim ripples instead of rotating as a rigid ring.
    local spin=math.clamp((elapsed-Motion.Raise)/Motion.Revolution,0,1)*TAU
    local spinning=phase=="Casting" and elapsed<startFlight
    local flight=phase=="Casting" and elapsed>=startFlight
    local flexWeight=spinning and smooth(elapsed/Motion.Raise) or
        (flight and (1-math.clamp((elapsed-startFlight)/Motion.Flight,0,1))*.65 or 0)
    local idleWeight=(phase=="Idle" or phase=="Success" or phase=="Failed") and 1 or 0
    local oval=math.sin(spin*2-.5)*.11*flexWeight
    for i=1,48 do
        local a=(i-1)/48*TAU+math.pi/2
        local travellingWave=math.sin(a*3-spin*2.2)*.065*flexWeight
        local stretch=1+travellingWave
        -- The knot stays at the grip; free rope below it responds most.
        local freeWeight=(1-math.sin(a))*.5
        local soft=idleWeight*freeWeight*math.sin(now*2.4+a*2)*.032
        local px=math.cos(a)*rx*(1+oval)*stretch
        local py=math.sin(a)*ry*(1-oval*.75)*stretch-soft
        local pz=math.sin(a*2-spin*1.7)*.13*flexWeight
            + math.sin(now*2.1+a*3)*.042*idleWeight*freeWeight
        points[i]=cf:PointToWorldSpace(Vector3.new(px,py,pz))
    end
    s.loop:Update(points,fade)
    local knot=points[1]
    s.knot.CFrame=CFrame.new(knot)
    s.line:Update(curve(rightGrip,knot,phase=="Idle" and .035 or .12,18))
    s.feed:Update(curve(leftGrip,rightGrip,.40+s.lag.Magnitude*.15,12))
    s.coil:Update(CFrame.new(leftGrip),root.CFrame,dt,now,c:GetAttribute("LassoTugTime"))
    s.light.Brightness=s.style.Glow*.45*(.9+.1*math.sin(now*2))
end

RunService.PreAnimation:Connect(function()
    local now=workspace:GetServerTimeNow()
    local camera=workspace.CurrentCamera
    for _,player in ipairs(Players:GetPlayers()) do
        local c=player.Character
        local root=c and c:FindFirstChild("HumanoidRootPart")
        local humanoid=c and c:FindFirstChildOfClass("Humanoid")
        local equipped=c and hasLasso(player,c)
        local inRange=root and camera and (root.Position-camera.CFrame.Position).Magnitude<160
        local key=tostring(player:GetAttribute("EquippedLassoName")).."/"..tostring(player:GetAttribute("EquippedLassoSkin"))
        local s=states[player]
        if s and (s.character~=c or not equipped or not inRange or not humanoid or humanoid.Health<=0 or s.key~=key) then
            destroy(s) states[player]=nil s=nil
        end
        if equipped and inRange and humanoid and humanoid.Health>0 then
            if not s then s=create(player,c) states[player]=s end
            hideLegacyHeldMeshes(s,c)
            pose(s,now)
        end
    end
    for player,s in pairs(states) do
        if not player.Parent then destroy(s) states[player]=nil end
    end
end)
RunService.PreSimulation:Connect(function()
    local now=workspace:GetServerTimeNow()
    for _,s in pairs(states) do
        if s.waist and s.waist.Parent then
            local twist,lean=0,0
            if s.phase=="Casting" then
                local t=math.clamp((s.elapsed-Motion.Raise)/Motion.Revolution,0,1)
                local weight=smooth(s.elapsed/Motion.Raise)
                twist=math.sin(t*TAU)*.13*weight
                lean=-.055*weight
            elseif s.phase=="Holding" then
                local tug=math.sin(math.clamp((now-(s.character:GetAttribute("LassoTugTime") or 0))/.34,0,1)*math.pi)
                twist=-.06*tug lean=.06*tug
            end
            -- Animator supplies the base pose each frame. Add a restrained
            -- weight shift while preserving locomotion and the IK hand reach.
            s.waist.Transform=CFrame.Angles(lean,twist,0)*s.waist.Transform
        end
    end
end)
RunService:BindToRenderStep("TwoHandedLasso",Enum.RenderPriority.Character.Value+1,function(dt)
    local now=workspace:GetServerTimeNow()
    for _,s in pairs(states) do render(s,dt,now) end
end)
