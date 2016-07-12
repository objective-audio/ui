//
//  yas_ui_node_protocol.mm
//

#include "yas_ui_batch_protocol.h"
#include "yas_ui_node_protocol.h"
#include "yas_ui_renderer.h"

using namespace yas;

#pragma mark - node_update_info

bool ui::tree_updates::is_any_updated() const {
    return node_updates.flags.any() || mesh_updates.flags.any() || mesh_data_updates.flags.any();
}

bool ui::tree_updates::is_collider_updated() const {
    static node_updates_t const _node_collider_updates = {
        ui::node_update_reason::enabled, ui::node_update_reason::children, ui::node_update_reason::collider};

    return node_updates.and_test(_node_collider_updates);
}

ui::batch_building_type ui::tree_updates::batch_building_type() const {
    static node_updates_t const _node_rebuild_updates = {ui::node_update_reason::mesh, ui::node_update_reason::enabled,
                                                         ui::node_update_reason::children,
                                                         ui::node_update_reason::batch};
    static mesh_updates_t const _mesh_rebuild_updates = {ui::mesh_update_reason::texture,
                                                         ui::mesh_update_reason::mesh_data};
    static mesh_data_updates_t const _mesh_data_rebuild_updates = {ui::mesh_data_update_reason::index_count,
                                                                   ui::mesh_data_update_reason::vertex_count};

    if (node_updates.and_test(_node_rebuild_updates) || mesh_updates.and_test(_mesh_rebuild_updates) ||
        mesh_data_updates.and_test(_mesh_data_rebuild_updates)) {
        return ui::batch_building_type::rebuild;
    }

    if (node_updates.flags.any() || mesh_updates.flags.any() || mesh_data_updates.flags.any()) {
        return ui::batch_building_type::overwrite;
    }

    return ui::batch_building_type::none;
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

void ui::renderable_node::fetch_updates(ui::tree_updates &info) {
    return impl_ptr<impl>()->fetch_updates(info);
}

void ui::renderable_node::build_render_info(ui::render_info &info) {
    impl_ptr<impl>()->build_render_info(info);
}

bool ui::renderable_node::is_rendering_color_exists() {
    return impl_ptr<impl>()->is_rendering_color_exists();
}

void ui::renderable_node::clear_updates() {
    impl_ptr<impl>()->clear_updates();
}

std::string yas::to_string(ui::node_update_reason const &reason) {
    switch (reason) {
        case ui::node_update_reason::geometry:
            return "geometry";
        case ui::node_update_reason::mesh:
            return "mesh";
        case ui::node_update_reason::collider:
            return "collider";
        case ui::node_update_reason::enabled:
            return "enabled";
        case ui::node_update_reason::batch:
            return "batch";
        case ui::node_update_reason::children:
            return "children";
        case ui::node_update_reason::count:
            return "count";
    }
}

std::ostream &operator<<(std::ostream &os, yas::ui::node_update_reason const &reason) {
    os << to_string(reason);
    return os;
}
