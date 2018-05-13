//
//  yas_ui_metal_encode_info.h
//

#pragma once

#include <Metal/Metal.h>
#include <unordered_map>
#include <vector>
#include "yas_base.h"

namespace yas::ui {
class mesh;
class effect;
class texture;

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

    virtual ~metal_encode_info() final;

    void append_mesh(ui::mesh);
    void append_effect(ui::effect);

    MTLRenderPassDescriptor *renderPassDescriptor() const;
    id<MTLRenderPipelineState> pipelineStateWithTexture() const;
    id<MTLRenderPipelineState> pipelineStateWithoutTexture() const;

    std::vector<ui::mesh> &meshes() const;
    std::vector<ui::effect> &effects() const;
    std::unordered_map<uintptr_t, ui::texture> &textures() const;
};
}  // namespace yas::ui
