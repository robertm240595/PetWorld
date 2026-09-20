local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Root = ReplicatedStorage:WaitForChild("WildernessPets")
local Config = require(Root.Shared.Config)
local LootConfig = require(Root.Shared.LootConfig)
local EquipmentConfig = require(Root.Shared.EquipmentConfig)
local ForgeRemote = Root.Remotes:WaitForChild("Forge")
local GetState = Root.Remotes:WaitForChild("GetState")

local gui = Instance.new("ScreenGui")
gui.Name = "WildforgeUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 125
gui.Enabled = true
gui.Parent = playerGui

local mainPanel
local forgePanel
local resultPanel
local currentTab = "Craft"
local selectedBlueprintId = EquipmentConfig.BlueprintOrder[1]
local selectedTierIndex = 1
local selectedInvestment = 1
local selectedPetId = ""
local selectedWorldBoss = "Jörmungandr"
local activeForge
local currentForgeInputAction
local forgeScores = {}
local forgeInput = {
    Heat = false,
    Hammer = 0,
    Quench = false,
}

local palette = {
    panel = Color3.fromRGB(24, 28, 33),
    inset = Color3.fromRGB(34, 39, 46),
    row = Color3.fromRGB(44, 50, 58),
    accent = Color3.fromRGB(225, 143, 61),
    gold = Color3.fromRGB(245, 194, 94),
    text = Color3.fromRGB(235, 237, 240),
    muted = Color3.fromRGB(166, 175, 185),
    good = Color3.fromRGB(132, 210, 151),
    bad = Color3.fromRGB(226, 132, 124),
}

local function round(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = parent
end

local function stroke(parent, color, transparency)
    local item = Instance.new("UIStroke")
    item.Color = color or palette.accent
    item.Transparency = transparency == nil and 0.45 or transparency
    item.Thickness = 1
    item.Parent = parent
end

local function text(parent, value, position, size, fontSize)
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Position = position or UDim2.new()
    label.Size = size or UDim2.fromOffset(200, 24)
    label.Font = Enum.Font.GothamMedium
    label.TextSize = fontSize or 12
    label.TextColor3 = palette.text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.TextWrapped = true
    label.Text = tostring(value or "")
    label.Parent = parent
    return label
end

local function button(parent, value, position, size)
    local b = Instance.new("TextButton")
    b.Position = position or UDim2.new()
    b.Size = size or UDim2.fromOffset(120, 36)
    b.BackgroundColor3 = palette.row
    b.BorderSizePixel = 0
    b.AutoButtonColor = true
    b.Font = Enum.Font.GothamBold
    b.TextSize = 11
    b.TextColor3 = palette.text
    b.Text = tostring(value or "")
    b.Parent = parent
    round(b, 7)
    return b
end

local function scrolling(parent, position, size)
    local scroll = Instance.new("ScrollingFrame")
    scroll.Position = position
    scroll.Size = size
    scroll.BackgroundColor3 = palette.inset
    scroll.BackgroundTransparency = 0.15
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 5
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.CanvasSize = UDim2.new()
    scroll.Parent = parent
    round(scroll, 8)

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 6)
    layout.Parent = scroll

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 6)
    padding.PaddingBottom = UDim.new(0, 6)
    padding.PaddingLeft = UDim.new(0, 6)
    padding.PaddingRight = UDim.new(0, 6)
    padding.Parent = scroll

    return scroll
end

local function toast(message, good)
    local old = gui:FindFirstChild("WildforgeToast")
    if old then old:Destroy() end

    local label = text(
        gui,
        message,
        UDim2.new(0.5, -280, 0, 90),
        UDim2.fromOffset(560, 48),
        12
    )
    label.Name = "WildforgeToast"
    label.BackgroundTransparency = 0.06
    label.BackgroundColor3 = palette.panel
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextColor3 = good == false and palette.bad or palette.good
    round(label, 8)
    stroke(label, good == false and palette.bad or palette.accent, 0.35)

    task.delay(4.5, function()
        if label.Parent then label:Destroy() end
    end)
end

local function closeMain()
    if mainPanel then
        mainPanel:Destroy()
        mainPanel = nil
    end
end

local function closeForge()
    if forgePanel then
        forgePanel:Destroy()
        forgePanel = nil
    end
end

local function closeResult()
    if resultPanel then
        resultPanel:Destroy()
        resultPanel = nil
    end
end

local function formatPercent(value)
    return tostring(math.floor((tonumber(value) or 0) * 1000 + 0.5) / 10) .. "%"
end

local function statLine(stat)
    if type(stat) ~= "table" then return "" end
    return tostring(EquipmentConfig.StatLabels[stat.Name] or stat.Name or "Stat")
        .. " +"
        .. formatPercent(stat.Value)
end

local function itemLines(item)
    if type(item) ~= "table" then return {"Unknown equipment"} end

    local lines = {
        tostring(item.Name or "Equipment")
            .. "  ·  "
            .. tostring(item.Tier or "Common")
            .. " "
            .. tostring(item.Quality or "Crude")
            .. "  ·  Lv."
            .. tostring(item.ItemLevel or 1)
            .. ((tonumber(item.WorldforgeLevel) or 0) > 0
                and ("  ·  Worldforged +" .. tostring(item.WorldforgeLevel))
                or ""),
        "MAIN  ·  " .. statLine(item.MainStat),
    }

    for index, sub in ipairs(item.Substats or {}) do
        table.insert(lines, "SUB " .. tostring(index) .. "  ·  " .. statLine(sub))
    end

    return lines
end

local function fetchState()
    local ok, state = pcall(function()
        return GetState:InvokeServer()
    end)
    return ok and state or nil
end

local function inventoryQuantity(state, itemType, name)
    local total = 0
    for _, item in ipairs(state and state.Inventory or {}) do
        if type(item) == "table"
            and item.Type == itemType
            and item.Name == name then
            total += math.max(0, math.floor(tonumber(item.Quantity) or 0))
        end
    end
    return total
end

local function materialGroupCount(state, groupName, tier)
    local total = 0
    for _, item in ipairs(state and state.Inventory or {}) do
        if type(item) == "table" and item.Type == "Loot" then
            local _, _, rarity = LootConfig:GetTraderValue(item.Name, Config.Pets)
            if rarity == tier
                and EquipmentConfig:GetMaterialGroup(item.Name) == groupName then
                total += math.max(0, math.floor(tonumber(item.Quantity) or 0))
            end
        end
    end
    return total
end

local function makeRoot(titleText)
    closeMain()

    local panel = Instance.new("Frame")
    panel.Name = "WildforgeWindow"
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.Position = UDim2.fromScale(0.5, 0.5)
    panel.Size = UDim2.fromOffset(980, 650)
    panel.BackgroundColor3 = palette.panel
    panel.BorderSizePixel = 0
    panel.Parent = gui
    round(panel, 12)
    stroke(panel, palette.accent, 0.25)
    mainPanel = panel

    local title = text(
        panel,
        titleText or "WILDFORGE SMITH",
        UDim2.fromOffset(20, 12),
        UDim2.fromOffset(600, 34),
        22
    )
    title.Font = Enum.Font.GothamBlack
    title.TextColor3 = palette.gold

    local subtitle = text(
        panel,
        "Forge permanent equipment from wild materials. Crafting never fails — precision determines quality.",
        UDim2.fromOffset(20, 45),
        UDim2.fromOffset(740, 28),
        10
    )
    subtitle.TextColor3 = palette.muted

    local closeButton = button(
        panel,
        "×",
        UDim2.fromOffset(922, 12),
        UDim2.fromOffset(40, 34)
    )
    closeButton.TextSize = 19
    closeButton.Activated:Connect(closeMain)

    local tabs = {"Craft", "Equipment", "Worldforge"}
    for index, tab in ipairs(tabs) do
        local tabButton = button(
            panel,
            string.upper(tab),
            UDim2.fromOffset(20 + (index - 1) * 152, 78),
            UDim2.fromOffset(142, 34)
        )
        tabButton.BackgroundColor3 = currentTab == tab
            and Color3.fromRGB(102, 70, 42)
            or palette.row
        tabButton.Activated:Connect(function()
            currentTab = tab
            task.defer(function()
                if currentTab == "Craft" then
                    -- filled below after renderer definitions
                end
            end)
        end)
    end

    return panel
end

local renderMain
local renderCraft
local renderEquipment
local renderWorldforge

local function hookTabButtons(panel)
    local names = {"Craft", "Equipment", "Worldforge"}
    for index, tab in ipairs(names) do
        local tabButton = panel:FindFirstChildWhichIsA("TextButton")
        -- Main renderer rebuilds the full panel on tab changes instead of
        -- trying to mutate old scrolling frames.
    end
end

renderCraft = function()
    local state = fetchState()
    if not state then
        toast("Could not load Wildforge state.", false)
        return
    end

    local panel = makeRoot("WILDFORGE SMITH  ·  CRAFT")

    -- Rebind tab controls created in makeRoot.
    local allButtons = {}
    for _, child in ipairs(panel:GetChildren()) do
        if child:IsA("TextButton") then table.insert(allButtons, child) end
    end
    for _, child in ipairs(allButtons) do
        if child.Text == "CRAFT" then
            child.Activated:Connect(function() currentTab = "Craft"; renderCraft() end)
        elseif child.Text == "EQUIPMENT" then
            child.Activated:Connect(function() currentTab = "Equipment"; renderEquipment() end)
        elseif child.Text == "WORLDFORGE" then
            child.Activated:Connect(function() currentTab = "Worldforge"; renderWorldforge() end)
        end
    end

    local list = scrolling(
        panel,
        UDim2.fromOffset(20, 125),
        UDim2.fromOffset(375, 500)
    )

    for _, blueprintId in ipairs(EquipmentConfig.BlueprintOrder) do
        local blueprint = EquipmentConfig.Blueprints[blueprintId]
        local selected = blueprintId == selectedBlueprintId
        local row = button(
            list,
            tostring(blueprint.Name)
                .. "  ·  "
                .. tostring(blueprint.Slot)
                .. "  ·  "
                .. tostring(EquipmentConfig.StatLabels[blueprint.MainStat] or blueprint.MainStat),
            UDim2.new(),
            UDim2.fromOffset(348, 44)
        )
        row.TextXAlignment = Enum.TextXAlignment.Left
        row.TextSize = 9
        row.BackgroundColor3 = selected
            and Color3.fromRGB(88, 66, 43)
            or palette.row
        row.Activated:Connect(function()
            selectedBlueprintId = blueprintId
            renderCraft()
        end)
    end

    local detail = Instance.new("Frame")
    detail.Position = UDim2.fromOffset(415, 125)
    detail.Size = UDim2.fromOffset(545, 500)
    detail.BackgroundColor3 = palette.inset
    detail.BorderSizePixel = 0
    detail.Parent = panel
    round(detail, 9)

    local blueprint = EquipmentConfig.Blueprints[selectedBlueprintId]
    local tier = EquipmentConfig.TierOrder[selectedTierIndex] or "Common"
    local investment = EquipmentConfig.Investments[selectedInvestment] or EquipmentConfig.Investments[1]
    local recipe = EquipmentConfig:GetRecipe(selectedBlueprintId, tier, selectedInvestment)

    local heading = text(
        detail,
        blueprint.Name,
        UDim2.fromOffset(18, 15),
        UDim2.fromOffset(500, 28),
        18
    )
    heading.Font = Enum.Font.GothamBold

    text(
        detail,
        blueprint.Description,
        UDim2.fromOffset(18, 49),
        UDim2.fromOffset(505, 44),
        11
    ).TextColor3 = palette.muted

    text(
        detail,
        "SLOT  " .. string.upper(blueprint.Slot)
            .. "     MAIN STAT  "
            .. string.upper(EquipmentConfig.StatLabels[blueprint.MainStat] or blueprint.MainStat),
        UDim2.fromOffset(18, 95),
        UDim2.fromOffset(500, 24),
        11
    ).TextColor3 = palette.gold

    local tierPrev = button(detail, "◀", UDim2.fromOffset(18, 134), UDim2.fromOffset(42, 34))
    local tierLabel = button(
        detail,
        string.upper(tier),
        UDim2.fromOffset(66, 134),
        UDim2.fromOffset(180, 34)
    )
    tierLabel.Active = false
    local tierNext = button(detail, "▶", UDim2.fromOffset(252, 134), UDim2.fromOffset(42, 34))

    tierPrev.Activated:Connect(function()
        selectedTierIndex = selectedTierIndex - 1
        if selectedTierIndex < 1 then selectedTierIndex = #EquipmentConfig.TierOrder end
        renderCraft()
    end)
    tierNext.Activated:Connect(function()
        selectedTierIndex = selectedTierIndex + 1
        if selectedTierIndex > #EquipmentConfig.TierOrder then selectedTierIndex = 1 end
        renderCraft()
    end)

    local invest = button(
        detail,
        "INVESTMENT  ·  " .. tostring(investment.Label),
        UDim2.fromOffset(310, 134),
        UDim2.fromOffset(214, 34)
    )
    invest.Activated:Connect(function()
        selectedInvestment += 1
        if not EquipmentConfig.Investments[selectedInvestment] then
            selectedInvestment = 1
        end
        renderCraft()
    end)

    local primaryOwned = materialGroupCount(state, recipe.PrimaryGroup, tier)
    local secondaryOwned = materialGroupCount(state, recipe.SecondaryGroup, tier)
    local enoughPrimary = primaryOwned >= recipe.PrimaryCount
    local enoughSecondary = secondaryOwned >= recipe.SecondaryCount
    local enoughCoins = (tonumber(state.Coins) or 0) >= recipe.Coins

    local recipeBox = text(
        detail,
        "RECIPE\n"
            .. tostring(recipe.PrimaryCount)
            .. "× "
            .. tier
            .. " "
            .. recipe.PrimaryGroup
            .. " materials  ("
            .. tostring(primaryOwned)
            .. " owned)\n"
            .. tostring(recipe.SecondaryCount)
            .. "× "
            .. tier
            .. " "
            .. recipe.SecondaryGroup
            .. " materials  ("
            .. tostring(secondaryOwned)
            .. " owned)\n"
            .. tostring(recipe.Coins)
            .. " Coins  ("
            .. tostring(state.Coins or 0)
            .. " owned)",
        UDim2.fromOffset(18, 185),
        UDim2.fromOffset(507, 106),
        12
    )
    recipeBox.TextYAlignment = Enum.TextYAlignment.Top
    recipeBox.TextColor3 = enoughPrimary and enoughSecondary and enoughCoins
        and palette.text
        or palette.bad

    local levelText = {}
    for level, weight in ipairs(investment.LevelWeights) do
        if weight > 0 then
            table.insert(levelText, "Lv." .. tostring(level) .. " " .. tostring(weight) .. "%")
        end
    end

    local outcome = text(
        detail,
        "ITEM LEVEL ODDS  ·  "
            .. table.concat(levelText, "  ·  ")
            .. "\n\nQUALITY comes from your forge performance. Every craft produces an item. "
            .. "Normal items roll 2 unique substats; a Perfect 100-score forge rolls 3.",
        UDim2.fromOffset(18, 298),
        UDim2.fromOffset(507, 82),
        11
    )
    outcome.TextYAlignment = Enum.TextYAlignment.Top
    outcome.TextColor3 = palette.muted

    local caps = text(
        detail,
        "Equipment contribution caps are enforced after all three slots are combined. "
            .. "Example: Attack Haste 35% · Cooldown Reduction 25% · Power 40% · Health 50%.",
        UDim2.fromOffset(18, 384),
        UDim2.fromOffset(507, 55),
        10
    )
    caps.TextColor3 = palette.muted
    caps.TextYAlignment = Enum.TextYAlignment.Top

    local start = button(
        detail,
        "START FORGE MINIGAME",
        UDim2.fromOffset(120, 447),
        UDim2.fromOffset(305, 40)
    )
    start.BackgroundColor3 = Color3.fromRGB(112, 70, 39)
    local canCraft = enoughPrimary and enoughSecondary and enoughCoins
    start.Active = canCraft
    if not canCraft then
        start.Text = "INSUFFICIENT MATERIALS / COINS"
        start.BackgroundColor3 = Color3.fromRGB(68, 61, 57)
    end
    start.Activated:Connect(function()
        start.Active = false
        start.Text = "HEATING FORGE..."
        ForgeRemote:FireServer(
            "BeginForge",
            selectedBlueprintId,
            tier,
            selectedInvestment
        )
    end)
end

local function petById(state, petId)
    for _, pet in ipairs(state.Pets or {}) do
        if pet.Id == petId then return pet end
    end
end

renderEquipment = function()
    local state = fetchState()
    if not state then
        toast("Could not load equipment storage.", false)
        return
    end

    currentTab = "Equipment"
    local panel = makeRoot("WILDFORGE SMITH  ·  EQUIPMENT")

    for _, child in ipairs(panel:GetChildren()) do
        if child:IsA("TextButton") then
            if child.Text == "CRAFT" then
                child.Activated:Connect(function() currentTab = "Craft"; renderCraft() end)
            elseif child.Text == "EQUIPMENT" then
                child.Activated:Connect(function() renderEquipment() end)
            elseif child.Text == "WORLDFORGE" then
                child.Activated:Connect(function() currentTab = "Worldforge"; renderWorldforge() end)
            end
        end
    end

    local pets = state.Pets or {}
    if selectedPetId == "" or not petById(state, selectedPetId) then
        selectedPetId = pets[1] and pets[1].Id or ""
    end
    local selectedPet = petById(state, selectedPetId)

    local petBox = Instance.new("Frame")
    petBox.Position = UDim2.fromOffset(20, 125)
    petBox.Size = UDim2.fromOffset(940, 154)
    petBox.BackgroundColor3 = palette.inset
    petBox.BorderSizePixel = 0
    petBox.Parent = panel
    round(petBox, 9)

    if not selectedPet then
        text(
            petBox,
            "Capture a pet before equipping Wildforge gear.",
            UDim2.fromOffset(18, 18),
            UDim2.fromOffset(880, 32),
            14
        )
    else
        local petIndex = 1
        for index, pet in ipairs(pets) do
            if pet.Id == selectedPet.Id then petIndex = index break end
        end

        local prev = button(petBox, "◀", UDim2.fromOffset(18, 14), UDim2.fromOffset(42, 34))
        local nextButton = button(petBox, "▶", UDim2.fromOffset(880, 14), UDim2.fromOffset(42, 34))
        local petTitle = text(
            petBox,
            tostring(selectedPet.Name or selectedPet.Species)
                .. "  ·  "
                .. tostring(selectedPet.Species)
                .. "  ·  "
                .. tostring(selectedPet.Rarity),
            UDim2.fromOffset(72, 14),
            UDim2.fromOffset(790, 34),
            16
        )
        petTitle.TextXAlignment = Enum.TextXAlignment.Center
        petTitle.Font = Enum.Font.GothamBold

        prev.Activated:Connect(function()
            petIndex -= 1
            if petIndex < 1 then petIndex = #pets end
            selectedPetId = pets[petIndex].Id
            renderEquipment()
        end)
        nextButton.Activated:Connect(function()
            petIndex += 1
            if petIndex > #pets then petIndex = 1 end
            selectedPetId = pets[petIndex].Id
            renderEquipment()
        end)

        local equipped = type(selectedPet.Equipment) == "table" and selectedPet.Equipment or {}
        for slotIndex, slotName in ipairs(EquipmentConfig.Slots) do
            local x = 18 + (slotIndex - 1) * 304
            local item = equipped[slotName]
            local slotButton = button(
                petBox,
                item
                    and (slotName:upper() .. "\n" .. tostring(item.Name) .. " · " .. tostring(item.Quality))
                    or (slotName:upper() .. "\nEMPTY"),
                UDim2.fromOffset(x, 63),
                UDim2.fromOffset(286, 72)
            )
            slotButton.TextWrapped = true
            slotButton.TextSize = 10
            slotButton.BackgroundColor3 = item
                and Color3.fromRGB(70, 61, 48)
                or palette.row
            if item then
                slotButton.Activated:Connect(function()
                    ForgeRemote:FireServer("Unequip", selectedPet.Id, slotName)
                end)
            else
                slotButton.Active = false
            end
        end

        local bonuses = EquipmentConfig:GetBonuses(selectedPet)
        local capped = {}
        for statName, cap in pairs(EquipmentConfig.StatCaps) do
            if cap > 0 and (tonumber(bonuses[statName]) or 0) >= cap - 0.0001 then
                table.insert(capped, EquipmentConfig.StatLabels[statName] or statName)
            end
        end
        table.sort(capped)

        local capLabel = text(
            petBox,
            #capped > 0
                and ("EQUIPMENT CAP REACHED: " .. table.concat(capped, " · "))
                or "Equipment caps active · Power 40% · Health 50% · Defence 40% · Haste 35% · Cooldowns 25%",
            UDim2.fromOffset(18, 136),
            UDim2.fromOffset(904, 16),
            8
        )
        capLabel.TextXAlignment = Enum.TextXAlignment.Center
        capLabel.TextColor3 = #capped > 0 and palette.gold or palette.muted
    end

    local storedTitle = text(
        panel,
        "UNEQUIPPED EQUIPMENT  ·  "
            .. tostring(#(state.Equipment or {}))
            .. "/"
            .. tostring(state.EquipmentCapacity or EquipmentConfig.MaxEquipment),
        UDim2.fromOffset(20, 291),
        UDim2.fromOffset(600, 24),
        12
    )
    storedTitle.Font = Enum.Font.GothamBold

    local list = scrolling(
        panel,
        UDim2.fromOffset(20, 322),
        UDim2.fromOffset(940, 303)
    )

    for _, item in ipairs(state.Equipment or {}) do
        local row = Instance.new("Frame")
        row.Size = UDim2.fromOffset(914, 92)
        row.BackgroundColor3 = palette.row
        row.BorderSizePixel = 0
        row.Parent = list
        round(row, 7)

        local info = text(
            row,
            table.concat(itemLines(item), "\n"),
            UDim2.fromOffset(12, 7),
            UDim2.fromOffset(570, 78),
            9
        )
        info.TextYAlignment = Enum.TextYAlignment.Top

        local fav = button(
            row,
            item.Favourite and "★" or "☆",
            UDim2.fromOffset(588, 8),
            UDim2.fromOffset(38, 34)
        )
        fav.TextSize = 18
        fav.BackgroundColor3 = item.Favourite
            and Color3.fromRGB(103, 82, 46)
            or Color3.fromRGB(52, 58, 66)
        fav.Activated:Connect(function()
            ForgeRemote:FireServer("Favourite", item.Id, not item.Favourite)
        end)

        local equip = button(
            row,
            selectedPet and "EQUIP" or "NO PET",
            UDim2.fromOffset(632, 8),
            UDim2.fromOffset(84, 34)
        )
        equip.Active = selectedPet ~= nil
        equip.Activated:Connect(function()
            if selectedPet then
                ForgeRemote:FireServer("Equip", selectedPet.Id, item.Id)
            end
        end)

        local sell = button(
            row,
            item.BossUnique and "TRADE ONLY" or ("SELL " .. tostring(item.SmithSellValue or 0)),
            UDim2.fromOffset(722, 8),
            UDim2.fromOffset(178, 34)
        )
        sell.TextSize = 9
        sell.Active = not item.BossUnique and not item.Favourite
        if sell.Active then
            sell.Activated:Connect(function()
                ForgeRemote:FireServer("Sell", item.Id)
            end)
        end

        local salvage = button(
            row,
            item.BossUnique and "BOSS UNIQUE" or "SALVAGE",
            UDim2.fromOffset(632, 49),
            UDim2.fromOffset(268, 32)
        )
        salvage.TextSize = 9
        salvage.Active = not item.BossUnique and not item.Favourite
        if salvage.Active then
            salvage.Activated:Connect(function()
                ForgeRemote:FireServer("Salvage", item.Id)
            end)
        end
    end

    if #(state.Equipment or {}) == 0 then
        text(
            list,
            "No unequipped Wildforge equipment yet. Craft your first piece in the CRAFT tab.",
            UDim2.new(),
            UDim2.fromOffset(900, 55),
            12
        ).TextXAlignment = Enum.TextXAlignment.Center
    end
end

local worldBossOrder = {"Jörmungandr", "Kraken", "Fenrir", "Gaia Titan"}

renderWorldforge = function()
    local state = fetchState()
    if not state then
        toast("Could not load Worldforge equipment.", false)
        return
    end

    currentTab = "Worldforge"
    local panel = makeRoot("WILDFORGE SMITH  ·  WORLDFORGE")

    for _, child in ipairs(panel:GetChildren()) do
        if child:IsA("TextButton") then
            if child.Text == "CRAFT" then
                child.Activated:Connect(function() currentTab = "Craft"; renderCraft() end)
            elseif child.Text == "EQUIPMENT" then
                child.Activated:Connect(function() currentTab = "Equipment"; renderEquipment() end)
            elseif child.Text == "WORLDFORGE" then
                child.Activated:Connect(function() renderWorldforge() end)
            end
        end
    end

    local sourceIndex = table.find(worldBossOrder, selectedWorldBoss) or 1
    local prev = button(panel, "◀", UDim2.fromOffset(20, 126), UDim2.fromOffset(42, 34))
    local source = button(
        panel,
        "BOSS MATERIALS  ·  " .. string.upper(selectedWorldBoss),
        UDim2.fromOffset(68, 126),
        UDim2.fromOffset(340, 34)
    )
    source.Active = false
    local nextButton = button(panel, "▶", UDim2.fromOffset(414, 126), UDim2.fromOffset(42, 34))

    prev.Activated:Connect(function()
        sourceIndex -= 1
        if sourceIndex < 1 then sourceIndex = #worldBossOrder end
        selectedWorldBoss = worldBossOrder[sourceIndex]
        renderWorldforge()
    end)
    nextButton.Activated:Connect(function()
        sourceIndex += 1
        if sourceIndex > #worldBossOrder then sourceIndex = 1 end
        selectedWorldBoss = worldBossOrder[sourceIndex]
        renderWorldforge()
    end)

    local materialSource = EquipmentConfig.WorldforgeSources[selectedWorldBoss]
    local materialText = materialSource
        and (
            tostring(materialSource.Primary)
                .. ": "
                .. tostring(inventoryQuantity(state, "Loot", materialSource.Primary))
                .. " owned   ·   "
                .. tostring(materialSource.Secondary)
                .. ": "
                .. tostring(inventoryQuantity(state, "Loot", materialSource.Secondary))
                .. " owned"
        )
        or "No Worldforge materials configured."

    text(
        panel,
        materialText,
        UDim2.fromOffset(475, 126),
        UDim2.fromOffset(485, 34),
        10
    ).TextColor3 = palette.muted

    local note = text(
        panel,
        "Worldforge upgrades never reroll your item. Each + level increases every rolled stat by 3%, up to +5. "
            .. "Build a great base item first, then invest boss materials.",
        UDim2.fromOffset(20, 169),
        UDim2.fromOffset(940, 44),
        11
    )
    note.TextColor3 = palette.muted

    local all = {}
    for _, item in ipairs(state.Equipment or {}) do
        table.insert(all, {Item = item, Owner = nil})
    end
    for _, pet in ipairs(state.Pets or {}) do
        for _, slotName in ipairs(EquipmentConfig.Slots) do
            local item = type(pet.Equipment) == "table" and pet.Equipment[slotName] or nil
            if item then
                table.insert(all, {Item = item, Owner = pet})
            end
        end
    end

    local list = scrolling(
        panel,
        UDim2.fromOffset(20, 222),
        UDim2.fromOffset(940, 403)
    )

    for _, record in ipairs(all) do
        local item = record.Item
        local current = math.clamp(
            math.floor(tonumber(item.WorldforgeLevel) or 0),
            0,
            EquipmentConfig.MaxWorldforgeLevel
        )

        local row = Instance.new("Frame")
        row.Size = UDim2.fromOffset(914, 92)
        row.BackgroundColor3 = palette.row
        row.BorderSizePixel = 0
        row.Parent = list
        round(row, 7)

        local ownerText = record.Owner
            and ("  ·  EQUIPPED TO " .. tostring(record.Owner.Name or record.Owner.Species))
            or ""

        local info = text(
            row,
            table.concat(itemLines(item), "\n") .. ownerText,
            UDim2.fromOffset(12, 7),
            UDim2.fromOffset(575, 78),
            9
        )
        info.TextYAlignment = Enum.TextYAlignment.Top

        if current >= EquipmentConfig.MaxWorldforgeLevel then
            local maxed = button(
                row,
                "WORLDFORGED +5",
                UDim2.fromOffset(610, 27),
                UDim2.fromOffset(285, 38)
            )
            maxed.Active = false
            maxed.BackgroundColor3 = Color3.fromRGB(66, 91, 69)
        else
            local nextLevel = current + 1
            local cost = EquipmentConfig.WorldforgeCosts[nextLevel]
            local sourceInfo = EquipmentConfig.WorldforgeSources[selectedWorldBoss]

            local costText = sourceInfo and cost
                and (
                    "+"
                        .. tostring(nextLevel)
                        .. "  ·  "
                        .. tostring(cost.Primary)
                        .. " "
                        .. tostring(sourceInfo.Primary)
                        .. (cost.Secondary > 0
                            and (" + " .. tostring(cost.Secondary) .. " " .. tostring(sourceInfo.Secondary))
                            or "")
                        .. " + "
                        .. tostring(cost.Coins)
                        .. " Coins"
                )
                or "SOURCE UNAVAILABLE"

            local upgrade = button(
                row,
                costText,
                UDim2.fromOffset(600, 20),
                UDim2.fromOffset(300, 50)
            )
            upgrade.TextWrapped = true
            upgrade.TextSize = 9
            upgrade.BackgroundColor3 = Color3.fromRGB(82, 67, 49)
            upgrade.Active = sourceInfo ~= nil and cost ~= nil
            upgrade.Activated:Connect(function()
                ForgeRemote:FireServer("Worldforge", item.Id, selectedWorldBoss)
            end)
        end
    end

    if #all == 0 then
        text(
            list,
            "Forge equipment first, then return here with world-boss materials.",
            UDim2.new(),
            UDim2.fromOffset(900, 55),
            12
        ).TextXAlignment = Enum.TextXAlignment.Center
    end
end

renderMain = function()
    if currentTab == "Equipment" then
        renderEquipment()
    elseif currentTab == "Worldforge" then
        renderWorldforge()
    else
        currentTab = "Craft"
        renderCraft()
    end
end

local function makeForgeBar(parent, labelText, y)
    text(
        parent,
        labelText,
        UDim2.fromOffset(42, y),
        UDim2.fromOffset(650, 25),
        13
    ).Font = Enum.Font.GothamBold

    local bar = Instance.new("Frame")
    bar.Position = UDim2.fromOffset(42, y + 31)
    bar.Size = UDim2.fromOffset(716, 36)
    bar.BackgroundColor3 = Color3.fromRGB(54, 58, 63)
    bar.BorderSizePixel = 0
    bar.Parent = parent
    round(bar, 7)

    local target = Instance.new("Frame")
    target.Name = "PerfectZone"
    target.AnchorPoint = Vector2.new(0.5, 0)
    target.Position = UDim2.fromScale(0.5, 0)
    target.Size = UDim2.new(0.05, 0, 1, 0)
    target.BackgroundColor3 = palette.good
    target.BorderSizePixel = 0
    target.Parent = bar
    round(target, 5)

    local marker = Instance.new("Frame")
    marker.Name = "Marker"
    marker.AnchorPoint = Vector2.new(0.5, 0.5)
    marker.Position = UDim2.fromScale(0, 0.5)
    marker.Size = UDim2.fromOffset(8, 48)
    marker.BackgroundColor3 = palette.gold
    marker.BorderSizePixel = 0
    marker.Parent = bar
    round(marker, 4)

    return bar, marker
end

local function showForge(session)
    closeMain()
    closeResult()
    closeForge()

    activeForge = session
    forgeScores = {}
    forgeInput = {Heat = false, Hammer = 0, Quench = false}

    local panel = Instance.new("Frame")
    panel.Name = "ForgeMinigame"
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.Position = UDim2.fromScale(0.5, 0.5)
    panel.Size = UDim2.fromOffset(800, 440)
    panel.BackgroundColor3 = palette.panel
    panel.BorderSizePixel = 0
    panel.Parent = gui
    round(panel, 12)
    stroke(panel, palette.accent, 0.18)
    forgePanel = panel

    local heading = text(
        panel,
        "TEMPERING  ·  " .. tostring(session.BlueprintName or "Equipment"),
        UDim2.fromOffset(28, 15),
        UDim2.fromOffset(744, 34),
        20
    )
    heading.Font = Enum.Font.GothamBlack
    heading.TextColor3 = palette.gold

    local instructions = text(
        panel,
        "Crafting cannot fail. SPACE / TAP at the best moment. A perfect forge requires near-perfect timing in every stage.",
        UDim2.fromOffset(28, 49),
        UDim2.fromOffset(744, 38),
        10
    )
    instructions.TextColor3 = palette.muted

    local stageLabel = text(
        panel,
        "GET READY...",
        UDim2.fromOffset(42, 98),
        UDim2.fromOffset(716, 30),
        16
    )
    stageLabel.Name = "StageLabel"
    stageLabel.Font = Enum.Font.GothamBold
    stageLabel.TextXAlignment = Enum.TextXAlignment.Center

    local bar, marker = makeForgeBar(panel, "FORGE PRECISION", 142)

    local scoreLabel = text(
        panel,
        "HEAT —   ·   HAMMER — / — / —   ·   QUENCH —",
        UDim2.fromOffset(42, 235),
        UDim2.fromOffset(716, 30),
        12
    )
    scoreLabel.Name = "ScoreLabel"
    scoreLabel.TextXAlignment = Enum.TextXAlignment.Center
    scoreLabel.TextColor3 = palette.muted

    local strike = button(
        panel,
        "PRESS SPACE / TAP",
        UDim2.fromOffset(250, 292),
        UDim2.fromOffset(300, 54)
    )
    strike.Name = "StrikeButton"
    strike.BackgroundColor3 = Color3.fromRGB(111, 69, 39)
    strike.TextSize = 15

    local footer = text(
        panel,
        "HEAT: centre the moving marker  ·  HAMMER: hit all 3 beats  ·  QUENCH: strike when cooling reaches the centre",
        UDim2.fromOffset(42, 365),
        UDim2.fromOffset(716, 42),
        10
    )
    footer.TextXAlignment = Enum.TextXAlignment.Center
    footer.TextColor3 = palette.muted

    local function sendInput()
        if not activeForge or activeForge.Id ~= session.Id then return end
        local now = workspace:GetServerTimeNow()

        if now < session.StartAt then return end

        if now <= session.StartAt + 4.1 then
            if not forgeInput.Heat then
                forgeInput.Heat = true
                ForgeRemote:FireServer("ForgeInput", session.Id, "Heat", 1, now)
            end
            return
        end

        if now <= session.StartAt + 8.6 then
            if forgeInput.Hammer < 3 then
                forgeInput.Hammer += 1
                ForgeRemote:FireServer(
                    "ForgeInput",
                    session.Id,
                    "Hammer",
                    forgeInput.Hammer,
                    now
                )
            end
            return
        end

        if not forgeInput.Quench then
            forgeInput.Quench = true
            ForgeRemote:FireServer("ForgeInput", session.Id, "Quench", 1, now)
        end
    end

    currentForgeInputAction = sendInput
    strike.Activated:Connect(sendInput)

    local connection
    connection = RunService.RenderStepped:Connect(function()
        if not panel.Parent or not activeForge or activeForge.Id ~= session.Id then
            connection:Disconnect()
            return
        end

        local now = workspace:GetServerTimeNow()
        local elapsed = now - session.StartAt
        local position = 0

        if elapsed < 0 then
            stageLabel.Text = "GET READY  ·  " .. string.format("%.1f", math.abs(elapsed))
            strike.Active = false
            strike.Text = "WAIT FOR THE FORGE"

        elseif elapsed <= 4.1 then
            stageLabel.Text = forgeInput.Heat and "HEAT LOCKED" or "HEAT  ·  CENTRE THE MARKER"
            strike.Active = not forgeInput.Heat
            strike.Text = forgeInput.Heat and "HEAT RECORDED" or "LOCK TEMPERATURE"

            local phase = ((now - session.StartAt) / session.HeatPeriod + session.HeatOffset) % 2
            position = phase <= 1 and phase or (2 - phase)

        elseif elapsed <= 8.6 then
            local nextIndex = math.min(3, forgeInput.Hammer + 1)
            stageLabel.Text = forgeInput.Hammer >= 3
                and "HAMMERING COMPLETE"
                or ("HAMMER STRIKE " .. tostring(nextIndex) .. " / 3")
            strike.Active = forgeInput.Hammer < 3
            strike.Text = forgeInput.Hammer >= 3 and "ALL STRIKES RECORDED" or "HAMMER"

            if forgeInput.Hammer < 3 then
                local targetAt = session.HammerTargets[nextIndex]
                local delta = now - targetAt
                position = math.clamp(0.5 + delta / 1.1, 0, 1)
            else
                position = 0.5
            end

        else
            stageLabel.Text = forgeInput.Quench and "QUENCH LOCKED" or "QUENCH  ·  WAIT FOR THE CENTRE"
            strike.Active = not forgeInput.Quench
            strike.Text = forgeInput.Quench and "QUENCH RECORDED" or "QUENCH"

            local delta = now - session.QuenchTarget
            position = math.clamp(0.5 + delta / 1.4, 0, 1)
        end

        marker.Position = UDim2.fromScale(position, 0.5)

        local function shown(key)
            local value = forgeScores[key]
            return value == nil and "—" or tostring(value)
        end
        scoreLabel.Text = "HEAT "
            .. shown("Heat")
            .. "   ·   HAMMER "
            .. shown("Hammer1")
            .. " / "
            .. shown("Hammer2")
            .. " / "
            .. shown("Hammer3")
            .. "   ·   QUENCH "
            .. shown("Quench")

        if now > session.EndAt + 1 then
            strike.Active = false
            strike.Text = "FINISHING EQUIPMENT..."
        end
    end)
end

local function showResult(item)
    activeForge = nil
    currentForgeInputAction = nil
    closeForge()
    closeResult()

    resultPanel = Instance.new("Frame")
    resultPanel.Name = "ForgeResult"
    resultPanel.AnchorPoint = Vector2.new(0.5, 0.5)
    resultPanel.Position = UDim2.fromScale(0.5, 0.5)
    resultPanel.Size = UDim2.fromOffset(570, 430)
    resultPanel.BackgroundColor3 = palette.panel
    resultPanel.BorderSizePixel = 0
    resultPanel.Parent = gui
    round(resultPanel, 12)
    stroke(
        resultPanel,
        item.Quality == "Perfect" and palette.gold or palette.accent,
        0.18
    )

    local title = text(
        resultPanel,
        item.Quality == "Perfect" and "PERFECT FORGE!" or "FORGE COMPLETE",
        UDim2.fromOffset(20, 18),
        UDim2.fromOffset(530, 35),
        22
    )
    title.Font = Enum.Font.GothamBlack
    title.TextColor3 = item.Quality == "Perfect" and palette.gold or palette.text
    title.TextXAlignment = Enum.TextXAlignment.Center

    local score = text(
        resultPanel,
        "FORGE SCORE  "
            .. tostring(item.ForgeScore or 0)
            .. "/100  ·  "
            .. tostring(item.Tier)
            .. " "
            .. tostring(item.Quality)
            .. "  ·  ITEM LEVEL "
            .. tostring(item.ItemLevel),
        UDim2.fromOffset(20, 61),
        UDim2.fromOffset(530, 26),
        12
    )
    score.TextXAlignment = Enum.TextXAlignment.Center
    score.TextColor3 = palette.muted

    local box = text(
        resultPanel,
        table.concat(itemLines(item), "\n"),
        UDim2.fromOffset(30, 105),
        UDim2.fromOffset(510, 205),
        14
    )
    box.BackgroundTransparency = 0
    box.BackgroundColor3 = palette.inset
    box.TextYAlignment = Enum.TextYAlignment.Top
    box.TextXAlignment = Enum.TextXAlignment.Center
    round(box, 9)

    local note = text(
        resultPanel,
        item.Quality == "Perfect"
            and "Perfect forging unlocked the third substat."
            or "Reforge this blueprint whenever you want to hunt for a higher level, quality or better substats.",
        UDim2.fromOffset(30, 321),
        UDim2.fromOffset(510, 42),
        10
    )
    note.TextXAlignment = Enum.TextXAlignment.Center
    note.TextColor3 = palette.muted

    local back = button(
        resultPanel,
        "BACK TO WILDFORGE",
        UDim2.fromOffset(165, 375),
        UDim2.fromOffset(240, 38)
    )
    back.BackgroundColor3 = Color3.fromRGB(97, 68, 42)
    back.Activated:Connect(function()
        closeResult()
        currentTab = "Equipment"
        renderEquipment()
    end)
end

UserInputService.InputBegan:Connect(function(input, processed)
    if processed or not activeForge then return end
    if input.KeyCode == Enum.KeyCode.Space and currentForgeInputAction then
        currentForgeInputAction()
    end
end)

ForgeRemote.OnClientEvent:Connect(function(action, ...)
    local args = {...}

    if action == "Open" then
        activeForge = nil
        closeForge()
        closeResult()
        renderMain()

    elseif action == "ForgeStarted" then
        if type(args[1]) == "table" then
            showForge(args[1])
        end

    elseif action == "InputScored" then
        local stage = tostring(args[1] or "")
        local index = tonumber(args[2])
        local score = math.clamp(math.floor(tonumber(args[3]) or 0), 0, 100)
        local key = stage == "Hammer"
            and ("Hammer" .. tostring(index or 1))
            or stage
        forgeScores[key] = score

    elseif action == "ForgeFinished" then
        if type(args[1]) == "table" then
            showResult(args[1])
        end

    elseif action == "EquipmentResult" then
        local success = args[1] == true
        local message = tostring(args[2] or (success and "Equipment updated." or "Equipment update failed."))
        toast(message, success)
        if success and mainPanel then
            task.defer(renderMain)
        end

    elseif action == "Error" then
        toast(args[1] or "Wildforge action failed.", false)
        if mainPanel then
            task.defer(renderMain)
        end
    end
end)
