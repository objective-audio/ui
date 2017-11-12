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
    XCTAssertLessThan(transformer(0.25f), 0.25f);
    XCTAssertLessThan(transformer(0.5f), 0.5f);
    XCTAssertLessThan(transformer(0.75f), 0.75f);
    XCTAssertEqual(transformer(1.0f), 1.0f);
}

- (void)test_ease_out_sine_transformer {
    auto const &transformer = ui::ease_out_sine_transformer();

    XCTAssertEqual(transformer(0.0f), 0.0f);
    XCTAssertGreaterThan(transformer(0.25f), 0.25f);
    XCTAssertGreaterThan(transformer(0.5f), 0.5f);
    XCTAssertGreaterThan(transformer(0.75f), 0.75f);
    XCTAssertEqual(transformer(1.0f), 1.0f);
}

- (void)test_ease_in_out_sine_transformer {
    auto const &transformer = ui::ease_in_out_sine_transformer();

    XCTAssertEqual(transformer(0.0f), 0.0f);
    XCTAssertLessThan(transformer(0.25f), 0.25f);
    XCTAssertEqual(transformer(0.5f), 0.5f);
    XCTAssertGreaterThan(transformer(0.75f), 0.75f);
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
