# RecipeScout

**Which of these 70 patterns are boots?** RecipeScout labels every recipe a merchant sells with what it makes, marks the ones you or your alts already know, and lets you filter all pages at once.

![RecipeScout next to a recipe merchant: slot badges on every icon and the side panel listing all pages](https://raw.githubusercontent.com/jlblancolb/recipe-scout/main/media/screenshots/panel.png)

## What you see

- **A slot on every recipe icon:** `Feet`, `Chest`, `Waist`, `Two-Hand`, `Off Hand`, `Relic`… or the item type for things you don't wear (`Reagent Bag`). Enchanting formulas show what they enchant, using the same slot names (`Weapon`, `Wrist`, `Feet`), so the Feet filter finds boot enchants too.
- **Known recipes:** green check on the icon and a green row.
- **Can't learn yet** (skill too low, reputation): stays red, as the game already shows.

![Enchanting formulas: Two-Hand, Off Hand, Relic and Weapon at a glance](https://raw.githubusercontent.com/jlblancolb/recipe-scout/main/media/screenshots/enchanting.png)

## The side panel

Opens next to any merchant that sells recipes:

- slot buttons with counts: `Feet (12)`, `Hands (11)`…
- name search and **Hide known**
- every match from **all pages** in one list; hover for the tooltip, click to jump to its page

![Feet filter: the 12 boots and sandals from all 7 pages in one list; red ones need more skill](https://raw.githubusercontent.com/jlblancolb/recipe-scout/main/media/screenshots/feet-filter.png)

![Leatherworking: 15 boots and sabatons out of 81 patterns over 9 pages](https://raw.githubusercontent.com/jlblancolb/recipe-scout/main/media/screenshots/leatherworking-feet.png)

Close it with the X; the **Recipes** button on the merchant brings it back. `/rs` prints every recipe on the merchant in chat.

## Your alts

Open each crafter's profession window once and RecipeScout remembers what they know, across your whole account.

- **Yellow** recipe = one of your other characters already knows it, with their name next to the price (`Durga`, or `Durga +1` when several do) and in the panel (`Durga · Chest`).
- The recipe **tooltip** lists who knows it, who can learn it right now, and who has the profession but not enough skill. Works on merchants, in bags and at the auction house.
- `/rs alts` lists your characters and their recipe counts; `/rs forget <name>` removes one.

![Alts: Durga already knows Shadow Gown and Shadow Circle, so they show in yellow with that name](https://raw.githubusercontent.com/jlblancolb/recipe-scout/main/media/screenshots/alts.png)

## Plays nicely

- Works with every profession and every recipe merchant.
- Reads the game's own item data: no recipe database to go out of date, and labels follow your game language.
- Only adds its own labels and panel; never hides or moves merchant items, so tooltip, profession and known-item addons keep working.

Source and issues: [github.com/jlblancolb/recipe-scout](https://github.com/jlblancolb/recipe-scout)
