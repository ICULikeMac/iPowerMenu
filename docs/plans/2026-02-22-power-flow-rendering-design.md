# Power Flow Line/Math Design

**Date:** 2026-02-22

## Problem
Power flow dots in both full and compact views do not reliably travel from one component circle to another, route math can be inconsistent when multiple origins contribute simultaneously, and dot color should reflect origin source. Dots must not animate for small flows.

## Goals
- Align animated-dot geometry with line geometry so dots visibly travel edge-to-edge between circles.
- Use a deterministic proportional flow model when multiple sources feed a destination.
- Use origin-based dot colors.
- Gate all animated flows at strictly greater than 20 watts.
- Apply identical logic to both full and compact power flow views.

## Flow Model
- Inputs:
  - `solarGeneration` (>= 0)
  - `gridPower` (>0 import, <0 export)
  - `batteryPower` (>0 charging, <0 discharging)
  - `homeDemand` (>= 0)
- Home allocation:
  - `solarToHome = min(solarGeneration, homeDemand)`
  - Remaining home demand is split proportionally by availability from battery discharge and grid import.
- Battery charging allocation:
  - Battery charging need is supplied first by solar excess, then grid import remainder.
- Grid export allocation:
  - Export is allocated proportionally from available solar excess and battery-discharge excess.
- A rendered route is emitted only when `watts > 20`.

## Visual/Path Model
- Keep existing node layout.
- Compute route endpoints by offsetting along direction vectors by view-appropriate circle radius (+ padding).
- Use shared curve-control-point computation for each curved route.
- Use the same geometry function for static line drawing and animated dots.

## Color Rules (Origin-Based)
- Solar-origin flow: orange
- Grid-origin flow: blue
- Battery-origin flow: fixed battery color (amber/yellow), independent of SOC.

## Validation
- Run unit tests for route math on representative scenarios:
  - Solar-only home supply
  - Mixed supply to home (proportional split)
  - Solar + grid battery charging split
  - Mixed-origin export split
  - Threshold gating at <= 20W
- Run package build/tests to verify integration.
- Manually check both views for edge-to-edge animation and origin-based colors.
