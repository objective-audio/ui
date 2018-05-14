//
//  yas_ui_strings_tests.mm
//

#import <XCTest/XCTest.h>
#import <iostream>
#import "yas_ui_collection_layout.h"
#import "yas_ui_font_atlas.h"
#import "yas_ui_layout_guide.h"
#import "yas_ui_rect_plane.h"
#import "yas_ui_strings.h"

using namespace yas;

@interface yas_ui_strings_tests : XCTestCase

@end

@implementation yas_ui_strings_tests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)test_create_without_args {
    ui::strings strings;

    XCTAssertTrue(strings);
    XCTAssertEqual(strings.text(), "");
    XCTAssertFalse(strings.font_atlas());
    XCTAssertTrue(strings.rect_plane());
    XCTAssertFalse(strings.line_height());
    XCTAssertEqual(strings.alignment(), ui::layout_alignment::min);
}

- (void)test_create_with_args {
    auto device = make_objc_ptr(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    ui::metal_system metal_system{device.object()};

    ui::texture texture{{.point_size = {256, 256}, .scale_factor = 1.0}};
    ui::font_atlas font_atlas{
        {.font_name = "HelveticaNeue", .font_size = 14.0, .words = "abcde12345", .texture = texture}};

    ui::region frame{.origin = {10.0f, 20.0f}, .size = {30.0f, 40.0f}};

    ui::strings strings{{.max_word_count = 1,
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
    ui::strings strings = nullptr;

    XCTAssertFalse(strings);
}

- (void)test_set_values {
    auto device = make_objc_ptr(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    ui::metal_system metal_system{device.object()};

    ui::texture texture{{.point_size = {256, 256}, .scale_factor = 1.0}};
    ui::font_atlas font_atlas{
        {.font_name = "HelveticaNeue", .font_size = 14.0, .words = "abcde12345", .texture = texture}};

    ui::strings strings;

    strings.set_text("test_text");

    XCTAssertEqual(strings.text(), "test_text");
    XCTAssertEqual(strings.rect_plane().data().rect_count(), 0);

    strings.set_font_atlas(font_atlas);

    XCTAssertEqual(strings.font_atlas(), font_atlas);
    XCTAssertEqual(strings.rect_plane().data().rect_count(), 0);

    XCTAssertFalse(strings.line_height());

    strings.set_line_height(20.0f);

    XCTAssertTrue(strings.line_height());
    XCTAssertEqual(*strings.line_height(), 20.0f);

    strings.set_alignment(ui::layout_alignment::max);

    XCTAssertEqual(strings.alignment(), ui::layout_alignment::max);

    strings.frame_layout_guide_rect().set_region({.origin = {0.0f, 0.0f}, .size = {1024.0f, 0.0f}});

    XCTAssertEqual(strings.rect_plane().data().rect_count(), 0);

    texture.metal().metal_setup(metal_system);

    XCTAssertEqual(strings.rect_plane().data().rect_count(), 9);
}

- (void)test_notity {
    ui::font_atlas font_atlas{{.font_name = "HelveticaNeue", .font_size = 14.0, .words = "abcde12345"}};

    ui::strings strings;

    std::experimental::optional<ui::strings::method> notified_method;

    auto observer = strings.subject().make_wild_card_observer(
        [&notified_method](auto const &context) { notified_method = context.key; });

    strings.set_text("test_text");

    XCTAssertEqual(*notified_method, ui::strings::method::text_changed);

    notified_method = nullopt;

    strings.set_font_atlas(font_atlas);

    XCTAssertEqual(*notified_method, ui::strings::method::font_atlas_changed);

    notified_method = nullopt;

    strings.set_line_height(1.0f);

    XCTAssertEqual(*notified_method, ui::strings::method::line_height_changed);

    notified_method = nullopt;

    strings.set_alignment(ui::layout_alignment::max);

    XCTAssertEqual(*notified_method, ui::strings::method::alignment_changed);
}

- (void)test_no_throw_without_atlas_or_texture {
    ui::strings strings;

    XCTAssertNoThrow(strings.set_text("123"));

    XCTAssertNoThrow(strings.frame_layout_guide_rect().set_region({.origin = {0.0f, 0.0f}, .size = {64.0f, 0.0f}}));

    ui::font_atlas font_atlas{
        {.font_name = "HelveticaNeue", .font_size = 14.0, .words = "abcde12345", .texture = nullptr}};

    XCTAssertNoThrow(strings.set_font_atlas(font_atlas));
}

- (void)test_text_receiver {
    ui::strings strings;

    flow::sender<std::string> sender;

    auto flow = sender.begin().end(strings.text_receiver());

    XCTAssertEqual(strings.text(), "");

    sender.send_value("test_text");

    XCTAssertEqual(strings.text(), "test_text");
}

@end
