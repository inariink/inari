local ADDON_NAME, ns = ...

local MASK_FILE = "Interface\\AddOns\\EllesmereUI\\media\\portraits\\circle_mask.tga"
local RING_FILE = "Interface\\AddOns\\EllesmereUI\\media\\portraits\\circle_border.tga"
local FILL_FILE = "Interface\\Buttons\\WHITE8X8"
local SHADOW_FILE = "Interface\\AddOns\\inari\\Media\\portrait-shadow.png"
local INNER_SHADOW_FILE = "Interface\\AddOns\\inari\\Media\\portrait-inner-shadow.png"
local HIGHLIGHT_FILE = "Interface\\AddOns\\inari\\Media\\portrait-highlight.png"

local UNITS = { "player", "target" }
local UNIT_EVENTS = {
    player = {
        "UNIT_PORTRAIT_UPDATE",
        "PORTRAITS_UPDATED",
        "UNIT_MODEL_CHANGED",
        "UNIT_CONNECTION",
        "UNIT_ENTERED_VEHICLE",
        "UNIT_EXITING_VEHICLE",
        "UNIT_EXITED_VEHICLE",
        "VEHICLE_UPDATE",
    },
    target = {
        "UNIT_PORTRAIT_UPDATE",
        "PORTRAITS_UPDATED",
        "UNIT_MODEL_CHANGED",
        "UNIT_CONNECTION",
        "PLAYER_TARGET_CHANGED",
        "INSTANCE_ENCOUNTER_ENGAGE_UNIT",
    },
}

local portraits = {}
local parentRetries = 0
local MAX_PARENT_RETRIES = 16
local MAX_TEXTURE_TRIES = 10
local IsUnitModelReadyForUI = IsUnitModelReadyForUI or function() return true end
local ShouldUnitIdentityBeSecret = _G.C_Secrets and _G.C_Secrets.ShouldUnitIdentityBeSecret

local function DB()
    ns.EnsureDB()
    return InariDB.portraits
end

local function OppositeAnchor(anchor)
    if anchor == "LEFT" then return "RIGHT" end
    if anchor == "RIGHT" then return "LEFT" end
    return "CENTER"
end

local function SafeValue(value)
    if issecretvalue and issecretvalue(value) then return nil end
    return value
end

local function IsSecretUnit(unit)
    return unit and ShouldUnitIdentityBeSecret and ShouldUnitIdentityBeSecret(unit) or false
end

local function UnitEnabled(unit)
    local db = DB()
    local unitDB = db and db[unit]
    return db and db.enabled == true and unitDB and unitDB.enable ~= false
end

local function ParentFrame(unit)
    local names = ns.FRAME_NAMES
    local name = names and names[unit]
    return name and _G[name]
end

local function ApplyMirror(texture, mirror)
    if mirror then
        texture:SetTexCoord(1, 0, 0, 1)
    else
        texture:SetTexCoord(0, 1, 0, 1)
    end
end

local function RingColor(unit)
    if not IsSecretUnit(unit) and UnitIsPlayer(unit) then
        local _, class = UnitClass(unit)
        class = SafeValue(class)
        local color = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
        if color then return color.r, color.g, color.b end
    end
    local reaction = SafeValue(UnitReaction(unit, "player"))
    local colors = FACTION_BAR_COLORS
    local color = reaction and colors and colors[reaction]
    if color then return color.r, color.g, color.b end
    return 1, 1, 1
end

-- Returns true when a previously suppressed portrait was released.
local function SetUnitFramePortraitSuppressed(parent, suppressed)
    if not parent then return false end
    local wasSuppressed = parent._inariPortraitSuppressed == true
    if not suppressed and not wasSuppressed then return false end
    parent._inariPortraitSuppressed = suppressed and true or nil
    local portrait = parent.Portrait
    local backdrop = portrait and portrait.backdrop
    local function HookHide(frame)
        if not frame or frame._inariPortraitHooked then return end
        frame._inariPortraitHooked = true
        hooksecurefunc(frame, "Show", function(self)
            if self._inariSuppressLock then return end
            if self._inariWantPortraitHidden then
                self._inariSuppressLock = true
                self:Hide()
                self._inariSuppressLock = nil
            end
        end)
    end
    local function Apply(frame)
        if not frame or type(frame.Hide) ~= "function" then return end
        HookHide(frame)
        frame._inariWantPortraitHidden = suppressed and true or false
        if suppressed then
            frame:Hide()
            if frame.SetAlpha then frame:SetAlpha(0) end
        elseif frame.SetAlpha then
            -- Only undo our own hiding; Ellesmere's reload decides what shows.
            frame:SetAlpha(1)
        end
    end
    local function ApplyTree(frame)
        if not frame then return end
        Apply(frame)
        if frame.GetRegions then
            local regions = { frame:GetRegions() }
            for _, region in ipairs(regions) do
                Apply(region)
            end
        end
        if frame.GetChildren then
            local children = { frame:GetChildren() }
            for _, child in ipairs(children) do
                ApplyTree(child)
            end
        end
    end
    Apply(portrait)
    ApplyTree(backdrop)
    if type(parent.DisableElement) == "function" and suppressed then
        pcall(parent.DisableElement, parent, "Portrait")
    end
    return wasSuppressed and not suppressed
end

local function ApplyMask(frame)
    if not frame.mask then return end
    frame.mask:ClearAllPoints()
    frame.mask:SetAllPoints(frame.face)
    frame.mask:SetTexture(MASK_FILE, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    frame.mask:Show()
    if frame.photo then
        pcall(frame.photo.RemoveMaskTexture, frame.photo, frame.mask)
        frame.photo:AddMaskTexture(frame.mask)
    end
    if frame.bg then
        pcall(frame.bg.RemoveMaskTexture, frame.bg, frame.mask)
        frame.bg:AddMaskTexture(frame.mask)
    end
    if frame.innerShadow then
        pcall(frame.innerShadow.RemoveMaskTexture, frame.innerShadow, frame.mask)
        frame.innerShadow:AddMaskTexture(frame.mask)
    end
end

local function ApplyZoom(frame)
    local db = DB()
    local zoom = tonumber(db and db.zoom) or 0.22
    local size = tonumber(db and db.size) or 52
    local offset = (size / 2) * zoom
    frame.photo:ClearAllPoints()
    frame.photo:SetPoint("TOPLEFT", frame.face, "TOPLEFT", -offset, offset)
    frame.photo:SetPoint("BOTTOMRIGHT", frame.face, "BOTTOMRIGHT", offset, -offset)
end

local function LayoutPortrait(frame)
    local db = DB()
    local unitDB = db[frame.unit]
    local size = tonumber(db.size) or 52
    local anchor = unitDB and unitDB.anchor or (frame.unit == "target" and "RIGHT" or "LEFT")
    local x = unitDB and tonumber(unitDB.x) or 0
    local y = unitDB and tonumber(unitDB.y) or 0
    local parent = frame:GetParent()
    if not parent then return end

    frame:SetSize(size / 2, size / 2)
    frame.face:SetSize(size, size)
    frame:ClearAllPoints()
    frame:SetPoint(OppositeAnchor(anchor), parent, anchor, x, y)
    frame:SetFrameLevel(tonumber(db.level) or 20)
    if frame.shadow then
        frame.shadow:ClearAllPoints()
        frame.shadow:SetPoint("CENTER", frame.face, "CENTER", 1.5, -2.5)
        frame.shadow:SetSize(size * 1.16, size * 1.16)
    end
    if frame.ringLip then
        frame.ringLip:ClearAllPoints()
        frame.ringLip:SetPoint("TOPLEFT", frame.face, "TOPLEFT", -1.2, 1.2)
        frame.ringLip:SetPoint("BOTTOMRIGHT", frame.face, "BOTTOMRIGHT", 1.2, -1.2)
    end
    ApplyMask(frame)
    ApplyZoom(frame)
end

local function CancelRetry(frame)
    if frame.textureRetry then
        frame.textureRetry:Cancel()
        frame.textureRetry = nil
    end
end

local UpdatePhoto

local function RetryTexture(frame)
    if frame.textureRetry or not frame:IsVisible() then return end
    if (frame.textureTries or 0) >= MAX_TEXTURE_TRIES then return end
    frame.textureTries = (frame.textureTries or 0) + 1
    frame.textureRetry = C_Timer.NewTimer(0.2, function()
        frame.textureRetry = nil
        if frame:IsShown() then
            UpdatePhoto(frame, true)
        end
    end)
end

UpdatePhoto = function(frame, force)
    local unit = frame.unit
    if not UnitExists(unit) then
        frame:Hide()
        return
    end

    frame:Show()
    local secret = IsSecretUnit(unit)
    local guid = UnitGUID(unit)
    guid = (issecretvalue and issecretvalue(guid)) and " " or guid
    local ready = (IsUnitModelReadyForUI(unit) and SafeValue(UnitIsConnected(unit)) and SafeValue(UnitIsVisible(unit))) or false
    local changed = force or frame.lastGUID ~= guid or frame.ready ~= ready
    if not changed then return end

    frame.lastGUID = guid
    frame.ready = ready
    local unitDB = DB()[unit]
    local mirror = (unitDB and unitDB.anchor or (unit == "target" and "RIGHT" or "LEFT")) == "RIGHT"
    if ready or force or not frame.photoSet then
        SetPortraitTexture(frame.photo, unit, true)
        ApplyMirror(frame.photo, mirror)
        ApplyZoom(frame)
        ApplyMask(frame)
        frame.photoSet = ready
    end
    local r, g, b = RingColor(unit)
    frame.ring:SetVertexColor(r, g, b, 1)
    if ready then
        frame.textureTries = nil
        CancelRetry(frame)
    else
        RetryTexture(frame)
    end

    local dead = not secret and SafeValue(UnitIsDead(unit)) or false
    if frame.photo.SetDesaturated then
        frame.photo:SetDesaturated(dead and true or false)
    end
end

local function OnEvent(frame, event, eventUnit)
    if not frame:IsVisible() and event ~= "PLAYER_TARGET_CHANGED" then return end
    if eventUnit and event:sub(1, 5) == "UNIT_" and event ~= "UNIT_TARGET" then
        if SafeValue(UnitIsUnit(eventUnit, frame.unit)) == false then return end
    end
    if event == "UNIT_ENTERED_VEHICLE" then
        C_Timer.After(0.6, function()
            if frame:IsShown() then UpdatePhoto(frame, true) end
        end)
        return
    end
    UpdatePhoto(frame, event == "PORTRAITS_UPDATED" or event == "PLAYER_TARGET_CHANGED" or event == "ForceUpdate")
end

local function RegisterPortraitEvents(frame)
    local events = UNIT_EVENTS[frame.unit]
    frame:UnregisterAllEvents()
    for _, event in ipairs(events) do
        if event:sub(1, 5) == "UNIT_" then
            frame:RegisterUnitEvent(event, frame.unit)
        else
            frame:RegisterEvent(event)
        end
    end
    frame:SetScript("OnEvent", OnEvent)
    frame:SetScript("OnShow", function()
        UpdatePhoto(frame, true)
    end)
end

local function EnsureDepthLayers(frame)
    if not frame.face then return end

    if not frame.shadow then
        frame.shadow = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
        frame.shadow:SetTexture(SHADOW_FILE, "CLAMP", "CLAMP", "TRILINEAR")
        frame.shadow:SetVertexColor(0, 0, 0, 0.58)
    end

    if not frame.innerShadow then
        frame.innerShadow = frame.face:CreateTexture(nil, "OVERLAY", nil, 0)
        frame.innerShadow:SetAllPoints()
        frame.innerShadow:SetTexture(INNER_SHADOW_FILE, "CLAMP", "CLAMP", "TRILINEAR")
        frame.innerShadow:SetVertexColor(0, 0, 0, 0.9)
    end

    if not frame.ringLip then
        frame.ringLip = frame.face:CreateTexture(nil, "OVERLAY", nil, 1)
        frame.ringLip:SetTexture(RING_FILE, "CLAMP", "CLAMP", "TRILINEAR")
        frame.ringLip:SetVertexColor(0, 0, 0, 0.45)
    end

    if not frame.highlight then
        frame.highlight = frame.face:CreateTexture(nil, "OVERLAY", nil, 3)
        frame.highlight:SetAllPoints()
        frame.highlight:SetTexture(HIGHLIGHT_FILE, "CLAMP", "CLAMP", "TRILINEAR")
        frame.highlight:SetVertexColor(1, 1, 1, 0.5)
    end
end

local function CreatePortrait(unit, parent)
    local name = "InariPortrait_" .. unit
    local frame = _G[name] or CreateFrame("Frame", name, parent)
    frame:SetParent(parent)
    frame.unit = unit
    frame:EnableMouse(false)
    frame:SetClipsChildren(false)

    if not frame.face then
        if frame.bg then frame.bg:Hide() end
        if frame.photo then frame.photo:Hide() end
        if frame.ring then frame.ring:Hide() end
        if frame.ringOuter then frame.ringOuter:Hide() end
        if frame.mask then frame.mask:Hide() end

        frame.face = CreateFrame("Frame", nil, frame)
        frame.face:SetPoint("CENTER")
        frame.face:SetClipsChildren(false)

        frame.bg = frame.face:CreateTexture(nil, "BACKGROUND")
        frame.bg:SetAllPoints()
        frame.bg:SetTexture(FILL_FILE)
        frame.bg:SetVertexColor(0, 0, 0, 1)

        frame.mask = frame.face:CreateMaskTexture()
        frame.mask:SetAllPoints()
        frame.mask:SetTexture(MASK_FILE, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")

        frame.photo = frame.face:CreateTexture(nil, "ARTWORK")
        frame.photo:SetAllPoints()

        frame.ring = frame.face:CreateTexture(nil, "OVERLAY", nil, 2)
        frame.ring:SetAllPoints()
        frame.ring:SetTexture(RING_FILE, "CLAMP", "CLAMP", "TRILINEAR")
    end

    EnsureDepthLayers(frame)
    ApplyMask(frame)

    portraits[unit] = frame
    LayoutPortrait(frame)
    RegisterPortraitEvents(frame)
    UpdatePhoto(frame, true)
    return frame
end

local function HidePortrait(unit)
    local frame = portraits[unit] or _G["InariPortrait_" .. unit]
    if not frame then return end
    CancelRetry(frame)
    frame:UnregisterAllEvents()
    frame:SetScript("OnEvent", nil)
    frame:SetScript("OnShow", nil)
    frame:Hide()
end

local function SuppressBlinkii()
    local addon = _G.BLINKIISPORTRAITS
    if type(addon) ~= "table" then return end
    local profile = addon.db and addon.db.profile
    if type(profile) == "table" then
        if type(profile.player) == "table" then profile.player.enable = false end
        if type(profile.target) == "table" then profile.target.enable = false end
    end
    if type(addon.KillPlayerPortrait) == "function" then pcall(addon.KillPlayerPortrait, addon) end
    if type(addon.KillTargetPortrait) == "function" then pcall(addon.KillTargetPortrait, addon) end
end

function ns.RefreshPortraits()
    ns.EnsureDB()
    local db = DB()
    if not db.enabled or not InariDB.enabled then
        local released = false
        for _, unit in ipairs(UNITS) do
            HidePortrait(unit)
            released = SetUnitFramePortraitSuppressed(ParentFrame(unit), false) or released
        end
        if released and ns.ReloadEllesmereFrames and not (InCombatLockdown and InCombatLockdown()) then
            ns.ReloadEllesmereFrames()
        end
        return
    end

    SuppressBlinkii()

    local missingParent = false
    for _, unit in ipairs(UNITS) do
        local parent = ParentFrame(unit)
        if not parent then
            missingParent = true
            HidePortrait(unit)
        elseif not UnitEnabled(unit) then
            HidePortrait(unit)
            -- Keep the Ellesmere square hidden. Per-unit off means no portrait,
            -- not a fallback to the attached square.
            SetUnitFramePortraitSuppressed(parent, true)
        else
            SetUnitFramePortraitSuppressed(parent, true)
            CreatePortrait(unit, parent)
        end
    end

    if missingParent and parentRetries < MAX_PARENT_RETRIES then
        parentRetries = parentRetries + 1
        C_Timer.After(0.25, ns.RefreshPortraits)
    else
        parentRetries = 0
    end
end

function ns.UpdatePortrait(unit, force)
    local frame = portraits[unit]
    if frame then UpdatePhoto(frame, force) end
end

function ns.GetPortraitStatus()
    ns.EnsureDB()
    local db = DB()
    if not db.enabled then
        return "Disabled"
    end
    local parts = {}
    if db.player.enable ~= false then parts[#parts + 1] = "Player" end
    if db.target.enable ~= false then parts[#parts + 1] = "Target" end
    if #parts == 0 then
        return "Disabled"
    end
    return table.concat(parts, " + "), "ok"
end

function ns.BlinkiiPortraitsPresent()
    if _G.BLINKIISPORTRAITS ~= nil then return true end
    if C_AddOns and C_AddOns.IsAddOnLoaded then
        return C_AddOns.IsAddOnLoaded("Blinkiis_Portraits") == true
    end
    return false
end

if ns.ReloadEllesmereFrames then
    local reloadFrames = ns.ReloadEllesmereFrames
    ns.ReloadEllesmereFrames = function()
        local reloaded = reloadFrames()
        C_Timer.After(0.2, ns.RefreshPortraits)
        return reloaded
    end
end

local boot = CreateFrame("Frame")
boot:RegisterEvent("PLAYER_LOGIN")
boot:RegisterEvent("PLAYER_ENTERING_WORLD")
boot:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        C_Timer.After(0, ns.RefreshPortraits)
        C_Timer.After(0.5, ns.RefreshPortraits)
    elseif event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(0, ns.RefreshPortraits)
    end
end)
