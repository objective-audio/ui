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

    auto const node1 = ui::node::make_shared();
    auto const node2 = ui::node::make_shared();
    auto const group1 = ui::action_group::make_shared();
    auto const group2 = ui::action_group::make_shared();
    auto const action1 = ui::action::make_shared({.group = group1});
    auto const action2 = ui::action::make_shared({.group = group2});

    manager->insert_action(action1);

    XCTAssertEqual(manager->actions().size(), 1);
    XCTAssertEqual(manager->actions().at(0), action1);

    manager->insert_action(action2);

    XCTAssertEqual(manager->actions().size(), 2);

    manager->erase_action(group1);

    XCTAssertEqual(manager->actions().size(), 1);
    XCTAssertEqual(manager->actions().at(0), action2);

    manager->erase_action(action2);

    XCTAssertEqual(manager->actions().size(), 0);
}

@end
