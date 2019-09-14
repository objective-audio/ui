//
//  yas_ui_image.h
//

#pragma once

#include <functional>
#include "yas_ui_ptr.h"
#include "yas_ui_texture_protocol.h"
#include "yas_ui_types.h"

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
    class impl;

    std::unique_ptr<impl> _impl;

    image(args const &);

    image(image const &) = delete;
    image(image &&) = delete;
    image &operator=(image const &) = delete;
    image &operator=(image &&) = delete;
};
}  // namespace yas::ui
