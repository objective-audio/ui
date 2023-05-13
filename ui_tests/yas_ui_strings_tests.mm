//
//  yas_ui_strings_tests.mm
//

#import <XCTest/XCTest.h>
#import <ui/yas_ui_umbrella.h>
#import <iostream>
#import "yas_ui_view_look_stubs.h"

using namespace yas;
using namespace yas::ui;

@interface yas_ui_strings_tests : XCTestCase

@end

@implementation yas_ui_strings_tests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)test_create_with_args {
    auto const view_look = view_look_scale_factor_stub::make_shared(1.0);

    auto const texture = texture::make_shared({.point_size = {256, 256}}, view_look);
    auto const font_atlas =
        font_atlas::make_shared({.font_name = "HelveticaNeue", .font_size = 14.0, .words = "abcde12345"}, texture);

    region frame{.origin = {10.0f, 20.0f}, .size = {30.0f, 40.0f}};

    std::vector<strings_attribute> const attributes{
        {.range = std::nullopt, .color = to_color(ui::white_color(), 1.0f)},
        {.range = index_range{.index = 1, .length = 2}, .color = to_color(ui::red_color(), 0.5f)}};

    auto strings = strings::make_shared({.max_word_count = 1,
                                         .text = "test_text",
                                         .attributes = attributes,
                                         .line_height = 10.0f,
                                         .frame = frame,
                                         .alignment = layout_alignment::mid},
                                        font_atlas);

    XCTAssertTrue(strings);
    XCTAssertEqual(strings->rect_plane()->data()->dynamic_vertex_data()->max_count(), 4);
    XCTAssertEqual(strings->text(), "test_text");
    XCTAssertEqual(strings->attributes().size(), 2);
    XCTAssertEqual(strings->attributes(), attributes);
    XCTAssertEqual(strings->font_atlas(), font_atlas);
    XCTAssertEqual(strings->line_height(), 10.0f);
    XCTAssertEqual(strings->alignment(), layout_alignment::mid);
}

- (void)test_set_values {
    auto device = objc_ptr_with_move_object(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    auto const metal_system = metal_system::make_shared(device.object(), nil);
    auto const view_look = view_look_scale_factor_stub::make_shared(1.0);

    auto texture = texture::make_shared({.point_size = {256, 256}}, view_look);
    auto font_atlas =
        font_atlas::make_shared({.font_name = "HelveticaNeue", .font_size = 14.0, .words = "abcde12345"}, texture);

    auto strings = strings::make_shared({}, font_atlas);

    strings->set_text("test_text");

    XCTAssertEqual(strings->text(), "test_text");
    XCTAssertEqual(strings->rect_plane()->data()->rect_count(), 0);

    XCTAssertFalse(strings->line_height());

    strings->set_line_height(20.0f);

    XCTAssertTrue(strings->line_height());
    XCTAssertEqual(*strings->line_height(), 20.0f);

    strings->set_alignment(layout_alignment::max);

    XCTAssertEqual(strings->alignment(), layout_alignment::max);

    strings->preferred_layout_guide()->set_region({.origin = {0.0f, 0.0f}, .size = {1024.0f, 0.0f}});

    XCTAssertEqual(strings->rect_plane()->data()->rect_count(), 0);

    texture->metal_setup(metal_system);

    XCTAssertEqual(strings->rect_plane()->data()->rect_count(), 9);
}

- (void)test_observe_text {
    auto const strings = [self make_strings];

    strings->set_text("a");

    std::string notified;

    auto canceller = strings->observe_text([&notified](std::string const &text) { notified = text; }).sync();

    XCTAssertEqual(notified, "a");

    strings->set_text("b");

    XCTAssertEqual(notified, "b");
}

- (void)test_observe_line_height {
    auto const strings = [self make_strings];

    std::optional<float> notified = std::nullopt;

    auto observer =
        strings->observe_line_height([&notified](std::optional<float> const &line_height) { notified = line_height; })
            .sync();

    XCTAssertFalse(notified);

    strings->set_line_height(1.0f);

    XCTAssertTrue(notified);
    XCTAssertEqual(*notified, 1.0f);
}

- (void)test_observe_alignment {
    auto const strings = [self make_strings];

    layout_alignment notified;

    auto canceller =
        strings->observe_alignment([&notified](layout_alignment const &alignment) { notified = alignment; }).sync();

    XCTAssertEqual(notified, layout_alignment::min);

    strings->set_alignment(layout_alignment::max);

    XCTAssertEqual(notified, layout_alignment::max);
}

- (void)test_observe_actual_cell_regions {
    auto const strings = [self make_strings];

    std::vector<region> notified;

    auto canceller =
        strings->observe_actual_cell_regions([&notified](auto const &regions) { notified = regions; }).sync();

    XCTAssertEqual(notified.size(), 0);

    // metal_textureをセットしないと更新されない
}

- (void)test_observe_attributes {
    auto const strings = [self make_strings];

    std::vector<strings_attribute> notified;

    auto canceller = strings->observe_attributes([&notified](auto const &attributes) { notified = attributes; }).sync();

    XCTAssertEqual(notified.size(), 0);

    strings->set_attributes(
        {{.range = index_range{.index = 1, .length = 2}, .color = to_color(ui::blue_color(), 0.5f)}});

    XCTAssertEqual(notified.size(), 1);

    XCTAssertEqual(notified, (std::vector<strings_attribute>{{.range = index_range{.index = 1, .length = 2},
                                                              .color = to_color(ui::blue_color(), 0.5f)}}));
}

- (std::shared_ptr<ui::strings>)make_strings {
    auto const view_look = view_look_scale_factor_stub::make_shared(1.0);
    auto const texture = texture::make_shared({.point_size = {256, 256}}, view_look);
    auto const font_atlas =
        font_atlas::make_shared({.font_name = "HelveticaNeue", .font_size = 14.0, .words = "abcde12345"}, texture);

    return strings::make_shared({}, font_atlas);
}

@end
