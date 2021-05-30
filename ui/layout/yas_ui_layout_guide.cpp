//
//  yas_ui_layout_guide.cpp
//

#include "yas_ui_layout_guide.h"

#include <cpp_utils/yas_delaying_caller.h>

using namespace yas;
using namespace yas::ui;

#pragma mark - layout_guide

layout_guide::layout_guide(float const value) : _value(observing::value::holder<float>::make_shared(value)) {
}

layout_guide::~layout_guide() = default;

void layout_guide::set_value(float const value) {
    this->_value->set_value(value);
}

float const &layout_guide::value() const {
    return this->_value->value();
}

void layout_guide::push_notify_waiting() {
    if (this->_wait_count->value() == 0) {
        this->_pushed_value = this->_value->value();
    }

    this->_wait_count->set_value(this->_wait_count->value() + 1);
}

void layout_guide::pop_notify_waiting() {
    this->_wait_count->set_value(this->_wait_count->value() - 1);

    if (this->_wait_count == 0) {
        this->_pushed_value = std::nullopt;
    }
}

observing::syncable layout_guide::observe(observing::caller<float>::handler_f &&handler) {
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

std::shared_ptr<layout_guide> layout_guide::make_shared() {
    return make_shared(0.0f);
}

std::shared_ptr<layout_guide> layout_guide::make_shared(float const value) {
    return std::shared_ptr<layout_guide>{new layout_guide{value}};
}

#pragma mark - layout_guide_point

layout_guide_point::layout_guide_point(ui::point &&origin)
    : _x_guide(layout_guide::make_shared(origin.x)), _y_guide(layout_guide::make_shared(origin.y)) {
}

layout_guide_point::~layout_guide_point() = default;

std::shared_ptr<layout_guide> &layout_guide_point::x() {
    return this->_x_guide;
}

std::shared_ptr<layout_guide> &layout_guide_point::y() {
    return this->_y_guide;
}

std::shared_ptr<layout_guide> const &layout_guide_point::x() const {
    return this->_x_guide;
}

std::shared_ptr<layout_guide> const &layout_guide_point::y() const {
    return this->_y_guide;
}

void layout_guide_point::set_point(ui::point point) {
    this->push_notify_waiting();

    this->_x_guide->set_value(std::move(point.x));
    this->_y_guide->set_value(std::move(point.y));

    this->pop_notify_waiting();
}

point layout_guide_point::point() const {
    return ui::point{_x_guide->value(), _y_guide->value()};
}

void layout_guide_point::push_notify_waiting() {
    this->_x_guide->push_notify_waiting();
    this->_y_guide->push_notify_waiting();
}

void layout_guide_point::pop_notify_waiting() {
    this->_x_guide->pop_notify_waiting();
    this->_y_guide->pop_notify_waiting();
}

observing::syncable layout_guide_point::observe(observing::caller<ui::point>::handler_f &&handler) {
    auto x_endable = this->_x_guide->observe([this, handler](float const &) { handler(this->point()); }).to_endable();
    auto y_syncable = this->_y_guide->observe([this, handler](float const &) { handler(this->point()); });
    y_syncable.merge(std::move(x_endable));
    return y_syncable;
}

std::shared_ptr<layout_guide_point> layout_guide_point::make_shared() {
    return make_shared(ui::point{});
}

std::shared_ptr<layout_guide_point> layout_guide_point::make_shared(ui::point point) {
    return std::shared_ptr<layout_guide_point>(new layout_guide_point{std::move(point)});
}

#pragma mark - layout_guide_range

layout_guide_range::layout_guide_range(ui::range &&range)
    : _min_guide(layout_guide::make_shared(range.min())),
      _max_guide(layout_guide::make_shared(range.max())),
      _length_guide(layout_guide::make_shared(range.length)) {
    this->_min_canceller =
        this->_min_guide
            ->observe([this](float const &min) { this->_length_guide->set_value(this->max()->value() - min); })
            .end();
    this->_max_canceller =
        this->_max_guide
            ->observe([this](float const &max) { this->_length_guide->set_value(max - this->min()->value()); })
            .end();
}

layout_guide_range::~layout_guide_range() = default;

std::shared_ptr<layout_guide> &layout_guide_range::min() {
    return this->_min_guide;
}

std::shared_ptr<layout_guide> &layout_guide_range::max() {
    return this->_max_guide;
}

std::shared_ptr<layout_guide> const &layout_guide_range::min() const {
    return this->_min_guide;
}

std::shared_ptr<layout_guide> const &layout_guide_range::max() const {
    return this->_max_guide;
}

std::shared_ptr<layout_guide> const &layout_guide_range::length() const {
    return this->_length_guide;
}

void layout_guide_range::set_range(ui::range const &range) {
    this->push_notify_waiting();

    this->_min_guide->set_value(range.min());
    this->_max_guide->set_value(range.max());

    this->pop_notify_waiting();
}

range layout_guide_range::range() const {
    auto const &min = this->_min_guide->value();
    auto const &max = this->_max_guide->value();

    return ui::range{.location = min, .length = max - min};
}

void layout_guide_range::push_notify_waiting() {
    this->_min_guide->push_notify_waiting();
    this->_max_guide->push_notify_waiting();
    this->_length_guide->push_notify_waiting();
}

void layout_guide_range::pop_notify_waiting() {
    this->_min_guide->pop_notify_waiting();
    this->_max_guide->pop_notify_waiting();
    this->_length_guide->pop_notify_waiting();
}

observing::syncable layout_guide_range::observe(observing::caller<ui::range>::handler_f &&handler) {
    auto min_endable =
        this->_min_guide->observe([this, handler](float const &) { handler(this->range()); }).to_endable();
    auto max_syncable = this->_max_guide->observe([this, handler](float const &) { handler(this->range()); });
    max_syncable.merge(std::move(min_endable));
    return max_syncable;
}

std::shared_ptr<layout_guide_range> layout_guide_range::make_shared() {
    return make_shared(ui::range{});
}

std::shared_ptr<layout_guide_range> layout_guide_range::make_shared(ui::range range) {
    return std::shared_ptr<layout_guide_range>(new layout_guide_range{std::move(range)});
}

#pragma mark - layout_guide_rect

layout_guide_rect::layout_guide_rect(region_ranges_args args)
    : _vertical_range(layout_guide_range::make_shared(std::move(args.vertical))),
      _horizontal_range(layout_guide_range::make_shared(std::move(args.horizontal))) {
}

layout_guide_rect::layout_guide_rect(ui::region region)
    : layout_guide_rect({.horizontal = region.horizontal_range(), .vertical = region.vertical_range()}) {
}

layout_guide_rect::~layout_guide_rect() = default;

std::shared_ptr<layout_guide_range> &layout_guide_rect::horizontal_range() {
    return this->_horizontal_range;
}

std::shared_ptr<layout_guide_range> &layout_guide_rect::vertical_range() {
    return this->_vertical_range;
}

std::shared_ptr<layout_guide_range> const &layout_guide_rect::horizontal_range() const {
    return this->_horizontal_range;
}

std::shared_ptr<layout_guide_range> const &layout_guide_rect::vertical_range() const {
    return this->_vertical_range;
}

std::shared_ptr<layout_guide> &layout_guide_rect::left() {
    return this->horizontal_range()->min();
}

std::shared_ptr<layout_guide> &layout_guide_rect::right() {
    return this->horizontal_range()->max();
}

std::shared_ptr<layout_guide> &layout_guide_rect::bottom() {
    return this->vertical_range()->min();
}

std::shared_ptr<layout_guide> &layout_guide_rect::top() {
    return this->vertical_range()->max();
}

std::shared_ptr<layout_guide> const &layout_guide_rect::left() const {
    return this->horizontal_range()->min();
}

std::shared_ptr<layout_guide> const &layout_guide_rect::right() const {
    return this->horizontal_range()->max();
}

std::shared_ptr<layout_guide> const &layout_guide_rect::bottom() const {
    return this->vertical_range()->min();
}

std::shared_ptr<layout_guide> const &layout_guide_rect::top() const {
    return this->vertical_range()->max();
}

std::shared_ptr<layout_guide> const &layout_guide_rect::width() const {
    return this->horizontal_range()->length();
}

std::shared_ptr<layout_guide> const &layout_guide_rect::height() const {
    return this->vertical_range()->length();
}

void layout_guide_rect::set_horizontal_range(range range) {
    this->_horizontal_range->set_range(std::move(range));
}

void layout_guide_rect::set_vertical_range(range range) {
    this->_vertical_range->set_range(std::move(range));
}

void layout_guide_rect::set_ranges(region_ranges_args args) {
    this->push_notify_waiting();

    this->set_vertical_range(std::move(args.vertical));
    this->set_horizontal_range(std::move(args.horizontal));

    this->pop_notify_waiting();
}

void layout_guide_rect::set_region(ui::region const &region) {
    this->set_ranges({.vertical = region.vertical_range(), .horizontal = region.horizontal_range()});
}

region layout_guide_rect::region() const {
    auto h_range = this->_horizontal_range->range();
    auto v_range = this->_vertical_range->range();

    return make_region({.horizontal = h_range, .vertical = v_range});
}

void layout_guide_rect::push_notify_waiting() {
    this->_vertical_range->push_notify_waiting();
    this->_horizontal_range->push_notify_waiting();
}

void layout_guide_rect::pop_notify_waiting() {
    this->_vertical_range->pop_notify_waiting();
    this->_horizontal_range->pop_notify_waiting();
}

observing::syncable layout_guide_rect::observe(observing::caller<ui::region>::handler_f &&handler) {
    auto v_endable =
        this->_vertical_range->observe([this, handler](range const &) { handler(this->region()); }).to_endable();
    auto h_syncable = this->_horizontal_range->observe([this, handler](range const &) { handler(this->region()); });
    h_syncable.merge(std::move(v_endable));
    return h_syncable;
}

std::shared_ptr<layout_guide_rect> layout_guide_rect::make_shared() {
    return make_shared(region_ranges_args{.horizontal = {.v = 0.0f}, .vertical = {.v = 0.0f}});
}

std::shared_ptr<layout_guide_rect> layout_guide_rect::make_shared(region_ranges_args args) {
    return std::shared_ptr<layout_guide_rect>(new layout_guide_rect{std::move(args)});
}

std::shared_ptr<layout_guide_rect> layout_guide_rect::make_shared(ui::region region) {
    return make_shared({.horizontal = region.horizontal_range(), .vertical = region.vertical_range()});
}

#pragma mark - layout_guide_pair

std::vector<layout_guide_pair> ui::make_layout_guide_pairs(layout_guide_point_pair point_pair) {
    return {layout_guide_pair{.source = point_pair.source->x(), .destination = point_pair.destination->x()},
            layout_guide_pair{.source = point_pair.source->y(), .destination = point_pair.destination->y()}};
}

std::vector<layout_guide_pair> ui::make_layout_guide_pairs(layout_guide_range_pair range_pair) {
    return {layout_guide_pair{.source = range_pair.source->min(), .destination = range_pair.destination->min()},
            layout_guide_pair{.source = range_pair.source->max(), .destination = range_pair.destination->max()}};
}

std::vector<layout_guide_pair> ui::make_layout_guide_pairs(layout_guide_rect_pair rect_pair) {
    return {layout_guide_pair{.source = rect_pair.source->left(), .destination = rect_pair.destination->left()},
            layout_guide_pair{.source = rect_pair.source->right(), .destination = rect_pair.destination->right()},
            layout_guide_pair{.source = rect_pair.source->bottom(), .destination = rect_pair.destination->bottom()},
            layout_guide_pair{.source = rect_pair.source->top(), .destination = rect_pair.destination->top()}};
}
