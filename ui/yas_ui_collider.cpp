//
//  yas_ui_collider.cpp
//

#include "yas_to_bool.h"
#include "yas_ui_collider.h"

using namespace yas;

#pragma mark - shape

struct ui::shape::impl : base::impl {
    virtual bool hit_test(ui::point const &) {
        return false;
    }
};

ui::shape::shape(std::shared_ptr<impl> &&impl) : base(std::move(impl)) {
}

ui::shape::shape(std::nullptr_t) : base(nullptr) {
}

bool ui::shape::hit_test(ui::point const &pos) {
    return impl_ptr<impl>()->hit_test(pos);
}

struct ui::anywhere_shape::impl : ui::shape::impl {
    bool hit_test(ui::point const &) override {
        return true;
    }
};

ui::anywhere_shape::anywhere_shape() : ui::shape(std::make_shared<impl>()) {
}

ui::anywhere_shape::anywhere_shape(std::nullptr_t) : ui::shape(nullptr) {
}

struct ui::circle_shape::impl : ui::shape::impl {
    impl(args &&args) : _args(std::move(args)) {
    }

    bool hit_test(ui::point const &pos) override {
        return std::powf(pos.x - _args.center.x, 2.0f) + std::powf(pos.y - _args.center.y, 2.0f) <
               std::powf(_args.radius, 2.0f);
    }

    args _args;
};

ui::circle_shape::circle_shape(args args) : ui::shape(std::make_shared<impl>(std::move(args))) {
}

ui::circle_shape::circle_shape(std::nullptr_t) : ui::shape(nullptr) {
}

void ui::circle_shape::set_center(ui::point center) {
    impl_ptr<impl>()->_args.center = std::move(center);
}

void ui::circle_shape::set_radius(float const radius) {
    impl_ptr<impl>()->_args.radius = radius;
}

ui::point ui::circle_shape::center() const {
    return impl_ptr<impl>()->_args.center;
}

float ui::circle_shape::radius() const {
    return impl_ptr<impl>()->_args.radius;
}

struct ui::rect_shape::impl : ui::shape::impl {
    impl() {
    }

    impl(ui::float_region &&rect) : _rect(std::move(rect)) {
    }

    bool hit_test(ui::point const &pos) override {
        return contains(_rect, pos);
    }

    ui::float_region _rect = {-0.5f, -0.5f, 1.0f, 1.0f};
};

ui::rect_shape::rect_shape() : ui::shape(std::make_shared<impl>()) {
}

ui::rect_shape::rect_shape(ui::float_region rect) : ui::shape(std::make_shared<impl>(std::move(rect))) {
}

ui::rect_shape::rect_shape(std::nullptr_t) : ui::shape(nullptr) {
}

void ui::rect_shape::set_rect(ui::float_region rect) {
    impl_ptr<impl>()->_rect = std::move(rect);
}

ui::float_region const &ui::rect_shape::rect() const {
    return impl_ptr<impl>()->_rect;
}

#pragma mark - collider

struct ui::collider::impl : base::impl, renderable_collider::impl {
    impl() {
    }

    impl(ui::shape &&shape) : _shape(std::move(shape)) {
    }

    bool hit_test(ui::point const &loc) {
        if (_shape) {
            auto pos = simd::float4x4(matrix_invert(_matrix)) * to_float4(loc.v);
            return _shape.hit_test({pos.x, pos.y});
        }
        return false;
    }

    simd::float4x4 const &matrix() const override {
        return _matrix;
    }

    void set_matrix(simd::float4x4 &&matrix) override {
        _matrix = std::move(matrix);
    }

    ui::shape _shape = nullptr;

   private:
    simd::float4x4 _matrix = matrix_identity_float4x4;
};

ui::collider::collider() : base(std::make_shared<impl>()) {
}

ui::collider::collider(ui::shape shape) : base(std::make_shared<impl>(std::move(shape))) {
}

ui::collider::collider(std::nullptr_t) : base(nullptr) {
}

void ui::collider::set_shape(ui::shape shape) {
    impl_ptr<impl>()->_shape = std::move(shape);
}

ui::shape const &ui::collider::shape() const {
    return impl_ptr<impl>()->_shape;
}
bool ui::collider::hit_test(ui::point const &pos) const {
    return impl_ptr<impl>()->hit_test(pos);
}

ui::renderable_collider &ui::collider::renderable() {
    if (!_renderable) {
        _renderable = ui::renderable_collider{impl_ptr<ui::renderable_collider::impl>()};
    }
    return _renderable;
}

#pragma mark -

template <typename T>
T yas::cast(ui::shape const &src) {
    static_assert(std::is_base_of<ui::shape, T>(), "base class is not yas::ui::shape.");

    auto obj = T(nullptr);
    obj.set_impl_ptr(std::dynamic_pointer_cast<typename T::impl>(src.impl_ptr()));
    return obj;
}

template ui::anywhere_shape yas::cast<ui::anywhere_shape>(ui::shape const &);
template ui::circle_shape yas::cast<ui::circle_shape>(ui::shape const &);
template ui::rect_shape yas::cast<ui::rect_shape>(ui::shape const &);
