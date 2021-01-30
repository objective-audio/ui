//
//  yas_ui_layout_guide.cpp
//

#include "yas_ui_layout_guide.h"

#include <cpp_utils/yas_delaying_caller.h>

using namespace yas;

#pragma mark - ui::layout_guide

ui::layout_guide::layout_guide(float const value) : _value(observing::value::holder<float>::make_shared(value)) {
}

ui::layout_guide::~layout_guide() = default;

void ui::layout_guide::set_value(float const value) {
    this->_value->set_value(value);
}

float const &ui::layout_guide::value() const {
    return this->_value->value();
}

void ui::layout_guide::push_notify_waiting() {
    if (this->_wait_count->value() == 0) {
        this->_pushed_value = this->_value->value();
    }

    this->_wait_count->set_value(this->_wait_count->value() + 1);
}

void ui::layout_guide::pop_notify_waiting() {
    this->_wait_count->set_value(this->_wait_count->value() - 1);

    if (this->_wait_count == 0) {
        this->_pushed_value = std::nullopt;
    }
}

observing::cancellable_ptr ui::layout_guide::observe(observing::caller<float>::handler_f &&handler, bool const sync) {
    auto pool = observing::canceller_pool::make_shared();

    this->_value
        ->observe(
            [handler, this](float const &value) {
                if (this->_wait_count->value() == 0) {
                    handler(value);
                }
            },
            sync)
        ->add_to(*pool);

    this->_wait_count
        ->observe(
            [handler, this](int32_t const &count) {
                if (count == 0) {
                    if (this->_pushed_value.has_value() && this->_pushed_value.value() == this->_value->value()) {
                        return;
                    }
                    handler(this->_value->value());
                }
            },
            false)
        ->add_to(*pool);

    return pool;
}

void ui::layout_guide::_prepare(std::shared_ptr<layout_guide> &guide) {
    this->_weak_ptr = guide;
}

std::shared_ptr<ui::layout_guide> ui::layout_guide::make_shared() {
    return make_shared(0.0f);
}

std::shared_ptr<ui::layout_guide> ui::layout_guide::make_shared(float const value) {
    auto shared = std::shared_ptr<layout_guide>{new layout_guide{value}};
    shared->_prepare(shared);
    return shared;
}

#pragma mark - ui::layout_guide_point

ui::layout_guide_point::layout_guide_point(ui::point &&origin)
    : _x_guide(layout_guide::make_shared(origin.x)), _y_guide(layout_guide::make_shared(origin.y)) {
}

ui::layout_guide_point::~layout_guide_point() = default;

ui::layout_guide_ptr &ui::layout_guide_point::x() {
    return this->_x_guide;
}

ui::layout_guide_ptr &ui::layout_guide_point::y() {
    return this->_y_guide;
}

ui::layout_guide_ptr const &ui::layout_guide_point::x() const {
    return this->_x_guide;
}

ui::layout_guide_ptr const &ui::layout_guide_point::y() const {
    return this->_y_guide;
}

void ui::layout_guide_point::set_point(ui::point point) {
    this->push_notify_waiting();

    this->_x_guide->set_value(std::move(point.x));
    this->_y_guide->set_value(std::move(point.y));

    this->pop_notify_waiting();
}

ui::point ui::layout_guide_point::point() const {
    return ui::point{_x_guide->value(), _y_guide->value()};
}

void ui::layout_guide_point::push_notify_waiting() {
    this->_x_guide->push_notify_waiting();
    this->_y_guide->push_notify_waiting();
}

void ui::layout_guide_point::pop_notify_waiting() {
    this->_x_guide->pop_notify_waiting();
    this->_y_guide->pop_notify_waiting();
}

observing::cancellable_ptr ui::layout_guide_point::observe(observing::caller<ui::point>::handler_f &&handler,
                                                           bool const sync) {
    auto pool = observing::canceller_pool::make_shared();

    this->_x_guide->observe([this, handler](float const &) { handler(this->point()); }, false)->add_to(*pool);
    this->_y_guide->observe([this, handler](float const &) { handler(this->point()); }, sync)->add_to(*pool);

    return pool;
}

std::shared_ptr<ui::layout_guide_point> ui::layout_guide_point::make_shared() {
    return make_shared(ui::point{});
}

std::shared_ptr<ui::layout_guide_point> ui::layout_guide_point::make_shared(ui::point point) {
    return std::shared_ptr<layout_guide_point>(new layout_guide_point{std::move(point)});
}

#pragma mark - ui::layout_guide_range

ui::layout_guide_range::layout_guide_range(ui::range &&range)
    : _min_guide(layout_guide::make_shared(range.min())),
      _max_guide(layout_guide::make_shared(range.max())),
      _length_guide(layout_guide::make_shared(range.length)) {
    this->_min_canceller = this->_min_guide->observe(
        [this](float const &min) { this->_length_guide->set_value(this->max()->value() - min); }, false);
    this->_max_canceller = this->_max_guide->observe(
        [this](float const &max) { this->_length_guide->set_value(max - this->min()->value()); }, false);
}

ui::layout_guide_range::~layout_guide_range() = default;

ui::layout_guide_ptr &ui::layout_guide_range::min() {
    return this->_min_guide;
}

ui::layout_guide_ptr &ui::layout_guide_range::max() {
    return this->_max_guide;
}

ui::layout_guide_ptr const &ui::layout_guide_range::min() const {
    return this->_min_guide;
}

ui::layout_guide_ptr const &ui::layout_guide_range::max() const {
    return this->_max_guide;
}

ui::layout_guide_ptr const &ui::layout_guide_range::length() const {
    return this->_length_guide;
}

void ui::layout_guide_range::set_range(ui::range const &range) {
    this->push_notify_waiting();

    this->_min_guide->set_value(range.min());
    this->_max_guide->set_value(range.max());

    this->pop_notify_waiting();
}

ui::range ui::layout_guide_range::range() const {
    auto const &min = this->_min_guide->value();
    auto const &max = this->_max_guide->value();

    return ui::range{.location = min, .length = max - min};
}

void ui::layout_guide_range::push_notify_waiting() {
    this->_min_guide->push_notify_waiting();
    this->_max_guide->push_notify_waiting();
    this->_length_guide->push_notify_waiting();
}

void ui::layout_guide_range::pop_notify_waiting() {
    this->_min_guide->pop_notify_waiting();
    this->_max_guide->pop_notify_waiting();
    this->_length_guide->pop_notify_waiting();
}

observing::cancellable_ptr ui::layout_guide_range::observe(observing::caller<ui::range>::handler_f &&handler,
                                                           bool const sync) {
    auto pool = observing::canceller_pool::make_shared();

    this->_min_guide->observe([this, handler](float const &) { handler(this->range()); }, false)->add_to(*pool);
    this->_max_guide->observe([this, handler](float const &) { handler(this->range()); }, sync)->add_to(*pool);

    return pool;
}

std::shared_ptr<ui::layout_guide_range> ui::layout_guide_range::make_shared() {
    return make_shared(ui::range{});
}

std::shared_ptr<ui::layout_guide_range> ui::layout_guide_range::make_shared(ui::range range) {
    return std::shared_ptr<layout_guide_range>(new layout_guide_range{std::move(range)});
}

#pragma mark - ui::layout_guide_rect

ui::layout_guide_rect::layout_guide_rect(ranges_args args)
    : _vertical_range(layout_guide_range::make_shared(std::move(args.vertical_range))),
      _horizontal_range(layout_guide_range::make_shared(std::move(args.horizontal_range))) {
}

ui::layout_guide_rect::layout_guide_rect(ui::region region)
    : layout_guide_rect({.horizontal_range = region.horizontal_range(), .vertical_range = region.vertical_range()}) {
}

ui::layout_guide_rect::~layout_guide_rect() = default;

ui::layout_guide_range_ptr &ui::layout_guide_rect::horizontal_range() {
    return this->_horizontal_range;
}

ui::layout_guide_range_ptr &ui::layout_guide_rect::vertical_range() {
    return this->_vertical_range;
}

ui::layout_guide_range_ptr const &ui::layout_guide_rect::horizontal_range() const {
    return this->_horizontal_range;
}

ui::layout_guide_range_ptr const &ui::layout_guide_rect::vertical_range() const {
    return this->_vertical_range;
}

ui::layout_guide_ptr &ui::layout_guide_rect::left() {
    return this->horizontal_range()->min();
}

ui::layout_guide_ptr &ui::layout_guide_rect::right() {
    return this->horizontal_range()->max();
}

ui::layout_guide_ptr &ui::layout_guide_rect::bottom() {
    return this->vertical_range()->min();
}

ui::layout_guide_ptr &ui::layout_guide_rect::top() {
    return this->vertical_range()->max();
}

ui::layout_guide_ptr const &ui::layout_guide_rect::left() const {
    return this->horizontal_range()->min();
}

ui::layout_guide_ptr const &ui::layout_guide_rect::right() const {
    return this->horizontal_range()->max();
}

ui::layout_guide_ptr const &ui::layout_guide_rect::bottom() const {
    return this->vertical_range()->min();
}

ui::layout_guide_ptr const &ui::layout_guide_rect::top() const {
    return this->vertical_range()->max();
}

ui::layout_guide_ptr const &ui::layout_guide_rect::width() const {
    return this->horizontal_range()->length();
}

ui::layout_guide_ptr const &ui::layout_guide_rect::height() const {
    return this->vertical_range()->length();
}

void ui::layout_guide_rect::set_horizontal_range(ui::range range) {
    this->_horizontal_range->set_range(std::move(range));
}

void ui::layout_guide_rect::set_vertical_range(ui::range range) {
    this->_vertical_range->set_range(std::move(range));
}

void ui::layout_guide_rect::set_ranges(ranges_args args) {
    this->push_notify_waiting();

    this->set_vertical_range(std::move(args.vertical_range));
    this->set_horizontal_range(std::move(args.horizontal_range));

    this->pop_notify_waiting();
}

void ui::layout_guide_rect::set_region(ui::region const &region) {
    this->set_ranges({.vertical_range = region.vertical_range(), .horizontal_range = region.horizontal_range()});
}

ui::region ui::layout_guide_rect::region() const {
    auto h_range = this->_horizontal_range->range();
    auto v_range = this->_vertical_range->range();

    return ui::make_region(h_range, v_range);
}

void ui::layout_guide_rect::push_notify_waiting() {
    this->_vertical_range->push_notify_waiting();
    this->_horizontal_range->push_notify_waiting();
}

void ui::layout_guide_rect::pop_notify_waiting() {
    this->_vertical_range->pop_notify_waiting();
    this->_horizontal_range->pop_notify_waiting();
}

observing::cancellable_ptr ui::layout_guide_rect::observe(observing::caller<ui::region>::handler_f &&handler,
                                                          bool const sync) {
    auto pool = observing::canceller_pool::make_shared();

    this->_vertical_range->observe([this, handler](ui::range const &) { handler(this->region()); }, false)
        ->add_to(*pool);
    this->_horizontal_range->observe([this, handler](ui::range const &) { handler(this->region()); }, sync)
        ->add_to(*pool);

    return pool;
}

std::shared_ptr<ui::layout_guide_rect> ui::layout_guide_rect::make_shared() {
    return make_shared(ranges_args{.horizontal_range = {.v = 0.0f}, .vertical_range = {.v = 0.0f}});
}

std::shared_ptr<ui::layout_guide_rect> ui::layout_guide_rect::make_shared(ranges_args args) {
    return std::shared_ptr<layout_guide_rect>(new layout_guide_rect{std::move(args)});
}

std::shared_ptr<ui::layout_guide_rect> ui::layout_guide_rect::make_shared(ui::region region) {
    return make_shared({.horizontal_range = region.horizontal_range(), .vertical_range = region.vertical_range()});
}

#pragma mark - layout_guide_pair

std::vector<ui::layout_guide_pair> ui::make_layout_guide_pairs(ui::layout_guide_point_pair point_pair) {
    return {ui::layout_guide_pair{.source = point_pair.source->x(), .destination = point_pair.destination->x()},
            ui::layout_guide_pair{.source = point_pair.source->y(), .destination = point_pair.destination->y()}};
}

std::vector<ui::layout_guide_pair> ui::make_layout_guide_pairs(ui::layout_guide_range_pair range_pair) {
    return {ui::layout_guide_pair{.source = range_pair.source->min(), .destination = range_pair.destination->min()},
            ui::layout_guide_pair{.source = range_pair.source->max(), .destination = range_pair.destination->max()}};
}

std::vector<ui::layout_guide_pair> ui::make_layout_guide_pairs(ui::layout_guide_rect_pair rect_pair) {
    return {ui::layout_guide_pair{.source = rect_pair.source->left(), .destination = rect_pair.destination->left()},
            ui::layout_guide_pair{.source = rect_pair.source->right(), .destination = rect_pair.destination->right()},
            ui::layout_guide_pair{.source = rect_pair.source->bottom(), .destination = rect_pair.destination->bottom()},
            ui::layout_guide_pair{.source = rect_pair.source->top(), .destination = rect_pair.destination->top()}};
}
