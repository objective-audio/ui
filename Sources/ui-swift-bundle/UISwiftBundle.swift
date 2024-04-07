import Foundation
import Metal

@objcMembers
public class UISwiftBundle: NSObject {
    public static func defaultMetalLibrary(device: MTLDevice) -> MTLLibrary? {
        try? device.makeDefaultLibrary(bundle: Bundle.module)
    }
}
