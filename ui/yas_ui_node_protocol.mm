//
//  yas_ui_node_protocol.mm
//

#include "yas_ui_node_protocol.h"
#include "yas_ui_renderer.h"

using namespace yas;

#pragma mark - renderable_node

ui::renderable_node::renderable_node(std::shared_ptr<impl> impl) : protocol(std::move(impl)) {
}

ui::node_renderer ui::renderable_node::renderer() const {
    return impl_ptr<impl>()->renderer();
}

void ui::renderable_node::set_renderer(ui::node_renderer renderer) {
    impl_ptr<impl>()->set_renderer(std::move(renderer));
}
