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
        return this->_value.hit_test(pos);
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
    chaining::value::holder<ui::shape> _shape{ui::shape{nullptr}};
    chaining::value::holder<bool> _enabled{true};

    impl(ui::shape &&shape) : _shape(std::move(shape)) {
    }

    bool hit_test(ui::point const &loc) {
        auto const &shape = this->_shape.raw();
        if (shape && this->_enabled.raw()) {
            auto pos = simd::float4x4(matrix_invert(this->_matrix)) * to_float4(loc.v);
            return shape.hit_test({pos.x, pos.y});
        }
        return false;
    }

    simd::float4x4 const &matrix() const override {
        return this->_matrix;
    }

    void set_matrix(simd::float4x4 &&matrix) override {
        this->_matrix = std::move(matrix);
    }

   private:
    simd::float4x4 _matrix = matrix_identity_float4x4;
};

ui::collider::collider() : base(std::make_shared<impl>(nullptr)) {
}

ui::collider::collider(ui::shape shape) : base(std::make_shared<impl>(std::move(shape))) {
}

ui::collider::collider(std::nullptr_t) : base(nullptr) {
}

ui::collider::~collider() = default;

void ui::collider::set_shape(ui::shape shape) {
    impl_ptr<impl>()->_shape.set_value(std::move(shape));
}

ui::shape const &ui::collider::shape() const {
    return impl_ptr<impl>()->_shape.raw();
}

void ui::collider::set_enabled(bool const enabled) {
    impl_ptr<impl>()->_enabled.set_value(enabled);
}

bool ui::collider::is_enabled() const {
    return impl_ptr<impl>()->_enabled.raw();
}

bool ui::collider::hit_test(ui::point const &pos) const {
    return impl_ptr<impl>()->hit_test(pos);
}

chaining::chain_sync_t<ui::shape> ui::collider::chain_shape() const {
    return impl_ptr<impl>()->_shape.chain();
}

chaining::chain_sync_t<bool> ui::collider::chain_enabled() const {
    return impl_ptr<impl>()->_enabled.chain();
}

chaining::receiver<ui::shape> &ui::collider::shape_receiver() {
    return impl_ptr<impl>()->_shape.receiver();
}

chaining::receiver<bool> &ui::collider::enabled_receiver() {
    return impl_ptr<impl>()->_enabled.receiver();
}

ui::renderable_collider &ui::collider::renderable() {
    if (!this->_renderable) {
        this->_renderable = ui::renderable_collider{impl_ptr<ui::renderable_collider::impl>()};
    }
    return this->_renderable;
}
