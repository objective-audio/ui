#import "yas_ui_bundle.h"

@implementation UIBundle

+ (id<MTLLibrary>)defaultMetalLibraryWithDevice:(id<MTLDevice>)device {
    return [device newDefaultLibraryWithBundle:SWIFTPM_MODULE_BUNDLE error:nil];
}

@end
