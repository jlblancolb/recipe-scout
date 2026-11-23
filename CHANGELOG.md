# Changelog

## 0.2.0 (2026-11-23)

- Alts: each character's recipes are remembered when their profession window opens. Recipes another character knows are yellow, with that character's name next to the price and in the panel.
- Recipe tooltips (merchant, bags, auction house) list who knows it, who can learn it now, and who has the profession but too little skill.
- `/rs alts`, `/rs forget <name>`, `/rs debug`.
- Colour key in the panel: green for you, yellow for an alt.
- Enchanting formulas use gear slot names: boot enchants show as Feet, bracer as Wrist, gloves as Hands, cloak as Back, 2H weapon as Two-Hand.
- Filter buttons fit their text ("Permanent", "2H Weapon" were clipped).

## 0.1.1 (2026-11-23)

- First CurseForge release. Same features as 0.1.0, now packaged automatically from GitHub tags.

## 0.1.0 (2026-11-23)

- First version, for WoW Forever.
- Slot badge on every recipe a merchant sells: the slot of the crafted item (`Feet`, `Chest`, `Off Hand`…), its type for non-gear (`Reagent Bag`), and the enchanted slot for enchanting formulas.
- Known recipes get a green check and a green row.
- Side panel next to recipe merchants: slot buttons with counts, name search, Hide known, every match across all pages; click a row to jump to its page.
- `/rs` lists every recipe on the open merchant.
