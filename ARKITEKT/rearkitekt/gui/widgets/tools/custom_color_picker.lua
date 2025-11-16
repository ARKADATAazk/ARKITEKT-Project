-- @noindex
-- ReArkitekt/gui/widgets/tools/custom_color_picker.lua
-- Enhanced color picker based on ImGui's ColorPicker4 implementation
-- Features smooth gradients, proper triangle rendering, and polished cursors

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.10'
local Colors = require('rearkitekt.core.colors')

local M = {}

-- Convert HSV to RGB (matches ImGui's ColorConvertHSVtoRGB)
local function hsv_to_rgb(h, s, v)
  local c = v * s
  local x = c * (1 - math.abs((h * 6) % 2 - 1))
  local m = v - c

  local r, g, b
  if h < 1/6 then
    r, g, b = c, x, 0
  elseif h < 2/6 then
    r, g, b = x, c, 0
  elseif h < 3/6 then
    r, g, b = 0, c, x
  elseif h < 4/6 then
    r, g, b = 0, x, c
  elseif h < 5/6 then
    r, g, b = x, 0, c
  else
    r, g, b = c, 0, x
  end

  return (r + m) * 255, (g + m) * 255, (b + m) * 255
end

-- Convert RGB to HSV (matches ImGui's ColorConvertRGBtoHSV)
local function rgb_to_hsv(r, g, b)
  r, g, b = r / 255, g / 255, b / 255
  local max_c = math.max(r, g, b)
  local min_c = math.min(r, g, b)
  local delta = max_c - min_c

  local h = 0
  if delta ~= 0 then
    if max_c == r then
      h = ((g - b) / delta) % 6
    elseif max_c == g then
      h = (b - r) / delta + 2
    else
      h = (r - g) / delta + 4
    end
    h = h / 6
  end

  local s = (max_c == 0) and 0 or (delta / max_c)
  local v = max_c

  return h, s, v
end

-- Rotate a point around origin (for triangle rotation)
local function rotate_point(x, y, cos_a, sin_a)
  return x * cos_a - y * sin_a, x * sin_a + y * cos_a
end

-- Check if point is in triangle using barycentric coordinates
local function point_in_triangle(px, py, ax, ay, bx, by, cx, cy)
  local v0x, v0y = cx - ax, cy - ay
  local v1x, v1y = bx - ax, by - ay
  local v2x, v2y = px - ax, py - ay

  local dot00 = v0x * v0x + v0y * v0y
  local dot01 = v0x * v1x + v0y * v1y
  local dot02 = v0x * v2x + v0y * v2y
  local dot11 = v1x * v1x + v1y * v1y
  local dot12 = v1x * v2x + v1y * v2y

  local denom = dot00 * dot11 - dot01 * dot01
  if math.abs(denom) < 0.0001 then return false end

  local inv_denom = 1 / denom
  local u = (dot11 * dot02 - dot01 * dot12) * inv_denom
  local v = (dot00 * dot12 - dot01 * dot02) * inv_denom

  return (u >= 0) and (v >= 0) and (u + v <= 1)
end

-- Get barycentric coordinates for a point in triangle
local function get_barycentric(px, py, ax, ay, bx, by, cx, cy)
  local v0x, v0y = bx - ax, by - ay
  local v1x, v1y = cx - ax, cy - ay
  local v2x, v2y = px - ax, py - ay

  local d00 = v0x * v0x + v0y * v0y
  local d01 = v0x * v1x + v0y * v1y
  local d11 = v1x * v1x + v1y * v1y
  local d20 = v2x * v0x + v2y * v0y
  local d21 = v2x * v1x + v2y * v1y

  local denom = d00 * d11 - d01 * d01
  if math.abs(denom) < 0.0001 then return 0, 0, 0 end

  local inv_denom = 1 / denom
  local v = (d11 * d20 - d01 * d21) * inv_denom
  local w = (d00 * d21 - d01 * d20) * inv_denom
  local u = 1 - v - w

  return u, v, w
end

-- Find closest point on triangle edge
local function closest_point_on_triangle(px, py, ax, ay, bx, by, cx, cy)
  -- Helper to get closest point on line segment
  local function closest_on_segment(px, py, ax, ay, bx, by)
    local dx, dy = bx - ax, by - ay
    local t = ((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy)
    t = math.max(0, math.min(1, t))
    return ax + t * dx, ay + t * dy
  end

  -- Check all three edges
  local c1x, c1y = closest_on_segment(px, py, ax, ay, bx, by)
  local c2x, c2y = closest_on_segment(px, py, bx, by, cx, cy)
  local c3x, c3y = closest_on_segment(px, py, cx, cy, ax, ay)

  local d1 = (px - c1x)^2 + (py - c1y)^2
  local d2 = (px - c2x)^2 + (py - c2y)^2
  local d3 = (px - c3x)^2 + (py - c3y)^2

  if d1 <= d2 and d1 <= d3 then
    return c1x, c1y
  elseif d2 <= d3 then
    return c2x, c2y
  else
    return c3x, c3y
  end
end

--- Render enhanced color picker (based on ImGui ColorPicker4)
--- @param ctx userdata ImGui context
--- @param size number Size of the picker
--- @param h number Hue (0-1)
--- @param s number Saturation (0-1)
--- @param v number Value (0-1)
--- @return boolean changed, number h, number s, number v
function M.render(ctx, size, h, s, v)
  local changed = false
  local value_changed_h = false
  local value_changed_sv = false

  local draw_list = ImGui.GetWindowDrawList(ctx)
  local cx, cy = ImGui.GetCursorScreenPos(ctx)

  -- Picker geometry (matching ImGui's calculations)
  local wheel_thickness = size * 0.08
  local wheel_r_outer = size * 0.50
  local wheel_r_inner = wheel_r_outer - wheel_thickness
  local center_x = cx + size * 0.5
  local center_y = cy + size * 0.5

  -- Triangle geometry
  local triangle_r = wheel_r_inner - math.floor(size * 0.027)
  local triangle_pa_x, triangle_pa_y = triangle_r, 0  -- Hue point
  local triangle_pb_x, triangle_pb_y = triangle_r * -0.5, triangle_r * -0.866025  -- Black point
  local triangle_pc_x, triangle_pc_y = triangle_r * -0.5, triangle_r * 0.866025   -- White point

  -- Color definitions
  local col_white = 0xFFFFFFFF
  local col_black = 0xFF000000
  local col_midgrey = 0xFF808080

  -- Hue colors for the wheel (matching ImGui's col_hues array)
  local col_hues = {
    0xFF0000FF, -- Red
    0xFF00FFFF, -- Yellow
    0xFF00FF00, -- Green
    0xFFFFFF00, -- Cyan
    0xFFFF0000, -- Blue
    0xFFFF00FF, -- Magenta
    0xFF0000FF, -- Red (wraparound)
  }

  -- === RENDER HUE WHEEL ===
  local aeps = 0.5 / wheel_r_outer  -- Half a pixel arc length
  local segment_per_arc = math.max(4, math.floor(wheel_r_outer / 12))

  for n = 0, 5 do
    local a0 = (n / 6) * 2 * math.pi - aeps
    local a1 = ((n + 1) / 6) * 2 * math.pi + aeps

    -- Draw arc as thick path
    local num_segments = segment_per_arc
    for i = 0, num_segments - 1 do
      local t0 = i / num_segments
      local t1 = (i + 1) / num_segments
      local angle0 = a0 + (a1 - a0) * t0
      local angle1 = a0 + (a1 - a0) * t1

      local x0_out = center_x + math.cos(angle0) * wheel_r_outer
      local y0_out = center_y + math.sin(angle0) * wheel_r_outer
      local x1_out = center_x + math.cos(angle1) * wheel_r_outer
      local y1_out = center_y + math.sin(angle1) * wheel_r_outer

      local x0_in = center_x + math.cos(angle0) * wheel_r_inner
      local y0_in = center_y + math.sin(angle0) * wheel_r_inner
      local x1_in = center_x + math.cos(angle1) * wheel_r_inner
      local y1_in = center_y + math.sin(angle1) * wheel_r_inner

      -- Interpolate colors
      local mix = t0
      local r1, g1, b1 = hsv_to_rgb(n / 6 + mix / 6, 1, 1)
      local col = ImGui.ColorConvertDouble4ToU32(r1/255, g1/255, b1/255, 1)

      ImGui.DrawList_AddQuadFilled(draw_list, x0_out, y0_out, x1_out, y1_out, x1_in, y1_in, x0_in, y0_in, col)
    end
  end

  -- === RENDER HUE CURSOR ===
  local cos_hue_angle = math.cos(h * 2 * math.pi)
  local sin_hue_angle = math.sin(h * 2 * math.pi)
  local hue_cursor_pos_x = center_x + cos_hue_angle * (wheel_r_inner + wheel_r_outer) * 0.5
  local hue_cursor_pos_y = center_y + sin_hue_angle * (wheel_r_inner + wheel_r_outer) * 0.5
  local hue_cursor_rad = value_changed_h and (wheel_thickness * 0.65) or (wheel_thickness * 0.55)

  -- Get current hue color
  local r_hue, g_hue, b_hue = hsv_to_rgb(h, 1, 1)
  local hue_color32 = ImGui.ColorConvertDouble4ToU32(r_hue/255, g_hue/255, b_hue/255, 1)

  ImGui.DrawList_AddCircleFilled(draw_list, hue_cursor_pos_x, hue_cursor_pos_y, hue_cursor_rad, hue_color32, 32)
  ImGui.DrawList_AddCircle(draw_list, hue_cursor_pos_x, hue_cursor_pos_y, hue_cursor_rad + 1, col_midgrey, 32, 2)
  ImGui.DrawList_AddCircle(draw_list, hue_cursor_pos_x, hue_cursor_pos_y, hue_cursor_rad, col_white, 32, 2)

  -- === RENDER SV TRIANGLE (rotated by hue) ===
  local tra_x = center_x + cos_hue_angle * triangle_pa_x - sin_hue_angle * triangle_pa_y
  local tra_y = center_y + sin_hue_angle * triangle_pa_x + cos_hue_angle * triangle_pa_y
  local trb_x = center_x + cos_hue_angle * triangle_pb_x - sin_hue_angle * triangle_pb_y
  local trb_y = center_y + sin_hue_angle * triangle_pb_x + cos_hue_angle * triangle_pb_y
  local trc_x = center_x + cos_hue_angle * triangle_pc_x - sin_hue_angle * triangle_pc_y
  local trc_y = center_y + sin_hue_angle * triangle_pc_x + cos_hue_angle * triangle_pc_y

  -- Draw triangle with proper vertex colors using PrimReserve/PrimVtx approach
  -- We'll approximate the gradient by drawing the triangle in layers

  -- Base triangle with hue color at top, black at bottom-left, white at bottom-right
  ImGui.DrawList_PathClear(draw_list)
  ImGui.DrawList_PathLineTo(draw_list, tra_x, tra_y)
  ImGui.DrawList_PathLineTo(draw_list, trb_x, trb_y)
  ImGui.DrawList_PathLineTo(draw_list, trc_x, trc_y)
  ImGui.DrawList_PathFillConvex(draw_list, hue_color32)

  -- Add white to black gradient overlay (simulating saturation/value)
  -- We'll draw horizontal strips from white corner to black corner
  local gradient_steps = 32
  for i = 0, gradient_steps do
    local t = i / gradient_steps
    local alpha = math.floor(255 * (1 - t))

    -- From white corner
    local overlay_col = ImGui.ColorConvertDouble4ToU32(0, 0, 0, alpha / 255)

    ImGui.DrawList_PathClear(draw_list)
    ImGui.DrawList_PathLineTo(draw_list, tra_x, tra_y)
    ImGui.DrawList_PathLineTo(draw_list, trb_x, trb_y)
    ImGui.DrawList_PathLineTo(draw_list, trc_x, trc_y)
    ImGui.DrawList_PathFillConvex(draw_list, overlay_col)
  end

  -- Better approach: draw using vertex colors (simplified gradient)
  -- White to color gradient from bottom-right to top
  for i = 0, 15 do
    local t = i / 15
    local next_t = (i + 1) / 15

    local p1_x = trc_x + (tra_x - trc_x) * t
    local p1_y = trc_y + (tra_y - trc_y) * t
    local p2_x = trc_x + (tra_x - trc_x) * next_t
    local p2_y = trc_y + (tra_y - trc_y) * next_t

    local alpha_white = math.floor(255 * (1 - t))
    local col_overlay = ImGui.ColorConvertDouble4ToU32(1, 1, 1, alpha_white / 255)

    -- Draw thin quad strip
    ImGui.DrawList_AddQuadFilled(draw_list,
      trc_x, trc_y, p1_x, p1_y, p2_x, p2_y, trc_x, trc_y, col_overlay)
  end

  -- Black gradient from bottom-left to top
  for i = 0, 15 do
    local t = i / 15
    local next_t = (i + 1) / 15

    local p1_x = trb_x + (tra_x - trb_x) * t
    local p1_y = trb_y + (tra_y - trb_y) * t
    local p2_x = trb_x + (tra_x - trb_x) * next_t
    local p2_y = trb_y + (tra_y - trb_y) * next_t

    local alpha_black = math.floor(255 * (1 - t))
    local col_overlay = ImGui.ColorConvertDouble4ToU32(0, 0, 0, alpha_black / 255)

    -- Draw thin quad strip
    ImGui.DrawList_AddQuadFilled(draw_list,
      trb_x, trb_y, p1_x, p1_y, p2_x, p2_y, trb_x, trb_y, col_overlay)
  end

  -- Triangle border
  ImGui.DrawList_AddTriangle(draw_list, tra_x, tra_y, trb_x, trb_y, trc_x, trc_y, col_midgrey, 1.5)

  -- === RENDER SV CURSOR ===
  -- Calculate cursor position using linear interpolation (ImLerp in ImGui)
  local sv_cursor_x = trc_x + (tra_x - trc_x) * s + (trb_x - trc_x) * (1 - v)
  local sv_cursor_y = trc_y + (tra_y - trc_y) * s + (trb_y - trc_y) * (1 - v)
  local sv_cursor_rad = value_changed_sv and (wheel_thickness * 0.55) or (wheel_thickness * 0.40)

  -- Get current color
  local r_cur, g_cur, b_cur = hsv_to_rgb(h, s, v)
  local user_col32 = ImGui.ColorConvertDouble4ToU32(r_cur/255, g_cur/255, b_cur/255, 1)

  ImGui.DrawList_AddCircleFilled(draw_list, sv_cursor_x, sv_cursor_y, sv_cursor_rad, user_col32, 32)
  ImGui.DrawList_AddCircle(draw_list, sv_cursor_x, sv_cursor_y, sv_cursor_rad + 1, col_midgrey, 32, 2)
  ImGui.DrawList_AddCircle(draw_list, sv_cursor_x, sv_cursor_y, sv_cursor_rad, col_white, 32, 2)

  -- === INTERACTION ===
  ImGui.SetCursorScreenPos(ctx, cx, cy)
  ImGui.InvisibleButton(ctx, "##picker_wheel", size, size)

  if ImGui.IsItemActive(ctx) then
    local mx, my = ImGui.GetMousePos(ctx)
    local initial_mx, initial_my = ImGui.GetMouseClickedPos(ctx, 0)

    -- Check initial click position
    local dx = initial_mx - center_x
    local dy = initial_my - center_y
    local dist = math.sqrt(dx * dx + dy * dy)

    -- Interacting with hue wheel
    if dist >= (wheel_r_inner - 1) and dist <= (wheel_r_outer + 1) then
      local current_dx = mx - center_x
      local current_dy = my - center_y
      h = math.atan(current_dy, current_dx) / math.pi * 0.5
      if h < 0 then h = h + 1 end
      changed = true
      value_changed_h = true
    end

    -- Interacting with SV triangle
    -- Transform initial click to unrotated space
    local cos_neg = math.cos(-h * 2 * math.pi)
    local sin_neg = math.sin(-h * 2 * math.pi)
    local initial_off_x = initial_mx - center_x
    local initial_off_y = initial_my - center_y
    local initial_unrot_x, initial_unrot_y = rotate_point(initial_off_x, initial_off_y, cos_neg, sin_neg)

    if point_in_triangle(initial_unrot_x, initial_unrot_y,
                         triangle_pa_x, triangle_pa_y,
                         triangle_pb_x, triangle_pb_y,
                         triangle_pc_x, triangle_pc_y) then
      -- Transform current position
      local current_off_x = mx - center_x
      local current_off_y = my - center_y
      local current_unrot_x, current_unrot_y = rotate_point(current_off_x, current_off_y, cos_neg, sin_neg)

      -- Clamp to triangle if outside
      if not point_in_triangle(current_unrot_x, current_unrot_y,
                               triangle_pa_x, triangle_pa_y,
                               triangle_pb_x, triangle_pb_y,
                               triangle_pc_x, triangle_pc_y) then
        current_unrot_x, current_unrot_y = closest_point_on_triangle(
          current_unrot_x, current_unrot_y,
          triangle_pa_x, triangle_pa_y,
          triangle_pb_x, triangle_pb_y,
          triangle_pc_x, triangle_pc_y)
      end

      -- Get barycentric coordinates
      local uu, vv, ww = get_barycentric(
        current_unrot_x, current_unrot_y,
        triangle_pa_x, triangle_pa_y,
        triangle_pb_x, triangle_pb_y,
        triangle_pc_x, triangle_pc_y)

      v = math.max(0.0001, math.min(1, 1 - vv))
      s = math.max(0.0001, math.min(1, uu / v))
      changed = true
      value_changed_sv = true
    end
  end

  return changed, h, s, v
end

return M
