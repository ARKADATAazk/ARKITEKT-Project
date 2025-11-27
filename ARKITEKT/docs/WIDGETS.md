# Widget Development Guide

How to create and extend ARKITEKT widgets.

---

## Widget Categories

| Category | Path | Purpose |
|----------|------|---------|
| Primitives | `widgets/primitives/` | Atomic UI elements (button, checkbox, slider) |
| Containers | `widgets/containers/` | Layout and grouping (panel, grid, scroll) |
| Composites | `widgets/composites/` | Multi-primitive combinations |
| Overlays | `widgets/overlays/` | Full-screen modal overlays |
| Media | `widgets/media/` | Media-specific (waveform, grid) |

---

## Widget API Contract

### Signature
```lua
function M.draw(ctx, opts)
  -- ctx: ImGui context (userdata)
  -- opts: Configuration table (optional fields)
  return result  -- State table for caller
end
```

### opts Table Convention
```lua
---@class WidgetOptions
---@field id? string           Unique identifier (auto-generated if nil)
---@field x? number            X position (nil = cursor position)
---@field y? number            Y position (nil = cursor position)
---@field width? number        Widget width
---@field height? number       Widget height
---@field disabled? boolean    Disable interactions
---@field preset_name? string  Style preset name
```

### Result Table Convention
```lua
---@class WidgetResult
---@field hovered boolean      Mouse is over widget
---@field active boolean       Widget is being interacted with
---@field width number         Actual rendered width
---@field height number        Actual rendered height
```

---

## Minimal Widget Template

```lua
-- @noindex
-- arkitekt/gui/widgets/primitives/my_widget.lua

local Style = require('arkitekt.gui.style.defaults')
local Base = require('arkitekt.gui.widgets.base')

local M = {}

---@class MyWidgetOptions
---@field id? string
---@field value number
---@field width? number

---@class MyWidgetResult
---@field value number
---@field changed boolean
---@field hovered boolean

---@param ctx userdata
---@param opts MyWidgetOptions
---@return MyWidgetResult
function M.draw(ctx, opts)
  opts = opts or {}
  local ImGui = reaper.ImGui

  -- Generate ID
  local id = opts.id or ("mywidget_" .. tostring(opts):match("0x(%x+)"))

  -- Get/create state
  local state = Base.get_state(id) or {value = opts.value or 0}

  -- Resolve config from theme
  local config = {
    bg_color = Style.COLORS.BG_BASE,
    text_color = Style.COLORS.TEXT_NORMAL,
    width = opts.width or 100,
  }

  -- Get cursor position
  local x, y = ImGui.GetCursorScreenPos(ctx)
  local w, h = config.width, 20

  -- Draw
  local dl = ImGui.GetWindowDrawList(ctx)
  ImGui.DrawList_AddRectFilled(dl, x, y, x + w, y + h, config.bg_color)

  -- Handle input
  ImGui.SetCursorScreenPos(ctx, x, y)
  ImGui.InvisibleButton(ctx, id, w, h)
  local hovered = ImGui.IsItemHovered(ctx)
  local active = ImGui.IsItemActive(ctx)

  -- Update state
  local changed = false
  if active then
    -- Handle interaction
    state.value = state.value + 1
    changed = true
  end

  -- Save state
  Base.set_state(id, state)

  -- Advance cursor
  ImGui.SetCursorScreenPos(ctx, x, y + h)

  return {
    value = state.value,
    changed = changed,
    hovered = hovered,
  }
end

function M.cleanup()
  -- Optional: cleanup state on script exit
end

return M
```

---

## Config Resolution Pattern

### Dynamic Config (Theme-Reactive)
```lua
local function resolve_config(opts)
  local Style = require('arkitekt.gui.style.defaults')

  -- Base config from theme
  local config = {
    bg_color = Style.COLORS.BG_BASE,
    bg_hover_color = Style.COLORS.BG_HOVER,
    text_color = Style.COLORS.TEXT_NORMAL,
    rounding = 0,
    padding_x = 10,
    padding_y = 6,
  }

  -- Apply preset if specified
  if opts.preset_name and Style[opts.preset_name] then
    for k, v in pairs(Style[opts.preset_name]) do
      config[k] = v
    end
  end

  -- User overrides (highest priority)
  for k, v in pairs(opts) do
    if config[k] ~= nil and v ~= nil then
      config[k] = v
    end
  end

  return config
end
```

### Static Presets (Legacy)
```lua
-- Still supported but prefer dynamic
local base = Style.BUTTON
local config = Style.apply_defaults(base, opts)
```

---

## State Management

### Using Base.state_store
```lua
local Base = require('arkitekt.gui.widgets.base')

function M.draw(ctx, opts)
  local id = opts.id or generate_id()

  -- Get existing state or create new
  local state = Base.get_state(id) or {
    expanded = false,
    scroll_y = 0,
  }

  -- Modify state
  if clicked then
    state.expanded = not state.expanded
  end

  -- Save state
  Base.set_state(id, state)
end
```

### Cleanup
```lua
function M.cleanup()
  -- Called periodically by Base.periodic_cleanup()
  -- Clear stale state entries
end
```

---

## Drawing Patterns

### DrawList Usage
```lua
local dl = ImGui.GetWindowDrawList(ctx)

-- Rectangles
ImGui.DrawList_AddRectFilled(dl, x1, y1, x2, y2, color, rounding)
ImGui.DrawList_AddRect(dl, x1, y1, x2, y2, color, rounding, flags, thickness)

-- Text
ImGui.DrawList_AddText(dl, x, y, color, text)
-- or with font:
ImGui.DrawList_AddTextEx(dl, font, font_size, x, y, color, text)

-- Lines
ImGui.DrawList_AddLine(dl, x1, y1, x2, y2, color, thickness)
```

### Cursor Management
```lua
-- Save position
local x, y = ImGui.GetCursorScreenPos(ctx)

-- Draw widget...

-- Restore/advance cursor
ImGui.SetCursorScreenPos(ctx, x, y + height)  -- vertical advance
-- or
ImGui.SetCursorScreenPos(ctx, x + width, y)   -- horizontal advance
```

---

## Input Handling

### InvisibleButton Pattern
```lua
ImGui.SetCursorScreenPos(ctx, x, y)
ImGui.InvisibleButton(ctx, id, width, height)

local hovered = ImGui.IsItemHovered(ctx)
local active = ImGui.IsItemActive(ctx)
local clicked = ImGui.IsItemClicked(ctx)
local right_clicked = ImGui.IsItemClicked(ctx, 1)  -- Right mouse
```

### Mouse Position
```lua
local mx, my = ImGui.GetMousePos(ctx)
local rel_x = mx - x  -- Relative to widget
local rel_y = my - y
```

### Keyboard Input
```lua
if ImGui.IsItemFocused(ctx) then
  if ImGui.IsKeyPressed(ctx, ImGui.Key_Enter) then
    -- Handle enter
  end
end
```

---

## Style Integration

### Color Keys
Common `Style.COLORS` keys:
```lua
BG_BASE           -- Control background
BG_HOVER          -- Hovered background
BG_ACTIVE         -- Active/pressed background
BG_PANEL          -- Panel/container background
BORDER_OUTER      -- Dark outer border
BORDER_INNER      -- Light inner highlight
TEXT_NORMAL       -- Standard text
TEXT_HOVER        -- Bright hover text
TEXT_DIMMED       -- Secondary/disabled text
ACCENT_PRIMARY    -- Primary accent color
```

### Preset Names
Common presets in `Style`:
```lua
BUTTON
BUTTON_TOGGLE_TEAL
BUTTON_TOGGLE_WHITE
BUTTON_DANGER
DROPDOWN
TOOLTIP
```

---

## Testing Widgets

### Manual Testing Checklist
- [ ] Renders correctly at default size
- [ ] Responds to hover/active states
- [ ] Works with theme changes (dark/light)
- [ ] Handles disabled state
- [ ] Works with custom colors via opts
- [ ] No visual glitches at edges
- [ ] Proper cursor advancement

### Demo Pattern
```lua
-- scripts/demos/demo_my_widget.lua
local ark = require('arkitekt')

local function draw(ctx, state)
  ImGui.Text(ctx, "MyWidget Demo")

  local result = ark.MyWidget.draw(ctx, {
    value = state.value or 0,
    width = 200,
  })

  if result.changed then
    state.value = result.value
  end

  ImGui.Text(ctx, "Value: " .. result.value)
end
```

---

## Common Mistakes

### Forgetting to Advance Cursor
```lua
-- BAD: Next widget overlaps
ImGui.DrawList_AddRect(...)

-- GOOD: Advance cursor after drawing
ImGui.SetCursorScreenPos(ctx, x, y + height)
```

### Hardcoded Colors
```lua
-- BAD: Won't respond to theme
local bg = 0x252525FF

-- GOOD: Theme-reactive
local bg = Style.COLORS.BG_BASE
```

### Missing ID
```lua
-- BAD: State collisions
local state = Base.get_state("button")

-- GOOD: Unique per-instance
local id = opts.id or ("button_" .. tostring(opts):match("0x(%x+)"))
local state = Base.get_state(id)
```

---

*Last updated: 2025-11-27*
