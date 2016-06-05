//
//  yas_ui_mesh_data_protocol.h
//

#pragma once

#include <Metal/Metal.h>
#include <bitset>
#include "yas_protocol.h"

namespace yas {
namespace ui {
    enum class mesh_data_update_reason : std::size_t {
        data,
        vertex_count,
        index_count,

        count,
    };

    using mesh_data_update_reason_size_t = std::underlying_type<ui::mesh_data_update_reason>::type;
    static std::size_t const mesh_data_update_reason_count =
        static_cast<mesh_data_update_reason_size_t>(ui::mesh_data_update_reason::count);
    using mesh_data_updates_t = std::bitset<mesh_data_update_reason_count>;

    struct renderable_mesh_data : protocol {
        struct impl : protocol::impl {
            virtual std::size_t vertex_buffer_byte_offset() = 0;
            virtual std::size_t index_buffer_byte_offset() = 0;
            virtual id<MTLBuffer> vertexBuffer() = 0;
            virtual id<MTLBuffer> indexBuffer() = 0;

            virtual mesh_data_updates_t const &updates() = 0;
            virtual void update_render_buffer_if_needed() = 0;
        };

        explicit renderable_mesh_data(std::shared_ptr<impl>);
        renderable_mesh_data(std::nullptr_t);

        std::size_t vertex_buffer_byte_offset();
        std::size_t index_buffer_byte_offset();
        id<MTLBuffer> vertexBuffer();
        id<MTLBuffer> indexBuffer();

        mesh_data_updates_t const &updates();
        void update_render_buffer_if_needed();
    };
}
}