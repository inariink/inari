local ADDON_NAME, ns = ...

-- WoW Forever (game type "camelot") runs the retail engine with vanilla content and
-- reports a 1.60+ interface (16001). Same range check EllesmereUI_ClientGate.lua uses.
do
    local iface = select(4, GetBuildInfo())
    ns.IS_FOREVER = type(iface) == "number" and iface >= 16000 and iface < 20000
end

local FRAME_NAMES = {
    player = "EllesmereUIUnitFrames_Player",
    target = "EllesmereUIUnitFrames_Target",
    focus = "EllesmereUIUnitFrames_Focus",
    pet = "EllesmereUIUnitFrames_Pet",
    targettarget = "EllesmereUIUnitFrames_TargetTarget",
    focustarget = "EllesmereUIUnitFrames_FocusTarget",
    boss1 = "EllesmereUIUnitFrames_Boss1",
    boss2 = "EllesmereUIUnitFrames_Boss2",
    boss3 = "EllesmereUIUnitFrames_Boss3",
    boss4 = "EllesmereUIUnitFrames_Boss4",
    boss5 = "EllesmereUIUnitFrames_Boss5",
}

for i = 1, 4 do
    FRAME_NAMES["party" .. i] = "EllesmereUIUnitFrames_Party" .. i
end

for i = 1, 40 do
    FRAME_NAMES["raid" .. i] = "EllesmereUIUnitFrames_Raid" .. i
end

local DB_UNITS = {
    "player", "target", "focus",
    "pet", "targettarget", "focustarget", "totPet",
    "party", "raid", "boss",
}
local FONT_MEDIA = {
    { name = "Gilroy", path = "Interface\\AddOns\\inari\\Media\\Gilroy-Regular.ttf" },
    { name = "Gilroy SemiBold", path = "Interface\\AddOns\\inari\\Media\\Gilroy-SemiBold.ttf" },
    { name = "Gilroy Bold", path = "Interface\\AddOns\\inari\\Media\\Gilroy-Bold.ttf" },
}
local STATUSBAR_MEDIA = {
    { name = "Skyline Compact", path = "Interface\\AddOns\\inari\\Media\\bar_skyline_compact.png" },
    { name = "Bar Grad", path = "Interface\\AddOns\\inari\\Media\\bar_grad.tga" },
}
-- Display names match Naowh's labels, tagged as inari for WeakAuras / SharedMedia pickers.
local SOUND_MEDIA = {
    { name = "|cfff47c9b+Damage - inari|r", file = "+Damage.ogg" },
    { name = "|cfff47c9b1 - inari|r", file = "1.ogg" },
    { name = "|cfff47c9b2 - inari|r", file = "2.ogg" },
    { name = "|cfff47c9b3 - inari|r", file = "3.ogg" },
    { name = "|cfff47c9b4 - inari|r", file = "4.ogg" },
    { name = "|cfff47c9b5 - inari|r", file = "5.ogg" },
    { name = "|cfff47c9b6 - inari|r", file = "6.ogg" },
    { name = "|cfff47c9b7 - inari|r", file = "7.ogg" },
    { name = "|cfff47c9b8 - inari|r", file = "8.ogg" },
    { name = "|cfff47c9b9 - inari|r", file = "9.ogg" },
    { name = "|cfff47c9b10 - inari|r", file = "10.ogg" },
    { name = "|cfff47c9bAbsorb - inari|r", file = "Absorb.ogg" },
    { name = "|cfff47c9bAdd - inari|r", file = "Add.ogg" },
    { name = "|cfff47c9bAdds - inari|r", file = "Adds.ogg" },
    { name = "|cfff47c9bAoE - inari|r", file = "AoE.ogg" },
    { name = "|cfff47c9bApex - inari|r", file = "Apex.ogg" },
    { name = "|cfff47c9bArrow - inari|r", file = "Arrow.ogg" },
    { name = "|cfff47c9bAvoid - inari|r", file = "Avoid.ogg" },
    { name = "|cfff47c9bBait - inari|r", file = "Bait.ogg" },
    { name = "|cfff47c9bBeam - inari|r", file = "Beam.ogg" },
    { name = "|cfff47c9bBehind - inari|r", file = "Behind.ogg" },
    { name = "|cfff47c9bBleed - inari|r", file = "Bleed.ogg" },
    { name = "|cfff47c9bBloodlust - inari|r", file = "Bloodlust.ogg" },
    { name = "|cfff47c9bBomb - inari|r", file = "Bomb.ogg" },
    { name = "|cfff47c9bBreath - inari|r", file = "Breath.ogg" },
    { name = "|cfff47c9bBuff - inari|r", file = "Buff.ogg" },
    { name = "|cfff47c9bCC - inari|r", file = "CC.ogg" },
    { name = "|cfff47c9bCharge - inari|r", file = "Charge.ogg" },
    { name = "|cfff47c9bClear In - inari|r", file = "ClearIn.ogg" },
    { name = "|cfff47c9bClear - inari|r", file = "Clear.ogg" },
    { name = "|cfff47c9bCollect - inari|r", file = "Collect.ogg" },
    { name = "|cfff47c9bCombat - inari|r", file = "Combat.ogg" },
    { name = "|cfff47c9bDance - inari|r", file = "Dance.ogg" },
    { name = "|cfff47c9bDebuff - inari|r", file = "Debuff.ogg" },
    { name = "|cfff47c9bDestroy - inari|r", file = "Destroy.ogg" },
    { name = "|cfff47c9bDispell - inari|r", file = "Dispell.ogg" },
    { name = "|cfff47c9bDodge Inc - inari|r", file = "DodgeInc.ogg" },
    { name = "|cfff47c9bDodge - inari|r", file = "Dodge.ogg" },
    { name = "|cfff47c9bDot - inari|r", file = "Dot.ogg" },
    { name = "|cfff47c9bEnrage - inari|r", file = "Enrage.ogg" },
    { name = "|cfff47c9bExternal - inari|r", file = "External.ogg" },
    { name = "|cfff47c9bFixate - inari|r", file = "Fixate.ogg" },
    { name = "|cfff47c9bFreedom - inari|r", file = "Freedom.ogg" },
    { name = "|cfff47c9bFrontal - inari|r", file = "Frontal.ogg" },
    { name = "|cfff47c9bGreen - inari|r", file = "Green.ogg" },
    { name = "|cfff47c9bHide - inari|r", file = "Hide.ogg" },
    { name = "|cfff47c9bHigh Stacks - inari|r", file = "HighStacks.ogg" },
    { name = "|cfff47c9bImmune - inari|r", file = "Immune.ogg" },
    { name = "|cfff47c9bIn - inari|r", file = "In.ogg" },
    { name = "|cfff47c9bInc - inari|r", file = "Inc.ogg" },
    { name = "|cfff47c9bInside - inari|r", file = "Inside.ogg" },
    { name = "|cfff47c9bIntermission - inari|r", file = "Intermission.ogg" },
    { name = "|cfff47c9bJump - inari|r", file = "Jump.ogg" },
    { name = "|cfff47c9bKick - inari|r", file = "Kick.ogg" },
    { name = "|cfff47c9bKnock - inari|r", file = "Knock.ogg" },
    { name = "|cfff47c9bLeap - inari|r", file = "Leap.ogg" },
    { name = "|cfff47c9bLeft - inari|r", file = "Left.ogg" },
    { name = "|cfff47c9bLinked - inari|r", file = "Linked.ogg" },
    { name = "|cfff47c9bLoS - inari|r", file = "LoS.ogg" },
    { name = "|cfff47c9bMelee - inari|r", file = "Melee.ogg" },
    { name = "|cfff47c9bMount - inari|r", file = "Mount.ogg" },
    { name = "|cfff47c9bMove - inari|r", file = "Move.ogg" },
    { name = "|cfff47c9bNext - inari|r", file = "Next.ogg" },
    { name = "|cfff47c9bNuke - inari|r", file = "Nuke.ogg" },
    { name = "|cfff47c9bOrb - inari|r", file = "Orb.ogg" },
    { name = "|cfff47c9bOrbs - inari|r", file = "Orbs.ogg" },
    { name = "|cfff47c9bOut - inari|r", file = "Out.ogg" },
    { name = "|cfff47c9bOutrange - inari|r", file = "Outrange.ogg" },
    { name = "|cfff47c9bPersonal - inari|r", file = "Personal.ogg" },
    { name = "|cfff47c9bPlatform - inari|r", file = "Platform.ogg" },
    { name = "|cfff47c9bPot - inari|r", file = "Pot.ogg" },
    { name = "|cfff47c9bProc - inari|r", file = "Proc.ogg" },
    { name = "|cfff47c9bPull - inari|r", file = "Pull.ogg" },
    { name = "|cfff47c9bPush - inari|r", file = "Push.ogg" },
    { name = "|cfff47c9bRanged - inari|r", file = "Ranged.ogg" },
    { name = "|cfff47c9bReady - inari|r", file = "Ready.ogg" },
    { name = "|cfff47c9bRe-buff - inari|r", file = "Re-buff.ogg" },
    { name = "|cfff47c9bRed - inari|r", file = "Red.ogg" },
    { name = "|cfff47c9bReflect - inari|r", file = "Reflect.ogg" },
    { name = "|cfff47c9bRescue - inari|r", file = "Rescue.ogg" },
    { name = "|cfff47c9bRight - inari|r", file = "Right.ogg" },
    { name = "|cfff47c9bRun - inari|r", file = "Run.ogg" },
    { name = "|cfff47c9bSac - inari|r", file = "Sac.ogg" },
    { name = "|cfff47c9bShield - inari|r", file = "Shield.ogg" },
    { name = "|cfff47c9bSoak - inari|r", file = "Soak.ogg" },
    { name = "|cfff47c9bSpike - inari|r", file = "Spike.ogg" },
    { name = "|cfff47c9bSpread - inari|r", file = "Spread.ogg" },
    { name = "|cfff47c9bStack - inari|r", file = "Stack.ogg" },
    { name = "|cfff47c9bStop - inari|r", file = "Stop.ogg" },
    { name = "|cfff47c9bStop Cast - inari|r", file = "StopCast.ogg" },
    { name = "|cfff47c9bSwap - inari|r", file = "Swap.ogg" },
    { name = "|cfff47c9bSwitch - inari|r", file = "Switch.ogg" },
    { name = "|cfff47c9bTankHit - inari|r", file = "Tankhit.ogg" },
    { name = "|cfff47c9bTaunt - inari|r", file = "Taunt.ogg" },
    { name = "|cfff47c9bTotem - inari|r", file = "Totem.ogg" },
    { name = "|cfff47c9bTrap - inari|r", file = "Trap.ogg" },
    { name = "|cfff47c9bTurn - inari|r", file = "Turn.ogg" },
    { name = "|cfff47c9bZone - inari|r", file = "Zone.ogg" },
}
-- Packed into tables to stay under Lua's 200-local main-chunk limit.
local CONST = {
    THEME_NAME = "Custom Color",
    THEME_COLOR = { r = 0x60 / 255, g = 0x45 / 255, b = 0x54 / 255 },
    ACCENT_COLOR = { r = 0xE8 / 255, g = 0xA4 / 255, b = 0xB8 / 255 },
    DARK_BG_COLOR = { r = 0x11 / 255, g = 0x11 / 255, b = 0x11 / 255 },
    UI_SCALE = 0.5333333333,
    idleFadeAlpha = 0.07,
    idleFadeInterval = 0.35,
    profilePromptVersion = 1,
}
local COOLDOWN_VIEWER_FRAME_NAMES = {
    "EssentialCooldownViewer",
    "UtilityCooldownViewer",
    "BuffIconCooldownViewer",
    "BuffBarCooldownViewer",
}
local RESOURCE_BAR_FRAME_NAMES = {
    "ERB_HealthBar",
    "ERB_PrimaryBar",
    "ERB_SecondaryFrame",
    "ERB_SecondaryBar",
}
local State = {
    pendingApply = false,
    pendingApplyForce = false,
    pendingRosterPatch = false,
    pendingIdleFade = false,
    bootstrapped = false,
    applyingBootstrap = false,
    hookedReload = nil,
    hookedRaidReload = nil,
    startupRetryVersion = 0,
    profileOfferScheduled = false,
    freshInstallerOpenScheduled = false,
    freshInstallerOpened = false,
    profileUpdatePromptDismissedThisSession = false,
    installedProfilesPromptFrame = nil,
    profileUpdatePromptFrame = nil,
    fontsRegistered = false,
    statusbarsRegistered = false,
    soundsRegistered = false,
    countdownRegistered = false,
    barStyleRegistered = false,
    friendlyNameplateCVarHooked = false,
    actionBarPagingDeferFrame = nil,
    actionBarPagingOverrideApplied = false,
    actionBarPagingBindOwner = nil,
    actionBarPagingKeybindHooked = false,
    idleFadeFrame = nil,
    idleFadeTouchedFrames = {},
    raidFrameHealthCache = setmetatable({}, { __mode = "k" }),
    raidFrameBackgroundCache = setmetatable({}, { __mode = "k" }),
}
ns.ADDON_NAME = ADDON_NAME
ns.CONST = CONST
ns.State = State
ns.FRAME_NAMES = FRAME_NAMES
ns.DB_UNITS = DB_UNITS
ns.FONT_MEDIA = FONT_MEDIA
ns.STATUSBAR_MEDIA = STATUSBAR_MEDIA
ns.SOUND_MEDIA = SOUND_MEDIA
ns.COOLDOWN_VIEWER_FRAME_NAMES = COOLDOWN_VIEWER_FRAME_NAMES
ns.RESOURCE_BAR_FRAME_NAMES = RESOURCE_BAR_FRAME_NAMES

local HookReload
local ScheduleApply
local EnsureDB
local EXBOSS_IMPORT_SLOT_KEYS = {
    "raid_tank",
    "raid_dps",
    "raid_heal",
    "mplus_tank",
    "mplus_dps",
    "mplus_heal",
}
local EXBOSS_IMPORT_AUTHOR_SUFFIXES = {
    raid_tank = "\229\157\166\229\133\139",
    raid_dps = "DPS",
    raid_heal = "\230\178\187\231\150\151",
    mplus_tank = "\229\157\166\229\133\139",
    mplus_dps = "DPS",
    mplus_heal = "\230\178\187\231\150\151",
}
ns.EXBOSS_IMPORT_SLOT_KEYS = EXBOSS_IMPORT_SLOT_KEYS
ns.EXBOSS_IMPORT_AUTHOR_SUFFIXES = EXBOSS_IMPORT_AUTHOR_SUFFIXES

local function Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cffe8a4b8inari:|r " .. tostring(msg))
end

local function RegisterFonts()
    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
    if not LSM then return false end

    for _, font in ipairs(FONT_MEDIA) do
        LSM:Register(LSM.MediaType.FONT, font.name, font.path)
        if EllesmereUI then
            EllesmereUI._smFontPaths = EllesmereUI._smFontPaths or {}
            EllesmereUI._smFontPaths[font.name] = font.path
        end
    end

    State.fontsRegistered = true
    return true
end

local function RegisterStatusbars()
    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
    if not LSM then return false end

    for _, bar in ipairs(STATUSBAR_MEDIA) do
        LSM:Register(LSM.MediaType.STATUSBAR, bar.name, bar.path)
    end

    State.statusbarsRegistered = true
    return true
end

local function RegisterSounds()
    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
    if not LSM then return false end

    local base = "Interface\\AddOns\\inari\\Media\\Sounds\\"
    for _, sound in ipairs(SOUND_MEDIA) do
        LSM:Register(LSM.MediaType.SOUND, sound.name, base .. sound.file)
    end

    State.soundsRegistered = true
    return true
end

local function RegisterCountdownVoice()
    if State.countdownRegistered then return true end
    if not BigWigsAPI or type(BigWigsAPI.RegisterCountdown) ~= "function" then return false end
    if BigWigsAPI.HasCountdown and BigWigsAPI:HasCountdown("Inari") then
        State.countdownRegistered = true
        return true
    end

    local base = "Interface\\AddOns\\inari\\Media\\Countdown\\"
    local ok, err = pcall(BigWigsAPI.RegisterCountdown, BigWigsAPI, "Inari", "Inari", {
        base .. "1.ogg",
        base .. "2.ogg",
        base .. "3.ogg",
        base .. "4.ogg",
        base .. "5.ogg",
    })
    if not ok then
        -- Already registered by a previous load is fine.
        if type(err) == "string" and err:find("already registered", 1, true) then
            State.countdownRegistered = true
            return true
        end
        return false
    end

    State.countdownRegistered = true
    return true
end

local function RegisterBarStyle()
    if State.barStyleRegistered then return true end
    if not BigWigsAPI or type(BigWigsAPI.RegisterBarStyle) ~= "function" then return false end
    if BigWigsAPI.GetBarStyle and BigWigsAPI:GetBarStyle("inari") then
        State.barStyleRegistered = true
        return true
    end

    local backdropBorder = {
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    }

    local function removeStyle(bar)
        bar.candyBarBackdrop:Hide()
        bar.candyBarIconFrameBackdrop:Hide()
        local height = bar:Get("bigwigs:restoreheight")
        if height then
            bar:SetHeight(height)
        end

        local statusbar = bar.candyBarBar
        local duration = bar.candyBarDuration
        duration:ClearAllPoints()
        duration:SetPoint("TOPLEFT", statusbar, "TOPLEFT", 2, 0)
        duration:SetPoint("BOTTOMRIGHT", statusbar, "BOTTOMRIGHT", -2, 0)

        local label = bar.candyBarLabel
        label:ClearAllPoints()
        label:SetPoint("TOPLEFT", statusbar, "TOPLEFT", 2, 0)
        label:SetPoint("BOTTOMRIGHT", statusbar, "BOTTOMRIGHT", -2, 0)
    end

    local function styleBar(bar)
        local barHeight = bar:GetHeight()

        bar:Set("bigwigs:restoreheight", barHeight)
        bar:SetHeight(barHeight / 2)

        bar.candyBarLabel:ClearAllPoints()
        bar.candyBarDuration:ClearAllPoints()
        local statusbar = bar.candyBarBar
        statusbar:ClearAllPoints()

        local bd = bar.candyBarBackdrop
        if bd.SetToDefaults then
            bd:SetToDefaults()
            bd:SetFrameLevel(0)
        end
        bd:ClearAllPoints()
        bd:SetBackdrop(backdropBorder)
        bd:SetBackdropColor(0.1, 0.1, 0.1, 1)
        bd:SetBackdropBorderColor(0, 0, 0, 1)
        bd:SetPoint("TOPLEFT", statusbar, "TOPLEFT", -1, 1)
        bd:SetPoint("BOTTOMRIGHT", statusbar, "BOTTOMRIGHT", 1, -1)
        bd:Show()

        local iconTexture = bar:GetIcon()
        if iconTexture then
            local reApplyIcon = false
            local iconFrame = bar.candyBarIconFrame
            local iconBd = bar.candyBarIconFrameBackdrop
            if iconFrame.IsAnchoringSecret and iconFrame:IsAnchoringSecret() then
                iconFrame:SetToDefaults()
                iconBd:SetToDefaults()
                iconBd:SetFrameLevel(0)
                reApplyIcon = true
            end

            iconFrame:ClearAllPoints()
            iconBd:ClearAllPoints()

            if bar:GetIconPosition() == "RIGHT" then
                iconFrame:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", -2, 0)
                statusbar:SetPoint("TOPRIGHT", iconFrame, "LEFT", -4, -2)
                statusbar:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", 2, 0)
            else
                iconFrame:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", 2, 0)
                statusbar:SetPoint("TOPLEFT", iconFrame, "RIGHT", 4, -2)
                statusbar:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", -2, 0)
            end
            iconFrame:SetSize(barHeight, barHeight)

            iconBd:SetBackdrop(backdropBorder)
            iconBd:SetBackdropColor(0.1, 0.1, 0.1, 1)
            iconBd:SetBackdropBorderColor(0, 0, 0, 1)
            iconBd:SetPoint("TOPLEFT", iconFrame, "TOPLEFT", -1, 1)
            iconBd:SetPoint("BOTTOMRIGHT", iconFrame, "BOTTOMRIGHT", 1, -1)
            iconBd:Show()

            if reApplyIcon then
                iconFrame:SetTexture(iconTexture)
                iconFrame:SetTexCoord(0.07, 0.93, 0.07, 0.93)
            end
        end

        bar.candyBarLabel:SetPoint("BOTTOMLEFT", statusbar, "TOPLEFT", 2, -7)
        bar.candyBarDuration:SetPoint("BOTTOMRIGHT", statusbar, "TOPRIGHT", -2, -7)
    end

    local ok, err = pcall(BigWigsAPI.RegisterBarStyle, BigWigsAPI, "inari", {
        apiVersion = 1,
        version = 11,
        barHeight = 20,
        texture = "Bar Grad",
        fontName = "Gilroy Bold",
        fontSizeNormal = 14,
        fontSizeEmphasized = 14,
        spellIndicatorsOffset = 2,
        spellIndicatorsPosition = "RIGHT",
        fontOutline = "OUTLINE",
        iconPosition = "RIGHT",
        GetSpacing = function(bar) return bar:GetHeight() + 4 end,
        ApplyStyle = styleBar,
        BarStopped = removeStyle,
        GetStyleName = function() return "inari" end,
    })
    if not ok then
        if type(err) == "string" and err:find("already exist", 1, true) then
            State.barStyleRegistered = true
            return true
        end
        return false
    end

    State.barStyleRegistered = true
    return true
end

local function RegisterMedia()
    local okFonts = RegisterFonts()
    local okBars = RegisterStatusbars()
    local okSounds = RegisterSounds()
    local okCountdown = RegisterCountdownVoice()
    local okBarStyle = RegisterBarStyle()
    return okFonts or okBars or okSounds or okCountdown or okBarStyle
end

local BASE_CVARS = ns.BASE_CVARS or {
    accountNeedsTurnStrafeDialog = 0,
    advancedCombatLogging = 1,
    autoLootDefault = 1,
    autoLootRate = 150,
    cameraDistanceMaxZoomFactor = 2.6,
    cooldownViewerEnabled = 1,
    encounterTimelineEnabled = 0,
}

local FLOATING_COMBAT_TEXT_CVARS = {
    "floatingCombatTextCombatDamage_v2",
    "floatingCombatTextCombatHealing_v2",
    "floatingCombatTextCombatLogPeriodicSpells_v2",
    "floatingCombatTextPetMeleeDamage_v2",
    "floatingCombatTextPetSpellDamage_v2",
    "enableFloatingCombatText",
    "floatingCombatTextAuras",
    "floatingCombatTextCombatDamage",
    "floatingCombatTextCombatDamageAllAutos",
    "floatingCombatTextCombatHealing",
    "floatingCombatTextCombatHealingAbsorbSelf",
    "floatingCombatTextCombatHealingAbsorbTarget",
    "floatingCombatTextCombatLogPeriodicSpells",
    "floatingCombatTextCombatState",
    "floatingCombatTextComboPoints",
    "floatingCombatTextDamageReduction",
    "floatingCombatTextDodgeParryMiss",
    "floatingCombatTextEnergyGains",
    "floatingCombatTextFriendlyHealers",
    "floatingCombatTextHonorGains",
    "floatingCombatTextLowManaHealth",
    "floatingCombatTextPeriodicEnergyGains",
    "floatingCombatTextPetMeleeDamage",
    "floatingCombatTextPetSpellDamage",
    "floatingCombatTextReactives",
    "floatingCombatTextRepChanges",
    "floatingCombatTextSpellMechanics",
    "floatingCombatTextSpellMechanicsOther",
}

local FPS_CVARS = {
    { "graphicsShadowQuality",      "1" },
    { "graphicsLiquidDetail",       "0" },
    { "graphicsParticleDensity",    "5" },
    { "graphicsSSAO",               "0" },
    { "graphicsDepthEffects",       "0" },
    { "graphicsComputeEffects",     "0" },
    { "graphicsOutlineMode",        "0" },
    { "graphicsTextureResolution",  "2" },
    { "graphicsSpellDensity",       "1" },
    { "graphicsProjectedTextures",  "1" },
    { "graphicsViewDistance",       "1" },
    { "graphicsEnvironmentDetail",  "1" },
    { "graphicsGroundClutter",      "1" },
    { "RAIDsettingsEnabled",        "0" },
    { "ResampleAlwaysSharpen",      "1" },
    { "gxVSync",                    "0" },
    { "gxTripleBuffer",             "0" },
    { "maxFPSBk",                   "30" },
}

local INARI_GRAPHICS_CVARS = {
    { "graphicsShadowQuality",      "2" },
    { "graphicsLiquidDetail",       "1" },
    { "graphicsParticleDensity",    "5" },
    { "graphicsSSAO",               "1" },
    { "graphicsDepthEffects",       "1" },
    { "graphicsComputeEffects",     "1" },
    { "graphicsOutlineMode",        "0" },
    { "graphicsTextureResolution",  "2" },
    { "graphicsSpellDensity",       "2" },
    { "graphicsProjectedTextures",  "1" },
    { "graphicsViewDistance",       "5" },
    { "graphicsEnvironmentDetail",  "5" },
    { "graphicsGroundClutter",      "3" },
    { "RAIDsettingsEnabled",        "0" },
    { "ResampleAlwaysSharpen",      "1" },
}

ns.BASE_CVARS = BASE_CVARS
ns.FLOATING_COMBAT_TEXT_CVARS = FLOATING_COMBAT_TEXT_CVARS
ns.FPS_CVARS = FPS_CVARS
ns.INARI_GRAPHICS_CVARS = INARI_GRAPHICS_CVARS

local function GetInariCVar(name)
    if C_CVar and C_CVar.GetCVar then
        local value = C_CVar.GetCVar(name)
        if value ~= nil then return value end
    end

    if GetCVar then
        local ok, value = pcall(GetCVar, name)
        if ok then return value end
    end

    return nil
end

local afterCombatQueue = {}
local afterCombatFrame

-- Runs fn now, or once combat ends. Queuing the same key again replaces the earlier call.
local function RunAfterCombat(key, fn)
    if not (InCombatLockdown and InCombatLockdown()) then
        fn()
        return true
    end

    afterCombatQueue[key] = fn
    if not afterCombatFrame then
        afterCombatFrame = CreateFrame("Frame")
        afterCombatFrame:SetScript("OnEvent", function(self)
            self:UnregisterEvent("PLAYER_REGEN_ENABLED")
            local queued = afterCombatQueue
            afterCombatQueue = {}
            for _, queuedFn in pairs(queued) do
                queuedFn()
            end
        end)
    end
    afterCombatFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    return false
end

local function SetInariCVar(name, value)
    if InCombatLockdown and InCombatLockdown() then return false end

    local text = tostring(value)
    local ok = false

    if SetCVar then
        ok = pcall(SetCVar, name, text)
    elseif C_CVar and C_CVar.SetCVar then
        ok = pcall(C_CVar.SetCVar, name, text)
    end

    return ok and GetInariCVar(name) ~= nil
end

-- Returns applied, skipped, queued. In combat the whole table waits for combat to end.
local function ApplyCVarTable(cvars)
    if InCombatLockdown and InCombatLockdown() then
        RunAfterCombat(cvars, function() ApplyCVarTable(cvars) end)
        return 0, 0, true
    end

    local applied = 0
    local skipped = 0

    for key, entry in pairs(cvars) do
        local name, value
        if type(entry) == "table" then
            name, value = entry[1], entry[2]
        else
            name, value = key, entry
        end

        if SetInariCVar(name, value) then
            applied = applied + 1
        else
            skipped = skipped + 1
        end
    end

    return applied, skipped
end

local function FormatCVarResult(prefix, applied, skipped, queued)
    if queued then return prefix .. "queued until combat ends" end
    local message = prefix .. applied .. " CVars"
    if skipped > 0 then message = message .. ", " .. skipped .. " skipped" end
    return message
end

local function ApplyFPSSettings()
    local applied, skipped, queued = ApplyCVarTable(FPS_CVARS)
    if type(InariDB) == "table" then InariDB.graphicsPreset = "fps" end

    return applied, skipped, queued
end

local function ApplyInariGraphicsSettings()
    local applied, skipped, queued = ApplyCVarTable(INARI_GRAPHICS_CVARS)
    if type(InariDB) == "table" then InariDB.graphicsPreset = "inari" end
    return applied, skipped, queued
end

local function ApplyFloatingCombatText(value)
    local cvars = {}
    for _, name in ipairs(FLOATING_COMBAT_TEXT_CVARS) do
        cvars[name] = value
    end
    if type(InariDB) == "table" then
        InariDB.floatingCombatTextPreset = tonumber(value) == 1 and "enabled" or "disabled"
    end

    return ApplyCVarTable(cvars)
end

local function TryLoadAddon(name)
    if C_AddOns and C_AddOns.LoadAddOn then
        pcall(C_AddOns.LoadAddOn, name)
    elseif LoadAddOn then
        pcall(LoadAddOn, name)
    end
end

local function ApplyInariUIScale(applyLive)
    TryLoadAddon("EllesmereUI")

    if type(EllesmereUIDB) ~= "table" then EllesmereUIDB = {} end
    EllesmereUIDB.ppUIScaleAuto = false
    EllesmereUIDB.ppUIScale = CONST.UI_SCALE

    SetInariCVar("useUiScale", 1)
    SetInariCVar("uiScale", CONST.UI_SCALE)

    if not applyLive then return end

    if EllesmereUI and EllesmereUI.PP and type(EllesmereUI.PP.SetUIScale) == "function" then
        pcall(EllesmereUI.PP.SetUIScale, CONST.UI_SCALE)
    elseif UIParent and UIParent.SetScale and not (InCombatLockdown and InCombatLockdown()) then
        UIParent:SetScale(CONST.UI_SCALE)
    end
end

local function DetectLayoutAspect()
    local width = (GetScreenWidth and GetScreenWidth()) or 0
    local height = (GetScreenHeight and GetScreenHeight()) or 0
    if height <= 0 then return "16" end
    if (width / height) >= 2.0 then return "21" end
    return "16"
end

local function NormalizeLayoutAspect(value)
    value = tostring(value or ""):lower():gsub("%s+", "")
    if value == "21" or value == "21:9" or value == "21x9" or value == "ultrawide" or value == "uw" then
        return "21"
    end
    if value == "16" or value == "16:9" or value == "16x9" or value == "standard" then
        return "16"
    end
    return nil
end

local function GetLayoutAspect()
    EnsureDB()
    return InariDB.layoutAspect == "21" and "21" or "16"
end

local function SetLayoutAspect(value)
    EnsureDB()
    local aspect = NormalizeLayoutAspect(value)
    if not aspect then return nil end
    InariDB.layoutAspect = aspect
    return aspect
end

local function GetLayoutAspectLabel(aspect)
    aspect = aspect or GetLayoutAspect()
    return aspect == "21" and "21:9" or "16:9"
end

local function GetEllesmereLayoutProfileName(aspect)
    aspect = aspect or GetLayoutAspect()
    return aspect == "21" and "inari21:9" or "inari16:9"
end

local function IsInariEllesmereProfile(name)
    return name == "inari" or name == "inari16:9" or name == "inari21:9"
end

local function EllesmereProfileExists(profileName)
    return type(EllesmereUIDB) == "table"
        and type(EllesmereUIDB.profiles) == "table"
        and type(EllesmereUIDB.profiles[profileName]) == "table"
end

local function GetActiveEllesmereProfile()
    if EllesmereUI and type(EllesmereUI.GetActiveProfileName) == "function" then
        local ok, profileName = pcall(EllesmereUI.GetActiveProfileName)
        if ok and type(profileName) == "string" and profileName ~= "" then
            return profileName
        end
    end

    if type(EllesmereUIDB) == "table" and type(EllesmereUIDB.activeProfile) == "string" then
        return EllesmereUIDB.activeProfile
    end

    return nil
end

-- Forced profile settings only apply while one of inari's own profiles is active.
local function IsInariEllesmereProfileActive()
    return IsInariEllesmereProfile(GetActiveEllesmereProfile())
end

local DB_DEFAULTS = {
    enabled = true,
    classBackground = true,
    darkOpacity = true,
    forceDarkMode = true,
    forceEUITheme = true,
    forceOpacity = true,
    forceChatSidebarRight = true,
    disableFriendlyPlayerNameplates = true,
    fadeIdlePlayerAndCooldowns = false,
    disableEllesmereActionBarPaging = true,
    frameShadows = true,
    profilePromptEnabled = true,
    profileUpdateEnabled = true,
    targetArrows = true,
}
local DB_AUTO_PRESET_KEYS = {
    "enabled", "classBackground", "darkOpacity", "forceDarkMode", "forceEUITheme", "forceOpacity",
    "forceChatSidebarRight", "disableFriendlyPlayerNameplates", "fadeIdlePlayerAndCooldowns",
    "disableEllesmereActionBarPaging",
}
local DB_TABLE_KEYS = {
    "profilePromptApplied", "profilePromptDismissed", "importedProfileVersions", "profileUpdateDismissed", "portraits",
}
local PORTRAIT_UNIT_ANCHORS = { player = "LEFT", target = "RIGHT" }

local function ClampNumber(tbl, key, default, min, max)
    local value = tbl[key]
    if type(value) ~= "number" then value = default end
    if min and value < min then value = min end
    if max and value > max then value = max end
    tbl[key] = value
end

EnsureDB = function()
    -- Validated once per saved-variable table; setters clamp their own input.
    if type(InariDB) == "table" and State.validatedDB == InariDB then return end
    if type(InariDB) ~= "table" then InariDB = {} end
    local db = InariDB

    if db.autoPresetVersion ~= 1 then
        for _, key in ipairs(DB_AUTO_PRESET_KEYS) do
            db[key] = DB_DEFAULTS[key]
        end
        db.appearanceMode = "dark"
        db.healthBarOpacity = 85
        db.tint = 0.75
        db.autoPresetVersion = 1
    end
    for key, value in pairs(DB_DEFAULTS) do
        if db[key] == nil then db[key] = value end
    end
    if db.appearanceMode ~= "dark" and db.appearanceMode ~= "class" then
        db.appearanceMode = db.forceDarkMode and "dark" or "class"
    end
    for _, key in ipairs(DB_TABLE_KEYS) do
        if type(db[key]) ~= "table" then db[key] = {} end
    end
    ClampNumber(db, "healthBarOpacity", 85, 0, 100)
    ClampNumber(db, "tint", 0.75, 0, 1)
    ClampNumber(db, "frameShadowStrength", 70, 0, 100)
    if type(db.targetArrowSize) == "number" then
        db.targetArrowSize = math.floor(db.targetArrowSize + 0.5)
    end
    ClampNumber(db, "targetArrowSize", 30, 12, 80)
    if db.layoutAspect ~= "16" and db.layoutAspect ~= "21" then
        db.layoutAspect = DetectLayoutAspect()
    end
    if db.graphicsPreset ~= "fps" and db.graphicsPreset ~= "inari" then db.graphicsPreset = nil end
    if db.floatingCombatTextPreset ~= "enabled" and db.floatingCombatTextPreset ~= "disabled" then db.floatingCombatTextPreset = nil end
    db.qol = nil
    if type(db.lastConfigPage) ~= "string" then db.lastConfigPage = "home" end

    local portraits = db.portraits
    if db.extrasDefaultsVersion ~= 2 then
        db.disableEllesmereActionBarPaging = true
        db.forceChatSidebarRight = true
        db.disableFriendlyPlayerNameplates = true
        db.fadeIdlePlayerAndCooldowns = false
        portraits.enabled = true
        portraits.size = 52
        portraits.zoom = 0.22
        for unit, anchor in pairs(PORTRAIT_UNIT_ANCHORS) do
            local unitDB = type(portraits[unit]) == "table" and portraits[unit] or {}
            unitDB.enable = true
            unitDB.anchor = anchor
            unitDB.x = 0
            unitDB.y = 0
            portraits[unit] = unitDB
        end
        db.extrasDefaultsVersion = 2
    end
    if portraits.enabled == nil then portraits.enabled = true end
    ClampNumber(portraits, "size", 52, 16, 256)
    ClampNumber(portraits, "zoom", 0.22, 0, 1)
    ClampNumber(portraits, "level", 20)
    for unit, anchor in pairs(PORTRAIT_UNIT_ANCHORS) do
        if type(portraits[unit]) ~= "table" then portraits[unit] = {} end
        local unitDB = portraits[unit]
        if unitDB.enable == nil then unitDB.enable = true end
        if unitDB.anchor ~= "LEFT" and unitDB.anchor ~= "RIGHT" then unitDB.anchor = anchor end
        ClampNumber(unitDB, "x", 0)
        ClampNumber(unitDB, "y", 0)
    end

    State.validatedDB = db
end

local function ApplyFriendlyPlayerNameplatePreference()
    EnsureDB()
    if not InariDB.disableFriendlyPlayerNameplates then return false end
    if InCombatLockdown and InCombatLockdown() then
        RunAfterCombat("friendlyNameplates", ApplyFriendlyPlayerNameplatePreference)
        return false
    end

    local changed = false
    if GetInariCVar("nameplateShowFriendlyPlayers") ~= "0" then
        changed = SetInariCVar("nameplateShowFriendlyPlayers", 0) or changed
    end
    if GetInariCVar("nameplateShowFriends") ~= "0" then
        changed = SetInariCVar("nameplateShowFriends", 0) or changed
    end

    return changed
end

local function ScheduleFriendlyPlayerNameplatePreference(delay)
    C_Timer.After(delay or 0, function()
        ApplyFriendlyPlayerNameplatePreference()
    end)
end

local function HookFriendlyPlayerNameplateCVars()
    if State.friendlyNameplateCVarHooked or not hooksecurefunc then return end

    local function WatchFriendlyNameplateCVar(name, value)
        if type(InariDB) ~= "table" or not InariDB.disableFriendlyPlayerNameplates then return end
        if name ~= "nameplateShowFriendlyPlayers" and name ~= "nameplateShowFriends" then return end
        if tostring(value) == "0" then return end
        ScheduleFriendlyPlayerNameplatePreference(0)
    end

    if SetCVar then pcall(hooksecurefunc, "SetCVar", WatchFriendlyNameplateCVar) end
    if C_CVar and C_CVar.SetCVar then pcall(hooksecurefunc, C_CVar, "SetCVar", WatchFriendlyNameplateCVar) end
    State.friendlyNameplateCVarHooked = true
end

local idleFadeApplying = false
local idleFadeAlphaHooked = {}

local function QueueIdleFadeShadowRefresh()
    if ns.QueueFrameShadowRefresh then
        ns.QueueFrameShadowRefresh()
    end
end

local function RestoreIdleFadeFrames()
    local restored = false
    idleFadeApplying = true
    for frame in pairs(State.idleFadeTouchedFrames) do
        if frame and type(frame.SetAlpha) == "function" then
            local base = frame._inariIdleFadeBaseAlpha or 1
            frame._inariIdleFaded = nil
            frame._inariIdleFadeBaseAlpha = nil
            pcall(frame.SetAlpha, frame, base)
            restored = true
        end
    end
    idleFadeApplying = false
    for frame in pairs(State.idleFadeTouchedFrames) do
        State.idleFadeTouchedFrames[frame] = nil
    end
    if restored then
        QueueIdleFadeShadowRefresh()
    end
end

local function ShouldIdleFade(enteringCombat)
    EnsureDB()
    if enteringCombat then return false end
    if not InariDB.enabled then return false end
    if InariDB.fadeIdlePlayerAndCooldowns ~= true then return false end

    local inInstance, instanceType = IsInInstance()
    if inInstance and (instanceType == "party" or instanceType == "raid") then return false end
    if InCombatLockdown and InCombatLockdown() then return false end
    if UnitAffectingCombat and UnitAffectingCombat("player") then return false end
    if UnitExists and UnitExists("target") then return false end

    return true
end

local function ForEachIdleFadeFrame(callback)
    local seen = {}
    local function Visit(frame)
        if not frame or seen[frame] or type(frame.SetAlpha) ~= "function" or type(frame.GetAlpha) ~= "function" then return end
        seen[frame] = true
        callback(frame)
    end

    local player = _G[FRAME_NAMES.player]
    Visit((player and player._visWrap) or player)
    Visit(_G[FRAME_NAMES.pet])
    for _, name in ipairs(COOLDOWN_VIEWER_FRAME_NAMES) do
        Visit(_G[name])
    end
    for _, name in ipairs(RESOURCE_BAR_FRAME_NAMES) do
        Visit(_G[name])
    end

    local getBarFrame = _G._ECME_GetBarFrame
    local cdmDB = _G._ECME_AceDB
    local bars = cdmDB and cdmDB.profile and cdmDB.profile.cdmBars and cdmDB.profile.cdmBars.bars
    if type(getBarFrame) == "function" and type(bars) == "table" then
        for _, barData in ipairs(bars) do
            if type(barData) == "table" and barData.enabled ~= false and barData.key then
                Visit(getBarFrame(barData.key))
            end
        end
    end

    for i = 1, 20 do
        Visit(_G["ECME_TBBWrap" .. i])
    end
end

local function ReassertIdleFade(frame, requestedAlpha)
    if idleFadeApplying or not frame or not frame._inariIdleFaded then return end
    if not ShouldIdleFade() then return end
    requestedAlpha = tonumber(requestedAlpha)
    if not requestedAlpha then
        requestedAlpha = (frame.GetAlpha and frame:GetAlpha()) or 1
    end
    if requestedAlpha <= 0 then return end
    if math.abs(requestedAlpha - CONST.idleFadeAlpha) <= 0.001 then return end
    frame._inariIdleFadeBaseAlpha = requestedAlpha
    idleFadeApplying = true
    pcall(frame.SetAlpha, frame, CONST.idleFadeAlpha)
    idleFadeApplying = false
    QueueIdleFadeShadowRefresh()
end

local function HookIdleFadeAlpha(frame)
    if not frame or idleFadeAlphaHooked[frame] or not hooksecurefunc then return end
    idleFadeAlphaHooked[frame] = true
    hooksecurefunc(frame, "SetAlpha", function(self, alpha)
        ReassertIdleFade(self, alpha)
    end)
end

local function ApplyIdleFadeState(enteringCombat)
    if not ShouldIdleFade(enteringCombat) then
        RestoreIdleFadeFrames()
        return
    end

    local changed = false
    idleFadeApplying = true
    ForEachIdleFadeFrame(function(frame)
        HookIdleFadeAlpha(frame)
        local alpha = frame:GetAlpha() or 1
        if alpha <= 0 then
            if frame._inariIdleFaded then
                changed = true
            end
            frame._inariIdleFaded = nil
            frame._inariIdleFadeBaseAlpha = nil
            State.idleFadeTouchedFrames[frame] = nil
            return
        end

        if not frame._inariIdleFaded or math.abs(alpha - CONST.idleFadeAlpha) > 0.001 then
            changed = true
            frame._inariIdleFadeBaseAlpha = alpha
        end
        frame._inariIdleFaded = true
        State.idleFadeTouchedFrames[frame] = true
        frame:SetAlpha(CONST.idleFadeAlpha)
    end)
    idleFadeApplying = false
    if changed then
        QueueIdleFadeShadowRefresh()
    end
end

local function UpdateIdleFadeController()
    EnsureDB()
    if State.idleFadeFrame then State.idleFadeFrame:SetScript("OnUpdate", nil) end
    if InariDB.enabled and InariDB.fadeIdlePlayerAndCooldowns == true then
        ApplyIdleFadeState()
    else
        RestoreIdleFadeFrames()
    end
end

local function ScheduleIdleFadeUpdate(delay)
    delay = delay or 0
    if delay == 0 then
        if State.pendingIdleFade then return end
        State.pendingIdleFade = true
        C_Timer.After(0, function()
            State.pendingIdleFade = false
            UpdateIdleFadeController()
        end)
        return
    end
    C_Timer.After(delay, UpdateIdleFadeController)
end

local function UnitKey(unit)
    if not unit then return nil end
    if unit:match("^boss%d+$") then return "boss" end
    if unit:match("^party%d+$") then return "party" end
    if unit:match("^raid%d+$") then return "raid" end
    return unit
end

local function LegacyMiniUnitKey(unit)
    return (unit == "pet" or unit == "targettarget" or unit == "focustarget") and "totPet" or nil
end

local function GetEllesmereAddonProfile(addonName)
    local root = _G.EllesmereUIDB
    if type(root) ~= "table" then return nil end
    local profileName = root.activeProfile or "Default"
    local profile = root.profiles and root.profiles[profileName]
    local addons = profile and profile.addons
    return addons and addons[addonName]
end

local function EnsureEllesmereAddonProfile(addonName)
    local root = _G.EllesmereUIDB
    if type(root) ~= "table" then return nil end
    local profileName = root.activeProfile or "Default"
    root.profiles = root.profiles or {}
    root.profiles[profileName] = root.profiles[profileName] or {}
    root.profiles[profileName].addons = root.profiles[profileName].addons or {}
    root.profiles[profileName].addons[addonName] = root.profiles[profileName].addons[addonName] or {}
    return root.profiles[profileName].addons[addonName]
end

local function GetEllesmereProfile()
    return GetEllesmereAddonProfile("EllesmereUIUnitFrames")
end

local function GetEllesmereRaidFramesProfile()
    return GetEllesmereAddonProfile("EllesmereUIRaidFrames")
end

local function GetInariCharacterKey()
    local name = UnitName and UnitName("player") or "Unknown"
    local realm = GetRealmName and GetRealmName() or "Unknown"
    return tostring(name or "Unknown") .. " - " .. tostring(realm or "Unknown")
end

local function MarkProfilePromptApplied()
    EnsureDB()
    InariDB.profilePromptApplied[GetInariCharacterKey()] = CONST.profilePromptVersion
    InariDB.profilePromptDismissed[GetInariCharacterKey()] = nil
end

local function MarkInstallerCompleted()
    EnsureDB()
    InariDB.installerCompletedVersion = CONST.profilePromptVersion
    InariDB.installerPendingFinalScale = nil
end

local function MarkInstallerPendingFinalScale()
    EnsureDB()
    InariDB.installerPendingFinalScale = true
end

local function MarkProfilePromptDismissed()
    EnsureDB()
    InariDB.profilePromptDismissed[GetInariCharacterKey()] = CONST.profilePromptVersion
end

local function ApplySignature()
    EnsureDB()
    return table.concat({
        tostring(InariDB.enabled),
        tostring(InariDB.appearanceMode),
        tostring(InariDB.forceEUITheme),
        tostring(InariDB.classBackground),
        tostring(InariDB.healthBarOpacity),
        tostring(InariDB.tint),
        tostring(InariDB.frameShadows),
        tostring(InariDB.frameShadowStrength),
        tostring(InariDB.disableEllesmereActionBarPaging),
        tostring(InariDB.forceChatSidebarRight),
        tostring(InariDB.fadeIdlePlayerAndCooldowns),
        tostring(InariDB.disableFriendlyPlayerNameplates),
        tostring(GetActiveEllesmereProfile()),
    }, "|")
end

local function PatchUnit(unit)
    if ns.PatchUnit then ns.PatchUnit(unit) end
end

local function PatchRaidAndParty()
    if ns.PatchRaidAndParty then ns.PatchRaidAndParty() end
end

local function PlayerFrameStillPatched()
    local frame = _G[FRAME_NAMES.player]
    local health = frame and frame.Health
    return health and health._inariPostUpdateColor ~= nil and health.PostUpdateColor == health._inariPostUpdateColor
end

local function ApplyAll(force)
    EnsureDB()
    if ns.InvalidateAppearanceToken then ns.InvalidateAppearanceToken() end
    local signature = ApplySignature()
    local settingsUnchanged = State.applySignature == signature
    if not force and settingsUnchanged and State.framesPatched then
        return State.lastPatchCount or 0
    end
    if InariDB.enabled and (not settingsUnchanged or not State.framesPatched) then
        ns.ApplyEllesmereThemeSettings()
        ns.ApplyConfiguredProfileSettings()
        ApplyFriendlyPlayerNameplatePreference()
        if IsInariEllesmereProfileActive() then ns.ApplyChatSettings() end
        ns.ApplyEllesmereActionBarPagingOverride()
    end
    local patched = ns.PatchAllFrames and ns.PatchAllFrames() or 0
    if ns.RefreshPortraits then ns.RefreshPortraits() end
    if ns.RefreshTargetArrows then ns.RefreshTargetArrows() end
    if ns.QueueFrameShadowRefresh then
        ns.QueueFrameShadowRefresh()
    elseif ns.RefreshFrameShadows then
        ns.RefreshFrameShadows()
    end
    State.applySignature = signature
    State.framesPatched = true
    State.lastPatchCount = patched
    return patched
end

ScheduleApply = function(delay, force)
    delay = delay or 0
    force = force == true
    if delay == 0 then
        if force then State.pendingApplyForce = true end
        if State.pendingApply then return end
        State.pendingApply = true
        C_Timer.After(0, function()
            local shouldForce = State.pendingApplyForce
            State.pendingApply = false
            State.pendingApplyForce = false
            ApplyAll(shouldForce)
        end)
        return
    end
    C_Timer.After(delay, function()
        ApplyAll(force)
    end)
end

local function ScheduleApplyBurst()
    ScheduleApply(0, true)
    ScheduleApply(0.15, true)
end

local function ScheduleSpecApplyBurst()
    ScheduleApply(0, true)
    ScheduleApply(0.15, true)
    ScheduleApply(0.50, true)
    ScheduleApply(1.00, true)
end

local function ScheduleRosterPatch()
    if State.pendingRosterPatch then return end
    State.pendingRosterPatch = true
    C_Timer.After(0, function()
        State.pendingRosterPatch = false
        PatchRaidAndParty()
        if ns.QueueFrameShadowRefresh then ns.QueueFrameShadowRefresh() end
    end)
end

local function ScheduleStartupRetries()
    State.startupRetryVersion = State.startupRetryVersion + 1
    local version = State.startupRetryVersion
    local delays = { 0.25, 1.00 }

    for _, delay in ipairs(delays) do
        C_Timer.After(delay, function()
            if version ~= State.startupRetryVersion then return end
            if delay > 0 and PlayerFrameStillPatched() then return end
            HookReload()
            ns.ApplyEllesmereThemeSettings(true)
            State.discoveredFramesCached = false
            State.applyingBootstrap = true
            if ns.ApplyConfiguredProfileSettings() then ns.ReloadEllesmereFrames() end
            ApplyAll(true)
            State.applyingBootstrap = false
        end)
    end
end

function HookReload()
    if type(_G._EUF_ReloadFrames) == "function" and State.hookedReload ~= _G._EUF_ReloadFrames then
        hooksecurefunc("_EUF_ReloadFrames", function()
            if State.applyingBootstrap then return end
            ScheduleApplyBurst()
        end)
        State.hookedReload = _G._EUF_ReloadFrames
    end

    if type(_G._ERF_RefreshAll) == "function" and State.hookedRaidReload ~= _G._ERF_RefreshAll then
        hooksecurefunc("_ERF_RefreshAll", function()
            if State.applyingBootstrap then return end
            ScheduleApplyBurst()
        end)
        State.hookedRaidReload = _G._ERF_RefreshAll
    end
end

local function ShouldOpenFreshInstaller()
    EnsureDB()
    if InariDB.installerPendingFinalScale == true then return true end
    return InariDB.installerCompletedVersion ~= CONST.profilePromptVersion and InariDB.installerDeferred ~= true
end

local function ScheduleFreshInstallerOpen()
    if State.freshInstallerOpenScheduled or State.freshInstallerOpened then return end
    State.freshInstallerOpenScheduled = true
    C_Timer.After(2, function()
        State.freshInstallerOpenScheduled = false
        if InCombatLockdown and InCombatLockdown() then return end
        if ShouldOpenFreshInstaller() then
            State.freshInstallerOpened = true
            ns.ShowInstallerFrame()
        end
    end)
end

-- EllesmereUI stores an opacity of 1 as the fraction 1.0 (100%), so that step is skipped.
local function NormalizeHealthOpacity(value, previous)
    if value ~= 1 then return value end
    return (previous or 0) > 1 and 0 or 2
end

local RESET_KEEP_KEYS = {
    installerCompletedVersion = true,
    installerPendingFinalScale = true,
    installerDeferred = true,
    profilePromptApplied = true,
    profilePromptDismissed = true,
    importedProfileVersions = true,
    profileUpdateDismissed = true,
    profileVersionsSeeded = true,
    layoutAspect = true,
    targetArrowPrev = true,
}

-- Back to inari's defaults. Install and profile bookkeeping is kept, and tables are
-- emptied in place because the settings pages hold references to them.
local function ResetSettings()
    EnsureDB()
    local portraits = InariDB.portraits
    for key in pairs(InariDB) do
        if not RESET_KEEP_KEYS[key] and key ~= "portraits" then
            InariDB[key] = nil
        end
    end
    for key, value in pairs(portraits) do
        if type(value) == "table" then
            wipe(value)
        else
            portraits[key] = nil
        end
    end
    State.validatedDB = nil
    EnsureDB()

    ns.SetInariAppearanceMode(InariDB.appearanceMode)
    ns.ApplyEllesmereActionBarPagingOverride()
    UpdateIdleFadeController()
    ScheduleApply(0, true)
end

-- Private EllesmereUI entry points inari relies on, grouped by the module that owns them.
local DOCTOR_HOOKS = {
    {
        addon = "EllesmereUI",
        fields = {
            "DecodeImportString", "ImportProfile", "DeleteProfile", "SwitchProfile", "GetActiveProfileName",
            "SetDarkModeAll", "RefreshAllAddons", "SetActiveTheme", "SetAccentColor", "GetClassColor",
            "RegisterExternalInstaller", "_ModuleNS", "PP",
        },
    },
    { addon = "EllesmereUIUnitFrames", globals = { "_EUF_ReloadFrames", "EllesmereUIUnitFrames_Player" } },
    { addon = "EllesmereUIRaidFrames", globals = { "_ERF_RefreshAll" } },
    { addon = "EllesmereUIActionBars", globals = { "_EAB_UpdateKeybinds", "EABBar_MainBar" } },
    { addon = "EllesmereUICooldownManager", globals = { "_ECME_GetBarFrame", "_ECME_AceDB" } },
    { addon = "EllesmereUINameplates", globals = { "_ENP_RefreshAllSettings" } },
    { addon = "EllesmereUIChat", fields = { "_chatCFD" } },
    { addon = "EllesmereUIBlizzardSkin", globals = { "_EDR_UpdateVisibility", "_EDR_Rebuild" } },
    { addon = "EllesmereUIDamageMeters", globals = { "_EDM_BarTextures" } },
}

local function RunDoctor()
    local getMetadata = C_AddOns and C_AddOns.GetAddOnMetadata
    local isLoaded = C_AddOns and C_AddOns.IsAddOnLoaded
    local function Version(addon)
        return getMetadata and getMetadata(addon, "Version") or "unknown"
    end

    Print("doctor: inari " .. Version(ADDON_NAME) .. ", EllesmereUI " .. Version("EllesmereUI"))
    local active = GetActiveEllesmereProfile()
    Print("active EllesmereUI profile: " .. tostring(active or "unknown")
        .. (IsInariEllesmereProfile(active) and "" or " (not an inari profile; forced settings are paused)"))

    local problems = 0
    for _, entry in ipairs(DOCTOR_HOOKS) do
        if isLoaded and not isLoaded(entry.addon) then
            Print(entry.addon .. ": not loaded")
        else
            local missing = {}
            for _, name in ipairs(entry.globals or {}) do
                if _G[name] == nil then missing[#missing + 1] = name end
            end
            for _, name in ipairs(entry.fields or {}) do
                if not EllesmereUI or EllesmereUI[name] == nil then missing[#missing + 1] = "EllesmereUI." .. name end
            end
            if #missing > 0 then
                problems = problems + #missing
                Print(entry.addon .. ": |cffff6060missing|r " .. table.concat(missing, ", "))
            else
                Print(entry.addon .. ": ok")
            end
        end
    end
    Print(problems == 0 and "all hooks found" or (problems .. " hooks missing; parts of inari will not work with this EllesmereUI version"))
end

local function ShowHelp()
    Print("enabled=" .. tostring(InariDB.enabled) ..
        ", appearance=" .. ns.GetAppearanceMode() ..
        ", bg=" .. tostring(InariDB.classBackground) ..
        ", dark=" .. tostring(InariDB.forceDarkMode) ..
        ", euiTheme=" .. tostring(InariDB.forceEUITheme) ..
        ", friendlyNameplatesOff=" .. tostring(InariDB.disableFriendlyPlayerNameplates) ..
        ", idleFade=" .. tostring(InariDB.fadeIdlePlayerAndCooldowns) ..
        ", formPaging=" .. (InariDB.disableEllesmereActionBarPaging and "off" or "on") ..
        ", chatButtons=" .. (InariDB.forceChatSidebarRight and "right" or "left") ..
        ", opacity=" .. tostring(InariDB.healthBarOpacity or 85) .. "%" ..
        ", tint=" .. math.floor((InariDB.tint or 0.75) * 100 + 0.5) .. "%" ..
        ", shadows=" .. tostring(InariDB.frameShadows == true) ..
        " " .. tostring(InariDB.frameShadowStrength or 70) .. "%" ..
        ", layout=" .. GetLayoutAspectLabel())
    Print("/inari or /iui opens settings, /inari help shows this list")
    Print("general: /inari on|off, /inari apply, /inari media, /inari doctor, /inari reset")
    Print("appearance: /inari appearance dark|class, /inari layout 16|21, /inari bg on|off, /inari theme on|off, /inari tint 75, /inari opacity 85, /inari shadows on|off")
    Print("extras: /inari idlefade on|off, /inari arrows on|off|30, /inari paging on|off, /inari chat right|left, /inari portraits")
    Print("setup: /inari install [ellesmere [16|21]|bigwigs|editmode|exboss|sarena|baganator|settings], /inari cvars, /inari fct on|off, /inari fps, /inari graphics inari")
    Print("profiles: /inari profiles, /inari cdm import")
end

SLASH_INARI1 = "/inari"
SLASH_INARI2 = "/iui"
SLASH_INARI3 = "/inariui"
local TOGGLE_WORDS = {
    on = true, ["1"] = true, ["true"] = true, enable = true, enabled = true,
    off = false, ["0"] = false, ["false"] = false, disable = false, disabled = false,
}

-- Maps an on/off word to true/false; nil for anything else.
local function ParseToggle(arg)
    return TOGGLE_WORDS[arg]
end

local function PrintCVarResult(prefix, applied, skipped, queued)
    Print(FormatCVarResult(prefix, applied, skipped, queued))
end

function Inari_OnAddonCompartmentClick()
    ns.ShowConfigFrame()
end

SlashCmdList.INARI = function(msg)
    EnsureDB()
    msg = (msg or ""):lower():match("^%s*(.-)%s*$")
    local cmd, arg = msg:match("^(%S+)%s*(.*)$")
    local toggle = ParseToggle(arg)

    if not cmd or cmd == "" then
        ns.ShowConfigFrame()
    elseif cmd == "help" or cmd == "status" then
        ShowHelp()
    elseif cmd == "on" then
        InariDB.enabled = true
        ScheduleApply()
        UpdateIdleFadeController()
        Print("enabled")
    elseif cmd == "off" then
        InariDB.enabled = false
        ns.RestoreAll()
        UpdateIdleFadeController()
        Print("disabled")
    elseif cmd == "bg" then
        if toggle == nil then
            Print("usage: /inari bg on|off")
            return
        end
        InariDB.classBackground = toggle
        Print("class background " .. (toggle and "enabled" or "disabled"))
        ScheduleApply()
    elseif cmd == "appearance" or cmd == "mode" then
        if arg == "dark" or arg == "darkmode" then
            ns.SetInariAppearanceMode("dark")
            Print("appearance set to dark mode")
        elseif arg == "class" or arg == "classcolored" or arg == "class-coloured" or arg == "class-colored" then
            ns.SetInariAppearanceMode("class")
            Print("appearance set to class colored")
        else
            Print("usage: /inari appearance dark|class")
            return
        end
    elseif cmd == "layout" or cmd == "aspect" then
        if arg == "" or not arg then
            ns.ShowConfigFrame("layout")
        else
            local aspect = SetLayoutAspect(arg)
            if not aspect then
                Print("usage: /inari layout 16|21")
                return
            end
            if InCombatLockdown and InCombatLockdown() then
                Print("layout set to " .. GetLayoutAspectLabel(aspect) .. "; switch after combat")
                return
            end
            local profileName = GetEllesmereLayoutProfileName(aspect)
            local ok, message
            if EllesmereProfileExists(profileName) and ns.ActivateEllesmereLayoutProfile then
                ok, message = ns.ActivateEllesmereLayoutProfile(profileName)
            else
                ok, message = ns.ImportEllesmereUIProfile()
            end
            Print(message or (ok and ("EllesmereUI switched to " .. profileName) or "EllesmereUI layout change failed"))
            if ok then ReloadUI() end
        end
    elseif cmd == "dark" then
        if toggle == nil then
            Print("usage: /inari dark on|off")
            return
        end
        ns.SetInariAppearanceMode(toggle and "dark" or "class")
        Print(toggle and "appearance set to dark mode" or "appearance set to class colored")
    elseif cmd == "theme" then
        if toggle == nil then
            Print("usage: /inari theme on|off")
            return
        end
        InariDB.forceEUITheme = toggle
        if toggle then ns.ApplyEllesmereThemeSettings(true, true) end
        Print("EllesmereUI theme enforcement " .. (toggle and "enabled" or "disabled"))
        ScheduleApply()
    elseif cmd == "idlefade" or cmd == "fade" then
        if toggle == nil then
            Print("usage: /inari idlefade on|off")
            return
        end
        InariDB.fadeIdlePlayerAndCooldowns = toggle
        UpdateIdleFadeController()
        Print("idle fade " .. (toggle and "enabled" or "disabled"))
    elseif cmd == "arrows" or cmd == "targetarrows" then
        local size = tonumber(arg)
        if toggle ~= nil then
            InariDB.targetArrows = toggle
            Print("target arrows " .. (toggle and "enabled" or "disabled"))
        elseif size then
            size = math.floor(size + 0.5)
            if size < 12 then size = 12 end
            if size > 80 then size = 80 end
            InariDB.targetArrowSize = size
            InariDB.targetArrows = true
            Print("target arrow size set to " .. tostring(size))
        else
            Print("usage: /inari arrows on|off|30")
            return
        end
        if ns.RefreshTargetArrows then ns.RefreshTargetArrows() end
    elseif cmd == "paging" or cmd == "actionbarpaging" or cmd == "barpaging" then
        if toggle == nil then
            Print("usage: /inari paging on|off")
            return
        end
        InariDB.disableEllesmereActionBarPaging = not toggle

        local applied = ns.ApplyEllesmereActionBarPagingOverride()
        ScheduleApply()
        local message = InariDB.disableEllesmereActionBarPaging
            and "form/stealth action bar paging disabled"
            or "form/stealth action bar paging enabled"
        if InCombatLockdown and InCombatLockdown() then
            message = message .. "; will apply after combat"
        elseif not applied then
            message = message .. "; will apply when action bars load"
        end
        Print(message)
    elseif cmd == "chat" then
        local right = toggle
        if arg == "right" then
            right = true
        elseif arg == "left" then
            right = false
        end
        if right == nil then
            Print("usage: /inari chat right|left")
            return
        end
        InariDB.forceChatSidebarRight = right
        ns.ApplyChatSettings()
        Print("chat buttons set to " .. (right and "right" or "left"))
        ScheduleApply()
    elseif cmd == "extras" or cmd == "behavior" or cmd == "portraits" or cmd == "portrait" then
        ns.ShowConfigFrame("extras")
    elseif cmd == "cdm" or cmd == "cooldowns" then
        if arg == "import" then
            local ok, message = ns.ImportInariCooldownLayouts()
            Print(message or (ok and "cooldown layouts imported" or "cooldown import failed"))
        else
            ns.ShowConfigFrame("cooldowns")
        end
    elseif cmd == "install" or cmd == "installer" then
        local sub, rest = (arg or ""):match("^(%S*)%s*(.*)$")
        sub = sub or ""
        rest = (rest or ""):match("^%s*(.-)%s*$") or ""
        if sub == "ellesmere" or sub == "ellesmereui" or sub == "eui" then
            if rest ~= "" then
                local aspect = SetLayoutAspect(rest)
                if not aspect then
                    Print("usage: /inari install ellesmere [16|21]")
                    return
                end
            end
            local ok, message
            if ns.ImportBothEllesmereUIProfiles then
                ok, message = ns.ImportBothEllesmereUIProfiles()
            else
                ok, message = ns.ImportEllesmereUIProfile()
            end
            Print(message or (ok and "EllesmereUI imported" or "EllesmereUI import failed"))
        elseif arg == "bigwigs" or arg == "bw" then
            local ok, message = ns.ImportBigWigsProfile(function(accepted)
                Print(accepted and "BigWigs profile imported as inari" or "BigWigs import cancelled")
            end)
            Print(message or (ok and "BigWigs import opened" or "BigWigs import failed"))
        elseif arg == "editmode" or arg == "edit" then
            local ok, message = ns.ImportEditModeLayout()
            Print(message or (ok and "Edit Mode imported" or "Edit Mode import failed"))
        elseif arg == "blinkii" or arg == "blinkiis" or arg == "portraits" then
            Print("player and target portraits are built into inari; Blinkii's Portraits is no longer required")
        elseif arg == "exboss" or arg == "exb" then
            local ok, message = ns.ImportEXBossProfile()
            Print(message or (ok and "EXBoss imported" or "EXBoss import failed"))
        elseif arg == "sarena" or arg == "arena" or arg == "sarenareloaded" then
            local ok, message = ns.ImportSArenaProfile()
            Print(message or (ok and "sArena imported" or "sArena import failed"))
        elseif arg == "baganator" or arg == "bags" or arg == "bag" then
            local ok, message = ns.ImportBaganatorProfile()
            Print(message or (ok and "Baganator imported" or "Baganator import failed"))
        elseif arg == "settings" or arg == "extras" or arg == "blizz" or arg == "blizzard" then
            local ok, message = ns.ApplyEllesmereExtrasSettings()
            Print(message or (ok and "Ellesmere settings applied" or "Ellesmere settings failed"))
        else
            ns.ShowInstallerFrame()
        end
    elseif cmd == "profiles" or cmd == "applyprofiles" or cmd == "alt" then
        local ok, message = ns.ApplyInstalledProfilesToCharacter(true)
        Print(message)
        if ok then
            Print("reload UI to finish applying loaded profiles")
        end
    elseif cmd == "cvars" then
        PrintCVarResult("base CVars set: ", ApplyCVarTable(BASE_CVARS))
    elseif cmd == "fct" or cmd == "combattext" then
        if toggle == nil then
            Print("usage: /inari fct on|off")
            return
        end
        PrintCVarResult("floating combat text " .. (toggle and "enabled" or "disabled") .. ": ",
            ApplyFloatingCombatText(toggle and 1 or 0))
    elseif cmd == "fps" or cmd == "graphics" then
        if cmd == "graphics" and (arg == "inari" or arg == "inaris" or arg == "inari's") then
            PrintCVarResult("Inari's graphics applied: ", ApplyInariGraphicsSettings())
            return
        end
        PrintCVarResult("FPS settings applied: ", ApplyFPSSettings())
    elseif cmd == "tint" then
        local value = tonumber(arg)
        if not value then
            Print("usage: /inari tint 75")
            return
        end
        if value > 1 then value = value / 100 end
        if value < 0 then value = 0 end
        if value > 1 then value = 1 end
        InariDB.tint = value
        ScheduleApply()
        Print("class background tint set to " .. math.floor(value * 100 + 0.5) .. "%")
    elseif cmd == "opacity" then
        local value = tonumber(arg)
        if not value then
            Print("usage: /inari opacity 75")
            return
        end
        value = math.floor(value + 0.5)
        if value < 0 then value = 0 end
        if value > 100 then value = 100 end
        value = NormalizeHealthOpacity(value)
        InariDB.healthBarOpacity = value
        InariDB.forceOpacity = true
        if ns.SetAllHealthOpacity(value) then
            ScheduleApply()
            ns.ReloadEllesmereFrames()
            Print("health opacity set to " .. value .. "%")
        else
            Print("Ellesmere unit frame profiles were not ready")
        end
    elseif cmd == "shadows" or cmd == "shadow" or cmd == "frameshadows" then
        local strength = tonumber(arg)
        if toggle ~= nil then
            InariDB.frameShadows = toggle
            Print("frame shadows " .. (toggle and "enabled" or "disabled"))
        elseif strength then
            if strength < 0 then strength = 0 end
            if strength > 100 then strength = 100 end
            InariDB.frameShadows = true
            InariDB.frameShadowStrength = strength
            Print("shadow strength set to " .. tostring(strength) .. "%")
        else
            Print("usage: /inari shadows on|off|70")
            return
        end
        ScheduleApply()
    elseif cmd == "doctor" or cmd == "check" then
        RunDoctor()
    elseif cmd == "reset" then
        if arg ~= "confirm" then
            Print("this resets inari's own settings to defaults (imported profiles are kept); type /inari reset confirm")
            return
        end
        ResetSettings()
        Print("settings reset to defaults")
    elseif cmd == "apply" or cmd == "reload" then
        local count = ApplyAll(true)
        ns.ApplyEllesmereThemeSettings(true, true)
        Print("patched " .. count .. " unit frame bars")
    elseif cmd == "fonts" or cmd == "media" then
        if RegisterMedia() then
            Print("registered inari fonts, statusbars, sounds, BigWigs countdown, and bar style")
        else
            Print("LibSharedMedia-3.0 / BigWigs API was not available")
        end
    else
        ShowHelp()
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
eventFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
eventFrame:RegisterEvent("UNIT_PET")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
pcall(eventFrame.RegisterEvent, eventFrame, "PLAYER_CAN_GLIDE_CHANGED")
pcall(eventFrame.RegisterEvent, eventFrame, "PLAYER_IS_GLIDING_CHANGED")
pcall(eventFrame.RegisterEvent, eventFrame, "PLAYER_DIFFICULTY_CHANGED")
pcall(eventFrame.RegisterUnitEvent, eventFrame, "PLAYER_SPECIALIZATION_CHANGED", "player")
pcall(eventFrame.RegisterEvent, eventFrame, "ACTIVE_TALENT_GROUP_CHANGED")
pcall(eventFrame.RegisterEvent, eventFrame, "TRAIT_CONFIG_UPDATED")
local RELATED_ADDONS = {
    [ADDON_NAME] = true,
    EllesmereUIUnitFrames = true,
    EllesmereUIRaidFrames = true,
    EllesmereUIChat = true,
    EllesmereUINameplates = true,
    EllesmereUICooldownManager = true,
    EllesmereUIResourceBars = true,
    EllesmereUIActionBars = true,
    BigWigs = true,
    BigWigs_Plugins = true,
}

local function Bootstrap(forceThemeLive, retry)
    if not State.fontsRegistered or not State.statusbarsRegistered or not State.soundsRegistered or not State.countdownRegistered or not State.barStyleRegistered then
        RegisterMedia()
    end
    EnsureDB()
    HookFriendlyPlayerNameplateCVars()
    HookReload()
    ns.ApplyEllesmereThemeSettings(forceThemeLive)
    State.discoveredFramesCached = false
    State.applyingBootstrap = true
    if ns.ApplyConfiguredProfileSettings() then ns.ReloadEllesmereFrames() end
    ApplyAll(true)
    State.applyingBootstrap = false
    ScheduleIdleFadeUpdate(0)
    State.bootstrapped = true
    if retry then ScheduleStartupRetries() end
end

local function RefreshAfterLoadScreen()
    HookReload()
    ScheduleIdleFadeUpdate(0)
    if ns.RefreshPortraits then ns.RefreshPortraits() end
    if ns.QueueFrameShadowRefresh then ns.QueueFrameShadowRefresh() end
    if not PlayerFrameStillPatched() then
        State.discoveredFramesCached = false
        State.framesPatched = false
        ScheduleApply(0, true)
    end
end

local ELLESMERE_RUNTIME_ADDONS = {
    EllesmereUIUnitFrames = true,
    EllesmereUIRaidFrames = true,
    EllesmereUIChat = true,
    EllesmereUINameplates = true,
    EllesmereUICooldownManager = true,
    EllesmereUIResourceBars = true,
    EllesmereUIActionBars = true,
}

eventFrame:SetScript("OnEvent", function(_, event, addonName, ...)
    if event == "ADDON_LOADED" then
        if addonName == ADDON_NAME then
            -- Keeps EllesmereUI's own first-install picker quiet; inari owns the setup.
            if EllesmereUI and type(EllesmereUI.RegisterExternalInstaller) == "function" then
                pcall(EllesmereUI.RegisterExternalInstaller, "inari")
            end
            Bootstrap(true, true)
            return
        end
        if not RELATED_ADDONS[addonName] then return end
        if addonName == "BigWigs" or addonName == "BigWigs_Plugins" then
            RegisterMedia()
            return
        end
        if State.bootstrapped and ELLESMERE_RUNTIME_ADDONS[addonName] then
            HookReload()
            State.discoveredFramesCached = false
            ScheduleApply(0, true)
        end
        return
    end

    if event == "PLAYER_LOGIN" then
        if not State.bootstrapped then Bootstrap(true, true) end
        ns.ScheduleInstalledProfilesOffer()
        ScheduleFreshInstallerOpen()
        return
    end

    if event == "PLAYER_ENTERING_WORLD" then
        if not State.bootstrapped then
            Bootstrap(true, true)
        else
            RefreshAfterLoadScreen()
        end
        ns.ScheduleInstalledProfilesOffer()
        ScheduleFreshInstallerOpen()
        return
    end

    if event == "PLAYER_TARGET_CHANGED" then
        PatchUnit("target")
        PatchUnit("targettarget")
        ScheduleIdleFadeUpdate(0)
        return
    end

    if event == "PLAYER_FOCUS_CHANGED" then
        PatchUnit("focus")
        PatchUnit("focustarget")
        return
    end

    if event == "UNIT_PET" then
        PatchUnit("pet")
        return
    end

    if event == "GROUP_ROSTER_UPDATE" or event == "INSTANCE_ENCOUNTER_ENGAGE_UNIT" then
        ScheduleRosterPatch()
        return
    end

    if event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" or event == "ZONE_CHANGED_NEW_AREA" or event == "PLAYER_DIFFICULTY_CHANGED"
        or event == "PLAYER_MOUNT_DISPLAY_CHANGED" or event == "PLAYER_CAN_GLIDE_CHANGED" or event == "PLAYER_IS_GLIDING_CHANGED" then
        -- InCombatLockdown() is still false while PLAYER_REGEN_DISABLED fires.
        ApplyIdleFadeState(event == "PLAYER_REGEN_DISABLED")
        return
    end

    if event == "PLAYER_SPECIALIZATION_CHANGED" or event == "ACTIVE_TALENT_GROUP_CHANGED" or event == "TRAIT_CONFIG_UPDATED" then
        ns.ApplyEllesmereThemeSettings(true)
        if type(InariDB) == "table" and InariDB.enabled then
            ns.ApplyEllesmereActionBarPagingOverride()
        end
        ScheduleSpecApplyBurst()
        return
    end
end)

C_Timer.After(0, function()
    RegisterMedia()
    EnsureDB()
    HookFriendlyPlayerNameplateCVars()
    HookReload()
end)

function ns.IsAddonPresent(name)
    if not name then return true end
    if C_AddOns and C_AddOns.DoesAddOnExist then
        return C_AddOns.DoesAddOnExist(name) == true
    end
    if C_AddOns and C_AddOns.GetAddOnInfo then
        local addonName = C_AddOns.GetAddOnInfo(name)
        return addonName ~= nil and addonName ~= ""
    end
    if GetAddOnInfo then
        local addonName = GetAddOnInfo(name)
        return addonName ~= nil and addonName ~= ""
    end
    return false
end

ns.Print = Print
ns.EnsureDB = EnsureDB
ns.DetectLayoutAspect = DetectLayoutAspect
ns.GetLayoutAspect = GetLayoutAspect
ns.SetLayoutAspect = SetLayoutAspect
ns.GetLayoutAspectLabel = GetLayoutAspectLabel
ns.GetEllesmereLayoutProfileName = GetEllesmereLayoutProfileName
ns.IsInariEllesmereProfile = IsInariEllesmereProfile
ns.IsInariEllesmereProfileActive = IsInariEllesmereProfileActive
ns.EllesmereProfileExists = EllesmereProfileExists
ns.GetActiveEllesmereProfile = GetActiveEllesmereProfile
ns.TryLoadAddon = TryLoadAddon
ns.GetInariCVar = GetInariCVar
ns.SetInariCVar = SetInariCVar
ns.ApplyCVarTable = ApplyCVarTable
ns.ApplyFPSSettings = ApplyFPSSettings
ns.ApplyInariGraphicsSettings = ApplyInariGraphicsSettings
ns.ApplyFloatingCombatText = ApplyFloatingCombatText
ns.ApplyInariUIScale = ApplyInariUIScale
ns.RegisterMedia = RegisterMedia
ns.GetInariCharacterKey = GetInariCharacterKey
ns.MarkProfilePromptApplied = MarkProfilePromptApplied
ns.MarkInstallerCompleted = MarkInstallerCompleted
ns.MarkInstallerPendingFinalScale = MarkInstallerPendingFinalScale
ns.IsInstallerComplete = function()
    EnsureDB()
    return InariDB.installerPendingFinalScale ~= true and InariDB.installerCompletedVersion == CONST.profilePromptVersion
end
ns.UI_SCALE = CONST.UI_SCALE
ns.MarkProfilePromptDismissed = MarkProfilePromptDismissed
ns.ScheduleApply = ScheduleApply
ns.ApplyAll = ApplyAll
ns.UpdateIdleFadeController = UpdateIdleFadeController
ns.ScheduleIdleFadeUpdate = ScheduleIdleFadeUpdate
ns.ApplyFriendlyPlayerNameplatePreference = ApplyFriendlyPlayerNameplatePreference
ns.HookFriendlyPlayerNameplateCVars = HookFriendlyPlayerNameplateCVars
ns.GetEllesmereProfile = GetEllesmereProfile
ns.GetEllesmereRaidFramesProfile = GetEllesmereRaidFramesProfile
ns.GetEllesmereAddonProfile = GetEllesmereAddonProfile
ns.EnsureEllesmereAddonProfile = EnsureEllesmereAddonProfile

ns.UnitKey = UnitKey
ns.LegacyMiniUnitKey = LegacyMiniUnitKey
ns.RunAfterCombat = RunAfterCombat
ns.FormatCVarResult = FormatCVarResult
ns.NormalizeHealthOpacity = NormalizeHealthOpacity
ns.ResetSettings = ResetSettings
