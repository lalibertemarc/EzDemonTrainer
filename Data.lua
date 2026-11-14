-- Static data: the warlock's demons and every ability their grimoires teach.
-- The ability table was read from WoW Forever's own game data (build 1.60.1.70707 on wago.tools: ItemSparse →
-- ItemXItemEffect → ItemEffect → SpellEffect → SpellName/Spell); Classic Era's grimoires are the same items.
-- Each rank: spell = the pet spell ID, level = the grimoire's "Requires level", item = the grimoire's item ID,
-- price = its base vendor price in copper (reputation discounts lower it). A rank with no item comes with the demon.
local _, ns = ...

ns.ERA = select(4, GetBuildInfo()) < 16000

-- Demons in tab order. group = which ability list it learns (the Incubus learns the Succubus' grimoires).
-- summon = the warlock's summon spell (known = you have that demon), level = when you can first get it.
ns.DEMONS = {
    { key = "imp", name = "Imp", group = "imp", summon = 688, level = 1 },
    { key = "voidwalker", name = "Voidwalker", group = "voidwalker", summon = 697, level = 10 },
    { key = "succubus", name = "Succubus", group = "succubus", summon = 712, level = 20 },
    { key = "incubus", name = "Incubus", group = "succubus", summon = 713, level = 20, forever = true },
    { key = "felhunter", name = "Felhunter", group = "felhunter", summon = 691, level = 30 },
}

ns.ABILITIES = {
    imp = {
        { key = "firebolt", name = "Firebolt", ranks = {
            { spell = 3110, level = 1 }, -- comes with the demon
            { spell = 7799, level = 8, item = 16302, price = 100 },
            { spell = 7800, level = 18, item = 16316, price = 1500 },
            { spell = 7801, level = 28, item = 16317, price = 5000 },
            { spell = 7802, level = 38, item = 16318, price = 10000 },
            { spell = 11762, level = 48, item = 16319, price = 14000 },
            { spell = 11763, level = 58, item = 16320, price = 24000 },
        } },
        { key = "bloodpact", name = "Blood Pact", ranks = {
            { spell = 6307, level = 4, item = 16321, price = 100 },
            { spell = 7804, level = 14, item = 16322, price = 900 },
            { spell = 7805, level = 26, item = 16323, price = 4000 },
            { spell = 11766, level = 38, item = 16324, price = 10000 },
            { spell = 11767, level = 50, item = 16325, price = 15000 },
        } },
        { key = "fireshield", name = "Fire Shield", ranks = {
            { spell = 2947, level = 14, item = 16326, price = 900 },
            { spell = 8316, level = 24, item = 16327, price = 3000 },
            { spell = 8317, level = 34, item = 16328, price = 8000 },
            { spell = 11770, level = 44, item = 16329, price = 12000 },
            { spell = 11771, level = 54, item = 16330, price = 20000 },
        } },
        { key = "phaseshift", name = "Phase Shift", ranks = {
            { spell = 4511, level = 12, item = 16331, price = 600 },
        } },
    },
    voidwalker = {
        { key = "torment", name = "Torment", ranks = {
            { spell = 3716, level = 10 }, -- comes with the demon
            { spell = 7809, level = 20, item = 16346, price = 2000 },
            { spell = 7810, level = 30, item = 16347, price = 6000 },
            { spell = 7811, level = 40, item = 16348, price = 11000 },
            { spell = 11774, level = 50, item = 16349, price = 15000 },
            { spell = 11775, level = 60, item = 16350, price = 26000 },
        } },
        { key = "sacrifice", name = "Sacrifice", ranks = {
            { spell = 7812, level = 16, item = 16351, price = 1200 },
            { spell = 19438, level = 24, item = 16352, price = 3000 },
            { spell = 19440, level = 32, item = 16353, price = 7000 },
            { spell = 19441, level = 40, item = 16354, price = 11000 },
            { spell = 19442, level = 48, item = 16355, price = 14000 },
            { spell = 19443, level = 56, item = 16356, price = 22000 },
        } },
        { key = "consumeshadows", name = "Consume Shadows", ranks = {
            { spell = 17767, level = 18, item = 16357, price = 1500 },
            { spell = 17850, level = 26, item = 16358, price = 4000 },
            { spell = 17851, level = 34, item = 16359, price = 8000 },
            { spell = 17852, level = 42, item = 16360, price = 11000 },
            { spell = 17853, level = 50, item = 16361, price = 15000 },
            { spell = 17854, level = 58, item = 16362, price = 24000 },
        } },
        { key = "suffering", name = "Suffering", ranks = {
            { spell = 17735, level = 24, item = 16363, price = 3000 },
            { spell = 17750, level = 36, item = 16364, price = 9000 },
            { spell = 17751, level = 48, item = 16365, price = 14000 },
            { spell = 17752, level = 60, item = 16366, price = 26000 },
        } },
    },
    succubus = {
        { key = "lashofpain", name = "Lash of Pain", ranks = {
            { spell = 7814, level = 20 }, -- comes with the demon
            { spell = 7815, level = 28, item = 16368, price = 5000 },
            { spell = 7816, level = 36, item = 16371, price = 9000 },
            { spell = 11778, level = 44, item = 16372, price = 12000 },
            { spell = 11779, level = 52, item = 16373, price = 18000 },
            { spell = 11780, level = 60, item = 16374, price = 26000 },
        } },
        { key = "soothingkiss", name = "Soothing Kiss", ranks = {
            { spell = 6360, level = 22, item = 16375, price = 2500 },
            { spell = 7813, level = 34, item = 16376, price = 8000 },
            { spell = 11784, level = 46, item = 16377, price = 13000 },
            { spell = 11785, level = 58, item = 16378, price = 24000 },
        } },
        { key = "seduction", name = "Seduction", ranks = {
            { spell = 6358, level = 26, item = 16379, price = 4000 },
        } },
        { key = "lesserinvisibility", name = "Lesser Invisibility", ranks = {
            { spell = 7870, level = 32, item = 16380, price = 7000 },
        } },
    },
    felhunter = {
        { key = "devourmagic", name = "Devour Magic", ranks = {
            { spell = 19505, level = 30 }, -- comes with the demon
            { spell = 19731, level = 38, item = 16381, price = 10000 },
            { spell = 19734, level = 46, item = 16382, price = 13000 },
            { spell = 19736, level = 54, item = 16383, price = 20000 },
        } },
        { key = "taintedblood", name = "Tainted Blood", ranks = {
            { spell = 19478, level = 32, item = 16384, price = 7000 },
            { spell = 19655, level = 40, item = 16385, price = 11000 },
            { spell = 19656, level = 48, item = 16386, price = 14000 },
            { spell = 19660, level = 56, item = 16387, price = 22000 },
        } },
        { key = "spelllock", name = "Spell Lock", ranks = {
            { spell = 19244, level = 36, item = 16388, price = 9000 },
            { spell = 19647, level = 52, item = 16389, price = 18000 },
        } },
        { key = "paranoia", name = "Paranoia", ranks = {
            { spell = 19480, level = 42, item = 16390, price = 11000 },
        } },
    },
}

ns.ICON = "Interface\\Icons\\INV_Misc_Book_06"
ns.SETTLE = 0.3 -- seconds to let the pet's spellbook fill in after a change before reading it
