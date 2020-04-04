//
//  yas_ui_collection_layout.cpp
//

#include "yas_ui_collection_layout.h"

#include <chaining/yas_chaining_utils.h>
#include <cpp_utils/yas_delaying_caller.h>
#include <cpp_utils/yas_fast_each.h>

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

#pragma mark - ui::collection_layout

ui::collection_layout::collection_layout(args args)
    : frame_guide_rect(ui::layout_guide_rect::make_shared(std::move(args.frame))),
      preferred_cell_count(chaining::value::holder<std::size_t>::make_shared(args.preferred_cell_count)),
      default_cell_size(chaining::value::holder<ui::size>::make_shared(std::move(args.default_cell_size))),
      lines(chaining::value::holder<std::vector<ui::collection_layout::line>>::make_shared(std::move(args.lines))),
      row_spacing(chaining::value::holder<float>::make_shared(args.row_spacing)),
      col_spacing(chaining::value::holder<float>::make_shared(args.col_spacing)),
      alignment(chaining::value::holder<ui::layout_alignment>::make_shared(args.alignment)),
      direction(chaining::value::holder<ui::layout_direction>::make_shared(args.direction)),
      row_order(chaining::value::holder<ui::layout_order>::make_shared(args.row_order)),
      col_order(chaining::value::holder<ui::layout_order>::make_shared(args.col_order)),
      _left_border_observer(frame_guide_rect->left()
                                ->chain()
                                .to(chaining::add(args.borders.left))
                                .send_to(_border_guide_rect->left())
                                .sync()),
      _right_border_observer(frame_guide_rect->right()
                                 ->chain()
                                 .to(chaining::add(-args.borders.right))
                                 .send_to(_border_guide_rect->right())
                                 .sync()),
      _bottom_border_observer(frame_guide_rect->bottom()
                                  ->chain()
                                  .to(chaining::add(args.borders.bottom))
                                  .send_to(_border_guide_rect->bottom())
                                  .sync()),
      _top_border_observer(frame_guide_rect->top()
                               ->chain()
                               .to(chaining::add(-args.borders.top))
                               .send_to(_border_guide_rect->top())
                               .sync()),
      borders(std::move(args.borders)) {
    if (args.borders.left < 0 || args.borders.right < 0 || args.borders.bottom < 0 || args.borders.top < 0) {
        throw "borders value is negative.";
    }
}

chaining::value::holder_ptr<std::size_t> const &ui::collection_layout::actual_cell_count() const {
    return this->_actual_cell_count;
}

void ui::collection_layout::_prepare(std::shared_ptr<collection_layout> const &layout) {
    auto weak_layout = to_weak(layout);

    this->_layout_receiver = chaining::perform_receiver<>::make_shared([weak_layout]() {
        if (auto layout = weak_layout.lock()) {
            layout->_update_layout();
        }
    });

    this->frame_guide_rect->chain().send_null_to(this->_layout_receiver).end()->add_to(this->_pool);
    this->_border_guide_rect->chain().send_null_to(this->_layout_receiver).end()->add_to(this->_pool);
    this->row_spacing->chain().send_null_to(this->_layout_receiver).end()->add_to(this->_pool);
    this->col_spacing->chain().send_null_to(this->_layout_receiver).end()->add_to(this->_pool);
    this->alignment->chain().send_null_to(this->_layout_receiver).end()->add_to(this->_pool);
    this->direction->chain().send_null_to(this->_layout_receiver).end()->add_to(this->_pool);
    this->row_order->chain().send_null_to(this->_layout_receiver).end()->add_to(this->_pool);
    this->col_order->chain().send_null_to(this->_layout_receiver).end()->add_to(this->_pool);
    this->preferred_cell_count->chain().send_null_to(this->_layout_receiver).end()->add_to(this->_pool);
    this->default_cell_size->chain().send_null_to(this->_layout_receiver).end()->add_to(this->_pool);
    this->lines->chain().send_null_to(this->_layout_receiver).end()->add_to(this->_pool);

    this->_update_layout();
}

void ui::collection_layout::_push_notify_waiting() {
    for (auto &rect : this->cell_guide_rects) {
        rect->push_notify_waiting();
    }
}

void ui::collection_layout::_pop_notify_waiting() {
    for (auto &rect : this->cell_guide_rects) {
        rect->pop_notify_waiting();
    }
}

void ui::collection_layout::_update_layout() {
    auto frame_region = this->_direction_swapped_region_if_horizontal(this->frame_guide_rect->region());
    auto const &preferred_cell_count = this->preferred_cell_count->raw();

    if (preferred_cell_count == 0) {
        this->cell_guide_rects.clear();
        this->_actual_cell_count->set_value(0);
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

    if (actual_cell_count < this->cell_guide_rects.size()) {
        this->cell_guide_rects.resize(actual_cell_count);
    } else {
        while (this->cell_guide_rects.size() < actual_cell_count) {
            this->cell_guide_rects.emplace_back(ui::layout_guide_rect::make_shared());
        }
    }

    this->_push_notify_waiting();

    std::size_t idx = 0;

    for (auto const &row_regions : regions) {
        if (row_regions.size() > 0) {
            auto align_offset = 0.0f;
            auto const alignment = this->alignment->raw();

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
                this->cell_guide_rects.at(idx)->set_region(
                    this->_direction_swapped_region_if_horizontal(aligned_region));

                ++idx;
            }
        }
    }

    this->_pop_notify_waiting();

    this->_actual_cell_count->set_value(actual_cell_count);
}

std::optional<ui::collection_layout::cell_location> ui::collection_layout::_cell_location(std::size_t const cell_idx) {
    std::size_t top_idx = 0;
    std::size_t line_idx = 0;

    for (auto const &line : this->lines->raw()) {
        if (top_idx <= cell_idx && cell_idx < (top_idx + line.cell_sizes.size())) {
            return cell_location{.line_idx = line_idx, .cell_idx = cell_idx - top_idx};
        }
        top_idx += line.cell_sizes.size();
        ++line_idx;
    }

    return std::nullopt;
}

ui::size ui::collection_layout::_cell_size(std::size_t const idx) {
    std::size_t find_idx = 0;

    for (auto const &line : this->lines->raw()) {
        std::size_t const line_idx = idx - find_idx;
        std::size_t const line_cell_count = line.cell_sizes.size();

        if (line_idx < line_cell_count) {
            return line.cell_sizes.at(line_idx);
        }

        find_idx += line_cell_count;
    }

    return this->default_cell_size->raw();
}

bool ui::collection_layout::_is_top_of_new_line(std::size_t const idx) {
    if (auto cell_location = this->_cell_location(idx)) {
        if (cell_location->line_idx > 0 && cell_location->cell_idx == 0) {
            return true;
        }
    }

    return false;
}

ui::size ui::collection_layout::_transformed_cell_size(std::size_t const idx) {
    ui::size result;
    auto const &cell_size = _cell_size(idx);

    switch (this->direction->raw()) {
        case ui::layout_direction::horizontal:
            result = ui::size{cell_size.height, cell_size.width};
        case ui::layout_direction::vertical:
            result = cell_size;
    }

    if (this->row_order->raw() == ui::layout_order::descending) {
        result.height *= -1.0f;
    }

    if (this->col_order->raw() == ui::layout_order::descending) {
        result.width *= -1.0;
    }

    if (result.width == 0) {
        result.width = this->_transformed_border_rect().size.width;
    }

    return result;
}

float ui::collection_layout::_transformed_col_diff(std::size_t const idx) {
    auto diff = fabsf(_transformed_cell_size(idx).width) + this->col_spacing->raw();
    if (this->col_order->raw() == ui::layout_order::descending) {
        diff *= -1.0f;
    }
    return diff;
}

float ui::collection_layout::_transformed_row_cell_diff(std::size_t const idx) {
    auto diff = fabsf(this->_transformed_cell_size(idx).height) + this->row_spacing->raw();
    if (this->row_order->raw() == ui::layout_order::descending) {
        diff *= -1.0f;
    }
    return diff;
}

float ui::collection_layout::_transformed_row_new_line_diff(std::size_t const idx) {
    auto diff = 0.0f;
    auto const &lines = this->lines->raw();

    if (auto cell_location = _cell_location(idx)) {
        auto line_idx = cell_location->line_idx;

        while (line_idx > 0) {
            --line_idx;

            diff += lines.at(line_idx).new_line_min_offset + this->row_spacing->raw();

            if (lines.at(line_idx).cell_sizes.size() > 0) {
                break;
            }
        }
    }

    if (this->row_order->raw() == ui::layout_order::descending) {
        diff *= -1.0f;
    }

    return diff;
}

ui::region ui::collection_layout::_transformed_border_rect() {
    auto const original = _direction_swapped_region_if_horizontal(this->_border_guide_rect->region());
    ui::region result{.size = original.size};

    switch (this->row_order->raw()) {
        case ui::layout_order::ascending: {
            result.origin.y = original.origin.y;
        } break;
        case ui::layout_order::descending: {
            result.origin.y = original.origin.y + original.size.height;
            result.size.height *= -1.0f;
        } break;
    }

    switch (this->col_order->raw()) {
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

ui::region ui::collection_layout::_direction_swapped_region_if_horizontal(ui::region const &region) {
    if (this->direction->raw() == ui::layout_direction::horizontal) {
        return ui::region{.origin = {region.origin.y, region.origin.x},
                          .size = {region.size.height, region.size.width}};
    } else {
        return region;
    }
}

ui::collection_layout_ptr ui::collection_layout::make_shared() {
    return make_shared({});
}

ui::collection_layout_ptr ui::collection_layout::make_shared(args args) {
    auto shared = std::shared_ptr<collection_layout>(new collection_layout{std::move(args)});
    shared->_prepare(shared);
    return shared;
}
