import SwiftUI

struct PowerFlowLayout {
    let size: CGSize
    let circleRadius: CGFloat
    let padding: CGFloat
    let curveScale: CGFloat
    let minCurve: CGFloat
    let maxCurve: CGFloat
    let centerYOffset: CGFloat
    /// Vertical offset from the VStack center (set by .position()) to the actual circle center.
    /// Negative because the circle sits at the top of the VStack, above center.
    let circleCenterYOffset: CGFloat

    init(
        size: CGSize,
        circleRadius: CGFloat,
        padding: CGFloat,
        curveScale: CGFloat,
        minCurve: CGFloat,
        maxCurve: CGFloat,
        centerYOffset: CGFloat = 0,
        circleCenterYOffset: CGFloat = 0
    ) {
        self.size = size
        self.circleRadius = circleRadius
        self.padding = padding
        self.curveScale = curveScale
        self.minCurve = minCurve
        self.maxCurve = maxCurve
        self.centerYOffset = centerYOffset
        self.circleCenterYOffset = circleCenterYOffset
    }

    var nodeCenters: [PowerFlowNode: CGPoint] {
        let dy = circleCenterYOffset
        return [
            .solar: CGPoint(x: size.width * 0.5, y: size.height * 0.2 + dy),
            .grid: CGPoint(x: size.width * 0.2, y: size.height * 0.5 + dy),
            .home: CGPoint(x: size.width * 0.8, y: size.height * 0.5 + dy),
            .battery: CGPoint(x: size.width * 0.5, y: size.height * 0.8 + dy)
        ]
    }

    var center: CGPoint {
        CGPoint(x: size.width * 0.5, y: size.height * 0.5)
    }

    var visibleEdges: [(PowerFlowNode, PowerFlowNode)] {
        [
            (.solar, .grid),
            (.solar, .home),
            (.solar, .battery),
            (.grid, .home),
            (.grid, .battery),
            (.battery, .home)
        ]
    }
}

struct PowerFlowSegment {
    let start: CGPoint
    let end: CGPoint
    let control: CGPoint?
}

// MARK: - Edge Classification

private enum EdgeType {
    case centerVertical
    case centerHorizontal
    case diagonal
}

private func classifyEdge(from: PowerFlowNode, to: PowerFlowNode) -> EdgeType {
    let pair: Set<PowerFlowNode> = [from, to]
    if pair == [.solar, .battery] {
        return .centerVertical
    } else if pair == [.grid, .home] {
        return .centerHorizontal
    } else {
        return .diagonal
    }
}

// MARK: - Path Builder

enum PowerFlowPathBuilder {

    /// Single shared geometry model for both scaffold connectors and animated flow dots.
    /// All connector endpoints land on the circle's true edge, aimed toward the connected node.
    /// Center routes are straight; diagonal routes curve smoothly outward from the layout center.
    static func segment(
        in layout: PowerFlowLayout,
        from: PowerFlowNode,
        to: PowerFlowNode
    ) -> PowerFlowSegment? {
        guard
            from != to,
            let fromCenter = layout.nodeCenters[from],
            let toCenter = layout.nodeCenters[to]
        else {
            return nil
        }

        let edgeType = classifyEdge(from: from, to: to)

        switch edgeType {
        case .centerVertical:
            // Solar <-> Battery: straight vertical line
            let start = circleEdgePoint(fromCenter, toward: toCenter, layout: layout)
            let end = circleEdgePoint(toCenter, toward: fromCenter, layout: layout)
            return PowerFlowSegment(start: start, end: end, control: nil)

        case .centerHorizontal:
            // Grid <-> Home: straight line, elevated by centerYOffset
            let yOff = layout.centerYOffset
            let aimFrom = CGPoint(x: toCenter.x, y: toCenter.y + yOff)
            let aimTo = CGPoint(x: fromCenter.x, y: fromCenter.y + yOff)
            let start = circleEdgePoint(fromCenter, toward: aimFrom, layout: layout)
            let end = circleEdgePoint(toCenter, toward: aimTo, layout: layout)
            return PowerFlowSegment(start: start, end: end, control: nil)

        case .diagonal:
            // Outer routes: smooth curve bowing away from layout center
            let start = circleEdgePoint(fromCenter, toward: toCenter, layout: layout)
            let end = circleEdgePoint(toCenter, toward: fromCenter, layout: layout)
            let control = outwardControlPoint(
                start: start, end: end,
                layoutCenter: layout.center,
                layout: layout
            )
            return PowerFlowSegment(start: start, end: end, control: control)
        }
    }

    /// Draw all scaffold connectors as a single Path.
    static func drawDottedVisibleEdges(path: inout Path, layout: PowerFlowLayout) {
        for (from, to) in layout.visibleEdges {
            guard let seg = segment(in: layout, from: from, to: to) else { continue }
            path.move(to: seg.start)
            if let control = seg.control {
                path.addQuadCurve(to: seg.end, control: control)
            } else {
                path.addLine(to: seg.end)
            }
        }
    }

    // MARK: - Private Geometry Helpers

    /// Returns the point on a circle's edge closest to the target direction.
    private static func circleEdgePoint(
        _ center: CGPoint,
        toward target: CGPoint,
        layout: PowerFlowLayout
    ) -> CGPoint {
        let dx = target.x - center.x
        let dy = target.y - center.y
        let distance = sqrt(dx * dx + dy * dy)
        guard distance > 0 else { return center }

        let effectiveRadius = layout.circleRadius + layout.padding
        return CGPoint(
            x: center.x + (dx / distance) * effectiveRadius,
            y: center.y + (dy / distance) * effectiveRadius
        )
    }

    /// Computes a quadratic Bezier control point that bows the curve away from the layout center.
    private static func outwardControlPoint(
        start: CGPoint,
        end: CGPoint,
        layoutCenter: CGPoint,
        layout: PowerFlowLayout
    ) -> CGPoint {
        let distance = sqrt(pow(end.x - start.x, 2) + pow(end.y - start.y, 2))
        let curveIntensity = min(layout.maxCurve, max(layout.minCurve, distance * layout.curveScale))

        let angle = atan2(end.y - start.y, end.x - start.x)
        let midX = (start.x + end.x) / 2
        let midY = (start.y + end.y) / 2

        // Pick the perpendicular direction that points toward the layout center
        let perp1 = angle + .pi / 2
        let inwardX = layoutCenter.x - midX
        let inwardY = layoutCenter.y - midY
        let dot = inwardX * cos(perp1) + inwardY * sin(perp1)
        let perpAngle = dot >= 0 ? perp1 : angle - .pi / 2

        return CGPoint(
            x: midX + cos(perpAngle) * curveIntensity,
            y: midY + sin(perpAngle) * curveIntensity
        )
    }
}

extension PowerFlowOrigin {
    var color: Color {
        switch self {
        case .solar:
            return .orange
        case .grid:
            return .blue
        case .battery:
            return Color(red: 0.95, green: 0.72, blue: 0.10)
        case .car:
            return Color(red: 0.09, green: 0.70, blue: 0.78)
        }
    }
}
