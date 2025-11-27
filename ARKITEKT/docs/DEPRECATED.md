# Deprecation Log

Track deprecated code for coordinated removal.

---

## Format

```
## [Date] Category: Description
- **Location**: file:line
- **Deprecated**: What's deprecated
- **Replacement**: What to use instead
- **Removal Target**: Version or date
- **Migration**: How to update
```

---

## Active Deprecations

*(None currently)*

---

## Pending Review

Items that may need deprecation:

### Widget Refactor Candidates
From `WIDGET_REFACTOR_STRATEGY.md`:
- Static preset tables (`M.BUTTON_COLORS`, `M.PANEL_COLORS`, etc.)
- Will be replaced by `build_*_config()` functions
- **Status**: Waiting for widget refactor completion

### Old Require Paths
From `arkitekt/app/README.md`:
```lua
-- Old paths (still work but discouraged)
require('arkitekt.app.runtime.shell')
require('arkitekt.app.assets.fonts')
require('arkitekt.app.chrome.window.window')

-- New paths (preferred)
require('arkitekt.app.shell')
require('arkitekt.app.chrome.fonts')
require('arkitekt.app.chrome.window')
```
- **Status**: Old paths work via compatibility layer, document for v2.0 removal

---

## Completed Removals

### 2025-11
*(None yet)*

---

## How to Deprecate

1. Add `---@deprecated` annotation
2. Add inline comment with date and replacement
3. Log warning on usage (optional for high-traffic paths)
4. Add entry to this file
5. Update COOKBOOK.md changelog section

Example:
```lua
---@deprecated Use Theme.COLORS.BG_PANEL instead
-- @deprecated 2025-11: Use Theme.COLORS.BG_PANEL
-- @removal-target: v2.0
function M.get_panel_bg()
  return Theme.COLORS.BG_PANEL
end
```

---

## Removal Process

When ready to remove:
1. Search codebase for usages: `grep -r "deprecated_function" ARKITEKT/`
2. Update all call sites
3. Remove deprecated code
4. Move entry from "Active" to "Completed" with date
5. Update version notes

---

*Last updated: 2025-11-27*
