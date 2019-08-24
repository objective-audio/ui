//
//  yas_sample_bg.mm
//

#include "yas_sample_bg.h"

using namespace yas;

struct sample::bg::impl {
    ui::rect_plane_ptr _rect_plane = ui::rect_plane::make_shared(1);
    ui::layout_guide_rect_ptr _layout_guide_rect = ui::layout_guide_rect::make_shared();

    impl() {
        auto &node = this->_rect_plane->node();
        node->color()->set_value({.v = 0.75f});
    }

    void prepare(std::shared_ptr<sample::bg> const &bg) {
        auto weak_bg = to_weak(bg);

        this->_rect_observer = this->_layout_guide_rect->chain()
                                   .guard([weak_bg](ui::region const &) { return !weak_bg.expired(); })
                                   .perform([weak_bg](ui::region const &value) {
                                       weak_bg.lock()->rect_plane()->data()->set_rect_position(value, 0);
                                   })
                                   .end();

        this->_renderer_observer =
            this->_rect_plane->node()
                ->chain_renderer()
                .perform([weak_bg,
                          layout = chaining::any_observer_ptr{nullptr}](ui::renderer_ptr const &value) mutable {
                    if (auto bg = weak_bg.lock()) {
                        auto &impl = bg->_impl;
                        if (value) {
                            layout =
                                value->safe_area_layout_guide_rect()->chain().send_to(impl->_layout_guide_rect).sync();
                        } else {
                            layout = nullptr;
                        }
                    }
                })
                .end();
    }

   private:
    chaining::any_observer_ptr _renderer_observer = nullptr;
    chaining::any_observer_ptr _rect_observer = nullptr;
};

sample::bg::bg() : _impl(std::make_shared<impl>()) {
}

ui::rect_plane_ptr const &sample::bg::rect_plane() {
    return this->_impl->_rect_plane;
}

void sample::bg::_prepare(std::shared_ptr<bg> const &shared) {
    this->_impl->prepare(shared);
}

sample::bg_ptr sample::bg::make_shared() {
    auto shared = std::shared_ptr<bg>(new bg{});
    shared->_prepare(shared);
    return shared;
}
