//
//  yas_ui_render_target_protocol.h
//

#pragma once

#include <Metal/Metal.h>
#include <cpp_utils/yas_flagset.h>
#include <simd/simd.h>
#include "yas_ui_effect.h"
#include "yas_ui_mesh.h"
#include "yas_ui_render_encoder_protocol.h"

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

    virtual ui::mesh_ptr const &mesh() = 0;
    virtual ui::effect_ptr const &effect() = 0;
    virtual render_target_updates_t &updates() = 0;
    virtual void clear_updates() = 0;
    virtual MTLRenderPassDescriptor *renderPassDescriptor() = 0;
    virtual simd::float4x4 &projection_matrix() = 0;
    virtual bool push_encode_info(ui::render_stackable_ptr const &) = 0;
};

using renderable_render_target_ptr = std::shared_ptr<renderable_render_target>;
}  // namespace yas::ui
