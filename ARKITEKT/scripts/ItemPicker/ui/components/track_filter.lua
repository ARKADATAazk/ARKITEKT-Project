-- @noindex
-- ItemPicker/ui/components/track_filter.lua
-- Track whitelist filter with tile-style track headers

local ImGui = require 'imgui' '0.10'
local Colors = require('rearkitekt.core.colors')

local M = {}

-- Tile styling constants
local TRACK_TILE = {
  HEIGHT = 24,
  PADDING_X = 8,
  PADDING_Y = 4,
  MARGIN_Y = 2,
  ROUNDING = 4,
  COLOR_BAR_WIDTH = 4,
}

-- Ensure color has minimum lightness for readability
local function ensure_min_lightness(color, min_lightness)
  local h, s, l = Colors.rgb_to_hsl(color)
  if l < min_lightness then
    l = min_lightness
  end
  local r, g, b = Colors.hsl_to_rgb(h, s, l)
  return Colors.components_to_rgba(r, g, b, 0xFF)
end

-- Get track color from REAPER's COLORREF format
local function get_track_display_color(track_color)
  if track_color and (track_color & 0x01000000) ~= 0 then
    -- Has color: extract RGB from COLORREF (0x00BBGGRR)
    local colorref = track_color & 0x00FFFFFF
    local R = colorref & 255
    local G = (colorref >> 8) & 255
    local B = (colorref >> 16) & 255
    return ImGui.ColorConvertDouble4ToU32(R/255, G/255, B/255, 1)
  else
    -- No color: use default grey
    return ImGui.ColorConvertDouble4ToU32(85/255, 91/255, 91/255, 1)
  end
end

-- Collect all unique tracks from loaded items
function M.collect_tracks(state)
  local tracks = {}
  local seen_guids = {}

  -- Helper to add track from item data
  local function add_track_from_item(item_data)
    if not item_data or not item_data.item then return end

    local item = item_data.item
    if not reaper.ValidatePtr2(0, item, "MediaItem*") then return end

    local track = reaper.GetMediaItem_Track(item)
    if not track then return end

    local guid = reaper.GetTrackGUID(track)
    if seen_guids[guid] then return end
    seen_guids[guid] = true

    local _, track_name = reaper.GetTrackName(track)
    local track_color = reaper.GetMediaTrackInfo_Value(track, "I_CUSTOMCOLOR")
    local track_idx = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")

    table.insert(tracks, {
      guid = guid,
      name = track_name or "Track " .. math.floor(track_idx),
      color = track_color,
      display_color = get_track_display_color(track_color),
      index = track_idx,
    })
  end

  -- Collect from raw audio items
  if state.loader and state.loader.raw_audio_items then
    for _, item_data in ipairs(state.loader.raw_audio_items) do
      add_track_from_item(item_data)
    end
  end

  -- Collect from raw MIDI items
  if state.loader and state.loader.raw_midi_items then
    for _, item_data in ipairs(state.loader.raw_midi_items) do
      add_track_from_item(item_data)
    end
  end

  -- Sort by track index
  table.sort(tracks, function(a, b)
    return a.index < b.index
  end)

  return tracks
end

-- Draw a single track tile
local function draw_track_tile(ctx, draw_list, x, y, width, track_data, is_selected, alpha)
  local height = TRACK_TILE.HEIGHT
  local rounding = TRACK_TILE.ROUNDING

  -- Background
  local bg_alpha = is_selected and 0xCC or 0x44
  bg_alpha = math.floor(bg_alpha * alpha)
  local bg_color = Colors.hexrgb("#2A2A2A")
  bg_color = Colors.with_alpha(bg_color, bg_alpha)

  ImGui.DrawList_AddRectFilled(draw_list, x, y, x + width, y + height, bg_color, rounding)

  -- Color bar on the left
  local bar_color = track_data.display_color
  if not is_selected then
    bar_color = Colors.with_alpha(bar_color, math.floor(0x88 * alpha))
  else
    bar_color = Colors.with_alpha(bar_color, math.floor(0xFF * alpha))
  end

  ImGui.DrawList_AddRectFilled(draw_list,
    x, y,
    x + TRACK_TILE.COLOR_BAR_WIDTH, y + height,
    bar_color, rounding, ImGui.DrawFlags_RoundCornersLeft)

  -- Track name
  local text_x = x + TRACK_TILE.COLOR_BAR_WIDTH + TRACK_TILE.PADDING_X
  local text_y = y + (height - ImGui.GetTextLineHeight(ctx)) / 2

  local text_alpha = is_selected and 0xFF or 0x88
  text_alpha = math.floor(text_alpha * alpha)
  local text_color = Colors.hexrgb("#FFFFFF")
  text_color = Colors.with_alpha(text_color, text_alpha)

  ImGui.DrawList_AddText(draw_list, text_x, text_y, text_color, track_data.name)

  -- Selection indicator (checkmark or filled circle)
  if is_selected then
    local indicator_size = 6
    local indicator_x = x + width - TRACK_TILE.PADDING_X - indicator_size
    local indicator_y = y + (height - indicator_size) / 2
    local indicator_color = Colors.with_alpha(Colors.hexrgb("#42E896"), math.floor(0xFF * alpha))

    ImGui.DrawList_AddCircleFilled(draw_list,
      indicator_x + indicator_size/2, indicator_y + indicator_size/2,
      indicator_size/2, indicator_color)
  end

  return height
end

-- Draw the track filter popup
function M.draw_popup(ctx, draw_list, x, y, width, height, state, config, alpha)
  alpha = alpha or 1.0

  -- Collect tracks if not cached
  if not state.track_filter_tracks then
    state.track_filter_tracks = M.collect_tracks(state)
  end

  -- Initialize whitelist if not present (all selected by default)
  if not state.track_whitelist then
    state.track_whitelist = {}
    for _, track in ipairs(state.track_filter_tracks) do
      state.track_whitelist[track.guid] = true
    end
  end

  local tracks = state.track_filter_tracks
  local padding = 8

  -- Background panel
  local bg_color = Colors.hexrgb("#1A1A1A")
  bg_color = Colors.with_alpha(bg_color, math.floor(0xF0 * alpha))
  ImGui.DrawList_AddRectFilled(draw_list, x, y, x + width, y + height, bg_color, 6)

  -- Border
  local border_color = Colors.hexrgb("#333333")
  border_color = Colors.with_alpha(border_color, math.floor(0xFF * alpha))
  ImGui.DrawList_AddRect(draw_list, x, y, x + width, y + height, border_color, 6)

  -- Header
  local header_y = y + padding
  local header_color = Colors.hexrgb("#AAAAAA")
  header_color = Colors.with_alpha(header_color, math.floor(0xFF * alpha))
  ImGui.DrawList_AddText(draw_list, x + padding, header_y, header_color, "TRACK FILTER")

  -- Track count
  local selected_count = 0
  for _, track in ipairs(tracks) do
    if state.track_whitelist[track.guid] then
      selected_count = selected_count + 1
    end
  end

  local count_text = string.format("%d / %d", selected_count, #tracks)
  local count_w = ImGui.CalcTextSize(ctx, count_text)
  local count_color = Colors.hexrgb("#666666")
  count_color = Colors.with_alpha(count_color, math.floor(0xFF * alpha))
  ImGui.DrawList_AddText(draw_list, x + width - padding - count_w, header_y, count_color, count_text)

  -- Separator
  local sep_y = header_y + ImGui.GetTextLineHeight(ctx) + padding
  local sep_color = Colors.hexrgb("#333333")
  sep_color = Colors.with_alpha(sep_color, math.floor(0xFF * alpha))
  ImGui.DrawList_AddLine(draw_list, x + padding, sep_y, x + width - padding, sep_y, sep_color)

  -- Track list
  local list_y = sep_y + padding
  local list_width = width - padding * 2
  local mouse_x, mouse_y = ImGui.GetMousePos(ctx)
  local mouse_clicked = ImGui.IsMouseClicked(ctx, ImGui.MouseButton_Left)

  for i, track in ipairs(tracks) do
    local tile_y = list_y + (i - 1) * (TRACK_TILE.HEIGHT + TRACK_TILE.MARGIN_Y)
    local tile_x = x + padding
    local is_selected = state.track_whitelist[track.guid] == true

    -- Check hover
    local is_hovered = mouse_x >= tile_x and mouse_x <= tile_x + list_width and
                       mouse_y >= tile_y and mouse_y <= tile_y + TRACK_TILE.HEIGHT

    -- Handle click
    if is_hovered and mouse_clicked then
      state.track_whitelist[track.guid] = not is_selected
    end

    -- Adjust alpha for hover
    local tile_alpha = alpha
    if is_hovered then
      tile_alpha = math.min(1.0, alpha * 1.3)
    end

    draw_track_tile(ctx, draw_list, tile_x, tile_y, list_width, track, is_selected, tile_alpha)
  end

  -- "All" / "None" buttons at bottom
  local btn_y = y + height - padding - TRACK_TILE.HEIGHT
  local btn_width = (list_width - padding) / 2

  -- Check if mouse is in "All" button area
  local all_btn_x = x + padding
  local all_hovered = mouse_x >= all_btn_x and mouse_x <= all_btn_x + btn_width and
                      mouse_y >= btn_y and mouse_y <= btn_y + TRACK_TILE.HEIGHT

  if all_hovered and mouse_clicked then
    for _, track in ipairs(tracks) do
      state.track_whitelist[track.guid] = true
    end
  end

  -- Draw "All" button
  local all_bg = all_hovered and Colors.hexrgb("#3A3A3A") or Colors.hexrgb("#2A2A2A")
  all_bg = Colors.with_alpha(all_bg, math.floor(0xCC * alpha))
  ImGui.DrawList_AddRectFilled(draw_list, all_btn_x, btn_y, all_btn_x + btn_width, btn_y + TRACK_TILE.HEIGHT, all_bg, 4)
  local all_text_w = ImGui.CalcTextSize(ctx, "All")
  ImGui.DrawList_AddText(draw_list,
    all_btn_x + (btn_width - all_text_w) / 2,
    btn_y + (TRACK_TILE.HEIGHT - ImGui.GetTextLineHeight(ctx)) / 2,
    Colors.with_alpha(Colors.hexrgb("#FFFFFF"), math.floor(0xCC * alpha)), "All")

  -- Check if mouse is in "None" button area
  local none_btn_x = x + padding + btn_width + padding
  local none_hovered = mouse_x >= none_btn_x and mouse_x <= none_btn_x + btn_width and
                       mouse_y >= btn_y and mouse_y <= btn_y + TRACK_TILE.HEIGHT

  if none_hovered and mouse_clicked then
    for _, track in ipairs(tracks) do
      state.track_whitelist[track.guid] = false
    end
  end

  -- Draw "None" button
  local none_bg = none_hovered and Colors.hexrgb("#3A3A3A") or Colors.hexrgb("#2A2A2A")
  none_bg = Colors.with_alpha(none_bg, math.floor(0xCC * alpha))
  ImGui.DrawList_AddRectFilled(draw_list, none_btn_x, btn_y, none_btn_x + btn_width, btn_y + TRACK_TILE.HEIGHT, none_bg, 4)
  local none_text_w = ImGui.CalcTextSize(ctx, "None")
  ImGui.DrawList_AddText(draw_list,
    none_btn_x + (btn_width - none_text_w) / 2,
    btn_y + (TRACK_TILE.HEIGHT - ImGui.GetTextLineHeight(ctx)) / 2,
    Colors.with_alpha(Colors.hexrgb("#FFFFFF"), math.floor(0xCC * alpha)), "None")
end

-- Calculate required popup height based on track count
function M.get_popup_height(state)
  if not state.track_filter_tracks then
    state.track_filter_tracks = M.collect_tracks(state)
  end

  local track_count = #state.track_filter_tracks
  local header_height = 40  -- Header + separator
  local footer_height = 40  -- All/None buttons + padding
  local list_height = track_count * (TRACK_TILE.HEIGHT + TRACK_TILE.MARGIN_Y)

  return header_height + list_height + footer_height
end

return M
