//
//  yas_ui_metal_system.h
//

#pragma once

#include <CoreGraphics/CoreGraphics.h>
#include "yas_base.h"
#include "yas_ui_metal_system_protocol.h"

namespace yas {
namespace ui {
    class metal_system : public base {
       public:
        class impl;

        explicit metal_system(id<MTLDevice> const);
        metal_system(std::nullptr_t);

        id<MTLTexture> newMtlTexture(MTLTextureDescriptor *) const;
        id<MTLSamplerState> newMtlSamplerState(MTLSamplerDescriptor *) const;
        id<MTLBuffer> newMtlBuffer(std::size_t const length) const;

        ui::renderable_metal_system &renderable();

       private:
        ui::renderable_metal_system _renderable = nullptr;
    };
}
}
