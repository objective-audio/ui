//
//  yas_sample_bg.mm
//

#include "yas_sample_bg.h"

using namespace yas;

struct sample::bg::impl : base::impl {
    ui::rect_plane _rect_plane = ui::make_rect_plane(1);

    impl() {
        _rect_plane.data().set_rect_position({-0.5f, -0.5f, 1.0f, 1.0f}, 0);
        auto &node = _rect_plane.node();
        node.set_scale(0.0f);
        node.set_color(0.75f);
    }

    void setup_renderer_observer() {
        _rect_plane.node().dispatch_method(ui::node::method::renderer_changed);
        _renderer_observer = _rect_plane.node().subject().make_observer(
            ui::node::method::renderer_changed,
            [weak_bg = to_weak(cast<bg>()), view_size_observer = base{nullptr}](auto const &context) mutable {
                if (auto bg = weak_bg.lock()) {
                    auto impl = bg.impl_ptr<bg::impl>();
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

sample::bg::bg() : base(std::make_shared<impl>()) {
    impl_ptr<impl>()->setup_renderer_observer();
}

sample::bg::bg(std::nullptr_t) : base(nullptr) {
}

ui::rect_plane &sample::bg::rect_plane() {
    return impl_ptr<impl>()->_rect_plane;
}
