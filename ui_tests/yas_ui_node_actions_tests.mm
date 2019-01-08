//
//  yas_ui_node_actions_tests.mm
//

#import <XCTest/XCTest.h>
#import <ui/yas_ui_angle.h>
#import <ui/yas_ui_mesh.h>
#import <ui/yas_ui_node.h>
#import <ui/yas_ui_node_actions.h>
#import <unordered_set>

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
    ui::continuous_action::args args{.duration = 1.0, .action = {.begin_time = time}};
    auto action = ui::make_action({.target = target,
                                   .begin_position = {0.0f, -1.0f},
                                   .end_position = {1.0f, 1.0f},
                                   .continuous_action = std::move(args)});

    auto &updatable = action.updatable();

    updatable.update(time);

    XCTAssertEqual(target.position().value().x, 0.0f);
    XCTAssertEqual(target.position().value().y, -1.0f);

    updatable.update(time + 500ms);

    XCTAssertEqual(target.position().value().x, 0.5f);
    XCTAssertEqual(target.position().value().y, 0.0f);

    updatable.update(time + 1s);

    XCTAssertEqual(target.position().value().x, 1.0f);
    XCTAssertEqual(target.position().value().y, 1.0f);
}

- (void)test_update_rotate_action {
    ui::node target;
    auto time = std::chrono::system_clock::now();
    ui::continuous_action::args args{.duration = 1.0, .action = {.begin_time = time}};
    auto action = ui::make_action({.target = target,
                                   .begin_angle = 0.0f,
                                   .end_angle = 360.0f,
                                   .is_shortest = false,
                                   .continuous_action = std::move(args)});

    auto &updatable = action.updatable();

    updatable.update(time);

    XCTAssertEqual(target.angle().value().degrees, 0.0f);

    updatable.update(time + 500ms);

    XCTAssertEqual(target.angle().value().degrees, 180.0f);

    updatable.update(time + 1s);

    XCTAssertEqual(target.angle().value().degrees, 360.0f);
}

- (void)test_update_rotate_action_shortest_1 {
    ui::node target;
    auto time = std::chrono::system_clock::now();
    ui::continuous_action::args args{.duration = 1.0, .action = {.begin_time = time}};
    auto action = ui::make_action({.target = target,
                                   .begin_angle = 0.0f,
                                   .end_angle = 270.0f,
                                   .is_shortest = true,
                                   .continuous_action = std::move(args)});

    auto &updatable = action.updatable();

    updatable.update(time);

    XCTAssertEqual(target.angle().value().degrees, 360.0f);

    updatable.update(time + 500ms);

    XCTAssertEqual(target.angle().value().degrees, 315.0f);

    updatable.update(time + 1s);

    XCTAssertEqual(target.angle().value().degrees, 270.0f);
}

- (void)test_update_rotate_action_shortest_2 {
    ui::node target;
    auto time = std::chrono::system_clock::now();
    ui::continuous_action::args args{.duration = 1.0, .action = {.begin_time = time}};
    auto action = ui::make_action({.target = target,
                                   .begin_angle = -180.0f,
                                   .end_angle = 90.0f,
                                   .is_shortest = true,
                                   .continuous_action = std::move(args)});

    auto &updatable = action.updatable();

    updatable.update(time);

    XCTAssertEqual(target.angle().value().degrees, 180.0f);

    updatable.update(time + 500ms);

    XCTAssertEqual(target.angle().value().degrees, 135.0f);

    updatable.update(time + 1s);

    XCTAssertEqual(target.angle().value().degrees, 90.0f);
}

- (void)test_update_scale_action {
    ui::node target;
    auto time = std::chrono::system_clock::now();
    ui::continuous_action::args args{.duration = 1.0, .action = {.begin_time = time}};
    auto action = ui::make_action({.target = target,
                                   .begin_scale = {0.0f, -1.0f},
                                   .end_scale = {1.0f, 1.0f},
                                   .continuous_action = std::move(args)});

    auto &updatable = action.updatable();

    updatable.update(time);

    XCTAssertEqual(target.scale().value().width, 0.0f);
    XCTAssertEqual(target.scale().value().height, -1.0f);

    updatable.update(time + 500ms);

    XCTAssertEqual(target.scale().value().width, 0.5f);
    XCTAssertEqual(target.scale().value().height, 0.0f);

    updatable.update(time + 1s);

    XCTAssertEqual(target.scale().value().width, 1.0f);
    XCTAssertEqual(target.scale().value().height, 1.0f);
}

- (void)test_update_color_action {
    ui::node target;
    auto time = std::chrono::system_clock::now();
    ui::continuous_action::args args{.duration = 1.0, .action = {.begin_time = time}};
    auto action = ui::make_action({.target = target,
                                   .begin_color = {0.0f, 0.25f, 0.5f},
                                   .end_color = {1.0f, 0.75f, 0.5f},
                                   .continuous_action = std::move(args)});

    ui::mesh mesh;
    target.mesh().set_value(mesh);
    auto &updatable = action.updatable();

    updatable.update(time);

    XCTAssertEqual(target.color().value().red, 0.0f);
    XCTAssertEqual(target.color().value().green, 0.25f);
    XCTAssertEqual(target.color().value().blue, 0.5f);

    updatable.update(time + 500ms);

    XCTAssertEqual(target.color().value().red, 0.5f);
    XCTAssertEqual(target.color().value().green, 0.5f);
    XCTAssertEqual(target.color().value().blue, 0.5f);

    updatable.update(time + 1s);

    XCTAssertEqual(target.color().value().red, 1.0f);
    XCTAssertEqual(target.color().value().green, 0.75f);
    XCTAssertEqual(target.color().value().blue, 0.5f);
}

- (void)test_update_alpha_action {
    ui::node target;
    auto time = std::chrono::system_clock::now();
    ui::continuous_action::args args{.duration = 1.0, .action = {.begin_time = time}};
    auto action = ui::make_action(
        {.target = target, .begin_alpha = 1.0f, .end_alpha = 0.0f, .continuous_action = std::move(args)});

    ui::mesh mesh;
    target.mesh().set_value(mesh);
    auto &updatable = action.updatable();

    updatable.update(time);

    XCTAssertEqual(target.alpha().value(), 1.0f);

    updatable.update(time + 500ms);

    XCTAssertEqual(target.alpha().value(), 0.5f);

    updatable.update(time + 1s);

    XCTAssertEqual(target.alpha().value(), 0.0f);
}

@end
