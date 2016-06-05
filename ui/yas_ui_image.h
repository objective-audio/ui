//
//  yas_ui_image.h
//

#pragma once

#include <CoreGraphics/CoreGraphics.h>
#include <functional>
#include "yas_base.h"

namespace yas {
namespace ui {
    class uint_size;

    class image : public base {
       public:
        class impl;

        image(ui::uint_size const point_size, double const scale_factor = 1.0);
        image(std::nullptr_t);

        ui::uint_size point_size() const;
        ui::uint_size actual_size() const;
        double scale_factor() const;

        const void *data() const;
        void *data();

        void clear();
        void draw(std::function<void(CGContextRef const)> const &);
    };
}
}
