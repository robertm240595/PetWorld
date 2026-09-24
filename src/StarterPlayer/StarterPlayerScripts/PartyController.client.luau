local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Root = ReplicatedStorage:WaitForChild("WildernessPets")
local Remotes = Root:WaitForChild("Remotes")
local PartyInviteRemote = Remotes:WaitForChild("PartyInvite")
local PartyActionRemote = Remotes:WaitForChild("PartyAction")
local PartyStateRemote = Remotes:WaitForChild("PartyState")

----------------------------------------------------------------
-- State
----------------------------------------------------------------

local currentParty = nil -- { PartyKey, Members, LeaderUserId }
local pendingInvite = nil -- { FromUserId, FromName, FromDisplayName, PartyKey, PartySize, MaxSize }

----------------------------------------------------------------
-- UI helpers
----------------------------------------------------------------

local gui = Instance.new("ScreenGui")
gui.Name = "PartyUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 115
gui.Parent = playerGui

local function round(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = parent
end

local function stroke(parent, color)
    local s = Instance.new("UIStroke")
    s.Color = color or Color3.fromRGB(110, 126, 148)
    s.Transparency = .35
    s.Thickness = 1
    s.Parent = parent
end

local function makeText(parent, value, position, size, textSize)
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Position = position or UDim2.new()
    label.Size = size or UDim2.fromOffset(200, 24)
    label.Font = Enum.Font.GothamMedium
    label.TextSize = textSize or 12
    label.TextColor3 = Color3.fromRGB(232, 235, 239)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextWrapped = true
    label.Text = tostring(value or "")
    label.Parent = parent
    return label
end

local function makeButton(parent, value, position, size)
    local button = Instance.new("TextButton")
    button.Position = position or UDim2.new()
    button.Size = size or UDim2.fromOffset(120, 36)
    button.BackgroundColor3 = Color3.fromRGB(48, 56, 67)
    button.BorderSizePixel = 0
    button.Font = Enum.Font.GothamBold
    button.TextSize = 11
    button.TextColor3 = Color3.fromRGB(240, 241, 244)
    button.Text = tostring(value or "")
    button.Parent = parent
    round(button, 7)
    return button
end

local function toast(message, good)
    local old = gui:FindFirstChild("PartyToast")
    if old then old:Destroy() end

    local label = makeText(
        gui,
        message,
        UDim2.new(.5, -260, 0, 52),
        UDim2.fromOffset(520, 48),
        12
    )
    label.Name = "PartyToast"
    label.BackgroundTransparency = .08
    label.BackgroundColor3 = Color3.fromRGB(24, 27, 32)
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextColor3 = good == false
        and Color3.fromRGB(240, 164, 154)
        or Color3.fromRGB(175, 228, 181)
    round(label, 8)
    stroke(label)

    task.delay(4, function()
        if label.Parent then label:Destroy() end
    end)
end

----------------------------------------------------------------
-- Party HUD (always-visible member list)
----------------------------------------------------------------

local hudFrame = Instance.new("Frame")
hudFrame.Name = "PartyHUD"
hudFrame.Position = UDim2.new(0, 12, 0, 120)
hudFrame.Size = UDim2.fromOffset(200, 30)
hudFrame.BackgroundColor3 = Color3.fromRGB(25, 29, 35)
hudFrame.BackgroundTransparency = .15
hudFrame.BorderSizePixel = 0
hudFrame.Visible = false
hudFrame.Parent = gui
round(hudFrame, 8)
stroke(hudFrame)

local hudLayout = Instance.new("UIListLayout")
hudLayout.Padding = UDim.new(0, 2)
hudLayout.Parent = hudFrame

local function refreshHUD()
    for _, child in ipairs(hudFrame:GetChildren()) do
        if child:IsA("TextLabel") or child:IsA("TextButton") then
            child:Destroy()
        end
    end

    if not currentParty or #currentParty.Members == 0 then
        hudFrame.Visible = false
        return
    end

    hudFrame.Visible = true

    local title = makeText(hudFrame, "PARTY", UDim2.fromOffset(8, 4), UDim2.fromOffset(180, 20), 13)
    title.Font = Enum.Font.GothamBold
    title.Name = "Title"

    for _, member in ipairs(currentParty.Members) do
        local suffix = member.IsLeader and " ★" or ""
        local row = makeText(
            hudFrame,
            member.DisplayName .. suffix,
            UDim2.fromOffset(8, 0),
            UDim2.fromOffset(180, 18),
            11
        )
        row.Name = "Member_" .. tostring(member.UserId)
        row.TextColor3 = member.UserId == player.UserId
            and Color3.fromRGB(175, 228, 181)
            or Color3.fromRGB(210, 215, 222)
    end

    local leaveBtn = makeButton(hudFrame, "LEAVE", UDim2.fromOffset(8, 0), UDim2.fromOffset(80, 26))
    leaveBtn.Name = "LeaveBtn"
    leaveBtn.TextSize = 10
    leaveBtn.Activated:Connect(function()
        PartyActionRemote:FireServer("Leave")
    end)

    -- Resize frame
    local count = #currentParty.Members
    hudFrame.Size = UDim2.fromOffset(200, 30 + count * 20 + 30)
end

----------------------------------------------------------------
-- Invite popup
----------------------------------------------------------------

local function showInvitePopup(data)
    if type(data) ~= "table" then return end
    pendingInvite = data

    local old = gui:FindFirstChild("PartyInvitePopup")
    if old then old:Destroy() end

    local popup = Instance.new("Frame")
    popup.Name = "PartyInvitePopup"
    popup.AnchorPoint = Vector2.new(.5, 0)
    popup.Position = UDim2.new(.5, 0, 0, 145)
    popup.Size = UDim2.fromOffset(460, 110)
    popup.BackgroundColor3 = Color3.fromRGB(29, 34, 41)
    popup.BorderSizePixel = 0
    popup.Parent = gui
    round(popup, 10)
    stroke(popup)

    local title = makeText(
        popup,
        tostring(data.FromDisplayName or data.FromName or "A player") .. " invited you to a party!",
        UDim2.fromOffset(16, 12),
        UDim2.fromOffset(420, 28),
        15
    )
    title.Font = Enum.Font.GothamBold

    local info = makeText(
        popup,
        "Party size: " .. tostring(data.PartySize or 1) .. "/" .. tostring(data.MaxSize or 6),
        UDim2.fromOffset(16, 43),
        UDim2.fromOffset(400, 20),
        10
    )
    info.TextColor3 = Color3.fromRGB(174, 181, 191)

    local accept = makeButton(popup, "ACCEPT", UDim2.fromOffset(120, 72), UDim2.fromOffset(100, 30))
    accept.BackgroundColor3 = Color3.fromRGB(61, 101, 73)

    local decline = makeButton(popup, "DECLINE", UDim2.fromOffset(240, 72), UDim2.fromOffset(100, 30))
    decline.BackgroundColor3 = Color3.fromRGB(97, 55, 57)

    accept.Activated:Connect(function()
        if popup.Parent then popup:Destroy() end
        pendingInvite = nil
        PartyInviteRemote:FireServer("Accept")
    end)

    decline.Activated:Connect(function()
        if popup.Parent then popup:Destroy() end
        pendingInvite = nil
        PartyInviteRemote:FireServer("Decline")
    end)

    task.delay(30, function()
        if popup.Parent then popup:Destroy() end
        pendingInvite = nil
    end)
end

----------------------------------------------------------------
-- Remote listeners
----------------------------------------------------------------

PartyInviteRemote.OnClientEvent:Connect(function(action, ...)
    local args = { ... }

    if action == "InviteResult" then
        local success, message = args[1], args[2]
        toast(message or "Invite sent.", success)

    elseif action == "AcceptResult" then
        local success, message = args[1], args[2]
        toast(message or "Joined party.", success)

    elseif action == "DeclineResult" then
        local success, message = args[1], args[2]
        toast(message or "Invite declined.", success)
    end
end)

PartyActionRemote.OnClientEvent:Connect(function(action, ...)
    local args = { ... }

    if action == "LeaveResult" then
        local success, message = args[1], args[2]
        toast(message or "Left party.", success)

    elseif action == "KickResult" then
        local success, message = args[1], args[2]
        toast(message or "Member kicked.", success)
    end
end)

PartyStateRemote.OnClientEvent:Connect(function(action, data)
    if action == "Created" or action == "Update" then
        if type(data) == "table" then
            currentParty = data
            refreshHUD()
        end

    elseif action == "MemberJoined" or action == "MemberLeft" or action == "MemberKicked" or action == "LeaderChanged" then
        if type(data) == "table" then
            currentParty = data
            refreshHUD()
        end

    elseif action == "InviteReceived" then
        showInvitePopup(data)

    elseif action == "InviteExpired" then
        local popup = gui:FindFirstChild("PartyInvitePopup")
        if popup then popup:Destroy() end
        pendingInvite = nil

    elseif action == "InviteDeclined" then
        if type(data) == "table" then
            toast(tostring(data.TargetName or "Player") .. " declined your party invite.", false)
        end

    elseif action == "Disbanded" then
        currentParty = nil
        refreshHUD()
        if type(data) == "table" then
            toast(data.Reason or "Party disbanded.", false)
        end

    elseif action == "Kicked" then
        currentParty = nil
        refreshHUD()
        toast("You were kicked from the party.", false)

    elseif action == "Left" then
        currentParty = nil
        refreshHUD()
    end
end)