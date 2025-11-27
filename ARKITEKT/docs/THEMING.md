# Theme System

Dynamic theming with algorithmic palette generation.

---

## Quick Start

```lua
local ThemeManager = require('arkitekt.core.theme_manager')

-- Set mode
ThemeManager.set_dark()   -- Dark preset (t=0)
ThemeManager.set_light()  -- Light preset (t=1)
ThemeManager.adapt()      -- Sync with REAPER theme

-- Access colors
local Theme = require('arkitekt.core.theme')
local bg = Theme.COLORS.BG_PANEL
local text = Theme.COLORS.TEXT_NORMAL
```

---

## Architecture

```
User selects mode (dark/light/adapt)
            ↓
    generate_palette(base_bg)
            ↓
    DSL wrappers resolve:
      offset() → BG-derived colors
      snap()   → discrete dark/light
      lerp()   → smooth interpolation
            ↓
       Theme.COLORS
            ↓
    Widgets read at render time
```

---

## DSL Wrappers

Three wrappers define how values adapt to theme:

### `offset(dark, light, [threshold])`
Delta from BG_BASE. Snaps between deltas at threshold.
```lua
BG_HOVER = offset(0.03, -0.04)     -- +3% dark, -4% light
BG_PANEL = offset(-0.04)           -- -4% both (constant)
```

### `snap(dark, light, [threshold])`
Discrete snap. No interpolation.
```lua
TEXT_NORMAL = snap("#FFFFFF", "#000000")  -- White or black
```

### `lerp(dark, light)`
Smooth interpolation based on t.
```lua
OPACITY = lerp(0.87, 0.60)         -- Smooth transition
```

---

## Theme.COLORS Keys

### Backgrounds
```lua
BG_BASE          -- Standard control background
BG_HOVER         -- Hovered state
BG_ACTIVE        -- Active/pressed state
BG_PANEL         -- Panel/container background
BG_CHROME        -- Window chrome background
```

### Borders
```lua
BORDER_OUTER     -- Dark outer border
BORDER_INNER     -- Light inner highlight
BORDER_HOVER     -- Border on hover
BORDER_ACTIVE    -- Border when active
```

### Text
```lua
TEXT_NORMAL      -- Standard text
TEXT_HOVER       -- Bright hover text
TEXT_DIMMED      -- Secondary/disabled text
TEXT_BRIGHT      -- Maximum contrast text
```

### Accents
```lua
ACCENT_PRIMARY   -- Primary accent (blue)
ACCENT_TEAL      -- Teal accent
ACCENT_SUCCESS   -- Success (green)
ACCENT_WARNING   -- Warning (orange)
ACCENT_DANGER    -- Danger (red)
```

---

## Reading Theme Values

### Direct Access (Recommended)
```lua
local Theme = require('arkitekt.core.theme')

-- Colors auto-update when theme changes
local bg = Theme.COLORS.BG_PANEL
local text = Theme.COLORS.TEXT_NORMAL

-- Get interpolation factor (0=dark, 1=light)
local t = Theme.get_t()
```

### In Widgets
```lua
local function resolve_config(opts)
  local config = {
    bg_color = Style.COLORS.BG_BASE,
    text_color = Style.COLORS.TEXT_NORMAL,
  }
  return config
end
```

---

## Script-Specific Palettes

For scripts with custom theme-reactive colors:

```lua
local ThemeManager = require('arkitekt.core.theme_manager')
local snap = ThemeManager.snap
local lerp = ThemeManager.lerp
local offset = ThemeManager.offset

-- Register at load time
ThemeManager.register_script_palette("MyScript", {
  HIGHLIGHT = snap("#FF6B6B", "#CC4444"),
  BADGE_TEXT = snap("#FFFFFF", "#1A1A1A"),
  GLOW_OPACITY = lerp(0.8, 0.5),
  PANEL_BG = offset(-0.06),
})

-- Access computed values
local p = ThemeManager.get_script_palette("MyScript")
local color = p.HIGHLIGHT  -- Already RGBA
```

---

## Mode Persistence

Theme mode persists via REAPER ExtState:
- Key: `ARKITEKT_ThemeMode`
- Values: `"dark"`, `"light"`, `"adapt"`

Loaded automatically by `ThemeManager.init()`.

### Titlebar Integration
Users change theme via titlebar context menu (right-click icon).
All window-mode apps share the same preference.

### Overlay Mode
As of 2025-11, overlay-mode apps (ItemPicker, etc.) also call `Theme.init()` at startup.

---

## REAPER Integration

### Manual Sync
```lua
ThemeManager.sync_with_reaper()
```

### Live Sync
```lua
local sync = ThemeManager.create_live_sync(1.0)  -- Check every second

function main_loop()
  sync()  -- Checks REAPER theme, updates if changed
  draw_ui()
end
```

### What REAPER Provides
Ultra-minimal approach:
- Reads 2 colors: `col_main_bg2` + `col_arrangebg`
- Extracts contrast intent, clamps deltas to ±10%
- Auto-derives text color from luminance
- **No accent extraction** - stays neutral grayscale

---

## Debugging

```lua
-- Get current values
local l = ThemeManager.get_theme_lightness()
local t = ThemeManager.get_current_t()

-- Toggle debug overlay (F12 also works)
ThemeManager.toggle_debug()

-- Validate palette configuration
local valid, err = ThemeManager.validate()
```

---

## Adding New Theme Values

1. Choose wrapper:
   - `offset()` for BG-derived
   - `snap()` for discrete
   - `lerp()` for smooth

2. Add to palette in `theme_manager/palette.lua`:
```lua
MY_NEW_COLOR = snap("#FF0000", "#00FF00"),
MY_NEW_BG = offset(0.08, -0.06),
```

3. Access in code:
```lua
local color = Theme.COLORS.MY_NEW_COLOR
```

---

## Performance

- Theme switch: <0.1ms
- Live sync check: <1μs per second
- Per-frame cost: 0ms (direct reads)

No rebuild needed - colors update automatically.

---

*Last updated: 2025-11-27*
