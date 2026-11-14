-- The list: one tab per demon, one row per ability, one cell per rank showing the level it needs, coloured by
-- what that demon knows (green known, gold buy this one, grey skip/later). Own flat frames only (Blizzard
-- menus crash in combat on Forever); nothing here is protected. Opens beside the demon trainer by itself.
local _, ns = ...

local PAD = 8
local ICON_X, NAME_X, NAME_W = PAD, PAD + 24, 128
local CELL_X, CELL_W, CELL_H, CELL_GAP = PAD + 156, 36, 20, 2
local MAX_RANKS = 7
local W = CELL_X + MAX_RANKS * (CELL_W + CELL_GAP) + PAD
local ROW_H = 26
local MAX_ROWS = 4
local H = 330
local GOLD = { 1, 0.82, 0, 1 }
local WHITE = "Interface\\Buttons\\WHITE8x8"
local FLAT = { bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 }

-- Cell looks per state: background, border, text colour.
local LOOK = {
    known = { { 0.13, 0.42, 0.13, 0.95 }, { 0.3, 0.8, 0.3, 0.6 }, { 1, 1, 1 } },
    learn = { { 0.45, 0.34, 0, 0.95 }, GOLD, { 1, 0.95, 0.6 } },
    maybe = { { 0.3, 0.24, 0.02, 0.9 }, { 1, 0.82, 0, 0.5 }, { 1, 0.9, 0.5 } },
    skip = { { 0.1, 0.1, 0.1, 0.9 }, { 1, 1, 1, 0.06 }, { 0.45, 0.45, 0.45 } },
    later = { { 0.06, 0.06, 0.07, 0.9 }, { 1, 1, 1, 0.08 }, { 0.65, 0.65, 0.65 } },
    nodemon = { { 0.06, 0.06, 0.07, 0.9 }, { 1, 1, 1, 0.05 }, { 0.4, 0.4, 0.4 } },
}

local function Skin(f, alpha)
    f:SetBackdrop(FLAT)
    f:SetBackdropColor(0.05, 0.05, 0.06, alpha or 0.92)
    f:SetBackdropBorderColor(1, 1, 1, 0.08)
end

local function Text(parent, font)
    return parent:CreateFontString(nil, "OVERLAY", font or "GameFontHighlightSmall")
end

local function TextButton(parent, label, width)
    local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
    b:SetSize(width, 20)
    Skin(b, 0.6)
    local hl = b:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(1, 1, 1, 0.08)
    b.text = Text(b)
    b.text:SetPoint("LEFT", 4, 0)
    b.text:SetPoint("RIGHT", -4, 0)
    b.text:SetWordWrap(false)
    b.text:SetJustifyH("CENTER")
    b.text:SetText(label)
    return b
end

local function Money(copper)
    local coins = (C_CurrencyInfo and C_CurrencyInfo.GetCoinTextureString) or GetCoinTextureString
    if coins then
        local ok, text = pcall(coins, copper)
        if ok and text then return text end
    end
    return ns.Money(copper)
end

local function Ago(t)
    local s = time() - (t or 0)
    if s < 120 then return "just now" end
    if s < 3600 then return ("%d min ago"):format(s / 60) end
    if s < 86400 then return ("%d h ago"):format(s / 3600) end
    return ("%d days ago"):format(s / 86400)
end

local function Names(list)
    local out = {}
    for _, e in ipairs(list) do out[#out + 1] = ns.RankName(e.ability, e.rank, ns.AbilityName(e.ability)) end
    return table.concat(out, ", ")
end

---------------------------------------------------------------------------
-- Window
---------------------------------------------------------------------------
local window, tabs, rows, status, buy, nextUp, checks
local selected -- demon key on show

local function CellTooltip(self)
    local a, i, d = self.ability, self.rank, self.demon
    if not a then return end
    local r = a.ranks[i]
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine(ns.RankName(a, i, ns.AbilityName(a)), 1, 1, 1)
    if r.item then
        GameTooltip:AddLine(("Grimoire, requires level %d"):format(r.level), 0.9, 0.9, 0.9)
        if r.price and r.price > 0 then GameTooltip:AddLine("About " .. Money(r.price), 0.9, 0.9, 0.9) end
    else
        GameTooltip:AddLine("Comes with the demon", 0.9, 0.9, 0.9)
    end
    local text, cr, cg, cb = ns.StateText(self.state, d, { info = r })
    if text and not (self.state == "known" and not r.item) then GameTooltip:AddLine(text, cr, cg, cb, true) end
    GameTooltip:Show()
end

local function Refresh()
    if not window or not window:IsShown() then return end
    local level = ns.Level()
    local demons = ns.Demons(ns.ERA)
    local d = ns.Demon(selected) or demons[1]
    ns.char.tab = d.key

    for i, t in ipairs(tabs) do
        local td = demons[i]
        local has = ns.HasDemon(td)
        local learn = has and ns.ToLearn(td.group, ns.Ranks(td.key), level) or {}
        local label = ns.DemonName(td)
        if #learn > 0 then label = label .. (" |cffffd100+%d|r"):format(#learn) end
        t.text:SetText(label)
        t.text:SetTextColor(has and 1 or 0.5, has and 1 or 0.5, has and 1 or 0.5)
        t:SetBackdropBorderColor(unpack(td == d and GOLD or { 1, 1, 1, 0.08 }))
    end

    local has = ns.HasDemon(d)
    local rec = ns.char.demons[d.key]
    local ranks = ns.Ranks(d.key)
    local name = ns.DemonName(d)
    if not has then
        status:SetText(("|cff999999You don't have the %s yet (warlock quest from level %d).|r"):format(name, d.level))
    elseif not ranks then
        status:SetText(("|cffffd100Summon your %s once so I can read what it knows.|r Until then, gold = what it may still need."):format(name))
    elseif ns.current == d.key then
        status:SetText(("|cff66dd66Your %s is out|r (level %s): this is what it knows now."):format(name, rec.level or "?"))
    else
        status:SetText(("Your %s, as read %s."):format(name, Ago(rec.t)))
    end

    local list = ns.ABILITIES[d.group]
    for i, row in ipairs(rows) do
        local a = list[i]
        row:SetShown(a ~= nil)
        if a then
            row.icon:SetTexture(ns.SpellIcon(a.ranks[1].spell) or ns.ICON)
            local known = ranks and (ranks[a.key] or 0) or nil
            row.name:SetText(ns.AbilityName(a))
            for k, cell in ipairs(row.cells) do
                local r = a.ranks[k]
                cell:SetShown(r ~= nil)
                if r then
                    local state = ns.RankState(a, k, known, level)
                    if not has and state ~= "later" then state = "nodemon" end
                    local look = LOOK[state]
                    cell:SetBackdropColor(unpack(look[1]))
                    cell:SetBackdropBorderColor(unpack(look[2]))
                    cell.text:SetTextColor(unpack(look[3]))
                    cell.text:SetText(r.level)
                    cell.ability, cell.rank, cell.demon, cell.state = a, k, d, state
                end
            end
        end
    end

    local learn, total = ns.ToLearn(d.group, ranks, level)
    if not has then
        buy:SetText("")
    elseif #learn > 0 then
        buy:SetText(("|cffffd100Buy now%s:|r %s — about %s"):format(ranks and "" or " (unless it knows them)",
            Names(learn), Money(total)))
    else
        buy:SetText("Nothing to buy now.")
    end
    local at, upcoming = ns.NextUp(d.group, level)
    if at then
        nextUp:SetText(("Next at level %d: %s."):format(at, Names(upcoming)))
    else
        nextUp:SetText("No grimoires left above your level.")
    end
    checks.trainer:SetChecked(ns.db.atTrainer ~= false)
    checks.notify:SetChecked(ns.db.notify ~= false)
end

function ns.PlaceWindow()
    if not window then return end
    window:ClearAllPoints()
    local p = ns.db.win
    if p then
        window:SetPoint(p[1], UIParent, p[2], p[3], p[4])
    else
        window:SetPoint("CENTER", 0, 60)
    end
end

local function Check(label, tip, onClick)
    local c = CreateFrame("CheckButton", nil, window, "UICheckButtonTemplate")
    c:SetSize(22, 22)
    local t = Text(c)
    t:SetPoint("LEFT", c, "RIGHT", 2, 1)
    t:SetText(label)
    c:SetHitRectInsets(0, -t:GetStringWidth() - 4, 0, 0)
    c:SetScript("OnClick", function(self) onClick(self:GetChecked() and true or false) end)
    c:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine(tip, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    c:SetScript("OnLeave", function() GameTooltip:Hide() end)
    c.label = t
    return c
end

local function Window()
    if window then return window end
    window = CreateFrame("Frame", "EzGrimoireFrame", UIParent, "BackdropTemplate")
    window:SetSize(W, H)
    window:SetFrameStrata("HIGH")
    window:EnableMouse(true)
    window:SetMovable(true)
    window:SetClampedToScreen(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", window.StartMoving)
    window:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        ns.db.win = { "TOPLEFT", "BOTTOMLEFT", self:GetLeft(), self:GetTop() }
    end)
    Skin(window)
    window:Hide()
    tinsert(UISpecialFrames, "EzGrimoireFrame") -- Escape closes it
    ns.PlaceWindow()

    local title = Text(window, "GameFontNormal")
    title:SetPoint("TOPLEFT", PAD + 2, -PAD - 4)
    title:SetText("Demon grimoires")
    local close = TextButton(window, "x", 22)
    close:SetPoint("TOPRIGHT", -PAD, -PAD)
    close:SetScript("OnClick", function() window:Hide() end)

    tabs = {}
    local demons = ns.Demons(ns.ERA)
    local gap = 4
    local tabW = math.floor((W - 2 * PAD - gap * (#demons - 1)) / #demons)
    for i, d in ipairs(demons) do
        local t = TextButton(window, d.name, tabW)
        t:SetPoint("TOPLEFT", PAD + (i - 1) * (tabW + gap), -36)
        t:SetScript("OnClick", function()
            selected = d.key
            Refresh()
        end)
        tabs[i] = t
    end

    status = Text(window)
    status:SetPoint("TOPLEFT", PAD + 2, -64)
    status:SetWidth(W - 2 * PAD - 4)
    status:SetJustifyH("LEFT")

    local head = Text(window, "GameFontNormalSmall")
    head:SetPoint("TOPLEFT", NAME_X, -98)
    head:SetText("Ability")
    head:SetTextColor(0.6, 0.6, 0.6)
    for k = 1, MAX_RANKS do
        local h = Text(window, "GameFontNormalSmall")
        h:SetPoint("TOPLEFT", CELL_X + (k - 1) * (CELL_W + CELL_GAP), -98)
        h:SetWidth(CELL_W)
        h:SetJustifyH("CENTER")
        h:SetTextColor(0.6, 0.6, 0.6)
        h:SetText(k == 1 and "Rank 1" or k)
    end

    rows = {}
    for i = 1, MAX_ROWS do
        local row = CreateFrame("Frame", nil, window)
        row:SetSize(W - 2 * PAD, ROW_H)
        row:SetPoint("TOPLEFT", 0, -112 - (i - 1) * ROW_H)
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(20, 20)
        row.icon:SetPoint("LEFT", ICON_X, 0)
        row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        row.name = Text(row, "GameFontHighlight")
        row.name:SetPoint("LEFT", NAME_X, 0)
        row.name:SetWidth(NAME_W)
        row.name:SetJustifyH("LEFT")
        row.name:SetWordWrap(false)
        row.cells = {}
        for k = 1, MAX_RANKS do
            local cell = CreateFrame("Button", nil, row, "BackdropTemplate")
            cell:SetSize(CELL_W, CELL_H)
            cell:SetPoint("LEFT", CELL_X + (k - 1) * (CELL_W + CELL_GAP), 0)
            cell:SetBackdrop(FLAT)
            cell.text = Text(cell, "GameFontHighlightSmall")
            cell.text:SetPoint("CENTER")
            cell:SetScript("OnEnter", CellTooltip)
            cell:SetScript("OnLeave", function() GameTooltip:Hide() end)
            row.cells[k] = cell
        end
        rows[i] = row
    end

    local legend = Text(window)
    legend:SetPoint("TOPLEFT", PAD + 2, -112 - MAX_ROWS * ROW_H - 6)
    legend:SetWidth(W - 2 * PAD - 4)
    legend:SetJustifyH("LEFT")
    legend:SetText("Number = level needed.   |cff66dd66Known|r   |cffffd100Buy this one|r   "
        .. "|cff777777Skip|r   |cffaaaaaaLater|r   (hover a cell for more)")

    buy = Text(window)
    buy:SetPoint("TOPLEFT", legend, "BOTTOMLEFT", 0, -10)
    buy:SetWidth(W - 2 * PAD - 4)
    buy:SetJustifyH("LEFT")
    nextUp = Text(window)
    nextUp:SetPoint("TOPLEFT", buy, "BOTTOMLEFT", 0, -6)
    nextUp:SetWidth(W - 2 * PAD - 4)
    nextUp:SetJustifyH("LEFT")

    checks = {}
    checks.trainer = Check("Open at the demon trainer",
        "Shows this list beside the demon trainer's window, and closes it with it.",
        function(on) ns.db.atTrainer = on end)
    checks.trainer:SetPoint("BOTTOMLEFT", PAD - 2, PAD - 2)
    checks.notify = Check("Tell me on level-up",
        "A chat line when you reach a level that opens new grimoires for your demons.",
        function(on) ns.db.notify = on end)
    checks.notify:SetPoint("LEFT", checks.trainer.label, "RIGHT", 16, -1)

    window:SetScript("OnShow", Refresh)
    window:SetScript("OnHide", function(self)
        if self.byTrainer then
            self.byTrainer = false
            ns.PlaceWindow()
        end
    end)
    return window
end

-- The tab to open on: the demon that's out, else the last one looked at, else the first you have.
local function DefaultTab()
    if ns.current then return ns.current end
    local last = ns.char.tab and ns.Demon(ns.char.tab)
    if last and not (ns.ERA and last.forever) then return last.key end
    return "imp"
end

function ns.Open(key)
    selected = key or DefaultTab()
    local w = Window()
    if w:IsShown() then Refresh() else w:Show() end
end

function ns.Toggle()
    local w = Window()
    if w:IsShown() then
        w:Hide()
    else
        ns.Open()
    end
end

function ns.ShowAtTrainer()
    local w = Window()
    if w:IsShown() and not w.byTrainer then return Refresh() end -- you opened it yourself: leave it where it is
    selected = DefaultTab()
    if MerchantFrame then
        w:ClearAllPoints()
        w:SetPoint("TOPLEFT", MerchantFrame, "TOPRIGHT", 6, 0)
    end
    w.byTrainer = true
    w:Show()
    Refresh()
end

function ns.LeftTrainer()
    if window and window.byTrainer then window:Hide() end
end

function ns.Redraw()
    Refresh()
end

function ns.Login()
    selected = DefaultTab()
end
