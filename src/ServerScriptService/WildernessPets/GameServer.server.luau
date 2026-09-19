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
local PetModelFactory = require(script.Parent.Systems.PetModelFactory)

local DataService = require(script.Parent.Services.PlayerDataService)
local PetService = require(script.Parent.Services.PetService)
local MountService = require(script.Parent.Services.MountService)
local PlotService = require(script.Parent.Services.PlotService)
local ShopService = require(script.Parent.Services.ShopService)
local ArenaService = require(script.Parent.Services.ArenaService)
local CaptureService = require(script.Parent.Services.CaptureService)
local ActionLockService = require(script.Parent.Services.ActionLockService)
local BeastTraderService = require(script.Parent.Services.BeastTraderService)
local LassoKeeperService = require(script.Parent.Services.LassoKeeperService)
local PetMerchantService = require(script.Parent.Services.PetMerchantService)
local PotionService = require(script.Parent.Services.PotionService)
local BarnService = require(script.Parent.Services.BarnService)
local MonsterService = require(script.Parent.Services.MonsterService)
local QuestService = require(script.Parent.Services.QuestService)
local BossTravelService = require(script.Parent.Services.BossTravelService)
local LootService = require(script.Parent.Services.LootService)
local WorldBossRewardService = require(script.Parent.Services.WorldBossRewardService)
local TestCommandService = require(script.Parent.Services.TestCommandService)
MonsterService:Init()
MountService:Init()
LootService:Init()
WorldBossRewardService:Init()
QuestService:Init()
BossTravelService:Init()
BeastTraderService:Init()
LassoKeeperService:Init()
PetMerchantService:Init()
BarnService:Init()
local equipCompanion, unequipCompanion
local syncCompanionLabel
local combatSessions
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
    local data = DataService:Load(player)
    player:SetAttribute("EquippedLassoName", data and data.Lasso or "Rough Rope")
    PetService:RefreshHealing(player)
    ActionLockService:Initialize(player)
    QuestService:PlayerReady(player)
    TestCommandService:BindPlayer(player)

    player.CharacterAdded:Connect(function(character)
        teleportToPlot(player, character)
        task.defer(function()
            MountService:Restore(player)
            PotionService:ApplyCharacterEffects(player)
        end)
    end)

    if player.Character then
        task.spawn(function()
            teleportToPlot(player, player.Character)
            MountService:Restore(player)
            PotionService:ApplyCharacterEffects(player)
        end)
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(setupPlayer, player)
end

Players.PlayerAdded:Connect(setupPlayer)

Players.PlayerRemoving:Connect(function(player)
    TestCommandService:PlayerRemoving(player)
    MountService:PlayerRemoving(player)
    LootService:PlayerRemoving(player)
    WorldBossRewardService:PlayerRemoving(player)
    BossTravelService:PlayerRemoving(player)
    QuestService:PlayerRemoving(player)
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

    PetService:RefreshHealing(player)

    return {
        Coins = data.Coins,
        Gems = data.Gems,
        Lasso = data.Lasso,
        Inventory = data.Inventory or {},
        InventoryCapacity = math.max(tonumber(Config.MaxInventory) or 25, tonumber(data.InventoryCapacity) or tonumber(Config.MaxInventory) or 25),
        BackpackName = data.BackpackName or "Starter Bag",
        Pets = PetService:GetPets(player),
        Mounts = MountService:GetMounts(player),
        MountCollection = data.MountCollection or {},
        EquippedMountId = data.EquippedMountId or "",
        PetBuyback = data.PetBuyback or {},
        LassoBuyback = data.LassoBuyback or {},
        ActiveEffects = data.ActiveEffects or {},
        PetCollection = data.PetCollection or {},
        CollectionRewardsClaimed = data.CollectionRewardsClaimed or {},
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
        if success then
            QuestService:OnPlayerAction(player, "RenamePet", {PetId = petId})
        end

        PetsRemote:FireClient(player, "Updated", success, message)

    elseif action == "Upgrade" then
        local petId = args[1]
        local stat = args[2]

        local success = PetService:Upgrade(player, petId, stat)
        if success then
            QuestService:OnPlayerAction(player, "UpgradePet", {PetId = petId})
        end

        PetsRemote:FireClient(player, "Updated", success)

    elseif action == "Favourite" then
        local success, message = PetService:SetFavourite(player, args[1], args[2] == true)
        PetsRemote:FireClient(player, "Updated", success, message)

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
        local petId = args[1]
        local success, message = equipCompanion(player, petId)
        if success then
            QuestService:OnPlayerAction(player, "EquipPet", {PetId = petId})
        end
        PetsRemote:FireClient(player, "Updated", success, message)
    elseif action == "Unequip" then
        unequipCompanion(player)
        PetsRemote:FireClient(player, "Updated", true)

    elseif action == "EquipMount" then
        local mountId = args[1]
        local success, message = MountService:Equip(player, mountId)
        if success then
            QuestService:OnPlayerAction(player, "EquipMount", {MountId = mountId})
        end
        PetsRemote:FireClient(player, "MountUpdated", success, message)

    elseif action == "UnequipMount" then
        local success, message = MountService:Unequip(player)
        PetsRemote:FireClient(player, "MountUpdated", success, message)

    elseif action == "ClaimCollectionReward" then
        local data = DataService:Get(player)
        if not data then
            PetsRemote:FireClient(player, "CollectionReward", false, "Player data unavailable.")
            return
        end

        data.PetCollection = type(data.PetCollection) == "table" and data.PetCollection or {}
        data.CollectionRewardsClaimed = type(data.CollectionRewardsClaimed) == "table" and data.CollectionRewardsClaimed or {}

        local collected = 0
        for species, discovered in pairs(data.PetCollection) do
            local info = discovered == true and Config.Pets[species] or nil
            if info and info.Legacy ~= true and info.SpawnMode ~= "Legacy" then
                collected += 1
            end
        end

        local milestone
        for _, reward in ipairs(Config.CollectionMilestones or {}) do
            local key = tostring(math.max(0, math.floor(tonumber(reward.Required) or 0)))
            if not data.CollectionRewardsClaimed[key] then
                milestone = reward
                break
            end
        end

        if not milestone then
            PetsRemote:FireClient(player, "CollectionReward", false, "All collection rewards have already been claimed.")
            return
        end

        local required = math.max(0, math.floor(tonumber(milestone.Required) or 0))
        if collected < required then
            PetsRemote:FireClient(
                player,
                "CollectionReward",
                false,
                "Discover " .. tostring(required - collected) .. " more pet species to unlock this reward."
            )
            return
        end

        local key = tostring(required)
        local coins = math.max(0, math.floor(tonumber(milestone.Coins) or 0))
        local gems = math.max(0, math.floor(tonumber(milestone.Gems) or 0))

        -- Grant currency before marking the milestone claimed so a failed grant
        -- can never consume the reward.
        local coinBalance = tonumber(data.Coins) or 0
        local gemBalance = tonumber(data.Gems) or 0
        if coins > 0 then
            coinBalance = DataService:AddCoins(player, coins)
            if coinBalance == nil then
                PetsRemote:FireClient(player, "CollectionReward", false, "Could not grant the Coin reward. Please try again.")
                return
            end
        end
        if gems > 0 then
            gemBalance = DataService:AddGems(player, gems)
            if gemBalance == nil then
                if coins > 0 then
                    data.Coins = math.max(0, (tonumber(data.Coins) or 0) - coins)
                end
                PetsRemote:FireClient(player, "CollectionReward", false, "Could not grant the Gem reward. Please try again.")
                return
            end
        end

        data.CollectionRewardsClaimed[key] = true

        local parts = {}
        if coins > 0 then table.insert(parts, tostring(coins) .. " Coins") end
        if gems > 0 then table.insert(parts, tostring(gems) .. " Gems") end
        local rewardText = #parts > 0 and table.concat(parts, " + ") or "reward"

        PetsRemote:FireClient(
            player,
            "CollectionReward",
            true,
            "Collection milestone " .. tostring(required) .. " claimed: " .. rewardText .. ".",
            coinBalance,
            gemBalance
        )
    end
end)

----------------------------------------------------------------
-- SHOPS
----------------------------------------------------------------

ShopRemote.OnServerEvent:Connect(function(player, action, ...)
    local args = {...}
    local value = args[1]

    if action == "BuyLasso" then
        local allowed, gateMessage = LassoKeeperService:CanTrade(player)
        if not allowed then
            ShopRemote:FireClient(player, "LassoShopResult", false, gateMessage)
            return
        end
        local success, message = ShopService:BuyLasso(player, value)
        if success then QuestService:PushState(player) end
        ShopRemote:FireClient(player, "LassoShopResult", success, message)

    elseif action == "SellLasso" then
        local allowed, gateMessage = LassoKeeperService:CanTrade(player)
        if not allowed then
            ShopRemote:FireClient(player, "LassoShopResult", false, gateMessage)
            return
        end
        local success, message = ShopService:SellLasso(player, value)
        ShopRemote:FireClient(player, "LassoShopResult", success, message)

    elseif action == "BuybackLasso" then
        local allowed, gateMessage = LassoKeeperService:CanTrade(player)
        if not allowed then
            ShopRemote:FireClient(player, "LassoShopResult", false, gateMessage)
            return
        end
        local success, message = ShopService:BuybackLasso(player, value)
        ShopRemote:FireClient(player, "LassoShopResult", success, message)

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

        local session = combatSessions and combatSessions[player]
        local wasEquipped = (data.EquippedPetId == value)
            or (session and session.petId == value)

        local amount, message = ShopService:SellPet(player, value)
        local success = type(amount) == "number" and amount > 0

        if success then
            if wasEquipped then
                unequipCompanion(player, true)
            end
            local refresh = script.Parent.Systems:FindFirstChild("PetDisplayRefresh")
            if refresh then refresh:Fire(player) end
            QuestService:OnPlayerAction(player, "SellPet")
        end

        ShopRemote:FireClient(player, "Sold", success, success and amount or 0, message)

    elseif action == "BuybackPet" then
        local allowed, gateMessage = BeastTraderService:CanTrade(player)
        if not allowed then
            ShopRemote:FireClient(player, "PetBuybackResult", false, gateMessage)
            return
        end

        local success, message = ShopService:BuybackPet(player, value)
        local refresh = script.Parent.Systems:FindFirstChild("PetDisplayRefresh")
        if success then
            if refresh then refresh:Fire(player) end
            QuestService:OnPlayerAction(player, "BuybackPet")
        end
        ShopRemote:FireClient(player, "PetBuybackResult", success, message)

    elseif action == "BuyBackpack" then
        local allowed, gateMessage = QuestService:CanLeatherTrade(player)
        if not allowed then
            ShopRemote:FireClient(player, "BackpackResult", false, gateMessage)
            return
        end

        local success, message = ShopService:BuyBackpack(player, value)
        ShopRemote:FireClient(
            player,
            "BackpackResult",
            success,
            message,
            ShopService:GetInventoryCapacity(player)
        )

    elseif action == "BuyPotion" then
        local allowed, gateMessage = PetMerchantService:CanTrade(player)
        if not allowed then
            ShopRemote:FireClient(player, "PotionResult", false, gateMessage)
            return
        end

        local success, message = PotionService:BuyPotion(player, value)
        ShopRemote:FireClient(player, "PotionResult", success, message)

    elseif action == "UsePotion" then
        local potionName = value
        local requestedPetId = args[2]
        local potion = Config.Potions and Config.Potions[potionName]
        if not potion then
            ShopRemote:FireClient(player, "PotionResult", false, "Potion unavailable.")
            return
        end

        local data = DataService:Get(player)
        if not data then
            ShopRemote:FireClient(player, "PotionResult", false, "Player data unavailable.")
            return
        end

        local session = combatSessions and combatSessions[player]
        local context = {
            InCombat = session and session.attacking == true or false,
            BarnAllowed = false
        }

        if potion.Type == "BattleHeal" then
            requestedPetId = data.EquippedPetId
        elseif potion.Type == "InstantRevive" then
            local allowed, message = BarnService:CanUse(player)
            context.BarnAllowed = allowed
            if not allowed then
                ShopRemote:FireClient(player, "PotionResult", false, message)
                return
            end
        end

        local success, message = PotionService:UsePotion(player, potionName, requestedPetId, context)

        if success then
            local activeSession = combatSessions and combatSessions[player]
            if activeSession and activeSession.pet then
                local refreshed = PetService:Find(player, activeSession.petId)
                if refreshed then activeSession.pet = refreshed end
                if activeSession.companion and activeSession.companion.Parent and refreshed then
                    syncCompanionLabel(activeSession.companion, refreshed)
                end
            end
            local refresh = script.Parent.Systems:FindFirstChild("PetDisplayRefresh")
            if refresh then refresh:Fire(player) end
            BarnService:RefreshVisuals(player)
        end

        ShopRemote:FireClient(player, "PotionResult", success, message)

    elseif action == "StartHealing" then
        local allowed, gateMessage = BarnService:CanUse(player)
        if not allowed then
            ShopRemote:FireClient(player, "BarnResult", false, gateMessage)
            return
        end

        local tutorialHealingSeconds = QuestService:GetTutorialHealingSeconds(player, value)
        local success, message, seconds = PetService:StartHealing(player, value, tutorialHealingSeconds)
        if success then
            BarnService:RefreshVisuals(player)
            QuestService:OnPlayerAction(player, "StartHealing", {PetId = value})
            task.delay(math.max(1, tonumber(seconds) or 1), function()
                if player and player.Parent then
                    BarnService:RefreshVisuals(player)
                end
            end)
        end
        ShopRemote:FireClient(player, "BarnResult", success, message, seconds or 0)

    elseif action == "CollectHealed" then
        local allowed, gateMessage = BarnService:CanUse(player)
        if not allowed then
            ShopRemote:FireClient(player, "BarnResult", false, gateMessage)
            return
        end

        local success, message = PetService:CollectHealed(player, value)
        if success then
            BarnService:RefreshVisuals(player)
            local refresh = script.Parent.Systems:FindFirstChild("PetDisplayRefresh")
            if refresh then refresh:Fire(player) end
            QuestService:OnPlayerAction(player, "CollectHealed", {PetId = value})
        end
        ShopRemote:FireClient(player, "BarnResult", success, message, 0)
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
combatSessions = setmetatable({}, {__mode="k"})
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
local function validSelectableCreature(monster)
    local folder = monsterFolder()
    if not folder or typeof(monster) ~= "Instance" or monster.Parent ~= folder or not monster:IsA("Model") then return false end
    if monster:GetAttribute("Dead") or monster:GetAttribute("Captured") or monster:GetAttribute("BeingCaptured") then return false end
    return monsterPart(monster) ~= nil
end

local function validMonster(monster)
    if not validSelectableCreature(monster) then return false end
    if monster:GetAttribute("CreatureType") == "Mount" or monster:GetAttribute("QuestNoCombat") then return false end
    return true
end
local function petModel(pet)
    local info = Config.Pets[pet.Species]
    return PetModelFactory:Create(pet.Species), info
end
local function destroyCompanion(session)
    if session and session.companion and session.companion.Parent then session.companion:Destroy() end
end

syncCompanionLabel = function(model, pet)
    if not model or not model.Parent or not model.PrimaryPart or not pet then return end

    local stats = PetService:GetEffectiveStats(pet)
    local maximumHealth = math.max(1, tonumber(stats.Health) or 1)
    local currentHealth = math.clamp(tonumber(pet.CurrentHealth) or maximumHealth, 0, maximumHealth)
    pet.CurrentHealth = currentHealth

    if model:GetAttribute("MaxHealth") ~= maximumHealth then
        model:SetAttribute("MaxHealth", maximumHealth)
    end
    if model:GetAttribute("Health") ~= currentHealth then
        model:SetAttribute("Health", currentHealth)
    end

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
    local model, info = petModel(pet)
    if not model then return nil, "No creature model exists for "..tostring(pet.Species) end
    local root = playerRoot(player)
    if not root then
        model:Destroy()
        return nil, "Character is not ready."
    end
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
    local effectiveStats = PetService:GetEffectiveStats(pet)
    model:SetAttribute("Health", math.clamp(tonumber(pet.CurrentHealth) or effectiveStats.Health, 0, effectiveStats.Health))
    model:SetAttribute("MaxHealth", effectiveStats.Health)
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
local function getPetSpeedMultiplier(player)
    local data = DataService:Get(player)
    local active = data and data.ActiveEffects
    if type(active) == "table" and (tonumber(active.SpeedBoostUntil) or 0) > os.time() then
        return math.max(1, tonumber(active.PetSpeedMultiplier) or 1)
    end
    return 1
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
                            local speedMultiplier = getPetSpeedMultiplier(player)
                            pcall(function() PetAnimator:PlayRunTo(companion, desired, math.clamp(distance/(13*speedMultiplier), .18, .9)) end)
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
        if target
            and target.Parent
            and target:GetAttribute("WorldBoss") ~= true
            and target:GetAttribute("CombatOwnerUserId") == player.UserId then
            target:SetAttribute("InCombat", false)
            target:SetAttribute("CombatOwnerUserId", nil)
            if not target:GetAttribute("Dead") and not target:GetAttribute("Captured") then
                pcall(function() PetAnimator:PlayIdle(target) end)
            end
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
    PetService:RefreshHealing(player)
    local pet = PetService:Find(player, petId)
    if not data or not pet then return false, "Pet not found." end
    if pet.Dead then
        local readyAt = tonumber(pet.HealReadyAt) or 0
        if readyAt > 0 and readyAt <= os.time() then
            return false, "That pet is healed and waiting at your Barn. Collect it first."
        elseif readyAt > os.time() then
            return false, "That pet is still healing at your Barn."
        end
        return false, "That pet is dead. Heal it at your Barn first."
    end
    if (tonumber(pet.CurrentHealth) or pet.Health) <= 0 then return false, "That pet needs healing." end
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
    if not root or not validSelectableCreature(target) or not targetPart then
        combatTell(player, "Error", "That is not a living wild creature.")
        return false
    end
    if not QuestService:IsQuestMonsterAllowed(player, target) then
        combatTell(player, "Error", "That quest creature belongs to another player's objective.")
        return false
    end
    if (root.Position - targetPart.Position).Magnitude > 160 then
        combatTell(player, "Error", "That creature is too far away.")
        return false
    end
    local owner = target:GetAttribute("CombatOwnerUserId")
    local sharedBoss = target:GetAttribute("WorldBoss") == true
    if not sharedBoss and target:GetAttribute("InCombat") and owner ~= player.UserId then
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
    if not validSelectableCreature(target) then combatTell(player, "Error", "Select a living wild creature first.") return false end
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

    if target:GetAttribute("WorldBoss") == true then
        WorldBossRewardService:ResolveBossDeath(target)
        combatTell(player, "Reward", 0, "World Boss")
        return
    end

    local questAction = target:GetAttribute("QuestActionOnDefeat")
    if type(questAction) == "string" and questAction ~= "" then
        QuestService:OnPlayerAction(player, questAction, {
            Target = target,
            BossId = target:GetAttribute("BossId"),
            Species = target:GetAttribute("Species"),
        })
    end

    if target:GetAttribute("QuestNoRewards") then
        combatTell(player, "Reward", 0, target:GetAttribute("Rarity") or "Quest")
        return
    end

    local rarity = target:GetAttribute("Rarity") or "Common"
    local rarityInfo = Config.Rarities[rarity]
    local rank = rarityInfo and rarityInfo.Rank or 1
    local info = Config.Pets[target:GetAttribute("Species") or ""]
    local baseXP = math.max(20, rank * 30)
    local sellValue = math.floor(
        ((info and info.SellValue) or 35)
        * ((rarityInfo and rarityInfo.SellMultiplier) or 1)
        * (tonumber(Config.BeastTraderSellMultiplier) or 1)
    )
    local baseCoins = math.max(
        1,
        math.floor(sellValue * (tonumber(Config.WildKillCoinRatio) or 0.15))
    )
    local part = monsterPart(target)
    local destination = session.companion and session.companion.PrimaryPart and session.companion.PrimaryPart.Position

    if part then makeExperienceOrbs(part.Position, destination) end

    -- XP is immediate. Coins and species materials are claimed from the
    -- player-owned loot bag that appears at the defeated creature.
    local _, _, awardedXP = PetService:AddXP(player, session.petId, baseXP)
    awardedXP = awardedXP or baseXP
    LootService:SpawnBag(player, target, baseCoins)

    QuestService:OnMonsterKilled(player, target, session.petId)
    combatTell(player, "Reward", awardedXP, rarity)

    local refresh = script.Parent.Systems:FindFirstChild("PetDisplayRefresh")
    if refresh and refresh:IsA("BindableEvent") then refresh:Fire(player) end
end

local function petBaseDamage(pet)
    local level = math.max(1, tonumber(pet.Level) or 1)
    local stats = PetService:GetEffectiveStats(pet)
    local power = math.max(1, tonumber(stats.Power) or 1)
    return math.max(1, math.floor(power * (1 + (level-1)*.06)))
end

local function wildPetDamage(target, pet)
    local power = math.max(1, tonumber(target:GetAttribute("Power")) or 1)
    local stats = PetService:GetEffectiveStats(pet)
    local defence = math.max(0, tonumber(stats.Defence) or 0)
    local scale = tonumber((Config.Combat or {}).WildDamageDefenceScale) or 0.45
    return math.max(1, math.floor(power - defence * scale))
end

local function defeatCompanion(player, session, target)
    if not session or session.petDefeated then return end

    session.petDefeated = true
    session.attacking = false
    session.attackToken = (session.attackToken or 0) + 1

    local pet = session.pet
    local companion = session.companion

    local tutorialDefeat = false
    if pet then
        pet.CurrentHealth = 0
        PetService:MarkDead(player, session.petId)
        tutorialDefeat = QuestService:OnCompanionDefeated(player, target, session.petId) == true
    end

    if companion and companion.Parent then
        companion:SetAttribute("Health", 0)
        pcall(function()
            PetAnimator:PlayFaint(companion, 0.7)
        end)
    end

    if target and target.Parent and target:GetAttribute("CombatOwnerUserId") == player.UserId then
        target:SetAttribute("InCombat", false)
        target:SetAttribute("CombatOwnerUserId", nil)
        pcall(function()
            PetAnimator:PlayIdle(target)
        end)
    end

    local data = DataService:Get(player)
    if data then data.EquippedPetId = "" end

    player:SetAttribute("EquippedPetId", "")
    player:SetAttribute("EquippedPetSpecies", "")
    player:SetAttribute("CombatTarget", "")

    combatTell(player, "PetDefeated", pet and pet.Name or "Your pet")
    combatTell(player, "ClearTarget")

    local refresh = script.Parent.Systems:FindFirstChild("PetDisplayRefresh")
    if refresh and refresh:IsA("BindableEvent") then refresh:Fire(player) end

    ActionLockService:End(player, "CompanionCombat")
    if tutorialDefeat then
        ActionLockService:AllowReturnHomeNow(player)
    end

    task.delay(0.75, function()
        if companion and companion.Parent then companion:Destroy() end
        if combatSessions[player] == session then
            combatSessions[player] = nil
        end
    end)
end

local function attackTarget(player)
    local session = combatSessions[player]
    if not session or not session.companion or not session.companion.Parent then
        combatTell(player, "Error", "Equip a pet before giving an attack command.")
        return false
    end
    if session.attacking then
        combatTell(player, "Error", "Your pet is already attacking.")
        return false
    end

    local pet = PetService:Find(player, session.petId)
    if not pet or pet.Dead or (tonumber(pet.CurrentHealth) or 0) <= 0 then
        combatTell(player, "Error", "That pet must be healed before it can fight.")
        return false
    end
    session.pet = pet

    local target = session.target
    if target and target:GetAttribute("CreatureType") == "Mount" then
        combatTell(player, "Error", "Rideable mounts cannot be fought. Use your lasso if you want to capture it.")
        return false
    end
    if not validMonster(target) then
        combatTell(player, "Error", "Select a living wild creature first.")
        return false
    end
    if not QuestService:IsQuestMonsterAllowed(player, target) then
        combatTell(player, "Error", "That quest creature belongs to another player's objective.")
        return false
    end

    local root = playerRoot(player)
    local targetPart = monsterPart(target)
    if not root or not targetPart then return false end

    if (root.Position - targetPart.Position).Magnitude > (tonumber(Config.AttackCommandRange) or 50) then
        combatTell(player, "Error", "Move a little closer before commanding your pet to attack.")
        return false
    end

    session.attacking = true
    session.petDefeated = false
    ActionLockService:Begin(player, "CompanionCombat")

    if target:GetAttribute("WorldBoss") ~= true then
        target:SetAttribute("InCombat", true)
        target:SetAttribute("CombatOwnerUserId", player.UserId)
    end

    local token = (session.attackToken or 0) + 1
    session.attackToken = token
    combatTell(player, "CombatState", "Engaging", target)

    task.spawn(function()
        local ok, err = pcall(function()
            while combatSessions[player] == session
                and session.attackToken == token
                and session.attacking
                and not session.petDefeated
                and validMonster(target) do

                local companion = session.companion
                if not companion or not companion.Parent then break end

                local current = monsterPart(target)
                if not current then break end

                local delta = Vector3.new(
                    current.Position.X - companion:GetPivot().Position.X,
                    0,
                    current.Position.Z - companion:GetPivot().Position.Z
                )
                local distance = delta.Magnitude

                if distance > 7 then
                    local stopAt = current.Position - delta.Unit * 4
                    local speedMultiplier = getPetSpeedMultiplier(player)
                    PetAnimator:PlayRunTo(
                        companion,
                        stopAt,
                        math.clamp(distance / (9 * speedMultiplier), .30, 2)
                    )
                end

                if not validMonster(target) or session.petDefeated then break end

                current = monsterPart(target)
                if not current then break end

                local close = (current.Position - companion:GetPivot().Position).Magnitude
                if close <= 9 then
                    PetAnimator:PlayAttack(companion, current.Position, .72, function()
                        if combatSessions[player] == session
                            and session.attacking
                            and not session.petDefeated
                            and validMonster(target) then
                            target:SetAttribute("LastHitUserId", player.UserId)
                            local damage = petBaseDamage(session.pet)
                            if target:GetAttribute("WorldBoss") == true then
                                local before = math.max(0, tonumber(target:GetAttribute("Health")) or 0)
                                WorldBossRewardService:RecordDamage(target, player, math.min(before, damage))
                            end
                            MonsterService:DamageMonster(target, damage)
                        end
                    end, .9)

                    local health = target:GetAttribute("Health") or 0
                    if health <= 0 or target:GetAttribute("Dead") then
                        rewardCombatKill(player, session, target)
                        break
                    end

                    if session.attacking
                        and not session.petDefeated
                        and validMonster(target)
                        and companion.Parent
                        and companion.PrimaryPart then

                        PetAnimator:PlayAttack(target, companion.PrimaryPart.Position, .72, function()
                            if combatSessions[player] ~= session
                                or not session.attacking
                                or session.petDefeated
                                or not companion.Parent then
                                return
                            end

                            local damage = wildPetDamage(target, session.pet)
                            session.pet.CurrentHealth = math.max(
                                0,
                                (tonumber(session.pet.CurrentHealth) or session.pet.Health) - damage
                            )
                            companion:SetAttribute("Health", session.pet.CurrentHealth)
                            syncCompanionLabel(companion, session.pet)

                            task.spawn(function()
                                if companion.Parent then
                                    pcall(function() PetAnimator:PlayHit(companion, .22) end)
                                end
                            end)
                        end, .9)

                        if (tonumber(session.pet.CurrentHealth) or 0) <= 0 then
                            defeatCompanion(player, session, target)
                            return
                        end
                    end
                end

                local interval = tonumber((Config.Combat or {}).WildAttackInterval) or 1.05
                task.wait(math.max(.08, interval - .72))
            end
        end)

        if not ok then
            warn("[WildernessPets] Companion combat: "..tostring(err))
        end

        if session.petDefeated then
            return
        end

        if target and target.Parent and target:GetAttribute("CombatOwnerUserId") == player.UserId then
            target:SetAttribute("InCombat", false)
            target:SetAttribute("CombatOwnerUserId", nil)
            if not target:GetAttribute("Dead") and not target:GetAttribute("Captured") then
                pcall(function() PetAnimator:PlayIdle(target) end)
            end
        end

        if combatSessions[player] == session then
            session.attacking = false
            ActionLockService:End(player, "CompanionCombat")
            if session.companion and session.companion.Parent then
                PetAnimator:PlayIdle(session.companion)
                syncCompanionLabel(session.companion, session.pet)
            end
            combatTell(player, "CombatState", "Ready", target)
        end
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
    if target
        and target.Parent
        and target:GetAttribute("WorldBoss") ~= true
        and target:GetAttribute("CombatOwnerUserId") == player.UserId then
        target:SetAttribute("InCombat", false)
        target:SetAttribute("CombatOwnerUserId", nil)
        if not target:GetAttribute("Dead") and not target:GetAttribute("Captured") then
            pcall(function() PetAnimator:PlayIdle(target) end)
        end
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
    player:SetAttribute("BossArena", "")
    QuestService:PushState(player)
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
