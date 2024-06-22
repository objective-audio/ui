import XCTest
import Metal
@testable import ui_bundle

final class UIBundleTests: XCTestCase {
    func testBundle() throws {
        let device = try XCTUnwrap(MTLCreateSystemDefaultDevice())
        XCTAssertNotNil(UIBundle.defaultMetalLibrary(with: device))
    }
}
