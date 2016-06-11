//
//  yas_ui_mesh_data_protocol.h
//

#pragma once

#include <Metal/Metal.h>
#include "yas_flagset.h"
#include "yas_protocol.h"

namespace yas {
namespace ui {
    enum class mesh_data_update_reason : std::size_t {
        data,
        vertex_count,
        index_count,
        render_buffer,

        count,
    };

    using mesh_data_updates_t = flagset<mesh_data_update_reason>;

    struct renderable_mesh_data : protocol {
        struct impl : protocol::impl {
            virtual std::size_t vertex_buffer_byte_offset() = 0;
            virtual std::size_t index_buffer_byte_offset() = 0;
            virtual id<MTLBuffer> vertexBuffer() = 0;
            virtual id<MTLBuffer> indexBuffer() = 0;

            virtual mesh_data_updates_t const &updates() = 0;
            virtual void update_render_buffer() = 0;
            virtual void clear_updates() = 0;
        };

        explicit renderable_mesh_data(std::shared_ptr<impl>);
        renderable_mesh_data(std::nullptr_t);

        std::size_t vertex_buffer_byte_offset();
        std::size_t index_buffer_byte_offset();
        id<MTLBuffer> vertexBuffer();
        id<MTLBuffer> indexBuffer();

        mesh_data_updates_t const &updates();
        void update_render_buffer();
        void clear_updates();
    };
}

std::string to_string(ui::mesh_data_update_reason const &);
}

std::ostream &operator<<(std::ostream &os, yas::ui::mesh_data_update_reason const &);
