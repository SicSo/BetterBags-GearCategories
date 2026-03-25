-- filter.lua

BBTC = BBTC or {}

local function IsTrue(value)
  return value == true
end

local function BuildBindExclusionQuery(state)
  local excluded = {}

  -- Exclude BoE unless explicitly included.
  if not IsTrue(state.pendingIncludeBoe) then
    table.insert(excluded, "bindtype=2")
  end

  -- Exclude both Warbound and Warbound-until-equipped unless explicitly included.
  if not IsTrue(state.pendingIncludeBow) then
    table.insert(excluded, "bindtype=8")
    table.insert(excluded, "bindtype=9")
  end

  if #excluded == 0 then
    return nil
  end

  return "not (" .. table.concat(excluded, " or ") .. ")"
end

function BBTC.BuildFilteredQuery(key, baseQuery)
  if type(baseQuery) ~= "string" or baseQuery == "" then
    return baseQuery
  end

  if not BBTC.GetState then
    return baseQuery
  end

  local state = BBTC.GetState(key)
  if not state then
    return baseQuery
  end

  local exclusion = BuildBindExclusionQuery(state)
  if not exclusion then
    return "(" .. baseQuery .. ")"
  end

  return "(" .. baseQuery .. ") and " .. exclusion
end