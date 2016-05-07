//
//  yas_ui_font.h
//

#pragma once

#include <string>
#include <vector>
#include "yas_base.h"
#include "yas_ui_types.h"

namespace yas {
namespace ui {
    class texture;

    struct strings_layout {
        vertex2d_square_t const &square(std::size_t const word_index) const;
        std::vector<vertex2d_square_t> const &squares() const;
        std::size_t word_count() const;
        double width() const;

       protected:
        strings_layout(std::size_t const word_count);

        std::vector<vertex2d_square_t> _squares;
        double _width;
    };

    class font_atlas : base {
       public:
        class impl;

        font_atlas(std::string font_name, double const font_size, std::string words, texture texture);

        std::string const &font_name() const;
        double const &font_size() const;
        std::string const &words() const;
        ui::texture const &texture() const;

        strings_layout make_strings_layout(std::string const &text, pivot const pivot) const;
    };
}
}