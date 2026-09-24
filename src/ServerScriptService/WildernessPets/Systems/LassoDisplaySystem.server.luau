local Players = game:GetService("Players")

local VisualService = require(script.Parent.LassoVisualService)

local function removeDisplay(character)
    local existing = character and character:FindFirstChild("EquippedLassoDisplay")
    if existing then
        existing:Destroy()
    end
end

local function mountDisplay(player, character)
    if not character or not character.Parent then return end

    removeDisplay(character)

    -- While the Tool is equipped, its hand-held LassoVisual is the only visible copy.
    -- Otherwise keep a passive rope bundle in the left hand so lassos are never back-mounted.
    if character:FindFirstChild("Lasso") then
        return
    end

    local lassoName = player:GetAttribute("EquippedLassoName")
    if type(lassoName) ~= "string" or lassoName == "" then
        lassoName = "Rough Rope"
    end
    local skinId = player:GetAttribute("EquippedLassoSkin")
    if type(skinId) ~= "string" then
        skinId = ""
    end

    local hand = character:FindFirstChild("LeftHand")
        or character:FindFirstChild("Left Arm")

    if not hand or not hand:IsA("BasePart") then
        hand = character:WaitForChild("LeftHand", 2)
            or character:FindFirstChild("Left Arm")
    end
    if not hand or not hand:IsA("BasePart") then return end

    local gripCFrame = hand.CFrame
    if hand.Name == "Left Arm" then
        gripCFrame = hand.CFrame * CFrame.new(0, -0.86, -0.02)
    else
        gripCFrame = hand.CFrame * CFrame.new(0, -0.025, -0.025)
    end
    gripCFrame *= CFrame.Angles(0, math.rad(-5), math.rad(4))

    local display = VisualService:Mount(
        character,
        hand,
        lassoName,
        skinId,
        "EquippedLassoDisplay",
        gripCFrame
    )
    if display then
        display:SetAttribute("CollectibleDisplay", true)
    end
end

local function bindPlayer(player)
    local function refresh()
        local character = player.Character
        if character then
            task.defer(function()
                mountDisplay(player, character)
            end)
        end
    end

    local function bindCharacter(character)
        character.ChildAdded:Connect(function(child)
            if child:IsA("Tool") and child.Name == "Lasso" then
                refresh()
            end
        end)
        character.ChildRemoved:Connect(function(child)
            if child:IsA("Tool") and child.Name == "Lasso" then
                refresh()
            end
        end)

        task.wait(0.25)
        mountDisplay(player, character)
    end

    player.CharacterAdded:Connect(bindCharacter)

    player:GetAttributeChangedSignal("EquippedLassoName"):Connect(refresh)
    player:GetAttributeChangedSignal("EquippedLassoSkin"):Connect(refresh)

    if player.Character then
        task.spawn(bindCharacter, player.Character)
    end
end

Players.PlayerAdded:Connect(bindPlayer)

for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(bindPlayer, player)
end
