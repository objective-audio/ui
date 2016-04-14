//
//  YASSampleMetalViewController.mm
//

#import "YASSampleMetalViewController.h"
#import "yas_cf_utils.h"
#import "yas_objc_ptr.h"
#import "yas_property.h"
#import "yas_ui_matrix.h"

using namespace yas;

namespace yas {
namespace sample {
    namespace metal_view_controller {
        struct cpp_variables {
            ui::node_renderer renderer;
            ui::square_node touch_node{1};
            weak<ui::action> touch_scale_action;
            ui::node cursor_node;
            weak<ui::action> cursor_color_action;
            std::vector<observer<ui::event>> observers;

            cpp_variables() : renderer(make_objc_ptr(MTLCreateSystemDefaultDevice()).object()) {
                _setup_touch_node();
                _setup_cursor_node();
            }

            void _setup_touch_node() {
                auto &node = touch_node;
                node.set_square_position({-0.5f, -0.5f, 1.0f, 1.0f}, 0);
                node.set_scale(0.0f);
                node.set_color({1.0f, 0.6f, 0.0f, 1.0f});

                auto root_node = renderer.root_node();
                root_node.add_sub_node(node);
            }

            void _setup_cursor_node() {
                auto &node = cursor_node;

                auto const count = 5;
                auto const angle_diff = 360.0f / count;
                ui::square_node mesh_node{count};

                ui::float_region region{-0.5f, -0.5f, 1.0f, 1.0f};
                auto trans_matrix = ui::matrix::translation(0.0f, 1.6f);
                for (auto const &idx : make_each(count)) {
                    mesh_node.set_square_position(region, idx, ui::matrix::rotation(angle_diff * idx) * trans_matrix);
                }

                mesh_node.set_color(0.0f);
                node.add_sub_node(mesh_node);

                auto root_node = renderer.root_node();
                root_node.add_sub_node(node);

                auto rotate_action =
                    ui::make_action({.end_angle = -360.0f, .continuous_action = {.duration = 2.0f, .loop_count = 0}});
                rotate_action.set_target(node);

                auto scale_action = ui::make_action({.start_scale = 10.0f,
                                                     .end_scale = 15.0f,
                                                     .continuous_action = {.duration = 5.0f, .loop_count = 0}});
                scale_action.set_value_transformer(
                    ui::connect({ui::ping_pong_transformer(), ui::ease_in_out_transformer()}));
                scale_action.set_target(node);

                renderer.insert_action(rotate_action);
                renderer.insert_action(scale_action);
            }
        };
    }
}
}

@interface YASSampleMetalViewController ()

@end

@implementation YASSampleMetalViewController {
    sample::metal_view_controller::cpp_variables _cpp;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setRenderer:_cpp.renderer.view_renderable()];

    auto event_manager = [self event_manager];

    _cpp.observers.reserve(3);

    _cpp.observers.emplace_back(event_manager.subject().make_observer(ui::event_method::cursor_changed, [
        weak_node = to_weak(_cpp.cursor_node),
        weak_action = _cpp.cursor_color_action,
        weak_renderer = to_weak(_cpp.renderer)
    ](auto const &method, ui::event const &event) mutable {
        if (auto node = weak_node.lock()) {
            auto const &value = event.get<ui::cursor>();

            node.set_position(node.parent().convert_position(value.position()));

            if (auto renderer = weak_renderer.lock()) {
                for (auto child_node : node.children()) {
                    switch (event.phase()) {
                        case ui::event_phase::began: {
                            if (auto prev_action = weak_action.lock()) {
                                renderer.erase_action(prev_action);
                            }

                            auto action = ui::make_action({.start_color = child_node.color(),
                                                           .end_color = {0.0f, 0.6f, 1.0f, 1.0f},
                                                           .continuous_action = {.duration = 0.5}});
                            action.set_target(child_node);
                            renderer.insert_action(action);
                            weak_action = action;
                        } break;

                        case ui::event_phase::ended: {
                            if (auto prev_action = weak_action.lock()) {
                                renderer.erase_action(prev_action);
                            }

                            auto action = ui::make_action({.start_color = child_node.color(),
                                                           .end_color = 0.0f,
                                                           .continuous_action = {.duration = 0.5}});
                            action.set_target(child_node);
                            renderer.insert_action(action);
                            weak_action = action;
                        } break;

                        default:
                            break;
                    }
                    break;
                }
            }
        }
    }));

    _cpp.observers.emplace_back(event_manager.subject().make_observer(ui::event_method::touch_changed, [
        weak_node = to_weak(_cpp.touch_node),
        weak_renderer = to_weak(_cpp.renderer),
        weak_action = _cpp.touch_scale_action
    ](auto const &method, ui::event const &event) mutable {
        if (auto node = weak_node.lock()) {
            auto const &value = event.get<ui::touch>();

            node.set_position(node.parent().convert_position(value.position()));

            if (auto renderer = weak_renderer.lock()) {
                switch (event.phase()) {
                    case ui::event_phase::began: {
                        if (auto prev_action = weak_action.lock()) {
                            renderer.erase_action(prev_action);
                        }

                        auto scale_action1 = ui::make_action(
                            {.start_scale = 0.1f, .end_scale = 200.0f, .continuous_action = {.duration = 0.1}});
                        scale_action1.set_value_transformer(ui::ease_in_transformer());
                        scale_action1.set_target(node);

                        auto scale_action2 = ui::make_action(
                            {.start_scale = 200.0f, .end_scale = 50.0f, .continuous_action = {.duration = 0.2}});
                        scale_action2.set_value_transformer(ui::ease_out_transformer());
                        scale_action2.set_target(node);

                        auto action =
                            ui::make_action_sequence({scale_action1, scale_action2}, std::chrono::system_clock::now());
                        action.set_target(node);
                        renderer.insert_action(action);
                        weak_action = action;
                    } break;

                    case ui::event_phase::ended: {
                        if (auto prev_action = weak_action.lock()) {
                            renderer.erase_action(prev_action);
                        }

                        auto action = ui::make_action(
                            {.start_scale = node.scale(), .end_scale = 0.0f, .continuous_action = {.duration = 0.3}});
                        action.set_value_transformer(ui::ease_out_transformer());
                        action.set_target(node);
                        renderer.insert_action(action);
                        weak_action = action;
                    } break;

                    default:
                        break;
                }
            }
        }
    }));

    _cpp.observers.emplace_back(event_manager.subject().make_observer(
        ui::event_method::key_changed, [](auto const &method, ui::event const &event) {
            auto key_event = event.get<ui::key>();
            std::cout << "characters:" << key_event.characters() << " phase:" << to_string(event.phase()) << std::endl;
        }));

    _cpp.observers.emplace_back(event_manager.subject().make_observer(
        ui::event_method::modifier_changed, [](auto const &method, ui::event const &event) {
            auto mod_value = event.get<ui::modifier>();
            std::cout << "modifier:" << to_string(mod_value.flag()) << " phase:" << to_string(event.phase())
                      << std::endl;

        }));
}

@end
