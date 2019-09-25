//
//  yas_sample_bg.mm
//

#include "yas_sample_bg.h"

using namespace yas;

sample::bg::bg() {
    this->_rect_plane->node()->color()->set_value({.v = 0.75f});
}

ui::rect_plane_ptr const &sample::bg::rect_plane() {
    return this->_rect_plane;
}

void sample::bg::_prepare(std::shared_ptr<bg> const &shared) {
    auto weak_bg = to_weak(shared);

    this->_rect_observer = this->_layout_guide_rect->chain()
                               .guard([weak_bg](ui::region const &) { return !weak_bg.expired(); })
                               .perform([weak_bg](ui::region const &value) {
                                   weak_bg.lock()->rect_plane()->data()->set_rect_position(value, 0);
                               })
                               .end();

    this->_renderer_observer =
        this->_rect_plane->node()
            ->chain_renderer()
            .perform([weak_bg, layout = chaining::any_observer_ptr{nullptr}](ui::renderer_ptr const &value) mutable {
                if (auto bg = weak_bg.lock()) {
                    if (value) {
                        layout = value->safe_area_layout_guide_rect()->chain().send_to(bg->_layout_guide_rect).sync();
                    } else {
                        layout = nullptr;
                    }
                }
            })
            .end();
}

sample::bg_ptr sample::bg::make_shared() {
    auto shared = std::shared_ptr<bg>(new bg{});
    shared->_prepare(shared);
    return shared;
}
