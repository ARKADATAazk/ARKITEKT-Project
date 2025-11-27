# ARKITEKT Framework

ReaImGui-based UI toolkit for REAPER. Lua 5.4, ImGui 0.10.

## Quick Reference

```lua
-- Bootstrap
local ARK = dofile(debug.getinfo(1,"S").source:sub(2):match("(.-ARKITEKT[/\\])") .. "arkitekt/app/bootstrap.lua").init()

-- Namespace access
local ark = require('arkitekt')
ark.Button.draw(ctx, {label = "Click"})

-- Direct require (also valid)
local Button = require('arkitekt.gui.widgets.primitives.button')
```

## Architecture

```
ARKITEKT/
├── arkitekt/           # Framework core
│   ├── app/            # Bootstrap, Shell, Chrome (window/titlebar/status)
│   ├── core/           # Colors, Config, Settings, Theme, ThemeManager
│   ├── gui/
│   │   ├── widgets/    # Primitives, Containers, Overlays, Media
│   │   └── style/      # defaults.lua (Style.COLORS, presets)
│   └── defs/           # Constants (app.lua, typography.lua)
├── scripts/            # Applications (ItemPicker, RegionPlaylist, etc.)
└── docs/               # Developer documentation
```

## Key Modules

| Module | Path | Purpose |
|--------|------|---------|
| Shell | `arkitekt.app.shell` | App runner (window/overlay modes) |
| Style | `arkitekt.gui.style.defaults` | Colors, presets, config builders |
| Theme | `arkitekt.core.theme` | Theme.COLORS, Theme.get_t() |
| ThemeManager | `arkitekt.core.theme_manager` | Mode switching, REAPER sync |
| Colors | `arkitekt.core.colors` | Color math (HSL, lerp, adjust) |

## Common Patterns

### Widget opts Pattern
All widgets take `(ctx, opts)` and return a result table:
```lua
local result = ark.Button.draw(ctx, {
  label = "Click",
  preset_name = "BUTTON_TOGGLE_TEAL",
  on_click = function() end,
})
if result.clicked then ... end
```

### Theme-Reactive Colors
```lua
local Theme = require('arkitekt.core.theme')
local bg = Theme.COLORS.BG_PANEL      -- Auto-updates with theme
local t = Theme.get_t()               -- 0=dark, 1=light
```

### Lazy Loading
```lua
local _Module
local function get_module()
  if not _Module then
    local ok, m = pcall(require, 'path.to.module')
    if ok then _Module = m end
  end
  return _Module
end
```

## Documentation

| Topic | File | Lines |
|-------|------|-------|
| **Patterns & Architecture** | `ARKITEKT/docs/COOKBOOK.md` | ~400 |
| **Widget Development** | `ARKITEKT/docs/WIDGETS.md` | ~300 |
| **Theme System** | `ARKITEKT/docs/THEMING.md` | ~250 |
| **Coding Standards** | `ARKITEKT/docs/STYLE_GUIDE.md` | ~150 |
| **Deprecations** | `ARKITEKT/docs/DEPRECATED.md` | Living |
| **LuaLS Annotations** | `ARKITEKT/docs/LUALS_ANNOTATIONS.md` | ~200 |

## Scripts

| Script | Description |
|--------|-------------|
| ItemPicker | Template/media browser overlay |
| RegionPlaylist | Region management with themes |
| TemplateBrowser | Project template browser |

## Key Decisions

1. **Flat palettes** - Theme uses DSL wrappers (snap/lerp/offset), not nested tables
2. **Direct Theme.COLORS reads** - Widgets read colors at render time, no rebuild
3. **ark.* namespace** - Single import, lazy-loaded modules
4. **Shell modes** - Window mode (chrome) or Overlay mode (transparent fullscreen)
5. **No godfiles** - Max ~500 lines per file, split when larger

## Quick Commands

```bash
# Find all widgets
find ARKITEKT/arkitekt/gui/widgets -name "*.lua" | head -20

# Search for pattern
grep -r "Theme.COLORS" ARKITEKT/arkitekt/

# Check file size (godfile detection)
wc -l ARKITEKT/arkitekt/gui/widgets/primitives/*.lua
```
