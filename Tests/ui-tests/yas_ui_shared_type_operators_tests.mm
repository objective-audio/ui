//
//  yas_ui_shared_type_operators_tests.mm
//

#import <XCTest/XCTest.h>
#include <ui/common/yas_ui_shared_type_operators.hpp>

using namespace yas;
using namespace yas::ui;

@interface yas_ui_shared_type_operators_tests : XCTestCase

@end

@implementation yas_ui_shared_type_operators_tests

- (void)test_equal_vertex2d_t {
    XCTAssertTrue((vertex2d_t{.position = 1.0f, .tex_coord = 2.0f, .color = 4.0f}) ==
                  (vertex2d_t{.position = 1.0f, .tex_coord = 2.0f, .color = 4.0f}));
    XCTAssertFalse((vertex2d_t{.position = 1.0f, .tex_coord = 2.0f, .color = 4.0f}) ==
                   (vertex2d_t{.position = 8.0f, .tex_coord = 2.0f, .color = 4.0f}));
    XCTAssertFalse((vertex2d_t{.position = 1.0f, .tex_coord = 2.0f, .color = 4.0f}) ==
                   (vertex2d_t{.position = 1.0f, .tex_coord = 8.0f, .color = 4.0f}));
    XCTAssertFalse((vertex2d_t{.position = 1.0f, .tex_coord = 2.0f, .color = 4.0f}) ==
                   (vertex2d_t{.position = 1.0f, .tex_coord = 2.0f, .color = 8.0f}));

    XCTAssertFalse((vertex2d_t{.position = 1.0f, .tex_coord = 2.0f, .color = 4.0f}) !=
                   (vertex2d_t{.position = 1.0f, .tex_coord = 2.0f, .color = 4.0f}));
    XCTAssertTrue((vertex2d_t{.position = 1.0f, .tex_coord = 2.0f, .color = 4.0f}) !=
                  (vertex2d_t{.position = 8.0f, .tex_coord = 2.0f, .color = 4.0f}));
    XCTAssertTrue((vertex2d_t{.position = 1.0f, .tex_coord = 2.0f, .color = 4.0f}) !=
                  (vertex2d_t{.position = 1.0f, .tex_coord = 8.0f, .color = 4.0f}));
    XCTAssertTrue((vertex2d_t{.position = 1.0f, .tex_coord = 2.0f, .color = 4.0f}) !=
                  (vertex2d_t{.position = 1.0f, .tex_coord = 2.0f, .color = 8.0f}));
}

- (void)test_equal_uniform2d_t {
    XCTAssertTrue((uniforms2d_t{.matrix = 1.0f, .color = 2.0f, .use_mesh_color = false}) ==
                  (uniforms2d_t{.matrix = 1.0f, .color = 2.0f, .use_mesh_color = false}));
    XCTAssertFalse((uniforms2d_t{.matrix = 1.0f, .color = 2.0f, .use_mesh_color = false}) ==
                   (uniforms2d_t{.matrix = 4.0f, .color = 2.0f, .use_mesh_color = false}));
    XCTAssertFalse((uniforms2d_t{.matrix = 1.0f, .color = 2.0f, .use_mesh_color = false}) ==
                   (uniforms2d_t{.matrix = 1.0f, .color = 4.0f, .use_mesh_color = false}));
    XCTAssertFalse((uniforms2d_t{.matrix = 1.0f, .color = 2.0f, .use_mesh_color = false}) ==
                   (uniforms2d_t{.matrix = 1.0f, .color = 2.0f, .use_mesh_color = true}));

    XCTAssertFalse((uniforms2d_t{.matrix = 1.0f, .color = 2.0f, .use_mesh_color = false}) !=
                   (uniforms2d_t{.matrix = 1.0f, .color = 2.0f, .use_mesh_color = false}));
    XCTAssertTrue((uniforms2d_t{.matrix = 1.0f, .color = 2.0f, .use_mesh_color = false}) !=
                  (uniforms2d_t{.matrix = 4.0f, .color = 2.0f, .use_mesh_color = false}));
    XCTAssertTrue((uniforms2d_t{.matrix = 1.0f, .color = 2.0f, .use_mesh_color = false}) !=
                  (uniforms2d_t{.matrix = 1.0f, .color = 4.0f, .use_mesh_color = false}));
    XCTAssertTrue((uniforms2d_t{.matrix = 1.0f, .color = 2.0f, .use_mesh_color = false}) !=
                  (uniforms2d_t{.matrix = 1.0f, .color = 2.0f, .use_mesh_color = true}));
}

@end
