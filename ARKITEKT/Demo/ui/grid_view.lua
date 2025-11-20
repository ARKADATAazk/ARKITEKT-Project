-- @noindex
-- Demo/ui/grid_view.lua
--
-- Showcase ARKITEKT's Grid system and widgets with Panel + tab_strip

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.10'

-- ARKITEKT dependencies
local Colors = require('rearkitekt.core.colors')
local Panel = require('rearkitekt.gui.widgets.containers.panel')
local Grid = require('rearkitekt.gui.widgets.containers.grid.core')
local Shapes = require('rearkitekt.gui.rendering.shapes')
local Button = require('rearkitekt.gui.widgets.primitives.button')
local Checkbox = require('rearkitekt.gui.widgets.primitives.checkbox')

local M = {}
local hexrgb = Colors.hexrgb

-- ============================================================================
-- PANEL STATE
-- ============================================================================

local panel = nil
local active_tab = "widgets"
local grid_instance = nil

local function init_panel()
  local tab_items = {
    { id = "widgets", label = "🎛️ Widgets" },
    { id = "grid", label = "📦 Grid" },
  }

  local tab_config = {
    spacing = 0,
    min_width = 80,
    max_width = 150,
    padding_x = 12,
    chip_radius = 6,
    on_change = function(new_tab)
      active_tab = new_tab
    end,
  }

  local panel_config = {
    header = {
      enabled = true,
      height = 32,
      elements = {
        {
          id = "tabs",
          type = "tab_strip",
          flex = 1,
          spacing_before = 0,
          config = tab_config,
        },
      },
    },
  }

  panel = Panel.new({
    id = "grid_demo_panel",
    config = panel_config,
  })

  panel:set_tabs(tab_items, active_tab)
end

-- ============================================================================
-- WIDGETS TAB (ARKITEKT Primitives)
-- ============================================================================

local function render_widgets_tab(ctx, state)
  if not state.grid.widget_state then
    state.grid.widget_state = {
      text_input = "Edit me!",
      checkbox1 = false,
      checkbox2 = true,
      checkbox3 = false,
      slider_value = 50,
      button_clicks = 0,
    }
  end

  local dl = ImGui.GetWindowDrawList(ctx)
  local ws = state.grid.widget_state

  ImGui.Spacing(ctx)
  ImGui.TextColored(ctx, hexrgb("#A78BFA"), "ARKITEKT Widget Showcase")
  ImGui.Spacing(ctx)
  ImGui.Separator(ctx)
  ImGui.Spacing(ctx)

  -- Buttons
  ImGui.Text(ctx, "Buttons:")
  ImGui.Spacing(ctx)

  local cursor_x, cursor_y = ImGui.GetCursorScreenPos(ctx)

  local btn_clicked = Button.draw(ctx, dl, cursor_x, cursor_y, 120, 32, {
    label = "Click Me!",
    bg_color = hexrgb("#3B82F6"),
    bg_hover_color = hexrgb("#2563EB"),
    text_color = hexrgb("#FFFFFF"),
    rounding = 6,
  }, "demo_btn_1")

  if btn_clicked then
    ws.button_clicks = ws.button_clicks + 1
  end

  ImGui.SetCursorScreenPos(ctx, cursor_x + 130, cursor_y)
  ImGui.Text(ctx, string.format("Clicked: %d times", ws.button_clicks))

  ImGui.SetCursorScreenPos(ctx, cursor_x, cursor_y + 40)
  ImGui.Spacing(ctx)
  ImGui.Spacing(ctx)

  -- Checkboxes
  ImGui.Text(ctx, "Checkboxes:")
  ImGui.Spacing(ctx)

  local cb1_clicked = Checkbox.draw_at_cursor(ctx, "Enable audio", ws.checkbox1, {}, "cb1")
  if cb1_clicked then
    ws.checkbox1 = not ws.checkbox1
  end

  local cb2_clicked = Checkbox.draw_at_cursor(ctx, "Enable MIDI", ws.checkbox2, {}, "cb2")
  if cb2_clicked then
    ws.checkbox2 = not ws.checkbox2
  end

  local cb3_clicked = Checkbox.draw_at_cursor(ctx, "Enable FX", ws.checkbox3, {}, "cb3")
  if cb3_clicked then
    ws.checkbox3 = not ws.checkbox3
  end

  ImGui.Spacing(ctx)
  ImGui.Spacing(ctx)

  -- Text Input
  ImGui.Text(ctx, "Text Input:")
  ImGui.Spacing(ctx)

  ImGui.SetNextItemWidth(ctx, 300)
  local changed, new_text = ImGui.InputText(ctx, "##text_input", ws.text_input)
  if changed then
    ws.text_input = new_text
  end

  ImGui.Spacing(ctx)
  ImGui.Spacing(ctx)

  -- Slider
  ImGui.Text(ctx, "Slider:")
  ImGui.Spacing(ctx)

  ImGui.SetNextItemWidth(ctx, 300)
  local slider_changed, new_val = ImGui.SliderInt(ctx, "##slider", ws.slider_value, 0, 100)
  if slider_changed then
    ws.slider_value = new_val
  end

  ImGui.SameLine(ctx)
  ImGui.Text(ctx, string.format("%d%%", ws.slider_value))

  ImGui.Dummy(ctx, 1, 20)
end

-- ============================================================================
-- GRID TAB (ARKITEKT Grid Widget)
-- ============================================================================

-- Tile renderer for grid
local function create_tile_renderer()
  return {
    draw = function(self, ctx, dl, x, y, w, h, item, is_selected, is_hovered)
      local rounding = 8

      -- Background
      local bg_color = item.color
      if is_selected then
        bg_color = Colors.adjust_brightness(bg_color, 1.3)
      elseif is_hovered then
        bg_color = Colors.adjust_brightness(bg_color, 1.15)
      end

      ImGui.DrawList_AddRectFilled(dl, x, y, x + w, y + h, bg_color, rounding)

      -- Draw shape
      local cx = x + w / 2
      local cy = y + h / 2
      local shape_size = math.min(w, h) * 0.3

      if item.shape == "star" then
        Shapes.draw_star_filled(dl, cx, cy, shape_size, shape_size * 0.4, hexrgb("#FFFFFF"), 5)
      elseif item.shape == "circle" then
        ImGui.DrawList_AddCircleFilled(dl, cx, cy, shape_size, hexrgb("#FFFFFF"))
      elseif item.shape == "square" then
        local half = shape_size
        ImGui.DrawList_AddRectFilled(dl, cx - half, cy - half, cx + half, cy + half, hexrgb("#FFFFFF"), 4)
      elseif item.shape == "triangle" then
        ImGui.DrawList_PathClear(dl)
        ImGui.DrawList_PathLineTo(dl, cx, cy - shape_size)
        ImGui.DrawList_PathLineTo(dl, cx + shape_size, cy + shape_size)
        ImGui.DrawList_PathLineTo(dl, cx - shape_size, cy + shape_size)
        ImGui.DrawList_PathFillConvex(dl, hexrgb("#FFFFFF"))
      end

      -- Label
      local label = item.name
      local label_w, label_h = ImGui.CalcTextSize(ctx, label)
      local label_x = x + (w - label_w) / 2
      local label_y = y + h - label_h - 8

      ImGui.DrawList_AddText(dl, label_x + 1, label_y + 1, hexrgb("#00000080"), label)
      ImGui.DrawList_AddText(dl, label_x, label_y, hexrgb("#FFFFFF"), label)

      -- Selection border
      if is_selected then
        ImGui.DrawList_AddRect(dl, x, y, x + w, y + h, hexrgb("#60A5FA"), rounding, 0, 3)
      elseif is_hovered then
        ImGui.DrawList_AddRect(dl, x, y, x + w, y + h, hexrgb("#FFFFFF40"), rounding, 0, 1)
      end
    end,

    get_tooltip = function(self, item)
      return string.format("%s\nShape: %s\nClick to select", item.name, item.shape)
    end,
  }
end

-- Initialize grid
local function init_grid(state)
  if grid_instance then return end

  -- Create sample items
  if not state.grid.shape_tiles then
    state.grid.shape_tiles = {
      { id = "star_red", name = "Star", shape = "star", color = hexrgb("#EF4444") },
      { id = "circle_blue", name = "Circle", shape = "circle", color = hexrgb("#3B82F6") },
      { id = "square_green", name = "Square", shape = "square", color = hexrgb("#10B981") },
      { id = "triangle_purple", name = "Triangle", shape = "triangle", color = hexrgb("#8B5CF6") },
      { id = "star_orange", name = "Star", shape = "star", color = hexrgb("#F59E0B") },
      { id = "circle_pink", name = "Circle", shape = "circle", color = hexrgb("#EC4899") },
      { id = "square_cyan", name = "Square", shape = "square", color = hexrgb("#06B6D4") },
      { id = "triangle_lime", name = "Triangle", shape = "triangle", color = hexrgb("#84CC16") },
      { id = "star_indigo", name = "Star", shape = "star", color = hexrgb("#6366F1") },
      { id = "circle_emerald", name = "Circle", shape = "circle", color = hexrgb("#10B981") },
      { id = "square_rose", name = "Square", shape = "square", color = hexrgb("#F43F5E") },
      { id = "triangle_amber", name = "Triangle", shape = "triangle", color = hexrgb("#F59E0B") },
    }
  end

  -- Create grid config
  local grid_config = {
    tile_size = 120,
    gap = 12,
    key = function(item) return item.id end,
    get_items = function() return state.grid.shape_tiles end,
    renderer = create_tile_renderer(),
    selection_mode = "multi",
  }

  grid_instance = Grid.new(grid_config)
end

local function render_grid_tab(ctx, state)
  init_grid(state)

  ImGui.Spacing(ctx)
  ImGui.TextColored(ctx, hexrgb("#A78BFA"), "ARKITEKT Grid Widget")
  ImGui.Spacing(ctx)
  ImGui.Separator(ctx)
  ImGui.Spacing(ctx)

  -- Controls
  local cursor_x, cursor_y = ImGui.GetCursorScreenPos(ctx)
  local dl = ImGui.GetWindowDrawList(ctx)

  local clear_btn = Button.draw(ctx, dl, cursor_x, cursor_y, 120, 28, {
    label = "Clear Selection",
    bg_color = hexrgb("#475569"),
    bg_hover_color = hexrgb("#334155"),
    text_color = hexrgb("#F8FAFC"),
    rounding = 6,
  }, "clear_sel_btn")

  if clear_btn then
    grid_instance:clear_selection()
  end

  ImGui.SetCursorScreenPos(ctx, cursor_x + 130, cursor_y + 4)
  local selected_count = #grid_instance:get_selected()
  ImGui.Text(ctx, string.format("Selected: %d / %d", selected_count, #state.grid.shape_tiles))

  ImGui.SetCursorScreenPos(ctx, cursor_x, cursor_y + 36)
  ImGui.Spacing(ctx)

  -- Render grid
  grid_instance:render(ctx)

  ImGui.Dummy(ctx, 1, 20)
end

-- ============================================================================
-- MAIN RENDER
-- ============================================================================

function M.render(ctx, state)
  -- Initialize panel
  if not panel then
    init_panel()
  end

  -- Initialize grid state
  if not state.grid then
    state.grid = {}
  end

  -- Update active tab from panel
  active_tab = panel:get_active_tab_id() or active_tab

  -- Render panel
  if panel:begin_draw(ctx) then
    -- Render content based on active tab
    if active_tab == "widgets" then
      render_widgets_tab(ctx, state)
    elseif active_tab == "grid" then
      render_grid_tab(ctx, state)
    end
  end
  panel:end_draw(ctx)
end

return M
