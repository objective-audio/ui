//
//  yas_ui_metal_tests.mm
//

#import <XCTest/XCTest.h>
#import <ui/yas_ui_metal_protocol.h>
#import <sstream>

using namespace yas;

@interface yas_ui_metal_protocol_tests : XCTestCase

@end

@implementation yas_ui_metal_protocol_tests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)test_setup_metal_error_to_string {
    XCTAssertEqual(to_string(ui::setup_metal_error::create_texture_descriptor_failed),
                   "create_texture_descriptor_failed");
    XCTAssertEqual(to_string(ui::setup_metal_error::create_texture_failed), "create_texture_failed");
    XCTAssertEqual(to_string(ui::setup_metal_error::create_sampler_descriptor_failed),
                   "create_sampler_descriptor_failed");
    XCTAssertEqual(to_string(ui::setup_metal_error::create_sampler_failed), "create_sampler_failed");
    XCTAssertEqual(to_string(ui::setup_metal_error::create_vertex_buffer_failed), "create_vertex_buffer_failed");
    XCTAssertEqual(to_string(ui::setup_metal_error::create_index_buffer_failed), "create_index_buffer_failed");
    XCTAssertEqual(to_string(ui::setup_metal_error::create_argument_encoder_failed), "create_argument_encoder_failed");
    XCTAssertEqual(to_string(ui::setup_metal_error::create_argument_buffer_failed), "create_argument_buffer_failed");
    XCTAssertEqual(to_string(ui::setup_metal_error::unknown), "unknown");
}

- (void)test_ostream {
    auto const errors = {ui::setup_metal_error::create_texture_descriptor_failed,
                         ui::setup_metal_error::create_texture_failed,
                         ui::setup_metal_error::create_sampler_descriptor_failed,
                         ui::setup_metal_error::create_sampler_failed,
                         ui::setup_metal_error::create_vertex_buffer_failed,
                         ui::setup_metal_error::create_index_buffer_failed,
                         ui::setup_metal_error::unknown};

    for (auto const &error : errors) {
        std::ostringstream stream;
        stream << error;
        XCTAssertEqual(stream.str(), to_string(error));
    }
}

@end
