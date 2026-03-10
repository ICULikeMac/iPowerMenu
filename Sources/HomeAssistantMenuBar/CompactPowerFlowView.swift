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
                        carPower: carPowerValue,
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

    private var carPowerValue: Double {
        extractNumericValue(from: menuBarController.entityValues[.carPower] ?? "0") ?? 0
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
        let prefix = watts > 0 ? "↓" : "↑"
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
    let carPower: Double
    let homePower: Double

    var body: some View {
        ZStack {
            CompactDottedConnectionLines(layout: layout)

            CompactPowerFlows(
                layout: layout,
                routes: routes
            )
        }
    }

    private var layout: PowerFlowLayout {
        PowerFlowLayout(
            size: size,
            circleRadius: 25,
            padding: 0,
            curveScale: 0.30,
            minCurve: 15,
            maxCurve: 35,
            circleCenterYOffset: -15
        )
    }

    private var routes: [PowerFlowRoute] {
        PowerFlowMath.calculateRoutes(
            solarGeneration: solarPower,
            gridPower: gridPower,
            batteryPower: batteryPower,
            carPower: carPower,
            homeDemand: homePower,
            minimumRenderableWatts: 20
        )
    }
}

struct CompactDottedConnectionLines: View {
    let layout: PowerFlowLayout

    var body: some View {
        Path { path in
            PowerFlowPathBuilder.drawDottedVisibleEdges(path: &path, layout: layout)
        }
        .stroke(
            Color.gray.opacity(0.4),
            style: StrokeStyle(lineWidth: 1.2, lineCap: .round, dash: [3, 4])
        )
    }
}

// MARK: - Compact Power Flows

struct CompactPowerFlows: View {
    let layout: PowerFlowLayout
    let routes: [PowerFlowRoute]

    var body: some View {
        ZStack {
            ForEach(Array(routes.enumerated()), id: \.offset) { _, route in
                if let segment = PowerFlowPathBuilder.segment(in: layout, from: route.from, to: route.to) {
                    CompactFlowIndicator(
                        segment: segment,
                        color: route.origin.color,
                        power: route.watts
                    )
                }
            }
        }
    }
}

// MARK: - Compact Flow Indicator

struct CompactFlowIndicator: View {
    let segment: PowerFlowSegment
    let color: Color
    let power: Double

    var body: some View {
        CompactMovingDot(
            segment: segment,
            color: color,
            duration: animationDuration
        )
    }

    private var animationDuration: Double {
        max(0.6, min(2.5, 3.0 - (power / 1000)))
    }
}

// MARK: - Compact Moving Dot

struct CompactMovingDot: View {
    let segment: PowerFlowSegment
    let color: Color
    let duration: Double

    @State private var progress: CGFloat = 0

    var currentPosition: CGPoint {
        if let control = segment.control {
            return quadraticBezierPoint(t: progress, p0: segment.start, p1: control, p2: segment.end)
        } else {
            return CGPoint(
                x: segment.start.x + (segment.end.x - segment.start.x) * progress,
                y: segment.start.y + (segment.end.y - segment.start.y) * progress
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
                    Animation.linear(duration: duration)
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
