//
//  yas_ui_strings_data.h
//

#pragma once

#include <Metal/Metal.h>
#include <string>
#include <vector>
#include "yas_base.h"
#include "yas_ui_types.h"

namespace yas {
namespace ui {
    class texture;

    struct strings_info {
        vertex2d_square_t const &square(std::size_t const word_index) const;

        std::vector<vertex2d_square_t> const &squares() const;

        std::size_t word_count() const;

        Float64 width() const;

       protected:
        strings_info(std::size_t const word_count);

        std::vector<vertex2d_square_t> _squares;
        Float64 _width;
    };

    class strings_data : base {
        using super_class = base;

       public:
        strings_data(std::string font_name, Float64 const font_size, std::string words, texture texture);

        std::string const &font_name() const;
        Float64 const &font_size() const;
        std::string const &words() const;
        ui::texture const &texture() const;

        strings_info make_strings_info(std::string const &text, pivot const pivot) const;

        class impl;
    };
}
}