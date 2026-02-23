# V2X Flow And Negative Pricing Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add Car/V2X as a first-class power source/sink, switch flow allocation to no-priority proportional routing, support negative price formatting, and remove static circle-to-circle path lines.

**Architecture:** Extend entity/config models with a single net `carPower` sensor and feed it into shared flow math. Replace previous implicit route assumptions with proportional source allocation across Solar/Battery/Car/Grid for all sinks. Keep dot animation and color origin mapping, but remove static path line rendering.

**Tech Stack:** Swift, SwiftUI, Swift Package Manager tests

---

### Task 1: Add Failing Tests For 4-Source Math And Price Parsing

**Files:**
- Modify: `Tests/HomeAssistantMenuBarTests/PowerFlowMathTests.swift`
- Create: `Tests/HomeAssistantMenuBarTests/CurrencyFormattingTests.swift`

**Step 1: Write failing tests**
- Add tests for proportional home allocation using Solar/Battery/Car/Grid.
- Add tests for proportional charging allocation into battery/car from available sources.
- Add tests for grid export attribution including car source.
- Add tests for signed/annotated currency strings like `-$0.051`, `$-0.051`, `-0.051 /kWh`.

**Step 2: Run tests to verify failure**
Run: `swift test`
Expected: failures for missing `carPower` support and missing robust currency parsing helper.

### Task 2: Implement Shared Math/Formatting Updates

**Files:**
- Modify: `Sources/HomeAssistantMenuBar/PowerFlowMath.swift`
- Create: `Sources/HomeAssistantMenuBar/CurrencyFormatting.swift`
- Modify: `Sources/HomeAssistantMenuBar/MenuBarController.swift`

**Step 1: Implement 4-source no-priority flow math**
- Add `car` node/origin support.
- Add `carPower` input to route calculator.
- Allocate all sinks proportionally from currently available sources.
- Preserve `watts > 20` route gate.

**Step 2: Implement robust signed currency parsing/formatting**
- Parse signed values from decorated strings.
- Format negative values as `-$0.000/kWh`.
- Update menu formatter to use helper.

**Step 3: Run tests**
Run: `swift test`
Expected: new and existing tests pass.

### Task 3: Wire Car Entity Into Settings/UI/Data Pipeline

**Files:**
- Modify: `Sources/HomeAssistantMenuBar/Settings.swift`
- Modify: `Sources/HomeAssistantMenuBar/SettingsWindow.swift`
- Modify: `Sources/HomeAssistantMenuBar/PowerFlowView.swift`
- Modify: `Sources/HomeAssistantMenuBar/CompactPowerFlowView.swift`

**Step 1: Add `carPower` entity plumbing**
- Extend enum/properties/default IDs/getter-setter.
- Add settings row for Car/V2X entity.

**Step 2: Use `carPower` in full/compact flow models**
- Parse car value from entity map.
- Pass into shared flow calculator.
- Add car component node in both views.

**Step 3: Run tests/build**
Run: `swift test`
Expected: pass.

### Task 4: Remove Static Path Lines And Keep Dot-Only Flow

**Files:**
- Modify: `Sources/HomeAssistantMenuBar/PowerFlowView.swift`
- Modify: `Sources/HomeAssistantMenuBar/CompactPowerFlowView.swift`
- Modify: `Sources/HomeAssistantMenuBar/PowerFlowRenderingSupport.swift`

**Step 1: Remove static line rendering**
- Stop drawing static connection paths in both views.

**Step 2: Ensure segment builder supports required dynamic routes**
- Allow dot segments for all route pairs that may appear with car source/sink.

**Step 3: Run tests**
Run: `swift test`
Expected: pass.

### Task 5: Final Verification

**Files:**
- No additional file edits required unless failures found

**Step 1: Full verification run**
Run: `swift test`
Expected: all tests pass.

**Step 2: Manual scenario sanity checks**
- `solar=0, grid>0, home>0` yields grid-origin home dot.
- Negative prices render with sign and not placeholders.
- No static path lines visible.

