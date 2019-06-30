//
//  yas_ui_batch_protocol.mm
//

#include "yas_ui_batch_protocol.h"

using namespace yas;

ui::renderable_batch::renderable_batch(std::shared_ptr<impl> impl) : protocol(std::move(impl)) {
}

ui::renderable_batch::renderable_batch(std::nullptr_t) : protocol(nullptr) {
}

std::vector<ui::mesh> &ui::renderable_batch::meshes() {
    return impl_ptr<impl>()->meshes();
}

void ui::renderable_batch::begin_render_meshes_building(batch_building_type const type) {
    impl_ptr<impl>()->begin_render_meshes_building(type);
}

void ui::renderable_batch::commit_render_meshes_building() {
    impl_ptr<impl>()->commit_render_meshes_building();
}

void ui::renderable_batch::clear_render_meshes() {
    impl_ptr<impl>()->clear_render_meshes();
}

#pragma mark -

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
    os << yas::to_string(type);
    return os;
}
