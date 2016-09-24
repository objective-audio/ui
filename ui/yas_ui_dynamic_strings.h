//
//  yas_ui_dynamic_strings.h
//

#pragma once

#include "yas_ui_font_atlas.h"
#include "yas_ui_layout_types.h"

namespace yas {
namespace ui {
    class font_atlas;
    class rect_plane;
    class layout_guide_rect;
    enum class layout_alignment;

    class dynamic_strings : public base {
       public:
        class impl;

        struct args {
            std::size_t max_word_count = 16;
            std::string text;
            ui::font_atlas font_atlas = nullptr;
            float line_height = 0.0f;
            ui::layout_alignment alignment = ui::layout_alignment::min;
            ui::region frame = {.origin = {.v = 0.0f}, .size = {.v = 0.0f}};
        };

        dynamic_strings();
        explicit dynamic_strings(args);
        dynamic_strings(std::nullptr_t);

        virtual ~dynamic_strings() final;

        void set_text(std::string);
        void set_font_atlas(ui::font_atlas);
        void set_line_height(float const);
        void set_alignment(ui::layout_alignment const);

        std::string const &text() const;
        ui::font_atlas const &font_atlas() const;
        float line_height() const;
        ui::layout_alignment alignment() const;

        ui::layout_guide_rect &frame_layout_guide_rect();

        ui::rect_plane &rect_plane();
    };
}
}
