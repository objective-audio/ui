//
//  yas_ui_layout_guide.cpp
//

#include "yas_ui_layout_guide.h"

#include <cpp-utils/yas_delaying_caller.h>

using namespace yas;
using namespace yas::ui;

#pragma mark - layout_value_guide

layout_value_guide::layout_value_guide(float const value)
    : _value(observing::value::holder<float>::make_shared(value)) {
}

void layout_value_guide::set_value(float const value) {
    this->_value->set_value(value);
}

float const &layout_value_guide::value() const {
    return this->_value->value();
}

void layout_value_guide::push_notify_waiting() {
    if (this->_wait_count->value() == 0) {
        this->_pushed_value = this->_value->value();
    }

    this->_wait_count->set_value(this->_wait_count->value() + 1);
}

void layout_value_guide::pop_notify_waiting() {
    this->_wait_count->set_value(this->_wait_count->value() - 1);

    if (this->_wait_count == 0) {
        this->_pushed_value = std::nullopt;
    }
}

observing::syncable layout_value_guide::observe(std::function<void(float const &)> &&handler) const {
    auto value_syncable = this->_value->observe([handler, this](float const &value) {
        if (this->_wait_count->value() == 0) {
            handler(value);
        }
    });

    auto wait_count_endable = this->_wait_count->observe([handler, this](int32_t const &count) {
        if (count == 0) {
            if (this->_pushed_value.has_value() && this->_pushed_value.value() == this->_value->value()) {
                return;
            }
            handler(this->_value->value());
        }
    });

    value_syncable.merge(std::move(wait_count_endable));

    return value_syncable;
}

void layout_value_guide::set_layout_value(float const value) {
    this->set_value(value);
}

observing::syncable layout_value_guide::observe_layout_value(std::function<void(float const &)> &&handler) {
    return this->observe(std::move(handler));
}

std::shared_ptr<layout_value_guide> layout_value_guide::make_shared() {
    return make_shared(0.0f);
}

std::shared_ptr<layout_value_guide> layout_value_guide::make_shared(float const value) {
    return std::shared_ptr<layout_value_guide>{new layout_value_guide{value}};
}

#pragma mark - layout_guide_point

layout_point_guide::layout_point_guide(ui::point &&origin)
    : _x_guide(layout_value_guide::make_shared(origin.x)), _y_guide(layout_value_guide::make_shared(origin.y)) {
}

std::shared_ptr<layout_value_guide> const &layout_point_guide::x() const {
    return this->_x_guide;
}

std::shared_ptr<layout_value_guide> const &layout_point_guide::y() const {
    return this->_y_guide;
}

void layout_point_guide::set_point(ui::point &&point) {
    this->push_notify_waiting();

    this->_x_guide->set_value(std::move(point.x));
    this->_y_guide->set_value(std::move(point.y));

    this->pop_notify_waiting();
}

void layout_point_guide::set_point(ui::point const &point) {
    this->push_notify_waiting();

    this->_x_guide->set_value(point.x);
    this->_y_guide->set_value(point.y);

    this->pop_notify_waiting();
}

point layout_point_guide::point() const {
    return ui::point{_x_guide->value(), _y_guide->value()};
}

void layout_point_guide::push_notify_waiting() {
    if (this->_wait_count->value() == 0) {
        this->_pushed_value = this->point();
    }

    this->_wait_count->set_value(this->_wait_count->value() + 1);

    this->_x_guide->push_notify_waiting();
    this->_y_guide->push_notify_waiting();
}

void layout_point_guide::pop_notify_waiting() {
    this->_x_guide->pop_notify_waiting();
    this->_y_guide->pop_notify_waiting();

    this->_wait_count->set_value(this->_wait_count->value() - 1);

    if (this->_wait_count == 0) {
        this->_pushed_value = std::nullopt;
    }
}

observing::syncable layout_point_guide::observe(std::function<void(ui::point const &)> &&handler) {
    auto x_endable = this->_x_guide
                         ->observe([this, handler](float const &) {
                             if (this->_wait_count->value() == 0) {
                                 handler(this->point());
                             }
                         })
                         .to_endable();
    auto y_syncable = this->_y_guide->observe([this, handler](float const &) {
        if (this->_wait_count->value() == 0) {
            handler(this->point());
        }
    });
    y_syncable.merge(std::move(x_endable));

    auto wait_count_endable = this->_wait_count->observe([handler, this](int32_t const &count) {
        if (count == 0) {
            if (this->_pushed_value.has_value() && this->_pushed_value.value() == this->point()) {
                return;
            }
            handler(this->point());
        }
    });

    y_syncable.merge(std::move(wait_count_endable));

    return y_syncable;
}

void layout_point_guide::set_layout_point(ui::point const &point) {
    this->set_point(point);
}

observing::syncable layout_point_guide::observe_layout_point(std::function<void(ui::point const &)> &&handler) {
    return this->observe(std::move(handler));
}

std::shared_ptr<layout_value_source> layout_point_guide::layout_x_value_source() {
    return this->_x_guide;
}

std::shared_ptr<layout_value_source> layout_point_guide::layout_y_value_source() {
    return this->_y_guide;
}

std::shared_ptr<layout_point_guide> layout_point_guide::make_shared() {
    return make_shared(ui::point{});
}

std::shared_ptr<layout_point_guide> layout_point_guide::make_shared(ui::point point) {
    return std::shared_ptr<layout_point_guide>(new layout_point_guide{std::move(point)});
}

#pragma mark - layout_guide_range

layout_range_guide::layout_range_guide(ui::range &&range)
    : _min_guide(layout_value_guide::make_shared(range.min())),
      _max_guide(layout_value_guide::make_shared(range.max())),
      _length_guide(layout_value_guide::make_shared(range.length)) {
    this->_min_canceller =
        this->_min_guide
            ->observe([this](float const &min) { this->_length_guide->set_value(this->max()->value() - min); })
            .end();
    this->_max_canceller =
        this->_max_guide
            ->observe([this](float const &max) { this->_length_guide->set_value(max - this->min()->value()); })
            .end();
}

std::shared_ptr<layout_value_guide> const &layout_range_guide::min() const {
    return this->_min_guide;
}

std::shared_ptr<layout_value_guide> const &layout_range_guide::max() const {
    return this->_max_guide;
}

std::shared_ptr<layout_value_guide const> layout_range_guide::length() const {
    return this->_length_guide;
}

void layout_range_guide::set_range(ui::range const &range) {
    this->push_notify_waiting();

    this->_min_guide->set_value(range.min());
    this->_max_guide->set_value(range.max());

    this->pop_notify_waiting();
}

range layout_range_guide::range() const {
    auto const &min = this->_min_guide->value();
    auto const &max = this->_max_guide->value();

    return ui::range{.location = min, .length = max - min};
}

void layout_range_guide::push_notify_waiting() {
    if (this->_wait_count->value() == 0) {
        this->_pushed_value = this->range();
    }

    this->_wait_count->set_value(this->_wait_count->value() + 1);

    this->_min_guide->push_notify_waiting();
    this->_max_guide->push_notify_waiting();
    this->_length_guide->push_notify_waiting();
}

void layout_range_guide::pop_notify_waiting() {
    this->_min_guide->pop_notify_waiting();
    this->_max_guide->pop_notify_waiting();
    this->_length_guide->pop_notify_waiting();

    this->_wait_count->set_value(this->_wait_count->value() - 1);

    if (this->_wait_count == 0) {
        this->_pushed_value = std::nullopt;
    }
}

observing::syncable layout_range_guide::observe(std::function<void(ui::range const &)> &&handler) {
    auto min_endable = this->_min_guide
                           ->observe([this, handler](float const &) {
                               if (this->_wait_count->value() == 0) {
                                   handler(this->range());
                               }
                           })
                           .to_endable();
    auto max_syncable = this->_max_guide->observe([this, handler](float const &) {
        if (this->_wait_count->value() == 0) {
            handler(this->range());
        }
    });
    max_syncable.merge(std::move(min_endable));

    auto wait_count_endable = this->_wait_count->observe([handler, this](int32_t const &count) {
        if (count == 0) {
            auto const range = this->range();
            if (this->_pushed_value.has_value() && this->_pushed_value.value() == range) {
                return;
            }
            handler(range);
        }
    });

    max_syncable.merge(std::move(wait_count_endable));

    return max_syncable;
}

void layout_range_guide::set_layout_range(ui::range const &range) {
    this->set_range(range);
}

observing::syncable layout_range_guide::observe_layout_range(std::function<void(ui::range const &)> &&handler) {
    return this->observe(std::move(handler));
}

std::shared_ptr<layout_value_source> layout_range_guide::layout_min_value_source() {
    return this->_min_guide;
}

std::shared_ptr<layout_value_source> layout_range_guide::layout_max_value_source() {
    return this->_max_guide;
}

std::shared_ptr<layout_value_source> layout_range_guide::layout_length_value_source() {
    return this->_length_guide;
}

std::shared_ptr<layout_range_guide> layout_range_guide::make_shared() {
    return make_shared(ui::range{});
}

std::shared_ptr<layout_range_guide> layout_range_guide::make_shared(ui::range range) {
    return std::shared_ptr<layout_range_guide>(new layout_range_guide{std::move(range)});
}

#pragma mark - layout_region_guide

layout_region_guide::layout_region_guide(region_ranges_args args)
    : _vertical_range(layout_range_guide::make_shared(std::move(args.vertical))),
      _horizontal_range(layout_range_guide::make_shared(std::move(args.horizontal))) {
}

layout_region_guide::layout_region_guide(ui::region region)
    : layout_region_guide({.horizontal = region.horizontal_range(), .vertical = region.vertical_range()}) {
}

std::shared_ptr<layout_range_guide> const &layout_region_guide::horizontal_range() const {
    return this->_horizontal_range;
}

std::shared_ptr<layout_range_guide> const &layout_region_guide::vertical_range() const {
    return this->_vertical_range;
}

std::shared_ptr<layout_value_guide> const &layout_region_guide::left() const {
    return this->horizontal_range()->min();
}

std::shared_ptr<layout_value_guide> const &layout_region_guide::right() const {
    return this->horizontal_range()->max();
}

std::shared_ptr<layout_value_guide> const &layout_region_guide::bottom() const {
    return this->vertical_range()->min();
}

std::shared_ptr<layout_value_guide> const &layout_region_guide::top() const {
    return this->vertical_range()->max();
}

std::shared_ptr<layout_value_guide const> layout_region_guide::width() const {
    return this->horizontal_range()->length();
}

std::shared_ptr<layout_value_guide const> layout_region_guide::height() const {
    return this->vertical_range()->length();
}

void layout_region_guide::set_horizontal_range(range &&range) {
    this->_horizontal_range->set_range(std::move(range));
}

void layout_region_guide::set_horizontal_range(ui::range const &range) {
    this->_horizontal_range->set_range(range);
}

void layout_region_guide::set_vertical_range(range &&range) {
    this->_vertical_range->set_range(std::move(range));
}

void layout_region_guide::set_vertical_range(range const &range) {
    this->_vertical_range->set_range(range);
}

void layout_region_guide::set_ranges(region_ranges_args &&args) {
    this->push_notify_waiting();

    this->set_vertical_range(std::move(args.vertical));
    this->set_horizontal_range(std::move(args.horizontal));

    this->pop_notify_waiting();
}

void layout_region_guide::set_region(ui::region const &region) {
    this->set_ranges({.vertical = region.vertical_range(), .horizontal = region.horizontal_range()});
}

region layout_region_guide::region() const {
    auto h_range = this->_horizontal_range->range();
    auto v_range = this->_vertical_range->range();

    return make_region({.horizontal = h_range, .vertical = v_range});
}

void layout_region_guide::push_notify_waiting() {
    if (this->_wait_count->value() == 0) {
        this->_pushed_value = this->region();
    }

    this->_wait_count->set_value(this->_wait_count->value() + 1);

    this->_vertical_range->push_notify_waiting();
    this->_horizontal_range->push_notify_waiting();
}

void layout_region_guide::pop_notify_waiting() {
    this->_vertical_range->pop_notify_waiting();
    this->_horizontal_range->pop_notify_waiting();

    this->_wait_count->set_value(this->_wait_count->value() - 1);

    if (this->_wait_count == 0) {
        this->_pushed_value = std::nullopt;
    }
}

observing::syncable layout_region_guide::observe(std::function<void(ui::region const &)> &&handler) {
    auto v_endable = this->_vertical_range
                         ->observe([this, handler](range const &) {
                             if (this->_wait_count->value() == 0) {
                                 handler(this->region());
                             }
                         })
                         .to_endable();
    auto h_syncable = this->_horizontal_range->observe([this, handler](range const &) {
        if (this->_wait_count->value() == 0) {
            handler(this->region());
        }
    });
    h_syncable.merge(std::move(v_endable));

    auto wait_count_endable = this->_wait_count->observe([handler, this](int32_t const &count) {
        if (count == 0) {
            auto const region = this->region();
            if (this->_pushed_value.has_value() && this->_pushed_value.value() == region) {
                return;
            }
            handler(region);
        }
    });

    h_syncable.merge(std::move(wait_count_endable));

    return h_syncable;
}

void layout_region_guide::set_layout_region(ui::region const &region) {
    this->set_region(region);
}

observing::syncable layout_region_guide::observe_layout_region(std::function<void(ui::region const &)> &&handler) {
    return this->observe(std::move(handler));
}

std::shared_ptr<layout_range_source> layout_region_guide::layout_horizontal_range_source() {
    return this->_horizontal_range;
}

std::shared_ptr<layout_range_source> layout_region_guide::layout_vertical_range_source() {
    return this->_vertical_range;
}

std::shared_ptr<layout_region_guide> layout_region_guide::make_shared() {
    return make_shared(region_ranges_args{.horizontal = {.v = 0.0f}, .vertical = {.v = 0.0f}});
}

std::shared_ptr<layout_region_guide> layout_region_guide::make_shared(region_ranges_args args) {
    return std::shared_ptr<layout_region_guide>(new layout_region_guide{std::move(args)});
}

std::shared_ptr<layout_region_guide> layout_region_guide::make_shared(ui::region region) {
    return make_shared({.horizontal = region.horizontal_range(), .vertical = region.vertical_range()});
}

#pragma mark - layout_guide_pair

std::vector<layout_value_guide_pair> ui::make_layout_guide_pairs(layout_point_guide_pair point_pair) {
    return {layout_value_guide_pair{.source = point_pair.source->x(), .destination = point_pair.destination->x()},
            layout_value_guide_pair{.source = point_pair.source->y(), .destination = point_pair.destination->y()}};
}

std::vector<layout_value_guide_pair> ui::make_layout_guide_pairs(layout_range_guide_pair range_pair) {
    return {layout_value_guide_pair{.source = range_pair.source->min(), .destination = range_pair.destination->min()},
            layout_value_guide_pair{.source = range_pair.source->max(), .destination = range_pair.destination->max()}};
}

std::vector<layout_value_guide_pair> ui::make_layout_guide_pairs(layout_region_guide_pair rect_pair) {
    return {
        layout_value_guide_pair{.source = rect_pair.source->left(), .destination = rect_pair.destination->left()},
        layout_value_guide_pair{.source = rect_pair.source->right(), .destination = rect_pair.destination->right()},
        layout_value_guide_pair{.source = rect_pair.source->bottom(), .destination = rect_pair.destination->bottom()},
        layout_value_guide_pair{.source = rect_pair.source->top(), .destination = rect_pair.destination->top()}};
}
