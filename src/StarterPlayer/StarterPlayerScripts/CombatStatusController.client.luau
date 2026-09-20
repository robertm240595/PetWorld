local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local world = workspace:WaitForChild("WildernessPets")
local wildMonsters = world:WaitForChild("WildMonsters")
local companions = world:WaitForChild("Companions")

local STATUS_ORDER = {
    "Stun",
    "Blind",
    "Sunder",
    "Expose",
    "Weaken",
    "AttackSlow",
    "Bleed",
    "Burn",
    "Poison",
    "Frostbite",
    "Dreamrot",
}

local PET_BUFF_ORDER = {
    "AttackHaste",
    "Power",
    "DamageReduction",
    "Shield",
    "Reflect",
    "Evade",
    "ForgePowerAura",
    "ForgeDefenceAura",
    "ForgeHealthAura",
    "ForgeHasteAura",
}

local PET_DEBUFF_ORDER = {
    "Blind",
    "AttackSlow",
    "Poison",
    "Burn",
    "Bleed",
    "Frostbite",
}

local SHORT_NAMES = {
    AttackHaste = "HASTE",
    DamageReduction = "GUARD",
    AttackSlow = "SLOW",
    Frostbite = "FROST",
    Dreamrot = "DREAMROT",
    ForgePowerAura = "FORGE PWR AURA",
    ForgeDefenceAura = "FORGE DEF AURA",
    ForgeHealthAura = "FORGE HP AURA",
    ForgeHasteAura = "FORGE HASTE AURA",
}

local function shortName(name)
    return SHORT_NAMES[name] or string.upper(name)
end

local function remaining(untilValue)
    return math.max(0, (tonumber(untilValue) or 0) - workspace:GetServerTimeNow())
end

local function modelPart(model)
    return model
        and model.Parent
        and (model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true))
end

local function statusText(model, prefix, order)
    if not model or not model.Parent then return "" end

    local entries = {}
    for _, name in ipairs(order) do
        local timeLeft = remaining(model:GetAttribute(prefix .. "_" .. name .. "_Until"))
        if timeLeft > 0 then
            local value = tonumber(model:GetAttribute(prefix .. "_" .. name .. "_Value")) or 0
            local text = shortName(name)

            if name == "Sunder"
                or name == "Expose"
                or name == "Weaken"
                or name == "AttackSlow"
                or name == "AttackHaste"
                or name == "Power"
                or name == "DamageReduction"
                or name == "Reflect"
                or name == "ForgePowerAura"
                or name == "ForgeDefenceAura"
                or name == "ForgeHealthAura"
                or name == "ForgeHasteAura" then
                text ..= " " .. tostring(math.floor(value * 100 + 0.5)) .. "%"
            end

            text ..= " " .. string.format("%.1fs", timeLeft)

            local drTier = tonumber(model:GetAttribute("StatusDR_" .. name))
            local drRemaining = remaining(model:GetAttribute("StatusDR_" .. name .. "_Until"))
            if drTier and drTier > 1 and drRemaining > 0 then
                text ..= " [DR" .. tostring(drTier) .. "]"
            end

            table.insert(entries, text)
        end
    end

    return table.concat(entries, "  ·  ")
end

local tracked = setmetatable({}, {__mode = "k"})

local function ensureStatusBillboard(model)
    if not model or not model:IsA("Model") or tracked[model] then return end

    local part = modelPart(model)
    if not part then
        task.delay(0.2, function()
            if model.Parent then ensureStatusBillboard(model) end
        end)
        return
    end

    tracked[model] = true

    local gui = Instance.new("BillboardGui")
    gui.Name = "CombatStatusBillboard"
    gui.Size = UDim2.fromOffset(420, 44)
    gui.StudsOffsetWorldSpace = Vector3.new(
        0,
        math.max(3.5, model:GetExtentsSize().Y * 0.55 + 3.4),
        0
    )
    gui.MaxDistance = model:GetAttribute("WorldBoss") == true and 220 or 75
    gui.AlwaysOnTop = false
    gui.Parent = part

    local text = Instance.new("TextLabel")
    text.Name = "StatusText"
    text.BackgroundColor3 = Color3.fromRGB(18, 21, 25)
    text.BackgroundTransparency = 0.28
    text.BorderSizePixel = 0
    text.Size = UDim2.fromScale(1, 1)
    text.Font = Enum.Font.GothamBold
    text.TextSize = 11
    text.TextWrapped = true
    text.TextColor3 = Color3.fromRGB(236, 239, 242)
    text.TextStrokeTransparency = 0.65
    text.Visible = false
    text.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 7)
    corner.Parent = text

    local highlight = Instance.new("Highlight")
    highlight.Name = "CombatStatusHighlight"
    highlight.FillTransparency = 0.82
    highlight.OutlineTransparency = 0.35
    highlight.Enabled = false
    highlight.DepthMode = Enum.HighlightDepthMode.Occluded
    highlight.Parent = model
end

for _, model in ipairs(wildMonsters:GetChildren()) do
    ensureStatusBillboard(model)
end
for _, model in ipairs(companions:GetChildren()) do
    ensureStatusBillboard(model)
end

wildMonsters.ChildAdded:Connect(function(model)
    task.defer(ensureStatusBillboard, model)
end)
companions.ChildAdded:Connect(function(model)
    task.defer(ensureStatusBillboard, model)
end)

local bossGui = Instance.new("ScreenGui")
bossGui.Name = "BossEncounterHUD"
bossGui.ResetOnSpawn = false
bossGui.IgnoreGuiInset = true
bossGui.DisplayOrder = 60
bossGui.Enabled = false
bossGui.Parent = playerGui

local bossPanel = Instance.new("Frame")
bossPanel.Name = "BossPanel"
bossPanel.AnchorPoint = Vector2.new(0.5, 0)
bossPanel.Position = UDim2.new(0.5, 0, 0, 24)
bossPanel.Size = UDim2.fromOffset(620, 104)
bossPanel.BackgroundColor3 = Color3.fromRGB(17, 20, 24)
bossPanel.BackgroundTransparency = 0.08
bossPanel.BorderSizePixel = 0
bossPanel.Parent = bossGui

local bossCorner = Instance.new("UICorner")
bossCorner.CornerRadius = UDim.new(0, 11)
bossCorner.Parent = bossPanel

local bossName = Instance.new("TextLabel")
bossName.BackgroundTransparency = 1
bossName.Position = UDim2.fromOffset(18, 8)
bossName.Size = UDim2.fromOffset(390, 28)
bossName.Font = Enum.Font.GothamBlack
bossName.TextSize = 21
bossName.TextXAlignment = Enum.TextXAlignment.Left
bossName.TextColor3 = Color3.fromRGB(237, 224, 188)
bossName.Text = ""
bossName.Parent = bossPanel

local bossMeta = Instance.new("TextLabel")
bossMeta.BackgroundTransparency = 1
bossMeta.Position = UDim2.fromOffset(410, 9)
bossMeta.Size = UDim2.fromOffset(190, 25)
bossMeta.Font = Enum.Font.GothamBold
bossMeta.TextSize = 11
bossMeta.TextXAlignment = Enum.TextXAlignment.Right
bossMeta.TextColor3 = Color3.fromRGB(184, 191, 199)
bossMeta.Text = ""
bossMeta.Parent = bossPanel

local healthBack = Instance.new("Frame")
healthBack.Position = UDim2.fromOffset(18, 40)
healthBack.Size = UDim2.fromOffset(584, 18)
healthBack.BackgroundColor3 = Color3.fromRGB(60, 32, 34)
healthBack.BorderSizePixel = 0
healthBack.Parent = bossPanel

local healthCorner = Instance.new("UICorner")
healthCorner.CornerRadius = UDim.new(0, 6)
healthCorner.Parent = healthBack

local healthFill = Instance.new("Frame")
healthFill.Name = "Fill"
healthFill.Size = UDim2.fromScale(1, 1)
healthFill.BackgroundColor3 = Color3.fromRGB(162, 68, 64)
healthFill.BorderSizePixel = 0
healthFill.Parent = healthBack

local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(0, 6)
fillCorner.Parent = healthFill

local healthText = Instance.new("TextLabel")
healthText.BackgroundTransparency = 1
healthText.Size = UDim2.fromScale(1, 1)
healthText.Font = Enum.Font.GothamBold
healthText.TextSize = 11
healthText.TextColor3 = Color3.fromRGB(248, 242, 226)
healthText.Text = ""
healthText.Parent = healthBack

local bossStatus = Instance.new("TextLabel")
bossStatus.BackgroundTransparency = 1
bossStatus.Position = UDim2.fromOffset(18, 63)
bossStatus.Size = UDim2.fromOffset(584, 34)
bossStatus.Font = Enum.Font.GothamMedium
bossStatus.TextSize = 10
bossStatus.TextWrapped = true
bossStatus.TextColor3 = Color3.fromRGB(196, 204, 210)
bossStatus.Text = ""
bossStatus.Parent = bossPanel

local telegraph = Instance.new("TextLabel")
telegraph.Name = "BossTelegraph"
telegraph.AnchorPoint = Vector2.new(0.5, 0)
telegraph.Position = UDim2.new(0.5, 0, 0, 138)
telegraph.Size = UDim2.fromOffset(620, 54)
telegraph.BackgroundColor3 = Color3.fromRGB(74, 31, 27)
telegraph.BackgroundTransparency = 0.15
telegraph.BorderSizePixel = 0
telegraph.Font = Enum.Font.GothamBlack
telegraph.TextSize = 21
telegraph.TextColor3 = Color3.fromRGB(255, 220, 174)
telegraph.TextStrokeTransparency = 0.55
telegraph.Text = ""
telegraph.Visible = false
telegraph.Parent = bossGui

local telegraphCorner = Instance.new("UICorner")
telegraphCorner.CornerRadius = UDim.new(0, 10)
telegraphCorner.Parent = telegraph

local function findArenaBoss()
    local arena = tostring(player:GetAttribute("BossArena") or "")
    if arena == "Jormungdyrr" then
        return wildMonsters:FindFirstChild("Jormungdyrr")
    elseif arena == "Wyrm" then
        for _, model in ipairs(wildMonsters:GetChildren()) do
            if model:GetAttribute("BossId") == "HollowfangWyrm"
                and tonumber(model:GetAttribute("ArenaOwnerUserId")) == player.UserId then
                return model
            end
        end
    end
end

local elapsed = 0
RunService.RenderStepped:Connect(function(dt)
    elapsed += dt
    if elapsed < 0.10 then return end
    elapsed = 0

    for model in pairs(tracked) do
        if not model.Parent then
            tracked[model] = nil
        else
            local part = modelPart(model)
            local gui = part and part:FindFirstChild("CombatStatusBillboard")
            local label = gui and gui:FindFirstChild("StatusText")
            local highlight = model:FindFirstChild("CombatStatusHighlight")

            if label and label:IsA("TextLabel") then
                local enemyText = statusText(model, "Status", STATUS_ORDER)
                local buffText = statusText(model, "PetStatus", PET_BUFF_ORDER)
                local debuffText = statusText(model, "PetDebuff", PET_DEBUFF_ORDER)

                local combined = enemyText
                if buffText ~= "" then
                    combined = combined ~= "" and (combined .. "\n" .. buffText) or buffText
                end
                if debuffText ~= "" then
                    combined = combined ~= "" and (combined .. "\n" .. debuffText) or debuffText
                end

                label.Text = combined
                label.Visible = combined ~= ""
            end

            if highlight and highlight:IsA("Highlight") then
                local stunned = remaining(model:GetAttribute("Status_Stun_Until")) > 0
                local blinded = remaining(model:GetAttribute("Status_Blind_Until")) > 0
                    or remaining(model:GetAttribute("PetDebuff_Blind_Until")) > 0
                local burning = remaining(model:GetAttribute("Status_Burn_Until")) > 0
                    or remaining(model:GetAttribute("PetDebuff_Burn_Until")) > 0
                local poisoned = remaining(model:GetAttribute("Status_Poison_Until")) > 0
                    or remaining(model:GetAttribute("PetDebuff_Poison_Until")) > 0

                highlight.Enabled = stunned or blinded or burning or poisoned
                if stunned then
                    highlight.FillColor = Color3.fromRGB(241, 205, 78)
                elseif burning then
                    highlight.FillColor = Color3.fromRGB(230, 103, 48)
                elseif poisoned then
                    highlight.FillColor = Color3.fromRGB(105, 186, 95)
                else
                    highlight.FillColor = Color3.fromRGB(210, 217, 226)
                end
                highlight.OutlineColor = highlight.FillColor
            end
        end
    end

    local boss = findArenaBoss()
    bossGui.Enabled = boss ~= nil and boss.Parent ~= nil
    if not bossGui.Enabled then return end

    local hp = math.max(0, tonumber(boss:GetAttribute("Health")) or 0)
    local maximum = math.max(1, tonumber(boss:GetAttribute("MaxHealth")) or 1)
    local ratio = math.clamp(hp / maximum, 0, 1)
    local dead = boss:GetAttribute("Dead") == true or hp <= 0

    bossName.Text = tostring(boss:GetAttribute("DisplayName") or boss:GetAttribute("Species") or boss.Name)
    healthFill.Size = UDim2.fromScale(ratio, 1)
    healthText.Text = tostring(math.ceil(hp)) .. " / " .. tostring(math.ceil(maximum)) .. " HP"

    local phase = tostring(boss:GetAttribute("BossPhase") or "")
    local participants = math.max(0, tonumber(boss:GetAttribute("ActiveParticipants")) or 0)
    bossMeta.Text = phase .. (boss:GetAttribute("WorldBoss") == true and ("  ·  " .. tostring(participants) .. " HANDLERS") or "")

    local statuses = statusText(boss, "Status", STATUS_ORDER)
    if boss:GetAttribute("BossSoloWard") == true then
        statuses = "SOLO WARD: 85% damage reduction + regeneration"
            .. (statuses ~= "" and ("  ·  " .. statuses) or "")
    end

    if dead then
        local respawn = remaining(boss:GetAttribute("BossRespawnAt"))
        if respawn > 0 then
            statuses = "DEFEATED  ·  respawns in " .. tostring(math.ceil(respawn)) .. "s"
        else
            statuses = "DEFEATED"
        end
    end
    bossStatus.Text = statuses

    local telegraphRemaining = remaining(boss:GetAttribute("BossTelegraphUntil"))
    local telegraphName = tostring(boss:GetAttribute("BossTelegraph") or "")
    telegraph.Visible = not dead and telegraphRemaining > 0 and telegraphName ~= ""

    if telegraph.Visible then
        local targetUserId = tonumber(boss:GetAttribute("BossTelegraphTargetUserId")) or 0
        local targetText = targetUserId == player.UserId
            and "  ·  TARGETING YOUR PET"
            or ""
        telegraph.Text = telegraphName
            .. targetText
            .. "  ·  "
            .. string.format("%.1fs", telegraphRemaining)
    end
end)
