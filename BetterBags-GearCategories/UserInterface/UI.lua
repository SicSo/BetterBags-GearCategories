BBTC = BBTC or {}
BBTC.UIOptions = BBTC.UIOptions or {}

local UIOptions = BBTC.UIOptions

local config = BBTC.config
local AceConfig = BBTC.AceConfig

local GetTypeDef = BBTC.GetTypeDef
local GetState = BBTC.GetState
local GetSettings = BBTC.GetSettings
local GetPendingColor = BBTC.GetPendingColor
local GetPendingPriority = BBTC.GetPendingPriority
local GetPendingOrder = BBTC.GetPendingOrder
local GetMaxManagedOrder = BBTC.GetMaxManagedOrder
local ToggleCategory = BBTC.ToggleCategory
local ActivateCategory = BBTC.ActivateCategory
local ApplyPendingOrder = BBTC.ApplyPendingOrder
local ResetPendingName = BBTC.ResetPendingName
local ResetPendingColor = BBTC.ResetPendingColor
local NotifyConfigChanged = BBTC.NotifyConfigChanged
local GetStatusText = BBTC.GetStatusText
local SetPinnedEnabled = BBTC.SetPinnedEnabled
local SetEnforceOrderOnCreate = BBTC.SetEnforceOrderOnCreate
local SetEnforceOrderAlways = BBTC.SetEnforceOrderAlways
local SetIncludeBoeEnabled = BBTC.SetIncludeBoeEnabled
local SetIncludeBowEnabled = BBTC.SetIncludeBowEnabled

local WINDOW_NAME = "BBTCGearCategoriesWindow"

local ROOT_TABS = {
  { key = "overview", name = "Main" },
  { key = "midnight", name = "Midnight" },
}

local MIDNIGHT_SECTIONS = {
  crafted = {
    name = "Crafted",
    keys = { "crafted", "s1craft" },
  },
  season1 = {
    name = "Season 1",
    keys = { "myth", "hero", "champ", "vet", "adv", "season" },
  },
}

local function NotifyAndRefresh()
  if NotifyConfigChanged then
    NotifyConfigChanged()
  end

  if UIOptions.Refresh then
    UIOptions:Refresh()
  end
end

local function GetSectionForKey(typeKey)
  for sectionKey, section in pairs(MIDNIGHT_SECTIONS) do
    for _, key in ipairs(section.keys) do
      if key == typeKey then
        return sectionKey
      end
    end
  end

  return nil
end

local function IsKeyInSection(sectionKey, typeKey)
  local section = MIDNIGHT_SECTIONS[sectionKey]
  if not section then
    return false
  end

  for _, key in ipairs(section.keys) do
    if key == typeKey then
      return true
    end
  end

  return false
end

local function UpdateEditBoxText(editBox, value)
  value = tostring(value or "")

  if editBox and not editBox:HasFocus() and editBox:GetText() ~= value then
    editBox:SetText(value)
  end
end

local function SetEditBoxEnabled(editBox, enabled)
  editBox:SetEnabled(enabled)
  editBox:SetAlpha(enabled and 1 or 0.5)
end

local function SetWidgetEnabled(widget, enabled)
  widget:SetEnabled(enabled)
  widget:SetAlpha(enabled and 1 or 0.5)

  if widget.Label then
    widget.Label:SetAlpha(enabled and 1 or 0.5)
  end
end

local function SetTooltip(frame, text)
  if not text or text == "" then
    return
  end

  local oldEnter = frame:GetScript("OnEnter")
  local oldLeave = frame:GetScript("OnLeave")

  frame:SetScript("OnEnter", function(self, ...)
    if oldEnter then
      oldEnter(self, ...)
    end

    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(text, 1, 1, 1, 1, true)
  end)

  frame:SetScript("OnLeave", function(self, ...)
    if oldLeave then
      oldLeave(self, ...)
    end

    GameTooltip_Hide()
  end)
end

local function ResizeDynamicButton(button, minWidth)
  if DynamicResizeButton_Resize then
    DynamicResizeButton_Resize(button)
  end

  local fontString = button:GetFontString()
  local textWidth = fontString and fontString:GetStringWidth() or 0
  local width = math.max(minWidth or 0, textWidth + 40, 90)
  button:SetWidth(width)
end

local function CreateActionButton(parent, text, minWidth)
  --local button = CreateFrame("Button", nil, parent, "UIPanelDynamicResizeButtonTemplate")
  local button = CreateFrame("Button", nil, parent, "SharedButtonSmallTemplate")
  button:SetText(text)
  ResizeDynamicButton(button, minWidth)
  return button
end

local function CreateFixedButton(parent, text, width, height)
  --local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  local button = CreateFrame("Button", nil, parent, "SharedButtonSmallTemplate")
  button:SetSize(width, height or 22)
  button:SetText(text)
  return button
end

local function CreateInput(parent, width)
  local editBox = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
  editBox:SetSize(width, 30)
  editBox:SetAutoFocus(false)
  editBox:SetTextInsets(6, 6, 0, 0)
  editBox:SetMaxLetters(255)
  editBox:SetFontObject(ChatFontNormal)
  editBox:SetScript("OnEscapePressed", function(self)
    self:ClearFocus()
  end)
  editBox:SetScript("OnEditFocusGained", function(self)
    self:HighlightText()
  end)
  return editBox
end

local function CreateCheckbox(parent, text, tooltipText, labelWidth)
  local checkBox = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
  checkBox:SetSize(26, 26)

  local label = checkBox:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  label:SetPoint("LEFT", checkBox, "RIGHT", 6, 0)
  label:SetWidth(labelWidth or 150)
  label:SetJustifyH("LEFT")
  label:SetText(text)
  checkBox.Label = label

  SetTooltip(checkBox, tooltipText)

  label:EnableMouse(true)
  SetTooltip(label, tooltipText)
  label:SetScript("OnMouseDown", function()
    checkBox:Click()
  end)

  return checkBox
end

local function CreateTopTab(parent, id, text)
  local tab = CreateFrame("Button", nil, parent, "PanelTopTabButtonTemplate")
  tab:SetID(id)
  tab:SetText(text)
  tab:SetScript("OnShow", function(self)
    PanelTemplates_TabResize(self, 15, nil, 70)
    PanelTemplates_DeselectTab(self)
  end)
  tab:GetScript("OnShow")(tab)
  return tab
end

local function SetSwatchColor(swatch, color)
  local r = color and color.r or 1
  local g = color and color.g or 1
  local b = color and color.b or 1

  if swatch.SetColorRGB then
    swatch:SetColorRGB(r, g, b)
  end

  if swatch.swatchBg then
    swatch.swatchBg:SetVertexColor(r, g, b)
  end

  if swatch.texture then
    swatch.texture:SetVertexColor(r, g, b)
  end
end

local function CreateColorSwatch(parent, onChanged)
  local swatch = CreateFrame("Button", nil, parent, "ColorSwatchTemplate")
  swatch:RegisterForClicks("LeftButtonUp")
  swatch.currentColor = { r = 1, g = 1, b = 1, a = 1 }

  swatch:SetScript("OnClick", function()
    local current = UIOptions:CopyColour(swatch.currentColor)

    local info = {
      r = current.r,
      g = current.g,
      b = current.b,
      opacity = current.a,
      hasOpacity = false,
      swatchFunc = function()
        local r, g, b = ColorPickerFrame:GetColorRGB()
        local color = { r = r, g = g, b = b, a = 1 }
        swatch.currentColor = UIOptions:CopyColour(color)
        SetSwatchColor(swatch, color)
        onChanged(color)
      end,
      cancelFunc = function()
        swatch.currentColor = UIOptions:CopyColour(current)
        SetSwatchColor(swatch, current)
        onChanged(current)
      end,
    }

    ColorPickerFrame:SetupColorPickerAndShow(info)
  end)

  SetTooltip(swatch, "Choose the text color for this category.")
  return swatch
end

local function CreateScrollContent(parent, insetLeft, insetTop, insetRight, insetBottom)
  local scrollFrame = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
  scrollFrame:SetPoint("TOPLEFT", insetLeft or 0, insetTop or 0)
  scrollFrame:SetPoint("BOTTOMRIGHT", insetRight or 0, insetBottom or 0)

  local content = CreateFrame("Frame", nil, scrollFrame)
  content:SetSize(1, 1)
  scrollFrame:SetScrollChild(content)

  scrollFrame.content = content
  return scrollFrame, content
end

local function UpdateScrollChildHeight(content, bottomMarker, minHeight)
  minHeight = minHeight or 1

  if not content or not bottomMarker then
    return
  end

  local top = content:GetTop()
  local bottom = bottomMarker:GetBottom()

  if not top or not bottom then
    return
  end

  local height = math.max(minHeight, top - bottom)
  content:SetHeight(height)
end

local function CreateSectionBox(parent, title, width, height)
  local box = CreateFrame("Frame", nil, parent, "InsetFrameTemplate")
  box:SetSize(width, height)

  box.Title = box:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
  box.Title:SetPoint("TOPLEFT", 12, -10)
  box.Title:SetText(title)

  return box
end

function UIOptions:EnsureSelection()
  if not self.selectedRoot then
    self.selectedRoot = "overview"
  end

  if not self.selectedSection or not MIDNIGHT_SECTIONS[self.selectedSection] then
    self.selectedSection = "crafted"
  end

  if not self.selectedCategory or not IsKeyInSection(self.selectedSection, self.selectedCategory) then
    self.selectedCategory = MIDNIGHT_SECTIONS[self.selectedSection].keys[1]
  end
end

function UIOptions:GetSelectedKey()
  self:EnsureSelection()

  if self.selectedRoot ~= "midnight" then
    return nil
  end

  return self.selectedCategory
end

function UIOptions:SelectRoot(rootKey)
  self.selectedRoot = rootKey
  self:Refresh()
end

function UIOptions:SelectSection(sectionKey)
  if not MIDNIGHT_SECTIONS[sectionKey] then
    return
  end

  self.selectedSection = sectionKey
  self.selectedRoot = "midnight"

  if not IsKeyInSection(sectionKey, self.selectedCategory) then
    self.selectedCategory = MIDNIGHT_SECTIONS[sectionKey].keys[1]
  end

  self:Refresh()
end

function UIOptions:SelectCategory(typeKey)
  local sectionKey = GetSectionForKey(typeKey)
  if not sectionKey then
    return
  end

  self.selectedRoot = "midnight"
  self.selectedSection = sectionKey
  self.selectedCategory = typeKey
  self:Refresh()
end

function UIOptions:SavePendingName(shouldRefresh)
  local key = self:GetSelectedKey()
  if not key or not self.window then
    return
  end

  local state = GetState(key)
  state.pendingName = self.window.DetailPanel.NameInput:GetText()

  if shouldRefresh then
    NotifyAndRefresh()
  end
end

function UIOptions:SavePendingOrder(shouldRefresh)
  local key = self:GetSelectedKey()
  if not key or not self.window then
    return
  end

  local state = GetState(key)
  state.pendingOrder = self.window.DetailPanel.OrderInput:GetText()

  if shouldRefresh then
    NotifyAndRefresh()
  end
end

function UIOptions:SavePendingPriority(shouldRefresh)
  local key = self:GetSelectedKey()
  if not key or not self.window then
    return
  end

  local state = GetState(key)
  state.pendingPriority = self.window.DetailPanel.PriorityInput:GetText()

  if shouldRefresh then
    NotifyAndRefresh()
  end
end

function UIOptions:RefreshOverviewPanel()
  if not self.window then
    return
  end

  local overview = self.window.OverviewPanel
  local settings = GetSettings()

  overview.EnforceOnCreate:SetChecked(not not settings.enforceOrderOnCreate)
  overview.EnforceAlways:SetChecked(not not settings.enforceOrderAlways)

  if overview.Content and overview.BottomMarker then
    UpdateScrollChildHeight(overview.Content, overview.BottomMarker, 1)
  end
end

function UIOptions:RefreshSectionButtons()
  if not self.window then
    return
  end

  local buttons = self.window.MidnightPanel.SectionButtons
  for sectionKey, button in pairs(buttons) do
    local selected = sectionKey == self.selectedSection
    button:SetEnabled(not selected)
    button:SetAlpha(selected and 1 or 0.85)
  end
end

function UIOptions:RefreshCategoryButtons()
  if not self.window then
    return
  end

  local panel = self.window.MidnightPanel
  local section = MIDNIGHT_SECTIONS[self.selectedSection]
  local keys = section.keys

  panel.ListHeader:SetText(section.name .. " Categories")

  for index, button in ipairs(panel.CategoryButtons) do
    local typeKey = keys[index]

    if typeKey then
      local def = GetTypeDef(typeKey)
      button.typeKey = typeKey
      button:SetText(self:ColourText(def.treeName, GetPendingColor(typeKey)))
      button:Show()

      local selected = typeKey == self.selectedCategory
      button:SetEnabled(not selected)
      button:SetAlpha(selected and 1 or 0.95)
    else
      button.typeKey = nil
      button:Hide()
    end
  end
end

function UIOptions:RefreshDetailPanel()
  if not self.window then
    return
  end

  local key = self:GetSelectedKey()
  if not key then
    return
  end

  local detail = self.window.DetailPanel
  local def = GetTypeDef(key)
  local state = GetState(key)
  local pendingColor = GetPendingColor(key)
  local pinned = not not state.pinned

  detail.Title:SetText(self:ColourText(def.treeName, pendingColor))

  detail.Active:SetChecked(not not state.active)
  detail.Pinned:SetChecked(pinned)
  detail.IncludeBoe:SetChecked(not not state.pendingIncludeBoe)
  detail.IncludeBow:SetChecked(not not state.pendingIncludeBow)

  UpdateEditBoxText(detail.OrderInput, tostring(GetPendingOrder(key)))
  SetEditBoxEnabled(detail.OrderInput, pinned)
  SetWidgetEnabled(detail.ApplyOrder, pinned)
  detail.OrderLabel:SetAlpha(pinned and 1 or 0.5)
  detail.OrderHelp:SetAlpha(pinned and 1 or 0.5)
  detail.OrderHelp:SetText("Lower number = higher in pinned list. Range: 1-" .. tostring(GetMaxManagedOrder()))

  UpdateEditBoxText(detail.NameInput, state.pendingName or def.defaultName)

  detail.ColorSwatch.currentColor = UIOptions:CopyColour(pendingColor)
  SetSwatchColor(detail.ColorSwatch, pendingColor)

  UpdateEditBoxText(detail.PriorityInput, tostring(GetPendingPriority(key)))

  detail.DefaultName:SetText("Default: " .. def.defaultName)

  if state.active and state.plainActiveName then
    detail.CurrentName:SetText("Current active name: " .. state.plainActiveName)
  else
    detail.CurrentName:SetText("Current active name: (not active)")
  end

  if state.active and state.activeOrder then
    detail.CurrentOrder:SetText("Current active pinned order: " .. tostring(state.activeOrder))
  else
    detail.CurrentOrder:SetText("Current active pinned order: (not active)")
  end

  detail.Status:SetText(GetStatusText(key))

  local midnight = self.window.MidnightPanel
  if midnight and midnight.Content and midnight.BottomMarker then
    UpdateScrollChildHeight(midnight.Content, midnight.BottomMarker, 1)
  end
end

function UIOptions:RefreshRootTabs()
  if not self.window then
    return
  end

  local selectedIndex = 1

  for index, info in ipairs(ROOT_TABS) do
    local tab = self.window.RootTabs[index]
    if info.key == self.selectedRoot then
      selectedIndex = index
      PanelTemplates_SelectTab(tab)
    else
      PanelTemplates_DeselectTab(tab)
    end
  end

  PanelTemplates_SetTab(self.window, selectedIndex)
end

function UIOptions:Refresh()
  if not self.window then
    return
  end

  self:EnsureSelection()
  self:RefreshRootTabs()

  self.window.OverviewPanel:SetShown(self.selectedRoot == "overview")
  self.window.MidnightPanel:SetShown(self.selectedRoot == "midnight")

  self:RefreshOverviewPanel()

  if self.selectedRoot == "midnight" then
    self:RefreshSectionButtons()
    self:RefreshCategoryButtons()
    self:RefreshDetailPanel()
  end
end

function UIOptions:CreateWindow()
  local frame = CreateFrame("Frame", WINDOW_NAME, UIParent, "ButtonFrameTemplate")
  frame:SetSize(860, 620)
  frame:SetPoint("CENTER")
  frame:SetToplevel(true)
  frame:SetMovable(true)
  frame:SetClampedToScreen(true)
  frame:EnableMouse(true)
  frame:SetResizable(true)

  if frame.SetResizeBounds then
    frame:SetResizeBounds(620, 420, UIParent:GetWidth(), UIParent:GetHeight())
  elseif frame.SetMinResize then
    frame:SetMinResize(620, 420)

    if frame.SetMaxResize then
      frame:SetMaxResize(UIParent:GetWidth(), UIParent:GetHeight())
    end
  end

  if frame.SetTitle then
    frame:SetTitle("BetterBags - Gear Categories")
  elseif frame.TitleText then
    frame.TitleText:SetText("BetterBags - Gear Categories")
  end

  if ButtonFrameTemplate_HidePortrait then
    ButtonFrameTemplate_HidePortrait(frame)
  end

  if ButtonFrameTemplate_HideButtonBar then
    ButtonFrameTemplate_HideButtonBar(frame)
  end

  if frame.Inset then
    frame.Inset:Hide()
  end

  frame.DragArea = CreateFrame("Frame", nil, frame)
  frame.DragArea:SetPoint("TOPLEFT", 8, -6)
  frame.DragArea:SetPoint("TOPRIGHT", -30, -6)
  frame.DragArea:SetHeight(28)
  frame.DragArea:EnableMouse(true)
  frame.DragArea:RegisterForDrag("LeftButton")

  frame.DragArea:SetScript("OnDragStart", function()
    frame:StartMoving()
  end)

  frame.DragArea:SetScript("OnDragStop", function()
    frame:StopMovingOrSizing()
    frame:SetUserPlaced(false)
  end)

  frame.ResizeHandle = CreateFrame("Button", nil, frame)
  frame.ResizeHandle:SetSize(18, 18)
  frame.ResizeHandle:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2)
  frame.ResizeHandle:EnableMouse(true)
  frame.ResizeHandle:RegisterForDrag("LeftButton")

  frame.ResizeHandle:SetScript("OnDragStart", function()
    if frame.StartSizing then
      frame:StartSizing("BOTTOMRIGHT")
    end
  end)

  frame.ResizeHandle:SetScript("OnDragStop", function()
    if frame.StopMovingOrSizing then
      frame:StopMovingOrSizing()
    end
    frame:SetUserPlaced(false)
    UIOptions:Refresh()
  end)

  local resizeTexture = frame.ResizeHandle:CreateTexture(nil, "OVERLAY")
  resizeTexture:SetAllPoints()
  resizeTexture:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
  frame.ResizeHandle.texture = resizeTexture

  frame.ResizeHandle:SetScript("OnEnter", function(self)
    if self.texture then
      self.texture:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    end

    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText("Drag to resize", 1, 1, 1, 1, true)
  end)

  frame.ResizeHandle:SetScript("OnLeave", function(self)
    if self.texture then
      self.texture:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    end

    GameTooltip_Hide()
  end)

  frame:SetScript("OnShow", function()
    UIOptions:Refresh()
  end)

  if not tContains(UISpecialFrames, frame:GetName()) then
    table.insert(UISpecialFrames, frame:GetName())
  end

  if frame:GetHeight() >= UIParent:GetHeight() then
    frame:SetScale(UIParent:GetHeight() / frame:GetHeight() * 0.97)
  end

  frame.RootTabs = {}

  local previousTab
  for index, info in ipairs(ROOT_TABS) do
    local tab = CreateTopTab(frame, index, info.name)
    tab.key = info.key

    if previousTab then
      tab:SetPoint("LEFT", previousTab, "RIGHT", 5, 0)
    else
      tab:SetPoint("TOPLEFT", 17, -25)
    end

    tab:SetScript("OnClick", function(self)
      UIOptions:SelectRoot(self.key)
    end)

    frame.RootTabs[index] = tab
    previousTab = tab
  end

  PanelTemplates_SetNumTabs(frame, #frame.RootTabs)

  local overview = CreateFrame("Frame", nil, frame)
  overview:SetPoint("TOPLEFT", 18, -58)
  overview:SetPoint("BOTTOMRIGHT", -18, 18)
  frame.OverviewPanel = overview

  overview.ScrollFrame, overview.Content = CreateScrollContent(overview, 12, -12, -26, 12)
  local overviewContent = overview.Content
  overviewContent:SetWidth(780)
  overviewContent:SetHeight(1)

  overview.Title = overviewContent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  overview.Title:SetPoint("TOPLEFT", 8, -8)
  overview.Title:SetText("Ordering")

  overview.Description = overviewContent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  overview.Description:SetPoint("TOPLEFT", overview.Title, "BOTTOMLEFT", 0, -12)
  overview.Description:SetWidth(740)
  overview.Description:SetJustifyH("LEFT")
  overview.Description:SetText("Manage the default pinned ordering behavior for the addon.")

  overview.EnforceOnCreate = CreateCheckbox(
    overviewContent,
    "Enforce order at creation/update",
    "When a managed pinned category is created or updated, write its pinned order into BetterBags.",
    320
  )
  overview.EnforceOnCreate:SetPoint("TOPLEFT", overview.Description, "BOTTOMLEFT", -2, -22)
  overview.EnforceOnCreate:SetScript("OnClick", function(self)
    SetEnforceOrderOnCreate(self:GetChecked())
    UIOptions:Refresh()
  end)

  overview.EnforceAlways = CreateCheckbox(
    overviewContent,
    "Enforce order permanently",
    "Keep reapplying the managed pinned order when categories change.",
    300
  )
  overview.EnforceAlways:SetPoint("TOPLEFT", overview.EnforceOnCreate, "BOTTOMLEFT", 0, -12)
  overview.EnforceAlways:SetScript("OnClick", function(self)
    SetEnforceOrderAlways(self:GetChecked())
    UIOptions:Refresh()
  end)

  overview.Info = overviewContent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  overview.Info:SetPoint("TOPLEFT", overview.EnforceAlways, "BOTTOMLEFT", 2, -20)
  overview.Info:SetWidth(740)
  overview.Info:SetJustifyH("LEFT")
  overview.Info:SetText("Default managed order: Myth=1, Hero=2, Champion=3, Veteran=4, Adventurer=5, Season 1=6, S1 Crafted=7, Crafted=8.")

  overview.BottomMarker = CreateFrame("Frame", nil, overviewContent)
  overview.BottomMarker:SetSize(1, 1)
  overview.BottomMarker:SetPoint("TOPLEFT", overview.Info, "BOTTOMLEFT", 0, -24)

  local midnight = CreateFrame("Frame", nil, frame)
  midnight:SetPoint("TOPLEFT", 18, -58)
  midnight:SetPoint("BOTTOMRIGHT", -18, 18)
  frame.MidnightPanel = midnight

  midnight.ScrollFrame, midnight.Content = CreateScrollContent(midnight, 12, -12, -26, 12)
  local midnightContent = midnight.Content
  midnightContent:SetWidth(780)
  midnightContent:SetHeight(1)

  midnight.SectionLabel = midnightContent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  midnight.SectionLabel:SetPoint("TOPLEFT", 8, -8)
  midnight.SectionLabel:SetText("Midnight")

  midnight.SectionButtons = {}

  midnight.SectionButtons.crafted = CreateFixedButton(midnightContent, "Crafted", 110, 22)
  midnight.SectionButtons.crafted:SetPoint("TOPLEFT", midnight.SectionLabel, "BOTTOMLEFT", 0, -14)
  midnight.SectionButtons.crafted:SetScript("OnClick", function()
    UIOptions:SelectSection("crafted")
  end)

  midnight.SectionButtons.season1 = CreateFixedButton(midnightContent, "Season 1", 110, 22)
  midnight.SectionButtons.season1:SetPoint("LEFT", midnight.SectionButtons.crafted, "RIGHT", 8, 0)
  midnight.SectionButtons.season1:SetScript("OnClick", function()
    UIOptions:SelectSection("season1")
  end)

  midnight.ListInset = CreateFrame("Frame", nil, midnightContent, "InsetFrameTemplate")
  midnight.ListInset:SetPoint("TOPLEFT", midnight.SectionButtons.crafted, "BOTTOMLEFT", 0, -12)
  midnight.ListInset:SetWidth(200)
  midnight.ListInset:SetHeight(260)

  midnight.ListHeader = midnight.ListInset:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
  midnight.ListHeader:SetPoint("TOPLEFT", 14, -12)
  midnight.ListHeader:SetText("Categories")

  midnight.CategoryButtons = {}
  for index = 1, 6 do
    local button = CreateFixedButton(midnight.ListInset, "", 164, 24)

    if index == 1 then
      button:SetPoint("TOPLEFT", 14, -38)
    else
      button:SetPoint("TOPLEFT", midnight.CategoryButtons[index - 1], "BOTTOMLEFT", 0, -8)
    end

    button:SetScript("OnClick", function(self)
      if self.typeKey then
        UIOptions:SelectCategory(self.typeKey)
      end
    end)

    midnight.CategoryButtons[index] = button
  end

  local detail = CreateFrame("Frame", nil, midnightContent)
  detail:SetPoint("TOPLEFT", midnight.ListInset, "TOPRIGHT", 8, 0)
  detail:SetWidth(520)
  detail:SetHeight(1)
  frame.DetailPanel = detail

  detail.Title = detail:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  detail.Title:SetPoint("TOPLEFT", 0, 0)
  detail.Title:SetText("Category")

  detail.MainControlsBox = CreateSectionBox(detail, "Main Controls", 520, 140)
  detail.MainControlsBox:SetPoint("TOPLEFT", detail.Title, "BOTTOMLEFT", 0, -12)

  detail.Active = CreateCheckbox(
    detail.MainControlsBox,
    "Active",
    "Create/delete this category. If it is missing after reload, it will be restored.",
    65
  )
  detail.Active:SetPoint("TOPLEFT", 12, -36)
  detail.Active:SetScript("OnClick", function(self)
    local key = UIOptions:GetSelectedKey()
    if key then
      ToggleCategory(key, self:GetChecked())
      UIOptions:Refresh()
    end
  end)

  detail.Pinned = CreateCheckbox(
    detail.MainControlsBox,
    "Pinned",
    "Keep this category in BetterBags' pinned section.",
    65
  )
  detail.Pinned:SetPoint("LEFT", detail.Active, "RIGHT", 78, 0)
  detail.Pinned:SetScript("OnClick", function(self)
    local key = UIOptions:GetSelectedKey()
    if key then
      SetPinnedEnabled(key, self:GetChecked())
      UIOptions:Refresh()
    end
  end)

  detail.IncludeBoe = CreateCheckbox(
    detail.MainControlsBox,
    "Include BoE",
    "Include Bind on Equip items in this category.",
    88
  )
  detail.IncludeBoe:SetPoint("LEFT", detail.Pinned, "RIGHT", 78, 0)
  detail.IncludeBoe:SetScript("OnClick", function(self)
    local key = UIOptions:GetSelectedKey()
    if key then
      SetIncludeBoeEnabled(key, self:GetChecked())
      UIOptions:Refresh()
    end
  end)

  detail.IncludeBow = CreateCheckbox(
    detail.MainControlsBox,
    "Include BoW",
    "Include Warbound and Warbound until Equipped items in this category.",
    88
  )
  detail.IncludeBow:SetPoint("LEFT", detail.IncludeBoe, "RIGHT", 95, 0)
  detail.IncludeBow:SetScript("OnClick", function(self)
    local key = UIOptions:GetSelectedKey()
    if key then
      SetIncludeBowEnabled(key, self:GetChecked())
      UIOptions:Refresh()
    end
  end)

  detail.Status = detail.MainControlsBox:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  detail.Status:SetPoint("TOPLEFT", detail.Active, "BOTTOMLEFT", 2, -42)
  detail.Status:SetWidth(480)
  detail.Status:SetJustifyH("LEFT")

  detail.OrderBox = CreateSectionBox(detail, "Order", 520, 110)
  detail.OrderBox:SetPoint("TOPLEFT", detail.MainControlsBox, "BOTTOMLEFT", 0, -12)

  detail.OrderLabel = detail.OrderBox:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  detail.OrderLabel:SetPoint("TOPLEFT", 12, -36)
  detail.OrderLabel:SetText("Pinned Order")

  detail.OrderInput = CreateInput(detail.OrderBox, 90)
  detail.OrderInput:SetPoint("TOPLEFT", detail.OrderLabel, "BOTTOMLEFT", -2, -6)
  detail.OrderInput:SetScript("OnEnterPressed", function(self)
    UIOptions:SavePendingOrder(true)
    self:ClearFocus()
  end)
  detail.OrderInput:SetScript("OnEditFocusLost", function()
    UIOptions:SavePendingOrder(true)
  end)

  detail.ApplyOrder = CreateActionButton(detail.OrderBox, "Apply Order", 110)
  detail.ApplyOrder:SetPoint("LEFT", detail.OrderInput, "RIGHT", 10, 0)
  detail.ApplyOrder:SetScript("OnClick", function()
    local key = UIOptions:GetSelectedKey()
    if key then
      UIOptions:SavePendingOrder(false)
      ApplyPendingOrder(key)
      UIOptions:Refresh()
    end
  end)

  detail.OrderHelp = detail.OrderBox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  detail.OrderHelp:SetPoint("TOPLEFT", detail.OrderInput, "BOTTOMLEFT", 2, -10)
  detail.OrderHelp:SetWidth(470)
  detail.OrderHelp:SetJustifyH("LEFT")

  detail.NameBox = CreateSectionBox(detail, "Name", 520, 150)
  detail.NameBox:SetPoint("TOPLEFT", detail.OrderBox, "BOTTOMLEFT", 0, -12)

  detail.NameLabel = detail.NameBox:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  detail.NameLabel:SetPoint("TOPLEFT", 12, -36)
  detail.NameLabel:SetText("Name")

  detail.NameInput = CreateInput(detail.NameBox, 260)
  detail.NameInput:SetPoint("TOPLEFT", detail.NameLabel, "BOTTOMLEFT", -2, -6)
  detail.NameInput:SetScript("OnEnterPressed", function(self)
    UIOptions:SavePendingName(true)
    self:ClearFocus()
  end)
  detail.NameInput:SetScript("OnEditFocusLost", function()
    UIOptions:SavePendingName(true)
  end)

  detail.ApplyName = CreateActionButton(detail.NameBox, "Apply New Text", 120)
  detail.ApplyName:SetPoint("LEFT", detail.NameInput, "RIGHT", 10, 0)
  detail.ApplyName:SetScript("OnClick", function()
    local key = UIOptions:GetSelectedKey()
    if key then
      UIOptions:SavePendingName(false)
      ActivateCategory(key)
      UIOptions:Refresh()
    end
  end)

  detail.ResetText = CreateActionButton(detail.NameBox, "Reset Text", 100)
  detail.ResetText:SetPoint("LEFT", detail.ApplyName, "RIGHT", 8, 0)
  detail.ResetText:SetScript("OnClick", function()
    local key = UIOptions:GetSelectedKey()
    if key then
      local wasActive = GetState(key).active
      ResetPendingName(key)
      if wasActive then
        ActivateCategory(key)
      end
      UIOptions:Refresh()
    end
  end)

  detail.DefaultName = detail.NameBox:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  detail.DefaultName:SetPoint("TOPLEFT", detail.NameInput, "BOTTOMLEFT", 2, -14)
  detail.DefaultName:SetWidth(500)
  detail.DefaultName:SetJustifyH("LEFT")

  detail.CurrentName = detail.NameBox:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  detail.CurrentName:SetPoint("TOPLEFT", detail.DefaultName, "BOTTOMLEFT", 0, -10)
  detail.CurrentName:SetWidth(500)
  detail.CurrentName:SetJustifyH("LEFT")

  detail.ColourBox = CreateSectionBox(detail, "Colour", 520, 90)
  detail.ColourBox:SetPoint("TOPLEFT", detail.NameBox, "BOTTOMLEFT", 0, -12)

  detail.ColorLabel = detail.ColourBox:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  detail.ColorLabel:SetPoint("TOPLEFT", 12, -36)
  detail.ColorLabel:SetText("Text Color")

  detail.ColorSwatch = CreateColorSwatch(detail.ColourBox, function(color)
    local key = UIOptions:GetSelectedKey()
    if not key then
      return
    end

    local state = GetState(key)
    state.pendingColor = {
      r = color.r,
      g = color.g,
      b = color.b,
      a = 1,
    }

    NotifyAndRefresh()
  end)
  detail.ColorSwatch:SetPoint("LEFT", detail.ColorLabel, "RIGHT", 16, 0)

  detail.ResetColor = CreateActionButton(detail.ColourBox, "Reset Color", 100)
  detail.ResetColor:SetPoint("LEFT", detail.ColorSwatch, "RIGHT", 12, 0)
  detail.ResetColor:SetScript("OnClick", function()
    local key = UIOptions:GetSelectedKey()
    if key then
      local wasActive = GetState(key).active
      ResetPendingColor(key)
      if wasActive then
        ActivateCategory(key)
      end
      UIOptions:Refresh()
    end
  end)

  detail.PriorityBox = CreateSectionBox(detail, "Pickup Priority", 520, 130)
  detail.PriorityBox:SetPoint("TOPLEFT", detail.ColourBox, "BOTTOMLEFT", 0, -12)

  detail.PriorityLabel = detail.PriorityBox:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  detail.PriorityLabel:SetPoint("TOPLEFT", 12, -36)
  detail.PriorityLabel:SetText("Priority")

  detail.PriorityInput = CreateInput(detail.PriorityBox, 90)
  detail.PriorityInput:SetPoint("TOPLEFT", detail.PriorityLabel, "BOTTOMLEFT", -2, -6)
  detail.PriorityInput:SetScript("OnEnterPressed", function(self)
    UIOptions:SavePendingPriority(true)
    self:ClearFocus()
  end)
  detail.PriorityInput:SetScript("OnEditFocusLost", function()
    UIOptions:SavePendingPriority(true)
  end)

  detail.ApplyPriority = CreateActionButton(detail.PriorityBox, "Apply Priority", 120)
  detail.ApplyPriority:SetPoint("LEFT", detail.PriorityInput, "RIGHT", 10, 0)
  detail.ApplyPriority:SetScript("OnClick", function()
    local key = UIOptions:GetSelectedKey()
    if key then
      UIOptions:SavePendingPriority(false)

      local state = GetState(key)
      state.pendingPriority = GetPendingPriority(key)

      if state.active then
        ActivateCategory(key)
      else
        NotifyAndRefresh()
      end

      UIOptions:Refresh()
    end
  end)

  detail.CurrentOrder = detail.PriorityBox:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  detail.CurrentOrder:SetPoint("TOPLEFT", detail.PriorityInput, "BOTTOMLEFT", 2, -20)
  detail.CurrentOrder:SetWidth(500)
  detail.CurrentOrder:SetJustifyH("LEFT")

  midnight.BottomMarker = CreateFrame("Frame", nil, midnightContent)
  midnight.BottomMarker:SetSize(1, 1)
  midnight.BottomMarker:SetPoint("TOPLEFT", detail.PriorityBox, "BOTTOMLEFT", 0, -24)

  return frame
end

function UIOptions:EnsureWindow()
  if not self.window then
    self.window = self:CreateWindow()
  end

  return self.window
end

function UIOptions:Open(rootKey, sectionKey, typeKey)
  if rootKey then
    self.selectedRoot = rootKey
  end

  if sectionKey then
    self.selectedSection = sectionKey
  end

  if typeKey then
    self.selectedCategory = typeKey
  end

  local window = self:EnsureWindow()
  window:Show()
  window:Raise()
  self:Refresh()
end

local function OpenConfigWindow()
  UIOptions:Open()
end

local function RegisterSettingsShortcut()
  if UIOptions.settingsShortcutRegistered then
    return
  end

  if not Settings or not Settings.RegisterCanvasLayoutCategory then
    return
  end

  local optionsFrame = CreateFrame("Frame")

  local header = optionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge3")
  header:SetScale(2)
  header:SetPoint("CENTER", optionsFrame, 0, 42)
  header:SetText("Gear Categories")

  local instructions = optionsFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  instructions:SetPoint("CENTER", optionsFrame, 0, 2)
  instructions:SetText("Open the custom Gear Categories window.")

  --local template = "SharedButtonLargeTemplate"
  local template = "SharedButtonSmallTemplate"
  if not C_XMLUtil.GetTemplateInfo(template) then
    template = "UIPanelDynamicResizeButtonTemplate"
  end

  local button = CreateFrame("Button", nil, optionsFrame, template)
  button:SetText("Open Gear Categories")
  ResizeDynamicButton(button, 190)
  button:SetPoint("CENTER", optionsFrame, 0, -34)
  button:SetScript("OnClick", function()
    OpenConfigWindow()
  end)

  optionsFrame.OnCommit = function() end
  optionsFrame.OnDefault = function() end
  optionsFrame.OnRefresh = function() end

  local category = Settings.RegisterCanvasLayoutCategory(optionsFrame, "Gear Categories")
  category.ID = "BetterBagsGearCategories"
  Settings.RegisterAddOnCategory(category)

  UIOptions.settingsShortcutRegistered = true
end

---@class AceConfig.OptionsTable
local gearCategoriesConfigOptions = {
  openWindow = {
    type = "execute",
    name = "Open Gear Categories",
    order = 1,
    func = function()
      OpenConfigWindow()
    end,
  },
}

if AceConfig and AceConfig.RegisterOptionsTable then
  AceConfig:RegisterOptionsTable("BBGT_Window", {
    type = "group",
    name = "BetterBags - Gear Categories",
    args = gearCategoriesConfigOptions,
  })
end

if config.AddPluginConfig then
  config:AddPluginConfig("Gear Categories", gearCategoriesConfigOptions)
else
  print("BetterBags_GearCategories NOT loaded. BetterBags Plugin API Incompatible.")
end

RegisterSettingsShortcut()