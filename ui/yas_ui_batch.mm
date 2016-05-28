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
    ui::node root_node;
    ui::node render_node;
    std::vector<ui::node> batched_nodes;

    impl() {
        render_node.push_back_sub_node(root_node);
        root_node.renderable().set_children_batching_enabled(true);
    }
};

ui::batch::batch() : base(std::make_shared<impl>()) {
}

ui::batch::batch(std::nullptr_t) : base(nullptr) {
}

ui::node &ui::batch::root_node() {
    return impl_ptr<impl>()->root_node;
}

ui::node &ui::batch::render_node() {
    return impl_ptr<impl>()->render_node;
}

ui::renderable_batch ui::batch::renderable() {
    return ui::renderable_batch{impl_ptr<ui::renderable_batch::impl>()};
}
