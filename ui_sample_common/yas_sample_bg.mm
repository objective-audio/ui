//
//  yas_sample_bg.mm
//

#include "yas_sample_bg.h"
#include "yas_ui_layout.h"

using namespace yas;

struct sample::bg::impl : base::impl {
    ui::rect_plane _rect_plane{1};
    ui::layout_guide_rect _layout_guide_rect;

    impl() {
        auto &node = this->_rect_plane.node();
        node.set_color({.v = 0.75f});
    }

    void prepare(sample::bg &bg) {
        auto weak_bg = to_weak(bg);

        this->_layout_guide_rect.set_value_changed_handler([weak_bg](auto const &context) {
            if (auto bg = weak_bg.lock()) {
                bg.rect_plane().data().set_rect_position(context.layout_guide_rect.region(), 0);
            }
        });

        this->_renderer_observer = this->_rect_plane.node().dispatch_and_make_observer(
            ui::node::method::renderer_changed, [weak_bg, layout = ui::layout{nullptr}](auto const &context) mutable {
                if (sample::bg bg = weak_bg.lock()) {
                    auto impl = bg.impl_ptr<sample::bg::impl>();
                    ui::node node = context.value;
                    if (ui::renderer renderer = node.renderer()) {
                        layout = ui::make_layout(
                            ui::fixed_layout_rect::args{.source_guide_rect = renderer.safe_area_layout_guide_rect(),
                                                        .destination_guide_rect = impl->_layout_guide_rect});
                    } else {
                        layout = nullptr;
                    }
                }
            });
    }

   private:
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
