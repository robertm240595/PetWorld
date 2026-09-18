local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Root = ReplicatedStorage:WaitForChild("WildernessPets")
local Remotes = Root:WaitForChild("Remotes")

local PetsRemote = Remotes:WaitForChild("Pets")
local ShopRemote = Remotes:WaitForChild("Shop")
local ArenaRemote = Remotes:WaitForChild("Arena")
local GetState = Remotes:WaitForChild("GetState")
local GameRemote = Remotes:WaitForChild("Game")
local Config = require(Root.Shared.Config)

local DataService = require(script.Parent.Services.PlayerDataService)
local PetService = require(script.Parent.Services.PetService)
local PlotService = require(script.Parent.Services.PlotService)
local ShopService = require(script.Parent.Services.ShopService)
local ArenaService = require(script.Parent.Services.ArenaService)
local CaptureService = require(script.Parent.Services.CaptureService)
local ActionLockService = require(script.Parent.Services.ActionLockService)
local BeastTraderService = require(script.Parent.Services.BeastTraderService)
local MonsterService = require(script.Parent.Services.MonsterService)
MonsterService:Init()
BeastTraderService:Init()
local equipCompanion, unequipCompanion
local plots = workspace.WildernessPets.Plots

for _, plot in ipairs(plots:GetChildren()) do
    if plot:IsA("Folder") then
        PlotService:Register(plot)
    end
end

local function teleportToPlot(player, character)
    task.wait(0.2)

    local plot = PlotService:GetPlayerPlot(player)

    if not plot then
        return
    end

    local spawn = plot:FindFirstChild("Spawn")

    if spawn and character.PrimaryPart then
        character:PivotTo(spawn.CFrame + Vector3.new(0, 4, 0))
    end
end

local function setupPlayer(player)
    DataService:Load(player)
    ActionLockService:Initialize(player)

    player.CharacterAdded:Connect(function(character)
        teleportToPlot(player, character)
    end)

    if player.Character then
        task.spawn(function()
            teleportToPlot(player, player.Character)
        end)
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(setupPlayer, player)
end

Players.PlayerAdded:Connect(setupPlayer)

Players.PlayerRemoving:Connect(function(player)
    PlotService:Release(player)
    DataService:Cleanup(player)
end)

----------------------------------------------------------------
-- STATE
----------------------------------------------------------------

GetState.OnServerInvoke = function(player)
    local data = DataService:Get(player)

    if not data then
        return nil
    end

    return {
        Coins = data.Coins,
        Gems = data.Gems,
        Lasso = data.Lasso,
        Inventory = data.Inventory or {},
        Pets = data.Pets,
        SelectedPlot = data.SelectedPlot,
        DefencePetId = data.DefencePetId,
        EquippedPetId = data.EquippedPetId,
        PodiumPetId = data.PodiumPetId,
        ArenaRating = data.ArenaRating,
        ArenaWins = data.ArenaWins,
        ArenaLosses = data.ArenaLosses
    }
end

-- CaptureService owns the Capture remote, including validation, cooldowns, and outcomes.

----------------------------------------------------------------
-- PETS
----------------------------------------------------------------

PetsRemote.OnServerEvent:Connect(function(player, action, ...)
    local args = {...}

    if action == "Rename" then
        local petId = args[1]
        local name = args[2]

        local success, message = PetService:Rename(player, petId, name)
        local refresh = script.Parent.Systems:FindFirstChild("PetDisplayRefresh")
        if success and refresh then refresh:Fire(player) end

        PetsRemote:FireClient(player, "Updated", success, message)

    elseif action == "Upgrade" then
        local petId = args[1]
        local stat = args[2]

        local success = PetService:Upgrade(player, petId, stat)

        PetsRemote:FireClient(player, "Updated", success)

    elseif action == "Display" or action == "Hide" then
        local success, message = PetService:SetDisplayed(player, args[1], action == "Display")
        local refresh = script.Parent.Systems:FindFirstChild("PetDisplayRefresh")
        if success and action == "Display" and player:GetAttribute("EquippedPetId") == args[1] then unequipCompanion(player) end
        if success and refresh then refresh:Fire(player) end
        PetsRemote:FireClient(player, "Updated", success, message)
    elseif action == "Podium" then
        local success, message = PetService:SetPodium(player, args[1])
        local refresh = script.Parent.Systems:FindFirstChild("PetDisplayRefresh")
        if success and player:GetAttribute("EquippedPetId") == args[1] then unequipCompanion(player) end
        if success and refresh then refresh:Fire(player) end
        PetsRemote:FireClient(player, "Updated", success, message)
    elseif action == "Equip" then
        local success, message = equipCompanion(player, args[1])
        PetsRemote:FireClient(player, "Updated", success, message)
    elseif action == "Unequip" then
        unequipCompanion(player)
        PetsRemote:FireClient(player, "Updated", true)
    end
end)

----------------------------------------------------------------
-- SHOPS
----------------------------------------------------------------

ShopRemote.OnServerEvent:Connect(function(player, action, value)
    if action == "BuyLasso" then
        local success, message = ShopService:BuyLasso(player, value)
        ShopRemote:FireClient(player, "Purchase", success, message)

    elseif action == "EquipLasso" then
        local success, message = ShopService:EquipLasso(player, value)
        ShopRemote:FireClient(player, "LassoEquipped", success, message)

    elseif action == "SellPet" then
        local allowed, gateMessage = BeastTraderService:CanTrade(player)
        if not allowed then
            ShopRemote:FireClient(player, "Sold", false, 0, gateMessage)
            return
        end

        local data = DataService:Get(player)
        if not data then
            ShopRemote:FireClient(player, "Sold", false, 0, "Player data unavailable.")
            return
        end

        if data.EquippedPetId == value then
            unequipCompanion(player, true)
        end

        local amount, message = ShopService:SellPet(player, value)
        local success = type(amount) == "number" and amount > 0

        if success then
            local refresh = script.Parent.Systems:FindFirstChild("PetDisplayRefresh")
            if refresh then refresh:Fire(player) end
        end

        ShopRemote:FireClient(
            player,
            "Sold",
            success,
            success and amount or 0,
            message or (success and "Pet sold." or "Could not sell that pet.")
        )
    end
end)

----------------------------------------------------------------
-- ARENA
----------------------------------------------------------------

ArenaRemote.OnServerEvent:Connect(function(player, action, value)
    if action == "SetDefence" then
        local success = ArenaService:SetDefence(player, value)

        ArenaRemote:FireClient(
            player,
            "DefenceSet",
            success
        )

    elseif action == "GetOpponents" then
        ArenaRemote:FireClient(
            player,
            "Opponents",
            ArenaService:GetPlayers()
        )

    elseif action == "Attack" then
        local targetUserId = tonumber(value)

        if not targetUserId then
            return
        end

        local target = Players:GetPlayerByUserId(targetUserId)

        if not target then
            return
        end

        ActionLockService:Begin(player, "ArenaCombat")
        ActionLockService:Begin(target, "ArenaCombat")

        local ok, result = pcall(function()
            return ArenaService:Attack(player, target)
        end)

        ActionLockService:End(player, "ArenaCombat")
        ActionLockService:End(target, "ArenaCombat")

        if not ok then
            warn("[WildernessPets] Arena attack: " .. tostring(result))
            return
        end

        ArenaRemote:FireClient(
            player,
            "BattleResult",
            result
        )
    end
end)
----------------------------------------------------------------
-- COMPANION COMBAT SYSTEM
-- Uses the existing Game remote so no new networking dependency is required.
----------------------------------------------------------------
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local PetAnimator = require(script.Parent.Systems.PetAnimator)
local combatSessions = setmetatable({}, {__mode="k"})
local rewardGuard = setmetatable({}, {__mode="k"})

local function combatWorld()
    return workspace:FindFirstChild("WildernessPets")
end
local function companionsFolder()
    local world = combatWorld()
    if not world then return nil end
    local folder = world:FindFirstChild("Companions")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "Companions"
        folder.Parent = world
    end
    return folder
end
local function combatTell(player, action, ...)
    GameRemote:FireClient(player, "Combat", action, ...)
end
local function playerRoot(player)
    local character = player.Character
    return character and character:FindFirstChild("HumanoidRootPart")
end
local function monsterFolder()
    local world = combatWorld()
    return world and world:FindFirstChild("WildMonsters")
end
local function monsterPart(monster)
    if typeof(monster) ~= "Instance" or not monster.Parent then return nil end
    if monster:IsA("BasePart") then return monster end
    return monster.PrimaryPart or monster:FindFirstChild("HumanoidRootPart") or monster:FindFirstChildWhichIsA("BasePart", true)
end
local function validMonster(monster)
    local folder = monsterFolder()
    if not folder or typeof(monster) ~= "Instance" or monster.Parent ~= folder or not monster:IsA("Model") then return false end
    if monster:GetAttribute("Dead") or monster:GetAttribute("Captured") or monster:GetAttribute("BeingCaptured") then return false end
    return monsterPart(monster) ~= nil
end
local function petTemplate(pet)
    local templates = game.ServerStorage.WildernessPets.Monsters
    local template = templates:FindFirstChild(pet.Species)
    local info = Config.Pets[pet.Species]
    if not template and info and info.AnimationSpecies then template = templates:FindFirstChild(info.AnimationSpecies) end
    return template, info
end
local function destroyCompanion(session)
    if session and session.companion and session.companion.Parent then session.companion:Destroy() end
end

local function syncCompanionLabel(model, pet)
    if not model or not model.Parent or not model.PrimaryPart or not pet then return end

    local maximumHealth = math.max(1, tonumber(pet.Health) or 1)
    if model:GetAttribute("MaxHealth") ~= maximumHealth then
        model:SetAttribute("MaxHealth", maximumHealth)
    end
    if model:GetAttribute("Health") == nil then
        model:SetAttribute("Health", maximumHealth)
    end
    local currentHealth = math.clamp(tonumber(model:GetAttribute("Health")) or maximumHealth, 0, maximumHealth)

    local gui = model.PrimaryPart:FindFirstChild("CompanionName")
    if not gui then
        gui = Instance.new("BillboardGui")
        gui.Name = "CompanionName"
        gui.Size = UDim2.fromOffset(170, 48)
        gui.MaxDistance = 55
        gui.AlwaysOnTop = false
        gui.StudsOffsetWorldSpace = Vector3.new(0, model:GetExtentsSize().Y * 0.55 + 0.7, 0)
        gui.Parent = model.PrimaryPart

        local label = Instance.new("TextLabel")
        label.Name = "Label"
        label.BackgroundTransparency = 1
        label.Position = UDim2.fromOffset(0, 0)
        label.Size = UDim2.new(1, 0, 0, 24)
        label.Font = Enum.Font.GothamSemibold
        label.TextSize = 14
        label.TextStrokeTransparency = 0.35
        label.TextColor3 = Color3.fromRGB(247, 235, 185)
        label.Parent = gui

        local back = Instance.new("Frame")
        back.Name = "HealthBack"
        back.Position = UDim2.fromOffset(10, 29)
        back.Size = UDim2.fromOffset(150, 10)
        back.BackgroundColor3 = Color3.fromRGB(55, 35, 35)
        back.BorderSizePixel = 0
        back.Parent = gui

        local backCorner = Instance.new("UICorner")
        backCorner.CornerRadius = UDim.new(0, 4)
        backCorner.Parent = back

        local fill = Instance.new("Frame")
        fill.Name = "Fill"
        fill.Size = UDim2.fromScale(1, 1)
        fill.BackgroundColor3 = Color3.fromRGB(86, 188, 105)
        fill.BorderSizePixel = 0
        fill.Parent = back

        local fillCorner = Instance.new("UICorner")
        fillCorner.CornerRadius = UDim.new(0, 4)
        fillCorner.Parent = fill
    end

    local label = gui:FindFirstChild("Label")
    if label and label:IsA("TextLabel") then
        label.Text = tostring(pet.Name or pet.Species) .. "  Lv." .. tostring(pet.Level or 1)
    end

    local back = gui:FindFirstChild("HealthBack")
    local fill = back and back:FindFirstChild("Fill")
    if fill and fill:IsA("Frame") then
        fill.Size = UDim2.fromScale(math.clamp(currentHealth / maximumHealth, 0, 1), 1)
    end
end

local function createCompanion(player, pet)
    local template, info = petTemplate(pet)
    if not template then return nil, "No creature mesh exists for "..tostring(pet.Species) end
    local root = playerRoot(player)
    if not root then return nil, "Character is not ready." end
    local model = template:Clone()
    model.Name = "Companion_"..tostring(player.UserId)
    for _, item in ipairs(model:GetDescendants()) do
        if item:IsA("BillboardGui") then item:Destroy()
        elseif item:IsA("BasePart") then
            item.Anchored = true
            item.CanCollide = false
            item.CanTouch = false
            item.CanQuery = false
        end
    end
    model:SetAttribute("Companion", true)
    model:SetAttribute("OwnerUserId", player.UserId)
    model:SetAttribute("PetId", pet.Id)
    model:SetAttribute("Species", pet.Species)
    model:SetAttribute("AnimationSpecies", (info and info.AnimationSpecies) or pet.Species)
    model:SetAttribute("Health", math.max(1, tonumber(pet.Health) or 1))
    model:SetAttribute("MaxHealth", math.max(1, tonumber(pet.Health) or 1))
    model:SetAttribute("Captured", false)
    model:SetAttribute("InCombat", false)
    model.Parent = companionsFolder()
    local rig = PetAnimator:_getRig(model)
    if not rig then model:Destroy() return nil, "Creature mesh could not be animated." end
    local position = root.Position - root.CFrame.LookVector*4 + root.CFrame.RightVector*3
    rig.base = CFrame.new(position + Vector3.new(0, rig.clearance + .06, 0)) * CFrame.Angles(0, math.atan2(-root.CFrame.LookVector.X, -root.CFrame.LookVector.Z), 0)
    PetAnimator:Stop(model)
    PetAnimator:PlayIdle(model)
    syncCompanionLabel(model, pet)
    return model
end
local function startCompanionFollow(player, session)
    local token = (session.followToken or 0) + 1
    session.followToken = token
    task.spawn(function()
        while combatSessions[player] == session and session.companion and session.companion.Parent and session.followToken == token do
            local companion = session.companion
            syncCompanionLabel(companion, session.pet)
            local root = playerRoot(player)
            if root and not session.attacking then
                local desired = root.Position - root.CFrame.LookVector*4 + root.CFrame.RightVector*3
                local delta = desired - companion:GetPivot().Position
                local flat = Vector3.new(delta.X, 0, delta.Z)
                local distance = flat.Magnitude
                if distance > 70 then
                    local rig = PetAnimator:_getRig(companion)
                    if rig then
                        rig.base = CFrame.new(desired + Vector3.new(0, rig.clearance + .06, 0))
                        PetAnimator:Stop(companion)
                        PetAnimator:PlayIdle(companion)
                    end
                elseif distance > 5 and not session.moveBusy then
                    session.moveBusy = true
                    task.spawn(function()
                        if companion.Parent and combatSessions[player] == session and not session.attacking then
                            pcall(function() PetAnimator:PlayRunTo(companion, desired, math.clamp(distance/13, .25, .9)) end)
                        end
                        session.moveBusy = false
                    end)
                elseif distance <= 5 and not session.moveBusy and companion:GetAttribute("AnimationState") ~= "Idle" then
                    PetAnimator:PlayIdle(companion)
                end
            end
            task.wait(.28)
        end
    end)
end
unequipCompanion = function(player, silent)
    local session = combatSessions[player]
    if session then
        local wasAttacking = session.attacking
        session.attacking = false
        session.attackToken = (session.attackToken or 0) + 1
        local target = session.target
        if target and target.Parent and target:GetAttribute("CombatOwnerUserId") == player.UserId then
            target:SetAttribute("InCombat", false)
            target:SetAttribute("CombatOwnerUserId", nil)
        end
        session.followToken = (session.followToken or 0) + 1
        destroyCompanion(session)
        if wasAttacking then
            ActionLockService:End(player, "CompanionCombat")
        end
    end
    combatSessions[player] = nil
    local data = DataService:Get(player)
    if data then data.EquippedPetId = "" end
    player:SetAttribute("EquippedPetId", "")
    player:SetAttribute("EquippedPetSpecies", "")
    if not silent then combatTell(player, "Unequipped") end
end
equipCompanion = function(player, petId)
    local data = DataService:Get(player)
    local pet = PetService:Find(player, petId)
    if not data or not pet then return false, "Pet not found." end
    unequipCompanion(player, true)
    local model, err = createCompanion(player, pet)
    if not model then return false, err end
    local session = {petId=pet.Id, pet=pet, companion=model, target=nil, attacking=false, moveBusy=false, followToken=0, attackToken=0}
    combatSessions[player] = session
    pet.Displayed = false
    if data.PodiumPetId == pet.Id then data.PodiumPetId = "" end
    data.EquippedPetId = pet.Id
    local refresh = script.Parent.Systems:FindFirstChild("PetDisplayRefresh")
    if refresh then refresh:Fire(player) end
    player:SetAttribute("EquippedPetId", pet.Id)
    player:SetAttribute("EquippedPetSpecies", pet.Species)
    startCompanionFollow(player, session)
    combatTell(player, "Equipped", pet.Name, pet.Species, pet.Id)
    return true
end
local function selectCombatTarget(player, target)
    if target == nil then
        local s = combatSessions[player]
        if s then s.target = nil end
        player:SetAttribute("CombatTarget", "")
        combatTell(player, "ClearTarget")
        return true
    end
    local root = playerRoot(player)
    local targetPart = monsterPart(target)
    if not root or not validMonster(target) or not targetPart then
        combatTell(player, "Error", "That is not a living wild creature.")
        return false
    end
    if (root.Position - targetPart.Position).Magnitude > 160 then
        combatTell(player, "Error", "That creature is too far away.")
        return false
    end
    local owner = target:GetAttribute("CombatOwnerUserId")
    if target:GetAttribute("InCombat") and owner ~= player.UserId then
        combatTell(player, "Error", "That creature is already in a fight.")
        return false
    end
    local session = combatSessions[player]
    if not session then
        session = {target=nil, attacking=false, moveBusy=false, attackToken=0}
        combatSessions[player] = session
    end
    session.target = target
    player:SetAttribute("CombatTarget", target.Name)
    combatTell(player, "Target", target, target:GetAttribute("Species") or target.Name, target:GetAttribute("Rarity") or "Common", target:GetAttribute("Health") or 0, target:GetAttribute("MaxHealth") or 0)
    return true
end
local function lassoTarget(player)
    local session = combatSessions[player] or {}
    local target = session.target
    if not validMonster(target) then combatTell(player, "Error", "Select a living wild creature first.") return false end
    if session.attacking then combatTell(player, "Error", "Your companion is already fighting.") return false end
    local ok, success, message, alreadyNotified = pcall(function() return CaptureService:Capture(player, target) end)
    if not ok then combatTell(player, "Error", "The lasso could not complete the throw.") return false end
    if not success and message and not alreadyNotified then combatTell(player, "Error", message) end
    return success
end
local function makeExperienceOrbs(origin, destination)
    local folder = companionsFolder()
    if not folder then return end
    for i=1,3 do
        local orb = Instance.new("Part")
        orb.Name = "ExperienceOrb"
        orb.Shape = Enum.PartType.Ball
        orb.Size = Vector3.new(.45,.45,.45)
        orb.Material = Enum.Material.Neon
        orb.Color = Color3.fromRGB(121,220,255)
        orb.Anchored = true
        orb.CanCollide = false
        orb.CanTouch = false
        orb.CanQuery = false
        orb.Position = origin + Vector3.new((i-2)*.8, 1.2 + ((i%2)*.45), (i-2)*.45)
        orb.Parent = folder
        if destination then
            TweenService:Create(orb, TweenInfo.new(.65, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position=destination + Vector3.new(0,1.5,0)}):Play()
        end
        Debris:AddItem(orb, 1.1)
    end
end
local function rewardCombatKill(player, session, target)
    if rewardGuard[target] then return end
    rewardGuard[target] = true
    local rarity = target:GetAttribute("Rarity") or "Common"
    local rarityInfo = Config.Rarities[rarity]
    local rank = rarityInfo and rarityInfo.Rank or 1
    local info = Config.Pets[target:GetAttribute("Species") or ""]
    local xp = math.max(20, rank * 30)
    local coins = math.max(3, math.floor(((info and info.SellValue) or 40) * .1))
    local part = monsterPart(target)
    local destination = session.companion and session.companion.PrimaryPart and session.companion.PrimaryPart.Position
    if part then makeExperienceOrbs(part.Position, destination) end
    DataService:AddCoins(player, coins)
    PetService:AddXP(player, session.petId, xp)
    combatTell(player, "Reward", xp, coins, rarity)
    local refresh = script.Parent.Systems:FindFirstChild("PetDisplayRefresh")
    if refresh and refresh:IsA("BindableEvent") then refresh:Fire(player) end
end
local function petBaseDamage(pet)
    local level = math.max(1, tonumber(pet.Level) or 1)
    local power = math.max(1, tonumber(pet.Power) or 1)
    return math.max(1, math.floor(power * (1 + (level-1)*.06)))
end
local function attackTarget(player)
    local session = combatSessions[player]
    if not session or not session.companion or not session.companion.Parent then combatTell(player, "Error", "Equip a pet before giving an attack command.") return false end
    if session.attacking then combatTell(player, "Error", "Your pet is already attacking.") return false end
    local target = session.target
    if not validMonster(target) then combatTell(player, "Error", "Select a living wild creature first.") return false end
    local root = playerRoot(player)
    local targetPart = monsterPart(target)
    if not root or not targetPart then return false end
    if (root.Position - targetPart.Position).Magnitude > 180 then combatTell(player, "Error", "Move closer to that creature first.") return false end
    session.attacking = true
    ActionLockService:Begin(player, "CompanionCombat")
    target:SetAttribute("InCombat", true)
    target:SetAttribute("CombatOwnerUserId", player.UserId)
    local token = (session.attackToken or 0) + 1
    session.attackToken = token
    combatTell(player, "CombatState", "Engaging", target)
    task.spawn(function()
        local ok, err = pcall(function()
            while combatSessions[player] == session and session.attackToken == token and session.attacking and validMonster(target) do
                local companion = session.companion
                if not companion or not companion.Parent then break end
                local current = monsterPart(target)
                if not current then break end
                local delta = Vector3.new(current.Position.X-companion:GetPivot().Position.X, 0, current.Position.Z-companion:GetPivot().Position.Z)
                local distance = delta.Magnitude
                if distance > 7 then
                    local stopAt = current.Position - delta.Unit*4
                    PetAnimator:PlayRunTo(companion, stopAt, math.clamp(distance/9, .45, 2))
                end
                if not validMonster(target) then break end
                current = monsterPart(target)
                local close = (current.Position-companion:GetPivot().Position).Magnitude
                if close <= 9 then
                    PetAnimator:PlayAttack(companion, current.Position, .72, function()
                        if combatSessions[player] == session and session.attacking and validMonster(target) then
                            target:SetAttribute("LastHitUserId", player.UserId)
                            MonsterService:DamageMonster(target, petBaseDamage(session.pet))
                        end
                    end, .9)
                    local health = target:GetAttribute("Health") or 0
                    if health <= 0 or target:GetAttribute("Dead") then
                        rewardCombatKill(player, session, target)
                        break
                    end
                end
                task.wait(.15)
            end
        end)
        if not ok then warn("[WildernessPets] Companion combat: "..tostring(err)) end
        if target and target.Parent and target:GetAttribute("CombatOwnerUserId") == player.UserId then
            target:SetAttribute("InCombat", false)
            target:SetAttribute("CombatOwnerUserId", nil)
        end
        session.attacking = false
        ActionLockService:End(player, "CompanionCombat")
        if combatSessions[player] == session and session.companion and session.companion.Parent then PetAnimator:PlayIdle(session.companion) end
        if combatSessions[player] == session then combatTell(player, "CombatState", "Ready", target) end
    end)
    return true
end
local function abilityTarget(player, slot)
    if slot ~= 1 and slot ~= 2 and slot ~= 3 then return false end
    combatTell(player, "Error", "Ability "..tostring(slot).." is reserved for this pet's unique skill.")
    return false
end
local function recallCompanion(player)
    local session = combatSessions[player]
    if not session or not session.companion or not session.companion.Parent then
        combatTell(player, "Error", "You don't have a companion out.")
        return false
    end
    if not session.attacking then
        combatTell(player, "Error", "Your companion isn't attacking anything.")
        return false
    end
    session.attacking = false
    session.attackToken = (session.attackToken or 0) + 1
    ActionLockService:End(player, "CompanionCombat")
    local target = session.target
    if target and target.Parent and target:GetAttribute("CombatOwnerUserId") == player.UserId then
        target:SetAttribute("InCombat", false)
        target:SetAttribute("CombatOwnerUserId", nil)
    end
    PetAnimator:Stop(session.companion)
    PetAnimator:PlayIdle(session.companion)
    combatTell(player, "CombatState", "Ready", target)
    combatTell(player, "Recalled")
    return true
end

local function getOwnedPlot(player)
    local registered = PlotService:GetPlayerPlot(player)
    if registered then
        return registered
    end

    for _, plot in ipairs(plots:GetChildren()) do
        local owner = tonumber(plot:GetAttribute("OwnerUserId") or plot:GetAttribute("Owner"))
        if owner == player.UserId then
            return plot
        end
    end

    return nil
end

local function returnToPlot(player)
    local allowed, message, remaining = ActionLockService:CanReturnHome(player)
    if not allowed then
        GameRemote:FireClient(player, "HomeTeleport", false, message, remaining)
        return false
    end

    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not character or not humanoid or humanoid.Health <= 0 or not root then
        GameRemote:FireClient(player, "HomeTeleport", false, "Your character is not ready.", 0)
        return false
    end

    local plot = getOwnedPlot(player)
    if not plot then
        GameRemote:FireClient(player, "HomeTeleport", false, "You do not have a plot yet.", 0)
        return false
    end

    local spawn = plot:FindFirstChild("Spawn", true) or plot:FindFirstChild("SpawnLocation", true)
    if not spawn or not spawn:IsA("BasePart") then
        local land = plot:FindFirstChild("Land", true)
        if land and land:IsA("BasePart") then
            spawn = land
        end
    end

    if not spawn or not spawn:IsA("BasePart") then
        GameRemote:FireClient(player, "HomeTeleport", false, "Your plot spawn is unavailable.", 0)
        return false
    end

    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    character:PivotTo(spawn.CFrame + Vector3.new(0, 5, 0))
    GameRemote:FireClient(player, "HomeTeleport", true, "Returned to your plot.", 0)
    return true
end

GameRemote.OnServerEvent:Connect(function(player, action, value)
    if action == "CombatSelect" then
        selectCombatTarget(player, value)
    elseif action == "CombatAction" then
        if value == "Lasso" then lassoTarget(player)
        elseif value == "Attack" then attackTarget(player)
        elseif value == "Recall" then recallCompanion(player)
        elseif value == "Ability1" then abilityTarget(player, 1)
        elseif value == "Ability2" then abilityTarget(player, 2)
        elseif value == "Ability3" then abilityTarget(player, 3)
        end
    elseif action == "ReturnToPlot" then
        returnToPlot(player)
    end
end)
Players.PlayerRemoving:Connect(function(player)
    unequipCompanion(player, true)
end)
