//
//  yas_ui_node_protocol.h
//

#pragma once

#include "yas_protocol.h"

namespace yas {
namespace ui {
    class node_renderer;

    enum class node_method {
        add_to_super,
        remove_from_super,
        change_parent,
        change_node_renderer,

        change_position,
        change_angle,
        change_scale,
        change_color,
        change_alpha,
        change_mesh,
        change_collider,
        change_enabled,
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