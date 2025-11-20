-- @noindex
-- @description ARKITEKT Demo
-- @author ARKADATA
-- @version 1.0.0
-- @about
--   Interactive demo showcasing ARKITEKT framework features.
--   Learn how to build professional REAPER interfaces with primitives,
--   widgets, grid systems, and more.
--
--   Perfect for getting started with ARKITEKT development!

-- ============================================================================
-- BOOTSTRAP ARKITEKT FRAMEWORK
-- ============================================================================
--
-- WHY THIS PATTERN:
-- Every ARKITEKT app starts by locating and loading the bootstrap module.
-- This scans upward from the script's directory to find rearkitekt/app/init/
-- and initializes the framework with all necessary paths and utilities.
--
-- The ARK context provides:
-- - ImGui: Pre-loaded ImGui module
-- - Constants: Framework constants (colors, fonts, etc.)
-- - dirname(): Path utilities
-- - And more utilities defined in bootstrap.lua

local ARK
do
  local sep = package.config:sub(1,1)
  local src = debug.getinfo(1, "S").source:sub(2)
  local path = src:match("(.*"..sep..")")

  -- Scan upward for rearkitekt/app/init/init.lua
  while path and #path > 3 do
    local init = path .. "rearkitekt" .. sep .. "app" .. sep .. "init" .. sep .. "init.lua"
    local f = io.open(init, "r")
    if f then
      f:close()
      local Init = dofile(init)
      ARK = Init.bootstrap()
      break
    end
    path = path:match("(.*"..sep..")[^"..sep.."]-"..sep.."$")
  end

  if not ARK then
    reaper.MB("ARKITEKT framework not found!\n\nMake sure this script is in the ARKITEKT folder.", "Demo Error", 0)
    return
  end
end

-- ============================================================================
-- LOAD DEPENDENCIES
-- ============================================================================
--
-- WHY REQUIRE AFTER BOOTSTRAP:
-- The bootstrap sets up package.path to include rearkitekt modules.
-- Now we can require both framework modules and our demo modules.

local ImGui = ARK.ImGui

-- Framework modules
local Shell = require("rearkitekt.app.runtime.shell")

-- Load ARKITEKT style (provides default ImGui styling)
local style_ok, Style = pcall(require, "rearkitekt.gui.style.imgui_defaults")

-- Demo modules
local State = require("Demo.core.state")
local WelcomeView = require("Demo.ui.welcome_view")
local PrimitivesView = require("Demo.ui.primitives_view")
local GridView = require("Demo.ui.grid_view")

-- ============================================================================
-- INITIALIZE APPLICATION STATE
-- ============================================================================
--
-- WHY SEPARATE STATE INITIALIZATION:
-- Keeping state separate from UI makes the code more maintainable.
-- State holds all runtime data, UI just renders it.

local state = State.initialize()

-- ============================================================================
-- MAIN DRAW FUNCTION
-- ============================================================================
--
-- WHY THIS PATTERN:
-- The draw function is called every frame by the Shell.
-- We receive the ImGui context and shell_state (which includes window).
-- We use window:get_active_tab() to know which tab is active.
-- The Shell handles window management, styling, fonts - we just draw content.
--
-- @param ctx ImGui context
-- @param shell_state table Shell state (window, fonts, style, etc.)

local function draw(ctx, shell_state)
  -- Get active tab from menutabs system
  local active_tab = shell_state.window:get_active_tab()

  -- Render the appropriate view based on active tab
  if active_tab == "WELCOME" then
    WelcomeView.render(ctx, state)
  elseif active_tab == "PRIMITIVES" then
    PrimitivesView.render(ctx, state)
  elseif active_tab == "GRID" then
    GridView.render(ctx, state)
  end
end

-- ============================================================================
-- RUN APPLICATION
-- ============================================================================
--
-- WHY Shell.run:
-- Shell.run() is ARKITEKT's application runner. It:
-- - Creates and manages the ImGui window
-- - Handles the defer loop for continuous rendering
-- - Manages fonts and styling (via style parameter)
-- - Provides window chrome (titlebar, etc.)
-- - Handles visibility toggling (run script again to hide)
--
-- Configuration options:
-- - title: Window title in REAPER
-- - initial_size: Initial window size {w, h}
-- - draw: Your draw function called every frame (NOT render!)
-- - style: Style module for ImGui colors/styling (CRITICAL!)
-- - fonts: Custom font configuration (optional)

Shell.run({
  title = "ARKITEKT Demo",
  version = "1.0.0",

  -- Initial window size
  initial_size = { w = 950, h = 700 },
  min_size = { w = 700, h = 500 },

  -- Menutabs configuration (Shell-level tabs)
  tabs = {
    items = {
      { id = "WELCOME", label = "👋 Welcome" },
      { id = "PRIMITIVES", label = "🔘 Primitives" },
      { id = "GRID", label = "📦 Grid System" },
    },
    active = "WELCOME",  -- Initial active tab
  },

  -- Main draw function (receives ctx and shell_state)
  draw = draw,

  -- CRITICAL: Pass the style to get ARKITEKT colors/styling
  style = style_ok and Style or nil,

  -- Content padding around the main content area
  content_padding = 16,
})

-- ============================================================================
-- NOTES FOR DEVELOPERS
-- ============================================================================
--[[

WHAT YOU CAN LEARN FROM THIS DEMO:

1. **Bootstrap Pattern**
   Every ARKITEKT app uses the same bootstrap pattern to locate and
   initialize the framework. Copy this pattern for your own apps.

2. **Menutabs System**
   This demo uses Shell-level menutabs for navigation between sections.
   See Shell.run({ tabs = {...} }) configuration above.
   Access active tab via shell_state.window:get_active_tab().

3. **State Management**
   See Demo/core/state.lua for how to structure application state.
   Keep state separate from UI for maintainability.

4. **Modular Views**
   See Demo/ui/ for how to split UI into logical view modules.
   Each view is self-contained and receives state as a parameter.
   Views are switched based on active tab in the draw function.

5. **Primitives**
   See Demo/ui/primitives_view.lua for button, checkbox, text,
   drawing, and color utilities examples.

6. **Grid System**
   See Demo/ui/grid_view.lua for responsive grid layout with
   selection and interaction examples.

NEXT STEPS:

- Explore the code in Demo/ folder
- Read the inline documentation and tooltips
- Experiment by modifying the demo
- Use these patterns in your own REAPER scripts

For more information about ARKITEKT:
- Study the rearkitekt/ library modules
- Check scripts/ folder for real-world examples
- Read Widget documentation in source files

]]
