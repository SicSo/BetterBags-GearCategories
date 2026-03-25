-- Backend.lua

BBTC = BBTC or {}
BBTC.UIOptions = BBTC.UIOptions or {}

local UIOptions = BBTC.UIOptions

local addon = BBTC.addon
local database = addon and addon:GetModule('Database')
local const = addon and addon:GetModule('Constants')

local categories = BBTC.categories
local events = BBTC.events
local L = BBTC.L
local AceDB = BBTC.AceDB
local AceConfigRegistry = BBTC.AceConfigRegistry
local mycontext = BBTC.mycontext

local TYPE_DEFS = BBTC.TYPE_DEFS
local defaults = BBTC.defaults

local DEFAULT_PROFILE_NAME = "Default"
local restoreStarted = false
local categoriesReady = false

local EXPANSION_MIDNIGHT = "midnight"
local SEASON_1 = "s1"
local CRAFTED_GROUP = "crafted"

local CATEGORY_ORDER = {
  "crafted",
  "season",
  "adv",
  "vet",
  "champ",
  "hero",
  "myth",
  "s1craft",
}

local CATEGORY_PATHS = {
  season  = { expansion = EXPANSION_MIDNIGHT, season = SEASON_1, category = "season"  },
  adv     = { expansion = EXPANSION_MIDNIGHT, season = SEASON_1, category = "adv"     },
  vet     = { expansion = EXPANSION_MIDNIGHT, season = SEASON_1, category = "vet"     },
  champ   = { expansion = EXPANSION_MIDNIGHT, season = SEASON_1, category = "champ"   },
  hero    = { expansion = EXPANSION_MIDNIGHT, season = SEASON_1, category = "hero"    },
  myth    = { expansion = EXPANSION_MIDNIGHT, season = SEASON_1, category = "myth"    },
  crafted = { expansion = EXPANSION_MIDNIGHT, crafted = CRAFTED_GROUP, category = "crafted" },
  s1craft = { expansion = EXPANSION_MIDNIGHT, crafted = CRAFTED_GROUP, category = "s1craft" },
}

local GetQueryForKey

local function GetTypeDef(key)
  local path = CATEGORY_PATHS[key]
  if not path then
    return nil
  end

  local expansionDef = TYPE_DEFS[path.expansion]
  if not expansionDef then
    return nil
  end

  if path.season then
    local seasonDef = expansionDef.seasons and expansionDef.seasons[path.season]
    return seasonDef and seasonDef.categories and seasonDef.categories[path.category] or nil
  end

  if path.crafted then
    local craftedDef = expansionDef.crafted
    return craftedDef and craftedDef.categories and craftedDef.categories[path.category] or nil
  end

  return nil
end

local function EnsureDB()
  if not BBTC.db then
    BBTC.db = AceDB:New("BBGT_DB", defaults, DEFAULT_PROFILE_NAME)
  end

  if BBTC.db.GetCurrentProfile and BBTC.db:GetCurrentProfile() ~= DEFAULT_PROFILE_NAME then
    BBTC.db:SetProfile(DEFAULT_PROFILE_NAME)
  end

  return BBTC.db
end

local function NotifyConfigChanged()
  if AceConfigRegistry and AceConfigRegistry.NotifyChange then
    AceConfigRegistry:NotifyChange("BBGT_Window")
  end
end

local function NormalizeColor(color, fallback)
  local src = color or fallback or { r = 1, g = 1, b = 1, a = 1 }

  local r = tonumber(src.r or src[1] or (fallback and (fallback.r or fallback[1])) or 1) or 1
  local g = tonumber(src.g or src[2] or (fallback and (fallback.g or fallback[2])) or 1) or 1
  local b = tonumber(src.b or src[3] or (fallback and (fallback.b or fallback[3])) or 1) or 1
  local a = tonumber(src.a or src[4] or (fallback and (fallback.a or fallback[4])) or 1) or 1

  if r < 0 then r = 0 elseif r > 1 then r = 1 end
  if g < 0 then g = 0 elseif g > 1 then g = 1 end
  if b < 0 then b = 0 elseif b > 1 then b = 1 end
  if a < 0 then a = 0 elseif a > 1 then a = 1 end

  return {
    r = r,
    g = g,
    b = b,
    a = a,
  }
end

local function RefreshBags()
  if events and mycontext then
    events:SendMessage(mycontext, "bags/FullRefreshAll")
  end
end

local function GetNextPinnedIndex(pinnedList)
  local nextIndex = 1

  for _, index in pairs(pinnedList or {}) do
    if type(index) == "number" and index >= nextIndex then
      nextIndex = index + 1
    end
  end

  return nextIndex
end

local function SetCategoryPinnedByName(name, pinned, skipRefresh)
  if not database or not const or not name or name == "" then
    return
  end

  local changed = false
  local strippedName = UIOptions:StripColourCodes(name)
  local bagKinds = {
    const.BAG_KIND.BACKPACK,
    const.BAG_KIND.BANK,
  }

  for _, kind in ipairs(bagKinds) do
    local pinnedList = database:GetCustomSectionSort(kind)
    if pinnedList then
      if pinned then
        if pinnedList[name] == nil then
          database:SetCustomSectionSort(kind, name, GetNextPinnedIndex(pinnedList))
          if strippedName ~= name then
            pinnedList[strippedName] = nil
          end
          changed = true
        end
      else
        if pinnedList[name] ~= nil then
          pinnedList[name] = nil
          changed = true
        end
        if strippedName ~= name and pinnedList[strippedName] ~= nil then
          pinnedList[strippedName] = nil
          changed = true
        end
      end
    end
  end

  if changed and not skipRefresh then
    RefreshBags()
  end
end

local function NormalizePriority(key, value)
  local def = GetTypeDef(key)
  local n = tonumber(value)
  if not n then
    return def.defaultPriority
  end

  return math.floor(n)
end

local function EnsureCategoryStateShape(key, state)
  local def = GetTypeDef(key)

  if state.active == nil then
    state.active = false
  else
    state.active = not not state.active
  end

  if state.activeName == nil then
    state.activeName = nil
  end

  if state.plainActiveName == nil then
    state.plainActiveName = nil
  end

  if state.activeColor ~= nil then
    state.activeColor = NormalizeColor(state.activeColor, def.defaultColor)
  end

  if state.activePriority ~= nil then
    state.activePriority = NormalizePriority(key, state.activePriority)
  end

  if state.activeIncludeBoe == nil then
    state.activeIncludeBoe = nil
  else
    state.activeIncludeBoe = not not state.activeIncludeBoe
  end

  if state.activeIncludeBow == nil then
    state.activeIncludeBow = nil
  else
    state.activeIncludeBow = not not state.activeIncludeBow
  end

  if state.pendingName == nil then
    state.pendingName = def.defaultName
  end

  state.pendingColor = NormalizeColor(
    state.pendingColor or UIOptions:CopyColour(def.defaultColor),
    def.defaultColor
  )

  if state.pendingPriority == nil then
    state.pendingPriority = def.defaultPriority
  else
    state.pendingPriority = NormalizePriority(key, state.pendingPriority)
  end

  if state.pendingIncludeBoe == nil then
    state.pendingIncludeBoe = false
  else
    state.pendingIncludeBoe = not not state.pendingIncludeBoe
  end

  if state.pendingIncludeBow == nil then
    state.pendingIncludeBow = false
  else
    state.pendingIncludeBow = not not state.pendingIncludeBow
  end

  if state.pinned == nil then
    state.pinned = true
  else
    state.pinned = not not state.pinned
  end

  return state
end

local function GetCategoryStateTable(db, key)
  db.profile = db.profile or {}
  db.profile.expansions = db.profile.expansions or {}

  local path = CATEGORY_PATHS[key]
  if not path then
    return nil
  end

  db.profile.expansions[path.expansion] = db.profile.expansions[path.expansion] or {}
  local expansionDb = db.profile.expansions[path.expansion]

  if path.season then
    expansionDb.seasons = expansionDb.seasons or {}
    expansionDb.seasons[path.season] = expansionDb.seasons[path.season] or {}
    expansionDb.seasons[path.season].categories = expansionDb.seasons[path.season].categories or {}

    local categoriesDb = expansionDb.seasons[path.season].categories
    categoriesDb[path.category] = categoriesDb[path.category] or {}
    return categoriesDb[path.category]
  end

  if path.crafted then
    expansionDb.crafted = expansionDb.crafted or {}
    expansionDb.crafted.categories = expansionDb.crafted.categories or {}

    local categoriesDb = expansionDb.crafted.categories
    categoriesDb[path.category] = categoriesDb[path.category] or {}
    return categoriesDb[path.category]
  end

  return nil
end

local function MigrateLegacyCategories(db)
  db.profile = db.profile or {}

  local legacy = db.profile.categories
  if type(legacy) ~= "table" then
    return
  end

  for key, oldState in pairs(legacy) do
    if CATEGORY_PATHS[key] and type(oldState) == "table" then
      local newState = GetCategoryStateTable(db, key)
      if newState then
        for field, value in pairs(oldState) do
          if newState[field] == nil then
            if type(value) == "table" then
              local copy = {}
              for k, v in pairs(value) do
                copy[k] = v
              end
              newState[field] = copy
            else
              newState[field] = value
            end
          end
        end
      end
    end
  end

  db.profile.categories = nil
end

local function GetState(key)
  local db = EnsureDB()
  MigrateLegacyCategories(db)

  local state = GetCategoryStateTable(db, key)
  if not state then
    state = {}
  end

  return EnsureCategoryStateShape(key, state)
end

local function SetPinnedEnabled(key, value)
  local state = GetState(key)
  state.pinned = not not value

  if state.activeName then
    SetCategoryPinnedByName(state.activeName, state.pinned)
  end

  NotifyConfigChanged()
end

local function NormalizeName(key, value)
  local def = GetTypeDef(key)
  local text = value

  if type(text) ~= "string" then
    text = ""
  end

  text = text:gsub("^%s+", ""):gsub("%s+$", "")

  if text == "" then
    return def.defaultName
  end

  return text
end

local function GetPendingColor(key)
  local state = GetState(key)
  local def = GetTypeDef(key)
  return NormalizeColor(state.pendingColor, def.defaultColor)
end

local function GetCategoryName(key, plainName, color)
  return UIOptions:ColourText(plainName, color or GetPendingColor(key))
end

local function BuildSeasonQuery()
  local parts = {}
  local ordered = { "adv", "vet", "champ", "hero", "myth" }

  for _, key in ipairs(ordered) do
    local def = GetTypeDef(key)
    local state = GetState(key)
    if def and def.includeInSeason and state and state.active and def.query then
      table.insert(parts, def.query)
    end
  end

  return table.concat(parts, " or ")
end

local function BuildBaseQueryForKey(key)
  if key == "season" then
    return BuildSeasonQuery()
  end

  local def = GetTypeDef(key)
  return def and def.query or nil
end

GetQueryForKey = function(key)
  local baseQuery = BuildBaseQueryForKey(key)
  if not baseQuery or baseQuery == "" then
    return baseQuery
  end

  if BBTC.BuildFilteredQuery then
    return BBTC.BuildFilteredQuery(key, baseQuery)
  end

  return baseQuery
end

local function GetPendingPriority(key)
  local state = GetState(key)
  return NormalizePriority(key, state.pendingPriority)
end

local function ResetPendingPriority(key)
  local state = GetState(key)
  local def = GetTypeDef(key)
  state.pendingPriority = def.defaultPriority
  NotifyConfigChanged()
end

local function ResetPendingIncludeBoe(key)
  local state = GetState(key)
  state.pendingIncludeBoe = false
  NotifyConfigChanged()
end

local function ResetPendingIncludeBow(key)
  local state = GetState(key)
  state.pendingIncludeBow = false
  NotifyConfigChanged()
end

local function AreCategoriesReady()
  if not categories then
    return false
  end

  if type(categories.CreateCategory) ~= "function" then
    return false
  end

  if type(categories.DeleteCategory) ~= "function" then
    return false
  end

  if type(categories.GetAllCategories) == "function" then
    local ok, result = pcall(categories.GetAllCategories, categories)
    if ok and type(result) == "table" then
      return true
    end
  end

  return false
end

local function UpdateCategoriesReadyState()
  categoriesReady = AreCategoriesReady()
  return categoriesReady
end

local function FindManagedCategory(key, plainName, query)
  if not UpdateCategoriesReadyState() then
    return nil, nil
  end

  if not categories or not categories.GetAllCategories then
    return nil, nil
  end

  local expectedStrippedName = UIOptions:StripColourCodes(GetCategoryName(key, plainName, GetPendingColor(key)))

  local ok, result = pcall(categories.GetAllCategories, categories)
  if not ok or type(result) ~= "table" then
    return nil, nil
  end

  local fallbackKey, fallbackData = nil, nil

  for categoryKey, categoryData in pairs(result) do
    if type(categoryData) == "table" then
      local dataName = tostring(categoryData.name or "")
      local strippedKey = UIOptions:StripColourCodes(tostring(categoryKey or ""))
      local strippedDataName = UIOptions:StripColourCodes(dataName)
      local dataQuery = categoryData.searchCategory and categoryData.searchCategory.query or nil

      if dataQuery == query then
        return categoryKey, categoryData
      end

      if strippedKey == expectedStrippedName or strippedDataName == expectedStrippedName then
        fallbackKey, fallbackData = categoryKey, categoryData
      end
    end
  end

  return fallbackKey, fallbackData
end

local function CreateCategory(key, plainName, query, color, priority)
  local def = GetTypeDef(key)
  local safeColor = NormalizeColor(color, def.defaultColor)
  local categoryName = GetCategoryName(key, plainName, safeColor)

  categories:CreateCategory(mycontext, {
    name = categoryName,
    itemList = {},
    save = true,
    searchCategory = {
      query = query,
    },
    priority = NormalizePriority(key, priority),
  })

  RefreshBags()
  return categoryName
end

local function CategoryExistsByName(name)
  if not name or name == "" then
    return false
  end

  if not UpdateCategoriesReadyState() then
    return false
  end

  local strippedName = UIOptions:StripColourCodes(name)

  if categories.GetCategory then
    local ok, result = pcall(categories.GetCategory, categories, name)
    if ok and result then
      return true
    end

    ok, result = pcall(categories.GetCategory, categories, strippedName)
    if ok and result then
      return true
    end
  end

  if categories.GetAllCategories then
    local ok, result = pcall(categories.GetAllCategories, categories)
    if ok and type(result) == "table" then
      for categoryName, categoryData in pairs(result) do
        local candidateName = categoryName
        local candidateDataName = type(categoryData) == "table" and categoryData.name or nil

        if candidateName == name or candidateName == strippedName then
          return true
        end

        if UIOptions:StripColourCodes(tostring(candidateName or "")) == strippedName then
          return true
        end

        if candidateDataName then
          if candidateDataName == name or candidateDataName == strippedName then
            return true
          end

          if UIOptions:StripColourCodes(candidateDataName) == strippedName then
            return true
          end
        end
      end
    end
  end

  return false
end

local function DeleteCategoryByName(name)
  if not name or name == "" then
    return true
  end

  SetCategoryPinnedByName(name, false, true)

  if not UpdateCategoriesReadyState() then
    return false
  end

  local strippedName = UIOptions:StripColourCodes(name)

  if categories.DeleteCategory then
    local ok = pcall(categories.DeleteCategory, categories, mycontext, name)
    if ok then
      RefreshBags()
      return true
    end

    ok = pcall(categories.DeleteCategory, categories, name)
    if ok then
      RefreshBags()
      return true
    end

    ok = pcall(categories.DeleteCategory, categories, mycontext, strippedName)
    if ok then
      RefreshBags()
      return true
    end

    ok = pcall(categories.DeleteCategory, categories, strippedName)
    if ok then
      RefreshBags()
      return true
    end
  end

  return false
end

local function DeleteManagedCategory(key, plainName, query)
  local foundKey, foundData = FindManagedCategory(key, plainName, query)

  if foundKey then
    if DeleteCategoryByName(tostring(foundKey)) then
      return true
    end
  end

  if foundData and type(foundData) == "table" and foundData.name then
    if DeleteCategoryByName(foundData.name) then
      return true
    end
  end

  return false
end

local function SyncStateFromExistingCategories()
  if not UpdateCategoriesReadyState() then
    return
  end

  for _, key in ipairs(CATEGORY_ORDER) do
    local state = GetState(key)
    local plainName = NormalizeName(key, state.plainActiveName or state.pendingName)
    local query = GetQueryForKey(key)

    if query and query ~= "" then
      local foundKey, foundData = FindManagedCategory(key, plainName, query)

      if state.active then
        if foundKey then
          state.activeName = tostring(foundKey)
          state.plainActiveName = plainName

          if type(foundData) == "table" and foundData.priority ~= nil then
            state.activePriority = NormalizePriority(key, foundData.priority)
          else
            local def = GetTypeDef(key)
            state.activePriority = NormalizePriority(key, state.pendingPriority or def.defaultPriority)
          end

          local def = GetTypeDef(key)
          state.activeColor = NormalizeColor(state.pendingColor, def.defaultColor)
          state.activeIncludeBoe = not not state.pendingIncludeBoe
          state.activeIncludeBow = not not state.pendingIncludeBow
        end
      else
        if foundKey or foundData then
          DeleteManagedCategory(key, plainName, query)
        end

        state.activeName = nil
        state.plainActiveName = nil
        state.activeColor = nil
        state.activePriority = nil
        state.activeIncludeBoe = nil
        state.activeIncludeBow = nil
      end
    end
  end

  NotifyConfigChanged()
end

local function EnsureCategoryMatchesState(key)
  local state = GetState(key)

  if not state.active then
    return
  end

  if not UpdateCategoriesReadyState() then
    return
  end

  local def = GetTypeDef(key)
  local plainName = NormalizeName(key, state.plainActiveName or state.pendingName)
  local color = NormalizeColor(state.activeColor or state.pendingColor, def.defaultColor)
  local priority = NormalizePriority(key, state.activePriority or state.pendingPriority or def.defaultPriority)
  local expectedName = GetCategoryName(key, plainName, color)
  local query = GetQueryForKey(key)

  if not query or query == "" then
    return
  end

  state.plainActiveName = plainName
  state.activeColor = UIOptions:CopyColour(color)
  state.activePriority = priority
  state.activeIncludeBoe = not not state.pendingIncludeBoe
  state.activeIncludeBow = not not state.pendingIncludeBow

  local foundKey, foundData = FindManagedCategory(key, plainName, query)

  if foundKey then
    state.activeName = tostring(foundKey)

    if type(foundData) == "table" and foundData.priority ~= nil then
      state.activePriority = NormalizePriority(key, foundData.priority)
    end

    SetCategoryPinnedByName(state.activeName, state.pinned)
    return
  end

  state.activeName = expectedName
  CreateCategory(key, plainName, query, color, priority)
  SetCategoryPinnedByName(state.activeName, state.pinned, true)
end

local function RestoreActiveCategories()
  if restoreStarted then
    return
  end

  if not UpdateCategoriesReadyState() then
    return
  end

  restoreStarted = true

  for _, key in ipairs(CATEGORY_ORDER) do
    local state = GetState(key)
    if state.active then
      EnsureCategoryMatchesState(key)
    end
  end

  NotifyConfigChanged()
end

local function RestoreWhenReady(attempt)
  attempt = attempt or 1
  EnsureDB()

  if UpdateCategoriesReadyState() then
    SyncStateFromExistingCategories()
    RestoreActiveCategories()
    return
  end

  if attempt >= 40 then
    return
  end

  C_Timer.After(0.25, function()
    RestoreWhenReady(attempt + 1)
  end)
end

local function ActivateCategory(key)
  local def = GetTypeDef(key)
  local state = GetState(key)
  local newPlainName = NormalizeName(key, state.pendingName)
  local newColor = UIOptions:CopyColour(GetPendingColor(key))
  local newPriority = GetPendingPriority(key)
  local newCategoryName = GetCategoryName(key, newPlainName, newColor)
  local query = GetQueryForKey(key)

  state.pendingName = newPlainName
  state.pendingColor = UIOptions:CopyColour(newColor)
  state.pendingPriority = newPriority

  if not query or query == "" then
    print("BetterBags_GearCategories: No query available for " .. tostring(key))
    return
  end

  if not UpdateCategoriesReadyState() then
    RestoreWhenReady()
    state.active = true
    state.activeName = newCategoryName
    state.plainActiveName = newPlainName
    state.activeColor = NormalizeColor(newColor, def.defaultColor)
    state.activePriority = newPriority
    state.activeIncludeBoe = not not state.pendingIncludeBoe
    state.activeIncludeBow = not not state.pendingIncludeBow
    SetCategoryPinnedByName(state.activeName, state.pinned, true)
    NotifyConfigChanged()
    return
  end

  DeleteManagedCategory(key, newPlainName, query)

  local createdName = CreateCategory(key, newPlainName, query, newColor, newPriority)
  state.active = true
  state.activeName = createdName or newCategoryName
  state.plainActiveName = newPlainName
  state.activeColor = NormalizeColor(newColor, def.defaultColor)
  state.activePriority = newPriority
  state.activeIncludeBoe = not not state.pendingIncludeBoe
  state.activeIncludeBow = not not state.pendingIncludeBow
  SetCategoryPinnedByName(state.activeName, state.pinned, true)

  NotifyConfigChanged()
end

local function SetIncludeBoeEnabled(key, value)
  local state = GetState(key)
  state.pendingIncludeBoe = not not value

  if state.active then
    ActivateCategory(key)
  else
    NotifyConfigChanged()
  end
end

local function SetIncludeBowEnabled(key, value)
  local state = GetState(key)
  state.pendingIncludeBow = not not value

  if state.active then
    ActivateCategory(key)
  else
    NotifyConfigChanged()
  end
end

local function DeactivateCategory(key)
  local state = GetState(key)
  local plainName = NormalizeName(key, state.plainActiveName or state.pendingName)
  local query = GetQueryForKey(key)

  state.active = false

  if query and query ~= "" and UpdateCategoriesReadyState() then
    DeleteManagedCategory(key, plainName, query)
  elseif state.activeName and UpdateCategoriesReadyState() then
    DeleteCategoryByName(state.activeName)
  end

  if state.activeName then
    SetCategoryPinnedByName(state.activeName, false)
  end

  state.activeName = nil
  state.plainActiveName = nil
  state.activeColor = nil
  state.activePriority = nil
  state.activeIncludeBoe = nil
  state.activeIncludeBow = nil

  NotifyConfigChanged()
end

local function ToggleCategory(key, value)
  if value then
    ActivateCategory(key)
  else
    DeactivateCategory(key)
  end
end

local function ResetPendingName(key)
  local state = GetState(key)
  local def = GetTypeDef(key)
  state.pendingName = def.defaultName
  NotifyConfigChanged()
end

local function ResetPendingColor(key)
  local state = GetState(key)
  local def = GetTypeDef(key)
  state.pendingColor = UIOptions:CopyColour(def.defaultColor)
  NotifyConfigChanged()
end

local function GetStatusText(key)
  local state = GetState(key)
  local def = GetTypeDef(key)

  if state.active then
    local pendingName = NormalizeName(key, state.pendingName)
    local pendingCategoryName = GetCategoryName(key, pendingName, GetPendingColor(key))

    if state.activeName and UIOptions:StripColourCodes(pendingCategoryName) ~= UIOptions:StripColourCodes(state.activeName) then
      return "Status: " .. UIOptions:ColourTextHex("Active (pending changes)", UIOptions.turquoise)
    end

    local pendingColor = GetPendingColor(key)
    local activeColor = state.activeColor or def.defaultColor
    if UIOptions:ColourToHex(pendingColor) ~= UIOptions:ColourToHex(activeColor) then
      return "Status: " .. UIOptions:ColourTextHex("Active (pending changes)", UIOptions.turquoise)
    end

    local pendingPriority = GetPendingPriority(key)
    local activePriority = NormalizePriority(key, state.activePriority or def.defaultPriority)
    if pendingPriority ~= activePriority then
      return "Status: " .. UIOptions:ColourTextHex("Active (pending changes)", UIOptions.turquoise)
    end

    local pendingIncludeBoe = not not state.pendingIncludeBoe
    local activeIncludeBoe = not not state.activeIncludeBoe
    if pendingIncludeBoe ~= activeIncludeBoe then
      return "Status: " .. UIOptions:ColourTextHex("Active (pending changes)", UIOptions.turquoise)
    end

    local pendingIncludeBow = not not state.pendingIncludeBow
    local activeIncludeBow = not not state.activeIncludeBow
    if pendingIncludeBow ~= activeIncludeBow then
      return "Status: " .. UIOptions:ColourTextHex("Active (pending changes)", UIOptions.turquoise)
    end

    if not categoriesReady then
      return "Status: " .. UIOptions:ColourTextHex("Active (loading)", UIOptions.yellow)
    end

    return "Status: " .. UIOptions:ColourTextHex("Active", UIOptions.green)
  end

  return "Status: " .. UIOptions:ColourTextHex("Inactive", UIOptions.red)
end

BBTC.EnsureDB = EnsureDB
BBTC.NotifyConfigChanged = NotifyConfigChanged
BBTC.RefreshBags = RefreshBags
BBTC.GetState = GetState
BBTC.NormalizeName = NormalizeName
BBTC.GetPendingColor = GetPendingColor
BBTC.GetCategoryName = GetCategoryName
BBTC.BuildSeasonQuery = BuildSeasonQuery
BBTC.GetQueryForKey = GetQueryForKey
BBTC.NormalizePriority = NormalizePriority
BBTC.GetPendingPriority = GetPendingPriority
BBTC.ResetPendingPriority = ResetPendingPriority
BBTC.ResetPendingIncludeBoe = ResetPendingIncludeBoe
BBTC.ResetPendingIncludeBow = ResetPendingIncludeBow
BBTC.CreateCategory = CreateCategory
BBTC.CategoryExistsByName = CategoryExistsByName
BBTC.DeleteCategoryByName = DeleteCategoryByName
BBTC.EnsureCategoryMatchesState = EnsureCategoryMatchesState
BBTC.RestoreActiveCategories = RestoreActiveCategories
BBTC.ActivateCategory = ActivateCategory
BBTC.DeactivateCategory = DeactivateCategory
BBTC.ToggleCategory = ToggleCategory
BBTC.ResetPendingName = ResetPendingName
BBTC.ResetPendingColor = ResetPendingColor
BBTC.GetStatusText = GetStatusText
BBTC.AreCategoriesReady = AreCategoriesReady
BBTC.RestoreWhenReady = RestoreWhenReady
BBTC.FindManagedCategory = FindManagedCategory
BBTC.DeleteManagedCategory = DeleteManagedCategory
BBTC.SyncStateFromExistingCategories = SyncStateFromExistingCategories
BBTC.SetPinnedEnabled = SetPinnedEnabled
BBTC.SetIncludeBoeEnabled = SetIncludeBoeEnabled
BBTC.SetIncludeBowEnabled = SetIncludeBowEnabled
BBTC.GetTypeDef = GetTypeDef

local restoreFrame = CreateFrame("Frame")
restoreFrame:RegisterEvent("PLAYER_LOGIN")
restoreFrame:SetScript("OnEvent", function()
  RestoreWhenReady()
end)