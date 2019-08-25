//
//  yas_ui_render_encoder_protocol.h
//

#pragma once

#include <cpp_utils/yas_protocol.h>
#include "yas_ui_effect.h"
#include "yas_ui_mesh.h"
#include "yas_ui_metal_encode_info.h"

namespace yas::ui {
class renderer;

struct render_encodable {
    virtual ~render_encodable() = default;

    virtual void append_mesh(ui::mesh_ptr const &mesh) = 0;
};

using render_encodable_ptr = std::shared_ptr<render_encodable>;

struct render_effectable : protocol {
    struct impl : protocol::impl {
        virtual void append_effect(ui::effect_ptr const &effect) = 0;
    };

    explicit render_effectable(std::shared_ptr<impl>);
    render_effectable(std::nullptr_t);

    void append_effect(ui::effect_ptr const &);
};

struct render_stackable : protocol {
    struct impl : protocol::impl {
        virtual void push_encode_info(ui::metal_encode_info_ptr const &) = 0;
        virtual void pop_encode_info() = 0;
        virtual ui::metal_encode_info_ptr const &current_encode_info() = 0;
    };

    explicit render_stackable(std::shared_ptr<impl>);
    render_stackable(std::nullptr_t);

    void push_encode_info(ui::metal_encode_info_ptr const &);
    void pop_encode_info();
    ui::metal_encode_info_ptr const &current_encode_info();
};
}  // namespace yas::ui
