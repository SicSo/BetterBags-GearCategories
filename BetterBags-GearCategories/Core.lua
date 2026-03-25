-- Core.lua

BBTC = BBTC or {}

BBTC.UIOptions = BBTC.UIOptions or {}

local UIOptions = BBTC.UIOptions

-- This will get a handle on the BetterBags addon.
---@class BetterBags: AceAddon
local addon = LibStub('AceAddon-3.0'):GetAddon("BetterBags")

---@class Categories: AceModule
local categories = addon:GetModule('Categories')

---@class Config: AceModule
local config = addon:GetModule('Config')

---@class Events: AceModule
local events = addon:GetModule('Events')

---@class Context: AceModule
local context = addon:GetModule('Context')

---@class Localization: AceModule
local L = addon:GetModule('Localization')

---@class GearCategories: AceModule
local gearCategories = addon:NewModule('GearCategories')

local AceDB = LibStub("AceDB-3.0")
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")

local mycontext = context:New('BetterBags_GearCategories Create Category')

BBTC.addon = addon
BBTC.gearCategories = gearCategories
BBTC.categories = categories
BBTC.config = config
BBTC.events = events
BBTC.context = context
BBTC.L = L
BBTC.AceDB = AceDB
BBTC.AceConfig = AceConfig
BBTC.AceConfigDialog = AceConfigDialog
BBTC.AceConfigRegistry = AceConfigRegistry
BBTC.mycontext = mycontext

function gearCategories:OnInitialize()
  if BBTC.EnsureDB then
    BBTC.EnsureDB()
  end
end


function UIOptions:CopyColour(colour)
  if not colour then
    return { r = 1, g = 1, b = 1, a = 1 }
  end

  return {
    r = colour.r or 1,
    g = colour.g or 1,
    b = colour.b or 1,
    a = colour.a or 1,
  }
end

function UIOptions:ColourToHex(colour)
  if colour and colour.r and colour.g and colour.b then
    local r = math.floor((colour.r or 1) * 255 + 0.5)
    local g = math.floor((colour.g or 1) * 255 + 0.5)
    local b = math.floor((colour.b or 1) * 255 + 0.5)
    return string.format("ff%02x%02x%02x", r, g, b)
  end

  return "ffffffff"
end

function UIOptions:ColourText(text, colour)
  if not text then return "" end
  return "|c" .. self:ColourToHex(colour) .. text .. "|r"
end

function UIOptions:ColourTextHex(text, colour)
    if not text then return "" end
    return ("|c%s%s|r"):format(colour, text)
end

function UIOptions:StripColourCodes(text)
  if type(text) ~= "string" then
    return text
  end

  text = text:gsub("|c%x%x%x%x%x%x%x%x", "")
  text = text:gsub("|r", "")
  return text
end
