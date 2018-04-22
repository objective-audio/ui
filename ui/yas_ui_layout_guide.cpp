//
//  yas_ui_layout_guide.cpp
//

#include "yas_delaying_caller.h"
#include "yas_property.h"
#include "yas_ui_layout_guide.h"

using namespace yas;

#pragma mark - ui::layout_guide::impl

struct ui::layout_guide::impl : base::impl {
    property<float> _value;
    subject_t _subject;
    value_changed_f _value_changed_handler = nullptr;

    impl(float const value) : _value({.value = value}) {
    }

    void prepare(layout_guide &guide) {
        this->_observer = this->_value.subject().make_observer(
            property_method::did_change, [weak_guide = to_weak(guide)](auto const &context) {
                if (auto guide = weak_guide.lock()) {
                    guide.impl_ptr<ui::layout_guide::impl>()->_request_notify_value_changed(context, guide);
                }
            });
    }

    void push_notify_caller() {
        this->_notify_caller.push();
    }

    void pop_notify_caller() {
        this->_notify_caller.pop();
    }

    float old_value_in_notify() {
        return *this->_old_value;
    }

   private:
    property<float>::observer_t _observer;
    delaying_caller _notify_caller;
    std::experimental::optional<float> _old_value = nullopt;

    void _request_notify_value_changed(property<float>::observer_t::change_context const &context,
                                       ui::layout_guide const &guide) {
        if (!this->_old_value) {
            this->_old_value = context.value.old_value;
        }

        auto const &new_value = context.value.new_value;

        if (this->_old_value == new_value) {
            this->_notify_caller.cancel();
        } else {
            this->_notify_caller.request([new_value = context.value.new_value, weak_guide = to_weak(guide)]() {
                if (auto guide = weak_guide.lock()) {
                    auto guide_impl = guide.impl_ptr<ui::layout_guide::impl>();

                    auto const context = change_context{
                        .old_value = *guide_impl->_old_value, .new_value = new_value, .layout_guide = guide};

                    if (auto handler = guide_impl->_value_changed_handler) {
                        handler(context);
                    }

                    guide.subject().notify(method::value_changed, context);

                    guide_impl->_old_value = nullopt;
                }
            });
        }
    }
};

#pragma mark - ui::layout_guide

ui::layout_guide::layout_guide() : layout_guide(0.0f) {
}

ui::layout_guide::layout_guide(float const value) : base(std::make_shared<impl>(value)) {
    impl_ptr<impl>()->prepare(*this);
}

ui::layout_guide::layout_guide(std::nullptr_t) : base(nullptr) {
}

ui::layout_guide::~layout_guide() = default;

void ui::layout_guide::set_value(float const value) {
    impl_ptr<impl>()->_value.set_value(value);
}

float const &ui::layout_guide::value() const {
    return impl_ptr<impl>()->_value.value();
}

void ui::layout_guide::set_value_changed_handler(value_changed_f handler) {
    impl_ptr<impl>()->_value_changed_handler = std::move(handler);
}

ui::layout_guide::subject_t &ui::layout_guide::subject() {
    return impl_ptr<impl>()->_subject;
}

void ui::layout_guide::push_notify_caller() {
    impl_ptr<impl>()->push_notify_caller();
}

void ui::layout_guide::pop_notify_caller() {
    impl_ptr<impl>()->pop_notify_caller();
}

#pragma mark - ui::layout_guide_point::impl

struct ui::layout_guide_point::impl : base::impl {
    layout_guide _x_guide;
    layout_guide _y_guide;

    impl(ui::point &&origin) : _x_guide(origin.x), _y_guide(origin.y) {
    }

    void set_point(ui::point &&point) {
        this->push_notify_caller();

        this->_x_guide.set_value(std::move(point.x));
        this->_y_guide.set_value(std::move(point.y));

        this->pop_notify_caller();
    }

    ui::point point() {
        return ui::point{_x_guide.value(), _y_guide.value()};
    }

    void set_value_changed_handler(value_changed_f &&handler) {
        auto guide_handler =
            [handler = std::move(handler), weak_point = to_weak(cast<ui::layout_guide_point>())](auto const &context) {
            if (auto point = weak_point.lock()) {
                handler(change_context{.old_value = point.impl_ptr<impl>()->old_point_in_notify(),
                                       .new_value = point.impl_ptr<impl>()->point(),
                                       .layout_guide_point = point});
            }
        };

        this->_x_guide.set_value_changed_handler(guide_handler);
        this->_y_guide.set_value_changed_handler(guide_handler);
    }

    void push_notify_caller() {
        this->_x_guide.push_notify_caller();
        this->_y_guide.push_notify_caller();
    }

    void pop_notify_caller() {
        this->_x_guide.pop_notify_caller();
        this->_y_guide.pop_notify_caller();
    }

    ui::point old_point_in_notify() {
        return ui::point{this->_x_guide.impl_ptr<ui::layout_guide::impl>()->old_value_in_notify(),
                         this->_y_guide.impl_ptr<ui::layout_guide::impl>()->old_value_in_notify()};
    }
};

#pragma mark - ui::layout_guide_point

ui::layout_guide_point::layout_guide_point() : layout_guide_point(ui::point{}) {
}

ui::layout_guide_point::layout_guide_point(ui::point origin) : base(std::make_shared<impl>(std::move(origin))) {
}

ui::layout_guide_point::layout_guide_point(std::nullptr_t) : base(nullptr) {
}

ui::layout_guide_point::~layout_guide_point() = default;

ui::layout_guide &ui::layout_guide_point::x() {
    return impl_ptr<impl>()->_x_guide;
}

ui::layout_guide &ui::layout_guide_point::y() {
    return impl_ptr<impl>()->_y_guide;
}

ui::layout_guide const &ui::layout_guide_point::x() const {
    return impl_ptr<impl>()->_x_guide;
}

ui::layout_guide const &ui::layout_guide_point::y() const {
    return impl_ptr<impl>()->_y_guide;
}

void ui::layout_guide_point::set_point(ui::point point) {
    impl_ptr<impl>()->set_point(std::move(point));
}

ui::point ui::layout_guide_point::point() const {
    return impl_ptr<impl>()->point();
}

void ui::layout_guide_point::set_value_changed_handler(value_changed_f handler) {
    impl_ptr<impl>()->set_value_changed_handler(std::move(handler));
}

void ui::layout_guide_point::push_notify_caller() {
    impl_ptr<impl>()->push_notify_caller();
}

void ui::layout_guide_point::pop_notify_caller() {
    impl_ptr<impl>()->pop_notify_caller();
}

#pragma mark - ui::layout_guide_range::impl

struct ui::layout_guide_range::impl : base::impl {
    layout_guide _min_guide;
    layout_guide _max_guide;
    layout_guide _length_guide;
    layout_guide::observer_t _min_observer = nullptr;
    layout_guide::observer_t _max_observer = nullptr;
    layout_guide::observer_t _length_observer = nullptr;

    impl(ui::range &&range) : _min_guide(range.min()), _max_guide(range.max()), _length_guide(range.length) {
    }

    void prepare(ui::layout_guide_range &range) {
        auto weak_range = to_weak(range);

        this->_min_observer = this->_min_guide.subject().make_observer(
            ui::layout_guide::method::value_changed, [weak_range](auto const &context) {
                if (auto range = weak_range.lock()) {
                    float const length = range.impl_ptr<impl>()->_max_guide.value() - context.value.new_value;
                    range.impl_ptr<impl>()->_length_guide.set_value(length);
                }
            });

        this->_max_observer = this->_max_guide.subject().make_observer(
            ui::layout_guide::method::value_changed, [weak_range](auto const &context) {
                if (auto range = weak_range.lock()) {
                    float const length = context.value.new_value - range.impl_ptr<impl>()->_min_guide.value();
                    range.impl_ptr<impl>()->_length_guide.set_value(length);
                }
            });

        this->_length_observer = this->_length_guide.subject().make_observer(
            ui::layout_guide::method::value_changed, [weak_range](auto const &context) {
                if (auto range = weak_range.lock()) {
                    float const max = range.impl_ptr<impl>()->_min_guide.value() + context.value.new_value;
                    range.impl_ptr<impl>()->_max_guide.set_value(max);
                }
            });
    }

    void set_range(ui::range &&range) {
        this->push_notify_caller();

        this->_min_guide.set_value(range.min());
        this->_max_guide.set_value(range.max());
        this->_length_guide.set_value(range.length);

        this->pop_notify_caller();
    }

    ui::range range() {
        auto const &min = this->_min_guide.value();
        auto const &max = this->_max_guide.value();

        return ui::range{.location = min, .length = max - min};
    }

    void set_value_changed_handler(value_changed_f &&handler) {
        auto guide_handler =
            [handler = std::move(handler), weak_guide_range = to_weak(cast<ui::layout_guide_range>())](auto const &) {
            if (auto guide_range = weak_guide_range.lock()) {
                handler(change_context{.old_value = guide_range.impl_ptr<impl>()->old_range_in_notify(),
                                       .new_value = guide_range.impl_ptr<impl>()->range(),
                                       .layout_guide_range = guide_range});
            }
        };

        this->_min_guide.set_value_changed_handler(guide_handler);
        this->_max_guide.set_value_changed_handler(guide_handler);
        this->_length_guide.set_value_changed_handler(guide_handler);
    }

    void push_notify_caller() {
        this->_min_guide.push_notify_caller();
        this->_max_guide.push_notify_caller();
        this->_length_guide.push_notify_caller();
    }

    void pop_notify_caller() {
        this->_min_guide.pop_notify_caller();
        this->_max_guide.pop_notify_caller();
        this->_length_guide.pop_notify_caller();
    }

    ui::range old_range_in_notify() {
        auto const loc = this->_min_guide.impl_ptr<ui::layout_guide::impl>()->old_value_in_notify();
        auto const len = this->_max_guide.impl_ptr<ui::layout_guide::impl>()->old_value_in_notify() - loc;
        return ui::range{.location = loc, .length = len};
    }
};

#pragma mark - ui::layout_guide_range

ui::layout_guide_range::layout_guide_range() : layout_guide_range(ui::range{}) {
}

ui::layout_guide_range::layout_guide_range(ui::range range) : base(std::make_shared<impl>(std::move(range))) {
    impl_ptr<impl>()->prepare(*this);
}

ui::layout_guide_range::layout_guide_range(std::nullptr_t) : base(nullptr) {
}

ui::layout_guide_range::~layout_guide_range() = default;

ui::layout_guide &ui::layout_guide_range::min() {
    return impl_ptr<impl>()->_min_guide;
}

ui::layout_guide &ui::layout_guide_range::max() {
    return impl_ptr<impl>()->_max_guide;
}

ui::layout_guide &ui::layout_guide_range::length() {
    return impl_ptr<impl>()->_length_guide;
}

ui::layout_guide const &ui::layout_guide_range::min() const {
    return impl_ptr<impl>()->_min_guide;
}

ui::layout_guide const &ui::layout_guide_range::max() const {
    return impl_ptr<impl>()->_max_guide;
}

ui::layout_guide const &ui::layout_guide_range::length() const {
    return impl_ptr<impl>()->_length_guide;
}

void ui::layout_guide_range::set_range(ui::range range) {
    impl_ptr<impl>()->set_range(std::move(range));
}

ui::range ui::layout_guide_range::range() const {
    return impl_ptr<impl>()->range();
}

void ui::layout_guide_range::set_value_changed_handler(value_changed_f handler) {
    impl_ptr<impl>()->set_value_changed_handler(std::move(handler));
}

void ui::layout_guide_range::push_notify_caller() {
    impl_ptr<impl>()->push_notify_caller();
}

void ui::layout_guide_range::pop_notify_caller() {
    impl_ptr<impl>()->pop_notify_caller();
}

#pragma mark - ui::layout_guide_rect::impl

struct ui::layout_guide_rect::impl : base::impl {
    layout_guide_range _vertical_range;
    layout_guide_range _horizontal_range;

    impl(ranges_args &&args)
        : _vertical_range(std::move(args.vertical_range)), _horizontal_range(std::move(args.horizontal_range)) {
    }

    void set_vertical_range(ui::range &&range) {
        this->_vertical_range.set_range(std::move(range));
    }

    void set_horizontal_range(ui::range &&range) {
        this->_horizontal_range.set_range(std::move(range));
    }

    void set_ranges(ranges_args &&args) {
        this->set_vertical_range(std::move(args.vertical_range));
        this->set_horizontal_range(std::move(args.horizontal_range));
    }

    void set_region(ui::region &&region) {
        this->set_ranges({.vertical_range = region.vertical_range(), .horizontal_range = region.horizontal_range()});
    }

    ui::region region() {
        auto h_range = this->_horizontal_range.range();
        auto v_range = this->_vertical_range.range();

        return ui::region{.origin = {h_range.location, v_range.location}, .size = {h_range.length, v_range.length}};
    }

    void set_value_changed_handler(value_changed_f &&handler) {
        auto guide_handler = [handler, weak_guide_rect = to_weak(cast<ui::layout_guide_rect>())](auto const &) {
            if (auto const guide_rect = weak_guide_rect.lock()) {
                handler(change_context{.old_value = guide_rect.impl_ptr<impl>()->old_region_in_notify(),
                                       .new_value = guide_rect.impl_ptr<impl>()->region(),
                                       .layout_guide_rect = guide_rect});
            }
        };

        this->_vertical_range.min().set_value_changed_handler(guide_handler);
        this->_vertical_range.max().set_value_changed_handler(guide_handler);
        this->_horizontal_range.min().set_value_changed_handler(guide_handler);
        this->_horizontal_range.max().set_value_changed_handler(guide_handler);
    }

    void push_notify_caller() {
        this->_vertical_range.push_notify_caller();
        this->_horizontal_range.push_notify_caller();
    }

    void pop_notify_caller() {
        this->_vertical_range.pop_notify_caller();
        this->_horizontal_range.pop_notify_caller();
    }

    ui::region old_region_in_notify() {
        auto const h_range = this->_horizontal_range.impl_ptr<ui::layout_guide_range::impl>()->old_range_in_notify();
        auto const v_range = this->_vertical_range.impl_ptr<ui::layout_guide_range::impl>()->old_range_in_notify();
        return ui::region{.origin = {h_range.location, v_range.location}, .size = {h_range.length, v_range.length}};
    }
};

#pragma mark - ui::layout_guide_rect

ui::layout_guide_rect::layout_guide_rect()
    : layout_guide_rect(ranges_args{.horizontal_range = {.v = 0.0f}, .vertical_range = {.v = 0.0f}}) {
}

ui::layout_guide_rect::layout_guide_rect(ranges_args args) : base(std::make_shared<impl>(std::move(args))) {
}

ui::layout_guide_rect::layout_guide_rect(ui::region region)
    : layout_guide_rect({.horizontal_range = region.horizontal_range(), .vertical_range = region.vertical_range()}) {
}

ui::layout_guide_rect::layout_guide_rect(std::nullptr_t) : base(nullptr) {
}

ui::layout_guide_rect::~layout_guide_rect() = default;

ui::layout_guide_range &ui::layout_guide_rect::horizontal_range() {
    return impl_ptr<impl>()->_horizontal_range;
}

ui::layout_guide_range &ui::layout_guide_rect::vertical_range() {
    return impl_ptr<impl>()->_vertical_range;
}

ui::layout_guide_range const &ui::layout_guide_rect::horizontal_range() const {
    return impl_ptr<impl>()->_horizontal_range;
}

ui::layout_guide_range const &ui::layout_guide_rect::vertical_range() const {
    return impl_ptr<impl>()->_vertical_range;
}

ui::layout_guide &ui::layout_guide_rect::left() {
    return this->horizontal_range().min();
}

ui::layout_guide &ui::layout_guide_rect::right() {
    return this->horizontal_range().max();
}

ui::layout_guide &ui::layout_guide_rect::bottom() {
    return this->vertical_range().min();
}

ui::layout_guide &ui::layout_guide_rect::top() {
    return this->vertical_range().max();
}

ui::layout_guide &ui::layout_guide_rect::width() {
    return this->horizontal_range().length();
}

ui::layout_guide &ui::layout_guide_rect::height() {
    return this->vertical_range().length();
}

ui::layout_guide const &ui::layout_guide_rect::left() const {
    return this->horizontal_range().min();
}

ui::layout_guide const &ui::layout_guide_rect::right() const {
    return this->horizontal_range().max();
}

ui::layout_guide const &ui::layout_guide_rect::bottom() const {
    return this->vertical_range().min();
}

ui::layout_guide const &ui::layout_guide_rect::top() const {
    return this->vertical_range().max();
}

ui::layout_guide const &ui::layout_guide_rect::width() const {
    return this->horizontal_range().length();
}

ui::layout_guide const &ui::layout_guide_rect::height() const {
    return this->vertical_range().length();
}

void ui::layout_guide_rect::set_horizontal_range(ui::range range) {
    impl_ptr<impl>()->set_horizontal_range(std::move(range));
}

void ui::layout_guide_rect::set_vertical_range(ui::range range) {
    impl_ptr<impl>()->set_vertical_range(std::move(range));
}

void ui::layout_guide_rect::set_ranges(ranges_args args) {
    impl_ptr<impl>()->set_ranges(std::move(args));
}

void ui::layout_guide_rect::set_region(ui::region region) {
    impl_ptr<impl>()->set_region(std::move(region));
}

ui::region ui::layout_guide_rect::region() const {
    return impl_ptr<impl>()->region();
}

void ui::layout_guide_rect::set_value_changed_handler(value_changed_f handler) {
    impl_ptr<impl>()->set_value_changed_handler(std::move(handler));
}

void ui::layout_guide_rect::push_notify_caller() {
    impl_ptr<impl>()->push_notify_caller();
}

void ui::layout_guide_rect::pop_notify_caller() {
    impl_ptr<impl>()->pop_notify_caller();
}

#pragma mark - layout_guide_pair

std::vector<ui::layout_guide_pair> ui::make_layout_guide_pairs(ui::layout_guide_point_pair point_pair) {
    return {ui::layout_guide_pair{.source = point_pair.source.x(), .destination = point_pair.destination.x()},
            ui::layout_guide_pair{.source = point_pair.source.y(), .destination = point_pair.destination.y()}};
}

std::vector<ui::layout_guide_pair> ui::make_layout_guide_pairs(ui::layout_guide_range_pair range_pair) {
    return {ui::layout_guide_pair{.source = range_pair.source.min(), .destination = range_pair.destination.min()},
            ui::layout_guide_pair{.source = range_pair.source.max(), .destination = range_pair.destination.max()}};
}

std::vector<ui::layout_guide_pair> ui::make_layout_guide_pairs(ui::layout_guide_rect_pair rect_pair) {
    return {ui::layout_guide_pair{.source = rect_pair.source.left(), .destination = rect_pair.destination.left()},
            ui::layout_guide_pair{.source = rect_pair.source.right(), .destination = rect_pair.destination.right()},
            ui::layout_guide_pair{.source = rect_pair.source.bottom(), .destination = rect_pair.destination.bottom()},
            ui::layout_guide_pair{.source = rect_pair.source.top(), .destination = rect_pair.destination.top()}};
}
