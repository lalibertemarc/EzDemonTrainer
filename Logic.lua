-- Rules with no game API (tested by tests/grimoire.lua): which ranks a demon knows, which grimoire is worth
-- buying now, which can be skipped, and which wait for a level.
local _, ns = ...

-- Indexes: pet spell ID → entry, grimoire item ID → entry; entry = { group, ability, rank, info }.
local bySpell, byItem = {}, {}
for group, list in pairs(ns.ABILITIES) do
    for _, a in ipairs(list) do
        for i, r in ipairs(a.ranks) do
            local e = { group = group, ability = a, rank = i, info = r }
            bySpell[r.spell] = e
            if r.item then byItem[r.item] = e end
        end
    end
end

function ns.ForSpell(id) return id and bySpell[id] end
function ns.ForItem(id) return id and byItem[id] end

function ns.Demon(key)
    for _, d in ipairs(ns.DEMONS) do
        if d.key == key then return d end
    end
end

-- The demons this client has (no Incubus in Era).
function ns.Demons(era)
    local out = {}
    for _, d in ipairs(ns.DEMONS) do
        if not (era and d.forever) then out[#out + 1] = d end
    end
    return out
end

-- Highest known rank of each of group's abilities, from isKnown(spellID).
-- Returns { [abilityKey] = rank (0 = not known) }, and how many ranks were known in all.
function ns.ReadRanks(group, isKnown)
    local out, count = {}, 0
    for _, a in ipairs(ns.ABILITIES[group]) do
        local best = 0
        for i, r in ipairs(a.ranks) do
            if isKnown(r.spell) then
                best = i
                count = count + 1
            end
        end
        out[a.key] = best
    end
    return out, count
end

-- Which ability list a pet's spells belong to (the one with the most known ranks), or nil: not one of the
-- warlock's own demons (an enslaved one, a hunter's pet).
function ns.GroupOf(isKnown)
    local bestGroup, bestCount = nil, 0
    for group in pairs(ns.ABILITIES) do
        local _, count = ns.ReadRanks(group, isKnown)
        if count > bestCount then bestGroup, bestCount = group, count end
    end
    return bestGroup
end

-- The highest rank you're high enough for (0 = none yet).
function ns.BestRank(ability, level)
    local best = 0
    for i, r in ipairs(ability.ranks) do
        if r.level <= level then best = i end
    end
    return best
end

-- State of rank i of ability for a demon that knows rank `known` (nil = never read: summon it once):
--   "known"  it knows it (or, never read, it comes with the demon)
--   "learn"  the best rank you can use now and it doesn't know: buy this one
--   "maybe"  same, for a demon never read (it may know it already)
--   "skip"   you could use it, but a higher rank you can also use replaces it
--   "later"  you're not high enough yet
function ns.RankState(ability, i, known, level)
    local r = ability.ranks[i]
    if known and i <= known then return "known" end
    if r.level > level then return "later" end
    if not r.item then return "known" end -- comes with the demon
    if i < ns.BestRank(ability, level) then return "skip" end
    return known and "learn" or "maybe"
end

-- Grimoires worth buying now for a demon: { { ability, rank, info, state } } in ability order, and their
-- total price. ranks = { [abilityKey] = rank } or nil (never read).
function ns.ToLearn(group, ranks, level)
    local out, total = {}, 0
    for _, a in ipairs(ns.ABILITIES[group]) do
        local known = ranks and (ranks[a.key] or 0) or nil
        for i, r in ipairs(a.ranks) do
            local state = ns.RankState(a, i, known, level)
            if state == "learn" or state == "maybe" then
                out[#out + 1] = { ability = a, rank = i, info = r, state = state }
                total = total + (r.price or 0)
            end
        end
    end
    return out, total
end

-- The next grimoire(s) you're not high enough for: the lowest level above yours, and what it brings.
function ns.NextUp(group, level)
    local at
    for _, a in ipairs(ns.ABILITIES[group]) do
        for _, r in ipairs(a.ranks) do
            if r.item and r.level > level and (not at or r.level < at) then at = r.level end
        end
    end
    local out = {}
    if not at then return nil, out end
    for _, a in ipairs(ns.ABILITIES[group]) do
        for i, r in ipairs(a.ranks) do
            if r.item and r.level == at then out[#out + 1] = { ability = a, rank = i, info = r } end
        end
    end
    return at, out
end

-- Grimoires that open up at exactly this level, per group: { [group] = { { ability, rank, info } } }.
function ns.NewAt(level)
    local out
    for group, list in pairs(ns.ABILITIES) do
        for _, a in ipairs(list) do
            for i, r in ipairs(a.ranks) do
                if r.item and r.level == level then
                    out = out or {}
                    out[group] = out[group] or {}
                    table.insert(out[group], { ability = a, rank = i, info = r })
                end
            end
        end
    end
    return out
end

-- "Torment (Rank 5)", or just the name for an ability with one rank. name = its (localized) name.
function ns.RankName(ability, i, name)
    name = name or ability.name
    if #ability.ranks == 1 then return name end
    return ("%s (Rank %d)"):format(name, i)
end

-- "1g 20s", "35s", "80c" (plain text, for chat and tests).
function ns.Money(copper)
    copper = math.floor(copper or 0)
    local g, s, c = math.floor(copper / 10000), math.floor(copper / 100) % 100, copper % 100
    local parts = {}
    if g > 0 then parts[#parts + 1] = g .. "g" end
    if s > 0 then parts[#parts + 1] = s .. "s" end
    if c > 0 or #parts == 0 then parts[#parts + 1] = c .. "c" end
    return table.concat(parts, " ")
end

-- Slash words → demon key.
ns.ALIASES = {
    imp = "imp", void = "voidwalker", vw = "voidwalker", voidwalker = "voidwalker",
    succ = "succubus", succubus = "succubus", sayaad = "succubus", inc = "incubus", incubus = "incubus",
    fel = "felhunter", fh = "felhunter", felhunter = "felhunter", hunter = "felhunter",
}
