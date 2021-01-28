//
//  yas_ui_texture.mm
//

#include "yas_ui_texture.h"
#include <cpp_utils/yas_objc_ptr.h>
#include <cpp_utils/yas_stl_utils.h>
#include <cpp_utils/yas_unless.h>
#include <map>
#include "yas_ui_image.h"
#include "yas_ui_metal_texture.h"
#include "yas_ui_metal_types.h"
#include "yas_ui_renderer.h"
#include "yas_ui_texture_element.h"

using namespace yas;

namespace yas::ui {
enum class draw_image_error {
    unknown,
    image_is_null,
    no_setup,
    out_of_range,
};
}

namespace yas {
std::string to_string(ui::draw_image_error const &);
}

std::ostream &operator<<(std::ostream &, yas::ui::draw_image_error const &);

ui::texture::texture(args &&args)
    : _draw_actual_padding(args.draw_padding * args.scale_factor),
      _draw_actual_pos({_draw_actual_padding, _draw_actual_padding}),
      _point_size(std::move(args.point_size)),
      _scale_factor(std::move(args.scale_factor)),
      _usages(args.usages),
      _pixel_format(args.pixel_format) {
}

uintptr_t ui::texture::identifier() const {
    return reinterpret_cast<uintptr_t>(this);
}

ui::uint_size ui::texture::point_size() const {
    return this->_point_size;
}

ui::uint_size ui::texture::actual_size() const {
    ui::uint_size const &point_size = this->_point_size;
    double const &scale_factor = this->_scale_factor;
    return {static_cast<uint32_t>(point_size.width * scale_factor),
            static_cast<uint32_t>(point_size.height * scale_factor)};
}

double ui::texture::scale_factor() const {
    return this->_scale_factor;
}

uint32_t ui::texture::depth() const {
    return this->_depth;
}

bool ui::texture::has_alpha() const {
    return this->_has_alpha;
}

void ui::texture::set_point_size(ui::uint_size size) {
    if (this->_point_size != size) {
        this->_point_size = size;
        this->_size_updated();
    }
}

void ui::texture::set_scale_factor(double const scale_factor) {
    if (this->_scale_factor != scale_factor) {
        this->_scale_factor = scale_factor;
        this->_size_updated();
    }
}

ui::texture_element_ptr const &ui::texture::add_draw_handler(ui::uint_size size, ui::draw_handler_f handler) {
    auto element = texture_element::make_shared(std::make_pair(std::move(size), std::move(handler)));

    if (this->_metal_texture) {
        this->_add_image_to_metal_texture(element);
    }

    this->_texture_elements.emplace_back(std::move(element));
    return this->_texture_elements.back();
}

void ui::texture::remove_draw_handler(texture_element_ptr const &erase_element) {
    erase_if(this->_texture_elements,
             [&erase_element](texture_element_ptr const &element) { return element == erase_element; });
}

ui::metal_texture_ptr const &ui::texture::metal_texture() const {
    return this->_metal_texture;
}

observing::canceller_ptr ui::texture::observe(observing::caller<chain_pair_t>::handler_f &&handler) {
    return this->_notifier->observe(std::move(handler));
}

void ui::texture::sync_scale_from_renderer(ui::renderer_ptr const &renderer) {
    this->_scale_canceller =
        renderer->observe_scale_factor([this](double const &scale) { this->set_scale_factor(scale); }, true);
}

void ui::texture::_prepare(texture_ptr const &texture) {
    this->_weak_texture = texture;
}

ui::setup_metal_result ui::texture::metal_setup(std::shared_ptr<ui::metal_system> const &metal_system) {
    if (this->_metal_system != metal_system) {
        this->_metal_system = metal_system;
        this->_metal_texture = nullptr;
    }

    if (!this->_metal_texture) {
        this->_metal_texture = ui::metal_texture::make_shared(this->actual_size(), this->_usages, this->_pixel_format);

        if (auto ul = unless(ui::metal_object::cast(this->_metal_texture)->metal_setup(metal_system))) {
            return ul.value;
        }

        this->_add_images_to_metal_texture();

        if (auto texture = this->_weak_texture.lock()) {
            texture->_notifier->notify(std::make_pair(method::metal_texture_changed, texture));
        }
    }

    return ui::setup_metal_result{nullptr};
}

ui::draw_image_result ui::texture::_reserve_image_size(image_ptr const &image) {
    if (!image) {
        return draw_image_result{draw_image_error::image_is_null};
    }

    auto const actual_image_size = image->actual_size();

    this->_prepare_draw_pos(actual_image_size);

    if (!this->_can_draw(actual_image_size)) {
        return draw_image_result{draw_image_error::out_of_range};
    }

    ui::uint_point const origin = this->_draw_actual_pos;

    this->_move_draw_pos(actual_image_size);

    return draw_image_result{ui::uint_region{.origin = origin, .size = actual_image_size}};
}

ui::draw_image_result ui::texture::_replace_image(image_ptr const &image, uint_point const origin) {
    if (!image) {
        return draw_image_result{draw_image_error::image_is_null};
    }

    if (!this->_metal_texture->texture() || !this->_metal_texture->samplerState()) {
        return draw_image_result{draw_image_error::no_setup};
    }

    auto region = uint_region{origin, image->actual_size()};

    if (id<MTLTexture> texture = this->_metal_texture->texture()) {
        [texture replaceRegion:to_mtl_region(region)
                   mipmapLevel:0
                     withBytes:image->data()
                   bytesPerRow:region.size.width * 4];
    }

    return draw_image_result{std::move(region)};
}

void ui::texture::_prepare_draw_pos(uint_size const size) {
    if (this->actual_size().width < (this->_draw_actual_pos.x + size.width + this->_draw_actual_padding)) {
        this->_move_draw_pos(size);
    }
}

void ui::texture::_move_draw_pos(uint_size const size) {
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

bool ui::texture::_can_draw(uint_size const size) {
    ui::uint_size const actual_size = this->actual_size();
    if ((actual_size.width < this->_draw_actual_pos.x + size.width + this->_draw_actual_padding) ||
        (actual_size.height < this->_draw_actual_pos.y + size.height + this->_draw_actual_padding)) {
        return false;
    }

    return true;
}

void ui::texture::_add_images_to_metal_texture() {
    for (auto const &element : this->_texture_elements) {
        this->_add_image_to_metal_texture(element);
    }
}

void ui::texture::_add_image_to_metal_texture(texture_element_ptr const &element) {
    if (!this->_metal_texture) {
        throw std::runtime_error("metal_texture not found.");
    }

    auto const &pair = element->draw_pair();
    auto const &point_size = pair.first;
    auto const &draw_handler = pair.second;

    auto image = ui::image::make_shared({.point_size = point_size, .scale_factor = this->_scale_factor});

    if (auto reserve_result = this->_reserve_image_size(image)) {
        if (draw_handler) {
            auto const &tex_coords = reserve_result.value();
            element->set_tex_coords(tex_coords);
            image->draw(draw_handler);
            this->_replace_image(image, tex_coords.origin);
        }
    }
}

void ui::texture::_size_updated() {
    this->_metal_texture = nullptr;
    this->_draw_actual_pos = {this->_draw_actual_padding, this->_draw_actual_padding};
    this->_notifier->notify(std::make_pair(method::size_updated, this->_weak_texture.lock()));
}

ui::texture_ptr ui::texture::make_shared(args args) {
    auto shared = std::shared_ptr<texture>(new texture{std::move(args)});
    shared->_prepare(shared);
    return shared;
}

#pragma mark -

std::string yas::to_string(ui::draw_image_error const &error) {
    switch (error) {
        case ui::draw_image_error::image_is_null:
            return "image_is_null";
        case ui::draw_image_error::no_setup:
            return "no_setup";
        case ui::draw_image_error::out_of_range:
            return "out_of_range";
        default:
            return "unknown";
    }
}

std::string yas::to_string(ui::texture::method const &method) {
    switch (method) {
        case ui::texture::method::metal_texture_changed:
            return "metal_texture_changed";
        case ui::texture::method::size_updated:
            return "size_updated";
    }
}

std::ostream &operator<<(std::ostream &os, yas::ui::draw_image_error const &error) {
    os << to_string(error);
    return os;
}

std::ostream &operator<<(std::ostream &os, yas::ui::texture::method const &method) {
    os << to_string(method);
    return os;
}
