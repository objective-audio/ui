//
//  yas_ui_transformer_tests.mm
//

#import <XCTest/XCTest.h>
#import "yas_ui_transformer.h"

using namespace yas;

@interface yas_ui_transformer_tests : XCTestCase

@end

@implementation yas_ui_transformer_tests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)test_ease_in_sine_transformer {
    auto const &transformer = ui::ease_in_sine_transformer();

    XCTAssertEqual(transformer(0.0f), 0.0f);
    XCTAssertEqualWithAccuracy(transformer(0.125f), 0.019f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.25f), 0.076f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.375f), 0.169f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.5f), 0.293f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.625f), 0.444f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.75f), 0.617f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.875f), 0.805f, 0.001f);
    XCTAssertEqual(transformer(1.0f), 1.0f);
}

- (void)test_ease_out_sine_transformer {
    auto const &transformer = ui::ease_out_sine_transformer();

    XCTAssertEqual(transformer(0.0f), 0.0f);
    XCTAssertEqualWithAccuracy(transformer(0.125f), 0.195f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.25f), 0.383f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.375f), 0.556f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.5f), 0.707f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.625f), 0.831f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.75f), 0.924f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.875f), 0.981f, 0.001f);
    XCTAssertEqual(transformer(1.0f), 1.0f);
}

- (void)test_ease_in_out_sine_transformer {
    auto const &transformer = ui::ease_in_out_sine_transformer();

    XCTAssertEqual(transformer(0.0f), 0.0f);
    XCTAssertEqualWithAccuracy(transformer(0.125f), 0.038f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.25f), 0.146f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.375f), 0.309f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.5f), 0.500f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.625f), 0.691f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.75f), 0.854f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.875f), 0.962f, 0.001f);
    XCTAssertEqual(transformer(1.0f), 1.0f);
}

- (void)test_ease_in_quad_transformer {
    auto const &transformer = ui::ease_in_quad_transformer();

    XCTAssertEqual(transformer(0.0f), 0.0f);
    XCTAssertEqualWithAccuracy(transformer(0.125f), 0.0156f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.25f), 0.0625f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.375f), 0.14f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.5f), 0.25f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.625f), 0.39f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.75f), 0.562f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.875f), 0.765f, 0.001f);
    XCTAssertEqual(transformer(1.0f), 1.0f);
}

- (void)test_ease_out_quad_transformer {
    auto const &transformer = ui::ease_out_quad_transformer();

    XCTAssertEqual(transformer(0.0f), 0.0f);
    XCTAssertEqualWithAccuracy(transformer(0.125f), 0.234f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.25f), 0.437f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.375f), 0.609f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.5f), 0.75f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.625f), 0.859f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.75f), 0.937f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.875f), 0.984f, 0.001f);
    XCTAssertEqual(transformer(1.0f), 1.0f);
}

- (void)test_ease_in_out_quad_transformer {
    auto const &transformer = ui::ease_in_out_quad_transformer();

    XCTAssertEqual(transformer(0.0f), 0.0f);
    XCTAssertEqualWithAccuracy(transformer(0.125f), 0.031f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.25f), 0.125f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.375f), 0.281f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.5f), 0.5f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.625f), 0.718f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.75f), 0.875f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.875f), 0.968f, 0.001f);
    XCTAssertEqual(transformer(1.0f), 1.0f);
}

- (void)test_ease_in_cubic_transformer {
    auto const &transformer = ui::ease_in_cubic_transformer();

    XCTAssertEqual(transformer(0.0f), 0.0f);
    XCTAssertEqualWithAccuracy(transformer(0.125f), 0.002f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.25f), 0.016f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.375f), 0.053f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.5f), 0.125f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.625f), 0.244f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.75f), 0.422f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.875f), 0.670f, 0.001f);
    XCTAssertEqual(transformer(1.0f), 1.0f);
}

- (void)test_ease_out_cubic_transformer {
    auto const &transformer = ui::ease_out_cubic_transformer();

    XCTAssertEqual(transformer(0.0f), 0.0f);
    XCTAssertEqualWithAccuracy(transformer(0.125f), 0.33f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.25f), 0.578f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.375f), 0.756f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.5f), 0.875f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.625f), 0.947f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.75f), 0.984f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.875f), 0.998f, 0.001f);
    XCTAssertEqual(transformer(1.0f), 1.0f);
}

- (void)test_ease_in_out_cubic_transformer {
    auto const &transformer = ui::ease_in_out_cubic_transformer();

    XCTAssertEqual(transformer(0.0f), 0.0f);
    XCTAssertEqualWithAccuracy(transformer(0.125f), 0.008f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.25f), 0.062f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.375f), 0.211f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.5f), 0.5f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.625f), 0.789f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.75f), 0.938f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.875f), 0.992f, 0.001f);
    XCTAssertEqual(transformer(1.0f), 1.0f);
}

- (void)test_ease_in_quart_transformer {
    auto const &transformer = ui::ease_in_quart_transformer();

    XCTAssertEqual(transformer(0.0f), 0.0f);
    XCTAssertEqualWithAccuracy(transformer(0.125f), 0.000f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.25f), 0.004f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.375f), 0.020f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.5f), 0.062f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.625f), 0.153f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.75f), 0.316f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.875f), 0.586f, 0.001f);
    XCTAssertEqual(transformer(1.0f), 1.0f);
}

- (void)test_ease_out_quart_transformer {
    auto const &transformer = ui::ease_out_quart_transformer();

    XCTAssertEqual(transformer(0.0f), 0.0f);
    XCTAssertEqualWithAccuracy(transformer(0.125f), 0.414f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.25f), 0.684f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.375f), 0.847f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.5f), 0.938f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.625f), 0.980f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.75f), 0.996f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.875f), 1.000f, 0.001f);
    XCTAssertEqual(transformer(1.0f), 1.0f);
}

- (void)test_ease_in_out_quart_transformer {
    auto const &transformer = ui::ease_in_out_quart_transformer();

    XCTAssertEqual(transformer(0.0f), 0.0f);
    XCTAssertEqualWithAccuracy(transformer(0.125f), 0.002f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.25f), 0.031f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.375f), 0.158f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.5f), 0.500f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.625f), 0.842f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.75f), 0.969f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.875f), 0.998f, 0.001f);
    XCTAssertEqual(transformer(1.0f), 1.0f);
}

- (void)test_ease_in_quint_transformer {
    auto const &transformer = ui::ease_in_quint_transformer();

    XCTAssertEqual(transformer(0.0f), 0.0f);
    XCTAssertEqualWithAccuracy(transformer(0.125f), 0.000f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.25f), 0.001f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.375f), 0.007f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.5f), 0.031f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.625f), 0.095f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.75f), 0.237f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.875f), 0.513f, 0.001f);
    XCTAssertEqual(transformer(1.0f), 1.0f);
}

- (void)test_ease_out_quint_transformer {
    auto const &transformer = ui::ease_out_quint_transformer();

    XCTAssertEqual(transformer(0.0f), 0.0f);
    XCTAssertEqualWithAccuracy(transformer(0.125f), 0.487f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.25f), 0.763f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.375f), 0.905f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.5f), 0.969f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.625f), 0.993f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.75f), 0.999f, 0.001f);
    XCTAssertEqual(transformer(1.0f), 1.0f);
}

- (void)test_ease_in_out_quint_transformer {
    auto const &transformer = ui::ease_in_out_quint_transformer();

    XCTAssertEqual(transformer(0.0f), 0.0f);
    XCTAssertEqualWithAccuracy(transformer(0.125f), 0.000f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.25f), 0.016f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.375f), 0.119f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.5f), 0.500f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.625f), 0.881f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.75f), 0.984f, 0.001f);
    XCTAssertEqualWithAccuracy(transformer(0.875f), 1.000f, 0.001f);
    XCTAssertEqual(transformer(1.0f), 1.0f);
}

- (void)test_ping_pong_transformer {
    auto const &transformer = ui::ping_pong_transformer();

    XCTAssertEqual(transformer(0.0f), 0.0f);
    XCTAssertEqual(transformer(0.25f), 0.5f);
    XCTAssertEqual(transformer(0.5f), 1.0f);
    XCTAssertEqual(transformer(0.75f), 0.5f);
    XCTAssertEqual(transformer(1.0f), 0.0f);
}

- (void)test_reverse_transformer {
    auto const &transformer = ui::reverse_transformer();

    XCTAssertEqual(transformer(0.0f), 1.0f);
    XCTAssertEqual(transformer(0.25f), 0.75f);
    XCTAssertEqual(transformer(0.5f), 0.5f);
    XCTAssertEqual(transformer(0.75f), 0.25f);
    XCTAssertEqual(transformer(1.0f), 0.0f);
}

- (void)test_connect {
    auto transformer = ui::connect({ui::ping_pong_transformer(), ui::reverse_transformer()});

    XCTAssertEqual(transformer(0.0f), 1.0f);
    XCTAssertEqual(transformer(0.25f), 0.5f);
    XCTAssertEqual(transformer(0.5f), 0.0f);
    XCTAssertEqual(transformer(0.75f), 0.5f);
    XCTAssertEqual(transformer(1.0f), 1.0f);
}

@end
