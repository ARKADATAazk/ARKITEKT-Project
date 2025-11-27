# Demo Development Guide

> A comprehensive guide to creating modular, maintainable demonstration scripts for ARKITEKT widgets and features.

## Table of Contents

1. [Philosophy](#philosophy)
2. [Architecture](#architecture)
3. [Demo Hub Pattern](#demo-hub-pattern)
4. [Demo Structure](#demo-structure)
5. [Feature vs Context Pattern](#feature-vs-context-pattern)
6. [Best Practices](#best-practices)
7. [Code Visibility](#code-visibility)
8. [Size Guidelines](#size-guidelines)
9. [Anti-Patterns](#anti-patterns)

---

## Philosophy

### Why Modular Demos?

**Problem with monolithic demos:**
- 8000+ line files are overwhelming and hard to navigate
- Can't test individual widgets in isolation
- Difficult to maintain (one file touches everything)
- Performance impact from loading everything at once
- Hard for users to find relevant examples

**Solution: Modular demo architecture**
- One demo per widget or feature
- Central hub for discovery and navigation
- Isolated examples that are easy to understand
- Better performance (load only what you need)
- Easier maintenance and community contributions

### Goals

| Goal | Description |
|------|-------------|
| **Discoverability** | Users can quickly find examples for the widget they need |
| **Learnability** | Code is small enough to read and understand completely |
| **Inspectability** | Users can see both the result and the code that made it |
| **Inspiration** | Show both how widgets work and what can be built |
| **Maintainability** | Updates to one widget only affect one demo file |

---

## Architecture

### Directory Structure

```
scripts/Demos/
├── ARK_DemoHub.lua              # Main launcher (gallery of all demos)
├── app/
│   ├── state.lua                # Hub state (favorites, recent, etc.)
│   └── launcher.lua             # Demo launching logic
├── ui/
│   ├── gallery.lua              # Gallery grid view
│   └── search.lua               # Search and filter
├── demos/
│   ├── primitives/
│   │   ├── button_demo.lua      # Button: states, icons, animations
│   │   ├── slider_demo.lua      # Slider: ranges, formats, styling
│   │   ├── checkbox_demo.lua    # Checkbox: states, groups
│   │   └── combo_demo.lua       # Combo: options, search
│   ├── containers/
│   │   ├── panel_demo.lua       # Panel: collapsing, tabs, headers
│   │   ├── grid_demo.lua        # Grid: drag, constraints, wrapping
│   │   └── sliding_zone_demo.lua # SlidingZone: resizable panels
│   ├── canvas/
│   │   ├── nodal_demo.lua       # Primary: nodal editor
│   │   └── contexts_demo.lua    # Alternative uses (drawing, graphs)
│   ├── complex/
│   │   ├── theme_demo.lua       # Live theme switching
│   │   └── animation_demo.lua   # Easing functions, timing
│   └── integration/
│       ├── reaper_items_demo.lua # Integration with REAPER items
│       └── midi_editor_demo.lua  # MIDI editor integration
├── shared/
│   ├── demo_utils.lua           # Shared utilities
│   ├── code_display.lua         # Source code viewer
│   └── playground.lua           # Live parameter editing
└── defs/
    └── manifest.lua             # Demo registry/metadata
```

### Demo Manifest

```lua
-- defs/manifest.lua
-- Central registry of all demos

return {
  categories = {
    {
      name = "Primitives",
      description = "Atomic UI elements",
      demos = {
        {
          name = "Button",
          script = "demos/primitives/button_demo.lua",
          difficulty = "beginner",
          tags = {"input", "click", "icon"},
          description = "Interactive buttons with icons, states, and animations",
        },
        {
          name = "Slider",
          script = "demos/primitives/slider_demo.lua",
          difficulty = "beginner",
          tags = {"input", "numeric"},
          description = "Sliders for numeric input with custom formatting",
        },
      },
    },
    {
      name = "Canvas",
      description = "Drawing and nodal systems",
      demos = {
        {
          name = "Nodal Editor",
          script = "demos/canvas/nodal_demo.lua",
          difficulty = "advanced",
          tags = {"canvas", "nodes", "connections"},
          description = "Complete nodal editor with drag, zoom, and connections",
        },
        {
          name = "Canvas Contexts",
          script = "demos/canvas/contexts_demo.lua",
          difficulty = "intermediate",
          tags = {"canvas", "drawing", "creative"},
          description = "Alternative uses: drawing tools, graphs, visualizations",
        },
      },
    },
  },
}
```

---

## Demo Hub Pattern

### Hub Entry Point

```lua
-- ARK_DemoHub.lua
-- Main entry point: Gallery of all available demos

local ARK = (function()
  local sep = package.config:sub(1,1)
  local src = debug.getinfo(1, "S").source:sub(2)
  local path = src:match("(.*"..sep..")")
  while path and #path > 3 do
    local init = path .. "arkitekt" .. sep .. "app" .. sep .. "init" .. sep .. "init.lua"
    local f = io.open(init, "r")
    if f then
      f:close()
      return dofile(init).bootstrap()
    end
    path = path:match("(.*"..sep..")[^"..sep.."]-"..sep.."$")
  end
  error("ARKITEKT framework not found!")
end)()

local Shell = require('arkitekt.app.runtime.shell')
local Gallery = require('Demos.ui.gallery')
local Search = require('Demos.ui.search')
local Manifest = require('Demos.defs.manifest')

local state = {
  search_query = "",
  selected_category = nil,
  favorites = {},
  recent = {},
}

local function draw_main_ui(ctx)
  -- Search bar at top
  Search.draw(ctx, {
    value = state.search_query,
    on_change = function(query)
      state.search_query = query
    end,
  })

  -- Category tabs
  for _, category in ipairs(Manifest.categories) do
    -- Tab rendering...
  end

  -- Gallery grid of demo cards
  Gallery.draw(ctx, {
    demos = get_filtered_demos(),
    on_launch = function(demo)
      launch_demo(demo)
    end,
  })
end

Shell.run({
  app_name = "ARKITEKT Demo Hub",
  app_version = "1.0.0",
  window_width = 1200,
  window_height = 800,
  draw_main = draw_main_ui,
})
```

### Gallery Card Design

```lua
-- ui/gallery.lua
-- Grid of cards showing each demo

local ark = require('arkitekt.init')

local M = {}

function M.draw(ctx, opts)
  local demos = opts.demos or {}
  local on_launch = opts.on_launch or function() end

  local card_width = 280
  local card_height = 180
  local spacing = 16

  -- Calculate grid layout
  local avail_w = ark.ImGui.GetContentRegionAvail(ctx)
  local cols = math.floor(avail_w / (card_width + spacing))

  for i, demo in ipairs(demos) do
    -- Card background
    local result = ark.Panel.draw(ctx, {
      width = card_width,
      height = card_height,
      bg_color = ark.Theme.COLORS.BG_RAISED,
    })

    -- Demo icon/thumbnail (if available)
    -- Demo title
    -- Demo description
    -- Difficulty badge
    -- Tags

    -- Launch button
    if ark.Button.draw(ctx, {
      label = "Launch",
      width = card_width - 16,
    }).clicked then
      on_launch(demo)
    end

    -- Grid wrapping
    if i % cols ~= 0 then
      ark.ImGui.SameLine(ctx)
    end
  end
end

return M
```

---

## Demo Structure

### Standard Demo Template

```lua
-- @noindex
-- demos/primitives/button_demo.lua
-- Demonstrates Button widget: states, icons, animations, events

local ARK = (function()
  -- Bootstrap (same as hub)
end)()

local Shell = require('arkitekt.app.runtime.shell')
local ark = require('arkitekt.init')

-- ============================================================================
-- STATE
-- ============================================================================

local state = {
  click_count = 0,
  toggle_state = false,
  disabled = false,

  -- Playground parameters
  label = "Click Me",
  width = 120,
  icon = "",
  show_code = false,
}

-- ============================================================================
-- CODE DISPLAY
-- ============================================================================

local function get_example_code()
  return [[
-- Basic button
local result = ark.Button.draw(ctx, {
  label = "Click Me",
  width = 120,
})

if result.clicked then
  reaper.ShowConsoleMsg("Button clicked!\n")
end

-- Button with icon
ark.Button.draw(ctx, {
  label = "Save",
  icon = "",
  width = 100,
})

-- Toggle button
local toggled = ark.Button.draw(ctx, {
  label = "Toggle",
  is_toggled = state.toggled,
}).clicked

if toggled then
  state.toggled = not state.toggled
end
]]
end

-- ============================================================================
-- MAIN UI
-- ============================================================================

local function draw_main_ui(ctx)
  local ImGui = ark.ImGui

  -- Header
  ImGui.Text(ctx, "Button Widget Demo")
  ImGui.Separator(ctx)
  ImGui.Spacing(ctx)

  -- Toggle code visibility
  if ark.Button.draw(ctx, {
    label = state.show_code and "Hide Code" or "Show Code",
    width = 120,
  }).clicked then
    state.show_code = not state.show_code
  end

  ImGui.Spacing(ctx)

  -- Two-column layout: Examples | Code
  if state.show_code then
    ImGui.BeginChild(ctx, "examples", 0, 0, ImGui.ChildFlags_Border)
  end

  -- ========================================================================
  -- EXAMPLES
  -- ========================================================================

  ImGui.Text(ctx, "Basic Button")
  if ark.Button.draw(ctx, {
    label = "Click Me",
    width = 120,
  }).clicked then
    state.click_count = state.click_count + 1
  end
  ImGui.Text(ctx, string.format("Clicks: %d", state.click_count))

  ImGui.Spacing(ctx)
  ImGui.Separator(ctx)
  ImGui.Spacing(ctx)

  ImGui.Text(ctx, "Button with Icon")
  ark.Button.draw(ctx, {
    label = "Save",
    icon = "",
    width = 100,
  })

  ImGui.Spacing(ctx)
  ImGui.Separator(ctx)
  ImGui.Spacing(ctx)

  ImGui.Text(ctx, "Toggle Button")
  if ark.Button.draw(ctx, {
    label = "Toggle",
    is_toggled = state.toggle_state,
    width = 100,
  }).clicked then
    state.toggle_state = not state.toggle_state
  end
  ImGui.Text(ctx, string.format("State: %s", state.toggle_state and "ON" or "OFF"))

  ImGui.Spacing(ctx)
  ImGui.Separator(ctx)
  ImGui.Spacing(ctx)

  ImGui.Text(ctx, "Disabled Button")
  ark.Checkbox.draw(ctx, {
    label = "Disable",
    checked = state.disabled,
    on_change = function(checked)
      state.disabled = checked
    end,
  })
  ark.Button.draw(ctx, {
    label = "Disabled",
    width = 100,
    disabled = state.disabled,
  })

  if state.show_code then
    ImGui.EndChild(ctx)
    ImGui.SameLine(ctx)

    -- Code panel
    ImGui.BeginChild(ctx, "code", 0, 0, ImGui.ChildFlags_Border)
    ImGui.Text(ctx, "Example Code:")
    ImGui.Separator(ctx)
    ImGui.TextWrapped(ctx, get_example_code())

    if ark.Button.draw(ctx, {
      label = "Copy to Clipboard",
    }).clicked then
      ark.ImGui.SetClipboardText(ctx, get_example_code())
    end

    ImGui.EndChild(ctx)
  end
end

-- ============================================================================
-- RUN
-- ============================================================================

Shell.run({
  app_name = "Button Demo",
  app_version = "1.0.0",
  window_width = state.show_code and 1200 or 600,
  window_height = 700,
  draw_main = draw_main_ui,
})
```

### Demo File Anatomy

Every demo should include:

1. **Header comment** - What the demo shows
2. **Bootstrap** - Standard ARKITEKT initialization
3. **State** - Demo-specific state (counters, toggles, etc.)
4. **Code display** - Source code string for "Show Code" feature
5. **Examples section** - Multiple examples showing different uses
6. **Interactive elements** - Let user tweak parameters
7. **Shell.run** - Standard window setup

---

## Feature vs Context Pattern

### Use Case: Canvas Demo

For complex widgets with multiple use cases, provide **two modes**:

- **Features Mode**: "How does this widget work?" (API learning)
- **Contexts Mode**: "What can I build with this?" (inspiration)

```lua
-- demos/canvas/nodal_demo.lua (or canvas_demo.lua with mode toggle)

local state = {
  mode = "features",  -- or "contexts"
}

local function draw_main_ui(ctx)
  -- Mode toggle at top
  if ark.Button.draw(ctx, {
    label = state.mode == "features" and "→ Contexts" or "→ Features",
  }).clicked then
    state.mode = state.mode == "features" and "contexts" or "features"
  end

  if state.mode == "features" then
    draw_features_mode(ctx)
  else
    draw_contexts_mode(ctx)
  end
end

-- ============================================================================
-- FEATURES MODE: Show individual Canvas capabilities
-- ============================================================================

local function draw_features_mode(ctx)
  ImGui.Text(ctx, "Canvas Features")

  -- Example 1: Basic drawing
  ImGui.Text(ctx, "1. Basic Drawing")
  -- Minimal example showing Canvas.draw()

  ImGui.Separator(ctx)

  -- Example 2: Zoom and pan
  ImGui.Text(ctx, "2. Zoom and Pan")
  -- Example with zoom controls

  ImGui.Separator(ctx)

  -- Example 3: Hit testing
  ImGui.Text(ctx, "3. Click Detection")
  -- Example showing click detection

  -- ... more isolated features
end

-- ============================================================================
-- CONTEXTS MODE: Show complete use cases
-- ============================================================================

local function draw_contexts_mode(ctx)
  -- Tabs for different contexts
  local contexts = {
    "Nodal Editor",
    "Drawing Tool",
    "Graph Visualization",
    "Audio Waveform",
    "Custom UI Layout",
  }

  for _, context in ipairs(contexts) do
    if ark.Button.draw(ctx, {label = context}).clicked then
      state.active_context = context
    end
  end

  ImGui.Separator(ctx)

  -- Render active context
  if state.active_context == "Nodal Editor" then
    draw_nodal_editor_example(ctx)
  elseif state.active_context == "Drawing Tool" then
    draw_drawing_tool_example(ctx)
  -- ... etc
  end
end

local function draw_nodal_editor_example(ctx)
  -- Complete mini nodal editor
  -- Shows nodes, connections, dragging, context menus
  -- This is a "real world" example, not just features
end
```

### When to Use Each Mode

| Mode | Use When | Example |
|------|----------|---------|
| **Features** | Widget has many capabilities | Canvas, Grid, Panel |
| **Contexts** | Widget has multiple use cases | Canvas (nodal vs drawing), Grid (media vs data) |
| **Single demo** | Widget is simple | Button, Checkbox, Slider |

---

## Best Practices

### 1. Progressive Disclosure

Start simple, add complexity gradually:

```lua
-- Example 1: Minimal (just label)
ark.Button.draw(ctx, {label = "Click"})

-- Example 2: Add width
ark.Button.draw(ctx, {label = "Click", width = 100})

-- Example 3: Add icon
ark.Button.draw(ctx, {label = "Save", icon = "", width = 100})

-- Example 4: Add state
ark.Button.draw(ctx, {
  label = "Toggle",
  is_toggled = state.toggled,
  width = 100,
})

-- Example 5: Full customization
ark.Button.draw(ctx, {
  label = "Custom",
  icon = "",
  width = 120,
  height = 40,
  bg_color = 0xFF4488FF,
  on_click = function() reaper.ShowConsoleMsg("Clicked!\n") end,
})
```

### 2. Interactive Playground

Let users tweak parameters live:

```lua
-- Playground section
ImGui.Text(ctx, "Playground: Customize the button")
ImGui.Separator(ctx)

state.label = ark.InputText.draw(ctx, {
  label = "Label",
  value = state.label,
}).value

state.width = ark.Slider.draw(ctx, {
  label = "Width",
  value = state.width,
  min = 50,
  max = 300,
}).value

state.icon = ark.InputText.draw(ctx, {
  label = "Icon",
  value = state.icon,
}).value

ImGui.Separator(ctx)
ImGui.Text(ctx, "Preview:")

-- Live preview with user parameters
ark.Button.draw(ctx, {
  label = state.label,
  width = state.width,
  icon = state.icon,
})
```

### 3. Copy-Paste Ready Code

Show the exact code needed:

```lua
-- In get_example_code():
local code = string.format([[
-- Your customized button
ark.Button.draw(ctx, {
  label = "%s",
  width = %d,
  icon = "%s",
})
]], state.label, state.width, state.icon)

-- Copy button
if ark.Button.draw(ctx, {label = "Copy Code"}).clicked then
  ark.ImGui.SetClipboardText(ctx, code)
end
```

### 4. Visual Feedback

Help users understand what's happening:

```lua
-- Show state changes visually
if result.clicked then
  state.last_click_time = reaper.time_precise()
  state.click_count = state.click_count + 1
end

ImGui.Text(ctx, string.format("Clicks: %d", state.click_count))

-- Flash effect for recent clicks
if reaper.time_precise() - state.last_click_time < 0.3 then
  ImGui.Text(ctx, "✓ Clicked!")
end
```

### 5. Difficulty Indicators

Mark examples by complexity:

```lua
ImGui.Text(ctx, "🟢 Beginner: Basic Button")
-- Simple example

ImGui.Text(ctx, "🟡 Intermediate: Stateful Toggle")
-- Example with state management

ImGui.Text(ctx, "🔴 Advanced: Custom Rendering")
-- Example with custom draw list operations
```

---

## Code Visibility

### Pattern 1: Toggle Panel

```lua
local state = { show_code = false }

if ark.Button.draw(ctx, {
  label = state.show_code and "Hide Code" or "Show Code"
}).clicked then
  state.show_code = not state.show_code
end

if state.show_code then
  ImGui.BeginChild(ctx, "code_panel", 400, 0, ImGui.ChildFlags_Border)
  ImGui.Text(ctx, get_example_code())
  ImGui.EndChild(ctx)
end
```

### Pattern 2: Split View

```lua
-- Left: Examples | Right: Code
local split_x = 600

ImGui.BeginChild(ctx, "examples", split_x, 0)
-- ... examples
ImGui.EndChild(ctx)

ImGui.SameLine(ctx)

ImGui.BeginChild(ctx, "code", 0, 0)
-- ... code display
ImGui.EndChild(ctx)
```

### Pattern 3: Tabs

```lua
local tabs = {"Examples", "Code", "Playground"}

for _, tab in ipairs(tabs) do
  if ark.Button.draw(ctx, {label = tab}).clicked then
    state.active_tab = tab
  end
end

if state.active_tab == "Examples" then
  draw_examples(ctx)
elseif state.active_tab == "Code" then
  draw_code(ctx)
elseif state.active_tab == "Playground" then
  draw_playground(ctx)
end
```

---

## Size Guidelines

### Recommended File Sizes

| Demo Type | Target Size | Max Size | Split If... |
|-----------|-------------|----------|-------------|
| **Simple widget** | 100-200 LOC | 300 LOC | >400 LOC |
| **Complex widget** | 300-500 LOC | 700 LOC | >1000 LOC |
| **Integration** | 500-800 LOC | 1200 LOC | >1500 LOC |
| **Hub/Launcher** | 200-400 LOC | 600 LOC | >800 LOC |

### When to Split

Split into multiple demos when:
- File exceeds max size
- Widget has distinct use cases (features vs contexts)
- Examples have very different complexity levels (beginner vs advanced)

```
# Instead of:
demos/canvas_mega_demo.lua  (2000 LOC)

# Do:
demos/canvas/features_demo.lua     (400 LOC)
demos/canvas/nodal_demo.lua        (600 LOC)
demos/canvas/drawing_demo.lua      (500 LOC)
demos/canvas/graphs_demo.lua       (400 LOC)
```

---

## Anti-Patterns

### ❌ Don't: Monolithic Demo

```lua
-- BAD: One massive file with everything
function draw_all_demos(ctx)
  draw_button_demo(ctx)
  draw_slider_demo(ctx)
  draw_checkbox_demo(ctx)
  draw_panel_demo(ctx)
  draw_grid_demo(ctx)
  draw_tree_demo(ctx)
  draw_canvas_demo(ctx)
  -- ... 50 more widgets
end
-- Result: 8000 line file nobody can navigate
```

### ❌ Don't: Example Without Context

```lua
-- BAD: No explanation of what's being shown
ark.Button.draw(ctx, {
  label = "X",
  width = 100,
  icon = "",
  bg_color = 0xFF4488FF,
  on_click = function() state.x = state.x + 1 end,
})
```

### ✅ Do: Explained Example

```lua
-- GOOD: Clear context and explanation
ImGui.Text(ctx, "Example: Button with icon and custom color")
ImGui.TextWrapped(ctx, "You can customize button colors and add icons")

if ark.Button.draw(ctx, {
  label = "Delete",
  icon = "",
  width = 100,
  bg_color = 0xFF4444FF,  -- Red background
}).clicked then
  state.items = {}  -- Clear items
end
```

### ❌ Don't: Assume Knowledge

```lua
-- BAD: Using advanced features without introduction
local result = ark.Canvas.draw(ctx, {
  transform = state.xform,
  viewport = state.vp,
  on_render = function(canvas_ctx)
    -- Complex rendering
  end,
})
```

### ✅ Do: Progressive Examples

```lua
-- GOOD: Start simple, build up
ImGui.Text(ctx, "Example 1: Basic Canvas")
ark.Canvas.draw(ctx, {
  width = 400,
  height = 300,
})

ImGui.Separator(ctx)

ImGui.Text(ctx, "Example 2: Canvas with Drawing")
ark.Canvas.draw(ctx, {
  width = 400,
  height = 300,
  on_render = function(canvas_ctx)
    -- Simple drawing
  end,
})

-- ... gradually add complexity
```

### ❌ Don't: Hide Implementation Details

```lua
-- BAD: Magic happens off-screen
local result = magic_function_that_does_everything()
```

### ✅ Do: Show the Code

```lua
-- GOOD: Show what's actually happening
local result = ark.Button.draw(ctx, {
  label = "Click Me",
  width = 120,
})

if result.clicked then
  state.count = state.count + 1
  reaper.ShowConsoleMsg("Clicked! Count: " .. state.count .. "\n")
end
```

---

## Maintenance

### Adding a New Demo

1. **Create demo file** in appropriate category folder
2. **Add to manifest** (`defs/manifest.lua`)
3. **Test independently** (run demo directly)
4. **Test from hub** (launch from gallery)
5. **Verify code display** (if showing source)
6. **Check on different screen sizes**

### Updating Existing Demo

1. **Update only the demo file** (isolated change)
2. **Don't break the API** (users might have copied code)
3. **Update manifest** if description/tags change
4. **Test before committing**

### Community Contributions

To make demos easy for community contributions:
- **Clear template** (standard demo structure)
- **Manifest is simple** (just add one entry)
- **No complex dependencies** (each demo is standalone)
- **Easy to test** (run demo file directly)

---

## Summary

### Key Principles

1. **One demo per widget/feature** - Keep files small and focused
2. **Hub for discovery** - Central launcher makes demos findable
3. **Show, don't tell** - Code + result is better than documentation
4. **Progressive examples** - Simple → intermediate → advanced
5. **Copy-paste ready** - Users can immediately use the code
6. **Features + Contexts** - Show how it works AND what it's for

### Quick Checklist

Before publishing a demo, verify:

- [ ] File is < 500 LOC (or split into multiple)
- [ ] Has header comment explaining purpose
- [ ] Starts with simple example
- [ ] Shows 3-5 different use cases
- [ ] Has "Show Code" toggle or split view
- [ ] Code is copy-paste ready
- [ ] Added to manifest with tags
- [ ] Tested standalone and from hub
- [ ] Window size is reasonable (not fullscreen by default)

---

## Next Steps

1. **Start with Demo Hub** - Build the launcher first
2. **Create 5-6 core demos** - Button, Slider, Panel, Grid, Canvas
3. **Get feedback** - See what users find helpful
4. **Expand gradually** - Don't try to cover everything at once
5. **Community** - Make it easy for others to contribute demos

---

*This guide will evolve as we build the demo system. Suggestions and improvements welcome!*
