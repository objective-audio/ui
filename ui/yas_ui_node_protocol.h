//
//  yas_ui_node_protocol.h
//

#pragma once

#include "yas_flagset.h"
#include "yas_protocol.h"
#include "yas_ui_mesh_data_protocol.h"
#include "yas_ui_mesh_protocol.h"

namespace yas {
namespace ui {
    class renderer;
    class render_info;
    enum class batch_building_type;

    enum class node_method {
        added_to_super,
        removed_from_super,

        parent_changed,
        renderer_changed,
        position_changed,
        angle_changed,
        scale_changed,
        color_changed,
        alpha_changed,
        mesh_changed,
        collider_changed,
        enabled_changed,
    };

    enum class node_update_reason : std::size_t {
        geometry,
        mesh,
        collider,
        enabled,
        children,
        batch,

        count,
    };

    using node_updates_t = flagset<node_update_reason>;

    struct tree_updates {
        node_updates_t node_updates;
        mesh_updates_t mesh_updates;
        mesh_data_updates_t mesh_data_updates;

        bool is_any_updated() const;
        bool is_collider_updated() const;
        ui::batch_building_type batch_building_type() const;
    };

    struct renderable_node : protocol {
        struct impl : protocol::impl {
            virtual ui::renderer renderer() = 0;
            virtual void set_renderer(ui::renderer &&) = 0;
            virtual void fetch_updates(ui::tree_updates &) = 0;
            virtual void build_render_info(ui::render_info &) = 0;
            virtual bool is_rendering_color_exists() = 0;
            virtual void clear_updates() = 0;
        };

        explicit renderable_node(std::shared_ptr<impl>);
        renderable_node(std::nullptr_t);

        ui::renderer renderer();
        void set_renderer(ui::renderer);
        void fetch_updates(ui::tree_updates &);
        void build_render_info(ui::render_info &);
        bool is_rendering_color_exists();
        void clear_updates();
    };
}

std::string to_string(ui::node_update_reason const &);
}

std::ostream &operator<<(std::ostream &os, yas::ui::node_update_reason const &);
