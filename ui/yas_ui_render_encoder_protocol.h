//
//  yas_ui_render_encoder_protocol.h
//

#pragma once

#include "yas_ui_effect.h"
#include "yas_ui_mesh.h"
#include "yas_ui_metal_encode_info.h"

namespace yas::ui {
class render_encodable;
class render_effectable;
class render_stackable;
using render_encodable_ptr = std::shared_ptr<render_encodable>;
using render_effectable_ptr = std::shared_ptr<render_effectable>;
using render_stackable_ptr = std::shared_ptr<render_stackable>;

struct render_encodable {
    virtual ~render_encodable() = default;

    virtual void append_mesh(ui::mesh_ptr const &mesh) = 0;

    static render_encodable_ptr cast(render_encodable_ptr const &encodable) {
        return encodable;
    }
};

using render_encodable_ptr = std::shared_ptr<render_encodable>;

struct render_effectable {
    virtual ~render_effectable() = default;

    virtual void append_effect(ui::effect_ptr const &effect) = 0;

    static render_effectable_ptr cast(render_effectable_ptr const &effectable) {
        return effectable;
    }
};

using render_effectable_ptr = std::shared_ptr<render_effectable>;

struct render_stackable {
    virtual ~render_stackable() = default;

    virtual void push_encode_info(ui::metal_encode_info_ptr const &) = 0;
    virtual void pop_encode_info() = 0;
    virtual ui::metal_encode_info_ptr const &current_encode_info() = 0;

    static render_stackable_ptr cast(render_stackable_ptr const &stackable) {
        return stackable;
    }
};

using render_stackable_ptr = std::shared_ptr<render_stackable>;
}  // namespace yas::ui
