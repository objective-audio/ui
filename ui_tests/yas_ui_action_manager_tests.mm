//
//  yas_ui_action_manager_tests.mm
//

#import <XCTest/XCTest.h>
#import <ui/ui.h>

using namespace yas;
using namespace yas::ui;

@interface yas_ui_action_manager_tests : XCTestCase

@end

@implementation yas_ui_action_manager_tests

- (void)test_action {
    auto manager = ui::action_manager::make_shared();

    auto target1 = ui::node::make_shared();
    auto target2 = ui::node::make_shared();
    auto action1 = ui::action::make_shared({.target = target1});
    auto action2 = ui::action::make_shared({.target = target2});

    manager->insert_action(action1);

    XCTAssertEqual(manager->actions().size(), 1);
    XCTAssertEqual(manager->actions().at(0), action1);

    manager->insert_action(action2);

    XCTAssertEqual(manager->actions().size(), 2);

    manager->erase_action(target1);

    XCTAssertEqual(manager->actions().size(), 1);
    XCTAssertEqual(manager->actions().at(0), action2);

    manager->erase_action(action2);

    XCTAssertEqual(manager->actions().size(), 0);
}

@end
