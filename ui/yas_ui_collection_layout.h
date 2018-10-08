//
//  yas_ui_collection_layout.h
//

#pragma once

#include <vector>
#include "yas_base.h"
#include "yas_chaining.h"
#include "yas_result.h"
#include "yas_ui_layout_types.h"
#include "yas_ui_types.h"

namespace yas {
template <typename K, typename T>
class subject;
template <typename K, typename T>
class observer;
}  // namespace yas

namespace yas::ui {
class layout_guide_rect;

class collection_layout : public base {
   public:
    class impl;

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

    [[nodiscard]] chaining::chain_syncable_t<std::size_t> chain_preferred_cell_count() const;
    [[nodiscard]] chaining::chain_syncable_t<std::size_t> chain_actual_cell_count() const;
    [[nodiscard]] chaining::chain_syncable_t<ui::size> chain_default_cell_size() const;
    [[nodiscard]] chaining::chain_syncable_t<std::vector<line>> chain_lines() const;
    [[nodiscard]] chaining::chain_syncable_t<float> chain_row_spacing() const;
    [[nodiscard]] chaining::chain_syncable_t<float> chain_col_spacing() const;
    [[nodiscard]] chaining::chain_syncable_t<ui::layout_alignment> chain_alignment() const;
    [[nodiscard]] chaining::chain_syncable_t<ui::layout_direction> chain_direction() const;
    [[nodiscard]] chaining::chain_syncable_t<ui::layout_order> chain_row_order() const;
    [[nodiscard]] chaining::chain_syncable_t<ui::layout_order> chain_col_order() const;
};
}  // namespace yas::ui
