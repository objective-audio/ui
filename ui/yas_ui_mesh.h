//
//  yas_ui_mesh.h
//

#pragma once

#include <Metal/Metal.h>
#include <simd/simd.h>
#include <vector>
#include "yas_base.h"
#include "yas_ui_metal_protocol.h"
#include "yas_ui_shared_types.h"

namespace yas {
namespace ui {
    class renderer;
    class encode_info;
    class texture;

    struct renderable_mesh : protocol {
        struct impl : protocol::impl {
            virtual simd::float4x4 const &matrix() const = 0;
            virtual void set_matrix(simd::float4x4 &&) = 0;
            virtual void render(ui::renderer &, id<MTLRenderCommandEncoder> const, ui::encode_info const &) = 0;
        };

        explicit renderable_mesh(std::shared_ptr<impl>);

        simd::float4x4 const &matrix() const;
        virtual void set_matrix(simd::float4x4);
        virtual void render(ui::renderer &, id<MTLRenderCommandEncoder> const, ui::encode_info const &);
    };

    class mesh : public base {
        using super_class = base;

       public:
        mesh(UInt32 const vertex_count, UInt32 const index_count, bool const dynamic);
        mesh(std::nullptr_t);

        ui::texture const &texture() const;
        simd::float4 const &color() const;
        const ui::vertex2d_t *vertices() const;
        UInt32 vertex_count() const;
        const UInt16 *indices() const;
        UInt32 index_count() const;
        bool is_dynamic() const;

        void set_texture(ui::texture texture);
        void set_color(simd::float4 const);
        void set_vertex_count(UInt32 const);
        void set_index_count(UInt32 const);

        void write(std::function<void(std::vector<ui::vertex2d_t> &, std::vector<UInt16> &)> const &);

        ui::metal_object metal();
        ui::renderable_mesh renderable();

       private:
        class impl;
    };
}
}
