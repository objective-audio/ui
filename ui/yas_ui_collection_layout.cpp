//
//  yas_ui_collection_layout.cpp
//

#include "yas_delaying_caller.h"
#include "yas_property.h"
#include "yas_ui_collection_layout.h"
#include "yas_ui_layout.h"
#include "yas_ui_layout_guide.h"
#include "yas_fast_each.h"

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

    property<float> _row_spacing_property;
    property<float> _col_spacing_property;
    property<ui::layout_alignment> _alignment_property;
    property<ui::layout_direction> _direction_property;
    property<ui::layout_order> _row_order_property;
    property<ui::layout_order> _col_order_property;
    property<std::size_t> _preferred_cell_count_property;
    property<ui::size> _default_cell_size_property;
    property<std::vector<ui::collection_layout::line>> _lines_property;

    ui::layout_guide_rect _frame_guide_rect;
    ui::layout_guide_rect _border_guide_rect;
    std::vector<ui::layout_guide_rect> _cell_guide_rects;
    ui::layout _left_border_layout;
    ui::layout _right_border_layout;
    ui::layout _bottom_border_layout;
    ui::layout _top_border_layout;
    ui::layout_borders const _borders;
    subject_t _subject;

    impl(args &&args)
        : _frame_guide_rect(std::move(args.frame)),
          _preferred_cell_count_property({.value = args.preferred_cell_count}),
          _default_cell_size_property(
              {.value = std::move(args.default_cell_size),
               .validator = [](auto const &value) { return value.width >= 0.0f && value.height >= 0.0f; }}),
          _lines_property({.value = std::move(args.lines),
                           .validator =
                               [](auto const &value) {
                                   for (auto const &line : value) {
                                       if (line.new_line_min_offset < 0.0f) {
                                           return false;
                                       }

                                       for (auto const &cell_size : line.cell_sizes) {
                                           if (cell_size.width < 0.0f || cell_size.height < 0.0f) {
                                               return false;
                                           }
                                       }
                                   }
                                   return true;
                               }}),
          _row_spacing_property(
              {.value = args.row_spacing, .validator = [](auto const &value) { return value >= 0.0f; }}),
          _col_spacing_property(
              {.value = args.col_spacing, .validator = [](auto const &value) { return value >= 0.0f; }}),
          _alignment_property({.value = args.alignment}),
          _direction_property({.value = args.direction}),
          _row_order_property({.value = args.row_order}),
          _col_order_property({.value = args.col_order}),
          _left_border_layout(ui::make_layout({.source_guide = _frame_guide_rect.left(),
                                               .destination_guide = _border_guide_rect.left(),
                                               .distance = args.borders.left})),
          _right_border_layout(ui::make_layout({.source_guide = _frame_guide_rect.right(),
                                                .destination_guide = _border_guide_rect.right(),
                                                .distance = -args.borders.right})),
          _bottom_border_layout(ui::make_layout({.source_guide = _frame_guide_rect.bottom(),
                                                 .destination_guide = _border_guide_rect.bottom(),
                                                 .distance = args.borders.bottom})),
          _top_border_layout(ui::make_layout({.source_guide = _frame_guide_rect.top(),
                                              .destination_guide = _border_guide_rect.top(),
                                              .distance = -args.borders.top})),
          _borders(std::move(args.borders)) {
        if (args.borders.left < 0 || args.borders.right < 0 || args.borders.bottom < 0 || args.borders.top < 0) {
            throw "borders value is negative.";
        }
    }

    void prepare(ui::collection_layout &layout) {
        this->_border_guide_rect.set_value_changed_handler([weak_layout = to_weak(layout)](auto const &) {
            if (auto layout = weak_layout.lock()) {
                layout.impl_ptr<impl>()->_update_layout();
            }
        });

        auto weak_layout = to_weak(layout);

        auto property_handler = [weak_layout](ui::collection_layout::method const &method) {
            if (auto layout = weak_layout.lock()) {
                auto layout_impl = layout.impl_ptr<impl>();
                layout_impl->_update_layout();
                layout_impl->_subject.notify(method, layout);
            }
        };

        this->_property_observers.emplace_back(_row_spacing_property.subject().make_observer(
            property_method::did_change, [property_handler](auto const &context) {
                property_handler(ui::collection_layout::method::row_spacing_changed);
            }));

        this->_property_observers.emplace_back(_col_spacing_property.subject().make_observer(
            property_method::did_change, [property_handler](auto const &context) {
                property_handler(ui::collection_layout::method::col_spacing_changed);
            }));

        this->_property_observers.emplace_back(_alignment_property.subject().make_observer(
            property_method::did_change, [property_handler](auto const &context) {
                property_handler(ui::collection_layout::method::alignment_changed);
            }));

        this->_property_observers.emplace_back(_direction_property.subject().make_observer(
            property_method::did_change, [property_handler](auto const &context) {
                property_handler(ui::collection_layout::method::direction_changed);
            }));

        this->_property_observers.emplace_back(_row_order_property.subject().make_observer(
            property_method::did_change, [property_handler](auto const &context) {
                property_handler(ui::collection_layout::method::row_order_changed);
            }));

        this->_property_observers.emplace_back(_col_order_property.subject().make_observer(
            property_method::did_change, [property_handler](auto const &context) {
                property_handler(ui::collection_layout::method::col_order_changed);
            }));

        this->_property_observers.emplace_back(_preferred_cell_count_property.subject().make_observer(
            property_method::did_change, [property_handler](auto const &context) {
                property_handler(ui::collection_layout::method::preferred_cell_count_changed);
            }));

        this->_property_observers.emplace_back(_default_cell_size_property.subject().make_observer(
            property_method::did_change, [property_handler](auto const &context) {
                property_handler(ui::collection_layout::method::default_cell_size_changed);
            }));

        this->_property_observers.emplace_back(_lines_property.subject().make_observer(
            property_method::did_change, [property_handler](auto const &context) {
                property_handler(ui::collection_layout::method::lines_changed);
            }));

        this->_update_layout();
    }

    void set_frame(ui::region &&frame) {
        if (this->_frame_guide_rect.region() != frame) {
            this->_frame_guide_rect.set_region(std::move(frame));

            this->_update_layout();
            this->_subject.notify(ui::collection_layout::method::frame_changed, cast<ui::collection_layout>());
        }
    }

    void push_notify_caller() {
        for (auto &rect : this->_cell_guide_rects) {
            rect.push_notify_caller();
        }
    }

    void pop_notify_caller() {
        for (auto &rect : this->_cell_guide_rects) {
            rect.pop_notify_caller();
        }
    }

   private:
    std::vector<base> _property_observers;

    void _update_layout() {
        auto frame_region = this->_direction_swapped_region_if_horizontal(this->_frame_guide_rect.region());
        auto const &preferred_cell_count = this->_preferred_cell_count_property.value();

        if (preferred_cell_count == 0) {
            this->_cell_guide_rects.clear();
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

        this->push_notify_caller();

        std::size_t idx = 0;

        for (auto const &row_regions : regions) {
            if (row_regions.size() > 0) {
                auto align_offset = 0.0f;
                auto const alignment = this->_alignment_property.value();

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

        this->pop_notify_caller();

        if (prev_actual_cell_count != actual_cell_count) {
            this->_subject.notify(ui::collection_layout::method::actual_cell_count_changed,
                                  cast<ui::collection_layout>());
        }
    }

    std::experimental::optional<cell_location> _cell_location(std::size_t const cell_idx) {
        std::size_t top_idx = 0;
        std::size_t line_idx = 0;

        for (auto const &line : _lines_property.value()) {
            if (top_idx <= cell_idx && cell_idx < (top_idx + line.cell_sizes.size())) {
                return cell_location{.line_idx = line_idx, .cell_idx = cell_idx - top_idx};
            }
            top_idx += line.cell_sizes.size();
            ++line_idx;
        }

        return nullopt;
    }

    ui::size _cell_size(std::size_t const idx) {
        std::size_t find_idx = 0;

        for (auto const &line : this->_lines_property.value()) {
            std::size_t const line_idx = idx - find_idx;
            std::size_t const line_cell_count = line.cell_sizes.size();

            if (line_idx < line_cell_count) {
                return line.cell_sizes.at(line_idx);
            }

            find_idx += line_cell_count;
        }

        return this->_default_cell_size_property.value();
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

        switch (this->_direction_property.value()) {
            case ui::layout_direction::horizontal:
                result = ui::size{cell_size.height, cell_size.width};
            case ui::layout_direction::vertical:
                result = cell_size;
        }

        if (this->_row_order_property.value() == ui::layout_order::descending) {
            result.height *= -1.0f;
        }

        if (this->_col_order_property.value() == ui::layout_order::descending) {
            result.width *= -1.0;
        }

        if (result.width == 0) {
            result.width = this->_transformed_border_rect().size.width;
        }

        return result;
    }

    float _transformed_col_diff(std::size_t const idx) {
        auto diff = fabsf(_transformed_cell_size(idx).width) + this->_col_spacing_property.value();
        if (this->_col_order_property.value() == ui::layout_order::descending) {
            diff *= -1.0f;
        }
        return diff;
    }

    float _transformed_row_cell_diff(std::size_t const idx) {
        auto diff = fabsf(this->_transformed_cell_size(idx).height) + this->_row_spacing_property.value();
        if (this->_row_order_property.value() == ui::layout_order::descending) {
            diff *= -1.0f;
        }
        return diff;
    }

    float _transformed_row_new_line_diff(std::size_t const idx) {
        auto diff = 0.0f;
        auto const &lines = this->_lines_property.value();

        if (auto cell_location = _cell_location(idx)) {
            auto line_idx = cell_location->line_idx;

            while (line_idx > 0) {
                --line_idx;

                diff += lines.at(line_idx).new_line_min_offset + this->_row_spacing_property.value();

                if (lines.at(line_idx).cell_sizes.size() > 0) {
                    break;
                }
            }
        }

        if (this->_row_order_property.value() == ui::layout_order::descending) {
            diff *= -1.0f;
        }

        return diff;
    }

    ui::region _transformed_border_rect() {
        auto const original = _direction_swapped_region_if_horizontal(this->_border_guide_rect.region());
        ui::region result{.size = original.size};

        switch (this->_row_order_property.value()) {
            case ui::layout_order::ascending: {
                result.origin.y = original.origin.y;
            } break;
            case ui::layout_order::descending: {
                result.origin.y = original.origin.y + original.size.height;
                result.size.height *= -1.0f;
            } break;
        }

        switch (this->_col_order_property.value()) {
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
        if (this->_direction_property.value() == ui::layout_direction::horizontal) {
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
    impl_ptr<impl>()->_preferred_cell_count_property.set_value(count);
}

ui::region ui::collection_layout::frame() const {
    return impl_ptr<impl>()->_frame_guide_rect.region();
}

void ui::collection_layout::set_default_cell_size(ui::size size) {
    impl_ptr<impl>()->_default_cell_size_property.set_value(std::move(size));
}

void ui::collection_layout::set_lines(std::vector<ui::collection_layout::line> lines) {
    impl_ptr<impl>()->_lines_property.set_value(std::move(lines));
}

void ui::collection_layout::set_row_spacing(float const spacing) {
    impl_ptr<impl>()->_row_spacing_property.set_value(spacing);
}

void ui::collection_layout::set_col_spacing(float const spacing) {
    impl_ptr<impl>()->_col_spacing_property.set_value(spacing);
}

void ui::collection_layout::set_alignment(ui::layout_alignment const align) {
    impl_ptr<impl>()->_alignment_property.set_value(align);
}

void ui::collection_layout::set_direction(ui::layout_direction const dir) {
    impl_ptr<impl>()->_direction_property.set_value(dir);
}

void ui::collection_layout::set_row_order(ui::layout_order const order) {
    impl_ptr<impl>()->_row_order_property.set_value(order);
}

void ui::collection_layout::set_col_order(ui::layout_order const order) {
    impl_ptr<impl>()->_col_order_property.set_value(order);
}

std::size_t const &ui::collection_layout::preferred_cell_count() const {
    return impl_ptr<impl>()->_preferred_cell_count_property.value();
}

std::size_t ui::collection_layout::actual_cell_count() const {
    return impl_ptr<impl>()->_cell_guide_rects.size();
}

ui::size const &ui::collection_layout::default_cell_size() const {
    return impl_ptr<impl>()->_default_cell_size_property.value();
}

std::vector<ui::collection_layout::line> const &ui::collection_layout::lines() const {
    return impl_ptr<impl>()->_lines_property.value();
}

float const &ui::collection_layout::row_spacing() const {
    return impl_ptr<impl>()->_row_spacing_property.value();
}

float const &ui::collection_layout::col_spacing() const {
    return impl_ptr<impl>()->_col_spacing_property.value();
}

ui::layout_alignment const &ui::collection_layout::alignment() const {
    return impl_ptr<impl>()->_alignment_property.value();
}

ui::layout_direction const &ui::collection_layout::direction() const {
    return impl_ptr<impl>()->_direction_property.value();
}

ui::layout_order const &ui::collection_layout::row_order() const {
    return impl_ptr<impl>()->_row_order_property.value();
}

ui::layout_order const &ui::collection_layout::col_order() const {
    return impl_ptr<impl>()->_col_order_property.value();
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

ui::collection_layout::subject_t &ui::collection_layout::subject() {
    return impl_ptr<impl>()->_subject;
}
