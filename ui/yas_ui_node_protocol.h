//
//  yas_ui_node_protocol.h
//

#pragma once

#include <cpp_utils/yas_flagset.h>
#include "yas_ui_effect_protocol.h"
#include "yas_ui_mesh_data_protocol.h"
#include "yas_ui_mesh_protocol.h"
#include "yas_ui_ptr.h"
#include "yas_ui_render_target_protocol.h"

namespace yas::ui {
class render_info;
enum class batch_building_type;

enum class node_update_reason : std::size_t {
    geometry,
    mesh,
    collider,
    enabled,
    children,
    batch,
    render_target,

    count,
};

using node_updates_t = flagset<node_update_reason>;

struct tree_updates {
    node_updates_t node_updates;
    mesh_updates_t mesh_updates;
    mesh_data_updates_t mesh_data_updates;
    render_target_updates_t render_target_updates;
    effect_updates_t effect_updates;

    bool is_any_updated() const;
    bool is_collider_updated() const;
    bool is_render_target_updated() const;
    ui::batch_building_type batch_building_type() const;
};

struct renderable_node {
    virtual ~renderable_node() = default;

    virtual ui::renderer_ptr renderer() = 0;
    virtual void set_renderer(ui::renderer_ptr const &) = 0;
    virtual void fetch_updates(ui::tree_updates &) = 0;
    virtual void build_render_info(ui::render_info &) = 0;
    virtual bool is_rendering_color_exists() = 0;
    virtual void clear_updates() = 0;
};

using renderable_node_ptr = std::shared_ptr<renderable_node>;
}  // namespace yas::ui

namespace yas {
std::string to_string(ui::node_update_reason const &);
}

std::ostream &operator<<(std::ostream &os, yas::ui::node_update_reason const &);
