-- Remembers what every character on the account can craft, so a merchant recipe
-- can say "your alt already knows this" or "your alt could learn this".
--
-- RecipeScoutDB.chars["Name-Realm"] = {
--     name, realm, class,
--     skills = { [professionName] = rank },               -- from the skill list at login
--     profs  = { [professionName] = { scanned = time,     -- from the profession window
--                items = { [itemID] = true }, spells = { [recipeID] = true }, names = { [name] = true } } },
-- }

local _, ns = ...
ns = ns or {}
local Recipe = ns.Recipe

local Alts = {}
ns.Alts = Alts

local isSecret = function(value)
    return issecretvalue ~= nil and issecretvalue(value) == true
end
local function Plain(value)
    if isSecret(value) then return nil end
    return value
end

local function Call(func, ...)
    if type(func) ~= "function" then return nil end
    local results = { pcall(func, ...) }
    if not results[1] then return nil end
    return unpack(results, 2)
end

local function DB()
    RecipeScoutDB = RecipeScoutDB or {}
    RecipeScoutDB.chars = RecipeScoutDB.chars or {}
    return RecipeScoutDB
end

local meKey
local function Me()
    if meKey then return meKey end
    local name, realm = Plain(UnitName("player")), Plain(GetRealmName and GetRealmName())
    if not name then return nil end
    meKey = name .. "-" .. (realm or "")
    return meKey
end
Alts.Me = Me

local function MyChar()
    local key = Me()
    if not key then return nil end
    local chars = DB().chars
    local char = chars[key] or { skills = {}, profs = {} }
    chars[key] = char
    char.name, char.realm = key:match("^(.-)%-(.*)$")
    local _, class = Call(UnitClass, "player")
    char.class = Plain(class) or char.class
    char.skills = char.skills or {}
    char.profs = char.profs or {}
    return char
end

-- Profession ranks from the skill list. Mainline: GetProfessions; classic: GetSkillLineInfo.
-- Weapon skills land here too on classic; harmless, they never match a recipe requirement.
function Alts.RecordSkills()
    local char = MyChar()
    if not char then return end
    local found = false
    if GetProfessions then
        for _, index in pairs({ Call(GetProfessions) }) do
            local name, _, rank = Call(GetProfessionInfo, index)
            name, rank = Plain(name), Plain(rank)
            if type(name) == "string" and type(rank) == "number" then
                char.skills[name] = rank
                found = true
            end
        end
    end
    if not found and GetNumSkillLines then
        for index = 1, Call(GetNumSkillLines) or 0 do
            local name, isHeader, _, rank = Call(GetSkillLineInfo, index)
            name, rank = Plain(name), Plain(rank)
            if not isHeader and type(name) == "string" and type(rank) == "number" then
                char.skills[name] = rank
            end
        end
    end
end

local function ItemFromLink(link)
    link = Plain(link)
    if type(link) ~= "string" then return nil end
    return tonumber(link:match("item:(%d+)"))
end

local function NewProf(char, name, rank)
    local prof = { scanned = time(), items = {}, spells = {}, names = {} }
    char.profs[name] = prof
    if type(rank) == "number" then char.skills[name] = rank end
    return prof
end

-- Mainline profession window (C_TradeSkillUI). Returns true if it handled the scan.
local function ScanModern(char)
    local ui = C_TradeSkillUI
    if not (ui and ui.GetAllRecipeIDs and ui.GetRecipeInfo) then return false end
    if Call(ui.IsTradeSkillLinked) or Call(ui.IsTradeSkillGuild) or Call(ui.IsNPCCrafting) then return true end
    local ids = Call(ui.GetAllRecipeIDs)
    if type(ids) ~= "table" or #ids == 0 then return false end

    local base = Call(ui.GetBaseProfessionInfo) or Call(ui.GetChildProfessionInfo)
    local profName = base and Plain(base.professionName)
    local rank = base and Plain(base.skillLevel)
    if not profName and GetTradeSkillLine then
        profName, rank = Call(GetTradeSkillLine)
        profName, rank = Plain(profName), Plain(rank)
    end
    if type(profName) ~= "string" or profName == "" then return false end

    local prof = NewProf(char, profName, rank)
    for _, id in ipairs(ids) do
        local info = Call(ui.GetRecipeInfo, id)
        if type(info) == "table" and info.learned then
            prof.spells[id] = true
            local name = Recipe.ShortName(info.name)
            if name then prof.names[name] = true end
            local output = Call(ui.GetRecipeOutputItemData, id)
            local item = type(output) == "table" and Plain(output.itemID)
            if not item then
                local schematic = Call(ui.GetRecipeSchematic, id, false)
                item = type(schematic) == "table" and Plain(schematic.outputItemID)
            end
            if not item then item = ItemFromLink(Call(ui.GetRecipeItemLink, id)) end
            if type(item) == "number" then prof.items[item] = true end
        end
    end
    return true
end

-- Classic profession window (GetTradeSkillInfo); every listed recipe is learned.
local function ScanClassic(char)
    if not (GetNumTradeSkills and GetTradeSkillLine) then return false end
    local profName, rank = Call(GetTradeSkillLine)
    profName = Plain(profName)
    local count = Call(GetNumTradeSkills) or 0
    if type(profName) ~= "string" or profName == "" or profName == "UNKNOWN" or count == 0 then return false end
    local prof = NewProf(char, profName, Plain(rank))
    for index = 1, count do
        local name, kind = Call(GetTradeSkillInfo, index)
        if kind ~= "header" and kind ~= "subheader" then
            name = Recipe.ShortName(name)
            if name then prof.names[name] = true end
            local item = ItemFromLink(Call(GetTradeSkillItemLink, index))
            if item then prof.items[item] = true end
            local recipeLink = Plain(Call(GetTradeSkillRecipeLink, index))
            local spell = type(recipeLink) == "string" and tonumber(recipeLink:match("enchant:(%d+)"))
            if spell then prof.spells[spell] = true end
        end
    end
    return true
end

function Alts.ScanProfession()
    local char = MyChar()
    if not char then return end
    if not ScanModern(char) then ScanClassic(char) end
end

-- A freshly learned recipe counts right away, before the profession window is reopened.
function Alts.Learned(recipeID)
    local char = MyChar()
    recipeID = Plain(recipeID)
    if not char or type(recipeID) ~= "number" then return end
    for _, prof in pairs(char.profs) do prof.spells[recipeID] = true end
end

local function Knows(char, info)
    for _, prof in pairs(char.profs or {}) do
        if (info.crafted and prof.items[info.crafted]) or (info.spell and prof.spells[info.spell])
            or (info.name and prof.names[info.name]) then
            return true
        end
    end
    return false
end

local function Display(key, char)
    local name = char.name or key
    local myRealm = Me() and Me():match("%-(.*)$")
    if char.realm and char.realm ~= "" and char.realm ~= myRealm then name = name .. "-" .. char.realm end
    local color = char.class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[char.class]
    if color and color.colorStr then return "|c" .. color.colorStr .. name .. "|r" end
    return name
end

-- Which other characters know this recipe, could learn it now, or have the profession
-- but too little skill. Each list holds display names; `low` and `unscanned` add a skill note.
function Alts.For(info)
    local result = { known = {}, can = {}, low = {}, unscanned = {} }
    if type(info) ~= "table" then return result end
    local me = Me()
    local keys = {}
    for key in pairs(DB().chars) do
        if key ~= me then keys[#keys + 1] = key end
    end
    table.sort(keys)
    for _, key in ipairs(keys) do
        local char = DB().chars[key]
        if Knows(char, info) then
            result.known[#result.known + 1] = Display(key, char)
        elseif info.reqProf then
            local rank = char.skills and char.skills[info.reqProf]
            local scanned = char.profs and char.profs[info.reqProf]
            if rank then
                local entry = string.format("%s (%d)", Display(key, char), rank)
                if rank < (info.reqSkill or 0) then
                    result.low[#result.low + 1] = entry
                elseif scanned then
                    result.can[#result.can + 1] = Display(key, char)
                else
                    result.unscanned[#result.unscanned + 1] = entry
                end
            end
        end
    end
    return result
end

-- Extra tooltip lines for any recipe tooltip (merchant, bags, auction house).
function Alts.AddTooltipLines(tooltip, data)
    if not tooltip or type(data) ~= "table" then return end
    local id = Plain(data.id)
    if type(id) ~= "number" or not Recipe.IsRecipe(id) then return end
    local alts = Alts.For(Recipe.Parse(data))
    if #alts.known + #alts.can + #alts.low + #alts.unscanned == 0 then return end
    tooltip:AddLine(" ")
    tooltip:AddLine("RecipeScout", 0.4, 0.8, 1)
    if #alts.known > 0 then
        tooltip:AddLine("Known by: " .. table.concat(alts.known, ", "), 1, 0.82, 0, true)
    end
    if #alts.can > 0 then
        tooltip:AddLine("Can learn: " .. table.concat(alts.can, ", "), 0.25, 1, 0.25, true)
    end
    if #alts.unscanned > 0 then
        tooltip:AddLine("Has the profession, recipes not checked yet: " .. table.concat(alts.unscanned, ", ")
            .. " (open their profession window once)", 0.7, 0.7, 0.7, true)
    end
    if #alts.low > 0 then
        tooltip:AddLine("Skill too low: " .. table.concat(alts.low, ", "), 0.6, 0.6, 0.6, true)
    end
end

-- Chat summary for /rs alts.
function Alts.Summary()
    local lines = {}
    local keys = {}
    for key in pairs(DB().chars) do keys[#keys + 1] = key end
    table.sort(keys)
    for _, key in ipairs(keys) do
        local char = DB().chars[key]
        local parts = {}
        for profName, prof in pairs(char.profs or {}) do
            local count = 0
            for _ in pairs(prof.spells) do count = count + 1 end
            local rank = char.skills and char.skills[profName]
            parts[#parts + 1] = string.format("%s %s: %d recipes", profName, rank and ("(" .. rank .. ")") or "", count)
        end
        table.sort(parts)
        lines[#lines + 1] = Display(key, char) .. (key == Me() and " (this character)" or "") .. " - "
            .. (#parts > 0 and table.concat(parts, ", ") or "no profession window opened yet")
    end
    return lines
end

function Alts.Forget(name)
    if type(name) ~= "string" or name == "" then return nil end
    name = name:lower()
    for key in pairs(DB().chars) do
        local short = key:match("^(.-)%-") or key
        if key:lower() == name or short:lower() == name then
            DB().chars[key] = nil
            return key
        end
    end
    return nil
end

-- Events: skills at login and when they change, recipes when a profession window shows or updates.
local pending = false
local function ScanSoon()
    if pending then return end
    pending = true
    C_Timer.After(0.5, function()
        pending = false
        Alts.ScanProfession()
    end)
end

local events = CreateFrame("Frame")
for _, event in ipairs({ "PLAYER_LOGIN", "SKILL_LINES_CHANGED", "TRADE_SKILL_SHOW", "TRADE_SKILL_LIST_UPDATE",
    "TRADE_SKILL_DATA_SOURCE_CHANGED", "NEW_RECIPE_LEARNED" }) do
    pcall(events.RegisterEvent, events, event)
end
events:SetScript("OnEvent", function(_, event, arg1)
    if event == "PLAYER_LOGIN" or event == "SKILL_LINES_CHANGED" then
        Alts.RecordSkills()
    elseif event == "NEW_RECIPE_LEARNED" then
        Alts.Learned(arg1)
        ScanSoon()
    else
        ScanSoon()
    end
end)

if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
        if tooltip == GameTooltip or tooltip == ItemRefTooltip then
            pcall(Alts.AddTooltipLines, tooltip, data)
        end
    end)
end
