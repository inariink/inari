std = "lua51"
max_line_length = false
codes = true

exclude_files = {
    "inari/ProfileStrings.lua",
    "inari/CooldownLayouts.lua",
}

ignore = {
    "211/ADDON_NAME", -- every file unpacks `...` the same way
    "212",            -- unused arguments (callback signatures)
    "432",            -- nested closures reuse `self`
}

-- Written by inari: its own globals and the other addons' saved variables it imports into.
globals = {
    "InariDB",
    "InariProfiles",
    "InariCooldownLayouts",
    "InariCooldownLayoutsForever",
    "InariUI",
    "Inari_OnAddonCompartmentClick",
    "SLASH_INARI1",
    "SLASH_INARI2",
    "SLASH_INARI3",
    "SlashCmdList",
    "UISpecialFrames",
    "EllesmereUI",
    "EllesmereUIDB",
    "BigWigs3DB",
    "EXBossDataDB",
    "sArena_ReloadedDB",
}

read_globals = {
    -- Other addons
    "BAGANATOR_CONFIG",
    "BAGANATOR_CURRENT_PROFILE",
    "Baganator",
    "BigWigsAPI",
    "BigWigsLoader",
    "CooldownViewerSettings",
    "DynamicCam",
    "DynamicCamDB",
    "ExBoss",
    "LibStub",
    "sArena",

    -- WoW API
    "C_ActionBar",
    "C_AddOns",
    "C_CVar",
    "C_EditMode",
    "C_NamePlate",
    "C_Timer",
    "ClearOverrideBindings",
    "Constants",
    "CopyTable",
    "CreateFrame",
    "DEFAULT_CHAT_FRAME",
    "Enum",
    "FACTION_BAR_COLORS",
    "GetAddOnInfo",
    "GetAddOnMetadata",
    "GetBindingKey",
    "GetBuildInfo",
    "GetCVar",
    "GetNumSpecializations",
    "GetOverrideBarIndex",
    "GetRealmName",
    "GetScreenHeight",
    "GetScreenWidth",
    "GetSpecialization",
    "GetSpecializationInfo",
    "GetVehicleBarIndex",
    "InCombatLockdown",
    "IsInInstance",
    "IsUnitModelReadyForUI",
    "LOCALIZED_CLASS_NAMES_MALE",
    "LoadAddOn",
    "MouseIsOver",
    "NUM_ACTIONBAR_PAGES",
    "PixelUtil",
    "RAID_CLASS_COLORS",
    "RegisterStateDriver",
    "ReloadUI",
    "STANDARD_TEXT_FONT",
    "SetCVar",
    "SetOverrideBindingClick",
    "SetPortraitTexture",
    "UIFrameFadeIn",
    "UIParent",
    "UnitAffectingCombat",
    "UnitCanAttack",
    "UnitCastingInfo",
    "UnitChannelInfo",
    "UnitClass",
    "UnitExists",
    "UnitGUID",
    "UnitIsConnected",
    "UnitIsDead",
    "UnitIsPlayer",
    "UnitIsUnit",
    "UnitIsVisible",
    "UnitName",
    "UnitReaction",
    "UnregisterStateDriver",
    "hooksecurefunc",
    "issecretvalue",
    "tinsert",
    "tremove",
    "wipe",
}
