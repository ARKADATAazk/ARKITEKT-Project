# Performance Optimization Trade-offs

## TL;DR: Optimize Hot Paths, Leave Cold Paths Readable

**Rule of Thumb:** Only optimize code that runs frequently. Readability often trumps micro-optimization.

---

## The Two Optimizations Analyzed

### 1. `table.insert(t, value)` → `t[#t + 1] = value`

#### Performance Gain:
- **Eliminates function call overhead** (~10-30% faster depending on context)
- Most noticeable in tight loops or per-frame operations

#### Downsides of Optimization:
| Aspect | `table.insert(t, v)` | `t[#t + 1] = v` |
|--------|---------------------|------------------|
| **Readability** | ✅ Clear intent: "append to array" | ⚠️ Less obvious to newcomers |
| **Maintainability** | ✅ Standard library = familiar | ⚠️ Requires comment for clarity |
| **Safety** | ✅ Well-tested stdlib function | ✅ Equivalent for append |
| **Edge Cases** | Handles `table.insert(t, pos, v)` | Need separate handling for insert-at-position |
| **Performance** | ⚠️ Function call overhead | ✅ Direct operation |

#### When to Keep `table.insert`:
```lua
-- ✅ KEEP in cold paths (startup, config loading)
function load_config()
  local plugins = {}
  for line in io.lines("config.txt") do
    table.insert(plugins, line)  -- Runs once at startup - readability wins
  end
end

-- ✅ KEEP when inserting at specific position
table.insert(history, 1, new_item)  -- Insert at beginning

-- ✅ KEEP in rarely-called code
function on_user_click_settings()
  local options = {}
  table.insert(options, "Option A")  -- Called once per user action - fine
end
```

#### When to Replace:
```lua
-- ⚠️ REPLACE in hot paths (every frame)
function render_tiles(items)
  local visible = {}
  for i = 1, #items do
    if items[i].visible then
      visible[#visible + 1] = items[i]  -- Called 60 times/sec - optimize
    end
  end
end

-- ⚠️ REPLACE in tight loops processing large datasets
function process_audio_items(project)
  local results = {}
  for i = 0, reaper.CountMediaItems(project) - 1 do
    local item = reaper.GetMediaItem(project, i)
    results[#results + 1] = process(item)  -- Could be 1000+ items
  end
end
```

---

### 2. `math.floor(x)` → `x // 1`

#### Performance Gain:
- **5-10% CPU reduction** in loops with many floor operations
- Built-in operator vs function call + lookup

#### Downsides of Optimization:
| Aspect | `math.floor(x)` | `x // 1` |
|--------|-----------------|----------|
| **Readability** | ✅ Self-documenting | ⚠️ Less obvious (floor division by 1?) |
| **Familiarity** | ✅ Universal across languages | ⚠️ Lua 5.3+ specific syntax |
| **Negative Numbers** | ✅ Clear behavior | ✅ Same behavior (rounds toward -∞) |
| **Performance** | ⚠️ Function call | ✅ Native operator |
| **Precision** | ✅ Works with math. functions | ✅ Equivalent |

#### When to Keep `math.floor`:
```lua
-- ✅ KEEP in cold paths
function calculate_grid_size(available_space, item_count)
  local cols = math.floor(math.sqrt(item_count))  -- Called once on resize - readable
  return cols, math.ceil(item_count / cols)
end

-- ✅ KEEP in documentation/teaching code
-- Example: helpers/ReaImGui_Demo.lua - prioritizes clarity for learners

-- ✅ KEEP when already cached locally
local floor = math.floor  -- At top of file
local function snap(x)
  return floor(x + 0.5)  -- No performance penalty, readable
end
```

#### When to Replace:
```lua
-- ⚠️ REPLACE in per-frame rendering
function draw_grid(draw_list, x, y, w, h)
  local snap_x = (x + 0.5) // 1  -- Called 60 times/sec per tile
  local snap_y = (y + 0.5) // 1
  r.ImGui_DrawList_AddRect(draw_list, snap_x, snap_y, w, h)
end

-- ⚠️ REPLACE in tight loops
function convert_colors(pixels)
  for i = 1, #pixels do
    local r = (pixels[i].r * 255) // 1  -- 1000+ iterations
    local g = (pixels[i].g * 255) // 1
    local b = (pixels[i].b * 255) // 1
  end
end
```

---

## Decision Framework

### Priority Matrix

| Code Location | Frequency | Action | Reason |
|---------------|-----------|--------|--------|
| **GUI Rendering** (draw functions) | Every frame (60 FPS) | ✅ **OPTIMIZE** | High impact |
| **Event Handlers** (mouse, keyboard) | Per user action (~1-10/sec) | ⚠️ **MAYBE** | Low impact, consider readability |
| **Engine Updates** (playback, monitoring) | Every defer cycle (~30 FPS) | ✅ **OPTIMIZE** | Medium-high impact |
| **Data Processing** (region scans, item loops) | Variable (10-1000+ items) | ✅ **OPTIMIZE** if >100 items | Scales with project size |
| **Startup/Init** (config, module loading) | Once per script launch | ❌ **SKIP** | Zero impact, keep readable |
| **User Actions** (save, load, export) | Rare (~1/min) | ❌ **SKIP** | Zero impact |

### Quantify with Profiling

```lua
-- Add to suspected hot paths:
local start = reaper.time_precise()
-- ... code block ...
local elapsed = reaper.time_precise() - start
if elapsed > 0.001 then  -- If > 1ms, worth optimizing
  reaper.ShowConsoleMsg(string.format("Hotspot: %.4fms\n", elapsed * 1000))
end
```

---

## Recommended Strategy

### Phase 1: High-Value Targets Only
Focus on files that are **proven hot paths**:

1. ✅ `arkitekt/gui/widgets/*/` - Rendered every frame
2. ✅ `arkitekt/gui/draw/` - Core drawing functions
3. ✅ `scripts/RegionPlaylist/engine/` - Real-time playback
4. ✅ `scripts/*/ui/grids/` - Tile rendering with many items
5. ✅ Files with explicit "Performance:" comments

### Phase 2: Leave These Alone
Files where optimization **doesn't matter**:

1. ❌ `arkitekt/debug/` - Logging (cold path)
2. ❌ `*/storage/persistence.lua` - Save/load (rare)
3. ❌ `*/config/` - Configuration (startup only)
4. ❌ `helpers/` - Example/demo code (clarity over speed)
5. ❌ `*/domain/undo.lua` - Undo history (infrequent)

### Phase 3: Profile-Driven
For anything in between:

```bash
# Profile a script in REAPER with large project
# If idle CPU < 1% → don't optimize
# If idle CPU > 5% → profile and optimize hot spots
```

---

## Concrete Recommendations for ARKITEKT

### ✅ DO OPTIMIZE:

**1. Widget Rendering (High Traffic)**
- `arkitekt/gui/widgets/navigation/tree_view.lua` - 9 `math.floor` calls
- `arkitekt/gui/widgets/primitives/spinner.lua` - 8 `math.floor` calls
- `arkitekt/gui/widgets/primitives/slider.lua` - Value rounding
- `arkitekt/gui/widgets/media/package_tiles/renderer.lua` - 23 `table.insert` calls

**2. Real-time Engine (Critical Path)**
- `scripts/RegionPlaylist/engine/*` - Playback engine (already well-optimized)
- `scripts/RegionPlaylist/ui/tiles/coordinator_render.lua` - Per-frame updates

**3. Large Dataset Processing**
- `scripts/ItemPicker/services/visualization.lua` - Already has `local floor = math.floor` ✅
- `scripts/TemplateBrowser/ui/views/tree_view.lua` - 21 `table.insert` in loops

### ❌ SKIP OPTIMIZATION:

**1. Cold Paths**
- `arkitekt/debug/logger.lua` - Only logs errors
- `arkitekt/app/chrome/status_bar.lua` - Updated infrequently
- `scripts/*/storage/sws_importer.lua` - Runs once on import

**2. Already Fast Enough**
- `arkitekt/arkitekt/reaper/regions.lua` - REAPER API is bottleneck, not Lua
- `scripts/RegionPlaylist/domains/playlist.lua` - Data model (not called in loops)

**3. Readability Matters More**
- `scripts/demos/demo*.lua` - Teaching examples
- `helpers/ReaImGui_Demo.lua` - Reference code
- Undo/history management (clarity over speed)

---

## The 80/20 Rule

**80% of performance impact comes from 20% of the code.**

### Estimated Impact by Category:

| Optimization Area | Files | Impact | Effort |
|-------------------|-------|--------|--------|
| **GUI Widget Rendering** | ~15 files | 🔥🔥🔥 HIGH | 2-3 hours |
| **RegionPlaylist Engine** | ~7 files | 🔥🔥 MEDIUM | Already mostly done ✅ |
| **ItemPicker Grids** | ~10 files | 🔥 LOW-MEDIUM | 1-2 hours |
| **TemplateBrowser UI** | ~12 files | 🔥 LOW-MEDIUM | 1-2 hours |
| **Core ARKITEKT** (non-GUI) | ~30 files | ❄️ NEGLIGIBLE | Skip |
| **Debug/Config/Storage** | ~20 files | ❄️ NONE | Skip |

**Recommendation:** Focus on the **15 GUI widget files** for maximum return on investment.

---

## Final Answer to "Should We Replace Everywhere?"

### ✅ YES - Replace in These:
- Anything in `arkitekt/gui/widgets/` that does pixel math or rendering
- `scripts/*/ui/grids/` and tile renderers
- Files with loops processing 100+ items
- Code with explicit performance comments

### ❌ NO - Keep Readable in These:
- Startup/initialization code
- Debug/logging utilities
- Storage/persistence (save/load)
- Domain models and business logic
- Demo/example code
- Anything called < 10 times per second

### 🤔 PROFILE FIRST - For These:
- Event handlers (user clicks, keyboard)
- Data model updates
- Undo/redo operations
- Non-rendering engine code

---

## Measuring Success

### Before Optimization:
```lua
-- In main script loop
local frames = 0
local start = reaper.time_precise()

function main()
  frames = frames + 1
  if frames % 600 == 0 then  -- Every 10 seconds
    local elapsed = reaper.time_precise() - start
    local avg_fps = frames / elapsed
    reaper.ShowConsoleMsg(string.format("Avg FPS: %.2f\n", avg_fps))
  end
  reaper.defer(main)
end
```

### Target Goals:
- **60 FPS** for smooth UI = 16.7ms per frame
- **Idle CPU < 1%** when no playback
- **< 5% CPU** during playback with large projects

---

## Bottom Line

**Optimize hot paths ruthlessly. Leave cold paths readable.**

The codebase already shows good instincts (hot rendering paths are optimized). Now just need to:
1. Complete the widget optimization (high value)
2. Skip the cold path files (low value)
3. Profile anything uncertain

Would save ~8 hours of work by skipping files that don't matter.
