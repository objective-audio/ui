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

    auto action = ui::make_action({.end_angle = 360.0f, .continuous_action = {.duration = 4.0f, .loop_count = 0}});
    action.set_target(_cpp.node);

    _cpp.renderer.insert_action(action);
}

@end
