//
//  yas_ui_strings_node_tests.mm
//

#import <Metal/Metal.h>
#import <XCTest/XCTest.h>
#import <iostream>
#import "yas_objc_ptr.h"
#import "yas_ui_font_atlas.h"
#import "yas_ui_square_node.h"
#import "yas_ui_strings_node.h"

using namespace yas;

@interface yas_ui_strings_node_tests : XCTestCase

@end

@implementation yas_ui_strings_node_tests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)test_create {
    ui::strings_node node{{.font_atlas = nullptr, .max_word_count = 16}};

    XCTAssertTrue(node);

    XCTAssertFalse(node.font_atlas());
    XCTAssertEqual(node.text().size(), 0);
    XCTAssertEqual(node.pivot(), ui::pivot::left);
    XCTAssertEqual(node.width(), 0.0f);

    XCTAssertEqual(node.square_node().square_mesh_data().max_square_count(), 16);
}

- (void)test_create_with_font_atlas {
    ui::font_atlas font_atlas{{.font_name = "HelveticaNeue", .font_size = 14.0, .words = "abcde12345"}};

    ui::strings_node node{{.font_atlas = font_atlas, .max_word_count = 8}};

    XCTAssertTrue(node);

    XCTAssertTrue(node.font_atlas());
    XCTAssertEqual(node.font_atlas(), font_atlas);
}

- (void)test_create_null {
    ui::strings_node node{nullptr};

    XCTAssertFalse(node);
}

- (void)test_variables {
    auto device = make_objc_ptr(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    ui::strings_node node{{.font_atlas = nullptr, .max_word_count = 4}};

    auto texture = ui::make_texture({.device = device.object(), .point_size = {256, 256}, .scale_factor = 1.0}).value();
    ui::font_atlas font_atlas{
        {.font_name = "HelveticaNeue", .font_size = 14.0, .words = "abcde12345", .texture = texture}};
    node.set_font_atlas(font_atlas);

    XCTAssertTrue(node.font_atlas());
    XCTAssertEqual(node.font_atlas(), font_atlas);

    node.set_text("test_text");

    XCTAssertEqual(node.text(), "test_text");

    node.set_pivot(ui::pivot::right);

    XCTAssertEqual(node.pivot(), ui::pivot::right);
}

@end
