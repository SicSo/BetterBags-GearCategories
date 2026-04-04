BBTC = BBTC or {}
BBTC.UIOptions = BBTC.UIOptions or {}
BBTC.PopupUI = BBTC.PopupUI or {}

local UIOptions = BBTC.UIOptions
local PopupUI = BBTC.PopupUI

local GetState = BBTC.GetState
local GetTypeDef = BBTC.GetTypeDef
local EnsureDB = BBTC.EnsureDB
local ToggleCategory = BBTC.ToggleCategory
local SetPinnedEnabled = BBTC.SetPinnedEnabled

local POPUP_WINDOW_NAME = "BBTCSeasonPopupWindow"
local CATEGORY_KEYS = {  "season", "myth", "hero", "champ", "vet", "adv", "s1craft" }

BBTC_POPUP_VERSION = 1

local function ResizeDynamicButton(button, minWidth)
  if DynamicResizeButton_Resize then
    DynamicResizeButton_Resize(button)
  end

  local fontString = button:GetFontString()
  local textWidth = fontString and fontString:GetStringWidth() or 0
  local width = math.max(minWidth or 0, textWidth + 40, 90)
  button:SetWidth(width)
end

local function CreateFixedButton(parent, text, width, height)
  local button = CreateFrame("Button", nil, parent, "SharedButtonSmallTemplate")
  button:SetSize(width, height or 22)
  button:SetText(text)
  return button
end

local function CreateActionButton(parent, text, minWidth)
  local button = CreateFrame("Button", nil, parent, "SharedButtonSmallTemplate")
  button:SetText(text)
  ResizeDynamicButton(button, minWidth)
  return button
end

local function CreateCheckIcon(parent, tooltipText, onClick)
  local button = CreateFrame("Button", nil, parent)
  button:SetSize(18, 18)
  button:RegisterForClicks("LeftButtonUp")

  button.bg = button:CreateTexture(nil, "BACKGROUND")
  button.bg:SetAllPoints()
  button.bg:SetColorTexture(0.12, 0.12, 0.12, 0.9)

  button.tex = button:CreateTexture(nil, "ARTWORK")
  button.tex:SetAllPoints()
  button.tex:SetAtlas("common-icon-checkmark")

  if tooltipText and tooltipText ~= "" then
    button:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:SetText(tooltipText, 1, 1, 1, 1, true)
    end)

    button:SetScript("OnLeave", function()
      GameTooltip_Hide()
    end)
  end

  if onClick then
    button:SetScript("OnClick", function(self)
      onClick(self)
    end)
  end

  function button:SetChecked(checked)
    self.tex:SetShown(not not checked)
    self:SetAlpha(checked and 1 or 0.35)
  end

  return button
end

local function GetSectionForKey(key)
  if key == "season" or key == "adv" or key == "vet" or key == "champ" or key == "hero" or key == "myth" then
    return "season1"
  end

  return "crafted"
end

local function GetPopupSettings()
  if not EnsureDB then
    return nil
  end

  local db = EnsureDB()
  if not db then
    return nil
  end

  db.profile = db.profile or {}
  db.profile.settings = db.profile.settings or {}

  if db.profile.settings.popupVersion == nil then
    db.profile.settings.popupVersion = 0
  else
    db.profile.settings.popupVersion = tonumber(db.profile.settings.popupVersion) or 0
  end

  return db.profile.settings
end

function PopupUI:ShouldOpenOnLogin()
  local settings = GetPopupSettings()
  if not settings then
    return true
  end

  local savedVersion = tonumber(settings.popupVersion) or 0
  local currentVersion = tonumber(BBTC_POPUP_VERSION) or 0
  return savedVersion ~= currentVersion
end

function PopupUI:MarkShown()
  local settings = GetPopupSettings()
  if not settings then
    return
  end

  settings.popupVersion = tonumber(BBTC_POPUP_VERSION) or 0
end

local function CreateRow(parent, previousRow, key)
  local row = CreateFrame("Frame", nil, parent)
  row:SetSize(640, 28)

  if previousRow then
    row:SetPoint("TOPLEFT", previousRow, "BOTTOMLEFT", 0, -8)
  else
    row:SetPoint("TOPLEFT", 24, -160)
  end

  row.Name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  row.Name:SetPoint("LEFT", 0, 0)
  row.Name:SetWidth(300)
  row.Name:SetJustifyH("LEFT")

  row.ActiveIcon = CreateCheckIcon(row, "Click to toggle whether the category is active.", function()
    if not GetState or not ToggleCategory then
      return
    end

    local state = GetState(key)
    if not state then
      return
    end

    ToggleCategory(key, not state.active)
    PopupUI:Refresh()
  end)
  row.ActiveIcon:SetPoint("LEFT", row, "LEFT", 340, 0)

  row.PinnedIcon = CreateCheckIcon(row, "Click to toggle whether the category is pinned.", function()
    if not GetState or not SetPinnedEnabled then
      return
    end

    local state = GetState(key)
    if not state then
      return
    end

    SetPinnedEnabled(key, not state.pinned)
    PopupUI:Refresh()
  end)
  row.PinnedIcon:SetPoint("LEFT", row, "LEFT", 435, 0)

  row.OpenButton = CreateActionButton(row, "More Options", 100)
  row.OpenButton:SetPoint("LEFT", row, "LEFT", 525, 0)
  row.OpenButton:SetScript("OnClick", function()
    if UIOptions and UIOptions.Open then
      UIOptions:Open("midnight", GetSectionForKey(key), key)
    end

    if PopupUI.window then
      PopupUI.window:Hide()
    end
  end)

  row.key = key
  return row
end

function PopupUI:Refresh()
  if not self.window then
    return
  end

  for _, row in ipairs(self.window.Rows or {}) do
    local def = GetTypeDef and GetTypeDef(row.key)
    local state = GetState and GetState(row.key)

    if def and state then
      local nameText = def.treeName or def.defaultName or row.key
      if UIOptions and UIOptions.ColourText and BBTC.GetPendingColor then
        nameText = UIOptions:ColourText(nameText, BBTC.GetPendingColor(row.key))
      end

      row.Name:SetText(nameText)
      row.ActiveIcon:SetChecked(state.active)
      row.PinnedIcon:SetChecked(state.pinned)

      row.ActiveIcon:SetEnabled(true)
      row.PinnedIcon:SetEnabled(state.active)

      if state.active then
        row.PinnedIcon:SetAlpha(state.pinned and 1 or 0.35)
      else
        row.PinnedIcon:SetAlpha(0.2)
      end

      row:Show()
    else
      row.Name:SetText(row.key)
      row.ActiveIcon:SetChecked(false)
      row.PinnedIcon:SetChecked(false)
      row.ActiveIcon:SetEnabled(false)
      row.PinnedIcon:SetEnabled(false)
      row:Show()
    end
  end
end

function PopupUI:CreateWindow()
  local frame = CreateFrame("Frame", POPUP_WINDOW_NAME, UIParent, "ButtonFrameTemplate")
  frame:SetSize(760, 500)
  frame:SetPoint("CENTER")
  frame:SetToplevel(true)
  frame:SetMovable(true)
  frame:SetClampedToScreen(true)
  frame:EnableMouse(true)

  if frame.SetTitle then
    frame:SetTitle("BetterBags - Gear Categories (Midnight Season 1)")
  elseif frame.TitleText then
    frame.TitleText:SetText("BetterBags - Gear Categories (Midnight Season 1)")
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
  frame.DragArea:SetPoint("TOPRIGHT", -34, -6)
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

  frame:SetScript("OnShow", function()
    PopupUI:Refresh()
  end)

  if not tContains(UISpecialFrames, frame:GetName()) then
    table.insert(UISpecialFrames, frame:GetName())
  end

  frame.Header = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  frame.Header:SetPoint("TOPLEFT", 24, -44)
  frame.Header:SetText("Midnight / Season 1")

  frame.Description = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.Description:SetPoint("TOPLEFT", frame.Header, "BOTTOMLEFT", 0, -10)
  frame.Description:SetWidth(700)
  frame.Description:SetJustifyH("LEFT")
  frame.Description:SetText("Latest season categories. Each row shows whether the category is active, whether it is pinned, and gives you a shortcut to open that category in the main UI.")

  frame.NameHeader = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  frame.NameHeader:SetPoint("TOPLEFT", frame.Description, "BOTTOMLEFT", 0, -28)
  frame.NameHeader:SetWidth(300)
  frame.NameHeader:SetJustifyH("LEFT")
  frame.NameHeader:SetText("Category")

  frame.ActiveHeader = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  frame.ActiveHeader:SetPoint("LEFT", frame.NameHeader, "LEFT", 340, 0)
  frame.ActiveHeader:SetWidth(70)
  frame.ActiveHeader:SetJustifyH("LEFT")
  frame.ActiveHeader:SetText("Active")

  frame.PinnedHeader = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  frame.PinnedHeader:SetPoint("LEFT", frame.NameHeader, "LEFT", 435, 0)
  frame.PinnedHeader:SetWidth(70)
  frame.PinnedHeader:SetJustifyH("LEFT")
  frame.PinnedHeader:SetText("Pinned")

  frame.OpenHeader = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  frame.OpenHeader:SetPoint("LEFT", frame.NameHeader, "LEFT", 525, 0)
  frame.OpenHeader:SetWidth(90)
  frame.OpenHeader:SetJustifyH("LEFT")
  frame.OpenHeader:SetText("More Options")

  frame.Separator = frame:CreateTexture(nil, "ARTWORK")
  frame.Separator:SetColorTexture(1, 1, 1, 0.12)
  frame.Separator:SetHeight(1)
  frame.Separator:SetPoint("TOPLEFT", frame.NameHeader, "BOTTOMLEFT", 0, -8)
  frame.Separator:SetPoint("TOPRIGHT", -24, frame.NameHeader:GetBottom() - 8)

  frame.Rows = {}
  local previousRow
  for _, key in ipairs(CATEGORY_KEYS) do
    local row = CreateRow(frame, previousRow, key)
    frame.Rows[#frame.Rows + 1] = row
    previousRow = row
  end

  frame.CloseSpacer = CreateFrame("Frame", nil, frame)
  frame.CloseSpacer:SetSize(1, 34)
  frame.CloseSpacer:SetPoint("TOPLEFT", previousRow, "BOTTOMLEFT", 0, -18)

  frame.CloseButtonBottom = CreateFixedButton(frame, "Close", 80, 22)
  frame.CloseButtonBottom:SetPoint("TOPLEFT", frame.CloseSpacer, "BOTTOMLEFT", 0, -8)
  frame.CloseButtonBottom:SetScript("OnClick", function()
    frame:Hide()
  end)

  return frame
end

function PopupUI:EnsureWindow()
  if not self.window then
    self.window = self:CreateWindow()
  end

  return self.window
end

function PopupUI:Open(markShown)
  local window = self:EnsureWindow()
  window:Show()
  window:Raise()
  self:Refresh()

  if markShown then
    self:MarkShown()
  end
end

function PopupUI:OpenOnLoginIfNeeded()
  if self:ShouldOpenOnLogin() then
    self:Open(true)
  end
end

function PopupUI:AttachButtonToMainWindow(window)
  if not window or window.PopupShortcutButton then
    return
  end

  local button = CreateActionButton(window, "Current Season Config", 180)
  button:ClearAllPoints()
  button:SetPoint("TOP", window, "TOP", 0, -54)
  button:SetScript("OnClick", function()
    PopupUI:Open(false)
  end)

  window.PopupShortcutButton = button

  local function UpdateLayout()
    local show = UIOptions and UIOptions.selectedRoot == "overview"

    button:SetShown(show)

    if window.OverviewPanel then
      window.OverviewPanel:ClearAllPoints()
      if show then
        window.OverviewPanel:SetPoint("TOPLEFT", 18, -86)
      else
        window.OverviewPanel:SetPoint("TOPLEFT", 18, -58)
      end
      window.OverviewPanel:SetPoint("BOTTOMRIGHT", -18, 18)
    end

    if window.MidnightPanel then
      window.MidnightPanel:ClearAllPoints()
      if show then
        window.MidnightPanel:SetPoint("TOPLEFT", 18, -86)
      else
        window.MidnightPanel:SetPoint("TOPLEFT", 18, -58)
      end
      window.MidnightPanel:SetPoint("BOTTOMRIGHT", -18, 18)
    end
  end

  if not window._bbtcPopupHooked then
    window._bbtcPopupHooked = true

    if UIOptions and UIOptions.Refresh then
      hooksecurefunc(UIOptions, "Refresh", function()
        UpdateLayout()
      end)
    end
  end

  UpdateLayout()
end

local function TryAttachButton()
  if UIOptions and UIOptions.window then
    PopupUI:AttachButtonToMainWindow(UIOptions.window)
    return true
  end

  return false
end

local hookupFrame = CreateFrame("Frame")
hookupFrame:RegisterEvent("PLAYER_LOGIN")
hookupFrame:SetScript("OnEvent", function()
  if UIOptions and UIOptions.CreateWindow then
    hooksecurefunc(UIOptions, "CreateWindow", function()
      C_Timer.After(0, function()
        if UIOptions.window then
          PopupUI:AttachButtonToMainWindow(UIOptions.window)
        end
      end)
    end)
  end

  C_Timer.After(0.2, function()
    TryAttachButton()
    PopupUI:OpenOnLoginIfNeeded()
  end)
end)

SLASH_BBTCPOPUP1 = "/bbtcpopup"
SlashCmdList.BBTCPOPUP = function()
  PopupUI:Open(false)
end