std = "lua51"
max_line_length = false
self = false
exclude_files = { ".release/", "tests/" }

globals = {
    "EzDemonTrainerDB",
    "EzDemonTrainerCharDB",
    "EzDemonTrainer_Toggle",
    "EzDemonTrainer_OnAddonCompartmentClick",
    "BINDING_HEADER_EZDEMONTRAINER",
    "BINDING_NAME_EZDEMONTRAINER_TOGGLE",
    "SLASH_EZDEMONTRAINER1",
    "SLASH_EZDEMONTRAINER2",
    "SLASH_EZDEMONTRAINER3",
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
