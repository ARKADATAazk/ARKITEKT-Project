-- @noindex
-- Demo/ui/tooltips.lua
--
-- WHY THIS EXISTS: Centralized tooltip and help text for all ARKITEKT Demo controls.
-- This keeps the UI code clean and makes it easy to update help text.
--
-- PATTERN:
-- - Organize tooltips by view/section
-- - Use descriptive multi-line text for better learning
-- - Provide a format() helper for dynamic tooltips

local M = {}

-- ============================================================================
-- GENERAL NAVIGATION
-- ============================================================================

M.NAVIGATION = {
  welcome_tab = "Overview of the ARKITEKT framework and what you can learn from this demo\n\nStart here if you're new to ARKITEKT!",
  primitives_tab = "Learn the basic building blocks:\n• Buttons with states and callbacks\n• Checkboxes and toggles\n• Text rendering and formatting\n• Drawing primitives (rectangles, circles, lines)\n• Color utilities and transformations",
  grid_tab = "Explore the powerful grid system:\n• Responsive column layout\n• Multi-selection support\n• Custom tile rendering\n• Grid interactions and behaviors",
}

-- ============================================================================
-- PRIMITIVES VIEW
-- ============================================================================

M.PRIMITIVES = {
  -- Buttons
  button_basic = "Interactive button with click detection\n\nFeatures:\n• Hover and active states\n• Tooltips\n• Custom colors and styling\n• Click callbacks\n\nTry clicking to increment the counter!",

  button_colored = "Buttons can use custom colors for different purposes:\n• Success (green) - confirmations, positive actions\n• Warning (orange) - caution, important actions\n• Danger (red) - destructive actions\n\nCustomize bg_color, bg_hover_color, and text_color",

  -- Checkboxes
  checkbox_basic = "Toggle widget for binary states\n\nFeatures:\n• Checked/unchecked states\n• Smooth animations\n• Custom styling\n• Change callbacks\n\nClick to toggle the state!",

  -- Text
  text_colored = "Text can use different colors for semantic meaning:\n• Red - errors, warnings\n• Green - success, confirmations\n• Blue - information, links\n• Purple - highlights, special content\n• Gray - secondary, muted text",

  text_wrapped = "TextWrapped automatically breaks long text to fit the available width\n\nUse PushTextWrapPos() to control the wrap width",

  -- Drawing
  drawing_primitives = "Low-level drawing functions for custom graphics\n\nAvailable shapes:\n• Rectangles (filled and outlined)\n• Circles and ellipses\n• Lines and polylines\n• Bezier curves\n• Custom paths\n\nAll shapes support corner rounding and anti-aliasing",

  -- Colors
  color_utilities = "ARKITEKT's color module provides powerful transformations:\n\n• hexrgb() - Convert hex strings to ImGui colors\n• adjust_brightness() - Make colors lighter or darker\n• saturate()/desaturate() - Adjust color intensity\n• with_alpha() - Change transparency\n• lerp() - Blend between two colors\n\nColors are in RGBA format (0xRRGGBBAA)",
}

-- ============================================================================
-- GRID VIEW
-- ============================================================================

M.GRID = {
  simple_grid = "Basic responsive grid layout\n\nFeatures:\n• Automatically adjusts column count based on width\n• Click to select/deselect tiles\n• Visual feedback for hover and selection\n• Efficient rendering for many items\n\nThis is a simplified demo grid. Production apps use\nthe full Grid widget with drag & drop, animations,\nvirtualization, and more.",

  clear_selection = "Clear all selected items in the grid\n\nIn production grids, you can also:\n• Multi-select with Ctrl+Click\n• Range select with Shift+Click\n• Marquee select by dragging\n• Select all with Ctrl+A",

  production_grid = "The full Grid widget (rearkitekt.gui.widgets.containers.grid)\nprovides advanced features:\n\n• Factory pattern for creating custom grids\n• Custom tile renderers with complex visuals\n• Drag & drop reordering\n• Selection rectangle across entire container\n• Spawn/destroy animations with TileFX\n• Virtualization for large datasets\n• Marching ants selection borders\n• Context menus and double-click actions\n\nSee Region_Playlist and ThemeAdjuster for real examples!",

  grid_features = "Production Grid features:\n\n📐 Responsive Layout - Auto-adjusts columns\n🎯 Multi-Selection - Click, Ctrl+Click, marquee\n🎨 Custom Rendering - Full drawing control\n✨ Animations - Smooth transitions\n🖱️ Drag & Drop - Visual drop indicators\n📦 Virtualization - Efficient large datasets\n⚡ Performance - 60fps with hundreds of items\n🎮 Interactions - Hover, click, context menus",
}

-- ============================================================================
-- CODE EXAMPLES
-- ============================================================================

M.CODE = {
  button_example = "This code shows the basic Button.draw_at_cursor() pattern:\n\n1. Require the button module\n2. Call draw_at_cursor() with config and unique ID\n3. Check if button was clicked\n4. Execute action on click\n\nThe button automatically handles:\n• Position (cursor)\n• Sizing (auto-width from label, or custom)\n• Visual states (normal, hover, active)\n• Tooltips",

  checkbox_example = "Checkbox pattern:\n\n1. Require the checkbox module\n2. Call draw_at_cursor() with current state\n3. Check if changed and get new value\n4. Update your state variable\n\nThe checkbox automatically handles:\n• Visual states\n• Toggle animations\n• Label positioning",

  text_example = "Text rendering patterns:\n\n• Text() - Simple text\n• TextColored() - With custom color\n• TextWrapped() - Auto-wrapping\n• PushTextWrapPos() - Control wrap width\n\nColors use the hexrgb() function to convert\nhex strings like '#3B82F6' to ImGui RGBA format.",

  drawing_example = "Drawing primitives use the DrawList API:\n\n1. Get draw list: ImGui.GetWindowDrawList(ctx)\n2. Call DrawList_Add* functions with coordinates\n3. Use hexrgb() for colors\n4. Specify rounding, thickness, etc.\n\nDrawing happens in screen coordinates.\nUse GetCursorScreenPos() to get current position.",

  color_example = "Color utility examples:\n\n• hexrgb() converts '#3B82F6' to 0x3B82F6FF\n• adjust_brightness() multiplies RGB values\n• saturate()/desaturate() adjusts in HSV space\n• with_alpha() replaces alpha channel\n• lerp() linearly interpolates RGB values\n\nAll functions work with ImGui RGBA format (0xRRGGBBAA)",

  grid_example = "Production grid pattern:\n\n1. Create factory with custom tile renderer\n2. Create Grid instance with factory\n3. Configure selection, drag & drop, animations\n4. Call grid:render() in your draw loop\n\nThe Grid handles all interaction logic:\n• Click detection\n• Selection state\n• Drag & drop\n• Layout calculations\n• Scroll virtualization",
}

-- ============================================================================
-- HELPER FUNCTION
-- ============================================================================

--- Format tooltip with string.format support
-- @param tooltip string Base tooltip text
-- @param ... any Format arguments
-- @return string Formatted tooltip
function M.format(tooltip, ...)
  if select('#', ...) > 0 then
    return string.format(tooltip, ...)
  end
  return tooltip
end

return M
