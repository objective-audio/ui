//
//  yas_ui_mesh_protocol.h
//

#pragma once

#include <Metal/Metal.h>
#include <simd/simd.h>
#include "yas_flagset.h"
#include "yas_protocol.h"

namespace yas {
namespace ui {
    class renderer_base;
    class metal_encode_info;
    class batch_render_mesh_info;
    enum class batch_building_type;

    enum class mesh_update_reason : std::size_t {
        mesh_data,
        texture,
        primitive_type,
        color,
        use_mesh_color,

        count,
    };

    using mesh_updates_t = flagset<mesh_update_reason>;

    struct renderable_mesh : protocol {
        struct impl : protocol::impl {
            virtual simd::float4x4 const &matrix() = 0;
            virtual void set_matrix(simd::float4x4 &&) = 0;
            virtual std::size_t render_vertex_count() = 0;
            virtual std::size_t render_index_count() = 0;
            virtual mesh_updates_t const &updates() = 0;
            virtual bool pre_render() = 0;
            virtual void metal_render(ui::renderer_base &, id<MTLRenderCommandEncoder> const,
                                      ui::metal_encode_info const &) = 0;
            virtual void batch_render(batch_render_mesh_info &, ui::batch_building_type const) = 0;
            virtual bool is_rendering_color_exists() = 0;
            virtual void clear_updates() = 0;
        };

        explicit renderable_mesh(std::shared_ptr<impl>);
        renderable_mesh(std::nullptr_t);

        simd::float4x4 const &matrix();
        void set_matrix(simd::float4x4);
        std::size_t render_vertex_count();
        std::size_t render_index_count();
        mesh_updates_t const &updates();
        bool pre_render();
        void metal_render(ui::renderer_base &, id<MTLRenderCommandEncoder> const, ui::metal_encode_info const &);
        void batch_render(batch_render_mesh_info &, ui::batch_building_type const);
        bool is_rendering_color_exists();
        void clear_updates();
    };
}

std::string to_string(ui::mesh_update_reason const &);
}

std::ostream &operator<<(std::ostream &os, yas::ui::mesh_update_reason const &);
