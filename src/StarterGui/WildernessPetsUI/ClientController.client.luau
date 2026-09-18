local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

local Root = ReplicatedStorage:WaitForChild("WildernessPets")
local Remotes = Root:WaitForChild("Remotes")

local GameRemote = Remotes:WaitForChild("Game")
local CaptureRemote = Remotes:WaitForChild("Capture")
local PetsRemote = Remotes:WaitForChild("Pets")
local ShopRemote = Remotes:WaitForChild("Shop")
local ArenaRemote = Remotes:WaitForChild("Arena")
local GetState = Remotes:WaitForChild("GetState")

local state
local petsOpen=false
local selectedPetId
local showPets

local gui = script.Parent

--------------------------------------------------------------
-- UI HELPERS
--------------------------------------------------------------

local function clear()
    petsOpen=false
    gui:SetAttribute("InventoryOpen",false)
    for _, child in ipairs(gui:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextButton") or child:IsA("TextLabel") then
            child:Destroy()
        end
    end
end

local function frame(size, position)
    local f = Instance.new("Frame")
    f.Size = size
    f.Position = position
    f.BackgroundColor3 = Color3.fromRGB(25,25,30)
    f.BackgroundTransparency = 0.08
    f.BorderSizePixel = 0
    f.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0,12)
    corner.Parent = f

    return f
end

local function button(parent, text, position, size)
    local b = Instance.new("TextButton")
    b.Text = text
    b.Size = size or UDim2.fromOffset(170,45)
    b.Position = position or UDim2.new()
    b.BackgroundColor3 = Color3.fromRGB(55,70,90)
    b.TextColor3 = Color3.new(1,1,1)
    b.Font = Enum.Font.GothamBold
    b.TextScaled = true
    b.BorderSizePixel = 0
    b.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0,8)
    corner.Parent = b

    return b
end

local function text(parent, value, position, size)
    local t = Instance.new("TextLabel")
    t.Text = value
    t.Size = size or UDim2.fromOffset(300,40)
    t.Position = position or UDim2.new()
    t.BackgroundTransparency = 1
    t.TextColor3 = Color3.new(1,1,1)
    t.Font = Enum.Font.GothamBold
    t.TextScaled = true
    t.Parent = parent

    return t
end

local function notify(message)
    local n = text(
        gui,
        tostring(message),
        UDim2.new(0.5,-250,0,120),
        UDim2.fromOffset(500,50)
    )

    n.BackgroundColor3 = Color3.fromRGB(20,20,25)
    n.BackgroundTransparency = 0.1

    task.delay(3,function()
        if n then
            n:Destroy()
        end
    end)
end

--------------------------------------------------------------
-- PET UI
--------------------------------------------------------------

showPets = function()
    clear()
    petsOpen=true gui:SetAttribute("InventoryOpen",true)
    state=GetState:InvokeServer()
    if not state then
        petsOpen=false
        gui:SetAttribute("InventoryOpen",false)
        return
    end
    local panel=frame(UDim2.fromOffset(740,500),UDim2.new(.5,-370,.5,-250))
    panel.Name="PetBackpack"
    panel.AnchorPoint=Vector2.new(.5,.5)
    panel.Position=UDim2.new(.5,0,.5,-45)
    local fit=Instance.new("UIScale") fit.Scale=math.min(1,(workspace.CurrentCamera.ViewportSize.X-24)/740,(workspace.CurrentCamera.ViewportSize.Y-190)/500) fit.Parent=panel
    text(panel,"BACKPACK  /  COLLECTED PETS",UDim2.fromOffset(20,12),UDim2.fromOffset(520,32))
    local count=0 for _,pet in ipairs(state.Pets or {}) do if pet.Displayed then count+=1 end end
    local status=text(panel,"Plot: "..count.."/10  ·  Choose where each companion belongs",UDim2.fromOffset(20,46),UDim2.fromOffset(680,24))
    status.TextScaled=false status.TextSize=13
    local list=Instance.new("ScrollingFrame")
    list.Name="CollectedPets" list.Position=UDim2.fromOffset(18,82) list.Size=UDim2.fromOffset(305,392)
    list.BackgroundTransparency=1 list.BorderSizePixel=0 list.ScrollBarThickness=4 list.AutomaticCanvasSize=Enum.AutomaticSize.Y list.CanvasSize=UDim2.new() list.Parent=panel
    local layout=Instance.new("UIListLayout") layout.Padding=UDim.new(0,7) layout.Parent=list
    local detail=Instance.new("Frame") detail.Name="PetDetails" detail.Position=UDim2.fromOffset(342,82) detail.Size=UDim2.fromOffset(378,392)
    detail.BackgroundTransparency=1 detail.Parent=panel
    local function destination(p)
        if state.EquippedPetId==p.Id then return "COMPANION" end
        if state.PodiumPetId==p.Id then return "PODIUM" end
        return p.Displayed and "ROAMING" or "COLLECTION"
    end
    local function details(pet)
        selectedPetId=pet.Id detail:ClearAllChildren()
        text(detail,pet.Name,UDim2.fromOffset(0,0),UDim2.fromOffset(370,30))
        local rating=math.ceil(pet.Health*pet.Power*pet.Defence)
        local stats=text(detail,pet.Species.." · "..pet.Rarity.." · Lv."..pet.Level.."\n"..destination(pet).."\n\nHealth "..pet.Health.."   Power "..pet.Power.."   Defence "..pet.Defence.."\nPower rating "..rating.."\nXP "..pet.XP.." / "..(pet.Level*100).."   ·   Upgrade points "..pet.UpgradePoints,UDim2.fromOffset(0,36),UDim2.fromOffset(370,145))
        stats.TextScaled=false stats.TextSize=14 stats.TextWrapped=true
        local options={
            {state.EquippedPetId==pet.Id and "UNEQUIP" or "EQUIP",state.EquippedPetId==pet.Id and "Unequip" or "Equip"},
            {pet.Displayed and "REMOVE FROM PLOT" or "ROAM IN PLOT",pet.Displayed and "Hide" or "Display"},
            {state.PodiumPetId==pet.Id and "ON PODIUM" or "PLACE ON PODIUM","Podium"}
        }
        for i,option in ipairs(options) do
            local b=button(detail,option[1],UDim2.fromOffset(0,193+(i-1)*45),UDim2.fromOffset(370,38))
            b.Name=option[2]
            b.TextScaled=false b.TextSize=13
            b.MouseButton1Click:Connect(function() PetsRemote:FireServer(option[2],pet.Id) end)
        end
        for i,stat in ipairs({"Health","Power","Defence"}) do
            local b=button(detail,"+ "..stat,UDim2.fromOffset((i-1)*124,338),UDim2.fromOffset(118,36))
            b.TextScaled=false b.TextSize=12
            b.MouseButton1Click:Connect(function() PetsRemote:FireServer("Upgrade",pet.Id,stat) end)
        end
    end
    local chosen
    for _,pet in ipairs(state.Pets or {}) do
        local b=button(list,pet.Name.."  ·  Lv."..pet.Level.."\n"..pet.Rarity.."  /  "..destination(pet),UDim2.new(),UDim2.fromOffset(288,58))
        b.TextScaled=false b.TextSize=13 b.TextWrapped=true
        b.MouseButton1Click:Connect(function() details(pet) end)
        if pet.Id==selectedPetId then chosen=pet end
    end
    chosen=chosen or (state.Pets or {})[1]
    if chosen then details(chosen) else
        local empty=text(detail,"Your collection is empty.\nSelect a wild creature and press 1 to throw your lasso.",UDim2.fromOffset(0,70),UDim2.fromOffset(370,130))
        empty.TextScaled=false empty.TextSize=16 empty.TextWrapped=true
    end
    local close=button(panel,"×",UDim2.fromOffset(684,12),UDim2.fromOffset(36,32))
    close.MouseButton1Click:Connect(function() showHUD() end)
end

--------------------------------------------------------------
-- SHOPS
--------------------------------------------------------------

local function showLassoShop()
    clear()

    local panel = frame(
        UDim2.fromOffset(650,500),
        UDim2.new(0.5,-325,0.5,-250)
    )

    text(
        panel,
        "LASSO SHOP",
        UDim2.fromOffset(20,15),
        UDim2.fromOffset(610,50)
    )

    local Config = require(Root.Shared.Config)

    local i = 0

    for name, info in pairs(Config.Lassos) do
        i += 1

        local b = button(
            panel,
            name ..
            "\nStrength " .. info.Strength ..
            " | " .. info.Coins .. " Coins" ..
            (info.Gems > 0 and (" | " .. info.Gems .. " Gems") or ""),
            UDim2.fromOffset(30,65 + (i-1)*65),
            UDim2.fromOffset(590,55)
        )

        b.MouseButton1Click:Connect(function()
            ShopRemote:FireServer("BuyLasso",name)
        end)
    end

    local close = button(
        panel,
        "CLOSE",
        UDim2.fromOffset(240,445)
    )

    close.MouseButton1Click:Connect(function()
        showHUD()
    end)
end

--------------------------------------------------------------
-- ARENA
--------------------------------------------------------------

local function showArena()
    clear()

    local panel = frame(
        UDim2.fromOffset(700,540),
        UDim2.new(0.5,-350,0.5,-270)
    )

    text(
        panel,
        "VILLAGE ARENA",
        UDim2.fromOffset(20,15),
        UDim2.fromOffset(660,45)
    )

    state = GetState:InvokeServer()

    text(
        panel,
        "Rating: " .. tostring(state.ArenaRating) ..
        "    Wins: " .. tostring(state.ArenaWins) ..
        "    Losses: " .. tostring(state.ArenaLosses),
        UDim2.fromOffset(20,65),
        UDim2.fromOffset(660,35)
    )

    text(
        panel,
        "Select your defensive pet:",
        UDim2.fromOffset(20,110),
        UDim2.fromOffset(660,35)
    )

    for i, pet in ipairs(state.Pets or {}) do
        local b = button(
            panel,
            "DEFEND: " .. pet.Name .. " Lv." .. pet.Level,
            UDim2.fromOffset(25,145 + (i-1)*55),
            UDim2.fromOffset(300,45)
        )

        b.MouseButton1Click:Connect(function()
            ArenaRemote:FireServer("SetDefence",pet.Id)
            notify("Defensive pet selected.")
        end)
    end

    local opponents = button(
        panel,
        "FIND VILLAGES TO CHALLENGE",
        UDim2.fromOffset(350,145),
        UDim2.fromOffset(320,55)
    )

    opponents.MouseButton1Click:Connect(function()
        ArenaRemote:FireServer("GetOpponents")
    end)

    local close = button(
        panel,
        "CLOSE",
        UDim2.fromOffset(265,475)
    )

    close.MouseButton1Click:Connect(function()
        showHUD()
    end)
end

--------------------------------------------------------------
-- HUD
--------------------------------------------------------------

function showHUD()
    clear()

    state = GetState:InvokeServer()

    if not state then return end
    local top=frame(UDim2.fromOffset(210,90),UDim2.new(1,-228,0,45))
    top.Name="PlayerStats"
    local title=text(top,player.DisplayName,UDim2.fromOffset(10,7),UDim2.fromOffset(190,22))
    title.TextScaled=false title.TextSize=14
    local coins=text(top,"Coins  "..tostring(state.Coins).."    Gems  "..tostring(state.Gems),UDim2.fromOffset(10,33),UDim2.fromOffset(190,20))
    coins.TextScaled=false coins.TextSize=12
    local lasso=text(top,state.Lasso,UDim2.fromOffset(10,57),UDim2.fromOffset(190,20))
    lasso.TextScaled=false lasso.TextSize=12
    local menu = frame(
        UDim2.fromOffset(152,193),
        UDim2.new(0,15,0.5,-96)
    )

    local pets = button(
        menu,
        "MY PETS",
        UDim2.fromOffset(20,15)
    )

    pets.Size=UDim2.fromOffset(128,34) pets.Position=UDim2.fromOffset(12,12) pets.TextScaled=false pets.TextSize=13
    pets.MouseButton1Click:Connect(showPets)

    local lassos = button(
        menu,
        "LASSO SHOP",
        UDim2.fromOffset(20,70)
    )

    lassos.Size=UDim2.fromOffset(128,34) lassos.Position=UDim2.fromOffset(12,57) lassos.TextScaled=false lassos.TextSize=13
    lassos.MouseButton1Click:Connect(showLassoShop)

    local arena = button(
        menu,
        "ARENA",
        UDim2.fromOffset(20,125)
    )

    arena.Size=UDim2.fromOffset(128,34) arena.Position=UDim2.fromOffset(12,102) arena.TextScaled=false arena.TextSize=13
    arena.MouseButton1Click:Connect(showArena)

    local refresh = button(
        menu,
        "REFRESH",
        UDim2.fromOffset(20,180)
    )

    refresh.Size=UDim2.fromOffset(128,34) refresh.Position=UDim2.fromOffset(12,147) refresh.TextScaled=false refresh.TextSize=13
    refresh.MouseButton1Click:Connect(showHUD)
end

--------------------------------------------------------------
-- CAPTURE FEEDBACK
--------------------------------------------------------------

CaptureRemote.OnClientEvent:Connect(function(action, value)
    if action == "Captured" or action == "Success" then
        notify(
            "CAPTURED! " ..
            tostring(type(value) == "table" and value.Name or value) ..
            " joined your pets."
        )

    elseif action == "Failed" then
        notify(
            "The monster broke free and is chasing you!"
        )

    elseif action == "Error" then
        notify(tostring(value))
    end
end)

--------------------------------------------------------------
-- ARENA FEEDBACK
--------------------------------------------------------------

ArenaRemote.OnClientEvent:Connect(function(action, value)
    if action == "DefenceSet" then
        if value then
            notify("Village defence updated.")
        else
            notify("Could not set defensive pet.")
        end

    elseif action == "Opponents" then
        local opponents = value or {}

        local panel = frame(
            UDim2.fromOffset(650,500),
            UDim2.new(0.5,-325,0.5,-250)
        )

        text(
            panel,
            "CHOOSE A VILLAGE",
            UDim2.fromOffset(20,15),
            UDim2.fromOffset(610,45)
        )

        local row = 0

        for _, opponent in ipairs(opponents) do
            if opponent.UserId ~= player.UserId then
                local b = button(
                    panel,
                    opponent.Name ..
                    " | Rating " ..
                    tostring(opponent.Rating),
                    UDim2.fromOffset(25,70 + row*55),
                    UDim2.fromOffset(600,45)
                )

                b.MouseButton1Click:Connect(function()
                    ArenaRemote:FireServer(
                        "Attack",
                        opponent.UserId
                    )

                    notify("Battle started!")
                end)

                row += 1
            end
        end
    end
end)

--------------------------------------------------------------
-- START
--------------------------------------------------------------

GameRemote.OnClientEvent:Connect(function(action)
    if action == "GameStarted" then
        showHUD()
    end
end)

local playerGui=player:WaitForChild("PlayerGui")
local bag
local bagConnection
local function bindBagEvent()
    local current=playerGui:FindFirstChild("OpenPetBackpack")
    if not current then
        current=Instance.new("BindableEvent")
        current.Name="OpenPetBackpack"
        current.Parent=playerGui
    end
    if not current:IsA("BindableEvent") then return end
    if bag==current and bagConnection and bagConnection.Connected then return end
    if bagConnection then bagConnection:Disconnect() end
    bag=current
    bagConnection=bag.Event:Connect(function()
        local panelOpen=gui:FindFirstChild("PetBackpack")~=nil
        if petsOpen and panelOpen then showHUD() else showPets() end
    end)
end
bindBagEvent()
playerGui.ChildAdded:Connect(function(child)
    if child.Name=="OpenPetBackpack" and child:IsA("BindableEvent") then
        task.defer(bindBagEvent)
    end
end)
player.CharacterAdded:Connect(function()
    task.defer(function()
        gui.ResetOnSpawn=false
        gui.Enabled=true
        bindBagEvent()
    end)
end)

task.wait(2)

local initialState = GetState:InvokeServer()

if initialState and initialState.SelectedPlot and initialState.SelectedPlot > 0 then
    showHUD()
else
    -- VillageIntroController handles village selection with spectating camera.
    -- Wait for the server to set VillageReady, then build the HUD.
    local conn
    conn = player:GetAttributeChangedSignal("VillageReady"):Connect(function()
        if player:GetAttribute("VillageReady") then
            if conn then
                conn:Disconnect()
                conn = nil
            end
            task.wait(0.5)
            showHUD()
        end
    end)
end
PetsRemote.OnClientEvent:Connect(function(action, success, message)
    if action == "Updated" then
        if success and petsOpen then showPets() end
        notify(success and "Pet updated." or (message or "Could not update this pet."))
    end
end)
