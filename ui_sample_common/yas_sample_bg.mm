//
//  yas_sample_bg.mm
//

#include "yas_sample_bg.h"

using namespace yas;

sample::bg::bg() {
    this->_rect_plane->node()->set_color({.v = 0.75f});

    this->_rect_canceller =
        this->_layout_guide_rect
            ->observe([this](ui::region const &region) { this->rect_plane()->data()->set_rect_position(region, 0); })
            .end();

    this->_renderer_canceller = this->_rect_plane->node()
                                    ->observe_renderer([this, canceller = observing::cancellable_ptr{nullptr}](
                                                           ui::renderer_ptr const &value) mutable {
                                        if (value) {
                                            canceller = value->safe_area_layout_guide_rect()
                                                            ->observe([this](ui::region const &region) {
                                                                this->_layout_guide_rect->set_region(region);
                                                            })
                                                            .sync();
                                        } else {
                                            canceller = nullptr;
                                        }
                                    })
                                    .end();
}

ui::rect_plane_ptr const &sample::bg::rect_plane() {
    return this->_rect_plane;
}

sample::bg_ptr sample::bg::make_shared() {
    return std::shared_ptr<bg>(new bg{});
}
