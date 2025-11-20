-- @noindex
-- Demo/core/state.lua
--
-- WHY THIS EXISTS: Manages demo application state including active showcase tab,
-- user interactions, and example data for demonstrating ARKITEKT features.
--
-- This is the single source of truth for the demo app's runtime state.

local M = {}

--- Initialize the demo application state
-- @return table State object with default values
function M.initialize()
  return {
    -- Active tab in the showcase
    active_tab = "primitives",

    -- Primitives showcase state
    primitives = {
      button_click_count = 0,
      checkbox_state = false,
      checkbox_mixed_state = true,
      slider_value = 0.5,
      text_input = "Edit me!",
      color_value = 0xFF6B9DFF, -- Nice purple color
    },

    -- Widgets showcase state
    widgets = {
      selected_chip = nil,
      chips = {
        { id = "audio", label = "Audio", icon = "🎵" },
        { id = "midi", label = "MIDI", icon = "🎹" },
        { id = "video", label = "Video", icon = "🎬" },
        { id = "effects", label = "Effects", icon = "✨" },
      },
      dropdown_value = "option_1",
      search_text = "",
    },

    -- Grid showcase state
    grid = {
      selected_items = {},
      items = M.generate_sample_tiles(24),
    },

    -- Colors showcase state
    colors = {
      base_color = 0x3B82F6FF, -- Blue-500
      brightness_factor = 1.0,
      saturation_amount = 0.0,
      alpha_value = 255,
    },

    -- Animation showcase state
    animations = {
      progress = 0.0,
      running = false,
      speed = 1.0,
    },
  }
end

--- Generate sample tiles for grid demonstration
-- @param count number Number of tiles to generate
-- @return table Array of tile objects
function M.generate_sample_tiles(count)
  local tiles = {}
  local colors = {
    0xFF6B9DFF, -- Purple
    0x3B82F6FF, -- Blue
    0x10B981FF, -- Green
    0xF59E0BFF, -- Amber
    0xEF4444FF, -- Red
    0x8B5CF6FF, -- Violet
    0xEC4899FF, -- Pink
    0x06B6D4FF, -- Cyan
  }

  for i = 1, count do
    table.insert(tiles, {
      id = "tile_" .. i,
      label = "Item " .. i,
      color = colors[((i - 1) % #colors) + 1],
      enabled = true,
      metadata = {
        type = i % 3 == 0 and "special" or "normal",
        index = i,
      }
    })
  end

  return tiles
end

--- Toggle selection of a grid item
-- @param state table Demo state object
-- @param item_id string Item ID to toggle
function M.toggle_item_selection(state, item_id)
  local selected = state.grid.selected_items

  -- Check if already selected
  local found_index = nil
  for i, id in ipairs(selected) do
    if id == item_id then
      found_index = i
      break
    end
  end

  if found_index then
    -- Remove from selection
    table.remove(selected, found_index)
  else
    -- Add to selection
    table.insert(selected, item_id)
  end
end

--- Check if item is selected
-- @param state table Demo state object
-- @param item_id string Item ID to check
-- @return boolean True if item is selected
function M.is_item_selected(state, item_id)
  for _, id in ipairs(state.grid.selected_items) do
    if id == item_id then
      return true
    end
  end
  return false
end

--- Clear all selections
-- @param state table Demo state object
function M.clear_selection(state)
  state.grid.selected_items = {}
end

return M
