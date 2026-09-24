# Wilderness Pets – Repeatable Smoke Test

Run this after gameplay/UI/data changes. Use a fresh Studio play session unless a step explicitly needs progression. Record PASS/FAIL and the first console error.

## 1. Startup and village
- Start Play; no red errors or infinite-yield warnings.
- Village selector appears; claim Village 1.
- Selector closes; main HUD, CompanionHUD and QuestHUD enable.
- Character spawns on the claimed plot and ownership updates.

## 2. Backpack and shops
- Backpack opens from normal HUD/input, tabs work, closes back to HUD.
- Lasso Keeper: E opens Buy/Sell/Buyback; close returns to HUD.
- Beast Trader, Pet Merchant, Material Trader and Pet Barn each open from their real prompt.
- Buy/sell changes balances/inventory once.

## 3. Quests
- Talk to Rowan after village claim; dialogue opens and buttons fit.
- Accept quest; tracker/compass update.
- Advance one stage; progress increments once; turn-in rewards once.
- SteelTempered, MysticResonance and AncientOath obey lasso/prerequisite gates.

## 4. Combat and capture
- Select living wild creature; target panel appears.
- Companion attack changes target health.
- Lasso out of range gives "Too far away!" and no capture.
- In range, capture starts and owner/state attributes set.
- Complete one capture end-to-end; pet enters backpack once.

## 5. Pets, mastery and mounts
- Equip/unequip pet; companion follows.
- Cross mastery level; aura unlock appears.
- Select aura; cosmetic effect appears without changing stats; No Aura hides it.
- Equip/unequip mount; movement/animation works.
- Dead pet -> Barn -> timer -> collect; Barn upgrade reduces new healing timers.

## 6. Achievements
- Achievement list fits and shows rewards/status.
- Trigger First Capture and pet-level milestone; Gems award exactly once.
- Rejoin/re-open; completed achievements do not reward twice.

## 7. Village development
- Workbench upgrades Healing Barn with Coins.
- Training Area assigns eligible pet and shows its model.
- Base training gives 1 XP per 15 minutes online.
- Training upgrade reduces interval.
- Gem purchase unlocks another training slot.
- Equipped/dead/displayed/podium/defence pets are rejected until freed.

## 8. Global auction and mailbox
- Browse/Sell/My Listings/Mail fit and refresh.
- List tradeable loot; item leaves inventory and listing appears.
- Second server/account sees and buys listing.
- Buyer pays full price; seller mail gets price minus 1%; buyer mail gets item.
- Seller may be offline; proceeds persist to next join.
- Cancel/expiry returns item once.
- Claim mail once; no duplicate reward.

## 9. Player trade
- Nearby players request, offer, accept; changing offer clears acceptance.
- Favourite/equipped/non-tradeable assets rejected.
- Completion transfers once; cancellation cleans up.

## 10. Hollowfang / Wyrm
- Entrance -> transition -> Wyrm arena -> defeat -> reward/quest -> exit return point.
- Death/reset during travel/arena does not strand player.

## 11. Jormungdyrr world boss
- Progress WorldBossTrail and enter cave behind northeast waterfall.
- Multiple players share one boss instance.
- Test attacks/phases, pet damage, death/reset and reconnect behavior.
- Verify solo/participation protection.
- Defeat with 2+ players; contribution records correctly.
- Eligible players receive loot exactly once.
- Ancient pet/mount token rolls stay tradeable and vendor-protected.
- Quest advances to ReportVictory; Rowan completes chain.
- Exit returns players safely.

## 12. UI/visual/text regression
- Desktop plus common phone/tablet simulator sizes.
- Quest dialogue + notices/toasts: no overlap.
- No top-level panel outside safe bounds.
- No visible TextFits failures.
- Check prompts/shops/quests/achievement/mastery/auction/village spelling and encoding.
- Final console has no game-script errors.

## 13. Lasso tiers, casting and skins
- Equip Rough Rope, Hunter's Lasso, Iron Lasso, Steel Lasso, Mystic Lasso and Ancient Lasso one at a time; each shows its own 3D model.
- Cast each tier at a valid wild target; arm cast motion blends without stopping movement.
- Rope travels from the lasso rope-end to the target, settles cleanly, and fades without snapping or clipping.
- Start and complete a capture; existing capture strength/probability behavior is unchanged.
- Lasso Skins tab shows all 12 starter skins, owned/unowned state, rarity, exact drop chance and 3D preview.
- Award/obtain a skin, equip it, unequip it, and verify tier strength remains unchanged.
- Duplicate skin ownership remains boolean and does not award currency or an extra item.
- Verify Common/Rare/Epic/Legendary/Mythic/Ancient configured rates are 5% / 3% / 2% / 1% / 0.1% / 0.01%.
- Rejoin/save validation: owned skins and equipped skin persist in a non-Studio DataStore-enabled session.

## 14. Temporary asset inspection platform
- TEMP_ASSET_INSPECTION_PLATFORM_REMOVE_AFTER_REVIEW exists high above the village.
- Expected creature display count equals the current live ServerStorage creature-template count (including intentionally retained legacy templates).
- Expected NPC display count equals the current live NPC-template count.
- ActualDisplayCount and ActualLabelCount both equal ExpectedTotalDisplays.
- All displayed models are clones, anchored/frozen, generously spaced and have readable labels.
- Spot-check pets, mounts, quest NPCs and service NPCs; source templates remain unchanged.

## Release gate
Sections 1–9 and 12–14 must pass, Hollowfang must pass, and Jormungdyrr must pass or be explicitly BLOCKED with a reproducible reason.
