//
//  yas_ui_node_protocol.mm
//

#include "yas_ui_node_protocol.h"
#include "yas_ui_renderer.h"

using namespace yas;

#pragma mark - renderable_node

ui::renderable_node::renderable_node(std::shared_ptr<impl> impl) : protocol(std::move(impl)) {
}

ui::renderer ui::renderable_node::renderer() {
    return impl_ptr<impl>()->renderer();
}

void ui::renderable_node::set_renderer(ui::renderer renderer) {
    impl_ptr<impl>()->set_renderer(std::move(renderer));
}

bool ui::renderable_node::needs_update_for_render() {
    return impl_ptr<impl>()->needs_update_for_render();
}

void ui::renderable_node::update_render_info(ui::render_info &info) {
    impl_ptr<impl>()->update_render_info(info);
}
