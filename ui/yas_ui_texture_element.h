//
//  yas_ui_texture_element.h
//

#pragma once

#include "yas_base.h"
#include "yas_chaining.h"
#include "yas_ui_texture_protocol.h"
#include "yas_ui_types.h"

namespace yas::ui {
class image;

class texture_element : public base {
   public:
    class impl;

    texture_element(draw_pair_t &&);
    texture_element(std::nullptr_t);

    ui::draw_pair_t const &draw_pair() const;

    void set_tex_coords(ui::uint_region const &);
    ui::uint_region const &tex_coords() const;

    [[nodiscard]] chaining::chain_sync_t<uint_region> chain_tex_coords() const;
};
}  // namespace yas::ui
