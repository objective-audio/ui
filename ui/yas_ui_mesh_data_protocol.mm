//
//  yas_ui_mesh_data_protocol.mm
//

#include "yas_ui_mesh_data_protocol.h"

using namespace yas;

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
