//
//  yas_ui_texture_element.mm
//

#include "yas_ui_texture_element.h"

using namespace yas;
using namespace yas::ui;

texture_element::texture_element(draw_pair_t &&pair) : _draw_pair(std::move(pair)) {
}

draw_pair_t const &texture_element::draw_pair() const {
    return this->_draw_pair;
}

void texture_element::set_tex_coords(uint_region const &tex_coords) {
    this->_tex_coords->set_value(tex_coords);
}

uint_region const &texture_element::tex_coords() const {
    return this->_tex_coords->value();
}

observing::syncable texture_element::observe_tex_coords(std::function<void(uint_region const &)> &&handler) {
    return this->_tex_coords->observe(std::move(handler));
}

std::shared_ptr<texture_element> texture_element::make_shared(draw_pair_t &&pair) {
    return std::shared_ptr<texture_element>(new texture_element{std::move(pair)});
}
