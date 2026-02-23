import XCTest
@testable import HomeAssistantMenuBar

final class PowerFlowRenderingSupportTests: XCTestCase {
    func testVisibleNodePairsHaveSegmentsAndCarPairIsHidden() {
        let layout = PowerFlowLayout(
            size: CGSize(width: 400, height: 300),
            circleRadius: 50,
            padding: 5,
            curveScale: 0.15,
            minCurve: 20,
            maxCurve: 50
        )

        XCTAssertNotNil(PowerFlowPathBuilder.segment(in: layout, from: .solar, to: .home))
        XCTAssertNil(PowerFlowPathBuilder.segment(in: layout, from: .car, to: .home))
    }
}
