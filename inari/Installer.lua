local ADDON_NAME, ns = ...

local function UI()
    return ns.UI or _G.InariUI
end

local function Print(msg)
    ns.Print(msg)
end

local function AddonPresent(name)
    if not name then return true end
    if ns.IsAddonPresent then return ns.IsAddonPresent(name) end
    return true
end

local ROW_HEIGHT = 56
local ROW_GAP = 8

function ns.BuildInstallerPage(configFrame, ui)
    local page = CreateFrame("Frame", nil, configFrame.content)
    page:SetAllPoints()
    page._done = {}
    page._failed = {}
    page._skipped = {}
    page._appearanceMode = ns.GetAppearanceMode()
    page._layoutAspect = ns.GetLayoutAspect and ns.GetLayoutAspect() or "16"

    local steps = {
        {
            title = "BigWigs",
            copy = "Imports the inari BigWigs profile. Accept the BigWigs confirmation popup, then continue.",
            action = "IMPORT BIGWIGS",
            addon = "BigWigs",
            skippable = true,
            async = true,
            run = function()
                return ns.ImportBigWigsProfile(function(accepted)
                    page._busy = false
                    page._done[1] = accepted and true or false
                    page._failed[1] = not accepted
                    page._skipped[1] = not accepted
                    Print(accepted and "BigWigs profile imported as inari" or "BigWigs import cancelled")
                    page._currentIndex = page:NextIncomplete(1) or 1
                    page:RenderChecklist()
                    if accepted then
                        page:SetMuted("BigWigs profile imported as inari")
                    else
                        page:SetStatus(false, "BigWigs import cancelled · skipped")
                    end
                end)
            end,
        },
        {
            title = "EXBoss",
            copy = "Imports the inari EXBoss profile, including appearance and M+ / raid role slots.",
            action = "IMPORT EXBOSS",
            addon = "EXBoss",
            skippable = true,
            run = ns.ImportEXBossProfile,
        },
        {
            title = "sArena",
            copy = "Imports the inari sArena Reloaded profile.",
            action = "IMPORT SARENA",
            addon = "sArena_Reloaded",
            skippable = true,
            run = ns.ImportSArenaProfile,
        },
        {
            title = "Baganator",
            copy = "Imports the inari Baganator bag profile.",
            action = "IMPORT BAGANATOR",
            addon = "Baganator",
            skippable = true,
            run = ns.ImportBaganatorProfile,
        },
        {
            title = "Blizzard Edit Mode",
            copy = "Imports the inari Edit Mode layout. An existing inari layout is removed first so this is repeatable.",
            action = "IMPORT EDIT MODE",
            skippable = true,
            run = ns.ImportEditModeLayout,
        },
        {
            title = "Cooldown Manager",
            copy = "Imports Cooldown Manager layouts for your current class. Existing inari layouts are replaced.",
            action = "IMPORT CDM",
            skippable = true,
            run = ns.ImportInariCooldownLayouts,
        },
        {
            title = "EllesmereUI",
            copy = "Imports both inari EllesmereUI profiles (inari16:9 and inari21:9), then activates the layout you picked. Unit frame patches still apply after this step.",
            action = "IMPORT ELLESMEREUI",
            addon = "EllesmereUI",
            skippable = true,
            run = function()
                return ns.ImportBothEllesmereUIProfiles(page._layoutAspect)
            end,
        },
        {
            title = "Ellesmere Settings",
            copy = "Applies inari's Ellesmere chat, Blizzard UI Enhanced, and Damage Meter settings.",
            action = "APPLY SETTINGS",
            addon = "EllesmereUI",
            skippable = true,
            run = function()
                local ok, message = ns.ApplyEllesmereExtrasSettings()
                if ok then
                    local mode = ns.SetInariAppearanceMode(page._appearanceMode or ns.GetAppearanceMode())
                    local extra = mode == "class" and "appearance set to class colored" or "appearance set to dark mode"
                    message = (message or "settings applied") .. " · " .. extra
                    page:SetMuted(extra)
                end
                return ok, message
            end,
        },
        {
            title = "Initialize Profiles",
            copy = "Reload once so Edit Mode, action bars, cooldowns, and Ellesmere initialize before UI scale.",
            action = "RELOAD UI",
            run = function()
                ns.SetInariAppearanceMode(page._appearanceMode or ns.GetAppearanceMode())
                ns.MarkInstallerPendingFinalScale()
                ReloadUI()
                return true, "Reloading UI"
            end,
        },
        {
            title = "UI Scale",
            copy = "Apply the 0.5333 UI scale, mark the install complete, and reload one final time.",
            action = "APPLY SCALE",
            run = function()
                ns.ApplyInariUIScale(false)
                ns.MarkInstallerCompleted()
                ns.MarkProfilePromptApplied()
                ReloadUI()
                return true, "Reloading UI"
            end,
        },
    }

    local function StepAvailable(step)
        return AddonPresent(step.addon)
    end

    function page:VisibleSteps()
        local list = {}
        for index, step in ipairs(steps) do
            if StepAvailable(step) then
                list[#list + 1] = { index = index, step = step }
            end
        end
        return list
    end

    function page:NextIncomplete(afterIndex)
        afterIndex = afterIndex or 0
        for _, entry in ipairs(self:VisibleSteps()) do
            if entry.index > afterIndex and not self._done[entry.index] and not self._skipped[entry.index] then
                return entry.index
            end
        end
        return nil
    end

    function page:FirstIncomplete()
        return self:NextIncomplete(0)
    end

    local welcome = CreateFrame("Frame", nil, page)
    welcome:SetAllPoints()

    welcome.header = ui:CreateText(welcome, "Install inari", 20, "text", "bold")
    welcome.header:SetPoint("TOPLEFT", 0, 0)
    welcome.header:SetPoint("RIGHT", 0, 0)

    welcome.description = ui:CreateText(welcome, "Imports inari profiles into supported addons. Missing addons are skipped. Pick 16:9 or 21:9 for EllesmereUI; both profiles are imported so you can switch later. Appearance is applied after import.", 12, "muted", "semibold")
    welcome.description:SetPoint("TOPLEFT", welcome.header, "BOTTOMLEFT", 0, -8)
    welcome.description:SetPoint("RIGHT", 0, 0)
    welcome.description:SetWordWrap(true)

    welcome.footer = CreateFrame("Frame", nil, welcome)
    welcome.footer:SetPoint("BOTTOMLEFT", 0, 0)
    welcome.footer:SetPoint("BOTTOMRIGHT", 0, 0)
    welcome.footer:SetHeight(40)

    welcome.notNow = ui:CreateGhostButton(welcome.footer, "NOT NOW")
    welcome.notNow:SetSize(140, 36)
    welcome.notNow:SetPoint("LEFT")
    welcome.notNow:SetOnClick(function()
        configFrame.SelectPage("overview")
    end)

    welcome.start = ui:CreatePrimaryButton(welcome.footer, "START INSTALL")
    welcome.start:SetSize(180, 36)
    welcome.start:SetPoint("RIGHT")
    welcome.start:SetOnClick(function()
        if ns.SetLayoutAspect then
            ns.SetLayoutAspect(page._layoutAspect or ns.GetLayoutAspect())
        end
        page._currentIndex = page:FirstIncomplete() or #steps
        page:ShowChecklist()
    end)

    welcome.grid = CreateFrame("Frame", nil, welcome)
    welcome.grid:SetPoint("TOPLEFT", welcome.description, "BOTTOMLEFT", 0, -18)
    welcome.grid:SetPoint("BOTTOMRIGHT", welcome.footer, "TOPRIGHT", 0, 16)

    local function MakeCard(title, icon)
        local card = ui:CreateDashboardCard(welcome.grid)
        card:SetTitle(title)
        card:SetIcon(icon)
        return card
    end

    local profilesCard = MakeCard("Profiles", ui.Media.IconProfiles)
    local blizzardCard = MakeCard("Blizzard", ui.Media.IconCooldowns)
    local ellesmereCard = MakeCard("EllesmereUI", ui.Media.IconInstaller)
    local appearanceCard = MakeCard("Appearance", ui.Media.IconAppearance)

    local layoutControl = ui:CreateSegmentedControl(ellesmereCard.controlHost, {
        { label = "16:9", value = "16", width = 80, height = 26 },
        { label = "21:9", value = "21", width = 80, height = 26 },
    })
    layoutControl:SetOnChanged(function(_, aspect)
        page._layoutAspect = aspect
        if ns.SetLayoutAspect then ns.SetLayoutAspect(aspect) end
        ellesmereCard:SetStatus(ns.GetEllesmereLayoutProfileName and ns.GetEllesmereLayoutProfileName(aspect) or ((ns.GetLayoutAspectLabel and ns.GetLayoutAspectLabel(aspect) or aspect) .. " layout"))
    end)
    ellesmereCard:AttachControl(layoutControl)

    local appearanceControl = ui:CreateSegmentedControl(appearanceCard.controlHost, {
        { label = "Dark", value = "dark", width = 80, height = 26 },
        { label = "Class", value = "class", width = 80, height = 26 },
    })
    appearanceControl:SetOnChanged(function(_, mode)
        page._appearanceMode = mode
        appearanceCard:SetStatus(mode == "class" and "Class Colored" or "Dark Mode")
    end)
    appearanceCard:AttachControl(appearanceControl)

    local relayoutWelcome = ui:LayoutCardGrid(welcome.grid, {
        profilesCard,
        blizzardCard,
        ellesmereCard,
        appearanceCard,
    }, 2, 12)

    local function RefreshWelcomeCards()
        profilesCard:SetStatusLines({
            { text = "BigWigs", on = AddonPresent("BigWigs") },
            { text = "EXBoss", on = AddonPresent("EXBoss") },
            { text = "sArena Reloaded", on = AddonPresent("sArena_Reloaded") },
            { text = "Baganator", on = AddonPresent("Baganator") },
        })
        blizzardCard:SetStatusLines({
            { text = "Edit Mode", on = true },
            { text = "Cooldown Manager", on = true },
        })
        local aspect = page._layoutAspect or (ns.GetLayoutAspect and ns.GetLayoutAspect()) or "16"
        page._layoutAspect = aspect
        if AddonPresent("EllesmereUI") then
            ellesmereCard:SetStatus(ns.GetEllesmereLayoutProfileName and ns.GetEllesmereLayoutProfileName(aspect) or ((ns.GetLayoutAspectLabel and ns.GetLayoutAspectLabel(aspect) or aspect) .. " layout"))
        else
            ellesmereCard:SetStatus("EllesmereUI missing", "warn")
        end
        layoutControl:SetValue(aspect, true)
        local mode = page._appearanceMode or ns.GetAppearanceMode()
        appearanceCard:SetStatus(mode == "class" and "Class Colored" or "Dark Mode")
        appearanceControl:SetValue(mode, true)
        if relayoutWelcome then relayoutWelcome() end
    end

    local checklist = CreateFrame("Frame", nil, page)
    checklist:SetAllPoints()
    checklist:Hide()

    checklist.header = ui:CreateText(checklist, "Install", 20, "text", "bold")
    checklist.header:SetPoint("TOPLEFT", 0, 0)
    checklist.header:SetPoint("RIGHT", 0, 0)

    checklist.description = ui:CreateText(checklist, "Run these in order. Missing addons are skipped.", 12, "muted", "semibold")
    checklist.description:SetPoint("TOPLEFT", checklist.header, "BOTTOMLEFT", 0, -8)
    checklist.description:SetPoint("RIGHT", 0, 0)

    checklist.progress = CreateFrame("Frame", nil, checklist)
    checklist.progress:SetPoint("TOPLEFT", checklist.description, "BOTTOMLEFT", 0, -14)
    checklist.progress:SetPoint("TOPRIGHT", checklist.description, "BOTTOMRIGHT", 0, -14)
    checklist.progress:SetHeight(18)

    checklist.progressTrack = CreateFrame("Frame", nil, checklist.progress)
    checklist.progressTrack:SetPoint("LEFT")
    checklist.progressTrack:SetPoint("RIGHT", -64, 0)
    checklist.progressTrack:SetHeight(4)
    ui:SetFrameColor(checklist.progressTrack, ui.Theme.row)

    checklist.progressFill = checklist.progressTrack:CreateTexture(nil, "ARTWORK")
    checklist.progressFill:SetPoint("TOPLEFT")
    checklist.progressFill:SetPoint("BOTTOMLEFT")
    checklist.progressFill:SetColorTexture(ui.Theme.accent[1], ui.Theme.accent[2], ui.Theme.accent[3], 1)

    checklist.progressText = ui:CreateText(checklist.progress, "", 12, "text", "bold")
    checklist.progressText:SetPoint("RIGHT")
    checklist.progressText:SetJustifyH("RIGHT")

    checklist.toast = ui:CreateStatusRow(checklist)
    checklist.toast:SetPoint("BOTTOMLEFT", 0, 0)
    checklist.toast:SetPoint("BOTTOMRIGHT", 0, 0)
    checklist.toast:SetHeight(34)
    checklist.toast:Hide()

    local scrollFrame, scrollChild = ui:CreateScrollArea(checklist)
    scrollFrame:SetPoint("TOPLEFT", checklist.progress, "BOTTOMLEFT", 0, -14)
    scrollFrame:SetPoint("BOTTOMRIGHT", checklist.toast, "TOPRIGHT", 0, 12)

    local toastTimer
    local function ShowToast(setter, a, b)
        setter(checklist.toast, a, b)
        if toastTimer then toastTimer:Cancel() end
        toastTimer = C_Timer.NewTimer(3.5, function()
            if checklist.toast then checklist.toast:Hide() end
        end)
    end

    function page:SetStatus(ok, message)
        ShowToast(checklist.toast.SetStatus, ok, message)
    end

    function page:SetMuted(message)
        ShowToast(checklist.toast.SetMuted, message)
    end

    page._rows = {}
    for index, step in ipairs(steps) do
        local row = ui:CreateStepRow(scrollChild)
        row:SetTitle(step.title)
        row:SetCopy(step.copy)
        row:Hide()
        page._rows[index] = row
    end

    local function RefreshProgress(visibleIndex, total)
        local ratio = total > 0 and visibleIndex / total or 0
        checklist.progressText:SetText(tostring(visibleIndex) .. " / " .. tostring(total))
        local width = checklist.progressTrack:GetWidth() or 0
        checklist.progressFill:SetWidth(math.max(1, width * math.max(ratio, 0.04)))
    end

    checklist.progressTrack:SetScript("OnSizeChanged", function()
        local visible = page:VisibleSteps()
        local current = page._currentIndex or page:FirstIncomplete() or #steps
        local visibleIndex = 1
        for i, entry in ipairs(visible) do
            if entry.index == current then
                visibleIndex = i
                break
            end
        end
        RefreshProgress(visibleIndex, #visible)
    end)

    local function SkipStep(index, message)
        local step = steps[index]
        if not step then return end
        page._busy = false
        page._done[index] = false
        page._skipped[index] = true
        page._failed[index] = true
        page._currentIndex = page:NextIncomplete(index) or index
        if message and message ~= "" then
            page:SetStatus(false, message)
            Print(message)
        else
            page:SetMuted((step.title or "step") .. " skipped")
        end
        page:RenderChecklist()
    end

    local function RunStep(index, again)
        local step = steps[index]
        if not step or page._busy then return end
        if not StepAvailable(step) then
            SkipStep(index, (step.title or "addon") .. " is not available · skipped")
            return
        end

        if not step.run then
            page._done[index] = true
            page._skipped[index] = nil
            page._currentIndex = page:NextIncomplete(index) or index
            page:RenderChecklist()
            return
        end

        page._busy = true
        page:RenderChecklist()
        local ok, message = step.run()
        if step.async then
            if not ok then
                if step.skippable then
                    SkipStep(index, (message or "installer step failed") .. " · skipped")
                else
                    page._busy = false
                    page._failed[index] = true
                    page._done[index] = false
                    Print(message or "installer step failed")
                    page:SetStatus(false, message or "installer step failed")
                    page:RenderChecklist()
                end
            end
            return
        end

        page._busy = false
        if ok then
            page._done[index] = true
            page._failed[index] = false
            page._skipped[index] = nil
            Print(message or "installer step completed")
            page:SetMuted(message or "completed")
            if not again then
                page._currentIndex = page:NextIncomplete(index) or index
            end
        elseif step.skippable then
            SkipStep(index, (message or "installer step failed") .. " · skipped")
            return
        else
            page._done[index] = false
            page._failed[index] = true
            Print(message or "installer step failed")
            page:SetStatus(false, message or "installer step failed")
        end
        page:RenderChecklist()
    end

    local rendering
    function page:RenderChecklist()
        if rendering then return end
        rendering = true

        local visible = self:VisibleSteps()
        if self._done[self._currentIndex] or self._skipped[self._currentIndex] or not self._currentIndex then
            self._currentIndex = self:FirstIncomplete() or (visible[#visible] and visible[#visible].index)
        end

        local y = 0
        local visibleIndex = #visible
        for i, entry in ipairs(visible) do
            local index = entry.index
            local step = entry.step
            local row = self._rows[index]
            local done = self._done[index] == true
            local skipped = self._skipped[index] == true
            local failed = self._failed[index] == true
            local current = index == self._currentIndex and not done and not skipped

            if entry.index == self._currentIndex then
                visibleIndex = i
            end

            local state = "waiting"
            if done then
                state = "completed"
            elseif skipped then
                state = "skipped"
            elseif failed then
                state = "failed"
            elseif current then
                state = "current"
            end
            row:SetState(state)

            if current then
                row:SetAction(step.action, "primary", function()
                    RunStep(index, false)
                end)
                row.action:SetEnabledState(not self._busy)
                row:SetSkip(step.skippable == true, function()
                    SkipStep(index)
                end)
                row.skip:SetEnabledState(not self._busy)
            elseif done or skipped then
                row:SetAction("RUN AGAIN", "ghost", function()
                    RunStep(index, true)
                end)
                row.action:SetEnabledState(not self._busy)
                row:SetSkip(false)
            else
                row:SetAction(nil)
                row:SetSkip(false)
            end

            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", 0, -y)
            row:SetPoint("TOPRIGHT", 0, -y)
            row:Show()
            y = y + ROW_HEIGHT + ROW_GAP
        end

        for index, step in ipairs(steps) do
            if not StepAvailable(step) then
                self._rows[index]:Hide()
            end
        end

        RefreshProgress(visibleIndex, #visible)
        scrollFrame:SetContentHeight(math.max(1, y - ROW_GAP))
        rendering = false
    end

    function page:UpdateBack()
        if self._stage == "checklist" then
            configFrame:SetBackVisible(true, function()
                self:ShowWelcome()
            end)
        elseif ns.IsInstallerComplete and ns.IsInstallerComplete() then
            configFrame:SetBackVisible(true, function()
                configFrame.SelectPage("overview")
            end)
        else
            configFrame:SetBackVisible(false)
        end
    end

    function page:ShowWelcome()
        self._stage = "welcome"
        checklist:Hide()
        welcome:Show()
        RefreshWelcomeCards()
        self:UpdateBack()
    end

    function page:ShowChecklist()
        self._stage = "checklist"
        welcome:Hide()
        checklist:Show()
        if not self._currentIndex then
            self._currentIndex = self:FirstIncomplete() or #steps
        end
        self:RenderChecklist()
        self:UpdateBack()
    end

    checklist:SetScript("OnSizeChanged", function()
        if page._stage == "checklist" then
            page:RenderChecklist()
        end
    end)

    function page:PrepareResumeAtScale()
        local last = #steps
        for index, step in ipairs(steps) do
            if index < last then
                self._done[index] = StepAvailable(step)
            end
        end
        self._currentIndex = last
        self._failed = {}
    end

    function page:Refresh()
        ns.EnsureDB()
        page._appearanceMode = page._appearanceMode or ns.GetAppearanceMode()
        page._layoutAspect = page._layoutAspect or (ns.GetLayoutAspect and ns.GetLayoutAspect()) or "16"
        if InariDB.installerPendingFinalScale then
            self:PrepareResumeAtScale()
            self:ShowChecklist()
        elseif ns.IsInstallerComplete and ns.IsInstallerComplete() and self._stage ~= "checklist" then
            self:ShowWelcome()
        elseif self._stage == "checklist" then
            self:ShowChecklist()
        else
            self:ShowWelcome()
        end
    end

    page:Hide()
    return page
end

function ns.ShowInstallerFrame()
    ns.ShowConfigFrame("install")
end

function ns.ShowInstalledProfilesPrompt()
    if InCombatLockdown and InCombatLockdown() then return end
    if not ns.ShouldOfferInstalledProfiles() then return end

    local ui = UI()
    if not ui then return end
    local State = ns.State

    if not State.installedProfilesPromptFrame then
        local frame = ui:CreateDialog("InariInstalledProfilesPromptFrame", 500, 300, "profiles")
        frame:SetHeading("Profiles installed")
        frame:SetCopy("Apply inari's installed profiles to this character and reload the UI?")
        frame.primaryButton:SetLabel("Apply & Reload")
        frame.secondaryButton:SetLabel("Not Now")

        local function Dismiss()
            ns.MarkProfilePromptDismissed()
            frame:Hide()
        end

        frame:SetOnClose(Dismiss)
        frame.secondaryButton:SetOnClick(Dismiss)
        frame.primaryButton:SetOnClick(function()
            local ok, message = ns.ApplyInstalledProfilesToCharacter(true)
            Print(message)
            if ok then
                ReloadUI()
                return
            end
            frame:SetDialogStatus(false, message or "No installed profiles were applied.")
        end)

        State.installedProfilesPromptFrame = frame
    end

    State.installedProfilesPromptFrame:SetDialogStatus(true, "")
    State.installedProfilesPromptFrame:Show()
end

function ns.ShowProfileUpdatePrompt()
    if InCombatLockdown and InCombatLockdown() then return end

    local outdated = ns.GetOutdatedInstalledProfiles()
    if #outdated == 0 then return end

    local ui = UI()
    if not ui then return end
    local State = ns.State

    local labelList = ns.FormatProfileLabelList(outdated)
    local copyText
    if #outdated == 1 then
        copyText = labelList .. " has been updated.\n\nReimport it to get the latest version?"
    else
        copyText = labelList .. " have been updated.\n\nReimport them to get the latest versions?"
    end

    if not State.profileUpdatePromptFrame then
        local frame = ui:CreateDialog("InariProfileUpdatePromptFrame", 520, 340, "profiles")
        frame:SetHeading("Profiles updated")
        frame.primaryButton:SetLabel("Reimport & Reload")
        frame.secondaryButton:SetLabel("Not Now")
        State.profileUpdatePromptFrame = frame
    end

    local frame = State.profileUpdatePromptFrame
    frame._outdatedProfiles = outdated
    frame:SetCopy(copyText)
    frame:SetDialogStatus(true, "")

    local function Dismiss()
        State.profileUpdatePromptDismissedThisSession = true
        frame:Hide()
    end

    frame:SetOnClose(Dismiss)
    frame.secondaryButton:SetOnClick(Dismiss)
    frame.primaryButton:SetOnClick(function()
        local current = frame._outdatedProfiles or {}
        frame:SetDialogStatus(true, "Reimporting updated profiles...")
        ns.ReimportOutdatedProfiles(current, function(ok, message, shouldReload)
            Print(message)
            if shouldReload and ok then
                ReloadUI()
                return
            end
            frame:SetDialogStatus(ok, message or "Reimport finished.")
            if ok then
                frame:Hide()
            end
        end)
    end)

    frame:Show()
end
