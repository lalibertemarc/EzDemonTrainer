-- Plain Lua 5.1 checks for EzGrimoire: the data, the rules (Logic.lua), then the whole addon on a stubbed game
-- API (pet read, window, trainer tags, tooltips, level-up note, slash). lua tests/grimoire.lua (in the addon folder).
local checks, failed = 0, 0
local function check(ok, what)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL: " .. what)
    end
end
local function eq(a, b, what)
    check(a == b, what .. ": got " .. tostring(a) .. ", wanted " .. tostring(b))
end

local build = 16001
_G.GetBuildInfo = function() return "1.60.1", "0", "", build end
local function Load(files)
    local ns = {}
    for _, file in ipairs(files) do assert(loadfile(file))("EzGrimoire", ns) end
    return ns
end

---------------------------------------------------------------------------
-- Data
---------------------------------------------------------------------------
local ns = Load({ "Data.lua", "Logic.lua" })
local spells, items, grimoires = {}, {}, 0
for group, list in pairs(ns.ABILITIES) do
    eq(#list, 4, group .. " has four abilities")
    for _, a in ipairs(list) do
        check(#a.ranks >= 1 and #a.ranks <= 7, a.key .. " rank count fits the window")
        for i, r in ipairs(a.ranks) do
            check(not spells[r.spell], a.key .. " spell " .. r.spell .. " unique")
            spells[r.spell] = true
            if r.item then
                grimoires = grimoires + 1
                check(not items[r.item], a.key .. " item " .. r.item .. " unique")
                items[r.item] = true
                check(r.price and r.price > 0, a.key .. " rank " .. i .. " has a price")
            else
                eq(i, 1, a.key .. ": only rank 1 can come with the demon")
            end
            if i > 1 then check(r.level > a.ranks[i - 1].level, a.key .. " levels rise with rank") end
        end
    end
end
eq(grimoires, 59, "pet grimoires in the data")
for _, d in ipairs(ns.DEMONS) do check(ns.ABILITIES[d.group], d.key .. " has an ability list") end
eq(#ns.Demons(false), 5, "Forever: five demons (Incubus)")
eq(#ns.Demons(true), 4, "Era: no Incubus")

---------------------------------------------------------------------------
-- Rules
---------------------------------------------------------------------------
local torment = ns.ABILITIES.voidwalker[1]
eq(torment.key, "torment", "first voidwalker ability")
eq(ns.BestRank(torment, 9), 0, "no rank before the demon")
eq(ns.BestRank(torment, 35), 3, "best torment at 35")
-- Knows rank 2, level 35: rank 3 (30) is the one to buy.
eq(ns.RankState(torment, 1, 2, 35), "known", "rank 1 known")
eq(ns.RankState(torment, 2, 2, 35), "known", "rank 2 known")
eq(ns.RankState(torment, 3, 2, 35), "learn", "rank 3 to buy")
eq(ns.RankState(torment, 4, 2, 35), "later", "rank 4 later")
-- Knows only rank 1 at 45: rank 2 and 3 are skipped for rank 4.
eq(ns.RankState(torment, 2, 1, 45), "skip", "rank 2 skipped")
eq(ns.RankState(torment, 3, 1, 45), "skip", "rank 3 skipped")
eq(ns.RankState(torment, 4, 1, 45), "learn", "rank 4 to buy")
-- Never read: the starter is known, the best one "maybe".
eq(ns.RankState(torment, 1, nil, 35), "known", "starter comes with it")
eq(ns.RankState(torment, 3, nil, 35), "maybe", "never read: maybe")
eq(ns.RankState(torment, 2, nil, 35), "skip", "never read: lower skipped")
-- One-rank ability.
local seduction = ns.ABILITIES.succubus[3]
eq(seduction.key, "seduction", "seduction")
eq(ns.RankState(seduction, 1, 0, 25), "later", "seduction at 26")
eq(ns.RankState(seduction, 1, 0, 26), "learn", "seduction learnable")
eq(ns.RankName(seduction, 1), "Seduction", "one-rank name")
eq(ns.RankName(torment, 5), "Torment (Rank 5)", "rank name")

local learn, total = ns.ToLearn("voidwalker", { torment = 2, sacrifice = 2, consumeshadows = 0, suffering = 0 }, 26)
local names = {}
for _, e in ipairs(learn) do names[#names + 1] = ns.RankName(e.ability, e.rank) end
eq(table.concat(names, ", "), "Consume Shadows (Rank 2), Suffering (Rank 1)", "voidwalker to buy at 26")
eq(total, 4000 + 3000, "their price")
local at, up = ns.NextUp("voidwalker", 26)
eq(at, 30, "next voidwalker level")
eq(#up, 1, "one grimoire at 30")
eq(ns.NextUp("imp", 60), nil, "nothing above 60")

local new = ns.NewAt(40)
check(new and new.voidwalker and #new.voidwalker == 2, "two voidwalker grimoires at 40 (Torment 4, Sacrifice 4)")
eq(ns.NewAt(3), nil, "nothing at 3")

local known = { [3716] = true, [7809] = true, [7812] = true }
eq(ns.GroupOf(function(id) return known[id] end), "voidwalker", "group from spells")
eq(ns.GroupOf(function() return false end), nil, "unknown pet")
local ranks = ns.ReadRanks("voidwalker", function(id) return known[id] end)
eq(ranks.torment, 2, "read torment rank")
eq(ranks.sacrifice, 1, "read sacrifice rank")
eq(ranks.suffering, 0, "read suffering none")

local e = ns.ForItem(16349)
check(e and e.ability.key == "torment" and e.rank == 5, "item → Torment 5")
eq(ns.ForItem(1), nil, "not a grimoire")

eq(ns.Money(26000), "2g 60s", "money")
eq(ns.Money(100), "1s", "money silver")
eq(ns.Money(0), "0c", "money zero")
eq(ns.Money(10005), "1g 5c", "money gold copper")

---------------------------------------------------------------------------
-- The whole addon on a stubbed API
---------------------------------------------------------------------------
local printed = {}
local function Stub(name)
    local o = { _name = name, _scripts = {}, _shown = false, _events = {}, _fs = {}, _lines = {} }
    return setmetatable(o, { __index = function(t, k)
        if k == "SetScript" then return function(self, ev, fn) self._scripts[ev] = fn end end
        if k == "Show" then return function(self)
            self._shown = true
            if self._scripts.OnShow then self._scripts.OnShow(self) end
        end end
        if k == "Hide" then return function(self)
            local was = self._shown
            self._shown = false
            if was and self._scripts.OnHide then self._scripts.OnHide(self) end
        end end
        if k == "SetShown" then return function(self, v) if v then self:Show() else self:Hide() end end end
        if k == "IsShown" then return function(self) return self._shown end end
        if k == "SetText" then return function(self, v) self._text = v end end
        if k == "GetText" then return function(self) return self._text end end
        if k == "SetChecked" then return function(self, v) self._checked = v end end
        if k == "GetChecked" then return function(self) return self._checked end end
        if k == "CreateFontString" or k == "CreateTexture" then return function(self)
            local fs = Stub(k)
            table.insert(self._fs, fs)
            return fs
        end end
        if k == "RegisterEvent" then return function(self, ev) self._events[ev] = true end end
        if k == "GetStringWidth" or k == "GetLeft" or k == "GetTop" then return function() return 10 end end
        if k == "AddLine" then return function(self, text) table.insert(self._lines, text) end end
        return function() end
    end })
end

local frames = {}
_G.CreateFrame = function(_, name)
    local f = Stub(name)
    frames[#frames + 1] = f
    if name then _G[name] = f end
    return f
end
_G.UIParent, _G.ChatFrame1 = Stub("UIParent"), Stub("ChatFrame1")
_G.DEFAULT_CHAT_FRAME = { AddMessage = function(_, m) printed[#printed + 1] = m end }
_G.GameTooltip = Stub("GameTooltip")
_G.UISpecialFrames, _G.SlashCmdList = {}, {}
_G.tinsert, _G.wipe = table.insert, function(t) for k in pairs(t) do t[k] = nil end return t end
_G.strtrim = function(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end
_G.time = os.time
_G.Enum = { SpellBookSpellBank = { Player = 0, Pet = 1 }, TooltipDataType = { Item = 0 } }
local timers = {}
_G.C_Timer = { After = function(_, fn) timers[#timers + 1] = fn end }
local function RunTimers()
    while #timers > 0 do table.remove(timers, 1)() end
end

local level, class = 35, "WARLOCK"
local petSpells, playerSpells, petOut, petSex = {}, { [688] = true, [697] = true }, false, 3
_G.UnitLevel = function() return level end
_G.UnitClass = function() return "Warlock", class end
_G.UnitExists = function(u) return u == "pet" and petOut end
_G.UnitSex = function() return petSex end
_G.UnitCreatureFamily = function() return nil end
_G.C_SpellBook = {
    IsSpellKnown = function(id, bank) if bank == 1 then return petSpells[id] == true end return playerSpells[id] == true end,
    HasPetSpells = function() return petOut and 3 or nil end,
    GetSpellBookItemInfo = function() return nil end,
}
_G.C_Spell = { GetSpellName = function() return nil end, GetSpellTexture = function() return 136000 end }
local tooltipCall
_G.TooltipDataProcessor = { AddTooltipPostCall = function(_, fn) tooltipCall = fn end }
local hooked = {}
_G.hooksecurefunc = function(name, fn) hooked[name] = fn end
_G.MerchantFrame_UpdateMerchantInfo = function() end
_G.MERCHANT_ITEMS_PER_PAGE = 10
_G.MerchantFrame = Stub("MerchantFrame")
_G.MerchantFrame.page, _G.MerchantFrame.selectedTab = 1, 1
local merchant = { 16346, 16347, 16348, 16351, 2901 } -- Torment 2/3/4, Sacrifice 1, a pick
_G.GetMerchantNumItems = function() return #merchant end
_G.GetMerchantItemLink = function(i) return merchant[i] and ("|Hitem:%d::|h[x]|h"):format(merchant[i]) end
for i = 1, 10 do _G["MerchantItem" .. i .. "ItemButton"] = Stub("MerchantItem" .. i .. "ItemButton") end

ns = Load({ "Data.lua", "Logic.lua", "Core.lua", "UI.lua" })
local events = frames[1]
local OnEvent = events._scripts.OnEvent
OnEvent(events, "PLAYER_LOGIN")
check(events._events.UNIT_PET and events._events.MERCHANT_SHOW, "warlock: events registered")
check(hooked.MerchantFrame_UpdateMerchantInfo, "merchant hook")
check(tooltipCall, "tooltip hook")
RunTimers()

-- Voidwalker out, knows Torment 2 and Sacrifice 1.
petOut, petSpells = true, { [3716] = true, [7809] = true, [7812] = true }
OnEvent(events, "UNIT_PET", "player")
RunTimers()
eq(ns.current, "voidwalker", "voidwalker read")
eq(EzGrimoireCharDB.demons.voidwalker.ranks.torment, 2, "saved torment rank")

-- Window
SlashCmdList.EZGRIMOIRE("")
local window = _G.EzGrimoireFrame
check(window and window:IsShown(), "slash opens the window")
SlashCmdList.EZGRIMOIRE("imp")
SlashCmdList.EZGRIMOIRE("felhunter")
SlashCmdList.EZGRIMOIRE("incubus")
SlashCmdList.EZGRIMOIRE("void")

-- Trainer: window beside it, tags on the grimoires.
OnEvent(events, "MERCHANT_SHOW")
RunTimers()
check(ns.atTrainer, "grimoire merchant = trainer")
check(window:IsShown() and window.byTrainer, "window opens beside the trainer")
local function Tag(i)
    local fs = _G["MerchantItem" .. i .. "ItemButton"]._fs
    return fs[1] and fs[1]._text
end
eq(Tag(1), "Known", "Torment 2 tag")
eq(Tag(2), "Learn", "Torment 3 tag")
eq(Tag(3), "Lv 40", "Torment 4 tag")
eq(Tag(4), "Known", "Sacrifice 1 tag")
check(Tag(5) == nil or Tag(5) == "", "no tag on a pick")
_G.MerchantFrame.selectedTab = 2 -- buyback tab: tags cleared
hooked.MerchantFrame_UpdateMerchantInfo()
eq(Tag(1), "", "no tags on buyback")
_G.MerchantFrame.selectedTab = 1
OnEvent(events, "MERCHANT_CLOSED")
check(not window:IsShown(), "window closes with the trainer when it opened by itself")

-- Tooltip on Torment 3 (learn) and on a pick (nothing).
local tip = Stub("tip")
tooltipCall(tip, { id = 16347 })
local joined = table.concat(tip._lines, "|")
check(joined:find("can learn it", 1, true), "tooltip says learn: " .. joined)
check(joined:find("knows Rank 2 of 6", 1, true), "tooltip says known rank: " .. joined)
local tip2 = Stub("tip2")
tooltipCall(tip2, { id = 2901 })
eq(#tip2._lines, 0, "no lines on other items")
local tip3 = Stub("tip3")
tooltipCall(tip3, { id = 16384 }) -- Tainted Blood 1 (32): no Felhunter
check(table.concat(tip3._lines, "|"):find("don't have the Felhunter", 1, true), "no felhunter yet")

-- Level-up note.
printed = {}
OnEvent(events, "PLAYER_LEVEL_UP", 40)
check(printed[1] and printed[1]:find("Voidwalker: Torment %(Rank 4%), Sacrifice %(Rank 4%)"), "level-up note: " .. tostring(printed[1]))
check(not printed[1]:find("Felhunter", 1, true), "no note for a demon you don't have")

-- Incubus detection (Forever): male pet with succubus spells.
petSpells, petSex = { [7814] = true }, 2
OnEvent(events, "PET_BAR_UPDATE")
RunTimers()
eq(ns.current, "incubus", "incubus read")
petSex = 3
OnEvent(events, "PET_BAR_UPDATE")
RunTimers()
eq(ns.current, "succubus", "succubus read")

-- Pet dismissed; slash commands.
petOut = false
OnEvent(events, "UNIT_PET", "player")
RunTimers()
eq(ns.current, nil, "no pet")
SlashCmdList.EZGRIMOIRE("trainer off")
eq(EzGrimoireDB.atTrainer, false, "trainer off")
SlashCmdList.EZGRIMOIRE("forget voidwalker")
eq(EzGrimoireCharDB.demons.voidwalker, nil, "forgot voidwalker")
SlashCmdList.EZGRIMOIRE("forget all")
SlashCmdList.EZGRIMOIRE("reset")
SlashCmdList.EZGRIMOIRE("help")
_G.EzGrimoire_Toggle()

-- Era client: no Incubus tab; another class stands down.
build, class = 11509, "PRIEST"
EzGrimoireDB, EzGrimoireCharDB = nil, nil
frames = {}
local era = Load({ "Data.lua", "Logic.lua", "Core.lua", "UI.lua" })
check(era.ERA, "era flag")
frames[1]._scripts.OnEvent(frames[1], "PLAYER_LOGIN")
check(era.off, "priest: stands down")
eq(frames[1]._events.UNIT_PET, nil, "priest: no events")

print(("%d checks, %d failed"):format(checks, failed))
if failed > 0 then os.exit(1) end
