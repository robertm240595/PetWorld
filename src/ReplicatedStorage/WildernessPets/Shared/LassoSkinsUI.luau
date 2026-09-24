local Root = script.Parent.Parent
local SkinConfig = require(script.Parent.LassoSkinConfig)
local Preview = require(script.Parent.LassoSkinPreview)

local UI = {}

local function label(parent, value, position, size, textSize)
    local item = Instance.new("TextLabel")
    item.BackgroundTransparency = 1
    item.Text = value
    item.Position = position
    item.Size = size
    item.TextColor3 = Color3.new(1, 1, 1)
    item.Font = Enum.Font.GothamBold
    item.TextSize = textSize or 12
    item.TextXAlignment = Enum.TextXAlignment.Left
    item.ZIndex = 22
    item.Parent = parent
    return item
end

local function dropRateText(rarity)
    local percent = (tonumber(SkinConfig.DropRates[rarity]) or 0) * 100
    if percent >= 1 then
        return string.format("%.0f%%", percent)
    elseif percent >= 0.1 then
        return string.format("%.1f%%", percent)
    end
    return string.format("%.2f%%", percent)
end

function UI.Render(panel, state, fire)
    local old = panel:FindFirstChild("LassoSkinsContent")
    if old then old:Destroy() end

    local owned = state.LassoSkinsOwned or {}
    local equippedId = tostring(state.EquippedLassoSkin or "")
    local models = Root:FindFirstChild("LassoModels")
    local tierName = state.Lasso or "Rough Rope"
    local template = models and models:FindFirstChild(tierName)

    local box = Instance.new("Frame")
    box.Name = "LassoSkinsContent"
    box.Position = UDim2.fromOffset(18, 108)
    box.Size = UDim2.fromOffset(782, 492)
    box.BackgroundColor3 = Color3.fromRGB(30, 34, 42)
    box.BorderSizePixel = 0
    box.ClipsDescendants = true
    box.ZIndex = 20
    box.Parent = panel

    local boxCorner = Instance.new("UICorner")
    boxCorner.CornerRadius = UDim.new(0, 10)
    boxCorner.Parent = box

    local equipped = SkinConfig.Get(equippedId)
    local status = label(
        box,
        "COSMETIC ONLY  ·  Equipped: " .. (equipped and equipped.Name or "Base appearance")
            .. "  ·  Wild drops never change capture strength",
        UDim2.fromOffset(12, 5),
        UDim2.fromOffset(752, 26),
        11
    )
    status.TextColor3 = Color3.fromRGB(210, 215, 224)

    local list = Instance.new("ScrollingFrame")
    list.Name = "SkinGrid"
    list.Position = UDim2.fromOffset(8, 34)
    list.Size = UDim2.fromOffset(766, 450)
    list.BackgroundTransparency = 1
    list.BorderSizePixel = 0
    list.ScrollBarThickness = 5
    list.AutomaticCanvasSize = Enum.AutomaticSize.Y
    list.CanvasSize = UDim2.new()
    list.ZIndex = 21
    list.Parent = box

    local grid = Instance.new("UIGridLayout")
    grid.CellSize = UDim2.fromOffset(374, 106)
    grid.CellPadding = UDim2.fromOffset(8, 8)
    grid.FillDirection = Enum.FillDirection.Horizontal
    grid.FillDirectionMaxCells = 2
    grid.SortOrder = Enum.SortOrder.LayoutOrder
    grid.Parent = list

    for index, skinId in ipairs(SkinConfig.Order) do
        local skin = SkinConfig.Get(skinId)
        if skin then
            local has = owned[skinId] == true
            local on = equippedId == skinId

            local card = Instance.new("Frame")
            card.Name = "Skin_" .. skinId
            card.LayoutOrder = index
            card.BackgroundColor3 = on
                and Color3.fromRGB(62, 73, 58)
                or (has and Color3.fromRGB(43, 48, 58) or Color3.fromRGB(35, 38, 45))
            card.BorderSizePixel = 0
            card.ZIndex = 21
            card.Parent = list

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 9)
            corner.Parent = card

            Preview.Make(card, template, tierName, skinId, has)

            local name = label(
                card,
                (has and "" or "LOCKED  ") .. skin.Name,
                UDim2.fromOffset(104, 9),
                UDim2.fromOffset(258, 22),
                13
            )
            name.TextTruncate = Enum.TextTruncate.AtEnd

            local rarity = label(
                card,
                skin.Rarity .. "  ·  Wild drop " .. dropRateText(skin.Rarity),
                UDim2.fromOffset(104, 35),
                UDim2.fromOffset(258, 20),
                10
            )
            rarity.TextColor3 = SkinConfig.RarityColors[skin.Rarity] or Color3.new(1, 1, 1)

            local stateText = label(
                card,
                on and "CURRENTLY EQUIPPED" or (has and "Owned" or "Not collected"),
                UDim2.fromOffset(104, 57),
                UDim2.fromOffset(126, 18),
                9
            )
            stateText.TextColor3 = Color3.fromRGB(185, 192, 203)

            local action = Instance.new("TextButton")
            action.Name = "SkinAction"
            action.Text = not has and "LOCKED" or (on and "UNEQUIP" or "EQUIP")
            action.Position = UDim2.fromOffset(232, 68)
            action.Size = UDim2.fromOffset(128, 29)
            action.Font = Enum.Font.GothamBold
            action.TextSize = 10
            action.TextColor3 = Color3.new(1, 1, 1)
            action.BackgroundColor3 = not has and Color3.fromRGB(49, 50, 54)
                or (on and Color3.fromRGB(88, 78, 53) or Color3.fromRGB(55, 70, 90))
            action.BorderSizePixel = 0
            action.ZIndex = 22
            action.Parent = card

            local actionCorner = Instance.new("UICorner")
            actionCorner.CornerRadius = UDim.new(0, 7)
            actionCorner.Parent = action

            if not has then
                action.Active = false
                action.AutoButtonColor = false
            elseif on then
                action.MouseButton1Click:Connect(function()
                    fire("UnequipLassoSkin")
                end)
            else
                action.MouseButton1Click:Connect(function()
                    fire("EquipLassoSkin", skinId)
                end)
            end
        end
    end

    return box
end

return UI
