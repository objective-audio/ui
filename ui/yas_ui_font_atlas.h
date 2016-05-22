//
//  yas_ui_font.h
//

#pragma once

#include <string>
#include <vector>
#include "yas_base.h"
#include "yas_ui_texture.h"
#include "yas_ui_types.h"

namespace yas {
template <typename T, typename K>
class subject;
template <typename T, typename K>
class observer;

namespace ui {
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

    enum class font_atlas_method { texture_changed };

    class font_atlas : public base {
       public:
        class impl;

        using subject_t = subject<font_atlas, font_atlas_method>;
        using observer_t = observer<font_atlas, font_atlas_method>;

        struct args {
            std::string font_name;
            double font_size;
            std::string words;
            ui::texture texture = nullptr;
        };

        font_atlas(args);
        font_atlas(std::nullptr_t);

        std::string const &font_name() const;
        double const &font_size() const;
        std::string const &words() const;
        ui::texture const &texture() const;

        void set_texture(ui::texture);

        subject_t &subject();

        strings_layout make_strings_layout(std::string const &text, pivot const pivot) const;
    };
}

std::string to_string(ui::font_atlas_method const &);
}
