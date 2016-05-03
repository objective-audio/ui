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
                    mesh.set_mesh_data(impl_ptr<impl>()->mesh_data);
                    mesh.set_texture(impl_ptr<impl>()->texture);
                    node.set_mesh(mesh);
                    node.set_scale(0.0f);

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

                void move_touch_node(uintptr_t const identifier, ui::point const &position) {
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
            ui::strings_node modifier_node = nullptr;

            ui::square_node bg_node = nullptr;

            std::vector<ui::square_node> cursor_over_nodes;

            std::vector<base> observers;

            ui::node_renderer renderer = nullptr;

            void setup(double const scale_factor) {
                renderer = make_objc_ptr(MTLCreateSystemDefaultDevice()).object();
                touch_holder = {renderer.device(), scale_factor};

                _setup_background_node();
                _setup_cursor_over_nodes();
                _setup_cursor_node();
                _setup_text_node(scale_factor);
            }

            void _setup_background_node() {
                bg_node = ui::make_square_node(1);

                auto &node = bg_node.node();
                bg_node.square_mesh_data().set_square_position({-0.5f, -0.5f, 1.0f, 1.0f}, 0);
                node.set_scale(0.0f);
                node.set_color({0.15f, 0.15f, 0.15f});

                auto root_node = renderer.root_node();
                root_node.add_sub_node(node);
            }

            void _setup_cursor_over_nodes() {
                auto const count = 16;

                for (auto const &idx : make_each(count)) {
                    auto sq_node = ui::make_square_node(1);
                    sq_node.square_mesh_data().set_square_position({-0.5f, -0.5f, 1.0f, 1.0f}, 0);

                    auto &node = sq_node.node();
                    node.set_position({100.0f, 0.0f});
                    node.set_scale({10.0f, 30.0f});
                    node.set_color(0.3f);
                    node.set_collider({{.shape = ui::collider_shape::square}});
                    node.dispatch_method(ui::node_method::renderer_changed);

                    observers.emplace_back(node.subject().make_observer(
                        ui::node_method::renderer_changed, [idx, obs = base{nullptr}](auto const &context) mutable {
                            obs = nullptr;

                            ui::node node = context.value;
                            if (auto renderer = node.renderer()) {
                                auto &event_manager = renderer.event_manager();
                                obs = event_manager.subject().make_observer(ui::event_method::cursor_changed, [
                                    weak_node = to_weak(node),
                                    prev_detected = std::move(std::make_shared<bool>(false))
                                ](auto const &context) {
                                    ui::event const &event = context.value;
                                    auto cursor_event = event.get<ui::cursor>();

                                    if (auto node = weak_node.lock()) {
                                        if (auto renderer = node.renderer()) {
                                            auto is_detected = renderer.collision_detector().detect(
                                                cursor_event.position(), node.collider());

                                            auto make_color_action = [](ui::node &node, ui::color const &color) {
                                                auto action = ui::make_action(
                                                    {.start_color = node.color().v, .end_color = color});
                                                action.set_target(node);
                                                return action;
                                            };

                                            if (is_detected && !*prev_detected) {
                                                renderer.erase_action(node);
                                                renderer.insert_action(make_color_action(node, {1.0f, 0.6f, 0.0f}));
                                            } else if (!is_detected && *prev_detected) {
                                                renderer.erase_action(node);
                                                renderer.insert_action(make_color_action(node, {0.3f, 0.3f, 0.3f}));
                                            }

                                            *prev_detected = is_detected;
                                        }
                                    }
                                });
                            }
                        }));

                    ui::node handle_node;
                    handle_node.add_sub_node(node);
                    handle_node.set_angle(360.0f / count * idx);

                    auto root_node = renderer.root_node();
                    root_node.add_sub_node(handle_node);

                    cursor_over_nodes.emplace_back(sq_node);
                }
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
                mesh_node.node().set_alpha(0.0f);
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

                    ui::font_atlas font_atlas{"TrebuchetMS-Bold", 26.0f,
                                              " abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890+",
                                              text_texture};

                    text_node = ui::strings_node{font_atlas, 512};
                    text_node.set_pivot(ui::pivot::left);

                    modifier_node = ui::strings_node{font_atlas, 64};
                    modifier_node.set_pivot(ui::pivot::right);

                    auto root_node = renderer.root_node();
                    root_node.add_sub_node(text_node.square_node().node());
                    root_node.add_sub_node(modifier_node.square_node().node());
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
    _cpp.setup(self.view.layer.contentsScale);
#elif TARGET_OS_MAC
    _cpp.setup([NSScreen mainScreen].backingScaleFactor);
#endif

    [self setRenderer:_cpp.renderer.view_renderable()];

    auto &event_manager = _cpp.renderer.event_manager();

    auto const &view_size = _cpp.renderer.view_size();
    _cpp.bg_node.node().set_scale({static_cast<float>(view_size.width), static_cast<float>(view_size.height)});

    auto set_text_pos = [](ui::node &node, ui::uint_size const &view_size) {
        node.set_position(
            {static_cast<float>(view_size.width) * -0.5f, static_cast<float>(view_size.height) * 0.5f - 22.0f});
    };

    auto set_modifier_pos = [](ui::node &node, ui::uint_size const &view_size) {
        node.set_position(
            {static_cast<float>(view_size.width) * 0.5f, static_cast<float>(view_size.height) * -0.5f + 6.0f});
    };

    set_text_pos(_cpp.text_node.square_node().node(), view_size);
    set_modifier_pos(_cpp.modifier_node.square_node().node(), view_size);

    _cpp.observers.emplace_back(_cpp.renderer.subject().make_observer(ui::renderer_method::drawable_size_changed, [
        weak_bg_node = to_weak(_cpp.bg_node),
        weak_text_node = to_weak(_cpp.text_node),
        weak_mod_node = to_weak(_cpp.modifier_node),
        set_text_pos = std::move(set_text_pos),
        set_modifier_pos = std::move(set_modifier_pos)
    ](auto const &context) {
        auto const &renderer = context.value;
        auto const &view_size = renderer.view_size();

        if (auto bg_node = weak_bg_node.lock()) {
            bg_node.node().set_scale({static_cast<float>(view_size.width), static_cast<float>(view_size.height)});
        }

        if (auto text_node = weak_text_node.lock()) {
            set_text_pos(text_node.square_node().node(), view_size);
        }

        if (auto mod_node = weak_mod_node.lock()) {
            set_modifier_pos(mod_node.square_node().node(), view_size);
        }
    }));

    _cpp.observers.emplace_back(event_manager.subject().make_observer(ui::event_method::cursor_changed, [
        weak_node = to_weak(_cpp.cursor_node),
        weak_action = _cpp.cursor_color_action,
        weak_renderer = to_weak(_cpp.renderer)
    ](auto const &context) mutable {
        if (auto node = weak_node.lock()) {
            ui::event const &event = context.value;
            auto const &value = event.get<ui::cursor>();

            node.set_position(node.parent().convert_position(value.position()));

            if (auto renderer = weak_renderer.lock()) {
                for (auto child_node : node.children()) {
                    auto make_fade_action = [](ui::node &node, simd::float3 const &color, float const alpha) {
                        double const duration = 0.5;

                        ui::parallel_action action;

                        auto color_action = ui::make_action({.start_color = node.color().v,
                                                             .end_color = color,
                                                             .continuous_action = {.duration = duration}});
                        color_action.set_target(node);
                        action.insert_action(std::move(color_action));

                        auto alpha_action = ui::make_action({.start_alpha = node.alpha(),
                                                             .end_alpha = alpha,
                                                             .continuous_action = {.duration = duration}});
                        alpha_action.set_target(node);
                        action.insert_action(std::move(alpha_action));

                        action.set_target(node);

                        return action;
                    };

                    switch (event.phase()) {
                        case ui::event_phase::began: {
                            if (auto prev_action = weak_action.lock()) {
                                renderer.erase_action(prev_action);
                            }

                            auto action = make_fade_action(child_node, simd::float3{0.0f, 0.6f, 1.0f}, 1.0f);
                            renderer.insert_action(action);
                            weak_action = action;
                        } break;

                        case ui::event_phase::ended: {
                            if (auto prev_action = weak_action.lock()) {
                                renderer.erase_action(prev_action);
                            }

                            auto action = make_fade_action(child_node, simd::float3{0.0f}, 0.0f);
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
        [weak_touch_holder = to_weak(_cpp.touch_holder),
         weak_renderer = to_weak(_cpp.renderer)](auto const &context) mutable {
            if (auto result = where(weak_renderer.lock(), weak_touch_holder.lock())) {
                ui::event const &event = context.value;
                auto &renderer = std::get<0>(result.value());
                auto &touch_holder = std::get<1>(result.value());
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
        }));

    _cpp.observers.emplace_back(event_manager.subject().make_observer(
        ui::event_method::key_changed,
        [weak_text_node = to_weak(_cpp.text_node), weak_renderer = to_weak(_cpp.renderer)](auto const &context) {
            ui::event const &event = context.value;
            if (auto result = where(weak_text_node.lock(), event.phase() == ui::event_phase::began ||
                                                               event.phase() == ui::event_phase::changed)) {
                auto &text_node = std::get<0>(result.value());
                auto const key_code = event.get<ui::key>().key_code();

                switch (key_code) {
                    case 51: {
                        auto &text = text_node.text();
                        if (text.size() > 0) {
                            text_node.set_text(text.substr(0, text.size() - 1));
                        }
                    } break;

                    default: { text_node.set_text(text_node.text() + event.get<ui::key>().characters()); } break;
                }
            }
        }));

    _cpp.observers.emplace_back(event_manager.subject().make_observer(ui::event_method::modifier_changed, [
        weak_mod_node = to_weak(_cpp.modifier_node),
        flags = std::make_shared<std::unordered_set<ui::modifier_flags>>()
    ](auto const &context) {
        ui::event const &event = context.value;
        auto flag = event.get<ui::modifier>().flag();

        if (event.phase() == ui::event_phase::began) {
            flags->insert(flag);
        } else if (event.phase() == ui::event_phase::ended) {
            flags->erase(flag);
        }

        if (auto mod_node = weak_mod_node.lock()) {
            std::vector<std::string> flag_texts;
            flag_texts.reserve(flags->size());

            for (auto const &flg : *flags) {
                flag_texts.emplace_back(to_string(flg));
            }

            mod_node.set_text(joined(flag_texts, " + "));
        }
    }));
}

@end
