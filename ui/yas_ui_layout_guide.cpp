//
//  yas_ui_layout_guide.cpp
//

#include "yas_property.h"
#include "yas_ui_layout_guide.h"

using namespace yas;

#pragma mark - layout_guide::layout_guide

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