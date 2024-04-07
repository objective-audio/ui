#import "yas_ui_bundle.h"

@import ui_swift_bundle;

@implementation UIBundle

+ (id<MTLLibrary>)defaultMetalLibraryWithDevice:(id<MTLDevice>)device {
    return [UISwiftBundle defaultMetalLibraryWithDevice:device];
}

@end
