//
//  yas_ui_node_protocol.mm
//

#include "yas_ui_node_protocol.h"
#include "yas_ui_renderer.h"

using namespace yas;

#pragma mark - node_update_info

bool ui::tree_updates::is_any_updated() const {
    return node_updates.any() || mesh_updates.any() || mesh_data_updates.any();
}

#pragma mark - renderable_node

ui::renderable_node::renderable_node(std::shared_ptr<impl> impl) : protocol(std::move(impl)) {
}

ui::renderable_node::renderable_node(std::nullptr_t) : protocol(nullptr) {
}

ui::renderer ui::renderable_node::renderer() {
    return impl_ptr<impl>()->renderer();
}

void ui::renderable_node::set_renderer(ui::renderer renderer) {
    impl_ptr<impl>()->set_renderer(std::move(renderer));
}

void ui::renderable_node::fetch_tree_updates(ui::tree_updates &info) {
    return impl_ptr<impl>()->fetch_tree_updates(info);
}

void ui::renderable_node::update_render_info(ui::render_info &info) {
    impl_ptr<impl>()->update_render_info(info);
}
