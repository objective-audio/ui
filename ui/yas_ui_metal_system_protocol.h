//
//  yas_ui_metal_system_protocol.h
//

#pragma once

#include <Metal/Metal.h>
#include "yas_objc_macros.h"
#include "yas_protocol.h"

namespace yas {
namespace ui {
    class renderer;
    class mesh;
    class metal_encode_info;

    struct renderable_metal_system : protocol {
        struct impl : protocol::impl {
            virtual void view_render(yas_objc_view *const view, ui::renderer &) = 0;
            virtual void prepare_uniforms_buffer(uint32_t const uniforms_count) = 0;
            virtual void mesh_encode(ui::mesh &, id<MTLRenderCommandEncoder> const, ui::metal_encode_info const &) = 0;
        };

        explicit renderable_metal_system(std::shared_ptr<impl>);
        renderable_metal_system(std::nullptr_t);

        void view_render(yas_objc_view *const view, ui::renderer &);
        void prepare_uniforms_buffer(uint32_t const uniforms_count);
        void mesh_encode(ui::mesh &, id<MTLRenderCommandEncoder> const, ui::metal_encode_info const &);
    };
}
}
