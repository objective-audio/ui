//
//  yas_ui_render_info_dependency.h
//

#pragma once

#include <ui/yas_ui_collider.h>
#include <ui/yas_ui_types.h>

#include <memory>

namespace yas::ui {
struct render_encodable {
    virtual ~render_encodable() = default;

    virtual void append_mesh(std::shared_ptr<mesh> const &mesh) = 0;

    [[nodiscard]] static std::shared_ptr<render_encodable> cast(std::shared_ptr<render_encodable> const &encodable) {
        return encodable;
    }
};

struct render_effectable {
    virtual ~render_effectable() = default;

    virtual void append_effect(std::shared_ptr<effect> const &effect) = 0;

    [[nodiscard]] static std::shared_ptr<render_effectable> cast(std::shared_ptr<render_effectable> const &effectable) {
        return effectable;
    }
};

struct render_stackable {
    virtual ~render_stackable() = default;

    virtual void push_encode_info(std::shared_ptr<metal_encode_info> const &) = 0;
    virtual void pop_encode_info() = 0;
    virtual std::shared_ptr<metal_encode_info> const &current_encode_info() = 0;

    [[nodiscard]] static std::shared_ptr<render_stackable> cast(std::shared_ptr<render_stackable> const &stackable) {
        return stackable;
    }
};

struct render_detectable {
    virtual ~render_detectable() = default;

    [[nodiscard]] virtual bool is_updating() = 0;
    virtual void push_front_collider(std::shared_ptr<collider> const &) = 0;

    [[nodiscard]] static std::shared_ptr<render_detectable> cast(std::shared_ptr<render_detectable> const &detectable) {
        return detectable;
    }
};
}  // namespace yas::ui
