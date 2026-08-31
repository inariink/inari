local ADDON_NAME, ns = ...

local ARROW_TEX = "Interface\\AddOns\\inari\\Media\\targetarrow.tga"
local DEFAULT_ARROW_SIZE = 30
local MIN_ARROW_SIZE = 12
local MAX_ARROW_SIZE = 80
local SIDE_GAP = 6
local CAST_KICK = 8

local arrow, texL, texR
local lastL, lastR

local function ArrowSize()
    ns.EnsureDB()
    local size = tonumber(InariDB.targetArrowSize) or DEFAULT_ARROW_SIZE
    if size < MIN_ARROW_SIZE then size = MIN_ARROW_SIZE end
    if size > MAX_ARROW_SIZE then size = MAX_ARROW_SIZE end
    return size
end

local function ApplyArrowSize()
    if not texL then return end
    local size = ArrowSize()
    texL:SetSize(size, size)
    texR:SetSize(size, size)
end

local function Enabled()
    ns.EnsureDB()
    return InariDB.enabled == true and InariDB.targetArrows == true
end

local function GetNameplatesProfile()
    if ns.GetEllesmereAddonProfile then
        return ns.GetEllesmereAddonProfile("EllesmereUINameplates")
    end
    local root = _G.EllesmereUIDB
    if type(root) ~= "table" then return nil end
    local profile = root.profiles and root.profiles[root.activeProfile or "Default"]
    return profile and profile.addons and profile.addons.EllesmereUINameplates
end

local function RefreshNameplates()
    if _G._ENP_RefreshAllSettings then
        pcall(_G._ENP_RefreshAllSettings)
    end
end

local function ApplyEUIArrowSuppression()
    local prof = GetNameplatesProfile()
    if not prof then return end

    if Enabled() then
        if InariDB.targetArrowPrev == nil then
            InariDB.targetArrowPrev = prof.showTargetArrows and true or false
        end
        if prof.showTargetArrows ~= false then
            prof.showTargetArrows = false
            RefreshNameplates()
        end
    elseif InariDB.targetArrowPrev ~= nil then
        prof.showTargetArrows = InariDB.targetArrowPrev
        InariDB.targetArrowPrev = nil
        RefreshNameplates()
    end
end

local function EnsureArrow()
    if arrow then return arrow end
    arrow = CreateFrame("Frame", "InariTargetArrow", UIParent)
    arrow:SetFrameStrata("HIGH")
    arrow:Hide()
    texL = arrow:CreateTexture(nil, "OVERLAY")
    texL:SetTexture(ARROW_TEX)
    texL:SetRotation(0)
    texR = arrow:CreateTexture(nil, "OVERLAY")
    texR:SetTexture(ARROW_TEX)
    texR:SetRotation(math.pi)
    ApplyArrowSize()
    return arrow
end

local function TargetIsCasting()
    if not UnitExists("target") then return false end
    return (UnitCastingInfo("target") or UnitChannelInfo("target")) and true or false
end

local function CurrentGaps()
    local left = SIDE_GAP
    if TargetIsCasting() then
        left = SIDE_GAP + CAST_KICK
    end
    return left, SIDE_GAP
end

local function AnchorArrows(gapL, gapR)
    if gapL == lastL and gapR == lastR then return end
    lastL, lastR = gapL, gapR
    texL:ClearAllPoints()
    texR:ClearAllPoints()
    texL:SetPoint("RIGHT", arrow, "LEFT", -gapL, 0)
    texR:SetPoint("LEFT", arrow, "RIGHT", gapR, 0)
end

local function RefreshArrowGap()
    if not (arrow and arrow:IsShown()) then return end
    AnchorArrows(CurrentGaps())
end

local function UpdateTargetArrow()
    if not Enabled() then
        if arrow then arrow:Hide() end
        return
    end
    EnsureArrow()
    ApplyArrowSize()

    local plate = UnitExists("target") and UnitCanAttack("player", "target")
        and C_NamePlate and C_NamePlate.GetNamePlateForUnit("target")
    if not plate then
        arrow:Hide()
        return
    end

    lastL, lastR = nil, nil
    arrow:SetParent(plate)
    arrow:ClearAllPoints()
    arrow:SetAllPoints(plate.UnitFrame or plate)
    AnchorArrows(CurrentGaps())
    arrow:Show()
end

function ns.RefreshTargetArrows()
    ApplyEUIArrowSuppression()
    UpdateTargetArrow()
end

local CAST_EVENTS = {
    UNIT_SPELLCAST_START = true,
    UNIT_SPELLCAST_STOP = true,
    UNIT_SPELLCAST_CHANNEL_START = true,
    UNIT_SPELLCAST_CHANNEL_STOP = true,
    UNIT_SPELLCAST_INTERRUPTED = true,
    UNIT_SPELLCAST_FAILED = true,
    UNIT_SPELLCAST_SUCCEEDED = true,
}

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:RegisterEvent("PLAYER_TARGET_CHANGED")
ev:RegisterEvent("NAME_PLATE_UNIT_ADDED")
ev:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
for eventName in pairs(CAST_EVENTS) do
    ev:RegisterUnitEvent(eventName, "target")
end
ev:RegisterUnitEvent("UNIT_FACTION", "target")

ev:SetScript("OnEvent", function(_, event, unit)
    if CAST_EVENTS[event] then
        RefreshArrowGap()
        return
    end
    if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        ApplyEUIArrowSuppression()
    elseif event == "NAME_PLATE_UNIT_ADDED" or event == "NAME_PLATE_UNIT_REMOVED" then
        if unit and not UnitIsUnit(unit, "target") then return end
    end
    UpdateTargetArrow()
end)
