//
//  yas_ui_button_node.mm
//

#include "yas_each_index.h"
#include "yas_sample_button_node.h"
#include "yas_ui_collider.h"

using namespace yas;

#pragma mark - button_node::impl

struct sample::button_node::impl : base::impl {
    void set_texture(ui::texture &&texture) {
        auto &mesh = _button.square().node().mesh();
        mesh.set_texture(texture);

        if (!texture) {
            return;
        }

        uint32_t const width = radius * 2;

        auto &square_mesh_data = _button.square().square_mesh_data();

        ui::uint_size image_size{width, width};
        ui::image image{{.point_size = image_size, .scale_factor = texture.scale_factor()}};

        auto set_image_region = [&square_mesh_data](ui::uint_region const &pixel_region, bool const tracking) {
            std::size_t const sq_idx = tracking ? 1 : 0;
            square_mesh_data.set_square_tex_coords(pixel_region, sq_idx);
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

    float const radius = 60;
    ui::button _button{{-radius, -radius, radius * 2.0f, radius * 2.0f}};
};

#pragma mark - button_node

sample::button_node::button_node() : base(std::make_shared<impl>()) {
}

sample::button_node::button_node(std::nullptr_t) : base(nullptr) {
}

void sample::button_node::set_texture(ui::texture texture) {
    impl_ptr<impl>()->set_texture(std::move(texture));
}

ui::button &sample::button_node::button() {
    return impl_ptr<impl>()->_button;
}
