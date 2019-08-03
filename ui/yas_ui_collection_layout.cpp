//
//  yas_ui_collection_layout.cpp
//

#include "yas_ui_collection_layout.h"
#include <chaining/yas_chaining_utils.h>
#include <cpp_utils/yas_delaying_caller.h>
#include <cpp_utils/yas_fast_each.h>
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

struct ui::collection_layout::impl {
    struct cell_location {
        std::size_t line_idx;
        std::size_t cell_idx;
    };

    chaining::value::holder<float> _row_spacing;
    chaining::value::holder<float> _col_spacing;
    chaining::value::holder<ui::layout_alignment> _alignment;
    chaining::value::holder<ui::layout_direction> _direction;
    chaining::value::holder<ui::layout_order> _row_order;
    chaining::value::holder<ui::layout_order> _col_order;
    chaining::value::holder<std::size_t> _preferred_cell_count;
    chaining::value::holder<std::size_t> _actual_cell_count{std::size_t(0)};
    chaining::value::holder<ui::size> _default_cell_size;
    chaining::value::holder<std::vector<ui::collection_layout::line>> _lines;

    ui::layout_guide_rect _frame_guide_rect;
    ui::layout_guide_rect _border_guide_rect;
    std::vector<ui::layout_guide_rect> _cell_guide_rects;
    chaining::any_observer_ptr _left_border_observer;
    chaining::any_observer_ptr _right_border_observer;
    chaining::any_observer_ptr _bottom_border_observer;
    chaining::any_observer_ptr _top_border_observer;
    ui::layout_borders const _borders;
    chaining::any_observer_ptr _border_observer = nullptr;
    std::optional<chaining::perform_receiver<>> _layout_receiver = std::nullopt;

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
                                    .send_to(_border_guide_rect.left())
                                    .sync()),
          _right_border_observer(_frame_guide_rect.right()
                                     .chain()
                                     .to(chaining::add(-args.borders.right))
                                     .send_to(_border_guide_rect.right())
                                     .sync()),
          _bottom_border_observer(_frame_guide_rect.bottom()
                                      .chain()
                                      .to(chaining::add(args.borders.bottom))
                                      .send_to(_border_guide_rect.bottom())
                                      .sync()),
          _top_border_observer(_frame_guide_rect.top()
                                   .chain()
                                   .to(chaining::add(-args.borders.top))
                                   .send_to(_border_guide_rect.top())
                                   .sync()),

          _borders(std::move(args.borders)) {
        if (args.borders.left < 0 || args.borders.right < 0 || args.borders.bottom < 0 || args.borders.top < 0) {
            throw "borders value is negative.";
        }
    }

    void prepare(std::shared_ptr<ui::collection_layout> const &layout) {
        auto weak_layout = to_weak(layout);

        this->_layout_receiver = chaining::perform_receiver<>{[weak_layout]() {
            if (auto layout = weak_layout.lock()) {
                layout->_impl->_update_layout();
            }
        }};

        this->_border_observer =
            this->_border_guide_rect.chain()
                .guard([weak_layout](ui::region const &) { return !weak_layout.expired(); })
                .perform([weak_layout](ui::region const &) { weak_layout.lock()->_impl->_update_layout(); })
                .end();

        this->_property_observers.emplace_back(this->_row_spacing.chain().send_null(*this->_layout_receiver).end());

        this->_property_observers.emplace_back(this->_col_spacing.chain().send_null(*this->_layout_receiver).end());

        this->_property_observers.emplace_back(this->_alignment.chain().send_null(*this->_layout_receiver).end());

        this->_property_observers.emplace_back(this->_direction.chain().send_null(*this->_layout_receiver).end());

        this->_property_observers.emplace_back(this->_row_order.chain().send_null(*this->_layout_receiver).end());

        this->_property_observers.emplace_back(this->_col_order.chain().send_null(*this->_layout_receiver).end());

        this->_property_observers.emplace_back(
            this->_preferred_cell_count.chain().send_null(*this->_layout_receiver).end());

        this->_property_observers.emplace_back(
            this->_default_cell_size.chain().send_null(*this->_layout_receiver).end());

        this->_property_observers.emplace_back(this->_lines.chain().send_null(*this->_layout_receiver).end());

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
    std::vector<chaining::any_observer_ptr> _property_observers;

    void _update_layout() {
        auto frame_region = this->_direction_swapped_region_if_horizontal(this->_frame_guide_rect.region());
        auto const &preferred_cell_count = this->_preferred_cell_count.raw();

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
                auto const alignment = this->_alignment.raw();

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

        for (auto const &line : this->_lines.raw()) {
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

        for (auto const &line : this->_lines.raw()) {
            std::size_t const line_idx = idx - find_idx;
            std::size_t const line_cell_count = line.cell_sizes.size();

            if (line_idx < line_cell_count) {
                return line.cell_sizes.at(line_idx);
            }

            find_idx += line_cell_count;
        }

        return this->_default_cell_size.raw();
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

        switch (this->_direction.raw()) {
            case ui::layout_direction::horizontal:
                result = ui::size{cell_size.height, cell_size.width};
            case ui::layout_direction::vertical:
                result = cell_size;
        }

        if (this->_row_order.raw() == ui::layout_order::descending) {
            result.height *= -1.0f;
        }

        if (this->_col_order.raw() == ui::layout_order::descending) {
            result.width *= -1.0;
        }

        if (result.width == 0) {
            result.width = this->_transformed_border_rect().size.width;
        }

        return result;
    }

    float _transformed_col_diff(std::size_t const idx) {
        auto diff = fabsf(_transformed_cell_size(idx).width) + this->_col_spacing.raw();
        if (this->_col_order.raw() == ui::layout_order::descending) {
            diff *= -1.0f;
        }
        return diff;
    }

    float _transformed_row_cell_diff(std::size_t const idx) {
        auto diff = fabsf(this->_transformed_cell_size(idx).height) + this->_row_spacing.raw();
        if (this->_row_order.raw() == ui::layout_order::descending) {
            diff *= -1.0f;
        }
        return diff;
    }

    float _transformed_row_new_line_diff(std::size_t const idx) {
        auto diff = 0.0f;
        auto const &lines = this->_lines.raw();

        if (auto cell_location = _cell_location(idx)) {
            auto line_idx = cell_location->line_idx;

            while (line_idx > 0) {
                --line_idx;

                diff += lines.at(line_idx).new_line_min_offset + this->_row_spacing.raw();

                if (lines.at(line_idx).cell_sizes.size() > 0) {
                    break;
                }
            }
        }

        if (this->_row_order.raw() == ui::layout_order::descending) {
            diff *= -1.0f;
        }

        return diff;
    }

    ui::region _transformed_border_rect() {
        auto const original = _direction_swapped_region_if_horizontal(this->_border_guide_rect.region());
        ui::region result{.size = original.size};

        switch (this->_row_order.raw()) {
            case ui::layout_order::ascending: {
                result.origin.y = original.origin.y;
            } break;
            case ui::layout_order::descending: {
                result.origin.y = original.origin.y + original.size.height;
                result.size.height *= -1.0f;
            } break;
        }

        switch (this->_col_order.raw()) {
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
        if (this->_direction.raw() == ui::layout_direction::horizontal) {
            return ui::region{.origin = {region.origin.y, region.origin.x},
                              .size = {region.size.height, region.size.width}};
        } else {
            return region;
        }
    }
};

#pragma mark - ui::collection_layout

ui::collection_layout::collection_layout(args args) : _impl(std::make_shared<impl>(std::move(args))) {
}

void ui::collection_layout::set_frame(ui::region frame) {
    this->_impl->set_frame(std::move(frame));
}

void ui::collection_layout::set_preferred_cell_count(std::size_t const count) {
    this->_impl->_preferred_cell_count.set_value(count);
}

ui::region ui::collection_layout::frame() const {
    return this->_impl->_frame_guide_rect.region();
}

void ui::collection_layout::set_default_cell_size(ui::size size) {
    this->_impl->_default_cell_size.set_value(std::move(size));
}

void ui::collection_layout::set_lines(std::vector<ui::collection_layout::line> lines) {
    this->_impl->_lines.set_value(std::move(lines));
}

void ui::collection_layout::set_row_spacing(float const spacing) {
    this->_impl->_row_spacing.set_value(spacing);
}

void ui::collection_layout::set_col_spacing(float const spacing) {
    this->_impl->_col_spacing.set_value(spacing);
}

void ui::collection_layout::set_alignment(ui::layout_alignment const align) {
    this->_impl->_alignment.set_value(align);
}

void ui::collection_layout::set_direction(ui::layout_direction const dir) {
    this->_impl->_direction.set_value(dir);
}

void ui::collection_layout::set_row_order(ui::layout_order const order) {
    this->_impl->_row_order.set_value(order);
}

void ui::collection_layout::set_col_order(ui::layout_order const order) {
    this->_impl->_col_order.set_value(order);
}

std::size_t const &ui::collection_layout::preferred_cell_count() const {
    return this->_impl->_preferred_cell_count.raw();
}

std::size_t ui::collection_layout::actual_cell_count() const {
    return this->_impl->_cell_guide_rects.size();
}

ui::size const &ui::collection_layout::default_cell_size() const {
    return this->_impl->_default_cell_size.raw();
}

std::vector<ui::collection_layout::line> const &ui::collection_layout::lines() const {
    return this->_impl->_lines.raw();
}

float const &ui::collection_layout::row_spacing() const {
    return this->_impl->_row_spacing.raw();
}

float const &ui::collection_layout::col_spacing() const {
    return this->_impl->_col_spacing.raw();
}

ui::layout_alignment const &ui::collection_layout::alignment() const {
    return this->_impl->_alignment.raw();
}

ui::layout_direction const &ui::collection_layout::direction() const {
    return this->_impl->_direction.raw();
}

ui::layout_order const &ui::collection_layout::row_order() const {
    return this->_impl->_row_order.raw();
}

ui::layout_order const &ui::collection_layout::col_order() const {
    return this->_impl->_col_order.raw();
}

ui::layout_borders const &ui::collection_layout::borders() const {
    return this->_impl->_borders;
}

ui::layout_guide_rect &ui::collection_layout::frame_layout_guide_rect() {
    return this->_impl->_frame_guide_rect;
}

std::vector<ui::layout_guide_rect> &ui::collection_layout::cell_layout_guide_rects() {
    return this->_impl->_cell_guide_rects;
}

chaining::chain_sync_t<std::size_t> ui::collection_layout::chain_preferred_cell_count() const {
    return this->_impl->_preferred_cell_count.chain();
}

chaining::chain_sync_t<std::size_t> ui::collection_layout::chain_actual_cell_count() const {
    return this->_impl->_actual_cell_count.chain();
}

chaining::chain_sync_t<ui::size> ui::collection_layout::chain_default_cell_size() const {
    return this->_impl->_default_cell_size.chain();
}

chaining::chain_sync_t<std::vector<ui::collection_layout::line>> ui::collection_layout::chain_lines() const {
    return this->_impl->_lines.chain();
}

chaining::chain_sync_t<float> ui::collection_layout::chain_row_spacing() const {
    return this->_impl->_row_spacing.chain();
}

chaining::chain_sync_t<float> ui::collection_layout::chain_col_spacing() const {
    return this->_impl->_col_spacing.chain();
}

chaining::chain_sync_t<ui::layout_alignment> ui::collection_layout::chain_alignment() const {
    return this->_impl->_alignment.chain();
}

chaining::chain_sync_t<ui::layout_direction> ui::collection_layout::chain_direction() const {
    return this->_impl->_direction.chain();
}

chaining::chain_sync_t<ui::layout_order> ui::collection_layout::chain_row_order() const {
    return this->_impl->_row_order.chain();
}

chaining::chain_sync_t<ui::layout_order> ui::collection_layout::chain_col_order() const {
    return this->_impl->_col_order.chain();
}

void ui::collection_layout::_prepare(std::shared_ptr<collection_layout> const &layout) {
    this->_impl->prepare(layout);
}

std::shared_ptr<ui::collection_layout> ui::collection_layout::make_shared() {
    return make_shared({});
}

std::shared_ptr<ui::collection_layout> ui::collection_layout::make_shared(args args) {
    auto shared = std::shared_ptr<collection_layout>(new collection_layout{std::move(args)});
    shared->_prepare(shared);
    return shared;
}
