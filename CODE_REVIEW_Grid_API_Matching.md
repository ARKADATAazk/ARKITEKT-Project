# Grid API Matching - Code Review

**Date:** 2025-11-30
**Branch:** `claude/review-grid-api-matching-016Sdsa26Rcvu3of9Hj8SwL5`
**Reviewer:** Claude Code
**Scope:** Grid widget implementation vs. GRID_REWORK.md specifications

---

## Executive Summary

**Status:** ⚠️ **NOT READY FOR MERGE**

The Grid implementation in `arkitekt/gui/widgets/containers/grid/` is **NOT YET MIGRATED** to the new ImGui-style API specified in `TODO/01_HIGH/FEATURE_APIMatching/GRID_REWORK.md`. The current implementation still uses the old explicit retained mode pattern, which contradicts the API matching roadmap.

### Critical Findings

| Category | Status | Details |
|----------|--------|---------|
| **API Pattern** | ❌ **FAIL** | Still uses `Grid.new()` + `grid:draw()` - should be `Ark.Grid(ctx, opts)` |
| **Hidden State** | ❌ **NOT IMPLEMENTED** | No hidden state management - user must store grid object |
| **Namespace** | ❌ **MISSING** | Not registered in `Ark.*` namespace |
| **Code Quality** | ✅ **PASS** | Well-structured, no globals, good separation of concerns |
| **Documentation** | ⚠️ **PARTIAL** | README.md documents old API, not target API |
| **ARKITEKT Conventions** | ✅ **PASS** | Follows module structure, no anti-patterns |

---

## Detailed Analysis

### 1. API Pattern Mismatch

#### Current Implementation (core.lua:101-177)
```lua
-- User must call Grid.new() and store the result
local grid = Grid.new({
  id = "pool_grid",
  gap = 8,
  render_tile = render_fn,
  key = key_fn,
  -- ...
})

-- User must manage lifecycle
rt.pool_grid = grid  -- Store somewhere

-- Draw every frame
grid:draw(ctx)
```

#### Target API (per GRID_REWORK.md:43-71)
```lua
-- Every frame - just call it
local r = Ark.Grid(ctx, {
  id = "pool_grid",
  items = get_pool_items(),
  render = render_tile,
  key = function(item) return "pool_" .. item.rid end,

  selectable = true,
  draggable = true,
  reorderable = true,
})

-- Access state via result
if r.selection_changed then
  handle_selection(r.selected_keys)
end
```

**Issues:**
- ❌ No `__call` metamethod to enable `Ark.Grid(ctx, opts)` pattern
- ❌ No hidden state management system
- ❌ User must manually create and store grid instances
- ❌ Lifecycle management is manual (no auto-cleanup)
- ❌ No result object with state snapshot

**Impact:** HIGH - This is the core purpose of the API matching initiative

---

### 2. Missing Features

#### 2.1 Hidden State Management

**Required (GRID_REWORK.md:42-78):**
- State stored internally by ID
- Auto-cleanup after 30s of no access
- Result object with state snapshot

**Current:** NONE

The implementation has no hidden state registry. Compare to ImGui's approach:
```lua
-- ImGui pattern (what we should mimic)
local state = ImGui._GetOrCreateState(id)
state.last_access = now
-- Auto-cleanup stale states
```

#### 2.2 Callable Module Pattern

**Required (README.md:11, DECISIONS.md:31-53):**
```lua
return setmetatable(M, {
  __call = function(_, ctx, opts)
    return M.draw(ctx, opts)
  end
})
```

**Current:** Module returns plain table `M`, not callable

**Location:** `arkitekt/gui/widgets/containers/grid/core.lua:1177`

#### 2.3 Namespace Registration

**Required:** Grid should be accessible as `Ark.Grid`

**Expected location:** `arkitekt/loader.lua` should register:
```lua
Grid = lazy_load('arkitekt.gui.widgets.containers.grid.core')
```

**Current:** No registration found

---

### 3. Architecture Review

#### 3.1 Module Structure ✅ GOOD

The Grid is well-organized:
- `core.lua` - Main orchestrator (1177 LOC)
- `grid_bridge.lua` - Cross-grid coordination (280 LOC)
- `input.lua` - Input handling
- `layout.lua` - Layout calculations
- `rendering.lua` - Rendering utilities
- `animation.lua` - Spawn/destroy animations
- `dnd_state.lua` - Drag-drop state
- `drop_zones.lua` - Drop target detection

**Adherence to CLAUDE.md:**
- ✅ No globals
- ✅ Returns table `M`
- ✅ Clear separation of concerns
- ✅ No hardcoded magic numbers (uses DEFAULTS)

#### 3.2 Performance Optimizations ✅ EXCELLENT

**Virtual list mode (core.lua:353-656):**
```lua
-- Only render visible items for 1000+ datasets
if self.virtual and num_items > 0 then
  if self:_draw_virtual(ctx, items, num_items) then
    return
  end
end
```

**Viewport culling (core.lua:912-938):**
```lua
-- Calculate visible row range to avoid looping all items
-- For 1000 items with 10 visible, reduces loop from 1000 to ~20
local first_visible_row = max(0, (viewport_top - origin_y - self.gap) // row_height)
local last_visible_row = ceil((viewport_bottom - origin_y - self.gap) / row_height)
```

**Caching (core.lua:165-167):**
```lua
-- Cache string IDs for performance (avoid concat every frame)
_cached_bg_id = "##grid_bg_" .. grid_id,
_cached_empty_id = "##grid_empty_" .. grid_id,
```

**Assessment:** Performance optimizations are top-notch. These should be preserved during migration.

#### 3.3 Code Quality ✅ GOOD

**Strengths:**
- Clear function names and documentation
- Sensible defaults with override capability
- Good use of local functions
- Performance-conscious (caching, viewport culling)
- Comprehensive feature set (selection, DnD, animations, virtual scrolling)

**Minor Issues:**
- Some functions are very long (`:draw` is 500 LOC, `:_draw_virtual` is 303 LOC)
- Could benefit from extraction of sub-workflows
- Not a blocker, but consider for future refactoring

---

### 4. API Design Issues

#### 4.1 Opts Structure Inconsistency

**Current (core.lua:101-176):**
```lua
Grid.new({
  get_items = function() return items end,  -- Function
  render_tile = function(...) end,           -- Function
  key = function(item) return item.id end,  -- Function
  -- ...
})
```

**Target (GRID_REWORK.md:46-56):**
```lua
Ark.Grid(ctx, {
  items = items,              -- Direct value (not function)
  render = render_fn,         -- Renamed from render_tile
  key = key_fn,               -- Function
})
```

**Issues:**
- ❌ `get_items` is a function, should be direct `items` value
- ❌ `render_tile` should be renamed to `render`
- ⚠️ Need migration path for existing code

#### 4.2 Behaviors vs. Callbacks

**Current pattern:**
```lua
behaviors = {
  drag_start = function(grid, item_keys) ... end,
  reorder = function(grid, new_order) ... end,
  ['click:right'] = function(grid, key, selected) ... end,
}
```

**Target pattern (GRID_REWORK.md:186-196):**
```lua
on_drag_start = function(keys) ... end,
on_reorder = function(new_order) ... end,
on_right_click = function(key, selected) ... end,
```

**Issue:** Need clear migration path. GRID_REWORK.md suggests supporting both.

---

### 5. Documentation Review

#### 5.1 README.md Status

**Current:** Documents the OLD API pattern
- Shows `Grid.new()` usage
- Shows object-oriented `:draw()` calls
- Does NOT mention `Ark.Grid()` pattern

**Required:** Update to show target API

#### 5.2 Code Comments

**Assessment:** Generally good, but some areas need clarification:
- Virtual mode requirements could be clearer
- State lifecycle not documented (because it doesn't exist yet)

---

### 6. Breaking Changes Assessment

#### Migration Impact

**Files affected (based on git log):**
- `scripts/RegionPlaylist/ui/tiles/pool_grid_factory.lua`
- `scripts/RegionPlaylist/ui/tiles/active_grid_factory.lua`
- `scripts/RegionPlaylist/ui/tiles/coordinator*.lua`
- `scripts/ItemPicker/ui/grids/coordinator.lua`
- `scripts/ItemPicker/ui/grids/factories/*.lua`
- `scripts/ThemeAdjuster/ui/grids/*_grid_factory.lua`
- `scripts/TemplateBrowser/ui/tiles/factory.lua`
- `scripts/ColorPalette/widgets/color_grid.lua`

**Estimated migration effort:** HIGH
- 10+ files use Grid
- Each factory module needs refactoring
- Need to preserve functionality during migration

**Recommended approach (per GRID_REWORK.md:219-254):**
1. Phase 1: Add ImGui-style API alongside old API
2. Phase 2: Migrate apps one by one
3. Phase 3: Deprecate old API with warnings
4. Phase 4: Remove old API

---

### 7. Compliance with ARKITEKT Guidelines

#### From CLAUDE.md

| Guideline | Status | Notes |
|-----------|--------|-------|
| **Namespace** `arkitekt.*` | ✅ PASS | `require('arkitekt.gui.widgets.containers.grid.core')` |
| **Lazy load** `Ark.*` | ❌ FAIL | Not registered in loader |
| **No globals** | ✅ PASS | All modules return `M` |
| **Layer separation** | ✅ PASS | GUI layer, no domain logic mixed in |
| **Bootstrap pattern** | N/A | Not an entry point |
| **Edit discipline** | ✅ PASS | Clean diffs, focused changes |

---

## Recommendations

### Critical (Must-Do Before Merge)

1. **DO NOT MERGE THIS AS-IS**
   - Current implementation does not meet API matching goals
   - Would be a step backward from the roadmap

2. **Implement Hidden State Management**
   - Create state registry indexed by ID
   - Implement auto-cleanup after 30s
   - Return result object with state snapshot

3. **Add Callable Pattern**
   - Make module callable with `__call` metamethod
   - Support `Ark.Grid(ctx, opts)` syntax
   - Keep `Grid.new()` as internal implementation

4. **Register in Ark Namespace**
   - Update `arkitekt/loader.lua` to register `Ark.Grid`
   - Test accessibility via `Ark.Grid()`

5. **Implement Phased Migration**
   - Phase 1: Add new API alongside old (parallel support)
   - Phase 2: Create migration examples
   - Phase 3: Migrate one app (e.g., ColorPalette)
   - Phase 4: Document migration path

### Important (Should Do)

6. **Update Documentation**
   - Update README.md to show target API
   - Add migration guide
   - Document gotchas (per GRID_REWORK.md:299-403)

7. **Add ID Validation**
   - Require explicit `id` field (per GRID_REWORK.md:257-268)
   - Error if missing: "Ark.Grid: 'id' field is required"
   - Add debug mode duplicate ID detection

8. **Create Result Object Spec**
   - Define all result fields (GRID_REWORK.md:133-166)
   - Implement as snapshot (not live reference)
   - Document behavior

### Nice to Have

9. **Extract Long Functions**
   - `:draw()` is 500 LOC - could be split
   - `:_draw_virtual()` is 303 LOC - could be split
   - Not blocking, but improves maintainability

10. **Add Tests**
    - No tests found for Grid
    - Should add basic lifecycle tests
    - Test hidden state cleanup

---

## Conclusion

The Grid implementation is **high-quality code** with excellent performance optimizations, but it **does not implement the API matching specifications**. The work is incomplete:

### What's Done ✅
- Solid, performant Grid implementation
- Good architecture and code quality
- Virtual scrolling for large datasets
- Comprehensive feature set

### What's Missing ❌
- ImGui-style hidden state API
- Callable module pattern
- Ark namespace registration
- Result object with state snapshot
- Migration path from old API

### Next Steps

**Do not merge this branch.** Instead:

1. **Decide on approach:**
   - Option A: Implement hidden state API in this branch
   - Option B: Mark as "planning/documentation only" and create new implementation branch
   - Option C: Keep current Grid as-is, create new `Ark.Grid` as separate implementation

2. **If proceeding with migration:**
   - Review GRID_REWORK.md:219-254 for phased approach
   - Start with hidden state registry
   - Add callable pattern
   - Preserve all performance optimizations
   - Create migration guide

3. **Update TODO/01_HIGH/FEATURE_APIMatching/CHECKLIST.md:**
   - Add Grid-specific checklist items
   - Track implementation progress

---

## Files Reviewed

- `arkitekt/gui/widgets/containers/grid/core.lua` (1177 LOC)
- `arkitekt/gui/widgets/containers/grid/grid_bridge.lua` (280 LOC)
- `arkitekt/gui/widgets/containers/grid/README.md` (354 LOC)
- `TODO/01_HIGH/FEATURE_APIMatching/GRID_REWORK.md` (493 LOC)
- `TODO/01_HIGH/FEATURE_APIMatching/README.md` (151 LOC)
- `TODO/01_HIGH/FEATURE_APIMatching/GUARDRAILS.md` (161 LOC)
- `TODO/01_HIGH/FEATURE_APIMatching/DECISIONS.md` (partial)
- `CLAUDE.md` (framework guidelines)

**Review Time:** ~45 minutes
**Recommendation:** **DO NOT MERGE** - Incomplete implementation
