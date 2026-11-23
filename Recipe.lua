-- Reads what a merchant recipe makes and whether you know it, from the
-- merchant item's tooltip data. Measured on Forever 1.60.1 (probe, 2026-11-23):
-- the recipe tooltip holds the crafted item as a nested line with `tooltipID`,
-- and a known recipe has a requirement line reading ITEM_SPELL_KNOWN.

local _, ns = ...
ns = ns or {}

local Recipe = {}
ns.Recipe = Recipe

-- Settings, all on by default. Read through ns.Opt so a missing key means its default.
ns.DEFAULTS = {
    enabled = true, badges = true, known = true, alts = true, looks = true, tooltip = true, panelShown = true,
}
function ns.Opt(key)
    local db = RecipeScoutDB
    if type(db) ~= "table" or db[key] == nil then return ns.DEFAULTS[key] end
    return db[key]
end

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

-- "Requires %s (%d)" (ITEM_MIN_SKILL) as a Lua pattern capturing profession and level.
local skillPattern
local function SkillPattern()
    if skillPattern then return skillPattern end
    local template = Text(ITEM_MIN_SKILL) or "Requires %s (%d)"
    local escaped = template:gsub("[%(%)%.%+%-%*%?%[%]%^%$]", "%%%0")
    skillPattern = "^" .. escaped:gsub("%%s", "(.+)"):gsub("%%d", "(%%d+)") .. "$"
    return skillPattern
end
Recipe.SkillPattern = SkillPattern

-- The recipe's name without its "Pattern: " style prefix, lower-cased for matching.
function Recipe.ShortName(name)
    name = Text(name)
    if not name then return nil end
    return (name:match("^[^:]+:%s*(.+)$") or name):lower()
end

-- Parses tooltip data into { crafted, known, spell, reqProf, reqSkill, name }.
-- The crafted item comes first as a nested line; the recipe's own "Use: Teaches..."
-- spell and its profession requirement come after it, so the last match wins for those.
function Recipe.Parse(data)
    local result = { known = false }
    if type(data) ~= "table" or type(data.lines) ~= "table" then return result end
    local knownText = Text(ITEM_SPELL_KNOWN) or "Already known"
    local lookMissing = Text(TRANSMOGRIFY_TOOLTIP_APPEARANCE_UNKNOWN) or "You haven't collected this appearance"
    local lookOwned = Text(TRANSMOGRIFY_TOOLTIP_APPEARANCE_KNOWN) or "You've collected this appearance"
    local lookOwnedOther = Text(TRANSMOGRIFY_TOOLTIP_ITEM_UNKNOWN_APPEARANCE_KNOWN)
        or "You've collected this appearance, but not from this item"
    for index, line in ipairs(data.lines) do
        local id = line.tooltipID
        if not result.crafted and type(id) == "number" and not isSecret(id)
            and (line.tooltipType == nil or line.tooltipType == 0) then
            result.crafted = id
        end
        local spell = line.spellID
        if type(spell) == "number" and not isSecret(spell) then result.spell = spell end
        local text = Text(line.leftText)
        if line.isValidInvSlot ~= nil then result.slotLine = true end
        if text == knownText then
            result.known = true
        elseif text == lookMissing then
            result.lookMissing = true
        elseif text == lookOwned or text == lookOwnedOther then
            result.lookOwned = true
        elseif text then
            local prof, level = text:match(SkillPattern())
            if prof then
                result.reqProf, result.reqSkill = prof, tonumber(level)
            end
        end
        if index == 1 then result.name = Recipe.ShortName(text) end
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

-- Enchanting formula targets mapped to the same slot names gear uses, so "Feet" also finds boot enchants.
Recipe.ENCHANT_SLOTS = {
    boots = "INVTYPE_FEET", bracer = "INVTYPE_WRIST", gloves = "INVTYPE_HAND", cloak = "INVTYPE_CLOAK",
    chest = "INVTYPE_CHEST", shield = "INVTYPE_SHIELD", ["2h weapon"] = "INVTYPE_2HWEAPON",
}

-- Slots that have an appearance you can collect.
Recipe.TRANSMOG = {
    INVTYPE_HEAD = true, INVTYPE_SHOULDER = true, INVTYPE_BODY = true, INVTYPE_CHEST = true, INVTYPE_ROBE = true,
    INVTYPE_WAIST = true, INVTYPE_LEGS = true, INVTYPE_FEET = true, INVTYPE_WRIST = true, INVTYPE_HAND = true,
    INVTYPE_CLOAK = true, INVTYPE_TABARD = true, INVTYPE_WEAPON = true, INVTYPE_SHIELD = true,
    INVTYPE_2HWEAPON = true, INVTYPE_WEAPONMAINHAND = true, INVTYPE_WEAPONOFFHAND = true,
    INVTYPE_HOLDABLE = true, INVTYPE_RANGED = true, INVTYPE_RANGEDRIGHT = true,
}

-- "owned" when you've collected the crafted item's appearance, "missing" when you haven't,
-- nil when it has none or the tooltip isn't complete yet. Measured on Forever: the game only
-- writes the "haven't collected" line; a collected appearance simply has no line.
function Recipe.Look(info)
    if info.lookMissing then return "missing" end
    if info.lookOwned then return "owned" end
    if not (info.crafted and info.slotLine) then return nil end
    local _, _, _, equipLoc = ItemInstant(info.crafted)
    equipLoc = Text(equipLoc)
    if equipLoc and Recipe.TRANSMOG[equipLoc] then return "owned" end
    return nil
end

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
    local target = Recipe.EnchantTarget(recipeName)
    local slot = target and Recipe.ENCHANT_SLOTS[target:lower()]
    return slot and Text(_G[slot]) or target
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
    info.title = Text(name)
    info.label = Recipe.Label(info.crafted, name)
    info.look = Recipe.Look(info)
    if ns.Alts and ns.Opt("alts") then info.alts = ns.Alts.For(info) end
    return info
end

return Recipe
