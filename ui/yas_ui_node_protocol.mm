//
//  yas_ui_node_protocol.mm
//

#include "yas_ui_node_protocol.h"
#include "yas_ui_batch_protocol.h"
#include "yas_ui_renderer.h"

using namespace yas;

#pragma mark - node_update_info

bool ui::tree_updates::is_any_updated() const {
    return this->node_updates.flags.any() || this->mesh_updates.flags.any() || this->mesh_data_updates.flags.any() ||
           this->render_target_updates.flags.any() || this->effect_updates.flags.any();
}

bool ui::tree_updates::is_collider_updated() const {
    static node_updates_t const _node_collider_updates = {
        ui::node_update_reason::enabled, ui::node_update_reason::children, ui::node_update_reason::collider};

    return this->node_updates.and_test(_node_collider_updates);
}

bool ui::tree_updates::is_render_target_updated() const {
    return this->render_target_updates.flags.any() || this->effect_updates.flags.any();
}

ui::batch_building_type ui::tree_updates::batch_building_type() const {
    static node_updates_t const _node_rebuild_updates = {ui::node_update_reason::mesh, ui::node_update_reason::enabled,
                                                         ui::node_update_reason::children,
                                                         ui::node_update_reason::batch};
    static mesh_updates_t const _mesh_rebuild_updates = {ui::mesh_update_reason::texture,
                                                         ui::mesh_update_reason::mesh_data};
    static mesh_data_updates_t const _mesh_data_rebuild_updates = {ui::mesh_data_update_reason::index_count,
                                                                   ui::mesh_data_update_reason::vertex_count};

    if (this->node_updates.and_test(_node_rebuild_updates) || this->mesh_updates.and_test(_mesh_rebuild_updates) ||
        this->mesh_data_updates.and_test(_mesh_data_rebuild_updates)) {
        return ui::batch_building_type::rebuild;
    }

    if (this->node_updates.flags.any() || this->mesh_updates.flags.any() || this->mesh_data_updates.flags.any()) {
        return ui::batch_building_type::overwrite;
    }

    return ui::batch_building_type::none;
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
        case ui::node_update_reason::render_target:
            return "render_target";
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
