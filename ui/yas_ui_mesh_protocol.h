//
//  yas_ui_mesh_protocol.h
//

#pragma once

#include <Metal/Metal.h>
#include <simd/simd.h>
#include "yas_protocol.h"

namespace yas {
namespace ui {
    class renderer_base;
    class metal_encode_info;

    struct renderable_mesh_data : protocol {
        struct impl : protocol::impl {
            virtual std::size_t vertex_buffer_byte_offset() = 0;
            virtual std::size_t index_buffer_byte_offset() = 0;
            virtual id<MTLBuffer> vertexBuffer() = 0;
            virtual id<MTLBuffer> indexBuffer() = 0;

            virtual bool needs_update_for_render() = 0;
            virtual void update_render_buffer_if_needed() = 0;
        };

        explicit renderable_mesh_data(std::shared_ptr<impl>);

        std::size_t vertex_buffer_byte_offset();
        std::size_t index_buffer_byte_offset();
        id<MTLBuffer> vertexBuffer();
        id<MTLBuffer> indexBuffer();

        bool needs_update_for_render();
        void update_render_buffer_if_needed();
    };

    struct renderable_mesh : protocol {
        struct impl : protocol::impl {
            virtual simd::float4x4 const &matrix() = 0;
            virtual void set_matrix(simd::float4x4 &&) = 0;
            virtual bool needs_update_for_render() = 0;
            virtual void render(ui::renderer_base &, id<MTLRenderCommandEncoder> const,
                                ui::metal_encode_info const &) = 0;
        };

        explicit renderable_mesh(std::shared_ptr<impl>);

        simd::float4x4 const &matrix();
        void set_matrix(simd::float4x4);
        bool needs_update_for_render();
        void render(ui::renderer_base &, id<MTLRenderCommandEncoder> const, ui::metal_encode_info const &);
    };
}
}
