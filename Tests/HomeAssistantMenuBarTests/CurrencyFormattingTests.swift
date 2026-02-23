import XCTest
@testable import HomeAssistantMenuBar

final class CurrencyFormattingTests: XCTestCase {
    func testParsesAndFormatsSignedCurrencyStrings() {
        XCTAssertEqual(CurrencyFormatting.format(raw: "-$0.051"), "-$0.051/kWh")
        XCTAssertEqual(CurrencyFormatting.format(raw: "$-0.052"), "-$0.052/kWh")
        XCTAssertEqual(CurrencyFormatting.format(raw: "-0.053 /kWh"), "-$0.053/kWh")
        XCTAssertEqual(CurrencyFormatting.format(raw: "0.054"), "$0.054/kWh")
    }

    func testInvalidCurrencyStringFallsBackToPlaceholder() {
        XCTAssertEqual(CurrencyFormatting.format(raw: "not-a-number"), "$---.---/kWh")
    }
}
