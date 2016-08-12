//
//  yas_ui_strings.h
//

#pragma once

namespace yas {
namespace ui {
    class font_atlas;
    class rect_plane;

    class strings_extension : public base {
       public:
        class impl;

        struct args {
            ui::font_atlas font_atlas = nullptr;
            std::size_t max_word_count = 16;
        };

        strings_extension(args);
        strings_extension(std::nullptr_t);

        ui::font_atlas const &font_atlas() const;
        std::string const &text() const;
        ui::pivot pivot() const;
        float width() const;

        void set_font_atlas(ui::font_atlas);
        void set_text(std::string);
        void set_pivot(ui::pivot const);

        ui::rect_plane &rect_plane();
    };
}
}
