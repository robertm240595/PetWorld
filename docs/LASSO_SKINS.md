# Lasso Skins

Lasso skins are cosmetic-only overlays. They never modify lasso Strength, capture difficulty, minigame width/speed, range, cooldown, or any other capture statistic.

## Wild-pet drop model

Each eligible normal wild-pet defeat performs one server-side rarity roll, with at most one skin selected. The configured per-defeat chances are:

- Common: 5%
- Rare: 3%
- Epic: 2%
- Legendary: 1%
- Mythic: 0.1%
- Ancient: 0.01%

The roll is evaluated rarest-first using non-overlapping probability bands, so the marginal chance for each rarity remains exactly the configured rate. World bosses and quest targets flagged to suppress normal rewards do not roll lasso skins.

Within the selected rarity, one skin is chosen uniformly from that rarity's data-driven pool in `LassoSkinConfig.luau`.

## Duplicate policy

Ownership is a boolean collection flag. Once a skin is owned, duplicate rolls:

- do not create a stack,
- do not reroll,
- do not convert into Coins, Gems, or other value.

This is intentionally the least exploitable policy. It prevents duplicate farming from becoming a currency source and prevents rerolls from increasing the effective chance of obtaining a new high-rarity skin.

## Starter collection

There are 12 starter skins, two per rarity:

- Common: Meadow Twine, Ember Stitch
- Rare: Frostbite Cord, Verdant Rune
- Epic: Arcane Pulse, Crimson Comet
- Legendary: Solar Flare, Storm Crown
- Mythic: Void Bloom, Celestial Tide
- Ancient: Worldroot Gold, Firstlight Relic

All styling is applied through `LassoVisuals.luau`, independently of `Config.Lassos` strength values.

