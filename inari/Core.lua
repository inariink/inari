local ADDON_NAME, ns = ...

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
    profileUpdatePromptDismissedThisSession = false,
    cooldownImportFrame = nil,
    installerFrame = nil,
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

local function ApplyCVarTable(cvars)
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

local function ApplyFPSSettings()
    local applied, skipped = ApplyCVarTable(FPS_CVARS)
    if type(InariDB) == "table" then InariDB.graphicsPreset = "fps" end

    return applied, skipped
end

local function ApplyInariGraphicsSettings()
    local applied, skipped = ApplyCVarTable(INARI_GRAPHICS_CVARS)
    if type(InariDB) == "table" then InariDB.graphicsPreset = "inari" end
    return applied, skipped
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

local ApplyChatSettings

local function TryLoadAddon(name)
    if C_AddOns and C_AddOns.LoadAddOn then
        pcall(C_AddOns.LoadAddOn, name)
    elseif LoadAddOn then
        pcall(LoadAddOn, name)
    end
end

local function CopyPlainTable(src, dest)
    if type(dest) ~= "table" then dest = {} end
    if type(src) ~= "table" then return dest end

    for key, value in pairs(src) do
        if type(value) == "table" then
            dest[key] = CopyPlainTable(value, type(dest[key]) == "table" and dest[key] or {})
        else
            dest[key] = value
        end
    end

    return dest
end

local function ApplyInariUIScale(applyLive)
    TryLoadAddon("EllesmereUI")

    if type(EllesmereUIDB) ~= "table" then EllesmereUIDB = {} end
    EllesmereUIDB.ppFixedScale = true
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

EnsureDB = function()
    if type(InariDB) ~= "table" then InariDB = {} end
    if InariDB.autoPresetVersion ~= 1 then
        InariDB.enabled = true
        InariDB.classBackground = true
        InariDB.darkOpacity = true
        InariDB.forceDarkMode = true
        InariDB.appearanceMode = "dark"
        InariDB.forceEUITheme = true
        InariDB.forceOpacity = true
        InariDB.forceChatSidebarRight = true
        InariDB.disableFriendlyPlayerNameplates = true
        InariDB.fadeIdlePlayerAndCooldowns = false
        InariDB.disableEllesmereActionBarPaging = true
        InariDB.healthBarOpacity = 85
        InariDB.tint = 0.75
        InariDB.autoPresetVersion = 1
    end
    if InariDB.enabled == nil then InariDB.enabled = true end
    if InariDB.classBackground == nil then InariDB.classBackground = true end
    if InariDB.darkOpacity == nil then InariDB.darkOpacity = true end
    if InariDB.forceDarkMode == nil then InariDB.forceDarkMode = true end
    if InariDB.appearanceMode ~= "dark" and InariDB.appearanceMode ~= "class" then
        InariDB.appearanceMode = InariDB.forceDarkMode and "dark" or "class"
    end
    if InariDB.forceEUITheme == nil then InariDB.forceEUITheme = true end
    if InariDB.forceOpacity == nil then InariDB.forceOpacity = true end
    if InariDB.forceChatSidebarRight == nil then InariDB.forceChatSidebarRight = true end
    if InariDB.disableFriendlyPlayerNameplates == nil then InariDB.disableFriendlyPlayerNameplates = true end
    if InariDB.fadeIdlePlayerAndCooldowns == nil then InariDB.fadeIdlePlayerAndCooldowns = false end
    if InariDB.disableEllesmereActionBarPaging == nil then InariDB.disableEllesmereActionBarPaging = true end
    if type(InariDB.healthBarOpacity) ~= "number" then InariDB.healthBarOpacity = 85 end
    if type(InariDB.tint) ~= "number" then InariDB.tint = 0.75 end
    if InariDB.frameShadows == nil then InariDB.frameShadows = true end
    if type(InariDB.frameShadowStrength) ~= "number" then InariDB.frameShadowStrength = 70 end
    if InariDB.frameShadowStrength < 0 then InariDB.frameShadowStrength = 0 end
    if InariDB.frameShadowStrength > 100 then InariDB.frameShadowStrength = 100 end
    if type(InariDB.profilePromptApplied) ~= "table" then InariDB.profilePromptApplied = {} end
    if type(InariDB.profilePromptDismissed) ~= "table" then InariDB.profilePromptDismissed = {} end
    if InariDB.profilePromptEnabled == nil then InariDB.profilePromptEnabled = true end
    if InariDB.layoutAspect ~= "16" and InariDB.layoutAspect ~= "21" then
        InariDB.layoutAspect = DetectLayoutAspect()
    end
    if type(InariDB.importedProfileVersions) ~= "table" then InariDB.importedProfileVersions = {} end
    if type(InariDB.profileUpdateDismissed) ~= "table" then InariDB.profileUpdateDismissed = {} end
    if InariDB.profileUpdateEnabled == nil then InariDB.profileUpdateEnabled = true end
    if InariDB.graphicsPreset ~= "fps" and InariDB.graphicsPreset ~= "inari" then InariDB.graphicsPreset = nil end
    if InariDB.floatingCombatTextPreset ~= "enabled" and InariDB.floatingCombatTextPreset ~= "disabled" then InariDB.floatingCombatTextPreset = nil end
    InariDB.qol = nil
    if InariDB.healthBarOpacity < 0 then InariDB.healthBarOpacity = 0 end
    if InariDB.healthBarOpacity > 100 then InariDB.healthBarOpacity = 100 end
    if InariDB.tint < 0 then InariDB.tint = 0 end
    if InariDB.tint > 1 then InariDB.tint = 1 end
    if type(InariDB.lastConfigPage) ~= "string" then InariDB.lastConfigPage = "home" end
    if type(InariDB.portraits) ~= "table" then InariDB.portraits = {} end
    local portraits = InariDB.portraits
    if InariDB.extrasDefaultsVersion ~= 2 then
        InariDB.disableEllesmereActionBarPaging = true
        InariDB.forceChatSidebarRight = true
        InariDB.disableFriendlyPlayerNameplates = true
        InariDB.fadeIdlePlayerAndCooldowns = false
        portraits.enabled = true
        portraits.size = 52
        portraits.zoom = 0.22
        portraits.player = type(portraits.player) == "table" and portraits.player or {}
        portraits.player.enable = true
        portraits.player.anchor = "LEFT"
        portraits.player.x = 0
        portraits.player.y = 0
        portraits.target = type(portraits.target) == "table" and portraits.target or {}
        portraits.target.enable = true
        portraits.target.anchor = "RIGHT"
        portraits.target.x = 0
        portraits.target.y = 0
        InariDB.extrasDefaultsVersion = 2
    end
    if portraits.enabled == nil then portraits.enabled = true end
    if type(portraits.size) ~= "number" then portraits.size = 52 end
    if portraits.size < 16 then portraits.size = 16 end
    if portraits.size > 256 then portraits.size = 256 end
    if type(portraits.zoom) ~= "number" then portraits.zoom = 0.22 end
    if portraits.zoom < 0 then portraits.zoom = 0 end
    if portraits.zoom > 1 then portraits.zoom = 1 end
    if type(portraits.level) ~= "number" then portraits.level = 20 end
    if type(portraits.player) ~= "table" then portraits.player = {} end
    if portraits.player.enable == nil then portraits.player.enable = true end
    if portraits.player.anchor ~= "LEFT" and portraits.player.anchor ~= "RIGHT" then portraits.player.anchor = "LEFT" end
    if type(portraits.player.x) ~= "number" then portraits.player.x = 0 end
    if type(portraits.player.y) ~= "number" then portraits.player.y = 0 end
    if type(portraits.target) ~= "table" then portraits.target = {} end
    if portraits.target.enable == nil then portraits.target.enable = true end
    if portraits.target.anchor ~= "LEFT" and portraits.target.anchor ~= "RIGHT" then portraits.target.anchor = "RIGHT" end
    if type(portraits.target.x) ~= "number" then portraits.target.x = 0 end
    if type(portraits.target.y) ~= "number" then portraits.target.y = 0 end
    if InariDB.targetArrows == nil then InariDB.targetArrows = true end
    if type(InariDB.targetArrowSize) ~= "number" then InariDB.targetArrowSize = 30 end
    InariDB.targetArrowSize = math.floor(InariDB.targetArrowSize + 0.5)
    if InariDB.targetArrowSize < 12 then InariDB.targetArrowSize = 12 end
    if InariDB.targetArrowSize > 80 then InariDB.targetArrowSize = 80 end
end

local function ApplyFriendlyPlayerNameplatePreference()
    EnsureDB()
    if not InariDB.disableFriendlyPlayerNameplates then return false end

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

local function ShouldIdleFade()
    EnsureDB()
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

local function ApplyIdleFadeState()
    if not ShouldIdleFade() then
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
    local signature = ApplySignature()
    local settingsUnchanged = State.applySignature == signature
    if not force and settingsUnchanged and State.framesPatched then
        return State.lastPatchCount or 0
    end
    if not settingsUnchanged or not State.framesPatched then
        ns.ApplyEllesmereThemeSettings()
        ns.ApplyConfiguredProfileSettings()
        ApplyFriendlyPlayerNameplatePreference()
        ns.ApplyChatSettings()
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
    return InariDB.installerPendingFinalScale == true or InariDB.installerCompletedVersion ~= CONST.profilePromptVersion
end

local function ScheduleFreshInstallerOpen()
    if State.freshInstallerOpenScheduled then return end
    State.freshInstallerOpenScheduled = true
    C_Timer.After(2, function()
        State.freshInstallerOpenScheduled = false
        if InCombatLockdown and InCombatLockdown() then return end
        if ShouldOpenFreshInstaller() then
            ns.ShowInstallerFrame()
        end
    end)
end

local function PrintDamageMeterPositions()
    local found = false
    for index = 1, 5 do
        local frame = _G["EllesmereUIDMFrame" .. index]
        if frame then
            found = true
            local left = frame:GetLeft()
            local top = frame:GetTop()
            local width = frame:GetWidth()
            local height = frame:GetHeight()
            if left and top and width and height then
                Print(("dm window %d: x=%d, y=%d, width=%d, height=%d"):format(
                    index,
                    math.floor(left + 0.5),
                    math.floor(top + 0.5),
                    math.floor(width + 0.5),
                    math.floor(height + 0.5)
                ))
            else
                Print("dm window " .. index .. ": position is not available yet")
            end
        end
    end

    if not found then
        Print("no Damage Meter windows found")
    end
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
    Print("general: /inari on|off, /inari apply, /inari media")
    Print("appearance: /inari appearance dark|class, /inari layout 16|21, /inari bg on|off, /inari theme on|off, /inari tint 75, /inari opacity 85, /inari shadows on|off")
    Print("extras: /inari idlefade on|off, /inari arrows on|off|30, /inari paging on|off, /inari chat right|left, /inari portraits")
    Print("setup: /inari install [ellesmere [16|21]|bigwigs|editmode|exboss|sarena|baganator|settings], /inari cvars, /inari fct on|off, /inari fps, /inari graphics inari")
    Print("profiles: /inari profiles, /inari cdm import")
end

SLASH_INARI1 = "/inari"
SLASH_INARI2 = "/iui"
SLASH_INARI3 = "/inariui"
SlashCmdList.INARI = function(msg)
    EnsureDB()
    msg = (msg or ""):lower():match("^%s*(.-)%s*$")
    local cmd, arg = msg:match("^(%S+)%s*(.*)$")

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
        if arg == "on" or arg == "1" or arg == "true" then
            InariDB.classBackground = true
            Print("class background enabled")
        elseif arg == "off" or arg == "0" or arg == "false" then
            InariDB.classBackground = false
            Print("class background disabled")
        else
            Print("usage: /inari bg on|off")
            return
        end
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
            if type(EllesmereUIDB) == "table"
                and type(EllesmereUIDB.profiles) == "table"
                and type(EllesmereUIDB.profiles[profileName]) == "table"
                and ns.ActivateEllesmereLayoutProfile
            then
                ok, message = ns.ActivateEllesmereLayoutProfile(profileName)
            else
                ok, message = ns.ImportEllesmereUIProfile()
            end
            Print(message or (ok and ("EllesmereUI switched to " .. profileName) or "EllesmereUI layout change failed"))
            if ok then ReloadUI() end
        end
    elseif cmd == "dark" then
        if arg == "on" or arg == "1" or arg == "true" then
            ns.SetInariAppearanceMode("dark")
            Print("appearance set to dark mode")
        elseif arg == "off" or arg == "0" or arg == "false" then
            ns.SetInariAppearanceMode("class")
            Print("appearance set to class colored")
        else
            Print("usage: /inari dark on|off")
            return
        end
    elseif cmd == "theme" then
        if arg == "on" or arg == "1" or arg == "true" then
            InariDB.forceEUITheme = true
            ns.ApplyEllesmereThemeSettings(true, true)
            Print("EllesmereUI theme enforcement enabled")
        elseif arg == "off" or arg == "0" or arg == "false" then
            InariDB.forceEUITheme = false
            Print("EllesmereUI theme enforcement disabled")
        else
            Print("usage: /inari theme on|off")
            return
        end
        ScheduleApply()
    elseif cmd == "idlefade" or cmd == "fade" then
        if arg == "on" or arg == "1" or arg == "true" then
            InariDB.fadeIdlePlayerAndCooldowns = true
            UpdateIdleFadeController()
            Print("idle fade enabled")
        elseif arg == "off" or arg == "0" or arg == "false" then
            InariDB.fadeIdlePlayerAndCooldowns = false
            UpdateIdleFadeController()
            Print("idle fade disabled")
        else
            Print("usage: /inari idlefade on|off")
            return
        end
    elseif cmd == "arrows" or cmd == "targetarrows" then
        if arg == "on" or arg == "1" or arg == "true" then
            InariDB.targetArrows = true
            if ns.RefreshTargetArrows then ns.RefreshTargetArrows() end
            Print("target arrows enabled")
        elseif arg == "off" or arg == "0" or arg == "false" then
            InariDB.targetArrows = false
            if ns.RefreshTargetArrows then ns.RefreshTargetArrows() end
            Print("target arrows disabled")
        else
            local size = tonumber(arg)
            if size then
                size = math.floor(size + 0.5)
                if size < 12 then size = 12 end
                if size > 80 then size = 80 end
                InariDB.targetArrowSize = size
                InariDB.targetArrows = true
                if ns.RefreshTargetArrows then ns.RefreshTargetArrows() end
                Print("target arrow size set to " .. tostring(size))
            else
                Print("usage: /inari arrows on|off|30")
                return
            end
        end
    elseif cmd == "paging" or cmd == "actionbarpaging" or cmd == "barpaging" then
        if arg == "off" or arg == "0" or arg == "false" or arg == "disable" or arg == "disabled" then
            InariDB.disableEllesmereActionBarPaging = true
        elseif arg == "on" or arg == "1" or arg == "true" or arg == "enable" or arg == "enabled" then
            InariDB.disableEllesmereActionBarPaging = false
        else
            Print("usage: /inari paging on|off")
            return
        end

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
        if arg == "right" or arg == "on" or arg == "1" or arg == "true" then
            InariDB.forceChatSidebarRight = true
            ns.ApplyChatSettings()
            Print("chat buttons set to right")
        elseif arg == "left" or arg == "off" or arg == "0" or arg == "false" then
            InariDB.forceChatSidebarRight = false
            ns.ApplyChatSettings()
            Print("chat buttons set to left")
        else
            Print("usage: /inari chat right|left")
            return
        end
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
            local ok, message = ns.ImportBothEllesmereUIProfiles and ns.ImportBothEllesmereUIProfiles() or ns.ImportEllesmereUIProfile()
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
    elseif cmd == "dmpos" or cmd == "damagepos" or cmd == "meterpos" then
        PrintDamageMeterPositions()
    elseif cmd == "cvars" then
        local applied, skipped = ApplyCVarTable(BASE_CVARS)
        local message = "set CVars: " .. applied .. " applied"
        if skipped > 0 then message = message .. ", " .. skipped .. " skipped" end
        Print(message)
    elseif cmd == "fct" or cmd == "combattext" then
        local value
        if arg == "on" or arg == "1" or arg == "true" or arg == "enable" then
            value = 1
        elseif arg == "off" or arg == "0" or arg == "false" or arg == "disable" then
            value = 0
        else
            Print("usage: /inari fct on|off")
            return
        end
        local applied, skipped = ApplyFloatingCombatText(value)
        local message = "floating combat text " .. (value == 1 and "enabled" or "disabled") .. ": " .. applied .. " CVars"
        if skipped > 0 then message = message .. ", " .. skipped .. " skipped" end
        Print(message)
    elseif cmd == "fps" or cmd == "graphics" then
        if cmd == "graphics" and (arg == "inari" or arg == "inaris" or arg == "inari's") then
            local applied, skipped = ApplyInariGraphicsSettings()
            local message = "Inari's graphics applied: " .. applied .. " CVars"
            if skipped > 0 then message = message .. ", " .. skipped .. " skipped" end
            Print(message)
            return
        end

        local applied, skipped = ApplyFPSSettings()
        local message = "FPS settings applied: " .. applied .. " CVars"
        if skipped > 0 then message = message .. ", " .. skipped .. " skipped" end
        Print(message)
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
        if arg == "on" or arg == "1" or arg == "true" then
            InariDB.frameShadows = true
            Print("frame shadows enabled")
        elseif arg == "off" or arg == "0" or arg == "false" then
            InariDB.frameShadows = false
            Print("frame shadows disabled")
        else
            local strength = tonumber(arg)
            if strength then
                if strength < 0 then strength = 0 end
                if strength > 100 then strength = 100 end
                InariDB.frameShadows = true
                InariDB.frameShadowStrength = strength
                Print("shadow strength set to " .. tostring(strength) .. "%")
            else
                Print("usage: /inari shadows on|off|70")
                return
            end
        end
        ScheduleApply()
    elseif cmd == "apply" or cmd == "reload" then
        local count = ApplyAll()
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
pcall(eventFrame.RegisterEvent, eventFrame, "PLAYER_SPECIALIZATION_CHANGED")
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
        ApplyIdleFadeState()
        return
    end

    if event == "PLAYER_SPECIALIZATION_CHANGED" or event == "ACTIVE_TALENT_GROUP_CHANGED" or event == "TRAIT_CONFIG_UPDATED" then
        ns.ApplyEllesmereThemeSettings(true)
        ns.ApplyEllesmereActionBarPagingOverride()
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
ns.TryLoadAddon = TryLoadAddon
ns.CopyPlainTable = CopyPlainTable
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
