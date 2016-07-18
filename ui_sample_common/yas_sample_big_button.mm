//
//  yas_ui_big_button.mm
//

#include "yas_each_index.h"
#include "yas_sample_big_button.h"
#include "yas_ui_collider.h"

using namespace yas;

#pragma mark - big_button::impl

struct sample::big_button::impl : base::impl {
    impl() {
        _button.rect_plane().node().set_collider(ui::collider{ui::shape{ui::circle_shape{.radius = _radius}}});
    }

    void set_texture(ui::texture &&texture) {
        auto &mesh = _button.rect_plane().node().mesh();
        mesh.set_texture(texture);

        if (!texture) {
            return;
        }

        uint32_t const width = _radius * 2;

        auto &rect_plane_data = _button.rect_plane().data();

        ui::uint_size image_size{width, width};
        ui::image image{{.point_size = image_size, .scale_factor = texture.scale_factor()}};

        auto set_image_region = [&rect_plane_data](ui::uint_region const &pixel_region, bool const tracking) {
            std::size_t const rect_idx = tracking ? 1 : 0;
            rect_plane_data.set_rect_tex_coords(pixel_region, rect_idx);
        };

        image.draw([&image_size](const CGContextRef ctx) {
            CGContextSetFillColorWithColor(ctx, [yas_objc_color colorWithRed:0.3 green:0.3 blue:0.3 alpha:1.0].CGColor);
            CGContextFillEllipseInRect(ctx, CGRectMake(0, 0, image_size.width, image_size.height));
        });

        if (auto texture_result = texture.add_image(image)) {
            set_image_region(texture_result.value(), false);
        }

        image.clear();
        image.draw([&image_size](const CGContextRef ctx) {
            CGContextSetFillColorWithColor(ctx, [yas_objc_color redColor].CGColor);
            CGContextFillEllipseInRect(ctx, CGRectMake(0, 0, image_size.width, image_size.height));
        });

        if (auto texture_result = texture.add_image(image)) {
            set_image_region(texture_result.value(), true);
        }
    }

    float const _radius = 60;
    ui::button _button{{-_radius, -_radius, _radius * 2.0f, _radius * 2.0f}};
};

#pragma mark - big_button

sample::big_button::big_button() : base(std::make_shared<impl>()) {
}

sample::big_button::big_button(std::nullptr_t) : base(nullptr) {
}

void sample::big_button::set_texture(ui::texture texture) {
    impl_ptr<impl>()->set_texture(std::move(texture));
}

ui::button &sample::big_button::button() {
    return impl_ptr<impl>()->_button;
}
