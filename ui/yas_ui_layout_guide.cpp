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
                    if (auto handler = guide.impl_ptr<impl>()->_value_changed_handler) {
                        handler(context.value.new_value);
                    }

                    guide.subject().notify(method::value_changed, change_context{.old_value = context.value.old_value,
                                                                                 .new_value = context.value.new_value,
                                                                                 .layout_guide = guide});
                }
            });
    }

   private:
    property<float>::observer_t _observer;
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

#pragma mark - ui::layout_range::impl

struct ui::layout_range::impl : base::impl {
    layout_guide _min_guide;
    layout_guide _max_guide;

    impl(ui::float_range &&range) : _min_guide(range.min()), _max_guide(range.max()) {
    }

    void set_range(ui::float_range &&range) {
        _min_guide.set_value(range.min());
        _max_guide.set_value(range.max());
    }
};

#pragma mark - ui::layout_range

ui::layout_range::layout_range() : layout_range(ui::float_range{}) {
}

ui::layout_range::layout_range(ui::float_range range) : base(std::make_shared<impl>(std::move(range))) {
}

ui::layout_range::layout_range(std::nullptr_t) : base(nullptr) {
}

ui::layout_range::~layout_range() = default;

ui::layout_guide &ui::layout_range::min_guide() {
    return impl_ptr<impl>()->_min_guide;
}

ui::layout_guide &ui::layout_range::max_guide() {
    return impl_ptr<impl>()->_max_guide;
}

void ui::layout_range::set_range(ui::float_range range) {
    impl_ptr<impl>()->set_range(std::move(range));
}

#pragma mark - ui::layout_rect::impl

struct ui::layout_rect::impl : base::impl {
    layout_range _vertical_range;
    layout_range _horizontal_range;

    impl(args &&args)
        : _vertical_range(std::move(args.vertical_range)), _horizontal_range(std::move(args.horizontal_range)) {
    }

    void set_ranges(args &&args) {
        _vertical_range.set_range(std::move(args.vertical_range));
        _horizontal_range.set_range(std::move(args.horizontal_range));
    }

    void set_region(ui::float_region &&region) {
        set_ranges({.vertical_range = region.vertical_range(), .horizontal_range = region.horizontal_range()});
    }
};

#pragma mark - ui::layout_rect

ui::layout_rect::layout_rect() : layout_rect(args{}) {
}

ui::layout_rect::layout_rect(args args) : base(std::make_shared<impl>(std::move(args))) {
}

ui::layout_rect::layout_rect(std::nullptr_t) : base(nullptr) {
}

ui::layout_rect::~layout_rect() = default;

ui::layout_range &ui::layout_rect::vertical_range() {
    return impl_ptr<impl>()->_vertical_range;
}

ui::layout_range &ui::layout_rect::horizontal_range() {
    return impl_ptr<impl>()->_horizontal_range;
}

ui::layout_guide &ui::layout_rect::left_guide() {
    return horizontal_range().min_guide();
}

ui::layout_guide &ui::layout_rect::right_guide() {
    return horizontal_range().max_guide();
}

ui::layout_guide &ui::layout_rect::bottom_guide() {
    return vertical_range().min_guide();
}

ui::layout_guide &ui::layout_rect::top_guide() {
    return vertical_range().max_guide();
}

void ui::layout_rect::set_ranges(args args) {
    impl_ptr<impl>()->set_ranges(std::move(args));
}

void ui::layout_rect::set_region(ui::float_region region) {
    impl_ptr<impl>()->set_region(std::move(region));
}
