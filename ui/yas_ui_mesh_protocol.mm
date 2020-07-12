//
//  yas_ui_mesh_protocol.cpp
//

#include "yas_ui_mesh_protocol.h"

using namespace yas;

ui::renderable_mesh_ptr ui::renderable_mesh::cast(renderable_mesh_ptr const &mesh) {
    return mesh;
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
        case ui::mesh_update_reason::alpha_exists:
            return "alpha_exists";
        case ui::mesh_update_reason::use_mesh_color:
            return "use_mesh_color";
        case ui::mesh_update_reason::matrix:
            return "matrix";
        case ui::mesh_update_reason::count:
            return "count";
    }
}

std::ostream &operator<<(std::ostream &os, yas::ui::mesh_update_reason const &reason) {
    os << to_string(reason);
    return os;
}
