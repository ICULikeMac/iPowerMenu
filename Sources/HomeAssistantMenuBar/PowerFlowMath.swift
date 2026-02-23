import Foundation

enum PowerFlowNode: Hashable {
    case solar
    case grid
    case battery
    case car
    case home
}

enum PowerFlowOrigin {
    case solar
    case grid
    case battery
    case car
}

struct PowerFlowRoute {
    let from: PowerFlowNode
    let to: PowerFlowNode
    let origin: PowerFlowOrigin
    let watts: Double
}

enum PowerFlowMath {
    static func calculateRoutes(
        solarGeneration: Double,
        gridPower: Double,
        batteryPower: Double,
        carPower: Double,
        homeDemand: Double,
        minimumRenderableWatts: Double = 20
    ) -> [PowerFlowRoute] {
        var routes: [PowerFlowRoute] = []

        var availableSources: [PowerFlowNode: Double] = [
            .solar: max(0, solarGeneration),
            .battery: max(0, -batteryPower),
            .car: max(0, -carPower),
            .grid: max(0, gridPower)
        ]

        let sinks: [(node: PowerFlowNode, demand: Double)] = [
            (.home, max(0, homeDemand)),
            (.battery, max(0, batteryPower)),
            (.car, max(0, carPower)),
            (.grid, max(0, -gridPower))
        ]

        for sink in sinks where sink.demand > 0 {
            let allocations = allocateProportionally(from: &availableSources, demand: sink.demand)
            for (sourceNode, watts) in allocations {
                appendRoute(
                    &routes,
                    from: sourceNode,
                    to: sink.node,
                    watts: watts,
                    minimumRenderableWatts: minimumRenderableWatts
                )
            }
        }

        return routes
    }

    private static func allocateProportionally(
        from sources: inout [PowerFlowNode: Double],
        demand: Double
    ) -> [PowerFlowNode: Double] {
        let totalAvailable = sources.values.reduce(0, +)
        guard totalAvailable > 0, demand > 0 else { return [:] }

        let allocatedDemand = min(demand, totalAvailable)
        var allocations: [PowerFlowNode: Double] = [:]

        for (node, available) in sources where available > 0 {
            let share = allocatedDemand * (available / totalAvailable)
            allocations[node] = share
            sources[node] = max(0, available - share)
        }

        return allocations
    }

    private static func appendRoute(
        _ routes: inout [PowerFlowRoute],
        from: PowerFlowNode,
        to: PowerFlowNode,
        watts: Double,
        minimumRenderableWatts: Double
    ) {
        guard watts > minimumRenderableWatts else { return }

        let origin: PowerFlowOrigin
        switch from {
        case .solar:
            origin = .solar
        case .grid:
            origin = .grid
        case .battery:
            origin = .battery
        case .car:
            origin = .car
        case .home:
            return
        }

        routes.append(PowerFlowRoute(from: from, to: to, origin: origin, watts: watts))
    }
}
