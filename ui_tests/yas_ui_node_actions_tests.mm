//
//  yas_ui_node_actions_tests.mm
//

#import <XCTest/XCTest.h>
#import <ui/ui.h>
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
    auto target = ui::node::make_shared();
    auto time = std::chrono::system_clock::now();
    ui::continuous_action::args args{.duration = 1.0, .action = {.begin_time = time}};
    auto action = ui::make_action({.target = target,
                                   .begin_position = {0.0f, -1.0f},
                                   .end_position = {1.0f, 1.0f},
                                   .continuous_action = std::move(args)});

    auto const updatable = ui::updatable_action::cast(action);

    updatable->update(time);

    XCTAssertEqual(target->position().x, 0.0f);
    XCTAssertEqual(target->position().y, -1.0f);

    updatable->update(time + 500ms);

    XCTAssertEqual(target->position().x, 0.5f);
    XCTAssertEqual(target->position().y, 0.0f);

    updatable->update(time + 1s);

    XCTAssertEqual(target->position().x, 1.0f);
    XCTAssertEqual(target->position().y, 1.0f);
}

- (void)test_update_rotate_action {
    auto target = ui::node::make_shared();
    auto time = std::chrono::system_clock::now();
    ui::continuous_action::args args{.duration = 1.0, .action = {.begin_time = time}};
    auto action = ui::make_action({.target = target,
                                   .begin_angle = 0.0f,
                                   .end_angle = 360.0f,
                                   .is_shortest = false,
                                   .continuous_action = std::move(args)});

    auto const updatable = ui::updatable_action::cast(action);

    updatable->update(time);

    XCTAssertEqual(target->angle().degrees, 0.0f);

    updatable->update(time + 500ms);

    XCTAssertEqual(target->angle().degrees, 180.0f);

    updatable->update(time + 1s);

    XCTAssertEqual(target->angle().degrees, 360.0f);
}

- (void)test_update_rotate_action_shortest_1 {
    auto target = ui::node::make_shared();
    auto time = std::chrono::system_clock::now();
    ui::continuous_action::args args{.duration = 1.0, .action = {.begin_time = time}};
    auto action = ui::make_action({.target = target,
                                   .begin_angle = 0.0f,
                                   .end_angle = 270.0f,
                                   .is_shortest = true,
                                   .continuous_action = std::move(args)});

    auto const updatable = ui::updatable_action::cast(action);

    updatable->update(time);

    XCTAssertEqual(target->angle().degrees, 360.0f);

    updatable->update(time + 500ms);

    XCTAssertEqual(target->angle().degrees, 315.0f);

    updatable->update(time + 1s);

    XCTAssertEqual(target->angle().degrees, 270.0f);
}

- (void)test_update_rotate_action_shortest_2 {
    auto target = ui::node::make_shared();
    auto time = std::chrono::system_clock::now();
    ui::continuous_action::args args{.duration = 1.0, .action = {.begin_time = time}};
    auto action = ui::make_action({.target = target,
                                   .begin_angle = -180.0f,
                                   .end_angle = 90.0f,
                                   .is_shortest = true,
                                   .continuous_action = std::move(args)});

    auto const updatable = ui::updatable_action::cast(action);

    updatable->update(time);

    XCTAssertEqual(target->angle().degrees, 180.0f);

    updatable->update(time + 500ms);

    XCTAssertEqual(target->angle().degrees, 135.0f);

    updatable->update(time + 1s);

    XCTAssertEqual(target->angle().degrees, 90.0f);
}

- (void)test_update_scale_action {
    auto target = ui::node::make_shared();
    auto time = std::chrono::system_clock::now();
    ui::continuous_action::args args{.duration = 1.0, .action = {.begin_time = time}};
    auto action = ui::make_action({.target = target,
                                   .begin_scale = {0.0f, -1.0f},
                                   .end_scale = {1.0f, 1.0f},
                                   .continuous_action = std::move(args)});

    auto const updatable = ui::updatable_action::cast(action);

    updatable->update(time);

    XCTAssertEqual(target->scale().width, 0.0f);
    XCTAssertEqual(target->scale().height, -1.0f);

    updatable->update(time + 500ms);

    XCTAssertEqual(target->scale().width, 0.5f);
    XCTAssertEqual(target->scale().height, 0.0f);

    updatable->update(time + 1s);

    XCTAssertEqual(target->scale().width, 1.0f);
    XCTAssertEqual(target->scale().height, 1.0f);
}

- (void)test_update_color_action {
    auto target = ui::node::make_shared();
    auto time = std::chrono::system_clock::now();
    ui::continuous_action::args args{.duration = 1.0, .action = {.begin_time = time}};
    auto action = ui::make_action({.target = target,
                                   .begin_color = {0.0f, 0.25f, 0.5f},
                                   .end_color = {1.0f, 0.75f, 0.5f},
                                   .continuous_action = std::move(args)});

    auto mesh = ui::mesh::make_shared();
    target->mesh()->set_value(mesh);
    auto const updatable = ui::updatable_action::cast(action);

    updatable->update(time);

    XCTAssertEqual(target->color()->value().red, 0.0f);
    XCTAssertEqual(target->color()->value().green, 0.25f);
    XCTAssertEqual(target->color()->value().blue, 0.5f);

    updatable->update(time + 500ms);

    XCTAssertEqual(target->color()->value().red, 0.5f);
    XCTAssertEqual(target->color()->value().green, 0.5f);
    XCTAssertEqual(target->color()->value().blue, 0.5f);

    updatable->update(time + 1s);

    XCTAssertEqual(target->color()->value().red, 1.0f);
    XCTAssertEqual(target->color()->value().green, 0.75f);
    XCTAssertEqual(target->color()->value().blue, 0.5f);
}

- (void)test_update_alpha_action {
    auto target = ui::node::make_shared();
    auto time = std::chrono::system_clock::now();
    ui::continuous_action::args args{.duration = 1.0, .action = {.begin_time = time}};
    auto action = ui::make_action(
        {.target = target, .begin_alpha = 1.0f, .end_alpha = 0.0f, .continuous_action = std::move(args)});

    auto mesh = ui::mesh::make_shared();
    target->mesh()->set_value(mesh);
    auto const updatable = ui::updatable_action::cast(action);

    updatable->update(time);

    XCTAssertEqual(target->alpha()->value(), 1.0f);

    updatable->update(time + 500ms);

    XCTAssertEqual(target->alpha()->value(), 0.5f);

    updatable->update(time + 1s);

    XCTAssertEqual(target->alpha()->value(), 0.0f);
}

@end
