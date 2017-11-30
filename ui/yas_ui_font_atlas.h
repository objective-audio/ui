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
template <typename K, typename T>
class subject;
template <typename K, typename T>
class observer;

namespace ui {
    class font_atlas : public base {
       public:
        class impl;

        enum class method { texture_changed };

        using subject_t = subject<method, font_atlas>;
        using observer_t = observer<method, font_atlas>;

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
        ui::size advance(std::string const &word) const;

        void set_texture(ui::texture);

        subject_t &subject();
    };
}

std::string to_string(ui::font_atlas::method const &);
}
