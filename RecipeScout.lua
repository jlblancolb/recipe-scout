-- RecipeScout: shows what each recipe on a merchant makes (Feet, Chest, Potion...)
-- and marks the ones you already know in green. Only reads data and adds its own
-- textures/font strings on top of the merchant buttons; never changes Blizzard code.

local _, ns = ...
local Recipe = ns.Recipe

local KNOWN = { 0.25, 1.0, 0.25 }
local CHECK_TEXTURE = "Interface\\RaidFrame\\ReadyCheck-Ready"

local overlays = {}

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

    overlays[slot] = {
        frame = overlay, strip = strip, label = label, check = check, row = row, tint = tint, glow = glow,
    }
    return overlays[slot]
end

local function HideAll()
    for _, overlay in pairs(overlays) do
        overlay.frame:Hide()
        overlay.tint:Hide()
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
            if info and (info.label or info.known) then
                overlay.label:SetText(info.label or "")
                overlay.strip:SetShown(info.label ~= nil)
                if info.known then
                    overlay.label:SetTextColor(KNOWN[1], KNOWN[2], KNOWN[3])
                else
                    overlay.label:SetTextColor(1, 1, 1)
                end
                overlay.check:SetShown(info.known)
                overlay.tint:SetShown(info.known)
                overlay.frame:Show()
            else
                overlay.frame:Hide()
                overlay.tint:Hide()
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
SlashCmdList.RECIPESCOUT = function()
    if not (MerchantFrame and MerchantFrame:IsShown()) then
        DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffRecipeScout|r open a merchant to see recipe slots.")
        return
    end
    local shown = 0
    for index = 1, GetMerchantNumItems() or 0 do
        local info = Recipe.ForMerchantItem(index)
        if info then
            shown = shown + 1
            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff66ccffRecipeScout|r %d: %s%s", index,
                info.label or "?", info.known and " |cff40ff40(known)|r" or ""))
        end
    end
    DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffRecipeScout|r " .. shown .. " recipes on this merchant.")
end
