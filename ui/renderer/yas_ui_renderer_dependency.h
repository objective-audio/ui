//
//  yas_ui_renderer_dependency.h
//

#pragma once

#include <Metal/Metal.h>
#include <objc_utils/yas_objc_macros.h>
#include <ui/yas_ui_node_dependency.h>
#include <ui/yas_ui_renderer_dependency_cpp.h>
#include <ui/yas_ui_types.h>

@class YASUIMetalView;

namespace yas::ui {
struct renderable_render_target {
    virtual ~renderable_render_target() = default;

    [[nodiscard]] virtual std::shared_ptr<mesh> const &mesh() const = 0;
    [[nodiscard]] virtual std::shared_ptr<effect> const &effect() const = 0;
    [[nodiscard]] virtual render_target_updates_t const &updates() const = 0;
    virtual void clear_updates() = 0;
    [[nodiscard]] virtual MTLRenderPassDescriptor *renderPassDescriptor() const = 0;
    [[nodiscard]] virtual simd::float4x4 const &projection_matrix() const = 0;
    [[nodiscard]] virtual bool push_encode_info(std::shared_ptr<render_stackable> const &) = 0;

    static std::shared_ptr<renderable_render_target> cast(
        std::shared_ptr<renderable_render_target> const &render_target) {
        return render_target;
    }
};

struct renderable_mesh_data {
    virtual ~renderable_mesh_data() = default;

    [[nodiscard]] virtual std::size_t vertex_buffer_byte_offset() = 0;
    [[nodiscard]] virtual std::size_t index_buffer_byte_offset() = 0;
    [[nodiscard]] virtual id<MTLBuffer> vertexBuffer() = 0;
    [[nodiscard]] virtual id<MTLBuffer> indexBuffer() = 0;

    [[nodiscard]] virtual mesh_data_updates_t const &updates() = 0;
    virtual void update_render_buffer() = 0;
    virtual void clear_updates() = 0;

    [[nodiscard]] static std::shared_ptr<renderable_mesh_data> cast(
        std::shared_ptr<renderable_mesh_data> const &mesh_data) {
        return mesh_data;
    }
};

struct renderable_metal_system {
    virtual ~renderable_metal_system() = default;

    virtual void view_render(YASUIMetalView *const view, std::shared_ptr<ui::render_info_detector_interface> const &,
                             simd::float4x4 const &projection_matrix, std::shared_ptr<ui::node> const &) = 0;
    virtual void prepare_uniforms_buffer(uint32_t const uniforms_count) = 0;
    virtual void mesh_encode(std::shared_ptr<mesh> const &, id<MTLRenderCommandEncoder> const,
                             std::shared_ptr<metal_encode_info> const &) = 0;
    virtual void push_render_target(std::shared_ptr<render_stackable> const &, ui::render_target const *) = 0;

    [[nodiscard]] static std::shared_ptr<renderable_metal_system> cast(
        std::shared_ptr<renderable_metal_system> const &system) {
        return system;
    }
};
}  // namespace yas::ui
