//
//  yas_ui_node_protocol.h
//

#pragma once

#include "yas_protocol.h"

namespace yas {
namespace ui {
    class renderer;

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

    struct renderable_node : protocol {
        struct impl : protocol::impl {
            virtual ui::renderer renderer() = 0;
            virtual void set_renderer(ui::renderer &&) = 0;
            virtual bool needs_update_for_render() = 0;
        };

        explicit renderable_node(std::shared_ptr<impl> impl);

        ui::renderer renderer();
        void set_renderer(ui::renderer);
        bool needs_update_for_render();
    };
}
}