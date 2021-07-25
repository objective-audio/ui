//
//  yas_ui_metal_buffer.mm
//

#include "yas_ui_metal_buffer.h"

using namespace yas;
using namespace yas::ui;

metal_buffer::metal_buffer(objc_ptr<id<MTLBuffer>> &&raw_buffer) : _raw_buffer(std::move(raw_buffer)) {
}

id<MTLBuffer> metal_buffer::rawBuffer() const {
    return this->_raw_buffer.object();
}

void metal_buffer::write_from_vertices(std::vector<ui::vertex2d_t> const &vertices,
                                       std::size_t const dynamic_buffer_index) {
    if (auto vertex_ptr = static_cast<vertex2d_t *>([this->rawBuffer() contents])) {
        memcpy(&vertex_ptr[vertices.size() * dynamic_buffer_index], vertices.data(),
               vertices.size() * sizeof(vertex2d_t));
    }
}

void metal_buffer::write_from_indices(std::vector<ui::index2d_t> const &indices,
                                      std::size_t const dynamic_buffer_index) {
    if (auto index_ptr = static_cast<index2d_t *>([this->rawBuffer() contents])) {
        memcpy(&index_ptr[indices.size() * dynamic_buffer_index], indices.data(), indices.size() * sizeof(index2d_t));
    }
}

std::shared_ptr<metal_buffer> metal_buffer::make_shared(id<MTLDevice> const device, std::size_t const length) {
    auto raw_buffer = objc_ptr_with_move_object([device newBufferWithLength:length
                                                                    options:MTLResourceOptionCPUCacheModeDefault]);
    return std::shared_ptr<metal_buffer>(new metal_buffer{std::move(raw_buffer)});
}
