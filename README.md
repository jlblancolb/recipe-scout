# RecipeScout

Shows what every recipe on a merchant makes (Feet, Chest, Hands, Off Hand, Reagent Bag…) and marks the ones you already know, with a side panel to filter all pages at once. Built for WoW Forever, where the Merchant's Favor vendors sell dozens of patterns, plans, formulas and schematics across several pages.

## What you see

- **Slot badge on every recipe icon:** the slot of the item it makes (`Feet`, `Waist`, `Two-Hand`, `Relic`…), or its type for things you don't wear (`Reagent Bag`). Enchanting formulas show what they enchant (`Weapon`, `Bracer`).
- **Known recipes:** a green check on the icon and a soft green wash over the row. Names keep their usual quality colour.
- **Recipes you can't learn yet** (skill too low, reputation) stay red, as the game already shows them.
- **Side panel** next to the merchant, only when it sells recipes:
  - slot buttons with counts (`Feet (12)`, `Hands (11)`…), built from what this merchant sells
  - a name search and a **Hide known** option (remembered)
  - every matching recipe from all pages; hover for the full tooltip, click to jump to its page (its icon glows briefly)
  - close it with the X; the **Recipes** button on the merchant's right edge brings it back
- `/rs` lists every recipe on the open merchant with its slot and whether you know it.

Works with every profession and every recipe merchant, not only Merchant's Favor. It reads the game's own item data, so there's no recipe database to go out of date and labels use your game language.

## Works with

RecipeScout only adds its own labels and panel on top of the merchant window and never changes Blizzard code, so it runs alongside tooltip and profession addons. It doesn't hide items or move them between pages, so addons that do (like known-item filters) keep working.

Related addons that do different jobs: FavorCraft plans Merchant's Favor purchases from its own window; Known Item Filter hides known recipes at vendors.

## Compatibility

WoW Forever (1.60.1). Not Classic Era: the tooltip data it relies on doesn't exist there.

## Feedback

Issues and suggestions: [GitHub issues](https://github.com/jlblancolb/recipe-scout/issues). A screenshot of the merchant and the output of `/rs` help most.
