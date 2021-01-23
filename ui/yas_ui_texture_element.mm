//
//  yas_ui_texture_element.mm
//

#include "yas_ui_texture_element.h"

using namespace yas;

ui::texture_element::texture_element(draw_pair_t &&pair) : _draw_pair(std::move(pair)) {
}

ui::draw_pair_t const &ui::texture_element::draw_pair() const {
    return this->_draw_pair;
}

void ui::texture_element::set_tex_coords(ui::uint_region const &tex_coords) {
    this->_tex_coords->set_value(tex_coords);
}

ui::uint_region const &ui::texture_element::tex_coords() const {
    return this->_tex_coords->value();
}

chaining::chain_sync_t<ui::uint_region> ui::texture_element::chain_tex_coords() const {
    return this->_tex_coords->chain();
}

ui::texture_element_ptr ui::texture_element::make_shared(draw_pair_t &&pair) {
    return std::shared_ptr<texture_element>(new texture_element{std::move(pair)});
}
