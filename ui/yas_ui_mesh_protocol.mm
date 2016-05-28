//
//  yas_ui_mesh_protocol.cpp
//

#include "yas_ui_mesh_protocol.h"

using namespace yas;

#pragma mark - renderable_mesh_data

ui::renderable_mesh_data::renderable_mesh_data(std::shared_ptr<impl> impl) : protocol(std::move(impl)) {
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

bool ui::renderable_mesh_data::needs_update_for_render() {
    return impl_ptr<impl>()->needs_update_for_render();
}

void ui::renderable_mesh_data::update_render_buffer_if_needed() {
    impl_ptr<impl>()->update_render_buffer_if_needed();
}

#pragma mark - renderable_mesh

ui::renderable_mesh::renderable_mesh(std::shared_ptr<impl> impl) : protocol(std::move(impl)) {
}

simd::float4x4 const &ui::renderable_mesh::matrix() {
    return impl_ptr<impl>()->matrix();
}

void ui::renderable_mesh::set_matrix(simd::float4x4 matrix) {
    impl_ptr<impl>()->set_matrix(std::move(matrix));
}

bool ui::renderable_mesh::needs_update_for_render() {
    return impl_ptr<impl>()->needs_update_for_render();
}

void ui::renderable_mesh::render(ui::renderer_base &renderer, id<MTLRenderCommandEncoder> const encoder,
                                 ui::metal_encode_info const &encode_info) {
    impl_ptr<impl>()->render(renderer, encoder, encode_info);
}
