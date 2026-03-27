-- UI.lua

BBTC = BBTC or {}
BBTC.UIOptions = BBTC.UIOptions or {}

local UIOptions = BBTC.UIOptions

local config = BBTC.config
local AceConfig = BBTC.AceConfig
local AceConfigDialog = BBTC.AceConfigDialog

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

local function OpenConfigWindow()
  AceConfigDialog:Open("BBGT_Window")
end

local function MakeTypeGroup(key, order)
  local def = GetTypeDef(key)
  local actualOrder = order or def.order or 999

  return {
    type = "group",
    name = function()
      return UIOptions:ColourText(def.treeName, GetPendingColor(key))
    end,
    order = actualOrder,
    args = {
      active = {
        type = "toggle",
        name = "Active",
        desc = "Create/delete this category. If it is missing after reload, it will be restored.",
        order = 1,
        get = function()
          return GetState(key).active
        end,
        set = function(_, value)
          ToggleCategory(key, value)
        end,
      },
      pinned = {
        type = "toggle",
        name = "Pinned",
        desc = "Keep this category in BetterBags' pinned section.",
        order = 1.1,
        get = function()
          return GetState(key).pinned
        end,
        set = function(_, value)
          SetPinnedEnabled(key, value)
        end,
      },
      includeBoe = {
        type = "toggle",
        name = "Include BoE (can be BoW)",
        desc = "Include Bind on Equip items in this category.",
        order = 1.2,
        get = function()
          return not not GetState(key).pendingIncludeBoe
        end,
        set = function(_, value)
          BBTC.SetIncludeBoeEnabled(key, value)
        end,
      },
      includeBow = {
        type = "toggle",
        name = "Include BoW",
        desc = "Include Warbound and Warbound until Equipped items in this category.",
        order = 1.3,
        get = function()
          return not not GetState(key).pendingIncludeBow
        end,
        set = function(_, value)
          BBTC.SetIncludeBowEnabled(key, value)
        end,
      },

      orderSpacer = {
        type = "description",
        name = "",
        order = 1.35,
        width = "full",
      },
      pendingOrder = {
        type = "input",
        name = "Pinned Order",
        width = 0.8,
        order = 1.4,
        disabled = function()
          return not GetState(key).pinned
        end,
        get = function()
          return tostring(GetPendingOrder(key))
        end,
        set = function(_, value)
          local state = GetState(key)
          state.pendingOrder = value
          NotifyConfigChanged()
        end,
      },
      applyOrder = {
        type = "execute",
        name = "Apply Order",
        width = 1.2,
        order = 1.5,
        disabled = function()
          return not GetState(key).pinned
        end,
        func = function()
          ApplyPendingOrder(key)
        end,
      },
      orderHelp = {
        type = "description",
        name = function()
          return "Lower number = higher in pinned list. Range: 1-" .. tostring(GetMaxManagedOrder())
        end,
        order = 1.6,
        width = "full",
      },

      pendingName = {
        type = "input",
        name = "Name",
        width = "full",
        order = 2,
        get = function()
          local state = GetState(key)
          return state.pendingName or def.defaultName
        end,
        set = function(_, value)
          local state = GetState(key)
          state.pendingName = value
          NotifyConfigChanged()
        end,
      },
      activate = {
        type = "execute",
        name = "Apply New Text",
        width = 1.2,
        order = 3,
        func = function()
          ActivateCategory(key)
        end,
      },
      resetText = {
        type = "execute",
        name = "Reset Text",
        width = 1.2,
        order = 3.1,
        func = function()
          local wasActive = GetState(key).active
          ResetPendingName(key)
          if wasActive then
            ActivateCategory(key)
          end
        end,
      },
      textColor = {
        type = "color",
        name = "Text Color",
        hasAlpha = false,
        width = "full",
        order = 4,
        get = function()
          local color = GetPendingColor(key)
          return color.r, color.g, color.b
        end,
        set = function(_, r, g, b)
          local state = GetState(key)
          state.pendingColor = {
            r = r,
            g = g,
            b = b,
            a = 1,
          }
          NotifyConfigChanged()
        end,
      },
      gap1 = {
        type = "description",
        name = "",
        order = 4.5,
        width = "full",
      },
      priorityInput = {
        type = "input",
        name = "Priority",
        width = 0.8,
        order = 5,
        get = function()
          return tostring(GetPendingPriority(key))
        end,
        set = function(_, value)
          local state = GetState(key)
          state.pendingPriority = value
          NotifyConfigChanged()
        end,
      },
      applyPriority = {
        type = "execute",
        name = "Apply Priority",
        width = 1.2,
        order = 6,
        func = function()
          local wasActive = GetState(key).active
          local state = GetState(key)
          state.pendingPriority = GetPendingPriority(key)
          if wasActive then
            ActivateCategory(key)
          else
            NotifyConfigChanged()
          end
        end,
      },
      gap2 = {
        type = "description",
        name = "",
        order = 6.5,
        width = "full",
      },
      resetColor = {
        type = "execute",
        name = "Reset Color",
        order = 8,
        func = function()
          local wasActive = GetState(key).active
          ResetPendingColor(key)
          if wasActive then
            ActivateCategory(key)
          end
        end,
      },
      defaultName = {
        type = "description",
        name = "Default: " .. def.defaultName,
        order = 9,
      },
      currentName = {
        type = "description",
        name = function()
          local state = GetState(key)
          if state.active and state.plainActiveName then
            return "Current active name: " .. state.plainActiveName
          end
          return "Current active name: (not active)"
        end,
        order = 10,
      },
      currentOrder = {
        type = "description",
        name = function()
          local state = GetState(key)
          if state.active and state.activeOrder then
            return "Current active pinned order: " .. tostring(state.activeOrder)
          end
          return "Current active pinned order: (not active)"
        end,
        order = 10.1,
      },
      status = {
        type = "description",
        name = function()
          return GetStatusText(key)
        end,
        order = 11,
      },
    },
  }
end

local windowOptions = {
  type = "group",
  name = "BetterBags - Gear Categories",
  childGroups = "tree",
  args = {
    overview = {
      type = "group",
      name = "Main",
      order = 0,
      inline = false,
      args = {
        orderingHeader = {
          type = "header",
          name = "Ordering",
          order = 1,
        },
        enforceOrderOnCreate = {
          type = "toggle",
          name = "Enforce order at creation/update",
          desc = "When a managed pinned category is created or updated, write its pinned order into BetterBags.",
          order = 2,
          width = "full",
          get = function()
            return GetSettings().enforceOrderOnCreate
          end,
          set = function(_, value)
            SetEnforceOrderOnCreate(value)
          end,
        },
        enforceOrderAlways = {
          type = "toggle",
          name = "Enforce order permanently",
          desc = "Keep reapplying the managed pinned order when categories change.",
          order = 3,
          width = "full",
          get = function()
            return GetSettings().enforceOrderAlways
          end,
          set = function(_, value)
            SetEnforceOrderAlways(value)
          end,
        },
        orderingInfo = {
          type = "description",
          name = "Default managed order: Myth=1, Hero=2, Champion=3, Veteran=4, Adventurer=5, Season 1=6, S1 Crafted=7, Crafted=8.",
          order = 4,
          width = "full",
        },
      },
    },

    midnight = {
      type = "group",
      name = "Midnight",
      order = 1,
      args = {
        crafted = {
          type = "group",
          name = "Crafted",
          order = 1,
          args = {
            craftedGroup = MakeTypeGroup("crafted", 1),
            s1craftGroup = MakeTypeGroup("s1craft", 2),
          },
        },
        season1 = {
          type = "group",
          name = "Season 1",
          order = 2,
          args = {
            seasonGroup = MakeTypeGroup("season", 1),
            advGroup = MakeTypeGroup("adv", 2),
            vetGroup = MakeTypeGroup("vet", 3),
            champGroup = MakeTypeGroup("champ", 4),
            heroGroup = MakeTypeGroup("hero", 5),
            mythGroup = MakeTypeGroup("myth", 6),
          },
        },
      },
    },
  },
}

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

AceConfig:RegisterOptionsTable("BBGT_Window", windowOptions)
AceConfigDialog:SetDefaultSize("BBGT_Window", 750, 520)

if config.AddPluginConfig then
  config:AddPluginConfig("Gear Categories", gearCategoriesConfigOptions)
else
  print("BetterBags_GearCategories NOT loaded. BetterBags Plugin API Incompatible.")
end