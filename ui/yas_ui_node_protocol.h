//
//  yas_ui_node_protocol.h
//

#pragma once

#include "yas_protocol.h"

namespace yas {
namespace ui {
    class renderer;
    class render_info;

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
        hierarchie,
        geometry,
        color,
        mesh,
        collider,
        enabled,
        batch,

        count,
    };

    using node_update_reason_t = std::underlying_type<ui::node_update_reason>::type;
    static std::size_t const node_update_reason_count =
        static_cast<node_update_reason_t>(ui::node_update_reason::count);

    struct renderable_node : protocol {
        struct impl : protocol::impl {
            virtual ui::renderer renderer() = 0;
            virtual void set_renderer(ui::renderer &&) = 0;
            virtual bool needs_update_for_render() = 0;
            virtual void update_render_info(ui::render_info &) = 0;
        };

        explicit renderable_node(std::shared_ptr<impl>);
        renderable_node(std::nullptr_t);

        ui::renderer renderer();
        void set_renderer(ui::renderer);
        bool needs_update_for_render();
        void update_render_info(ui::render_info &);
    };
}
}