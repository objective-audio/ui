//
//  yas_ui_collection_layout.cpp
//

#include "yas_ui_collection_layout.h"
#include "yas_chaining_utils.h"
#include "yas_delaying_caller.h"
#include "yas_fast_each.h"
#include "yas_ui_layout_guide.h"

using namespace yas;

#pragma mark - ui::collection_layout::line

bool ui::collection_layout::line::operator==(line const &rhs) const {
    if (this->new_line_min_offset != rhs.new_line_min_offset) {
        return false;
    }

    auto const cell_count = this->cell_sizes.size();

    if (cell_count != rhs.cell_sizes.size()) {
        return false;
    }

    auto each = make_fast_each(cell_count);
    while (yas_each_next(each)) {
        auto const &idx = yas_each_index(each);
        if (this->cell_sizes.at(idx) != rhs.cell_sizes.at(idx)) {
            return false;
        }
    }

    return true;
}

bool ui::collection_layout::line::operator!=(line const &rhs) const {
    return !(*this == rhs);
}

#pragma mark - ui::colleciton_layout::impl

struct ui::collection_layout::impl : base::impl {
    struct cell_location {
        std::size_t line_idx;
        std::size_t cell_idx;
    };

    chaining::holder<float> _row_spacing;
    chaining::holder<float> _col_spacing;
    chaining::holder<ui::layout_alignment> _alignment;
    chaining::holder<ui::layout_direction> _direction;
    chaining::holder<ui::layout_order> _row_order;
    chaining::holder<ui::layout_order> _col_order;
    chaining::holder<std::size_t> _preferred_cell_count;
    chaining::holder<std::size_t> _actual_cell_count{std::size_t(0)};
    chaining::holder<ui::size> _default_cell_size;
    chaining::holder<std::vector<ui::collection_layout::line>> _lines;

    ui::layout_guide_rect _frame_guide_rect;
    ui::layout_guide_rect _border_guide_rect;
    std::vector<ui::layout_guide_rect> _cell_guide_rects;
    chaining::any_observer _left_border_observer;
    chaining::any_observer _right_border_observer;
    chaining::any_observer _bottom_border_observer;
    chaining::any_observer _top_border_observer;
    ui::layout_borders const _borders;
    chaining::any_observer _border_observer = nullptr;
    chaining::receiver<> _layout_receiver = nullptr;

    impl(args &&args)
        : _frame_guide_rect(std::move(args.frame)),
          _preferred_cell_count(args.preferred_cell_count),
          _default_cell_size(std::move(args.default_cell_size)),
          _lines(std::move(args.lines)),
          _row_spacing(args.row_spacing),
          _col_spacing(args.col_spacing),
          _alignment(args.alignment),
          _direction(args.direction),
          _row_order(args.row_order),
          _col_order(args.col_order),
          _left_border_observer(_frame_guide_rect.left()
                                    .chain()
                                    .to(chaining::add(args.borders.left))
                                    .receive(_border_guide_rect.left().receiver())
                                    .sync()),
          _right_border_observer(_frame_guide_rect.right()
                                     .chain()
                                     .to(chaining::add(-args.borders.right))
                                     .receive(_border_guide_rect.right().receiver())
                                     .sync()),
          _bottom_border_observer(_frame_guide_rect.bottom()
                                      .chain()
                                      .to(chaining::add(args.borders.bottom))
                                      .receive(_border_guide_rect.bottom().receiver())
                                      .sync()),
          _top_border_observer(_frame_guide_rect.top()
                                   .chain()
                                   .to(chaining::add(-args.borders.top))
                                   .receive(_border_guide_rect.top().receiver())
                                   .sync()),

          _borders(std::move(args.borders)) {
        if (args.borders.left < 0 || args.borders.right < 0 || args.borders.bottom < 0 || args.borders.top < 0) {
            throw "borders value is negative.";
        }
    }

    void prepare(ui::collection_layout &layout) {
        auto weak_layout = to_weak(layout);

        this->_layout_receiver = chaining::receiver<>{[weak_layout]() {
            if (auto layout = weak_layout.lock()) {
                auto layout_impl = layout.impl_ptr<impl>();
                layout_impl->_update_layout();
            }
        }};

        this->_border_observer =
            this->_border_guide_rect.chain()
                .guard([weak_layout](ui::region const &) { return !!weak_layout; })
                .perform([weak_layout](ui::region const &) { weak_layout.lock().impl_ptr<impl>()->_update_layout(); })
                .end();

        this->_property_observers.emplace_back(this->_row_spacing.chain().receive_null(this->_layout_receiver).end());

        this->_property_observers.emplace_back(this->_col_spacing.chain().receive_null(this->_layout_receiver).end());

        this->_property_observers.emplace_back(this->_alignment.chain().receive_null(this->_layout_receiver).end());

        this->_property_observers.emplace_back(this->_direction.chain().receive_null(this->_layout_receiver).end());

        this->_property_observers.emplace_back(this->_row_order.chain().receive_null(this->_layout_receiver).end());

        this->_property_observers.emplace_back(this->_col_order.chain().receive_null(this->_layout_receiver).end());

        this->_property_observers.emplace_back(
            this->_preferred_cell_count.chain().receive_null(this->_layout_receiver).end());

        this->_property_observers.emplace_back(
            this->_default_cell_size.chain().receive_null(this->_layout_receiver).end());

        this->_property_observers.emplace_back(this->_lines.chain().receive_null(this->_layout_receiver).end());

        this->_update_layout();
    }

    void set_frame(ui::region &&frame) {
        if (this->_frame_guide_rect.region() != frame) {
            this->_frame_guide_rect.set_region(std::move(frame));

            this->_update_layout();
        }
    }

    void push_notify_waiting() {
        for (auto &rect : this->_cell_guide_rects) {
            rect.push_notify_waiting();
        }
    }

    void pop_notify_waiting() {
        for (auto &rect : this->_cell_guide_rects) {
            rect.pop_notify_waiting();
        }
    }

   private:
    std::vector<base> _property_observers;

    void _update_layout() {
        auto frame_region = this->_direction_swapped_region_if_horizontal(this->_frame_guide_rect.region());
        auto const &preferred_cell_count = this->_preferred_cell_count.value();

        if (preferred_cell_count == 0) {
            this->_cell_guide_rects.clear();
            this->_actual_cell_count.set_value(0);
            return;
        }

        auto const is_col_limiting = frame_region.size.width != 0;
        auto const is_row_limiting = frame_region.size.height != 0;
        auto const border_rect = this->_transformed_border_rect();
        auto const border_abs_size = ui::size{fabsf(border_rect.size.width), fabsf(border_rect.size.height)};
        std::vector<std::vector<ui::region>> regions;
        float row_max_diff = 0.0f;
        ui::point origin = {.v = 0.0f};
        std::vector<ui::region> row_regions;
        auto const prev_actual_cell_count = this->_cell_guide_rects.size();
        std::size_t actual_cell_count = 0;

        auto each = make_fast_each(preferred_cell_count);
        while (yas_each_next(each)) {
            auto const &idx = yas_each_index(each);
            auto cell_size = this->_transformed_cell_size(idx);

            if ((is_col_limiting && fabsf(origin.x + cell_size.width) > border_abs_size.width) ||
                this->_is_top_of_new_line(idx)) {
                regions.emplace_back(std::move(row_regions));

                auto const row_new_line_diff = this->_transformed_row_new_line_diff(idx);
                if (std::fabsf(row_new_line_diff) > std::fabs(row_max_diff)) {
                    row_max_diff = row_new_line_diff;
                }

                origin.x = 0.0f;
                origin.y += row_max_diff;

                row_regions.clear();
                row_max_diff = 0.0f;
            }

            if (is_row_limiting && fabsf(origin.y + cell_size.height) > border_abs_size.height) {
                break;
            }

            row_regions.emplace_back(
                ui::region{.origin = {origin.x + border_rect.origin.x, origin.y + border_rect.origin.y},
                           .size = {cell_size.width, cell_size.height}});

            ++actual_cell_count;

            if (auto const row_cell_diff = this->_transformed_row_cell_diff(idx)) {
                if (std::fabsf(row_cell_diff) > std::fabs(row_max_diff)) {
                    row_max_diff = row_cell_diff;
                }
            }

            origin.x += this->_transformed_col_diff(idx);
        }

        if (row_regions.size() > 0) {
            regions.emplace_back(std::move(row_regions));
        }

        this->_cell_guide_rects.resize(actual_cell_count);

        this->push_notify_waiting();

        std::size_t idx = 0;

        for (auto const &row_regions : regions) {
            if (row_regions.size() > 0) {
                auto align_offset = 0.0f;
                auto const alignment = this->_alignment.value();

                if (alignment != ui::layout_alignment::min) {
                    auto const content_width =
                        row_regions.back().origin.x + row_regions.back().size.width - row_regions.front().origin.x;
                    align_offset = border_rect.size.width - content_width;

                    if (alignment == ui::layout_alignment::mid) {
                        align_offset *= 0.5f;
                    }
                }

                for (auto const &region : row_regions) {
                    ui::region aligned_region{.origin = {region.origin.x + align_offset, region.origin.y},
                                              .size = region.size};
                    this->_cell_guide_rects.at(idx).set_region(
                        this->_direction_swapped_region_if_horizontal(aligned_region));

                    ++idx;
                }
            }
        }

        this->pop_notify_waiting();

        if (prev_actual_cell_count != actual_cell_count) {
            this->_actual_cell_count.set_value(actual_cell_count);
        }
    }

    std::optional<cell_location> _cell_location(std::size_t const cell_idx) {
        std::size_t top_idx = 0;
        std::size_t line_idx = 0;

        for (auto const &line : this->_lines.value()) {
            if (top_idx <= cell_idx && cell_idx < (top_idx + line.cell_sizes.size())) {
                return cell_location{.line_idx = line_idx, .cell_idx = cell_idx - top_idx};
            }
            top_idx += line.cell_sizes.size();
            ++line_idx;
        }

        return std::nullopt;
    }

    ui::size _cell_size(std::size_t const idx) {
        std::size_t find_idx = 0;

        for (auto const &line : this->_lines.value()) {
            std::size_t const line_idx = idx - find_idx;
            std::size_t const line_cell_count = line.cell_sizes.size();

            if (line_idx < line_cell_count) {
                return line.cell_sizes.at(line_idx);
            }

            find_idx += line_cell_count;
        }

        return this->_default_cell_size.value();
    }

    bool _is_top_of_new_line(std::size_t const idx) {
        if (auto cell_location = this->_cell_location(idx)) {
            if (cell_location->line_idx > 0 && cell_location->cell_idx == 0) {
                return true;
            }
        }

        return false;
    }

    ui::size _transformed_cell_size(std::size_t const idx) {
        ui::size result;
        auto const &cell_size = _cell_size(idx);

        switch (this->_direction.value()) {
            case ui::layout_direction::horizontal:
                result = ui::size{cell_size.height, cell_size.width};
            case ui::layout_direction::vertical:
                result = cell_size;
        }

        if (this->_row_order.value() == ui::layout_order::descending) {
            result.height *= -1.0f;
        }

        if (this->_col_order.value() == ui::layout_order::descending) {
            result.width *= -1.0;
        }

        if (result.width == 0) {
            result.width = this->_transformed_border_rect().size.width;
        }

        return result;
    }

    float _transformed_col_diff(std::size_t const idx) {
        auto diff = fabsf(_transformed_cell_size(idx).width) + this->_col_spacing.value();
        if (this->_col_order.value() == ui::layout_order::descending) {
            diff *= -1.0f;
        }
        return diff;
    }

    float _transformed_row_cell_diff(std::size_t const idx) {
        auto diff = fabsf(this->_transformed_cell_size(idx).height) + this->_row_spacing.value();
        if (this->_row_order.value() == ui::layout_order::descending) {
            diff *= -1.0f;
        }
        return diff;
    }

    float _transformed_row_new_line_diff(std::size_t const idx) {
        auto diff = 0.0f;
        auto const &lines = this->_lines.value();

        if (auto cell_location = _cell_location(idx)) {
            auto line_idx = cell_location->line_idx;

            while (line_idx > 0) {
                --line_idx;

                diff += lines.at(line_idx).new_line_min_offset + this->_row_spacing.value();

                if (lines.at(line_idx).cell_sizes.size() > 0) {
                    break;
                }
            }
        }

        if (this->_row_order.value() == ui::layout_order::descending) {
            diff *= -1.0f;
        }

        return diff;
    }

    ui::region _transformed_border_rect() {
        auto const original = _direction_swapped_region_if_horizontal(this->_border_guide_rect.region());
        ui::region result{.size = original.size};

        switch (this->_row_order.value()) {
            case ui::layout_order::ascending: {
                result.origin.y = original.origin.y;
            } break;
            case ui::layout_order::descending: {
                result.origin.y = original.origin.y + original.size.height;
                result.size.height *= -1.0f;
            } break;
        }

        switch (this->_col_order.value()) {
            case ui::layout_order::ascending: {
                result.origin.x = original.origin.x;
            } break;
            case ui::layout_order::descending: {
                result.origin.x = original.origin.x + original.size.width;
                result.size.width *= -1.0f;
            } break;
        }

        return result;
    }

    ui::region _direction_swapped_region_if_horizontal(ui::region const &region) {
        if (this->_direction.value() == ui::layout_direction::horizontal) {
            return ui::region{.origin = {region.origin.y, region.origin.x},
                              .size = {region.size.height, region.size.width}};
        } else {
            return region;
        }
    }
};

#pragma mark - ui::collection_layout

ui::collection_layout::collection_layout() : collection_layout(args{}) {
}

ui::collection_layout::collection_layout(args args) : base(std::make_shared<impl>(std::move(args))) {
    impl_ptr<impl>()->prepare(*this);
}

ui::collection_layout::collection_layout(std::nullptr_t) : base(nullptr) {
}

void ui::collection_layout::set_frame(ui::region frame) {
    impl_ptr<impl>()->set_frame(std::move(frame));
}

void ui::collection_layout::set_preferred_cell_count(std::size_t const count) {
    impl_ptr<impl>()->_preferred_cell_count.set_value(count);
}

ui::region ui::collection_layout::frame() const {
    return impl_ptr<impl>()->_frame_guide_rect.region();
}

void ui::collection_layout::set_default_cell_size(ui::size size) {
    impl_ptr<impl>()->_default_cell_size.set_value(std::move(size));
}

void ui::collection_layout::set_lines(std::vector<ui::collection_layout::line> lines) {
    impl_ptr<impl>()->_lines.set_value(std::move(lines));
}

void ui::collection_layout::set_row_spacing(float const spacing) {
    impl_ptr<impl>()->_row_spacing.set_value(spacing);
}

void ui::collection_layout::set_col_spacing(float const spacing) {
    impl_ptr<impl>()->_col_spacing.set_value(spacing);
}

void ui::collection_layout::set_alignment(ui::layout_alignment const align) {
    impl_ptr<impl>()->_alignment.set_value(align);
}

void ui::collection_layout::set_direction(ui::layout_direction const dir) {
    impl_ptr<impl>()->_direction.set_value(dir);
}

void ui::collection_layout::set_row_order(ui::layout_order const order) {
    impl_ptr<impl>()->_row_order.set_value(order);
}

void ui::collection_layout::set_col_order(ui::layout_order const order) {
    impl_ptr<impl>()->_col_order.set_value(order);
}

std::size_t const &ui::collection_layout::preferred_cell_count() const {
    return impl_ptr<impl>()->_preferred_cell_count.value();
}

std::size_t ui::collection_layout::actual_cell_count() const {
    return impl_ptr<impl>()->_cell_guide_rects.size();
}

ui::size const &ui::collection_layout::default_cell_size() const {
    return impl_ptr<impl>()->_default_cell_size.value();
}

std::vector<ui::collection_layout::line> const &ui::collection_layout::lines() const {
    return impl_ptr<impl>()->_lines.value();
}

float const &ui::collection_layout::row_spacing() const {
    return impl_ptr<impl>()->_row_spacing.value();
}

float const &ui::collection_layout::col_spacing() const {
    return impl_ptr<impl>()->_col_spacing.value();
}

ui::layout_alignment const &ui::collection_layout::alignment() const {
    return impl_ptr<impl>()->_alignment.value();
}

ui::layout_direction const &ui::collection_layout::direction() const {
    return impl_ptr<impl>()->_direction.value();
}

ui::layout_order const &ui::collection_layout::row_order() const {
    return impl_ptr<impl>()->_row_order.value();
}

ui::layout_order const &ui::collection_layout::col_order() const {
    return impl_ptr<impl>()->_col_order.value();
}

ui::layout_borders const &ui::collection_layout::borders() const {
    return impl_ptr<impl>()->_borders;
}

ui::layout_guide_rect &ui::collection_layout::frame_layout_guide_rect() {
    return impl_ptr<impl>()->_frame_guide_rect;
}

std::vector<ui::layout_guide_rect> &ui::collection_layout::cell_layout_guide_rects() {
    return impl_ptr<impl>()->_cell_guide_rects;
}

chaining::chain_sync_t<std::size_t> ui::collection_layout::chain_preferred_cell_count() const {
    return impl_ptr<impl>()->_preferred_cell_count.chain();
}

chaining::chain_sync_t<std::size_t> ui::collection_layout::chain_actual_cell_count() const {
    return impl_ptr<impl>()->_actual_cell_count.chain();
}

chaining::chain_sync_t<ui::size> ui::collection_layout::chain_default_cell_size() const {
    return impl_ptr<impl>()->_default_cell_size.chain();
}

chaining::chain_sync_t<std::vector<ui::collection_layout::line>> ui::collection_layout::chain_lines() const {
    return impl_ptr<impl>()->_lines.chain();
}

chaining::chain_sync_t<float> ui::collection_layout::chain_row_spacing() const {
    return impl_ptr<impl>()->_row_spacing.chain();
}

chaining::chain_sync_t<float> ui::collection_layout::chain_col_spacing() const {
    return impl_ptr<impl>()->_col_spacing.chain();
}

chaining::chain_sync_t<ui::layout_alignment> ui::collection_layout::chain_alignment() const {
    return impl_ptr<impl>()->_alignment.chain();
}

chaining::chain_sync_t<ui::layout_direction> ui::collection_layout::chain_direction() const {
    return impl_ptr<impl>()->_direction.chain();
}

chaining::chain_sync_t<ui::layout_order> ui::collection_layout::chain_row_order() const {
    return impl_ptr<impl>()->_row_order.chain();
}

chaining::chain_sync_t<ui::layout_order> ui::collection_layout::chain_col_order() const {
    return impl_ptr<impl>()->_col_order.chain();
}
