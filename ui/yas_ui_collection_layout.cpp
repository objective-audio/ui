//
//  yas_ui_collection_layout.cpp
//

#include "yas_delaying_caller.h"
#include "yas_each_index.h"
#include "yas_ui_collection_layout.h"
#include "yas_ui_layout.h"
#include "yas_ui_layout_guide.h"

using namespace yas;

#pragma mark - ui::colleciton_layout::impl

struct ui::collection_layout::impl : base::impl {
    struct line_cell_idx {
        std::size_t line_idx;
        std::size_t cell_idx;
    };

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
          _preferred_cell_count(args.preferred_cell_count),
          _default_cell_size(std::move(args.default_cell_size)),
          _lines(std::move(args.lines)),
          _row_spacing(args.row_spacing),
          _col_spacing(args.col_spacing),
          _alignment(args.alignment),
          _direction(args.direction),
          _row_order(args.row_order),
          _col_order(args.col_order),
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

        if (!_validate_default_cell_size()) {
            throw "invalid default_cell_size.";
        }

        if (!_validate_lines()) {
            throw "invalid lines.";
        }

        if (!_validate_row_spacing()) {
            throw "invalid row_spacing.";
        }

        if (!_validate_col_spacing()) {
            throw "invalid col_spacing.";
        }
    }

    void prepare(ui::collection_layout &layout) {
        _border_guide_rect.set_value_changed_handler([weak_layout = to_weak(layout)](auto const &) {
            if (auto layout = weak_layout.lock()) {
                layout.impl_ptr<impl>()->_update_layout();
            }
        });

        _update_layout();
    }

    void set_frame(ui::region &&frame) {
        if (_frame_guide_rect.region() != frame) {
            _frame_guide_rect.set_region(frame);

            _update_layout();

            if (_subject.has_observer()) {
                _subject.notify(ui::collection_layout::method::frame_changed, cast<ui::collection_layout>());
            }
        }
    }

    void set_preferred_cell_count(std::size_t const count) {
        if (_preferred_cell_count != count) {
            _preferred_cell_count = count;

            _update_layout();

            if (_subject.has_observer()) {
                _subject.notify(ui::collection_layout::method::preferred_cell_count_changed,
                                cast<ui::collection_layout>());
            }
        }
    }

    std::size_t const &preferred_cell_count() {
        return _preferred_cell_count;
    }

    void set_default_cell_size(ui::size &&size) {
        _default_cell_size = std::move(size);

        if (!_validate_default_cell_size()) {
            throw "invalid default_cell_size.";
        }

        _update_layout();

        if (_subject.has_observer()) {
            _subject.notify(ui::collection_layout::method::default_cell_size_changed, cast<ui::collection_layout>());
        }
    }

    ui::size &default_cell_size() {
        return _default_cell_size;
    }

    void set_lines(std::vector<ui::collection_layout::line> &&lines) {
        _lines = std::move(lines);

        if (!_validate_lines()) {
            throw "invalid lines.";
        }

        _update_layout();

        if (_subject.has_observer()) {
            _subject.notify(ui::collection_layout::method::lines_changed, cast<ui::collection_layout>());
        }
    }

    std::vector<ui::collection_layout::line> &lines() {
        return _lines;
    }

    void set_row_spacing(float const spacing) {
        if (_row_spacing != spacing) {
            _row_spacing = spacing;

            if (!_validate_row_spacing()) {
                throw "invalid row_spacing.";
            }

            _update_layout();

            if (_subject.has_observer()) {
                _subject.notify(ui::collection_layout::method::row_spacing_changed, cast<ui::collection_layout>());
            }
        }
    }

    float row_spacing() {
        return _row_spacing;
    }

    void set_col_spacing(float const spacing) {
        if (_col_spacing != spacing) {
            _col_spacing = spacing;

            if (!_validate_col_spacing()) {
                throw "invalid col_spacing.";
            }

            _update_layout();

            if (_subject.has_observer()) {
                _subject.notify(ui::collection_layout::method::col_spacing_changed, cast<ui::collection_layout>());
            }
        }
    }

    float col_spacing() {
        return _col_spacing;
    }

    void set_alignment(ui::layout_alignment &&align) {
        if (_alignment != align) {
            _alignment = std::move(align);

            _update_layout();

            if (_subject.has_observer()) {
                _subject.notify(ui::collection_layout::method::alignment_changed, cast<ui::collection_layout>());
            }
        }
    }

    ui::layout_alignment alignment() {
        return _alignment;
    }

    void set_direction(ui::layout_direction &&dir) {
        if (_direction != dir) {
            _direction = std::move(dir);

            _update_layout();

            if (_subject.has_observer()) {
                _subject.notify(ui::collection_layout::method::direction_changed, cast<ui::collection_layout>());
            }
        }
    }

    ui::layout_direction direction() {
        return _direction;
    }

    void set_row_order(ui::layout_order &&order) {
        if (_row_order != order) {
            _row_order = std::move(order);

            _update_layout();

            if (_subject.has_observer()) {
                _subject.notify(ui::collection_layout::method::row_order_changed, cast<ui::collection_layout>());
            }
        }
    }

    ui::layout_order row_order() {
        return _row_order;
    }

    void set_col_order(ui::layout_order &&order) {
        if (_col_order != order) {
            _col_order = std::move(order);

            _update_layout();

            if (_subject.has_observer()) {
                _subject.notify(ui::collection_layout::method::col_order_changed, cast<ui::collection_layout>());
            }
        }
    }

    ui::layout_order col_order() {
        return _col_order;
    }

    void push_notify_caller() {
        for (auto &rect : _cell_guide_rects) {
            rect.push_notify_caller();
        }
    }

    void pop_notify_caller() {
        for (auto &rect : _cell_guide_rects) {
            rect.pop_notify_caller();
        }
    }

   private:
    std::size_t _preferred_cell_count;
    ui::size _default_cell_size;
    std::vector<ui::collection_layout::line> _lines;
    float _row_spacing;
    float _col_spacing;
    ui::layout_alignment _alignment;
    ui::layout_direction _direction;
    ui::layout_order _row_order;
    ui::layout_order _col_order;

    void _update_layout() {
        auto frame_region = _direction_swapped_region_if_horizontal(_frame_guide_rect.region());

        if (_preferred_cell_count == 0 || frame_region.size.width == 0.0f) {
            _cell_guide_rects.clear();
            return;
        }

        auto const is_row_limiting = frame_region.size.height != 0;
        auto const border_rect = _transformed_border_rect();
        auto const border_abs_size = ui::size{fabsf(border_rect.size.width), fabsf(border_rect.size.height)};
        std::vector<std::vector<ui::region>> regions;
        float row_max_diff = 0.0f;
        ui::point origin = {.v = 0.0f};
        std::vector<ui::region> row_regions;
        auto const prev_actual_cell_count = _cell_guide_rects.size();
        std::size_t actual_cell_count = 0;

        for (auto const &idx : make_each(_preferred_cell_count)) {
            auto cell_size = _transformed_cell_size(idx);

            if (fabsf(origin.x + cell_size.width) > border_abs_size.width || _is_top_of_new_line(idx)) {
                regions.emplace_back(std::move(row_regions));

                auto const row_new_line_diff = _transformed_row_new_line_diff(idx);
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

            if (auto const row_cell_diff = _transformed_row_cell_diff(idx)) {
                if (std::fabsf(row_cell_diff) > std::fabs(row_max_diff)) {
                    row_max_diff = row_cell_diff;
                }
            }

            origin.x += _transformed_col_diff(idx);
        }

        if (row_regions.size() > 0) {
            regions.emplace_back(std::move(row_regions));
        }

        _cell_guide_rects.resize(actual_cell_count);

        push_notify_caller();

        std::size_t idx = 0;

        for (auto const &row_regions : regions) {
            if (row_regions.size() > 0) {
                auto align_offset = 0.0f;

                if (_alignment != ui::layout_alignment::min) {
                    auto const content_width =
                        row_regions.back().origin.x + row_regions.back().size.width - row_regions.front().origin.x;
                    align_offset = border_rect.size.width - content_width;

                    if (_alignment == ui::layout_alignment::mid) {
                        align_offset *= 0.5f;
                    }
                }

                for (auto const &region : row_regions) {
                    ui::region aligned_region{.origin = {region.origin.x + align_offset, region.origin.y},
                                              .size = region.size};
                    _cell_guide_rects.at(idx).set_region(_direction_swapped_region_if_horizontal(aligned_region));

                    ++idx;
                }
            }
        }

        pop_notify_caller();

        if (prev_actual_cell_count != actual_cell_count && _subject.has_observer()) {
            _subject.notify(ui::collection_layout::method::actual_cell_count_changed, cast<ui::collection_layout>());
        }
    }

    std::experimental::optional<line_cell_idx> _line_cell_idx(std::size_t const cell_idx) {
        std::size_t top_idx = 0;
        std::size_t line_idx = 0;

        for (auto const &line : _lines) {
            if (top_idx <= cell_idx && cell_idx < (top_idx + line.cell_sizes.size())) {
                return line_cell_idx{.line_idx = line_idx, .cell_idx = cell_idx - top_idx};
            }
            top_idx += line.cell_sizes.size();
            ++line_idx;
        }

        return nullopt;
    }

    ui::size _cell_size(std::size_t const idx) {
        std::size_t find_idx = 0;

        for (auto const &line : _lines) {
            std::size_t const line_idx = idx - find_idx;
            std::size_t const line_cell_count = line.cell_sizes.size();

            if (line_idx < line_cell_count) {
                return line.cell_sizes.at(line_idx);
            }

            find_idx += line_cell_count;
        }

        return _default_cell_size;
    }

    bool _is_top_of_new_line(std::size_t const idx) {
        if (auto line_cell_idx = _line_cell_idx(idx)) {
            if (line_cell_idx->line_idx > 0 && line_cell_idx->cell_idx == 0) {
                return true;
            }
        }

        return false;
    }

    ui::size _transformed_cell_size(std::size_t const idx) {
        ui::size result;
        auto const &cell_size = _cell_size(idx);

        switch (_direction) {
            case ui::layout_direction::horizontal:
                result = ui::size{cell_size.height, cell_size.width};
            case ui::layout_direction::vertical:
                result = cell_size;
        }

        if (_row_order == ui::layout_order::descending) {
            result.height *= -1.0f;
        }

        if (_col_order == ui::layout_order::descending) {
            result.width *= -1.0;
        }

        if (result.width == 0) {
            result.width = _transformed_border_rect().size.width;
        }

        return result;
    }

    float _transformed_col_diff(std::size_t const idx) {
        auto diff = fabsf(_transformed_cell_size(idx).width) + _col_spacing;
        if (_col_order == ui::layout_order::descending) {
            diff *= -1.0f;
        }
        return diff;
    }

    float _transformed_row_cell_diff(std::size_t const idx) {
        auto diff = fabsf(_transformed_cell_size(idx).height) + _row_spacing;
        if (_row_order == ui::layout_order::descending) {
            diff *= -1.0f;
        }
        return diff;
    }

    float _transformed_row_new_line_diff(std::size_t const idx) {
        auto diff = 0.0f;

        if (auto line_cell_idx = _line_cell_idx(idx)) {
            auto line_idx = line_cell_idx->line_idx;

            while (line_idx > 0) {
                --line_idx;

                diff += _lines.at(line_idx).new_line_min_offset + _row_spacing;

                if (_lines.at(line_idx).cell_sizes.size() > 0) {
                    break;
                }
            }
        }

        if (_row_order == ui::layout_order::descending) {
            diff *= -1.0f;
        }

        return diff;
    }

    ui::region _transformed_border_rect() {
        auto const original = _direction_swapped_region_if_horizontal(_border_guide_rect.region());
        ui::region result{.size = original.size};

        switch (_row_order) {
            case ui::layout_order::ascending: {
                result.origin.y = original.origin.y;
            } break;
            case ui::layout_order::descending: {
                result.origin.y = original.origin.y + original.size.height;
                result.size.height *= -1.0f;
            } break;
        }

        switch (_col_order) {
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
        if (_direction == ui::layout_direction::horizontal) {
            return ui::region{.origin = {region.origin.y, region.origin.x},
                              .size = {region.size.height, region.size.width}};
        } else {
            return region;
        }
    }

    bool _validate_lines() {
        for (auto const &line : _lines) {
            if (line.new_line_min_offset < 0.0f) {
                return false;
            }

            for (auto const &cell_size : line.cell_sizes) {
                if (cell_size.width < 0.0f || cell_size.height <= 0.0f) {
                    return false;
                }
            }
        }
        return true;
    }

    bool _validate_default_cell_size() {
        return _default_cell_size.width >= 0.0f && _default_cell_size.height >= 0.0f;
    }

    bool _validate_row_spacing() {
        return _row_spacing >= 0.0f;
    }

    bool _validate_col_spacing() {
        return _col_spacing >= 0.0f;
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

ui::region ui::collection_layout::frame() const {
    return impl_ptr<impl>()->_frame_guide_rect.region();
}

void ui::collection_layout::set_preferred_cell_count(std::size_t const count) {
    impl_ptr<impl>()->set_preferred_cell_count(count);
}

std::size_t ui::collection_layout::preferred_cell_count() const {
    return impl_ptr<impl>()->preferred_cell_count();
}

std::size_t ui::collection_layout::actual_cell_count() const {
    return impl_ptr<impl>()->_cell_guide_rects.size();
}

void ui::collection_layout::set_default_cell_size(ui::size size) {
    impl_ptr<impl>()->set_default_cell_size(std::move(size));
}

ui::size const &ui::collection_layout::default_cell_size() const {
    return impl_ptr<impl>()->default_cell_size();
}

void ui::collection_layout::set_lines(std::vector<ui::collection_layout::line> lines) {
    impl_ptr<impl>()->set_lines(std::move(lines));
}

std::vector<ui::collection_layout::line> const &ui::collection_layout::lines() const {
    return impl_ptr<impl>()->lines();
}

void ui::collection_layout::set_row_spacing(float const spacing) {
    impl_ptr<impl>()->set_row_spacing(spacing);
}

float ui::collection_layout::row_spacing() const {
    return impl_ptr<impl>()->row_spacing();
}

void ui::collection_layout::set_col_spacing(float const spacing) {
    impl_ptr<impl>()->set_col_spacing(spacing);
}

float ui::collection_layout::col_spacing() const {
    return impl_ptr<impl>()->col_spacing();
}

void ui::collection_layout::set_alignment(ui::layout_alignment align) {
    impl_ptr<impl>()->set_alignment(std::move(align));
}

ui::layout_alignment ui::collection_layout::alignment() const {
    return impl_ptr<impl>()->alignment();
}

void ui::collection_layout::set_direction(ui::layout_direction dir) {
    impl_ptr<impl>()->set_direction(std::move(dir));
}

ui::layout_direction ui::collection_layout::direction() const {
    return impl_ptr<impl>()->direction();
}

void ui::collection_layout::set_row_order(ui::layout_order order) {
    impl_ptr<impl>()->set_row_order(std::move(order));
}

ui::layout_order ui::collection_layout::row_order() const {
    return impl_ptr<impl>()->row_order();
}

void ui::collection_layout::set_col_order(ui::layout_order order) {
    impl_ptr<impl>()->set_col_order(std::move(order));
}

ui::layout_order ui::collection_layout::col_order() const {
    return impl_ptr<impl>()->col_order();
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
