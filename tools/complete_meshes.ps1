$ErrorActionPreference = "Stop"
$exe = "C:\Users\robert\AppData\Local\Roblox\Versions\version-574ecee7ee2b4e60\StudioMCP.exe"
$manifestPath = "D:\Roblox games\generated_mesh_assets_20260920.json"
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $exe
$psi.UseShellExecute = $false
$psi.RedirectStandardInput = $true
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError = $true
$p = New-Object System.Diagnostics.Process
$p.StartInfo = $psi
[void]$p.Start()
$script:rid = 0

function Rpc($method, $params) {
    $script:rid++
    $id = $script:rid
    $req = @{jsonrpc="2.0"; id=$id; method=$method; params=$params} | ConvertTo-Json -Compress -Depth 30
    $p.StandardInput.WriteLine($req)
    $p.StandardInput.Flush()
    while ($true) {
        $line = $p.StandardOutput.ReadLine()
        if ($null -eq $line) { throw "StudioMCP closed unexpectedly" }
        try { $obj = $line | ConvertFrom-Json } catch { continue }
        if ($obj.id -eq $id) { return $obj }
    }
}

function Tool($name, $arguments) {
    return Rpc "tools/call" @{name=$name; arguments=$arguments}
}$init = Rpc "initialize" @{
    protocolVersion="2024-11-05"
    capabilities=@{}
    clientInfo=@{name="PetWorld mesh finisher";version="1.0"}
}
$p.StandardInput.WriteLine('{"jsonrpc":"2.0","method":"notifications/initialized","params":{}}')
$p.StandardInput.Flush()
$studios = Tool "list_roblox_studios" @{}
$studioData = $studios.result.content[0].text | ConvertFrom-Json
$studio = ($studioData.studios | Where-Object {$_.name -eq "PetWorldOL.rbxl"} | Select-Object -First 1).id
if (-not $studio) { throw "PetWorldOL.rbxl Studio instance not found" }
Write-Output "STUDIO $studio"

$specLua = @'
local H=game:GetService("HttpService")
local C=require(game.ReplicatedStorage.WildernessPets.Shared.Config)
local T=game.ServerStorage.WildernessPets.Monsters
local function rgb(c)
 c=c or Color3.fromRGB(130,130,130)
 return string.format("%d,%d,%d",math.floor(c.R*255+.5),math.floor(c.G*255+.5),math.floor(c.B*255+.5))
end
local out={pets={},mounts={}}
local function add(dst,name,info,kind)
 local v=info.Visual or {}
 table.insert(dst,{name=name,kind=kind,rarity=info.Rarity or "",archetype=v.Archetype or "Quadruped",
  feature=v.Feature or "",scale=tonumber(v.Scale) or 1,primary=rgb(v.Color),accent=rgb(v.Accent)})
end
for name,info in pairs(C.Pets) do
 if not info.Legacy and not T:FindFirstChild(info.TemplateSpecies or name) then add(out.pets,name,info,"Pet") end
end
for name,info in pairs(C.Mounts or {}) do
 if not T:FindFirstChild(info.TemplateSpecies or name) then add(out.mounts,name,info,"Mount") end
end
return H:JSONEncode(out)
'@
$specResp = Tool "execute_luau" @{studio_id=$studio;datamodel_type="Edit";code=$specLua}
$specData = $specResp.result.content[0].text | ConvertFrom-Json
$specs = @($specData.pets) + @($specData.mounts)
Write-Output ("MISSING " + $specs.Count)

function Get-Parts($sp) {
    switch ($sp.archetype) {
        "Bird" { return "body, head, left wing, right wing, left leg, right leg, tail" }
        "Lizard" { return "body, head, front left leg, front right leg, rear left leg, rear right leg, tail" }
        "Serpent" { return "body, head, tail" }
        "Turtle" { return "body, head, front left leg, front right leg, rear left leg, rear right leg, tail" }
        "Raptor" { return "body, head, left leg, right leg, left wing, right wing, tail" }
        "Beetle" { return "body, head, left legs, right legs, left wing, right wing" }
        "Arachnid" { return "body, head, left legs, right legs" }
        "Kraken" { return "body, head, tail tentacle 1, tail tentacle 2, tail tentacle 3, tail tentacle 4, tail tentacle 5, tail tentacle 6" }
        "Imp" { return "body, head, left arm, right arm, left leg, right leg, tail" }
        "Titan" {
            if ($sp.name -like "*Mammoth*") { return "body, head, front left leg, front right leg, rear left leg, rear right leg, tail" }
            return "body, head, left arm, right arm, left leg, right leg"
        }
        default {
            if ($sp.feature -eq "wings") {
                return "body, head, front left leg, front right leg, rear left leg, rear right leg, left wing, right wing"
            }
            return "body, head, front left leg, front right leg, rear left leg, rear right leg, tail"
        }
    }
}

function Get-Size($sp) {
    $s = [double]$sp.scale
    switch ($sp.archetype) {
        "Bird" { $b=@(6.0,5.0,5.5) }
        "Lizard" { $b=@(4.5,3.0,7.0) }
        "Serpent" { $b=@(6.0,5.0,10.0) }
        "Turtle" { $b=@(5.0,3.2,6.0) }
        "Raptor" { $b=@(8.0,7.0,8.0) }
        "Beetle" { $b=@(4.0,3.0,4.5) }
        "Arachnid" { $b=@(6.0,3.2,6.0) }
        "Titan" { $b=@(6.0,9.0,6.0) }
        "Kraken" { $b=@(10.0,9.0,10.0) }
        "Imp" { $b=@(4.0,6.0,4.0) }
        default { $b=@(2.8,5.0,6.6) }
    }
    return @{x=[Math]::Round($b[0]*$s,2);y=[Math]::Round($b[1]*$s,2);z=[Math]::Round($b[2]*$s,2)}
}

function Get-Prompt($sp) {
    $role = if ($sp.kind -eq "Mount") { "rideable fantasy mount" } else { "fantasy creature" }
    if ($sp.name -eq "Manticore") {
        return "Highly detailed stylized fantasy game winged lion guardian beast with a muscular feline body, deep maroon-brown fur, rosy-magenta accents, broad fantasy wings, sharp ears and a dangerous long stinger tail. Clean readable silhouette, polished low-poly hand-painted Roblox style. Neutral animation-ready pose facing forward (+Z). No environment, no base, no text. Keep named parts separate but visually connected."
    }
    return "Highly detailed stylized fantasy game $($sp.name): a $($sp.archetype.ToLower()) $role. Primary color RGB $($sp.primary), accent RGB $($sp.accent). Distinct $($sp.feature) features and a strong readable silhouette. Polished low-poly hand-painted Roblox fantasy style matching an existing creature collection. Neutral animation-ready pose facing forward (+Z). No environment, no base, no text. Keep named parts separate but visually connected."
}

function Promote-Mesh($sp, $tag, $assetId) {
    $nameJson = $sp.name | ConvertTo-Json -Compress
    $tagJson = ([string]$tag) | ConvertTo-Json -Compress
    $assetJson = ([string]$assetId) | ConvertTo-Json -Compress
    $lua = @"
local name=$nameJson
local tag=$tagJson
local assetId=$assetJson
local CS=game:GetService("CollectionService")
local source=nil
if tag~="" then
 for _,inst in ipairs(CS:GetTagged(tag)) do
  if inst:IsA("Model") then source=inst break end
 end
end
if not source then
 for _,m in ipairs(workspace:GetChildren()) do
  if m:IsA("Model") and m.Name:find(name,1,true) then source=m break end
 end
end
if not source then return "MISSING_SOURCE" end
local monsters=game.ServerStorage.WildernessPets.Monsters
local old=monsters:FindFirstChild(name); if old then old:Destroy() end
local clone=source:Clone(); clone.Name=name
for _,x in ipairs(clone:GetDescendants()) do
 if x:IsA("PackageLink") then x:Destroy()
 elseif x:IsA("BasePart") then x.Anchored=true;x.CanCollide=false;x.CanTouch=false;x.CanQuery=false;x.Massless=true end
end
local body=clone:FindFirstChild("body_geom",true)
if body and body:IsA("BasePart") then clone.PrimaryPart=body end
clone:SetAttribute("GeneratedMesh",true)
clone:SetAttribute("GeneratedAssetId",assetId)
clone:SetAttribute("GenerationTag",tag)
clone.Parent=monsters
source:Destroy()
return "PROMOTED"
"@
    $r = Tool "execute_luau" @{studio_id=$studio;datamodel_type="Edit";code=$lua}
    return [string]$r.result.content[0].text
}

$manifest = @{}
$failed = @()
for ($i=0; $i -lt $specs.Count; $i += 4) {
    $end = [Math]::Min($i+3,$specs.Count-1)
    $batch = @($specs[$i..$end])
    $jobs = @()
    Write-Output ("BATCH " + ([int]($i/4)+1) + " " + (($batch | ForEach-Object {$_.name}) -join ", "))
    foreach ($sp in $batch) {
        $args = @{
            studio_id=$studio
            textPrompt=(Get-Prompt $sp)
            segmentation="explicit"
            partNames=(Get-Parts $sp)
            size=(Get-Size $sp)
            maxTriangles=6500
            async=$true
        }
        try {
            $r = Tool "generate_mesh" $args
            if ($r.result.isError) { throw $r.result.content[0].text }
            $ji = $r.result.content[0].text | ConvertFrom-Json
            $jobs += [pscustomobject]@{spec=$sp;jobId=$ji.jobId}
            Write-Output ("START " + $sp.name + " " + $ji.jobId)
        } catch {
            Write-Output ("START_FAIL " + $sp.name + " " + $_.Exception.Message)
            $failed += $sp.name
        }
    }
    foreach ($j in $jobs) {
        try {
            $w = Tool "wait_job_finished" @{studio_id=$studio;jobId=$j.jobId;timeout=360}
            $wi = $w.result.content[0].text | ConvertFrom-Json
            if ($wi.status -ne "Completed") { throw ("job status " + $wi.status) }
            $sc = $wi.jobResult.structuredContent
            $assetId = [string]$sc.publishedAssetId
            $tag = [string]$sc.tag
            $promoted = Promote-Mesh $j.spec $tag $assetId
            if ($promoted -ne "PROMOTED") { throw $promoted }
            $manifest[$j.spec.name] = @{assetId=$assetId;tag=$tag;kind=$j.spec.kind}
            Write-Output ("DONE " + $j.spec.name + " " + $assetId)
        } catch {
            Write-Output ("JOB_FAIL " + $j.spec.name + " " + $_.Exception.Message)
            $failed += $j.spec.name
        }
    }
    Start-Sleep -Seconds 3
}

@{generated=$manifest;failed=@($failed)} | ConvertTo-Json -Depth 6 | Set-Content -Encoding UTF8 $manifestPath
Write-Output ("MANIFEST " + $manifestPath)
Write-Output ("FAILED " + (($failed | Select-Object -Unique) -join ", "))

$validateLua = @'
local H=game:GetService("HttpService")
local C=require(game.ReplicatedStorage.WildernessPets.Shared.Config)
local T=game.ServerStorage.WildernessPets.Monsters
local p,m={},{}
for name,info in pairs(C.Pets) do
 if not info.Legacy and not T:FindFirstChild(info.TemplateSpecies or name) then table.insert(p,name) end
end
for name,info in pairs(C.Mounts or {}) do
 if not T:FindFirstChild(info.TemplateSpecies or name) then table.insert(m,name) end
end
table.sort(p);table.sort(m)
return H:JSONEncode({pets=p,mounts=m})
'@
try {
    $v = Tool "execute_luau" @{studio_id=$studio;datamodel_type="Edit";code=$validateLua}
    Write-Output ("VALIDATE " + $v.result.content[0].text)
} catch { Write-Output ("VALIDATE_FAIL " + $_.Exception.Message) }

try {
    $saveLua = 'local ok,err=pcall(function() game:SavePlace() end); return ok and "SAVE_OK" or ("SAVE_FAIL "..tostring(err))'
    $sv = Tool "execute_luau" @{studio_id=$studio;datamodel_type="Edit";code=$saveLua}
    Write-Output ("SAVE " + $sv.result.content[0].text)
} catch { Write-Output ("SAVE_CALL_FAIL " + $_.Exception.Message) }

try { $p.Kill() } catch {}
