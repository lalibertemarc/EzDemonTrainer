-- Reads what your demon knows whenever it's out (its spellbook, kept per demon so the others stay listed),
-- notices the demon trainer (a merchant selling pet grimoires): opens the list beside it and tags each grimoire
-- Known / Learn / Skip / Lv N, adds the same to grimoire tooltips anywhere, and says on level-up which new
-- grimoires opened. Warlocks only; never buys or uses anything.
local addonName, ns = ...

local PET_BANK = (Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Pet) or 1
local PLAYER_BANK = (Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player) or 0
local TAG = "|cff9482c9EzDemonTrainer|r: "

local function Print(msg)
    (DEFAULT_CHAT_FRAME or ChatFrame1):AddMessage(TAG .. msg)
end
ns.Print = Print

local function Readable(v)
    return v ~= nil and not (issecretvalue and issecretvalue(v))
end

---------------------------------------------------------------------------
-- Spells
---------------------------------------------------------------------------
function ns.SpellName(id)
    local name
    if C_Spell and C_Spell.GetSpellName then
        name = C_Spell.GetSpellName(id)
    elseif GetSpellInfo then
        name = GetSpellInfo(id)
    end
    return Readable(name) and name or nil
end

function ns.SpellIcon(id)
    local icon
    if C_Spell and C_Spell.GetSpellTexture then
        icon = C_Spell.GetSpellTexture(id)
    elseif GetSpellTexture then
        icon = GetSpellTexture(id)
    end
    return Readable(icon) and icon or nil
end

-- The ability's name in the client's language (English until the spell data is in).
function ns.AbilityName(a)
    if not a.localName then a.localName = ns.SpellName(a.ranks[1].spell) end
    return a.localName or a.name
end

function ns.DemonName(d)
    if not d.localName then
        local summon = ns.SpellName(d.summon)
        -- "Summon Imp" → "Imp" in English; other languages keep our English name.
        d.localName = summon and summon:match("^Summon (.+)$") or (summon and d.name)
    end
    return d.localName or d.name
end

-- Do you have this demon (its summon spell)?
function ns.HasDemon(d)
    if C_SpellBook and C_SpellBook.IsSpellKnown then
        local ok, known = pcall(C_SpellBook.IsSpellKnown, d.summon, PLAYER_BANK)
        if ok and Readable(known) and known then return true end
    end
    if IsPlayerSpell then
        local ok, known = pcall(IsPlayerSpell, d.summon)
        if ok and Readable(known) and known then return true end
    end
    if IsSpellKnown then
        local ok, known = pcall(IsSpellKnown, d.summon)
        if ok and Readable(known) and known then return true end
    end
    return false
end

---------------------------------------------------------------------------
-- The pet's spellbook
---------------------------------------------------------------------------
local scanned = {} -- spell IDs seen in the pet's spellbook on the last read

local function Mark(id)
    if Readable(id) and type(id) == "number" and id > 0 then
        scanned[id] = true
        scanned[id % 0x1000000] = true -- pet action IDs carry flags above the spell ID
    end
end

-- By name + "Rank N" when the IDs don't match ours (another client build).
local function MarkByName(name, sub)
    if not (Readable(name) and Readable(sub)) then return end
    for _, list in pairs(ns.ABILITIES) do
        for _, a in ipairs(list) do
            if ns.AbilityName(a) == name then
                local rank = tonumber(sub and sub:match("(%d+)")) or 1
                local r = a.ranks[rank]
                if r then scanned[r.spell] = true end
            end
        end
    end
end

local function NumPetSpells()
    local n
    if C_SpellBook and C_SpellBook.HasPetSpells then
        n = C_SpellBook.HasPetSpells()
    elseif HasPetSpells then
        n = HasPetSpells()
    end
    return Readable(n) and tonumber(n) or 0
end

local function ScanBook()
    wipe(scanned)
    for i = 1, NumPetSpells() do
        if C_SpellBook and C_SpellBook.GetSpellBookItemInfo then
            local ok, info = pcall(C_SpellBook.GetSpellBookItemInfo, i, PET_BANK)
            if ok and type(info) == "table" then
                Mark(info.spellID)
                Mark(info.actionID)
                MarkByName(info.name, info.subName)
            end
        elseif GetSpellBookItemInfo then
            local ok, _, id = pcall(GetSpellBookItemInfo, i, "pet")
            if ok then Mark(id) end
            local ok2, name, sub = pcall(GetSpellBookItemName, i, "pet")
            if ok2 then MarkByName(name, sub) end
        end
    end
end

local function PetKnows(id)
    if C_SpellBook and C_SpellBook.IsSpellKnown then
        local ok, known = pcall(C_SpellBook.IsSpellKnown, id, PET_BANK)
        if ok and Readable(known) and known then return true end
    elseif IsSpellKnown then
        local ok, known = pcall(IsSpellKnown, id, true)
        if ok and Readable(known) and known then return true end
    end
    return scanned[id] == true
end

-- Which of your demons is out: its key and ability group, or nil.
local function CurrentDemon()
    if not UnitExists("pet") then return end
    ScanBook()
    local group = ns.GroupOf(PetKnows)
    if not group then return end
    if group == "succubus" and not ns.ERA then
        local family = UnitCreatureFamily("pet")
        local sex = UnitSex("pet")
        if (Readable(family) and family == "Incubus")
            or (not (Readable(family) and family == "Succubus") and Readable(sex) and sex == 2) then
            return "incubus", group
        end
    end
    return group, group
end

function ns.ReadPet()
    local key, group = CurrentDemon()
    ns.current = key
    if key then
        local ranks, count = ns.ReadRanks(group, PetKnows)
        if count > 0 then -- 0 = the spellbook isn't filled in yet; another event follows
            local rec = ns.char.demons[key] or {}
            rec.ranks, rec.t = ranks, time()
            local level = UnitLevel("pet")
            if Readable(level) then rec.level = level end
            ns.char.demons[key] = rec
        end
    end
    ns.Redraw()
end

local waiting
local function ReadSoon()
    if waiting then return end
    waiting = true
    C_Timer.After(ns.SETTLE, function()
        waiting = false
        ns.ReadPet()
    end)
end

-- What a demon knows ({ [abilityKey] = rank }), or nil if it was never read.
function ns.Ranks(key)
    local rec = ns.char and ns.char.demons[key]
    return rec and rec.ranks
end

function ns.Level()
    return ns.level or UnitLevel("player") or 1
end

-- The demon a group's grimoire is for: the one out, else the one of that group last read, else the first.
function ns.DemonFor(group)
    local pick, t
    for _, d in ipairs(ns.Demons(ns.ERA)) do
        if d.group == group then
            if d.key == ns.current then return d end
            local rec = ns.char.demons[d.key]
            if not pick or (rec and rec.t and rec.t > (t or 0)) then pick, t = d, rec and rec.t end
        end
    end
    return pick
end

-- State of a grimoire (item ID) for its demon: state, demon, entry. nil if not a pet grimoire.
function ns.GrimoireState(itemID)
    local e = ns.ForItem(itemID)
    if not e then return end
    local d = ns.DemonFor(e.group)
    local ranks = ns.Ranks(d.key)
    local known = ranks and (ranks[e.ability.key] or 0) or nil
    local state = ns.RankState(e.ability, e.rank, known, ns.Level())
    if not ns.HasDemon(d) and state ~= "later" then state = "nodemon" end
    return state, d, e
end

---------------------------------------------------------------------------
-- Grimoire tooltips (bags, the trainer, the auction house)
---------------------------------------------------------------------------
local STATE_TIP = {
    known = { "%s knows it.", 0.4, 0.9, 0.4 },
    learn = { "%s can learn it: the best rank you can use now.", 1, 0.82, 0 },
    maybe = { "%s can learn it, unless it already has (summon it once so I can read what it knows).", 1, 0.82, 0 },
    skip = { "Not needed: a higher rank you can use replaces it.", 0.6, 0.6, 0.6 },
    later = { "Too low: needs level %d.", 1, 0.4, 0.4 },
    nodemon = { "You don't have the %s yet.", 0.6, 0.6, 0.6 },
}

function ns.StateText(state, d, e)
    local tip = STATE_TIP[state]
    if not tip then return end
    local arg
    if state == "later" then
        arg = e.info.level
    elseif state == "nodemon" then
        arg = ns.DemonName(d)
    else
        arg = "Your " .. ns.DemonName(d)
    end
    return tip[1]:format(arg), tip[2], tip[3], tip[4]
end

local function AddGrimoireLines(tooltip, itemID)
    if ns.off or not Readable(itemID) then return end
    local state, d, e = ns.GrimoireState(itemID)
    if not state then return end
    local text, r, g, b = ns.StateText(state, d, e)
    local ranks = ns.Ranks(d.key)
    local known = ranks and ranks[e.ability.key]
    tooltip:AddLine(" ")
    tooltip:AddLine(text, r, g, b, true)
    if known and known > 0 and #e.ability.ranks > 1 then
        tooltip:AddLine(("%s knows Rank %d of %d."):format(ns.DemonName(d), known, #e.ability.ranks), 0.8, 0.8, 0.8)
    end
    tooltip:Show()
end

local function HookTooltips()
    if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
            if type(data) == "table" then AddGrimoireLines(tooltip, data.id) end
        end)
    elseif GameTooltip and GameTooltip.HookScript then
        GameTooltip:HookScript("OnTooltipSetItem", function(tooltip)
            local _, link = tooltip:GetItem()
            if Readable(link) then AddGrimoireLines(tooltip, tonumber(link:match("item:(%d+)"))) end
        end)
    end
end

---------------------------------------------------------------------------
-- The demon trainer
---------------------------------------------------------------------------
local function ItemIDOf(link)
    return Readable(link) and tonumber(link:match("item:(%d+)")) or nil
end

-- How many pet grimoires this merchant sells (0 = not a demon trainer).
local function GrimoiresSold()
    local count = 0
    for i = 1, (GetMerchantNumItems() or 0) do
        if ns.ForItem(ItemIDOf(GetMerchantItemLink(i))) then count = count + 1 end
    end
    return count
end

local TAGS = {
    known = { "Known", 0.4, 0.9, 0.4 },
    learn = { "Learn", 1, 0.82, 0 },
    maybe = { "Learn?", 1, 0.82, 0 },
    skip = { "Skip", 0.6, 0.6, 0.6 },
    nodemon = { "No demon", 0.6, 0.6, 0.6 },
}
local tags = {} -- our font strings on the merchant's item buttons, by slot

function ns.TagMerchant()
    local perPage = MERCHANT_ITEMS_PER_PAGE or 10
    local buying = not MerchantFrame or MerchantFrame.selectedTab == nil or MerchantFrame.selectedTab == 1
    local page = MerchantFrame and MerchantFrame.page or 1
    for i = 1, perPage do
        local button = _G["MerchantItem" .. i .. "ItemButton"]
        local text, r, g, b
        if button and buying and not ns.off and ns.db.tags ~= false then
            local state, _, e = ns.GrimoireState(ItemIDOf(GetMerchantItemLink((page - 1) * perPage + i)))
            if state == "later" then
                text, r, g, b = "Lv " .. e.info.level, 1, 0.4, 0.4
            elseif state then
                text, r, g, b = TAGS[state][1], TAGS[state][2], TAGS[state][3], TAGS[state][4]
            end
        end
        local fs = tags[i]
        if text and not fs then
            fs = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            fs:SetPoint("BOTTOM", button, "TOP", 0, 1)
            fs:SetShadowOffset(1, -1)
            tags[i] = fs
        end
        if fs then
            fs:SetText(text or "")
            if text then fs:SetTextColor(r, g, b) end
        end
    end
end

local function MerchantShown()
    if ns.off then return end
    ns.atTrainer = GrimoiresSold() > 0
    if ns.atTrainer and ns.db.atTrainer ~= false then ns.ShowAtTrainer() end
    ns.TagMerchant()
end

---------------------------------------------------------------------------
-- Level-up note
---------------------------------------------------------------------------
local function LevelNote(level)
    if ns.db.notify == false then return end
    local new = ns.NewAt(level)
    if not new then return end
    local parts = {}
    for _, d in ipairs(ns.Demons(ns.ERA)) do
        local list = new[d.group]
        -- One line per group: the Incubus shares the Succubus' grimoires.
        if list and ns.HasDemon(d) and ns.DemonFor(d.group) == d then
            local names = {}
            for _, e in ipairs(list) do names[#names + 1] = ns.RankName(e.ability, e.rank, ns.AbilityName(e.ability)) end
            parts[#parts + 1] = ns.DemonName(d) .. ": " .. table.concat(names, ", ")
        end
    end
    if #parts > 0 then
        Print("new at the demon trainer: " .. table.concat(parts, "; ") .. ". |cff888888/grimoire|r")
    end
end

---------------------------------------------------------------------------
-- Slash, binding, drawer
---------------------------------------------------------------------------
local function OnOff(word, current)
    if word == "on" then return true elseif word == "off" then return false end
    return not current
end

local function Slash(msg)
    if ns.off then return Print("only for warlocks.") end
    local cmd, rest = strtrim(msg or ""):lower():match("^(%S*)%s*(.-)$")
    if cmd == "" then return ns.Toggle() end
    if ns.ALIASES[cmd] and ns.Demon(ns.ALIASES[cmd]) then
        local d = ns.Demon(ns.ALIASES[cmd])
        if ns.ERA and d.forever then return Print(d.name .. " isn't in this game.") end
        return ns.Open(d.key)
    end
    if cmd == "trainer" then
        ns.db.atTrainer = OnOff(rest, ns.db.atTrainer ~= false)
        Print("open at the demon trainer: " .. (ns.db.atTrainer and "on" or "off"))
    elseif cmd == "notify" then
        ns.db.notify = OnOff(rest, ns.db.notify ~= false)
        Print("level-up note: " .. (ns.db.notify and "on" or "off"))
    elseif cmd == "tags" then
        ns.db.tags = OnOff(rest, ns.db.tags ~= false)
        Print("tags on the trainer's grimoires: " .. (ns.db.tags and "on" or "off"))
        if MerchantFrame and MerchantFrame:IsShown() then ns.TagMerchant() end
    elseif cmd == "forget" then
        local key = ns.ALIASES[rest]
        if rest == "all" then
            wipe(ns.char.demons)
            Print("forgot what every demon knows. Summon them again to read it.")
        elseif key then
            ns.char.demons[key] = nil
            Print("forgot what your " .. ns.DemonName(ns.Demon(key)) .. " knows.")
        else
            return Print("/grimoire forget <imp|voidwalker|succubus|incubus|felhunter|all>")
        end
        ns.ReadPet()
    elseif cmd == "reset" then
        ns.db.win = nil
        ns.PlaceWindow()
        Print("window put back in the middle.")
    else
        Print("/grimoire — the list. /grimoire <demon> — open its page.")
        Print("/grimoire trainer|notify|tags [on|off], /grimoire forget <demon|all>, /grimoire reset")
    end
end

BINDING_HEADER_EZDEMONTRAINER = "EzDemonTrainer"
BINDING_NAME_EZDEMONTRAINER_TOGGLE = "Show/hide the demon grimoire list"

function EzDemonTrainer_Toggle()
    if ns.off then return Print("only for warlocks.") end
    ns.Toggle()
end

function EzDemonTrainer_OnAddonCompartmentClick()
    EzDemonTrainer_Toggle()
end

SLASH_EZDEMONTRAINER1 = "/grimoire"
SLASH_EZDEMONTRAINER2 = "/demontrainer"
SLASH_EZDEMONTRAINER3 = "/ezdemontrainer"
SlashCmdList.EZDEMONTRAINER = Slash

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function(_, event, arg1)
    if event == "PLAYER_LOGIN" then
        EzDemonTrainerDB = EzDemonTrainerDB or {}
        EzDemonTrainerCharDB = EzDemonTrainerCharDB or {}
        ns.db, ns.char = EzDemonTrainerDB, EzDemonTrainerCharDB
        ns.char.demons = ns.char.demons or {}
        local _, class = UnitClass("player")
        if class ~= "WARLOCK" then
            ns.off = true -- stands down: no events, no tooltips, no tags
            return
        end
        HookTooltips()
        if hooksecurefunc and MerchantFrame_UpdateMerchantInfo then
            hooksecurefunc("MerchantFrame_UpdateMerchantInfo", ns.TagMerchant)
        end
        for _, e in ipairs({ "UNIT_PET", "PET_BAR_UPDATE", "SPELLS_CHANGED", "PLAYER_LEVEL_UP",
            "MERCHANT_SHOW", "MERCHANT_UPDATE", "MERCHANT_CLOSED" }) do
            f:RegisterEvent(e)
        end
        ns.Login()
        ReadSoon()
    elseif event == "UNIT_PET" then
        if arg1 == "player" then ReadSoon() end
    elseif event == "PET_BAR_UPDATE" or event == "SPELLS_CHANGED" then
        ReadSoon()
    elseif event == "PLAYER_LEVEL_UP" then
        ns.level = arg1
        LevelNote(arg1)
        ns.Redraw()
    elseif event == "MERCHANT_SHOW" then
        C_Timer.After(0, MerchantShown) -- the item list fills in right after
    elseif event == "MERCHANT_UPDATE" then
        if ns.atTrainer then ns.TagMerchant() end
    elseif event == "MERCHANT_CLOSED" then
        ns.atTrainer = false
        ns.LeftTrainer()
    end
end)

ns.addonName = addonName
