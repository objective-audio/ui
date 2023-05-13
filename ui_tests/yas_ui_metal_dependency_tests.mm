//
//  yas_ui_metal_dependency_tests.mm
//

#import <XCTest/XCTest.h>
#import <ui/yas_ui_umbrella.h>
#import <sstream>

using namespace yas;
using namespace yas::ui;

@interface yas_ui_metal_dependency_tests : XCTestCase

@end

@implementation yas_ui_metal_dependency_tests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)test_setup_metal_error_to_string {
    XCTAssertEqual(to_string(setup_metal_error::create_texture_descriptor_failed), "create_texture_descriptor_failed");
    XCTAssertEqual(to_string(setup_metal_error::create_texture_failed), "create_texture_failed");
    XCTAssertEqual(to_string(setup_metal_error::create_sampler_descriptor_failed), "create_sampler_descriptor_failed");
    XCTAssertEqual(to_string(setup_metal_error::create_sampler_failed), "create_sampler_failed");
    XCTAssertEqual(to_string(setup_metal_error::create_vertex_buffer_failed), "create_vertex_buffer_failed");
    XCTAssertEqual(to_string(setup_metal_error::create_index_buffer_failed), "create_index_buffer_failed");
    XCTAssertEqual(to_string(setup_metal_error::create_argument_encoder_failed), "create_argument_encoder_failed");
    XCTAssertEqual(to_string(setup_metal_error::create_argument_buffer_failed), "create_argument_buffer_failed");
    XCTAssertEqual(to_string(setup_metal_error::unknown), "unknown");
}

- (void)test_ostream {
    auto const errors = {setup_metal_error::create_texture_descriptor_failed,
                         setup_metal_error::create_texture_failed,
                         setup_metal_error::create_sampler_descriptor_failed,
                         setup_metal_error::create_sampler_failed,
                         setup_metal_error::create_vertex_buffer_failed,
                         setup_metal_error::create_index_buffer_failed,
                         setup_metal_error::unknown};

    for (auto const &error : errors) {
        std::ostringstream stream;
        stream << error;
        XCTAssertEqual(stream.str(), to_string(error));
    }
}

@end
