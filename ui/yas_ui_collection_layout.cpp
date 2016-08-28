//
//  yas_ui_collection_layout.cpp
//

#include "yas_delaying_caller.h"
#include "yas_each_index.h"
#include "yas_ui_collection_layout.h"
#include "yas_ui_fixed_layout.h"
#include "yas_ui_layout_guide.h"

using namespace yas;

#pragma mark - ui::colleciton_layout::impl

struct ui::collection_layout::impl : base::impl {
    ui::layout_guide_rect _frame_guide_rect;
    ui::layout_guide_rect _border_guide_rect;
    std::vector<ui::layout_guide_rect> _cell_guide_rects;
    ui::fixed_layout _left_border_layout;
    ui::fixed_layout _right_border_layout;
    ui::fixed_layout _bottom_border_layout;
    ui::fixed_layout _top_border_layout;
    subject_t _subject;

    impl(args &&args)
        : _frame_guide_rect(std::move(args.frame)),
          _preferred_cell_count(args.preferred_cell_count),
          _cell_sizes(std::move(args.cell_sizes)),
          _row_spacing(args.row_spacing),
          _col_spacing(args.col_spacing),
          _alignment(args.alignment),
          _direction(args.direction),
          _row_order(args.row_order),
          _col_order(args.col_order),
          _left_border_layout({.source_guide = _frame_guide_rect.left(),
                               .destination_guide = _border_guide_rect.left(),
                               .distance = args.borders.left}),
          _right_border_layout({.source_guide = _frame_guide_rect.right(),
                                .destination_guide = _border_guide_rect.right(),
                                .distance = -args.borders.right}),
          _bottom_border_layout({.source_guide = _frame_guide_rect.bottom(),
                                 .destination_guide = _border_guide_rect.bottom(),
                                 .distance = args.borders.bottom}),
          _top_border_layout({.source_guide = _frame_guide_rect.top(),
                              .destination_guide = _border_guide_rect.top(),
                              .distance = -args.borders.top}) {
        if (args.borders.left < 0 || args.borders.right < 0 || args.borders.bottom < 0 || args.borders.top < 0) {
            throw "borders value is negative.";
        }

        if (!_validate_cell_sizes()) {
            throw "invalid cell_sizes.";
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

    void set_frame(ui::float_region &&frame) {
        if (_frame_guide_rect.region() != frame) {
            _frame_guide_rect.set_region(frame);

            _update_layout();
        }
    }

    void set_preferred_cell_count(std::size_t const count) {
        if (_preferred_cell_count != count) {
            _preferred_cell_count = count;

            _update_layout();
        }
    }

    std::size_t const &preferred_cell_count() {
        return _preferred_cell_count;
    }

    void set_cell_sizes(std::vector<ui::float_size> &&sizes) {
        _cell_sizes = std::move(sizes);

        if (!_validate_cell_sizes()) {
            throw "invalid cell_sizes.";
        }

        _update_layout();
    }

    std::vector<ui::float_size> const &cell_sizes() {
        return _cell_sizes;
    }

    void set_row_spacing(float const spacing) {
        if (_row_spacing != spacing) {
            _row_spacing = spacing;

            if (!_validate_row_spacing()) {
                throw "invalid row_spacing.";
            }

            _update_layout();
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
        }
    }

    float col_spacing() {
        return _col_spacing;
    }

    void set_alignment(ui::layout_alignment &&align) {
        if (_alignment != align) {
            _alignment = std::move(align);

            _update_layout();
        }
    }

    ui::layout_alignment alignment() {
        return _alignment;
    }

    void set_direction(ui::layout_direction &&dir) {
        if (_direction != dir) {
            _direction = std::move(dir);

            _update_layout();
        }
    }

    ui::layout_direction direction() {
        return _direction;
    }

    void set_row_order(ui::layout_order &&order) {
        if (_row_order != order) {
            _row_order = std::move(order);

            _update_layout();
        }
    }

    ui::layout_order row_order() {
        return _row_order;
    }

    void set_col_order(ui::layout_order &&order) {
        if (_col_order != order) {
            _col_order = std::move(order);

            _update_layout();
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
    std::vector<ui::float_size> _cell_sizes;
    float _row_spacing;
    float _col_spacing;
    ui::layout_alignment _alignment;
    ui::layout_direction _direction;
    ui::layout_order _row_order;
    ui::layout_order _col_order;

    void _update_layout() {
        if (_preferred_cell_count == 0) {
            _cell_guide_rects.clear();
            return;
        }

        auto const border_rect = _transformed_border_rect();
        auto const border_abs_size = ui::float_size{fabsf(border_rect.size.width), fabsf(border_rect.size.height)};
        std::vector<std::vector<ui::float_region>> regions;
        float row_max_diff = 0.0f;
        ui::float_origin origin;
        std::vector<ui::float_region> row_regions;
        auto const prev_actual_cell_count = _cell_guide_rects.size();
        std::size_t actual_cell_count = 0;

        for (auto const &idx : make_each(_preferred_cell_count)) {
            auto cell_size = _transformed_cell_size(idx);

            if (fabsf(origin.x + cell_size.width) > border_abs_size.width) {
                if (row_regions.size() == 0) {
                    break;
                }

                regions.emplace_back(std::move(row_regions));

                origin.x = 0.0f;
                origin.y += row_max_diff;

                if (border_abs_size.height > 0.0f && fabsf(origin.y + cell_size.height) > border_abs_size.height) {
                    break;
                }

                row_regions.clear();
                row_max_diff = 0.0f;
            }

            row_regions.emplace_back(ui::float_region{
                .origin = {origin.x + border_rect.origin.x, origin.y + border_rect.origin.y}, .size = cell_size});

            ++actual_cell_count;

            if (auto const row_diff = _transformed_row_diff(idx)) {
                if (std::fabsf(row_diff) > row_max_diff) {
                    row_max_diff = row_diff;
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
                ui::float_region aligned_region{.origin = {region.origin.x + align_offset, region.origin.y},
                                                .size = region.size};
                _cell_guide_rects.at(idx).set_region(_swap_direction_if_horizontal(aligned_region));

                ++idx;
            }
        }

        pop_notify_caller();

        if (prev_actual_cell_count != actual_cell_count && _subject.has_observer()) {
            _subject.notify(ui::collection_layout::method::actual_cell_count_changed, cast<ui::collection_layout>());
        }
    }

    ui::float_size _transformed_cell_size(std::size_t const idx) {
        ui::float_size result;
        auto const &cell_size = _cell_sizes.at(idx % _cell_sizes.size());

        switch (_direction) {
            case ui::layout_direction::horizontal:
                result = ui::float_size{cell_size.height, cell_size.width};
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

    float _transformed_row_diff(std::size_t const idx) {
        auto diff = fabsf(_transformed_cell_size(idx).height) + _row_spacing;
        if (_row_order == ui::layout_order::descending) {
            diff *= -1.0f;
        }
        return diff;
    }

    ui::float_region _transformed_border_rect() {
        auto const original = _swap_direction_if_horizontal(_border_guide_rect.region());
        ui::float_region result{.size = original.size};

        switch (_row_order) {
            case ui::layout_order::ascending: {
                result.origin.y = original.bottom();
            } break;
            case ui::layout_order::descending: {
                result.origin.y = original.top();
                result.size.height *= -1.0f;
            } break;
        }

        switch (_col_order) {
            case ui::layout_order::ascending: {
                result.origin.x = original.left();
            } break;
            case ui::layout_order::descending: {
                result.origin.x = original.right();
                result.size.width *= -1.0f;
            } break;
        }

        return result;
    }

    ui::float_region _swap_direction_if_horizontal(ui::float_region const &region) {
        if (_direction == ui::layout_direction::horizontal) {
            return ui::float_region{.origin = {region.origin.y, region.origin.x},
                                    .size = {region.size.height, region.size.width}};
        } else {
            return region;
        }
    }

    bool _validate_cell_sizes() {
        for (auto const &cell_size : _cell_sizes) {
            if (cell_size.width < 0 || cell_size.height <= 0) {
                return false;
            }
        }
        return true;
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

void ui::collection_layout::set_frame(ui::float_region frame) {
    impl_ptr<impl>()->set_frame(std::move(frame));
}

ui::float_region ui::collection_layout::frame() const {
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

void ui::collection_layout::set_cell_sizes(std::vector<ui::float_size> sizes) {
    impl_ptr<impl>()->set_cell_sizes(std::move(sizes));
}

std::vector<ui::float_size> const &ui::collection_layout::cell_sizes() const {
    return impl_ptr<impl>()->cell_sizes();
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

void ui::collection_layout::set_borders(ui::layout_borders borders) {
    impl_ptr<impl>()->push_notify_caller();

    set_left_border(borders.left);
    set_right_border(borders.right);
    set_bottom_border(borders.bottom);
    set_top_border(borders.top);

    impl_ptr<impl>()->pop_notify_caller();
}

void ui::collection_layout::set_left_border(float const value) {
    if (value < 0) {
        throw "value is negative.";
    }

    impl_ptr<impl>()->_left_border_layout.set_distance(value);
}

void ui::collection_layout::set_right_border(float const value) {
    if (value < 0) {
        throw "value is negative.";
    }

    impl_ptr<impl>()->_right_border_layout.set_distance(-value);
}

void ui::collection_layout::set_bottom_border(float const value) {
    if (value < 0) {
        throw "value is negative.";
    }

    impl_ptr<impl>()->_bottom_border_layout.set_distance(value);
}

void ui::collection_layout::set_top_border(float const value) {
    if (value < 0) {
        throw "value is negative.";
    }

    impl_ptr<impl>()->_top_border_layout.set_distance(-value);
}

ui::layout_borders ui::collection_layout::borders() const {
    return ui::layout_borders{
        .left = left_border(), .right = right_border(), .bottom = bottom_border(), .top = top_border()};
}

float ui::collection_layout::left_border() const {
    return impl_ptr<impl>()->_left_border_layout.distance();
}

float ui::collection_layout::right_border() const {
    return -impl_ptr<impl>()->_right_border_layout.distance();
}

float ui::collection_layout::bottom_border() const {
    return impl_ptr<impl>()->_bottom_border_layout.distance();
}

float ui::collection_layout::top_border() const {
    return -impl_ptr<impl>()->_top_border_layout.distance();
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

#pragma mark - to_string

std::string yas::to_string(ui::layout_direction const &dir) {
    switch (dir) {
        case ui::layout_direction::horizontal:
            return "horizontal";
        case ui::layout_direction::vertical:
            return "vertical";
    }
}

std::string yas::to_string(ui::layout_order const &order) {
    switch (order) {
        case ui::layout_order::ascending:
            return "ascending";
        case ui::layout_order::descending:
            return "descending";
    }
}

std::string yas::to_string(ui::layout_alignment const &align) {
    switch (align) {
        case ui::layout_alignment::min:
            return "min";
        case ui::layout_alignment::mid:
            return "mid";
        case ui::layout_alignment::max:
            return "max";
    }
}

std::string yas::to_string(ui::layout_borders const &borders) {
    return "{left=" + std::to_string(borders.left) + ", right=" + std::to_string(borders.right) + ", bottom=" +
           std::to_string(borders.bottom) + ", top=" + std::to_string(borders.top) + "}";
}

#pragma mark - ostream

std::ostream &operator<<(std::ostream &os, yas::ui::layout_direction const &dir) {
    os << to_string(dir);
    return os;
}

std::ostream &operator<<(std::ostream &os, yas::ui::layout_order const &order) {
    os << to_string(order);
    return os;
}

std::ostream &operator<<(std::ostream &os, yas::ui::layout_alignment const &align) {
    os << to_string(align);
    return os;
}

std::ostream &operator<<(std::ostream &os, yas::ui::layout_borders const &borders) {
    os << to_string(borders);
    return os;
}

bool operator==(yas::ui::layout_borders const &lhs, yas::ui::layout_borders const &rhs) {
    return lhs.left == rhs.left && lhs.right == rhs.right && lhs.bottom == rhs.bottom && lhs.top == rhs.top;
}

bool operator!=(yas::ui::layout_borders const &lhs, yas::ui::layout_borders const &rhs) {
    return lhs.left != rhs.left || lhs.right != rhs.right || lhs.bottom != rhs.bottom || lhs.top != rhs.top;
}
