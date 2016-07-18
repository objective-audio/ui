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
    class shape : public base {
       public:
        class impl;

        shape(std::nullptr_t);

        bool hit_test(ui::point const &);

       protected:
        shape(std::shared_ptr<impl> &&);
    };

    class anywhere_shape : public shape {
       public:
        class impl;

        anywhere_shape();
        anywhere_shape(std::nullptr_t);
    };

    class circle_shape : public shape {
       public:
        class impl;

        struct args {
            ui::point center = 0.0f;
            float radius = 0.5f;
        };

        explicit circle_shape(args);
        circle_shape(std::nullptr_t);

        void set_center(ui::point);
        void set_radius(float const);

        ui::point center() const;
        float radius() const;
    };

    class rect_shape : public shape {
       public:
        class impl;

        rect_shape();
        explicit rect_shape(ui::float_region);
        rect_shape(std::nullptr_t);

        void set_rect(ui::float_region);
        ui::float_region const &rect() const;
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

template <typename T>
T cast(ui::shape const &);
}
