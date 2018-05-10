//
//  yas_ui_texture_element.h
//

#pragma once

#include "yas_base.h"
#include "yas_ui_types.h"
#include "yas_observing.h"
#include "yas_ui_texture_protocol.h"

namespace yas::ui {
class image;

class texture_element : public base {
   public:
    class impl;

    enum class method { tex_coords_changed };

    using subject_t = subject<method, texture_element>;
    using observer_t = subject_t::observer_t;

    texture_element(draw_pair_t &&);
    texture_element(std::nullptr_t);

    ui::draw_pair_t const &draw_pair() const;

    void set_tex_coords(ui::uint_region const &);
    ui::uint_region const &tex_coords() const;

    [[nodiscard]] flow::node<uint_region, uint_region, uint_region> begin_tex_coords_flow() const;
};
}
