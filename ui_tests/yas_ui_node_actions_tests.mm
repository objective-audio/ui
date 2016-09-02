//
//  yas_ui_node_actions_tests.mm
//

#import <XCTest/XCTest.h>
#import "yas_ui_node_actions.h"

#import <unordered_set>
#import "yas_ui_action.h"
#import "yas_ui_mesh.h"
#import "yas_ui_node.h"

using namespace std::chrono_literals;
using namespace yas;

@interface yas_ui_node_actions_tests : XCTestCase

@end

@implementation yas_ui_node_actions_tests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)test_update_translate_action {
    ui::node target;
    auto time = std::chrono::system_clock::now();
    ui::continuous_action::args args{.duration = 1.0, .action = {.start_time = time}};
    auto action = ui::make_action({.target = target,
                                   .start_position = {0.0f, -1.0f},
                                   .end_position = {1.0f, 1.0f},
                                   .continuous_action = std::move(args)});

    auto &updatable = action.updatable();

    updatable.update(time);

    XCTAssertEqual(target.position().x, 0.0f);
    XCTAssertEqual(target.position().y, -1.0f);

    updatable.update(time + 500ms);

    XCTAssertEqual(target.position().x, 0.5f);
    XCTAssertEqual(target.position().y, 0.0f);

    updatable.update(time + 1s);

    XCTAssertEqual(target.position().x, 1.0f);
    XCTAssertEqual(target.position().y, 1.0f);
}

- (void)test_update_rotate_action {
    ui::node target;
    auto time = std::chrono::system_clock::now();
    ui::continuous_action::args args{.duration = 1.0, .action = {.start_time = time}};
    auto action = ui::make_action({.target = target,
                                   .start_angle = 0.0f,
                                   .end_angle = 360.0f,
                                   .is_shortest = false,
                                   .continuous_action = std::move(args)});

    auto &updatable = action.updatable();

    updatable.update(time);

    XCTAssertEqual(target.angle(), 0.0f);

    updatable.update(time + 500ms);

    XCTAssertEqual(target.angle(), 180.0f);

    updatable.update(time + 1s);

    XCTAssertEqual(target.angle(), 360.0f);
}

- (void)test_update_rotate_action_shortest_1 {
    ui::node target;
    auto time = std::chrono::system_clock::now();
    ui::continuous_action::args args{.duration = 1.0, .action = {.start_time = time}};
    auto action = ui::make_action({.target = target,
                                   .start_angle = 0.0f,
                                   .end_angle = 270.0f,
                                   .is_shortest = true,
                                   .continuous_action = std::move(args)});

    auto &updatable = action.updatable();

    updatable.update(time);

    XCTAssertEqual(target.angle(), 360.0f);

    updatable.update(time + 500ms);

    XCTAssertEqual(target.angle(), 315.0f);

    updatable.update(time + 1s);

    XCTAssertEqual(target.angle(), 270.0f);
}

- (void)test_update_rotate_action_shortest_2 {
    ui::node target;
    auto time = std::chrono::system_clock::now();
    ui::continuous_action::args args{.duration = 1.0, .action = {.start_time = time}};
    auto action = ui::make_action({.target = target,
                                   .start_angle = -180.0f,
                                   .end_angle = 90.0f,
                                   .is_shortest = true,
                                   .continuous_action = std::move(args)});

    auto &updatable = action.updatable();

    updatable.update(time);

    XCTAssertEqual(target.angle(), 180.0f);

    updatable.update(time + 500ms);

    XCTAssertEqual(target.angle(), 135.0f);

    updatable.update(time + 1s);

    XCTAssertEqual(target.angle(), 90.0f);
}

- (void)test_update_scale_action {
    ui::node target;
    auto time = std::chrono::system_clock::now();
    ui::continuous_action::args args{.duration = 1.0, .action = {.start_time = time}};
    auto action = ui::make_action({.target = target,
                                   .start_scale = {0.0f, -1.0f},
                                   .end_scale = {1.0f, 1.0f},
                                   .continuous_action = std::move(args)});

    auto &updatable = action.updatable();

    updatable.update(time);

    XCTAssertEqual(target.scale().width, 0.0f);
    XCTAssertEqual(target.scale().height, -1.0f);

    updatable.update(time + 500ms);

    XCTAssertEqual(target.scale().width, 0.5f);
    XCTAssertEqual(target.scale().height, 0.0f);

    updatable.update(time + 1s);

    XCTAssertEqual(target.scale().width, 1.0f);
    XCTAssertEqual(target.scale().height, 1.0f);
}

- (void)test_update_color_action {
    ui::node target;
    auto time = std::chrono::system_clock::now();
    ui::continuous_action::args args{.duration = 1.0, .action = {.start_time = time}};
    auto action = ui::make_action({.target = target,
                                   .start_color = {0.0f, 0.25f, 0.5f},
                                   .end_color = {1.0f, 0.75f, 0.5f},
                                   .continuous_action = std::move(args)});

    ui::mesh mesh;
    target.set_mesh(mesh);
    auto &updatable = action.updatable();

    updatable.update(time);

    XCTAssertEqual(target.color().red, 0.0f);
    XCTAssertEqual(target.color().green, 0.25f);
    XCTAssertEqual(target.color().blue, 0.5f);

    updatable.update(time + 500ms);

    XCTAssertEqual(target.color().red, 0.5f);
    XCTAssertEqual(target.color().green, 0.5f);
    XCTAssertEqual(target.color().blue, 0.5f);

    updatable.update(time + 1s);

    XCTAssertEqual(target.color().red, 1.0f);
    XCTAssertEqual(target.color().green, 0.75f);
    XCTAssertEqual(target.color().blue, 0.5f);
}

- (void)test_update_alpha_action {
    ui::node target;
    auto time = std::chrono::system_clock::now();
    ui::continuous_action::args args{.duration = 1.0, .action = {.start_time = time}};
    auto action = ui::make_action(
        {.target = target, .start_alpha = 1.0f, .end_alpha = 0.0f, .continuous_action = std::move(args)});

    ui::mesh mesh;
    target.set_mesh(mesh);
    auto &updatable = action.updatable();

    updatable.update(time);

    XCTAssertEqual(target.alpha(), 1.0f);

    updatable.update(time + 500ms);

    XCTAssertEqual(target.alpha(), 0.5f);

    updatable.update(time + 1s);

    XCTAssertEqual(target.alpha(), 0.0f);
}

@end