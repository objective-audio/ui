//
//  yas_sample_bg_node.mm
//

#include "yas_sample_bg_node.h"

using namespace yas;

struct sample::bg_node::impl : base::impl {
    ui::square_node square_node = ui::make_square_node(1);

    impl() {
        square_node.square_mesh_data().set_square_position({-0.5f, -0.5f, 1.0f, 1.0f}, 0);
        auto &node = square_node.node();
        node.set_scale(0.0f);
        node.set_color(0.75f);
    }

    void setup_renderer_observer() {
        square_node.node().dispatch_method(ui::node::method::renderer_changed);
        _renderer_observer = square_node.node().subject().make_observer(
            ui::node::method::renderer_changed,
            [weak_bg_node = to_weak(cast<bg_node>()), view_size_observer = base{nullptr}](auto const &context) mutable {
                if (auto bg_node = weak_bg_node.lock()) {
                    auto impl = bg_node.impl_ptr<bg_node::impl>();
                    auto node = context.value;
                    if (auto renderer = node.renderer()) {
                        view_size_observer = _make_view_size_observer(node, renderer);
                    } else {
                        view_size_observer = nullptr;
                    }
                }
            });
    }

   private:
    static base _make_view_size_observer(ui::node &node, ui::renderer &renderer) {
        auto set_scale = [](ui::node &node, ui::uint_size const &view_size) {
            node.set_scale({static_cast<float>(view_size.width), static_cast<float>(view_size.height)});
        };

        set_scale(node, renderer.view_size());

        return renderer.subject().make_observer(
            ui::renderer::method::view_size_changed,
            [weak_node = to_weak(node), set_scale = std::move(set_scale)](auto const &context) {
                if (auto node = weak_node.lock()) {
                    auto const &renderer = context.value;
                    set_scale(node, renderer.view_size());
                }
            });
    }

    base _renderer_observer = nullptr;
};

sample::bg_node::bg_node() : base(std::make_shared<impl>()) {
    impl_ptr<impl>()->setup_renderer_observer();
}

sample::bg_node::bg_node(std::nullptr_t) : base(nullptr) {
}

ui::square_node &sample::bg_node::square_node() {
    return impl_ptr<impl>()->square_node;
}
