//
//  yas_ui_collection_layout.h
//

#pragma once

#include <cpp_utils/yas_result.h>
#include <ui/yas_ui_collection_layout_types.h>
#include <ui/yas_ui_layout_guide.h>

#include <observing/yas_observing_umbrella.hpp>
#include <vector>

namespace yas::ui {
struct collection_layout final {
    using line = collection_layout_line;
    using args = collection_layout_args;

    [[nodiscard]] std::shared_ptr<layout_region_guide> const &preferred_layout_guide() const;
    ui::layout_borders const borders;

    void set_preferred_cell_count(std::size_t const &);
    void set_preferred_cell_count(std::size_t &&);
    [[nodiscard]] std::size_t preferred_cell_count() const;
    [[nodiscard]] observing::syncable observe_preferred_cell_count(std::function<void(std::size_t const &)> &&);

    [[nodiscard]] std::size_t actual_cell_count() const;

    void set_default_cell_size(ui::size const &);
    void set_default_cell_size(ui::size &&);
    [[nodiscard]] ui::size default_cell_size() const;
    [[nodiscard]] observing::syncable observe_default_cell_size(std::function<void(ui::size const &)> &&);

    void set_lines(std::vector<ui::collection_layout::line> const &);
    void set_lines(std::vector<ui::collection_layout::line> &&);
    [[nodiscard]] std::vector<ui::collection_layout::line> const &lines() const;
    [[nodiscard]] observing::syncable observe_lines(
        std::function<void(std::vector<ui::collection_layout::line> const &)> &&);

    void set_row_spacing(float const &);
    void set_row_spacing(float &&);
    [[nodiscard]] float const &row_spacing() const;
    [[nodiscard]] observing::syncable observe_row_spacing(std::function<void(float const &)> &&);

    void set_col_spacing(float const &);
    void set_col_spacing(float &&);
    [[nodiscard]] float const &col_spacing() const;
    [[nodiscard]] observing::syncable observe_col_spacing(std::function<void(float const &)> &&);

    void set_alignment(ui::layout_alignment const &);
    void set_alignment(ui::layout_alignment &&);
    [[nodiscard]] ui::layout_alignment const &alignment() const;
    [[nodiscard]] observing::syncable observe_alignment(std::function<void(ui::layout_alignment const &)> &&);

    void set_direction(ui::layout_direction const &);
    void set_direction(ui::layout_direction &&);
    [[nodiscard]] ui::layout_direction const &direction() const;
    [[nodiscard]] observing::syncable observe_direction(std::function<void(ui::layout_direction const &)> &&);

    void set_row_order(ui::layout_order const &);
    void set_row_order(ui::layout_order &&);
    [[nodiscard]] ui::layout_order const &row_order() const;
    [[nodiscard]] observing::syncable observe_row_order(std::function<void(ui::layout_order const &)> &&);

    void set_col_order(ui::layout_order const &);
    void set_col_order(ui::layout_order &&);
    [[nodiscard]] ui::layout_order const &col_order() const;
    [[nodiscard]] observing::syncable observe_col_order(std::function<void(ui::layout_order const &)> &&);

    [[nodiscard]] std::vector<region> const &actual_cell_regions() const;
    [[nodiscard]] observing::syncable observe_actual_cell_regions(std::function<void(std::vector<region> const &)> &&);
    [[nodiscard]] ui::region actual_frame() const;
    [[nodiscard]] std::shared_ptr<layout_region_source> actual_frame_layout_source() const;

    [[nodiscard]] static std::shared_ptr<collection_layout> make_shared();
    [[nodiscard]] static std::shared_ptr<collection_layout> make_shared(args);

   private:
    struct cell_location {
        std::size_t line_idx;
        std::size_t cell_idx;
    };

    std::shared_ptr<layout_region_guide> const _preferred_layout_guide;

    observing::value::holder_ptr<std::size_t> const _preferred_cell_count;
    observing::value::holder_ptr<ui::size> const _default_cell_size;
    observing::value::holder_ptr<std::vector<ui::collection_layout::line>> const _lines;
    observing::value::holder_ptr<float> const _row_spacing;
    observing::value::holder_ptr<float> const _col_spacing;
    observing::value::holder_ptr<ui::layout_alignment> const _alignment;
    observing::value::holder_ptr<ui::layout_direction> const _direction;
    observing::value::holder_ptr<ui::layout_order> const _row_order;
    observing::value::holder_ptr<ui::layout_order> const _col_order;

    observing::value::holder_ptr<std::vector<region>> const _actual_cell_regions;
    std::shared_ptr<layout_region_guide> const _actual_frame_layout_guide;

    std::shared_ptr<layout_region_guide> const _border_layout_guide;
    observing::canceller_pool _pool;

    collection_layout(args);

    collection_layout(collection_layout const &) = delete;
    collection_layout(collection_layout &&) = delete;
    collection_layout &operator=(collection_layout const &) = delete;
    collection_layout &operator=(collection_layout &&) = delete;

    void _update_layout();
    std::optional<cell_location> _cell_location(std::size_t const cell_idx);
    ui::size _cell_size(std::size_t const idx);
    bool _is_head_of_new_line(std::size_t const idx);
    ui::size _transformed_cell_size(std::size_t const idx);
    float _transformed_col_diff(std::size_t const idx);
    float _transformed_row_cell_diff(std::size_t const idx);
    float _transformed_row_new_line_diff(std::size_t const idx);
    ui::region _transformed_border_region();
    ui::region _direction_swapped_region_if_horizontal(ui::region const &region);
};
}  // namespace yas::ui
