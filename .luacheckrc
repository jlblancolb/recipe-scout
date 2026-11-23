std = "lua51"
max_line_length = 120
exclude_files = { "probe/data" }

local wow = {
    "C_Item", "C_MerchantFrame", "C_Timer", "C_TooltipInfo", "CreateFrame", "DEFAULT_CHAT_FRAME", "GameTooltip",
    "GetItemInfoInstant", "GetMerchantItemID", "GetMerchantNumItems", "hooksecurefunc", "issecretvalue",
    "ITEM_SPELL_KNOWN", "ITEM_MIN_SKILL", "MERCHANT_ITEMS_PER_PAGE", "MerchantFrame_Update", "STANDARD_TEXT_FONT",
    "wipe", "TRANSMOGRIFY_TOOLTIP_APPEARANCE_UNKNOWN", "TRANSMOGRIFY_TOOLTIP_APPEARANCE_KNOWN",
    "TRANSMOGRIFY_TOOLTIP_ITEM_UNKNOWN_APPEARANCE_KNOWN",
}

files["Recipe.lua"] = { read_globals = { "RecipeScoutDB", unpack(wow) } }
files["Alts.lua"] = {
    globals = { "RecipeScoutDB" },
    read_globals = { "C_TradeSkillUI", "Enum", "GetNumSkillLines", "GetNumTradeSkills", "GetProfessionInfo",
        "GetProfessions", "GetRealmName", "GetNormalizedRealmName", "GetNumCrafts", "GetCraftDisplaySkillLine",
        "GetCraftInfo", "GetCraftItemLink", "date", "GetSkillLineInfo", "GetTradeSkillInfo", "GetTradeSkillItemLink",
        "GetTradeSkillLine", "GetTradeSkillRecipeLink", "ItemRefTooltip", "RAID_CLASS_COLORS", "TooltipDataProcessor",
        "UnitClass", "UnitName", "time", "unpack", unpack(wow) },
}
files["Options.lua"] = {
    globals = { "RecipeScoutDB", "RecipeScout_OnAddonCompartmentClick", "RecipeScout_OnAddonCompartmentEnter",
        "RecipeScout_OnAddonCompartmentLeave" },
    read_globals = { "Settings", "WOW_PROJECT_ID", "WOW_PROJECT_CLASSIC", "InCombatLockdown", unpack(wow) },
}
files["Panel.lua"] = {
    globals = { "RecipeScoutDB", "MerchantFrame", "StaticPopupDialogs" },
    read_globals = { "StaticPopup_Show", "BuyMerchantItem", "GetMoneyString", "GetMerchantItemCostInfo",
        "GetMerchantItemCostItem", "PURCHASE", "CANCEL", unpack(wow) },
}
files["RecipeScout.lua"] = {
    globals = { "SLASH_RECIPESCOUT1", "SLASH_RECIPESCOUT2", "SlashCmdList", "RecipeScoutDB" },
    read_globals = { "MerchantFrame", unpack(wow) },
}
files["probe"] = {
    globals = { "RSProbeDB", "SLASH_RSPROBE1", "SlashCmdList" },
    read_globals = { "C_Item", "C_MerchantFrame", "C_TooltipInfo", "C_TradeSkillUI", "C_TransmogCollection",
        "CreateFrame", "DEFAULT_CHAT_FRAME", "GetBuildInfo", "GetItemInfo", "GetItemInfoInstant", "GetItemSpell",
        "GetMerchantItemCostInfo", "GetMerchantItemCostItem", "GetMerchantItemID", "GetMerchantItemInfo",
        "GetMerchantItemLink", "GetMerchantNumItems", "issecretvalue", "ITEM_SPELL_KNOWN", "MERCHANT_ITEMS_PER_PAGE",
        "MerchantFrame", "TooltipDataProcessor", "UIParent", "UnitName", "date" },
}

-- Tests install WoW API mocks as globals and read them back.
files["tests"] = { allow_defined_top = true, max_line_length = 140, ignore = { "11", "12", "13", "143", "211", "212", "213", "431", "432" } }
