//
//  yas_ui_mesh_data_protocol.mm
//

#include "yas_ui_mesh_data_protocol.h"

using namespace yas;

#pragma mark - renderable_mesh_data

ui::renderable_mesh_data::renderable_mesh_data(std::shared_ptr<impl> impl) : protocol(std::move(impl)) {
}

ui::renderable_mesh_data::renderable_mesh_data(std::nullptr_t) : protocol(nullptr) {
}

std::size_t ui::renderable_mesh_data::vertex_buffer_byte_offset() {
    return impl_ptr<impl>()->vertex_buffer_byte_offset();
}

std::size_t ui::renderable_mesh_data::index_buffer_byte_offset() {
    return impl_ptr<impl>()->index_buffer_byte_offset();
}

id<MTLBuffer> ui::renderable_mesh_data::vertexBuffer() {
    return impl_ptr<impl>()->vertexBuffer();
}

id<MTLBuffer> ui::renderable_mesh_data::indexBuffer() {
    return impl_ptr<impl>()->indexBuffer();
}

ui::mesh_data_updates_t const &ui::renderable_mesh_data::updates() {
    return impl_ptr<impl>()->updates();
}

void ui::renderable_mesh_data::update_render_buffer_if_needed() {
    impl_ptr<impl>()->update_render_buffer_if_needed();
}
