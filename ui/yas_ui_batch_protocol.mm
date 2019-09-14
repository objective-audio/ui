//
//  yas_ui_batch_protocol.mm
//

#include "yas_ui_batch_protocol.h"

using namespace yas;

ui::renderable_batch_ptr ui::renderable_batch::cast(renderable_batch_ptr const &renderable) {
    return renderable;
}

std::string yas::to_string(ui::batch_building_type const &type) {
    switch (type) {
        case ui::batch_building_type::rebuild:
            return "rebuild";
        case ui::batch_building_type::overwrite:
            return "overwrite";
        case ui::batch_building_type::none:
            return "none";
    }
}

std::ostream &operator<<(std::ostream &os, yas::ui::batch_building_type const &type) {
    os << to_string(type);
    return os;
}
