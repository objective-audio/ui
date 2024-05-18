//
//  yas_ui_metal_buffer.h
//

#pragma once

#include <Metal/Metal.h>
#include <cpp-utils/objc_ptr.h>

#include <vector>

namespace yas::ui {
struct metal_buffer final {
    id<MTLBuffer> rawBuffer() const;

    template <typename T>
    void write(std::vector<T> const &data, std::size_t const dynamic_buffer_index);

    [[nodiscard]] static std::shared_ptr<metal_buffer> make_shared(id<MTLDevice> const, std::size_t const length);

   private:
    objc_ptr<id<MTLBuffer>> _raw_buffer;

    metal_buffer(objc_ptr<id<MTLBuffer>> &&);
};
}  // namespace yas::ui
