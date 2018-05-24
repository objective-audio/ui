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

        this->_rect_observer = this->_layout_guide_rect.begin_flow()
                                   .filter([weak_bg](ui::region const &) { return !!weak_bg; })
                                   .perform([weak_bg](ui::region const &value) {
                                       weak_bg.lock().rect_plane().data().set_rect_position(value, 0);
                                   })
                                   .end();

        this->_renderer_observer = this->_rect_plane.node().dispatch_and_make_observer(
            ui::node::method::renderer_changed,
            [weak_bg, layout = flow::observer{nullptr}](auto const &context) mutable {
                if (sample::bg bg = weak_bg.lock()) {
                    auto impl = bg.impl_ptr<sample::bg::impl>();
                    ui::node node = context.value;
                    if (ui::renderer renderer = node.renderer()) {
                        layout = renderer.safe_area_layout_guide_rect()
                                     .begin_flow()
                                     .receive(impl->_layout_guide_rect.receiver())
                                     .sync();
                    } else {
                        layout = nullptr;
                    }
                }
            });
    }

   private:
    ui::node::observer_t _renderer_observer = nullptr;
    flow::observer _rect_observer = nullptr;
};

sample::bg::bg() : base(std::make_shared<impl>()) {
    impl_ptr<impl>()->prepare(*this);
}

sample::bg::bg(std::nullptr_t) : base(nullptr) {
}

ui::rect_plane &sample::bg::rect_plane() {
    return impl_ptr<impl>()->_rect_plane;
}
