//
//  yas_ui_collection_layout.h
//

#pragma once

#include <chaining/yas_chaining_umbrella.h>
#include <cpp_utils/yas_result.h>
#include <vector>
#include "yas_ui_layout_guide.h"
#include "yas_ui_layout_types.h"
#include "yas_ui_ptr.h"
#include "yas_ui_types.h"

namespace yas::ui {
struct collection_layout {
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

    chaining::value::holder_ptr<std::size_t> preferred_cell_count;
    chaining::value::holder_ptr<std::size_t> const &actual_cell_count() const;
    chaining::value::holder_ptr<ui::size> default_cell_size;
    chaining::value::holder_ptr<std::vector<ui::collection_layout::line>> lines;
    chaining::value::holder_ptr<float> row_spacing;
    chaining::value::holder_ptr<float> col_spacing;
    chaining::value::holder_ptr<ui::layout_alignment> alignment;
    chaining::value::holder_ptr<ui::layout_direction> direction;
    chaining::value::holder_ptr<ui::layout_order> row_order;
    chaining::value::holder_ptr<ui::layout_order> col_order;
    ui::layout_borders const borders;
    ui::layout_guide_rect_ptr frame_guide_rect;
    std::vector<ui::layout_guide_rect_ptr> cell_guide_rects;

    [[nodiscard]] static collection_layout_ptr make_shared();
    [[nodiscard]] static collection_layout_ptr make_shared(args);

   private:
    struct cell_location {
        std::size_t line_idx;
        std::size_t cell_idx;
    };

    chaining::value::holder_ptr<std::size_t> _actual_cell_count =
        chaining::value::holder<std::size_t>::make_shared(std::size_t(0));

    ui::layout_guide_rect_ptr _border_guide_rect = ui::layout_guide_rect::make_shared();
    chaining::any_observer_ptr _left_border_observer;
    chaining::any_observer_ptr _right_border_observer;
    chaining::any_observer_ptr _bottom_border_observer;
    chaining::any_observer_ptr _top_border_observer;
    chaining::perform_receiver_ptr<> _layout_receiver = nullptr;

    chaining::observer_pool _pool;

    collection_layout(args);

    collection_layout(collection_layout const &) = delete;
    collection_layout(collection_layout &&) = delete;
    collection_layout &operator=(collection_layout const &) = delete;
    collection_layout &operator=(collection_layout &&) = delete;

    void _prepare(std::shared_ptr<collection_layout> const &);
    void _push_notify_waiting();
    void _pop_notify_waiting();
    void _update_layout();
    std::optional<cell_location> _cell_location(std::size_t const cell_idx);
    ui::size _cell_size(std::size_t const idx);
    bool _is_top_of_new_line(std::size_t const idx);
    ui::size _transformed_cell_size(std::size_t const idx);
    float _transformed_col_diff(std::size_t const idx);
    float _transformed_row_cell_diff(std::size_t const idx);
    float _transformed_row_new_line_diff(std::size_t const idx);
    ui::region _transformed_border_rect();
    ui::region _direction_swapped_region_if_horizontal(ui::region const &region);
};
}  // namespace yas::ui
