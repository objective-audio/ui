//
//  yas_ui_metal_buffer.mm
//

#include "yas_ui_metal_buffer.h"

using namespace yas;
using namespace yas::ui;

metal_buffer::metal_buffer(objc_ptr<id<MTLBuffer>> &&raw_buffer) : _raw_buffer(std::move(raw_buffer)) {
}

id<MTLBuffer> metal_buffer::raw_buffer() const {
    return this->_raw_buffer.object();
}

std::shared_ptr<metal_buffer> metal_buffer::make_shared(id<MTLDevice> const device, std::size_t const length) {
    auto raw_buffer = objc_ptr_with_move_object([device newBufferWithLength:length
                                                                    options:MTLResourceOptionCPUCacheModeDefault]);
    return std::shared_ptr<metal_buffer>(new metal_buffer{std::move(raw_buffer)});
}
