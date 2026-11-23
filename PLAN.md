# RecipeScout plan

Goal: when a merchant sells recipes (patterns, plans, formulas, schematics, recipes, manuals), show at a glance what each one makes (slot: Feet, Chest, Back…) and whether you already know it, and let you filter all pages at once. Prompted by Merchant's Favor vendors on WoW Forever (e.g. Jim'bek, 7 pages of patterns). Built for Forever first (Mainline UI, interface `16001`, client 1.60.1) and loading on Classic Era too (`11509`), same as YardsToKm and DistanceToTarget.

Status: probe run on Jim'bek 2026-11-23; MVP checked in-game 2026-11-23 (Jim'bek, enchanting vendor). Filter panel checked in-game 2026-11-23. 0.1.0 released on GitHub 2026-11-23. Next: CurseForge project (maintainer), then alts or appearances.

## 0. Decisions

- [x] **Standalone addon:** its own addon, not part of Mastercraft or Polestar (those belong to others). It should run alongside them without conflicts (2026-11-23)
- [x] **Scope:** every recipe type, not only tailoring patterns (2026-11-23)
- [x] **Name:** "RecipeScout"; no addon with that name on CurseForge, closest are Recipe Radar / Recipe Tracker (2026-11-23)
- [ ] **Merchants only, or bags/AH too:** start with merchants; decide later if badges should also show in bags and the auction house
- [x] **Similar addons checked (2026-11-23):** none shows the crafted item's slot on recipes in the merchant window. Build only that gap and work alongside the others; don't hide items or re-layout pages, so Known Item Filter's hide mode keeps working
  - FavorCraft (Forever, 626 downloads, MIT, beta): own `/fc` window with a built-in database of 309 Favor recipes, class/build filter, Favor purchase planner, shopping list; syncs learned recipes per character. Not in the merchant window, no slot filter
  - Known Item Filter (Forever 1.60.1, 334 downloads, All Rights Reserved): hides or dims known recipes at any vendor, closes the gaps. No slot info
  - Vendor Filter (Retail/MoP only, 33k downloads, GPLv3): filter bar in the vendor window, gear by slot, recipes by profession only, fades known. Not listed for Forever

Colours (proposed, confirm after the MVP):
green = this character knows it · yellow = an alt knows it, or the appearance is already collected · normal = learnable now · red = can't learn (wrong profession or skill too low)

## 1. Probe (do first)

The hard part is finding which item a recipe makes, and its slot, without a big data table. Check on Forever what the client gives addons.

- [x] **Probe addon:** `probe/RSProbe`, `/rsp` with a merchant open saves every item's link, merchant info, cost, item class, teach spell, tooltip lines (via `C_TooltipInfo.GetMerchantItem` or a hidden tooltip), name-based lookup of the crafted item, and transmog API answers to `RSProbeDB`. Syntax checked with fengari (2026-11-23)
- [x] **Run on Forever:** Jim'bek, 68 items, Tailoring character; saved as `probe/data/2026-11-23-rsprobe.lua` (2026-11-23)
- [x] **Read the results (2026-11-23):**
  `C_TooltipInfo.GetMerchantItem(i)` works. Every recipe (67/67) has a nested line (type 19) with `tooltipID` = crafted item ID, and `data.hyperlink` is the crafted item link. `C_Item.GetItemInfoInstant(craftedID)` gives `INVTYPE_*` with no cache wait; the crafted item's slot line is type 21 (`Feet`/`Cloth`).
  Known: a type 43 line `leftText = ITEM_SPELL_KNOWN` ("Already known"), `requirementType = 14`, `usable = false` (3 items). Known recipes still have `isUsable = true`.
  Can't learn yet (skill too low, reputation): `C_MerchantFrame.GetItemInfo(i).isUsable = false`; Blizzard already shows these red, so no red of our own.
  Appearance: plain text line "You haven't collected this appearance" (64 items, absent on one known item). My `PlayerHasTransmog(link)` call was wrong (needs an itemID); retest with the crafted ID in phase 4.
  Non-gear: reagent bags (crafted subtype "Reagent Bag"), "Tailoring Certification" (Miscellaneous, not a recipe). No secret values; `GetMerchantItemInfo` is gone (use `C_MerchantFrame.GetItemInfo`). 10 items per page.
- [x] **Pick the lookup:** tooltip data, no database (2026-11-23)
- [x] **Enchanting check:** works; "Enchant Weapon - …" formulas show `Weapon` from the name, wands/staves/relics show their slot (2026-11-23, screenshot)
- [ ] **Classic Era:** no `C_TooltipInfo` there, so the addon does nothing yet; decide later if it's worth a fallback

## 2. MVP

- [x] **Release skeleton:** TOC `## Interface: 16001` only (Classic Era lacks `C_TooltipInfo`), icon 134939, `.pkgmeta`, `.luacheckrc`, `scripts/test.sh` (+ luacheck), `scripts/package.py`, CI workflow, README, CHANGELOG, CONTRIBUTING (2026-11-23)
- [x] **Core:** `Recipe.lua` (parse tooltip data, label) + `RecipeScout.lua` (overlay, hooks, `/rs` lists every recipe on the merchant); `tests/recipe.lua` with probe-shaped data, passes on fengari; `scripts/install.sh` copies to the Forever AddOns folder; installed (2026-11-23)
- [x] **Slot badge:** short slot label on each merchant button (`FEET`, `CHEST`, `BACK`…), localized slot name from the crafted item (`Feet`, `Hands`), subtype for non-gear (`Reagent Bag`, `Potion`); crafted ID cached per recipe (2026-11-23)
- [x] **Known colours:** green check on the icon, green badge, soft green wash over the row; red left to Blizzard (2026-11-23)
- [x] **Known ≠ green name:** uncommon recipes already have green names (enchanting vendor screenshot), so names keep their quality colour and "known" is the check + row wash (2026-11-23)
- [x] **Short slot names:** "Held In Off-hand" overflowed the icon; now `Off Hand` (`SECONDARYHANDSLOT`), also main hand and robe → chest (2026-11-23)
- [x] **No taint:** hook with `hooksecurefunc` after the merchant updates, no changes to Blizzard functions; no errors seen alongside Mastercraft/Polestar (2026-11-23)
- [x] **In-game check on Forever:** badges readable, known recipe marked, no errors seen (2026-11-23, maintainer screenshots)

## 3. Filter across pages

- [x] **Side panel (`Panel.lua`):** to the right of the merchant, only when it sells recipes; search box, "Hide known" (saved), slot buttons with counts built from what this merchant sells, list of every match across all pages with icon, check, slot, red when not learnable; hover shows the item tooltip; click jumps to its page and makes its icon glow for 2.5 s; close button + "Recipes" tab to reopen (saved); hidden on buyback. Tests cover filters, hide known, jump, buyback (2026-11-23)
- [ ] **Buy from the panel:** maybe later; jumping to the page is enough for now
- [x] **In-game check on Forever:** 67 recipes, slot buttons with counts, Feet filter (12), Hide known (64 of 67), red for not-yet-learnable, row tooltip includes Mastercraft/Polestar lines, buyback hides the panel (2026-11-23, maintainer screenshots)
- [ ] **Polish:** the scroll bar looks small and plain next to the list; try Mainline's `ScrollFrameTemplate`/`MinimalScrollBar`

## 4. Alts and appearances

- [ ] **Alt recipes:** save each character's known recipes when their profession window opens (SavedVariables); yellow when an alt knows it, names in the tooltip
- [ ] **Appearance collected:** use the transmog API if the probe shows it answers
- [ ] **Settings panel and addon compartment:** same pattern as DistanceToTarget

## 5. Release

- [x] **GitHub:** public repo https://github.com/jlblancolb/recipe-scout; CI green (luacheck 0 warnings, tests on Lua 5.1) (2026-11-23)
- [x] **Release 0.1.0:** [v0.1.0](https://github.com/jlblancolb/recipe-scout/releases/tag/v0.1.0), `RecipeScout-0.1.0.zip` attached by CI and checked (7 files) (2026-11-23)
- [ ] **CurseForge project:** create "RecipeScout", game version 1.60.1 (Forever), MIT, description from README, upload `RecipeScout-0.1.0.zip` by hand (maintainer)
- [ ] **CurseForge auto-upload:** Source = GitHub repo, tagged commits only; GitHub push webhook to `curseforge.com/api/projects/<id>/package` with the same API token as YardsToKm/DistanceToTarget. Then: bump TOC version, tag `vX.Y.Z`, push the tag. Don't re-push `v0.1.0`
- [x] **Logo and description:** `media/icon.svg` → `icon-512.png`, `icon-400.png`: option B "slot badge" (pattern icon with a FEET strip + green check, navy/gold like DistanceToTarget), picked from 5 candidates in `media/variants/` (2026-11-23), `media/curseforge-description.md` (2026-11-23)
- [ ] **Screenshots for CurseForge:** maintainer's 2026-11-23 shots (panel + Feet filter + enchanting badges) are good candidates
