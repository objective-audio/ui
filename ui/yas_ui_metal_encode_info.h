//
//  yas_ui_metal_encode_info.h
//

#pragma once

#include <Metal/Metal.h>
#include <unordered_map>
#include <vector>
#include "yas_ui_effect.h"
#include "yas_ui_mesh.h"
#include "yas_ui_ptr.h"

namespace yas::ui {
class texture;

struct metal_encode_info final {
    struct args {
        MTLRenderPassDescriptor *renderPassDescriptor = nil;
        id<MTLRenderPipelineState> pipelineStateWithTexture = nil;
        id<MTLRenderPipelineState> pipelineStateWithoutTexture = nil;
    };

    virtual ~metal_encode_info();

    void append_mesh(ui::mesh_ptr const &);
    void append_effect(ui::effect_ptr const &);

    MTLRenderPassDescriptor *renderPassDescriptor() const;
    id<MTLRenderPipelineState> pipelineStateWithTexture() const;
    id<MTLRenderPipelineState> pipelineStateWithoutTexture() const;

    std::vector<ui::mesh_ptr> const &meshes() const;
    std::vector<ui::effect_ptr> const &effects() const;
    std::unordered_map<uintptr_t, ui::texture_ptr> &textures() const;

    [[nodiscard]] static metal_encode_info_ptr make_shared(args);

   private:
    class impl;

    std::unique_ptr<impl> _impl;

    metal_encode_info(args &&);

    metal_encode_info(metal_encode_info const &) = delete;
    metal_encode_info(metal_encode_info &&) = delete;
    metal_encode_info &operator=(metal_encode_info const &) = delete;
    metal_encode_info &operator=(metal_encode_info &&) = delete;
};
}  // namespace yas::ui
