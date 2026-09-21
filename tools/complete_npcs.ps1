$ErrorActionPreference = "Stop"
$exe = "C:\Users\robert\AppData\Local\Roblox\Versions\version-574ecee7ee2b4e60\StudioMCP.exe"
$manifestPath = "D:\Roblox games\generated_npc_assets_20260920.json"
$psi=New-Object Diagnostics.ProcessStartInfo
$psi.FileName=$exe;$psi.UseShellExecute=$false;$psi.RedirectStandardInput=$true;$psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true
$p=New-Object Diagnostics.Process;$p.StartInfo=$psi;[void]$p.Start()
$script:rid=0
function Rpc($method,$params){
 $script:rid++;$id=$script:rid
 $req=@{jsonrpc="2.0";id=$id;method=$method;params=$params}|ConvertTo-Json -Compress -Depth 30
 $p.StandardInput.WriteLine($req);$p.StandardInput.Flush()
 while($true){$line=$p.StandardOutput.ReadLine();if($null -eq $line){throw "StudioMCP closed"}
  try{$o=$line|ConvertFrom-Json}catch{continue};if($o.id -eq $id){return $o}}
}
function Tool($name,$arguments){Rpc "tools/call" @{name=$name;arguments=$arguments}}
$null=Rpc "initialize" @{protocolVersion="2024-11-05";capabilities=@{};clientInfo=@{name="PetWorld NPC finisher";version="1.0"}}
$p.StandardInput.WriteLine('{"jsonrpc":"2.0","method":"notifications/initialized","params":{}}');$p.StandardInput.Flush()
$st=Tool "list_roblox_studios" @{};$sd=$st.result.content[0].text|ConvertFrom-Json
$studio=($sd.studios|?{$_.name -eq "PetWorldOL.rbxl"}|select -First 1).id
if(-not $studio){throw "Studio not found"}
$specs=@(
 [pscustomobject]@{key="Rowan";prompt="Warden Rowan, rugged male wilderness warden and beast handler, olive green tunic, weathered brown leather straps, practical boots, confident ranger silhouette"},
 [pscustomobject]@{key="Bram";prompt="Quartermaster Bram, sturdy male village quartermaster, brown and tan work clothes, leather belt pouches, utility vest and practical boots"},
 [pscustomobject]@{key="Anya";prompt="Beast Healer Anya, compassionate female fantasy animal healer, sage green tunic, cream apron, herb satchel and gentle practical village clothing"},
 [pscustomobject]@{key="Elara";prompt="Astronomer Elara, scholarly female fantasy astronomer, deep indigo and navy robes, silver-violet trim, subtle star and moon motifs"},
 [pscustomobject]@{key="Holt";prompt="Trapper Holt, rugged male wilderness trapper, earthy brown clothing, leather gear, fur-trimmed collar and outdoorsman boots"},
 [pscustomobject]@{key="Orin";prompt="Sage Orin, older male fantasy sage, muted teal-green robes, layered cloth, mystical scholarly details and calm wise silhouette"},
 [pscustomobject]@{key="Rook";prompt="Captain Rook, disciplined male village guard captain, dark steel-blue uniform, leather armor accents, shoulder guards and sturdy boots"},
 [pscustomobject]@{key="Vale";prompt="Historian Vale, scholarly fantasy historian, plum and muted purple robes, layered travel coat, parchment and bookish detailing built into outfit"},
 [pscustomobject]@{key="Maeve";prompt="Stablemaster Maeve, capable female stablemaster and rider, warm brown riding vest, tan shirt, leather gloves, boots and horse-keeper utility belt"},
 [pscustomobject]@{key="ScoutMira";prompt="Scout Mira, agile female wilderness scout, moss green explorer clothing, leather straps, compact satchel, boots and practical cave-rescue gear"},
 [pscustomobject]@{key="LeatherTrader";prompt="Leather Trader Corvin, experienced male leatherworker merchant, dark brown leather apron, rolled sleeves, tool belt and rugged work boots"},
 [pscustomobject]@{key="MaterialTrader";prompt="Material Trader, friendly fantasy village merchant, earth-brown and tan clothing, heavy work apron, utility belt, pouches and sturdy boots"}
)
$checkLua='local H=game:GetService("HttpService");local f=game.ServerStorage.WildernessPets.NPCs;local o={};for _,x in ipairs(f:GetChildren()) do o[x.Name]=true end;return H:JSONEncode(o)'
$c=Tool "execute_luau" @{studio_id=$studio;datamodel_type="Edit";code=$checkLua}
$existing=$c.result.content[0].text|ConvertFrom-Json
$todo=@($specs|?{-not $existing.($_.key)})
Write-Output ("NPC_MISSING "+$todo.Count)
function Promote($sp,$tag,$assetId){
 $nameJson=$sp.key|ConvertTo-Json -Compress
 $tagJson=([string]$tag)|ConvertTo-Json -Compress
 $assetJson=([string]$assetId)|ConvertTo-Json -Compress
 $lua=@"
local name=$nameJson;local tag=$tagJson;local aid=$assetJson
local CS=game:GetService("CollectionService");local src=nil
for _,m in ipairs(CS:GetTagged(tag)) do if m:IsA("Model") then src=m break end end
if not src then return "MISSING_SOURCE" end
local folder=game.ServerStorage.WildernessPets.NPCs
local old=folder:FindFirstChild(name);if old then old:Destroy() end
local m=src:Clone();m.Name=name
for _,x in ipairs(m:GetDescendants()) do
 if x:IsA("PackageLink") then x:Destroy()
 elseif x:IsA("BasePart") then x.Anchored=true;x.CanCollide=false;x.CanTouch=false;x.CanQuery=true;x.Massless=true end
end
local body=m:FindFirstChild("body_geom",true) or m:FindFirstChildWhichIsA("BasePart",true)
if not body then m:Destroy();return "NO_BODY" end
m.PrimaryPart=body;m:SetAttribute("GeneratedMesh",true);m:SetAttribute("GeneratedAssetId",aid);m:SetAttribute("GenerationTag",tag)
m.Parent=folder;src:Destroy();return "PROMOTED"
"@
 $r=Tool "execute_luau" @{studio_id=$studio;datamodel_type="Edit";code=$lua}
 [string]$r.result.content[0].text
}
$manifest=@{};$failed=@()
for($i=0;$i -lt $todo.Count;$i+=4){
 $end=[Math]::Min($i+3,$todo.Count-1);$batch=@($todo[$i..$end]);$jobs=@()
 Write-Output ("NPC_BATCH "+([int]($i/4)+1)+" "+(($batch|%{$_.key}) -join ", "))
 foreach($sp in $batch){
  $prompt="Highly detailed stylized fantasy Roblox game NPC: $($sp.prompt). Stylized friendly proportions, expressive face, clean readable silhouette, polished low-poly hand-painted fantasy style matching a whimsical pet adventure village. Neutral upright animation-ready pose facing forward (+Z). No environment, no base, no text. Keep body, head, arms and legs separate but visually connected."
  try{
   $r=Tool "generate_mesh" @{studio_id=$studio;textPrompt=$prompt;segmentation="explicit";partNames="body, head, left arm, right arm, left leg, right leg";size=@{x=3.0;y=6.3;z=2.7};maxTriangles=5500;async=$true}
   $j=$r.result.content[0].text|ConvertFrom-Json;$jobs+=[pscustomobject]@{sp=$sp;job=$j.jobId}
   Write-Output ("NPC_START "+$sp.key+" "+$j.jobId)
  }catch{Write-Output ("NPC_START_FAIL "+$sp.key+" "+$_.Exception.Message);$failed+=$sp.key}
 }
 foreach($j in $jobs){
  try{
   $w=Tool "wait_job_finished" @{studio_id=$studio;jobId=$j.job;timeout=360}
   $wi=$w.result.content[0].text|ConvertFrom-Json
   if($wi.status -ne "Completed"){throw ("job status "+$wi.status)}
   $sc=$wi.jobResult.structuredContent;$aid=[string]$sc.publishedAssetId;$tag=[string]$sc.tag
   $pr=Promote $j.sp $tag $aid;if($pr -ne "PROMOTED"){throw $pr}
   $manifest[$j.sp.key]=@{assetId=$aid;tag=$tag};Write-Output ("NPC_DONE "+$j.sp.key+" "+$aid)
  }catch{Write-Output ("NPC_JOB_FAIL "+$j.sp.key+" "+$_.Exception.Message);$failed+=$j.sp.key}
 }
 Start-Sleep -Seconds 3
}
@{generated=$manifest;failed=@($failed)}|ConvertTo-Json -Depth 5|Set-Content -Encoding UTF8 $manifestPath
Write-Output ("NPC_MANIFEST "+$manifestPath)
Write-Output ("NPC_FAILED "+(($failed|select -Unique)-join ", "))
try{$p.Kill()}catch{}
