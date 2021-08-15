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

std::type_info const &shape::type_info() const {
    return this->_impl->type();
}

bool shape::hit_test(point const &pos) const {
    return this->_impl->hit_test(pos);
}

std::shared_ptr<shape> shape::make_shared(anywhere::type type) {
    return std::shared_ptr<shape>(new shape{std::move(type)});
}

std::shared_ptr<shape> shape::make_shared(circle::type type) {
    return std::shared_ptr<shape>(new shape{std::move(type)});
}

std::shared_ptr<shape> shape::make_shared(rect::type type) {
    return std::shared_ptr<shape>(new shape{std::move(type)});
}

#pragma mark - collider

collider::collider(std::shared_ptr<ui::shape> &&shape)
    : _shape(observing::value::holder<std::shared_ptr<ui::shape>>::make_shared(std::move(shape))) {
}

void collider::set_shape(std::shared_ptr<ui::shape> shape) {
    this->_shape->set_value(std::move(shape));
}

std::shared_ptr<shape> const &collider::shape() const {
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

observing::syncable collider::observe_shape(observing::caller<std::shared_ptr<ui::shape>>::handler_f &&handler) {
    return this->_shape->observe(std::move(handler));
}

observing::syncable collider::observe_enabled(observing::caller<bool>::handler_f &&handler) {
    return this->_enabled->observe(std::move(handler));
}

simd::float4x4 const &collider::matrix() const {
    return this->_matrix;
}

void collider::set_matrix(simd::float4x4 const &matrix) {
    this->_matrix = std::move(matrix);
}

std::shared_ptr<collider> collider::make_shared() {
    return make_shared(nullptr);
}

std::shared_ptr<collider> collider::make_shared(std::shared_ptr<ui::shape> shape) {
    return std::shared_ptr<collider>(new collider{std::move(shape)});
}
