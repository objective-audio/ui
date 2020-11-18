//
//  yas_ui_image.h
//

#pragma once

#include <ui/yas_ui_ptr.h>
#include <ui/yas_ui_texture_protocol.h>
#include <ui/yas_ui_types.h>

#include <functional>

namespace yas::ui {
struct image final {
    struct args {
        ui::uint_size point_size;
        double scale_factor = 1.0;
    };

    virtual ~image();

    ui::uint_size point_size() const;
    ui::uint_size actual_size() const;
    double scale_factor() const;

    void const *data() const;
    void *data();

    void clear();
    void draw(ui::draw_handler_f const &);

    [[nodiscard]] static image_ptr make_shared(args const &);

   private:
    uint_size _point_size;
    double _scale_factor;
    uint_size _actual_size;
    CGContextRef _bitmap_context;

    image(args const &);

    image(image const &) = delete;
    image(image &&) = delete;
    image &operator=(image const &) = delete;
    image &operator=(image &&) = delete;
};
}  // namespace yas::ui
