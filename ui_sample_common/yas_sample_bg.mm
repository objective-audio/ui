//
//  yas_sample_bg.mm
//

#include "yas_sample_bg.h"

using namespace yas;

struct sample::bg::impl : base::impl {
    ui::rect_plane _rect_plane{1};
    ui::layout_guide_rect _layout_guide_rect;

    impl() {
        auto &node = this->_rect_plane.node();
        node.color().set_value({.v = 0.75f});
    }

    void prepare(sample::bg &bg) {
        auto weak_bg = to_weak(bg);

        this->_rect_observer = this->_layout_guide_rect.chain()
                                   .guard([weak_bg](ui::region const &) { return !!weak_bg; })
                                   .perform([weak_bg](ui::region const &value) {
                                       weak_bg.lock().rect_plane().data().set_rect_position(value, 0);
                                   })
                                   .end();

        this->_renderer_observer =
            this->_rect_plane.node()
                .chain_renderer()
                .perform([weak_bg, layout = chaining::any_observer{nullptr}](ui::renderer const &value) mutable {
                    if (sample::bg bg = weak_bg.lock()) {
                        auto impl = bg.impl_ptr<sample::bg::impl>();
                        if (ui::renderer renderer = value) {
                            layout = renderer.safe_area_layout_guide_rect()
                                         .chain()
                                         .send_to(impl->_layout_guide_rect.receiver())
                                         .sync();
                        } else {
                            layout = nullptr;
                        }
                    }
                })
                .end();
    }

   private:
    chaining::any_observer _renderer_observer = nullptr;
    chaining::any_observer _rect_observer = nullptr;
};

sample::bg::bg() : base(std::make_shared<impl>()) {
    impl_ptr<impl>()->prepare(*this);
}

sample::bg::bg(std::nullptr_t) : base(nullptr) {
}

ui::rect_plane &sample::bg::rect_plane() {
    return impl_ptr<impl>()->_rect_plane;
}
