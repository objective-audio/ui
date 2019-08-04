//
//  yas_ui_collection_layout.h
//

#pragma once

#include <chaining/yas_chaining_umbrella.h>
#include <cpp_utils/yas_result.h>
#include <vector>
#include "yas_ui_layout_guide.h"
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

    chaining::value::holder<std::size_t> preferred_cell_count;
    chaining::value::holder<std::size_t> const &actual_cell_count() const;
    chaining::value::holder<ui::size> default_cell_size;
    chaining::value::holder<std::vector<ui::collection_layout::line>> lines;
    chaining::value::holder<float> row_spacing;
    chaining::value::holder<float> col_spacing;
    chaining::value::holder<ui::layout_alignment> alignment;
    chaining::value::holder<ui::layout_direction> direction;
    chaining::value::holder<ui::layout_order> row_order;
    chaining::value::holder<ui::layout_order> col_order;
    ui::layout_borders const borders;
    ui::layout_guide_rect frame_guide_rect;
    std::vector<ui::layout_guide_rect> cell_guide_rects;

   private:
    struct cell_location {
        std::size_t line_idx;
        std::size_t cell_idx;
    };

    chaining::value::holder<std::size_t> _actual_cell_count{std::size_t(0)};

    ui::layout_guide_rect _border_guide_rect;
    chaining::any_observer_ptr _left_border_observer;
    chaining::any_observer_ptr _right_border_observer;
    chaining::any_observer_ptr _bottom_border_observer;
    chaining::any_observer_ptr _top_border_observer;
    std::optional<chaining::perform_receiver<>> _layout_receiver = std::nullopt;

    chaining::observer_pool _pool;

    collection_layout(args);

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

   public:
    static std::shared_ptr<collection_layout> make_shared();
    static std::shared_ptr<collection_layout> make_shared(args);
};
}  // namespace yas::ui
