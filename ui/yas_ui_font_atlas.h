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
        vertex2d_rect_t const &rect(std::size_t const word_index) const;
        std::vector<vertex2d_rect_t> const &rects() const;
        std::size_t word_count() const;
        double width() const;

       protected:
        strings_layout(std::size_t const word_count);

        std::vector<vertex2d_rect_t> _rects;
        double _width;
    };

    class font_atlas : public base {
       public:
        class impl;

        enum class method { texture_changed };

        using subject_t = subject<font_atlas, method>;
        using observer_t = observer<font_atlas, method>;

        struct args {
            std::string font_name;
            double font_size;
            std::string words;
            ui::texture texture = nullptr;
        };

        font_atlas(args);
        font_atlas(std::nullptr_t);

        virtual ~font_atlas() final;

        std::string const &font_name() const;
        double const &font_size() const;
        double const &ascent() const;
        double const &descent() const;
        double const &leading() const;
        std::string const &words() const;
        ui::texture const &texture() const;

        ui::vertex2d_rect_t const &rect(std::string const &word) const;
        ui::size const &advance(std::string const &word) const;

        void set_texture(ui::texture);

        subject_t &subject();

        strings_layout make_strings_layout(std::string const &text, pivot const pivot) const;
    };
}

std::string to_string(ui::font_atlas::method const &);
}
