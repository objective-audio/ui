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
        struct cpp {
            struct touch_object {
                ui::node node = nullptr;
                weak<ui::action> scale_action;
            };

            struct touch_holder : base {
                struct impl : base::impl {
                    std::unordered_map<uintptr_t, touch_object> _objects;
                    ui::texture texture = nullptr;
                    ui::mesh_data mesh_data = nullptr;

                    impl(id<MTLDevice> const device, double const scale_factor) {
                        assert(device);

                        auto texture_result = ui::make_texture(device, {1024, 1024}, scale_factor);
                        assert(texture_result);

                        texture = texture_result.value();

                        ui::image image{{100, 100}, scale_factor};
                        image.draw([](CGContextRef const ctx) {
                            CGContextSetStrokeColorWithColor(ctx, [yas_objc_color whiteColor].CGColor);
                            CGContextSetLineWidth(ctx, 1.0f);
                            CGContextStrokeEllipseInRect(ctx, CGRectMake(2, 2, 96, 96));
                        });

                        auto image_result = texture.add_image(image);
                        assert(image_result);

                        auto sq_mesh_data = ui::make_square_mesh_data(1);
                        sq_mesh_data.set_square_position({-0.5f, -0.5f, 1.0f, 1.0f}, 0);
                        sq_mesh_data.set_square_tex_coords(image_result.value(), 0);
                        mesh_data = std::move(sq_mesh_data.dynamic_mesh_data());
                    }
                };

                touch_holder(id<MTLDevice> const device, double const scale_factor)
                    : base(std::make_shared<impl>(device, scale_factor)) {
                }

                touch_holder(std::nullptr_t) : base(nullptr) {
                }

                void insert_touch_node(uintptr_t const identifier, ui::node_renderer &renderer) {
                    if (impl_ptr<impl>()->_objects.count(identifier) > 0) {
                        return;
                    }

                    ui::node node;
                    ui::mesh mesh;
                    mesh.set_data(impl_ptr<impl>()->mesh_data);
                    mesh.set_texture(impl_ptr<impl>()->texture);
                    node.set_mesh(mesh);
                    node.set_scale(0.0f);
                    node.set_color(1.0f);

                    auto root_node = renderer.root_node();
                    root_node.add_sub_node(node);

                    auto scale_action1 = ui::make_action(
                        {.start_scale = 0.1f, .end_scale = 200.0f, .continuous_action = {.duration = 0.1}});
                    scale_action1.set_value_transformer(ui::ease_in_transformer());
                    scale_action1.set_target(node);

                    auto scale_action2 = ui::make_action(
                        {.start_scale = 200.0f, .end_scale = 100.0f, .continuous_action = {.duration = 0.2}});
                    scale_action2.set_value_transformer(ui::ease_out_transformer());
                    scale_action2.set_target(node);

                    auto action =
                        ui::make_action_sequence({scale_action1, scale_action2}, std::chrono::system_clock::now());
                    action.set_target(node);
                    renderer.insert_action(action);

                    impl_ptr<impl>()->_objects.emplace(
                        std::make_pair(identifier, touch_object{.node = std::move(node), .scale_action = action}));
                }

                void move_touch_node(uintptr_t const identifier, simd::float2 const &position) {
                    auto &objects = impl_ptr<impl>()->_objects;
                    if (objects.count(identifier)) {
                        auto &touch_object = objects.at(identifier);
                        auto &node = touch_object.node;
                        node.set_position(node.parent().convert_position(position));
                    }
                }

                void erase_touch_node(uintptr_t const identifier, ui::node_renderer &renderer) {
                    auto &objects = impl_ptr<impl>()->_objects;
                    if (objects.count(identifier)) {
                        auto &touch_object = objects.at(identifier);

                        if (auto prev_action = touch_object.scale_action.lock()) {
                            renderer.erase_action(prev_action);
                            touch_object.scale_action = nullptr;
                        }

                        auto action = ui::make_action({.start_scale = touch_object.node.scale(),
                                                       .end_scale = 0.0f,
                                                       .continuous_action = {.duration = 0.3}});
                        action.set_value_transformer(ui::ease_out_transformer());
                        action.set_target(touch_object.node);
                        action.set_completion_handler([node = touch_object.node]() mutable {
                            node.remove_from_super_node();
                        });

                        renderer.insert_action(action);

                        objects.erase(identifier);
                    }
                }
            };

            touch_holder touch_holder = nullptr;

            ui::node cursor_node;
            weak<ui::action> cursor_color_action;

            ui::texture text_texture = nullptr;
            ui::strings_node text_node = nullptr;

            ui::square_node bg_node = nullptr;

            std::vector<base> observers;

            ui::node_renderer renderer = nullptr;

            void setup(double const scale_factor) {
                renderer = make_objc_ptr(MTLCreateSystemDefaultDevice()).object();
                touch_holder = {renderer.device(), scale_factor};

                _setup_background_node();
                _setup_cursor_node();
                _setup_text_node(scale_factor);
            }

            void _setup_background_node() {
                bg_node = ui::make_square_node(1);

                auto &node = bg_node.node();
                bg_node.square_mesh_data().set_square_position({-0.5f, -0.5f, 1.0f, 1.0f}, 0);
                node.set_scale(0.0f);
                node.set_color(0.25);

                auto root_node = renderer.root_node();
                root_node.add_sub_node(node);
            }

            void _setup_cursor_node() {
                auto const count = 5;
                auto const angle_dif = 360.0f / count;
                auto mesh_node = ui::make_square_node(count);

                ui::float_region region{-0.5f, -0.5f, 1.0f, 1.0f};
                auto trans_matrix = ui::matrix::translation(0.0f, 1.6f);
                for (auto const &idx : make_each(count)) {
                    mesh_node.square_mesh_data().set_square_position(
                        region, idx, ui::matrix::rotation(angle_dif * idx) * trans_matrix);
                }

                mesh_node.node().set_color(0.0f);
                cursor_node.add_sub_node(mesh_node.node());

                auto root_node = renderer.root_node();
                root_node.add_sub_node(cursor_node);

                auto rotate_action =
                    ui::make_action({.end_angle = -360.0f, .continuous_action = {.duration = 2.0f, .loop_count = 0}});
                rotate_action.set_target(cursor_node);

                auto scale_action = ui::make_action({.start_scale = 10.0f,
                                                     .end_scale = 15.0f,
                                                     .continuous_action = {.duration = 5.0f, .loop_count = 0}});
                scale_action.set_value_transformer(
                    ui::connect({ui::ping_pong_transformer(), ui::ease_in_out_transformer()}));
                scale_action.set_target(cursor_node);

                renderer.insert_action(rotate_action);
                renderer.insert_action(scale_action);
            }

            void _setup_text_node(double const scale_factor) {
                if (auto texture_result = ui::make_texture(renderer.device(), {1024, 1024}, scale_factor)) {
                    text_texture = std::move(texture_result.value());

                    text_node = ui::strings_node{ui::font_atlas{
                        "TrebuchetMS-Bold", 40.0f, " abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890",
                        text_texture}};

                    text_node.set_pivot(ui::pivot::center);

                    auto root_node = renderer.root_node();
                    root_node.add_sub_node(text_node.square_node().node());
                }
            }
        };
    }
}
}

@interface YASSampleMetalViewController ()

@end

@implementation YASSampleMetalViewController {
    sample::metal_view_controller::cpp _cpp;
}

- (void)viewDidLoad {
    [super viewDidLoad];

#if TARGET_OS_IPHONE
    self.view.multipleTouchEnabled = YES;
#endif

    _cpp.setup(self.view.layer.contentsScale);

    [self setRenderer:_cpp.renderer.view_renderable()];

    auto event_manager = [self event_manager];

    auto const &view_size = _cpp.renderer.view_size();
    _cpp.bg_node.node().set_scale({static_cast<float>(view_size.width), static_cast<float>(view_size.height)});

    _cpp.observers.emplace_back(_cpp.renderer.subject().make_observer(
        ui::renderer_method::drawable_size_changed,
        [weak_node = to_weak(_cpp.bg_node)](auto const &method, auto const &renderer) {
            if (auto bg_node = weak_node.lock()) {
                auto const &view_size = renderer.view_size();
                bg_node.node().set_scale({static_cast<float>(view_size.width), static_cast<float>(view_size.height)});
            }
        }));

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

    _cpp.observers.emplace_back(event_manager.subject().make_observer(
        ui::event_method::touch_changed,
        [weak_touch_holder = to_weak(_cpp.touch_holder), weak_renderer = to_weak(_cpp.renderer)](
            auto const &method, ui::event const &event) mutable {
            if (auto renderer = weak_renderer.lock()) {
                if (auto touch_holder = weak_touch_holder.lock()) {
                    auto const identifier = event.identifier();
                    auto const &value = event.get<ui::touch>();

                    switch (event.phase()) {
                        case ui::event_phase::began: {
                            touch_holder.insert_touch_node(identifier, renderer);
                            touch_holder.move_touch_node(identifier, value.position());
                        } break;

                        case ui::event_phase::changed: {
                            touch_holder.move_touch_node(identifier, value.position());
                        } break;

                        case ui::event_phase::ended:
                        case ui::event_phase::canceled: {
                            touch_holder.move_touch_node(identifier, value.position());
                            touch_holder.erase_touch_node(identifier, renderer);
                        } break;

                        default:
                            break;
                    }
                }
            }

        }));

    _cpp.observers.emplace_back(event_manager.subject().make_observer(
        ui::event_method::key_changed,
        [weak_text_node = to_weak(_cpp.text_node), weak_renderer = to_weak(_cpp.renderer)](auto const &method,
                                                                                           ui::event const &event) {
            auto key_event = event.get<ui::key>();
            if (auto text_node = weak_text_node.lock()) {
                auto &node = text_node.square_node().node();
                if (auto renderer = weak_renderer.lock()) {
                    if (event.phase() == ui::event_phase::began || event.phase() == ui::event_phase::changed) {
                        renderer.erase_action(node);

                        text_node.set_text(key_event.characters());

                        auto action = ui::make_action({.start_color = {1.0f, 1.0f, 1.0f, 1.0f},
                                                       .end_color = {0.0f, 0.0f, 0.0f, 0.0f},
                                                       .continuous_action = {.duration = 0.5f}});
                        action.set_target(node);
                        action.set_value_transformer(ui::ease_out_transformer());
                        renderer.insert_action(action);
                    }
                }
            }
        }));

    _cpp.observers.emplace_back(event_manager.subject().make_observer(
        ui::event_method::modifier_changed, [](auto const &method, ui::event const &event) {
            auto mod_value = event.get<ui::modifier>();
            std::cout << "modifier:" << to_string(mod_value.flag()) << " phase:" << to_string(event.phase())
                      << std::endl;

        }));
}

@end
