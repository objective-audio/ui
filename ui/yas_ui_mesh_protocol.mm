//
//  yas_ui_mesh_protocol.cpp
//

#include "yas_ui_mesh_protocol.h"

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

bool ui::renderable_mesh_data::needs_update_for_render() {
    return impl_ptr<impl>()->needs_update_for_render();
}

void ui::renderable_mesh_data::update_render_buffer_if_needed() {
    impl_ptr<impl>()->update_render_buffer_if_needed();
}

#pragma mark - renderable_mesh

ui::renderable_mesh::renderable_mesh(std::shared_ptr<impl> impl) : protocol(std::move(impl)) {
}

ui::renderable_mesh::renderable_mesh(std::nullptr_t) : protocol(nullptr) {
}

simd::float4x4 const &ui::renderable_mesh::matrix() {
    return impl_ptr<impl>()->matrix();
}

void ui::renderable_mesh::set_matrix(simd::float4x4 matrix) {
    impl_ptr<impl>()->set_matrix(std::move(matrix));
}

std::size_t ui::renderable_mesh::render_vertex_count() {
    return impl_ptr<impl>()->render_vertex_count();
}

std::size_t ui::renderable_mesh::render_index_count() {
    return impl_ptr<impl>()->render_index_count();
}

bool ui::renderable_mesh::needs_update_for_render() {
    return impl_ptr<impl>()->needs_update_for_render();
}

void ui::renderable_mesh::metal_render(ui::renderer_base &renderer, id<MTLRenderCommandEncoder> const encoder,
                                       ui::metal_encode_info const &encode_info) {
    impl_ptr<impl>()->metal_render(renderer, encoder, encode_info);
}

void ui::renderable_mesh::batch_render(batch_render_mesh_info &mesh_info) {
    impl_ptr<impl>()->batch_render(mesh_info);
}
