# Contributing

Bug reports, merchants where a label looks wrong, compatibility fixes and pull requests are welcome. Discuss large changes in an issue first.

## Reporting a wrong label

Open the merchant, type `/rs`, and attach a screenshot of the merchant plus the chat output. Say which recipe is wrong and what it should show.

## Local setup

1. Fork and clone the repository.
2. Install Lua 5.1 and luacheck for syntax checks, lint and tests (`scripts/test.sh`; it falls back to fengari through npm without Lua 5.1). Python 3 for packaging (`scripts/package.py`).
3. Copy `RecipeScout.toc`, `Recipe.lua`, `Panel.lua` and `RecipeScout.lua` into `Interface/AddOns/RecipeScout` in the WoW Forever folder (`scripts/install.sh` does this from WSL), and `/reload` after changes.

## Layout

- `Recipe.lua`: reads a merchant item's tooltip data: the crafted item (nested tooltip line with `tooltipID`), "Already known", and the slot label.
- `RecipeScout.lua`: badges, checks and row tint on the merchant buttons, hooks, events, `/rs`.
- `Panel.lua`: the side panel with filters.
- `probe/RSProbe`: the throwaway probe used to measure what Forever's API returns. Not shipped.
- `tests/`: Lua tests with mocked WoW APIs, shaped like real probe data.

## Guidelines

- Lua 5.1. Guard client-specific APIs and never compare or parse secret values: check `issecretvalue` first.
- Don't modify Blizzard functions or frames; use `hooksecurefunc` and add your own regions.
- Don't hide or reorder merchant items.
- Never commit account data, SavedVariables you haven't checked, or credentials.
