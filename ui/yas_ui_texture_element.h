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

    texture_element(image_pair_t &&);
    texture_element(std::nullptr_t);

    image_pair_t const &image_pair() const;

    void set_tex_coords(ui::uint_region const &);
    ui::uint_region const &tex_coords() const;

    subject_t &subject();
};
}
