//
//  yas_ui_render_encoder_protocol.h
//

#pragma once

#include "yas_protocol.h"

namespace yas::ui {
class mesh;
class effect;
class renderer;
class metal_encode_info;

struct render_encodable : protocol {
    struct impl : protocol::impl {
        virtual void append_mesh(ui::mesh &&mesh) = 0;
    };

    explicit render_encodable(std::shared_ptr<impl>);
    render_encodable(std::nullptr_t);

    void append_mesh(ui::mesh);
};

struct render_effectable : protocol {
    struct impl : protocol::impl {
        virtual void append_effect(ui::effect &&effect) = 0;
    };

    explicit render_effectable(std::shared_ptr<impl>);
    render_effectable(std::nullptr_t);

    void append_effect(ui::effect);
};

struct render_stackable : protocol {
    struct impl : protocol::impl {
        virtual void push_encode_info(ui::metal_encode_info &&) = 0;
        virtual void pop_encode_info() = 0;
        virtual ui::metal_encode_info &current_encode_info() = 0;
    };

    explicit render_stackable(std::shared_ptr<impl>);
    render_stackable(std::nullptr_t);

    void push_encode_info(ui::metal_encode_info);
    void pop_encode_info();
    ui::metal_encode_info const &current_encode_info();
};
}  // namespace yas::ui
