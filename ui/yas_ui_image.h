//
//  yas_ui_image.h
//

#pragma once

#include <functional>
#include "yas_base.h"
#include "yas_ui_types.h"

namespace yas {
namespace ui {
    class image : public base {
        using super_class = base;

       public:
        class impl;

        image(uint_size const point_size, double const scale_factor = 1.0);
        image(std::nullptr_t);

        uint_size point_size() const;
        uint_size actual_size() const;
        double scale_factor() const;

        const void *data() const;
        void *data();

        void clear();
        void draw(std::function<void(CGContextRef const)> const &);
    };
}

template <>
ui::image cast<ui::image>(base const &);
}
