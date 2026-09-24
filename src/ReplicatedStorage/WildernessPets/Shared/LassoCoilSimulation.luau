-- Fixed-length turns, independently suspended from the palm.
-- Only rigid rotations are applied to each turn: no vertex springs or scaling.
local Rope=require(script.Parent.LassoRopeGeometry)
local Coil={}
Coil.__index=Coil
local COUNT=40
local TAU=math.pi*2
function Coil.new(parent,style)
    local self=setmetatable({turns={}},Coil)
    for i=1,4 do
        local folder=Instance.new("Folder")
        folder.Name="LeftCoilTurn"..i folder.Parent=parent
        local turn={rope=Rope.new(folder,style,COUNT,true),nodes={},rest={},swing=Vector3.zero,velocity=Vector3.zero}
        local width=.43-(i-1)*.024
        local height=.75-(i-1)*.025
        for n=1,COUNT do
            local a=(n-1)/COUNT*TAU
            local free=(1-math.cos(a))*.5
            turn.rest[n]=Vector3.new(math.sin(a)*width*(.83+.17*free),-(1-math.cos(a))*height,0)
        end
        self.turns[i]=turn
    end
    return self
end
function Coil:Update(grip,root,dt,now,tugTime)
    local origin=grip.Position
    local movement=self.lastGrip and origin-self.lastGrip or Vector3.zero
    local reset=not self.lastGrip or movement.Magnitude>5 or dt>.15
    local handVelocity=reset and Vector3.zero or movement/math.max(dt,.001)
    local acceleration=reset and Vector3.zero or (handVelocity-(self.lastVelocity or handVelocity))/math.max(dt,.001)
    self.lastGrip=origin self.lastVelocity=handVelocity
    local horizontalVelocity=Vector3.new(handVelocity.X,0,handVelocity.Z)
    local drive=-horizontalVelocity*.010
    if drive.Magnitude>.27 then drive=drive.Unit*.27 end
    local impulse=Vector3.new(-acceleration.X,0,-acceleration.Z)*.0007
    if impulse.Magnitude>.10 then impulse=impulse.Unit*.10 end
    drive+=impulse
    local right=Vector3.new(root.RightVector.X,0,root.RightVector.Z)
    right=right.Magnitude>.001 and right.Unit or Vector3.xAxis
    local back=right:Cross(Vector3.yAxis)
    local motion=math.clamp(horizontalVelocity.Magnitude/12,0,1)
    local steps=math.clamp(math.ceil(dt*120),1,8)
    local h=math.min(dt,.0667)/steps
    local tugAge=now-(tugTime or 0)
    local tug=tugAge>=0 and tugAge<1 and math.sin(tugAge*10)*math.exp(-tugAge*3.5) or 0
    for index,turn in ipairs(self.turns) do
        if reset then turn.swing=Vector3.zero turn.velocity=Vector3.zero end
        local phase=index*.85
        -- Different natural periods make the turns fan out and settle separately.
        local target=drive*(.86+index*.07)
            +right*(math.sin(now*1.55+phase)*.016)
            +back*(math.sin(now*1.85+phase)*.012
                +math.sin(now*7.2+phase)*.026*motion+tug*.13)
        local stiffness=16+index*2.3
        local damping=3.6+index*.18
        for _=1,steps do
            turn.velocity+=((target-turn.swing)*stiffness-turn.velocity*damping)*h
            turn.swing+=turn.velocity*h
            if turn.swing.Magnitude>.42 then
                turn.swing=turn.swing.Unit*.42
                local outward=turn.velocity:Dot(turn.swing.Unit)
                if outward>0 then turn.velocity-=turn.swing.Unit*outward end
            end
        end
        local down=(Vector3.new(0,-1,0)+turn.swing).Unit
        local x=(right-down*right:Dot(down)).Unit
        local z=x:Cross(-down).Unit
        local fan=math.rad((index-2.5)*7)+math.sin(now*1.15+phase)*.045
        local pin=origin+back*((index-2.5)*.067)
        local frame=CFrame.fromMatrix(pin,x,-down,z)*CFrame.Angles(0,fan,0)
        for n,point in ipairs(turn.rest) do
            turn.nodes[n]=frame:PointToWorldSpace(point)
        end
        turn.rope:Update(turn.nodes)
    end
end
return Coil
