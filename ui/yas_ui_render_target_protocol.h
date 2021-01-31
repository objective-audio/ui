//
//  yas_ui_render_target_protocol.h
//

#pragma once

#include <Metal/Metal.h>
#include <cpp_utils/yas_flagset.h>
#include <simd/simd.h>
#include <ui/yas_ui_effect.h>
#include <ui/yas_ui_mesh.h>
#include <ui/yas_ui_ptr.h>
#include <ui/yas_ui_render_encoder_protocol.h>

namespace yas::ui {
enum class render_target_update_reason : std::size_t {
    region,
    scale_factor,
    effect,

    count,
};

using render_target_updates_t = flagset<render_target_update_reason>;

struct renderable_render_target {
    virtual ~renderable_render_target() = default;

    virtual ui::mesh_ptr const &mesh() const = 0;
    virtual ui::effect_ptr const &effect() const = 0;
    virtual render_target_updates_t const &updates() const = 0;
    virtual void clear_updates() = 0;
    virtual MTLRenderPassDescriptor *renderPassDescriptor() const = 0;
    virtual simd::float4x4 const &projection_matrix() const = 0;
    virtual bool push_encode_info(ui::render_stackable_ptr const &) = 0;

    static renderable_render_target_ptr cast(renderable_render_target_ptr const &render_target) {
        return render_target;
    }
};
}  // namespace yas::ui
