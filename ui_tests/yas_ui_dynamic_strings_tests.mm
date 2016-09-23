//
//  yas_ui_dynamic_strings_tests.mm
//

#import <XCTest/XCTest.h>
#import <iostream>
#import "yas_ui_collection_layout.h"
#import "yas_ui_dynamic_strings.h"
#import "yas_ui_font_atlas.h"
#import "yas_ui_rect_plane.h"

using namespace yas;

@interface yas_ui_dynamic_strings_tests : XCTestCase

@end

@implementation yas_ui_dynamic_strings_tests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)test_create_without_args {
    ui::dynamic_strings strings;

    XCTAssertTrue(strings);
    XCTAssertEqual(strings.text(), "");
    XCTAssertFalse(strings.font_atlas());
    XCTAssertTrue(strings.rect_plane());
    XCTAssertEqual(strings.alignment(), ui::layout_alignment::min);
}

- (void)test_create_with_args {
    auto device = make_objc_ptr(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    ui::metal_system metal_system{device.object()};

    auto texture =
        ui::make_texture({.metal_system = metal_system, .point_size = {256, 256}, .scale_factor = 1.0}).value();
    ui::font_atlas font_atlas{
        {.font_name = "HelveticaNeue", .font_size = 14.0, .words = "abcde12345", .texture = texture}};

    ui::region frame{.origin = {10.0f, 20.0f}, .size = {30.0f, 40.0f}};

    ui::dynamic_strings strings{{.max_word_count = 1,
                                 .text = "test_text",
                                 .font_atlas = font_atlas,
                                 .line_height = 10.0f,
                                 .frame = frame,
                                 .alignment = ui::layout_alignment::mid}};

    XCTAssertTrue(strings);
    XCTAssertEqual(strings.rect_plane().data().dynamic_mesh_data().max_vertex_count(), 4);
    XCTAssertEqual(strings.text(), "test_text");
    XCTAssertEqual(strings.font_atlas(), font_atlas);
    XCTAssertEqual(strings.line_height(), 10.0f);
    XCTAssertEqual(strings.alignment(), ui::layout_alignment::mid);
}

- (void)test_create_null {
    ui::dynamic_strings strings = nullptr;

    XCTAssertFalse(strings);
}

@end
