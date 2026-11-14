std = "lua51"
max_line_length = false
self = false
exclude_files = { ".release/", "tests/" }

globals = {
    "EzGrimoireDB",
    "EzGrimoireCharDB",
    "EzGrimoire_Toggle",
    "EzGrimoire_OnAddonCompartmentClick",
    "BINDING_HEADER_EZGRIMOIRE",
    "BINDING_NAME_EZGRIMOIRE_TOGGLE",
    "SLASH_EZGRIMOIRE1",
    "SLASH_EZGRIMOIRE2",
    "SlashCmdList",
    "UISpecialFrames",
}

read_globals = {
    -- Lua / WoW utility
    "strtrim", "tinsert", "wipe", "time", "issecretvalue", "hooksecurefunc", "Enum", "_G",
    -- Frames & UI
    "CreateFrame", "UIParent", "ChatFrame1", "DEFAULT_CHAT_FRAME", "GameTooltip", "TooltipDataProcessor",
    "MerchantFrame", "MerchantFrame_UpdateMerchantInfo", "MERCHANT_ITEMS_PER_PAGE",
    -- Namespaced APIs
    "C_Spell", "C_SpellBook", "C_Timer", "C_CurrencyInfo",
    -- Global APIs
    "GetBuildInfo", "GetSpellInfo", "GetSpellTexture", "IsPlayerSpell", "IsSpellKnown", "HasPetSpells",
    "GetSpellBookItemInfo", "GetSpellBookItemName", "UnitExists", "UnitLevel", "UnitClass", "UnitSex",
    "UnitCreatureFamily", "GetMerchantNumItems", "GetMerchantItemLink", "GetCoinTextureString",
}
