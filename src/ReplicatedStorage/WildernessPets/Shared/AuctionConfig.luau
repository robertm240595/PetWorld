local AuctionConfig = {}

AuctionConfig.FeeRate = 0.01
AuctionConfig.MinPrice = 100
AuctionConfig.MaxPrice = 10000000
AuctionConfig.MaxListingsPerPlayer = 12
AuctionConfig.ListingDurationSeconds = 72 * 60 * 60
AuctionConfig.PageSize = 30

AuctionConfig.TradeableInventoryTypes = {
    Loot = true,
    BossPetToken = true,
    BossMountToken = true,
}

return AuctionConfig
