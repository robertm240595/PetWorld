# PetWorldOL Project Handoff

## Verified environment — 2026-09-21
- Project root: `D:\Roblox games`
- Main place: `D:\Roblox games\PetWorldOL.rbxl`
- Rojo project: `D:\Roblox games\default.project.json`
- Git remote: `https://github.com/robertm240595/PetWorld.git`
- Roblox Studio was verified open on `PetWorldOL.rbxl`.
- Rojo was verified serving `default.project.json` on localhost port `34872`.
- A pre-lasso `rojo build` completed successfully.
- Rojo source currently contains 62 creature/mount mesh templates and 16 NPC mesh templates.
- Local `Backups/` is intentionally ignored by Git.

## Current implemented state
All current pet/mount meshes are Rojo-backed. All current NPCs have custom mesh models. The 16 NPC mesh templates are under `ServerStorage.WildernessPets.NPCs`.

Four service NPC mesh assets added most recently:
- LassoKeeper — asset `103279073788639`
- PetMerchant — asset `114382979100425`
- ArenaMaster — asset `81071142704498`
- BeastTrader — asset `83912990904462`

Their mechanics were deliberately left unchanged; only visuals were replaced. Lasso Keeper, Pet Merchant, Beast Trader prompts and quest NPC prompts were runtime-checked after the NPC mesh pass.

Related files:
- NPC asset manifest: `generated_npc_assets_20260920.json`
- Creature/mount asset manifest: `generated_mesh_assets_20260920.json`
- Latest post-NPC local backup: `Backups\PetWorldOL_after_all_npc_meshes_20260921_184158.rbxl`
- Repeatable QA checklist: `docs\SMOKE_TEST_CHECKLIST.md`

Existing Phase 1+ systems include:
- end-tier Steel/Mystic/Ancient lasso quests
- achievements with Gem rewards
- pet mastery with cosmetic auras
- global auction house/mailbox system
- village healing upgrades
- passive pet training area with upgradeable speed and Gem-purchased slots
- GUI regression fixes
- obsolete `BossTravelServer` removed

## Execution preference
Work source-first through GitHub/Rojo where possible. Use Desktop Commander/Roblox Studio only when live inspection, mesh generation, playtesting, or saving the place is actually needed. Do not recreate systems that already exist.

## Next task — full lasso / skins / inspection-platform brief

1. **Create custom 3D models for every lasso tier in the game.**
   - Inspect the existing lasso config first and identify every lasso name/tier.
   - Design each lasso visually to match its name and progression tier.
   - Keep the silhouettes readable and increasingly premium as tiers increase.
   - Make sure each lasso has a clear handle/spool/rope-end structure suitable for animation.
   - Make the models durable in the Rojo source after creation.

2. **Make lasso usage look polished.**
   - The rope/lasso should extend cleanly toward the capture target without ugly stretching, snapping, or clipping.
   - Add a smooth player lasso-throw/cast animation.
   - The animation should blend naturally and not break movement, mounts, capture logic, or existing combat.
   - Preserve all existing capture mechanics and probabilities unless a bug requires fixing.

3. **Introduce collectible lasso skins.**
   - Skins are cosmetic only and must not change lasso strength or capture stats.
   - Wild pets can drop lasso skins using these rarity drop rates:
     - Common: **5%**
     - Rare: **3%**
     - Epic: **2%**
     - Legendary: **1%**
     - Mythic: **0.1%**
     - Ancient: **0.01%**
   - Make the drop system data-driven rather than hard-coded into lots of separate creature scripts.
   - Prevent duplicate-award/exploit issues.
   - Decide whether duplicate skins should stack, convert to something, or simply remain owned once; use the least exploitable design and document the choice.
   - Create a sensible starter set of skins across those rarities, visually distinct from the base lasso tiers.

4. **Add a Lasso Skins GUI.**
   - Add it as a **separate tab inside the existing Pet Collection GUI**.
   - Show owned/unowned skins, rarity, preview/name, and currently equipped skin.
   - Players must be able to equip and unequip skins.
   - Keep the UI consistent with the existing fantasy theme.
   - Ensure it works at desktop and mobile/tablet sizes without overlap or clipping.

5. **Create a temporary inspection platform above the village.**
   - Make a large temporary platform high above the village.
   - Display **every creature mesh and every NPC mesh** in a clean line/grid with generous spacing.
   - Put a readable name label above every model.
   - Include pets, mounts, quest NPCs, and service NPCs.
   - Anchor/freeze the models so they don’t wander or animate away.
   - Do not alter the original live templates; use clones.
   - Clearly name the temporary platform/model so it can be removed later after approval/rejection.

6. **Validation requirements.**
   - Do not break lasso capture mechanics, quests, vendors, combat, mounts, trading, or NPC prompts.
   - Run a targeted playtest after implementation:
     - equip each lasso tier
     - cast lasso
     - rope extension
     - animation
     - start and complete a capture
     - skin drop test
     - skin GUI equip/unequip
     - rejoin/save persistence
     - GUI overlap/text-fit scan
     - console error scan
   - Also verify the temporary inspection platform contains the expected total number of creature/NPC displays and readable labels.

7. **Source control / cleanup.**
   - Keep all final source/models in the Rojo project.
   - Do not leave unnecessary temporary probe/build/export files.
   - Keep the temporary inspection platform in the place until review.
   - Before finishing, create one dated backup.
   - Report exactly what was changed, what was tested, and anything still unverified.

Inspect the current repository/project state before modifying anything, then continue this task from there. Do not recreate systems that already exist.
