//
//  yas_ui_render_encoder_protocol.h
//

#pragma once

#include "yas_ui_effect.h"
#include "yas_ui_mesh.h"
#include "yas_ui_metal_encode_info.h"

namespace yas::ui {
struct render_encodable {
    virtual ~render_encodable() = default;

    virtual void append_mesh(ui::mesh_ptr const &mesh) = 0;
};

using render_encodable_ptr = std::shared_ptr<render_encodable>;

struct render_effectable {
    virtual ~render_effectable() = default;

    virtual void append_effect(ui::effect_ptr const &effect) = 0;
};

using render_effectable_ptr = std::shared_ptr<render_effectable>;

struct render_stackable {
    virtual ~render_stackable() = default;

    virtual void push_encode_info(ui::metal_encode_info_ptr const &) = 0;
    virtual void pop_encode_info() = 0;
    virtual ui::metal_encode_info_ptr const &current_encode_info() = 0;
};

using render_stackable_ptr = std::shared_ptr<render_stackable>;
}  // namespace yas::ui
