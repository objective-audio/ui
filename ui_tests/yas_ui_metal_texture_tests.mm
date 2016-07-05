//
//  yas_ui_metal_texture_tests.mm
//

#import <XCTest/XCTest.h>
#import "yas_ui.h"

using namespace yas;

@interface yas_ui_metal_texture_tests : XCTestCase

@end

@implementation yas_ui_metal_texture_tests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)test_create_metal_texture {
    ui::metal_texture metal_texture{ui::uint_size{1, 2}};

    XCTAssertEqual(metal_texture.size(), (ui::uint_size{1, 2}));
    XCTAssertNil(metal_texture.samplerState());
    XCTAssertNil(metal_texture.texture());
    XCTAssertEqual(metal_texture.texture_type(), MTLTextureType2D);
    XCTAssertEqual(metal_texture.pixel_format(), MTLPixelFormatRGBA8Unorm);
    XCTAssertFalse(metal_texture.metal_system());
}

@end
