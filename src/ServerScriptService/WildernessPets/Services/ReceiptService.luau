local Players=game:GetService("Players")
local MarketplaceService=game:GetService("MarketplaceService")
local Data=require(script.Parent.PlayerDataService)
local Schema=require(script.Parent.ProfileSchema)
local Products=require(game.ReplicatedStorage.WildernessPets.Shared.ProductDefinitions)
local Service={}
local busy={}
function Service:Process(receipt)
    local pending=Enum.ProductPurchaseDecision.NotProcessedYet
    local player=Players:GetPlayerByUserId(receipt.PlayerId)
    local data=player and Data:Get(player)
    if not data or busy[player] or type(receipt.PurchaseId)~="string" then return pending end
    busy[player]=true
    local ok,result=pcall(function()
        if not require(script.Parent.ReceiptLedger).Apply(data,receipt.PurchaseId,receipt.ProductId,Products[receipt.ProductId]) then
            return pending
        end
        Data:AddCoins(player,0); Data:AddGems(player,0)
        -- Receipt marker and balance are persisted in the same profile write.
        if not Data:Save(player) then return pending end
        return Enum.ProductPurchaseDecision.PurchaseGranted
    end)
    busy[player]=nil
    if not ok then warn("[ReceiptService] Receipt deferred: "..tostring(result)); return pending end
    return result
end
function Service:Init()
    MarketplaceService.ProcessReceipt=function(receipt) return self:Process(receipt) end
end
return Service
