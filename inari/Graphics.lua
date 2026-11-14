local ADDON_NAME, ns = ...

local MAX_USER_PRESETS = 8
local MAX_NAME_LENGTH = 20
local DEFAULT_BUTTON_POSITION = { "CENTER", "CENTER", 0, -220 }

local BUILTIN_PRESETS = {
    { id = "fps", label = "FPS Settings", cvars = ns.FPS_CVARS, builtin = true },
    { id = "inari", label = "Inari Graphics", cvars = ns.INARI_GRAPHICS_CVARS, builtin = true },
}
local PRESET_ALIASES = { inaris = "inari", ["inari's"] = "inari" }
-- Words the slash command reads as an action, so no preset may be named after them.
local RESERVED_NAMES = {
    next = true, toggle = true, cycle = true, swap = true, list = true,
    save = true, add = true, delete = true, remove = true, button = true,
    inaris = true, ["inari's"] = true,
}

-- Every CVar a built-in preset touches; a saved preset snapshots exactly these.
local SNAPSHOT_CVARS = {}
do
    local seen = {}
    for _, preset in ipairs(BUILTIN_PRESETS) do
        for _, cvar in ipairs(preset.cvars) do
            if not seen[cvar[1]] then
                seen[cvar[1]] = true
                SNAPSHOT_CVARS[#SNAPSHOT_CVARS + 1] = cvar[1]
            end
        end
    end
end

local listeners = {}
local swapButton
local lastDragStop

local function Print(msg)
    ns.Print(msg)
end

-- Built-ins first, then the user's own presets in the order they were saved.
local function GetPresets()
    ns.EnsureDB()
    local list = {}
    for index, preset in ipairs(BUILTIN_PRESETS) do
        list[index] = preset
    end
    for _, saved in ipairs(InariDB.graphicsPresets) do
        if type(saved) == "table" and type(saved.name) == "string" and type(saved.cvars) == "table" then
            list[#list + 1] = { id = string.lower(saved.name), label = saved.name, cvars = saved.cvars }
        end
    end
    return list
end

local function FindPreset(id, presets)
    if type(id) ~= "string" then return nil end
    id = string.lower(id)
    id = PRESET_ALIASES[id] or id
    for index, preset in ipairs(presets or GetPresets()) do
        if preset.id == id then return preset, index end
    end
    return nil
end

local function PresetMatches(cvars)
    for _, cvar in ipairs(cvars) do
        if tostring(ns.GetInariCVar(cvar[1])) ~= tostring(cvar[2]) then
            return false
        end
    end
    return true
end

-- Last applied preset if it still exists, otherwise whichever preset the live CVars match.
local function GetCurrentPreset(presets)
    presets = presets or GetPresets()
    local preset, index = FindPreset(InariDB.graphicsPreset, presets)
    if preset then return preset, index end
    for position, candidate in ipairs(presets) do
        if PresetMatches(candidate.cvars) then return candidate, position end
    end
    return nil
end

local function RefreshButton()
    ns.EnsureDB()
    if InariDB.graphicsButton ~= true then
        if swapButton then swapButton:Hide() end
        return
    end

    local ui = ns.UI
    if not swapButton then
        swapButton = CreateFrame("Frame", "InariGraphicsButton", UIParent)
        swapButton:SetFrameStrata("MEDIUM")
        swapButton:SetMovable(true)
        swapButton:SetClampedToScreen(true)
        ui:SetFrameColor(swapButton, ui.Theme.bg)

        local button = ui:CreateGhostButton(swapButton, "")
        button:SetAllPoints()
        button:RegisterForDrag("LeftButton")
        button:SetScript("OnDragStart", function()
            swapButton:StartMoving()
        end)
        button:SetScript("OnDragStop", function()
            swapButton:StopMovingOrSizing()
            lastDragStop = GetTime()
            local point, _, relativePoint, x, y = swapButton:GetPoint(1)
            InariDB.graphicsButtonPosition = { point, relativePoint, x, y }
        end)
        button:SetOnClick(function()
            -- Releasing a drag over the button must not also swap the preset.
            if lastDragStop == GetTime() then return end
            local _, message = ns.CycleGraphicsPreset()
            Print(message)
        end)
        button:HookScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:AddLine("inari graphics")
            GameTooltip:AddLine("Click: next preset", 1, 1, 1)
            GameTooltip:AddLine("Drag: move", 1, 1, 1)
            GameTooltip:Show()
        end)
        button:HookScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        swapButton.button = button
    end

    local position = InariDB.graphicsButtonPosition
    if type(position) ~= "table" or type(position[1]) ~= "string" or type(position[2]) ~= "string"
        or type(position[3]) ~= "number" or type(position[4]) ~= "number" then
        position = DEFAULT_BUTTON_POSITION
    end
    swapButton:ClearAllPoints()
    swapButton:SetPoint(position[1], UIParent, position[2], position[3], position[4])

    local current = GetCurrentPreset()
    swapButton.button:SetLabel(current and current.label or "Graphics: custom")
    swapButton:SetSize(math.max(120, (swapButton.button.label:GetStringWidth() or 0) + 28), 28)
    swapButton:Show()
end

local function NotifyChanged()
    RefreshButton()
    for _, listener in ipairs(listeners) do
        listener()
    end
end

-- Returns ok, message. In combat the CVars wait for combat to end; a later swap replaces the queued one.
local function ApplyPreset(id)
    local preset = FindPreset(id)
    if not preset then
        return false, "no graphics preset named \"" .. tostring(id) .. "\""
    end

    InariDB.graphicsPreset = preset.id
    local applied, skipped
    local ran = ns.RunAfterCombat("graphicsPreset", function()
        applied, skipped = ns.ApplyCVarTable(preset.cvars)
    end)
    NotifyChanged()
    return true, ns.FormatCVarResult("graphics preset \"" .. preset.label .. "\" applied: ", applied or 0, skipped or 0, not ran)
end

local function CyclePreset()
    local presets = GetPresets()
    local _, index = GetCurrentPreset(presets)
    local nextPreset = presets[(index or 0) % #presets + 1]
    return ApplyPreset(nextPreset.id)
end

-- Saves the live graphics CVars under name; an existing preset of that name is overwritten.
local function SavePreset(name)
    ns.EnsureDB()
    name = tostring(name or ""):gsub("|", ""):gsub("%s+", " "):match("^%s*(.-)%s*$")
    if name == "" then
        return false, "enter a name for the graphics preset"
    end
    if #name > MAX_NAME_LENGTH then
        return false, "graphics preset names are limited to " .. MAX_NAME_LENGTH .. " characters"
    end

    local id = string.lower(name)
    local existing = FindPreset(id)
    if RESERVED_NAMES[id:match("^%S+")] or (existing and existing.builtin) then
        return false, "\"" .. name .. "\" is reserved, pick another name"
    end

    local cvars = {}
    for _, cvar in ipairs(SNAPSHOT_CVARS) do
        local value = ns.GetInariCVar(cvar)
        if value ~= nil then
            cvars[#cvars + 1] = { cvar, tostring(value) }
        end
    end

    local saved = InariDB.graphicsPresets
    local slot
    for index, entry in ipairs(saved) do
        if type(entry) == "table" and type(entry.name) == "string" and string.lower(entry.name) == id then
            slot = index
            break
        end
    end
    if not slot and #saved >= MAX_USER_PRESETS then
        return false, "only " .. MAX_USER_PRESETS .. " own graphics presets fit, delete one first"
    end
    saved[slot or (#saved + 1)] = { name = name, cvars = cvars }

    InariDB.graphicsPreset = id
    NotifyChanged()
    return true, "graphics preset \"" .. name .. "\" " .. (slot and "updated" or "saved") .. ": " .. #cvars .. " CVars"
end

local function DeletePreset(id)
    ns.EnsureDB()
    local preset = FindPreset(id)
    if not preset then
        return false, "no graphics preset named \"" .. tostring(id) .. "\""
    end
    if preset.builtin then
        return false, "\"" .. preset.label .. "\" is built in and cannot be deleted"
    end

    local saved = InariDB.graphicsPresets
    for index, entry in ipairs(saved) do
        if type(entry) == "table" and type(entry.name) == "string" and string.lower(entry.name) == preset.id then
            tremove(saved, index)
            break
        end
    end
    if InariDB.graphicsPreset == preset.id then InariDB.graphicsPreset = nil end
    NotifyChanged()
    return true, "graphics preset \"" .. preset.label .. "\" deleted"
end

local function SetButtonShown(shown)
    ns.EnsureDB()
    InariDB.graphicsButton = shown and true or nil
    RefreshButton()
    return shown and "graphics swap button shown; drag it to move" or "graphics swap button hidden"
end

local function PrintPresets()
    local presets = GetPresets()
    local current = GetCurrentPreset(presets)
    local names = {}
    for index, preset in ipairs(presets) do
        names[index] = preset.builtin and preset.id or preset.label
    end
    Print("graphics preset: " .. (current and current.label or "custom") .. " (available: " .. table.concat(names, ", ") .. ")")
    Print("usage: /inari graphics next|<name>|save <name>|delete <name>|button on|off")
end

local function HandleCommand(arg)
    arg = tostring(arg or ""):match("^%s*(.-)%s*$")
    local word, rest = arg:match("^(%S*)%s*(.-)$")
    word = string.lower(word)

    local _, message
    if word == "" or word == "list" then
        PrintPresets()
        return
    elseif word == "next" or word == "toggle" or word == "cycle" or word == "swap" then
        _, message = CyclePreset()
    elseif word == "save" or word == "add" then
        _, message = SavePreset(rest)
    elseif word == "delete" or word == "remove" then
        _, message = DeletePreset(rest)
    elseif word == "button" then
        rest = string.lower(rest)
        if rest == "on" or rest == "off" then
            message = SetButtonShown(rest == "on")
        elseif rest == "" then
            message = SetButtonShown(InariDB.graphicsButton ~= true)
        else
            message = "usage: /inari graphics button on|off"
        end
    else
        _, message = ApplyPreset(arg)
    end
    Print(message)
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", RefreshButton)

ns.GetGraphicsPresets = GetPresets
ns.GetCurrentGraphicsPreset = GetCurrentPreset
ns.ApplyGraphicsPreset = ApplyPreset
ns.CycleGraphicsPreset = CyclePreset
ns.SaveGraphicsPreset = SavePreset
ns.DeleteGraphicsPreset = DeletePreset
ns.SetGraphicsButtonShown = SetButtonShown
ns.RefreshGraphicsButton = RefreshButton
ns.HandleGraphicsCommand = HandleCommand

-- fn runs whenever the preset list or the active preset changes.
function ns.OnGraphicsPresetsChanged(fn)
    listeners[#listeners + 1] = fn
end
