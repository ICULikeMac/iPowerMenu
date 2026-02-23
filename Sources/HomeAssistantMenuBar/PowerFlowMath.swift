import Foundation

enum PowerFlowNode: Hashable {
    case solar
    case grid
    case battery
    case home
}

enum PowerFlowOrigin {
    case solar
    case grid
    case battery
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
        homeDemand: Double,
        minimumRenderableWatts: Double = 20
    ) -> [PowerFlowRoute] {
        var routes: [PowerFlowRoute] = []

        var solarAvailable = max(0, solarGeneration)
        let gridImport = max(0, gridPower)
        let gridExport = max(0, -gridPower)
        let batteryChargeNeed = max(0, batteryPower)
        let batteryDischargeAvailable = max(0, -batteryPower)
        var homeRemaining = max(0, homeDemand)

        // Solar serves home first.
        let solarToHome = min(solarAvailable, homeRemaining)
        appendRoute(&routes, from: .solar, to: .home, watts: solarToHome, minimumRenderableWatts: minimumRenderableWatts)
        solarAvailable -= solarToHome
        homeRemaining -= solarToHome

        var batteryDischargeRemaining = batteryDischargeAvailable
        var gridImportRemaining = gridImport

        // Remaining home demand is split proportionally across battery and grid import.
        if homeRemaining > 0 {
            let availableForHome = batteryDischargeRemaining + gridImportRemaining
            if availableForHome > 0 {
                let allocatedHome = min(homeRemaining, availableForHome)
                let batteryToHome = allocatedHome * (batteryDischargeRemaining / availableForHome)
                let gridToHome = allocatedHome * (gridImportRemaining / availableForHome)

                appendRoute(&routes, from: .battery, to: .home, watts: batteryToHome, minimumRenderableWatts: minimumRenderableWatts)
                appendRoute(&routes, from: .grid, to: .home, watts: gridToHome, minimumRenderableWatts: minimumRenderableWatts)

                batteryDischargeRemaining -= batteryToHome
                gridImportRemaining -= gridToHome
                homeRemaining -= allocatedHome
            }
        }

        // Battery charging uses solar excess first, then any remaining grid import.
        var chargingRemaining = batteryChargeNeed
        if chargingRemaining > 0 {
            let solarToBattery = min(solarAvailable, chargingRemaining)
            appendRoute(&routes, from: .solar, to: .battery, watts: solarToBattery, minimumRenderableWatts: minimumRenderableWatts)
            solarAvailable -= solarToBattery
            chargingRemaining -= solarToBattery

            let gridToBattery = min(gridImportRemaining, chargingRemaining)
            appendRoute(&routes, from: .grid, to: .battery, watts: gridToBattery, minimumRenderableWatts: minimumRenderableWatts)
            gridImportRemaining -= gridToBattery
            chargingRemaining -= gridToBattery
        }

        // Grid export is split proportionally across available excess origins.
        if gridExport > 0 {
            let solarExcess = max(0, solarAvailable)
            let batteryExcess = max(0, batteryDischargeRemaining)
            let totalExcess = solarExcess + batteryExcess

            if totalExcess > 0 {
                let dispatchedExport = min(gridExport, totalExcess)
                let solarToGrid = dispatchedExport * (solarExcess / totalExcess)
                let batteryToGrid = dispatchedExport * (batteryExcess / totalExcess)

                appendRoute(&routes, from: .solar, to: .grid, watts: solarToGrid, minimumRenderableWatts: minimumRenderableWatts)
                appendRoute(&routes, from: .battery, to: .grid, watts: batteryToGrid, minimumRenderableWatts: minimumRenderableWatts)
            }
        }

        return routes
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
        case .home:
            return
        }

        routes.append(PowerFlowRoute(from: from, to: to, origin: origin, watts: watts))
    }
}
