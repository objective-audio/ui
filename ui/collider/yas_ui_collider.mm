//
//  yas_ui_collider.cpp
//

#include "yas_ui_collider.h"

#include <cpp_utils/yas_to_bool.h>

using namespace yas;
using namespace yas::ui;

#pragma mark - shape

bool anywhere_shape::hit_test(point const &) const {
    return true;
}

bool circle_shape::hit_test(point const &pos) const {
    return std::powf(pos.x - this->center.x, 2.0f) + std::powf(pos.y - this->center.y, 2.0f) <
           std::powf(this->radius, 2.0f);
}

bool rect_shape::hit_test(point const &pos) const {
    return contains(this->rect, pos);
}

struct shape::impl_base {
    virtual std::type_info const &type() const = 0;
    virtual bool hit_test(point const &) = 0;
};

template <typename T>
struct shape::impl : impl_base {
    typename T::type _value;

    impl(typename T::type &&value) : _value(std::move(value)) {
    }

    std::type_info const &type() const override {
        return typeid(T);
    }

    bool hit_test(point const &pos) override {
        return this->_value.hit_test(pos);
    }
};

shape::shape(anywhere::type &&shape) : _impl(std::make_shared<impl<anywhere>>(std::move(shape))) {
}

shape::shape(circle::type &&shape) : _impl(std::make_shared<impl<circle>>(std::move(shape))) {
}

shape::shape(rect::type &&shape) : _impl(std::make_shared<impl<rect>>(std::move(shape))) {
}

shape::~shape() = default;

std::type_info const &shape::type_info() const {
    return this->_impl->type();
}

bool shape::hit_test(point const &pos) const {
    return this->_impl->hit_test(pos);
}

template <typename T>
typename T::type const &shape::get() const {
    if (auto ip = std::dynamic_pointer_cast<impl<T>>(this->_impl)) {
        return ip->_value;
    }

    static const typename T::type _default{};
    return _default;
}

template anywhere_shape const &shape::get<shape::anywhere>() const;
template circle_shape const &shape::get<shape::circle>() const;
template rect_shape const &shape::get<shape::rect>() const;

shape_ptr shape::make_shared(anywhere::type type) {
    return std::shared_ptr<shape>(new shape{std::move(type)});
}

shape_ptr shape::make_shared(circle::type type) {
    return std::shared_ptr<shape>(new shape{std::move(type)});
}

shape_ptr shape::make_shared(rect::type type) {
    return std::shared_ptr<shape>(new shape{std::move(type)});
}

#pragma mark - collider

collider::collider(shape_ptr &&shape) : _shape(observing::value::holder<shape_ptr>::make_shared(std::move(shape))) {
}

collider::~collider() = default;

void collider::set_shape(shape_ptr shape) {
    this->_shape->set_value(std::move(shape));
}

shape_ptr const &collider::shape() const {
    return this->_shape->value();
}

void collider::set_enabled(bool const enabled) {
    this->_enabled->set_value(enabled);
}

bool collider::is_enabled() const {
    return this->_enabled->value();
}

bool collider::hit_test(point const &loc) const {
    auto const &shape = this->_shape->value();
    if (shape && this->_enabled->value()) {
        auto pos = simd::float4x4(matrix_invert(this->_matrix)) * to_float4(loc.v);
        return shape->hit_test({pos.x, pos.y});
    }
    return false;
}

observing::canceller_ptr collider::observe_shape(observing::caller<shape_ptr>::handler_f &&handler, bool const sync) {
    return this->_shape->observe(std::move(handler), sync);
}

observing::canceller_ptr collider::observe_enabled(observing::caller<bool>::handler_f &&handler, bool const sync) {
    return this->_enabled->observe(std::move(handler), sync);
}

simd::float4x4 const &collider::matrix() const {
    return this->_matrix;
}

void collider::set_matrix(simd::float4x4 const &matrix) {
    this->_matrix = std::move(matrix);
}

collider_ptr collider::make_shared() {
    return make_shared(nullptr);
}

collider_ptr collider::make_shared(shape_ptr shape) {
    return std::shared_ptr<collider>(new collider{std::move(shape)});
}
