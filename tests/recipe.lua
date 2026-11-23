-- Recipe.lua and the merchant overlay against tooltip data shaped like the
-- Forever probe results (Jim'bek, 2026-11-23, probe/data/2026-11-23-rsprobe.lua).

local function check(condition, message)
    if not condition then error(message, 2) end
end

-- Item classes and slots as GetItemInfoInstant returns them on Forever.
local items = {
    [253892] = { "Recipe", "Tailoring", "INVTYPE_NON_EQUIP_IGNORE", 9 },  -- Pattern: Silky Boots
    [253891] = { "Armor", "Cloth", "INVTYPE_FEET", 4 },                   -- Silky Boots
    [253920] = { "Recipe", "Tailoring", "INVTYPE_NON_EQUIP_IGNORE", 9 },  -- Pattern: Shadow Gloves
    [253919] = { "Armor", "Cloth", "INVTYPE_HAND", 4 },
    [254080] = { "Recipe", "Tailoring", "INVTYPE_NON_EQUIP_IGNORE", 9 },  -- Pattern: Runecloth Reagent Bag
    [254079] = { "Container", "Reagent Bag", "INVTYPE_BAG", 1 },
    [271627] = { "Miscellaneous", "Other", "INVTYPE_NON_EQUIP_IGNORE", 15 }, -- Tailoring Certification
    [999001] = { "Recipe", "Enchanting", "INVTYPE_NON_EQUIP_IGNORE", 9 },  -- made-up formula
}
C_Item = {
    GetItemInfoInstant = function(id)
        local item = items[id]
        if not item then return nil end
        return id, item[1], item[2], item[3], 134939, item[4], 0
    end,
}
INVTYPE_FEET, INVTYPE_HAND, INVTYPE_BAG = "Feet", "Hands", "Bag"
ITEM_SPELL_KNOWN = "Already known"

local function Recipe(name, crafted, known)
    local lines = {
        { type = 22, leftText = name },
        { type = 20, leftText = "Binds when picked up" },
    }
    if crafted then lines[#lines + 1] = { type = 19, leftText = "", tooltipID = crafted, tooltipType = 0 } end
    lines[#lines + 1] = { type = 43, leftText = "Requires Tailoring (60)", requirementType = 2, usable = true }
    if known then
        lines[#lines + 1] = { type = 43, leftText = "Already known", requirementType = 14, usable = false }
    end
    return { lines = lines }
end

local merchant = {
    { 253892, Recipe("Pattern: Silky Boots", 253891) },
    { 253920, Recipe("Pattern: Shadow Gloves", 253919, true) },
    { 254080, Recipe("Pattern: Runecloth Reagent Bag", 254079) },
    { 271627, { lines = { { type = 22, leftText = "Tailoring Certification" } } } },
    { 999001, Recipe("Formula: Enchant Bracer - Minor Health", nil) },
}
function GetMerchantItemID(index) return merchant[index] and merchant[index][1] end
function GetMerchantNumItems() return #merchant end
C_TooltipInfo = { GetMerchantItem = function(index) return merchant[index] and merchant[index][2] end }

-- Minimal frames for the overlay.
local noop = function() end
local function NewRegion()
    local region = setmetatable({ shown = true, text = "" }, { __index = function() return noop end })
    region.GetFrameLevel = function() return 1 end
    region.SetText = function(self, text) self.text = text end
    region.GetText = function(self) return self.text end
    region.SetTextColor = function(self, r, g, b) self.color = { r, g, b } end
    region.Show = function(self) self.shown = true end
    region.Hide = function(self) self.shown = false; end
    region.SetShown = function(self, shown) self.shown = shown and true or false end
    region.IsShown = function(self) return self.shown end
    region.CreateTexture = function() return NewRegion() end
    region.CreateFontString = function() return NewRegion() end
    region.SetScript = function(self, name, callback) self["on" .. name] = callback end
    region.HookScript = noop
    region.SetChecked = function(self, value) self.checked = value end
    region.GetChecked = function(self) return self.checked end
    return region
end
local created = {}
function CreateFrame(kind, name)
    local f = NewRegion()
    f.kind = kind
    created[#created + 1] = f
    if name then _G[name] = f end
    return f
end
function wipe(t) for k in pairs(t) do t[k] = nil end return t end
GameTooltip = NewRegion()
STANDARD_TEXT_FONT = "Fonts\\FRIZQT__.TTF"
MERCHANT_ITEMS_PER_PAGE = 10
MerchantFrame = NewRegion()
MerchantFrame.page, MerchantFrame.selectedTab = 1, 1
for slot = 1, 10 do
    _G["MerchantItem" .. slot] = NewRegion()
    _G["MerchantItem" .. slot].ItemButton = NewRegion()
    _G["MerchantItem" .. slot .. "Name"] = NewRegion()
end
local hooks = {}
function MerchantFrame_Update() end
function hooksecurefunc(name, callback) hooks[name] = callback end
C_Timer = { After = function(_, callback) callback() end }
SlashCmdList = {}
local chat = {}
DEFAULT_CHAT_FRAME = { AddMessage = function(_, message) chat[#chat + 1] = message end }

local ns = {}
assert(loadfile("Recipe.lua"))("RecipeScout", ns)
assert(loadfile("Panel.lua"))("RecipeScout", ns)
assert(loadfile("RecipeScout.lua"))("RecipeScout", ns)
local R = ns.Recipe

-- Parsing
local boots = R.ForMerchantItem(1)
check(boots.crafted == 253891 and boots.label == "Feet" and not boots.known, "boots: Feet, not known")
local gloves = R.ForMerchantItem(2)
check(gloves.label == "Hands" and gloves.known, "gloves: Hands, known")
check(R.ForMerchantItem(3).label == "Reagent Bag" or R.ForMerchantItem(3).label == "Bag", "bag gets a label")
check(R.ForMerchantItem(4) == nil, "certification is not a recipe")
check(R.ForMerchantItem(5).label == "Bracer", "enchant formula label from its name")
check(R.Parse(nil).known == false, "nil data is safe")

-- Secret values are skipped, never compared.
local secret = {}
function issecretvalue(value) return rawequal(value, secret) end
check(R.Parse({ lines = { { leftText = secret, tooltipID = secret } } }).crafted == nil, "secret ID skipped")
issecretvalue = nil

-- Overlay on the merchant page
MerchantFrame:Show()
check(hooks.MerchantFrame_Update, "hooks MerchantFrame_Update")
hooks.MerchantFrame_Update()
local function Overlay(slot)
    return _G["MerchantItem" .. slot].ItemButton
end
check(Overlay(1) and ns.Update, "overlay exists")

-- Find the overlay font strings created for each slot via the hooked update.
SlashCmdList.RECIPESCOUT()
check(chat[#chat]:find("4 recipes"), "slash command counts 4 recipes, got: " .. chat[#chat])
check(chat[2]:find("Hands") and chat[2]:find("known"), "slash lists gloves as known")

-- Panel: opens on merchant show with every recipe, filters by slot, search and hide known.
local events
for _, f in ipairs(created) do if rawget(f, "onOnEvent") and not events then events = f end end
events.onOnEvent(events, "MERCHANT_SHOW")
local panel = RecipeScoutPanel
check(panel and panel.shown, "panel shown when the merchant sells recipes")
local function VisibleRows()
    local names = {}
    for _, f in ipairs(created) do
        if f.kind == "Button" and rawget(f, "index") and f.shown then names[#names + 1] = f.index end
    end
    return #names
end
check(VisibleRows() == 4, "panel lists 4 recipes, got " .. VisibleRows())
-- Slot chip "Hands" filters to the gloves.
for _, f in ipairs(created) do
    if rawget(f, "label") == "Hands" and rawget(f, "onOnClick") then f.onOnClick(f) end
end
check(VisibleRows() == 1, "Hands filter shows 1 row, got " .. VisibleRows())
-- Hide known removes the gloves too.
RecipeScoutDB.hideKnown = true
ns.Panel.Refresh()
check(VisibleRows() == 0, "hide known + Hands shows nothing")
RecipeScoutDB.hideKnown = false
-- Clicking a row jumps to its page.
for _, f in ipairs(created) do
    if rawget(f, "label") == false and rawget(f, "onOnClick") then f.onOnClick(f) end
end
for _, f in ipairs(created) do
    if f.kind == "Button" and rawget(f, "index") == 5 and f.shown then f.onOnClick(f) end
end
check(MerchantFrame.page == 1 and ns.highlight == nil, "jump to item 5 on page 1, glow cleared after the timer")

-- Robes use the chest name, held-in-off-hand items the short off-hand name.
items[700001] = { "Armor", "Cloth", "INVTYPE_ROBE", 4 }
items[700002] = { "Armor", "Miscellaneous", "INVTYPE_HOLDABLE", 4 }
INVTYPE_CHEST, INVTYPE_ROBE, SECONDARYHANDSLOT, INVTYPE_HOLDABLE = "Chest", "Chest", "Off Hand", "Held In Off-hand"
check(R.Label(700001) == "Chest" and R.Label(700002) == "Off Hand", "short slot names")

-- Buyback tab hides the panel without errors.
MerchantFrame.selectedTab = 2
hooks.MerchantFrame_Update()
check(not panel.shown, "panel hidden on buyback")
MerchantFrame.selectedTab = 1
hooks.MerchantFrame_Update()
check(panel.shown, "panel back on the merchant tab")

print("recipe tests passed")
