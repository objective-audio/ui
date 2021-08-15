//
//  yas_ui_metal_buffer.h
//

#pragma once

#include <Metal/Metal.h>
#include <cpp_utils/yas_objc_ptr.h>
#include <ui/yas_ui_gl_buffer.h>

#include <vector>

namespace yas::ui {
struct metal_buffer final : gl_buffer {
    id<MTLBuffer> rawBuffer() const;

    void write_from_vertices(std::vector<ui::vertex2d_t> const &, std::size_t const dynamic_buffer_index) override;
    void write_from_indices(std::vector<ui::index2d_t> const &, std::size_t const dynamic_buffer_index) override;

    [[nodiscard]] static std::shared_ptr<metal_buffer> make_shared(id<MTLDevice> const, std::size_t const length);

   private:
    objc_ptr<id<MTLBuffer>> _raw_buffer;

    metal_buffer(objc_ptr<id<MTLBuffer>> &&);
};
}  // namespace yas::ui
