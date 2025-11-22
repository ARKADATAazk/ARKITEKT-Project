-- @noindex
-- ReArkitekt/app/icon.lua
-- App icon drawing functions (DPI-aware vector graphics)

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.10'

local M = {}

-- ReArkitekt logo v1: Original (smaller circles, simpler)
function M.draw_rearkitekt(ctx, x, y, size, color)
  local draw_list = ImGui.GetWindowDrawList(ctx)
  local dpi = ImGui.GetWindowDpiScale(ctx)
  
  -- Scale dimensions
  local s = size * dpi
  local half_s = s * 0.5
  local cx, cy = x + half_s, y + half_s
  
  -- Circle radius
  local r = s * 0.12
  
  -- Define positions (normalized to icon size)
  local top_x, top_y = cx, cy - s * 0.35
  local left_bot_x, left_bot_y = cx - s * 0.35, cy + s * 0.35
  local right_bot_x, right_bot_y = cx + s * 0.35, cy + s * 0.35
  local left_mid_x, left_mid_y = cx - s * 0.45, cy - s * 0.05
  local right_mid_x, right_mid_y = cx + s * 0.45, cy - s * 0.05
  
  -- Draw connecting lines (triangle "A")
  local thickness = math.max(1.5 * dpi, 1.0)
  ImGui.DrawList_AddLine(draw_list, top_x, top_y, left_bot_x, left_bot_y, color, thickness)
  ImGui.DrawList_AddLine(draw_list, top_x, top_y, right_bot_x, right_bot_y, color, thickness)
  ImGui.DrawList_AddLine(draw_list, left_bot_x, left_bot_y, right_bot_x, right_bot_y, color, thickness)
  
  -- Draw circles at vertices and sides (audio node controls)
  ImGui.DrawList_AddCircleFilled(draw_list, top_x, top_y, r, color)
  ImGui.DrawList_AddCircleFilled(draw_list, left_bot_x, left_bot_y, r, color)
  ImGui.DrawList_AddCircleFilled(draw_list, right_bot_x, right_bot_y, r, color)
  ImGui.DrawList_AddCircleFilled(draw_list, left_mid_x, left_mid_y, r * 0.7, color)
  ImGui.DrawList_AddCircleFilled(draw_list, right_mid_x, right_mid_y, r * 0.7, color)
end

-- ReArkitekt logo v2: Refined (larger bulbs, fader-style side controls)
function M.draw_rearkitekt_v2(ctx, x, y, size, color)
  local draw_list = ImGui.GetWindowDrawList(ctx)
  local dpi = ImGui.GetWindowDpiScale(ctx)
  
  local s = size * dpi
  local cx, cy = x + s * 0.5, y + s * 0.5
  
  -- Circle sizes
  local r_vertex = s * 0.20   -- Triangle vertex circles
  local r_side = s * 0.18     -- Side fader circles
  
  -- Triangle vertices (tighter triangle)
  local top_x, top_y = cx, cy - s * 0.28
  local left_bot_x, left_bot_y = cx - s * 0.28, cy + s * 0.32
  local right_bot_x, right_bot_y = cx + s * 0.28, cy + s * 0.32
  
  -- Draw thick triangle lines
  local thickness = math.max(3.0 * dpi, 2.5)
  ImGui.DrawList_AddLine(draw_list, top_x, top_y, left_bot_x, left_bot_y, color, thickness)
  ImGui.DrawList_AddLine(draw_list, top_x, top_y, right_bot_x, right_bot_y, color, thickness)
  ImGui.DrawList_AddLine(draw_list, left_bot_x, left_bot_y, right_bot_x, right_bot_y, color, thickness)
  
  -- Main circles at triangle vertices
  ImGui.DrawList_AddCircleFilled(draw_list, top_x, top_y, r_vertex, color)
  ImGui.DrawList_AddCircleFilled(draw_list, left_bot_x, left_bot_y, r_vertex, color)
  ImGui.DrawList_AddCircleFilled(draw_list, right_bot_x, right_bot_y, r_vertex, color)
  
  -- Side fader controls (outside triangle)
  local side_offset = s * 0.50
  local left_fader_x, left_fader_y = cx - side_offset, cy + s * 0.02
  local right_fader_x, right_fader_y = cx + side_offset, cy + s * 0.02
  
  ImGui.DrawList_AddCircleFilled(draw_list, left_fader_x, left_fader_y, r_side, color)
  ImGui.DrawList_AddCircleFilled(draw_list, right_fader_x, right_fader_y, r_side, color)
  
  -- Small squares above side faders
  local sq_size = s * 0.10
  local sq_y = cy - s * 0.25
  ImGui.DrawList_AddRectFilled(draw_list, 
    left_fader_x - sq_size/2, sq_y - sq_size/2,
    left_fader_x + sq_size/2, sq_y + sq_size/2,
    color, sq_size * 0.15)
  ImGui.DrawList_AddRectFilled(draw_list, 
    right_fader_x - sq_size/2, sq_y - sq_size/2,
    right_fader_x + sq_size/2, sq_y + sq_size/2,
    color, sq_size * 0.15)
  
  -- Center horizontal bar (crossfader)
  local bar_w = s * 0.18
  local bar_h = s * 0.08
  local bar_y = cy + s * 0.02
  ImGui.DrawList_AddRectFilled(draw_list,
    cx - bar_w/2, bar_y - bar_h/2,
    cx + bar_w/2, bar_y + bar_h/2,
    color, bar_h * 0.2)
end

-- Alternative: Simple "A" monogram
function M.draw_simple_a(ctx, x, y, size, color)
  local draw_list = ImGui.GetWindowDrawList(ctx)
  local dpi = ImGui.GetWindowDpiScale(ctx)

  local s = size * dpi
  local cx, cy = x + s * 0.5, y + s * 0.5

  -- Triangle "A"
  local top_x, top_y = cx, cy - s * 0.4
  local left_x, left_y = cx - s * 0.35, cy + s * 0.4
  local right_x, right_y = cx + s * 0.35, cy + s * 0.4

  local thickness = math.max(2.0 * dpi, 1.5)
  ImGui.DrawList_AddLine(draw_list, top_x, top_y, left_x, left_y, color, thickness)
  ImGui.DrawList_AddLine(draw_list, top_x, top_y, right_x, right_y, color, thickness)

  -- Crossbar
  local bar_y = cy + s * 0.1
  ImGui.DrawList_AddLine(draw_list, cx - s * 0.25, bar_y, cx + s * 0.25, bar_y, color, thickness)
end

-- Arkitekt Default Logo (SVG-converted)
-- Auto-generated from AArkitekt_default.svg
function M.draw_arkitekt_default(ctx, x, y, size, color)
  local dl = ImGui.GetWindowDrawList(ctx)
  local dpi = ImGui.GetWindowDpiScale(ctx)
  local s = size * dpi

  -- Path 1 - Main shape
  ImGui.DrawList_PathClear(dl)
  ImGui.DrawList_PathLineTo(dl, x + s*0.534445, y + s*0.044154)
  ImGui.DrawList_PathBezierCubicCurveTo(dl, x + s*0.464979, y + s*0.211595, x + s*0.205739, y + s*0.495412, x + s*0.105644, y + s*0.595469)
  ImGui.DrawList_PathBezierCubicCurveTo(dl, x + s*0.000000, y + s*0.701114, x + s*0.607954, y + s*0.950761, x + s*0.607954, y + s*0.950761)
  ImGui.DrawList_PathLineTo(dl, x + s*1.000000, y + s*0.668978)
  ImGui.DrawList_PathLineTo(dl, x + s*0.872462, y + s*0.525232)
  ImGui.DrawList_PathBezierCubicCurveTo(dl, x + s*0.872462, y + s*0.525232, x + s*0.829215, y + s*0.478578, x + s*0.780944, y + s*0.352327)
  ImGui.DrawList_PathBezierCubicCurveTo(dl, x + s*0.769550, y + s*0.324859, x + s*0.832645, y + s*0.109920, x + s*0.840731, y + s*0.093160)
  ImGui.DrawList_PathBezierCubicCurveTo(dl, x + s*0.883366, y + s*0.004178, x + s*0.552700, y + s*0.000000, x + s*0.534445, y + s*0.044154)
  ImGui.DrawList_PathFillConvex(dl, color)

  -- Path 2 - Top rectangle
  ImGui.DrawList_PathClear(dl)
  ImGui.DrawList_PathLineTo(dl, x + s*1.000000, y + s*0.028915)
  ImGui.DrawList_PathBezierCubicCurveTo(dl, x + s*1.000000, y + s*0.012957, x + s*0.987365, y + s*0.000000, x + s*0.971875, y + s*0.000000)
  ImGui.DrawList_PathLineTo(dl, x + s*0.651507, y + s*0.000000)
  ImGui.DrawList_PathBezierCubicCurveTo(dl, x + s*0.636017, y + s*0.000000, x + s*0.623382, y + s*0.012957, x + s*0.623382, y + s*0.028915)
  ImGui.DrawList_PathLineTo(dl, x + s*0.623382, y + s*0.141171)
  ImGui.DrawList_PathBezierCubicCurveTo(dl, x + s*0.623382, y + s*0.157129, x + s*0.636017, y + s*0.170086, x + s*0.651507, y + s*0.170086)
  ImGui.DrawList_PathLineTo(dl, x + s*0.971875, y + s*0.170086)
  ImGui.DrawList_PathBezierCubicCurveTo(dl, x + s*0.987365, y + s*0.170086, x + s*1.000000, y + s*0.157129, x + s*1.000000, y + s*0.141171)
  ImGui.DrawList_PathLineTo(dl, x + s*1.000000, y + s*0.028915)
  ImGui.DrawList_PathFillConvex(dl, color)

  -- Path 3
  ImGui.DrawList_PathClear(dl)
  ImGui.DrawList_PathLineTo(dl, x + s*1.000000, y + s*0.028915)
  ImGui.DrawList_PathBezierCubicCurveTo(dl, x + s*1.000000, y + s*0.012957, x + s*0.973029, y + s*0.000000, x + s*0.939741, y + s*0.000000)
  ImGui.DrawList_PathLineTo(dl, x + s*0.683641, y + s*0.000000)
  ImGui.DrawList_PathBezierCubicCurveTo(dl, x + s*0.650353, y + s*0.000000, x + s*0.623382, y + s*0.012957, x + s*0.623382, y + s*0.028915)
  ImGui.DrawList_PathLineTo(dl, x + s*0.623382, y + s*0.141171)
  ImGui.DrawList_PathBezierCubicCurveTo(dl, x + s*0.623382, y + s*0.157129, x + s*0.650353, y + s*0.170086, x + s*0.683641, y + s*0.170086)
  ImGui.DrawList_PathLineTo(dl, x + s*0.939741, y + s*0.170086)
  ImGui.DrawList_PathBezierCubicCurveTo(dl, x + s*0.973029, y + s*0.170086, x + s*1.000000, y + s*0.157129, x + s*1.000000, y + s*0.141171)
  ImGui.DrawList_PathLineTo(dl, x + s*1.000000, y + s*0.028915)
  ImGui.DrawList_PathFillConvex(dl, color)

  -- Path 4
  ImGui.DrawList_PathClear(dl)
  ImGui.DrawList_PathLineTo(dl, x + s*1.000000, y + s*0.013649)
  ImGui.DrawList_PathBezierCubicCurveTo(dl, x + s*1.000000, y + s*0.006117, x + s*0.971328, y + s*0.000000, x + s*0.935975, y + s*0.000000)
  ImGui.DrawList_PathLineTo(dl, x + s*0.687407, y + s*0.000000)
  ImGui.DrawList_PathBezierCubicCurveTo(dl, x + s*0.652053, y + s*0.000000, x + s*0.623382, y + s*0.006117, x + s*0.623382, y + s*0.013649)
  ImGui.DrawList_PathLineTo(dl, x + s*0.623382, y + s*0.156436)
  ImGui.DrawList_PathBezierCubicCurveTo(dl, x + s*0.623382, y + s*0.163969, x + s*0.652053, y + s*0.170086, x + s*0.687407, y + s*0.170086)
  ImGui.DrawList_PathLineTo(dl, x + s*0.935975, y + s*0.170086)
  ImGui.DrawList_PathBezierCubicCurveTo(dl, x + s*0.971328, y + s*0.170086, x + s*1.000000, y + s*0.163969, x + s*1.000000, y + s*0.156436)
  ImGui.DrawList_PathLineTo(dl, x + s*1.000000, y + s*0.013649)
  ImGui.DrawList_PathFillConvex(dl, color)

  -- Path 5 - Small detail
  ImGui.DrawList_PathClear(dl)
  ImGui.DrawList_PathLineTo(dl, x + s*0.184465, y + s*0.020722)
  ImGui.DrawList_PathBezierCubicCurveTo(dl, x + s*0.182430, y + s*0.072317, x + s*0.193161, y + s*0.131730, x + s*0.240987, y + s*0.181730)
  ImGui.DrawList_PathBezierCubicCurveTo(dl, x + s*0.269696, y + s*0.211743, x + s*0.000000, y + s*0.188430, x + s*0.000000, y + s*0.188430)
  ImGui.DrawList_PathBezierCubicCurveTo(dl, x + s*0.000000, y + s*0.188430, x + s*0.047100, y + s*0.158722, x + s*0.047826, y + s*0.040604)
  ImGui.DrawList_PathBezierCubicCurveTo(dl, x + s*0.047961, y + s*0.018865, x + s*0.126087, y + s*0.040604, x + s*0.126087, y + s*0.040604)
  ImGui.DrawList_PathBezierCubicCurveTo(dl, x + s*0.126087, y + s*0.040604, x + s*0.185557, y + s*0.000000, x + s*0.184465, y + s*0.020722)
  ImGui.DrawList_PathFillConvex(dl, color)

  -- Path 6 - Center ellipse
  ImGui.DrawList_PathClear(dl)
  ImGui.DrawList_PathLineTo(dl, x + s*0.282609, y + s*0.573213)
  ImGui.DrawList_PathBezierCubicCurveTo(dl, x + s*0.282609, y + s*0.632934, x + s*0.429409, y + s*0.779735, x + s*0.489130, y + s*0.779735)
  ImGui.DrawList_PathBezierCubicCurveTo(dl, x + s*0.548851, y + s*0.779735, x + s*0.695652, y + s*0.632934, x + s*0.695652, y + s*0.573213)
  ImGui.DrawList_PathBezierCubicCurveTo(dl, x + s*0.695652, y + s*0.513492, x + s*0.548851, y + s*0.366691, x + s*0.489130, y + s*0.366691)
  ImGui.DrawList_PathBezierCubicCurveTo(dl, x + s*0.429409, y + s*0.366691, x + s*0.282609, y + s*0.513492, x + s*0.282609, y + s*0.573213)
  ImGui.DrawList_PathFillConvex(dl, color)

  -- Path 7 - Left ellipse
  ImGui.DrawList_PathClear(dl)
  ImGui.DrawList_PathLineTo(dl, x + s*0.000000, y + s*0.249324)
  ImGui.DrawList_PathBezierCubicCurveTo(dl, x + s*0.000000, y + s*0.289419, x + s*0.098560, y + s*0.387979, x + s*0.138655, y + s*0.387979)
  ImGui.DrawList_PathBezierCubicCurveTo(dl, x + s*0.178751, y + s*0.387979, x + s*0.277311, y + s*0.289419, x + s*0.277311, y + s*0.249324)
  ImGui.DrawList_PathBezierCubicCurveTo(dl, x + s*0.277311, y + s*0.209228, x + s*0.178751, y + s*0.110668, x + s*0.138655, y + s*0.110668)
  ImGui.DrawList_PathBezierCubicCurveTo(dl, x + s*0.098560, y + s*0.110668, x + s*0.000000, y + s*0.209228, x + s*0.000000, y + s*0.249324)
  ImGui.DrawList_PathFillConvex(dl, color)

  -- Path 8 - Vertical bar
  ImGui.DrawList_PathClear(dl)
  ImGui.DrawList_PathLineTo(dl, x + s*0.655462, y + s*0.000000)
  ImGui.DrawList_PathLineTo(dl, x + s*0.869748, y + s*0.000000)
  ImGui.DrawList_PathLineTo(dl, x + s*0.869748, y + s*0.659664)
  ImGui.DrawList_PathLineTo(dl, x + s*0.655462, y + s*0.659664)
  ImGui.DrawList_PathLineTo(dl, x + s*0.655462, y + s*0.000000)
  ImGui.DrawList_PathFillConvex(dl, color)

  -- Path 9 - Bottom ellipse
  ImGui.DrawList_PathClear(dl)
  ImGui.DrawList_PathLineTo(dl, x + s*0.306723, y + s*0.733193)
  ImGui.DrawList_PathBezierCubicCurveTo(dl, x + s*0.306723, y + s*0.790907, x + s*0.448589, y + s*0.932773, x + s*0.506303, y + s*0.932773)
  ImGui.DrawList_PathBezierCubicCurveTo(dl, x + s*0.564016, y + s*0.932773, x + s*0.705882, y + s*0.790907, x + s*0.705882, y + s*0.733193)
  ImGui.DrawList_PathBezierCubicCurveTo(dl, x + s*0.705882, y + s*0.675480, x + s*0.564016, y + s*0.533613, x + s*0.506303, y + s*0.533613)
  ImGui.DrawList_PathBezierCubicCurveTo(dl, x + s*0.448589, y + s*0.533613, x + s*0.306723, y + s*0.675480, x + s*0.306723, y + s*0.733193)
  ImGui.DrawList_PathFillConvex(dl, color)

  -- Path 10 - Lower left ellipse
  ImGui.DrawList_PathClear(dl)
  ImGui.DrawList_PathLineTo(dl, x + s*0.000000, y + s*0.428571)
  ImGui.DrawList_PathBezierCubicCurveTo(dl, x + s*0.000000, y + s*0.468667, x + s*0.098560, y + s*0.567227, x + s*0.138655, y + s*0.567227)
  ImGui.DrawList_PathBezierCubicCurveTo(dl, x + s*0.178751, y + s*0.567227, x + s*0.277311, y + s*0.468667, x + s*0.277311, y + s*0.428571)
  ImGui.DrawList_PathBezierCubicCurveTo(dl, x + s*0.277311, y + s*0.388476, x + s*0.178751, y + s*0.289916, x + s*0.138655, y + s*0.289916)
  ImGui.DrawList_PathBezierCubicCurveTo(dl, x + s*0.098560, y + s*0.289916, x + s*0.000000, y + s*0.388476, x + s*0.000000, y + s*0.428571)
  ImGui.DrawList_PathFillConvex(dl, color)
end

return M