local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Root = ReplicatedStorage:WaitForChild("WildernessPets")
local BossLootRemote = Root.Remotes:WaitForChild("BossLoot")
local world = workspace:WaitForChild("WildernessPets")
local folder = world:WaitForChild("WorldBossLootPouches")

local gui = Instance.new("ScreenGui")
gui.Name = "WorldBossLootUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 115
gui.Parent = playerGui

local panel

local function round(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = parent
end

local function stroke(parent)
    local s = Instance.new("UIStroke")
    s.Color = Color3.fromRGB(236, 150, 76)
    s.Transparency = .25
    s.Parent = parent
end

local function close()
    if panel then
        panel:Destroy()
        panel = nil
    end
end

local function showToast(message, good)
    local old = gui:FindFirstChild("BossLootToast")
    if old then old:Destroy() end

    local t = Instance.new("TextLabel")
    t.Name = "BossLootToast"
    t.AnchorPoint = Vector2.new(.5, 0)
    t.Position = UDim2.new(.5, 0, 0, 92)
    t.Size = UDim2.fromOffset(520, 42)
    t.BackgroundColor3 = Color3.fromRGB(26, 27, 32)
    t.BackgroundTransparency = .05
    t.BorderSizePixel = 0
    t.Font = Enum.Font.GothamBold
    t.TextSize = 12
    t.TextWrapped = true
    t.TextColor3 = good and Color3.fromRGB(164, 231, 169) or Color3.fromRGB(240, 165, 154)
    t.Text = tostring(message or "")
    t.Parent = gui
    round(t, 8)
    stroke(t)

    task.delay(4.5, function()
        if t.Parent then t:Destroy() end
    end)
end

local function showPouch(data)
    if type(data) ~= "table" or type(data.PouchId) ~= "string" then return end
    close()

    panel = Instance.new("Frame")
    panel.Name = "BossPouchWindow"
    panel.AnchorPoint = Vector2.new(.5, .5)
    panel.Position = UDim2.new(.5, 0, .5, 40)
    panel.Size = UDim2.fromOffset(470, 380)
    panel.BackgroundColor3 = Color3.fromRGB(25, 25, 31)
    panel.BorderSizePixel = 0
    panel.Parent = gui
    round(panel, 12)
    stroke(panel)

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Position = UDim2.fromOffset(20, 15)
    title.Size = UDim2.fromOffset(360, 30)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 20
    title.TextColor3 = Color3.fromRGB(255, 184, 98)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = "WORLD BOSS POUCH"
    title.Parent = panel

    local boss = Instance.new("TextLabel")
    boss.BackgroundTransparency = 1
    boss.Position = UDim2.fromOffset(20, 48)
    boss.Size = UDim2.fromOffset(410, 24)
    boss.Font = Enum.Font.GothamMedium
    boss.TextSize = 12
    boss.TextColor3 = Color3.fromRGB(190, 194, 200)
    boss.TextXAlignment = Enum.TextXAlignment.Left
    boss.Text = tostring(data.BossSpecies or "World Boss")
    boss.Parent = panel

    local closeButton = Instance.new("TextButton")
    closeButton.Position = UDim2.new(1, -47, 0, 12)
    closeButton.Size = UDim2.fromOffset(32, 30)
    closeButton.BackgroundColor3 = Color3.fromRGB(52, 47, 56)
    closeButton.BorderSizePixel = 0
    closeButton.Font = Enum.Font.GothamBold
    closeButton.TextSize = 19
    closeButton.TextColor3 = Color3.new(1,1,1)
    closeButton.Text = "×"
    closeButton.Parent = panel
    round(closeButton, 6)
    closeButton.Activated:Connect(close)

    local contents = Instance.new("TextLabel")
    contents.Position = UDim2.fromOffset(20, 85)
    contents.Size = UDim2.fromOffset(430, 185)
    contents.BackgroundColor3 = Color3.fromRGB(37, 39, 46)
    contents.BorderSizePixel = 0
    contents.Font = Enum.Font.GothamMedium
    contents.TextSize = 14
    contents.TextWrapped = true
    contents.TextColor3 = Color3.fromRGB(238, 229, 207)
    contents.Parent = panel
    round(contents, 9)

    local rewards = {}

    for _, material in ipairs(data.Materials or {}) do
        if type(material) == "table" then
            table.insert(
                rewards,
                tostring(material.Name or "Boss Material")
                    .. "  ×"
                    .. tostring(material.Quantity or 1)
            )
        end
    end

    if data.PetReward then
        table.insert(
            rewards,
            "0.01% ANCIENT PET RELIC  ·  "
                .. tostring(data.PetItemName or (tostring(data.PetReward) .. " Pet Relic"))
        )
    end

    if data.MountReward then
        table.insert(
            rewards,
            "0.01% ANCIENT MOUNT RELIC  ·  "
                .. tostring(data.MountItemName or (tostring(data.MountReward) .. " Mount Relic"))
        )
    end

    if type(data.EquipmentReward) == "table" then
        local item = data.EquipmentReward
        table.insert(
            rewards,
            "1% WORLD-BOSS EQUIPMENT  ·  "
                .. tostring(item.Name or "Ancient Equipment")
                .. "  ·  "
                .. tostring(item.Quality or "Ancient")
                .. " Lv."
                .. tostring(item.ItemLevel or 5)
        )

        if type(item.MainStat) == "table" then
            table.insert(
                rewards,
                "MAIN: "
                    .. tostring(item.MainStat.Name or "Stat")
                    .. " +"
                    .. tostring(math.floor((tonumber(item.MainStat.Value) or 0) * 1000 + 0.5) / 10)
                    .. "%"
            )
        end
        for index, sub in ipairs(item.Substats or {}) do
            if type(sub) == "table" then
                table.insert(
                    rewards,
                    "SUB "
                        .. tostring(index)
                        .. ": "
                        .. tostring(sub.Name or "Stat")
                        .. " +"
                        .. tostring(math.floor((tonumber(sub.Value) or 0) * 1000 + 0.5) / 10)
                        .. "%"
                )
            end
        end
    end

    if #rewards == 0 then
        table.insert(rewards, "No boss rewards were generated.")
    end
    contents.Text = table.concat(rewards, "\n")

    local note = Instance.new("TextLabel")
    note.BackgroundTransparency = 1
    note.Position = UDim2.fromOffset(20, 280)
    note.Size = UDim2.fromOffset(430, 32)
    note.Font = Enum.Font.GothamMedium
    note.TextSize = 10
    note.TextWrapped = true
    note.TextColor3 = Color3.fromRGB(163, 166, 172)
    note.Text = "Pet/mount relics go into your backpack first. The separate 1% world-boss equipment roll is stored in Wildforge equipment storage."
    note.Parent = panel

    local collect = Instance.new("TextButton")
    collect.AnchorPoint = Vector2.new(.5, 0)
    collect.Position = UDim2.new(.5, 0, 0, 326)
    collect.Size = UDim2.fromOffset(220, 36)
    collect.BackgroundColor3 = Color3.fromRGB(88, 61, 47)
    collect.BorderSizePixel = 0
    collect.Font = Enum.Font.GothamBold
    collect.TextSize = 12
    collect.TextColor3 = Color3.fromRGB(255, 229, 187)
    collect.Text = "COLLECT POUCH"
    collect.Parent = panel
    round(collect, 7)
    stroke(collect)

    collect.Activated:Connect(function()
        collect.Active = false
        collect.Text = "COLLECTING..."
        BossLootRemote:FireServer("Collect", data.PouchId)
    end)
end

local function configure(model)
    if not model:IsA("Model") then return end
    local owner = tonumber(model:GetAttribute("BossLootOwnerUserId"))
    local mine = owner == player.UserId

    for _, item in ipairs(model:GetDescendants()) do
        if item:IsA("BasePart") then
            item.LocalTransparencyModifier = mine and 0 or 1
        elseif item:IsA("BillboardGui") or item:IsA("ProximityPrompt") or item:IsA("PointLight") then
            item.Enabled = mine
        end
    end
end

for _, child in ipairs(folder:GetChildren()) do configure(child) end
folder.ChildAdded:Connect(function(child)
    task.defer(function() configure(child) end)
end)

BossLootRemote.OnClientEvent:Connect(function(action, first, second)
    if action == "Open" then
        showPouch(first)
    elseif action == "CollectResult" then
        if first == true then
            local result = type(second) == "table" and second or {}
            close()
            local rewards = {}
            for _, material in ipairs(result.Materials or {}) do
                if type(material) == "table" then
                    table.insert(
                        rewards,
                        tostring(material.Quantity or 1) .. "x " .. tostring(material.Name or "boss material")
                    )
                end
            end
            if result.PetReward then
                table.insert(rewards, tostring(result.PetItemName or result.PetReward .. " Pet Relic"))
            end
            if result.MountReward then
                table.insert(rewards, tostring(result.MountItemName or result.MountReward .. " Mount Relic"))
            end
            if type(result.EquipmentReward) == "table" then
                table.insert(rewards, tostring(result.EquipmentReward.Name or "Ancient world-boss equipment"))
            end

            local share = math.max(0, tonumber(result.ContributionShare) or 0)
            if share > 0 then
                table.insert(
                    rewards,
                    "Contribution "
                        .. tostring(math.floor(share * 1000 + 0.5) / 10)
                        .. "% ("
                        .. tostring(math.floor(tonumber(result.DamageContribution) or 0))
                        .. " damage + "
                        .. tostring(math.floor(tonumber(result.SupportContribution) or 0))
                        .. " support)"
                )
            end

            showToast(
                #rewards > 0
                    and ("Stored in backpack: " .. table.concat(rewards, " + "))
                    or "World-boss pouch collected.",
                true
            )
        else
            showToast(second or "Could not collect world-boss pouch.", false)
        end
    elseif action == "Error" then
        showToast(first or "That world-boss pouch is unavailable.", false)
    end
end)
