//
//  yas_sample_bg.mm
//

#include "yas_sample_bg.h"

using namespace yas;

struct sample::bg::impl : base::impl {
    ui::rect_plane _rect_plane = ui::make_rect_plane(1);

    impl() {
        auto &node = _rect_plane.node();
        node.set_color({.v = 0.75f});
    }

    void prepare(sample::bg &bg) {
        _rect_plane.node().dispatch_method(ui::node::method::renderer_changed);
        _renderer_observer = _rect_plane.node().subject().make_observer(ui::node::method::renderer_changed, [
            weak_bg = to_weak(bg), observer = base{nullptr}, safe_area_observer = base{nullptr}
        ](auto const &context) mutable {
            if (auto bg = weak_bg.lock()) {
                auto impl = bg.impl_ptr<sample::bg::impl>();
                auto node = context.value;
                if (auto renderer = node.renderer()) {
                    observer = _make_observer(node, renderer, weak_bg);
                } else {
                    observer = nullptr;
                }
            }
        });
    }

   private:
    static base _make_observer(ui::node &node, ui::renderer &renderer, weak<sample::bg> &weak_bg) {
        auto set_rect = [weak_bg](ui::node &node, ui::renderer const &renderer) {
            if (auto bg = weak_bg.lock()) {
                bg.rect_plane().data().set_rect_position(renderer.safe_area_layout_guide_rect().region(), 0);
            }
        };

        set_rect(node, renderer);

        return renderer.subject().make_wild_card_observer(
            [weak_node = to_weak(node), set_rect = std::move(set_rect)](auto const &context) {
                if (auto node = weak_node.lock()) {
                    switch (context.key) {
                        case ui::renderer::method::view_size_changed:
                        case ui::renderer::method::safe_area_insets_changed: {
                            auto const &renderer = context.value;
                            set_rect(node, renderer);
                        } break;

                        default:
                            break;
                    }
                }
            });
    }

    ui::node::observer_t _renderer_observer = nullptr;
};

sample::bg::bg() : base(std::make_shared<impl>()) {
    impl_ptr<impl>()->prepare(*this);
}

sample::bg::bg(std::nullptr_t) : base(nullptr) {
}

ui::rect_plane &sample::bg::rect_plane() {
    return impl_ptr<impl>()->_rect_plane;
}
