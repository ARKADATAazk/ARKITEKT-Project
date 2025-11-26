# ARKITEKT: Framework vs Component Library Analysis

**Date:** 2025-11-26
**Question:** Is ARKITEKT a framework or a widget/component library? What defines the boundary?

---

## Executive Summary

**Answer:** ARKITEKT is **BOTH** - a **hybrid architecture**

- **Framework layer** (Shell, bootstrap, window management) - controls your app
- **Component library layer** (widgets) - you control when to use

**The key distinction:**
> **"A library is something you call. A framework is something that calls you."**
> — Martin Fowler (Inversion of Control principle)

---

## 1. The Fundamental Distinction

### 1.1 Library (You're in control)

```lua
-- YOU control the flow
-- YOU call the library when YOU want

local button_lib = require('button_library')

function my_main_loop()
  -- I decide when to call this
  if button_lib.draw(ctx, "Click me") then
    handle_click()
  end

  -- I control everything
  reaper.defer(my_main_loop)
end

my_main_loop()
```

**Characteristics:**
- ✅ You call library functions
- ✅ You control application flow
- ✅ You manage lifecycle
- ✅ Library provides utilities
- ✅ You can use it partially (pick and choose)

**Examples:** jQuery, Lodash, date-fns, your widget modules IF used standalone

---

### 1.2 Framework (Framework is in control)

```lua
-- FRAMEWORK controls the flow
-- FRAMEWORK calls YOUR code

local framework = require('framework')

framework.run({
  -- Framework will call this function
  on_init = function()
    -- Framework decided WHEN to call this
  end,

  -- Framework manages the main loop
  draw = function(ctx)
    -- Framework calls this every frame
    -- YOU don't control WHEN
  end,

  -- Framework manages cleanup
  on_close = function()
    -- Framework calls this on shutdown
  end,
})

-- You're done! Framework is in control now.
-- You don't call reaper.defer() - framework does
```

**Characteristics:**
- ✅ Framework calls your code (inversion of control)
- ✅ Framework controls application flow
- ✅ Framework manages lifecycle
- ✅ You provide callbacks
- ✅ You must follow framework's structure

**Examples:** React, Angular, Django, Rails, your Shell.run()

---

## 2. Analyzing ARKITEKT's Architecture

### 2.1 The Framework Layer ⚙️

**Location:** `arkitekt/app/`

```lua
-- THIS IS A FRAMEWORK

local Shell = require('arkitekt.app.shell')

Shell.run({
  title = "My App",

  -- YOU provide callbacks
  -- SHELL decides when to call them
  draw = function(ctx, state)
    -- Shell calls this every frame
  end,

  on_close = function()
    -- Shell calls this on shutdown
  end,
})

-- You don't control the defer loop!
-- Shell does: reaper.defer(frame)
```

**Inversion of Control:**
- ✅ Shell controls the main loop
- ✅ Shell manages window lifecycle
- ✅ Shell handles errors (wraps defer with xpcall)
- ✅ Shell manages settings persistence
- ✅ You just provide callbacks

**This IS a Framework** because:
1. **You don't call `reaper.defer()`** - Shell does
2. **You don't manage window open/close** - Shell does
3. **You don't handle errors** - Shell wraps everything in xpcall
4. **You plug into Shell's structure** - you don't control it

---

### 2.2 The Component Library Layer 🧩

**Location:** `arkitekt/gui/widgets/`

```lua
-- THIS IS A LIBRARY

local ark = require('arkitekt')

function my_draw_function(ctx, state)
  -- YOU call widgets when YOU want
  ark.Button.draw(ctx, { label = "Save" })

  if some_condition then
    -- YOU decide whether to render this
    ark.Checkbox.draw(ctx, { label = "Enable" })
  end

  -- YOU control the flow
  for i = 1, count do
    ark.Panel.draw(ctx, { id = "panel_" .. i })
  end
end
```

**You're in Control:**
- ✅ You call `ark.Button.draw()` when you want
- ✅ You decide which widgets to use
- ✅ You control rendering order
- ✅ You can skip widgets conditionally
- ✅ Widgets don't call you back (except optional callbacks)

**This IS a Library** because:
1. **You call widget functions** - they don't call you
2. **You control when/if widgets render**
3. **You can use widgets in isolation** (without Shell)
4. **Widgets are passive** - they just draw and return results

---

### 2.3 Hybrid Architecture Diagram

```
┌─────────────────────────────────────────────┐
│  YOUR CODE                                  │
│  - Business logic                           │
│  - Data models                              │
│  - Event handlers                           │
└─────────────────┬───────────────────────────┘
                  │
                  │ You provide callbacks
                  ↓
┌─────────────────────────────────────────────┐
│  FRAMEWORK LAYER (Inversion of Control)     │
│  ┌─────────────────────────────────────┐   │
│  │ Shell.run()                         │   │
│  │ - Main loop (reaper.defer)          │   │
│  │ - Window lifecycle                  │   │
│  │ - Error handling (xpcall)           │   │
│  │ - Settings persistence              │   │
│  │ - Font loading                      │   │
│  │ - Theme initialization              │   │
│  └─────────────────────────────────────┘   │
│                                             │
│  Shell calls YOUR draw() function ─────────┤
│                                             │
└─────────────────┬───────────────────────────┘
                  │
                  │ Your draw() calls widgets
                  ↓
┌─────────────────────────────────────────────┐
│  COMPONENT LIBRARY LAYER (You Control)      │
│  ┌─────────────────────────────────────┐   │
│  │ ark.Button.draw()                   │   │
│  │ ark.Panel.draw()                    │   │
│  │ ark.Checkbox.draw()                 │   │
│  │ ark.Slider.draw()                   │   │
│  │ ... (50+ widgets)                   │   │
│  └─────────────────────────────────────┘   │
│                                             │
│  Widgets return results to YOU ─────────────┤
│                                             │
└─────────────────┬───────────────────────────┘
                  │
                  │ Widgets use utilities
                  ↓
┌─────────────────────────────────────────────┐
│  UTILITY LAYER (Library)                    │
│  - Colors                                   │
│  - Animation                                │
│  - Draw helpers                             │
│  - Math utilities                           │
└─────────────────────────────────────────────┘
                  │
                  ↓
┌─────────────────────────────────────────────┐
│  ReaImGui (Raw ImGui binding)               │
└─────────────────────────────────────────────┘
```

---

## 3. Concrete Examples

### 3.1 Using ARKITEKT as a Framework

```lua
-- FRAMEWORK USAGE (recommended)

local Shell = require('arkitekt.app.shell')
local ark = require('arkitekt')

Shell.run({
  title = "My App",
  version = "1.0.0",

  -- Framework calls this
  draw = function(ctx, state)
    -- You call library components
    ark.Button.draw(ctx, { label = "Save" })
  end,
})

-- Framework is in control:
-- - Shell manages defer loop
-- - Shell manages window
-- - Shell handles errors
-- - You just provide draw()
```

**This is using ARKITEKT as:**
- ✅ Framework (Shell layer)
- ✅ Component library (widget layer)

---

### 3.2 Using ARKITEKT as a Library Only

```lua
-- LIBRARY-ONLY USAGE (possible but not recommended)

local ImGui = require('imgui') '0.10'
local ark = require('arkitekt')

local ctx = ImGui.CreateContext('My App')

-- YOU control the main loop (not Shell)
local function my_main_loop()
  local visible, open = ImGui.Begin(ctx, 'My Window', true)

  if visible then
    -- Use widgets as a library
    ark.Button.draw(ctx, { label = "Save" })
    ark.Checkbox.draw(ctx, { label = "Enable" })

    ImGui.End(ctx)
  end

  if open then
    reaper.defer(my_main_loop)
  end
end

reaper.defer(my_main_loop)

-- You're in control:
-- - You manage defer loop
-- - You manage window
-- - You handle errors
-- - You just call widgets
```

**This is using ARKITEKT as:**
- ❌ Framework (not using Shell)
- ✅ Component library (widget layer only)

**Trade-offs:**
- ✅ More control
- ❌ More boilerplate
- ❌ No error handling
- ❌ No settings persistence
- ❌ No automatic font loading

---

## 4. Where is the Boundary?

### 4.1 Framework Characteristics in ARKITEKT

**These parts ARE a framework:**

| Component | Inversion of Control? | Manages Lifecycle? | Framework? |
|-----------|----------------------|-------------------|-----------|
| `Shell.run()` | ✅ Yes (calls your draw) | ✅ Yes (defer loop) | ✅ **YES** |
| `bootstrap.lua` | ✅ Yes (auto-runs on require) | ✅ Yes (package paths) | ✅ **YES** |
| Window chrome | ✅ Yes (calls your content) | ✅ Yes (window lifecycle) | ✅ **YES** |
| Error handling | ✅ Yes (wraps your code) | ✅ Yes (xpcall defer) | ✅ **YES** |
| Settings | ✅ Yes (auto-flush) | ✅ Yes (persistence) | ✅ **YES** |

---

### 4.2 Library Characteristics in ARKITEKT

**These parts ARE a library:**

| Component | You Call It? | You Control Flow? | Library? |
|-----------|-------------|------------------|----------|
| `ark.Button.draw()` | ✅ Yes | ✅ Yes | ✅ **YES** |
| `ark.Panel.draw()` | ✅ Yes | ✅ Yes | ✅ **YES** |
| `ark.Checkbox.draw()` | ✅ Yes | ✅ Yes | ✅ **YES** |
| `Colors.hexrgb()` | ✅ Yes | ✅ Yes | ✅ **YES** |
| `Draw.rect()` | ✅ Yes | ✅ Yes | ✅ **YES** |
| `Style.COLORS.*` | ✅ Yes | ✅ Yes | ✅ **YES** |

---

## 5. Comparison with Famous Projects

### 5.1 React (Framework)

**React:**
```jsx
// Framework controls rendering
ReactDOM.render(
  <App />,  // React calls your component
  document.getElementById('root')
)

function App() {
  // React calls this when it wants
  return <button>Click</button>
}
```

**ARKITEKT equivalent:**
```lua
Shell.run({
  draw = function(ctx, state)  -- Shell calls this when it wants
    ark.Button.draw(ctx, { label = "Click" })
  end,
})
```

**Similarity:** ✅ Both use inversion of control

---

### 5.2 Material-UI (Component Library)

**Material-UI:**
```jsx
import Button from '@mui/material/Button'

function MyComponent() {
  // YOU control when to render Button
  return (
    <div>
      <Button>Click</Button>
      {condition && <Button>Conditional</Button>}
    </div>
  )
}
```

**ARKITEKT equivalent:**
```lua
function draw(ctx, state)
  -- YOU control when to render Button
  ark.Button.draw(ctx, { label = "Click" })

  if condition then
    ark.Button.draw(ctx, { label = "Conditional" })
  end
end
```

**Similarity:** ✅ Both provide components you call

---

### 5.3 Next.js (Framework + Library)

**Next.js:**
- **Framework:** Routing, SSR, API routes (you plug into their structure)
- **Library:** React components (you call them)

**ARKITEKT:**
- **Framework:** Shell.run(), window chrome, lifecycle (you plug in)
- **Library:** Widgets (you call them)

**Similarity:** ✅ Both are hybrid (framework + library)

---

## 6. Defining the Boundary

### 6.1 The Litmus Test

**"Is X a framework or library?"**

Ask these questions:

| Question | Framework | Library |
|----------|-----------|---------|
| **Who calls who?** | It calls you | You call it |
| **Who controls main loop?** | It does | You do |
| **Who manages lifecycle?** | It does | You do |
| **Can you skip using it?** | No (all or nothing) | Yes (pick and choose) |
| **Inversion of control?** | Yes | No |

---

### 6.2 Applied to ARKITEKT

**Shell.run():**
- Who calls who? **Shell calls your draw()** ✅ Framework
- Who controls main loop? **Shell does** ✅ Framework
- Who manages lifecycle? **Shell does** ✅ Framework
- Can you skip it? **No (need Shell or roll your own)** ✅ Framework
- Inversion of control? **Yes** ✅ Framework

**ark.Button.draw():**
- Who calls who? **You call Button** ✅ Library
- Who controls flow? **You do** ✅ Library
- Who decides if it renders? **You do** ✅ Library
- Can you skip it? **Yes (use different widget)** ✅ Library
- Inversion of control? **No** ✅ Library

---

## 7. Why Does This Matter?

### 7.1 For Marketing/Documentation

**Call it the right thing:**

❌ **Wrong:**
> "ARKITEKT is a widget library for REAPER"

✅ **Better:**
> "ARKITEKT is a GUI framework and component library for REAPER"

✅ **Best:**
> "ARKITEKT is a GUI framework for REAPER that includes a comprehensive component library with 50+ professionally designed widgets"

---

### 7.2 For Users Understanding What They're Getting

**Framework benefits:**
- ✅ Less boilerplate (Shell manages everything)
- ✅ Best practices enforced (error handling, settings)
- ✅ Consistent structure (all ARKITEKT apps work the same)
- ❌ Less control (must follow Shell's patterns)

**Library benefits:**
- ✅ More control (use what you want)
- ✅ Can integrate piecemeal (just use Button, not Shell)
- ✅ Lighter weight (only load what you need)
- ❌ More boilerplate (manual defer loop, error handling)

**ARKITEKT gives you BOTH:**
- Use the framework (Shell) for full-featured apps
- Use the library (widgets) if you have your own framework

---

### 7.3 For Competitive Positioning

**Similar projects:**

| Project | Type | Notes |
|---------|------|-------|
| **Dear ImGui** | Library | Just widgets, no application framework |
| **egui (Rust)** | Framework | Controls main loop like Shell.run() |
| **React** | Framework | Manages rendering, you provide components |
| **Material-UI** | Library | Just components, use with React |
| **Next.js** | Framework + Library | Routing (framework) + React (library) |
| **ARKITEKT** | Framework + Library | Shell (framework) + Widgets (library) |

**Your competitive advantage:**
- ✅ More complete than Dear ImGui (framework + library)
- ✅ More flexible than egui (can use widgets standalone)
- ✅ Similar architecture to Next.js (hybrid approach)

---

## 8. Recommendations

### 8.1 Documentation Structure

Structure your docs to reflect the hybrid nature:

```
ARKITEKT Documentation
├── Getting Started
│   ├── Quick Start (using Shell framework)
│   └── Library-Only Usage (advanced)
├── Framework Guide
│   ├── Shell.run() API
│   ├── Application Lifecycle
│   ├── Settings Management
│   └── Error Handling
├── Component Library
│   ├── Button
│   ├── Checkbox
│   ├── Panel
│   └── ... (all widgets)
└── Advanced
    ├── Custom Widgets
    └── Using Without Shell
```

---

### 8.2 Naming Conventions

**Clear naming helps users understand:**

✅ **Good:**
```lua
-- Framework API
Shell.run(config)
Shell.run_overlay(config)

-- Library API
ark.Button.draw(ctx, opts)
ark.Panel.draw(ctx, opts)
```

❌ **Confusing:**
```lua
-- Mixed metaphors
ark.run()  -- Is this framework or library?
Shell.button()  -- Is Shell a widget collection?
```

**Your current naming is EXCELLENT** - clear separation:
- `Shell.run()` - obviously framework
- `ark.Button.draw()` - obviously library

---

### 8.3 Marketing Message

**Elevator pitch:**

> "ARKITEKT is a **GUI framework** for REAPER that includes a **comprehensive component library**. Use the framework for rapid development with best practices built-in, or use the component library standalone for maximum flexibility."

**Key points:**
1. **Framework first** - most users will use Shell.run()
2. **Component library second** - advanced users can go library-only
3. **Flexibility** - you can choose your level of framework usage

---

## 9. Spectrum of Framework vs Library

```
Pure Library          Hybrid              Pure Framework
     │                  │                       │
     ↓                  ↓                       ↓
┌─────────┐      ┌───────────┐         ┌──────────┐
│ Lodash  │      │ ARKITEKT  │         │ Rails    │
│ jQuery  │      │ Next.js   │         │ Angular  │
│ React   │      │ Nuxt      │         │ Ember    │
│ (comp)  │      │           │         │          │
└─────────┘      └───────────┘         └──────────┘

You call it       You call widgets      It calls you
Pick & choose     It calls your draw    All or nothing
No structure      Structured apps       Opinionated
```

**ARKITEKT sits in the middle:**
- Leans framework (Shell.run() is the recommended way)
- But allows library-only usage (widgets standalone)

---

## 10. Summary

### 10.1 What ARKITEKT Is

**Hybrid Architecture:**

1. **Framework Layer** (30% of codebase)
   - `Shell.run()` - application runner
   - `bootstrap.lua` - dependency validation
   - `Window` - chrome management
   - **Inversion of control:** ✅ Yes

2. **Component Library Layer** (60% of codebase)
   - `ark.Button`, `ark.Panel`, etc. - 50+ widgets
   - `Colors`, `Draw`, `Style` - utilities
   - **Inversion of control:** ❌ No (you call them)

3. **Utility Layer** (10% of codebase)
   - Pure functions (math, colors, etc.)
   - No side effects
   - **Definitely a library**

---

### 10.2 The Boundary

**Framework = Inversion of Control**
- The code calls your code
- You provide callbacks
- It manages lifecycle

**Library = Direct Control**
- Your code calls the library
- You control flow
- Library is passive

**ARKITEKT has BOTH:**
- Shell is a framework (it calls you)
- Widgets are a library (you call them)

---

### 10.3 How to Describe ARKITEKT

**Short version:**
> "A GUI framework for REAPER"

**Medium version:**
> "A GUI framework and component library for REAPER"

**Long version:**
> "ARKITEKT is a comprehensive GUI framework for REAPER that provides application scaffolding (Shell.run) and a rich component library (50+ widgets) with professional theming, animations, and state management"

**Technical version:**
> "ARKITEKT is a hybrid framework/library: the Shell layer provides inversion of control for application lifecycle management, while the widget layer provides a library of 50+ reusable components"

---

## 11. Final Answer

**Q: Is ARKITEKT a framework or a widget/component library?**

**A: Both! It's a hybrid.**

- **Framework:** Shell.run() (recommended usage)
- **Library:** Widgets (can be used standalone)

**The boundary:**
- Framework = calls your code (inversion of control)
- Library = you call its code (direct control)

**Most users will use it as a framework** (Shell.run), but advanced users can use just the widget library if they have their own application framework.

---

**END OF ANALYSIS**

Generated: 2025-11-26
Classification: Hybrid Framework + Component Library
Similar to: Next.js, Nuxt, Ruby on Rails (with component libraries)
