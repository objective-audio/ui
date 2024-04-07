//
//  yas_ui_metal_system_protocol.h
//

#pragma once

#include <Metal/Metal.h>
#include <MetalPerformanceShaders/MetalPerformanceShaders.h>
#include <cpp-utils/yas_objc_ptr.h>
#include <objc-utils/yas_objc_macros.h>
#include <ui/mesh/yas_ui_mesh.h>
#include <ui/metal/yas_ui_metal_encode_info.h>
#include <ui/render_info/yas_ui_render_info_dependency.h>

namespace yas::ui {
struct testable_metal_system {
    virtual ~testable_metal_system() = default;

    [[nodiscard]] virtual id<MTLRenderPipelineState> mtlRenderPipelineStateWithTexture() = 0;
    [[nodiscard]] virtual id<MTLRenderPipelineState> mtlRenderPipelineStateWithoutTexture() = 0;

    static std::shared_ptr<testable_metal_system> cast(std::shared_ptr<testable_metal_system> const &system) {
        return system;
    }
};
}  // namespace yas::ui
