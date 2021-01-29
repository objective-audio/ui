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
    this->_rect_canceller = this->_layout_guide_rect->observe(
        [this](ui::region const &region) { this->rect_plane()->data()->set_rect_position(region, 0); }, false);

    this->_renderer_canceller = this->_rect_plane->node()->observe_renderer(
        [this, canceller = observing::cancellable_ptr{nullptr}](ui::renderer_ptr const &value) mutable {
            if (value) {
                canceller = value->safe_area_layout_guide_rect()->observe(
                    [this](ui::region const &region) { this->_layout_guide_rect->set_region(region); }, true);
            } else {
                canceller = nullptr;
            }
        },
        false);
}

sample::bg_ptr sample::bg::make_shared() {
    auto shared = std::shared_ptr<bg>(new bg{});
    shared->_prepare(shared);
    return shared;
}
