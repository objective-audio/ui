//
//  yas_ui_metal_texture_tests.mm
//

#import <XCTest/XCTest.h>
#import <cpp_utils/yas_objc_ptr.h>
#import <ui/yas_ui_umbrella.h>
#import <iostream>

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
    ui::metal_texture metal_texture{
        ui::uint_size{1, 2}, {ui::texture_usage::shader_read}, ui::pixel_format::rgba8_unorm};

    XCTAssertEqual(metal_texture.size(), (ui::uint_size{1, 2}));
    XCTAssertNil(metal_texture.samplerState());
    XCTAssertNil(metal_texture.texture());
    XCTAssertEqual(metal_texture.texture_type(), MTLTextureType2D);
    XCTAssertEqual(metal_texture.pixel_format(), MTLPixelFormatRGBA8Unorm);
    XCTAssertEqual(metal_texture.texture_usage(), MTLTextureUsageShaderRead);
    XCTAssertFalse(metal_texture.metal_system());
}

- (void)test_create_for_render_target {
    ui::metal_texture metal_texture{
        ui::uint_size{1, 2}, {ui::texture_usage::render_target}, ui::pixel_format::bgra8_unorm};

    XCTAssertEqual(metal_texture.size(), (ui::uint_size{1, 2}));
    XCTAssertNil(metal_texture.samplerState());
    XCTAssertNil(metal_texture.texture());
    XCTAssertEqual(metal_texture.texture_type(), MTLTextureType2D);
    XCTAssertEqual(metal_texture.pixel_format(), MTLPixelFormatBGRA8Unorm);
    XCTAssertEqual(metal_texture.texture_usage(), MTLTextureUsageRenderTarget);
    XCTAssertFalse(metal_texture.metal_system());
}

- (void)test_metal_setup {
    auto device = make_objc_ptr(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    ui::metal_texture metal_texture{
        ui::uint_size{1, 2}, {ui::texture_usage::shader_read}, ui::pixel_format::rgba8_unorm};

    ui::metal_system metal_system{device.object()};
    XCTAssertTrue(metal_texture.metal().metal_setup(metal_system));

    XCTAssertTrue(metal_texture.metal_system());
    XCTAssertNotNil(metal_texture.samplerState());
    XCTAssertNotNil(metal_texture.texture());
}

@end
