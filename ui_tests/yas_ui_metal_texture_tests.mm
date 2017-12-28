//
//  yas_ui_metal_texture_tests.mm
//

#import <XCTest/XCTest.h>
#import <iostream>
#import "yas_objc_ptr.h"
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

- (void)test_create {
    ui::metal_texture metal_texture{ui::uint_size{1, 2}, false};

    XCTAssertEqual(metal_texture.size(), (ui::uint_size{1, 2}));
    XCTAssertNil(metal_texture.samplerState());
    XCTAssertNil(metal_texture.texture());
    XCTAssertEqual(metal_texture.texture_type(), MTLTextureType2D);
    XCTAssertEqual(metal_texture.pixel_format(), MTLPixelFormatRGBA8Unorm);
    XCTAssertFalse(metal_texture.metal_system());
}

- (void)test_create_for_render_target {
    ui::metal_texture metal_texture{ui::uint_size{1, 2}, true};

    XCTAssertEqual(metal_texture.size(), (ui::uint_size{1, 2}));
    XCTAssertNil(metal_texture.samplerState());
    XCTAssertNil(metal_texture.texture());
    XCTAssertEqual(metal_texture.texture_type(), MTLTextureType2D);
    XCTAssertEqual(metal_texture.pixel_format(), MTLPixelFormatBGRA8Unorm);
    XCTAssertFalse(metal_texture.metal_system());
}

- (void)test_metal_setup {
    auto device = make_objc_ptr(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    ui::metal_texture metal_texture{ui::uint_size{1, 2}, false};

    ui::metal_system metal_system{device.object()};
    XCTAssertTrue(metal_texture.metal().metal_setup(metal_system));

    XCTAssertTrue(metal_texture.metal_system());
    XCTAssertNotNil(metal_texture.samplerState());
    XCTAssertNotNil(metal_texture.texture());
}

@end
