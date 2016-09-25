//
//  yas_ui_strings.h
//

#pragma once

#include "yas_ui_font_atlas.h"
#include "yas_ui_layout_types.h"

namespace yas {
template <typename T, typename K>
class subject;
template <typename T, typename K>
class observer;

namespace ui {
    class font_atlas;
    class rect_plane;
    class layout_guide_rect;
    enum class layout_alignment;

    class strings : public base {
       public:
        class impl;

        enum class method { text_changed, font_atlas_changed, line_height_changed, alignment_changed };

        using subject_t = subject<strings, method>;
        using observer_t = observer<strings, method>;

        struct args {
            std::size_t max_word_count = 16;
            std::string text;
            ui::font_atlas font_atlas = nullptr;
            float line_height = 0.0f;
            ui::layout_alignment alignment = ui::layout_alignment::min;
            ui::region frame = {.origin = {.v = 0.0f}, .size = {.v = 0.0f}};
        };

        strings();
        explicit strings(args);
        strings(std::nullptr_t);

        virtual ~strings() final;

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

        subject_t &subject();
    };
}
}
