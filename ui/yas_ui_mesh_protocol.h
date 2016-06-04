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
    class batch_render_mesh_info;

    enum class mesh_data_update_reason : std::size_t {
        data,
        vertex_count,
        index_count,

        count,
    };

    using mesh_data_update_reason_t = std::underlying_type<ui::mesh_data_update_reason>::type;
    static std::size_t const mesh_data_update_reason_count =
        static_cast<mesh_data_update_reason_t>(ui::mesh_data_update_reason::count);

    enum class mesh_update_reason : std::size_t {
        mesh_data,
        texture,
        primitive_type,
        color,
        use_mesh_color,

        count,
    };

    using mesh_update_reason_t = std::underlying_type<ui::mesh_update_reason>::type;
    static std::size_t const mesh_update_reason_count =
        static_cast<mesh_update_reason_t>(ui::mesh_update_reason::count);

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
        renderable_mesh_data(std::nullptr_t);

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
            virtual std::size_t render_vertex_count() = 0;
            virtual std::size_t render_index_count() = 0;
            virtual bool needs_update_for_render() = 0;
            virtual void metal_render(ui::renderer_base &, id<MTLRenderCommandEncoder> const,
                                      ui::metal_encode_info const &) = 0;
            virtual void batch_render(batch_render_mesh_info &) = 0;
        };

        explicit renderable_mesh(std::shared_ptr<impl>);
        renderable_mesh(std::nullptr_t);

        simd::float4x4 const &matrix();
        void set_matrix(simd::float4x4);
        std::size_t render_vertex_count();
        std::size_t render_index_count();
        bool needs_update_for_render();
        void metal_render(ui::renderer_base &, id<MTLRenderCommandEncoder> const, ui::metal_encode_info const &);
        void batch_render(batch_render_mesh_info &);
    };
}
}
