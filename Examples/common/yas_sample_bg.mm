//
//  yas_sample_bg.mm
//

#include "yas_sample_bg.h"

using namespace yas;
using namespace yas::ui;

sample::bg::bg(std::shared_ptr<ui::view_look> const &view_look) {
    view_look
        ->observe_appearance([this](ui::appearance const &appearance) {
            switch (appearance) {
                case ui::appearance::normal: {
                    this->_rect_plane->node()->set_rgb_color({.v = 0.75f});
                } break;
                case ui::appearance::dark: {
                    this->_rect_plane->node()->set_rgb_color({.v = 0.25f});
                } break;
            }
        })
        .sync()
        ->add_to(this->_pool);

    this->_layout_guide
        ->observe([this](region const &region) { this->rect_plane()->data()->set_rect_position(region, 0); })
        .end()
        ->add_to(this->_pool);

    view_look->safe_area_layout_guide()
        ->observe([this](region const &region) { this->_layout_guide->set_region(region); })
        .sync()
        ->add_to(this->_pool);
}

std::shared_ptr<rect_plane> const &sample::bg::rect_plane() {
    return this->_rect_plane;
}

sample::bg_ptr sample::bg::make_shared(std::shared_ptr<ui::view_look> const &view_look) {
    return std::shared_ptr<bg>(new bg{view_look});
}
