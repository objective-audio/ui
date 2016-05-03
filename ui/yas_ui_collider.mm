//
//  yas_ui_collider.cpp
//

#include "yas_ui_collider.h"

using namespace yas;

struct ui::collider::impl : base::impl, renderable_collider::impl {
    ui::collider_args args;

    impl() {
    }

    impl(collider_args &&args) : args(std::move(args)) {
    }

    bool hit_test(ui::point const &loc) {
        auto const &shape = args.shape;

        if (shape == ui::collider_shape::none) {
            return false;
        } else if (shape == ui::collider_shape::anywhere) {
            return true;
        }

        auto pos = simd::float4x4(matrix_invert(_matrix)) * simd::float4{loc.x, loc.y, 0, 1};

        if (shape == ui::collider_shape::circle) {
            return std::powf(pos.x - args.center.x, 2) + std::powf(pos.y - args.center.y, 2) <
                   std::powf(args.radius, 2);
        } else if (shape == ui::collider_shape::square) {
            return contains(
                {-args.radius + args.center.x, -args.radius + args.center.y, args.radius * 2.0f, args.radius * 2.0f},
                {pos.x, pos.y});
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
};

ui::collider::collider() : base(std::make_shared<impl>()) {
}

ui::collider::collider(collider_args args) : base(std::make_shared<impl>(std::move(args))) {
}

ui::collider::collider(std::nullptr_t) : base(nullptr) {
}

void ui::collider::set_shape(collider_shape shape) {
    impl_ptr<impl>()->args.shape = std::move(shape);
}

void ui::collider::set_center(ui::point center) {
    impl_ptr<impl>()->args.center = std::move(center);
}

void ui::collider::set_radius(float const radius) {
    impl_ptr<impl>()->args.radius = radius;
}

ui::collider_shape ui::collider::shape() const {
    return impl_ptr<impl>()->args.shape;
}

ui::point const &ui::collider::center() const {
    return impl_ptr<impl>()->args.center;
}

float ui::collider::radius() const {
    return impl_ptr<impl>()->args.radius;
}

bool ui::collider::hit_test(ui::point const &pos) const {
    return impl_ptr<impl>()->hit_test(pos);
}

ui::renderable_collider ui::collider::renderable() {
    return ui::renderable_collider{impl_ptr<ui::renderable_collider::impl>()};
}

#pragma mark -

std::string yas::to_string(ui::collider_shape const &shape) {
    switch (shape) {
        case ui::collider_shape::none:
            return "none";
        case ui::collider_shape::anywhere:
            return "anywhere";
        case ui::collider_shape::circle:
            return "circle";
        case ui::collider_shape::square:
            return "square";
    }
}

std::ostream &operator<<(std::ostream &os, yas::ui::collider_shape const &shape) {
    os << to_string(shape);
    return os;
}
