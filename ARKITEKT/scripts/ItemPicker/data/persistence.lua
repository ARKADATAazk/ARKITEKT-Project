-- @noindex
-- ItemPicker/storage/persistence.lua
-- Settings persistence using REAPER project extended state

local M = {}

local EXTNAME = "ARK_ItemPicker"
local SETTINGS_KEY = "settings"

-- Safe deserializer that doesn't use load() to prevent code injection
-- Only supports the specific format we serialize: {[key]=value,...}
local function safe_deserialize(str)
  if not str or str == "" then return nil end

  -- Validate it looks like a table literal
  local trimmed = str:match("^%s*(.-)%s*$")
  if not trimmed:match("^{.*}$") then return nil end

  local result = {}

  -- Extract key-value pairs from the table literal
  -- Matches patterns like: ["key"]=value or [key]=value
  for key, value in trimmed:gmatch('%[([^%]]+)%]%s*=%s*([^,}]+)') do
    -- Parse key (remove quotes if string key)
    local parsed_key = key:match('^"(.-)"$') or key:match("^'(.-)'$") or key

    -- Parse value
    local parsed_value
    local trimmed_value = value:match("^%s*(.-)%s*$")

    if trimmed_value == "true" then
      parsed_value = true
    elseif trimmed_value == "false" then
      parsed_value = false
    elseif trimmed_value == "nil" then
      parsed_value = nil
    elseif trimmed_value:match("^%-?%d+%.?%d*$") then
      parsed_value = tonumber(trimmed_value)
    elseif trimmed_value:match('^".-"$') then
      -- String value - unescape basic escapes
      parsed_value = trimmed_value:match('^"(.-)"$')
      parsed_value = parsed_value:gsub('\\"', '"'):gsub('\\n', '\n'):gsub('\\\\', '\\')
    else
      parsed_value = trimmed_value
    end

    result[parsed_key] = parsed_value
  end

  return result
end

-- Safe deserializer for nested tables (audio/midi structure)
local function safe_deserialize_nested(str)
  if not str or str == "" then return nil end

  local trimmed = str:match("^%s*(.-)%s*$")
  if not trimmed:match("^{.*}$") then return nil end

  local result = { audio = {}, midi = {} }

  -- Find audio={...} section
  local audio_content = trimmed:match('audio%s*=%s*{([^}]*)}')
  if audio_content then
    for key in audio_content:gmatch('%[([^%]]+)%]%s*=%s*true') do
      local parsed_key = key:match('^"(.-)"$') or key:match("^'(.-)'$") or key
      result.audio[parsed_key] = true
    end
  end

  -- Find midi={...} section
  local midi_content = trimmed:match('midi%s*=%s*{([^}]*)}')
  if midi_content then
    for key in midi_content:gmatch('%[([^%]]+)%]%s*=%s*true') do
      local parsed_key = key:match('^"(.-)"$') or key:match("^'(.-)'$") or key
      result.midi[parsed_key] = true
    end
  end

  return result
end

-- Default settings
local function get_default_settings()
  return {
    play_item_through_track = false,
    show_muted_tracks = false,
    show_muted_items = false,
    show_disabled_items = false,
    show_favorites_only = false,
    show_audio = true,
    show_midi = true,
    focus_keyboard_on_init = true,
    search_string = "",
    tile_width = nil,  -- nil = use config default
    tile_height = nil,  -- nil = use config default
    split_midi_by_track = false,
    group_items_by_name = true,
    separator_position = nil,
    separator_position_horizontal = nil,
    sort_mode = "none",
    sort_reverse = false,
    waveform_quality = 1.0,
    waveform_filled = true,
    waveform_zero_line = false,
    show_visualization_in_small_tiles = false,
    enable_tile_fx = true,
    layout_mode = "vertical",
    enable_region_processing = false,  -- Enable region detection and filtering
    show_region_tags = false,  -- Show region tags on item tiles (only if processing enabled)
    search_mode = "items",  -- Search mode: "items", "tracks", "regions", "mixed"
  }
end

function M.load_settings()
  local has_state, state_str = reaper.GetProjExtState(0, EXTNAME, SETTINGS_KEY)

  if not has_state or has_state == 0 or state_str == "" then
    return get_default_settings()
  end

  local settings = safe_deserialize(state_str)
  if not settings or type(settings) ~= "table" then
    return get_default_settings()
  end

  -- Merge with defaults to handle new settings added
  local defaults = get_default_settings()
  for k, v in pairs(defaults) do
    if settings[k] == nil then
      settings[k] = v
    end
  end

  return settings
end

function M.save_settings(settings)
  if not settings then return end

  -- Serialize settings table
  local function serialize(tbl)
    local parts = {}
    for k, v in pairs(tbl) do
      local key_str
      if type(k) == "string" then
        key_str = string.format("[%q]", k)
      else
        key_str = string.format("[%s]", tostring(k))
      end

      local val_str
      if type(v) == "string" then
        val_str = string.format("%q", v)
      elseif type(v) == "number" then
        val_str = tostring(v)
      elseif type(v) == "boolean" then
        val_str = tostring(v)
      elseif v == nil then
        val_str = "nil"
      else
        val_str = "nil"  -- Skip complex types
      end

      table.insert(parts, key_str .. "=" .. val_str)
    end
    return "{" .. table.concat(parts, ",") .. "}"
  end

  local serialized = serialize(settings)
  reaper.SetProjExtState(0, EXTNAME, SETTINGS_KEY, serialized)
end

-- Disabled items persistence
function M.load_disabled_items()
  local has_state, state_str = reaper.GetProjExtState(0, EXTNAME, "disabled_items")

  if not has_state or has_state == 0 or state_str == "" then
    return { audio = {}, midi = {} }
  end

  local disabled = safe_deserialize_nested(state_str)
  if not disabled or type(disabled) ~= "table" then
    return { audio = {}, midi = {} }
  end

  return disabled
end

function M.save_disabled_items(disabled)
  if not disabled then return end

  local function serialize_set(tbl)
    if not tbl then return "{}" end
    local parts = {}
    for k, _ in pairs(tbl) do
      local key_str = string.format("[%q]", tostring(k))
      table.insert(parts, key_str .. "=true")
    end
    return "{" .. table.concat(parts, ",") .. "}"
  end

  local serialized = string.format(
    "{audio=%s,midi=%s}",
    serialize_set(disabled.audio),
    serialize_set(disabled.midi)
  )

  reaper.SetProjExtState(0, EXTNAME, "disabled_items", serialized)
end

-- Favorites persistence
function M.load_favorites()
  local has_state, state_str = reaper.GetProjExtState(0, EXTNAME, "favorites")

  if not has_state or has_state == 0 or state_str == "" then
    return { audio = {}, midi = {} }
  end

  local favorites = safe_deserialize_nested(state_str)
  if not favorites or type(favorites) ~= "table" then
    return { audio = {}, midi = {} }
  end

  return favorites
end

function M.save_favorites(favorites)
  if not favorites then return end

  local function serialize_set(tbl)
    if not tbl then return "{}" end
    local parts = {}
    for k, _ in pairs(tbl) do
      local key_str = string.format("[%q]", tostring(k))
      table.insert(parts, key_str .. "=true")
    end
    return "{" .. table.concat(parts, ",") .. "}"
  end

  local serialized = string.format(
    "{audio=%s,midi=%s}",
    serialize_set(favorites.audio),
    serialize_set(favorites.midi)
  )

  reaper.SetProjExtState(0, EXTNAME, "favorites", serialized)
end

return M
