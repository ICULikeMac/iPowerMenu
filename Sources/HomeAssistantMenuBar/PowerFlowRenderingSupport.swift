import SwiftUI

struct PowerFlowLayout {
    let size: CGSize
    let circleRadius: CGFloat
    let padding: CGFloat
    let curveScale: CGFloat
    let minCurve: CGFloat
    let maxCurve: CGFloat

    var nodeCenters: [PowerFlowNode: CGPoint] {
        [
            .solar: CGPoint(x: size.width * 0.5, y: size.height * 0.2),
            .grid: CGPoint(x: size.width * 0.2, y: size.height * 0.5),
            .home: CGPoint(x: size.width * 0.8, y: size.height * 0.5),
            .battery: CGPoint(x: size.width * 0.5, y: size.height * 0.8)
        ]
    }

    var allEdges: [PowerFlowEdge] {
        [
            .init(a: .solar, b: .grid, curved: true),
            .init(a: .solar, b: .home, curved: true),
            .init(a: .solar, b: .battery, curved: false),
            .init(a: .grid, b: .battery, curved: true),
            .init(a: .grid, b: .home, curved: false),
            .init(a: .battery, b: .home, curved: true)
        ]
    }
}

struct PowerFlowEdge {
    let a: PowerFlowNode
    let b: PowerFlowNode
    let curved: Bool

    func matches(_ from: PowerFlowNode, _ to: PowerFlowNode) -> Bool {
        (a == from && b == to) || (a == to && b == from)
    }
}

struct PowerFlowSegment {
    let start: CGPoint
    let end: CGPoint
    let control: CGPoint?
}

enum PowerFlowPathBuilder {
    static func segment(
        in layout: PowerFlowLayout,
        from: PowerFlowNode,
        to: PowerFlowNode
    ) -> PowerFlowSegment? {
        guard
            let edge = layout.allEdges.first(where: { $0.matches(from, to) }),
            let fromCenter = layout.nodeCenters[from],
            let toCenter = layout.nodeCenters[to],
            let canonicalStartCenter = layout.nodeCenters[edge.a],
            let canonicalEndCenter = layout.nodeCenters[edge.b]
        else {
            return nil
        }

        let start = adjustPointForCircle(fromCenter, towards: toCenter, layout: layout)
        let end = adjustPointForCircle(toCenter, towards: fromCenter, layout: layout)

        guard edge.curved else {
            return PowerFlowSegment(start: start, end: end, control: nil)
        }

        let canonicalStart = adjustPointForCircle(canonicalStartCenter, towards: canonicalEndCenter, layout: layout)
        let canonicalEnd = adjustPointForCircle(canonicalEndCenter, towards: canonicalStartCenter, layout: layout)
        let control = curveControlPoint(start: canonicalStart, end: canonicalEnd, layout: layout)

        return PowerFlowSegment(start: start, end: end, control: control)
    }

    static func drawStaticEdges(path: inout Path, layout: PowerFlowLayout) {
        for edge in layout.allEdges {
            guard let segment = segment(in: layout, from: edge.a, to: edge.b) else { continue }
            path.move(to: segment.start)
            if let control = segment.control {
                path.addQuadCurve(to: segment.end, control: control)
            } else {
                path.addLine(to: segment.end)
            }
        }
    }

    private static func adjustPointForCircle(_ point: CGPoint, towards target: CGPoint, layout: PowerFlowLayout) -> CGPoint {
        let dx = target.x - point.x
        let dy = target.y - point.y
        let distance = sqrt(dx * dx + dy * dy)

        guard distance > 0 else { return point }

        let unitX = dx / distance
        let unitY = dy / distance
        let effectiveRadius = layout.circleRadius + layout.padding

        return CGPoint(
            x: point.x + unitX * effectiveRadius,
            y: point.y + unitY * effectiveRadius
        )
    }

    private static func curveControlPoint(start: CGPoint, end: CGPoint, layout: PowerFlowLayout) -> CGPoint {
        let distance = sqrt(pow(end.x - start.x, 2) + pow(end.y - start.y, 2))
        let curveIntensity = min(layout.maxCurve, max(layout.minCurve, distance * layout.curveScale))

        let angle = atan2(end.y - start.y, end.x - start.x)
        let perpendicularAngle = angle + .pi / 2
        let midX = (start.x + end.x) / 2
        let midY = (start.y + end.y) / 2

        return CGPoint(
            x: midX + cos(perpendicularAngle) * curveIntensity,
            y: midY + sin(perpendicularAngle) * curveIntensity
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
        }
    }
}
