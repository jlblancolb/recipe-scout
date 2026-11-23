-- RecipeScout probe: a throwaway addon that records what the game tells addons
-- about every item a merchant sells, so we can see which APIs work on Forever
-- for recipes (crafted item, slot, "Already known", appearance collected).
-- Open a merchant, type /rsp, then /reload to write RSProbeDB to disk.

local isSecret = issecretvalue or function() return false end

local function Show(value)
    if isSecret(value) then return "SECRET" end
    if value == nil then return "nil" end
    return tostring(value)
end

local function Pack(...)
    return { n = select("#", ...), ... }
end

-- Calls func through pcall and returns every value as text (or an error).
local function Try(func, ...)
    if type(func) ~= "function" then return { "(missing API)" } end
    local results = Pack(pcall(func, ...))
    if not results[1] then return { "ERROR " .. Show(results[2]) } end
    local out = {}
    for index = 2, results.n do out[#out + 1] = Show(results[index]) end
    return out
end

local function Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffRSProbe|r " .. message)
end

-- Table fields as text, one level deep (for C_MerchantFrame.GetItemInfo and tooltip data).
local function Flat(value)
    if type(value) ~= "table" then return Show(value) end
    local out = {}
    for key, field in pairs(value) do
        if type(field) ~= "table" then out[#out + 1] = tostring(key) .. "=" .. Show(field) end
    end
    table.sort(out)
    return table.concat(out, " ")
end

-- Tooltip lines from the data API (Mainline) or a hidden GameTooltip (fallback).
local scanner
local function TooltipLines(index)
    local lines = {}
    if C_TooltipInfo and C_TooltipInfo.GetMerchantItem then
        local ok, data = pcall(C_TooltipInfo.GetMerchantItem, index)
        if ok and type(data) == "table" then
            lines.source = "C_TooltipInfo"
            lines.data = Flat(data)
            for _, line in ipairs(data.lines or {}) do
                local color = line.leftColor
                lines[#lines + 1] = {
                    left = Show(line.leftText),
                    right = Show(line.rightText),
                    type = Show(line.type),
                    color = color and string.format("%.2f,%.2f,%.2f", color.r or 0, color.g or 0, color.b or 0)
                        or "nil",
                    fields = Flat(line),
                }
            end
            return lines
        end
        lines.error = Show(data)
    end
    scanner = scanner or CreateFrame("GameTooltip", "RSProbeScanner", UIParent, "GameTooltipTemplate")
    scanner:SetOwner(UIParent, "ANCHOR_NONE")
    local ok, err = pcall(scanner.SetMerchantItem, scanner, index)
    lines.source = ok and "GameTooltip" or ("GameTooltip ERROR " .. Show(err))
    for line = 1, scanner:NumLines() do
        local left = _G["RSProbeScannerTextLeft" .. line]
        local right = _G["RSProbeScannerTextRight" .. line]
        lines[#lines + 1] = { left = Show(left and left:GetText()), right = Show(right and right:GetText()) }
    end
    scanner:Hide()
    return lines
end

-- The recipe name without its "Pattern: " style prefix, e.g. "Pearly Boots".
local function CraftedName(name)
    if type(name) ~= "string" or isSecret(name) then return nil end
    return name:match("^[^:]+:%s*(.+)$")
end

local function ProbeItem(index)
    local row = { index = index }
    local link = GetMerchantItemLink and GetMerchantItemLink(index)
    row.link = Show(link)
    row.legacyInfo = Try(GetMerchantItemInfo, index)
    if C_MerchantFrame and C_MerchantFrame.GetItemInfo then
        local ok, info = pcall(C_MerchantFrame.GetItemInfo, index)
        row.merchantInfo = ok and Flat(info) or ("ERROR " .. Show(info))
    end
    row.costCount = Try(GetMerchantItemCostInfo, index)
    row.costItem1 = Try(GetMerchantItemCostItem, index, 1)
    row.itemID = Try(GetMerchantItemID, index)
    if type(link) == "string" and not isSecret(link) then
        row.instant = Try(C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant, link)
        row.info = Try(C_Item and C_Item.GetItemInfo or GetItemInfo, link)
        row.spell = Try(C_Item and C_Item.GetItemSpell or GetItemSpell, link)
        local name = (C_Item and C_Item.GetItemInfo or GetItemInfo)(link)
        local crafted = CraftedName(name)
        if crafted then
            row.craftedName = crafted
            -- Only works if the crafted item is already in the client cache.
            row.craftedInfo = Try(C_Item and C_Item.GetItemInfo or GetItemInfo, crafted)
        end
        if C_TransmogCollection then
            row.appearanceKnown = Try(C_TransmogCollection.PlayerHasTransmog, link)
            row.sourceInfo = Try(C_TransmogCollection.GetItemInfo, link)
        end
    end
    row.tooltip = TooltipLines(index)
    return row
end

local function Run()
    if not MerchantFrame or not MerchantFrame:IsShown() then
        Print("open a merchant first")
        return
    end
    local count = GetMerchantNumItems()
    local run = {
        time = date("%Y-%m-%d %H:%M:%S"),
        build = Try(GetBuildInfo),
        merchant = Show(UnitName("npc")),
        count = count,
        apis = {
            C_TooltipInfo = C_TooltipInfo ~= nil,
            C_MerchantFrame = C_MerchantFrame ~= nil,
            C_TransmogCollection = C_TransmogCollection ~= nil,
            C_TradeSkillUI = C_TradeSkillUI ~= nil,
            TooltipDataProcessor = TooltipDataProcessor ~= nil,
            ITEM_SPELL_KNOWN = Show(ITEM_SPELL_KNOWN),
            perPage = Show(MERCHANT_ITEMS_PER_PAGE),
        },
        items = {},
    }
    for index = 1, count do
        run.items[index] = ProbeItem(index)
    end
    RSProbeDB = RSProbeDB or {}
    RSProbeDB.runs = RSProbeDB.runs or {}
    table.insert(RSProbeDB.runs, run)
    while #RSProbeDB.runs > 20 do table.remove(RSProbeDB.runs, 1) end
    local first = run.items[1]
    Print(string.format("%s: %d items saved (run %d). /reload to write the file.",
        run.merchant, count, #RSProbeDB.runs))
    if first then
        Print("item 1: " .. first.link .. ", tooltip via " .. Show(first.tooltip.source)
            .. ", " .. #first.tooltip .. " lines")
    end
end

SLASH_RSPROBE1 = "/rsp"
SlashCmdList.RSPROBE = Run
