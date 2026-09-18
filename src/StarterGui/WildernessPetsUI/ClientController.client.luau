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
local showLassoKeeper
local showPetMerchant
local showBarn
local backpackTab = "Pets"
local beastTraderTab = "Sell"
local lassoKeeperTab = "Buy"

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

    local panel=frame(UDim2.fromOffset(820,620),UDim2.new(.5,-410,.5,-310))
    panel.Name="PetBackpack"
    panel.AnchorPoint=Vector2.new(.5,.5)
    panel.Position=UDim2.new(.5,0,.5,0)

    local viewportSize=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280,720)
    local fit=Instance.new("UIScale")
    fit.Scale=math.min(1,(viewportSize.X-30)/820,(viewportSize.Y-40)/620)
    fit.Parent=panel

    local header=text(panel,"BACKPACK",UDim2.fromOffset(22,14),UDim2.fromOffset(430,30))
    header.TextScaled=false
    header.TextSize=22
    header.TextXAlignment=Enum.TextXAlignment.Left

    local close=button(panel,"×",UDim2.fromOffset(762,10),UDim2.fromOffset(38,34))
    close.TextScaled=false
    close.TextSize=24
    close.MouseButton1Click:Connect(function()
        showHUD()
    end)

    local petTab=button(
        panel,
        "🐾  PETS   "..tostring(#pets).."/"..tostring(Config.MaxPets or 60),
        UDim2.fromOffset(22,54),
        UDim2.fromOffset(230,50)
    )
    petTab.TextScaled=false
    petTab.TextSize=14

    local inventoryTab=button(
        panel,
        "🎒  INVENTORY   "..tostring(#inventory).."/"..tostring(Config.MaxInventory or 25),
        UDim2.fromOffset(260,54),
        UDim2.fromOffset(260,50)
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
            "Items  ·  "..tostring(#inventory).."/"..tostring(Config.MaxInventory or 25).." slots  ·  Equip your preferred lasso here",
            UDim2.fromOffset(22,112),
            UDim2.fromOffset(770,24)
        )
        status.TextScaled=false
        status.TextSize=13
        status.TextXAlignment=Enum.TextXAlignment.Left

        local list=Instance.new("ScrollingFrame")
        list.Name="InventoryItems"
        list.Position=UDim2.fromOffset(22,145)
        list.Size=UDim2.fromOffset(776,445)
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
            local empty=text(list,"Your inventory is empty.",UDim2.new(),UDim2.fromOffset(750,55))
            empty.TextScaled=false
            empty.TextSize=16
        else
            for _,item in ipairs(inventory) do
                if type(item)=="table" then
                    local itemType=tostring(item.Type or "Item")
                    local itemName=tostring(item.Name or "Unknown")
                    local quantity=math.max(1,tonumber(item.Quantity) or 1)

                    local row=Instance.new("Frame")
                    row.Size=UDim2.fromOffset(750,72)
                    row.BackgroundColor3=Color3.fromRGB(38,43,52)
                    row.BorderSizePixel=0
                    row.Parent=list
                    local corner=Instance.new("UICorner")
                    corner.CornerRadius=UDim.new(0,8)
                    corner.Parent=row

                    local itemIcon=text(
                        row,
                        itemType=="Lasso" and "◎" or "✦",
                        UDim2.fromOffset(12,12),
                        UDim2.fromOffset(44,44)
                    )
                    itemIcon.TextScaled=false
                    itemIcon.TextSize=26

                    local itemLabel=text(
                        row,
                        itemName.."  ·  "..itemType.."  ·  x"..tostring(quantity),
                        UDim2.fromOffset(66,8),
                        UDim2.fromOffset(455,22)
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
                    elseif itemType=="Potion" then
                        local info=Config.Potions and Config.Potions[itemName]
                        detailText=info and tostring(info.Description or "") or ""
                    end

                    local itemDetail=text(
                        row,
                        detailText,
                        UDim2.fromOffset(66,32),
                        UDim2.fromOffset(490,30)
                    )
                    itemDetail.TextScaled=false
                    itemDetail.TextSize=11
                    itemDetail.TextWrapped=true
                    itemDetail.TextColor3=Color3.fromRGB(190,195,205)
                    itemDetail.TextXAlignment=Enum.TextXAlignment.Left

                    if itemType=="Lasso" and state.Lasso~=itemName then
                        local equip=button(row,"EQUIP",UDim2.fromOffset(602,18),UDim2.fromOffset(130,36))
                        equip.TextScaled=false
                        equip.TextSize=12
                        equip.MouseButton1Click:Connect(function()
                            ShopRemote:FireServer("EquipLasso",itemName)
                        end)
                    elseif itemType=="Potion" then
                        local use=button(row,"USE",UDim2.fromOffset(602,18),UDim2.fromOffset(130,36))
                        use.TextScaled=false
                        use.TextSize=12
                        use.MouseButton1Click:Connect(function()
                            ShopRemote:FireServer("UsePotion",itemName,selectedPetId)
                        end)
                    end
                end
            end
        end

        return
    end

    local roamingCount=0
    for _,pet in ipairs(pets) do
        if pet.Displayed and not pet.Dead then roamingCount+=1 end
    end

    local status=text(
        panel,
        tostring(#pets).."/"..tostring(Config.MaxPets or 60).." pets  ·  Plot: "..roamingCount.."/10  ·  ★ protects pets from selling",
        UDim2.fromOffset(22,112),
        UDim2.fromOffset(770,24)
    )
    status.TextScaled=false
    status.TextSize=13
    status.TextXAlignment=Enum.TextXAlignment.Left

    local list=Instance.new("ScrollingFrame")
    list.Name="CollectedPets"
    list.Position=UDim2.fromOffset(18,145)
    list.Size=UDim2.fromOffset(326,445)
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
    detail.Position=UDim2.fromOffset(362,145)
    detail.Size=UDim2.fromOffset(438,445)
    detail.BackgroundTransparency=1
    detail.Parent=panel

    local function destination(p)
        if p.Dead then return "DEAD" end
        if state.EquippedPetId==p.Id then return "COMPANION" end
        if state.PodiumPetId==p.Id then return "PODIUM" end
        return p.Displayed and "ROAMING" or "COLLECTION"
    end

    local function makeDeadPreview(parent,pet)
        local viewport=Instance.new("ViewportFrame")
        viewport.Name="DeadPetPreview"
        viewport.Position=UDim2.fromOffset(224,128)
        viewport.Size=UDim2.fromOffset(200,150)
        viewport.BackgroundColor3=Color3.fromRGB(31,33,38)
        viewport.BorderSizePixel=0
        viewport.Ambient=Color3.fromRGB(190,190,190)
        viewport.LightColor=Color3.fromRGB(255,240,220)
        viewport.LightDirection=Vector3.new(-1,-1,-1)
        viewport.Parent=parent
        local corner=Instance.new("UICorner")
        corner.CornerRadius=UDim.new(0,10)
        corner.Parent=viewport

        local previews=Root:FindFirstChild("PetPreviews")
        local template=previews and (previews:FindFirstChild(pet.Species) or previews:FindFirstChild((Config.Pets[pet.Species] or {}).AnimationSpecies or ""))
        if not template then return end

        local copy=template:Clone()
        local worldModel=Instance.new("WorldModel")
        worldModel.Parent=viewport
        copy.Parent=worldModel

        local rootPart=copy.PrimaryPart or copy:FindFirstChildWhichIsA("BasePart",true)
        if not rootPart then return end
        copy.PrimaryPart=rootPart

        copy:PivotTo(CFrame.new()*CFrame.Angles(0,0,math.rad(78)))
        local size=copy:GetExtentsSize()
        local camera=Instance.new("Camera")
        camera.FieldOfView=38
        camera.CFrame=CFrame.lookAt(
            Vector3.new(0,math.max(1,size.Y*.25),math.max(6,size.Magnitude*1.15)),
            Vector3.new(0,0,0)
        )
        camera.Parent=viewport
        viewport.CurrentCamera=camera

        task.spawn(function()
            local angle=0
            while viewport.Parent and copy.Parent do
                angle+=0.012
                copy:PivotTo(CFrame.Angles(0,angle,math.rad(78)))
                task.wait(1/30)
            end
        end)
    end

    local function details(pet)
        selectedPetId=pet.Id
        detail:ClearAllChildren()

        local title=text(detail,pet.Name,UDim2.fromOffset(0,0),UDim2.fromOffset(330,30))
        title.TextScaled=false
        title.TextSize=21
        title.TextXAlignment=Enum.TextXAlignment.Left

        local favourite=button(
            detail,
            pet.Favourite and "★ FAVOURITE" or "☆ FAVOURITE",
            UDim2.fromOffset(316,0),
            UDim2.fromOffset(122,30)
        )
        favourite.TextScaled=false
        favourite.TextSize=10
        favourite.BackgroundColor3=pet.Favourite and Color3.fromRGB(110,88,48) or Color3.fromRGB(48,54,62)
        favourite.MouseButton1Click:Connect(function()
            PetsRemote:FireServer("Favourite",pet.Id,not pet.Favourite)
        end)

        local rating=math.ceil((pet.Health*pet.Power*pet.Defence)/1000)
        local currentHealth=math.max(0,tonumber(pet.CurrentHealth) or pet.Health)
        local stats=text(
            detail,
            pet.Species.." · "..pet.Rarity.." · Lv."..pet.Level..
            "\n"..destination(pet).."  ·  Imprint "..tostring(pet.Imprint or 20).."%"..
            "\n\nHealth "..math.floor(currentHealth).."/"..pet.Health.."   Power "..pet.Power.."   Defence "..pet.Defence..
            "\nPower rating "..rating..
            "\nXP "..pet.XP.." / "..(pet.Level*100).."   ·   Upgrade points "..pet.UpgradePoints,
            UDim2.fromOffset(0,36),
            UDim2.fromOffset(438,112)
        )
        stats.TextScaled=false
        stats.TextSize=13
        stats.TextWrapped=true
        stats.TextXAlignment=Enum.TextXAlignment.Left

        if pet.Dead then
            local deadBadge=text(
                detail,
                "DEAD",
                UDim2.fromOffset(0,154),
                UDim2.fromOffset(195,54)
            )
            deadBadge.TextScaled=false
            deadBadge.TextSize=30
            deadBadge.TextColor3=Color3.fromRGB(230,92,82)

            local healReady=tonumber(pet.HealReadyAt) or 0
            local healText
            if healReady>os.time() then
                local remaining=math.max(0,healReady-os.time())
                healText="HEALING AT BARN\n"..tostring(math.ceil(remaining)).." seconds remaining"
            else
                healText="Heal pet at the Barn on your plot.\nHealing time = 30s × level × rarity rank."
            end

            local hint=text(
                detail,
                healText,
                UDim2.fromOffset(0,218),
                UDim2.fromOffset(205,108)
            )
            hint.TextScaled=false
            hint.TextSize=13
            hint.TextWrapped=true
            hint.TextXAlignment=Enum.TextXAlignment.Left
            hint.TextColor3=Color3.fromRGB(210,198,178)

            makeDeadPreview(detail,pet)
            return
        end

        local renameCount=math.max(0,tonumber(pet.RenameCount) or 0)
        local renameCost=renameCount>=1 and math.max(0,tonumber(Config.PetRenameGemCost) or 0) or 0

        local renameBox=Instance.new("TextBox")
        renameBox.Name="RenameBox"
        renameBox.Position=UDim2.fromOffset(0,154)
        renameBox.Size=UDim2.fromOffset(280,36)
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
        local renameButton=button(detail,renameText,UDim2.fromOffset(288,154),UDim2.fromOffset(150,36))
        renameButton.TextScaled=false
        renameButton.TextSize=11
        renameButton.MouseButton1Click:Connect(function()
            PetsRemote:FireServer("Rename",pet.Id,renameBox.Text)
        end)

        local renameHint=text(
            detail,
            renameCost==0 and "This pet still has its one free rename." or ("Further renames cost "..tostring(renameCost).." Gems."),
            UDim2.fromOffset(0,194),
            UDim2.fromOffset(438,21)
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
            local b=button(detail,option[1],UDim2.fromOffset(0,222+(i-1)*45),UDim2.fromOffset(438,37))
            b.Name=option[2]
            b.TextScaled=false
            b.TextSize=13
            b.MouseButton1Click:Connect(function()
                PetsRemote:FireServer(option[2],pet.Id)
            end)
        end

        for i,stat in ipairs({"Health","Power","Defence"}) do
            local b=button(detail,"+ "..stat,UDim2.fromOffset((i-1)*148,370),UDim2.fromOffset(142,36))
            b.TextScaled=false
            b.TextSize=12
            b.MouseButton1Click:Connect(function()
                PetsRemote:FireServer("Upgrade",pet.Id,stat)
            end)
        end
    end

    local chosen
    for _,pet in ipairs(pets) do
        local prefix=pet.Favourite and "★ " or (pet.Dead and "☠ " or "")
        local b=button(
            list,
            prefix..pet.Name.."  ·  Lv."..pet.Level.."\n"..pet.Rarity.."  /  "..destination(pet),
            UDim2.new(),
            UDim2.fromOffset(306,58)
        )
        b.TextScaled=false
        b.TextSize=13
        b.TextWrapped=true
        b.BackgroundColor3=pet.Dead and Color3.fromRGB(62,43,45) or (pet.Favourite and Color3.fromRGB(66,57,43) or Color3.fromRGB(55,70,90))
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
            UDim2.fromOffset(438,130)
        )
        empty.TextScaled=false
        empty.TextSize=16
        empty.TextWrapped=true
    end
end

--------------------------------------------------------------
-- NPC SHOPS
--------------------------------------------------------------

showLassoKeeper = function(tab)
    if tab=="Buy" or tab=="Sell" or tab=="Buyback" then
        lassoKeeperTab=tab
    end

    clear()
    gui:SetAttribute("InventoryOpen",true)
    state=GetState:InvokeServer()
    if not state then return end

    local panel=frame(UDim2.fromOffset(760,590),UDim2.new(.5,-380,.5,-295))
    panel.Name="LassoKeeper"
    panel.AnchorPoint=Vector2.new(.5,.5)
    panel.Position=UDim2.new(.5,0,.5,0)

    local viewport=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280,720)
    local fit=Instance.new("UIScale")
    fit.Scale=math.min(1,(viewport.X-30)/760,(viewport.Y-40)/590)
    fit.Parent=panel

    local title=text(panel,"LASSO KEEPER",UDim2.fromOffset(20,12),UDim2.fromOffset(520,30))
    title.TextScaled=false
    title.TextSize=22
    title.TextXAlignment=Enum.TextXAlignment.Left

    local close=button(panel,"×",UDim2.fromOffset(704,10),UDim2.fromOffset(38,34))
    close.TextScaled=false
    close.TextSize=24
    close.MouseButton1Click:Connect(showHUD)

    for i,tabName in ipairs({"Buy","Sell","Buyback"}) do
        local tabButton=button(
            panel,
            string.upper(tabName),
            UDim2.fromOffset(20+(i-1)*150,52),
            UDim2.fromOffset(140,42)
        )
        tabButton.TextScaled=false
        tabButton.TextSize=12
        tabButton.BackgroundColor3=lassoKeeperTab==tabName and Color3.fromRGB(75,92,117) or Color3.fromRGB(45,51,61)
        tabButton.MouseButton1Click:Connect(function()
            showLassoKeeper(tabName)
        end)
    end

    local hint=text(
        panel,
        lassoKeeperTab=="Buy" and "Stronger lassos make capture timing slower and easier."
            or lassoKeeperTab=="Sell" and "Lassos sell back for their full original purchase value."
            or "Recently sold lassos can be recovered here.",
        UDim2.fromOffset(20,102),
        UDim2.fromOffset(710,30)
    )
    hint.TextScaled=false
    hint.TextSize=12
    hint.TextXAlignment=Enum.TextXAlignment.Left

    local list=Instance.new("ScrollingFrame")
    list.Position=UDim2.fromOffset(20,140)
    list.Size=UDim2.fromOffset(720,425)
    list.BackgroundTransparency=1
    list.BorderSizePixel=0
    list.ScrollBarThickness=5
    list.AutomaticCanvasSize=Enum.AutomaticSize.Y
    list.CanvasSize=UDim2.new()
    list.Parent=panel
    local layout=Instance.new("UIListLayout")
    layout.Padding=UDim.new(0,8)
    layout.Parent=list

    local owned={}
    local ownedLassos={}
    for _,item in ipairs(state.Inventory or {}) do
        if type(item)=="table" and item.Type=="Lasso" then
            owned[item.Name]=true
            table.insert(ownedLassos,item.Name)
        end
    end

    if lassoKeeperTab=="Buy" then
        local names={}
        for name in pairs(Config.Lassos or {}) do table.insert(names,name) end
        table.sort(names,function(a,b)
            return (Config.Lassos[a].Strength or 0)<(Config.Lassos[b].Strength or 0)
        end)

        for _,name in ipairs(names) do
            local info=Config.Lassos[name]
            local row=Instance.new("Frame")
            row.Size=UDim2.fromOffset(700,64)
            row.BackgroundColor3=Color3.fromRGB(38,43,52)
            row.BorderSizePixel=0
            row.Parent=list
            local corner=Instance.new("UICorner")
            corner.CornerRadius=UDim.new(0,8)
            corner.Parent=row

            local label=text(
                row,
                name.."  ·  Strength "..tostring(info.Strength),
                UDim2.fromOffset(14,8),
                UDim2.fromOffset(430,22)
            )
            label.TextScaled=false
            label.TextSize=14
            label.TextXAlignment=Enum.TextXAlignment.Left

            local price=text(
                row,
                tostring(info.Coins or 0).." Coins"..((info.Gems or 0)>0 and ("  ·  "..tostring(info.Gems).." Gems") or ""),
                UDim2.fromOffset(14,34),
                UDim2.fromOffset(430,18)
            )
            price.TextScaled=false
            price.TextSize=11
            price.TextColor3=Color3.fromRGB(190,195,205)
            price.TextXAlignment=Enum.TextXAlignment.Left

            local action
            if owned[name] then
                action=state.Lasso==name and "EQUIPPED" or "EQUIP"
            else
                action="BUY"
            end

            local buy=button(row,action,UDim2.fromOffset(540,14),UDim2.fromOffset(145,36))
            buy.TextScaled=false
            buy.TextSize=12
            if action=="EQUIPPED" then
                buy.Active=false
                buy.BackgroundColor3=Color3.fromRGB(45,50,55)
            else
                buy.MouseButton1Click:Connect(function()
                    if owned[name] then
                        ShopRemote:FireServer("EquipLasso",name)
                    else
                        ShopRemote:FireServer("BuyLasso",name)
                    end
                end)
            end
        end

    elseif lassoKeeperTab=="Sell" then
        if #ownedLassos==0 then
            local empty=text(list,"You do not own any lassos.",UDim2.new(),UDim2.fromOffset(680,55))
            empty.TextScaled=false
            empty.TextSize=15
        end

        table.sort(ownedLassos,function(a,b)
            return ((Config.Lassos[a] or {}).Strength or 0)<((Config.Lassos[b] or {}).Strength or 0)
        end)

        for _,name in ipairs(ownedLassos) do
            local info=Config.Lassos[name] or {}
            local row=Instance.new("Frame")
            row.Size=UDim2.fromOffset(700,64)
            row.BackgroundColor3=Color3.fromRGB(38,43,52)
            row.BorderSizePixel=0
            row.Parent=list
            local corner=Instance.new("UICorner")
            corner.CornerRadius=UDim.new(0,8)
            corner.Parent=row

            local label=text(row,name,UDim2.fromOffset(14,8),UDim2.fromOffset(430,22))
            label.TextScaled=false
            label.TextSize=14
            label.TextXAlignment=Enum.TextXAlignment.Left

            local refund=text(
                row,
                "Refund: "..tostring(info.Coins or 0).." Coins"..((info.Gems or 0)>0 and ("  ·  "..tostring(info.Gems).." Gems") or ""),
                UDim2.fromOffset(14,34),
                UDim2.fromOffset(430,18)
            )
            refund.TextScaled=false
            refund.TextSize=11
            refund.TextColor3=Color3.fromRGB(190,195,205)
            refund.TextXAlignment=Enum.TextXAlignment.Left

            local sell=button(row,"SELL",UDim2.fromOffset(540,14),UDim2.fromOffset(145,36))
            sell.TextScaled=false
            sell.TextSize=12
            sell.MouseButton1Click:Connect(function()
                ShopRemote:FireServer("SellLasso",name)
            end)
        end

    else
        local buybacks=state.LassoBuyback or {}
        if #buybacks==0 then
            local empty=text(list,"No recently sold lassos are available for buyback.",UDim2.new(),UDim2.fromOffset(680,55))
            empty.TextScaled=false
            empty.TextSize=15
        end

        for index,entry in ipairs(buybacks) do
            local row=Instance.new("Frame")
            row.Size=UDim2.fromOffset(700,64)
            row.BackgroundColor3=Color3.fromRGB(38,43,52)
            row.BorderSizePixel=0
            row.Parent=list
            local corner=Instance.new("UICorner")
            corner.CornerRadius=UDim.new(0,8)
            corner.Parent=row

            local label=text(row,tostring(entry.Name),UDim2.fromOffset(14,8),UDim2.fromOffset(430,22))
            label.TextScaled=false
            label.TextSize=14
            label.TextXAlignment=Enum.TextXAlignment.Left

            local price=text(
                row,
                tostring(entry.Coins or 0).." Coins"..((entry.Gems or 0)>0 and ("  ·  "..tostring(entry.Gems).." Gems") or ""),
                UDim2.fromOffset(14,34),
                UDim2.fromOffset(430,18)
            )
            price.TextScaled=false
            price.TextSize=11
            price.TextColor3=Color3.fromRGB(190,195,205)
            price.TextXAlignment=Enum.TextXAlignment.Left

            local buyback=button(row,"BUY BACK",UDim2.fromOffset(540,14),UDim2.fromOffset(145,36))
            buyback.TextScaled=false
            buyback.TextSize=11
            buyback.MouseButton1Click:Connect(function()
                ShopRemote:FireServer("BuybackLasso",index)
            end)
        end
    end
end

showPetMerchant = function()
    clear()
    gui:SetAttribute("InventoryOpen",true)
    state=GetState:InvokeServer()
    if not state then return end

    local panel=frame(UDim2.fromOffset(760,590),UDim2.new(.5,-380,.5,-295))
    panel.Name="PetMerchant"
    panel.AnchorPoint=Vector2.new(.5,.5)
    panel.Position=UDim2.new(.5,0,.5,0)

    local viewport=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280,720)
    local fit=Instance.new("UIScale")
    fit.Scale=math.min(1,(viewport.X-30)/760,(viewport.Y-40)/590)
    fit.Parent=panel

    local title=text(panel,"PET MERCHANT",UDim2.fromOffset(20,12),UDim2.fromOffset(520,30))
    title.TextScaled=false
    title.TextSize=22
    title.TextXAlignment=Enum.TextXAlignment.Left

    local subtitle=text(
        panel,
        "Potions are stored in your backpack inventory. Select a pet in your Pets tab before using pet-targeted potions.",
        UDim2.fromOffset(20,50),
        UDim2.fromOffset(680,42)
    )
    subtitle.TextScaled=false
    subtitle.TextSize=12
    subtitle.TextWrapped=true
    subtitle.TextXAlignment=Enum.TextXAlignment.Left

    local close=button(panel,"×",UDim2.fromOffset(704,10),UDim2.fromOffset(38,34))
    close.TextScaled=false
    close.TextSize=24
    close.MouseButton1Click:Connect(showHUD)

    local list=Instance.new("ScrollingFrame")
    list.Position=UDim2.fromOffset(20,104)
    list.Size=UDim2.fromOffset(720,460)
    list.BackgroundTransparency=1
    list.BorderSizePixel=0
    list.ScrollBarThickness=5
    list.AutomaticCanvasSize=Enum.AutomaticSize.Y
    list.CanvasSize=UDim2.new()
    list.Parent=panel
    local layout=Instance.new("UIListLayout")
    layout.Padding=UDim.new(0,8)
    layout.Parent=list

    local names={}
    for name in pairs(Config.Potions or {}) do table.insert(names,name) end
    table.sort(names,function(a,b)
        local pa=Config.Potions[a]
        local pb=Config.Potions[b]
        if (pa.Coins or 0)==(pb.Coins or 0) then return a<b end
        return (pa.Coins or 0)<(pb.Coins or 0)
    end)

    for _,name in ipairs(names) do
        local info=Config.Potions[name]
        local row=Instance.new("Frame")
        row.Size=UDim2.fromOffset(700,76)
        row.BackgroundColor3=Color3.fromRGB(38,43,52)
        row.BorderSizePixel=0
        row.Parent=list
        local corner=Instance.new("UICorner")
        corner.CornerRadius=UDim.new(0,8)
        corner.Parent=row

        local label=text(row,name,UDim2.fromOffset(14,7),UDim2.fromOffset(470,22))
        label.TextScaled=false
        label.TextSize=14
        label.TextXAlignment=Enum.TextXAlignment.Left

        local description=text(
            row,
            tostring(info.Description or ""),
            UDim2.fromOffset(14,30),
            UDim2.fromOffset(480,35)
        )
        description.TextScaled=false
        description.TextSize=11
        description.TextWrapped=true
        description.TextColor3=Color3.fromRGB(190,195,205)
        description.TextXAlignment=Enum.TextXAlignment.Left

        local buy=button(
            row,
            "BUY\n"..tostring(info.Coins or 0).." COINS",
            UDim2.fromOffset(525,14),
            UDim2.fromOffset(160,46)
        )
        buy.TextScaled=false
        buy.TextSize=11
        buy.MouseButton1Click:Connect(function()
            ShopRemote:FireServer("BuyPotion",name)
        end)
    end
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
