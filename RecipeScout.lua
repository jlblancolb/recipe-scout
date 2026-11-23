-- RecipeScout: shows what each recipe on a merchant makes (Feet, Chest, Potion...)
-- and marks the ones you already know in green. Only reads data and adds its own
-- textures/font strings on top of the merchant buttons; never changes Blizzard code.

local _, ns = ...
local Recipe = ns.Recipe

local KNOWN = { 0.25, 1.0, 0.25 }
local ALT = { 1.0, 0.82, 0.0 }
local CHECK_TEXTURE = "Interface\\RaidFrame\\ReadyCheck-Ready"
local LOOK_TEXTURE = "Interface\\CURSOR\\Transmogrify"
ns.LOOK_TEXTURE = LOOK_TEXTURE

local overlays = {}

-- "Durga", or "Durga +2" when several characters know it.
function ns.AltNames(names)
    if not names or #names == 0 then return "" end
    if #names == 1 then return names[1] end
    return names[1] .. " |cffffd100+" .. (#names - 1) .. "|r"
end

local function ItemButton(slot)
    local row = _G["MerchantItem" .. slot]
    return row, (row and (row.ItemButton or _G["MerchantItem" .. slot .. "ItemButton"]))
end

local function Overlay(slot)
    if overlays[slot] then return overlays[slot] end
    local row, button = ItemButton(slot)
    if not button then return nil end
    local overlay = CreateFrame("Frame", nil, button)
    overlay:SetAllPoints(button)
    overlay:SetFrameLevel(button:GetFrameLevel() + 5)

    local strip = overlay:CreateTexture(nil, "ARTWORK")
    strip:SetPoint("BOTTOMLEFT", 0, 0)
    strip:SetPoint("BOTTOMRIGHT", 0, 0)
    strip:SetHeight(11)
    strip:SetColorTexture(0, 0, 0, 0.75)

    local label = overlay:CreateFontString(nil, "OVERLAY")
    label:SetFont(STANDARD_TEXT_FONT, 8, "OUTLINE")
    label:SetPoint("BOTTOM", 0, 1)

    local check = overlay:CreateTexture(nil, "OVERLAY")
    check:SetTexture(CHECK_TEXTURE)
    check:SetSize(14, 14)
    check:SetPoint("TOPLEFT", -3, 3)

    -- Known: a soft green wash over the whole merchant row (names keep their quality colour,
    -- which is already green for uncommon recipes, so the name alone can't mean "known").
    local tint = CreateFrame("Frame", nil, row)
    tint:SetAllPoints(row)
    local wash = tint:CreateTexture(nil, "BACKGROUND")
    wash:SetAllPoints(tint)
    wash:SetColorTexture(KNOWN[1], KNOWN[2], KNOWN[3], 0.16)

    -- Jump target from the panel: a short-lived glow on the icon.
    local glow = overlay:CreateTexture(nil, "OVERLAY")
    glow:SetTexture("Interface\\Buttons\\CheckButtonHilight")
    glow:SetBlendMode("ADD")
    glow:SetAllPoints(overlay)

    -- Appearance already collected: the transmog icon in the top-right corner.
    local look = overlay:CreateTexture(nil, "OVERLAY")
    look:SetTexture(LOOK_TEXTURE)
    look:SetSize(16, 16)
    look:SetPoint("TOPRIGHT", 4, 4)

    -- Who else knows it: a name next to the price, e.g. "Durga" or "Durga +1".
    local whoFrame = CreateFrame("Frame", nil, row)
    whoFrame:SetAllPoints(row)
    local who = whoFrame:CreateFontString(nil, "OVERLAY")
    who:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
    who:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -4, 5)
    who:SetJustifyH("RIGHT")

    overlays[slot] = {
        frame = overlay, strip = strip, label = label, check = check, row = row, tint = tint, glow = glow, who = who,
        look = look,
    }
    return overlays[slot]
end

local function HideAll()
    for _, overlay in pairs(overlays) do
        overlay.frame:Hide()
        overlay.tint:Hide()
        overlay.who:SetText("")
    end
end

local lastTab
local function Update()
    local tab = MerchantFrame and MerchantFrame.selectedTab or 1
    if tab ~= lastTab then
        lastTab = tab
        ns.Panel.Update() -- buyback tab hides the panel, merchant tab brings it back
    end
    if not MerchantFrame or not MerchantFrame:IsShown() or tab ~= 1 then
        HideAll()
        return
    end
    local perPage = MERCHANT_ITEMS_PER_PAGE or 10
    local page = MerchantFrame.page or 1
    local count = GetMerchantNumItems() or 0
    for slot = 1, perPage do
        local index = (page - 1) * perPage + slot
        local info = index <= count and Recipe.ForMerchantItem(index) or nil
        local overlay = Overlay(slot)
        if overlay then
            local altKnown = info and not info.known and info.alts and #info.alts.known > 0
            if info and (info.label or info.known or altKnown or info.look == "owned") then
                overlay.label:SetText(info.label or "")
                overlay.strip:SetShown(info.label ~= nil)
                local color = info.known and KNOWN or altKnown and ALT or nil
                if color then
                    overlay.label:SetTextColor(color[1], color[2], color[3])
                else
                    overlay.label:SetTextColor(1, 1, 1)
                end
                -- Green check: you know it. Yellow check: an alt does.
                overlay.check:SetDesaturated(altKnown and true or false)
                if altKnown then
                    overlay.check:SetVertexColor(ALT[1], ALT[2], ALT[3])
                else
                    overlay.check:SetVertexColor(1, 1, 1)
                end
                overlay.check:SetShown(info.known or altKnown)
                overlay.look:SetShown(info.look == "owned")
                overlay.tint:SetShown(info.known)
                overlay.who:SetText(altKnown and ns.AltNames(info.alts.known) or "")
                overlay.frame:Show()
            else
                overlay.frame:Hide()
                overlay.tint:Hide()
                overlay.who:SetText("")
            end
            overlay.glow:SetShown(ns.highlight ~= nil and ns.highlight == index)
        end
    end
end
ns.Update = Update

-- Blizzard redraws the merchant page in these; we run right after.
for _, name in ipairs({ "MerchantFrame_UpdateMerchantInfo", "MerchantFrame_Update" }) do
    if type(_G[name]) == "function" then hooksecurefunc(name, Update) end
end

-- Item data can arrive late, and learning a recipe changes "known": refresh once, shortly after.
local pending = false
local function Refresh()
    if pending then return end
    pending = true
    C_Timer.After(0.1, function()
        pending = false
        Update()
        ns.Panel.Update()
    end)
end

local events = CreateFrame("Frame")
for _, event in ipairs({ "MERCHANT_SHOW", "MERCHANT_UPDATE", "GET_ITEM_INFO_RECEIVED", "NEW_RECIPE_LEARNED",
    "LEARNED_SPELL_IN_SKILL_LINE", "LEARNED_SPELL_IN_TAB" }) do
    pcall(events.RegisterEvent, events, event)
end
events:SetScript("OnEvent", function(_, event)
    if event == "GET_ITEM_INFO_RECEIVED" and not (MerchantFrame and MerchantFrame:IsShown()) then return end
    if event == "MERCHANT_SHOW" then ns.Panel.OnMerchantShow() end
    Refresh()
end)

SLASH_RECIPESCOUT1 = "/rs"
SLASH_RECIPESCOUT2 = "/recipescout"
local function Say(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffRecipeScout|r " .. message)
end

SlashCmdList.RECIPESCOUT = function(message)
    local command, rest = (message or ""):match("^%s*(%S*)%s*(.-)%s*$")
    command = (command or ""):lower()
    if command == "alts" then
        local lines = ns.Alts.Summary()
        if #lines == 0 then Say("no characters recorded yet: open a profession window on each crafter.") end
        for _, line in ipairs(lines) do Say(line) end
        return
    elseif command == "debug" then
        local scan = RecipeScoutDB and RecipeScoutDB.lastScan
        if not scan then
            Say("no profession scan yet: open a profession window first.")
            return
        end
        local keys = {}
        for key in pairs(scan) do keys[#keys + 1] = key end
        table.sort(keys)
        for _, key in ipairs(keys) do Say(key .. ": " .. tostring(scan[key])) end
        return
    elseif command == "forget" then
        local key = ns.Alts.Forget(rest)
        Say(key and ("forgot " .. key) or "no character called '" .. (rest or "") .. "'. /rs alts lists them.")
        return
    elseif command ~= "" then
        Say("/rs lists recipes on the open merchant, /rs alts lists your characters, /rs forget <name> removes one.")
        return
    end
    if not (MerchantFrame and MerchantFrame:IsShown()) then
        Say("open a merchant to see recipe slots. /rs alts lists your characters.")
        return
    end
    local shown = 0
    for index = 1, GetMerchantNumItems() or 0 do
        local info = Recipe.ForMerchantItem(index)
        if info then
            shown = shown + 1
            local alts = ""
            if info.alts and #info.alts.known > 0 then
                alts = " |cffffd100(alt: " .. table.concat(info.alts.known, ", ") .. ")|r"
            end
            local known = info.known and " |cff40ff40(known)|r" or ""
            local look = info.look == "owned" and " |cffb48cff(look owned)|r" or ""
            Say(string.format("%d: %s%s%s%s", index, info.label or "?", known, alts, look))
        end
    end
    Say(shown .. " recipes on this merchant.")
end
