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
local Config = require(Root:WaitForChild("Shared"):WaitForChild("Config"))

local state
local petsOpen=false
local selectedPetId
local showPets
local showBeastTrader
local backpackTab = "Pets"

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

showPets = function(tab)
    if tab == "Pets" or tab == "Inventory" then
        backpackTab = tab
    end

    clear()
    petsOpen=true
    gui:SetAttribute("InventoryOpen",true)

    state=GetState:InvokeServer()
    if not state then
        petsOpen=false
        gui:SetAttribute("InventoryOpen",false)
        return
    end

    local pets=state.Pets or {}
    local inventory=state.Inventory or {}

    local panel=frame(UDim2.fromOffset(780,590),UDim2.new(.5,-390,.5,-295))
    panel.Name="PetBackpack"
    panel.AnchorPoint=Vector2.new(.5,.5)
    panel.Position=UDim2.new(.5,0,.5,-25)

    local viewport=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280,720)
    local fit=Instance.new("UIScale")
    fit.Scale=math.min(1,(viewport.X-24)/780,(viewport.Y-100)/590)
    fit.Parent=panel

    local header=text(panel,"BACKPACK",UDim2.fromOffset(20,12),UDim2.fromOffset(420,30))
    header.TextScaled=false
    header.TextSize=22
    header.TextXAlignment=Enum.TextXAlignment.Left

    local close=button(panel,"×",UDim2.fromOffset(724,10),UDim2.fromOffset(38,34))
    close.TextScaled=false
    close.TextSize=24
    close.MouseButton1Click:Connect(function()
        showHUD()
    end)

    local petTab=button(
        panel,
        "🐾  PETS   "..tostring(#pets).."/"..tostring(Config.MaxPets or 60),
        UDim2.fromOffset(20,50),
        UDim2.fromOffset(220,52)
    )
    petTab.TextScaled=false
    petTab.TextSize=14

    local inventoryTab=button(
        panel,
        "🎒  INVENTORY   "..tostring(#inventory).."/"..tostring(Config.MaxInventory or 25),
        UDim2.fromOffset(248,50),
        UDim2.fromOffset(250,52)
    )
    inventoryTab.TextScaled=false
    inventoryTab.TextSize=14

    petTab.BackgroundColor3=backpackTab=="Pets" and Color3.fromRGB(75,92,117) or Color3.fromRGB(45,51,61)
    inventoryTab.BackgroundColor3=backpackTab=="Inventory" and Color3.fromRGB(75,92,117) or Color3.fromRGB(45,51,61)

    petTab.MouseButton1Click:Connect(function()
        showPets("Pets")
    end)
    inventoryTab.MouseButton1Click:Connect(function()
        showPets("Inventory")
    end)

    if backpackTab=="Inventory" then
        local status=text(
            panel,
            "Carried items  ·  "..tostring(#inventory).."/"..tostring(Config.MaxInventory or 25).." slots",
            UDim2.fromOffset(20,108),
            UDim2.fromOffset(730,24)
        )
        status.TextScaled=false
        status.TextSize=13
        status.TextXAlignment=Enum.TextXAlignment.Left

        local list=Instance.new("ScrollingFrame")
        list.Name="InventoryItems"
        list.Position=UDim2.fromOffset(20,140)
        list.Size=UDim2.fromOffset(740,425)
        list.BackgroundTransparency=1
        list.BorderSizePixel=0
        list.ScrollBarThickness=5
        list.AutomaticCanvasSize=Enum.AutomaticSize.Y
        list.CanvasSize=UDim2.new()
        list.Parent=panel

        local layout=Instance.new("UIListLayout")
        layout.Padding=UDim.new(0,8)
        layout.Parent=list

        if #inventory==0 then
            local empty=text(list,"Your inventory is empty.",UDim2.new(),UDim2.fromOffset(720,55))
            empty.TextScaled=false
            empty.TextSize=16
        else
            for _,item in ipairs(inventory) do
                if type(item)=="table" then
                    local itemType=tostring(item.Type or "Item")
                    local itemName=tostring(item.Name or "Unknown")
                    local quantity=math.max(1,tonumber(item.Quantity) or 1)
                    local row=Instance.new("Frame")
                    row.Size=UDim2.fromOffset(720,64)
                    row.BackgroundColor3=Color3.fromRGB(38,43,52)
                    row.BorderSizePixel=0
                    row.Parent=list
                    local corner=Instance.new("UICorner")
                    corner.CornerRadius=UDim.new(0,8)
                    corner.Parent=row

                    local itemIcon=text(
                        row,
                        itemType=="Lasso" and "◎" or "▣",
                        UDim2.fromOffset(12,9),
                        UDim2.fromOffset(44,44)
                    )
                    itemIcon.TextScaled=false
                    itemIcon.TextSize=26

                    local itemLabel=text(
                        row,
                        itemName.."  ·  "..itemType.."  ·  x"..tostring(quantity),
                        UDim2.fromOffset(66,9),
                        UDim2.fromOffset(430,22)
                    )
                    itemLabel.TextScaled=false
                    itemLabel.TextSize=14
                    itemLabel.TextXAlignment=Enum.TextXAlignment.Left

                    local detailText=""
                    if itemType=="Lasso" then
                        local info=Config.Lassos[itemName]
                        detailText="Strength "..tostring(info and info.Strength or "?")
                        if state.Lasso==itemName then
                            detailText=detailText.."  ·  EQUIPPED"
                        end
                    end

                    local itemDetail=text(
                        row,
                        detailText,
                        UDim2.fromOffset(66,33),
                        UDim2.fromOffset(430,20)
                    )
                    itemDetail.TextScaled=false
                    itemDetail.TextSize=11
                    itemDetail.TextColor3=Color3.fromRGB(190,195,205)
                    itemDetail.TextXAlignment=Enum.TextXAlignment.Left

                    if itemType=="Lasso" and state.Lasso~=itemName then
                        local equip=button(row,"EQUIP",UDim2.fromOffset(570,14),UDim2.fromOffset(130,36))
                        equip.TextScaled=false
                        equip.TextSize=12
                        equip.MouseButton1Click:Connect(function()
                            ShopRemote:FireServer("EquipLasso",itemName)
                        end)
                    end
                end
            end
        end

        return
    end

    local roamingCount=0
    for _,pet in ipairs(pets) do
        if pet.Displayed then roamingCount+=1 end
    end

    local status=text(
        panel,
        tostring(#pets).."/"..tostring(Config.MaxPets or 60).." pets  ·  Plot: "..roamingCount.."/10  ·  First rename free",
        UDim2.fromOffset(20,108),
        UDim2.fromOffset(730,24)
    )
    status.TextScaled=false
    status.TextSize=13
    status.TextXAlignment=Enum.TextXAlignment.Left

    local list=Instance.new("ScrollingFrame")
    list.Name="CollectedPets"
    list.Position=UDim2.fromOffset(18,140)
    list.Size=UDim2.fromOffset(315,425)
    list.BackgroundTransparency=1
    list.BorderSizePixel=0
    list.ScrollBarThickness=4
    list.AutomaticCanvasSize=Enum.AutomaticSize.Y
    list.CanvasSize=UDim2.new()
    list.Parent=panel

    local layout=Instance.new("UIListLayout")
    layout.Padding=UDim.new(0,7)
    layout.Parent=list

    local detail=Instance.new("Frame")
    detail.Name="PetDetails"
    detail.Position=UDim2.fromOffset(352,140)
    detail.Size=UDim2.fromOffset(410,425)
    detail.BackgroundTransparency=1
    detail.Parent=panel

    local function destination(p)
        if state.EquippedPetId==p.Id then return "COMPANION" end
        if state.PodiumPetId==p.Id then return "PODIUM" end
        return p.Displayed and "ROAMING" or "COLLECTION"
    end

    local function details(pet)
        selectedPetId=pet.Id
        detail:ClearAllChildren()

        local title=text(detail,pet.Name,UDim2.fromOffset(0,0),UDim2.fromOffset(402,30))
        title.TextScaled=false
        title.TextSize=21
        title.TextXAlignment=Enum.TextXAlignment.Left

        local rating=math.ceil((pet.Health*pet.Power*pet.Defence)/1000)
        local stats=text(
            detail,
            pet.Species.." · "..pet.Rarity.." · Lv."..pet.Level..
            "\n"..destination(pet)..
            "\n\nHealth "..pet.Health.."   Power "..pet.Power.."   Defence "..pet.Defence..
            "\nPower rating "..rating..
            "\nXP "..pet.XP.." / "..(pet.Level*100).."   ·   Upgrade points "..pet.UpgradePoints,
            UDim2.fromOffset(0,36),
            UDim2.fromOffset(402,120)
        )
        stats.TextScaled=false
        stats.TextSize=13
        stats.TextWrapped=true
        stats.TextXAlignment=Enum.TextXAlignment.Left

        local renameCount=math.max(0,tonumber(pet.RenameCount) or 0)
        local renameCost=renameCount>=1 and math.max(0,tonumber(Config.PetRenameGemCost) or 0) or 0

        local renameBox=Instance.new("TextBox")
        renameBox.Name="RenameBox"
        renameBox.Position=UDim2.fromOffset(0,158)
        renameBox.Size=UDim2.fromOffset(260,36)
        renameBox.BackgroundColor3=Color3.fromRGB(38,43,52)
        renameBox.BorderSizePixel=0
        renameBox.ClearTextOnFocus=false
        renameBox.Font=Enum.Font.GothamMedium
        renameBox.TextSize=14
        renameBox.TextColor3=Color3.new(1,1,1)
        renameBox.PlaceholderColor3=Color3.fromRGB(160,165,175)
        renameBox.PlaceholderText="New name"
        renameBox.Text=""
        renameBox.Parent=detail
        local renameCorner=Instance.new("UICorner")
        renameCorner.CornerRadius=UDim.new(0,7)
        renameCorner.Parent=renameBox

        local renameText=renameCost==0 and "RENAME · FREE" or ("RENAME · "..tostring(renameCost).." GEMS")
        local renameButton=button(detail,renameText,UDim2.fromOffset(268,158),UDim2.fromOffset(134,36))
        renameButton.TextScaled=false
        renameButton.TextSize=11
        renameButton.MouseButton1Click:Connect(function()
            PetsRemote:FireServer("Rename",pet.Id,renameBox.Text)
        end)

        local renameHint=text(
            detail,
            renameCost==0 and "This pet still has its one free rename." or ("Further renames cost "..tostring(renameCost).." Gems."),
            UDim2.fromOffset(0,197),
            UDim2.fromOffset(402,21)
        )
        renameHint.TextScaled=false
        renameHint.TextSize=11
        renameHint.TextColor3=Color3.fromRGB(190,195,205)
        renameHint.TextXAlignment=Enum.TextXAlignment.Left

        local options={
            {state.EquippedPetId==pet.Id and "UNEQUIP" or "EQUIP",state.EquippedPetId==pet.Id and "Unequip" or "Equip"},
            {pet.Displayed and "REMOVE FROM PLOT" or "ROAM IN PLOT",pet.Displayed and "Hide" or "Display"},
            {state.PodiumPetId==pet.Id and "ON PODIUM" or "PLACE ON PODIUM","Podium"}
        }

        for i,option in ipairs(options) do
            local b=button(detail,option[1],UDim2.fromOffset(0,226+(i-1)*45),UDim2.fromOffset(402,37))
            b.Name=option[2]
            b.TextScaled=false
            b.TextSize=13
            b.MouseButton1Click:Connect(function()
                PetsRemote:FireServer(option[2],pet.Id)
            end)
        end

        for i,stat in ipairs({"Health","Power","Defence"}) do
            local b=button(detail,"+ "..stat,UDim2.fromOffset((i-1)*136,372),UDim2.fromOffset(130,36))
            b.TextScaled=false
            b.TextSize=12
            b.MouseButton1Click:Connect(function()
                PetsRemote:FireServer("Upgrade",pet.Id,stat)
            end)
        end
    end

    local chosen
    for _,pet in ipairs(pets) do
        local b=button(
            list,
            pet.Name.."  ·  Lv."..pet.Level.."\n"..pet.Rarity.."  /  "..destination(pet),
            UDim2.new(),
            UDim2.fromOffset(298,58)
        )
        b.TextScaled=false
        b.TextSize=13
        b.TextWrapped=true
        b.MouseButton1Click:Connect(function()
            details(pet)
        end)
        if pet.Id==selectedPetId then chosen=pet end
    end

    chosen=chosen or pets[1]
    if chosen then
        details(chosen)
    else
        local empty=text(
            detail,
            "Your pet collection is empty.\nCapture wild pets to fill it.",
            UDim2.fromOffset(0,70),
            UDim2.fromOffset(402,130)
        )
        empty.TextScaled=false
        empty.TextSize=16
        empty.TextWrapped=true
    end
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
-- BEAST TRADER
--------------------------------------------------------------

showBeastTrader = function()
    clear()
    gui:SetAttribute("InventoryOpen",true)

    state=GetState:InvokeServer()
    if not state then return end

    local panel=frame(UDim2.fromOffset(720,560),UDim2.new(.5,-360,.5,-280))
    panel.Name="BeastTrader"
    panel.AnchorPoint=Vector2.new(.5,.5)
    panel.Position=UDim2.new(.5,0,.5,-20)

    local viewport=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280,720)
    local fit=Instance.new("UIScale")
    fit.Scale=math.min(1,(viewport.X-24)/720,(viewport.Y-100)/560)
    fit.Parent=panel

    local title=text(panel,"BEAST TRADER",UDim2.fromOffset(20,14),UDim2.fromOffset(520,30))
    title.TextScaled=false
    title.TextSize=22
    title.TextXAlignment=Enum.TextXAlignment.Left

    local subtitle=text(
        panel,
        "Sell captured pets for Coins. Beast Trader prices include a bonus. Selling gives NO pet XP.",
        UDim2.fromOffset(20,48),
        UDim2.fromOffset(660,42)
    )
    subtitle.TextScaled=false
    subtitle.TextSize=12
    subtitle.TextWrapped=true
    subtitle.TextXAlignment=Enum.TextXAlignment.Left

    local close=button(panel,"×",UDim2.fromOffset(664,12),UDim2.fromOffset(36,32))
    close.TextScaled=false
    close.TextSize=24
    close.MouseButton1Click:Connect(showHUD)

    local list=Instance.new("ScrollingFrame")
    list.Name="TradePets"
    list.Position=UDim2.fromOffset(20,100)
    list.Size=UDim2.fromOffset(680,430)
    list.BackgroundTransparency=1
    list.BorderSizePixel=0
    list.ScrollBarThickness=5
    list.AutomaticCanvasSize=Enum.AutomaticSize.Y
    list.CanvasSize=UDim2.new()
    list.Parent=panel

    local layout=Instance.new("UIListLayout")
    layout.Padding=UDim.new(0,8)
    layout.Parent=list

    local pets=state.Pets or {}
    if #pets==0 then
        local empty=text(list,"You do not have any captured pets to trade.",UDim2.new(),UDim2.fromOffset(660,60))
        empty.TextScaled=false
        empty.TextSize=15
        return
    end

    for _,pet in ipairs(pets) do
        local info=Config.Pets[pet.Species]
        local rarity=Config.Rarities[pet.Rarity]
        local value=0
        if info and rarity then
            value=math.floor(
                (info.SellValue or 0)
                * (rarity.SellMultiplier or 1)
                * (1 + ((math.max(1,tonumber(pet.Level) or 1)-1)*0.10))
                * (tonumber(Config.BeastTraderSellMultiplier) or 1)
            )
        end

        local row=Instance.new("Frame")
        row.Size=UDim2.fromOffset(660,68)
        row.BackgroundColor3=Color3.fromRGB(38,43,52)
        row.BorderSizePixel=0
        row.Parent=list
        local corner=Instance.new("UICorner")
        corner.CornerRadius=UDim.new(0,8)
        corner.Parent=row

        local name=text(
            row,
            tostring(pet.Name).."  ·  Lv."..tostring(pet.Level),
            UDim2.fromOffset(14,8),
            UDim2.fromOffset(390,23)
        )
        name.TextScaled=false
        name.TextSize=14
        name.TextXAlignment=Enum.TextXAlignment.Left

        local meta=text(
            row,
            tostring(pet.Species).."  ·  "..tostring(pet.Rarity).."  ·  Coins only",
            UDim2.fromOffset(14,34),
            UDim2.fromOffset(390,20)
        )
        meta.TextScaled=false
        meta.TextSize=11
        meta.TextColor3=Color3.fromRGB(190,195,205)
        meta.TextXAlignment=Enum.TextXAlignment.Left

        local sell=button(
            row,
            "SELL  "..tostring(value).." COINS",
            UDim2.fromOffset(432,15),
            UDim2.fromOffset(210,38)
        )
        sell.TextScaled=false
        sell.TextSize=12
        sell.MouseButton1Click:Connect(function()
            sell.Active=false
            sell.Text="SELLING..."
            ShopRemote:FireServer("SellPet",pet.Id)
        end)
    end
end

--------------------------------------------------------------
-- HUD
--------------------------------------------------------------

function showHUD()
    clear()

    state = GetState:InvokeServer()
    if not state then return end

    local top=frame(UDim2.fromOffset(220,68),UDim2.new(1,-238,0,45))
    top.Name="PlayerStats"

    local title=text(top,player.DisplayName,UDim2.fromOffset(10,7),UDim2.fromOffset(200,20))
    title.TextScaled=false
    title.TextSize=14

    local coins=text(
        top,
        "Coins  "..tostring(state.Coins).."    Gems  "..tostring(state.Gems),
        UDim2.fromOffset(10,29),
        UDim2.fromOffset(200,18)
    )
    coins.TextScaled=false
    coins.TextSize=11

    local lasso=text(
        top,
        "Lasso  ·  "..tostring(state.Lasso),
        UDim2.fromOffset(10,47),
        UDim2.fromOffset(200,16)
    )
    lasso.TextScaled=false
    lasso.TextSize=10
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

ShopRemote.OnClientEvent:Connect(function(action, ...)
    local args={...}

    if action=="OpenBeastTrader" then
        showBeastTrader()

    elseif action=="Sold" then
        local success=args[1]==true
        local amount=tonumber(args[2]) or 0
        local message=args[3]

        if success then
            showBeastTrader()
            notify(message or ("Sold pet for "..tostring(amount).." Coins."))
        else
            notify(message or "Could not sell that pet.")
        end

    elseif action=="Purchase" then
        local success=args[1]==true
        local message=args[2]
        notify(message or (success and "Purchase complete." or "Purchase failed."))
        if success and petsOpen then showPets(backpackTab) end

    elseif action=="LassoEquipped" then
        local success=args[1]==true
        local message=args[2]
        notify(message or (success and "Lasso equipped." or "Could not equip lasso."))
        if success and petsOpen then showPets("Inventory") end
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
        notify(message or (success and "Pet updated." or "Could not update this pet."))
    end
end)
