//
//  yas_ui_texture.mm
//

#include "yas_ui_texture.h"
#include <cpp_utils/yas_objc_ptr.h>
#include <cpp_utils/yas_stl_utils.h>
#include <cpp_utils/yas_unless.h>
#include <ui/yas_ui_image.h>
#include <ui/yas_ui_metal_texture.h>
#include <ui/yas_ui_metal_types.h>
#include <ui/yas_ui_renderer.h>
#include <ui/yas_ui_texture_element.h>
#include <ui/yas_ui_view_look.h>
#include <map>

using namespace yas;
using namespace yas::ui;

namespace yas::ui {
enum class draw_image_error {
    unknown,
    image_is_null,
    no_setup,
    out_of_range,
};
}

namespace yas {
std::string to_string(draw_image_error const &);
}

std::ostream &operator<<(std::ostream &, yas::ui::draw_image_error const &);

texture::texture(texture_args &&args, std::shared_ptr<scale_factor_observable> const &view_look)
    : _draw_actual_padding(args.draw_padding * view_look->scale_factor()),
      _draw_actual_pos({_draw_actual_padding, _draw_actual_padding}),
      _point_size(std::move(args.point_size)),
      _scale_factor(view_look->scale_factor()),
      _usages(args.usages),
      _pixel_format(args.pixel_format) {
    view_look->observe_scale_factor([this](double const &scale) { this->set_scale_factor(scale); })
        .sync()
        ->add_to(this->_pool);
}

uintptr_t texture::identifier() const {
    return reinterpret_cast<uintptr_t>(this);
}

uint_size texture::point_size() const {
    return this->_point_size;
}

uint_size texture::actual_size() const {
    uint_size const &point_size = this->_point_size;
    double const &scale_factor = this->_scale_factor;
    return {static_cast<uint32_t>(point_size.width * scale_factor),
            static_cast<uint32_t>(point_size.height * scale_factor)};
}

double texture::scale_factor() const {
    return this->_scale_factor;
}

uint32_t texture::depth() const {
    return this->_depth;
}

bool texture::has_alpha() const {
    return this->_has_alpha;
}

void texture::set_point_size(uint_size size) {
    if (this->_point_size != size) {
        this->_point_size = size;
        this->_size_updated();
    }
}

void texture::set_scale_factor(double const scale_factor) {
    if (this->_scale_factor != scale_factor) {
        this->_scale_factor = scale_factor;
        this->_size_updated();
    }
}

std::shared_ptr<texture_element> const &texture::add_draw_handler(uint_size size, draw_handler_f handler) {
    auto element = texture_element::make_shared(std::make_pair(std::move(size), std::move(handler)));

    if (this->_metal_texture) {
        this->_add_image_to_metal_texture(element);
    }

    this->_texture_elements.emplace_back(std::move(element));
    return this->_texture_elements.back();
}

void texture::remove_draw_handler(std::shared_ptr<texture_element> const &erase_element) {
    std::erase_if(this->_texture_elements, [&erase_element](std::shared_ptr<texture_element> const &element) {
        return element == erase_element;
    });
}

std::shared_ptr<metal_texture> const &texture::metal_texture() const {
    return this->_metal_texture;
}

observing::endable texture::observe_metal_texture_changed(std::function<void(std::nullptr_t const &)> &&handler) {
    return this->_texture_notifier->observe(std::move(handler));
}

observing::endable texture::observe_size_updated(std::function<void(std::nullptr_t const &)> &&handler) {
    return this->_size_notifier->observe(std::move(handler));
}

setup_metal_result texture::metal_setup(std::shared_ptr<metal_system> const &metal_system) {
    if (this->_metal_system != metal_system) {
        this->_metal_system = metal_system;
        this->_metal_texture = nullptr;
        this->_gl_texture = nullptr;
    }

    if (!this->_metal_texture) {
        if (auto result = metal_system->make_texture(this->actual_size(), this->_usages, this->_pixel_format)) {
            this->_metal_texture = result.value();
            this->_gl_texture = this->_metal_texture;
        } else {
            return setup_metal_result{result.error()};
        }

        this->_add_images_to_metal_texture();

        this->_texture_notifier->notify(nullptr);
    }

    return setup_metal_result{nullptr};
}

draw_image_result texture::_reserve_image_size(std::shared_ptr<image> const &image) {
    if (!image) {
        return draw_image_result{draw_image_error::image_is_null};
    }

    auto const actual_image_size = image->actual_size();

    this->_prepare_draw_pos(actual_image_size);

    if (!this->_can_draw(actual_image_size)) {
        return draw_image_result{draw_image_error::out_of_range};
    }

    uint_point const origin = this->_draw_actual_pos;

    this->_move_draw_pos(actual_image_size);

    return draw_image_result{uint_region{.origin = origin, .size = actual_image_size}};
}

draw_image_result texture::_replace_image(std::shared_ptr<image> const &image, uint_point const origin) {
    if (!image) {
        return draw_image_result{draw_image_error::image_is_null};
    }

    if (!this->_gl_texture->is_ready()) {
        return draw_image_result{draw_image_error::no_setup};
    }

    auto const region = uint_region{origin, image->actual_size()};

    this->_gl_texture->replace_data(region, image->data());

    return draw_image_result{std::move(region)};
}

void texture::_prepare_draw_pos(uint_size const size) {
    if (this->actual_size().width < (this->_draw_actual_pos.x + size.width + this->_draw_actual_padding)) {
        this->_move_draw_pos(size);
    }
}

void texture::_move_draw_pos(uint_size const size) {
    this->_draw_actual_pos.x += size.width + this->_draw_actual_padding;

    if (this->actual_size().width < this->_draw_actual_pos.x) {
        this->_draw_actual_pos.y += this->_max_line_height + this->_draw_actual_padding;
        this->_max_line_height = 0;
        this->_draw_actual_pos.x = this->_draw_actual_padding;
    }

    if (this->_max_line_height < size.height) {
        this->_max_line_height = size.height;
    }
}

bool texture::_can_draw(uint_size const size) {
    uint_size const actual_size = this->actual_size();
    if ((actual_size.width < this->_draw_actual_pos.x + size.width + this->_draw_actual_padding) ||
        (actual_size.height < this->_draw_actual_pos.y + size.height + this->_draw_actual_padding)) {
        return false;
    }

    return true;
}

void texture::_add_images_to_metal_texture() {
    for (auto const &element : this->_texture_elements) {
        this->_add_image_to_metal_texture(element);
    }
}

void texture::_add_image_to_metal_texture(std::shared_ptr<texture_element> const &element) {
    if (!this->_metal_texture) {
        throw std::runtime_error("metal_texture not found.");
    }

    auto const &pair = element->draw_pair();
    auto const &point_size = pair.first;
    auto const &draw_handler = pair.second;

    auto image = image::make_shared({.point_size = point_size, .scale_factor = this->_scale_factor});

    if (auto reserve_result = this->_reserve_image_size(image)) {
        if (draw_handler) {
            auto const &tex_coords = reserve_result.value();
            element->set_tex_coords(tex_coords);
            image->draw(draw_handler);
            this->_replace_image(image, tex_coords.origin);
        }
    }
}

void texture::_size_updated() {
    this->_metal_texture = nullptr;
    this->_draw_actual_pos = {this->_draw_actual_padding, this->_draw_actual_padding};
    this->_size_notifier->notify(nullptr);
}

std::shared_ptr<texture> texture::make_shared(texture_args &&args,
                                              std::shared_ptr<scale_factor_observable> const &view_look) {
    return std::shared_ptr<texture>(new texture{std::move(args), view_look});
}

#pragma mark -

std::string yas::to_string(draw_image_error const &error) {
    switch (error) {
        case draw_image_error::image_is_null:
            return "image_is_null";
        case draw_image_error::no_setup:
            return "no_setup";
        case draw_image_error::out_of_range:
            return "out_of_range";
        default:
            return "unknown";
    }
}

std::ostream &operator<<(std::ostream &os, yas::ui::draw_image_error const &error) {
    os << to_string(error);
    return os;
}
