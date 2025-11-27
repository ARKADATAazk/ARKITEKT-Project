# ARKITEKT Style Guide

Coding standards and practices for consistent, maintainable code.

---

## File Size Limits

**Target: ~300 lines ideal, 500 max**

Files exceeding 500 lines should be reviewed for splitting opportunities:
- Extract helper functions to separate module
- Split widget into base + variants
- Move constants to dedicated file

```bash
# Check file sizes
wc -l arkitekt/gui/widgets/primitives/*.lua | sort -n
```

---

## Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Files | `snake_case.lua` | `button.lua`, `theme_manager.lua` |
| Modules | `PascalCase` | `local Button = require(...)` |
| Functions | `snake_case` | `function M.draw_button()` |
| Private funcs | `_underscore` | `local function _helper()` |
| Constants | `SCREAMING_SNAKE` | `M.COLORS.BG_BASE` |
| Local vars | `snake_case` | `local item_count = 0` |

---

## Module Structure

```lua
-- @noindex
-- Path comment

-- 1. Requires (external first, then internal)
local ImGui = require('imgui')
local Style = require('arkitekt.gui.style.defaults')

-- 2. Module table
local M = {}

-- 3. Constants
M.DEFAULT_WIDTH = 100

-- 4. Private state
local _cache = {}

-- 5. Private functions
local function _helper()
end

-- 6. Public API
function M.draw(ctx, opts)
end

-- 7. Return
return M
```

---

## Comments

### When to Comment
- **Why**, not what (code shows what)
- Complex algorithms
- Non-obvious workarounds
- API contracts

### When NOT to Comment
```lua
-- BAD: Obvious
local count = 0  -- Initialize count to zero

-- GOOD: Non-obvious reason
local count = 0  -- Must start at 0 for accumulator pattern
```

### Block Comments for Sections
```lua
-- ============================================================================
-- SECTION NAME
-- ============================================================================
```

---

## Error Handling

### Safe Requires
```lua
local ok, Module = pcall(require, 'arkitekt.optional.module')
if not ok then return end  -- Graceful degradation
```

### Defensive Defaults
```lua
opts = opts or {}
local width = opts.width or 100
local colors = Theme and Theme.COLORS or {}
local bg = colors.BG_BASE or 0x252525FF
```

### Never Silently Fail
```lua
-- BAD: Silent failure
if not data then return end

-- GOOD: Log and return sensible default
if not data then
  Logger.warn("WIDGET", "No data provided")
  return {items = {}}
end
```

---

## Performance Guidelines

### Avoid Per-Frame Allocations
```lua
-- BAD: New table every frame
function draw()
  local config = {width = 100, height = 50}
end

-- GOOD: Reuse or cache
local _config = {width = 100, height = 50}
function draw()
  -- modify _config if needed
end
```

### Cache Expensive Operations
```lua
local _cache
local _cache_key

function M.get_expensive()
  local key = compute_cache_key()
  if _cache_key ~= key then
    _cache = expensive_operation()
    _cache_key = key
  end
  return _cache
end
```

### Lazy Load Optional Dependencies
```lua
local _Theme
local function get_theme()
  if not _Theme then
    local ok, t = pcall(require, 'arkitekt.core.theme')
    if ok then _Theme = t end
  end
  return _Theme
end
```

---

## Deprecation Notation

When deprecating code, add annotation and log to `DEPRECATED.md`:

```lua
---@deprecated Use Theme.COLORS.BG_PANEL instead
-- @deprecated 2025-11: Replaced by Theme.COLORS.BG_PANEL
-- @removal-target: v2.0
function M.get_panel_bg()
  Logger.warn("DEPRECATED", "get_panel_bg() is deprecated, use Theme.COLORS.BG_PANEL")
  return Theme.COLORS.BG_PANEL
end
```

---

## Import Order

1. Standard library / external
2. Framework core
3. Framework modules
4. Local/relative

```lua
-- External
local ImGui = require('imgui')

-- Framework core
local Config = require('arkitekt.core.config')
local Colors = require('arkitekt.core.colors')

-- Framework modules
local Style = require('arkitekt.gui.style.defaults')
local Base = require('arkitekt.gui.widgets.base')

-- Local (avoid if possible)
local helpers = require('arkitekt.gui.widgets.primitives._helpers')
```

---

## Git Commit Messages

```
<type>: <short description>

<optional body explaining why>
```

Types:
- `fix:` Bug fixes
- `feat:` New features
- `refactor:` Code changes that don't fix bugs or add features
- `docs:` Documentation only
- `style:` Formatting, no code change
- `perf:` Performance improvements
- `test:` Adding tests

Example:
```
fix: Theme.init() not called in overlay mode

Overlay-mode apps (ItemPicker, etc.) were not initializing
Theme.COLORS because run_overlay_mode() lacked Theme.init().
```

---

## Anti-Patterns to Avoid

| Don't | Do Instead |
|-------|------------|
| Hardcoded colors | `Theme.COLORS.*` |
| God files (>500 lines) | Split into modules |
| Circular requires | Lazy loading |
| Magic numbers | Named constants |
| Deep nesting (>3 levels) | Early returns, extract functions |
| Global variables | Module-level locals |
| Modifying function args | Copy first if needed |

---

## LuaLS Annotations (Minimum)

For public APIs, add at minimum:
```lua
---@param ctx userdata ImGui context
---@param opts WidgetOptions
---@return WidgetResult
function M.draw(ctx, opts)
```

See `LUALS_ANNOTATIONS_GUIDE.md` for full reference.

---

*Last updated: 2025-11-27*
