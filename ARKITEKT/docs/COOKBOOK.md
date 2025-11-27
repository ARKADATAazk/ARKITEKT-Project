# ARKITEKT Cookbook

Core patterns, conventions, and architectural decisions.

---

## Module Patterns

### Standard Module Structure
```lua
-- @noindex
-- arkitekt/path/to/module.lua

local M = {}

-- Private state
local _cache = {}

-- Private functions (local, underscore prefix)
local function _helper()
end

-- Public API
function M.public_method()
end

return M
```

### Lazy Loading Pattern
For optional dependencies or expensive modules:
```lua
local _Theme
local function get_theme()
  if not _Theme then
    local ok, theme = pcall(require, 'arkitekt.core.theme')
    if ok then _Theme = theme end
  end
  return _Theme
end

-- Usage
local Theme = get_theme()
if Theme then
  local color = Theme.COLORS.BG_PANEL
end
```

### Metatable Proxy Pattern
For backward-compatible lazy access:
```lua
M.COLORS = setmetatable({}, {
  __index = function(_, key)
    return M.get_colors()[key]
  end
})
```

---

## Widget Conventions

### opts Table Pattern
All widgets accept `(ctx, opts)`:
```lua
function M.draw(ctx, opts)
  opts = opts or {}
  local label = opts.label or ""
  local width = opts.width or 100
  -- ...
  return { clicked = clicked, hovered = hovered }
end
```

### Result Table Pattern
Widgets return state for caller to act on:
```lua
local result = Button.draw(ctx, {label = "Save"})
if result.clicked then
  save_file()
end
```

### ID Generation
Use unique IDs for stateful widgets:
```lua
local id = opts.id or ("widget_" .. tostring(opts):match("0x(%x+)"))
```

---

## Theme Integration

### Reading Theme Colors
```lua
local Theme = require('arkitekt.core.theme')

-- Direct read (updates automatically with theme)
local bg = Theme.COLORS.BG_PANEL
local text = Theme.COLORS.TEXT_NORMAL

-- Theme interpolation factor (0=dark, 1=light)
local t = Theme.get_t()
```

### Theme-Reactive Config
For script-specific colors:
```lua
local _cached_colors
local _last_t

function M.get_colors()
  local Theme = get_theme()
  local current_t = Theme and Theme.get_t() or 0

  -- Invalidate on theme change
  if _last_t ~= current_t then
    _cached_colors = nil
    _last_t = current_t
  end

  if not _cached_colors then
    local TC = Theme and Theme.COLORS or {}
    _cached_colors = {
      bg = TC.BG_PANEL or 0x1A1A1AFF,
      text = TC.TEXT_NORMAL or 0xFFFFFFFF,
    }
  end

  return _cached_colors
end
```

### Script Palette Registration
For complex scripts with many theme-reactive values:
```lua
local ThemeManager = require('arkitekt.core.theme_manager')
local snap = ThemeManager.snap
local lerp = ThemeManager.lerp
local offset = ThemeManager.offset

ThemeManager.register_script_palette("MyScript", {
  HIGHLIGHT = snap("#FF6B6B", "#CC4444"),
  OPACITY = lerp(0.8, 0.5),
  PANEL_BG = offset(-0.06),
})

-- Later: access computed values
local p = ThemeManager.get_script_palette("MyScript")
local color = p.HIGHLIGHT  -- Already RGBA
```

---

## State Management

### Per-Widget State (Base.state_store)
```lua
local Base = require('arkitekt.gui.widgets.base')

function M.draw(ctx, opts)
  local id = opts.id or generate_id()
  local state = Base.get_state(id) or {}

  state.counter = (state.counter or 0) + 1

  Base.set_state(id, state)
end
```

### Settings Persistence
```lua
local Settings = require('arkitekt.core.settings')
local settings = Settings.new(data_dir, 'settings.json')

-- Read with default
local value = settings:get('ui.zoom', 1.0)

-- Write (auto-flushed)
settings:set('ui.zoom', 1.5)

-- Subsection for components
local ui_settings = settings:sub('ui')
ui_settings:set('zoom', 1.5)
```

---

## Error Handling

### Safe Require
```lua
local ok, Module = pcall(require, 'arkitekt.some.module')
if not ok then
  -- Fallback or skip
  return
end
```

### Logger Usage
```lua
local Logger = require('arkitekt.debug.logger')
Logger.info("WIDGET", "Button clicked: %s", id)
Logger.warn("THEME", "Color not found: %s", key)
Logger.error("SYSTEM", "Failed to load: %s", err)
```

---

## Performance Patterns

### Frame Budget
Target: <16ms per frame (60 FPS)
- Config resolution: <0.001ms
- Theme color read: ~5ns
- Table creation: ~50ns

### Caching Strategy
```lua
local _cache = {}
local _cache_frame = -1

function M.expensive_calculation()
  local frame = ImGui.GetFrameCount(ctx)
  if _cache_frame ~= frame then
    _cache = do_calculation()
    _cache_frame = frame
  end
  return _cache
end
```

### Avoid Per-Frame Allocations
```lua
-- BAD: Creates table every frame
function draw()
  local colors = {bg = 0x000000FF, fg = 0xFFFFFFFF}
end

-- GOOD: Reuse or cache
local _colors = {bg = 0x000000FF, fg = 0xFFFFFFFF}
function draw()
  -- Use _colors
end
```

---

## File Organization

### Directory Conventions
```
widgets/
├── primitives/     # Atomic widgets (button, checkbox, slider)
├── containers/     # Layout widgets (panel, grid, scroll)
├── composites/     # Complex widgets combining primitives
├── overlays/       # Full-screen overlays
└── media/          # Media-specific widgets
```

### Naming Conventions
- Files: `snake_case.lua`
- Modules: `PascalCase` (e.g., `local Button = require(...)`)
- Functions: `snake_case`
- Constants: `SCREAMING_SNAKE`
- Private: `_underscore_prefix`

---

## Common Anti-Patterns

### Avoid
```lua
-- Hardcoded colors (not theme-reactive)
local bg = 0x252525FF

-- God objects (split into focused modules)
-- Files >500 lines should be reviewed

-- Direct reaper.* in widgets (use abstractions)

-- Circular requires (use lazy loading)
```

### Prefer
```lua
-- Theme-reactive
local bg = Theme.COLORS.BG_BASE

-- Focused modules
-- Single responsibility per file

-- Abstraction layers for REAPER API

-- Lazy loading for optional deps
```

---

## Changelog / Pending Updates

Track significant changes that need documentation updates:

- [ ] Overlay mode now calls Theme.init() (2025-11)
- [ ] ItemPicker uses Theme.COLORS directly (2025-11)

---

*Last updated: 2025-11-27*
