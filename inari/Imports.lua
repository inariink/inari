local ADDON_NAME, ns = ...
local TryLoadAddon = ns.TryLoadAddon
local EnsureDB = ns.EnsureDB
local CONST = ns.CONST
local State = ns.State
local EXBOSS_IMPORT_SLOT_KEYS = ns.EXBOSS_IMPORT_SLOT_KEYS
local EXBOSS_IMPORT_AUTHOR_SUFFIXES = ns.EXBOSS_IMPORT_AUTHOR_SUFFIXES
local GetInariCharacterKey = ns.GetInariCharacterKey
local GetBundledProfileVersion
local MarkImportedProfileVersion
local ActivateEllesmereLayoutProfile
local EllesmereProfileExists = ns.EllesmereProfileExists
local GetActiveEllesmereProfile = ns.GetActiveEllesmereProfile
local IsInariEllesmereProfile = ns.IsInariEllesmereProfile
local GetEllesmereLayoutProfileName = ns.GetEllesmereLayoutProfileName
local ImportInariCooldownLayouts
local HasInariCooldownLayouts

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

-- One slot per layout: the previous copy is overwritten on the next reimport.
local function BackupEllesmereProfile(profileName)
    if type(CopyTable) ~= "function" or not EllesmereProfileExists(profileName) then return end

    local backupName = profileName .. " backup"
    local copy = CopyTable(EllesmereUIDB.profiles[profileName])
    copy._importEstablishPending = nil
    EllesmereUIDB.profiles[backupName] = copy

    -- Cooldown Manager spells live outside the profile blob, keyed by profile name.
    local store = EllesmereUIDB.spellAssignments
    if type(store) == "table" and type(store.profiles) == "table" and type(store.profiles[profileName]) == "table" then
        store.profiles[backupName] = CopyTable(store.profiles[profileName])
    end

    local order = EllesmereUIDB.profileOrder
    if type(order) == "table" then
        for _, name in ipairs(order) do
            if name == backupName then return end
        end
        order[#order + 1] = backupName
    end
end

-- Importing onto an existing profile inherits its name-keyed leftovers, so it is
-- deleted first. DeleteProfile also drops its spec assignments; return them so the
-- caller can hand them back after the import.
local function DeleteEllesmereProfileForReimport(profileName)
    local specs = {}
    local specProfiles = type(EllesmereUIDB) == "table" and EllesmereUIDB.specProfiles
    if type(specProfiles) == "table" then
        for specID, assigned in pairs(specProfiles) do
            if assigned == profileName then specs[#specs + 1] = specID end
        end
    end
    pcall(EllesmereUI.DeleteProfile, profileName)
    return specs
end

local function RestoreEllesmereSpecAssignments(profileName, specs)
    if type(specs) ~= "table" or #specs == 0 or type(EllesmereUIDB) ~= "table" then return end
    if type(EllesmereUIDB.specProfiles) ~= "table" then EllesmereUIDB.specProfiles = {} end
    for _, specID in ipairs(specs) do
        EllesmereUIDB.specProfiles[specID] = profileName
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
            -- Transport-only; EllesmereUI's own installer import drops it too.
            payload.data.unlockLayoutMeta = nil
        end

        -- Bundled strings are regular profile exports. A full-account string would
        -- replace account-wide EllesmereUI settings and force a reload.
        if type(EllesmereUI.IsFullAccountPayload) == "function"
            and EllesmereUI.IsFullAccountPayload(payload)
        then
            return false, "EllesmereUI full-account strings are not supported"
        end

        if type(EllesmereUI.ImportProfile) ~= "function" then
            return false, "EllesmereUI import API is not available"
        end

        SwitchAwayFromOtherInariEllesmereProfile(profileName)

        local keptSpecs
        if EllesmereProfileExists(profileName) and type(EllesmereUI.DeleteProfile) == "function" then
            pcall(BackupEllesmereProfile, profileName)
            keptSpecs = DeleteEllesmereProfileForReimport(profileName)
        end

        local ok, success, err, status = pcall(EllesmereUI.ImportProfile, payload, profileName)
        if not ok then
            return false, tostring(success)
        end
        if not success then
            return false, tostring(err or "EllesmereUI import failed")
        end
        RestoreEllesmereSpecAssignments(profileName, keptSpecs)

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
    -- Only 21:9 ships while the 16:9 layout is disabled (CONST.LAYOUT_16_ENABLED).
    -- Players already on inari16:9 keep that profile instead of failing on the missing string.
    if not CONST.LAYOUT_16_ENABLED then
        if activateAspect == "16" then
            local ok, message = ActivateEllesmereLayoutProfile("inari16:9")
            if not ok then return false, message end
            return true, "kept your inari16:9 EllesmereUI layout"
        end
        return ImportEllesmereUIProfile(activateAspect)
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

    -- The limit is per layout type, and account layouts sit before character ones.
    local accountType = Enum and Enum.EditModeLayoutType and Enum.EditModeLayoutType.Account
    local characterType = Enum and Enum.EditModeLayoutType and Enum.EditModeLayoutType.Character
    local maxPerType = Constants and Constants.EditModeConsts and Constants.EditModeConsts.EditModeMaxLayoutsPerType or 5
    local accountCount = 0
    local insertIndex = #layouts.layouts + 1
    for i, layout in ipairs(layouts.layouts) do
        if characterType ~= nil and layout.layoutType == characterType then
            if i < insertIndex then insertIndex = i end
        else
            accountCount = accountCount + 1
        end
    end
    if accountCount >= maxPerType then
        return false, "maximum Edit Mode layouts already reached"
    end

    local okInfo, info = pcall(C_EditMode.ConvertStringToLayoutInfo, importString)
    if not okInfo or type(info) ~= "table" then
        return false, "Edit Mode import string is invalid"
    end

    info.layoutName = "inari"
    info.layoutType = accountType or info.layoutType

    tinsert(layouts.layouts, insertIndex, info)

    local okSave, saveErr = pcall(C_EditMode.SaveLayouts, layouts)
    if not okSave then
        return false, tostring(saveErr)
    end

    local presetCount = Enum and Enum.EditModePresetLayoutsMeta and Enum.EditModePresetLayoutsMeta.NumValues or 0
    local newIndex = presetCount + insertIndex
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

local function DynamicCamProfileExists(profileName)
    return type(DynamicCamDB) == "table"
        and type(DynamicCamDB.profiles) == "table"
        and type(DynamicCamDB.profiles[profileName]) == "table"
end

local function ImportDynamicCamProfile()
    local importString = InariProfiles and InariProfiles.dynamiccam
    if type(importString) ~= "string" or importString == "" then
        return false, "missing DynamicCam profile string"
    end

    if InCombatLockdown and InCombatLockdown() then
        return false, "leave combat before importing DynamicCam"
    end

    TryLoadAddon("DynamicCam")

    local dc = DynamicCam
    if not dc or not dc.db or type(dc.db.SetProfile) ~= "function"
        or type(dc.ImportIntoCurrentProfile) ~= "function" then
        return false, "DynamicCam import API is not available"
    end

    -- Switch to (or create) "inari", then let DynamicCam reset it and load the string,
    -- so reimports overwrite the profile instead of being refused as a duplicate.
    local ok, err = pcall(dc.db.SetProfile, dc.db, "inari")
    if not ok then
        return false, tostring(err or "DynamicCam profile switch failed")
    end

    ok, err = pcall(dc.ImportIntoCurrentProfile, dc, importString)
    if not ok then
        return false, tostring(err or "DynamicCam import failed")
    end

    MarkImportedProfileVersion("dynamiccam")
    return true, "DynamicCam profile imported as inari"
end

GetBundledProfileVersion = function(key)
    local versions = InariProfiles and InariProfiles.versions
    local version = versions and versions[key]
    if type(version) == "number" then return version end
    return 1
end

-- Cooldown Manager layouts are per class, so their imported version is too.
local function ImportedVersionKey(key)
    if key ~= "cdm" then return key end
    local _, classToken = UnitClass("player")
    return classToken and ("cdm:" .. classToken) or key
end

-- Optional one-line "what changed" for the update prompt.
local function GetProfileUpdateNote(key)
    local notes = InariProfiles and InariProfiles.notes
    local note = type(notes) == "table" and notes[key]
    if type(note) == "string" and note ~= "" then return note end
    return nil
end

MarkImportedProfileVersion = function(key)
    if type(key) ~= "string" or key == "" then return end
    EnsureDB()
    local storeKey = ImportedVersionKey(key)
    InariDB.importedProfileVersions[storeKey] = GetBundledProfileVersion(key)
    InariDB.profileUpdateDismissed[storeKey] = nil
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
                EllesmereUIDB.specProfiles[specID] = profileName
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
    TryLoadAddon("DynamicCam")

    return ResolveInstalledEllesmereProfile() ~= nil
        or BigWigsProfileExists("inari")
        or EXBossProfileExists("inari")
        or SArenaProfileExists("inari")
        or BaganatorProfileExists("inari")
        or DynamicCamProfileExists("inari")
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

local function ApplyExistingDynamicCamProfile(applied, missing, failed)
    TryLoadAddon("DynamicCam")

    if not DynamicCamProfileExists("inari") then
        missing[#missing + 1] = "DynamicCam"
        return
    end

    local db = DynamicCam and DynamicCam.db
    if not db or type(db.SetProfile) ~= "function" then
        failed[#failed + 1] = "DynamicCam: profile database is not available"
        return
    end

    if type(db.GetCurrentProfile) == "function" and db:GetCurrentProfile() == "inari" then
        applied[#applied + 1] = "DynamicCam (already active)"
        return
    end

    local ok, err = pcall(db.SetProfile, db, "inari")
    if not ok then
        failed[#failed + 1] = "DynamicCam: " .. tostring(err)
        return
    end

    applied[#applied + 1] = "DynamicCam"
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
    ApplyExistingDynamicCamProfile(applied, missing, failed)
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
    local defs = {
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
            key = "dynamiccam",
            label = "DynamicCam",
            exists = function()
                TryLoadAddon("DynamicCam")
                return DynamicCamProfileExists("inari")
            end,
            import = ImportDynamicCamProfile,
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

    if ns.IS_FOREVER then
        for index = #defs, 1, -1 do
            if defs[index].retailOnly then table.remove(defs, index) end
        end
    end
    return defs
end

local function SeedInstalledProfileVersions()
    EnsureDB()
    if InariDB.profileVersionsSeeded then return end

    for _, def in ipairs(GetManagedProfileDefs()) do
        local storeKey = ImportedVersionKey(def.key)
        if def.exists() and InariDB.importedProfileVersions[storeKey] == nil then
            InariDB.importedProfileVersions[storeKey] = GetBundledProfileVersion(def.key)
        end
    end

    InariDB.profileVersionsSeeded = true
end

local function GetOutdatedInstalledProfiles()
    EnsureDB()
    SeedInstalledProfileVersions()

    -- The bundled EllesmereUI update is 21:9-only while 16:9 is disabled; keep 16:9 players on theirs.
    local hold16 = ns.IsLegacy16Layout and ns.IsLegacy16Layout()

    local outdated = {}
    for _, def in ipairs(GetManagedProfileDefs()) do
        if def.exists() and not (hold16 and def.key == "ellesmereui") then
            local bundled = GetBundledProfileVersion(def.key)
            local imported = InariDB.importedProfileVersions[ImportedVersionKey(def.key)]
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

-- "Not now" skips the bundled version it was shown for; the next bump asks again.
local function DismissProfileUpdates(defs)
    EnsureDB()
    for _, def in ipairs(defs or {}) do
        InariDB.profileUpdateDismissed[ImportedVersionKey(def.key)] = GetBundledProfileVersion(def.key)
    end
end

local function ShouldOfferProfileUpdates()
    EnsureDB()
    if InariDB.profileUpdateEnabled == false then return false end
    if InariDB.installerCompletedVersion ~= CONST.profilePromptVersion then return false end
    if State.profileUpdatePromptDismissedThisSession then return false end
    for _, def in ipairs(GetOutdatedInstalledProfiles()) do
        if InariDB.profileUpdateDismissed[ImportedVersionKey(def.key)] ~= GetBundledProfileVersion(def.key) then
            return true
        end
    end
    return false
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

-- Spec APIs differ on WoW Forever, so every call is guarded and failures mean "no specs".
local function GetSpecNames()
    local specs = {}
    if type(GetNumSpecializations) ~= "function" or type(GetSpecializationInfo) ~= "function" then
        return specs
    end
    local okCount, count = pcall(GetNumSpecializations)
    if not okCount or type(count) ~= "number" then return specs end
    for index = 1, count do
        local ok, _, specName = pcall(GetSpecializationInfo, index)
        if ok and type(specName) == "string" then specs[#specs + 1] = specName end
    end
    return specs
end

local function GetCurrentSpecName()
    if type(GetSpecialization) ~= "function" or type(GetSpecializationInfo) ~= "function" then
        return nil
    end
    local okIndex, index = pcall(GetSpecialization)
    if not okIndex or type(index) ~= "number" then return nil end
    local ok, _, specName = pcall(GetSpecializationInfo, index)
    if ok and type(specName) == "string" then return specName end
    return nil
end

local function StartsWith(text, prefix)
    return type(text) == "string" and text:sub(1, #prefix) == prefix
end

local function GetInariCooldownData()
    -- Forever has its own class spell lists, so it gets its own set of layouts.
    local layouts = ns.IS_FOREVER and InariCooldownLayoutsForever or InariCooldownLayouts

    local classKey = GetClassKey()
    local classData = classKey and layouts and layouts[classKey]
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

            local newName
            if not specName and ns.IS_FOREVER and StartsWith(oldName, "inari - ") then
                -- Forever layouts are class-wide and already carry their inari name.
                newName = oldName
            else
                specName = specName or specs[index] or tostring(index)
                newName = "inari - " .. className .. " " .. specName
            end
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
    local prefix = "inari - " .. GetClassDisplayName()
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
    local imported = InariDB.importedProfileVersions and InariDB.importedProfileVersions[ImportedVersionKey("cdm")]
    local hasLayouts = HasInariCooldownLayouts()
    if type(imported) ~= "number" then imported = nil end
    return {
        bundled = bundled,
        imported = imported,
        hasLayouts = hasLayouts,
        outdated = hasLayouts and (imported or 0) < bundled,
    }
end


ns.GetBundledProfileVersion = GetBundledProfileVersion
ns.GetProfileUpdateNote = GetProfileUpdateNote
ns.MarkImportedProfileVersion = MarkImportedProfileVersion
ns.ImportEllesmereUIProfile = ImportEllesmereUIProfile
ns.ImportBothEllesmereUIProfiles = ImportBothEllesmereUIProfiles
ns.ActivateEllesmereLayoutProfile = ActivateEllesmereLayoutProfile
ns.ImportBigWigsProfile = ImportBigWigsProfile
ns.ImportEditModeLayout = ImportEditModeLayout
ns.ImportEXBossProfile = ImportEXBossProfile
ns.ImportSArenaProfile = ImportSArenaProfile
ns.ImportBaganatorProfile = ImportBaganatorProfile
ns.ImportDynamicCamProfile = ImportDynamicCamProfile
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
ns.DismissProfileUpdates = DismissProfileUpdates
ns.ScheduleInstalledProfilesOffer = ScheduleInstalledProfilesOffer
