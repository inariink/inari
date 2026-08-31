local ADDON_NAME, ns = ...
local TryLoadAddon = ns.TryLoadAddon
local CopyPlainTable = ns.CopyPlainTable
local EnsureDB = ns.EnsureDB
local Print = ns.Print
local CONST = ns.CONST
local State = ns.State
local EXBOSS_IMPORT_SLOT_KEYS = ns.EXBOSS_IMPORT_SLOT_KEYS
local EXBOSS_IMPORT_AUTHOR_SUFFIXES = ns.EXBOSS_IMPORT_AUTHOR_SUFFIXES
local GetInariCharacterKey = ns.GetInariCharacterKey
local GetBundledProfileVersion
local MarkImportedProfileVersion
local ActivateEllesmereLayoutProfile
local EllesmereProfileExists
local GetActiveEllesmereProfile
local ImportInariCooldownLayouts
local HasInariCooldownLayouts

local function GetEllesmereLayoutProfileName(aspect)
    aspect = aspect or (ns.GetLayoutAspect and ns.GetLayoutAspect()) or "16"
    return aspect == "21" and "inari21:9" or "inari16:9"
end

local function IsInariEllesmereProfile(name)
    return name == "inari" or name == "inari16:9" or name == "inari21:9"
end

-- Regular Ellesmere exports merge onto the active profile. Leave an inari16:9
-- / inari21:9 profile before importing the other layout, or the two mix.
local function SwitchAwayFromOtherInariEllesmereProfile(profileName)
    local active = GetActiveEllesmereProfile and GetActiveEllesmereProfile()
    if not active or active == profileName then return end
    if not IsInariEllesmereProfile(active) then return end
    if not EllesmereUI or type(EllesmereUI.SwitchProfile) ~= "function" then return end
    if EllesmereProfileExists and EllesmereProfileExists("Default") then
        pcall(EllesmereUI.SwitchProfile, "Default")
    end
end

local function RemapEllesmereFullAccountProfileToInari(payload, profileName)
    profileName = profileName or GetEllesmereLayoutProfileName()
    local data = payload and payload.data
    if type(data) ~= "table" then
        return false, "EllesmereUI full-account payload is missing data"
    end

    local oldName = data.activeProfile or payload.profileName or "Default"
    data.profiles = data.profiles or {}

    if oldName ~= profileName then
        if type(data.profiles[oldName]) == "table" then
            data.profiles[profileName] = data.profiles[oldName]
            data.profiles[oldName] = nil
        elseif type(data.profiles[profileName]) ~= "table" then
            for name, pdata in pairs(data.profiles) do
                data.profiles[profileName] = pdata
                if name ~= profileName then
                    data.profiles[name] = nil
                end
                oldName = name
                break
            end
        end

        if type(data.specProfiles) == "table" then
            for specID, assigned in pairs(data.specProfiles) do
                if assigned == oldName then
                    data.specProfiles[specID] = profileName
                end
            end
        end

        if data.colorsPullFrom == oldName then
            data.colorsPullFrom = profileName
        end

        if type(data.syncedModules) == "table" then
            for _, targets in pairs(data.syncedModules) do
                if type(targets) == "table" and targets[oldName] ~= nil then
                    targets[profileName] = targets[oldName]
                    targets[oldName] = nil
                end
            end
        end
    end

    data.activeProfile = profileName
    data.profileOrder = { profileName }
    payload.profileName = profileName
    return true
end

-- Ellesmere exports the full override store. If a spec was removed from a group
-- (or only sits in a conflicting group), leftover per-spec values become
-- "stranded": they still apply but cannot be edited. Scrub those on import so
-- installs do not ship with stuck power-bar / layout overrides.
local function EllesmereSpecInGroup(group, specID)
    for _, sid in ipairs(group.specs or {}) do
        if sid == specID then return true end
    end
    return false
end

local function EllesmereGroupsConflict(a, b)
    for _, sid in ipairs(a.specs or {}) do
        for _, osid in ipairs(b.specs or {}) do
            if sid == osid then return true end
        end
    end
    return false
end

local function EllesmereOverrideValueIsStranded(entry, specID, groups)
    if type(entry) ~= "table" or entry.group == nil or type(groups) ~= "table" then
        return false
    end

    local owner
    for _, group in ipairs(groups) do
        if group.id == entry.group then
            owner = group
            break
        end
    end
    if not owner then return false end
    if EllesmereSpecInGroup(owner, specID) then return false end

    local inAnyGroup = false
    for _, group in ipairs(groups) do
        if EllesmereSpecInGroup(group, specID) then
            inAnyGroup = true
            if not EllesmereGroupsConflict(owner, group) then
                return false
            end
        end
    end
    return inAnyGroup
end

local function ScrubEllesmereStrandedOverridesInProfile(profile)
    if type(profile) ~= "table" then return end
    local groups = profile.specOverrideGroups
    local store = profile.specOverrides
    if type(groups) ~= "table" or type(store) ~= "table" then return end

    for _, entry in ipairs(store) do
        if type(entry) == "table" and type(entry.values) == "table" then
            local remove = {}
            for specID in pairs(entry.values) do
                if type(specID) == "number"
                    and EllesmereOverrideValueIsStranded(entry, specID, groups)
                then
                    remove[#remove + 1] = specID
                end
            end
            for _, specID in ipairs(remove) do
                entry.values[specID] = nil
            end
        end
    end
end

local function ScrubEllesmereStrandedOverridesInPayload(payload)
    local data = payload and payload.data
    if type(data) ~= "table" then return end

    -- Normal profile export: overrides live on the profile data root.
    ScrubEllesmereStrandedOverridesInProfile(data)

    -- Full-account export: overrides live inside each carried profile.
    if type(data.profiles) == "table" then
        for _, profile in pairs(data.profiles) do
            ScrubEllesmereStrandedOverridesInProfile(profile)
        end
    end
end

local function GetEllesmereUIImportString(aspect)
    local profiles = InariProfiles
    if type(profiles) ~= "table" then return nil end
    aspect = aspect or (ns.GetLayoutAspect and ns.GetLayoutAspect()) or "16"
    if aspect == "21" then
        return profiles.ellesmereui21 or profiles.ellesmereui
    end
    return profiles.ellesmereui16 or profiles.ellesmereui
end

local function ImportEllesmereUIProfile(aspect, opts)
    opts = opts or {}
    local activate = opts.activate ~= false
    aspect = aspect or (ns.GetLayoutAspect and ns.GetLayoutAspect()) or "16"
    local importString = GetEllesmereUIImportString(aspect)
    local profileName = GetEllesmereLayoutProfileName(aspect)
    local label = ns.GetLayoutAspectLabel and ns.GetLayoutAspectLabel(aspect) or aspect
    if type(importString) ~= "string" or importString == "" then
        return false, "missing EllesmereUI " .. label .. " profile string"
    end

    TryLoadAddon("EllesmereUI")

    if not EllesmereUI then
        return false, "EllesmereUI import API is not available"
    end

    local function FinishImport(status)
        if not activate then
            return true, "EllesmereUI " .. label .. " profile stored as " .. profileName
        end
        MarkImportedProfileVersion("ellesmereui")
        local activated, activateErr = ActivateEllesmereLayoutProfile(profileName)
        if not activated then
            return false, tostring(activateErr or "EllesmereUI profile was imported but not activated")
        end
        return true, "EllesmereUI " .. label .. " profile imported as " .. profileName
    end

    if type(EllesmereUI.DecodeImportString) == "function" then
        local payload, decodeErr = EllesmereUI.DecodeImportString(importString)
        if not payload then
            return false, tostring(decodeErr or "EllesmereUI decode failed")
        end

        ScrubEllesmereStrandedOverridesInPayload(payload)
        if payload.data then
            payload.data.assignedSpecs = nil
        end

        if type(EllesmereUI.IsFullAccountPayload) == "function"
            and EllesmereUI.IsFullAccountPayload(payload)
        then
            if type(EllesmereUI.ImportFullAccountData) ~= "function" then
                return false, "EllesmereUI full-account import API is not available"
            end

            local remapOk, remapErr = RemapEllesmereFullAccountProfileToInari(payload, profileName)
            if not remapOk then
                return false, tostring(remapErr)
            end

            ScrubEllesmereStrandedOverridesInPayload(payload)
            if activate then
                MarkImportedProfileVersion("ellesmereui")
            end

            local realReloadUI = _G.ReloadUI
            _G.ReloadUI = function() end
            local ok, success = pcall(EllesmereUI.ImportFullAccountData, payload)
            _G.ReloadUI = realReloadUI

            if not ok then
                return false, tostring(success)
            end
            if not success then
                return false, "EllesmereUI full-account import failed"
            end

            if not activate then
                return true, "EllesmereUI " .. label .. " full-account profile stored as " .. profileName
            end

            local activated, activateErr = ActivateEllesmereLayoutProfile(profileName)
            if not activated then
                return false, tostring(activateErr or "EllesmereUI full-account profile was imported but not activated")
            end
            return true, "EllesmereUI " .. label .. " full-account profile imported as " .. profileName
        end

        if type(EllesmereUI.ImportProfile) ~= "function" then
            return false, "EllesmereUI import API is not available"
        end

        SwitchAwayFromOtherInariEllesmereProfile(profileName)

        if EllesmereProfileExists and EllesmereProfileExists(profileName)
            and GetActiveEllesmereProfile and GetActiveEllesmereProfile() ~= profileName
            and type(EllesmereUI.DeleteProfile) == "function"
        then
            pcall(EllesmereUI.DeleteProfile, profileName)
        end

        local ok, success, err, status = pcall(EllesmereUI.ImportProfile, payload, profileName)
        if not ok then
            return false, tostring(success)
        end
        if not success then
            return false, tostring(err or "EllesmereUI import failed")
        end

        return FinishImport(status)
    end

    if type(EllesmereUI.ImportProfile) ~= "function" then
        return false, "EllesmereUI import API is not available"
    end

    SwitchAwayFromOtherInariEllesmereProfile(profileName)

    local ok, success, err, status = pcall(EllesmereUI.ImportProfile, importString, profileName)
    if not ok then
        return false, tostring(success)
    end
    if not success then
        return false, tostring(err or "EllesmereUI import failed")
    end

    return FinishImport(status)
end

local function ImportBothEllesmereUIProfiles(activateAspect)
    activateAspect = activateAspect or (ns.GetLayoutAspect and ns.GetLayoutAspect()) or "16"
    if ns.SetLayoutAspect then
        ns.SetLayoutAspect(activateAspect)
        activateAspect = ns.GetLayoutAspect() or activateAspect
    end
    local otherAspect = activateAspect == "21" and "16" or "21"
    local ok, message = ImportEllesmereUIProfile(otherAspect, { activate = false })
    if not ok then
        return false, message
    end
    ok, message = ImportEllesmereUIProfile(activateAspect)
    if not ok then
        return false, message
    end
    return true, "EllesmereUI profiles imported as inari16:9 and inari21:9"
end

local function ImportBigWigsProfile(callback)
    local importString = InariProfiles and InariProfiles.bigwigs
    if type(importString) ~= "string" or importString == "" then
        return false, "missing BigWigs profile string"
    end

    TryLoadAddon("BigWigs")

    if not BigWigsAPI or type(BigWigsAPI.RegisterProfile) ~= "function" then
        return false, "BigWigs import API is not available"
    end

    local wrappedCallback = function(accepted)
        if accepted then
            MarkImportedProfileVersion("bigwigs")
            local bossString = InariProfiles and InariProfiles.bigwigsbosses
            if type(bossString) == "string" and bossString ~= "" and type(BigWigsAPI.ImportBossOptions) == "function" then
                pcall(BigWigsAPI.ImportBossOptions, "inari", bossString)
            end
        end
        if callback then
            callback(accepted)
        end
    end

    local ok, err = pcall(BigWigsAPI.RegisterProfile, "inari", importString, "inari", wrappedCallback)
    if not ok then
        return false, tostring(err)
    end

    return true, "BigWigs import confirmation opened"
end

local function ImportEditModeLayout()
    local importString = InariProfiles and InariProfiles.editmode
    if type(importString) ~= "string" or importString == "" then
        return false, "missing Edit Mode layout string"
    end
    if InCombatLockdown and InCombatLockdown() then
        return false, "Edit Mode layout cannot be imported in combat"
    end
    if not C_EditMode or type(C_EditMode.GetLayouts) ~= "function" or type(C_EditMode.ConvertStringToLayoutInfo) ~= "function" then
        return false, "Edit Mode import API is not available"
    end

    local okLayouts, layouts = pcall(C_EditMode.GetLayouts)
    if not okLayouts or type(layouts) ~= "table" or type(layouts.layouts) ~= "table" then
        return false, "Edit Mode layouts are not available"
    end

    for i = #layouts.layouts, 1, -1 do
        if layouts.layouts[i].layoutName == "inari" then
            tremove(layouts.layouts, i)
        end
    end

    if #layouts.layouts >= 5 then
        return false, "maximum Edit Mode layouts already reached"
    end

    local okInfo, info = pcall(C_EditMode.ConvertStringToLayoutInfo, importString)
    if not okInfo or type(info) ~= "table" then
        return false, "Edit Mode import string is invalid"
    end

    info.layoutName = "inari"
    info.layoutType = Enum and Enum.EditModeLayoutType and Enum.EditModeLayoutType.Account or info.layoutType

    tinsert(layouts.layouts, info)

    local okSave, saveErr = pcall(C_EditMode.SaveLayouts, layouts)
    if not okSave then
        return false, tostring(saveErr)
    end

    local presetCount = Enum and Enum.EditModePresetLayoutsMeta and Enum.EditModePresetLayoutsMeta.NumValues or 0
    local newIndex = presetCount + #layouts.layouts
    if type(C_EditMode.OnLayoutAdded) == "function" then
        pcall(C_EditMode.OnLayoutAdded, newIndex, true, true)
    end
    if type(C_EditMode.SetActiveLayout) == "function" then
        pcall(C_EditMode.SetActiveLayout, newIndex)
    end
    if type(C_EditMode.SetAccountSetting) == "function" then
        pcall(C_EditMode.SetAccountSetting, 22, 0)
        pcall(C_EditMode.SetAccountSetting, 0, 0)
    end

    MarkImportedProfileVersion("editmode")
    return true, "Edit Mode layout imported as inari"
end

local function ImportBlinkiisPortraitsProfile()
    local importString = InariProfiles and InariProfiles.blinkiiportraits
    if type(importString) ~= "string" or importString == "" then
        return false, "missing Blinkii's Portraits profile string"
    end

    TryLoadAddon("Blinkiis_Portraits")

    if not LibStub then return false, "LibStub is not available" end
    local LibSerialize = LibStub("LibSerialize", true)
    local LibDeflate = LibStub("LibDeflate", true)
    if not LibSerialize or not LibDeflate then
        return false, "Blinkii's Portraits import libraries are not available"
    end
    if not BLINKIISPORTRAITS or not BLINKIISPORTRAITS.db then
        return false, "Blinkii's Portraits profile database is not available"
    end
    if not importString:match("^!BP") then
        return false, "Blinkii's Portraits import string is invalid"
    end

    local encoded = importString:gsub("^!BP", "")
    local decoded = LibDeflate:DecodeForPrint(encoded)
    if not decoded then return false, "Blinkii's Portraits import string could not be decoded" end

    local decompressed = LibDeflate:DecompressDeflate(decoded)
    if not decompressed then return false, "Blinkii's Portraits import string could not be decompressed" end

    local ok, importDB = LibSerialize:Deserialize(decompressed)
    if not ok or type(importDB) ~= "table" or type(importDB.profile) ~= "table" then
        return false, "Blinkii's Portraits import string is corrupted"
    end

    BLINKIISPORTRAITS.db.profiles = BLINKIISPORTRAITS.db.profiles or {}
    local profile = CopyPlainTable(BLINKIISPORTRAITS.defaults and BLINKIISPORTRAITS.defaults.profile or {})
    CopyPlainTable(importDB.profile, profile)
    BLINKIISPORTRAITS.db.profiles.inari = profile

    local setOk, setErr = pcall(BLINKIISPORTRAITS.db.SetProfile, BLINKIISPORTRAITS.db, "inari")
    if not setOk then return false, tostring(setErr) end

    if type(BLINKIISPORTRAITS.LoadPortraits) == "function" then
        pcall(BLINKIISPORTRAITS.LoadPortraits, BLINKIISPORTRAITS)
    end

    MarkImportedProfileVersion("blinkiiportraits")
    return true, "Blinkii's Portraits profile imported as inari"
end

local function ImportEXBossProfile()
    local importString = InariProfiles and InariProfiles.exboss
    if type(importString) ~= "string" or importString == "" then
        return false, "missing EXBoss profile string"
    end

    TryLoadAddon("EXBoss")

    -- Current EXBoss ships EXBXC v7 bundles through EXBossWagoAPI. The older
    -- DecodePayload / GetImportSummary / Import helpers are gone.
    local api = _G.EXBossWagoAPI
    if type(api) ~= "table" or type(api.ImportProfile) ~= "function" then
        return false, "EXBoss import API is not available"
    end

    if InCombatLockdown and InCombatLockdown() then
        return false, "cannot import EXBoss in combat"
    end

    local ok, imported, result = pcall(api.ImportProfile, api, importString)
    if not ok then
        return false, tostring(imported)
    end
    if not imported then
        return false, tostring(result or "EXBoss import failed")
    end

    MarkImportedProfileVersion("exboss")
    if type(result) == "table" and result.reloadRequired == true then
        return true, "EXBoss profile imported as inari (reload to finish)"
    end
    return true, "EXBoss profile imported as inari"
end

local function ImportSArenaProfile()
    local importString = InariProfiles and InariProfiles.sarena
    if type(importString) ~= "string" or importString == "" then
        return false, "missing sArena profile string"
    end

    TryLoadAddon("sArena_Reloaded")

    if not sArena or type(sArena.ImportProfile) ~= "function" then
        return false, "sArena Reloaded import API is not available"
    end

    -- externalSource=true skips sArena's forced ReloadUI so the installer can continue.
    local success, err = sArena:ImportProfile(importString, "inari", true)
    if not success then
        return false, tostring(err or "sArena import failed")
    end

    if sArena.db and type(sArena.db.SetProfile) == "function" then
        pcall(sArena.db.SetProfile, sArena.db, "inari")
    elseif type(sArena_ReloadedDB) == "table" then
        sArena_ReloadedDB.profiles = sArena_ReloadedDB.profiles or {}
        sArena_ReloadedDB.profileKeys = sArena_ReloadedDB.profileKeys or {}
        sArena_ReloadedDB.profileKeys[GetInariCharacterKey()] = "inari"
    end

    if type(sArena.RefreshConfig) == "function" then
        pcall(sArena.RefreshConfig, sArena)
    end

    MarkImportedProfileVersion("sarena")
    return true, "sArena profile imported as inari"
end

local function ImportBaganatorProfile()
    local importString = InariProfiles and InariProfiles.baganator
    if type(importString) ~= "string" or importString == "" then
        return false, "missing Baganator profile string"
    end

    TryLoadAddon("Baganator")

    if not Baganator or not Baganator.API or type(Baganator.API.ImportString) ~= "function" then
        return false, "Baganator import API is not available"
    end

    local ok, err = pcall(Baganator.API.ImportString, importString, "inari")
    if not ok then
        return false, tostring(err or "Baganator import failed")
    end

    MarkImportedProfileVersion("baganator")
    return true, "Baganator profile imported as inari"
end

GetBundledProfileVersion = function(key)
    local versions = InariProfiles and InariProfiles.versions
    local version = versions and versions[key]
    if type(version) == "number" then return version end
    return 1
end

MarkImportedProfileVersion = function(key)
    if type(key) ~= "string" or key == "" then return end
    EnsureDB()
    InariDB.importedProfileVersions[key] = GetBundledProfileVersion(key)
    InariDB.profileUpdateDismissed[key] = nil
end

local function FindEditModeLayoutIndex(layoutName)
    if not C_EditMode or type(C_EditMode.GetLayouts) ~= "function" then return nil end

    local ok, layouts = pcall(C_EditMode.GetLayouts)
    if not ok or type(layouts) ~= "table" or type(layouts.layouts) ~= "table" then return nil end

    local presetCount = Enum and Enum.EditModePresetLayoutsMeta and Enum.EditModePresetLayoutsMeta.NumValues or 0
    for i, layout in ipairs(layouts.layouts) do
        if layout.layoutName == layoutName then
            return presetCount + i
        end
    end

    return nil
end

local function BigWigsProfileExists(profileName)
    if type(BigWigs3DB) == "table" and type(BigWigs3DB.profiles) == "table" and type(BigWigs3DB.profiles[profileName]) == "table" then
        return true
    end

    local db = BigWigsLoader and BigWigsLoader.db
    if db and type(db.GetProfiles) == "function" then
        local ok, profiles = pcall(db.GetProfiles, db, {})
        if ok and type(profiles) == "table" then
            for _, name in ipairs(profiles) do
                if name == profileName then return true end
            end
        end
    end

    return false
end

local function BlinkiisPortraitsProfileExists(profileName)
    if type(BlinkiisPortraitsDB) == "table"
        and type(BlinkiisPortraitsDB.profiles) == "table"
        and type(BlinkiisPortraitsDB.profiles[profileName]) == "table" then
        return true
    end

    local db = BLINKIISPORTRAITS and BLINKIISPORTRAITS.db
    return db and type(db.profiles) == "table" and type(db.profiles[profileName]) == "table"
end

local function EXBossProfileExists(profileName)
    local wanted = tostring(profileName or ""):lower()
    if wanted == "" then return false end

    local db = type(EXBossDataDB) == "table" and type(EXBossDataDB.bossConfig) == "table" and EXBossDataDB.bossConfig or nil
    local userOverrides = db and type(db.userOverrides) == "table" and db.userOverrides or nil
    if not userOverrides then return false end

    for _, slotKey in ipairs(EXBOSS_IMPORT_SLOT_KEYS) do
        local slotRoot = type(userOverrides[slotKey]) == "table" and userOverrides[slotKey] or nil
        if slotRoot then
            for authorKey, authorRow in pairs(slotRoot) do
                local key = tostring(authorKey or "")
                if key:lower():sub(1, #wanted) == wanted and type(authorRow) == "table" then
                    return true
                end
            end
        end
    end

    return false
end

EllesmereProfileExists = function(profileName)
    return type(EllesmereUIDB) == "table"
        and type(EllesmereUIDB.profiles) == "table"
        and type(EllesmereUIDB.profiles[profileName]) == "table"
end

local function SArenaProfileExists(profileName)
    if type(sArena_ReloadedDB) == "table"
        and type(sArena_ReloadedDB.profiles) == "table"
        and type(sArena_ReloadedDB.profiles[profileName]) == "table" then
        return true
    end

    local db = sArena and sArena.db
    return db and type(db.profiles) == "table" and type(db.profiles[profileName]) == "table"
end

local function BaganatorProfileExists(profileName)
    return type(BAGANATOR_CONFIG) == "table"
        and type(BAGANATOR_CONFIG.Profiles) == "table"
        and type(BAGANATOR_CONFIG.Profiles[profileName]) == "table"
end

GetActiveEllesmereProfile = function()
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

local function GetCurrentEllesmereSpecProfile()
    if type(EllesmereUIDB) ~= "table" then return nil end

    local characterKey = GetInariCharacterKey()
    local specID = type(EllesmereUIDB.lastSpecByChar) == "table"
        and EllesmereUIDB.lastSpecByChar[characterKey]
        or nil

    if not specID and GetSpecialization and GetSpecializationInfo then
        local specIndex = GetSpecialization()
        if specIndex and specIndex > 0 then
            specID = GetSpecializationInfo(specIndex)
        end
    end

    if not specID then return nil end

    if EllesmereUI and type(EllesmereUI.GetSpecProfile) == "function" then
        local ok, profileName = pcall(EllesmereUI.GetSpecProfile, specID)
        if ok and type(profileName) == "string" and profileName ~= "" then
            return profileName
        end
    end

    local specProfiles = EllesmereUIDB.specProfiles
    local profileName = type(specProfiles) == "table" and specProfiles[specID] or nil
    if type(profileName) == "string" and profileName ~= "" then
        return profileName
    end

    return nil
end

local function ResolveInstalledEllesmereProfile()
    local wanted = GetEllesmereLayoutProfileName()
    if EllesmereProfileExists(wanted) then return wanted end
    if EllesmereProfileExists("inari16:9") then return "inari16:9" end
    if EllesmereProfileExists("inari21:9") then return "inari21:9" end
    if EllesmereProfileExists("inari") then return "inari" end
    return nil
end

ActivateEllesmereLayoutProfile = function(profileName)
    profileName = profileName or GetEllesmereLayoutProfileName()
    if not EllesmereProfileExists(profileName) then
        return false, "EllesmereUI profile " .. tostring(profileName) .. " was not found"
    end

    if type(EllesmereUIDB) == "table" then
        local specProfiles = EllesmereUIDB.specProfiles
        if type(specProfiles) == "table" then
            for specID, assigned in pairs(specProfiles) do
                if IsInariEllesmereProfile(assigned) then
                    specProfiles[specID] = profileName
                end
            end
        end

        local specID
        if GetSpecialization and GetSpecializationInfo then
            local specIndex = GetSpecialization()
            if specIndex and specIndex > 0 then
                specID = GetSpecializationInfo(specIndex)
            end
        end
        if specID then
            EllesmereUIDB.specProfiles = EllesmereUIDB.specProfiles or {}
            local assigned = EllesmereUIDB.specProfiles[specID]
            if not assigned or IsInariEllesmereProfile(assigned) then
                if EllesmereUI and type(EllesmereUI.AssignProfileToSpec) == "function" then
                    pcall(EllesmereUI.AssignProfileToSpec, profileName, specID)
                else
                    EllesmereUIDB.specProfiles[specID] = profileName
                end
            end
        end
    end

    if GetActiveEllesmereProfile() == profileName then
        return true, "EllesmereUI already on " .. profileName
    end

    if EllesmereUI and type(EllesmereUI.SwitchProfile) == "function" then
        local ok, err = pcall(EllesmereUI.SwitchProfile, profileName)
        if not ok then
            return false, tostring(err)
        end
    elseif type(EllesmereUIDB) == "table" then
        EllesmereUIDB.activeProfile = profileName
    end

    if EllesmereUI and type(EllesmereUI.RefreshAllAddons) == "function" then
        pcall(EllesmereUI.RefreshAllAddons)
    end

    return true, "EllesmereUI switched to " .. profileName
end

local function HasInstalledInariProfiles()
    TryLoadAddon("EllesmereUI")
    TryLoadAddon("BigWigs")
    TryLoadAddon("EXBoss")
    TryLoadAddon("sArena_Reloaded")
    TryLoadAddon("Baganator")

    return ResolveInstalledEllesmereProfile() ~= nil
        or BigWigsProfileExists("inari")
        or EXBossProfileExists("inari")
        or SArenaProfileExists("inari")
        or BaganatorProfileExists("inari")
        or FindEditModeLayoutIndex("inari") ~= nil
end

local function ApplyExistingEllesmereProfile(applied, missing, failed)
    TryLoadAddon("EllesmereUI")

    local profileName = ResolveInstalledEllesmereProfile()
    if not profileName then
        missing[#missing + 1] = "EllesmereUI"
        return
    end

    local ok, message = ActivateEllesmereLayoutProfile(profileName)
    if not ok then
        failed[#failed + 1] = "EllesmereUI: " .. tostring(message)
        return
    end

    applied[#applied + 1] = "EllesmereUI (" .. profileName .. ")"
end

local function ApplyExistingBigWigsProfile(applied, missing, failed)
    TryLoadAddon("BigWigs")

    if not BigWigsProfileExists("inari") then
        missing[#missing + 1] = "BigWigs"
        return
    end

    local db = BigWigsLoader and BigWigsLoader.db
    if db and type(db.SetProfile) == "function" then
        local ok, err = pcall(db.SetProfile, db, "inari")
        if not ok then
            failed[#failed + 1] = "BigWigs: " .. tostring(err)
            return
        end
    elseif type(BigWigs3DB) == "table" then
        BigWigs3DB.profileKeys = BigWigs3DB.profileKeys or {}
        BigWigs3DB.profileKeys[GetInariCharacterKey()] = "inari"
    end

    applied[#applied + 1] = "BigWigs"
end

local function ApplyExistingBlinkiisPortraitsProfile(applied, missing, failed)
    TryLoadAddon("Blinkiis_Portraits")

    if not BlinkiisPortraitsProfileExists("inari") then
        missing[#missing + 1] = "Blinkii's Portraits"
        return
    end

    local db = BLINKIISPORTRAITS and BLINKIISPORTRAITS.db
    if db and type(db.SetProfile) == "function" then
        local ok, err = pcall(db.SetProfile, db, "inari")
        if not ok then
            failed[#failed + 1] = "Blinkii's Portraits: " .. tostring(err)
            return
        end
    elseif type(BlinkiisPortraitsDB) == "table" then
        BlinkiisPortraitsDB.profileKeys = BlinkiisPortraitsDB.profileKeys or {}
        BlinkiisPortraitsDB.profileKeys[GetInariCharacterKey()] = "inari"
    end

    if BLINKIISPORTRAITS and type(BLINKIISPORTRAITS.LoadPortraits) == "function" then
        pcall(BLINKIISPORTRAITS.LoadPortraits, BLINKIISPORTRAITS)
    end

    applied[#applied + 1] = "Blinkii's Portraits"
end

local function FindEXBossInariAuthor(slotKey)
    local db = type(EXBossDataDB) == "table" and type(EXBossDataDB.bossConfig) == "table" and EXBossDataDB.bossConfig or nil
    local slotRoot = db and type(db.userOverrides) == "table" and type(db.userOverrides[slotKey]) == "table" and db.userOverrides[slotKey] or nil
    if not slotRoot then return nil end

    local selected = db.slotSelection and db.slotSelection[slotKey]
    if type(selected) == "string" and selected:lower():sub(1, 5) == "inari" and type(slotRoot[selected]) == "table" then
        return selected
    end

    local suffix = EXBOSS_IMPORT_AUTHOR_SUFFIXES[slotKey]
    local expected = suffix and ("inari-" .. suffix):lower() or nil
    if expected then
        for authorKey, authorRow in pairs(slotRoot) do
            local key = tostring(authorKey or "")
            if key:lower() == expected and type(authorRow) == "table" then
                return key
            end
        end
    end

    for authorKey, authorRow in pairs(slotRoot) do
        local key = tostring(authorKey or "")
        if key:lower():sub(1, 5) == "inari" and type(authorRow) == "table" then
            return key
        end
    end

    return nil
end

local function ApplyExistingEXBossProfile(applied, missing, failed)
    TryLoadAddon("EXBoss")

    if not EXBossProfileExists("inari") then
        missing[#missing + 1] = "EXBoss"
        return
    end

    local bossConfig = ExBoss and (ExBoss.BossConfig or (ExBoss.Modules and ExBoss.Modules.Boss))
    local db = type(EXBossDataDB) == "table" and type(EXBossDataDB.bossConfig) == "table" and EXBossDataDB.bossConfig or nil
    if not bossConfig and not db then
        failed[#failed + 1] = "EXBoss: profile database is not available"
        return
    end

    local appliedAny = false
    for _, slotKey in ipairs(EXBOSS_IMPORT_SLOT_KEYS) do
        local authorKey = FindEXBossInariAuthor(slotKey)
        if authorKey then
            if bossConfig and type(bossConfig.SetSelectedAuthor) == "function" then
                local ok, err = pcall(bossConfig.SetSelectedAuthor, bossConfig, slotKey, authorKey)
                if not ok then
                    failed[#failed + 1] = "EXBoss: " .. tostring(err)
                    return
                end
            elseif db then
                db.slotSelection = db.slotSelection or {}
                db.slotSelection[slotKey] = authorKey
            end
            appliedAny = true
        end
    end

    if not appliedAny then
        missing[#missing + 1] = "EXBoss"
        return
    end

    if bossConfig and type(bossConfig.PublishRuntimeSelection) == "function" then
        pcall(bossConfig.PublishRuntimeSelection, bossConfig)
    end

    applied[#applied + 1] = "EXBoss"
end

local function ApplyExistingEditModeLayout(applied, missing, failed)
    if InCombatLockdown and InCombatLockdown() then
        failed[#failed + 1] = "Edit Mode: cannot apply in combat"
        return
    end

    local index = FindEditModeLayoutIndex("inari")
    if not index then
        missing[#missing + 1] = "Edit Mode"
        return
    end

    if C_EditMode and type(C_EditMode.SetActiveLayout) == "function" then
        local ok, err = pcall(C_EditMode.SetActiveLayout, index)
        if not ok then
            failed[#failed + 1] = "Edit Mode: " .. tostring(err)
            return
        end
    end

    if C_EditMode and type(C_EditMode.SetAccountSetting) == "function" then
        pcall(C_EditMode.SetAccountSetting, 22, 0)
        pcall(C_EditMode.SetAccountSetting, 0, 0)
    end

    applied[#applied + 1] = "Edit Mode"
end

local function ApplyExistingSArenaProfile(applied, missing, failed)
    TryLoadAddon("sArena_Reloaded")

    if not SArenaProfileExists("inari") then
        missing[#missing + 1] = "sArena"
        return
    end

    local db = sArena and sArena.db
    if db and type(db.SetProfile) == "function" then
        local ok, err = pcall(db.SetProfile, db, "inari")
        if not ok then
            failed[#failed + 1] = "sArena: " .. tostring(err)
            return
        end
    elseif type(sArena_ReloadedDB) == "table" then
        sArena_ReloadedDB.profileKeys = sArena_ReloadedDB.profileKeys or {}
        sArena_ReloadedDB.profileKeys[GetInariCharacterKey()] = "inari"
    else
        failed[#failed + 1] = "sArena: profile database is not available"
        return
    end

    if sArena and type(sArena.RefreshConfig) == "function" then
        pcall(sArena.RefreshConfig, sArena)
    end

    applied[#applied + 1] = "sArena"
end

local function ApplyExistingBaganatorProfile(applied, missing, failed)
    TryLoadAddon("Baganator")

    if not BaganatorProfileExists("inari") then
        missing[#missing + 1] = "Baganator"
        return
    end

    if BAGANATOR_CURRENT_PROFILE == "inari" then
        applied[#applied + 1] = "Baganator (already active)"
        return
    end

    -- ImportString with overwrite activates the named profile via Baganator's ChangeProfile.
    local ok, message = ImportBaganatorProfile()
    if not ok then
        failed[#failed + 1] = "Baganator: " .. tostring(message)
        return
    end

    applied[#applied + 1] = "Baganator"
end

local function ApplyInstalledProfilesToCharacter(markApplied)
    EnsureDB()

    local applied = {}
    local missing = {}
    local failed = {}

    ApplyExistingEllesmereProfile(applied, missing, failed)
    ApplyExistingBigWigsProfile(applied, missing, failed)
    ApplyExistingEXBossProfile(applied, missing, failed)
    ApplyExistingSArenaProfile(applied, missing, failed)
    ApplyExistingBaganatorProfile(applied, missing, failed)
    ApplyExistingEditModeLayout(applied, missing, failed)

    if #applied > 0 and #failed == 0 and markApplied then
        if ns.MarkProfilePromptApplied then
            ns.MarkProfilePromptApplied()
        end
    end

    local message
    if #applied > 0 then
        message = "inari profiles ready for this character: " .. table.concat(applied, ", ")
    else
        message = "no installed inari profiles were found for this character"
    end
    if #missing > 0 then
        message = message .. " (missing: " .. table.concat(missing, ", ") .. ")"
    end
    if #failed > 0 then
        message = message .. " (failed: " .. table.concat(failed, "; ") .. ")"
    end

    return #applied > 0 and #failed == 0, message
end

local function ShouldOfferInstalledProfiles()
    EnsureDB()
    if InariDB.profilePromptEnabled == false then return false end
    if InariDB.installerCompletedVersion ~= CONST.profilePromptVersion then return false end

    local key = GetInariCharacterKey()
    if InariDB.profilePromptApplied[key] == CONST.profilePromptVersion then return false end
    if InariDB.profilePromptDismissed[key] == CONST.profilePromptVersion then return false end

    return HasInstalledInariProfiles()
end

local function GetManagedProfileDefs()
    return {
        {
            key = "bigwigs",
            label = "BigWigs",
            exists = function()
                TryLoadAddon("BigWigs")
                return BigWigsProfileExists("inari")
            end,
            import = ImportBigWigsProfile,
            async = true,
        },
        {
            key = "exboss",
            label = "EXBoss",
            exists = function()
                TryLoadAddon("EXBoss")
                return EXBossProfileExists("inari")
            end,
            import = ImportEXBossProfile,
        },
        {
            key = "editmode",
            label = "Edit Mode",
            exists = function()
                return FindEditModeLayoutIndex("inari") ~= nil
            end,
            import = ImportEditModeLayout,
        },
        {
            key = "ellesmereui",
            label = "EllesmereUI",
            exists = function()
                TryLoadAddon("EllesmereUI")
                return ResolveInstalledEllesmereProfile() ~= nil
            end,
            import = ImportBothEllesmereUIProfiles,
        },
        {
            key = "sarena",
            label = "sArena",
            exists = function()
                TryLoadAddon("sArena_Reloaded")
                return SArenaProfileExists("inari")
            end,
            import = ImportSArenaProfile,
        },
        {
            key = "baganator",
            label = "Baganator",
            exists = function()
                TryLoadAddon("Baganator")
                return BaganatorProfileExists("inari")
            end,
            import = ImportBaganatorProfile,
        },
        {
            key = "cdm",
            label = "Cooldown Manager",
            exists = function()
                return HasInariCooldownLayouts()
            end,
            import = function()
                return ImportInariCooldownLayouts()
            end,
        },
    }
end

local function SeedInstalledProfileVersions()
    EnsureDB()
    if InariDB.profileVersionsSeeded then return end

    for _, def in ipairs(GetManagedProfileDefs()) do
        if def.exists() and InariDB.importedProfileVersions[def.key] == nil then
            InariDB.importedProfileVersions[def.key] = GetBundledProfileVersion(def.key)
        end
    end

    InariDB.profileVersionsSeeded = true
end

local function GetOutdatedInstalledProfiles()
    EnsureDB()
    SeedInstalledProfileVersions()

    local outdated = {}
    for _, def in ipairs(GetManagedProfileDefs()) do
        if def.exists() then
            local bundled = GetBundledProfileVersion(def.key)
            local imported = InariDB.importedProfileVersions[def.key]
            if type(imported) ~= "number" then imported = 0 end
            if imported < bundled then
                outdated[#outdated + 1] = def
            end
        end
    end
    return outdated
end

local function FormatProfileLabelList(defs)
    local labels = {}
    for _, def in ipairs(defs or {}) do
        labels[#labels + 1] = def.label
    end
    if #labels == 0 then return "" end
    if #labels == 1 then return labels[1] end
    if #labels == 2 then return labels[1] .. " and " .. labels[2] end
    return table.concat(labels, ", ", 1, #labels - 1) .. ", and " .. labels[#labels]
end

local function ReimportOutdatedProfiles(outdated, onDone)
    local applied = {}
    local failed = {}
    local pendingAsync

    for _, def in ipairs(outdated or {}) do
        if def.async then
            pendingAsync = def
        else
            local ok, message = def.import()
            if ok then
                applied[#applied + 1] = def.label
            else
                failed[#failed + 1] = def.label .. ": " .. tostring(message)
            end
        end
    end

    local function Finish(extraApplied, extraFailed)
        for _, label in ipairs(extraApplied or {}) do
            applied[#applied + 1] = label
        end
        for _, entry in ipairs(extraFailed or {}) do
            failed[#failed + 1] = entry
        end

        local message
        if #applied > 0 then
            message = "reimported updated profiles: " .. table.concat(applied, ", ")
        else
            message = "no updated profiles were reimported"
        end
        if #failed > 0 then
            message = message .. " (failed: " .. table.concat(failed, "; ") .. ")"
        end

        if onDone then
            onDone(#applied > 0 and #failed == 0, message, #applied > 0)
        end
    end

    if not pendingAsync then
        Finish()
        return
    end

    local ok, message = pendingAsync.import(function(accepted)
        if accepted then
            Finish({ pendingAsync.label })
        else
            Finish(nil, { pendingAsync.label .. ": cancelled" })
        end
    end)
    if not ok then
        Finish(nil, { pendingAsync.label .. ": " .. tostring(message) })
    end
end

local function ShouldOfferProfileUpdates()
    EnsureDB()
    if InariDB.profileUpdateEnabled == false then return false end
    if InariDB.installerCompletedVersion ~= CONST.profilePromptVersion then return false end
    if State.profileUpdatePromptDismissedThisSession then return false end
    return #GetOutdatedInstalledProfiles() > 0
end

local function ScheduleInstalledProfilesOffer()
    if State.profileOfferScheduled then return end
    State.profileOfferScheduled = true
    C_Timer.After(4, function()
        State.profileOfferScheduled = false
        if ShouldOfferProfileUpdates() then
            ns.ShowProfileUpdatePrompt()
            return
        end
        ns.ShowInstalledProfilesPrompt()
    end)
end

local function GetClassKey()
    local _, classToken = UnitClass("player")
    return classToken and string.lower(classToken)
end

local function GetClassDisplayName()
    local _, classToken = UnitClass("player")
    return (classToken and LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[classToken]) or classToken or "Class"
end

local function GetSpecNames()
    local specs = {}
    local count = GetNumSpecializations and GetNumSpecializations() or 0
    for index = 1, count do
        local _, specName = GetSpecializationInfo(index)
        if specName then specs[#specs + 1] = specName end
    end
    return specs
end

local function GetCurrentSpecName()
    local index = GetSpecialization and GetSpecialization()
    if not index then return nil end
    local _, specName = GetSpecializationInfo(index)
    return specName
end

local function StartsWith(text, prefix)
    return type(text) == "string" and text:sub(1, #prefix) == prefix
end

local function GetInariCooldownData()
    local classKey = GetClassKey()
    local classData = classKey and InariCooldownLayouts and InariCooldownLayouts[classKey]
    if type(classData) ~= "string" then
        return nil, "no inari cooldown data found for " .. tostring(classKey or "current class")
    end

    return classData
end

local function GetCooldownLayoutManager()
    if C_CVar and C_CVar.GetCVar and C_CVar.GetCVar("cooldownViewerEnabled") == "0" then
        return nil, "Blizzard Cooldown Manager is disabled"
    end

    if not CooldownViewerSettings then
        if C_AddOns and C_AddOns.LoadAddOn then
            pcall(C_AddOns.LoadAddOn, "Blizzard_CooldownViewer")
        elseif LoadAddOn then
            pcall(LoadAddOn, "Blizzard_CooldownViewer")
        end
    end

    if not CooldownViewerSettings or type(CooldownViewerSettings.GetLayoutManager) ~= "function" then
        return nil, "Blizzard Cooldown Manager settings are not loaded"
    end

    local layoutManager = CooldownViewerSettings:GetLayoutManager()
    if not layoutManager or type(layoutManager.CreateLayoutsFromSerializedData) ~= "function" then
        return nil, "Blizzard Cooldown Manager layout manager was not available"
    end

    return layoutManager
end

local function SaveCooldownLayouts(layoutManager)
    if layoutManager and type(layoutManager.SaveLayouts) == "function" then
        pcall(layoutManager.SaveLayouts, layoutManager)
    end
end

local function RemoveInariCooldownLayouts(layoutManager)
    if not layoutManager or type(layoutManager.layouts) ~= "table" then return 0 end

    local prefix = "inari - " .. GetClassDisplayName()
    local removed = 0
    local kept = {}

    for _, layout in pairs(layoutManager.layouts) do
        if layout then
            local name = layout.layoutName or layout.name
            if StartsWith(name, prefix) then
                removed = removed + 1
            else
                kept[#kept + 1] = layout
            end
        end
    end

    if removed == 0 then return 0 end

    for key in pairs(layoutManager.layouts) do
        layoutManager.layouts[key] = nil
    end

    for index, layout in ipairs(kept) do
        layout.layoutID = index
        layoutManager.layouts[index] = layout
    end

    SaveCooldownLayouts(layoutManager)
    return removed
end

local function RenameInariCooldownLayouts(layoutManager, layoutIDs)
    local className = GetClassDisplayName()
    local specs = GetSpecNames()
    local activeSpec = GetCurrentSpecName()
    local activeLayoutID = layoutIDs and layoutIDs[1]

    for index, layoutID in ipairs(layoutIDs or {}) do
        local layout = layoutManager.layouts and layoutManager.layouts[layoutID]
        if layout then
            local oldName = layout.name or layout.layoutName or ""
            local specName

            for _, candidate in ipairs(specs) do
                if oldName:find(candidate, 1, true) then
                    specName = candidate
                    break
                end
            end

            specName = specName or specs[index] or tostring(index)
            local newName = "inari - " .. className .. " " .. specName
            layout.name = newName
            layout.layoutName = newName

            if activeSpec and specName == activeSpec then
                activeLayoutID = layoutID
            end
        end
    end

    return activeLayoutID
end

ImportInariCooldownLayouts = function()
    if InCombatLockdown and InCombatLockdown() then
        return false, "leave combat before importing cooldown layouts"
    end

    local classData, dataError = GetInariCooldownData()
    if not classData then return false, dataError end

    local layoutManager, managerError = GetCooldownLayoutManager()
    if not layoutManager then return false, managerError end

    local removed = RemoveInariCooldownLayouts(layoutManager)
    local ok, layoutIDs = pcall(layoutManager.CreateLayoutsFromSerializedData, layoutManager, classData)
    if not ok or type(layoutIDs) ~= "table" or #layoutIDs == 0 then
        return false, "Blizzard rejected the cooldown layout import"
    end

    local activeLayoutID = RenameInariCooldownLayouts(layoutManager, layoutIDs)
    if activeLayoutID and type(layoutManager.SetActiveLayoutByID) == "function" then
        pcall(layoutManager.SetActiveLayoutByID, layoutManager, activeLayoutID)
    end

    SaveCooldownLayouts(layoutManager)
    MarkImportedProfileVersion("cdm")
    return true, "imported " .. #layoutIDs .. " cooldown layouts, removed " .. removed .. " old inari layouts"
end

HasInariCooldownLayouts = function()
    local layoutManager = GetCooldownLayoutManager()
    if not layoutManager or type(layoutManager.layouts) ~= "table" then return false end
    local prefix = "inari - "
    for _, layout in pairs(layoutManager.layouts) do
        local name = layout and (layout.name or layout.layoutName)
        if type(name) == "string" and StartsWith(name, prefix) then
            return true
        end
    end
    return false
end

local function GetCooldownLayoutVersionInfo()
    EnsureDB()
    local bundled = GetBundledProfileVersion("cdm")
    local imported = InariDB.importedProfileVersions and InariDB.importedProfileVersions.cdm
    local hasLayouts = HasInariCooldownLayouts()
    if type(imported) ~= "number" then imported = nil end
    return {
        bundled = bundled,
        imported = imported,
        hasLayouts = hasLayouts,
        outdated = imported ~= nil and imported < bundled,
    }
end


ns.GetBundledProfileVersion = GetBundledProfileVersion
ns.MarkImportedProfileVersion = MarkImportedProfileVersion
ns.ImportEllesmereUIProfile = ImportEllesmereUIProfile
ns.ImportBothEllesmereUIProfiles = ImportBothEllesmereUIProfiles
ns.ActivateEllesmereLayoutProfile = ActivateEllesmereLayoutProfile
ns.GetEllesmereLayoutProfileName = GetEllesmereLayoutProfileName
ns.ImportBigWigsProfile = ImportBigWigsProfile
ns.ImportEditModeLayout = ImportEditModeLayout
ns.ImportBlinkiisPortraitsProfile = ImportBlinkiisPortraitsProfile
ns.ImportEXBossProfile = ImportEXBossProfile
ns.ImportSArenaProfile = ImportSArenaProfile
ns.ImportBaganatorProfile = ImportBaganatorProfile
ns.ImportInariCooldownLayouts = ImportInariCooldownLayouts
ns.GetCooldownLayoutVersionInfo = GetCooldownLayoutVersionInfo
ns.GetClassDisplayName = GetClassDisplayName
ns.HasInstalledInariProfiles = HasInstalledInariProfiles
ns.ApplyInstalledProfilesToCharacter = ApplyInstalledProfilesToCharacter
ns.ShouldOfferInstalledProfiles = ShouldOfferInstalledProfiles
ns.GetManagedProfileDefs = GetManagedProfileDefs
ns.GetOutdatedInstalledProfiles = GetOutdatedInstalledProfiles
ns.FormatProfileLabelList = FormatProfileLabelList
ns.ReimportOutdatedProfiles = ReimportOutdatedProfiles
ns.ShouldOfferProfileUpdates = ShouldOfferProfileUpdates
ns.ScheduleInstalledProfilesOffer = ScheduleInstalledProfilesOffer
