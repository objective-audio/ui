//
//  yas_ui_image.h
//

#pragma once

#include <ui/yas_ui_image_types.h>
#include <ui/yas_ui_ptr.h>

#include <functional>

namespace yas::ui {
struct image final {
    virtual ~image();

    [[nodiscard]] ui::uint_size point_size() const;
    [[nodiscard]] ui::uint_size actual_size() const;
    [[nodiscard]] double scale_factor() const;

    [[nodiscard]] void const *data() const;
    [[nodiscard]] void *data();

    void clear();
    void draw(ui::draw_handler_f const &);

    [[nodiscard]] static image_ptr make_shared(image_args &&);

   private:
    uint_size _point_size;
    double _scale_factor;
    uint_size _actual_size;
    CGContextRef _bitmap_context;

    image(image_args &&);

    image(image const &) = delete;
    image(image &&) = delete;
    image &operator=(image const &) = delete;
    image &operator=(image &&) = delete;
};
}  // namespace yas::ui
