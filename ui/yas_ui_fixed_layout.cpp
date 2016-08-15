//
//  yas_ui_fixed_layout.cpp
//

#include "yas_property.h"
#include "yas_ui_fixed_layout.h"

using namespace yas;

struct ui::fixed_layout::impl : base::impl {
    property<float> _distance;
    ui::layout_guide _src_guide;
    ui::layout_guide _dst_guide;

    impl(args &&args)
        : _distance({.value = args.distance}),
          _src_guide(std::move(args.source_guide)),
          _dst_guide(std::move(args.destination_guide)) {
    }

    void prepare(ui::fixed_layout &layout) {
        auto weak_layout = to_weak(layout);

        _distance_observer =
            _distance.subject().make_observer(property_method::did_change, [weak_layout](auto const &context) {
                if (auto layout = weak_layout.lock()) {
                    layout.impl_ptr<impl>()->update_destination_value();
                }
            });

        _src_observer = _src_guide.subject().make_observer(ui::layout_guide::method::value_changed,
                                                           [weak_layout](auto const &context) {
                                                               if (auto layout = weak_layout.lock()) {
                                                                   layout.impl_ptr<impl>()->update_destination_value();
                                                               }
                                                           });

        update_destination_value();
    }

    void update_destination_value() {
        _dst_guide.set_value(_src_guide.value() + _distance.value());
    }

   private:
    property<float>::observer_t _distance_observer;
    ui::layout_guide::subject_t::observer_t _src_observer;
};

ui::fixed_layout::fixed_layout(args args) : base(std::make_shared<impl>(std::move(args))) {
    impl_ptr<impl>()->prepare(*this);
}

ui::fixed_layout::fixed_layout(std::nullptr_t) : base(nullptr) {
}

ui::fixed_layout::~fixed_layout() = default;

void ui::fixed_layout::set_distance(float const value) {
    impl_ptr<impl>()->_distance.set_value(value);
}

float const &ui::fixed_layout::distance() const {
    return impl_ptr<impl>()->_distance.value();
}

ui::layout_guide const &ui::fixed_layout::source_guide() const {
    return impl_ptr<impl>()->_src_guide;
}

ui::layout_guide const &ui::fixed_layout::destination_guide() const {
    return impl_ptr<impl>()->_dst_guide;
}
