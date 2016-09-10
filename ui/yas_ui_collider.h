//
//  yas_ui_collider.h
//

#pragma once

#include <string>
#include "yas_base.h"
#include "yas_ui_collider_protocol.h"
#include "yas_ui_types.h"

namespace yas {
template <typename T, typename K>
class subject;
template <typename T, typename K>
class observer;

namespace ui {
    struct anywhere_shape {
        bool hit_test(ui::point const &) const;
    };

    struct circle_shape {
        ui::point center = {.v = 0.0f};
        float radius = 0.5f;

        bool hit_test(ui::point const &) const;
    };

    struct rect_shape {
        ui::region rect = {.origin = {-0.5f, -0.5f}, .size = {1.0f, 1.0f}};

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

        virtual ~shape() final;

        std::type_info const &type_info() const;

        bool hit_test(ui::point const &) const;

        template <typename T>
        typename T::type const &get() const;
    };

    class collider : public base {
       public:
        class impl;

        enum class method {
            shape_changed,
            enabled_changed,
        };

        using subject_t = subject<collider, method>;
        using observer_t = observer<collider, method>;

        collider();
        explicit collider(ui::shape);
        collider(std::nullptr_t);

        virtual ~collider() final;

        void set_shape(ui::shape);
        ui::shape const &shape() const;

        void set_enabled(bool const);
        bool is_enabled() const;

        bool hit_test(ui::point const &) const;

        subject_t &subject();
        void dispatch_method(ui::collider::method const);

        ui::renderable_collider &renderable();

       private:
        ui::renderable_collider _renderable = nullptr;
    };
}
}
