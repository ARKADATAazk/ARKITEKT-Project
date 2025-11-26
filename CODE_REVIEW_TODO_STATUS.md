# Code Review: TODO Performance Optimizations Status

**Review Date:** 2025-11-26
**Reference:** `TODO/PERFORMANCE.md`
**Current Compliance:** 7.5/10 → **Estimated: 6.0/10** (More code than initially estimated)

---

## Executive Summary

The initial TODO estimates were **significantly understated**. The codebase contains:
- **284 `table.insert` calls** (vs. estimated ~90)
- **334 `math.floor` calls** (vs. estimated ~90)
- **182 `//1` floor divisions** already implemented

**Good news:** Priority files (core/colors, core/images, gui/draw/pattern) have been converted.
**Challenge:** Much more work remains than originally documented.

---

## 📊 Detailed Findings

### 1. Replace `table.insert` with Direct Indexing ⚠️ **IN PROGRESS**

**Status:** ~23% Complete (estimate based on some files converted)
**Impact:** Function call overhead removal
**Effort:** Medium (much larger scope than anticipated)

#### Current State:
| Area | Count | Example Files |
|------|-------|---------------|
| **Core ARKITEKT** | 99 | `debug/logger.lua`, `app/chrome/status_bar.lua`, `gui/widgets/navigation/tree_view.lua` |
| **RegionPlaylist** | 48 | `storage/sws_importer.lua`, `ui/status.lua`, `ui/batch_operations.lua` |
| **ItemPicker** | 38 | `data/reaper_api.lua`, `services/visualization.lua`, `ui/grids/factories/*` |
| **TemplateBrowser** | 41 | `domain/undo.lua`, `ui/views/tree_view.lua`, `ui/tiles/template_grid_factory.lua` |
| **Other Scripts** | 58 | Various demos and utilities |
| **TOTAL** | **284** | (excluding ThemeAdjuster & helpers) |

#### ✅ Already Converted:
- `arkitekt/reaper/region_operations.lua` - Uses `[#t + 1]` pattern
- `scripts/RegionPlaylist/engine/core.lua:72` - Uses `order[#order + 1]`

#### 🔥 Priority Files (High Traffic):
1. `arkitekt/gui/widgets/navigation/tree_view.lua` - Used in multiple views
2. `arkitekt/app/chrome/status_bar.lua` - Rendered every frame
3. `arkitekt/gui/widgets/media/package_tiles/renderer.lua` - Tile rendering
4. `scripts/RegionPlaylist/ui/tiles/coordinator_render.lua` - Real-time updates
5. `scripts/ItemPicker/services/visualization.lua` - Visualization hot path

---

### 2. Replace `math.floor` with `//1` ⚠️ **PARTIALLY COMPLETE**

**Status:** ~35% Complete (182 `//1` exist, 334 `math.floor` remain)
**Impact:** ~5-10% CPU reduction in loops
**Effort:** Medium-High

#### ✅ COMPLETED Priority Files:
- `arkitekt/core/colors.lua` ✅ No math.floor found
- `arkitekt/core/images.lua` ✅ No math.floor found
- `arkitekt/core/json.lua` ✅ Already uses `//1` extensively (lines 60, 62, 63, 66-68)
- `arkitekt/gui/draw/pattern.lua` ✅ No math.floor found
- `scripts/ColorPalette/app/gui.lua` ✅ No math.floor found

#### ❌ REMAINING Files with `math.floor`:

**High Priority (GUI Hot Paths):**
| File | Count | Context | Priority |
|------|-------|---------|----------|
| `arkitekt/gui/widgets/navigation/tree_view.lua` | 9 | Pixel snapping: `math.floor(x + 0.5)` | HIGH |
| `arkitekt/gui/widgets/primitives/spinner.lua` | 8 | Coordinate rounding | HIGH |
| `arkitekt/gui/widgets/primitives/slider.lua` | 1 | Value rounding | MEDIUM |
| `arkitekt/gui/widgets/primitives/corner_button.lua` | 2 | Layout calculations | MEDIUM |
| `arkitekt/gui/widgets/primitives/hue_slider.lua` | 1 | Pixel snapping | MEDIUM |
| `arkitekt/gui/widgets/data/selection_rectangle.lua` | 1+ | Rectangle snapping | MEDIUM |
| `arkitekt/gui/widgets/media/package_tiles/renderer.lua` | 1 | Image layout calculation | MEDIUM |
| `arkitekt/gui/widgets/navigation/tabs.lua` | 1 | Tab width calculation | LOW |
| `arkitekt/gui/widgets/navigation/menutabs.lua` | Uses local function | Already abstracted | LOW |

**Medium Priority:**
- `arkitekt/app/chrome/window.lua` - Has local `floor()` wrapper function
- `arkitekt/gui/widgets/base.lua` - Utility rounding function
- `arkitekt/debug/_console_widget.lua` - FPS calculation (cold path)

**✅ Acceptable (Has Local Caching):**
- `scripts/ItemPicker/services/visualization.lua` - Uses `local floor = math.floor` (3 occurrences)

---

### 3. Local Caching Headers ⚠️ **MINIMAL COVERAGE**

**Status:** ~8 files have explicit math function caching
**Impact:** 30% faster function calls in loops
**Effort:** Low (mechanical addition)

#### ✅ Already Cached:
- `scripts/RegionPlaylist/engine/playback.lua:6-7` - `local max, min = math.max, math.min`
- `scripts/ItemPicker/services/visualization.lua` - `local floor = math.floor` (multiple locations)
- `arkitekt/gui/rendering/tile/renderer.lua` - Exemplary (per TODO)
- `arkitekt/gui/draw.lua` - Local caching present

#### ❌ Missing Caching in Hot Paths:
1. **`arkitekt/gui/widgets/navigation/tree_view.lua`**
   - Needs: `local floor = math.floor` at top
   - Usage: 9 `math.floor` calls in rendering code

2. **`arkitekt/gui/widgets/primitives/spinner.lua`**
   - Needs: `local floor = math.floor`
   - Usage: 8 calls in draw functions

3. **`arkitekt/reaper/regions.lua`**
   - Needs: Check if REAPER API functions need caching in loops
   - Context: Region enumeration

4. **`scripts/RegionPlaylist/engine/core.lua`**
   - Has some optimization (direct indexing) but check for REAPER API caching needs

---

### 4. Review `pairs()` in GUI Hot Paths ⏸️ **DEFERRED**

**Status:** Not Analyzed (Low Priority per TODO)
**Recommendation:** Profile before optimizing
**Locations:** ~33 in `arkitekt/gui/`

---

### 5. String Concatenation in Loops ⏸️ **NOT ANALYZED**

**Status:** Needs Manual Audit
**Current:** 34 `table.concat` usages (good pattern)
**Files to Audit:**
- `arkitekt/debug/logger.lua`
- `scripts/*/storage/persistence.lua`

---

## 🔍 Additional Findings

### ✅ Already Optimized (No Action Needed)

| Pattern | Status | Evidence |
|---------|--------|----------|
| **String ID Caching** | ✅ Good | `arkitekt/gui/widgets/containers/grid/core.lua:164-166` |
| **Virtual List Mode** | ✅ Available | Grid widget supports virtual lists for 1000+ items |
| **Project State Detection** | ✅ Correct | Uses `GetProjectStateChangeCount(0)` properly |
| **Floor Division in Core** | ✅ Good | 47 `//1` usages in `arkitekt/core/` and `gui/draw/` |
| **Direct Indexing Examples** | ✅ Present | Some files already use `[#t + 1]` |

### 🎯 What's Working Well

1. **Hot rendering paths** already show optimization awareness
2. **Core modules** (colors, images, json) have been converted to `//1`
3. **Some files** demonstrate proper local caching patterns
4. **Documentation** includes performance comments

---

## 📋 Recommended Action Plan

### Phase 1: Quick Wins (Estimated: 2-4 hours)

**1A. Convert Remaining `math.floor` to `//1` in Widget Files**
- Priority files: `tree_view.lua`, `spinner.lua`, `slider.lua`, `corner_button.lua`
- Pattern: `math.floor(x + 0.5)` → `(x + 0.5) // 1`
- Can be done with careful regex find-replace

**1B. Add Local Caching Headers to Widget Files**
```lua
-- Add to top of files with math.floor usage:
local floor = math.floor  -- Or remove after converting to //1
local min, max = math.min, math.max
local abs = math.abs
```

### Phase 2: Systematic Cleanup (Estimated: 6-8 hours)

**2A. Convert `table.insert` - Priority Order:**
1. **GUI widgets** (99 occurrences) - Focus on hot-path files first
2. **RegionPlaylist** (48 occurrences) - Real-time engine
3. **ItemPicker** (38 occurrences) - Visualization and grids
4. **TemplateBrowser** (41 occurrences) - UI updates

**Regex pattern:**
```regex
Find:    table\.insert\((\w+),\s*([^)]+)\)
Replace: $1[#$1 + 1] = $2
```

⚠️ **WARNING:** This regex works for simple cases. **Manual review required** for:
- Multi-line arguments
- Complex expressions as second argument
- Table insert at specific position: `table.insert(t, 1, value)` (needs different handling)

**2B. Remaining `math.floor` Conversions**
- Work through remaining files systematically
- Test after each batch of changes
- Some `math.floor` in cold paths (startup) may be acceptable

### Phase 3: Profiling & Verification (Estimated: 2-3 hours)

**3A. Performance Testing**
```lua
local start = reaper.time_precise()
-- ... code to measure ...
local elapsed = reaper.time_precise() - start
reaper.ShowConsoleMsg(string.format("Elapsed: %.4fms\n", elapsed * 1000))
```

**3B. Targets:**
- Idle CPU < 1% ✅ OK
- Idle CPU 1-5% ⚠️ Monitor
- Idle CPU > 5% 🔴 Investigate

---

## 📈 Progress Metrics

| Metric | Before | Current | Target | Progress |
|--------|--------|---------|--------|----------|
| `math.floor` vs `//1` | Unknown | 334/182 (35%) | 10%/90% | **35% ✅** |
| `table.insert` vs `[#t+1]` | Unknown | 284/? (~77%?) | 20%/80% | **~23% ⚠️** |
| Local function caching | Unknown | ~8 files | All hot files | **~5% ⚠️** |

---

## 🚨 Risk Assessment

### Low Risk:
- Converting `math.floor` to `//1` (equivalent operations)
- Adding local caching headers (no logic change)

### Medium Risk:
- Batch `table.insert` replacement (test thoroughly)
- Watch for edge cases: `table.insert(t, position, value)` ← 3-argument form

### Watch For:
- **ThemeAdjuster** - Excluded (reference code)
- **Helper files** - Excluded (external)
- **Sandbox scripts** - Excluded (development)
- **Demo files** - Lower priority

---

## 🎯 Summary: Critical Path

### Must Do (High Impact):
1. ✅ **DONE:** Core modules (`colors.lua`, `images.lua`, `json.lua`, `pattern.lua`)
2. ⚠️ **IN PROGRESS:** Widget `math.floor` conversions (tree_view, spinner, slider)
3. ⚠️ **PENDING:** `table.insert` in GUI widgets and hot-path renderers
4. ⚠️ **PENDING:** Local caching headers in widgets with loops

### Should Do (Medium Impact):
5. ⚠️ **PENDING:** `table.insert` in RegionPlaylist, ItemPicker, TemplateBrowser
6. ⚠️ **PENDING:** Remaining `math.floor` in arkitekt core

### Nice to Have (Low Impact):
7. ⏸️ **DEFERRED:** Profile `pairs()` usage (only if performance issues arise)
8. ⏸️ **DEFERRED:** String concatenation audit (already using `table.concat` well)

---

## 📝 Notes for Implementation

### Conversion Safety Checklist:
- [ ] Read file first to understand context
- [ ] Check if it's in a hot path (rendering, engine updates)
- [ ] Test changes with REAPER scripts after conversion
- [ ] Look for 3-argument `table.insert(t, pos, val)` (different handling)
- [ ] Profile before/after in critical paths
- [ ] Commit in logical batches with clear messages

### Files to Handle with Care:
- `arkitekt/debug/logger.lua` - Logging system
- `scripts/RegionPlaylist/engine/*` - Real-time playback engine
- `arkitekt/gui/widgets/navigation/tree_view.lua` - Complex rendering logic
- Any file with `reaper.defer()` or `reaper.atexit()` loops

---

## 📊 Estimated Total Effort

| Phase | Effort | Impact |
|-------|--------|--------|
| Phase 1: Quick Wins | 2-4 hours | High (visible improvement) |
| Phase 2: Systematic Cleanup | 6-8 hours | High (comprehensive coverage) |
| Phase 3: Profiling | 2-3 hours | Medium (validation) |
| **TOTAL** | **10-15 hours** | **Target: 8.5/10 compliance** |

---

## Next Steps

1. **Start with Phase 1** - Widget `math.floor` conversions (immediate impact)
2. **Test thoroughly** - Run scripts in REAPER after each batch
3. **Commit incrementally** - Small, focused commits for easy rollback
4. **Profile critical paths** - Measure before declaring victory
5. **Update TODO/PERFORMANCE.md** - Revise estimates based on actual numbers

---

**Conclusion:** The codebase is **partially optimized** but has significant work remaining. Priority files are in good shape, but systematic cleanup of 284 `table.insert` calls and 334 `math.floor` calls is needed to reach target compliance. The scope is **~3x larger** than initially documented.
