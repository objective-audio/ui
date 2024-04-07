#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIBundle : NSObject

+ (id<MTLLibrary>)defaultMetalLibraryWithDevice:(id<MTLDevice>)device;

@end

NS_ASSUME_NONNULL_END
