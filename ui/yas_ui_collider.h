//
//  yas_ui_collider.h
//

#pragma once

#include <string>
#include "yas_base.h"
#include "yas_ui_collider_protocol.h"

namespace yas {
namespace ui {
    enum class collider_shape {
        none,
        anywhere,
        circle,
        square,
    };

    struct collider_args {
        collider_shape shape = collider_shape::none;
        simd::float2 center = 0.0f;
        float radius = 0.5f;
    };

    class collider : public base {
        class impl;

       public:
        collider();
        collider(collider_args);
        collider(std::nullptr_t);

        void set_shape(collider_shape);
        void set_center(simd::float2);
        void set_radius(float const);

        collider_shape shape() const;
        simd::float2 const &center() const;
        float radius() const;

        bool hit_test(simd::float2 const &) const;

        renderable_collider renderable();
    };
}

std::string to_string(ui::collider_shape const &);
}

std::ostream &operator<<(std::ostream &, yas::ui::collider_shape const &);
