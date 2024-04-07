//
//  yas_ui_mesh_data.h
//

#pragma once

#include <ui/metal/yas_ui_metal_setup_types.h>
#include <ui/renderer/yas_ui_renderer_dependency.h>

@protocol MTLBuffer;

namespace yas::ui {
template <typename T>
struct mesh_data {
    virtual ~mesh_data() = default;

    [[nodiscard]] virtual T const *raw_data() const = 0;
    [[nodiscard]] virtual std::size_t count() const = 0;

    [[nodiscard]] virtual std::size_t byte_offset() = 0;
    [[nodiscard]] virtual id<MTLBuffer> mtlBuffer() = 0;

    [[nodiscard]] virtual mesh_data_updates_t const &updates() = 0;
    virtual void update_render_buffer() = 0;
    virtual void clear_updates() = 0;

    [[nodiscard]] virtual ui::setup_metal_result metal_setup(std::shared_ptr<ui::metal_system> const &) = 0;
};
}  // namespace yas::ui
