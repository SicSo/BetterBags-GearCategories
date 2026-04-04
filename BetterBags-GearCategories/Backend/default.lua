-- default.lua

BBTC = BBTC or {}
BBTC.UIOptions = BBTC.UIOptions or {}

local UIOptions = BBTC.UIOptions

-- ============================================================================
-- MIDNIGHT SEASON 1 BONUS IDS
-- ============================================================================

local MDS1Adv   = "bonusid=12769 or bonusid=12770 or bonusid=12771 or bonusid=12772 or bonusid=12773 or bonusid=12774"
local MDS1Vet   = "bonusid=12777 or bonusid=12778 or bonusid=12779 or bonusid=12780 or bonusid=12781 or bonusid=12782"
local MDS1Champ = "bonusid=12785 or bonusid=12786 or bonusid=12787 or bonusid=12788 or bonusid=12789 or bonusid=12790"
local MDS1Hero  = "bonusid=12793 or bonusid=12794 or bonusid=12795 or bonusid=12796 or bonusid=12797 or bonusid=12798"
local MDS1Myth  = "bonusid=12801 or bonusid=12802 or bonusid=12803 or bonusid=12804 or bonusid=12805 or bonusid=12806"

local MDCrafted   = "bonusid=8790 or bonusid=8791 or bonusid=8795 or bonusid=8793 or bonusid=8794 or bonusid=8792"
local MDS1Crafted = "bonusid=12066"

-- ============================================================================
-- DEFAULT COLORS
-- ============================================================================

UIOptions.COLOR_COMMON    = ITEM_QUALITY_COLORS[1]
UIOptions.COLOR_UNCOMMON  = ITEM_QUALITY_COLORS[2]
UIOptions.COLOR_RARE      = ITEM_QUALITY_COLORS[3]
UIOptions.COLOR_EPIC      = ITEM_QUALITY_COLORS[4]
UIOptions.COLOR_LEGENDARY = ITEM_QUALITY_COLORS[5]
UIOptions.COLOR_ARTIFACT  = ITEM_QUALITY_COLORS[6] or ITEM_QUALITY_COLORS[5]

UIOptions.white     = "FFFFFFFF"
UIOptions.black     = "FF000000"
UIOptions.blue      = "FF0000FF"
UIOptions.purple    = "FFFF00FF"
UIOptions.turquoise = "FF00FFFF"
UIOptions.red       = "FFFF0000"
UIOptions.green     = "FF00FF00"
UIOptions.yellow    = "FFFFFF00"
UIOptions.grey      = "FF808080"
UIOptions.orange    = "FFFFA500"
UIOptions.gold      = "FFFFD700"

local DEFAULT_TYPE_COLORS = {
  season  = UIOptions.COLOR_EPIC,
  adv     = UIOptions.COLOR_UNCOMMON,
  vet     = UIOptions.COLOR_RARE,
  champ   = UIOptions.COLOR_EPIC,
  hero    = UIOptions.COLOR_LEGENDARY,
  myth    = UIOptions.COLOR_ARTIFACT,
  crafted = UIOptions.COLOR_COMMON,
  s1craft = UIOptions.COLOR_RARE,
}

local DEFAULT_SECTION_ORDERS = {
  myth = 1,
  hero = 2,
  champ = 3,
  vet = 4,
  adv = 5,
  season = 6,
  s1craft = 7,
  crafted = 8,
}

local DEFAULT_PRIORITY = 5

-- ============================================================================
-- DATABASE KEYS
-- ============================================================================

local EXPANSION_MIDNIGHT = "midnight"
local SEASON_1 = "s1"
local CRAFTED_GROUP = "crafted"

-- ============================================================================
-- TYPE DEFINITIONS
-- ============================================================================

local TYPE_DEFS = {
  [EXPANSION_MIDNIGHT] = {
    name = "Midnight",
    order = 1,

    seasons = {
      [SEASON_1] = {
        name = "Season 1",
        order = 1,

        categories = {
          season = {
            defaultName = "Midnight S1",
            defaultColor = UIOptions:CopyColour(DEFAULT_TYPE_COLORS.season),
            defaultPriority = DEFAULT_PRIORITY,
            defaultSectionOrder = DEFAULT_SECTION_ORDERS.season,
            order = 1,
            treeName = "Season 1",
            includeInSeason = false,
            isCombined = true,
          },
          adv = {
            defaultName = "Midnight S1: Adventurer",
            query = MDS1Adv,
            defaultColor = UIOptions:CopyColour(DEFAULT_TYPE_COLORS.adv),
            defaultPriority = DEFAULT_PRIORITY,
            defaultSectionOrder = DEFAULT_SECTION_ORDERS.adv,
            order = 3,
            treeName = "Adventurer",
            includeInSeason = true,
          },
          vet = {
            defaultName = "Midnight S1: Veteran",
            query = MDS1Vet,
            defaultColor = UIOptions:CopyColour(DEFAULT_TYPE_COLORS.vet),
            defaultPriority = DEFAULT_PRIORITY,
            defaultSectionOrder = DEFAULT_SECTION_ORDERS.vet,
            order = 4,
            treeName = "Veteran",
            includeInSeason = true,
          },
          champ = {
            defaultName = "Midnight S1: Champion",
            query = MDS1Champ,
            defaultColor = UIOptions:CopyColour(DEFAULT_TYPE_COLORS.champ),
            defaultPriority = DEFAULT_PRIORITY,
            defaultSectionOrder = DEFAULT_SECTION_ORDERS.champ,
            order = 5,
            treeName = "Champion",
            includeInSeason = true,
          },
          hero = {
            defaultName = "Midnight S1: Hero",
            query = MDS1Hero,
            defaultColor = UIOptions:CopyColour(DEFAULT_TYPE_COLORS.hero),
            defaultPriority = DEFAULT_PRIORITY,
            defaultSectionOrder = DEFAULT_SECTION_ORDERS.hero,
            order = 6,
            treeName = "Hero",
            includeInSeason = true,
          },
          myth = {
            defaultName = "Midnight S1: Myth",
            query = MDS1Myth,
            defaultColor = UIOptions:CopyColour(DEFAULT_TYPE_COLORS.myth),
            defaultPriority = DEFAULT_PRIORITY,
            defaultSectionOrder = DEFAULT_SECTION_ORDERS.myth,
            order = 7,
            treeName = "Myth",
            includeInSeason = true,
          },
        },
      },
    },

    crafted = {
      name = "Crafted",
      order = 2,

      categories = {
        crafted = {
          defaultName = "Midnight Crafted",
          query = MDCrafted,
          defaultColor = UIOptions:CopyColour(DEFAULT_TYPE_COLORS.crafted),
          defaultPriority = DEFAULT_PRIORITY,
          defaultSectionOrder = DEFAULT_SECTION_ORDERS.crafted,
          order = 1,
          treeName = "Crafted",
          includeInSeason = false,
        },
        s1craft = {
          defaultName = "Midnight S1: Crafted",
          query = MDS1Crafted,
          defaultColor = UIOptions:CopyColour(DEFAULT_TYPE_COLORS.s1craft),
          defaultPriority = DEFAULT_PRIORITY,
          defaultSectionOrder = DEFAULT_SECTION_ORDERS.s1craft,
          order = 2,
          treeName = "S1 Crafted",
          includeInSeason = false,
        },
      },
    },
  },
}

-- ============================================================================
-- DEFAULT CATEGORY STATE
-- ============================================================================

local function CreateCategoryDefaults(def)
  return {
    active = false,
    pinned = true,

    activeName = nil,
    plainActiveName = nil,
    activeColor = nil,
    activePriority = nil,
    activeOrder = nil,
    activeIncludeBoe = nil,
    activeIncludeBow = nil,

    pendingName = def.defaultName,
    pendingColor = UIOptions:CopyColour(def.defaultColor),
    pendingPriority = def.defaultPriority,
    pendingOrder = def.defaultSectionOrder,
    pendingIncludeBoe = false,
    pendingIncludeBow = false,
  }
end

local function BuildCategoryDefaults(categoryDefs)
  local categories = {}

  for categoryKey, def in pairs(categoryDefs) do
    categories[categoryKey] = CreateCategoryDefaults(def)
  end

  return categories
end

-- ============================================================================
-- DEFAULTS
-- ============================================================================

local defaults = {
  profile = {
    settings = {
      enforceOrderOnCreate = true,
      enforceOrderAlways = false,
      popupVersion = 0,
    },

    expansions = {
      [EXPANSION_MIDNIGHT] = {
        seasons = {
          [SEASON_1] = {
            categories = BuildCategoryDefaults(
              TYPE_DEFS[EXPANSION_MIDNIGHT].seasons[SEASON_1].categories
            ),
          },
        },

        crafted = {
          categories = BuildCategoryDefaults(
            TYPE_DEFS[EXPANSION_MIDNIGHT].crafted.categories
          ),
        },
      },
    },
  },
}

BBTC.TYPE_DEFS = TYPE_DEFS
BBTC.defaults = defaults