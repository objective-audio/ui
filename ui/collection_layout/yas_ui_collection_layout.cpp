//
//  yas_ui_collection_layout.cpp
//

#include "yas_ui_collection_layout.h"

#include <cpp_utils/yas_delaying_caller.h>
#include <cpp_utils/yas_fast_each.h>

using namespace yas;
using namespace yas::ui;

#pragma mark - collection_layout

collection_layout::collection_layout(args args)
    : _preferred_layout_guide(layout_region_guide::make_shared(std::move(args.frame))),
      borders(std::move(args.borders)),
      _preferred_cell_count(observing::value::holder<std::size_t>::make_shared(args.preferred_cell_count)),
      _default_cell_size(observing::value::holder<size>::make_shared(std::move(args.default_cell_size))),
      _lines(observing::value::holder<std::vector<collection_layout::line>>::make_shared(std::move(args.lines))),
      _row_spacing(observing::value::holder<float>::make_shared(args.row_spacing)),
      _col_spacing(observing::value::holder<float>::make_shared(args.col_spacing)),
      _alignment(observing::value::holder<layout_alignment>::make_shared(args.alignment)),
      _direction(observing::value::holder<layout_direction>::make_shared(args.direction)),
      _row_order(observing::value::holder<layout_order>::make_shared(args.row_order)),
      _col_order(observing::value::holder<layout_order>::make_shared(args.col_order)),
      _cell_layout_guides(observing::vector::holder<std::shared_ptr<layout_region_guide>>::make_shared()),
      _actual_cells_layout_guide(layout_region_guide::make_shared()),
      _border_layout_guide(ui::layout_region_guide::make_shared()) {
    if (borders.left < 0 || borders.right < 0 || borders.bottom < 0 || borders.top < 0) {
        throw std::runtime_error("borders value is negative.");
    }

    this->_preferred_layout_guide->left()
        ->observe([this, adding = borders.left](float const &value) {
            this->_border_layout_guide->left()->set_value(value + adding);
        })
        .sync()
        ->add_to(this->_pool);

    this->_preferred_layout_guide->right()
        ->observe([this, adding = -borders.right](float const &value) {
            this->_border_layout_guide->right()->set_value(value + adding);
        })
        .sync()
        ->add_to(this->_pool);

    this->_preferred_layout_guide->bottom()
        ->observe([this, adding = borders.bottom](float const &value) {
            this->_border_layout_guide->bottom()->set_value(value + adding);
        })
        .sync()
        ->add_to(this->_pool);

    this->_preferred_layout_guide->top()
        ->observe([this, adding = -borders.top](float const &value) {
            this->_border_layout_guide->top()->set_value(value + adding);
        })
        .sync()
        ->add_to(this->_pool);

    this->_preferred_layout_guide->observe([this](auto const &) { this->_update_layout(); }).end()->add_to(this->_pool);
    this->_border_layout_guide->observe([this](auto const &) { this->_update_layout(); }).end()->add_to(this->_pool);

    this->_row_spacing->observe([this](auto const &) { this->_update_layout(); }).end()->add_to(this->_pool);
    this->_col_spacing->observe([this](auto const &) { this->_update_layout(); }).end()->add_to(this->_pool);
    this->_alignment->observe([this](auto const &) { this->_update_layout(); }).end()->add_to(this->_pool);
    this->_direction->observe([this](auto const &) { this->_update_layout(); }).end()->add_to(this->_pool);
    this->_row_order->observe([this](auto const &) { this->_update_layout(); }).end()->add_to(this->_pool);
    this->_col_order->observe([this](auto const &) { this->_update_layout(); }).end()->add_to(this->_pool);
    this->_preferred_cell_count->observe([this](auto const &) { this->_update_layout(); }).end()->add_to(this->_pool);
    this->_default_cell_size->observe([this](auto const &) { this->_update_layout(); }).end()->add_to(this->_pool);
    this->_lines->observe([this](auto const &) { this->_update_layout(); }).end()->add_to(this->_pool);

    this->_update_layout();
}

std::shared_ptr<layout_region_guide> const &collection_layout::preferred_layout_guide() const {
    return this->_preferred_layout_guide;
}

void collection_layout::set_preferred_cell_count(std::size_t const &count) {
    this->_preferred_cell_count->set_value(count);
}

void collection_layout::set_preferred_cell_count(std::size_t &&count) {
    this->_preferred_cell_count->set_value(std::move(count));
}

std::size_t collection_layout::preferred_cell_count() const {
    return this->_preferred_cell_count->value();
}

observing::syncable collection_layout::observe_preferred_cell_count(
    observing::caller<std::size_t>::handler_f &&handler) {
    return this->_preferred_cell_count->observe(std::move(handler));
}

std::size_t collection_layout::actual_cell_count() const {
    return this->_cell_layout_guides->size();
}

void collection_layout::set_default_cell_size(size const &size) {
    this->_default_cell_size->set_value(size);
}

void collection_layout::set_default_cell_size(size &&size) {
    this->_default_cell_size->set_value(std::move(size));
}

size collection_layout::default_cell_size() const {
    return this->_default_cell_size->value();
}

observing::syncable collection_layout::observe_default_cell_size(observing::caller<size>::handler_f &&handler) {
    return this->_default_cell_size->observe(std::move(handler));
}

void collection_layout::set_lines(std::vector<collection_layout::line> const &lines) {
    this->_lines->set_value(lines);
}

void collection_layout::set_lines(std::vector<collection_layout::line> &&lines) {
    this->_lines->set_value(std::move(lines));
}

std::vector<collection_layout::line> const &collection_layout::lines() const {
    return this->_lines->value();
}

observing::syncable collection_layout::observe_lines(
    observing::caller<std::vector<collection_layout::line>>::handler_f &&handler) {
    return this->_lines->observe(std::move(handler));
}

void collection_layout::set_row_spacing(float const &spacing) {
    this->_row_spacing->set_value(spacing);
}

void collection_layout::set_row_spacing(float &&spacing) {
    this->_row_spacing->set_value(std::move(spacing));
}

float const &collection_layout::row_spacing() const {
    return this->_row_spacing->value();
}

observing::syncable collection_layout::observe_row_spacing(observing::caller<float>::handler_f &&handler) {
    return this->_row_spacing->observe(std::move(handler));
}

void collection_layout::set_col_spacing(float const &spacing) {
    this->_col_spacing->set_value(spacing);
}

void collection_layout::set_col_spacing(float &&spacing) {
    this->_col_spacing->set_value(std::move(spacing));
}

float const &collection_layout::col_spacing() const {
    return this->_col_spacing->value();
}

observing::syncable collection_layout::observe_col_spacing(observing::caller<float>::handler_f &&handler) {
    return this->_col_spacing->observe(std::move(handler));
}

void collection_layout::set_alignment(layout_alignment const &alignment) {
    this->_alignment->set_value(alignment);
}

void collection_layout::set_alignment(layout_alignment &&alignment) {
    this->_alignment->set_value(std::move(alignment));
}

layout_alignment const &collection_layout::alignment() const {
    return this->_alignment->value();
}

observing::syncable collection_layout::observe_alignment(observing::caller<layout_alignment>::handler_f &&handler) {
    return this->_alignment->observe(std::move(handler));
}

void collection_layout::set_direction(layout_direction const &direction) {
    this->_direction->set_value(direction);
}

void collection_layout::set_direction(layout_direction &&direction) {
    this->_direction->set_value(std::move(direction));
}

layout_direction const &collection_layout::direction() const {
    return this->_direction->value();
}

observing::syncable collection_layout::observe_direction(observing::caller<layout_direction>::handler_f &&handler) {
    return this->_direction->observe(std::move(handler));
}

void collection_layout::set_row_order(layout_order const &order) {
    this->_row_order->set_value(order);
}

void collection_layout::set_row_order(layout_order &&order) {
    this->_row_order->set_value(std::move(order));
}

layout_order const &collection_layout::row_order() const {
    return this->_row_order->value();
}

observing::syncable collection_layout::observe_row_order(observing::caller<layout_order>::handler_f &&handler) {
    return this->_row_order->observe(std::move(handler));
}

void collection_layout::set_col_order(layout_order const &order) {
    this->_col_order->set_value(order);
}

void collection_layout::set_col_order(layout_order &&order) {
    this->_col_order->set_value(std::move(order));
}

layout_order const &collection_layout::col_order() const {
    return this->_col_order->value();
}

observing::syncable collection_layout::observe_col_order(observing::caller<layout_order>::handler_f &&handler) {
    return this->_col_order->observe(std::move(handler));
}

std::vector<std::shared_ptr<layout_region_guide>> const &collection_layout::actual_cell_layout_guides() const {
    return this->_cell_layout_guides->value();
}

observing::syncable collection_layout::observe_cell_layout_guides(
    std::function<void(std::vector<std::shared_ptr<layout_region_guide>> const &)> &&handler) {
    return this->_cell_layout_guides->observe(
        [handler = std::move(handler)](auto const &event) { handler(event.elements); });
}

ui::region collection_layout::actual_cells_frame() const {
    return this->_actual_cells_layout_guide->region();
}

std::shared_ptr<layout_region_source> collection_layout::actual_frame_layout_source() const {
    return this->_actual_cells_layout_guide;
}

void collection_layout::_push_notify_waiting() {
    for (auto const &guide : this->_cell_layout_guides->value()) {
        guide->push_notify_waiting();
    }
}

void collection_layout::_pop_notify_waiting() {
    for (auto const &guide : this->_cell_layout_guides->value()) {
        guide->pop_notify_waiting();
    }
}

void collection_layout::_update_layout() {
    auto const frame_region = this->_direction_swapped_region_if_horizontal(this->_preferred_layout_guide->region());
    auto const &preferred_cell_count = this->preferred_cell_count();
    auto const border_region = this->_transformed_border_region();
    auto const border_abs_size = size{fabsf(border_region.size.width), fabsf(border_region.size.height)};

    std::optional<region> actual_frame{std::nullopt};
    std::size_t actual_cell_count = 0;
    std::vector<std::shared_ptr<layout_region_guide>> actual_cell_guides;

    if (preferred_cell_count > 0) {
        auto const is_col_limiting = frame_region.size.width != 0;
        auto const is_row_limiting = frame_region.size.height != 0;
        std::vector<std::vector<region>> regions;
        float row_max_diff = 0.0f;
        point origin = {.v = 0.0f};
        std::vector<region> row_regions;

        auto each = make_fast_each(preferred_cell_count);
        while (yas_each_next(each)) {
            auto const &idx = yas_each_index(each);
            auto const cell_size = this->_transformed_cell_size(idx);

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
                region{.origin = {origin.x + border_region.origin.x, origin.y + border_region.origin.y},
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

        actual_cell_guides = this->_cell_layout_guides->value();

        if (actual_cell_count < actual_cell_guides.size()) {
            actual_cell_guides.resize(actual_cell_count);
        } else {
            while (actual_cell_guides.size() < actual_cell_count) {
                actual_cell_guides.emplace_back(layout_region_guide::make_shared());
            }
        }

        this->_push_notify_waiting();

        std::size_t idx = 0;

        for (auto const &row_regions : regions) {
            if (row_regions.size() > 0) {
                auto align_offset = 0.0f;
                auto const alignment = this->_alignment->value();

                if (alignment != layout_alignment::min) {
                    auto const content_width =
                        row_regions.back().origin.x + row_regions.back().size.width - row_regions.front().origin.x;
                    align_offset = border_region.size.width - content_width;

                    if (alignment == layout_alignment::mid) {
                        align_offset *= 0.5f;
                    }
                }

                for (auto const &region : row_regions) {
                    ui::region const aligned_region{.origin = {region.origin.x + align_offset, region.origin.y},
                                                    .size = region.size};
                    actual_cell_guides.at(idx)->set_region(
                        this->_direction_swapped_region_if_horizontal(aligned_region));

                    if (!actual_frame.has_value()) {
                        actual_frame = actual_cell_guides.at(idx)->region();
                    } else {
                        actual_frame = actual_frame->combined(actual_cell_guides.at(idx)->region());
                    }

                    ++idx;
                }
            }
        }

        this->_pop_notify_waiting();
    }

    if (actual_frame) {
        this->_actual_cells_layout_guide->set_region(actual_frame.value());
    } else {
        this->_cell_layout_guides->clear();

        float align_offset;

        switch (this->_alignment->value()) {
            case layout_alignment::min:
                align_offset = 0.0f;
                break;
            case layout_alignment::mid:
                align_offset = border_region.size.width * 0.5f;
                break;
            case layout_alignment::max:
                align_offset = border_region.size.width;
                break;
        }

        ui::region const aligned_region{.origin = {border_region.origin.x + align_offset, border_region.origin.y},
                                        .size = size::zero()};
        this->_actual_cells_layout_guide->set_region(this->_direction_swapped_region_if_horizontal(aligned_region));
    }

    if (actual_cell_guides.size() != this->_cell_layout_guides->size()) {
        this->_cell_layout_guides->replace(std::move(actual_cell_guides));
    }
}

std::optional<collection_layout::cell_location> collection_layout::_cell_location(std::size_t const cell_idx) {
    std::size_t top_idx = 0;
    std::size_t line_idx = 0;

    for (auto const &line : this->_lines->value()) {
        if (top_idx <= cell_idx && cell_idx < (top_idx + line.cell_sizes.size())) {
            return cell_location{.line_idx = line_idx, .cell_idx = cell_idx - top_idx};
        }
        top_idx += line.cell_sizes.size();
        ++line_idx;
    }

    return std::nullopt;
}

size collection_layout::_cell_size(std::size_t const idx) {
    std::size_t find_idx = 0;

    for (auto const &line : this->_lines->value()) {
        std::size_t const line_idx = idx - find_idx;
        std::size_t const line_cell_count = line.cell_sizes.size();

        if (line_idx < line_cell_count) {
            return line.cell_sizes.at(line_idx);
        }

        find_idx += line_cell_count;
    }

    return this->_default_cell_size->value();
}

bool collection_layout::_is_top_of_new_line(std::size_t const idx) {
    if (auto cell_location = this->_cell_location(idx)) {
        if (cell_location->line_idx > 0 && cell_location->cell_idx == 0) {
            return true;
        }
    }

    return false;
}

size collection_layout::_transformed_cell_size(std::size_t const idx) {
    size result;
    auto const &cell_size = _cell_size(idx);

    switch (this->_direction->value()) {
        case layout_direction::horizontal:
            result = size{cell_size.height, cell_size.width};
        case layout_direction::vertical:
            result = cell_size;
    }

    if (this->_row_order->value() == layout_order::descending) {
        result.height *= -1.0f;
    }

    if (this->_col_order->value() == layout_order::descending) {
        result.width *= -1.0;
    }

    if (result.width == 0) {
        result.width = this->_transformed_border_region().size.width;
    }

    return result;
}

float collection_layout::_transformed_col_diff(std::size_t const idx) {
    auto diff = fabsf(_transformed_cell_size(idx).width) + this->_col_spacing->value();
    if (this->_col_order->value() == layout_order::descending) {
        diff *= -1.0f;
    }
    return diff;
}

float collection_layout::_transformed_row_cell_diff(std::size_t const idx) {
    auto diff = fabsf(this->_transformed_cell_size(idx).height) + this->_row_spacing->value();
    if (this->_row_order->value() == layout_order::descending) {
        diff *= -1.0f;
    }
    return diff;
}

float collection_layout::_transformed_row_new_line_diff(std::size_t const idx) {
    auto diff = 0.0f;
    auto const &lines = this->_lines->value();

    if (auto cell_location = _cell_location(idx)) {
        auto line_idx = cell_location->line_idx;

        while (line_idx > 0) {
            --line_idx;

            diff += lines.at(line_idx).new_line_min_offset + this->_row_spacing->value();

            if (lines.at(line_idx).cell_sizes.size() > 0) {
                break;
            }
        }
    }

    if (this->_row_order->value() == layout_order::descending) {
        diff *= -1.0f;
    }

    return diff;
}

region collection_layout::_transformed_border_region() {
    auto const original = _direction_swapped_region_if_horizontal(this->_border_layout_guide->region());
    region result{.size = original.size};

    switch (this->_row_order->value()) {
        case layout_order::ascending: {
            result.origin.y = original.origin.y;
        } break;
        case layout_order::descending: {
            result.origin.y = original.origin.y + original.size.height;
            result.size.height *= -1.0f;
        } break;
    }

    switch (this->_col_order->value()) {
        case layout_order::ascending: {
            result.origin.x = original.origin.x;
        } break;
        case layout_order::descending: {
            result.origin.x = original.origin.x + original.size.width;
            result.size.width *= -1.0f;
        } break;
    }

    return result;
}

region collection_layout::_direction_swapped_region_if_horizontal(region const &region) {
    if (this->_direction->value() == layout_direction::horizontal) {
        return ui::region{.origin = {region.origin.y, region.origin.x},
                          .size = {region.size.height, region.size.width}};
    } else {
        return region;
    }
}

std::shared_ptr<collection_layout> collection_layout::make_shared() {
    return make_shared({});
}

std::shared_ptr<collection_layout> collection_layout::make_shared(args args) {
    return std::shared_ptr<collection_layout>(new collection_layout{std::move(args)});
}
