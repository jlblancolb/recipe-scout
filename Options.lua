-- Settings page and addon compartment (minimap addon menu) entry.
-- Forever (Mainline API): Blizzard's native settings page. A client missing part
-- of that API gets a simple canvas page with the same options.
-- Same approach as DistanceToTarget and YardsToKm.
local addonName, ns = ...

local TITLE = "RecipeScout"

-- { key, label, tooltip }
local OPTIONS = {
    { "enabled", "Enable RecipeScout", "Turn off to hide every badge, mark and the panel." },
    { "badges", "Slot badges", "Show the slot (Feet, Chest, Off Hand…) on every recipe icon at merchants." },
    { "known", "Mark known recipes", "Green check and a green row for recipes this character knows." },
    { "alts", "Mark recipes your alts know", "Yellow check and the character's name for recipes another "
        .. "character on your account knows. Open each crafter's profession window once to record them." },
    { "looks", "Mark owned appearances", "Transmog icon on gear recipes whose appearance you already collected." },
    { "tooltip", "Alt lines in recipe tooltips", "Add \"Known by\", \"Can learn\" and \"Skill too low\" to recipe "
        .. "tooltips at merchants, in bags and at the auction house." },
    { "panelShown", "Show the filter panel", "Show the side panel with filters next to any merchant "
        .. "that sells recipes. The Filters button on the merchant opens it too." },
}

local category
local nativeSettings = {}
local canvasControls = {}
local openAfterCombat = false

local function DB()
    RecipeScoutDB = RecipeScoutDB or {}
    return RecipeScoutDB
end

function ns.ApplyDefaults()
    local db = DB()
    for key, value in pairs(ns.DEFAULTS) do
        if db[key] == nil then db[key] = value end
    end
end

local function UpdateControls()
    local db = DB()
    for key, setting in pairs(nativeSettings) do
        if setting:GetValue() ~= db[key] then setting:SetValue(db[key]) end
    end
    for key, box in pairs(canvasControls) do
        box:SetChecked(db[key] and true or false)
    end
end
ns.UpdateControls = UpdateControls

-- Every change goes through here: settings page, compartment, panel buttons, /rs.
function ns.SetSetting(key, value)
    DB()[key] = value
    if ns.Update then ns.Update() end
    if ns.Panel then ns.Panel.Update() end
    UpdateControls()
end

local function CreateNative()
    if WOW_PROJECT_ID and WOW_PROJECT_CLASSIC and WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then return nil end
    for _, name in ipairs({ "RegisterVerticalLayoutCategory", "RegisterAddOnSetting", "CreateCheckbox",
        "RegisterAddOnCategory" }) do
        if not Settings[name] then return nil end
    end
    local varTypes = Settings.VarType or {}
    local page = Settings.RegisterVerticalLayoutCategory(TITLE)
    local registered = {}
    for _, option in ipairs(OPTIONS) do
        local key = option[1]
        local setting = Settings.RegisterAddOnSetting(page, addonName .. "_" .. key, key, DB(),
            varTypes.Boolean or "boolean", option[2], ns.DEFAULTS[key])
        setting:SetValueChangedCallback(function(_, value)
            ns.SetSetting(key, value)
        end)
        Settings.CreateCheckbox(page, setting, option[3])
        registered[key] = setting
    end
    Settings.RegisterAddOnCategory(page)
    nativeSettings = registered
    return page
end

local function CreateCanvas()
    local panel = CreateFrame("Frame")
    panel.name = TITLE
    panel:Hide()
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText(TITLE)
    local description = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    description:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    description:SetText("What each merchant recipe makes, and who already knows it.")

    local previous = description
    for _, option in ipairs(OPTIONS) do
        local key = option[1]
        local box = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
        box:SetSize(26, 26)
        box:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, previous == description and -16 or -6)
        local label = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        label:SetPoint("LEFT", box, "RIGHT", 6, 0)
        label:SetText(option[2])
        box:SetScript("OnClick", function(self) ns.SetSetting(key, self:GetChecked() and true or false) end)
        box:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(option[2])
            GameTooltip:AddLine(option[3], 1, 1, 1, true)
            GameTooltip:Show()
        end)
        box:SetScript("OnLeave", function() GameTooltip:Hide() end)
        canvasControls[key] = box
        previous = box
    end

    local page = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
    Settings.RegisterAddOnCategory(page)
    return page
end

-- Called on ADDON_LOADED, after the saved variables have their defaults.
function ns.CreateSettings()
    if type(Settings) ~= "table" or not Settings.RegisterAddOnCategory then return end
    local ok, page = pcall(CreateNative)
    if ok and page then
        category = page
        return
    elseif not ok then
        nativeSettings = {}
        ns.Say("using the basic settings page (" .. tostring(page) .. ")")
    end
    if Settings.RegisterCanvasLayoutCategory then
        category = CreateCanvas()
        UpdateControls()
    end
end

-- The settings panel is protected UI, so it opens after combat.
function ns.OpenSettings()
    if not category or not Settings.OpenToCategory then
        ns.Say("no settings page in this client; /rs help lists the commands")
    elseif InCombatLockdown() then
        openAfterCombat = true
        ns.Say("settings will open when combat ends")
    else
        Settings.OpenToCategory(category:GetID())
    end
end

function ns.AfterCombat()
    if openAfterCombat then
        openAfterCombat = false
        ns.OpenSettings()
    end
end

-- Addon compartment, named in the TOC. Clients without it ignore those fields.
function RecipeScout_OnAddonCompartmentClick(_, mouseButton)
    if mouseButton == "RightButton" then
        ns.SetSetting("enabled", not ns.Opt("enabled"))
        ns.Say(ns.Opt("enabled") and "on" or "off")
    else
        ns.OpenSettings()
    end
end

function RecipeScout_OnAddonCompartmentEnter(_, button)
    GameTooltip:SetOwner(button, "ANCHOR_LEFT")
    GameTooltip:SetText(TITLE)
    GameTooltip:AddLine(ns.Opt("enabled") and "On" or "Off", 1, 1, 1)
    GameTooltip:AddLine("Left-click: settings", 0.7, 0.7, 0.7)
    GameTooltip:AddLine("Right-click: turn on or off", 0.7, 0.7, 0.7)
    GameTooltip:Show()
end

function RecipeScout_OnAddonCompartmentLeave()
    GameTooltip:Hide()
end
