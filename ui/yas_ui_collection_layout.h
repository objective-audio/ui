//
//  yas_ui_collection_layout.h
//

#pragma once

#include <vector>
#include "yas_base.h"
#include "yas_result.h"
#include "yas_ui_layout_types.h"
#include "yas_ui_types.h"

namespace yas {
template <typename T, typename K>
class subject;
template <typename T, typename K>
class observer;

namespace ui {
    class layout_guide_rect;

    class collection_layout : public base {
       public:
        class impl;

        enum class method {
            actual_cell_count_changed,
        };

        using subject_t = subject<collection_layout, method>;
        using observer_t = observer<collection_layout, method>;

        struct line {
            std::vector<ui::size> cell_sizes;
            float new_line_min_offset = 0.0f;
        };

        struct args {
            ui::region frame = {.origin = {.v = 0.0f}, .size = {.v = 0.0f}};
            std::size_t preferred_cell_count = 0;
            ui::size default_cell_size = {1.0f, 1.0f};
            std::vector<line> lines;
            float row_spacing = 0.0f;
            float col_spacing = 0.0f;
            ui::layout_borders borders;
            ui::layout_alignment alignment = ui::layout_alignment::min;
            ui::layout_direction direction = ui::layout_direction::vertical;
            ui::layout_order row_order = ui::layout_order::ascending;
            ui::layout_order col_order = ui::layout_order::ascending;
        };

        collection_layout();
        collection_layout(args);
        collection_layout(std::nullptr_t);

        void set_frame(ui::region);
        ui::region frame() const;

        void set_preferred_cell_count(std::size_t const);
        std::size_t preferred_cell_count() const;
        std::size_t actual_cell_count() const;

        void set_default_cell_size(ui::size);
        ui::size const &default_cell_size() const;

        void set_lines(std::vector<ui::collection_layout::line>);
        std::vector<line> const &lines() const;

        void set_row_spacing(float const);
        float row_spacing() const;

        void set_col_spacing(float const);
        float col_spacing() const;

        void set_alignment(ui::layout_alignment);
        ui::layout_alignment alignment() const;

        void set_direction(ui::layout_direction);
        ui::layout_direction direction() const;

        void set_row_order(ui::layout_order);
        ui::layout_order row_order() const;

        void set_col_order(ui::layout_order);
        ui::layout_order col_order() const;

        ui::layout_borders const &borders() const;

        ui::layout_guide_rect &frame_layout_guide_rect();
        std::vector<ui::layout_guide_rect> &cell_layout_guide_rects();

        subject_t &subject();
    };
}
}
