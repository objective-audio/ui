//
//  yas_ui_render_target_protocol.h
//

#pragma once

#include <Metal/Metal.h>
#include <cpp_utils/yas_flagset.h>
#include <cpp_utils/yas_protocol.h>
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

struct renderable_render_target : protocol {
    struct impl : protocol::impl {
        virtual ui::mesh_ptr const &mesh() = 0;
        virtual ui::effect_ptr const &effect() = 0;
        virtual render_target_updates_t &updates() = 0;
        virtual void clear_updates() = 0;
        virtual MTLRenderPassDescriptor *renderPassDescriptor() = 0;
        virtual simd::float4x4 &projection_matrix() = 0;
        virtual bool push_encode_info(ui::render_stackable &) = 0;
    };

    explicit renderable_render_target(std::shared_ptr<impl>);
    renderable_render_target(std::nullptr_t);

    ui::mesh_ptr const &mesh();
    ui::effect_ptr const &effect();
    render_target_updates_t const &updates();
    void clear_updates();
    MTLRenderPassDescriptor *renderPassDescriptor();
    simd::float4x4 const &projection_matrix();
    bool push_encode_info(ui::render_stackable &);
};
}  // namespace yas::ui
