//
//  yas_ui_batch.mm
//

#include "yas_ui_batch.h"
#include "yas_ui_batch_protocol.h"
#include "yas_ui_mesh.h"
#include "yas_ui_node.h"
#include "yas_ui_texture.h"

using namespace yas;

struct ui::batch::impl : base::impl, renderable_batch::impl {
    impl() {
    }
};

ui::batch::batch() : base(std::make_shared<impl>()) {
}

ui::batch::batch(std::nullptr_t) : base(nullptr) {
}

ui::renderable_batch ui::batch::renderable() {
    return ui::renderable_batch{impl_ptr<ui::renderable_batch::impl>()};
}
