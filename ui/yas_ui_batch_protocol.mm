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

void ui::renderable_batch::commit() {
    impl_ptr<impl>()->commit();
}

void ui::renderable_batch::clear() {
    impl_ptr<impl>()->clear();
}
