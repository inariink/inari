local ADDON_NAME, ns = ...

local SHADOW_FILE = "Interface\\AddOns\\inari\\Media\\frame-shadow.png"
local EDGE = 16
local OVERLAP = 1
local UV = EDGE / 64
local PIECES = {
    { key = "tl", left = 0,      right = UV,     top = 0,      bottom = UV },
    { key = "t",  left = UV,     right = 1 - UV, top = 0,      bottom = UV },
    { key = "tr", left = 1 - UV, right = 1,      top = 0,      bottom = UV },
    { key = "l",  left = 0,      right = UV,     top = UV,     bottom = 1 - UV },
    { key = "r",  left = 1 - UV, right = 1,      top = UV,     bottom = 1 - UV },
    { key = "bl", left = 0,      right = UV,     top = 1 - UV, bottom = 1 },
    { key = "b",  left = UV,     right = 1 - UV, top = 1 - UV, bottom = 1 },
    { key = "br", left = 1 - UV, right = 1,      top = 1 - UV, bottom = 1 },
}

local registry = {}
local pendingRefresh = false
local poolHooked = {}
local eventsReady = false
local hookedEDRVis = false
local hookedEDRRebuild = false
local hookedPartyPreview = false

local function GetRaidFramesNS()
    return EllesmereUI and EllesmereUI._ModuleNS and EllesmereUI._ModuleNS.EllesmereUIRaidFrames
end

local function ShadowsEnabled()
    ns.EnsureDB()
    return InariDB.enabled == true and InariDB.frameShadows == true
end

local function SafeNumber(value, fallback)
    if issecretvalue and issecretvalue(value) then
        return fallback
    end
    if type(value) ~= "number" then
        return fallback
    end
    return value
end

local function StrengthScale()
    ns.EnsureDB()
    local value = InariDB.frameShadowStrength
    if type(value) ~= "number" then value = 70 end
    if value < 0 then value = 0 end
    if value > 100 then value = 100 end
    return value / 100
end

local function GetShadowParent(host)
    return UIParent
end

local function GetUnitFrame(host)
    local frame = host
    while frame do
        if frame.Health == host or frame.Power == host or frame._barClip == host
            or frame._health == host or frame._power == host then
            return frame
        end
        frame = frame:GetParent()
    end
    -- Compact party cells: unnamed StatusBar, health stored on FFD or as _health.
    if host and host.GetParent then
        local parent = host:GetParent()
        if parent then
            if parent.GetAttribute then
                local unit = parent:GetAttribute("unit")
                if type(unit) == "string" and unit ~= "" then
                    return parent
                end
            end
            if parent._health or parent._uniformRef then
                return parent
            end
        end
    end
end

local function EffectiveAlpha(frame)
    local a = 1
    while frame do
        local alpha = 1
        if frame.GetAlpha then
            alpha = SafeNumber(frame:GetAlpha(), 1)
        end
        a = a * alpha
        if a <= 0.15 then return a end
        frame = frame.GetParent and frame:GetParent()
    end
    return a
end

local function IsAncestorHost(frame, hosts)
    local parent = frame:GetParent()
    while parent do
        if hosts[parent] then return true end
        parent = parent:GetParent()
    end
    return false
end

local function IsPlausibleHost(frame, allowHidden)
    if not frame or not frame.GetWidth then return false end
    if not allowHidden and frame.IsShown and not frame:IsShown() then return false end
    if (EffectiveAlpha(frame) or 1) <= 0.25 then return false end
    local width = SafeNumber(frame:GetWidth(), 0)
    local height = SafeNumber(frame:GetHeight(), 0)
    if (width < 8 or height < 4) and frame.GetParent then
        local parent = frame:GetParent()
        if parent and parent.GetWidth then
            width = SafeNumber(parent:GetWidth(), width)
            height = SafeNumber(parent:GetHeight(), height)
        end
    end
    if width < 8 or height < 4 then
        return allowHidden == true
    end
    if width > 520 or height > 120 then
        return frame.GetName and frame:GetName() == "EllesmereUIDragonRidingAnchor"
    end
    return true
end

local function AddHost(list, frame)
    if frame then list[#list + 1] = frame end
end

local function IsIconSized(frame)
    if not frame or not frame.GetWidth then return false end
    local width = SafeNumber(frame:GetWidth(), 0)
    local height = SafeNumber(frame:GetHeight(), 0)
    if width < 16 or height < 16 or width > 72 or height > 72 then return false end
    return math.abs(width - height) <= 16
end

local function FindCompactHealth(button)
    if not button then return nil end
    if button._health and button._health.GetStatusBarTexture then
        return button._health
    end
    if button.Health and button.Health.GetStatusBarTexture then
        return button.Health
    end
    local erfNS = GetRaidFramesNS()
    if erfNS and erfNS.GetFFD and erfNS._euiUnitButtons and erfNS._euiUnitButtons[button] then
        local fd = erfNS.GetFFD(button)
        if fd and fd.health and fd.health.GetStatusBarTexture then
            return fd.health
        end
    end
    if not button.GetChildren then return nil end
    local best
    local bestHeight = -1
    local children = { button:GetChildren() }
    for i = 1, #children do
        local child = children[i]
        local objectType = child.GetObjectType and child:GetObjectType() or nil
        if objectType == "StatusBar" and child.GetStatusBarTexture then
            local height = SafeNumber(child.GetHeight and child:GetHeight(), 0)
            if height > bestHeight then
                best = child
                bestHeight = height
            end
        end
    end
    return best
end

local function CollectPartyHosts(list, allowHidden)
    local seen = {}
    local function addButton(button)
        if not button or seen[button] then return end
        seen[button] = true
        local health = FindCompactHealth(button)
        if not health then return end
        AddHost(list, health)
        allowHidden[health] = true
    end

    for i = 1, 5 do
        addButton(_G["ERFPartyHeaderUnitButton" .. i])
    end
    addButton(_G.ERFPartySelfButton)

    local header = _G.ERFPartyHeader
    if header then
        for i = 1, 5 do
            addButton(header[i])
        end
        if header.GetChildren then
            local children = { header:GetChildren() }
            for i = 1, #children do
                addButton(children[i])
            end
        end
    end

    local erfNS = GetRaidFramesNS()
    if not erfNS then return end

    if type(erfNS._partyAllButtons) == "table" then
        for i = 1, #erfNS._partyAllButtons do
            addButton(erfNS._partyAllButtons[i])
        end
    end
    if type(erfNS._partyPvFrames) == "table" then
        for i = 1, #erfNS._partyPvFrames do
            addButton(erfNS._partyPvFrames[i])
        end
    end
end

local function CollectDragonHosts(list, allowHidden)
    local anchor = _G.EllesmereUIDragonRidingAnchor
    if not anchor then return end
    AddHost(list, anchor)
    allowHidden[anchor] = true
end

local function CollectCdmIcons(list)
    local seen = {}
    local function addIcon(frame)
        if frame and not seen[frame] and frame:IsShown() and IsIconSized(frame) then
            seen[frame] = true
            AddHost(list, frame)
        end
    end

    local getBarFrame = _G._ECME_GetBarFrame
    local cdmDB = _G._ECME_AceDB
    local bars = cdmDB and cdmDB.profile and cdmDB.profile.cdmBars and cdmDB.profile.cdmBars.bars
    if type(getBarFrame) == "function" and type(bars) == "table" then
        for _, barData in ipairs(bars) do
            if type(barData) == "table" and barData.enabled ~= false and barData.key then
                local bar = getBarFrame(barData.key)
                if bar and bar.GetChildren then
                    local children = { bar:GetChildren() }
                    for i = 1, #children do
                        addIcon(children[i])
                    end
                end
            end
        end
    end

    local names = ns.COOLDOWN_VIEWER_FRAME_NAMES
    if type(names) ~= "table" then return end
    for _, viewerName in ipairs(names) do
        local viewer = _G[viewerName]
        if viewer and viewer.itemFramePool and viewer.itemFramePool.EnumerateActive then
            if not poolHooked[viewer] and hooksecurefunc then
                poolHooked[viewer] = true
                hooksecurefunc(viewer.itemFramePool, "Acquire", function()
                    ns.QueueFrameShadowRefresh()
                    if ns.ScheduleIdleFadeUpdate then ns.ScheduleIdleFadeUpdate(0) end
                end)
            end
            for item in viewer.itemFramePool:EnumerateActive() do
                addIcon(item)
            end
        end
    end
end

local function CollectHosts()
    local list = {}
    local allowHidden = {}
    local names = ns.FRAME_NAMES
    if type(names) == "table" then
        for unit, frameName in pairs(names) do
            if type(unit) == "string" and not unit:find("^raid") and not unit:find("^party") then
                local frame = _G[frameName]
                if frame and frame.Health then
                    AddHost(list, frame.Health)
                    allowHidden[frame.Health] = true
                end
            end
        end
    end

    AddHost(list, _G.ERB_HealthBar)
    AddHost(list, _G.ERB_PrimaryBar)
    AddHost(list, _G.ERB_SecondaryBar)

    CollectPartyHosts(list, allowHidden)
    CollectDragonHosts(list, allowHidden)
    CollectCdmIcons(list)

    local hosts = {}
    for _, frame in ipairs(list) do
        hosts[frame] = true
    end

    local filtered = {}
    for _, frame in ipairs(list) do
        if not IsAncestorHost(frame, hosts) and IsPlausibleHost(frame, allowHidden[frame]) then
            filtered[#filtered + 1] = frame
        end
    end
    return filtered
end

local function HostIsShown(host)
    if host.IsVisible then
        if not host:IsVisible() then return false end
    elseif not host:IsShown() then
        return false
    end
    if EffectiveAlpha(host) <= 0.25 then return false end
    local unitFrame = GetUnitFrame(host)
    if unitFrame then
        if unitFrame.IsVisible then
            if not unitFrame:IsVisible() then return false end
        elseif not unitFrame:IsShown() then
            return false
        end
        if EffectiveAlpha(unitFrame) <= 0.25 then return false end
    end
    return true
end

local function SyncShadowState(host)
    local shadow = host and host._inariDropShadow
    if not shadow then return end

    if not ShadowsEnabled() or not HostIsShown(host) then
        shadow:Hide()
        return
    end

    local alpha = EffectiveAlpha(host)
    if alpha <= 0.15 then
        shadow:Hide()
        return
    end

    shadow:SetAlpha(alpha)
    shadow:Show()
end

local function HookHost(host)
    if host._inariShadowHooked then return end
    host._inariShadowHooked = true

    host:HookScript("OnShow", function()
        ns.QueueFrameShadowRefresh()
    end)
    host:HookScript("OnHide", function(self)
        local shadow = self._inariDropShadow
        if shadow then shadow:Hide() end
    end)
    if hooksecurefunc then
        hooksecurefunc(host, "SetAlpha", function()
            ns.QueueFrameShadowRefresh()
        end)
    end
    host:HookScript("OnSizeChanged", function()
        ns.QueueFrameShadowRefresh()
    end)

    local unitFrame = GetUnitFrame(host)
    if unitFrame and not unitFrame._inariShadowShowHooked then
        unitFrame._inariShadowShowHooked = true
        unitFrame:HookScript("OnShow", function()
            ns.QueueFrameShadowRefresh()
        end)
        unitFrame:HookScript("OnHide", function()
            if host._inariDropShadow then host._inariDropShadow:Hide() end
        end)
        if hooksecurefunc then
            hooksecurefunc(unitFrame, "SetAlpha", function()
                ns.QueueFrameShadowRefresh()
            end)
        end
    end
end

local function HideOldTextures(shadow)
    if shadow.texture then
        shadow.texture:Hide()
    end
    if shadow.layers then
        for _, tex in ipairs(shadow.layers) do
            tex:Hide()
        end
    end
end

local function EnsureShadow(host)
    local shadow = host._inariDropShadow
    local parent = GetShadowParent(host)
    if shadow then
        if shadow:GetParent() ~= parent then
            shadow:SetParent(parent)
        end
    else
        shadow = CreateFrame("Frame", nil, parent)
        shadow:EnableMouse(false)
        shadow:SetClipsChildren(false)
        shadow:SetIgnoreParentAlpha(true)
        host._inariDropShadow = shadow
        registry[host] = shadow
        HookHost(host)
    end

    HideOldTextures(shadow)

    if not shadow.pieces then
        shadow.pieces = {}
        for _, spec in ipairs(PIECES) do
            local tex = shadow:CreateTexture(nil, "BACKGROUND", nil, -8)
            tex:SetTexture(SHADOW_FILE, "CLAMP", "CLAMP", "TRILINEAR")
            tex:SetTexCoord(spec.left, spec.right, spec.top, spec.bottom)
            shadow.pieces[spec.key] = tex
        end
    end
    return shadow
end

local function LayoutShadow(host, shadow)
    local parent = GetShadowParent(host)
    if shadow:GetParent() ~= parent then
        shadow:SetParent(parent)
    end

    shadow:SetFrameStrata(host:GetFrameStrata() or "MEDIUM")
    local hostLevel = host:GetFrameLevel() or 1
    if hostLevel < 2 then hostLevel = 2 end
    shadow:SetFrameLevel(hostLevel - 1)

    local top = host
    local bottom = host
    local unitFrame = GetUnitFrame(host)
    local power = unitFrame and (unitFrame.Power or unitFrame._power)
    if not power and unitFrame then
        local erfNS = GetRaidFramesNS()
        if erfNS and erfNS.GetFFD and erfNS._euiUnitButtons and erfNS._euiUnitButtons[unitFrame] then
            local fd = erfNS.GetFFD(unitFrame)
            power = fd and fd.power
        end
    end
    if power and power:IsShown() then
        local healthTop = SafeNumber(host.GetTop and host:GetTop())
        local powerTop = SafeNumber(power.GetTop and power:GetTop())
        local healthBottom = SafeNumber(host.GetBottom and host:GetBottom())
        local powerBottom = SafeNumber(power.GetBottom and power:GetBottom())
        local healthLeft = SafeNumber(host.GetLeft and host:GetLeft())
        local powerLeft = SafeNumber(power.GetLeft and power:GetLeft())
        local healthRight = SafeNumber(host.GetRight and host:GetRight())
        local powerRight = SafeNumber(power.GetRight and power:GetRight())
        -- Only merge with an attached power bar; a detached one leaves an unshadowed gap.
        local attached = healthLeft and powerLeft and healthRight and powerRight
            and math.abs(healthLeft - powerLeft) <= 1 and math.abs(healthRight - powerRight) <= 1
            and ((healthBottom and powerTop and math.abs(powerTop - healthBottom) <= 0.5)
                or (healthTop and powerBottom and math.abs(powerBottom - healthTop) <= 0.5))
        if attached then
            if healthTop and powerTop and powerTop > healthTop + 0.5 then
                top = power
            end
            if healthBottom and powerBottom and powerBottom < healthBottom - 0.5 then
                bottom = power
            end
        end
    end

    shadow:ClearAllPoints()
    shadow:SetPoint("TOPLEFT", top, "TOPLEFT", 0, 0)
    shadow:SetPoint("BOTTOMRIGHT", bottom, "BOTTOMRIGHT", 0, 0)

    local width = SafeNumber(host:GetWidth(), 0)
    local height = SafeNumber(host:GetHeight(), 0)
    local edge = EDGE
    if width <= 64 and height <= 64 then
        edge = 10
    end
    local inset = OVERLAP

    local p = shadow.pieces
    local alpha = 0.75 * StrengthScale()
    for _, spec in ipairs(PIECES) do
        local tex = p[spec.key]
        tex:SetTexCoord(spec.left, spec.right, spec.top, spec.bottom)
        tex:SetVertexColor(1, 1, 1, alpha)
        tex:Show()
    end

    p.tl:ClearAllPoints()
    p.tl:SetSize(edge, edge)
    p.tl:SetPoint("TOPLEFT", shadow, "TOPLEFT", -edge + inset, edge - inset)

    p.tr:ClearAllPoints()
    p.tr:SetSize(edge, edge)
    p.tr:SetPoint("TOPRIGHT", shadow, "TOPRIGHT", edge - inset, edge - inset)

    p.bl:ClearAllPoints()
    p.bl:SetSize(edge, edge)
    p.bl:SetPoint("BOTTOMLEFT", shadow, "BOTTOMLEFT", -edge + inset, -edge + inset)

    p.br:ClearAllPoints()
    p.br:SetSize(edge, edge)
    p.br:SetPoint("BOTTOMRIGHT", shadow, "BOTTOMRIGHT", edge - inset, -edge + inset)

    p.t:ClearAllPoints()
    p.t:SetHeight(edge)
    p.t:SetPoint("TOPLEFT", p.tl, "TOPRIGHT")
    p.t:SetPoint("TOPRIGHT", p.tr, "TOPLEFT")

    p.b:ClearAllPoints()
    p.b:SetHeight(edge)
    p.b:SetPoint("BOTTOMLEFT", p.bl, "BOTTOMRIGHT")
    p.b:SetPoint("BOTTOMRIGHT", p.br, "BOTTOMLEFT")

    p.l:ClearAllPoints()
    p.l:SetWidth(edge)
    p.l:SetPoint("TOPLEFT", p.tl, "BOTTOMLEFT")
    p.l:SetPoint("BOTTOMLEFT", p.bl, "TOPLEFT")

    p.r:ClearAllPoints()
    p.r:SetWidth(edge)
    p.r:SetPoint("TOPRIGHT", p.tr, "BOTTOMRIGHT")
    p.r:SetPoint("BOTTOMRIGHT", p.br, "TOPRIGHT")
end

local function HookExternalRefresh()
    if not hooksecurefunc then return end
    if type(_G._EDR_UpdateVisibility) == "function" and not hookedEDRVis then
        hookedEDRVis = true
        hooksecurefunc("_EDR_UpdateVisibility", function()
            ns.QueueFrameShadowRefresh()
        end)
    end
    if type(_G._EDR_Rebuild) == "function" and not hookedEDRRebuild then
        hookedEDRRebuild = true
        hooksecurefunc("_EDR_Rebuild", function()
            ns.QueueFrameShadowRefresh()
        end)
    end
    local erfNS = GetRaidFramesNS()
    if erfNS and not hookedPartyPreview then
        hookedPartyPreview = true
        if type(erfNS.ShowPartyPreview) == "function" then
            hooksecurefunc(erfNS, "ShowPartyPreview", function()
                ns.QueueFrameShadowRefresh()
                C_Timer.After(0.05, function()
                    ns.RefreshFrameShadows()
                end)
            end)
        end
        if type(erfNS.HidePartyPreview) == "function" then
            hooksecurefunc(erfNS, "HidePartyPreview", function()
                ns.QueueFrameShadowRefresh()
            end)
        end
    end
end

local function EnsureEvents()
    HookExternalRefresh()
    if eventsReady then return end
    eventsReady = true
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_TARGET_CHANGED")
    frame:RegisterEvent("PLAYER_FOCUS_CHANGED")
    frame:RegisterEvent("GROUP_ROSTER_UPDATE")
    frame:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
    frame:RegisterEvent("PLAYER_CAN_GLIDE_CHANGED")
    frame:SetScript("OnEvent", function()
        ns.QueueFrameShadowRefresh()
    end)
end

function ns.RefreshFrameShadows()
    EnsureEvents()
    local enabled = ShadowsEnabled()
    local seen = {}

    if enabled then
        for _, host in ipairs(CollectHosts()) do
            local shadow = EnsureShadow(host)
            LayoutShadow(host, shadow)
            SyncShadowState(host)
            seen[host] = true
        end
    end

    for host, shadow in pairs(registry) do
        if not seen[host] and shadow then
            shadow:Hide()
        end
    end
end

function ns.QueueFrameShadowRefresh()
    if pendingRefresh then return end
    pendingRefresh = true
    C_Timer.After(0.05, function()
        pendingRefresh = false
        ns.RefreshFrameShadows()
    end)
end
