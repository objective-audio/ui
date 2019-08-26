//
//  yas_ui_collider.cpp
//

#include "yas_ui_collider.h"
#include <cpp_utils/yas_to_bool.h>

using namespace yas;

#pragma mark - shape

bool ui::anywhere_shape::hit_test(ui::point const &) const {
    return true;
}

bool ui::circle_shape::hit_test(ui::point const &pos) const {
    return std::powf(pos.x - this->center.x, 2.0f) + std::powf(pos.y - this->center.y, 2.0f) <
           std::powf(this->radius, 2.0f);
}

bool ui::rect_shape::hit_test(ui::point const &pos) const {
    return contains(this->rect, pos);
}

struct ui::shape::impl_base {
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
        return this->_value.hit_test(pos);
    }
};

ui::shape::shape(anywhere::type &&shape) : _impl(std::make_shared<impl<anywhere>>(std::move(shape))) {
}

ui::shape::shape(circle::type &&shape) : _impl(std::make_shared<impl<circle>>(std::move(shape))) {
}

ui::shape::shape(rect::type &&shape) : _impl(std::make_shared<impl<rect>>(std::move(shape))) {
}

ui::shape::~shape() = default;

std::type_info const &ui::shape::type_info() const {
    return this->_impl->type();
}

bool ui::shape::hit_test(ui::point const &pos) const {
    return this->_impl->hit_test(pos);
}

template <typename T>
typename T::type const &ui::shape::get() const {
    if (auto ip = std::dynamic_pointer_cast<impl<T>>(this->_impl)) {
        return ip->_value;
    }

    static const typename T::type _default{};
    return _default;
}

template ui::anywhere_shape const &ui::shape::get<ui::shape::anywhere>() const;
template ui::circle_shape const &ui::shape::get<ui::shape::circle>() const;
template ui::rect_shape const &ui::shape::get<ui::shape::rect>() const;

ui::shape_ptr ui::shape::make_shared(anywhere::type type) {
    return std::shared_ptr<shape>(new shape{std::move(type)});
}

ui::shape_ptr ui::shape::make_shared(circle::type type) {
    return std::shared_ptr<shape>(new shape{std::move(type)});
}

ui::shape_ptr ui::shape::make_shared(rect::type type) {
    return std::shared_ptr<shape>(new shape{std::move(type)});
}

#pragma mark - collider

struct ui::collider::impl {
    simd::float4x4 _matrix = matrix_identity_float4x4;

    chaining::value::holder_ptr<ui::shape_ptr> _shape;
    chaining::value::holder_ptr<bool> _enabled = chaining::value::holder<bool>::make_shared(true);

    impl(ui::shape_ptr &&shape) : _shape(chaining::value::holder<ui::shape_ptr>::make_shared(std::move(shape))) {
    }

    bool hit_test(ui::point const &loc) {
        auto const &shape = this->_shape->raw();
        if (shape && this->_enabled->raw()) {
            auto pos = simd::float4x4(matrix_invert(this->_matrix)) * to_float4(loc.v);
            return shape->hit_test({pos.x, pos.y});
        }
        return false;
    }
};

ui::collider::collider() : _impl(std::make_unique<impl>(nullptr)) {
}

ui::collider::collider(ui::shape_ptr &&shape) : _impl(std::make_unique<impl>(std::move(shape))) {
}

ui::collider::~collider() = default;

void ui::collider::set_shape(ui::shape_ptr shape) {
    this->_impl->_shape->set_value(std::move(shape));
}

ui::shape_ptr const &ui::collider::shape() const {
    return this->_impl->_shape->raw();
}

void ui::collider::set_enabled(bool const enabled) {
    this->_impl->_enabled->set_value(enabled);
}

bool ui::collider::is_enabled() const {
    return this->_impl->_enabled->raw();
}

bool ui::collider::hit_test(ui::point const &pos) const {
    return this->_impl->hit_test(pos);
}

chaining::chain_sync_t<ui::shape_ptr> ui::collider::chain_shape() const {
    return this->_impl->_shape->chain();
}

chaining::chain_sync_t<bool> ui::collider::chain_enabled() const {
    return this->_impl->_enabled->chain();
}

chaining::receiver_ptr<ui::shape_ptr> ui::collider::shape_receiver() {
    return this->_impl->_shape;
}

chaining::receiver_ptr<bool> ui::collider::enabled_receiver() {
    return this->_impl->_enabled;
}

simd::float4x4 const &ui::collider::matrix() const {
    return this->_impl->_matrix;
}

void ui::collider::set_matrix(simd::float4x4 const &matrix) {
    this->_impl->_matrix = std::move(matrix);
}

ui::renderable_collider_ptr ui::collider::renderable() {
    return std::dynamic_pointer_cast<renderable_collider>(this->shared_from_this());
}

ui::collider_ptr ui::collider::make_shared() {
    return std::shared_ptr<collider>(new ui::collider{});
}

ui::collider_ptr ui::collider::make_shared(ui::shape_ptr shape) {
    return std::shared_ptr<collider>(new ui::collider{std::move(shape)});
}
