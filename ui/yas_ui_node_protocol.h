//
//  yas_ui_node_protocol.h
//

#pragma once

#include "yas_protocol.h"

namespace yas {
namespace ui {
    class node_renderer;

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
            virtual ui::node_renderer renderer() = 0;
            virtual void set_renderer(ui::node_renderer &&) = 0;
        };

        explicit renderable_node(std::shared_ptr<impl> impl);

        ui::node_renderer renderer() const;
        void set_renderer(ui::node_renderer);
    };
}
}