//
//  yas_ui_mesh_protocol.cpp
//

#include "yas_ui_mesh_protocol.h"

using namespace yas;

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

ui::mesh_updates_t const &ui::renderable_mesh::updates() {
    return impl_ptr<impl>()->updates();
}

bool ui::renderable_mesh::pre_render() {
    return impl_ptr<impl>()->pre_render();
}

void ui::renderable_mesh::batch_render(ui::batch_render_mesh_info &mesh_info,
                                       ui::batch_building_type const building_type) {
    impl_ptr<impl>()->batch_render(mesh_info, building_type);
}

bool ui::renderable_mesh::is_rendering_color_exists() {
    return impl_ptr<impl>()->is_rendering_color_exists();
}

void ui::renderable_mesh::clear_updates() {
    impl_ptr<impl>()->clear_updates();
}

std::string yas::to_string(ui::mesh_update_reason const &reason) {
    switch (reason) {
        case ui::mesh_update_reason::mesh_data:
            return "mesh_data";
        case ui::mesh_update_reason::texture:
            return "texture";
        case ui::mesh_update_reason::primitive_type:
            return "primitive_type";
        case ui::mesh_update_reason::color:
            return "color";
        case ui::mesh_update_reason::use_mesh_color:
            return "use_mesh_color";
        case ui::mesh_update_reason::count:
            return "count";
    }
}

std::ostream &operator<<(std::ostream &os, yas::ui::mesh_update_reason const &reason) {
    os << to_string(reason);
    return os;
}
