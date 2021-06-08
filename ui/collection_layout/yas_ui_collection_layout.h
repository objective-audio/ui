//
//  yas_ui_collection_layout.h
//

#pragma once

#include <cpp_utils/yas_result.h>
#include <observing/yas_observing_umbrella.h>
#include <ui/yas_ui_collection_layout_types.h>
#include <ui/yas_ui_layout_guide.h>

#include <vector>

namespace yas::ui {
struct collection_layout {
    using line = collection_layout_line;
    using args = collection_layout_args;

    std::shared_ptr<layout_region_guide> const frame_layout_guide;
    ui::layout_borders const borders;

    void set_preferred_cell_count(std::size_t const &);
    void set_preferred_cell_count(std::size_t &&);
    [[nodiscard]] std::size_t preferred_cell_count() const;
    [[nodiscard]] observing::syncable observe_preferred_cell_count(observing::caller<std::size_t>::handler_f &&);

    [[nodiscard]] std::size_t actual_cell_count() const;
    [[nodiscard]] observing::syncable observe_actual_cell_count(observing::caller<std::size_t>::handler_f &&);

    void set_default_cell_size(ui::size const &);
    void set_default_cell_size(ui::size &&);
    [[nodiscard]] ui::size default_cell_size() const;
    [[nodiscard]] observing::syncable observe_default_cell_size(observing::caller<ui::size>::handler_f &&);

    void set_lines(std::vector<ui::collection_layout::line> const &);
    void set_lines(std::vector<ui::collection_layout::line> &&);
    [[nodiscard]] std::vector<ui::collection_layout::line> const &lines() const;
    [[nodiscard]] observing::syncable observe_lines(
        observing::caller<std::vector<ui::collection_layout::line>>::handler_f &&);

    void set_row_spacing(float const &);
    void set_row_spacing(float &&);
    [[nodiscard]] float const &row_spacing() const;
    [[nodiscard]] observing::syncable observe_row_spacing(observing::caller<float>::handler_f &&);

    void set_col_spacing(float const &);
    void set_col_spacing(float &&);
    [[nodiscard]] float const &col_spacing() const;
    [[nodiscard]] observing::syncable observe_col_spacing(observing::caller<float>::handler_f &&);

    void set_alignment(ui::layout_alignment const &);
    void set_alignment(ui::layout_alignment &&);
    [[nodiscard]] ui::layout_alignment const &alignment() const;
    [[nodiscard]] observing::syncable observe_alignment(observing::caller<ui::layout_alignment>::handler_f &&);

    void set_direction(ui::layout_direction const &);
    void set_direction(ui::layout_direction &&);
    [[nodiscard]] ui::layout_direction const &direction() const;
    [[nodiscard]] observing::syncable observe_direction(observing::caller<ui::layout_direction>::handler_f &&);

    void set_row_order(ui::layout_order const &);
    void set_row_order(ui::layout_order &&);
    [[nodiscard]] ui::layout_order const &row_order() const;
    [[nodiscard]] observing::syncable observe_row_order(observing::caller<ui::layout_order>::handler_f &&);

    void set_col_order(ui::layout_order const &);
    void set_col_order(ui::layout_order &&);
    [[nodiscard]] ui::layout_order const &col_order() const;
    [[nodiscard]] observing::syncable observe_col_order(observing::caller<ui::layout_order>::handler_f &&);

    [[nodiscard]] std::vector<std::shared_ptr<layout_region_guide>> const &cell_layout_guides() const;
    [[nodiscard]] ui::region actual_cells_frame() const;
    [[nodiscard]] std::shared_ptr<layout_region_source> actual_cells_frame_layout_source() const;

    [[nodiscard]] static std::shared_ptr<collection_layout> make_shared();
    [[nodiscard]] static std::shared_ptr<collection_layout> make_shared(args);

   private:
    struct cell_location {
        std::size_t line_idx;
        std::size_t cell_idx;
    };

    observing::value::holder_ptr<std::size_t> const _preferred_cell_count;
    observing::value::holder_ptr<std::size_t> const _actual_cell_count;
    observing::value::holder_ptr<ui::size> const _default_cell_size;
    observing::value::holder_ptr<std::vector<ui::collection_layout::line>> const _lines;
    observing::value::holder_ptr<float> const _row_spacing;
    observing::value::holder_ptr<float> const _col_spacing;
    observing::value::holder_ptr<ui::layout_alignment> const _alignment;
    observing::value::holder_ptr<ui::layout_direction> const _direction;
    observing::value::holder_ptr<ui::layout_order> const _row_order;
    observing::value::holder_ptr<ui::layout_order> const _col_order;

    std::vector<std::shared_ptr<layout_region_guide>> _cell_layout_guides;
    std::shared_ptr<layout_region_guide> const _actual_cells_frame_layout_guide;

    std::shared_ptr<layout_region_guide> const _border_layout_guide;
    observing::canceller_pool _pool;

    collection_layout(args);

    collection_layout(collection_layout const &) = delete;
    collection_layout(collection_layout &&) = delete;
    collection_layout &operator=(collection_layout const &) = delete;
    collection_layout &operator=(collection_layout &&) = delete;

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
    ui::region _transformed_border_region();
    ui::region _direction_swapped_region_if_horizontal(ui::region const &region);
};
}  // namespace yas::ui
