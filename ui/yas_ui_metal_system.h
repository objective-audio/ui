//
//  yas_ui_metal_system.h
//

#pragma once

#include <CoreGraphics/CoreGraphics.h>
#include "yas_ui_metal_system_protocol.h"
#include "yas_ui_ptr.h"

namespace yas::ui {

struct metal_system final : renderable_metal_system, std::enable_shared_from_this<metal_system> {
    class impl;

    virtual ~metal_system();

    std::size_t last_encoded_mesh_count() const;

    ui::makable_metal_system &makable();
    ui::renderable_metal_system_ptr renderable();

    ui::testable_metal_system testable();

    [[nodiscard]] static metal_system_ptr make_shared(id<MTLDevice> const);
    [[nodiscard]] static metal_system_ptr make_shared(id<MTLDevice> const, uint32_t const sample_count);

   private:
    std::shared_ptr<impl> _impl;

    ui::makable_metal_system _makable = nullptr;

    metal_system(id<MTLDevice> const, uint32_t const sample_count);

    metal_system(metal_system const &) = delete;
    metal_system(metal_system &&) = delete;
    metal_system &operator=(metal_system const &) = delete;
    metal_system &operator=(metal_system &&) = delete;

    void _prepare(metal_system_ptr const &);

    void view_configure(yas_objc_view *const) override;
    void view_render(yas_objc_view *const view, ui::renderer_ptr const &) override;
    void prepare_uniforms_buffer(uint32_t const uniforms_count) override;
    void mesh_encode(ui::mesh_ptr const &, id<MTLRenderCommandEncoder> const,
                     ui::metal_encode_info_ptr const &) override;
    void push_render_target(ui::render_stackable_ptr const &, ui::render_target_ptr const &) override;
};
}  // namespace yas::ui
