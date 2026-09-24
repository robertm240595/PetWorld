local Schema=require(script.Parent.ProfileSchema)
local Ledger={}
function Ledger.Apply(profile,purchaseId,productId,reward)
    if type(purchaseId)~="string" or #purchaseId==0 or #purchaseId>256
        or not Schema.ValidAmount(productId) or productId<1 then return false end
    local prior=profile.PurchaseReceipts[purchaseId]
    if prior then return type(prior)=="table" and prior.ProductId==productId end
    if type(reward)~="table" then return false end
    local coins,gems=reward.Coins or 0,reward.Gems or 0
    if not Schema.ValidAmount(coins) or not Schema.ValidAmount(gems) or coins+gems<=0
        or not Schema.ValidAmount(profile.Coins) or not Schema.ValidAmount(profile.Gems)
        or profile.Coins>Schema.MaxCurrency-coins or profile.Gems>Schema.MaxCurrency-gems then return false end
    profile.Coins+=coins
    profile.Gems+=gems
    profile.PurchaseReceipts[purchaseId]={ProductId=productId,GrantedAt=os.time()}
    return true
end
return Ledger
