//
//  yas_ui_metal_buffer.mm
//

#include "yas_ui_metal_buffer.h"

#include <ui/common/yas_ui_shared_types.h>
#include <ui/common/yas_ui_types.h>

using namespace yas;
using namespace yas::ui;

metal_buffer::metal_buffer(objc_ptr<id<MTLBuffer>> &&raw_buffer) : _raw_buffer(std::move(raw_buffer)) {
}

id<MTLBuffer> metal_buffer::rawBuffer() const {
    return this->_raw_buffer.object();
}

template <>
void metal_buffer::write(std::vector<vertex2d_t> const &data, std::size_t const dynamic_buffer_index) {
    if (auto contents = static_cast<vertex2d_t *>([this->rawBuffer() contents])) {
        memcpy(&contents[data.size() * dynamic_buffer_index], data.data(), data.size() * sizeof(vertex2d_t));
    }
}

template <>
void metal_buffer::write(std::vector<index2d_t> const &data, std::size_t const dynamic_buffer_index) {
    if (auto contents = static_cast<index2d_t *>([this->rawBuffer() contents])) {
        memcpy(&contents[data.size() * dynamic_buffer_index], data.data(), data.size() * sizeof(index2d_t));
    }
}

std::shared_ptr<metal_buffer> metal_buffer::make_shared(id<MTLDevice> const device, std::size_t const length) {
    auto raw_buffer = objc_ptr_with_move_object([device newBufferWithLength:length
                                                                    options:MTLResourceCPUCacheModeDefaultCache]);
    return std::shared_ptr<metal_buffer>(new metal_buffer{std::move(raw_buffer)});
}
