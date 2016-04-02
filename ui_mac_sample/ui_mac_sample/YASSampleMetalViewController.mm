//
//  YASSampleMetalViewController.mm
//

#import "YASSampleMetalViewController.h"
#import "yas_objc_ptr.h"
#import "yas_property.h"

using namespace yas;

namespace yas {
namespace sample {
    namespace metal_view_controller {
        struct cpp_variables {
            ui::node_renderer renderer{nullptr};
            observer<ui::renderer> renderer_observer;
            ui::node node{nullptr};
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

    auto device = make_objc_ptr(MTLCreateSystemDefaultDevice());
    _cpp.renderer = ui::node_renderer{device.object()};

    ui::mesh mesh{4, 6, false};

    mesh.write([](auto &vertices, auto &indices) {
        vertices[0].position.x = -50.0f;
        vertices[0].position.y = -50.0f;
        vertices[1].position.x = 50.0f;
        vertices[1].position.y = -50.0f;
        vertices[2].position.x = -50.0f;
        vertices[2].position.y = 50.0f;
        vertices[3].position.x = 50.0f;
        vertices[3].position.y = 50.0f;

        indices[0] = 0;
        indices[1] = 1;
        indices[2] = 2;
        indices[3] = 1;
        indices[4] = 2;
        indices[5] = 3;
    });

    _cpp.node = ui::node{};
    _cpp.node.set_mesh(mesh);
    _cpp.node.set_color({1.0f, 0.6f, 0.0f, 1.0f});

    auto root_node = _cpp.renderer.root_node();
    root_node.add_sub_node(_cpp.node);

    [self.metalView setRenderer:_cpp.renderer.view_renderable()];

    ui::action action;

    property<ui::time_point_t> prev_time;
    prev_time.set_value(std::chrono::system_clock::now());

    property<double> sum_duration;
    sum_duration.set_value(0.0);

    action.set_update_handler([
        prev_time = std::move(prev_time),
        sum_duration = std::move(sum_duration),
        weak_node = to_weak(_cpp.node),
        weak_renderer = to_weak(_cpp.renderer)
    ](ui::time_point_t const &now) mutable {
        std::chrono::duration<double> duration = now - prev_time.value();

        if (auto node = weak_node.lock()) {
            node.set_angle(fmodf(node.angle() + duration.count() * 100.0, 360.0f));

            auto sum = sum_duration.value() + duration.count();
            if (sum > 5.0) {
                sum = fmod(sum, 5.0);
                if (auto renderer = weak_renderer.lock()) {
                    renderer.erase_action(node);

                    ui::scale_action scale_action;
                    scale_action.set_target(node);
                    scale_action.set_duration(3.0);
                    scale_action.set_value_transformer([](float const value) {
                        auto const &transformer = ui::ease_out_transformer();
                        return transformer(transformer(value));
                    });
                    scale_action.set_start_scale({3.0f, 3.0f});
                    scale_action.set_end_scale({1.0f, 1.0f});
                    renderer.insert_action(scale_action);

                    ui::color_action color_action;
                    color_action.set_target(node);
                    color_action.set_duration(3.0);
                    color_action.set_value_transformer(ui::ease_out_transformer());
                    color_action.set_start_color({0.0f, 0.6f, 1.0f, 1.0f});
                    color_action.set_end_color({1.0f, 0.6f, 0.0f, 1.0f});

                    renderer.insert_action(std::move(color_action));
                }
            }
            sum_duration.set_value(sum);
        }

        prev_time.set_value(now);

        return false;
    });

    _cpp.renderer.insert_action(action);
}

@end
