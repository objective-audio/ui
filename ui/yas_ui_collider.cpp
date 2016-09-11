//
//  yas_ui_collider.cpp
//

#include "yas_observing.h"
#include "yas_property.h"
#include "yas_to_bool.h"
#include "yas_ui_collider.h"

using namespace yas;

#pragma mark - shape

bool ui::anywhere_shape::hit_test(ui::point const &) const {
    return true;
}

bool ui::circle_shape::hit_test(ui::point const &pos) const {
    return std::powf(pos.x - center.x, 2.0f) + std::powf(pos.y - center.y, 2.0f) < std::powf(radius, 2.0f);
}

bool ui::rect_shape::hit_test(ui::point const &pos) const {
    return contains(rect, pos);
}

struct ui::shape::impl_base : base::impl {
    virtual std::type_info const &type() const = 0;
    virtual bool hit_test(ui::point const &) = 0;
};

template <typename T>
struct ui::shape::impl : impl_base {
    typename T::type _value;

    impl(typename T::type &&value) : _value(std::move(value)) {
    }

    std::type_info const &type() const override {
        return typeid(T);
    }

    bool hit_test(ui::point const &pos) override {
        return _value.hit_test(pos);
    }
};

ui::shape::shape(anywhere::type shape) : base(std::make_shared<impl<anywhere>>(std::move(shape))) {
}

ui::shape::shape(circle::type shape) : base(std::make_shared<impl<circle>>(std::move(shape))) {
}

ui::shape::shape(rect::type shape) : base(std::make_shared<impl<rect>>(std::move(shape))) {
}

ui::shape::shape(std::nullptr_t) : base(nullptr) {
}

ui::shape::~shape() = default;

std::type_info const &ui::shape::type_info() const {
    return impl_ptr<impl_base>()->type();
}

bool ui::shape::hit_test(ui::point const &pos) const {
    return impl_ptr<impl_base>()->hit_test(pos);
}

template <typename T>
typename T::type const &ui::shape::get() const {
    if (auto ip = std::dynamic_pointer_cast<impl<T>>(impl_ptr())) {
        return ip->_value;
    }

    static const typename T::type _default{};
    return _default;
}

template ui::anywhere_shape const &ui::shape::get<ui::shape::anywhere>() const;
template ui::circle_shape const &ui::shape::get<ui::shape::circle>() const;
template ui::rect_shape const &ui::shape::get<ui::shape::rect>() const;

#pragma mark - collider

struct ui::collider::impl : base::impl, renderable_collider::impl {
    property<ui::shape> _shape_property{{.value = nullptr}};
    property<bool> _enabled_property{{.value = true}};
    subject_t _subject;

    impl(ui::shape &&shape) : _shape_property({.value = std::move(shape)}) {
        _property_observers.reserve(2);
    }

    void dispatch_method(ui::collider::method const method) {
        if (_property_observers.count(method)) {
            return;
        }

        auto weak_collider = to_weak(cast<ui::collider>());

        base observer = nullptr;

        auto make_observer = [](auto const method, auto property, auto weak_collider) {
            return property.subject().make_observer(property_method::did_change,
                                                    [weak_collider, method](auto const &context) {
                                                        if (auto node = weak_collider.lock()) {
                                                            node.subject().notify(method, node);
                                                        }
                                                    });
        };

        switch (method) {
            case ui::collider::method::shape_changed:
                observer = make_observer(method, _shape_property, weak_collider);
                break;
            case ui::collider::method::enabled_changed:
                observer = make_observer(method, _enabled_property, weak_collider);
                break;
        }

        _property_observers.emplace(std::make_pair(method, std::move(observer)));
    }

    bool hit_test(ui::point const &loc) {
        auto const &shape = _shape_property.value();
        if (shape && _enabled_property.value()) {
            auto pos = simd::float4x4(matrix_invert(_matrix)) * to_float4(loc.v);
            return shape.hit_test({pos.x, pos.y});
        }
        return false;
    }

    simd::float4x4 const &matrix() const override {
        return _matrix;
    }

    void set_matrix(simd::float4x4 &&matrix) override {
        _matrix = std::move(matrix);
    }

   private:
    simd::float4x4 _matrix = matrix_identity_float4x4;
    std::unordered_map<ui::collider::method, base> _property_observers;
};

ui::collider::collider() : base(std::make_shared<impl>(nullptr)) {
}

ui::collider::collider(ui::shape shape) : base(std::make_shared<impl>(std::move(shape))) {
}

ui::collider::collider(std::nullptr_t) : base(nullptr) {
}

ui::collider::~collider() = default;

void ui::collider::set_shape(ui::shape shape) {
    impl_ptr<impl>()->_shape_property.set_value(std::move(shape));
}

ui::shape const &ui::collider::shape() const {
    return impl_ptr<impl>()->_shape_property.value();
}

void ui::collider::set_enabled(bool const enabled) {
    impl_ptr<impl>()->_enabled_property.set_value(enabled);
}

bool ui::collider::is_enabled() const {
    return impl_ptr<impl>()->_enabled_property.value();
}

bool ui::collider::hit_test(ui::point const &pos) const {
    return impl_ptr<impl>()->hit_test(pos);
}

ui::collider::subject_t &ui::collider::subject() {
    return impl_ptr<impl>()->_subject;
}

void ui::collider::dispatch_method(ui::collider::method const method) {
    impl_ptr<impl>()->dispatch_method(method);
}

ui::renderable_collider &ui::collider::renderable() {
    if (!_renderable) {
        _renderable = ui::renderable_collider{impl_ptr<ui::renderable_collider::impl>()};
    }
    return _renderable;
}
