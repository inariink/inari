local ADDON_NAME, ns = ...

local function UI()
    return ns.UI or _G.InariUI
end

local function Print(msg)
    ns.Print(msg)
end

local PAGE_LABELS = {
    overview = "overview",
    appearance = "appearance",
    extras = "extras",
    profiles = "profiles",
    cooldowns = "cooldown manager",
    layout = "layout",
    setup = "setup",
    install = "setup",
}

local SUPPORTED_ADDONS = {
    { name = "EllesmereUI", label = "EllesmereUI", required = true },
    { name = "EllesmereUIUnitFrames", label = "Ellesmere Unit Frames", required = true },
    { name = "EllesmereUIChat", label = "Ellesmere Chat" },
    { name = "EllesmereUIBlizzardSkin", label = "Ellesmere Blizzard Skin" },
    { name = "EllesmereUIDamageMeters", label = "Ellesmere Damage Meters" },
    { name = "EllesmereUIRaidFrames", label = "Ellesmere Raid Frames" },
    { name = "BigWigs", label = "BigWigs" },
    { name = "EXBoss", label = "EXBoss" },
    { name = "sArena_Reloaded", label = "sArena Reloaded" },
    { name = "Baganator", label = "Baganator" },
}

local function NormalizePage(page)
    if page == "welcome" or page == "settings" or page == "home" or page == "runtime" then return "overview" end
    if page == "behavior" or page == "extra" or page == "portrait" or page == "portraits" or page == "blinkii" or page == "blinkiis" then return "extras" end
    if page == "layout" or page == "aspect" or page == "widescreen" or page == "ultrawide" then return "layout" end
    if page == "qol" or page == "movement" or page == "qol_movement" or page == "quality" or page == "qualityoflife" or page == "movementtracker" then return "overview" end
    if page == "cvars" or page == "graphics" or page == "fps" or page == "uiscale" or page == "client" then return "setup" end
    if page == "install" or page == "installer" then return "install" end
    if page == "cdm" or page == "cooldown" then return "cooldowns" end
    if page == "addons" then return "profiles" end
    return page or "overview"
end

local function CooldownVersionStatus()
    if ns.IS_FOREVER then
        return "Retail only", "muted"
    end
    local info = ns.GetCooldownLayoutVersionInfo and ns.GetCooldownLayoutVersionInfo()
    if not info then
        return "Not imported", "warn"
    end
    if info.imported then
        local text = "Version " .. tostring(info.imported)
        if info.outdated then
            return text .. " → " .. tostring(info.bundled), "warn"
        end
        return text, "ok"
    end
    if info.hasLayouts then
        if info.outdated then
            return "Outdated", "warn"
        end
        return "Imported", "ok"
    end
    return "Not imported", "warn"
end

local function FormatScale(value)
    return string.format("%.4f", tonumber(value) or 0):gsub("0+$", ""):gsub("%.$", "")
end

local function UIScaleIsCorrect()
    local expected = ns.UI_SCALE or 0.5333333333
    local current = tonumber(ns.GetInariCVar and ns.GetInariCVar("uiScale"))
    if not current then return false, expected, nil end
    return math.abs(current - expected) < 0.001, expected, current
end

local function ProfileCounts()
    local defs = ns.GetManagedProfileDefs and ns.GetManagedProfileDefs() or {}
    local installed = 0
    for _, def in ipairs(defs) do
        if def.exists and def.exists() then
            installed = installed + 1
        end
    end
    local outdated = ns.GetOutdatedInstalledProfiles and ns.GetOutdatedInstalledProfiles() or {}
    return installed, #defs, outdated
end

local function CombatTextMatches(value)
    local expected = tostring(value)
    for _, name in ipairs(ns.FLOATING_COMBAT_TEXT_CVARS) do
        if tostring(ns.GetInariCVar(name)) ~= expected then
            return false
        end
    end
    return true
end

local function PresetMatches(cvars)
    for _, cvar in ipairs(cvars) do
        if tostring(ns.GetInariCVar(cvar[1])) ~= tostring(cvar[2]) then
            return false
        end
    end
    return true
end

-- Stored preset if valid, otherwise whichever preset the live CVars match.
local function CurrentCombatTextPreset()
    local preset = InariDB.floatingCombatTextPreset
    if preset == "disabled" or preset == "enabled" then return preset end
    if CombatTextMatches(0) then return "disabled" end
    if CombatTextMatches(1) then return "enabled" end
    return nil
end

local function CurrentGraphicsPreset()
    local preset = InariDB.graphicsPreset
    if preset == "inari" or preset == "fps" then return preset end
    if PresetMatches(ns.INARI_GRAPHICS_CVARS) then return "inari" end
    if PresetMatches(ns.FPS_CVARS) then return "fps" end
    return nil
end

-- A held stepper would otherwise rebuild every Ellesmere frame per click.
local opacityReloadTimer
local function QueueOpacityReload()
    if opacityReloadTimer then opacityReloadTimer:Cancel() end
    opacityReloadTimer = C_Timer.NewTimer(0.3, function()
        opacityReloadTimer = nil
        ns.ScheduleApply()
        ns.ReloadEllesmereFrames()
    end)
end

local function ShowResetPrompt(onReset)
    local State = ns.State
    if not State.resetPromptFrame then
        local frame = UI():CreateDialog("InariResetPromptFrame", 500, 300, "setup")
        frame:SetHeading("Reset inari settings")
        frame:SetCopy("Sets inari's own options back to their defaults. Imported profiles and the install state are kept.")
        frame.primaryButton:SetLabel("Reset")
        frame.secondaryButton:SetLabel("Cancel")
        local function Close()
            frame:Hide()
        end
        frame:SetOnClose(Close)
        frame.secondaryButton:SetOnClick(Close)
        State.resetPromptFrame = frame
    end

    local frame = State.resetPromptFrame
    frame.primaryButton:SetOnClick(function()
        ns.ResetSettings()
        frame:Hide()
        if onReset then onReset() end
    end)
    frame:Show()
end

local function BuildAppearance(frame, ui)
    local page = ui:CreatePage(frame.content, "Appearance", "How inari colors unit frames. Class resource and power bars stay colored.")

    local inari = page:AddSection("Inari")
    local enableToggle = inari:AddToggle("Enable inari", InariDB.enabled == true, function(_, checked)
        InariDB.enabled = checked
        if checked then
            ns.ScheduleApply()
            ns.UpdateIdleFadeController()
            page:SetMuted("Inari enabled.")
            Print("enabled")
        else
            ns.RestoreAll()
            ns.UpdateIdleFadeController()
            page:SetMuted("Inari disabled.")
            Print("disabled")
        end
    end)
    inari:AddButtonRow({
        {
            label = "Reapply",
            width = 150,
            onClick = function()
                ns.ScheduleApply(0, true)
                page:SetMuted("Settings queued.")
                Print("runtime settings queued")
            end,
        },
    })

    local mode = page:AddSection("Mode")
    local appearanceControl = mode:AddSegmented({
        { label = "Dark Mode", value = "dark", width = 170 },
        { label = "Class Colored", value = "class", width = 170 },
    }, ns.GetAppearanceMode(), function(_, nextMode)
        nextMode = ns.SetInariAppearanceMode(nextMode)
        local message = nextMode == "class" and "appearance set to class colored" or "appearance set to dark mode"
        page:SetMuted(message)
        Print(message)
    end)
    local themeToggle = mode:AddToggle("Sync EllesmereUI colors to inari", InariDB.forceEUITheme == true, function(_, checked)
        InariDB.forceEUITheme = checked
        local message
        if checked then
            ns.ApplyEllesmereThemeSettings(true, true)
            message = "EllesmereUI color sync enabled"
        else
            message = "EllesmereUI color sync disabled"
        end
        page:SetMuted(message)
        Print(message)
    end)
    local opacityRow
    opacityRow = mode:AddStepperRow("Health opacity", InariDB.healthBarOpacity or 85, 0, 100, 1, function(_, value)
        local normalized = ns.NormalizeHealthOpacity(value, InariDB.healthBarOpacity)
        if normalized ~= value then
            value = normalized
            opacityRow:SetValue(value, true)
        end
        InariDB.healthBarOpacity = value
        InariDB.forceOpacity = true
        if ns.SetAllHealthOpacity(value) then
            QueueOpacityReload()
            local message = "health opacity set to " .. tostring(value) .. "%"
            page:SetMuted(message)
            Print(message)
        else
            page:SetStatus(false, "Ellesmere unit frame profiles were not ready")
            Print("Ellesmere unit frame profiles were not ready")
        end
    end)
    local tintRow = mode:AddStepperRow("Class background tint", math.floor((InariDB.tint or 0.75) * 100 + 0.5), 0, 100, 1, function(_, value)
        InariDB.tint = value / 100
        ns.ScheduleApply()
        local message = "class background tint set to " .. tostring(value) .. "%"
        page:SetMuted(message)
        Print(message)
    end)
    local shadowToggle = mode:AddToggle("Draw shadows on frames", InariDB.frameShadows == true, function(_, checked)
        InariDB.frameShadows = checked
        ns.ScheduleApply()
        local message = checked and "frame shadows enabled" or "frame shadows disabled"
        page:SetMuted(message)
        Print(message)
    end)
    local shadowRow = mode:AddStepperRow("Shadow strength", InariDB.frameShadowStrength or 70, 0, 100, 5, function(_, value)
        InariDB.frameShadowStrength = value
        ns.ScheduleApply()
        local message = "shadow strength set to " .. tostring(value) .. "%"
        page:SetMuted(message)
        Print(message)
    end)

    function page:Refresh()
        enableToggle:SetChecked(InariDB.enabled == true)
        appearanceControl:SetValue(ns.GetAppearanceMode(), true)
        themeToggle:SetChecked(InariDB.forceEUITheme == true)
        opacityRow:SetValue(InariDB.healthBarOpacity or 85, true)
        tintRow:SetValue(math.floor((InariDB.tint or 0.75) * 100 + 0.5), true)
        shadowToggle:SetChecked(InariDB.frameShadows == true)
        shadowRow:SetValue(InariDB.frameShadowStrength or 70, true)
    end

    page:UpdateLayout()
    return page
end

local function BuildExtras(frame, ui)
    local page = ui:CreatePage(frame.content, "Extras", "Extra live UI options while you play.")

    local combat = page:AddSection("Combat")
    local idleToggle = combat:AddToggle("Fade frames while idle", InariDB.fadeIdlePlayerAndCooldowns == true, function(_, checked)
        InariDB.fadeIdlePlayerAndCooldowns = checked
        ns.ScheduleIdleFadeUpdate(0)
        local message = checked and "idle fade enabled" or "idle fade disabled"
        page:SetMuted(message)
        Print(message)
    end)
    local nameplateToggle = combat:AddToggle("Force friendly player nameplates off", InariDB.disableFriendlyPlayerNameplates == true, function(_, checked)
        InariDB.disableFriendlyPlayerNameplates = checked
        local message
        if checked then
            ns.ApplyFriendlyPlayerNameplatePreference()
            message = "friendly player nameplates forced off"
        else
            message = "friendly player nameplate override disabled"
        end
        page:SetMuted(message)
        Print(message)
    end)
    local arrowsToggle = combat:AddToggle("inari target arrows", InariDB.targetArrows == true, function(_, checked)
        InariDB.targetArrows = checked
        if ns.RefreshTargetArrows then ns.RefreshTargetArrows() end
        local message = checked and "target arrows enabled" or "target arrows disabled"
        page:SetMuted(message)
        Print(message)
    end)
    local arrowsSizeRow = combat:AddStepperRow("Arrow size", InariDB.targetArrowSize or 30, 12, 80, 1, function(_, value)
        InariDB.targetArrowSize = value
        if ns.RefreshTargetArrows then ns.RefreshTargetArrows() end
        local message = "target arrow size set to " .. tostring(value)
        page:SetMuted(message)
        Print(message)
    end)
    local pagingToggle = combat:AddToggle("Disable form/stealth action bar paging", InariDB.disableEllesmereActionBarPaging == true, function(_, checked)
        InariDB.disableEllesmereActionBarPaging = checked
        local applied = ns.ApplyEllesmereActionBarPagingOverride()
        ns.ScheduleApply()
        local message = checked and "form/stealth action bar paging disabled" or "form/stealth action bar paging enabled"
        if InCombatLockdown and InCombatLockdown() then
            message = message .. "; will apply after combat"
        elseif not applied then
            message = message .. "; will apply when action bars load"
        end
        page:SetMuted(message)
        Print(message)
    end)

    local chat = page:AddSection("Chat")
    local chatControl = chat:AddSegmented({
        { label = "Buttons Left", value = "left", width = 170 },
        { label = "Buttons Right", value = "right", width = 170 },
    }, InariDB.forceChatSidebarRight and "right" or "left", function(_, side)
        InariDB.forceChatSidebarRight = side == "right"
        ns.ApplyChatSettings()
        ns.ScheduleApply()
        local message = side == "right" and "chat buttons set to right" or "chat buttons set to left"
        page:SetMuted(message)
        Print(message)
    end)

    ns.EnsureDB()
    local portraits = InariDB.portraits
    local function ApplyPortraits(message)
        if ns.RefreshPortraits then ns.RefreshPortraits() end
        if message then
            page:SetMuted(message)
            Print(message)
        end
    end

    local portraitsSection = page:AddSection("Portraits")
    local portraitsToggle = portraitsSection:AddToggle("Enable portraits", portraits.enabled == true, function(_, checked)
        portraits.enabled = checked
        ApplyPortraits(checked and "portraits enabled" or "portraits disabled")
    end)
    local sizeRow = portraitsSection:AddStepperRow("Size", portraits.size or 52, 16, 256, 1, function(_, value)
        portraits.size = value
        ApplyPortraits("portrait size set to " .. tostring(value))
    end)
    local zoomRow = portraitsSection:AddStepperRow("Zoom", portraits.zoom or 0.22, 0, 1, 0.01, function(_, value)
        portraits.zoom = value
        ApplyPortraits("portrait zoom set to " .. string.format("%.2f", value))
    end)

    local function AddPortraitUnit(key, title)
        local unitDB = portraits[key]
        local section = page:AddSection(title .. " Portrait")
        local unitToggle = section:AddToggle("Show " .. string.lower(title) .. " portrait", unitDB.enable ~= false, function(_, checked)
            unitDB.enable = checked
            ApplyPortraits(string.lower(title) .. " portrait " .. (checked and "enabled" or "disabled"))
        end)
        local anchorControl = section:AddSegmented({
            { label = "Left", value = "LEFT", width = 170 },
            { label = "Right", value = "RIGHT", width = 170 },
        }, unitDB.anchor, function(_, anchor)
            unitDB.anchor = anchor
            ApplyPortraits(string.lower(title) .. " portrait anchored " .. string.lower(anchor))
        end)
        local xRow = section:AddStepperRow("X offset", unitDB.x or 0, -64, 64, 1, function(_, value)
            unitDB.x = value
            ApplyPortraits(string.lower(title) .. " portrait X offset set to " .. tostring(value))
        end)
        local yRow = section:AddStepperRow("Y offset", unitDB.y or 0, -64, 64, 1, function(_, value)
            unitDB.y = value
            ApplyPortraits(string.lower(title) .. " portrait Y offset set to " .. tostring(value))
        end)
        return unitToggle, anchorControl, xRow, yRow
    end

    local playerToggle, playerAnchor, playerX, playerY = AddPortraitUnit("player", "Player")
    local targetToggle, targetAnchor, targetX, targetY = AddPortraitUnit("target", "Target")

    function page:Refresh()
        idleToggle:SetChecked(InariDB.fadeIdlePlayerAndCooldowns == true)
        nameplateToggle:SetChecked(InariDB.disableFriendlyPlayerNameplates == true)
        arrowsToggle:SetChecked(InariDB.targetArrows == true)
        arrowsSizeRow:SetValue(InariDB.targetArrowSize or 30, true)
        pagingToggle:SetChecked(InariDB.disableEllesmereActionBarPaging == true)
        chatControl:SetValue(InariDB.forceChatSidebarRight and "right" or "left", true)
        ns.EnsureDB()
        portraits = InariDB.portraits
        portraitsToggle:SetChecked(portraits.enabled == true)
        sizeRow:SetValue(portraits.size or 52, true)
        zoomRow:SetValue(portraits.zoom or 0.22, true)
        playerToggle:SetChecked(portraits.player.enable ~= false)
        playerAnchor:SetValue(portraits.player.anchor or "LEFT", true)
        playerX:SetValue(portraits.player.x or 0, true)
        playerY:SetValue(portraits.player.y or 0, true)
        targetToggle:SetChecked(portraits.target.enable ~= false)
        targetAnchor:SetValue(portraits.target.anchor or "RIGHT", true)
        targetX:SetValue(portraits.target.x or 0, true)
        targetY:SetValue(portraits.target.y or 0, true)
        if ns.BlinkiiPortraitsPresent and ns.BlinkiiPortraitsPresent() then
            page:SetMuted("Blinkii's Portraits is still loaded. Disable that addon to avoid a double portrait.")
        end
    end

    page:UpdateLayout()
    return page
end

local function BuildProfiles(frame, ui)
    local page = ui:CreatePage(frame.content, "Profiles", "Apply inari profiles to this character, update bundled versions, and see which addons are present.")
    local summary = page:AddSection("Installed")
    local installedRow = summary:AddInfoRow("Installed", "—")
    local outdatedRow = summary:AddInfoRow("Outdated", "—")
    summary:AddButtonRow({
        {
            label = "Apply Profiles",
            width = 150,
            variant = "primary",
            onClick = function()
                local ok, message = ns.ApplyInstalledProfilesToCharacter(true)
                page:SetStatus(ok, message)
                Print(message)
                if ok then Print("reload UI to finish applying loaded profiles") end
            end,
        },
        {
            label = "Update Profiles",
            width = 150,
            onClick = function()
                ns.ShowProfileUpdatePrompt()
            end,
        },
    })

    local detected = page:AddSection("Addons")
    local addonRows = {}
    for _, addon in ipairs(SUPPORTED_ADDONS) do
        addonRows[#addonRows + 1] = {
            addon = addon,
            row = detected:AddInfoRow(addon.label, "—"),
        }
    end

    function page:Refresh()
        local installed, total, outdated = ProfileCounts()
        installedRow.value:SetText(tostring(installed) .. " / " .. tostring(total))
        if #outdated > 0 then
            outdatedRow.value:SetText(ns.FormatProfileLabelList and ns.FormatProfileLabelList(outdated) or (tostring(#outdated) .. " outdated"))
        else
            outdatedRow.value:SetText(installed > 0 and "none" or "no profiles found")
        end
        for _, entry in ipairs(addonRows) do
            local present = ns.IsAddonPresent(entry.addon.name)
            entry.row.value:SetText(present and "detected" or (entry.addon.required and "missing (required)" or "missing"))
            ui:SetStatusColor(entry.row.value, present)
        end
    end

    page:UpdateLayout()
    return page
end

local function BuildCooldowns(frame, ui)
    local page = ui:CreatePage(frame.content, "Cooldown Manager Profiles", "Import Blizzard Cooldown Manager layouts for your current class.")
    local summary = page:AddSection("Blizzard Cooldown Manager")
    local versionRow = summary:AddInfoRow("Imported version", "—")
    local classRow = summary:AddInfoRow("Current class", ns.GetClassDisplayName())
    summary:AddInfoRow("Import behavior", "replaces old inari layouts")
    summary:AddButtonRow({
        {
            label = "Import Layouts",
            width = 170,
            variant = "primary",
            onClick = function()
                local ok, message = ns.ImportInariCooldownLayouts()
                page:SetStatus(ok, message or "")
                Print(message or (ok and "cooldown layouts imported" or "cooldown import failed"))
                if page.Refresh then page:Refresh() end
            end,
        },
    })
    function page:Refresh()
        local status = CooldownVersionStatus()
        versionRow.value:SetText(status)
        local info = ns.GetCooldownLayoutVersionInfo and ns.GetCooldownLayoutVersionInfo()
        ui:SetStatusColor(versionRow.value, info and (info.imported or info.hasLayouts) and not info.outdated)
        classRow.value:SetText(ns.GetClassDisplayName() or "")
    end
    page:UpdateLayout()
    return page
end

local function BuildSetup(frame, ui)
    local page = ui:CreatePage(frame.content, "Setup", "First-time install, UI scale, and WoW client presets.")

    local installer = page:AddSection("Installer")
    local installerRow = installer:AddInfoRow("Status", "—")
    installer:AddButtonRow({
        {
            label = "Run Installer",
            width = 170,
            variant = "primary",
            onClick = function()
                ns.ShowInstallerFrame()
            end,
        },
    })

    local scale = page:AddSection("UI Scale")
    local expectedRow = scale:AddInfoRow("Expected", FormatScale(ns.UI_SCALE or 0.5333333333))
    local currentRow = scale:AddInfoRow("Current", "—")
    local keepScaleToggle = scale:AddToggle("Keep my own UI scale", InariDB.keepUIScale == true, function(_, checked)
        InariDB.keepUIScale = checked or nil
        local message = checked and "inari will leave your UI scale alone" or "inari expects its own UI scale again"
        page:SetMuted(message)
        Print(message)
        if page.Refresh then page:Refresh() end
    end)
    scale:AddButtonRow({
        {
            label = "Apply UI Scale",
            width = 170,
            onClick = function()
                ns.ApplyInariUIScale(true)
                page:SetMuted("UI scale applied.")
                Print("UI scale applied")
                if page.Refresh then page:Refresh() end
            end,
        },
    })

    local base = page:AddSection("Base CVars")
    base:AddButtonRow({
        {
            label = "Set Base CVars",
            width = 170,
            onClick = function()
                local message = ns.FormatCVarResult("base CVars set: ", ns.ApplyCVarTable(ns.BASE_CVARS))
                page:SetMuted(message)
                Print(message)
            end,
        },
    })

    local combatText = page:AddSection("Floating combat text")
    local fctPreset = CurrentCombatTextPreset()
    local fctControl = combatText:AddSegmented({
        { label = "Disable", value = "disabled", width = 170 },
        { label = "Enable", value = "enabled", width = 170 },
    }, fctPreset, function(_, preset)
        local message = ns.FormatCVarResult("floating combat text " .. preset .. ": ",
            ns.ApplyFloatingCombatText(preset == "enabled" and 1 or 0))
        page:SetMuted(message)
        Print(message)
    end)

    local graphics = page:AddSection("Graphics")
    graphics:AddText("Graphics presets apply immediately and overwrite the matching client CVars.", 12, "muted", 36)
    local gfxPreset = CurrentGraphicsPreset()
    local gfxControl = graphics:AddSegmented({
        { label = "FPS Settings", value = "fps", width = 170 },
        { label = "Inari Graphics", value = "inari", width = 170 },
    }, gfxPreset, function(_, preset)
        local message
        if preset == "inari" then
            message = ns.FormatCVarResult("Inari's graphics applied: ", ns.ApplyInariGraphicsSettings())
        else
            message = ns.FormatCVarResult("FPS preset applied: ", ns.ApplyFPSSettings())
        end
        page:SetMuted(message)
        Print(message)
    end)

    local reset = page:AddSection("Reset")
    reset:AddButtonRow({
        {
            label = "Reset Settings",
            width = 170,
            onClick = function()
                ShowResetPrompt(function()
                    page:SetMuted("Settings reset to defaults.")
                    Print("settings reset to defaults")
                    if page.Refresh then page:Refresh() end
                end)
            end,
        },
    })

    function page:Refresh()
        keepScaleToggle:SetChecked(InariDB.keepUIScale == true)
        if InariDB.installerPendingFinalScale then
            installerRow.value:SetText("pending final scale")
            ui:SetStatusColor(installerRow.value, false)
        elseif ns.IsInstallerComplete and ns.IsInstallerComplete() then
            installerRow.value:SetText("completed")
            ui:SetStatusColor(installerRow.value, true)
        else
            installerRow.value:SetText("not completed")
            ui:SetStatusColor(installerRow.value, false)
        end

        local ok, expected, current = UIScaleIsCorrect()
        expectedRow.value:SetText(FormatScale(expected))
        currentRow.value:SetText(current and FormatScale(current) or "unknown")
        ui:SetStatusColor(currentRow.value, ok or InariDB.keepUIScale == true)

        local nextFct = CurrentCombatTextPreset()
        if nextFct then fctControl:SetValue(nextFct, true) end
        local nextGfx = CurrentGraphicsPreset()
        if nextGfx then gfxControl:SetValue(nextGfx, true) end
    end

    page:UpdateLayout()
    return page
end

local function ReimportEllesmereLayout(host, aspect, forceImport)
    if aspect then
        aspect = ns.SetLayoutAspect(aspect)
        if not aspect then return false end
    else
        aspect = ns.GetLayoutAspect and ns.GetLayoutAspect() or "16"
    end
    local label = ns.GetLayoutAspectLabel and ns.GetLayoutAspectLabel(aspect) or aspect
    local profileName = ns.GetEllesmereLayoutProfileName and ns.GetEllesmereLayoutProfileName(aspect) or ("inari" .. label)
    if InCombatLockdown and InCombatLockdown() then
        local message = "leave combat before switching to the " .. label .. " layout"
        Print(message)
        if host and host.SetStatus then host:SetStatus(false, "Leave combat first.") end
        return false
    end

    local ok, message
    local alreadyInstalled = ns.EllesmereProfileExists(profileName)
    if forceImport or not alreadyInstalled then
        ok, message = ns.ImportEllesmereUIProfile()
        message = message or (ok and ("EllesmereUI " .. label .. " imported as " .. profileName) or "EllesmereUI import failed")
    else
        ok, message = ns.ActivateEllesmereLayoutProfile(profileName)
        message = message or (ok and ("EllesmereUI switched to " .. profileName) or "EllesmereUI switch failed")
    end
    Print(message)
    if ok then
        if host and host.SetMuted then host:SetMuted(message) end
        ReloadUI()
        return true
    end
    if host and host.SetStatus then host:SetStatus(false, message) end
    return false
end

local function BuildLayout(frame, ui)
    local page = ui:CreatePage(frame.content, "Layout", "Switches the EllesmereUI profile between inari16:9 and inari21:9. Reimport only if you need a fresh copy of the bundled layout.")

    local monitor = page:AddSection("Monitor")
    local currentRow = monitor:AddInfoRow("Current", "—")
    local layoutControl = monitor:AddSegmented({
        { label = "16:9", value = "16", width = 170 },
        { label = "21:9", value = "21", width = 170 },
    }, ns.GetLayoutAspect and ns.GetLayoutAspect() or "16", function(_, aspect)
        if aspect == (ns.GetLayoutAspect and ns.GetLayoutAspect()) then return end
        ReimportEllesmereLayout(page, aspect)
        if page.Refresh then page:Refresh() end
    end)
    monitor:AddButtonRow({
        {
            label = "Reimport Layout",
            width = 170,
            variant = "primary",
            onClick = function()
                ReimportEllesmereLayout(page, nil, true)
                if page.Refresh then page:Refresh() end
            end,
        },
    })

    function page:Refresh()
        ns.EnsureDB()
        local aspect = ns.GetLayoutAspect and ns.GetLayoutAspect() or "16"
        local label = ns.GetLayoutAspectLabel and ns.GetLayoutAspectLabel(aspect) or aspect
        local profileName = ns.GetEllesmereLayoutProfileName and ns.GetEllesmereLayoutProfileName(aspect) or ("inari" .. label)
        currentRow.value:SetText(profileName)
        layoutControl:SetValue(aspect, true)
    end

    page:Refresh()
    return page
end

local function BuildOverview(frame, ui)
    local overview = CreateFrame("Frame", nil, frame.content)
    overview:SetAllPoints()

    overview.grid = CreateFrame("Frame", nil, overview)
    overview.grid:SetAllPoints()

    local function Card(id, title, icon)
        local card = ui:CreateDashboardCard(overview.grid)
        card:SetTitle(title)
        card:SetIcon(icon)
        card:SetOnOpen(function()
            frame.SelectPage(id)
        end)
        return card
    end

    local appearanceCard = Card("appearance", "Appearance", ui.Media.IconAppearance)
    local layoutCard = Card("layout", "Layout", ui.Media.IconLayout or ui.Media.IconUIScale)
    local extrasCard = Card("extras", "Extras", ui.Media.IconRuntime)
    local profilesCard = Card("profiles", "Profiles", ui.Media.IconProfiles)
    local cooldownsCard = Card("cooldowns", "Cooldown Manager Profiles", ui.Media.IconCooldowns)
    local setupCard = Card("setup", "Setup", ui.Media.IconInstaller)

    local appearanceControl = ui:CreateSegmentedControl(appearanceCard.controlHost, {
        { label = "Dark", value = "dark", width = 80, height = 26 },
        { label = "Class", value = "class", width = 80, height = 26 },
    })
    appearanceControl:SetOnChanged(function(_, mode)
        mode = ns.SetInariAppearanceMode(mode)
        local message = mode == "class" and "appearance set to class colored" or "appearance set to dark mode"
        Print(message)
        if overview.Refresh then overview:Refresh() end
    end)
    appearanceCard:AttachControl(appearanceControl)

    local layoutControl = ui:CreateSegmentedControl(layoutCard.controlHost, {
        { label = "16:9", value = "16", width = 80, height = 26 },
        { label = "21:9", value = "21", width = 80, height = 26 },
    })
    layoutControl:SetOnChanged(function(_, aspect)
        if aspect == (ns.GetLayoutAspect and ns.GetLayoutAspect()) then return end
        ReimportEllesmereLayout(nil, aspect)
        if overview.Refresh then overview:Refresh() end
    end)
    layoutCard:AttachControl(layoutControl)

    local relayout = ui:LayoutCardGrid(overview.grid, {
        appearanceCard,
        layoutCard,
        extrasCard,
        profilesCard,
        cooldownsCard,
        setupCard,
    }, 2, 12)

    function overview:Refresh()
        if relayout then relayout() end
        ns.EnsureDB()

        if not InariDB.enabled then
            appearanceCard:SetStatus("Inari disabled", "warn")
            appearanceCard:SetAttention(true)
        else
            local mode = ns.GetAppearanceMode()
            appearanceCard:SetStatus(mode == "class" and "Class Colored" or "Dark Mode")
            appearanceCard:SetAttention(false)
        end
        appearanceControl:SetValue(ns.GetAppearanceMode(), true)

        local aspect = ns.GetLayoutAspect and ns.GetLayoutAspect() or "16"
        local ellesmerePresent = ns.IsAddonPresent and ns.IsAddonPresent("EllesmereUI")
        if not ellesmerePresent then
            layoutCard:SetStatus("EllesmereUI missing", "warn")
            layoutCard:SetAttention(true)
        else
            layoutCard:SetStatus(ns.GetEllesmereLayoutProfileName and ns.GetEllesmereLayoutProfileName(aspect) or (aspect .. " layout"))
            layoutCard:SetAttention(false)
        end
        layoutControl:SetValue(aspect, true)

        local idleFade = InariDB.fadeIdlePlayerAndCooldowns == true
        local disableNameplates = InariDB.disableFriendlyPlayerNameplates == true
        local disablePaging = InariDB.disableEllesmereActionBarPaging == true
        local portraitsOn = InariDB.portraits and InariDB.portraits.enabled == true
        local arrowsOn = InariDB.targetArrows == true
        extrasCard:SetStatusLines({
            { text = "Idle Fade " .. (idleFade and "on" or "off"), on = idleFade },
            { text = "Disable friendly nameplates " .. (disableNameplates and "on" or "off"), on = disableNameplates },
            { text = "Target arrows " .. (arrowsOn and "on" or "off"), on = arrowsOn },
            { text = "Disable action bar paging " .. (disablePaging and "on" or "off"), on = disablePaging },
            { text = "Portraits " .. (portraitsOn and "on" or "off"), on = portraitsOn },
        })
        extrasCard:SetAttention(ns.BlinkiiPortraitsPresent and ns.BlinkiiPortraitsPresent() or false)
        extrasCard:SetAction(nil)

        local installed, total, outdated = ProfileCounts()
        if installed == 0 then
            profilesCard:SetStatus("None found", "warn")
            profilesCard:SetAttention(true)
            profilesCard:SetAction("APPLY PROFILES", "primary", function()
                local ok, message = ns.ApplyInstalledProfilesToCharacter(true)
                Print(message)
                if ok then Print("reload UI to finish applying loaded profiles") end
                overview:Refresh()
            end)
        elseif #outdated > 0 then
            profilesCard:SetStatus(tostring(#outdated) .. " of " .. tostring(installed) .. " outdated", "warn")
            profilesCard:SetAttention(true)
            profilesCard:SetAction("UPDATE PROFILES", "primary", function()
                ns.ShowProfileUpdatePrompt()
            end)
        else
            profilesCard:SetStatus(tostring(installed) .. " of " .. tostring(total) .. " current", "ok")
            profilesCard:SetAttention(false)
            profilesCard:SetAction("APPLY PROFILES", "ghost", function()
                local ok, message = ns.ApplyInstalledProfilesToCharacter(true)
                Print(message)
                if ok then Print("reload UI to finish applying loaded profiles") end
                overview:Refresh()
            end)
        end

        local cooldownStatus, cooldownKind = CooldownVersionStatus()
        cooldownsCard:SetStatus(cooldownStatus, cooldownKind)
        cooldownsCard:SetAttention(cooldownKind == "warn")
        if ns.IS_FOREVER then
            cooldownsCard:SetAction(nil)
        else
            local cooldownAction = cooldownKind == "warn" and cooldownStatus ~= "Not imported" and "UPDATE LAYOUTS" or "IMPORT LAYOUTS"
            cooldownsCard:SetAction(cooldownAction, cooldownKind == "warn" and "primary" or "ghost", function()
                local ok, message = ns.ImportInariCooldownLayouts()
                Print(message or (ok and "cooldown layouts imported" or "cooldown import failed"))
                overview:Refresh()
            end)
        end

        local scaleOk = UIScaleIsCorrect() or InariDB.keepUIScale == true
        if InariDB.installerPendingFinalScale then
            setupCard:SetStatus("Pending final scale", "warn")
            setupCard:SetAttention(true)
            setupCard:SetAction("CONTINUE", "primary", function()
                ns.ShowInstallerFrame()
            end)
        elseif not scaleOk then
            setupCard:SetStatus("UI scale drifted", "warn")
            setupCard:SetAttention(true)
            setupCard:SetAction("APPLY SCALE", "primary", function()
                ns.ApplyInariUIScale(true)
                Print("UI scale applied")
                overview:Refresh()
            end)
        elseif ns.IsInstallerComplete and ns.IsInstallerComplete() then
            setupCard:SetStatus("Install complete", "ok")
            setupCard:SetAttention(false)
            setupCard:SetAction("RUN AGAIN", "ghost", function()
                ns.ShowInstallerFrame()
            end)
        else
            setupCard:SetStatus("Not completed", "warn")
            setupCard:SetAttention(true)
            setupCard:SetAction("RUN INSTALLER", "primary", function()
                ns.ShowInstallerFrame()
            end)
        end
    end

    return overview
end

function ns.ShowConfigFrame(initialTab)
    ns.EnsureDB()
    local ui = UI()
    if not ui then return end

    local State = ns.State

    if not State.configFrame then
        local frame = ui:CreateWindow("InariConfigFrame", UIParent, 900, 640, "overview")
        frame._pages = {}

        frame.content = CreateFrame("Frame", nil, frame.body)
        frame.content:SetAllPoints()

        local builders = {
            appearance = BuildAppearance,
            layout = BuildLayout,
            extras = BuildExtras,
            profiles = BuildProfiles,
            cooldowns = BuildCooldowns,
            setup = BuildSetup,
            install = function(host, widgets)
                return ns.BuildInstallerPage(host, widgets)
            end,
        }

        frame.overview = BuildOverview(frame, ui)

        local function SelectPage(page)
            page = NormalizePage(page)
            if page ~= "overview" and not builders[page] then
                page = "overview"
            end
            frame._selectedPage = page
            if page ~= "install" then
                InariDB.lastConfigPage = page
            end

            if page == "overview" then
                frame:SetContext("overview")
                frame:SetBackVisible(false)
                frame.overview:Show()
                frame.overview:Refresh()
                for _, hosted in pairs(frame._pages) do
                    hosted:Hide()
                end
                return
            end

            frame:SetContext(PAGE_LABELS[page] or page)
            frame:SetBackVisible(true, function()
                SelectPage("overview")
            end)
            frame.overview:Hide()
            if not frame._pages[page] then
                frame._pages[page] = builders[page](frame, ui)
            end
            for id, hosted in pairs(frame._pages) do
                if id == page then
                    hosted:Show()
                    if hosted.Refresh then hosted:Refresh() end
                else
                    hosted:Hide()
                end
            end
        end

        frame.SelectPage = SelectPage
        frame:HookScript("OnShow", function()
            if frame._selectedPage == "overview" and frame.overview and frame.overview.Refresh then
                frame.overview:Refresh()
            elseif frame._pages[frame._selectedPage] and frame._pages[frame._selectedPage].Refresh then
                frame._pages[frame._selectedPage]:Refresh()
            end
            C_Timer.After(0, function()
                if not frame:IsShown() then return end
                if frame._selectedPage == "overview" and frame.overview and frame.overview.Refresh then
                    frame.overview:Refresh()
                elseif frame._pages[frame._selectedPage] and frame._pages[frame._selectedPage].Refresh then
                    frame._pages[frame._selectedPage]:Refresh()
                end
            end)
        end)

        State.configFrame = frame
    end

    local selected
    if initialTab then
        selected = NormalizePage(initialTab)
    else
        local fallback = State.configFrame._selectedPage
        if fallback == "install" then fallback = nil end
        selected = NormalizePage(fallback or InariDB.lastConfigPage or "overview")
        if selected == "install" then selected = "overview" end
    end
    State.configFrame.SelectPage(selected)
    State.configFrame:Show()
end
