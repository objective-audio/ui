//
//  yas_ui_background_tests.mm
//

#import <XCTest/XCTest.h>
#import <ui/yas_ui_background.h>
#import <ui/yas_ui_color.h>

using namespace yas;

@interface yas_ui_background_tests : XCTestCase

@end

@implementation yas_ui_background_tests

- (void)test_updates {
    auto const background = ui::background::make_shared();
    auto const renderable = ui::renderable_background::cast(background);

    XCTAssertTrue(renderable->updates().flags.any());

    renderable->clear_updates();

    XCTAssertFalse(renderable->updates().flags.any());

    background->color()->set_value(ui::gray_color());

    XCTAssertTrue(renderable->updates().flags.any());

    renderable->clear_updates();

    XCTAssertFalse(renderable->updates().flags.any());

    background->alpha()->set_value(0.5f);

    XCTAssertTrue(renderable->updates().flags.any());
}

@end
