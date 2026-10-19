local ADDON_NAME, ns = ...

ns = ns or {}
_G.inari = ns

local UI = ns.UI or {}
ns.UI = UI
_G.InariUI = UI

local MEDIA = "Interface\\AddOns\\inari\\Media\\"

UI.Media = {
    Logo = MEDIA .. "logo.png",
    Font = MEDIA .. "Gilroy-Regular.ttf",
    FontSemiBold = MEDIA .. "Gilroy-SemiBold.ttf",
    FontBold = MEDIA .. "Gilroy-Bold.ttf",
    IconRuntime = MEDIA .. "icon-runtime.png",
    IconAppearance = MEDIA .. "icon-appearance.png",
    IconProfiles = MEDIA .. "icon-profiles.png",
    IconUIScale = MEDIA .. "icon-uiscale.png",
    IconAddons = MEDIA .. "icon-addons.png",
    IconInstaller = MEDIA .. "icon-installer.png",
    IconQoL = MEDIA .. "icon-qol.png",
    IconLayout = MEDIA .. "icon-uiscale.png",
    IconCooldowns = MEDIA .. "icon-cooldowns.png",
    IconPortraits = MEDIA .. "icon-portraits.png",
}

UI.Theme = {
    bg = { 0x0C / 255, 0x0A / 255, 0x0C / 255, 0.98 },
    header = { 0x12 / 255, 0x0E / 255, 0x12 / 255, 1.00 },
    panel = { 0x10 / 255, 0x0C / 255, 0x10 / 255, 1.00 },
    row = { 0x18 / 255, 0x13 / 255, 0x18 / 255, 1.00 },
    rowHover = { 0x22 / 255, 0x1A / 255, 0x22 / 255, 1.00 },
    line = { 0x3A / 255, 0x2C / 255, 0x32 / 255, 1.00 },
    accent = { 0xE8 / 255, 0xA4 / 255, 0xB8 / 255, 1.00 },
    accentDim = { 0xE8 / 255, 0xA4 / 255, 0xB8 / 255, 0.18 },
    accentBarely = { 0xE8 / 255, 0xA4 / 255, 0xB8 / 255, 0.08 },
    ink = { 0x0C / 255, 0x0A / 255, 0x0C / 255, 1.00 },
    text = { 0xFF / 255, 0xFF / 255, 0xFF / 255, 1.00 },
    muted = { 0xA0 / 255, 0x8A / 255, 0x94 / 255, 1.00 },
    subtle = { 0x7A / 255, 0x68 / 255, 0x72 / 255, 1.00 },
    success = { 0x7E / 255, 0xC8 / 255, 0xB0 / 255, 1.00 },
    error = { 0xE0 / 255, 0x6B / 255, 0x7A / 255, 1.00 },
}

local function Unpack(color, alpha)
    return color[1], color[2], color[3], alpha or color[4] or 1
end

local function Color(target, color)
    target:SetTextColor(Unpack(color))
end

local function ApplyTexture(frame, key, layer, color, alpha)
    local texture = frame[key]
    if not texture then
        texture = frame:CreateTexture(nil, layer or "BACKGROUND")
        texture:SetAllPoints()
        frame[key] = texture
    end
    texture:SetColorTexture(Unpack(color, alpha))
    return texture
end

local function SetFlatBackground(frame, color, alpha)
    return ApplyTexture(frame, "_inariBg", "BACKGROUND", color, alpha)
end

local function FontPath(weight)
    if weight == "bold" then return UI.Media.FontBold end
    if weight == "semibold" then return UI.Media.FontSemiBold end
    return UI.Media.Font
end

local function ApplyFont(fontString, path, size, flags)
    if not fontString or type(path) ~= "string" or path == "" then return false end
    -- Ellesmere: SetFont raises if the file is missing. The success boolean is
    -- not evidence the face can draw, so only the raise matters.
    return pcall(fontString.SetFont, fontString, path, size or 12, flags or "")
end

local function SetFont(fontString, size, weight, flags)
    size = size or 12
    fontString._inariFontSize = size
    fontString._inariFontWeight = weight
    fontString._inariFontFlags = flags
    if ApplyFont(fontString, FontPath(weight), size, flags) then
        return true
    end
    if weight ~= "bold" and ApplyFont(fontString, UI.Media.FontBold, size, flags) then
        return true
    end
    if ApplyFont(fontString, UI.Media.Font, size, flags) then
        return true
    end
    return ApplyFont(fontString, STANDARD_TEXT_FONT, size, flags)
end

local function PixelSize(frame, value)
    if PixelUtil and PixelUtil.GetNearestPixelSize and frame then
        local scale = frame:GetEffectiveScale()
        if scale and scale > 0 then
            return PixelUtil.GetNearestPixelSize(value, scale)
        end
    end
    return value
end

local function SnapSize(region, width, height)
    if PixelUtil and PixelUtil.SetSize then
        PixelUtil.SetSize(region, width, height)
        return
    end
    region:SetSize(width, height)
end

local function SnapWidth(region, width)
    if PixelUtil and PixelUtil.SetWidth then
        PixelUtil.SetWidth(region, width)
        return
    end
    region:SetWidth(width)
end

local function SnapHeight(region, height)
    if PixelUtil and PixelUtil.SetHeight then
        PixelUtil.SetHeight(region, height)
        return
    end
    region:SetHeight(height)
end

local function AddBorder(frame, thickness)
    thickness = thickness or 2
    local border = frame._inariBorder
    if not border then
        border = {}
        frame._inariBorder = border
        local function Edge(key)
            local tex = frame:CreateTexture(nil, "BORDER")
            tex:SetColorTexture(Unpack(UI.Theme.line))
            border[key] = tex
            return tex
        end
        border.top = Edge("top")
        border.bottom = Edge("bottom")
        border.left = Edge("left")
        border.right = Edge("right")
    end

    local size = PixelSize(frame, thickness)
    border.top:ClearAllPoints()
    border.top:SetPoint("TOPLEFT")
    border.top:SetPoint("TOPRIGHT")
    SnapHeight(border.top, size)

    border.bottom:ClearAllPoints()
    border.bottom:SetPoint("BOTTOMLEFT")
    border.bottom:SetPoint("BOTTOMRIGHT")
    SnapHeight(border.bottom, size)

    border.left:ClearAllPoints()
    border.left:SetPoint("TOPLEFT")
    border.left:SetPoint("BOTTOMLEFT")
    SnapWidth(border.left, size)

    border.right:ClearAllPoints()
    border.right:SetPoint("TOPRIGHT")
    border.right:SetPoint("BOTTOMRIGHT")
    SnapWidth(border.right, size)
    return border
end

local function SetBorderColor(frame, color, alpha)
    local border = frame._inariBorder
    if not border then return end
    for _, key in ipairs({ "top", "bottom", "left", "right" }) do
        local tex = border[key]
        if tex then tex:SetColorTexture(Unpack(color, alpha)) end
    end
end

local function SetBorderShown(frame, shown)
    local border = frame._inariBorder
    if not border then return end
    for _, key in ipairs({ "top", "bottom", "left", "right" }) do
        local tex = border[key]
        if tex then tex:SetShown(shown) end
    end
end

local function RegisterEscape(frame)
    if not frame or not frame.GetName then return end
    local name = frame:GetName()
    if not name or name == "" then return end
    UISpecialFrames = UISpecialFrames or {}
    for _, existing in ipairs(UISpecialFrames) do
        if existing == name then return end
    end
    tinsert(UISpecialFrames, name)
end

local function FadeIn(frame, duration)
    if UIFrameFadeIn then
        UIFrameFadeIn(frame, duration or 0.10, 0, 1)
        return
    end
    frame:SetAlpha(1)
end

local function AddonVersion()
    local getter = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
    if getter then
        return getter(ADDON_NAME, "Version") or ""
    end
    return ""
end

function UI:SetFrameColor(frame, color)
    SetFlatBackground(frame, color or self.Theme.row)
end

function UI:SetTextColor(fontString, kind)
    Color(fontString, self.Theme[kind or "text"] or self.Theme.text)
end

function UI:SetStatusColor(fontString, ok)
    Color(fontString, ok and self.Theme.success or self.Theme.error)
end

function UI:CreateText(parent, text, size, kind, weight)
    local fontString = parent:CreateFontString(nil, "OVERLAY")
    fontString:SetDrawLayer("OVERLAY", 7)
    SetFont(fontString, size or 12, weight)
    fontString:SetJustifyH("LEFT")
    fontString:SetJustifyV("MIDDLE")
    fontString:SetText(text or "")
    self:SetTextColor(fontString, kind or "text")
    return fontString
end

function UI:ReapplyFonts(root)
    if not root then return end
    local function visit(frame)
        if not frame then return end
        if frame.GetRegions then
            local regions = { frame:GetRegions() }
            for _, region in ipairs(regions) do
                if region and region.GetObjectType and region:GetObjectType() == "FontString" and region._inariFontSize then
                    SetFont(region, region._inariFontSize, region._inariFontWeight, region._inariFontFlags)
                end
            end
        end
        if frame.GetObjectType and frame:GetObjectType() == "EditBox" and frame._inariFontSize then
            SetFont(frame, frame._inariFontSize, frame._inariFontWeight, frame._inariFontFlags)
        end
        if frame.GetChildren then
            local children = { frame:GetChildren() }
            for _, child in ipairs(children) do
                visit(child)
            end
        end
    end
    visit(root)
end

local function ApplyButtonVisual(button)
    if button._disabled then
        button:SetAlpha(0.42)
        return
    end
    button:SetAlpha(1)
    if button.variant == "primary" or button.choiceActive then
        local alpha = 1
        if button._pressed then
            alpha = 0.70
        elseif button._hovered then
            alpha = 0.86
        end
        SetFlatBackground(button, UI.Theme.accent, alpha)
        SetBorderShown(button, false)
        if button.label then button.label:SetTextColor(Unpack(UI.Theme.ink)) end
        if button.activeIndicator then button.activeIndicator:Hide() end
        return
    end

    SetFlatBackground(button, UI.Theme.bg, 0)
    if button.variant == "link" then
        SetBorderShown(button, false)
    else
        SetBorderShown(button, true)
        if button._pressed then
            SetBorderColor(button, UI.Theme.accent, 0.70)
        elseif button._hovered then
            SetBorderColor(button, UI.Theme.accent)
        else
            SetBorderColor(button, UI.Theme.line)
        end
    end
    if button.label then
        if button._hovered then
            UI:SetTextColor(button.label, "text")
        else
            UI:SetTextColor(button.label, "muted")
        end
    end
    if button.activeIndicator then
        button.activeIndicator:Hide()
    end
end

function UI:CreateButton(parent, label, variant)
    local button = CreateFrame("Button", nil, parent)
    SnapSize(button, 150, 32)
    button:RegisterForClicks("LeftButtonUp")
    button:EnableMouse(true)
    button.variant = variant or "ghost"
    button._labelText = label or ""
    SetFlatBackground(button, self.Theme.bg, 0)
    AddBorder(button, 2)

    button.label = self:CreateText(button, button._labelText, 12, "text", "bold")
    button.label:SetPoint("CENTER")
    button.label:SetJustifyH("CENTER")
    button.label:SetJustifyV("MIDDLE")
    button.label:SetWordWrap(false)

    button.activeIndicator = button:CreateTexture(nil, "ARTWORK")
    button.activeIndicator:SetPoint("TOPLEFT")
    button.activeIndicator:SetPoint("BOTTOMLEFT")
    SnapWidth(button.activeIndicator, PixelSize(button, 2))
    button.activeIndicator:SetColorTexture(Unpack(self.Theme.accent))
    button.activeIndicator:Hide()

    function button:SetOnClick(callback)
        self._inariOnClick = callback
    end

    function button:SetLabel(text)
        self._labelText = text or ""
        SetFont(self.label, self.label._inariFontSize or 12, "bold", self.label._inariFontFlags)
        self.label:SetText(self._labelText)
    end

    function button:SetChoiceActive(active)
        self.choiceActive = active and true or false
        ApplyButtonVisual(self)
    end

    function button:SetEnabledState(enabled)
        self._disabled = not enabled
        self:EnableMouse(enabled and true or false)
        if self.Enable then
            if enabled then self:Enable() else self:Disable() end
        end
        ApplyButtonVisual(self)
    end

    button:SetScript("OnEnter", function(self)
        self._hovered = true
        ApplyButtonVisual(self)
    end)
    button:SetScript("OnLeave", function(self)
        self._hovered = false
        self._pressed = false
        ApplyButtonVisual(self)
    end)
    button:SetScript("OnMouseDown", function(self, mouseButton)
        if self._disabled or mouseButton ~= "LeftButton" then return end
        self._pressed = true
        ApplyButtonVisual(self)
    end)
    button:SetScript("OnMouseUp", function(self)
        self._pressed = false
        ApplyButtonVisual(self)
    end)
    button:SetScript("OnClick", function(self)
        if self._disabled then return end
        if self._inariOnClick then self:_inariOnClick() end
    end)

    ApplyButtonVisual(button)
    return button
end

function UI:CreatePrimaryButton(parent, label)
    return self:CreateButton(parent, label, "primary")
end

function UI:CreateGhostButton(parent, label)
    return self:CreateButton(parent, label, "ghost")
end

function UI:CreateTextButton(parent, label)
    return self:CreateButton(parent, label, "link")
end

function UI:CreateFlatButton(parent, label, variant)
    if variant == "primary" then
        return self:CreatePrimaryButton(parent, label)
    end
    return self:CreateGhostButton(parent, label)
end

function UI:CreateDashboardCard(parent)
    local card = CreateFrame("Frame", nil, parent)
    card:EnableMouse(true)
    SetFlatBackground(card, self.Theme.row)
    card._pad = 16

    card.accentBar = card:CreateTexture(nil, "ARTWORK")
    card.accentBar:SetPoint("TOPLEFT")
    card.accentBar:SetPoint("BOTTOMLEFT")
    SnapWidth(card.accentBar, PixelSize(card, 3))
    card.accentBar:SetColorTexture(Unpack(self.Theme.accent))
    card.accentBar:Hide()

    card.icon = card:CreateTexture(nil, "ARTWORK")
    SnapSize(card.icon, 96, 96)
    card.icon:SetPoint("LEFT", 16, 0)
    card.icon:SetBlendMode("BLEND")

    card.title = self:CreateText(card, "", 12, "text", "bold")
    card.title:SetWordWrap(true)
    card.title:SetJustifyV("TOP")
    card.title:SetPoint("TOPLEFT", 112, -16)
    card.title:SetPoint("TOPRIGHT", -16, -16)

    card.dot = card:CreateTexture(nil, "OVERLAY")
    SnapSize(card.dot, 8, 8)
    card.dot:SetColorTexture(Unpack(self.Theme.success))
    card.dot:Hide()

    card.status = self:CreateText(card, "", 15, "text", "bold")
    card.status:SetWordWrap(false)
    card._statusLines = {}

    card.action = self:CreateGhostButton(card, "")
    SnapSize(card.action, 110, 26)
    card.action:Hide()

    card.controlHost = CreateFrame("Frame", nil, card)
    SnapSize(card.controlHost, 184, 28)
    card.controlHost:Hide()

    local function HideStatusLines(self)
        for _, line in ipairs(self._statusLines) do
            line:Hide()
            if line.dot then line.dot:Hide() end
        end
    end

    local function PlaceStatusLines(self)
        local pad = self._pad or 16
        local y = -8
        local row = 16
        for _, line in ipairs(self._statusLines) do
            if line:IsShown() then
                line:ClearAllPoints()
                if line.dot then
                    line.dot:ClearAllPoints()
                    line.dot:SetPoint("TOPLEFT", self.title, "BOTTOMLEFT", 0, y - 3)
                    line:SetPoint("LEFT", line.dot, "RIGHT", 8, 0)
                else
                    line:SetPoint("TOPLEFT", self.title, "BOTTOMLEFT", 0, y)
                end
                line:SetPoint("RIGHT", self, "RIGHT", -pad, 0)
                y = y - row
            end
        end
    end

    local function PlaceStatus(self, withDot)
        local pad = self._pad or 16
        self.dot:ClearAllPoints()
        self.status:ClearAllPoints()
        if self._usingStatusLines then
            self.dot:Hide()
            self.status:Hide()
            PlaceStatusLines(self)
            return
        end
        self.status:Show()
        if withDot then
            self.dot:SetPoint("TOPLEFT", self.title, "BOTTOMLEFT", 0, -10)
            self.dot:Show()
            self.status:SetPoint("LEFT", self.dot, "RIGHT", 8, 0)
        else
            self.dot:Hide()
            self.status:SetPoint("TOPLEFT", self.title, "BOTTOMLEFT", 0, -10)
        end
        self.status:SetPoint("RIGHT", self, "RIGHT", -pad, 0)
    end

    function card:LayoutContent()
        local width = self:GetWidth() or 0
        local height = self:GetHeight() or 0
        if width < 8 or height < 8 then return end
        local pad = 16
        self._pad = pad
        local iconSize = math.floor(math.min(height - pad * 2, width * 0.36))
        if iconSize < 64 then iconSize = math.min(64, math.max(48, height - pad * 2)) end
        SnapSize(self.icon, iconSize, iconSize)
        self.icon:ClearAllPoints()
        self.icon:SetPoint("LEFT", pad, 0)

        local contentLeft = pad + iconSize + 16
        self.title:ClearAllPoints()
        self.title:SetPoint("TOPLEFT", contentLeft, -pad)
        self.title:SetPoint("TOPRIGHT", -pad, -pad)
        self.title:SetJustifyV("TOP")
        self.title:SetWidth(math.max(40, width - contentLeft - pad))
        local titleText = self.title:GetText()
        if titleText and titleText ~= "" then
            self.title:SetText(titleText)
        end

        self.action:ClearAllPoints()
        self.action:SetPoint("BOTTOMRIGHT", -pad, pad)
        self.controlHost:ClearAllPoints()
        self.controlHost:SetPoint("BOTTOMRIGHT", -pad, pad)

        PlaceStatus(self, self.dot:IsShown())
    end

    function card:SetTitle(text)
        self.title:SetText(string.upper(text or ""))
    end

    function card:SetIcon(path)
        self.icon:SetTexture(path)
        self.icon:SetBlendMode("BLEND")
    end

    function card:SetStatus(text, kind)
        self._usingStatusLines = false
        HideStatusLines(self)
        self.status:SetText(text or "")
        if kind == "ok" then
            self.dot:SetColorTexture(Unpack(UI.Theme.success))
            UI:SetTextColor(self.status, "text")
            PlaceStatus(self, true)
        elseif kind == "warn" then
            self.dot:SetColorTexture(Unpack(UI.Theme.accent))
            UI:SetTextColor(self.status, "text")
            PlaceStatus(self, true)
        else
            UI:SetTextColor(self.status, kind == "muted" and "muted" or "text")
            PlaceStatus(self, false)
        end
    end

    function card:SetStatusLines(lines)
        self._usingStatusLines = true
        self.status:SetText("")
        self.status:Hide()
        self.dot:Hide()
        lines = lines or {}
        for index, entry in ipairs(lines) do
            local text, enabled
            if type(entry) == "table" then
                text = entry.text or entry[1] or ""
                enabled = entry.on == true or entry.ok == true
            else
                text = entry or ""
                enabled = false
            end
            local line = self._statusLines[index]
            if not line then
                line = UI:CreateText(self, "", 13, "text", "bold")
                line:SetWordWrap(false)
                line.dot = self:CreateTexture(nil, "OVERLAY")
                SnapSize(line.dot, 8, 8)
                line.dot:SetColorTexture(Unpack(UI.Theme.success))
                self._statusLines[index] = line
            end
            line:SetText(text)
            line:Show()
            if line.dot then
                line.dot:Show()
                if enabled then
                    line.dot:SetColorTexture(Unpack(UI.Theme.success))
                else
                    line.dot:SetColorTexture(Unpack(UI.Theme.subtle))
                end
            end
        end
        for index = #lines + 1, #self._statusLines do
            self._statusLines[index]:Hide()
            if self._statusLines[index].dot then self._statusLines[index].dot:Hide() end
        end
        PlaceStatus(self, false)
    end

    function card:SetAttention(on)
        self.accentBar:SetShown(on and true or false)
    end

    function card:SetAction(label, variant, callback)
        if not label or label == "" then
            self.action:Hide()
            PlaceStatus(self, self.dot:IsShown())
            return
        end
        self.action.variant = variant or "ghost"
        self.action:SetLabel(label)
        ApplyButtonVisual(self.action)
        self.action:SetOnClick(function()
            if callback then callback() end
        end)
        local width = math.max(96, (self.action.label:GetStringWidth() or 70) + 24)
        SnapSize(self.action, width, 26)
        self.action:Show()
        self.controlHost:Hide()
        PlaceStatus(self, self.dot:IsShown())
    end

    function card:AttachControl(control)
        control:SetParent(self.controlHost)
        control:ClearAllPoints()
        local width = 0
        if control.buttons then
            for index, button in ipairs(control.buttons) do
                width = width + (button:GetWidth() or 0)
                if index > 1 then width = width + 8 end
            end
        end
        if width < 1 then width = 184 end
        SnapSize(control, width, 28)
        SnapSize(self.controlHost, width, 28)
        control:SetPoint("RIGHT")
        self.controlHost:Show()
        self.action:Hide()
        PlaceStatus(self, self.dot:IsShown())
    end

    function card:SetOnOpen(callback)
        self._onOpen = callback
    end

    card:SetScript("OnEnter", function(self)
        SetFlatBackground(self, UI.Theme.rowHover)
    end)
    card:SetScript("OnLeave", function(self)
        SetFlatBackground(self, UI.Theme.row)
    end)
    card:SetScript("OnMouseUp", function(self, mouseButton)
        if mouseButton ~= "LeftButton" then return end
        if MouseIsOver then
            if self.action:IsShown() and MouseIsOver(self.action) then return end
            if self.controlHost:IsShown() and MouseIsOver(self.controlHost) then return end
        end
        if self._onOpen then self:_onOpen() end
    end)
    card:SetScript("OnSizeChanged", function(self)
        self:LayoutContent()
    end)

    return card
end

function UI:CreateStepRow(parent)
    local row = CreateFrame("Frame", nil, parent)
    SnapHeight(row, 56)
    SetFlatBackground(row, self.Theme.row)

    row.accentBar = row:CreateTexture(nil, "ARTWORK")
    row.accentBar:SetPoint("TOPLEFT")
    row.accentBar:SetPoint("BOTTOMLEFT")
    SnapWidth(row.accentBar, PixelSize(row, 3))
    row.accentBar:SetColorTexture(Unpack(self.Theme.accent))
    row.accentBar:Hide()

    row.dot = row:CreateTexture(nil, "OVERLAY")
    SnapSize(row.dot, 8, 8)
    row.dot:SetPoint("TOPLEFT", 16, -14)
    row.dot:SetColorTexture(Unpack(self.Theme.subtle))

    row.action = self:CreateGhostButton(row, "")
    SnapSize(row.action, 130, 26)
    row.action:SetPoint("RIGHT", -14, 0)
    row.action:Hide()

    row.skip = self:CreateGhostButton(row, "SKIP")
    SnapSize(row.skip, 72, 26)
    row.skip:SetPoint("RIGHT", row.action, "LEFT", -8, 0)
    row.skip:Hide()

    row.title = self:CreateText(row, "", 12, "text", "semibold")
    row.title:SetPoint("TOPLEFT", row.dot, "TOPRIGHT", 12, 3)
    row.title:SetPoint("RIGHT", row.skip, "LEFT", -12, 0)
    row.title:SetWordWrap(false)

    row.copy = self:CreateText(row, "", 11, "muted", "semibold")
    row.copy:SetPoint("TOPLEFT", row.title, "BOTTOMLEFT", 0, -3)
    row.copy:SetPoint("RIGHT", row.skip, "LEFT", -12, 0)
    row.copy:SetWordWrap(false)

    function row:SetTitle(text)
        self.title:SetText(string.upper(text or ""))
    end

    function row:SetCopy(text)
        self.copy:SetText(text or "")
    end

    function row:SetState(kind)
        local color = UI.Theme.subtle
        if kind == "current" then
            color = UI.Theme.accent
        elseif kind == "completed" then
            color = UI.Theme.success
        elseif kind == "failed" then
            color = UI.Theme.error
        end
        self.dot:SetColorTexture(Unpack(color))
        self.accentBar:SetShown(kind == "current")
        UI:SetTextColor(self.title, (kind == "waiting" or kind == "skipped") and "muted" or "text")
        UI:SetTextColor(self.copy, "muted")
        self._state = kind
    end

    function row:LayoutActions()
        self.action:ClearAllPoints()
        self.skip:ClearAllPoints()
        if self.action:IsShown() then
            self.action:SetPoint("RIGHT", -14, 0)
            if self.skip:IsShown() then
                self.skip:SetPoint("RIGHT", self.action, "LEFT", -8, 0)
                self.title:SetPoint("RIGHT", self.skip, "LEFT", -12, 0)
                self.copy:SetPoint("RIGHT", self.skip, "LEFT", -12, 0)
            else
                self.title:SetPoint("RIGHT", self.action, "LEFT", -12, 0)
                self.copy:SetPoint("RIGHT", self.action, "LEFT", -12, 0)
            end
        elseif self.skip:IsShown() then
            self.skip:SetPoint("RIGHT", -14, 0)
            self.title:SetPoint("RIGHT", self.skip, "LEFT", -12, 0)
            self.copy:SetPoint("RIGHT", self.skip, "LEFT", -12, 0)
        else
            self.title:SetPoint("RIGHT", -14, 0)
            self.copy:SetPoint("RIGHT", -14, 0)
        end
    end

    function row:SetAction(label, variant, callback)
        if not label or label == "" then
            self.action:Hide()
            self:LayoutActions()
            return
        end
        self.action.variant = variant or "ghost"
        self.action:SetLabel(label)
        ApplyButtonVisual(self.action)
        self.action:SetOnClick(function()
            if callback then callback() end
        end)
        local width = math.max(110, (self.action.label:GetStringWidth() or 70) + 24)
        SnapSize(self.action, math.min(width, 190), 26)
        self.action:Show()
        self:LayoutActions()
    end

    function row:SetSkip(enabled, callback)
        if not enabled then
            self.skip:Hide()
            self:LayoutActions()
            return
        end
        self.skip:SetOnClick(function()
            if callback then callback() end
        end)
        self.skip:Show()
        self:LayoutActions()
    end

    row:SetState("waiting")
    return row
end

function UI:LayoutCardGrid(container, cards, columns, gap)
    columns = columns or 2
    gap = gap or 14
    local pending
    local function Relayout()
        local width = container:GetWidth() or 0
        local height = container:GetHeight() or 0
        if width < 1 or height < 1 then
            if not pending then
                pending = C_Timer.After(0, function()
                    pending = nil
                    Relayout()
                end)
            end
            return
        end
        local rows = math.ceil(#cards / columns)
        local cellWidth = (width - gap * (columns - 1)) / columns
        local cellHeight = (height - gap * (rows - 1)) / rows
        for index, card in ipairs(cards) do
            local col = (index - 1) % columns
            local row = math.floor((index - 1) / columns)
            card:ClearAllPoints()
            SnapSize(card, cellWidth, cellHeight)
            card:SetPoint("TOPLEFT", col * (cellWidth + gap), -row * (cellHeight + gap))
            if card.LayoutContent then card:LayoutContent() end
        end
    end
    container:SetScript("OnSizeChanged", Relayout)
    container:HookScript("OnShow", Relayout)
    Relayout()
    return Relayout
end

function UI:CreateWindow(name, parent, width, height, context)
    local frame = CreateFrame("Frame", name, parent or UIParent)
    SnapSize(frame, width or 880, height or 600)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    SetFlatBackground(frame, self.Theme.bg)
    AddBorder(frame, 2)
    RegisterEscape(frame)

    frame.header = CreateFrame("Frame", nil, frame)
    frame.header:SetPoint("TOPLEFT", 2, -2)
    frame.header:SetPoint("TOPRIGHT", -2, -2)
    SnapHeight(frame.header, 52)
    frame.header:EnableMouse(true)
    frame.header:RegisterForDrag("LeftButton")
    frame.header:SetScript("OnDragStart", function() frame:StartMoving() end)
    frame.header:SetScript("OnDragStop", function() frame:StopMovingOrSizing() end)
    SetFlatBackground(frame.header, self.Theme.header)

    frame.headerRule = frame:CreateTexture(nil, "ARTWORK")
    frame.headerRule:SetColorTexture(Unpack(self.Theme.line))
    frame.headerRule:SetPoint("TOPLEFT", frame.header, "BOTTOMLEFT")
    frame.headerRule:SetPoint("TOPRIGHT", frame.header, "BOTTOMRIGHT")
    SnapHeight(frame.headerRule, PixelSize(frame, 2))

    frame.logo = frame.header:CreateTexture(nil, "ARTWORK")
    frame.logo:SetTexture(self.Media.Logo)
    SnapSize(frame.logo, 32, 32)
    frame.logo:SetPoint("LEFT", 16, 0)

    frame.title = self:CreateText(frame.header, "inari", 16, "text", "bold")
    frame.title:SetPoint("LEFT", frame.logo, "RIGHT", 10, 1)

    frame.backButton = self:CreateGhostButton(frame.header, "<")
    SnapSize(frame.backButton, 28, 28)
    frame.backButton:SetPoint("LEFT", 12, 0)
    frame.backButton:Hide()

    frame.subtitle = self:CreateText(frame.header, context or "settings", 11, "accent", "bold")
    frame.subtitle:SetPoint("LEFT", frame.title, "RIGHT", 8, -1)

    frame.version = self:CreateText(frame.header, AddonVersion(), 11, "subtle", "bold")
    frame.version:SetPoint("RIGHT", -46, 0)
    frame.version:SetJustifyH("RIGHT")

    frame.closeButton = self:CreateGhostButton(frame.header, "x")
    SnapSize(frame.closeButton, 28, 28)
    frame.closeButton:SetPoint("RIGHT", -12, 0)
    frame.closeButton:SetOnClick(function()
        frame:Hide()
    end)

    frame.body = CreateFrame("Frame", nil, frame)
    frame.body:SetPoint("TOPLEFT", frame.header, "BOTTOMLEFT", 16, -16)
    frame.body:SetPoint("BOTTOMRIGHT", -16, 16)

    function frame:SetContext(text)
        self.subtitle:SetText(text or "")
        UI:SetTextColor(self.subtitle, "accent")
    end

    function frame:SetBackVisible(visible, onBack)
        self.backButton:SetShown(visible and true or false)
        self.logo:ClearAllPoints()
        if visible then
            self.logo:SetPoint("LEFT", self.backButton, "RIGHT", 8, 0)
            self.backButton:SetOnClick(function()
                if onBack then onBack() end
            end)
        else
            self.logo:SetPoint("LEFT", 16, 0)
        end
    end

    function frame:SetOnClose(callback)
        self._onClose = callback
        self.closeButton:SetOnClick(function()
            if self._onClose then self._onClose() end
            self:Hide()
        end)
    end

    frame:SetScript("OnShow", function(self)
        FadeIn(self, 0.10)
    end)

    return frame
end

function UI:CreateSidebarButton(parent, label, pageId)
    local button = CreateFrame("Button", nil, parent)
    local width = parent and parent.GetWidth and parent:GetWidth() or 0
    if not width or width < 1 then width = 200 end
    SnapSize(button, width, 34)
    button:RegisterForClicks("LeftButtonUp")
    button:EnableMouse(true)
    button.pageId = pageId
    SetFlatBackground(button, self.Theme.bg, 0)

    button.activeLine = button:CreateTexture(nil, "ARTWORK")
    button.activeLine:SetPoint("TOPLEFT")
    button.activeLine:SetPoint("BOTTOMLEFT")
    SnapWidth(button.activeLine, PixelSize(button, 3))
    button.activeLine:SetColorTexture(Unpack(self.Theme.accent))

    button.hover = button:CreateTexture(nil, "BACKGROUND")
    button.hover:SetAllPoints()
    button.hover:SetColorTexture(Unpack(self.Theme.row, 0))

    button.label = self:CreateText(button, label, 12, "muted", "semibold")
    button.label:ClearAllPoints()
    button.label:SetPoint("LEFT", 14, 0)
    button.label:SetJustifyH("LEFT")
    button.label:SetJustifyV("MIDDLE")
    button.label:SetWordWrap(false)

    function button:SetLabelInset(left)
        self.label:ClearAllPoints()
        self.label:SetPoint("LEFT", left or 14, 0)
    end

    function button:SetActive(active)
        self._active = active and true or false
        self.activeLine:SetShown(self._active)
        if self._active then
            self.hover:SetColorTexture(Unpack(UI.Theme.accentBarely))
            self.label:SetTextColor(1, 1, 1, 1)
        elseif self._hovered then
            self.hover:SetColorTexture(Unpack(UI.Theme.rowHover))
            UI:SetTextColor(self.label, "text")
        else
            self.hover:SetColorTexture(Unpack(UI.Theme.row, 0))
            UI:SetTextColor(self.label, "muted")
        end
    end

    function button:SetOnClick(callback)
        self._inariOnClick = callback
    end

    button:SetScript("OnEnter", function(self)
        self._hovered = true
        self:SetActive(self._active)
    end)
    button:SetScript("OnLeave", function(self)
        self._hovered = false
        self:SetActive(self._active)
    end)
    button:SetScript("OnClick", function(self)
        if self._inariOnClick then self:_inariOnClick() end
    end)
    button:SetActive(false)
    return button
end

function UI:CreateSegmentedControl(parent, options)
    local row = CreateFrame("Frame", nil, parent)
    local height = (options[1] and options[1].height) or 34
    SnapHeight(row, height)
    row.buttons = {}
    row.value = nil

    local function Refresh()
        for _, button in ipairs(row.buttons) do
            button:SetChoiceActive(button._value == row.value)
        end
    end

    function row:SetValue(value, silent)
        self.value = value
        Refresh()
        if not silent and self._onChanged then
            self:_onChanged(value)
        end
    end

    function row:GetValue()
        return self.value
    end

    function row:SetOnChanged(callback)
        self._onChanged = callback
    end

    local previous
    for index, data in ipairs(options) do
        local button = UI:CreateGhostButton(row, data.label)
        button._value = data.value
        button:SetOnClick(function()
            row:SetValue(data.value)
        end)
        if previous then
            button:SetPoint("LEFT", previous, "RIGHT", 8, 0)
        else
            button:SetPoint("LEFT")
        end
        SnapSize(button, data.width or 170, data.height or height)
        row.buttons[index] = button
        previous = button
        if index == 1 then
            row.value = data.value
        end
    end
    Refresh()
    return row
end

function UI:CreateStatusRow(parent)
    local row = CreateFrame("Frame", nil, parent)
    SnapHeight(row, 34)
    SetFlatBackground(row, self.Theme.row)

    row.text = self:CreateText(row, "", 12, "muted", "semibold")
    row.text:SetPoint("LEFT", 12, 0)
    row.text:SetPoint("RIGHT", -12, 0)

    function row:SetStatus(ok, message)
        self.text:SetText(message or "")
        UI:SetStatusColor(self.text, ok)
        self:Show()
    end

    function row:SetMuted(message)
        self.text:SetText(message or "")
        UI:SetTextColor(self.text, "muted")
        self:Show()
    end

    row:Hide()
    return row
end

function UI:CreateToggleRow(parent, labelText)
    local row = CreateFrame("Button", nil, parent)
    SnapHeight(row, 40)
    row:RegisterForClicks("LeftButtonUp")
    row:EnableMouse(true)
    row.checked = false
    SetFlatBackground(row, self.Theme.row)

    row.label = self:CreateText(row, labelText, 12, "text", "semibold")
    row.label:SetPoint("LEFT", 14, 0)
    row.label:SetPoint("RIGHT", -74, 0)

    row.track = CreateFrame("Frame", nil, row)
    SnapSize(row.track, 44, 22)
    row.track:SetPoint("RIGHT", -12, 0)
    row.track.bg = row.track:CreateTexture(nil, "BACKGROUND")
    row.track.bg:SetAllPoints()

    row.thumb = row.track:CreateTexture(nil, "ARTWORK")
    SnapSize(row.thumb, 16, 16)
    row.thumb:SetColorTexture(Unpack(self.Theme.text))

    function row:Refresh()
        self.thumb:ClearAllPoints()
        if self.checked then
            self.track.bg:SetColorTexture(Unpack(UI.Theme.accent))
            self.thumb:SetPoint("RIGHT", self.track, "RIGHT", -3, 0)
        else
            self.track.bg:SetColorTexture(Unpack(UI.Theme.subtle, 0.55))
            self.thumb:SetPoint("LEFT", self.track, "LEFT", 3, 0)
        end
    end

    function row:SetChecked(value)
        self.checked = value and true or false
        self:Refresh()
    end

    function row:GetChecked()
        return self.checked
    end

    function row:SetOnChanged(callback)
        self._onChanged = callback
    end

    function row:SetOnClick(callback)
        self:SetOnChanged(callback)
    end

    row:SetScript("OnEnter", function(self)
        SetFlatBackground(self, UI.Theme.rowHover)
    end)
    row:SetScript("OnLeave", function(self)
        SetFlatBackground(self, UI.Theme.row)
    end)
    row:SetScript("OnClick", function(self)
        self:SetChecked(not self.checked)
        if self._onChanged then self:_onChanged(self.checked) end
    end)
    row:Refresh()
    return row
end

function UI:CreateStepperRow(parent, label, value, minValue, maxValue, stepValue, callback)
    local row = CreateFrame("Frame", nil, parent)
    SnapHeight(row, 40)
    SetFlatBackground(row, self.Theme.row)

    row.label = self:CreateText(row, label, 12, "text", "semibold")
    row.label:SetPoint("LEFT", 14, 0)
    row.label:SetPoint("RIGHT", -170, 0)

    row.value = tonumber(value) or tonumber(minValue) or 0
    row.minValue = tonumber(minValue) or row.value
    row.maxValue = tonumber(maxValue) or row.value
    row.stepValue = tonumber(stepValue) or 1

    row.minus = self:CreateGhostButton(row, "-")
    SnapSize(row.minus, 34, 24)
    row.minus:SetPoint("RIGHT", -96, 0)

    row.valueText = self:CreateText(row, "", 12, "text", "semibold")
    row.valueText:SetPoint("LEFT", row.minus, "RIGHT", 8, 0)
    row.valueText:SetPoint("RIGHT", row.minus, "RIGHT", 58, 0)
    row.valueText:SetJustifyH("CENTER")

    row.plus = self:CreateGhostButton(row, "+")
    SnapSize(row.plus, 34, 24)
    row.plus:SetPoint("RIGHT", -12, 0)

    row.valueHit = CreateFrame("Button", nil, row)
    row.valueHit:SetPoint("LEFT", row.minus, "RIGHT", 4, 0)
    row.valueHit:SetPoint("RIGHT", row.plus, "LEFT", -4, 0)
    SnapHeight(row.valueHit, 24)
    row.valueHit:RegisterForClicks("LeftButtonUp")
    row.valueHit:SetScript("OnEnter", function()
        UI:SetTextColor(row.valueText, "accent")
    end)
    row.valueHit:SetScript("OnLeave", function()
        UI:SetTextColor(row.valueText, "text")
    end)

    row.edit = CreateFrame("EditBox", nil, row)
    row.edit:SetAutoFocus(false)
    row.edit:SetMaxLetters(12)
    row.edit:SetJustifyH("CENTER")
    row.edit:SetPoint("LEFT", row.minus, "RIGHT", 4, 0)
    row.edit:SetPoint("RIGHT", row.plus, "LEFT", -4, 0)
    SnapHeight(row.edit, 24)
    SetFont(row.edit, 12, "semibold", "")
    row.edit:SetTextColor(Unpack(UI.Theme.text))
    row.edit:SetTextInsets(0, 0, 0, 0)
    row.edit:Hide()

    local function FormatValue(numeric)
        if row.stepValue and row.stepValue < 1 then
            return string.format("%.2f", numeric)
        end
        return tostring(numeric)
    end

    local function StopEdit()
        row._editing = false
        row._editCancel = false
        row.edit:Hide()
        row.valueText:Show()
        row.valueHit:Show()
        UI:SetTextColor(row.valueText, "text")
    end

    local function CommitEdit()
        if not row._editing then return end
        if row._editCancel then
            StopEdit()
            return
        end
        local parsed = tonumber(row.edit:GetText())
        StopEdit()
        if parsed then
            row:SetValue(parsed)
        else
            row.valueText:SetText(FormatValue(row.value))
        end
    end

    local function StartEdit()
        if row._editing then return end
        row._editing = true
        row._editCancel = false
        row.valueText:Hide()
        row.valueHit:Hide()
        row.edit:SetText(FormatValue(row.value))
        row.edit:Show()
        row.edit:SetFocus()
        row.edit:HighlightText()
    end

    function row:SetValue(nextValue, silent)
        local numeric = tonumber(nextValue) or self.value
        if numeric < self.minValue then numeric = self.minValue end
        if numeric > self.maxValue then numeric = self.maxValue end
        if self.stepValue and self.stepValue > 0 then
            numeric = self.minValue + math.floor((numeric - self.minValue) / self.stepValue + 0.5) * self.stepValue
        end
        if self.stepValue and self.stepValue < 1 then
            numeric = tonumber(string.format("%.2f", numeric)) or numeric
        end
        self.value = numeric
        self.valueText:SetText(FormatValue(numeric))
        if not silent and callback then callback(self, numeric) end
    end

    row.valueHit:SetScript("OnClick", StartEdit)

    row.edit:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
    end)
    row.edit:SetScript("OnEscapePressed", function(self)
        row._editCancel = true
        self:ClearFocus()
    end)
    row.edit:SetScript("OnEditFocusLost", function()
        CommitEdit()
    end)

    row.minus:SetOnClick(function()
        if row._editing then
            row.edit:ClearFocus()
        end
        row:SetValue(row.value - row.stepValue)
    end)
    row.plus:SetOnClick(function()
        if row._editing then
            row.edit:ClearFocus()
        end
        row:SetValue(row.value + row.stepValue)
    end)
    row:SetValue(row.value, true)
    return row
end

function UI:CreateDivider(parent)
    local divider = parent:CreateTexture(nil, "ARTWORK")
    SnapHeight(divider, PixelSize(parent, 2))
    divider:SetColorTexture(Unpack(self.Theme.line))
    return divider
end

function UI:CreateSpacer(parent, height)
    local spacer = CreateFrame("Frame", nil, parent)
    SnapHeight(spacer, height or 10)
    return spacer
end

local function CreateScrollbar(scrollFrame)
    local bar = CreateFrame("Slider", nil, scrollFrame)
    bar:SetPoint("TOPRIGHT", 0, 0)
    bar:SetPoint("BOTTOMRIGHT", 0, 0)
    SnapWidth(bar, 4)
    bar:SetMinMaxValues(0, 1)
    bar:SetValueStep(1)
    bar:SetObeyStepOnDrag(false)
    SetFlatBackground(bar, UI.Theme.panel)

    bar.thumb = bar:CreateTexture(nil, "ARTWORK")
    bar.thumb:SetColorTexture(Unpack(UI.Theme.accent))
    SnapWidth(bar.thumb, 4)
    bar:SetThumbTexture(bar.thumb)

    local function Sync()
        local range = scrollFrame:GetVerticalScrollRange() or 0
        if range <= 1 then
            bar:Hide()
            return
        end
        bar:Show()
        bar:SetMinMaxValues(0, range)
        bar:SetValue(scrollFrame:GetVerticalScroll() or 0)
        local height = math.max(24, (scrollFrame:GetHeight() / (scrollFrame:GetHeight() + range)) * scrollFrame:GetHeight())
        SnapHeight(bar.thumb, height)
    end

    bar:SetScript("OnValueChanged", function(_, value)
        scrollFrame:SetVerticalScroll(value)
    end)
    scrollFrame:HookScript("OnScrollRangeChanged", Sync)
    scrollFrame:HookScript("OnVerticalScroll", function(_, offset)
        bar:SetValue(offset or 0)
    end)
    bar.Sync = Sync
    bar:Hide()
    return bar
end

function UI:CreateScrollArea(parent)
    local scrollFrame = CreateFrame("ScrollFrame", nil, parent)
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local current = self:GetVerticalScroll()
        local maxScroll = self:GetVerticalScrollRange()
        local nextScroll = current - (delta * 42)
        if nextScroll < 0 then nextScroll = 0 end
        if nextScroll > maxScroll then nextScroll = maxScroll end
        self:SetVerticalScroll(nextScroll)
    end)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(1, 1)
    scrollFrame:SetScrollChild(scrollChild)
    local scrollbar = CreateScrollbar(scrollFrame)

    function scrollFrame:SetContentHeight(height)
        local width = math.max(1, (self:GetWidth() or 1) - 10)
        scrollChild:SetWidth(width)
        scrollChild:SetHeight(math.max(self:GetHeight() or 1, height or 1))
        if scrollbar.Sync then scrollbar:Sync() end
    end

    scrollFrame:HookScript("OnSizeChanged", function(self)
        local width = math.max(1, (self:GetWidth() or 1) - 10)
        scrollChild:SetWidth(width)
        if scrollbar.Sync then scrollbar:Sync() end
    end)

    scrollFrame.child = scrollChild
    return scrollFrame, scrollChild
end

function UI:CreateSection(parentPage, titleText, maxWidth)
    local section = CreateFrame("Frame", nil, parentPage.scrollChild)
    section:SetWidth(maxWidth or parentPage.maxSectionWidth or 620)
    section.cursorY = 0
    section.rows = {}

    local function Advance(self, amount)
        self.cursorY = self.cursorY - amount
        self:SetHeight(math.max(1, math.abs(self.cursorY)))
    end

    if titleText and titleText ~= "" then
        section.title = self:CreateText(section, titleText, 11, "muted", "semibold")
        section.title:SetPoint("TOPLEFT", 0, section.cursorY)
        section.underline = section:CreateTexture(nil, "ARTWORK")
        section.underline:SetColorTexture(Unpack(self.Theme.accent))
        SnapSize(section.underline, 28, PixelSize(section, 2))
        section.underline:SetPoint("TOPLEFT", section.title, "BOTTOMLEFT", 0, -4)
        Advance(section, 28)
    end

    function section:AddToggle(label, checked, callback)
        local row = UI:CreateToggleRow(self, label)
        row:SetPoint("TOPLEFT", 0, self.cursorY)
        row:SetPoint("TOPRIGHT", 0, self.cursorY)
        row:SetChecked(checked)
        row:SetOnChanged(callback)
        self.rows[#self.rows + 1] = row
        Advance(self, 48)
        return row
    end

    function section:AddInfoRow(label, value)
        local row = CreateFrame("Frame", nil, self)
        row:SetPoint("TOPLEFT", 0, self.cursorY)
        row:SetPoint("TOPRIGHT", 0, self.cursorY)
        SnapHeight(row, 40)
        UI:SetFrameColor(row, UI.Theme.row)

        row.label = UI:CreateText(row, label, 12, "muted", "semibold")
        row.label:SetPoint("LEFT", 14, 0)

        row.value = UI:CreateText(row, value, 12, "text", "semibold")
        row.value:SetPoint("RIGHT", -14, 0)
        row.value:SetJustifyH("RIGHT")

        self.rows[#self.rows + 1] = row
        Advance(self, 48)
        return row
    end

    function section:AddButtonRow(buttons, align)
        local row = CreateFrame("Frame", nil, self)
        row:SetPoint("TOPLEFT", 0, self.cursorY)
        row:SetPoint("TOPRIGHT", 0, self.cursorY)
        SnapHeight(row, 34)
        row.buttons = {}

        local totalWidth = 0
        for index, data in ipairs(buttons) do
            totalWidth = totalWidth + (data.width or 150)
            if index > 1 then totalWidth = totalWidth + 8 end
        end

        local previous
        for _, data in ipairs(buttons) do
            local button
            if data.variant == "primary" then
                button = UI:CreatePrimaryButton(row, data.label)
            else
                button = UI:CreateGhostButton(row, data.label)
            end
            SnapSize(button, data.width or 150, 34)
            button:SetOnClick(data.onClick)
            row.buttons[#row.buttons + 1] = button
            if previous then
                button:SetPoint("LEFT", previous, "RIGHT", 8, 0)
            elseif align == "right" then
                button:SetPoint("TOPLEFT", row, "TOPRIGHT", -totalWidth, 0)
            else
                button:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
            end
            previous = button
        end

        self.rows[#self.rows + 1] = row
        Advance(self, 48)
        return row
    end

    function section:AddSegmented(options, selected, callback)
        local control = UI:CreateSegmentedControl(self, options)
        control:SetPoint("TOPLEFT", 0, self.cursorY)
        control:SetPoint("TOPRIGHT", 0, self.cursorY)
        if selected ~= nil then control:SetValue(selected, true) end
        control:SetOnChanged(callback)
        self.rows[#self.rows + 1] = control
        Advance(self, 48)
        return control
    end

    function section:AddStepperRow(label, value, minValue, maxValue, stepValue, callback)
        local row = UI:CreateStepperRow(self, label, value, minValue, maxValue, stepValue, callback)
        row:SetPoint("TOPLEFT", 0, self.cursorY)
        row:SetPoint("TOPRIGHT", 0, self.cursorY)
        self.rows[#self.rows + 1] = row
        Advance(self, 48)
        return row
    end

    function section:AddText(text, size, kind, height)
        local line = UI:CreateText(self, text, size or 13, kind or "text", "semibold")
        line:SetPoint("TOPLEFT", 0, self.cursorY)
        line:SetPoint("RIGHT", 0, 0)
        line:SetWordWrap(true)
        line:SetSpacing(4)
        self.rows[#self.rows + 1] = line
        Advance(self, height or 48)
        return line
    end

    function section:AddImage(path, width, height, blockHeight)
        local row = CreateFrame("Frame", nil, self)
        row:SetPoint("TOPLEFT", 0, self.cursorY)
        row:SetPoint("TOPRIGHT", 0, self.cursorY)
        SnapHeight(row, blockHeight or height or 128)

        row.image = row:CreateTexture(nil, "ARTWORK")
        row.image:SetTexture(path)
        SnapSize(row.image, width or 128, height or 128)
        row.image:SetPoint("CENTER")

        self.rows[#self.rows + 1] = row
        Advance(self, blockHeight or height or 128)
        return row
    end

    function section:AddProgress(label, current, total)
        local row = CreateFrame("Frame", nil, self)
        row:SetPoint("TOPLEFT", 0, self.cursorY)
        row:SetPoint("TOPRIGHT", 0, self.cursorY)
        SnapHeight(row, 42)
        UI:SetFrameColor(row, UI.Theme.row)

        row.label = UI:CreateText(row, label, 12, "text", "semibold")
        row.label:SetPoint("LEFT", 14, 8)

        row.value = UI:CreateText(row, tostring(current or 0) .. " / " .. tostring(total or 0), 12, "muted", "semibold")
        row.value:SetPoint("RIGHT", -14, 8)
        row.value:SetJustifyH("RIGHT")

        row.track = CreateFrame("Frame", nil, row)
        row.track:SetPoint("BOTTOMLEFT", 14, 8)
        row.track:SetPoint("BOTTOMRIGHT", -14, 8)
        SnapHeight(row.track, 4)
        row.track.bg = row.track:CreateTexture(nil, "BACKGROUND")
        row.track.bg:SetAllPoints()
        row.track.bg:SetColorTexture(Unpack(UI.Theme.subtle, 0.35))

        row.fill = row.track:CreateTexture(nil, "ARTWORK")
        row.fill:SetPoint("TOPLEFT")
        row.fill:SetPoint("BOTTOMLEFT")
        row.fill:SetColorTexture(Unpack(UI.Theme.accent))

        local ratio = 0
        if type(current) == "number" and type(total) == "number" and total > 0 then
            ratio = current / total
        end
        if ratio < 0 then ratio = 0 end
        if ratio > 1 then ratio = 1 end
        SnapWidth(row.fill, math.max(1, (self:GetWidth() - 28) * ratio))

        self.rows[#self.rows + 1] = row
        Advance(self, 50)
        return row
    end

    return section
end

function UI:CreatePage(parent, titleText, descriptionText, maxSectionWidth)
    local page = CreateFrame("Frame", nil, parent)
    page:SetAllPoints()
    page.maxSectionWidth = maxSectionWidth or 620
    page.sections = {}
    page.splitRows = {}
    page:Show()

    page.header = self:CreateText(page, titleText, 20, "text", "bold")
    page.header:SetPoint("TOPLEFT", 0, 0)
    page.header:SetPoint("RIGHT", 0, 0)

    page.description = self:CreateText(page, descriptionText or "", 12, "muted", "semibold")
    page.description:SetPoint("TOPLEFT", page.header, "BOTTOMLEFT", 0, -8)
    page.description:SetPoint("RIGHT", 0, 0)
    page.description:SetWordWrap(true)
    page.description:SetSpacing(3)

    page.toast = self:CreateStatusRow(page)
    page.toast:SetPoint("BOTTOMLEFT", 0, 0)
    page.toast:SetPoint("BOTTOMRIGHT", 0, 0)
    SnapHeight(page.toast, 34)

    page.scrollFrame = CreateFrame("ScrollFrame", nil, page)
    page.scrollFrame:SetPoint("TOPLEFT", page.description, "BOTTOMLEFT", 0, -18)
    page.scrollFrame:SetPoint("BOTTOMRIGHT", page.toast, "TOPRIGHT", -10, 12)
    page.scrollFrame:EnableMouseWheel(true)
    page.scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local current = self:GetVerticalScroll()
        local maxScroll = self:GetVerticalScrollRange()
        local nextScroll = current - (delta * 42)
        if nextScroll < 0 then nextScroll = 0 end
        if nextScroll > maxScroll then nextScroll = maxScroll end
        self:SetVerticalScroll(nextScroll)
    end)

    page.scrollChild = CreateFrame("Frame", nil, page.scrollFrame)
    page.scrollChild:SetSize(page.maxSectionWidth, 1)
    page.scrollFrame:SetScrollChild(page.scrollChild)
    page.scrollbar = CreateScrollbar(page.scrollFrame)

    local toastTimer
    local function ShowToast(setter, a, b)
        setter(page.toast, a, b)
        if toastTimer then toastTimer:Cancel() end
        toastTimer = C_Timer.NewTimer(3.5, function()
            if page.toast then page.toast:Hide() end
        end)
    end

    function page:SetStatus(ok, message)
        ShowToast(page.toast.SetStatus, ok, message)
    end

    function page:SetMuted(message)
        ShowToast(page.toast.SetMuted, message)
    end

    function page:AddSection(title, sectionMaxWidth)
        local section = UI:CreateSection(self, title, sectionMaxWidth or self.maxSectionWidth)
        self.sections[#self.sections + 1] = section
        return section
    end

    function page:AddSplit(leftTitle, rightTitle)
        local width = math.floor((self.maxSectionWidth - 16) / 2)
        local left = UI:CreateSection(self, leftTitle, width)
        local right = UI:CreateSection(self, rightTitle, width)
        self.sections[#self.sections + 1] = left
        self.sections[#self.sections + 1] = right
        self.splitRows[#self.splitRows + 1] = { left = left, right = right }
        left._splitPartner = right
        right._splitPartner = left
        return left, right
    end

    function page:UpdateLayout()
        local currentY = 0
        local width = self.maxSectionWidth
        local seen = {}
        for _, section in ipairs(self.sections) do
            if not seen[section] then
                section:ClearAllPoints()
                if section._splitPartner then
                    local partner = section._splitPartner
                    seen[section] = true
                    seen[partner] = true
                    local left = section
                    local right = partner
                    for _, split in ipairs(self.splitRows) do
                        if split.left == section or split.right == section then
                            left, right = split.left, split.right
                            break
                        end
                    end
                    left:SetPoint("TOPLEFT", self.scrollChild, "TOPLEFT", 0, currentY)
                    right:SetPoint("TOPLEFT", self.scrollChild, "TOPLEFT", left:GetWidth() + 16, currentY)
                    width = math.max(width, left:GetWidth() + right:GetWidth() + 16)
                    currentY = currentY - math.max(left:GetHeight(), right:GetHeight()) - 24
                else
                    seen[section] = true
                    section:SetPoint("TOPLEFT", self.scrollChild, "TOPLEFT", 0, currentY)
                    width = math.max(width, section:GetWidth())
                    currentY = currentY - section:GetHeight() - 24
                end
            end
        end
        self.scrollChild:SetWidth(width)
        self.scrollChild:SetHeight(math.max(1, math.abs(currentY)))
        if self.scrollbar and self.scrollbar.Sync then
            self.scrollbar:Sync()
        end
    end

    return page
end

function UI:CreateDialog(name, width, height, context)
    local frame = self:CreateWindow(name, UIParent, width or 500, height or 300, context or "profiles")
    frame.body:ClearAllPoints()
    frame.body:SetPoint("TOPLEFT", frame.header, "BOTTOMLEFT", 28, -20)
    frame.body:SetPoint("BOTTOMRIGHT", -28, 24)

    frame.logo = frame.body:CreateTexture(nil, "ARTWORK")
    frame.logo:SetTexture(self.Media.Logo)
    SnapSize(frame.logo, 64, 64)
    frame.logo:SetPoint("TOP", frame.body, "TOP", 0, 0)

    frame.heading = self:CreateText(frame.body, "", 20, "text", "bold")
    frame.heading:SetPoint("TOPLEFT", frame.logo, "BOTTOMLEFT", -200, -14)
    frame.heading:SetPoint("TOPRIGHT", frame.logo, "BOTTOMRIGHT", 200, -14)
    frame.heading:SetJustifyH("CENTER")

    frame.copy = self:CreateText(frame.body, "", 12, "muted", "semibold")
    frame.copy:SetPoint("TOPLEFT", frame.heading, "BOTTOMLEFT", 0, -10)
    frame.copy:SetPoint("TOPRIGHT", frame.heading, "BOTTOMRIGHT", 0, -10)
    frame.copy:SetJustifyH("CENTER")
    frame.copy:SetWordWrap(true)
    frame.copy:SetSpacing(5)

    frame.status = self:CreateText(frame.body, "", 11, "muted", "semibold")
    frame.status:SetPoint("BOTTOMLEFT", frame.body, "BOTTOMLEFT", 0, 46)
    frame.status:SetPoint("BOTTOMRIGHT", frame.body, "BOTTOMRIGHT", 0, 46)
    frame.status:SetJustifyH("CENTER")

    frame.primaryButton = self:CreatePrimaryButton(frame.body, "Confirm")
    SnapSize(frame.primaryButton, 150, 36)
    frame.primaryButton:SetPoint("BOTTOMRIGHT", frame.body, "BOTTOM", -6, 0)

    frame.secondaryButton = self:CreateGhostButton(frame.body, "Not Now")
    SnapSize(frame.secondaryButton, 150, 36)
    frame.secondaryButton:SetPoint("BOTTOMLEFT", frame.body, "BOTTOM", 6, 0)

    function frame:SetHeading(text)
        self.heading:SetText(text or "")
    end

    function frame:SetCopy(text)
        self.copy:SetText(text or "")
    end

    function frame:SetDialogStatus(ok, message)
        self.status:SetText(message or "")
        if message and message ~= "" then
            UI:SetStatusColor(self.status, ok)
        else
            UI:SetTextColor(self.status, "muted")
        end
    end

    return frame
end

function UI:ClearFrame(frame)
    if not frame then return end
    local children = { frame:GetChildren() }
    for _, child in ipairs(children) do
        child:Hide()
        child:SetParent(nil)
    end
    local regions = { frame:GetRegions() }
    for _, region in ipairs(regions) do
        region:Hide()
    end
end
