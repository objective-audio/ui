//
//  yas_ui_collider.h
//

#pragma once

#include <string>
#include "yas_base.h"
#include "yas_ui_collider_protocol.h"
#include "yas_ui_types.h"

namespace yas {
namespace ui {
    struct anywhere_shape {
        bool hit_test(ui::point const &) const;
    };

    struct circle_shape {
        ui::point center = 0.0f;
        float radius = 0.5f;

        bool hit_test(ui::point const &) const;
    };

    struct rect_shape {
        ui::float_region rect = {-0.5f, -0.5f, 1.0f, 1.0f};

        bool hit_test(ui::point const &pos) const;
    };

    class shape : public base {
       public:
        class impl_base;

        template <typename T>
        class impl;

        struct anywhere {
            using type = anywhere_shape;
        };

        struct circle {
            using type = circle_shape;
        };

        struct rect {
            using type = rect_shape;
        };

        explicit shape(anywhere::type);
        explicit shape(circle::type);
        explicit shape(rect::type);
        shape(std::nullptr_t);

        std::type_info const &type_info() const;

        bool hit_test(ui::point const &) const;

        template <typename T>
        typename T::type const &get() const;
    };

    class collider : public base {
        class impl;

       public:
        collider();
        explicit collider(ui::shape);
        collider(std::nullptr_t);

        void set_shape(ui::shape);
        ui::shape const &shape() const;

        bool hit_test(ui::point const &) const;

        ui::renderable_collider &renderable();

       private:
        ui::renderable_collider _renderable = nullptr;
    };
}
}
