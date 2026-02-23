# Power Flow Rendering Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make full and compact power flow dots follow correct circle-to-circle paths, use proportional source math, color dots by origin source, and suppress animation for flows <= 20W.

**Architecture:** Introduce a shared pure flow-calculation model to compute directed source-to-destination routes. Reuse shared path geometry helpers so static lines and animated dots are generated from identical endpoint/control-point calculations. Keep existing UI layout and component visuals.

**Tech Stack:** Swift, SwiftUI, Swift Package Manager tests

---

### Task 1: Add Failing Math Tests (TDD Red)

**Files:**
- Modify: `Package.swift`
- Create: `Tests/HomeAssistantMenuBarTests/PowerFlowMathTests.swift`

**Step 1: Write failing tests**
- Add tests that reference a not-yet-existing shared flow calculator:
  - proportional home split
  - charging split (solar then grid)
  - export split (solar/battery proportional)
  - threshold exclusion at <= 20W

**Step 2: Run tests to verify failure**
Run: `swift test`
Expected: compile/test failure because shared calculator types/functions do not exist yet.

### Task 2: Implement Shared Flow Math (TDD Green)

**Files:**
- Create: `Sources/HomeAssistantMenuBar/PowerFlowMath.swift`

**Step 1: Add minimal implementation**
- Create route model and pure calculator that:
  - computes directed flows from inputs
  - allocates proportionally as designed
  - filters routes to `watts > 20`
  - exposes origin-based dot color mapping token/enum

**Step 2: Run tests to verify pass**
Run: `swift test`
Expected: all new tests pass.

### Task 3: Share Geometry And Wire Full View

**Files:**
- Modify: `Sources/HomeAssistantMenuBar/PowerFlowView.swift`

**Step 1: Introduce shared path geometry helpers**
- Define helper(s) for circle-edge adjusted endpoints and optional quadratic control points.
- Use helpers for both static lines and moving-dot path sampling.

**Step 2: Replace ad hoc flow conditions**
- Build flow routes using shared calculator output.
- Render one animated indicator per route using route origin color.
- Keep existing layout and line topology.

**Step 3: Verify build/tests**
Run: `swift test`
Expected: pass.

### Task 4: Wire Compact View To Shared Math/Geometry

**Files:**
- Modify: `Sources/HomeAssistantMenuBar/CompactPowerFlowView.swift`

**Step 1: Reuse shared calculator + geometry rules**
- Replace compact ad hoc route conditions with calculator routes.
- Ensure compact routes use same origin colors and >20W threshold behavior.

**Step 2: Verify build/tests**
Run: `swift test`
Expected: pass.

### Task 5: Final Verification

**Files:**
- No additional file edits required unless failures found

**Step 1: Full verification run**
Run: `swift test`
Expected: all tests pass, no regressions.

**Step 2: Manual scenario check via previews/runtime**
- Confirm dots originate/terminate at circle boundaries.
- Confirm color origin mapping and threshold gating in both views.

