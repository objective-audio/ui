//
//  yas_ui_metal_encode_info.h
//

#pragma once

#include <Metal/Metal.h>
#include <vector>
#include "yas_base.h"

namespace yas {
namespace ui {
    class mesh;

    class metal_encode_info : public base {
        class impl;

       public:
        struct args {
            MTLRenderPassDescriptor *renderPassDescriptor = nil;
            id<MTLRenderPipelineState> pipelineStateWithTexture = nil;
            id<MTLRenderPipelineState> pipelineStateWithoutTexture = nil;
        };

        metal_encode_info(args);
        metal_encode_info(std::nullptr_t);

        void push_back_mesh(ui::mesh mesh);

        MTLRenderPassDescriptor *renderPassDescriptor() const;
        id<MTLRenderPipelineState> pipelineStateWithTexture() const;
        id<MTLRenderPipelineState> pipelineStateWithoutTexture() const;

        std::vector<ui::mesh> &meshes() const;
    };
}
}
