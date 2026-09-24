local Rope = {}
Rope.__index = Rope
local TAU = math.pi * 2
local function part(parent, name)
    local p = Instance.new("Part")
    p.Name = name
    p.Anchored = true
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.CastShadow = false
    p.Material = Enum.Material.Fabric
    p.Parent = parent
    return p
end
local function beam(parent, a, b, color, width, light)
    local v = Instance.new("Beam")
    v.Attachment0 = a
    v.Attachment1 = b
    v.Color = ColorSequence.new(color)
    v.Width0 = width
    v.Width1 = width
    v.FaceCamera = true
    v.Segments = 1
    v.LightEmission = light
    v.LightInfluence = light > 0.4 and 0 or 0.5
    v.Parent = parent
    return v
end
function Rope.new(parent, style, count, closed)
    local self = {parts = {}, points = {}, accents = {}, beams = {}, style = style, closed = closed, count = count, runes = {}}
    local anchor = part(parent, "RopeGeometry")
    anchor.Transparency = 1
    anchor.Size = Vector3.new(0.05,0.05,0.05)
    anchor.CFrame = CFrame.identity
    self.anchor = anchor
    local n = closed and count or count + 1
    for i=1,n do
        self.points[i] = {}
        for strand=1,3 do
            local a = Instance.new("Attachment")
            a.Parent = anchor
            self.points[i][strand] = a
        end
    end
    for i=1,count do
        local p = part(parent, "BraidedRope")
        p.Shape = Enum.PartType.Cylinder
        p.Color = style.RopeColor
        p.Material = style.Material
        p.Reflectance = math.min(style.Reflectance,0.18)
        self.parts[i] = p
        local nextIndex = closed and (i % count + 1) or i + 1
        for strand=1,3 do
            local color = strand==1 and style.RopeColor:Lerp(style.AccentColor,style.Glow>=0.5 and .8 or .55)
                or (strand==2 and style.RopeColor:Lerp(Color3.new(1,1,1),.10)
                or style.RopeColor:Lerp(Color3.new(0,0,0),.25))
            self.beams[#self.beams+1] = beam(anchor,self.points[i][strand],self.points[nextIndex][strand],color,
                style.BeamWidth*0.32, strand==1 and style.BeamLight or 0)
        end
    end
    if closed and style.Glow >= 0.5 then
        for i=1,(count>=48 and 8 or 4) do
            local rune=part(parent,"LuminousBinding")
            rune.Shape=Enum.PartType.Cylinder
            rune.Material=Enum.Material.Neon
            rune.Color=style.AccentColor
            self.runes[i]=rune
        end
    end
    return setmetatable(self, Rope)
end
function Rope:Update(points, fade)
    fade = fade or 0
    local diameter = self.style.BeamWidth * 0.78
    -- Use the rope's own plane so the braid never flips at vertical tangents.
    local q=points[math.max(2,math.floor(#points*.25))]
    local m=points[math.max(3,math.floor(#points*.5))]
    local plane=(q-points[1]):Cross(m-points[1])
    plane=plane.Magnitude>.0001 and plane.Unit or (self.plane or Vector3.zAxis)
    self.plane=plane
    for i,p in ipairs(points) do
        local nextIndex = self.closed and (i % #points + 1) or math.min(#points,i+1)
        local prevIndex = self.closed and ((i-2)%#points+1) or math.max(1,i-1)
        local tangent = points[nextIndex]-points[prevIndex]
        if tangent.Magnitude<0.001 then tangent=Vector3.yAxis end
        tangent = tangent.Unit
        local normal = tangent:Cross(plane)
        if normal.Magnitude<0.01 then normal=tangent:Cross(Vector3.xAxis) end
        normal=normal.Unit
        local binormal=tangent:Cross(normal).Unit
        local angle=(i-1)/self.count*TAU*(self.closed and 12 or 3)
        for strand=1,3 do
            local phase=angle+(strand-1)*TAU/3
            self.points[i][strand].Position=p+(normal*math.cos(phase)+binormal*math.sin(phase))*diameter*0.46
        end
    end
    for i,p in ipairs(self.parts) do
        local a=points[i]
        local b=points[self.closed and (i % #points+1) or i+1]
        local delta=b-a
        p.Size=Vector3.new(math.max(0.005,delta.Magnitude+diameter*0.15),diameter,diameter)
        p.CFrame=CFrame.lookAt((a+b)*0.5,b)*CFrame.Angles(0,math.pi/2,0)
        p.Transparency=fade
    end
    for i,rune in ipairs(self.runes) do
        local index=1+math.floor((i-1)*self.count/#self.runes)
        local a=points[index]
        local b=points[index % #points+1]
        rune.Size=Vector3.new(diameter*.58,diameter*1.18,diameter*1.18)
        rune.CFrame=CFrame.lookAt(a,b)*CFrame.Angles(0,math.pi/2,0)
        rune.Transparency=fade
    end
    if self.lastFade~=fade then
        local seq=NumberSequence.new(fade)
        for _,b in ipairs(self.beams) do b.Transparency=seq end
        self.lastFade=fade
    end
end
function Rope:Destroy()
    for _,p in ipairs(self.parts) do p:Destroy() end
    for _,p in ipairs(self.runes) do p:Destroy() end
    self.anchor:Destroy()
end
return Rope
