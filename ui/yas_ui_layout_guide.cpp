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

    impl(float const value) : _value({.value = value}) {
    }

    void prepare(layout_guide &guide) {
        _observer = _value.subject().make_observer(
            property_method::did_change, [weak_guide = to_weak(guide)](auto const &context) {
                if (auto guide = weak_guide.lock()) {
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

ui::layout_guide::subject_t &ui::layout_guide::subject() {
    return impl_ptr<impl>()->_subject;
}

#pragma mark - ui::layout_vertical_range::impl

struct ui::layout_vertical_range::impl : base::impl {
    layout_guide _top_guide;
    layout_guide _bottom_guide;

    impl(args &&args) : _top_guide(args.top_value), _bottom_guide(args.bottom_value) {
    }
};

#pragma mark - ui::layout_vertical_range

ui::layout_vertical_range::layout_vertical_range() : layout_vertical_range(args{}) {
}

ui::layout_vertical_range::layout_vertical_range(args args) : base(std::make_shared<impl>(std::move(args))) {
}

ui::layout_vertical_range::layout_vertical_range(std::nullptr_t) : base(nullptr) {
}

ui::layout_vertical_range::~layout_vertical_range() = default;

ui::layout_guide &ui::layout_vertical_range::top_guide() {
    return impl_ptr<impl>()->_top_guide;
}

ui::layout_guide &ui::layout_vertical_range::bottom_guide() {
    return impl_ptr<impl>()->_bottom_guide;
}

#pragma mark - ui::layout_horizontal_range::impl

struct ui::layout_horizontal_range::impl : base::impl {
    layout_guide _left_guide;
    layout_guide _right_guide;

    impl(args &&args) : _left_guide(args.left_value), _right_guide(args.right_value) {
    }
};

#pragma mark - ui::layout_horizontal_range

ui::layout_horizontal_range::layout_horizontal_range() : layout_horizontal_range(args{}) {
}

ui::layout_horizontal_range::layout_horizontal_range(args args) : base(std::make_shared<impl>(std::move(args))) {
}

ui::layout_horizontal_range::layout_horizontal_range(std::nullptr_t) : base(nullptr) {
}

ui::layout_horizontal_range::~layout_horizontal_range() = default;

ui::layout_guide &ui::layout_horizontal_range::left_guide() {
    return impl_ptr<impl>()->_left_guide;
}

ui::layout_guide &ui::layout_horizontal_range::right_guide() {
    return impl_ptr<impl>()->_right_guide;
}

#pragma mark - ui::layout_rect::impl

struct ui::layout_rect::impl : base::impl {
    layout_vertical_range _vertical_range;
    layout_horizontal_range _horizontal_range;

    impl(args &&args)
        : _vertical_range(std::move(args.vertical_range)), _horizontal_range(std::move(args.horizontal_range)) {
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

ui::layout_vertical_range &ui::layout_rect::vertical_range() {
    return impl_ptr<impl>()->_vertical_range;
}
ui::layout_horizontal_range &ui::layout_rect::horizontal_range() {
    return impl_ptr<impl>()->_horizontal_range;
}
