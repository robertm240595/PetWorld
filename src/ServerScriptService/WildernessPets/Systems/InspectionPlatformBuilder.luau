local B={}
local NAME="TEMP_ASSET_INSPECTION_PLATFORM_REMOVE_AFTER_REVIEW"
local function list(f)
local t={}
if f then for _,x in ipairs(f:GetChildren()) do if x:IsA("Model") then table.insert(t,x) end end end
table.sort(t,function(a,b)return a.Name<b.Name end)
return t
end
local function freeze(m)
for _,x in ipairs(m:GetDescendants()) do
if x:IsA("BaseScript") then x.Disabled=true
elseif x:IsA("BasePart") then x.Anchored=true;x.CanCollide=false;x.CanTouch=false;x.CanQuery=false end
end
end
local function label(m,n,k)
local p=m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart",true)
if not p then return false end
local g=Instance.new("BillboardGui");g.Name="InspectionNameLabel";g.Adornee=p;g.AlwaysOnTop=true;g.Size=UDim2.fromOffset(220,42);g.StudsOffsetWorldSpace=Vector3.new(0,math.max(4,m:GetExtentsSize().Y*.55+2),0);g.Parent=m
local l=Instance.new("TextLabel");l.Size=UDim2.fromScale(1,1);l.Text=n.." - "..k;l.TextScaled=true;l.Parent=g
return true
end
function B.Build()
local old=workspace:FindFirstChild(NAME);if old then return old end
local s=game:GetService("ServerStorage"):FindFirstChild("WildernessPets");if not s then return nil end
local c=list(s:FindFirstChild("Monsters"));local n=list(s:FindFirstChild("NPCs"));local e={}
for _,x in ipairs(c) do table.insert(e,{x,"CREATURE"}) end
for _,x in ipairs(n) do table.insert(e,{x,"NPC"}) end
local w=workspace:FindFirstChild("WildernessPets");local ps=w and w:FindFirstChild("Plots");local pf=ps and ps:FindFirstChildWhichIsA("Folder");local sp=pf and pf:FindFirstChild("Spawn",true)
local o=(sp and sp:IsA("BasePart") and sp.Position or Vector3.zero)+Vector3.new(0,250,0);local rows=math.max(1,math.ceil(#e/10))
local root=Instance.new("Model");root.Name=NAME;root:SetAttribute("TemporaryInspectionPlatform",true);root:SetAttribute("ExpectedCreatureDisplays",#c);root:SetAttribute("ExpectedNPCDisplays",#n);root:SetAttribute("ExpectedTotalDisplays",#e);root.Parent=workspace
local deck=Instance.new("Part");deck.Name="InspectionDeck";deck.Anchored=true;deck.Size=Vector3.new(324,2,rows*30+24);deck.Position=o;deck.Material=Enum.Material.Slate;deck.Parent=root
local lc=0
for i,v in ipairs(e) do
local x=o.X+(((i-1)%10)-4.5)*30;local z=o.Z+(math.floor((i-1)/10)-(rows-1)/2)*30
local m=v[1]:Clone();m.Name=string.format("%03d_%s_%s",i,v[2],v[1].Name);m:SetAttribute("InspectionSourceName",v[1].Name);m:SetAttribute("InspectionKind",v[2]);freeze(m);m.Parent=root;m:PivotTo(CFrame.new(x,o.Y+10,z))
local cf,sz=m:GetBoundingBox();m:PivotTo(m:GetPivot()+Vector3.new(0,o.Y+1.2-(cf.Position.Y-sz.Y*.5),0));if label(m,v[1].Name,v[2]) then lc+=1 end
end
root:SetAttribute("ActualDisplayCount",#e);root:SetAttribute("ActualLabelCount",lc);return root
end
return B