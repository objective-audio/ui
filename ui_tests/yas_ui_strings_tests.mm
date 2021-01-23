//
//  yas_ui_strings_tests.mm
//

#import <XCTest/XCTest.h>
#import <ui/ui.h>
#import <iostream>

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
    auto strings = ui::strings::make_shared();

    XCTAssertTrue(strings);
    XCTAssertEqual(strings->text(), "");
    XCTAssertFalse(strings->font_atlas());
    XCTAssertTrue(strings->rect_plane());
    XCTAssertFalse(strings->line_height());
    XCTAssertEqual(strings->alignment(), ui::layout_alignment::min);
}

- (void)test_create_with_args {
    auto device = objc_ptr_with_move_object(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    auto metal_system = ui::metal_system::make_shared(device.object());

    auto texture = ui::texture::make_shared({.point_size = {256, 256}, .scale_factor = 1.0});
    auto font_atlas = ui::font_atlas::make_shared(
        {.font_name = "HelveticaNeue", .font_size = 14.0, .words = "abcde12345", .texture = texture});

    ui::region frame{.origin = {10.0f, 20.0f}, .size = {30.0f, 40.0f}};

    auto strings = ui::strings::make_shared({.max_word_count = 1,
                                             .text = "test_text",
                                             .font_atlas = font_atlas,
                                             .line_height = 10.0f,
                                             .frame = frame,
                                             .alignment = ui::layout_alignment::mid});

    XCTAssertTrue(strings);
    XCTAssertEqual(strings->rect_plane()->data()->dynamic_mesh_data()->max_vertex_count(), 4);
    XCTAssertEqual(strings->text(), "test_text");
    XCTAssertEqual(strings->font_atlas(), font_atlas);
    XCTAssertEqual(strings->line_height(), 10.0f);
    XCTAssertEqual(strings->alignment(), ui::layout_alignment::mid);
}

- (void)test_set_values {
    auto device = objc_ptr_with_move_object(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    auto metal_system = ui::metal_system::make_shared(device.object());

    auto texture = ui::texture::make_shared({.point_size = {256, 256}, .scale_factor = 1.0});
    auto font_atlas = ui::font_atlas::make_shared(
        {.font_name = "HelveticaNeue", .font_size = 14.0, .words = "abcde12345", .texture = texture});

    auto strings = ui::strings::make_shared();

    strings->set_text("test_text");

    XCTAssertEqual(strings->text(), "test_text");
    XCTAssertEqual(strings->rect_plane()->data()->rect_count(), 0);

    strings->set_font_atlas(font_atlas);

    XCTAssertEqual(strings->font_atlas(), font_atlas);
    XCTAssertEqual(strings->rect_plane()->data()->rect_count(), 0);

    XCTAssertFalse(strings->line_height());

    strings->set_line_height(20.0f);

    XCTAssertTrue(strings->line_height());
    XCTAssertEqual(*strings->line_height(), 20.0f);

    strings->set_alignment(ui::layout_alignment::max);

    XCTAssertEqual(strings->alignment(), ui::layout_alignment::max);

    strings->frame_layout_guide_rect()->set_region({.origin = {0.0f, 0.0f}, .size = {1024.0f, 0.0f}});

    XCTAssertEqual(strings->rect_plane()->data()->rect_count(), 0);

    ui::metal_object::cast(texture)->metal_setup(metal_system);

    XCTAssertEqual(strings->rect_plane()->data()->rect_count(), 9);
}

- (void)test_chain_text {
    auto strings = ui::strings::make_shared();

    strings->set_text("a");

    std::string notified;

    auto observer = strings->chain_text().perform([&notified](std::string const &text) { notified = text; }).sync();

    XCTAssertEqual(notified, "a");

    strings->set_text("b");

    XCTAssertEqual(notified, "b");
}

- (void)test_chain_font_atlas {
    auto strings = ui::strings::make_shared();

    ui::font_atlas_ptr notified = nullptr;

    auto observer = strings->chain_font_atlas()
                        .perform([&notified](ui::font_atlas_ptr const &font_atlas) { notified = font_atlas; })
                        .sync();

    XCTAssertFalse(notified);

    auto font_atlas =
        ui::font_atlas::make_shared({.font_name = "HelveticaNeue", .font_size = 14.0, .words = "abcde12345"});

    strings->set_font_atlas(font_atlas);

    XCTAssertTrue(notified);
    XCTAssertEqual(notified->font_name(), "HelveticaNeue");
}

- (void)test_chain_line_height {
    auto strings = ui::strings::make_shared();

    std::optional<float> notified = std::nullopt;

    auto observer = strings->chain_line_height()
                        .perform([&notified](std::optional<float> const &line_height) { notified = line_height; })
                        .sync();

    XCTAssertFalse(notified);

    strings->set_line_height(1.0f);

    XCTAssertTrue(notified);
    XCTAssertEqual(*notified, 1.0f);
}

- (void)test_chain_alignment {
    auto strings = ui::strings::make_shared();

    ui::layout_alignment notified;

    auto observer = strings->chain_alignment()
                        .perform([&notified](ui::layout_alignment const &alignment) { notified = alignment; })
                        .sync();

    XCTAssertEqual(notified, ui::layout_alignment::min);

    strings->set_alignment(ui::layout_alignment::max);

    XCTAssertEqual(notified, ui::layout_alignment::max);
}

- (void)test_no_throw_without_atlas_or_texture {
    auto strings = ui::strings::make_shared();

    XCTAssertNoThrow(strings->set_text("123"));

    XCTAssertNoThrow(strings->frame_layout_guide_rect()->set_region({.origin = {0.0f, 0.0f}, .size = {64.0f, 0.0f}}));

    auto font_atlas = ui::font_atlas::make_shared(
        {.font_name = "HelveticaNeue", .font_size = 14.0, .words = "abcde12345", .texture = nullptr});

    XCTAssertNoThrow(strings->set_font_atlas(font_atlas));
}

- (void)test_text_receiver {
    auto strings = ui::strings::make_shared();

    XCTAssertEqual(strings->text(), "");

    strings->text_receiver()->receive_value("test_text");

    XCTAssertEqual(strings->text(), "test_text");
}

@end
