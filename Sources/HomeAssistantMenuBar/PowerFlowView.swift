import SwiftUI

struct PowerFlowView: View {
    @ObservedObject private var menuBarController: MenuBarController

    init(menuBarController: MenuBarController) {
        self.menuBarController = menuBarController
    }

    var body: some View {
        VStack(alignment: .center, spacing: 20) {
            Text("Power Flow")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.bottom, 10)

            GeometryReader { geometry in
                ZStack {
                    // Connection lines
                    PowerFlowConnections(
                        size: geometry.size,
                        solarPower: solarPowerValue,
                        gridPower: gridPowerValue,
                        batteryPower: batteryPowerValue,
                        homePower: homePowerValue
                    )

                    // Power components
                    PowerComponentsLayout(
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
            .frame(maxWidth: 600, maxHeight: 500)

            // Connection status
            HStack {
                Image(systemName: connectionStatusIcon)
                    .foregroundColor(connectionStatusColor)
                Text(connectionStatusText)
                    .font(.caption)
                    .foregroundColor(connectionStatusColor)
            }
            .padding(.top, 10)
        }
        .padding(20)
        .frame(width: 650, height: 600)
    }

    // MARK: - Data Processing

    private var solarPowerValue: Double {
        extractNumericValue(from: menuBarController.entityValues[.solar] ?? "0") ?? 0
    }

    private var gridPowerValue: Double {
        extractNumericValue(from: menuBarController.entityValues[.gridUsage] ?? "0") ?? 0
    }

    private var batteryPowerValue: Double {
        let charging = extractNumericValue(from: menuBarController.entityValues[.batteryCharging] ?? "0") ?? 0
        let discharging = extractNumericValue(from: menuBarController.entityValues[.batteryDischarging] ?? "0") ?? 0

        // Return net battery power: positive for charging, negative for discharging
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
        case .error: return "Connection Error"
        }
    }

    private func extractNumericValue(from formattedValue: String) -> Double? {
        let cleanedValue = formattedValue.replacingOccurrences(of: "W", with: "")
                                      .replacingOccurrences(of: "%", with: "")
                                      .trimmingCharacters(in: .whitespaces)
        return Double(cleanedValue)
    }
}

// MARK: - Power Components Layout

struct PowerComponentsLayout: View {
    let size: CGSize
    let solarPower: Double
    let gridPower: Double
    let batteryPower: Double
    let batterySOC: Double
    let homePower: Double

    var body: some View {
        // Diamond/Square layout for better flow visualization

        // Solar (top)
        PowerComponent(
            icon: "sun.min",
            label: "Solar",
            value: formatWatts(solarPower),
            color: .orange,
            position: CGPoint(x: size.width * 0.5, y: size.height * 0.2)
        )

        // Grid (left)
        PowerComponent(
            icon: "bolt",
            label: gridLabel,
            value: formatWatts(abs(gridPower)),
            color: .blue,
            position: CGPoint(x: size.width * 0.2, y: size.height * 0.5)
        )

        // Home (right)
        PowerComponent(
            icon: "house",
            label: "Home",
            value: formatWatts(homePower),
            color: .indigo,
            position: CGPoint(x: size.width * 0.8, y: size.height * 0.5)
        )

        // Battery (bottom)
        PowerComponent(
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
        return "\(prefix) \(formatWatts(abs(watts)))"
    }
}

// MARK: - Individual Power Component

struct PowerComponent: View {
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
        VStack(spacing: 6) {
            // Icon circle
            Circle()
                .stroke(color, lineWidth: 3)
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: icon)
                        .font(.title)
                        .foregroundColor(color)
                )

            // Label
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)

            // Value
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            // Secondary value (for battery flow)
            if let secondaryValue = secondaryValue {
                Text(secondaryValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .position(position)
    }
}

// MARK: - Power Flow Connections

struct PowerFlowConnections: View {
    let size: CGSize
    let solarPower: Double
    let gridPower: Double
    let batteryPower: Double
    let homePower: Double

    var body: some View {
        ZStack {
            // Draw the connection lines (always visible)
            ConnectionLines(size: size)

            // Animated power flow indicators on direct connections

            // Solar flows
            if solarPower > 0 {
                // Solar to Home (direct consumption)
                if homePower > 0 && solarPower >= homePower {
                    DirectFlowIndicator(
                        start: CGPoint(x: size.width * 0.5, y: size.height * 0.2),
                        end: CGPoint(x: size.width * 0.8, y: size.height * 0.5),
                        color: .orange,
                        power: min(solarPower, homePower),
                        curved: true
                    )
                }

                // Solar to Battery (charging excess)
                if batteryPower > 0 {
                    DirectFlowIndicator(
                        start: CGPoint(x: size.width * 0.5, y: size.height * 0.2),
                        end: CGPoint(x: size.width * 0.5, y: size.height * 0.8),
                        color: .green,
                        power: batteryPower,
                        curved: false
                    )
                }

                // Solar to Grid (export excess) - only if >= 50W
                if gridPower < 0 && abs(gridPower) >= 50 {
                    DirectFlowIndicator(
                        start: CGPoint(x: size.width * 0.5, y: size.height * 0.2),
                        end: CGPoint(x: size.width * 0.2, y: size.height * 0.5),
                        color: .purple,
                        power: abs(gridPower),
                        curved: true
                    )
                }
            }

            // Grid flows
            if gridPower > 0 {
                // Grid to Home (import for consumption)
                if homePower > solarPower {
                    DirectFlowIndicator(
                        start: CGPoint(x: size.width * 0.2, y: size.height * 0.5),
                        end: CGPoint(x: size.width * 0.8, y: size.height * 0.5),
                        color: .blue,
                        power: gridPower,
                        curved: false
                    )
                }

                // Grid to Battery (charging from grid)
                if batteryPower > 0 && solarPower < batteryPower {
                    DirectFlowIndicator(
                        start: CGPoint(x: size.width * 0.2, y: size.height * 0.5),
                        end: CGPoint(x: size.width * 0.5, y: size.height * 0.8),
                        color: .blue,
                        power: batteryPower - solarPower,
                        curved: true
                    )
                }
            }

            // Battery flows
            if batteryPower < 0 {
                // Battery to Home (discharging)
                DirectFlowIndicator(
                    start: CGPoint(x: size.width * 0.5, y: size.height * 0.8),
                    end: CGPoint(x: size.width * 0.8, y: size.height * 0.5),
                    color: .yellow,
                    power: abs(batteryPower),
                    curved: true
                )

                // Battery to Grid (export from battery) - only if >= 50W
                if gridPower < 0 && abs(gridPower) > solarPower && (abs(gridPower) - solarPower) >= 50 {
                    DirectFlowIndicator(
                        start: CGPoint(x: size.width * 0.5, y: size.height * 0.8),
                        end: CGPoint(x: size.width * 0.2, y: size.height * 0.5),
                        color: .purple,
                        power: abs(gridPower) - solarPower,
                        curved: true
                    )
                }
            }
        }
    }
}

// MARK: - Static Connection Lines

struct ConnectionLines: View {
    let size: CGSize

    private let circleRadius: CGFloat = 40 // Half of the 80pt circle diameter

    var body: some View {
        Path { path in
            // Solar (0.5, 0.2) to Grid (0.2, 0.5)
            addCurvedLine(path: &path,
                         start: CGPoint(x: size.width * 0.5, y: size.height * 0.2),
                         end: CGPoint(x: size.width * 0.2, y: size.height * 0.5))

            // Solar (0.5, 0.2) to Home (0.8, 0.5)
            addCurvedLine(path: &path,
                         start: CGPoint(x: size.width * 0.5, y: size.height * 0.2),
                         end: CGPoint(x: size.width * 0.8, y: size.height * 0.5))

            // Solar (0.5, 0.2) to Battery (0.5, 0.8) - direct vertical
            path.move(to: CGPoint(x: size.width * 0.5, y: size.height * 0.2 + circleRadius))
            path.addLine(to: CGPoint(x: size.width * 0.5, y: size.height * 0.8 - circleRadius))

            // Grid (0.2, 0.5) to Battery (0.5, 0.8)
            addCurvedLine(path: &path,
                         start: CGPoint(x: size.width * 0.2, y: size.height * 0.5),
                         end: CGPoint(x: size.width * 0.5, y: size.height * 0.8))

            // Grid (0.2, 0.5) to Home (0.8, 0.5) - direct horizontal
            path.move(to: CGPoint(x: size.width * 0.2 + circleRadius, y: size.height * 0.5))
            path.addLine(to: CGPoint(x: size.width * 0.8 - circleRadius, y: size.height * 0.5))

            // Battery (0.5, 0.8) to Home (0.8, 0.5)
            addCurvedLine(path: &path,
                         start: CGPoint(x: size.width * 0.5, y: size.height * 0.8),
                         end: CGPoint(x: size.width * 0.8, y: size.height * 0.5))
        }
        .stroke(Color.gray.opacity(0.2), lineWidth: 1.5)
    }

    private func addCurvedLine(path: inout Path, start: CGPoint, end: CGPoint) {
        let adjustedStart = adjustPointForCircle(start, towards: end)
        let adjustedEnd = adjustPointForCircle(end, towards: start)

        // Create a curved line with control point for smooth flow
        let midX = (adjustedStart.x + adjustedEnd.x) / 2
        let midY = (adjustedStart.y + adjustedEnd.y) / 2
        let offset: CGFloat = 20 // Curve offset

        let controlPoint = CGPoint(
            x: midX + (adjustedStart.y < adjustedEnd.y ? -offset : offset),
            y: midY + (adjustedStart.x < adjustedEnd.x ? -offset : offset)
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

        return CGPoint(
            x: point.x + unitX * circleRadius,
            y: point.y + unitY * circleRadius
        )
    }
}

// MARK: - Direct Flow Indicator (for curved and straight paths)

struct DirectFlowIndicator: View {
    let start: CGPoint
    let end: CGPoint
    let color: Color
    let power: Double
    let curved: Bool

    private let circleRadius: CGFloat = 40

    private var dotCount: Int {
        min(5, max(1, Int(power / 500)))
    }

    private var animationSpeed: Double {
        max(0.5, min(3.0, 4.0 - (power / 1000)))
    }

    var body: some View {
        ZStack {
            ForEach(0..<dotCount, id: \.self) { index in
                MovingDotDirect(
                    start: adjustPointForCircle(start, towards: end),
                    end: adjustPointForCircle(end, towards: start),
                    color: color,
                    curved: curved,
                    delay: Double(index) * (animationSpeed / Double(dotCount)),
                    duration: animationSpeed
                )
            }
        }
    }

    private func adjustPointForCircle(_ point: CGPoint, towards target: CGPoint) -> CGPoint {
        let dx = target.x - point.x
        let dy = target.y - point.y
        let distance = sqrt(dx * dx + dy * dy)

        if distance == 0 { return point }

        let unitX = dx / distance
        let unitY = dy / distance

        return CGPoint(
            x: point.x + unitX * circleRadius,
            y: point.y + unitY * circleRadius
        )
    }
}

// MARK: - Moving Dot for Direct Connections

struct MovingDotDirect: View {
    let start: CGPoint
    let end: CGPoint
    let color: Color
    let curved: Bool
    let delay: Double
    let duration: Double

    @State private var progress: CGFloat = 0

    var currentPosition: CGPoint {
        if curved {
            // Calculate curved path position
            let midX = (start.x + end.x) / 2
            let midY = (start.y + end.y) / 2
            let offset: CGFloat = 20

            let controlPoint = CGPoint(
                x: midX + (start.y < end.y ? -offset : offset),
                y: midY + (start.x < end.x ? -offset : offset)
            )

            return quadraticBezierPoint(t: progress, p0: start, p1: controlPoint, p2: end)
        } else {
            // Straight line
            return CGPoint(
                x: start.x + (end.x - start.x) * progress,
                y: start.y + (end.y - start.y) * progress
            )
        }
    }

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
            .shadow(color: color.opacity(0.6), radius: 3)
            .position(currentPosition)
            .onAppear {
                withAnimation(
                    Animation.linear(duration: duration)
                        .delay(delay)
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

// MARK: - Animated Flow Indicator (Legacy - for backward compatibility)

struct FlowIndicator: View {
    let path: [CGPoint]
    let color: Color
    let power: Double

    @State private var offset: CGFloat = 0

    private var dotCount: Int {
        // More dots for higher power
        min(5, max(1, Int(power / 500)))
    }

    private var animationSpeed: Double {
        // Faster animation for higher power
        max(0.5, min(3.0, 4.0 - (power / 1000)))
    }

    var body: some View {
        ZStack {
            ForEach(0..<dotCount, id: \.self) { index in
                MovingDot(
                    path: path,
                    color: color,
                    delay: Double(index) * (animationSpeed / Double(dotCount)),
                    duration: animationSpeed
                )
            }
        }
    }
}

// MARK: - Moving Dot

struct MovingDot: View {
    let path: [CGPoint]
    let color: Color
    let delay: Double
    let duration: Double

    @State private var progress: CGFloat = 0

    var currentPosition: CGPoint {
        guard path.count >= 2 else { return .zero }

        let start = path[0]
        let end = path[1]

        return CGPoint(
            x: start.x + (end.x - start.x) * progress,
            y: start.y + (end.y - start.y) * progress
        )
    }

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
            .shadow(color: color.opacity(0.6), radius: 3)
            .position(currentPosition)
            .onAppear {
                withAnimation(
                    Animation.linear(duration: duration)
                        .delay(delay)
                        .repeatForever(autoreverses: false)
                ) {
                    progress = 1.0
                }
            }
    }
}

#Preview {
    PowerFlowView(menuBarController: {
        let controller = MenuBarController()
        controller.entityValues = [
            .solar: "1200W",
            .battery: "85%",
            .gridUsage: "-300W",
            .homePower: "800W"
        ]
        return controller
    }())
}