std = "lua51"
max_line_length = 120
exclude_files = { "probe/data" }

local wow = {
    "C_Item", "C_MerchantFrame", "C_Timer", "C_TooltipInfo", "CreateFrame", "DEFAULT_CHAT_FRAME", "GameTooltip",
    "GetItemInfoInstant", "GetMerchantItemID", "GetMerchantNumItems", "hooksecurefunc", "issecretvalue",
    "ITEM_SPELL_KNOWN", "MERCHANT_ITEMS_PER_PAGE", "MerchantFrame_Update", "STANDARD_TEXT_FONT", "wipe",
}

files["Recipe.lua"] = { read_globals = wow }
files["Panel.lua"] = { globals = { "RecipeScoutDB", "MerchantFrame" }, read_globals = wow }
files["RecipeScout.lua"] = {
    globals = { "SLASH_RECIPESCOUT1", "SLASH_RECIPESCOUT2", "SlashCmdList" },
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
files["tests"] = { allow_defined_top = true, ignore = { "11", "12", "13", "211", "212", "213", "431", "432" } }
