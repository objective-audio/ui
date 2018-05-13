//
//  yas_ui_collection_layout.h
//

#pragma once

#include <vector>
#include "yas_base.h"
#include "yas_result.h"
#include "yas_ui_layout_types.h"
#include "yas_ui_types.h"
#include "yas_flow.h"

namespace yas {
template <typename K, typename T>
class subject;
template <typename K, typename T>
class observer;
}

namespace yas::ui {
class layout_guide_rect;

class collection_layout : public base {
   public:
    class impl;

    enum class method {
        frame_changed,
        preferred_cell_count_changed,
        actual_cell_count_changed,
        default_cell_size_changed,
        lines_changed,
        row_spacing_changed,
        col_spacing_changed,
        alignment_changed,
        direction_changed,
        row_order_changed,
        col_order_changed
    };

    using subject_t = subject<method, collection_layout>;
    using observer_t = observer<method, collection_layout>;

    struct line {
        std::vector<ui::size> cell_sizes;
        float new_line_min_offset = 0.0f;

        bool operator==(line const &rhs) const;
        bool operator!=(line const &rhs) const;
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
    void set_preferred_cell_count(std::size_t const);
    void set_default_cell_size(ui::size);
    void set_lines(std::vector<ui::collection_layout::line>);
    void set_row_spacing(float const);
    void set_col_spacing(float const);
    void set_alignment(ui::layout_alignment const);
    void set_direction(ui::layout_direction const);
    void set_row_order(ui::layout_order const);
    void set_col_order(ui::layout_order const);

    ui::region frame() const;
    std::size_t const &preferred_cell_count() const;
    std::size_t actual_cell_count() const;
    ui::size const &default_cell_size() const;
    std::vector<line> const &lines() const;
    float const &row_spacing() const;
    float const &col_spacing() const;
    ui::layout_alignment const &alignment() const;
    ui::layout_direction const &direction() const;
    ui::layout_order const &row_order() const;
    ui::layout_order const &col_order() const;

    ui::layout_borders const &borders() const;

    ui::layout_guide_rect &frame_layout_guide_rect();
    std::vector<ui::layout_guide_rect> &cell_layout_guide_rects();

    subject_t &subject();

    [[nodiscard]] flow::node<std::size_t, std::size_t, std::size_t> begin_actual_cell_count_flow() const;
    [[nodiscard]] flow::node<ui::size, ui::size, ui::size> begin_default_cell_size_flow() const;
    [[nodiscard]] flow::node<std::vector<line>, std::vector<line>, std::vector<line>> begin_lines_flow() const;
    [[nodiscard]] flow::node<float, float, float> begin_row_spacing_flow() const;
    [[nodiscard]] flow::node<float, float, float> begin_col_spacing_flow() const;
    [[nodiscard]] flow::node<ui::layout_alignment, ui::layout_alignment, ui::layout_alignment> begin_alignment_flow()
        const;
    [[nodiscard]] flow::node<ui::layout_direction, ui::layout_direction, ui::layout_direction> begin_direction_flow()
        const;
    [[nodiscard]] flow::node<ui::layout_order, ui::layout_order, ui::layout_order> begin_row_order_flow() const;
    [[nodiscard]] flow::node<ui::layout_order, ui::layout_order, ui::layout_order> begin_col_order_flow() const;
};
}
