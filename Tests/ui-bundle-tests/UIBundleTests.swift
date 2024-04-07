import XCTest
import Metal
@testable import ui_swift_bundle

final class UIBundleTests: XCTestCase {
    func testSwiftBundle() throws {
        let device = try XCTUnwrap(MTLCreateSystemDefaultDevice())
        XCTAssertNotNil(UISwiftBundle.defaultMetalLibrary(device: device))
    }
}
