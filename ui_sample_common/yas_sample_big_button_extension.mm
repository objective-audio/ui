//
//  yas_ui_big_button_extension.mm
//

#include "yas_each_index.h"
#include "yas_sample_big_button_extension.h"
#include "yas_ui_collider.h"

using namespace yas;

#pragma mark - big_button_extension::impl

struct sample::big_button_extension::impl : base::impl {
    impl() {
        _button_ext.rect_plane_extension().node().set_collider(
            ui::collider{ui::shape{ui::circle_shape{.radius = _radius}}});
    }

    void set_texture(ui::texture &&texture) {
        auto &mesh = _button_ext.rect_plane_extension().node().mesh();
        mesh.set_texture(texture);

        if (!texture) {
            return;
        }

        uint32_t const width = _radius * 2;

        auto &rect_plane_data = _button_ext.rect_plane_extension().data();

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
    ui::button_extension _button_ext{{-_radius, -_radius, _radius * 2.0f, _radius * 2.0f}};
};

#pragma mark - big_button_extension

sample::big_button_extension::big_button_extension() : base(std::make_shared<impl>()) {
}

sample::big_button_extension::big_button_extension(std::nullptr_t) : base(nullptr) {
}

void sample::big_button_extension::set_texture(ui::texture texture) {
    impl_ptr<impl>()->set_texture(std::move(texture));
}

ui::button_extension &sample::big_button_extension::button_extension() {
    return impl_ptr<impl>()->_button_ext;
}
