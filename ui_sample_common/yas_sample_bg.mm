//
//  yas_sample_bg.mm
//

#include "yas_sample_bg.h"

using namespace yas;
using namespace yas::ui;

sample::bg::bg(std::shared_ptr<ui::layout_region_source> const &safe_area_guide) {
    this->_rect_plane->node()->set_color({.v = 0.75f});

    this->_layout_guide
        ->observe([this](region const &region) { this->rect_plane()->data()->set_rect_position(region, 0); })
        .end()
        ->add_to(this->_pool);

    safe_area_guide->observe_layout_region([this](region const &region) { this->_layout_guide->set_region(region); })
        .sync()
        ->add_to(this->_pool);
}

std::shared_ptr<rect_plane> const &sample::bg::rect_plane() {
    return this->_rect_plane;
}

sample::bg_ptr sample::bg::make_shared(std::shared_ptr<ui::layout_region_source> const &safe_area_guide) {
    return std::shared_ptr<bg>(new bg{safe_area_guide});
}
