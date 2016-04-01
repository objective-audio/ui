//
//  yas_ui_encode_info.h
//

#pragma once

#include <Metal/Metal.h>
#include <vector>
#include "yas_base.h"
#include "yas_objc_ptr.h"

namespace yas {
namespace ui {
    class mesh;

    class encode_info : public base {
        using super_class = base;

       public:
        encode_info(MTLRenderPassDescriptor *const render_pass_desc, id<MTLRenderPipelineState> const pipeline_state,
                    id<MTLRenderPipelineState> const pipeline_state_without_texture);
        encode_info(std::nullptr_t);

        void push_back_mesh(ui::mesh mesh);

        MTLRenderPassDescriptor *renderPassDescriptor() const;
        id<MTLRenderPipelineState> pipelineState() const;
        id<MTLRenderPipelineState> pipelineStateWithoutTexture() const;

        std::vector<ui::mesh> &meshes() const;

       private:
        class impl;
    };
}
}
