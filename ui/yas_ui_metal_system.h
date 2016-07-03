//
//  yas_ui_metal_system.h
//

#pragma once

#include <CoreGraphics/CoreGraphics.h>
#include <Metal/Metal.h>
#include "yas_base.h"
#include "yas_objc_macros.h"

namespace yas {
namespace ui {
    class renderer;
    class mesh;
    class metal_encode_info;

    class metal_system : public base {
       public:
        class impl;

        explicit metal_system(id<MTLDevice> const);
        metal_system(std::nullptr_t);

        id<MTLDevice> device() const;

        uint32_t sample_count() const;

        void view_render(yas_objc_view *const view, ui::renderer &);
        void mesh_render(ui::mesh &mesh, id<MTLRenderCommandEncoder> const encoder,
                         ui::metal_encode_info const &encode_info);
    };
}
}
