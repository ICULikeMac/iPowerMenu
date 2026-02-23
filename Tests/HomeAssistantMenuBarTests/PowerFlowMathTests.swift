import XCTest
@testable import HomeAssistantMenuBar

final class PowerFlowMathTests: XCTestCase {
    func testHomeDemandIsSplitProportionallyBetweenBatteryAndGridAfterSolar() {
        let routes = PowerFlowMath.calculateRoutes(
            solarGeneration: 600,
            gridPower: 500,
            batteryPower: -300,
            homeDemand: 1200,
            minimumRenderableWatts: 0
        )

        XCTAssertEqual(routeWatts(routes, from: .solar, to: .home), 600, accuracy: 0.001)
        XCTAssertEqual(routeWatts(routes, from: .battery, to: .home), 225, accuracy: 0.001)
        XCTAssertEqual(routeWatts(routes, from: .grid, to: .home), 375, accuracy: 0.001)
    }

    func testBatteryChargingUsesSolarExcessThenGridImport() {
        let routes = PowerFlowMath.calculateRoutes(
            solarGeneration: 1000,
            gridPower: 200,
            batteryPower: 300,
            homeDemand: 600,
            minimumRenderableWatts: 0
        )

        XCTAssertEqual(routeWatts(routes, from: .solar, to: .battery), 300, accuracy: 0.001)
        XCTAssertEqual(routeWatts(routes, from: .grid, to: .battery), 0, accuracy: 0.001)
    }

    func testGridCoversBatteryChargingRemainderWhenSolarExcessInsufficient() {
        let routes = PowerFlowMath.calculateRoutes(
            solarGeneration: 700,
            gridPower: 400,
            batteryPower: 300,
            homeDemand: 600,
            minimumRenderableWatts: 0
        )

        XCTAssertEqual(routeWatts(routes, from: .solar, to: .battery), 100, accuracy: 0.001)
        XCTAssertEqual(routeWatts(routes, from: .grid, to: .battery), 200, accuracy: 0.001)
    }

    func testExportIsSplitProportionallyByAvailableSolarAndBatteryExcess() {
        let routes = PowerFlowMath.calculateRoutes(
            solarGeneration: 500,
            gridPower: -300,
            batteryPower: -200,
            homeDemand: 100,
            minimumRenderableWatts: 0
        )

        XCTAssertEqual(routeWatts(routes, from: .solar, to: .grid), 200, accuracy: 0.001)
        XCTAssertEqual(routeWatts(routes, from: .battery, to: .grid), 100, accuracy: 0.001)
    }

    func testRoutesAtOrBelowThresholdAreNotRendered() {
        let routes = PowerFlowMath.calculateRoutes(
            solarGeneration: 21,
            gridPower: 0,
            batteryPower: 0,
            homeDemand: 21,
            minimumRenderableWatts: 20
        )
        XCTAssertEqual(routes.count, 1)

        let noRoutes = PowerFlowMath.calculateRoutes(
            solarGeneration: 20,
            gridPower: 0,
            batteryPower: 0,
            homeDemand: 20,
            minimumRenderableWatts: 20
        )
        XCTAssertTrue(noRoutes.isEmpty)
    }

    private func routeWatts(_ routes: [PowerFlowRoute], from: PowerFlowNode, to: PowerFlowNode) -> Double {
        routes.first(where: { $0.from == from && $0.to == to })?.watts ?? 0
    }
}
