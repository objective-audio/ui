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
    enum class collider_shape {
        none,
        anywhere,
        circle,
        square,
    };

    struct collider_args {
        collider_shape shape = collider_shape::none;
        ui::point center = 0.0f;
        float radius = 0.5f;
    };

    class collider : public base {
        class impl;

       public:
        collider();
        explicit collider(collider_args);
        collider(std::nullptr_t);

        void set_shape(collider_shape);
        void set_center(ui::point);
        void set_radius(float const);

        collider_shape shape() const;
        ui::point const &center() const;
        float radius() const;

        bool hit_test(ui::point const &) const;

        ui::renderable_collider &renderable();

       private:
        ui::renderable_collider _renderable = nullptr;
    };
}

std::string to_string(ui::collider_shape const &);
}

std::ostream &operator<<(std::ostream &, yas::ui::collider_shape const &);
