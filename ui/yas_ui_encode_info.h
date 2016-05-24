//
//  yas_ui_encode_info.h
//

#pragma once

#include <Metal/Metal.h>
#include <vector>
#include "yas_base.h"

namespace yas {
namespace ui {
    class mesh;

    class encode_info : public base {
        class impl;

       public:
        encode_info(MTLRenderPassDescriptor *const renderPassDesc, id<MTLRenderPipelineState> const pipelineState,
                    id<MTLRenderPipelineState> const pipelineStateWithoutTexture);
        encode_info(std::nullptr_t);

        void push_back_mesh(ui::mesh mesh);

        MTLRenderPassDescriptor *renderPassDescriptor() const;
        id<MTLRenderPipelineState> pipelineState() const;
        id<MTLRenderPipelineState> pipelineStateWithoutTexture() const;

        std::vector<ui::mesh> &meshes() const;
    };
}
}
