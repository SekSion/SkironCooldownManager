local SCM = select(2, ...)

local Keybinds = {}
SCM.Keybinds = Keybinds

local LSM = LibStub("LibSharedMedia-3.0", true)

local DEFAULT_FONT = "Interface\\AddOns\\SkironCooldownManager\\Media\\fonts\\Expressway.ttf"

-- ── State ────────────────────────────────────────────────────────────────────

local keyMap = nil
local pendingRebuild = false
local combatDirty = false

-- ── Key abbreviation ─────────────────────────────────────────────────────────

local function AbbreviateKey(key)
    if not key or key == "" then return "" end
    key = key:upper()

    key = key:gsub("MOUSE%s*WHEEL%s*UP",   "MWUP")
              :gsub("MOUSE%s*WHEEL%s*DOWN", "MWDN")
              :gsub("MOUSEBUTTON", "MB")
              :gsub("BUTTON",      "MB")

    key = key:gsub("SHIFT%-", "S")
              :gsub("CTRL%-",  "C")
              :gsub("ALT%-",   "A")

    key = key:gsub("MWUP",        "WU")
              :gsub("MWDN",       "WD")
              :gsub("NUMPADPLUS", "N+")
              :gsub("NUMPADMINUS","N%-")
              :gsub("NUMPAD",     "N")
              :gsub("PAGEUP",     "PU")
              :gsub("PAGEDOWN",   "PD")
              :gsub("INSERT",     "Ins")
              :gsub("DELETE",     "Del")
              :gsub("BACKSPACE",  "Bs")
              :gsub("SPACEBAR",   "Sp")
              :gsub("ESCAPE",     "Esc")
              :gsub("ENTER",      "Ent")
              :gsub("HOME",       "Hm")
              :gsub("END",        "En")
              :gsub("TAB",        "Tab")

    local trailing = key:sub(-1) == "-"
    if trailing then
        key = key:sub(1, -2):gsub("%-", "") .. "-"
    else
        key = key:gsub("%-", "")
    end

    return key
end

-- ── Spell / item helpers ─────────────────────────────────────────────────────

local function ResolveSpellName(spellID)
    if not spellID or spellID == 0 then return nil end
    if C_Spell and C_Spell.GetSpellName then
        local n = C_Spell.GetSpellName(spellID)
        if n and n ~= "" then return n end
    end
    return nil
end

local function ResolveSpellIDFromToken(token)
    if not token or token == "" then return nil end
    local n = tonumber(token)
    if n then
        return (C_Spell and C_Spell.DoesSpellExist and C_Spell.DoesSpellExist(n)) and n or nil
    end
    if C_Spell then
        if C_Spell.GetSpellIDForSpellIdentifier then
            local id = C_Spell.GetSpellIDForSpellIdentifier(token)
            if id and id ~= 0 then return id end
        end
        if C_Spell.GetSpellInfo then
            local info = C_Spell.GetSpellInfo(token)
            if info and info.spellID ~= 0 then return info.spellID end
        end
    end
    return nil
end

local function ResolveItemName(itemID)
    if not itemID or itemID == 0 then return nil end
    if C_Item and C_Item.GetItemNameByID then
        local n = C_Item.GetItemNameByID(itemID)
        if n and n ~= "" then return n end
    end
    return nil
end

-- ── Key map ───────────────────────────────────────────────────────────────────

local function StoreSpell(map, spellID, fmtKey, force)
    if not spellID or spellID == 0 or not fmtKey or fmtKey == "" then return end
    if not force and map.spells[spellID] then return end
    map.spells[spellID] = fmtKey

    local name = ResolveSpellName(spellID)
    if name then map.spellNames[name:lower()] = fmtKey end

    if C_Spell then
        local ov = C_Spell.GetOverrideSpell and C_Spell.GetOverrideSpell(spellID)
        if ov and ov ~= 0 and (force or not map.spells[ov]) then
            map.spells[ov] = fmtKey
            local on = ResolveSpellName(ov)
            if on then map.spellNames[on:lower()] = fmtKey end
        end
        local base = C_Spell.GetBaseSpell and C_Spell.GetBaseSpell(spellID)
        if base and base ~= 0 and (force or not map.spells[base]) then
            map.spells[base] = fmtKey
            local bn = ResolveSpellName(base)
            if bn then map.spellNames[bn:lower()] = fmtKey end
        end
    end
end

local function StoreItem(map, itemID, fmtKey, force)
    if not itemID or itemID == 0 or not fmtKey or fmtKey == "" then return end
    if not force and map.items[itemID] then return end
    map.items[itemID] = fmtKey
    local name = ResolveItemName(itemID)
    if name then map.itemNames[name:lower()] = fmtKey end
end

local function QuerySpell(map, spellID)
    if not map or not spellID then return nil end
    local k = map.spells[spellID]
    if k then return k end
    if C_Spell then
        local ov = C_Spell.GetOverrideSpell and C_Spell.GetOverrideSpell(spellID)
        if ov and map.spells[ov] then return map.spells[ov] end
        local base = C_Spell.GetBaseSpell and C_Spell.GetBaseSpell(spellID)
        if base and map.spells[base] then return map.spells[base] end
    end
    local name = ResolveSpellName(spellID)
    return name and map.spellNames[name:lower()] or nil
end

local function QueryItem(map, itemID)
    if not map or not itemID then return nil end
    local k = map.items[itemID]
    if k then return k end
    local name = ResolveItemName(itemID)
    return name and map.itemNames[name:lower()] or nil
end

-- ── Macro parsing ─────────────────────────────────────────────────────────────

local function TrimStr(s)
    return s and s:match("^%s*(.-)%s*$") or ""
end

local function DropConditionals(s)
    s = TrimStr(s)
    while true do
        local blk = s:match("^(%b[])")
        if not blk then break end
        s = TrimStr(s:sub(#blk + 1))
    end
    return s
end

local function ScrubToken(tok)
    tok = tok:gsub("%[.-%]", ""):gsub("#.*$", ""):gsub("!+", "")
    return TrimStr(tok)
end

local function FirstCastToken(body)
    for line in body:gmatch("[^\r\n]+") do
        local cmd, rest = TrimStr(line):match("^/(%S+)%s+(.+)$")
        if cmd then
            cmd = cmd:lower()
            if cmd == "cast" or cmd == "castsequence" then
                rest = DropConditionals(rest)
                if cmd == "castsequence" then
                    rest = rest:gsub("^reset=%S+%s*", "")
                end
                rest = ScrubToken((rest:match("^([^;]+)") or rest))
                if rest ~= "" then
                    return TrimStr(rest:match("^([^,]+)") or rest)
                end
            end
        end
    end
    return nil
end

local function ShowtooltipToken(body)
    for line in body:gmatch("[^\r\n]+") do
        local rest = TrimStr(line):match("^#showtooltip%s+(.+)$")
        if rest then
            rest = ScrubToken(rest)
            return rest ~= "" and rest or nil
        end
    end
    return nil
end

local function ExtractUseTokens(body)
    local found = {}
    for line in body:gmatch("[^\r\n]+") do
        local cmd, rest = TrimStr(line):match("^/(%S+)%s+(.+)$")
        if cmd and (cmd:lower() == "use" or cmd:lower() == "item") then
            for seg in rest:gmatch("([^;]+)") do
                local tok = ScrubToken(seg)
                if tok ~= "" then
                    for part in tok:gmatch("([^,]+)") do
                        local p = ScrubToken(part)
                        if p ~= "" then found[p:lower()] = p end
                    end
                end
            end
        end
    end
    local out = {}
    for _, v in pairs(found) do out[#out + 1] = v end
    return #out > 0 and out or nil
end

local function ResolveMacroSpellID(macroIdx, body)
    if GetMacroSpell then
        local v = GetMacroSpell(macroIdx)
        if type(v) == "number" and v > 0 then return v end
        if type(v) == "string" and v ~= "" then return ResolveSpellIDFromToken(v) end
    end
    local st = ShowtooltipToken(body)
    if st then
        local id = ResolveSpellIDFromToken(st)
        if id then return id end
    end
    local ct = FirstCastToken(body)
    if ct then return ResolveSpellIDFromToken(ct) end
    return nil
end

-- ── Button key detection ──────────────────────────────────────────────────────

local function ReadButtonKey(btn)
    if not btn then return nil end
    if btn.config and btn.config.keyBoundTarget then
        local k = GetBindingKey(btn.config.keyBoundTarget)
        if k and k ~= "" then return k end
    end
    if btn.commandName then
        local k = GetBindingKey(btn.commandName)
        if k and k ~= "" then return k end
    end
    local name = btn.GetName and btn:GetName()
    if name then
        local k = GetBindingKey("CLICK " .. name .. ":LeftButton")
        if k and k ~= "" then return k end
    end
    if btn.HotKey and btn.HotKey.GetText then
        local t = btn.HotKey:GetText()
        if t and t ~= "" and t ~= "●" then return t end
    end
    return nil
end

-- ── Bar iterator ──────────────────────────────────────────────────────────────

local function MakeBarIterator()
    if _G["DominosActionButton1"] and _G["DominosActionButton1"].action then
        return coroutine.wrap(function()
            for i = 1, 180 do
                local btn = _G["DominosActionButton" .. i]
                if btn and btn.action then
                    local k = ReadButtonKey(btn)
                    if k and k ~= "●" then coroutine.yield(btn.action, k) end
                end
            end
        end)
    end

    if _G["BT4Button1"] and _G["BT4Button1"].action then
        return coroutine.wrap(function()
            for i = 1, 180 do
                local btn = _G["BT4Button" .. i]
                if btn and btn.action then
                    local k = ReadButtonKey(btn)
                    if k and k ~= "●" then coroutine.yield(btn.action, k) end
                end
            end
        end)
    end

    if _G["ElvUI_Bar1Button1"] and _G["ElvUI_Bar1Button1"].action then
        return coroutine.wrap(function()
            for bar = 1, 15 do
                if _G["ElvUI_Bar" .. bar .. "Button1"] then
                    for j = 1, 12 do
                        local btn = _G["ElvUI_Bar" .. bar .. "Button" .. j]
                        if btn and btn.action then
                            local k = ReadButtonKey(btn)
                            if k and k ~= "●" then coroutine.yield(btn.action, k) end
                        end
                    end
                end
            end
        end)
    end

    local barPrefixes = {
        "ActionButton", "MultiBarBottomLeftButton", "MultiBarBottomRightButton",
        "MultiBarRightButton", "MultiBarLeftButton",
        "MultiBar5Button", "MultiBar6Button", "MultiBar7Button",
    }
    return coroutine.wrap(function()
        for _, prefix in ipairs(barPrefixes) do
            for j = 1, 12 do
                local btn = _G[prefix .. j]
                if btn and btn.action then
                    local k = ReadButtonKey(btn)
                    if k and k ~= "●" then
                        local slot = btn.action
                        if ActionButton_GetPagedID then
                            local paged = ActionButton_GetPagedID(btn)
                            if type(paged) == "number" and paged > 0 then slot = paged end
                        end
                        coroutine.yield(slot, k)
                    end
                end
            end
        end
    end)
end

-- ── Map construction ──────────────────────────────────────────────────────────

local function BuildKeyMap()
    if InCombatLockdown and InCombatLockdown() then
        return { spells = {}, spellNames = {}, items = {}, itemNames = {} }
    end

    local map = { spells = {}, spellNames = {}, items = {}, itemNames = {} }
    local macros = {}
    local seenSlots = {}

    for slot, rawKey in MakeBarIterator() do
        if not seenSlots[slot] then
            seenSlots[slot] = true
            local fmt = AbbreviateKey(rawKey)
            if fmt ~= "" and GetActionInfo then
                local aType, id = GetActionInfo(slot)
                if aType == "spell" then
                    StoreSpell(map, id, fmt)
                elseif aType == "item" then
                    StoreItem(map, id, fmt)
                elseif aType == "macro" then
                    macros[#macros + 1] = { slot = slot, id = id, fmt = fmt }
                end
            end
        end
    end

    for _, m in ipairs(macros) do
        local macroIdx
        if GetActionText and GetMacroIndexByName then
            local mname = GetActionText(m.slot)
            if mname and mname ~= "" then
                macroIdx = GetMacroIndexByName(mname)
            end
        end
        if (not macroIdx or macroIdx == 0) and type(m.id) == "number" and m.id > 0 and GetMacroInfo then
            if GetMacroInfo(m.id) then macroIdx = m.id end
        end

        if macroIdx and macroIdx > 0 then
            local body
            if GetMacroInfo then
                local _, _, b = GetMacroInfo(macroIdx)
                body = (b and b ~= "") and b or nil
            end
            body = body or (GetMacroBody and GetMacroBody(macroIdx))

            if body then
                local spellID = ResolveMacroSpellID(macroIdx, body)
                if spellID then
                    StoreSpell(map, spellID, m.fmt, true)
                end

                local hasSlash = body:lower():find("/cast", 1, true) or body:lower():find("/castsequence", 1, true)
                local tokens = ExtractUseTokens(body)
                if tokens then
                    for _, tok in ipairs(tokens) do
                        local n = tonumber(tok)
                        if n then
                            -- Plain number: slot IDs 13/14 are trinket slots, anything above is a direct item ID
                            if (n == 13 or n == 14) and not hasSlash then
                                local equipped = GetInventoryItemID and GetInventoryItemID("player", n)
                                if equipped then StoreItem(map, equipped, m.fmt, true) end
                            elseif n > 14 then
                                StoreItem(map, n, m.fmt, true)
                            end
                        else
                            -- "item:ITEMID" or full item string "item:ITEMID:bonus:..." (/use item:245898)
                            local rawID = tok:match("^[Ii]tem:(%d+)")
                            if rawID then
                                StoreItem(map, tonumber(rawID), m.fmt, true)
                            elseif GetItemInfo then
                                -- Item name token (/use Light's Potential) — resolve via cache
                                local _, link = GetItemInfo(tok)
                                if link then
                                    local id = link:match("item:(%d+)")
                                    if id then StoreItem(map, tonumber(id), m.fmt, true) end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return map
end

-- ── Overlay creation & styling ────────────────────────────────────────────────

local function GetOverlay(frame)
    if frame.SCMKeybindOverlay then
        return frame.SCMKeybindOverlay
    end

    local overlay = CreateFrame("Frame", nil, frame)
    overlay:SetFrameLevel(frame:GetFrameLevel() + 5)
    overlay:SetAllPoints(frame)

    local text = overlay:CreateFontString(nil, "OVERLAY")
    text:SetDrawLayer("OVERLAY", 7)
    text:SetShadowColor(0, 0, 0, 1)
    text:SetShadowOffset(1, -1)

    overlay.text = text
    frame.SCMKeybindOverlay = overlay
    return overlay
end

local function GetKeybindCfg()
    return SCM.db and SCM.db.profile and SCM.db.profile.options and SCM.db.profile.options.keybinds
end

local function ApplyStyle(overlay, cfg)
    local text = overlay.text
    local fontPath = DEFAULT_FONT
    if LSM then
        local p = LSM:Fetch("font", cfg.fontName)
        if p then fontPath = p end
    end
    text:SetFont(fontPath, cfg.fontSize or 11, cfg.fontFlags or "OUTLINE")
    local c = cfg.color or { 1, 1, 1, 1 }
    text:SetTextColor(c[1] or 1, c[2] or 1, c[3] or 1, c[4] or 1)
end

local function ShowKeybind(frame, key, cfg)
    local overlay = GetOverlay(frame)
    ApplyStyle(overlay, cfg)
    local anchor = cfg.anchor or "TOPRIGHT"
    overlay.text:ClearAllPoints()
    overlay.text:SetPoint(anchor, frame, anchor, cfg.offsetX or -1, cfg.offsetY or -1)
    overlay.text:SetText(key)
    overlay.text:Show()
    overlay:Show()
end

local function HideKeybind(frame)
    if frame and frame.SCMKeybindOverlay then
        frame.SCMKeybindOverlay:Hide()
    end
end

-- ── Per-frame application ─────────────────────────────────────────────────────

-- For regular CDM viewer children (SCMSpellID set by icons.lua:ProcessSingleChild)
local function ApplyToViewerChild(child, map, cfg)
    local spellID = child.SCMSpellID or child.SCMLinkedSpellID
    if not spellID then
        HideKeybind(child)
        return
    end

    local key = QuerySpell(map, spellID)
    if not key or key == "" then
        HideKeybind(child)
        return
    end

    ShowKeybind(child, key, cfg)
end

-- For SCM custom icon frames (SCMConfig with spellID/itemID/slotID)
local function ApplyToCustomFrame(frame, map, cfg)
    local config = frame.SCMConfig
    if not config then return end

    local key
    local iconType = frame.SCMIconType

    if iconType == "spell" or iconType == "timer" then
        key = config.spellID and QuerySpell(map, config.spellID)
    elseif iconType == "item" then
        key = config.itemID and QueryItem(map, config.itemID)
    elseif iconType == "slot" then
        if config.slotID and GetInventoryItemID then
            local itemID = GetInventoryItemID("player", config.slotID)
            if itemID and itemID ~= 0 then
                key = QueryItem(map, itemID)
            end
        end
        if not key and config.spellID then
            key = QuerySpell(map, config.spellID)
        end
    end

    if not key or key == "" then
        HideKeybind(frame)
        return
    end

    ShowKeybind(frame, key, cfg)
end

-- ── Public API ────────────────────────────────────────────────────────────────

function Keybinds.ApplyToFrame(frame)
    if not keyMap then return end
    local cfg = GetKeybindCfg()
    if not cfg or not cfg.enabled then
        HideKeybind(frame)
        return
    end
    ApplyToCustomFrame(frame, keyMap, cfg)
end

function Keybinds.ApplyToViewerChild(child)
    if not keyMap then return end
    local cfg = GetKeybindCfg()
    if not cfg or not cfg.enabled then
        HideKeybind(child)
        return
    end
    ApplyToViewerChild(child, keyMap, cfg)
end

function Keybinds.HideFromFrame(frame)
    HideKeybind(frame)
end

function Keybinds.RefreshAllFrames()
    local map = keyMap
    local cfg = GetKeybindCfg()
    local enabled = cfg and cfg.enabled

    -- Custom SCM frames (items, slots, timers, custom spells)
    if SCM.CustomIcons and SCM.CustomIcons.ForEachActiveFrame then
        SCM.CustomIcons.ForEachActiveFrame(function(frame)
            if not frame.SCMConfig then return end
            if enabled and map then
                ApplyToCustomFrame(frame, map, cfg)
            else
                HideKeybind(frame)
            end
        end)
    end

    -- Regular CDM viewer children (native Blizzard CDM spells)
    for _, viewerName in ipairs({ "EssentialCooldownViewer", "UtilityCooldownViewer" }) do
        local viewer = _G[viewerName]
        if viewer then
            for _, child in ipairs({ viewer:GetChildren() }) do
                if child.SCMSpellID then
                    if enabled and map then
                        ApplyToViewerChild(child, map, cfg)
                    else
                        HideKeybind(child)
                    end
                end
            end
        end
    end
end

function Keybinds.Rebuild()
    if InCombatLockdown and InCombatLockdown() then
        combatDirty = true
        return
    end
    keyMap = BuildKeyMap()
    Keybinds.RefreshAllFrames()
end

-- ── Events ────────────────────────────────────────────────────────────────────

local eventFrame = CreateFrame("Frame")
eventFrame:SetScript("OnEvent", function(_, event, arg1)
    if event == "PLAYER_REGEN_ENABLED" then
        if combatDirty then
            combatDirty = false
            Keybinds.Rebuild()
        end
        return
    end

    local cfg = GetKeybindCfg()
    if not cfg or not cfg.enabled then return end

    if InCombatLockdown and InCombatLockdown() then
        combatDirty = true
        return
    end

    if pendingRebuild then return end
    pendingRebuild = true
    C_Timer.After(0.15, function()
        pendingRebuild = false
        Keybinds.Rebuild()
    end)
end)

-- ── Lifecycle ────────────────────────────────────────────────────────────────

function Keybinds.Enable()
    eventFrame:RegisterEvent("UPDATE_BINDINGS")
    eventFrame:RegisterEvent("UPDATE_MACROS")
    eventFrame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
    eventFrame:RegisterEvent("ACTIONBAR_PAGE_CHANGED") -- Covers paging changes example druid forms
    eventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    eventFrame:RegisterEvent("ACTIVE_PLAYER_SPECIALIZATION_CHANGED")
    eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    Keybinds.Rebuild()
end

function Keybinds.Disable()
    eventFrame:UnregisterAllEvents()
    keyMap = nil
    combatDirty = false
    pendingRebuild = false
    Keybinds.RefreshAllFrames()
end

function Keybinds.OnSettingChanged()
    local cfg = GetKeybindCfg()
    if cfg and cfg.enabled then
        Keybinds.Enable()
    else
        Keybinds.Disable()
    end
end
