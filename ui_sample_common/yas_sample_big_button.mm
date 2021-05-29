//
//  yas_ui_big_button.mm
//

#include "yas_sample_big_button.h"
#include <cpp_utils/yas_each_index.h>
#include <ui/yas_ui_collider.h>

using namespace yas;
using namespace yas::ui;

#pragma mark - big_button

sample::big_button::big_button() {
    this->_button->rect_plane()->node()->set_collider(
        collider::make_shared(shape::make_shared(circle_shape{.radius = this->_radius})));
}

std::shared_ptr<button> &sample::big_button::button() {
    return this->_button;
}

void sample::big_button::set_texture(std::shared_ptr<texture> const &texture) {
    auto const &data = this->_button->rect_plane()->data();
    data->clear_observers();

    this->_button->rect_plane()->node()->mesh()->set_texture(texture);

    if (!texture) {
        return;
    }

    uint32_t const width = this->_radius * 2;

    uint_size image_size{width, width};

    auto element0 = texture->add_draw_handler(image_size, [image_size](CGContextRef const ctx) {
        CGContextSetFillColorWithColor(ctx, [yas_objc_color colorWithRed:0.3 green:0.3 blue:0.3 alpha:1.0].CGColor);
        CGContextFillEllipseInRect(ctx, CGRectMake(0, 0, image_size.width, image_size.height));
    });

    data->observe_rect_tex_coords(element0, 0);

    auto element1 = texture->add_draw_handler(image_size, [image_size](const CGContextRef ctx) {
        CGContextSetFillColorWithColor(ctx, [yas_objc_color redColor].CGColor);
        CGContextFillEllipseInRect(ctx, CGRectMake(0, 0, image_size.width, image_size.height));
    });

    data->observe_rect_tex_coords(element1, 1);
}

sample::big_button_ptr sample::big_button::make_shared() {
    return std::shared_ptr<big_button>(new big_button{});
}
