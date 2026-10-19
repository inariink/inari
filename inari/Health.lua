local ADDON_NAME, ns = ...
local CONST = ns.CONST
local State = ns.State
local EnsureDB = ns.EnsureDB
local FRAME_NAMES = ns.FRAME_NAMES
local DB_UNITS = ns.DB_UNITS
local GetEllesmereProfile = ns.GetEllesmereProfile
local GetEllesmereRaidFramesProfile = ns.GetEllesmereRaidFramesProfile
local ScheduleApply = ns.ScheduleApply
local UnitKey = ns.UnitKey
local LegacyMiniUnitKey = ns.LegacyMiniUnitKey
local ReloadEllesmereFrames

local function GetUnitSettings(unit)
    local profile = GetEllesmereProfile()
    if type(profile) ~= "table" then return nil end
    local key = UnitKey(unit)
    local legacyKey = LegacyMiniUnitKey(unit)
    return (key and profile[key]) or (legacyKey and profile[legacyKey]) or profile.player
end

local function GetHealthAlpha(unit)
    local settings = GetUnitSettings(unit)
    local opacity = settings and settings.healthBarOpacity or 90
    if opacity <= 1 then opacity = opacity * 100 end
    if opacity < 0 then opacity = 0 end
    if opacity > 100 then opacity = 100 end
    return opacity / 100
end

local function IsDarkMode()
    EnsureDB()
    if InariDB.appearanceMode == "class" then return false end
    return true
end

local function SetTableValue(tbl, key, value)
    if type(tbl) ~= "table" or tbl[key] == value then return false end
    tbl[key] = value
    return true
end

local function SetColorTable(tbl, key, color)
    if type(tbl) ~= "table" then return false end
    local current = tbl[key]
    if type(current) == "table" and current.r == color.r and current.g == color.g and current.b == color.b then
        return false
    end
    tbl[key] = { r = color.r, g = color.g, b = color.b }
    return true
end

local function ApplyClassColoredUnitSettings(settings)
    local changed = false
    changed = SetTableValue(settings, "healthClassColored", true) or changed
    changed = SetTableValue(settings, "bgClassColored", false) or changed
    changed = SetColorTable(settings, "customBgColor", CONST.DARK_BG_COLOR) or changed

    local textPrefixes = { "leftText", "rightText", "centerText", "extraText", "btbLeft", "btbRight", "btbCenter" }
    for _, prefix in ipairs(textPrefixes) do
        changed = SetTableValue(settings, prefix .. "ClassColor", false) or changed
        changed = SetTableValue(settings, prefix .. "ColorR", 1) or changed
        changed = SetTableValue(settings, prefix .. "ColorG", 1) or changed
        changed = SetTableValue(settings, prefix .. "ColorB", 1) or changed
    end

    return changed
end

local function ApplyDarkModeUnitSettings(settings)
    local changed = false
    local textSlots = {
        { prefix = "leftText", default = "name" },
        { prefix = "rightText", default = "both" },
        { prefix = "centerText", default = "none" },
        { prefix = "extraText", default = "none" },
    }

    for _, slot in ipairs(textSlots) do
        local content = settings[slot.prefix .. "Content"] or slot.default
        local shouldClassColor = content == "name" or content == "nametotarget"
        changed = SetTableValue(settings, slot.prefix .. "ClassColor", shouldClassColor) or changed
        if not shouldClassColor then
            changed = SetTableValue(settings, slot.prefix .. "ColorR", 1) or changed
            changed = SetTableValue(settings, slot.prefix .. "ColorG", 1) or changed
            changed = SetTableValue(settings, slot.prefix .. "ColorB", 1) or changed
        end
    end
    return changed
end

local function ApplyClassColoredRaidSettings(profile, prefix)
    local changed = false
    local function Key(name)
        return prefix and (prefix .. name) or name
    end

    changed = SetTableValue(profile, Key("healthColorMode"), "class") or changed
    changed = SetTableValue(profile, Key("bgClassColored"), false) or changed
    changed = SetColorTable(profile, Key("customBgColor"), CONST.DARK_BG_COLOR) or changed
    changed = SetTableValue(profile, Key("nameColorMode"), "custom") or changed
    changed = SetColorTable(profile, Key("nameCustomColor"), { r = 1, g = 1, b = 1 }) or changed
    changed = SetTableValue(profile, Key("healthTextColorMode"), "custom") or changed
    changed = SetColorTable(profile, Key("healthTextCustomColor"), { r = 1, g = 1, b = 1 }) or changed
    changed = SetTableValue(profile, Key("topNameBarTextColorMode"), "custom") or changed
    changed = SetColorTable(profile, Key("topNameBarTextColor"), { r = 1, g = 1, b = 1 }) or changed

    return changed
end

local function ApplyDarkModeRaidSettings(profile, prefix)
    local changed = false
    local function Key(name)
        return prefix and (prefix .. name) or name
    end

    changed = SetTableValue(profile, Key("healthColorMode"), "dark") or changed
    changed = SetTableValue(profile, Key("nameColorMode"), "class") or changed
    changed = SetTableValue(profile, Key("healthTextColorMode"), "class") or changed
    changed = SetTableValue(profile, Key("topNameBarTextColorMode"), "class") or changed

    return changed
end

local function GetAppearanceMode()
    EnsureDB()
    if InariDB.appearanceMode == "class" then return "class" end
    return "dark"
end

local function KeepResourceBarsColored()
    local module = EllesmereUI and EllesmereUI._ModuleNS and EllesmereUI._ModuleNS.EllesmereUIResourceBars
    local ERB = module and module.ERB
    local profile = ERB and ERB.db and ERB.db.profile
    if type(profile) ~= "table" and ns.EnsureEllesmereAddonProfile then
        profile = ns.EnsureEllesmereAddonProfile("EllesmereUIResourceBars")
    end
    if type(profile) ~= "table" then return false end

    local changed = false
    for _, key in ipairs({ "secondary", "primary", "health" }) do
        local settings = profile[key]
        if type(settings) == "table" and settings.darkTheme then
            settings.darkTheme = false
            changed = true
        end
    end

    if changed and ERB and type(ERB.ApplyAll) == "function" and not (InCombatLockdown and InCombatLockdown()) then
        pcall(ERB.ApplyAll, ERB)
    end
    return changed
end

local function ApplyConfiguredProfileSettings()
    local profile = GetEllesmereProfile()
    local appearanceMode = GetAppearanceMode()
    if not InariDB.enabled or not ns.IsInariEllesmereProfileActive() then return false end
    local classColored = appearanceMode == "class"

    local changed = false
    if type(profile) == "table" then
        local desiredDarkTheme = not classColored and InariDB.forceDarkMode == true
        if profile.darkTheme ~= desiredDarkTheme then
            profile.darkTheme = desiredDarkTheme
            changed = true
        end
    end

    if type(profile) == "table" then
        local opacity = math.floor((InariDB.healthBarOpacity or 85) + 0.5)
        for _, key in ipairs(DB_UNITS) do
            local settings = profile[key]
            if type(settings) == "table" then
                if InariDB.forceOpacity and settings.healthBarOpacity ~= opacity then
                    settings.healthBarOpacity = opacity
                    changed = true
                end
                if classColored then
                    changed = ApplyClassColoredUnitSettings(settings) or changed
                elseif InariDB.forceDarkMode then
                    changed = ApplyDarkModeUnitSettings(settings) or changed
                end
            end
        end
    end

    local raidProfile = GetEllesmereRaidFramesProfile()
    if type(raidProfile) == "table" then
        if classColored then
            changed = ApplyClassColoredRaidSettings(raidProfile) or changed
            changed = ApplyClassColoredRaidSettings(raidProfile, "party_") or changed
        elseif InariDB.forceDarkMode then
            changed = ApplyDarkModeRaidSettings(raidProfile) or changed
            changed = ApplyDarkModeRaidSettings(raidProfile, "party_") or changed
        end

        if InariDB.forceOpacity then
            local opacity = math.floor((InariDB.healthBarOpacity or 85) + 0.5)
            if raidProfile.healthBarOpacity ~= opacity then
                raidProfile.healthBarOpacity = opacity
                changed = true
            end
            if raidProfile.party_healthBarOpacity ~= opacity then
                raidProfile.party_healthBarOpacity = opacity
                changed = true
            end
        end
    end

    KeepResourceBarsColored()
    return changed
end

-- Rebuilt only after ApplyAll or a mode change; the raid hooks read it per color update.
local appearanceToken, raidAppearanceToken, partyAppearanceToken

local function InvalidateAppearanceToken()
    appearanceToken = nil
end

local function AppearanceToken()
    if not appearanceToken then
        appearanceToken = table.concat({
            tostring(InariDB.appearanceMode),
            tostring(InariDB.classBackground),
            tostring(InariDB.tint),
            tostring(InariDB.healthBarOpacity),
            tostring(InariDB.darkOpacity),
            tostring(InariDB.enabled),
        }, ":")
        raidAppearanceToken = appearanceToken .. ":false"
        partyAppearanceToken = appearanceToken .. ":true"
    end
    return appearanceToken
end

local function RaidAppearanceToken(isParty)
    AppearanceToken()
    return isParty and partyAppearanceToken or raidAppearanceToken
end

local function ClearBackgroundTintCache(bg)
    if not bg then return end
    bg._inariR, bg._inariG, bg._inariB = nil, nil, nil
end

local function UnwrapHealthAppearance(health)
    if not health then return end
    if health.PostUpdateColor == health._inariPostUpdateColor then
        health.PostUpdateColor = health._inariOriginalPostUpdateColor
    end
    health._inariPostUpdateColor = nil
    health._inariOriginalPostUpdateColor = nil
    health._inariDarkModeOverride = nil
    health._inariAppearanceToken = nil
    health._inariBgAnchored = nil
    health._inariRaidToken = nil
    ClearBackgroundTintCache(health.bg or health._inariBg)
end

local function SetInariAppearanceMode(mode)
    EnsureDB()
    if mode ~= "class" then mode = "dark" end

    InariDB.appearanceMode = mode
    InariDB.forceDarkMode = mode == "dark"
    InariDB.classBackground = mode == "dark"
    InvalidateAppearanceToken()

    ApplyConfiguredProfileSettings()
    State.discoveredFramesCached = false
    State.framesPatched = false

    for _, frameName in pairs(FRAME_NAMES) do
        local frame = _G[frameName]
        UnwrapHealthAppearance(frame and frame.Health)
    end
    for _, frame in ipairs(State.discoveredUnitFrames or {}) do
        UnwrapHealthAppearance(frame and frame.Health)
    end

    if EllesmereUI and type(EllesmereUI.SetDarkModeAll) == "function" then
        pcall(EllesmereUI.SetDarkModeAll, mode == "dark", function(provider)
            return not provider or provider.id ~= "resourceBars"
        end)
    end
    KeepResourceBarsColored()
    if ReloadEllesmereFrames then ReloadEllesmereFrames() end

    if ScheduleApply then
        ScheduleApply(0.05, true)
        ScheduleApply(0.25, true)
        ScheduleApply(0.60, true)
    end

    return mode
end

local function SafeValue(value)
    if issecretvalue and issecretvalue(value) then return nil end
    return value
end

local function ClassColorRGB(classToken)
    classToken = SafeValue(classToken)
    if not classToken then return end
    if EllesmereUI and EllesmereUI.GetClassColor then
        local color = EllesmereUI.GetClassColor(classToken)
        if color then return color.r, color.g, color.b end
    end
    local color = RAID_CLASS_COLORS and RAID_CLASS_COLORS[classToken]
    if color then return color.r, color.g, color.b end
end

local function GetClassTint(unit)
    local tint = InariDB.tint or 0.75
    local r, g, b

    if unit and UnitExists(unit) then
        if SafeValue(UnitIsPlayer(unit)) then
            local _, classToken = UnitClass(unit)
            r, g, b = ClassColorRGB(classToken)
        end
        if not r then
            local reaction = SafeValue(UnitReaction(unit, "player"))
            local reactionColor = reaction and FACTION_BAR_COLORS and FACTION_BAR_COLORS[reaction]
            if reactionColor then
                r, g, b = reactionColor.r, reactionColor.g, reactionColor.b
            end
        end
    end

    if not r then
        local _, playerClass = UnitClass("player")
        r, g, b = ClassColorRGB(playerClass)
    end

    if r then
        return r * tint, g * tint, b * tint
    end
end

local function GetHealthBackground(health)
    return health and (health.bg or health._inariBg) or nil
end

local function RestoreBackgroundColor(health, unit)
    local bg = GetHealthBackground(health)
    if not health or not bg then return end
    local settings = GetUnitSettings(unit)
    local darkMode = health._inariDarkModeOverride
    if darkMode == nil then darkMode = IsDarkMode() end
    if darkMode then
        ClearBackgroundTintCache(bg)
        bg:SetColorTexture(0x4f / 255, 0x4f / 255, 0x4f / 255, 1)
        return
    end

    if health._inariBgOwner then
        bg:ClearAllPoints()
        bg:SetAllPoints(health._inariBgOwner)
    end

    local customBg = settings and settings.customBgColor
    ClearBackgroundTintCache(bg)
    if customBg then
        bg:SetColorTexture(customBg.r, customBg.g, customBg.b, 1)
    else
        bg:SetColorTexture(17 / 255, 17 / 255, 17 / 255, 1)
    end
end

local function AnchorMissingHealthBackground(health)
    local bg = GetHealthBackground(health)
    if not health or not bg then return end
    local darkMode = health._inariDarkModeOverride
    if darkMode == nil then darkMode = IsDarkMode() end
    if not darkMode then return end
    local reverse = health._inariReverseFill or (health.GetReverseFill and health:GetReverseFill()) or false
    if health._inariBgAnchored == reverse then return end
    local fill = health:GetStatusBarTexture()
    if not fill then return end

    bg:ClearAllPoints()
    if reverse then
        bg:SetPoint("TOPLEFT", health, "TOPLEFT", 0, 0)
        bg:SetPoint("BOTTOMRIGHT", fill, "BOTTOMLEFT", 0, 0)
    else
        bg:SetPoint("TOPLEFT", fill, "TOPRIGHT", 0, 0)
        bg:SetPoint("BOTTOMRIGHT", health, "BOTTOMRIGHT", 0, 0)
    end
    health._inariBgAnchored = reverse
end

local function ApplyHealthPatch(health, unit, color)
    if not InariDB.enabled or not health then return end

    local settings = GetUnitSettings(unit)
    if settings then
        health._inariReverseFill = settings.healthReverseFill and true or false
        if health.SetReverseFill then health:SetReverseFill(health._inariReverseFill) end
    end

    local darkMode = IsDarkMode()
    local fill = health.GetStatusBarTexture and health:GetStatusBarTexture()
    local alpha = GetHealthAlpha(unit)
    if not darkMode or InariDB.darkOpacity then
        if fill then fill:SetAlpha(alpha) end
        local bg = GetHealthBackground(health)
        if bg then bg:SetAlpha(alpha) end
    end

    AnchorMissingHealthBackground(health)

    local bg = GetHealthBackground(health)
    if bg then
        if InariDB.classBackground then
            local r, g, b = GetClassTint(unit)
            if r then
                bg._inariR, bg._inariG, bg._inariB = r, g, b
                bg:SetColorTexture(r, g, b, 1)
            end
        else
            RestoreBackgroundColor(health, unit)
        end
    end
end

local DIRECT_UNITS = {
    player = true,
    target = true,
    focus = true,
    pet = true,
    targettarget = true,
    focustarget = true,
}

local function NormalizeUnit(unit)
    if type(unit) ~= "string" then return nil end
    unit = string.lower(unit)
    if DIRECT_UNITS[unit] or unit == "party" or unit == "raid" then return unit end
    if unit:match("^boss%d+$") or unit:match("^party%d+$") or unit:match("^raid%d+$") then return unit end
end

local function GetFrameName(frame)
    return frame and frame.GetName and frame:GetName() or nil
end

local function ResolveFrameUnit(frame, fallbackUnit)
    local unit = NormalizeUnit(fallbackUnit)

    if not unit and frame then
        unit = NormalizeUnit(frame.unit) or NormalizeUnit(frame._unit)
    end

    if not unit and frame and frame.GetAttribute then
        unit = NormalizeUnit(frame:GetAttribute("unit")) or NormalizeUnit(frame:GetAttribute("oUF-guessUnit"))
    end

    if unit == "party" or unit == "raid" then
        local index = GetFrameName(frame) and GetFrameName(frame):match("(%d+)$")
        if index then unit = unit .. index end
    end

    return unit
end

local function RestoreFrameObject(frame, fallbackUnit)
    local health = frame and frame.Health
    if not health then return end

    local unit = ResolveFrameUnit(frame, fallbackUnit or health._inariUnit)
    if not unit then return end

    RestoreBackgroundColor(health, unit)

    local alpha = GetHealthAlpha(unit)
    local fill = health.GetStatusBarTexture and health:GetStatusBarTexture()
    if fill then fill:SetAlpha(alpha) end
    local bg = GetHealthBackground(health)
    if bg then bg:SetAlpha(alpha) end
end

local function RestoreFrame(unit, frameName)
    RestoreFrameObject(_G[frameName], unit)
end

ReloadEllesmereFrames = function()
    local reloaded = false
    if type(_G._EUF_ReloadFrames) == "function" then
        _G._EUF_ReloadFrames()
        reloaded = true
    end
    if type(_G._ERF_RefreshAll) == "function" then
        _G._ERF_RefreshAll()
        reloaded = true
    end
    return reloaded
end

local RestoreEllesmereRaidFrames

local function RestoreAll()
    if ReloadEllesmereFrames() then
        if ns.RefreshFrameShadows then ns.RefreshFrameShadows() end
        return
    end

    for unit, frameName in pairs(FRAME_NAMES) do
        RestoreFrame(unit, frameName)
    end

    if RestoreEllesmereRaidFrames then RestoreEllesmereRaidFrames() end
    if ns.RefreshFrameShadows then ns.RefreshFrameShadows() end
end

local function WrapHealth(unit, health)
    if not health then return false end
    health._inariUnit = unit

    local token = AppearanceToken()
    if health._inariAppearanceToken ~= token then
        UnwrapHealthAppearance(health)
        health._inariAppearanceToken = token
    end

    if health.PostUpdateColor ~= health._inariPostUpdateColor then
        health._inariOriginalPostUpdateColor = health.PostUpdateColor
        health._inariPostUpdateColor = function(self, eventUnit, color)
            local original = self._inariOriginalPostUpdateColor
            if original and original ~= self._inariPostUpdateColor then
                original(self, eventUnit, color)
            end
            ApplyHealthPatch(self, self._inariUnit or eventUnit, color)
        end
        health.PostUpdateColor = health._inariPostUpdateColor
    end

    ApplyHealthPatch(health, unit)
    return true
end

local function PatchFrameObject(frame, fallbackUnit)
    local health = frame and frame.Health
    if not health then return nil end

    local unit = ResolveFrameUnit(frame, fallbackUnit or health._inariUnit)
    if not unit then return nil end

    if WrapHealth(unit, health) then return health end
end

local function PatchFrame(unit, frameName)
    return PatchFrameObject(_G[frameName], unit)
end

local function GetRaidFrameProfileValue(key, isParty)
    local profile = GetEllesmereRaidFramesProfile()
    if type(profile) ~= "table" then return nil end
    if isParty then
        local partyValue = profile["party_" .. key]
        if partyValue ~= nil then return partyValue end
    end
    return profile[key]
end

local function IsRaidFrameDarkMode(isParty)
    return GetRaidFrameProfileValue("healthColorMode", isParty) == "dark"
end

local function GetRaidFrameHealthAlpha(isParty)
    local opacity = GetRaidFrameProfileValue("healthBarOpacity", isParty) or 100
    if opacity <= 1 then opacity = opacity * 100 end
    if opacity < 0 then opacity = 0 end
    if opacity > 100 then opacity = 100 end
    return opacity / 100
end

local function GetRaidFrameClassTint(unit)
    local r, g, b = GetClassTint(unit)
    if r then return r, g, b end
end

local function RestoreRaidFrameBackground(health, isParty)
    local bg = GetHealthBackground(health)
    if not health or not bg then return end

    if IsRaidFrameDarkMode(isParty) then
        ClearBackgroundTintCache(bg)
        bg:SetColorTexture(0x4f / 255, 0x4f / 255, 0x4f / 255, 1)
        return
    end

    if health._inariBgOwner then
        bg:ClearAllPoints()
        bg:SetAllPoints(health._inariBgOwner)
    end

    local bgColor = GetRaidFrameProfileValue("customBgColor", isParty) or { r = 17 / 255, g = 17 / 255, b = 17 / 255 }
    local bgDarkness = GetRaidFrameProfileValue("bgDarkness", isParty) or 50
    ClearBackgroundTintCache(bg)
    bg:SetColorTexture(bgColor.r, bgColor.g, bgColor.b, bgDarkness / 100)
end

local ApplyRaidFrameHealthPatch
ApplyRaidFrameHealthPatch = function(button, health, bg, unit, isParty)
    if not InariDB.enabled or not health then return end

    local token = RaidAppearanceToken(isParty)
    local same = health._inariRaidToken == token and health._inariRaidUnit == unit
    if not same then
        health._inariRaidToken = token
        health._inariRaidUnit = unit
        health._inariUnit = unit
        health._inariBg = bg
        health._inariBgOwner = button
        health._inariDarkModeOverride = IsRaidFrameDarkMode(isParty)

        local fill = health.GetStatusBarTexture and health:GetStatusBarTexture()
        if not health._inariDarkModeOverride or InariDB.darkOpacity then
            local alpha = GetRaidFrameHealthAlpha(isParty)
            if fill then fill:SetAlpha(alpha) end
            if bg then bg:SetAlpha(alpha) end
        end

        AnchorMissingHealthBackground(health)
    end

    if bg then
        bg._inariRaidApplying = true
        if InariDB.classBackground then
            local r, g, b = GetRaidFrameClassTint(unit)
            if r then
                bg._inariR, bg._inariG, bg._inariB = r, g, b
                bg:SetColorTexture(r, g, b, 1)
            end
        else
            RestoreRaidFrameBackground(health, isParty)
        end
        bg._inariRaidApplying = false
    end
end

local function HookRaidFrameBackground(button, health, bg, isParty)
    if not hooksecurefunc or not button or not health or not bg or bg._inariRaidBgHooked then return end
    bg._inariRaidBgHooked = true
    hooksecurefunc(bg, "SetColorTexture", function(self)
        if self._inariRaidApplying then return end
        ApplyRaidFrameHealthPatch(button, health, self, ResolveFrameUnit(button) or health._inariUnit, isParty)
    end)
end

local function FindRaidFrameHealth(button)
    if not button or not button.GetChildren then return nil end
    if State.raidFrameHealthCache[button] then return State.raidFrameHealthCache[button] end

    local best
    local bestHeight = -1
    local children = { button:GetChildren() }
    for _, child in ipairs(children) do
        local objectType = child.GetObjectType and child:GetObjectType() or nil
        if objectType == "StatusBar" and child.GetStatusBarTexture then
            local height = child.GetHeight and child:GetHeight() or 0
            if height > bestHeight then
                best = child
                bestHeight = height
            end
        end
    end

    State.raidFrameHealthCache[button] = best
    return best
end

local function FindRaidFrameBackground(button)
    if not button or not button.GetRegions then return nil end
    if State.raidFrameBackgroundCache[button] then return State.raidFrameBackgroundCache[button] end

    local regions = { button:GetRegions() }
    for _, region in ipairs(regions) do
        local layer = region.GetDrawLayer and region:GetDrawLayer() or nil
        if layer == "BACKGROUND" and region.SetColorTexture then
            State.raidFrameBackgroundCache[button] = region
            return region
        end
    end
end

local function PatchRaidFrameButton(button, isParty, seenHealth)
    local health = FindRaidFrameHealth(button)
    if not health then return 0 end

    local unit = ResolveFrameUnit(button)
    if not unit then return 0 end

    local bg = FindRaidFrameBackground(button)
    health._inariRaidPatch = { button = button, bg = bg, isParty = isParty }
    HookRaidFrameBackground(button, health, bg, isParty)

    if hooksecurefunc and not health._inariRaidStatusColorHooked then
        health._inariRaidStatusColorHooked = true
        hooksecurefunc(health, "SetStatusBarColor", function(self)
            local patch = self._inariRaidPatch
            if patch then
                ApplyRaidFrameHealthPatch(patch.button, self, patch.bg, ResolveFrameUnit(patch.button) or self._inariUnit, patch.isParty)
            end
        end)
    end

    ApplyRaidFrameHealthPatch(button, health, bg, unit, isParty)

    if seenHealth[health] then return 0 end
    seenHealth[health] = true
    return 1
end

local function PatchHeaderButtons(header, isParty, seenHealth, maxButtons)
    if not header then return 0 end
    local patched = 0
    for index = 1, maxButtons do
        patched = patched + PatchRaidFrameButton(header[index], isParty, seenHealth)
    end
    return patched
end

local function PatchEllesmereRaidFrames(seenHealth)
    local patched = 0
    for group = 1, 8 do
        patched = patched + PatchHeaderButtons(_G["ERFGroupHeader" .. group], false, seenHealth, 5)
    end
    patched = patched + PatchHeaderButtons(_G.ERFFlatHeader, false, seenHealth, 40)
    patched = patched + PatchHeaderButtons(_G.ERFPartyHeader, true, seenHealth, 5)
    patched = patched + PatchRaidFrameButton(_G.ERFPartySelfButton, true, seenHealth)
    return patched
end

local function RestoreRaidFrameButton(button, isParty)
    local health = FindRaidFrameHealth(button)
    if not health then return end

    local bg = FindRaidFrameBackground(button)
    health._inariBg = bg
    health._inariBgOwner = button
    health._inariDarkModeOverride = IsRaidFrameDarkMode(isParty)

    RestoreRaidFrameBackground(health, isParty)

    local alpha = GetRaidFrameHealthAlpha(isParty)
    local fill = health.GetStatusBarTexture and health:GetStatusBarTexture()
    if fill then fill:SetAlpha(alpha) end
    if bg then bg:SetAlpha(alpha) end
end

local function RestoreRaidHeaderButtons(header, isParty, maxButtons)
    if not header then return end
    for index = 1, maxButtons do
        RestoreRaidFrameButton(header[index], isParty)
    end
end

RestoreEllesmereRaidFrames = function()
    for group = 1, 8 do
        RestoreRaidHeaderButtons(_G["ERFGroupHeader" .. group], false, 5)
    end
    RestoreRaidHeaderButtons(_G.ERFFlatHeader, false, 40)
    RestoreRaidHeaderButtons(_G.ERFPartyHeader, true, 5)
    RestoreRaidFrameButton(_G.ERFPartySelfButton, true)
end

local function SetAllHealthOpacity(value)
    local changed = false
    local profile = GetEllesmereProfile()
    if type(profile) == "table" then
        for _, key in ipairs(DB_UNITS) do
            if type(profile[key]) == "table" then
                profile[key].healthBarOpacity = value
                changed = true
            end
        end
    end

    local raidProfile = GetEllesmereRaidFramesProfile()
    if type(raidProfile) == "table" then
        raidProfile.healthBarOpacity = value
        raidProfile.party_healthBarOpacity = value
        changed = true
    end

    return changed
end


function ns.PatchAllFrames()
    local patched = 0
    local seenHealth = {}
    for unit, frameName in pairs(FRAME_NAMES) do
        local healthBar = PatchFrame(unit, frameName)
        if healthBar and not seenHealth[healthBar] then
            seenHealth[healthBar] = true
            patched = patched + 1
        end
    end
    patched = patched + PatchEllesmereRaidFrames(seenHealth)
    return patched
end

function ns.PatchUnit(unit)
    if not unit then return end
    local frameName = FRAME_NAMES[unit]
    if frameName then PatchFrame(unit, frameName) end
end

function ns.PatchRaidAndParty()
    local seenHealth = {}
    PatchEllesmereRaidFrames(seenHealth)
    for i = 1, 4 do
        PatchFrame("party" .. i, FRAME_NAMES["party" .. i])
    end
end

ns.RestoreAll = RestoreAll
ns.ReloadEllesmereFrames = ReloadEllesmereFrames
ns.GetAppearanceMode = GetAppearanceMode
ns.SetInariAppearanceMode = SetInariAppearanceMode
ns.ApplyConfiguredProfileSettings = ApplyConfiguredProfileSettings
ns.SetAllHealthOpacity = SetAllHealthOpacity
ns.InvalidateAppearanceToken = InvalidateAppearanceToken
