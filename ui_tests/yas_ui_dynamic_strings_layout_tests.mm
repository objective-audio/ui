//
//  yas_ui_strings_dynamic_layout_tests.mm
//

#import <XCTest/XCTest.h>
#import <iostream>
#import "yas_ui_dynamic_strings_layout.h"
#import "yas_ui_layout_guide.h"
#import "yas_ui_rect_plane.h"

#import "yas_ui_collection_layout.h"

using namespace yas;

@interface yas_ui_dynamic_strings_layout_tests : XCTestCase

@end

@implementation yas_ui_dynamic_strings_layout_tests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)test_create_dynamic_strings_layout_fill_args {
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

    ui::region frame{{.origin = {1.0f, 2.0f}, .size = {3.0f, 4.0f}}};

    ui::dynamic_strings_layout strings_layout{{.text = "a1z",
                                               .font_atlas = font_atlas,
                                               .line_height = 1.0f,
                                               .frame = frame,
                                               .alignment = ui::layout_alignment::max}};

    XCTAssertEqual(strings_layout.text(), "a1z");
    XCTAssertEqual(strings_layout.font_atlas(), font_atlas);
    XCTAssertEqual(strings_layout.line_height(), 1.0f);
    XCTAssertEqual(strings_layout.alignment(), ui::layout_alignment::max);
    XCTAssertTrue(strings_layout.frame_layout_guide_rect().region() == frame);
}

- (void)test_create_dynamic_strings_layout_empty_args {
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

    ui::dynamic_strings_layout strings_layout;

    XCTAssertEqual(strings_layout.text(), "");
    XCTAssertFalse(strings_layout.font_atlas());
    XCTAssertEqual(strings_layout.line_height(), 0.0f);
    XCTAssertEqual(strings_layout.alignment(), ui::layout_alignment::min);
}

- (void)test_dynamic_strings_layout_set_values {
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

    ui::dynamic_strings_layout strings_layout;

    strings_layout.set_text("test_text");

    XCTAssertEqual(strings_layout.text(), "test_text");
    XCTAssertEqual(strings_layout.rect_plane().data().rect_count(), 0);

    strings_layout.set_font_atlas(font_atlas);

    XCTAssertEqual(strings_layout.font_atlas(), font_atlas);
    XCTAssertGreaterThan(strings_layout.line_height(), 0.0f);
    XCTAssertEqual(strings_layout.rect_plane().data().rect_count(), 0);

    strings_layout.set_line_height(20.0f);

    XCTAssertEqual(strings_layout.line_height(), 20.0f);

    strings_layout.set_alignment(ui::layout_alignment::max);

    XCTAssertEqual(strings_layout.alignment(), ui::layout_alignment::max);

    strings_layout.frame_layout_guide_rect().set_region({.origin = {0.0f, 0.0f}, .size = {1024.0f, 0.0f}});

    XCTAssertEqual(strings_layout.rect_plane().data().rect_count(), 9);
}

@end
