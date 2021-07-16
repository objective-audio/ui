//
//  yas_ui_renderer_dependency_cpp.cpp
//

#include "yas_ui_renderer_dependency_cpp.h"

using namespace yas;
using namespace yas::ui;

bool tree_updates::is_any_updated() const {
    return this->node_updates.flags.any() || this->mesh_updates.flags.any() || this->mesh_data_updates.flags.any() ||
           this->render_target_updates.flags.any() || this->effect_updates.flags.any();
}

bool tree_updates::is_collider_updated() const {
    static node_updates_t const _node_collider_updates = {
        ui::node_update_reason::enabled, ui::node_update_reason::children, ui::node_update_reason::collider};

    return this->node_updates.and_test(_node_collider_updates);
}

bool tree_updates::is_render_target_updated() const {
    return this->render_target_updates.flags.any() || this->effect_updates.flags.any();
}

batch_building_type tree_updates::batch_building_type() const {
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
