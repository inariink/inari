local ADDON_NAME, ns = ...
local CONST = ns.CONST
local State = ns.State
local EnsureDB = ns.EnsureDB
local TryLoadAddon = ns.TryLoadAddon
local RegisterMedia = ns.RegisterMedia
local STATUSBAR_MEDIA = ns.STATUSBAR_MEDIA
local EnsureEllesmereAddonProfile = ns.EnsureEllesmereAddonProfile
local GetEllesmereAddonProfile = ns.GetEllesmereAddonProfile
local ApplyChatSettings

local function CopyColor(color)
    return { r = color.r, g = color.g, b = color.b }
end

local function SameColor(left, right)
    if type(left) ~= "table" then return false end
    return math.abs((left.r or 0) - right.r) < 0.00001 and
        math.abs((left.g or 0) - right.g) < 0.00001 and
        math.abs((left.b or 0) - right.b) < 0.00001
end

local function ApplyEllesmereThemeSettings(forceLive, refreshOptions)
    if not InariDB.enabled or not InariDB.forceEUITheme then return false end

    local root = _G.EllesmereUIDB
    if type(root) ~= "table" then return false end

    local changed = false
    if root.activeTheme ~= CONST.THEME_NAME then
        root.activeTheme = CONST.THEME_NAME
        changed = true
    end

    if not SameColor(root.accentColor, CONST.THEME_COLOR) then
        root.accentColor = CopyColor(CONST.THEME_COLOR)
        changed = true
    end

    if root.useClassAccentColor ~= false then
        root.useClassAccentColor = false
        changed = true
    end

    if not SameColor(root.customAccentColor, CONST.ACCENT_COLOR) then
        root.customAccentColor = CopyColor(CONST.ACCENT_COLOR)
        changed = true
    end

    if EllesmereUI and (changed or forceLive or refreshOptions) then
        if type(EllesmereUI.SetActiveTheme) == "function" then
            EllesmereUI.SetActiveTheme(CONST.THEME_NAME)
        end

        if type(EllesmereUI.SetAccentColor) == "function" then
            EllesmereUI.SetAccentColor(CONST.ACCENT_COLOR.r, CONST.ACCENT_COLOR.g, CONST.ACCENT_COLOR.b)
        elseif type(EllesmereUI.ApplyAccentColorLive) == "function" then
            EllesmereUI.ApplyAccentColorLive(CONST.ACCENT_COLOR.r, CONST.ACCENT_COLOR.g, CONST.ACCENT_COLOR.b)
        end

        if refreshOptions and type(EllesmereUI.RefreshPage) == "function" then
            EllesmereUI:RefreshPage()
        end
    end

    return changed
end

local function ApplyChatSidebarPosition()
    local cf1 = _G.ChatFrame1
    local getData = EllesmereUI and EllesmereUI._chatCFD
    local data = cf1 and getData and getData(cf1)
    local sidebar = data and data.sidebar
    local bg = data and data.bg
    if not sidebar or not bg then return false end

    sidebar:ClearAllPoints()
    if InariDB.forceChatSidebarRight then
        sidebar:SetPoint("TOPLEFT", bg, "TOPRIGHT", 0, 0)
        sidebar:SetPoint("BOTTOMLEFT", bg, "BOTTOMRIGHT", 0, 0)
    else
        sidebar:SetPoint("TOPRIGHT", bg, "TOPLEFT", 0, 0)
        sidebar:SetPoint("BOTTOMRIGHT", bg, "BOTTOMLEFT", 0, 0)
    end

    if data.sidebarDiv then
        data.sidebarDiv:ClearAllPoints()
        if InariDB.forceChatSidebarRight then
            data.sidebarDiv:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 0, 0)
            data.sidebarDiv:SetPoint("BOTTOMLEFT", sidebar, "BOTTOMLEFT", 0, 0)
        else
            data.sidebarDiv:SetPoint("TOPRIGHT", sidebar, "TOPRIGHT", 0, 0)
            data.sidebarDiv:SetPoint("BOTTOMRIGHT", sidebar, "BOTTOMRIGHT", 0, 0)
        end
    end

    return true
end

local function ApplyChatRuntimePreset(chat)
    local getData = EllesmereUI and EllesmereUI._chatCFD
    if not getData then return end

    for i = 1, 20 do
        local cf = _G["ChatFrame" .. i]
        local data = cf and getData(cf)
        if data and data.bg then
            local bgTex = data.bg:GetRegions()
            if bgTex and bgTex.SetColorTexture then
                bgTex:SetColorTexture(chat.bgR, chat.bgG, chat.bgB, chat.bgAlpha)
            end

            local editBox = _G["ChatFrame" .. i .. "EditBox"]
            if editBox then
                editBox:ClearAllPoints()
                if chat.inputOnTop then
                    editBox:SetPoint("TOPLEFT", cf, "TOPLEFT", -10, 3)
                    editBox:SetPoint("TOPRIGHT", cf, "TOPRIGHT", 5, 3)
                else
                    editBox:SetPoint("TOPLEFT", cf, "BOTTOMLEFT", -10, -8)
                    editBox:SetPoint("TOPRIGHT", cf, "BOTTOMRIGHT", 5, -8)
                end
            end

            if data.inputDiv then
                data.inputDiv:ClearAllPoints()
                if chat.inputOnTop then
                    data.inputDiv:SetPoint("TOPLEFT", cf, "TOPLEFT", -10, -20)
                    data.inputDiv:SetPoint("TOPRIGHT", cf, "TOPRIGHT", 10, -20)
                else
                    data.inputDiv:SetPoint("BOTTOMLEFT", cf, "BOTTOMLEFT", -10, -8)
                    data.inputDiv:SetPoint("BOTTOMRIGHT", cf, "BOTTOMRIGHT", 10, -8)
                end
            end

            data.bg:ClearAllPoints()
            data.bg:SetPoint("TOPLEFT", cf, "TOPLEFT", -10, 3)
            if chat.inputOnTop then
                data.bg:SetPoint("BOTTOMRIGHT", cf, "BOTTOMRIGHT", 10, -6)
            else
                data.bg:SetPoint("BOTTOMRIGHT", editBox or cf, "BOTTOMRIGHT", 5, editBox and -4 or -6)
            end

            if cf.FontStringContainer then
                cf.FontStringContainer:ClearAllPoints()
                if chat.inputOnTop then
                    cf.FontStringContainer:SetPoint("TOPLEFT", cf, "TOPLEFT", 0, -22)
                else
                    cf.FontStringContainer:SetPoint("TOPLEFT", cf, "TOPLEFT", 0, -6)
                end
                cf.FontStringContainer:SetPoint("BOTTOMRIGHT", cf, "BOTTOMRIGHT", 0, 0)
            end

            if data.scrollTrack then
                data.scrollTrack:ClearAllPoints()
                if chat.inputOnTop then
                    data.scrollTrack:SetPoint("TOPRIGHT", cf, "TOPRIGHT", 5, -22)
                else
                    data.scrollTrack:SetPoint("TOPRIGHT", cf, "TOPRIGHT", 5, -2)
                end
                data.scrollTrack:SetPoint("BOTTOMRIGHT", cf, "BOTTOMRIGHT", 5, 2)
            end
        end

        local tab = _G["ChatFrame" .. i .. "Tab"]
        local tabData = tab and getData(tab)
        if tabData and tabData.bg and tabData.bg.SetColorTexture then
            local active = tabData.underline and tabData.underline:IsShown()
            tabData.bg:SetColorTexture(chat.bgR, chat.bgG, chat.bgB, active and chat.bgAlpha or (chat.bgAlpha * 0.67))
        end
    end

    local cf1 = _G.ChatFrame1
    local data = cf1 and getData(cf1)
    if not data then return end

    if data.sidebar then
        data.sidebar:SetAlpha(1)
        data.sidebar:EnableMouse(true)
        local sbBg = data.sidebar:GetRegions()
        if sbBg and sbBg.SetColorTexture then
            sbBg:SetColorTexture(chat.bgR, chat.bgG, chat.bgB, chat.bgAlpha)
        end
        if sbBg and sbBg.SetShown then
            sbBg:SetShown(not chat.hideSidebarBg)
        end
    end

    if data.sidebarDiv then
        data.sidebarDiv:SetShown(not chat.hideSidebarBg)
    end

    local iconR, iconG, iconB = chat.iconR or 1, chat.iconG or 1, chat.iconB or 1
    for _, button in ipairs({ data.friendsBtn, data.copyBtn, data.portalBtn, data.voiceBtn, data.settingsBtn, data.scrollBtn }) do
        if button then
            button:SetScale(chat.sidebarIconScale or 1)
            if button._icon and button._icon.SetVertexColor then
                button._icon:SetVertexColor(iconR, iconG, iconB, 0.4)
            end
        end
    end

    if data.friendsBtn then data.friendsBtn:SetShown(chat.showFriends ~= false) end
    if data.copyBtn then data.copyBtn:SetShown(chat.showCopy ~= false) end
    if data.portalBtn then data.portalBtn:SetShown(chat.showPortals ~= false) end
    if data.voiceBtn then data.voiceBtn:SetShown(chat.showVoice ~= false) end
    if data.settingsBtn then data.settingsBtn:SetShown(chat.showSettings ~= false) end
    if data.scrollBtn then data.scrollBtn:SetShown(chat.showScroll ~= false) end
end

-- applyPreset writes inari's full chat look (installer / "install settings");
-- without it only the sidebar side is kept in sync.
ApplyChatSettings = function(applyPreset)
    TryLoadAddon("EllesmereUIChat")

    local profile = EnsureEllesmereAddonProfile("EllesmereUIChat")
    if type(profile) ~= "table" then return false end

    profile.chat = profile.chat or {}
    local chat = profile.chat
    local changed = false

    if applyPreset then
        local preset = {
            enabled = true,
            visibility = "always",
            visOnlyInstances = false,
            visHideHousing = false,
            visHideMounted = false,
            visHideNoTarget = false,
            visHideNoEnemy = false,
            bgAlpha = 0,
            bgR = 0.03,
            bgG = 0.045,
            bgB = 0.05,
            idleFadeDelay = 15,
            idleFadeStrength = 40,
            font = "__global",
            outlineMode = "__global",
            timestampFormat = "%I:%M ",
            sidebarVisibility = "mouseover",
            showFriends = true,
            showCopy = true,
            showPortals = true,
            showVoice = false,
            showSettings = true,
            showScroll = true,
            iconR = 1,
            iconG = 1,
            iconB = 1,
            iconUseAccent = false,
            hideSidebarBg = false,
            sidebarIconScale = 1.0,
            freeMoveIcons = false,
            hideTooltipOnHover = true,
            hideBorders = false,
            lockChatSize = false,
            inputOnTop = true,
            whisperSoundKey = "none",
        }

        for key, value in pairs(preset) do
            if chat[key] ~= value then
                chat[key] = value
                changed = true
            end
        end

        local iconOrder = chat.sidebarIconOrder
        if type(iconOrder) ~= "table"
            or iconOrder.showCopy ~= 1
            or iconOrder.showPortals ~= 2
            or iconOrder.showVoice ~= 3
            or iconOrder.showSettings ~= 4 then
            chat.sidebarIconOrder = {
                showCopy = 1,
                showPortals = 2,
                showVoice = 3,
                showSettings = 4,
            }
            changed = true
        end
    end

    if chat.sidebarRight ~= InariDB.forceChatSidebarRight then
        chat.sidebarRight = InariDB.forceChatSidebarRight and true or false
        changed = true
    end

    ApplyChatSidebarPosition()
    if applyPreset then ApplyChatRuntimePreset(chat) end
    return changed
end

local function GetOverrideBarIndexSafe()
    if GetOverrideBarIndex then return GetOverrideBarIndex() end
    if C_ActionBar and C_ActionBar.GetOverrideBarIndex then return C_ActionBar.GetOverrideBarIndex() end
    return 14
end

local function GetVehicleBarIndexSafe()
    if GetVehicleBarIndex then return GetVehicleBarIndex() end
    if C_ActionBar and C_ActionBar.GetVehicleBarIndex then return C_ActionBar.GetVehicleBarIndex() end
    return 12
end

local INARI_ACTION_BAR_MODIFIER_STATES = {
    { id = "alt",   macro = "[mod:alt]" },
    { id = "shift", macro = "[mod:shift]" },
    { id = "ctrl",  macro = "[mod:ctrl]" },
}

local INARI_ACTION_BAR_CLASS_STATES = {
    DRUID = {
        { id = "prowl",   macro = "[bonusbar:1,stealth]" },
        { id = "cat",     macro = "[bonusbar:1]" },
        { id = "tree",    macro = "[bonusbar:2]" },
        { id = "bear",    macro = "[bonusbar:3]" },
        { id = "moonkin", macro = "[bonusbar:4]" },
    },
    ROGUE = {
        { id = "stealth", macro = "[bonusbar:1]" },
    },
    WARRIOR = {
        { id = "battle",    macro = "[bonusbar:1]" },
        { id = "defensive", macro = "[bonusbar:2]" },
    },
    EVOKER = {
        { id = "soar", macro = "[bonusbar:1]" },
    },
}

local INARI_ACTION_BAR_CLASS_DEFAULTS = {
    DRUID = { prowl = 7, cat = 7, tree = 8, bear = 9, moonkin = 10 },
    ROGUE = { stealth = 7 },
}

local function BuildInariMainBarPagingConditions(pagingConfig, disableClassPaging)
    local parts = {
        "[overridebar] " .. GetOverrideBarIndexSafe(),
        "[vehicleui][possessbar] " .. GetVehicleBarIndexSafe(),
    }

    if type(pagingConfig) == "table" then
        for _, state in ipairs(INARI_ACTION_BAR_MODIFIER_STATES) do
            local page = pagingConfig[state.id]
            if page then
                parts[#parts + 1] = state.macro .. " " .. page
            end
        end
    end

    local _, class = UnitClass("player")
    local classStates = not disableClassPaging and INARI_ACTION_BAR_CLASS_STATES[class]
    if classStates then
        local defaults = INARI_ACTION_BAR_CLASS_DEFAULTS[class]
        for _, state in ipairs(classStates) do
            local page = type(pagingConfig) == "table" and pagingConfig[state.id] or nil
            if page then
                parts[#parts + 1] = state.macro .. " " .. page
            elseif page == nil and defaults and defaults[state.id] then
                parts[#parts + 1] = state.macro .. " " .. defaults[state.id]
            end
        end
    end

    parts[#parts + 1] = "[bonusbar:5] 11"
    for i = 2, (NUM_ACTIONBAR_PAGES or 6) do
        parts[#parts + 1] = "[bar:" .. i .. "] " .. i
    end
    parts[#parts + 1] = "1"
    return table.concat(parts, "; ")
end

local function ApplyInariMainBarKeybindOverride()
    if InCombatLockdown and InCombatLockdown() then return false end

    if not State.actionBarPagingBindOwner then
        State.actionBarPagingBindOwner = CreateFrame("Frame", "InariActionBarPagingBindOwner", UIParent)
    end
    ClearOverrideBindings(State.actionBarPagingBindOwner)

    if InariDB.disableEllesmereActionBarPaging ~= true then
        return true
    end

    for i = 1, 12 do
        local button = _G["EABButton" .. i]
        local buttonName = button and button:GetName()
        if buttonName then
            local key1, key2 = GetBindingKey("ACTIONBUTTON" .. i)
            if key1 then SetOverrideBindingClick(State.actionBarPagingBindOwner, true, key1, buttonName) end
            if key2 then SetOverrideBindingClick(State.actionBarPagingBindOwner, true, key2, buttonName) end
        end
    end

    return true
end

local function HookInariMainBarKeybindOverride()
    if State.actionBarPagingKeybindHooked or type(_G._EAB_UpdateKeybinds) ~= "function" or not hooksecurefunc then return end
    local ok = pcall(hooksecurefunc, "_EAB_UpdateKeybinds", function()
        if type(InariDB) == "table" and InariDB.disableEllesmereActionBarPaging == true then
            C_Timer.After(0, ApplyInariMainBarKeybindOverride)
        end
    end)
    State.actionBarPagingKeybindHooked = ok and true or false
end

local function ApplyEllesmereActionBarPagingOverride()
    EnsureDB()
    if InCombatLockdown and InCombatLockdown() then
        if not State.actionBarPagingDeferFrame then
            State.actionBarPagingDeferFrame = CreateFrame("Frame")
            State.actionBarPagingDeferFrame:SetScript("OnEvent", function(self)
                self:UnregisterEvent("PLAYER_REGEN_ENABLED")
                ApplyEllesmereActionBarPagingOverride()
            end)
        end
        State.actionBarPagingDeferFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
        return false
    end

    HookInariMainBarKeybindOverride()
    local profile = GetEllesmereAddonProfile and GetEllesmereAddonProfile("EllesmereUIActionBars")
    local pagingConfig = profile and profile.bars and profile.bars.MainBar and profile.bars.MainBar.paging
    local disableClassPaging = InariDB.disableEllesmereActionBarPaging == true
    if not disableClassPaging and not State.actionBarPagingOverrideApplied then return false end

    local frame = _G.EABBar_MainBar
    if not frame then return false end

    if type(_G._EAB_UpdateKeybinds) == "function" then
        _G._EAB_UpdateKeybinds()
    end

    if UnregisterStateDriver then
        UnregisterStateDriver(frame, "page")
    end
    if RegisterStateDriver then
        RegisterStateDriver(frame, "page", BuildInariMainBarPagingConditions(pagingConfig, disableClassPaging))
    end

    ApplyInariMainBarKeybindOverride()
    State.actionBarPagingOverrideApplied = disableClassPaging

    return true
end

local function ApplyBlizzardUIEnhancedSettings()
    TryLoadAddon("EllesmereUIBlizzardSkin")
    RegisterMedia()

    if type(_G.EllesmereUIDB) ~= "table" then _G.EllesmereUIDB = {} end
    local db = _G.EllesmereUIDB
    local changed = false

    local function Set(key, value)
        if db[key] ~= value then
            db[key] = value
            changed = true
        end
    end

    Set("customTooltips", true)
    Set("accentReskinElements", false)
    Set("tooltipPlayerTitles", true)
    Set("tooltipFontScale", 1.0)
    Set("uberTooltipsManual", true)
    Set("uberTooltips", true)
    Set("tooltipMythicScore", true)
    Set("reskinQueuePopup", true)
    Set("showQueueTimer", true)
    Set("reskinGameMenu", true)
    Set("reskinGreatVault", true)

    Set("themedCharacterSheet", true)
    Set("showMythicRating", false)
    Set("showItemLevel", true)
    Set("showUpgradeTrack", true)
    Set("showEnchants", true)
    Set("showGems", true)

    Set("themedInspectSheet", true)
    Set("inspectShowEnchants", true)
    Set("inspectShowItemLevel", true)
    Set("inspectShowUpgradeTrack", true)

    local statCategories = {
        "Attributes",
        "SecondaryStats",
        "Tertiary",
        "Attack",
        "Defense",
        "Crests",
        "PvP",
    }
    for _, key in ipairs(statCategories) do
        Set("showStatCategory_" .. key, true)
    end

    Set("showSecondaryRaw", false)
    Set("showSecondaryBoth", false)
    Set("showTertiaryRaw", false)
    Set("showTertiaryBoth", false)

    for _, key in ipairs({ "Myth", "Hero", "Champion", "Veteran", "Adventurer" }) do
        Set("showCrest_" .. key, true)
    end

    db.statCategoryColors = db.statCategoryColors or {}
    db.statCategoryUseColor = db.statCategoryUseColor or {}
    local colors = {
        ["Attributes"] = { r = 0.047, g = 0.824, b = 0.616 },
        ["Secondary Stats"] = { r = 0.471, g = 0.255, b = 0.784 },
        ["Tertiary Stats"] = { r = 0.859, g = 0.325, b = 0.855 },
        ["Attack"] = { r = 1.000, g = 0.353, b = 0.122 },
        ["Defense"] = { r = 0.247, g = 0.655, b = 1.000 },
        ["Crests"] = { r = 1.000, g = 0.784, b = 0.341 },
        ["PvP"] = { r = 0.671, g = 0.431, b = 0.349 },
    }
    for key, color in pairs(colors) do
        local current = db.statCategoryColors[key]
        if type(current) ~= "table"
            or current.r ~= color.r
            or current.g ~= color.g
            or current.b ~= color.b then
            db.statCategoryColors[key] = { r = color.r, g = color.g, b = color.b }
            changed = true
        end
        if db.statCategoryUseColor[key] ~= true then
            db.statCategoryUseColor[key] = true
            changed = true
        end
    end

    if EllesmereUI then
        if EllesmereUI._refreshStatsVisibility then pcall(EllesmereUI._refreshStatsVisibility) end
        if EllesmereUI._refreshStatFormats then pcall(EllesmereUI._refreshStatFormats) end
        if EllesmereUI._refreshCharacterSheetColors then pcall(EllesmereUI._refreshCharacterSheetColors) end
        if EllesmereUI._refreshItemLevelVisibility then pcall(EllesmereUI._refreshItemLevelVisibility) end
        if EllesmereUI._refreshUpgradeTrackVisibility then pcall(EllesmereUI._refreshUpgradeTrackVisibility) end
        if EllesmereUI._refreshEnchantsVisibility then pcall(EllesmereUI._refreshEnchantsVisibility) end
        if EllesmereUI._refreshGemsVisibility then pcall(EllesmereUI._refreshGemsVisibility) end
        if EllesmereUI._refreshInspectItemLevelVisibility then pcall(EllesmereUI._refreshInspectItemLevelVisibility) end
        if EllesmereUI._refreshInspectUpgradeTrackVisibility then pcall(EllesmereUI._refreshInspectUpgradeTrackVisibility) end
        if EllesmereUI._refreshInspectEnchantsVisibility then pcall(EllesmereUI._refreshInspectEnchantsVisibility) end
    end

    return true, changed and "Blizz UI Enhanced settings applied" or "Blizz UI Enhanced settings already matched"
end

local function ApplyDamageMeterSettings()
    TryLoadAddon("EllesmereUIDamageMeters")
    RegisterMedia()

    local textureKey = "sm:Skyline Compact"
    local texturePath = STATUSBAR_MEDIA[1] and STATUSBAR_MEDIA[1].path
    if texturePath and type(_G._EDM_BarTextures) == "table" then
        _G._EDM_BarTextures[textureKey] = texturePath
        if type(_G._EDM_BarTextureNames) == "table" then
            _G._EDM_BarTextureNames[textureKey] = "Skyline Compact"
        end
        if type(_G._EDM_BarTextureOrder) == "table" then
            local seen = false
            for _, key in ipairs(_G._EDM_BarTextureOrder) do
                if key == textureKey then
                    seen = true
                    break
                end
            end
            if not seen then
                _G._EDM_BarTextureOrder[#_G._EDM_BarTextureOrder + 1] = textureKey
            end
        end
    end

    local profile = EnsureEllesmereAddonProfile("EllesmereUIDamageMeters")
    if type(profile) ~= "table" then return false, "Damage Meters profile is not available" end

    profile.dm = profile.dm or {}
    local dm = profile.dm
    local changed = false

    local function Set(key, value)
        if dm[key] ~= value then
            dm[key] = value
            changed = true
        end
    end

    local function SetColor(key, r, g, b)
        local current = dm[key]
        if type(current) ~= "table"
            or current.r ~= r
            or current.g ~= g
            or current.b ~= b then
            dm[key] = { r = r, g = g, b = b }
            changed = true
        end
    end

    Set("visibility", "always")
    Set("visOnlyInstances", false)
    Set("visHideHousing", false)
    Set("visHideMounted", false)
    Set("visHideNoTarget", false)
    Set("visHideNoEnemy", false)
    Set("bgAlpha", 0.55)
    Set("bgR", 0)
    Set("bgG", 0)
    Set("bgB", 0)
    Set("showPinnedSelf", false)
    Set("refreshRate", 0.7)

    Set("hdrHeight", 20)
    Set("hdrBgAlpha", 0)
    Set("hdrFontSize", 13)
    Set("hdrIconSize", 22)
    Set("hdrMouseoverIcons", false)
    Set("hdrTextUseAccent", false)
    SetColor("hdrTextColor", 1, 1, 1)
    Set("iconColorUseAccent", false)
    SetColor("iconColor", 1, 1, 1)

    Set("barTexture", textureKey)
    Set("barHeight", 19)
    Set("showClassColor", true)
    Set("barColorUseAccent", false)
    SetColor("barColor", 0.96, 0.55, 0.73)
    Set("barFillAlpha", 1)
    Set("barSpacing", 2)
    Set("iconStyle", "spec")
    Set("showHoverTooltip", true)
    Set("breakdownBarTexture", "match")

    Set("numberFormat", 2)
    Set("hideNumbers", true)
    Set("leftFontSize", 12)
    Set("rightFontSize", 12)
    Set("leftTextUseClassColor", false)
    Set("rightTextUseClassColor", false)
    SetColor("leftTextColor", 1, 1, 1)
    SetColor("rightTextColor", 1, 1, 1)

    Set("standaloneTimer", false)
    Set("standaloneTimerAnchor", "free")

    if EllesmereUI and type(EllesmereUI.RequestVisibilityUpdate) == "function" then
        pcall(EllesmereUI.RequestVisibilityUpdate)
    end
    if EllesmereUI and type(EllesmereUI.RefreshPage) == "function" then
        pcall(EllesmereUI.RefreshPage, EllesmereUI)
    end

    return true, changed and "Damage Meter settings applied" or "Damage Meter settings already matched"
end

local function ApplyEllesmereExtrasSettings()
    local chatChanged = ApplyChatSettings(true)
    local blizzOk, blizzMessage = ApplyBlizzardUIEnhancedSettings()
    if not blizzOk then return false, blizzMessage end
    local dmOk, dmMessage = ApplyDamageMeterSettings()
    if not dmOk then return false, dmMessage end

    if chatChanged or blizzMessage == "Blizz UI Enhanced settings applied" or dmMessage == "Damage Meter settings applied" then
        return true, "Ellesmere chat, Blizz UI Enhanced, and Damage Meter settings applied"
    end
    return true, "Ellesmere chat, Blizz UI Enhanced, and Damage Meter settings already matched"
end


ns.ApplyEllesmereThemeSettings = ApplyEllesmereThemeSettings
ns.ApplyChatSettings = ApplyChatSettings
ns.ApplyEllesmereActionBarPagingOverride = ApplyEllesmereActionBarPagingOverride
ns.ApplyEllesmereExtrasSettings = ApplyEllesmereExtrasSettings
