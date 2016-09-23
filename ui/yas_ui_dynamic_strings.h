//
//  yas_ui_dynamic_strings.h
//

#pragma once

#include "yas_ui_dynamic_strings_layout.h"

namespace yas {
namespace ui {
    class font_atlas;
    class rect_plane;
    enum class layout_alignment;

    class dynamic_strings : public base {
        class impl;

       public:
        dynamic_strings();
        explicit dynamic_strings(ui::dynamic_strings_layout::args);
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
