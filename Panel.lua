-- Side panel next to the merchant: every recipe on all pages, filterable by slot,
-- name and "hide known". Clicking a row jumps to its merchant page and highlights it.

local _, ns = ...
local Recipe = ns.Recipe

local WIDTH, ROW_HEIGHT, CHIP_W, CHIP_H = 240, 18, 72, 20
local KNOWN = { 0.25, 1.0, 0.25 }

local Panel = {}
ns.Panel = Panel

local filter = { slot = nil, search = "" }
local entries = {}
local panel, list, content, search, hideKnown, toggle, countText
local chips, rows = {}, {}

local function DB()
    RecipeScoutDB = RecipeScoutDB or {}
    if RecipeScoutDB.panelShown == nil then RecipeScoutDB.panelShown = true end
    return RecipeScoutDB
end

local function Plain(text)
    if type(text) ~= "string" or (issecretvalue and issecretvalue(text)) then return nil end
    return text
end

-- Everything sold here that is a recipe, with its name, icon and whether you can use it.
local function Collect()
    wipe(entries)
    for index = 1, GetMerchantNumItems() or 0 do
        local info = Recipe.ForMerchantItem(index)
        if info then
            local name, icon, usable
            if C_MerchantFrame and C_MerchantFrame.GetItemInfo then
                local ok, item = pcall(C_MerchantFrame.GetItemInfo, index)
                if ok and item then name, icon, usable = item.name, item.texture, item.isUsable end
            end
            name = Plain(name) or ""
            entries[#entries + 1] = {
                index = index, label = info.label or "?", known = info.known, usable = usable ~= false,
                altKnown = not info.known and info.alts ~= nil and #info.alts.known > 0,
                alts = info.alts and info.alts.known,
                lookOwned = info.look == "owned",
                name = name, short = name:match("^[^:]+:%s*(.+)$") or name, icon = icon,
            }
        end
    end
end

local function Matches(entry)
    if filter.slot and entry.label ~= filter.slot then return false end
    if DB().hideKnown and entry.known then return false end
    if DB().hideLooks and entry.lookOwned then return false end
    if filter.search ~= "" and not entry.name:lower():find(filter.search, 1, true) then return false end
    return true
end

local function JumpTo(index)
    local perPage = MERCHANT_ITEMS_PER_PAGE or 10
    MerchantFrame.page = math.ceil(index / perPage)
    ns.highlight = index
    if MerchantFrame_Update then MerchantFrame_Update() else ns.Update() end
    C_Timer.After(2.5, function()
        if ns.highlight == index then
            ns.highlight = nil
            ns.Update()
        end
    end)
end

local function Row(i)
    if rows[i] then return rows[i] end
    local row = CreateFrame("Button", nil, content)
    row:SetSize(WIDTH - 40, ROW_HEIGHT)
    row:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_HEIGHT)
    row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(ROW_HEIGHT - 2, ROW_HEIGHT - 2)
    row.icon:SetPoint("LEFT", 0, 0)
    row.check = row:CreateTexture(nil, "OVERLAY")
    row.check:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
    row.check:SetSize(12, 12)
    row.check:SetPoint("BOTTOMRIGHT", row.icon, "BOTTOMRIGHT", 3, -2)
    row.look = row:CreateTexture(nil, "OVERLAY")
    row.look:SetTexture(ns.LOOK_TEXTURE)
    row.look:SetSize(13, 13)
    row.look:SetPoint("RIGHT", -2, 0)
    row.slot = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    row.slot:SetPoint("RIGHT", -18, 0)
    row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.name:SetPoint("LEFT", row.icon, "RIGHT", 4, 0)
    row.name:SetPoint("RIGHT", row.slot, "LEFT", -4, 0)
    row.name:SetJustifyH("LEFT")
    row.name:SetWordWrap(false)
    row:SetScript("OnClick", function(self) JumpTo(self.index) end)
    row:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        pcall(GameTooltip.SetMerchantItem, GameTooltip, self.index)
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function() GameTooltip:Hide() end)
    rows[i] = row
    return row
end

-- Slot buttons: "All" plus one per label on this merchant, with counts.
local function LayoutChips()
    local counts, order = {}, {}
    for _, entry in ipairs(entries) do
        if not counts[entry.label] then order[#order + 1] = entry.label end
        counts[entry.label] = (counts[entry.label] or 0) + 1
    end
    table.sort(order)
    table.insert(order, 1, false)
    if filter.slot and not counts[filter.slot] then filter.slot = nil end

    -- Flow layout: each button as wide as its text, wrapping onto new rows.
    local x, y, maxX = 8, 0, WIDTH - 8
    for i, label in ipairs(order) do
        local chip = chips[i]
        if not chip then
            chip = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
            chip:SetScript("OnClick", function(self)
                filter.slot = self.label or nil
                Panel.Refresh()
            end)
            chips[i] = chip
        end
        chip.label = label
        chip:SetText(label and string.format("%s (%d)", label, counts[label]) or string.format("All (%d)", #entries))
        local fontString = chip:GetFontString()
        local width = CHIP_W
        if fontString then
            fontString:SetFont(STANDARD_TEXT_FONT, 9)
            local textWidth = fontString:GetStringWidth()
            if type(textWidth) == "number" and textWidth > 0 then width = math.max(44, math.ceil(textWidth) + 16) end
        end
        if x + width > maxX and x > 8 then
            x, y = 8, y + CHIP_H
        end
        chip:SetSize(width, CHIP_H)
        chip:ClearAllPoints()
        chip:SetPoint("TOPLEFT", x, -98 - y)
        x = x + width
        if (filter.slot or false) == label then chip:LockHighlight() else chip:UnlockHighlight() end
        chip:Show()
    end
    for i = #order + 1, #chips do chips[i]:Hide() end
    return 98 + y + CHIP_H + 4
end

function Panel.Refresh()
    if not panel or not panel:IsShown() then return end
    local top = LayoutChips()
    list:ClearAllPoints()
    list:SetPoint("TOPLEFT", 8, -top)
    list:SetPoint("BOTTOMRIGHT", -28, 8)

    local shown = 0
    for _, entry in ipairs(entries) do
        if Matches(entry) then
            shown = shown + 1
            local row = Row(shown)
            row.index = entry.index
            row.icon:SetTexture(entry.icon)
            row.check:SetShown(entry.known or entry.altKnown)
            row.check:SetDesaturated(entry.altKnown)
            if entry.altKnown then row.check:SetVertexColor(1, 0.82, 0) else row.check:SetVertexColor(1, 1, 1) end
            row.name:SetText(entry.short)
            if entry.known then
                row.name:SetTextColor(KNOWN[1], KNOWN[2], KNOWN[3])
            elseif entry.altKnown then
                row.name:SetTextColor(1, 0.82, 0)
            elseif not entry.usable then
                row.name:SetTextColor(1, 0.3, 0.3)
            else
                row.name:SetTextColor(1, 1, 1)
            end
            row.look:SetShown(entry.lookOwned)
            if entry.altKnown then
                row.slot:SetText(ns.AltNames(entry.alts) .. " |cff808080·|r " .. entry.label)
            else
                row.slot:SetText(entry.label)
            end
            row:Show()
        end
    end
    for i = shown + 1, #rows do rows[i]:Hide() end
    content:SetSize(WIDTH - 40, math.max(1, shown * ROW_HEIGHT))
    countText:SetText(string.format("%d of %d", shown, #entries))
end

local function Build()
    panel = CreateFrame("Frame", "RecipeScoutPanel", MerchantFrame, "BackdropTemplate")
    panel:SetWidth(WIDTH)
    panel:SetPoint("TOPLEFT", MerchantFrame, "TOPRIGHT", 2, 0)
    panel:SetPoint("BOTTOMLEFT", MerchantFrame, "BOTTOMRIGHT", 2, 0)
    if panel.SetBackdrop then
        panel:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 14, insets = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        panel:SetBackdropColor(0.05, 0.05, 0.07, 0.95)
    end

    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", 10, -10)
    title:SetText("RecipeScout")
    countText = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    countText:SetPoint("TOPRIGHT", -28, -12)

    search = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    search:SetSize(WIDTH - 26, 20)
    search:SetPoint("TOPLEFT", 16, -30)
    search:SetAutoFocus(false)
    search:SetScript("OnTextChanged", function(self)
        filter.search = (Plain(self:GetText()) or ""):lower()
        Panel.Refresh()
    end)
    search:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    local hint = search:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("LEFT", 2, 0)
    hint:SetText("Search names...")
    search:HookScript("OnTextChanged", function(self) hint:SetShown(self:GetText() == "") end)

    hideKnown = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    hideKnown:SetSize(22, 22)
    hideKnown:SetPoint("TOPLEFT", 8, -56)
    local hideText = hideKnown:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hideText:SetPoint("LEFT", hideKnown, "RIGHT", 2, 0)
    hideText:SetText("Hide known")
    local hideLooks = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    hideLooks:SetSize(22, 22)
    hideLooks:SetPoint("TOPLEFT", 112, -56)
    local looksText = hideLooks:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    looksText:SetPoint("LEFT", hideLooks, "RIGHT", 2, 0)
    looksText:SetText("Hide |T" .. ns.LOOK_TEXTURE .. ":13|t owned looks")
    hideLooks:SetScript("OnClick", function(self)
        DB().hideLooks = self:GetChecked() and true or false
        Panel.Refresh()
    end)
    panel.hideLooks = hideLooks

    local key = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    key:SetPoint("TOPLEFT", 12, -80)
    key:SetText("|cff40ff40Green|r: you know it  |cffffd100Yellow|r: an alt does")
    hideKnown:SetScript("OnClick", function(self)
        DB().hideKnown = self:GetChecked() and true or false
        Panel.Refresh()
    end)

    list = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    content = CreateFrame("Frame", nil, list)
    content:SetSize(WIDTH - 40, 1)
    list:SetScrollChild(content)

    panel:SetScript("OnShow", function()
        hideKnown:SetChecked(DB().hideKnown)
        panel.hideLooks:SetChecked(DB().hideLooks)
        Panel.Refresh()
    end)
end

-- Small tab outside the merchant's right edge, shown only while the panel is closed.
local function BuildToggle()
    toggle = CreateFrame("Button", nil, MerchantFrame, "UIPanelButtonTemplate")
    toggle:SetSize(70, 20)
    toggle:SetText("Recipes")
    toggle:SetPoint("TOPLEFT", MerchantFrame, "TOPRIGHT", 2, -4)
    toggle:SetScript("OnClick", function()
        DB().panelShown = true
        Panel.Update()
    end)
    local close = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
    close:SetSize(22, 22)
    close:SetPoint("TOPRIGHT", -2, -2)
    close:SetScript("OnClick", function()
        DB().panelShown = false
        Panel.Update()
    end)
end

-- Called whenever the merchant changes: rebuild the list, show the panel only if there are recipes.
function Panel.Update()
    if not MerchantFrame or not MerchantFrame:IsShown() then return end
    if not panel then
        Build()
        BuildToggle()
    end
    Collect()
    local has = #entries > 0 and (MerchantFrame.selectedTab or 1) == 1
    toggle:SetShown(has and not DB().panelShown)
    if has and DB().panelShown then
        if panel:IsShown() then Panel.Refresh() else panel:Show() end
    else
        panel:Hide()
    end
end

function Panel.OnMerchantShow()
    filter.slot, filter.search = nil, ""
    if search then search:SetText("") end
    Panel.Update()
end
