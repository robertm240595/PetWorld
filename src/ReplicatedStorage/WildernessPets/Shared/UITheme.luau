local Theme = {}

Theme.Colors = {
    Parchment = Color3.fromRGB(229, 201, 146),
    ParchmentLight = Color3.fromRGB(247, 226, 178),
    ParchmentDark = Color3.fromRGB(190, 151, 91),
    Leather = Color3.fromRGB(80, 49, 27),
    LeatherDark = Color3.fromRGB(38, 25, 18),
    LeatherSoft = Color3.fromRGB(112, 73, 39),
    Forest = Color3.fromRGB(58, 77, 39),
    ForestLight = Color3.fromRGB(91, 119, 55),
    Gold = Color3.fromRGB(235, 184, 73),
    GoldDark = Color3.fromRGB(116, 76, 26),
    Cream = Color3.fromRGB(255, 240, 199),
    Ink = Color3.fromRGB(43, 30, 20),
    MutedInk = Color3.fromRGB(103, 82, 58),
    Inset = Color3.fromRGB(43, 35, 28),
    Inset2 = Color3.fromRGB(59, 47, 36),
    Green = Color3.fromRGB(83, 153, 55),
    Disabled = Color3.fromRGB(76, 69, 59),
    Red = Color3.fromRGB(151, 55, 37),
    Blue = Color3.fromRGB(61, 151, 205),
}

function Theme.Corner(object, radius)
    local c = object:FindFirstChild("AdventureCorner") or Instance.new("UICorner")
    c.Name = "AdventureCorner"
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = object
    return c
end

function Theme.Stroke(object, color, thickness, transparency)
    local s = object:FindFirstChild("AdventureStroke") or Instance.new("UIStroke")
    s.Name = "AdventureStroke"
    s.Color = color or Theme.Colors.GoldDark
    s.Thickness = thickness or 2
    s.Transparency = transparency or 0
    s.Parent = object
    return s
end

function Theme.RopeBorder(object, inset)
    local rope = object:FindFirstChild("RopeBorder")
    if rope then return rope end
    rope = Instance.new("Frame")
    rope.Name = "RopeBorder"
    rope.BackgroundTransparency = 1
    rope.Position = UDim2.fromOffset(inset or 4, inset or 4)
    rope.Size = UDim2.new(1, -2*(inset or 4), 1, -2*(inset or 4))
    rope.ZIndex = math.max(1, object.ZIndex + 20)
    rope.Parent = object
    Theme.Corner(rope, 11)
    local outer = Theme.Stroke(rope, Color3.fromRGB(91, 55, 24), 6, 0)
    outer.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    local inner = Instance.new("UIStroke")
    inner.Name = "RopeHighlight"
    inner.Color = Color3.fromRGB(205, 148, 70)
    inner.Thickness = 2
    inner.Transparency = .08
    inner.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    inner.Parent = rope
    return rope
end

function Theme.Panel(object, parchment)
    object.BorderSizePixel = 0
    object.BackgroundColor3 = parchment and Theme.Colors.Parchment or Theme.Colors.LeatherDark
    object.BackgroundTransparency = parchment and .02 or .04
    Theme.Corner(object, 11)
    Theme.Stroke(object, Theme.Colors.GoldDark, 2, .05)
    Theme.RopeBorder(object, 4)
end

function Theme.Button(object, selected)
    object.BorderSizePixel = 0
    object.AutoButtonColor = false
    object.BackgroundColor3 = selected and Theme.Colors.ParchmentLight or Theme.Colors.Leather
    object.TextColor3 = selected and Theme.Colors.Ink or Theme.Colors.Cream
    object.Font = Enum.Font.GothamBold
    Theme.Corner(object, 7)
    Theme.Stroke(object, selected and Theme.Colors.Gold or Theme.Colors.GoldDark, selected and 2 or 1, .08)
end

function Theme.Text(object, heading)
    object.TextColor3 = heading and Theme.Colors.Ink or Theme.Colors.Cream
    object.TextStrokeColor3 = Theme.Colors.LeatherDark
    object.TextStrokeTransparency = heading and .82 or .45
    object.Font = heading and Enum.Font.GothamBold or Enum.Font.GothamMedium
end

return Theme
