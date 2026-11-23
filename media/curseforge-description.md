# RecipeScout

**Which of these 70 patterns are boots?** RecipeScout labels every recipe a merchant sells with what it makes, marks the ones you already know, and lets you filter all pages at once. Made for the Merchant's Favor vendors on WoW Forever, and works at every recipe merchant.

## What you see

- **A slot on every recipe icon:** `Feet`, `Chest`, `Waist`, `Two-Hand`, `Off Hand`, `Relic`… or the item type for things you don't wear (`Reagent Bag`). Enchanting formulas show what they enchant (`Weapon`, `Bracer`).
- **Known recipes:** green check on the icon and a green row.
- **Can't learn yet** (skill too low, reputation): stays red, as the game already shows.

## The side panel

Opens next to any merchant that sells recipes:

- slot buttons with counts: `Feet (12)`, `Hands (11)`…
- name search and **Hide known**
- every match from **all pages** in one list; hover for the tooltip, click to jump to its page

Close it with the X; the **Recipes** button on the merchant brings it back. `/rs` prints every recipe on the merchant in chat.

## Plays nicely

- Reads the game's own item data: no recipe database to go out of date, and labels follow your game language.
- Only adds its own labels and panel; never hides or moves merchant items, so tooltip, profession and known-item addons keep working.

## Compatibility

WoW Forever (1.60.1).

Source and issues: [github.com/jlblancolb/recipe-scout](https://github.com/jlblancolb/recipe-scout)
