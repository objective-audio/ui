//
//  yas_ui_square_node_impl.mm
//

#include "yas_ui_mesh.h"
#include "yas_ui_mesh_data.h"
#include "yas_ui_square_node.h"

yas::ui::square_node::impl::impl(std::size_t const square_count) : super_class(), _mesh_data(square_count) {
    ui::mesh mesh;
    mesh.set_data(_mesh_data.mesh_data());
    set_mesh(std::move(mesh));
}