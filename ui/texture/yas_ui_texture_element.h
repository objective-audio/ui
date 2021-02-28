//
//  yas_ui_texture_element.h
//

#pragma once

#include <observing/yas_observing_umbrella.h>
#include <ui/yas_ui_ptr.h>
#include <ui/yas_ui_types.h>

namespace yas::ui {
class image;

struct texture_element {
    [[nodiscard]] ui::draw_pair_t const &draw_pair() const;

    void set_tex_coords(ui::uint_region const &);
    [[nodiscard]] ui::uint_region const &tex_coords() const;

    [[nodiscard]] observing::canceller_ptr observe_tex_coords(observing::caller<uint_region>::handler_f &&,
                                                              bool const sync);

    [[nodiscard]] static texture_element_ptr make_shared(draw_pair_t &&);

   private:
    draw_pair_t const _draw_pair;
    observing::value::holder_ptr<ui::uint_region> const _tex_coords =
        observing::value::holder<ui::uint_region>::make_shared(ui::uint_region::zero());

    texture_element(draw_pair_t &&);

    texture_element(texture_element const &) = delete;
    texture_element(texture_element &&) = delete;
    texture_element &operator=(texture_element const &) = delete;
    texture_element &operator=(texture_element &&) = delete;
};
}  // namespace yas::ui
