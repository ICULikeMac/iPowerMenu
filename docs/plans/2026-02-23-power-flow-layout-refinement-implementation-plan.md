# Power Flow Layout Refinement Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Refine the graph layout to remove Car circle, add dotted connectors, and stop dot-circle overlap.

**Architecture:** Keep shared proportional flow math unchanged, but restrict renderable nodes to Solar/Grid/Battery/Home. Reintroduce shared static connector rendering as dashed lines. Increase shared endpoint padding so moving dots remain outside circle strokes.

**Tech Stack:** Swift, SwiftUI, Swift Package Manager tests

---

### Task 1: Add Failing Rendering-Support Tests

**Files:**
- Create: `Tests/HomeAssistantMenuBarTests/PowerFlowRenderingSupportTests.swift`

**Step 1: Write failing test**
- Assert segment exists for visible pair (solar->home).
- Assert segment is nil for hidden car-node pair (car->home).

**Step 2: Run tests to verify red**
Run: `swift test`

### Task 2: Implement Layout/Connector Changes

**Files:**
- Modify: `Sources/HomeAssistantMenuBar/PowerFlowRenderingSupport.swift`
- Modify: `Sources/HomeAssistantMenuBar/PowerFlowView.swift`
- Modify: `Sources/HomeAssistantMenuBar/CompactPowerFlowView.swift`

**Steps:**
- Remove car center from graph layout.
- Restore static connector drawing helper for visible node edges.
- Render dotted connectors in full and compact views.
- Increase endpoint padding in full/compact layout values.
- Remove Car circle components from full and compact component layouts.

### Task 3: Verify

**Step 1:** Run `swift test`.
**Step 2:** Confirm no warnings/failures.
