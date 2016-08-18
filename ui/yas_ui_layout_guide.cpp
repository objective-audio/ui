//
//  yas_ui_layout_guide.cpp
//

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
        _observer = _value.subject().make_observer(
            property_method::did_change, [weak_guide = to_weak(guide)](auto const &context) {
                if (auto guide = weak_guide.lock()) {
                    guide.impl_ptr<ui::layout_guide::impl>()->_notify_or_delay_value_changed(context, guide);
                }
            });
    }

    bool is_delayed() {
        return _delayed_count != 0;
    }

    void push_notify_delayed() {
        ++_delayed_count;
    }

    void pop_notify_delayed() {
        if (_delayed_count == 0) {
            throw "delayed_count decrease failed.";
        }

        --_delayed_count;

        if (_delayed_count == 0 && _notify_handler) {
            _notify_handler();
            _notify_handler = nullptr;
            _old_value = nullopt;
        }
    }

   private:
    property<float>::observer_t _observer;
    std::size_t _delayed_count = 0;
    std::function<void(void)> _notify_handler = nullptr;
    std::experimental::optional<float> _old_value = nullopt;

    void _notify_or_delay_value_changed(property<float>::observer_t::change_context const &context,
                                        ui::layout_guide const &guide) {
        if (!_old_value) {
            _old_value = context.value.old_value;
        }

        auto handler = [new_value = context.value.new_value, weak_guide = to_weak(guide)]() {
            if (auto guide = weak_guide.lock()) {
                auto guide_impl = guide.impl_ptr<ui::layout_guide::impl>();

                if (auto handler = guide_impl->_value_changed_handler) {
                    handler(new_value);
                }

                guide.subject().notify(method::value_changed, change_context{.old_value = *guide_impl->_old_value,
                                                                             .new_value = new_value,
                                                                             .layout_guide = guide});
            }
        };

        if (is_delayed()) {
            _notify_handler = std::move(handler);
        } else {
            handler();
            _old_value = nullopt;
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

void ui::layout_guide::push_notify_delayed() {
    impl_ptr<impl>()->push_notify_delayed();
}

void ui::layout_guide::pop_notify_delayed() {
    impl_ptr<impl>()->pop_notify_delayed();
}

#pragma mark - ui::layout_guide_point::impl

struct ui::layout_guide_point::impl : base::impl {
    layout_guide _x_guide;
    layout_guide _y_guide;

    impl(ui::float_origin &&origin) : _x_guide(origin.x), _y_guide(origin.y) {
    }

    void set_point(ui::float_origin &&point) {
        push_notify_delayed();

        _x_guide.set_value(std::move(point.x));
        _y_guide.set_value(std::move(point.y));

        pop_notify_delayed();
    }

    void push_notify_delayed() {
        _x_guide.push_notify_delayed();
        _y_guide.push_notify_delayed();
    }

    void pop_notify_delayed() {
        _x_guide.pop_notify_delayed();
        _y_guide.pop_notify_delayed();
    }
};

#pragma mark - ui::layout_guide_point

ui::layout_guide_point::layout_guide_point() : layout_guide_point(ui::float_origin{}) {
}

ui::layout_guide_point::layout_guide_point(ui::float_origin origin) : base(std::make_shared<impl>(std::move(origin))) {
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

void ui::layout_guide_point::set_point(ui::float_origin point) {
    impl_ptr<impl>()->set_point(std::move(point));
}

void ui::layout_guide_point::push_notify_delayed() {
    impl_ptr<impl>()->push_notify_delayed();
}

void ui::layout_guide_point::pop_notify_delayed() {
    impl_ptr<impl>()->pop_notify_delayed();
}

#pragma mark - ui::layout_guide_range::impl

struct ui::layout_guide_range::impl : base::impl {
    layout_guide _min_guide;
    layout_guide _max_guide;

    impl(ui::float_range &&range) : _min_guide(range.min()), _max_guide(range.max()) {
    }

    void set_range(ui::float_range &&range) {
        push_notify_delayed();

        _min_guide.set_value(range.min());
        _max_guide.set_value(range.max());

        pop_notify_delayed();
    }

    void push_notify_delayed() {
        _min_guide.push_notify_delayed();
        _max_guide.push_notify_delayed();
    }

    void pop_notify_delayed() {
        _min_guide.pop_notify_delayed();
        _max_guide.pop_notify_delayed();
    }
};

#pragma mark - ui::layout_guide_range

ui::layout_guide_range::layout_guide_range() : layout_guide_range(ui::float_range{}) {
}

ui::layout_guide_range::layout_guide_range(ui::float_range range) : base(std::make_shared<impl>(std::move(range))) {
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

void ui::layout_guide_range::set_range(ui::float_range range) {
    impl_ptr<impl>()->set_range(std::move(range));
}

void ui::layout_guide_range::push_notify_delayed() {
    impl_ptr<impl>()->push_notify_delayed();
}

void ui::layout_guide_range::pop_notify_delayed() {
    impl_ptr<impl>()->pop_notify_delayed();
}

#pragma mark - ui::layout_guide_rect::impl

struct ui::layout_guide_rect::impl : base::impl {
    layout_guide_range _vertical_range;
    layout_guide_range _horizontal_range;

    impl(args &&args)
        : _vertical_range(std::move(args.vertical_range)), _horizontal_range(std::move(args.horizontal_range)) {
    }

    void set_vertical_range(ui::float_range &&range) {
        _vertical_range.set_range(std::move(range));
    }

    void set_horizontal_range(ui::float_range &&range) {
        _horizontal_range.set_range(std::move(range));
    }

    void set_ranges(args &&args) {
        set_vertical_range(std::move(args.vertical_range));
        set_horizontal_range(std::move(args.horizontal_range));
    }

    void set_region(ui::float_region &&region) {
        set_ranges({.vertical_range = region.vertical_range(), .horizontal_range = region.horizontal_range()});
    }

    void push_notify_delayed() {
        _vertical_range.push_notify_delayed();
        _horizontal_range.push_notify_delayed();
    }

    void pop_notify_delayed() {
        _vertical_range.pop_notify_delayed();
        _horizontal_range.pop_notify_delayed();
    }
};

#pragma mark - ui::layout_guide_rect

ui::layout_guide_rect::layout_guide_rect() : layout_guide_rect(args{}) {
}

ui::layout_guide_rect::layout_guide_rect(args args) : base(std::make_shared<impl>(std::move(args))) {
}

ui::layout_guide_rect::layout_guide_rect(std::nullptr_t) : base(nullptr) {
}

ui::layout_guide_rect::~layout_guide_rect() = default;

ui::layout_guide_range &ui::layout_guide_rect::vertical_range() {
    return impl_ptr<impl>()->_vertical_range;
}

ui::layout_guide_range &ui::layout_guide_rect::horizontal_range() {
    return impl_ptr<impl>()->_horizontal_range;
}

ui::layout_guide &ui::layout_guide_rect::left() {
    return horizontal_range().min();
}

ui::layout_guide &ui::layout_guide_rect::right() {
    return horizontal_range().max();
}

ui::layout_guide &ui::layout_guide_rect::bottom() {
    return vertical_range().min();
}

ui::layout_guide &ui::layout_guide_rect::top() {
    return vertical_range().max();
}

void ui::layout_guide_rect::set_vertical_range(ui::float_range range) {
    impl_ptr<impl>()->set_vertical_range(std::move(range));
}

void ui::layout_guide_rect::set_horizontal_range(ui::float_range range) {
    impl_ptr<impl>()->set_horizontal_range(std::move(range));
}

void ui::layout_guide_rect::set_ranges(args args) {
    impl_ptr<impl>()->set_ranges(std::move(args));
}

void ui::layout_guide_rect::set_region(ui::float_region region) {
    impl_ptr<impl>()->set_region(std::move(region));
}

void ui::layout_guide_rect::push_notify_delayed() {
    impl_ptr<impl>()->push_notify_delayed();
}

void ui::layout_guide_rect::pop_notify_delayed() {
    impl_ptr<impl>()->pop_notify_delayed();
}