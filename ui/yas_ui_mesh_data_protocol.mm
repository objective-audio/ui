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

void ui::renderable_mesh_data::clear_updates() {
    impl_ptr<impl>()->clear_updates();
}

std::string yas::to_string(ui::mesh_data_update_reason const &reason) {
    switch (reason) {
        case ui::mesh_data_update_reason::data:
            return "data";
        case ui::mesh_data_update_reason::vertex_count:
            return "vertex_count";
        case ui::mesh_data_update_reason::index_count:
            return "index_count";
        case ui::mesh_data_update_reason::render_buffer:
            return "render_buffer";
        case ui::mesh_data_update_reason::count:
            return "count";
    }
}

std::ostream &operator<<(std::ostream &os, yas::ui::mesh_data_update_reason const &reason) {
    os << to_string(reason);
    return os;
}
