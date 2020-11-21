//
//  yas_ui_metal_texture_tests.mm
//

#import <XCTest/XCTest.h>
#import <cpp_utils/yas_objc_ptr.h>
#import <ui/ui.h>
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
    auto metal_texture = ui::metal_texture::make_shared(ui::uint_size{1, 2}, {ui::texture_usage::shader_read},
                                                        ui::pixel_format::rgba8_unorm);

    XCTAssertEqual(metal_texture->size(), (ui::uint_size{1, 2}));
    XCTAssertNil(metal_texture->samplerState());
    XCTAssertNil(metal_texture->texture());
    XCTAssertEqual(metal_texture->texture_type(), MTLTextureType2D);
    XCTAssertEqual(metal_texture->pixel_format(), MTLPixelFormatRGBA8Unorm);
    XCTAssertEqual(metal_texture->texture_usage(), MTLTextureUsageShaderRead);
    XCTAssertFalse(metal_texture->metal_system());
}

- (void)test_create_for_render_target {
    auto metal_texture = ui::metal_texture::make_shared(ui::uint_size{1, 2}, {ui::texture_usage::render_target},
                                                        ui::pixel_format::bgra8_unorm);

    XCTAssertEqual(metal_texture->size(), (ui::uint_size{1, 2}));
    XCTAssertNil(metal_texture->samplerState());
    XCTAssertNil(metal_texture->texture());
    XCTAssertEqual(metal_texture->texture_type(), MTLTextureType2D);
    XCTAssertEqual(metal_texture->pixel_format(), MTLPixelFormatBGRA8Unorm);
    XCTAssertEqual(metal_texture->texture_usage(), MTLTextureUsageRenderTarget);
    XCTAssertFalse(metal_texture->metal_system());
}

- (void)test_metal_setup {
    auto device = objc_ptr_with_move_object(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    auto metal_texture = ui::metal_texture::make_shared(ui::uint_size{1, 2}, {ui::texture_usage::shader_read},
                                                        ui::pixel_format::rgba8_unorm);

    auto metal_system = ui::metal_system::make_shared(device.object());
    XCTAssertTrue(ui::metal_object::cast(metal_texture)->metal_setup(metal_system));

    XCTAssertTrue(metal_texture->metal_system());
    XCTAssertNotNil(metal_texture->samplerState());
    XCTAssertNotNil(metal_texture->texture());
}

@end
