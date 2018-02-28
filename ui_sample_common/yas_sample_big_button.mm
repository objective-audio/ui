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
        this->_button.rect_plane().node().set_collider(
            ui::collider{ui::shape{ui::circle_shape{.radius = this->_radius}}});
    }

    void set_texture(ui::texture &&texture) {
        this->_element_observers.clear();

        auto &mesh = this->_button.rect_plane().node().mesh();
        mesh.set_texture(texture);

        if (!texture) {
            return;
        }

        uint32_t const width = this->_radius * 2;

        auto weak_button = to_weak(this->_button);

        ui::uint_size image_size{width, width};

        auto texture_element = texture.add_image_handler(image_size, [](ui::image &image) {
            image.draw([image_size = image.point_size()](const CGContextRef ctx) {
                CGContextSetFillColorWithColor(ctx,
                                               [yas_objc_color colorWithRed:0.3 green:0.3 blue:0.3 alpha:1.0].CGColor);
                CGContextFillEllipseInRect(ctx, CGRectMake(0, 0, image_size.width, image_size.height));
            });
        });

        this->_button.rect_plane().data().set_rect_tex_coords(texture_element.tex_coords(), 0);

        this->_element_observers.emplace_back(texture_element.subject().make_observer(
            ui::texture_element::method::tex_coords_changed, [weak_button](auto const &context) {
                if (auto button = weak_button.lock()) {
                    ui::texture_element const &element = context.value;
                    button.rect_plane().data().set_rect_tex_coords(element.tex_coords(), 0);
                }
            }));

        texture_element = texture.add_image_handler(image_size, [](ui::image &image) {
            image.draw([image_size = image.point_size()](const CGContextRef ctx) {
                CGContextSetFillColorWithColor(ctx, [yas_objc_color redColor].CGColor);
                CGContextFillEllipseInRect(ctx, CGRectMake(0, 0, image_size.width, image_size.height));
            });
        });

        this->_button.rect_plane().data().set_rect_tex_coords(texture_element.tex_coords(), 1);

        this->_element_observers.emplace_back(texture_element.subject().make_observer(
            ui::texture_element::method::tex_coords_changed, [weak_button](auto const &context) {
                if (auto button = weak_button.lock()) {
                    ui::texture_element const &element = context.value;
                    button.rect_plane().data().set_rect_tex_coords(element.tex_coords(), 1);
                }
            }));
    }

    float const _radius = 60;
    ui::button _button{
        {.origin = {-this->_radius, -this->_radius}, .size = {this->_radius * 2.0f, this->_radius * 2.0f}}};
    std::vector<ui::texture_element::observer_t> _element_observers;
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
