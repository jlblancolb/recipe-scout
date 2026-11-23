-- Alts.lua: three characters on one account. Durga (Tailoring 75) opens the
-- profession window; Thrall has Tailoring 30 and never opens it; Jaina (no
-- tailoring) visits the merchant and should see what the other two can do.

local function check(condition, message)
    if not condition then error(message, 2) end
end

-- Shared world -------------------------------------------------------------
ITEM_SPELL_KNOWN = "Already known"
ITEM_MIN_SKILL = "Requires %s (%d)"
RAID_CLASS_COLORS = { WARLOCK = { colorStr = "ff8788ee" }, SHAMAN = { colorStr = "ff0070dd" } }
local items = {
    [253892] = 9, [253920] = 9, [999001] = 9, -- recipes
    [253891] = 4, [253919] = 4,               -- Silky Boots, Shadow Gloves
}
C_Item = { GetItemInfoInstant = function(id)
    if not items[id] then return nil end
    return id, "x", "x", "INVTYPE_FEET", 0, items[id], 0
end }
local function Frame()
    local frame = { events = {} }
    function frame:RegisterEvent(event) self.events[event] = true end
    function frame:SetScript(_, callback) self.onEvent = callback end
    return frame
end
local frames = {}
function CreateFrame() local f = Frame(); frames[#frames + 1] = f; return f end
C_Timer = { After = function(_, callback) callback() end }
function time() return 1000 end
unpack = unpack or table.unpack
function GetRealmName() return "Nightslayer" end

-- Recipe tooltips as the merchant returns them (shape from the Forever probe).
local function RecipeData(id, name, crafted, spell, prof, level)
    local lines = { { type = 22, leftText = name } }
    if crafted then lines[#lines + 1] = { type = 19, leftText = "", tooltipID = crafted, tooltipType = 0 } end
    lines[#lines + 1] = { type = 38, leftText = "Use: Teaches you how to craft it.", spellID = spell }
    lines[#lines + 1] = { type = 43, leftText = string.format("Requires %s (%d)", prof, level), requirementType = 2 }
    return { id = id, lines = lines }
end
local silky = RecipeData(253892, "Pattern: Silky Boots", 253891, 1257371, "Tailoring", 60)
local gloves = RecipeData(253920, "Pattern: Shadow Gloves", 253919, 1257385, "Tailoring", 75)
local insight = RecipeData(999001, "Formula: Enchant Weapon - Insight", nil, 777, "Enchanting", 100)

-- Load the addon files as a given character.
local ns
local function Login(name, class, professions, tradeskill)
    function UnitName() return name end
    function UnitClass() return class, class end
    function GetProfessions() local idx = {} for i in ipairs(professions) do idx[i] = i end return unpack(idx) end
    function GetProfessionInfo(i) return professions[i][1], nil, professions[i][2] end
    C_TradeSkillUI = tradeskill
    ns = {}
    frames = {}
    assert(loadfile("Recipe.lua"))("RecipeScout", ns)
    assert(loadfile("Alts.lua"))("RecipeScout", ns)
    local events = frames[#frames]
    events.onEvent(events, "PLAYER_LOGIN")
    return events
end

-- 1. Durga opens Tailoring: knows Silky Boots, not Shadow Gloves.
RecipeScoutDB = nil
local recipes = {
    [1257371] = { learned = true, name = "Silky Boots", output = 253891 },
    [1257385] = { learned = false, name = "Shadow Gloves", output = 253919 },
}
local durgaEvents = Login("Durga", "WARLOCK", { { "Tailoring", 75 } }, {
    GetAllRecipeIDs = function() return { 1257371, 1257385 } end,
    GetRecipeInfo = function(id) return { learned = recipes[id].learned, name = recipes[id].name } end,
    GetRecipeOutputItemData = function(id) return { itemID = recipes[id].output } end,
    GetBaseProfessionInfo = function() return { professionName = "Tailoring", skillLevel = 75 } end,
    IsTradeSkillLinked = function() return false end,
})
durgaEvents.onEvent(durgaEvents, "TRADE_SKILL_SHOW")
local durga = RecipeScoutDB.chars["Durga-Nightslayer"]
check(durga and durga.profs.Tailoring, "Durga's tailoring recorded")
check(durga.profs.Tailoring.items[253891] and durga.profs.Tailoring.spells[1257371], "Silky Boots recorded by item and spell")
check(not durga.profs.Tailoring.items[253919], "unlearned recipe not recorded")
check(durga.skills.Tailoring == 75, "skill recorded")

-- A linked profession (someone else's) is ignored.
recipes[1257385].learned = true
C_TradeSkillUI.IsTradeSkillLinked = function() return true end
durgaEvents.onEvent(durgaEvents, "TRADE_SKILL_SHOW")
check(not durga.profs.Tailoring.items[253919], "linked profession ignored")
recipes[1257385].learned = false

-- 2. Thrall: Tailoring 30 at login, never opens the window.
Login("Thrall", "SHAMAN", { { "Tailoring", 30 } }, nil)

-- 3. Jaina at the merchant.
Login("Jaina", "MAGE", {}, nil)
local A, R = ns.Alts, ns.Recipe

local parsed = R.Parse(silky)
check(parsed.spell == 1257371 and parsed.reqProf == "Tailoring" and parsed.reqSkill == 60, "parse spell and requirement")
check(parsed.name == "silky boots", "parse short name")

local s = A.For(parsed)
check(#s.known == 1 and s.known[1]:find("Durga"), "Silky Boots known by Durga")
check(s.known[1]:find("|cff8788ee"), "class colour")
check(#s.low == 1 and s.low[1]:find("Thrall") and s.low[1]:find("30"), "Thrall's skill too low for Silky Boots")

local g = A.For(R.Parse(gloves))
check(#g.known == 0, "nobody knows Shadow Gloves")
check(#g.can == 1 and g.can[1]:find("Durga"), "Durga can learn Shadow Gloves")
check(#g.low == 1, "Thrall too low for Shadow Gloves")

-- Enchanting matches by name (no crafted item).
RecipeScoutDB.chars["Durga-Nightslayer"].profs.Enchanting = {
    items = {}, spells = {}, names = { ["enchant weapon - insight"] = true } }
check(#A.For(R.Parse(insight)).known == 1, "enchant formula matched by name")

-- An alt with the profession but no scan is reported separately, not as "can learn".
RecipeScoutDB.chars["Thrall-Nightslayer"].skills.Tailoring = 80
local u = A.For(R.Parse(gloves))
check(#u.unscanned == 1 and #u.can == 1, "Thrall listed as not scanned, Durga as can learn")

-- Tooltip lines.
local tip = { lines = {} }
function tip:AddLine(text) self.lines[#self.lines + 1] = text end
A.AddTooltipLines(tip, gloves)
local text = table.concat(tip.lines, "\n")
check(text:find("Can learn: .*Durga"), "tooltip: can learn")
check(text:find("not checked yet: .*Thrall"), "tooltip: not scanned")
local plain = { lines = {} }
function plain:AddLine(t) self.lines[#self.lines + 1] = t end
A.AddTooltipLines(plain, { id = 253891, lines = {} })
check(#plain.lines == 0, "no lines on non-recipe items")

-- Other realms keep their realm in the name.
RecipeScoutDB.chars["Rexxar-Doomhowl"] = { name = "Rexxar", realm = "Doomhowl", skills = {}, profs = {
    Tailoring = { items = { [253891] = true }, spells = {}, names = {} } } }
local r = A.For(R.Parse(silky))
check(#r.known == 2 and table.concat(r.known, " "):find("Rexxar%-Doomhowl"), "other realm shown with realm")

-- Summary and forget.
local summary = table.concat(A.Summary(), "\n")
check(summary:find("Durga") and summary:find("Tailoring %(75%): 1 recipes"), "summary counts, got:\n" .. summary)
check(summary:find("Jaina.-this character"), "summary marks the current character")
check(A.Forget("rexxar") == "Rexxar-Doomhowl" and not RecipeScoutDB.chars["Rexxar-Doomhowl"], "forget by name")
check(A.Forget("nobody") == nil, "forget unknown name")

-- Learning a recipe adds it immediately.
Login("Durga", "WARLOCK", { { "Tailoring", 75 } }, nil)
ns.Alts.Learned(1257385)
check(RecipeScoutDB.chars["Durga-Nightslayer"].profs.Tailoring.spells[1257385], "NEW_RECIPE_LEARNED recorded")

-- Secret values never get compared or stored.
local secret = {}
function issecretvalue(value) return rawequal(value, secret) end
ns.Alts.Learned(secret)
check(R.Parse({ lines = { { leftText = secret, spellID = secret } } }).spell == nil, "secret spell skipped")
issecretvalue = nil

print("alts tests passed")
