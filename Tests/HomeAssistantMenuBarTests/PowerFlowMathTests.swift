import XCTest
@testable import HomeAssistantMenuBar

final class PowerFlowMathTests: XCTestCase {
    func testHomeDemandIsSplitAcrossSolarBatteryCarAndGridWithoutPriority() {
        let routes = PowerFlowMath.calculateRoutes(
            solarGeneration: 300,
            gridPower: 500,
            batteryPower: -300,
            carPower: -200,
            homeDemand: 1200,
            minimumRenderableWatts: 0
        )

        XCTAssertEqual(routeWatts(routes, from: .solar, to: .home), 276.923, accuracy: 0.01)
        XCTAssertEqual(routeWatts(routes, from: .battery, to: .home), 276.923, accuracy: 0.01)
        XCTAssertEqual(routeWatts(routes, from: .car, to: .home), 184.615, accuracy: 0.01)
        XCTAssertEqual(routeWatts(routes, from: .grid, to: .home), 461.538, accuracy: 0.01)
    }

    func testBatteryAndCarChargingSplitProportionallyFromAvailableSources() {
        let routes = PowerFlowMath.calculateRoutes(
            solarGeneration: 600,
            gridPower: 500,
            batteryPower: 300,
            carPower: 200,
            homeDemand: 600,
            minimumRenderableWatts: 0
        )

        XCTAssertEqual(routeWatts(routes, from: .solar, to: .battery), 163.636, accuracy: 0.01)
        XCTAssertEqual(routeWatts(routes, from: .grid, to: .battery), 136.364, accuracy: 0.01)
        XCTAssertEqual(routeWatts(routes, from: .solar, to: .car), 109.091, accuracy: 0.01)
        XCTAssertEqual(routeWatts(routes, from: .grid, to: .car), 90.909, accuracy: 0.01)
    }

    func testExportIsSplitProportionallyByAvailableSolarBatteryAndCarExcess() {
        let routes = PowerFlowMath.calculateRoutes(
            solarGeneration: 500,
            gridPower: -500,
            batteryPower: -300,
            carPower: -200,
            homeDemand: 200,
            minimumRenderableWatts: 0
        )

        XCTAssertEqual(routeWatts(routes, from: .solar, to: .grid), 250, accuracy: 0.01)
        XCTAssertEqual(routeWatts(routes, from: .battery, to: .grid), 150, accuracy: 0.01)
        XCTAssertEqual(routeWatts(routes, from: .car, to: .grid), 100, accuracy: 0.01)
    }

    func testRoutesAtOrBelowThresholdAreNotRendered() {
        let routes = PowerFlowMath.calculateRoutes(
            solarGeneration: 21,
            gridPower: 0,
            batteryPower: 0,
            carPower: 0,
            homeDemand: 21,
            minimumRenderableWatts: 20
        )
        XCTAssertEqual(routes.count, 1)

        let noRoutes = PowerFlowMath.calculateRoutes(
            solarGeneration: 20,
            gridPower: 0,
            batteryPower: 0,
            carPower: 0,
            homeDemand: 20,
            minimumRenderableWatts: 20
        )
        XCTAssertTrue(noRoutes.isEmpty)
    }

    private func routeWatts(_ routes: [PowerFlowRoute], from: PowerFlowNode, to: PowerFlowNode) -> Double {
        routes.first(where: { $0.from == from && $0.to == to })?.watts ?? 0
    }
}
