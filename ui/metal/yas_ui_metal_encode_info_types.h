//
//  yas_ui_metal_encode_info_types.h
//

#pragma once

#include <Metal/Metal.h>

namespace yas::ui {
struct metal_encode_info_args final {
    MTLRenderPassDescriptor *renderPassDescriptor = nil;
    id<MTLRenderPipelineState> pipelineStateWithTexture = nil;
    id<MTLRenderPipelineState> pipelineStateWithoutTexture = nil;
};
}  // namespace yas::ui
