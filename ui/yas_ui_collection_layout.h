//
//  yas_ui_collection_layout.h
//

#pragma once

#include <vector>
#include "yas_base.h"
#include "yas_ui_types.h"

namespace yas {
template <typename T, typename K>
class subject;
template <typename T, typename K>
class observer;

namespace ui {
    class layout_guide_rect;

    enum class layout_direction {
        vertical,
        horizontal,
    };

    enum class layout_order {
        ascending,
        descending,
    };

    enum class layout_alignment {
        min,
        mid,
        max,
    };

    struct layout_borders {
        float left = 0.0f;
        float right = 0.0f;
        float bottom = 0.0f;
        float top = 0.0f;
    };

    class collection_layout : public base {
       public:
        class impl;

        enum class method {
            actual_cell_count_changed,
        };

        using subject_t = subject<collection_layout, method>;
        using observer_t = observer<collection_layout, method>;

        struct args {
            ui::region frame;
            std::size_t preferred_cell_count = 0;
            std::vector<ui::float_size> cell_sizes = {{1.0f, 1.0f}};
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

        void set_cell_sizes(std::vector<ui::float_size>);
        std::vector<ui::float_size> const &cell_sizes() const;

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

std::string to_string(ui::layout_direction const &);
std::string to_string(ui::layout_order const &);
std::string to_string(ui::layout_alignment const &);
std::string to_string(ui::layout_borders const &);
}

std::ostream &operator<<(std::ostream &os, yas::ui::layout_direction const &);
std::ostream &operator<<(std::ostream &os, yas::ui::layout_order const &);
std::ostream &operator<<(std::ostream &os, yas::ui::layout_alignment const &);
std::ostream &operator<<(std::ostream &os, yas::ui::layout_borders const &);

bool operator==(yas::ui::layout_borders const &lhs, yas::ui::layout_borders const &rhs);
bool operator!=(yas::ui::layout_borders const &lhs, yas::ui::layout_borders const &rhs);
