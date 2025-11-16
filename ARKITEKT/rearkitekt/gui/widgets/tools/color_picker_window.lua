-- @noindex
-- ReArkitekt/gui/widgets/tools/color_picker_window.lua
-- Floating color picker window for live batch recoloring
-- Opens as a draggable, always-on-top window with hue wheel picker
-- Changes apply instantly to selected items as you adjust the color

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.10'
local Colors = require('rearkitekt.core.colors')

local M = {}

-- State for each picker instance
local instances = {}

--- Create or get a color picker instance
--- @param id string Unique identifier for this picker
--- @return table Instance state
local function get_instance(id)
  if not instances[id] then
    instances[id] = {
      is_open = false,
      current_color = 0xFF0000FF,  -- Default red
      backup_color = nil,
      first_open = true,
    }
  end
  return instances[id]
end

--- Open the color picker window
--- @param id string Unique identifier for this picker
--- @param initial_color number Optional initial color (RGBA)
function M.open(id, initial_color)
  local inst = get_instance(id)
  inst.is_open = true
  if initial_color then
    inst.current_color = initial_color
    inst.backup_color = initial_color
  end
  inst.first_open = true
end

--- Close the color picker window
--- @param id string Unique identifier for this picker
function M.close(id)
  local inst = get_instance(id)
  inst.is_open = false
end

--- Check if the color picker is open
--- @param id string Unique identifier for this picker
--- @return boolean
function M.is_open(id)
  local inst = get_instance(id)
  return inst.is_open
end

--- Render the color picker contents (without window wrapper)
--- @param ctx userdata ImGui context
--- @param id string Unique identifier for this picker
--- @param on_change function Callback when color changes
--- @return boolean changed Whether color was changed this frame
local function render_picker_contents(ctx, id, on_change)
  local inst = get_instance(id)
  local changed = false

  -- Extract RGB from current color
  local r = (inst.current_color >> 24) & 0xFF
  local g = (inst.current_color >> 16) & 0xFF
  local b = (inst.current_color >> 8) & 0xFF

  -- Use native ColorPicker4 with hue wheel
  local flags = ImGui.ColorEditFlags_PickerHueWheel |
                ImGui.ColorEditFlags_NoSidePreview |
                ImGui.ColorEditFlags_NoAlpha

  local rv, new_r, new_g, new_b = ImGui.ColorPicker4(ctx, "##picker", r/255, g/255, b/255, flags)

  if rv then
    -- Convert back to packed RGBA
    inst.current_color = (math.floor(new_r * 255) << 24) |
                         (math.floor(new_g * 255) << 16) |
                         (math.floor(new_b * 255) << 8) | 0xFF
    changed = true

    -- Store that we have a pending change
    inst.pending_change = true
  end

  -- Apply color only when mouse button is released
  if inst.pending_change and ImGui.IsMouseReleased(ctx, 0) then
    inst.pending_change = false

    if on_change then
      on_change(inst.current_color)
    end
  end

  -- Show hex value
  ImGui.Spacing(ctx)
  ImGui.Separator(ctx)
  ImGui.Spacing(ctx)

  local hex_str = string.format("#%06X", (inst.current_color >> 8) & 0xFFFFFF)
  ImGui.Text(ctx, "Color: " .. hex_str)

  return changed
end

--- Render the color picker as a floating window
--- @param ctx userdata ImGui context
--- @param id string Unique identifier for this picker
--- @param config table Configuration { on_change = function(color), title = string }
--- @return boolean changed Whether color was changed this frame
function M.render(ctx, id, config)
  config = config or {}
  local inst = get_instance(id)

  if not inst.is_open then
    return false
  end

  local title = config.title or "Color Picker"
  local on_change = config.on_change

  -- Window flags: always on top, auto-resize, with close button
  local window_flags = ImGui.WindowFlags_AlwaysAutoResize |
                       ImGui.WindowFlags_NoCollapse |
                       ImGui.WindowFlags_TopMost

  -- Set initial window position (center of screen) on first open
  if inst.first_open then
    local viewport = ImGui.GetMainViewport(ctx)
    local display_w, display_h = ImGui.Viewport_GetSize(viewport)
    ImGui.SetNextWindowPos(ctx, display_w * 0.5, display_h * 0.5, ImGui.Cond_Appearing, 0.5, 0.5)
    inst.first_open = false
  end

  -- Begin window
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowPadding, 12, 12)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowRounding, 4)

  local visible, open = ImGui.Begin(ctx, title .. "##" .. id, true, window_flags)

  ImGui.PopStyleVar(ctx, 2)

  -- Update open state from window close button
  if not open then
    inst.is_open = false
    ImGui.End(ctx)
    return false
  end

  if not visible then
    ImGui.End(ctx)
    return false
  end

  -- Render the picker contents
  local changed = render_picker_contents(ctx, id, on_change)

  -- Close button at bottom
  ImGui.Spacing(ctx)
  local button_w = ImGui.GetContentRegionAvail(ctx)
  if ImGui.Button(ctx, "Close", button_w, 0) then
    inst.is_open = false
  end

  ImGui.End(ctx)

  return changed
end

--- Get the current color value
--- @param id string Unique identifier for this picker
--- @return number Current color (RGBA)
function M.get_color(id)
  local inst = get_instance(id)
  return inst.current_color
end

--- Set the current color value (without triggering callback)
--- @param id string Unique identifier for this picker
--- @param color number Color to set (RGBA)
function M.set_color(id, color)
  local inst = get_instance(id)
  inst.current_color = color
end

--- Render the color picker inline (embedded in a panel)
--- @param ctx userdata ImGui context
--- @param id string Unique identifier for this picker
--- @param config table Configuration { on_change = function(color), on_close = function(), initial_color = number, size = number }
--- @return boolean changed Whether color was changed this frame
function M.render_inline(ctx, id, config)
  config = config or {}
  local inst = get_instance(id)
  local on_change = config.on_change
  local on_close = config.on_close
  local size = config.size or 195

  -- Set initial color if provided
  if config.initial_color and inst.first_open then
    inst.current_color = config.initial_color
    inst.first_open = false
  end

  -- Extract RGB from current color
  local r = (inst.current_color >> 24) & 0xFF
  local g = (inst.current_color >> 16) & 0xFF
  local b = (inst.current_color >> 8) & 0xFF

  -- Use native ColorPicker4 with hue wheel
  local flags = ImGui.ColorEditFlags_PickerHueWheel |
                ImGui.ColorEditFlags_NoSidePreview |
                ImGui.ColorEditFlags_NoAlpha

  local rv, new_r, new_g, new_b = ImGui.ColorPicker4(ctx, "##picker_inline", r/255, g/255, b/255, flags)

  if rv then
    -- Convert back to packed RGBA
    inst.current_color = (math.floor(new_r * 255) << 24) |
                         (math.floor(new_g * 255) << 16) |
                         (math.floor(new_b * 255) << 8) | 0xFF
    inst.pending_change = true
  end

  -- Apply color only when mouse button is released
  if inst.pending_change and ImGui.IsMouseReleased(ctx, 0) then
    inst.pending_change = false
    if on_change then
      on_change(inst.current_color)
    end
  end

  return rv
end

--- Initialize inline picker (call this to show it)
--- @param id string Unique identifier for this picker
--- @param initial_color number Optional initial color (RGBA)
function M.show_inline(id, initial_color)
  local inst = get_instance(id)
  inst.first_open = true
  if initial_color then
    inst.current_color = initial_color
  end
end

return M
