//
//  yas_ui_render_target_protocol.h
//

#pragma once

#include "yas_protocol.h"
#include "yas_flagset.h"
#include "yas_ui_render_encoder_protocol.h"
#include <Metal/Metal.h>
#include <simd/simd.h>

namespace yas {
namespace ui {
    class mesh;
    class effect;

    enum class render_target_update_reason : std::size_t {
        region,
        scale_factor,
        blur_sigma,

        count,
    };

    using render_target_updates_t = flagset<render_target_update_reason>;

    struct renderable_render_target : protocol {
        struct impl : protocol::impl {
            virtual ui::mesh &mesh() = 0;
            virtual ui::effect &effect() = 0;
            virtual render_target_updates_t &updates() = 0;
            virtual void clear_updates() = 0;
            virtual MTLRenderPassDescriptor *renderPassDescriptor() = 0;
            virtual simd::float4x4 &projection_matrix() = 0;
            virtual void push_encode_info(ui::render_stackable &) = 0;
        };

        explicit renderable_render_target(std::shared_ptr<impl>);
        renderable_render_target(std::nullptr_t);

        ui::mesh &mesh();
        ui::effect &effect();
        render_target_updates_t const &updates();
        void clear_updates();
        MTLRenderPassDescriptor *renderPassDescriptor();
        simd::float4x4 const &projection_matrix();
        void push_encode_info(ui::render_stackable &);
    };
}
}
