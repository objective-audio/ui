//
//  yas_ui_renderer_dependency.cpp
//

#include "yas_ui_renderer_dependency.h"

#include <cpp-utils/fast_each.h>
#include <cpp-utils/stl_utils.h>

using namespace yas;
using namespace yas::ui;

bool tree_updates::is_any_updated() const {
    return this->node_updates.flags.any() || this->mesh_updates.flags.any() || this->vertex_data_updates.flags.any() ||
           this->index_data_updates.flags.any() || this->render_target_updates.flags.any() ||
           this->effect_updates.flags.any();
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
    static mesh_updates_t const _mesh_rebuild_updates = {
        ui::mesh_update_reason::texture, ui::mesh_update_reason::vertex_data, ui::mesh_update_reason::index_data,
        ui::mesh_update_reason::primitive_type};
    static mesh_data_updates_t const _vertex_data_rebuild_updates = {ui::mesh_data_update_reason::data_count};

    if (this->node_updates.and_test(_node_rebuild_updates) || this->mesh_updates.and_test(_mesh_rebuild_updates) ||
        this->vertex_data_updates.and_test(_vertex_data_rebuild_updates) ||
        this->index_data_updates.and_test(_vertex_data_rebuild_updates)) {
        return ui::batch_building_type::rebuild;
    }

    if (this->node_updates.flags.any() || this->mesh_updates.flags.any() || this->vertex_data_updates.flags.any() ||
        this->index_data_updates.flags.any()) {
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

std::string yas::to_string(ui::batch_building_type const &type) {
    switch (type) {
        case ui::batch_building_type::rebuild:
            return "rebuild";
        case ui::batch_building_type::overwrite:
            return "overwrite";
        case ui::batch_building_type::none:
            return "none";
    }
}

std::string yas::to_string(ui::mesh_data_update_reason const &reason) {
    switch (reason) {
        case ui::mesh_data_update_reason::data_content:
            return "data_content";
        case ui::mesh_data_update_reason::data_count:
            return "data_count";
        case ui::mesh_data_update_reason::render_buffer:
            return "render_buffer";
        case ui::mesh_data_update_reason::count:
            return "count";
    }
}

std::string yas::to_string(ui::mesh_update_reason const &reason) {
    switch (reason) {
        case ui::mesh_update_reason::vertex_data:
            return "vertex_data";
        case ui::mesh_update_reason::index_data:
            return "index_data";
        case ui::mesh_update_reason::texture:
            return "texture";
        case ui::mesh_update_reason::primitive_type:
            return "primitive_type";
        case ui::mesh_update_reason::color:
            return "color";
        case ui::mesh_update_reason::use_mesh_color:
            return "use_mesh_color";
        case ui::mesh_update_reason::matrix:
            return "matrix";
        case ui::mesh_update_reason::count:
            return "count";
    }
}

std::ostream &operator<<(std::ostream &os, yas::ui::node_update_reason const &reason) {
    os << to_string(reason);
    return os;
}

std::ostream &operator<<(std::ostream &os, yas::ui::batch_building_type const &type) {
    os << to_string(type);
    return os;
}

std::ostream &operator<<(std::ostream &os, yas::ui::mesh_data_update_reason const &reason) {
    os << to_string(reason);
    return os;
}

std::ostream &operator<<(std::ostream &os, yas::ui::mesh_update_reason const &reason) {
    os << to_string(reason);
    return os;
}

std::ostream &operator<<(std::ostream &os, yas::ui::effect_update_reason const &value) {
    os << to_string(value);
    return os;
}

std::ostream &operator<<(std::ostream &os, yas::ui::effect_updates_t const &value) {
    os << to_string(value);
    return os;
}

#pragma mark -

std::string yas::to_string(ui::effect_update_reason const &reason) {
    switch (reason) {
        case ui::effect_update_reason::textures:
            return "textures";
        case ui::effect_update_reason::handler:
            return "handler";
        case ui::effect_update_reason::count:
            return "count";
    }
}

std::string yas::to_string(ui::effect_updates_t const &updates) {
    std::vector<std::string> flag_texts;
    auto each = make_fast_each(static_cast<std::size_t>(ui::effect_update_reason::count));
    while (yas_each_next(each)) {
        auto const value = static_cast<ui::effect_update_reason>(yas_each_index(each));
        if (updates.test(value)) {
            flag_texts.emplace_back(to_string(value));
        }
    }
    return joined(flag_texts, "|");
}
