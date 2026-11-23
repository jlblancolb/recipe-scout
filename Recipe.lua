-- Reads what a merchant recipe makes and whether you know it, from the
-- merchant item's tooltip data. Measured on Forever 1.60.1 (probe, 2026-11-23):
-- the recipe tooltip holds the crafted item as a nested line with `tooltipID`,
-- and a known recipe has a requirement line reading ITEM_SPELL_KNOWN.

local _, ns = ...
ns = ns or {}

local Recipe = {}
ns.Recipe = Recipe

local RECIPE_CLASS = 9 -- Enum.ItemClass.Recipe

local isSecret = function(value)
    return issecretvalue ~= nil and issecretvalue(value) == true
end

local function Text(value)
    if type(value) ~= "string" or isSecret(value) then return nil end
    return value
end

local function ItemInstant(item)
    local get = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
    if not get then return nil end
    local ok, itemID, itemType, subType, equipLoc, icon, classID = pcall(get, item)
    if not ok then return nil end
    return itemID, itemType, subType, equipLoc, icon, classID
end

-- True when this merchant item is a recipe (pattern, plan, formula, schematic...).
function Recipe.IsRecipe(itemID)
    if not itemID then return false end
    local _, _, _, _, _, classID = ItemInstant(itemID)
    return classID == RECIPE_CLASS
end

-- Parses tooltip data into { crafted = itemID or nil, known = bool }.
function Recipe.Parse(data)
    local result = { known = false }
    if type(data) ~= "table" or type(data.lines) ~= "table" then return result end
    local knownText = Text(ITEM_SPELL_KNOWN) or "Already known"
    for _, line in ipairs(data.lines) do
        local id = line.tooltipID
        if not result.crafted and type(id) == "number" and not isSecret(id)
            and (line.tooltipType == nil or line.tooltipType == 0) then
            result.crafted = id
        end
        if Text(line.leftText) == knownText then
            result.known = true
        end
    end
    return result
end

-- Enchanting formulas teach a spell, not an item: "Formula: Enchant Bracer - Minor Health" -> "Bracer".
function Recipe.EnchantTarget(recipeName)
    local name = Text(recipeName)
    if not name then return nil end
    return name:match("Enchant%s+(.-)%s+%-")
end

-- Shorter localized names for slots whose usual name doesn't fit under an icon
-- ("Held In Off-hand" -> "Off Hand").
Recipe.SHORT = {
    INVTYPE_HOLDABLE = "SECONDARYHANDSLOT",
    INVTYPE_WEAPONOFFHAND = "SECONDARYHANDSLOT",
    INVTYPE_WEAPONMAINHAND = "MAINHANDSLOT",
    INVTYPE_ROBE = "INVTYPE_CHEST",
}

-- Short label for what the recipe makes: the localized slot ("Feet", "Back"),
-- or the item subtype ("Potion", "Bag") for things you don't wear.
function Recipe.Label(craftedID, recipeName)
    if craftedID then
        local _, _, subType, equipLoc = ItemInstant(craftedID)
        equipLoc = Text(equipLoc)
        if equipLoc and equipLoc ~= "" and equipLoc ~= "INVTYPE_NON_EQUIP_IGNORE" then
            local slot = Text(_G[Recipe.SHORT[equipLoc] or equipLoc]) or Text(_G[equipLoc])
            if slot and slot ~= "" then return slot end
        end
        return Text(subType)
    end
    return Recipe.EnchantTarget(recipeName)
end

-- Everything about merchant item `index`, or nil if it isn't a recipe.
-- Crafted item IDs are cached per recipe; "known" is read fresh every time.
local craftedCache = {}
function Recipe.ForMerchantItem(index)
    if not (C_TooltipInfo and C_TooltipInfo.GetMerchantItem) then return nil end
    local recipeID = GetMerchantItemID and GetMerchantItemID(index)
    if isSecret(recipeID) or not Recipe.IsRecipe(recipeID) then return nil end
    local ok, data = pcall(C_TooltipInfo.GetMerchantItem, index)
    if not ok then return nil end
    local info = Recipe.Parse(data)
    if info.crafted then
        craftedCache[recipeID] = info.crafted
    else
        info.crafted = craftedCache[recipeID]
    end
    local name = data and data.lines and data.lines[1] and data.lines[1].leftText
    info.recipeID = recipeID
    info.label = Recipe.Label(info.crafted, name)
    return info
end

return Recipe
