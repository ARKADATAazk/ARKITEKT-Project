<!-- @noindex -->
# ARKITEKT Demo

Interactive demonstration of the ARKITEKT framework for building professional REAPER interfaces.

## Purpose

This demo serves two critical functions:

1. **Learning Resource**: Shows working examples of ARKITEKT features with code snippets
2. **Starter Template**: Provides a clean, well-documented codebase to copy from

## Structure

```
Demo/
├── core/
│   └── state.lua              # Application state management
├── ui/
│   ├── main_gui.lua           # Main UI orchestrator with panel/tabs
│   ├── welcome_view.lua       # Welcome screen and overview
│   ├── primitives_view.lua    # Primitives showcase (buttons, text, colors, etc.)
│   └── grid_view.lua          # Grid system showcase with tiles
└── README.md                  # This file
```

## Entry Point

```
ARKITEKT Demo.lua              # Main entry point (run this in REAPER)
```

## What Each File Demonstrates

### `ARKITEKT Demo.lua`
**Entry point showing:**
- Bootstrap pattern (how to initialize ARKITEKT)
- Shell.run() application setup
- Font configuration
- State initialization
- Main render loop

**Copy this file** as the starting point for any new ARKITEKT app.

---

### `core/state.lua`
**State management showing:**
- State initialization pattern
- Separating data from UI
- State manipulation functions
- Documentation best practices

**Key pattern:**
```lua
local M = {}

function M.initialize()
  return {
    -- Your app state here
  }
end

-- State manipulation functions
function M.toggle_item(state, item_id)
  -- Modify state
end

return M
```

---

### `ui/main_gui.lua`
**Main UI showing:**
- Panel widget usage
- Tab management
- View routing based on active tab
- Component composition

**Key pattern:**
```lua
-- Create panel with tabs
local panel = Panel.new({
  id = "my_panel",
  config = { /* ... */ }
})

-- Add tabs
panel:add_tab({ id = "tab1", label = "Tab 1" })
panel:add_tab({ id = "tab2", label = "Tab 2" })

-- In render:
panel:begin_panel(ctx, width, height)
  -- Render active view
  if panel.active_tab_id == "tab1" then
    render_tab1()
  end
panel:end_panel(ctx)
```

---

### `ui/welcome_view.lua`
**Welcome view showing:**
- Text formatting and wrapping
- Section layout patterns
- Color usage for hierarchy
- Card-style UI components

**Learning points:**
- How to structure informational views
- Text hierarchy with colors and sizing
- Background accents and visual separation

---

### `ui/primitives_view.lua`
**Primitives showcase demonstrating:**

#### Buttons
- Basic button with click handling
- Custom colors and styling
- Hover and active states
- Tooltips

#### Checkboxes
- Toggle state management
- Checkbox variants

#### Text & Typography
- Colored text
- Text wrapping
- Multiple fonts/sizes

#### Drawing Primitives
- Rectangles (filled and outlined)
- Circles
- Lines
- Custom shapes

#### Color Utilities
- Hex to RGBA conversion
- Brightness adjustment
- Saturation adjustment
- Alpha manipulation
- Color lerping

**This is the best starting point for learning ARKITEKT.**

---

### `ui/grid_view.lua`
**Grid system showing:**
- Responsive column calculation
- Tile rendering
- Selection state management
- Click interactions
- Custom tile content

**Key concepts:**
- Simplified grid for learning (production apps use full Grid widget)
- Layout calculation based on available width
- Tile state visualization (selected, hovered)
- Multi-selection patterns

**For production:** Use `rearkitekt.gui.widgets.containers.grid.core` which adds:
- Drag & drop
- Animations
- Marquee selection
- Virtualization
- And much more

---

## How to Use This Demo

### As a Learning Tool

1. **Run the demo**: Execute `ARKITEKT Demo.lua` in REAPER
2. **Navigate tabs**: Explore each showcase section
3. **Interact**: Click buttons, select tiles, experiment
4. **Read code**: Open the files and follow the comments
5. **Study patterns**: See how state, UI, and logic are separated

### As a Starter Template

1. **Copy the structure**: Use this folder layout for your app
2. **Copy entry point**: Use `ARKITEKT Demo.lua` as your base
3. **Modify state**: Change `core/state.lua` for your needs
4. **Create views**: Add new view files in `ui/`
5. **Update GUI**: Modify `ui/main_gui.lua` to route to your views

### Example: Creating a New App

```bash
# 1. Copy the Demo folder
cp -r Demo/ MyNewApp/

# 2. Copy the entry point
cp "ARKITEKT Demo.lua" "ARK_MyNewApp.lua"

# 3. Update the entry point
# Change: require("Demo.core.state")
# To:     require("MyNewApp.core.state")
# (and similar for other Demo requires)

# 4. Customize!
# Edit MyNewApp/core/state.lua for your data
# Edit MyNewApp/ui/main_gui.lua for your tabs
# Create new view files as needed
```

## Code Patterns to Learn

### 1. File Headers
Every file has a header explaining WHY it exists:
```lua
-- @noindex
-- path/to/file.lua
--
-- WHY THIS EXISTS: Clear explanation of purpose
--
-- More details...
```

### 2. Function Documentation
Public functions are documented:
```lua
--- Function description
-- @param ctx ImGui context
-- @param state table State object
-- @return boolean True if something happened
function M.do_something(ctx, state)
```

### 3. Section Organization
Large files use section headers:
```lua
-- ============================================================================
-- SECTION NAME
-- ============================================================================
```

### 4. State Management
State is passed, not global:
```lua
-- ❌ Don't do this:
local global_state = {}
function render()
  use(global_state)
end

-- ✅ Do this:
function render(ctx, state)
  use(state)
end
```

### 5. Modular UI
Each view is self-contained:
```lua
-- In your_view.lua
local M = {}

function M.render(ctx, state)
  -- Draw your UI
end

return M
```

### 6. Colors
Always use hexrgb for colors:
```lua
local Colors = require('rearkitekt.core.colors')
local hexrgb = Colors.hexrgb

local blue = hexrgb("#3B82F6")
local semi_transparent = hexrgb("#3B82F688")
```

## Performance Notes

### What This Demo Doesn't Show

This demo prioritizes **clarity over performance**. For production apps:

1. **Cache calculations**: Don't recalculate every frame
2. **Use full Grid widget**: Has optimizations this simple demo lacks
3. **Batch draw calls**: Group similar rendering operations
4. **Minimize state changes**: ImGui state changes have cost
5. **Profile your code**: Use the built-in Lua profiler

See `lua_perf_guide.md` in the project root for detailed performance tips.

## Next Steps

After exploring this demo:

1. **Read the other examples**: ColorPalette, Region_Playlist, ItemPicker
2. **Study the framework**: Look at rearkitekt/ source code
3. **Check documentation**: Read the docs in Documentation/
4. **Build something**: Start your own REAPER script!

## Common Questions

### Q: Can I use this code in my scripts?
**A:** Yes! This demo is part of ARKITEKT (GPL v3). You can use, modify, and build upon it. Just keep your modifications open source too.

### Q: Why is the grid demo simplified?
**A:** Educational clarity. The full Grid widget in `rearkitekt.gui.widgets.containers.grid.core` has 1000+ lines with animations, drag-drop, virtualization, etc. This simple version teaches the core concepts without overwhelming you.

### Q: Where's the advanced stuff?
**A:** Check out the real apps:
- `scripts/ColorPalette/` - Full app with grid, modals, persistence
- `scripts/Region_Playlist/` - Complex state machine, playback engine
- `scripts/ItemPicker/` - Media visualization, drag-drop

### Q: How do I add persistence (save settings)?
**A:** See ColorPalette for an example using `rearkitekt.core.settings`:
```lua
local Settings = require('rearkitekt.core.settings')
local settings = Settings.open(cache_dir, 'settings.json')

-- Read
local value = settings:get('my_key', default_value)

-- Write
settings:set('my_key', new_value)
settings:save()
```

### Q: How do I add keyboard shortcuts?
**A:** See Region_Playlist for an example:
```lua
if ImGui.IsKeyPressed(ctx, ImGui.Key_Space) then
  toggle_playback()
end

-- With modifiers
if ImGui.IsKeyPressed(ctx, ImGui.Key_S) and
   ImGui.IsKeyDown(ctx, ImGui.Mod_Ctrl) then
  save_project()
end
```

### Q: How do I handle modal dialogs?
**A:** See ItemPicker for overlay/modal examples using `rearkitekt.gui.widgets.overlays.overlay.manager`:
```lua
local OverlayManager = require('rearkitekt.gui.widgets.overlays.overlay.manager')
local overlay = OverlayManager.new()

overlay:show_modal({
  title = "Confirm",
  message = "Are you sure?",
  on_confirm = function() /* ... */ end,
  on_cancel = function() /* ... */ end,
})
```

## Troubleshooting

### "ARKITEKT framework not found!"
- Make sure the script is in the `ARKITEKT/` folder
- Check that `rearkitekt/` folder exists at the same level
- Verify folder structure matches the documentation

### "module 'Demo.core.state' not found"
- Check that Demo folder exists in ARKITEKT/
- Verify all files are in the correct locations
- Make sure you're running the script from REAPER (not command line)

### UI looks broken or doesn't respond
- Check REAPER console for errors
- Verify ReaImGui extension is installed
- Make sure you have the latest version of ARKITEKT

## Contributing

Found a bug in the demo? Have a suggestion?
- Open an issue on GitHub
- Submit a PR with improvements
- Share your modifications in the forum

## License

This demo is part of ARKITEKT, licensed under GPL v3.

---

**Happy coding! 🚀**

Built with ARKITEKT for the REAPER community.
