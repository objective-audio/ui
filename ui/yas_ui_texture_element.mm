//
//  yas_ui_texture_element.mm
//

#include "yas_ui_texture_element.h"

using namespace yas;

#pragma mark - ui::teture::texture_element::impl

struct ui::texture_element::impl : base::impl {
    draw_pair_t const _draw_pair;
    flow::property<ui::uint_region> _tex_coords{ui::uint_region::zero()};

    impl(draw_pair_t &&pair) : _draw_pair(std::move(pair)) {
    }
};

#pragma mark - ui::texture_element

ui::texture_element::texture_element(draw_pair_t &&pair) : base(std::make_shared<impl>(std::move(pair))) {
}

ui::texture_element::texture_element(std::nullptr_t) : base(nullptr) {
}

ui::draw_pair_t const &ui::texture_element::draw_pair() const {
    return impl_ptr<impl>()->_draw_pair;
}

void ui::texture_element::set_tex_coords(ui::uint_region const &tex_coords) {
    impl_ptr<impl>()->_tex_coords.set_value(tex_coords);
}

ui::uint_region const &ui::texture_element::tex_coords() const {
    return impl_ptr<impl>()->_tex_coords.value();
}

flow::node_t<ui::uint_region, true> ui::texture_element::begin_tex_coords_flow() const {
    return impl_ptr<impl>()->_tex_coords.begin();
}
