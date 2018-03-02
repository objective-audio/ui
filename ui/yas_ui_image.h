//
//  yas_ui_image.h
//

#pragma once

#include <CoreGraphics/CoreGraphics.h>
#include <functional>
#include "yas_base.h"
#include "yas_ui_types.h"

namespace yas::ui {
class uint_size;

class image : public base {
   public:
    class impl;

    struct args {
        ui::uint_size point_size;
        double scale_factor = 1.0;
    };
    
    using draw_handler_f = std::function<void(CGContextRef const)>;

    image(args);
    image(std::nullptr_t);

    virtual ~image() final;

    ui::uint_size point_size() const;
    ui::uint_size actual_size() const;
    double scale_factor() const;

    const void *data() const;
    void *data();

    void clear();
    void draw(draw_handler_f const &);
};
}
