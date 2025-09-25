import SwiftUI

struct CompactPowerFlowView: View {
    @ObservedObject private var menuBarController: MenuBarController

    init(menuBarController: MenuBarController) {
        self.menuBarController = menuBarController
    }

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            GeometryReader { geometry in
                ZStack {
                    // Subtle background gradient for compact modern look
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.98, green: 0.98, blue: 1.0).opacity(0.2),
                                    Color(red: 0.95, green: 0.97, blue: 1.0).opacity(0.05)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .black.opacity(0.03), radius: 6, x: 0, y: 3)

                    // Connection lines
                    CompactConnectionLines(
                        size: geometry.size,
                        solarPower: solarPowerValue,
                        gridPower: gridPowerValue,
                        batteryPower: batteryPowerValue,
                        homePower: homePowerValue
                    )

                    // Power components
                    CompactPowerComponentsLayout(
                        size: geometry.size,
                        solarPower: solarPowerValue,
                        gridPower: gridPowerValue,
                        batteryPower: batteryPowerValue,
                        batterySOC: batterySOCValue,
                        homePower: homePowerValue
                    )
                }
            }
            .aspectRatio(1.2, contentMode: .fit)
            .frame(maxWidth: 280, maxHeight: 200)

            // Connection status
            HStack {
                Image(systemName: connectionStatusIcon)
                    .foregroundColor(connectionStatusColor)
                    .font(.caption2)
                Text(connectionStatusText)
                    .font(.caption2)
                    .foregroundColor(connectionStatusColor)
            }
        }
        .padding(8)
        .frame(width: 300, height: 230)
    }

    // MARK: - Data Processing (same as full view)

    private var solarPowerValue: Double {
        extractNumericValue(from: menuBarController.entityValues[.solar] ?? "0") ?? 0
    }

    private var gridPowerValue: Double {
        extractNumericValue(from: menuBarController.entityValues[.gridUsage] ?? "0") ?? 0
    }

    private var batteryPowerValue: Double {
        let charging = extractNumericValue(from: menuBarController.entityValues[.batteryCharging] ?? "0") ?? 0
        let discharging = extractNumericValue(from: menuBarController.entityValues[.batteryDischarging] ?? "0") ?? 0
        return charging - discharging
    }

    private var batterySOCValue: Double {
        extractNumericValue(from: menuBarController.entityValues[.battery] ?? "0") ?? 0
    }

    private var homePowerValue: Double {
        extractNumericValue(from: menuBarController.entityValues[.homePower] ?? "0") ?? 0
    }

    private var connectionStatusIcon: String {
        switch menuBarController.connectionStatus {
        case .connected: return "checkmark.circle.fill"
        case .disconnected: return "xmark.circle.fill"
        case .error: return "exclamationmark.triangle.fill"
        }
    }

    private var connectionStatusColor: Color {
        switch menuBarController.connectionStatus {
        case .connected: return .green
        case .disconnected: return .gray
        case .error: return .red
        }
    }

    private var connectionStatusText: String {
        switch menuBarController.connectionStatus {
        case .connected: return "Connected"
        case .disconnected: return "Disconnected"
        case .error: return "Error"
        }
    }

    private func extractNumericValue(from formattedValue: String) -> Double? {
        let cleanedValue = formattedValue.replacingOccurrences(of: "W", with: "")
                                      .replacingOccurrences(of: "%", with: "")
                                      .trimmingCharacters(in: .whitespaces)
        return Double(cleanedValue)
    }
}

// MARK: - Compact Power Components Layout

struct CompactPowerComponentsLayout: View {
    let size: CGSize
    let solarPower: Double
    let gridPower: Double
    let batteryPower: Double
    let batterySOC: Double
    let homePower: Double

    var body: some View {
        // Compact diamond layout

        // Solar (top)
        CompactPowerComponent(
            icon: "sun.min",
            label: "Solar",
            value: formatWatts(solarPower),
            color: .orange,
            position: CGPoint(x: size.width * 0.5, y: size.height * 0.2)
        )

        // Grid (left)
        CompactPowerComponent(
            icon: "bolt",
            label: gridLabel,
            value: formatWatts(abs(gridPower)),
            color: .blue,
            position: CGPoint(x: size.width * 0.2, y: size.height * 0.5)
        )

        // Home (right)
        CompactPowerComponent(
            icon: "house",
            label: "Home",
            value: formatWatts(homePower),
            color: .indigo,
            position: CGPoint(x: size.width * 0.8, y: size.height * 0.5)
        )

        // Battery (bottom)
        CompactPowerComponent(
            icon: "bolt.house",
            label: "Battery",
            value: formatPercentage(batterySOC),
            secondaryValue: batteryPower != 0 ? formatBatteryFlow(batteryPower) : nil,
            color: batteryColor,
            position: CGPoint(x: size.width * 0.5, y: size.height * 0.8)
        )
    }

    private var gridLabel: String {
        "Grid"
    }

    private var batteryColor: Color {
        if batterySOC > 80 { return .green }
        else if batterySOC > 50 { return .yellow }
        else if batterySOC > 20 { return .orange }
        else { return .red }
    }

    private func formatWatts(_ watts: Double) -> String {
        if watts == 0 { return "0W" }
        if abs(watts) < 1000 {
            return String(format: "%.0fW", watts)
        } else {
            return String(format: "%.1fkW", watts / 1000)
        }
    }

    private func formatPercentage(_ percentage: Double) -> String {
        return String(format: "%.0f%%", percentage)
    }

    private func formatBatteryFlow(_ watts: Double) -> String {
        let prefix = watts > 0 ? "↑" : "↓"
        return "\(prefix)\(formatWatts(abs(watts)))"
    }
}

// MARK: - Compact Power Component

struct CompactPowerComponent: View {
    let icon: String
    let label: String
    let value: String
    let secondaryValue: String?
    let color: Color
    let position: CGPoint

    init(icon: String, label: String, value: String, secondaryValue: String? = nil, color: Color, position: CGPoint) {
        self.icon = icon
        self.label = label
        self.value = value
        self.secondaryValue = secondaryValue
        self.color = color
        self.position = position
    }

    var body: some View {
        VStack(spacing: 3) {
            // Icon circle with modern styling (compact)
            Circle()
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            color.opacity(0.8),
                            color.opacity(0.4)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
                .background(
                    Circle()
                        .fill(color.opacity(0.08))
                        .shadow(color: color.opacity(0.2), radius: 4, x: 0, y: 2)
                        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 4)
                )
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundColor(color.opacity(0.9))
                        .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 0.5)
                )

            // Label
            Text(label)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.secondary)

            // Value
            Text(value)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            // Secondary value (for battery flow)
            if let secondaryValue = secondaryValue {
                Text(secondaryValue)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .position(position)
    }
}

// MARK: - Compact Connection Lines & Flows

struct CompactConnectionLines: View {
    let size: CGSize
    let solarPower: Double
    let gridPower: Double
    let batteryPower: Double
    let homePower: Double

    private let circleRadius: CGFloat = 30 // Improved offset with padding for compact view

    var body: some View {
        ZStack {
            // Static connection lines (very subtle for compact view)
            Path { path in
                // Solar to Grid
                addCompactCurvedLine(path: &path,
                                   start: CGPoint(x: size.width * 0.5, y: size.height * 0.2),
                                   end: CGPoint(x: size.width * 0.2, y: size.height * 0.5))

                // Solar to Home
                addCompactCurvedLine(path: &path,
                                   start: CGPoint(x: size.width * 0.5, y: size.height * 0.2),
                                   end: CGPoint(x: size.width * 0.8, y: size.height * 0.5))

                // Solar to Battery (vertical)
                let padding: CGFloat = 3 // Smaller padding for compact view
                let effectiveRadius = circleRadius + padding
                path.move(to: CGPoint(x: size.width * 0.5, y: size.height * 0.2 + effectiveRadius))
                path.addLine(to: CGPoint(x: size.width * 0.5, y: size.height * 0.8 - effectiveRadius))

                // Grid to Battery
                addCompactCurvedLine(path: &path,
                                   start: CGPoint(x: size.width * 0.2, y: size.height * 0.5),
                                   end: CGPoint(x: size.width * 0.5, y: size.height * 0.8))

                // Grid to Home (horizontal)
                path.move(to: CGPoint(x: size.width * 0.2 + effectiveRadius, y: size.height * 0.5))
                path.addLine(to: CGPoint(x: size.width * 0.8 - effectiveRadius, y: size.height * 0.5))

                // Battery to Home
                addCompactCurvedLine(path: &path,
                                   start: CGPoint(x: size.width * 0.5, y: size.height * 0.8),
                                   end: CGPoint(x: size.width * 0.8, y: size.height * 0.5))
            }
            .stroke(Color.gray.opacity(0.06), lineWidth: 0.8)

            // Simplified flow indicators (fewer dots, faster animation for menu)
            CompactPowerFlows(
                size: size,
                solarPower: solarPower,
                gridPower: gridPower,
                batteryPower: batteryPower,
                homePower: homePower
            )
        }
    }

    private func addCompactCurvedLine(path: inout Path, start: CGPoint, end: CGPoint) {
        let adjustedStart = adjustPointForCircle(start, towards: end)
        let adjustedEnd = adjustPointForCircle(end, towards: start)

        // Calculate distance-based curve offset for compact view
        let distance = sqrt(pow(adjustedEnd.x - adjustedStart.x, 2) + pow(adjustedEnd.y - adjustedStart.y, 2))
        let curveIntensity: CGFloat = min(25, max(12, distance * 0.12)) // Smaller for compact

        // Calculate angle perpendicular to connection line
        let angle = atan2(adjustedEnd.y - adjustedStart.y, adjustedEnd.x - adjustedStart.x)
        let perpendicularAngle = angle + .pi / 2

        // Create control point offset perpendicular to line
        let midX = (adjustedStart.x + adjustedEnd.x) / 2
        let midY = (adjustedStart.y + adjustedEnd.y) / 2

        let controlPoint = CGPoint(
            x: midX + cos(perpendicularAngle) * curveIntensity,
            y: midY + sin(perpendicularAngle) * curveIntensity
        )

        path.move(to: adjustedStart)
        path.addQuadCurve(to: adjustedEnd, control: controlPoint)
    }

    private func adjustPointForCircle(_ point: CGPoint, towards target: CGPoint) -> CGPoint {
        let dx = target.x - point.x
        let dy = target.y - point.y
        let distance = sqrt(dx * dx + dy * dy)

        if distance == 0 { return point }

        let unitX = dx / distance
        let unitY = dy / distance

        // Add extra padding to ensure clean separation
        let padding: CGFloat = 3 // Smaller padding for compact view
        let effectiveRadius = circleRadius + padding

        return CGPoint(
            x: point.x + unitX * effectiveRadius,
            y: point.y + unitY * effectiveRadius
        )
    }
}

// MARK: - Compact Power Flows

struct CompactPowerFlows: View {
    let size: CGSize
    let solarPower: Double
    let gridPower: Double
    let batteryPower: Double
    let homePower: Double

    var body: some View {
        ZStack {
            // Show only the most important flows for clarity in compact view

            // Solar to Home
            if solarPower > 0 && homePower > 0 {
                CompactFlowIndicator(
                    start: CGPoint(x: size.width * 0.5, y: size.height * 0.2),
                    end: CGPoint(x: size.width * 0.8, y: size.height * 0.5),
                    color: .orange,
                    curved: true
                )
            }

            // Solar to Battery
            if batteryPower > 0 {
                CompactFlowIndicator(
                    start: CGPoint(x: size.width * 0.5, y: size.height * 0.2),
                    end: CGPoint(x: size.width * 0.5, y: size.height * 0.8),
                    color: .green,
                    curved: false
                )
            }

            // Battery to Home
            if batteryPower < 0 {
                CompactFlowIndicator(
                    start: CGPoint(x: size.width * 0.5, y: size.height * 0.8),
                    end: CGPoint(x: size.width * 0.8, y: size.height * 0.5),
                    color: .yellow,
                    curved: true
                )
            }

            // Grid import/export
            if gridPower > 0 {
                CompactFlowIndicator(
                    start: CGPoint(x: size.width * 0.2, y: size.height * 0.5),
                    end: CGPoint(x: size.width * 0.8, y: size.height * 0.5),
                    color: .blue,
                    curved: false
                )
            } else if gridPower < 0 && abs(gridPower) >= 50 {
                CompactFlowIndicator(
                    start: CGPoint(x: size.width * 0.5, y: size.height * 0.2),
                    end: CGPoint(x: size.width * 0.2, y: size.height * 0.5),
                    color: .purple,
                    curved: true
                )
            }
        }
    }
}

// MARK: - Compact Flow Indicator

struct CompactFlowIndicator: View {
    let start: CGPoint
    let end: CGPoint
    let color: Color
    let curved: Bool

    private let circleRadius: CGFloat = 30

    var body: some View {
        // Single moving dot for compact view
        CompactMovingDot(
            start: adjustPointForCircle(start, towards: end),
            end: adjustPointForCircle(end, towards: start),
            color: color,
            curved: curved
        )
    }

    private func adjustPointForCircle(_ point: CGPoint, towards target: CGPoint) -> CGPoint {
        let dx = target.x - point.x
        let dy = target.y - point.y
        let distance = sqrt(dx * dx + dy * dy)

        if distance == 0 { return point }

        let unitX = dx / distance
        let unitY = dy / distance

        // Add extra padding to ensure clean separation
        let padding: CGFloat = 3 // Smaller padding for compact view
        let effectiveRadius = circleRadius + padding

        return CGPoint(
            x: point.x + unitX * effectiveRadius,
            y: point.y + unitY * effectiveRadius
        )
    }
}

// MARK: - Compact Moving Dot

struct CompactMovingDot: View {
    let start: CGPoint
    let end: CGPoint
    let color: Color
    let curved: Bool

    @State private var progress: CGFloat = 0

    var currentPosition: CGPoint {
        if curved {
            // Calculate distance-based curve offset for compact view
            let distance = sqrt(pow(end.x - start.x, 2) + pow(end.y - start.y, 2))
            let curveIntensity: CGFloat = min(25, max(12, distance * 0.12)) // Smaller for compact

            // Calculate angle perpendicular to connection line
            let angle = atan2(end.y - start.y, end.x - start.x)
            let perpendicularAngle = angle + .pi / 2

            // Create control point offset perpendicular to line
            let midX = (start.x + end.x) / 2
            let midY = (start.y + end.y) / 2

            let controlPoint = CGPoint(
                x: midX + cos(perpendicularAngle) * curveIntensity,
                y: midY + sin(perpendicularAngle) * curveIntensity
            )

            return quadraticBezierPoint(t: progress, p0: start, p1: controlPoint, p2: end)
        } else {
            return CGPoint(
                x: start.x + (end.x - start.x) * progress,
                y: start.y + (end.y - start.y) * progress
            )
        }
    }

    var body: some View {
        Circle()
            .fill(RadialGradient(
                gradient: Gradient(colors: [
                    color.opacity(0.9),
                    color.opacity(0.6),
                    color.opacity(0.3)
                ]),
                center: .center,
                startRadius: 1,
                endRadius: 3
            ))
            .frame(width: 8, height: 8) // Slightly larger for better visibility
            .shadow(color: color.opacity(0.7), radius: 3, x: 0, y: 0)
            .shadow(color: color.opacity(0.3), radius: 6, x: 0, y: 0)
            .position(currentPosition)
            .onAppear {
                withAnimation(
                    Animation.linear(duration: 2.0) // Fixed duration for menu
                        .repeatForever(autoreverses: false)
                ) {
                    progress = 1.0
                }
            }
    }

    private func quadraticBezierPoint(t: CGFloat, p0: CGPoint, p1: CGPoint, p2: CGPoint) -> CGPoint {
        let oneMinusT = 1 - t
        let oneMinusTSquared = oneMinusT * oneMinusT
        let tSquared = t * t

        return CGPoint(
            x: oneMinusTSquared * p0.x + 2 * oneMinusT * t * p1.x + tSquared * p2.x,
            y: oneMinusTSquared * p0.y + 2 * oneMinusT * t * p1.y + tSquared * p2.y
        )
    }
}

#Preview {
    CompactPowerFlowView(menuBarController: {
        let controller = MenuBarController()
        controller.entityValues = [
            .solar: "1200W",
            .battery: "85%",
            .gridUsage: "-300W",
            .homePower: "800W",
            .batteryCharging: "400W",
            .batteryDischarging: "0W"
        ]
        return controller
    }())
}