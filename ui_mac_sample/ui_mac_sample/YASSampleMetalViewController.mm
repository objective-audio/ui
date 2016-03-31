//
//  YASSampleMetalViewController.mm
//

#import "YASSampleMetalViewController.h"
#import "yas_objc_container.h"

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

    auto device = make_container_move(MTLCreateSystemDefaultDevice());
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

    auto root_node = _cpp.renderer.root_node();
    root_node.add_sub_node(_cpp.node);

    [self.metalView setRenderer:_cpp.renderer.view_renderable()];

    [self startActions];

    [NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(startActions) userInfo:nil repeats:YES];
}

- (void)startActions {
    ui::rotate_action rotate_action;
    rotate_action.set_target(_cpp.node);
    rotate_action.set_duration(3.0);
    rotate_action.set_curve(ui::action_curve::ease_in_out);
    rotate_action.set_start_angle(0.0f);
    rotate_action.set_end_angle(360.0f);
    rotate_action.set_shortest(false);

    _cpp.renderer.insert_action(std::move(rotate_action));

    ui::scale_action scale_action;
    scale_action.set_target(_cpp.node);
    scale_action.set_duration(3.0);
    scale_action.set_curve(ui::action_curve::ease_in_out);
    scale_action.set_start_scale({0.5f, 2.0f});
    scale_action.set_end_scale({1.0f, 1.0f});

    _cpp.renderer.insert_action(std::move(scale_action));

    ui::color_action color_action;
    color_action.set_target(_cpp.node);
    color_action.set_duration(3.0);
    color_action.set_curve(ui::action_curve::ease_in_out);
    color_action.set_start_color({0.0f, 0.5f, 1.0f, 1.0f});
    color_action.set_end_color({1.0f, 0.5f, 0.0f, 1.0f});

    _cpp.renderer.insert_action(std::move(color_action));

    ui::translate_action translate_action;
    translate_action.set_target(_cpp.node);
    translate_action.set_duration(3.0);
    translate_action.set_curve(ui::action_curve::ease_in_out);
    translate_action.set_start_position({-50.0f, 0.0f});
    translate_action.set_end_position({50.0f, 0.0f});

    _cpp.renderer.insert_action(std::move(translate_action));
}

@end
