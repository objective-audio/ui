//
//  yas_ui_texture.mm
//

#include "yas_objc_ptr.h"
#include "yas_ui_image.h"
#include "yas_ui_metal_texture.h"
#include "yas_ui_metal_types.h"
#include "yas_ui_renderer.h"
#include "yas_ui_texture.h"
#include "yas_unless.h"
#include "yas_property.h"
#include <map>

using namespace yas;

namespace yas::ui {
using image_pair_t = std::pair<uint_size, texture::image_handler>;
}

#pragma mark - ui::texture::impl

struct ui::texture::impl : base::impl, metal_object::impl {
    impl(ui::uint_size &&point_size, double const scale_factor, uint32_t const draw_padding,
         ui::texture_usages_t const usages, ui::pixel_format const format)
        : _draw_actual_padding(draw_padding * scale_factor),
          _draw_actual_pos({_draw_actual_padding, _draw_actual_padding}),
          _point_size_property({.value = std::move(point_size)}),
          _scale_factor_property({.value = std::move(scale_factor)}),
          _usages(usages),
          _pixel_format(format) {
    }

    void prepare(ui::texture &texture) {
        auto weak_texture = to_weak(texture);

        this->_property_observers.emplace_back(this->_point_size_property.subject().make_observer(
            property_method::did_change, [weak_texture](auto const &context) {
                if (auto texture = weak_texture.lock()) {
                    texture.impl_ptr<impl>()->_property_changed();
                }
            }));

        this->_property_observers.emplace_back(this->_scale_factor_property.subject().make_observer(
            property_method::did_change, [weak_texture](auto const &context) {
                if (auto texture = weak_texture.lock()) {
                    texture.impl_ptr<impl>()->_property_changed();
                }
            }));
    }

    ui::setup_metal_result metal_setup(ui::metal_system const &metal_system) {
        if (!is_same(this->_metal_system, metal_system)) {
            this->_metal_system = metal_system;
            this->_metal_texture = nullptr;
        }

        if (!this->_metal_texture) {
            this->_metal_texture = ui::metal_texture{this->actual_size(), this->_usages, this->_pixel_format};

            if (auto ul = unless(this->_metal_texture.metal().metal_setup(metal_system))) {
                return ul.value;
            }

            this->_add_images_to_metal_texture();

            this->_subject.notify(method::metal_texture_changed, cast<ui::texture>());
        }

        return ui::setup_metal_result{nullptr};
    }

    ui::uint_size actual_size() {
        ui::uint_size const &point_size = this->_point_size_property.value();
        double const &scale_factor = this->_scale_factor_property.value();
        return {static_cast<uint32_t>(point_size.width * scale_factor),
                static_cast<uint32_t>(point_size.height * scale_factor)};
    }

    image_key add_image_handler(image_pair_t pair) {
        if (this->_metal_texture) {
            this->_add_image_to_metal_texture(pair);
        }

        uint32_t key = 0;
        auto it = this->_image_handlers.crbegin();
        if (it != this->_image_handlers.crend()) {
            key = it->first + 1;
        }

        this->_image_handlers.emplace(key, std::move(pair));

        return key;
    }

    void remove_image_handler(image_key const &key) {
        this->_image_handlers.erase(key);
    }

    property<std::nullptr_t, ui::uint_size> _point_size_property;
    property<std::nullptr_t, double> _scale_factor_property;
    uint32_t const _depth = 1;
    bool const _has_alpha = false;
    ui::texture_usages_t const _usages;
    ui::pixel_format const _pixel_format;

    ui::metal_texture _metal_texture = nullptr;

    subject_t _subject;

   private:
    ui::metal_system _metal_system = nullptr;
    uint32_t _max_line_height = 0;
    uint32_t const _draw_actual_padding;
    uint_point _draw_actual_pos;
    std::map<uint32_t, image_pair_t> _image_handlers;
    std::vector<base> _property_observers;

    void _property_changed() {
        this->_metal_texture = nullptr;
        this->_draw_actual_pos = {_draw_actual_padding, _draw_actual_padding};

        this->_subject.notify(ui::texture::method::size_updated, cast<ui::texture>());
    }

    draw_image_result _reserve_image_size(image const &image) {
        if (!image) {
            return draw_image_result{draw_image_error::image_is_null};
        }

        auto const actual_image_size = image.actual_size();

        this->_prepare_draw_pos(actual_image_size);

        if (!this->_can_draw(actual_image_size)) {
            return draw_image_result{draw_image_error::out_of_range};
        }

        ui::uint_point const origin = this->_draw_actual_pos;

        this->_move_draw_pos(actual_image_size);

        return draw_image_result{ui::uint_region{.origin = origin, .size = actual_image_size}};
    }

    draw_image_result _replace_image(image const &image, uint_point const origin) {
        if (!image) {
            return draw_image_result{draw_image_error::image_is_null};
        }

        if (!this->_metal_texture.texture() || !this->_metal_texture.samplerState()) {
            return draw_image_result{draw_image_error::no_setup};
        }

        auto region = uint_region{origin, image.actual_size()};

        if (id<MTLTexture> texture = this->_metal_texture.texture()) {
            [texture replaceRegion:to_mtl_region(region)
                       mipmapLevel:0
                         withBytes:image.data()
                       bytesPerRow:region.size.width * 4];
        }

        return draw_image_result{std::move(region)};
    }

    void _prepare_draw_pos(uint_size const size) {
        if (this->actual_size().width < (this->_draw_actual_pos.x + size.width + this->_draw_actual_padding)) {
            this->_move_draw_pos(size);
        }
    }

    void _move_draw_pos(uint_size const size) {
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

    bool _can_draw(uint_size const size) {
        ui::uint_size const actual_size = this->actual_size();
        if ((actual_size.width < this->_draw_actual_pos.x + size.width + this->_draw_actual_padding) ||
            (actual_size.height < this->_draw_actual_pos.y + size.height + this->_draw_actual_padding)) {
            return false;
        }

        return true;
    }

    void _add_images_to_metal_texture() {
        for (auto const &pair : this->_image_handlers) {
            this->_add_image_to_metal_texture(pair.second);
        }
    }

    void _add_image_to_metal_texture(image_pair_t const &pair) {
        if (!this->_metal_texture) {
            throw std::runtime_error("metal_texture not found.");
        }

        auto const &point_size = pair.first;
        auto const &image_handler = pair.second;

        ui::image image{{.point_size = point_size, .scale_factor = this->_scale_factor_property.value()}};

        if (auto reserve_result = this->_reserve_image_size(image)) {
            if (image_handler) {
                auto const &tex_coords = reserve_result.value();
                image_handler(image, tex_coords);
                this->_replace_image(image, tex_coords.origin);
            }
        }
    }
};

ui::texture::texture(args args)
    : base(std::make_shared<impl>(std::move(args.point_size), args.scale_factor, args.draw_padding, args.usages,
                                  args.pixel_format)) {
    impl_ptr<impl>()->prepare(*this);
}

ui::texture::texture(std::nullptr_t) : base(nullptr) {
}

bool ui::texture::operator==(texture const &rhs) const {
    return base::operator==(rhs);
}

bool ui::texture::operator!=(texture const &rhs) const {
    return base::operator!=(rhs);
}

ui::uint_size ui::texture::point_size() const {
    return impl_ptr<impl>()->_point_size_property.value();
}

ui::uint_size ui::texture::actual_size() const {
    return impl_ptr<impl>()->actual_size();
}

double ui::texture::scale_factor() const {
    return impl_ptr<impl>()->_scale_factor_property.value();
}

uint32_t ui::texture::depth() const {
    return impl_ptr<impl>()->_depth;
}

bool ui::texture::has_alpha() const {
    return impl_ptr<impl>()->_has_alpha;
}

void ui::texture::set_point_size(ui::uint_size size) {
    impl_ptr<impl>()->_point_size_property.set_value(std::move(size));
}

void ui::texture::set_scale_factor(double const scale_factor) {
    impl_ptr<impl>()->_scale_factor_property.set_value(scale_factor);
}

ui::texture::image_key ui::texture::add_image_handler(ui::uint_size size, image_handler handler) {
    return impl_ptr<impl>()->add_image_handler(std::make_pair(std::move(size), std::move(handler)));
}

void ui::texture::remove_image_handler(image_key const &key) {
    impl_ptr<impl>()->remove_image_handler(key);
}

ui::metal_texture &ui::texture::metal_texture() {
    return impl_ptr<impl>()->_metal_texture;
}

ui::metal_texture const &ui::texture::metal_texture() const {
    return impl_ptr<impl>()->_metal_texture;
}

ui::texture::subject_t &ui::texture::subject() {
    return impl_ptr<impl>()->_subject;
}

#pragma mark - protocol

ui::metal_object &ui::texture::metal() {
    if (!this->_metal_object) {
        this->_metal_object = ui::metal_object{impl_ptr<ui::metal_object::impl>()};
    }
    return this->_metal_object;
}

#pragma mark -

std::string yas::to_string(ui::texture::draw_image_error const &error) {
    switch (error) {
        case ui::texture::draw_image_error::image_is_null:
            return "image_is_null";
        case ui::texture::draw_image_error::no_setup:
            return "no_setup";
        case ui::texture::draw_image_error::out_of_range:
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

std::ostream &operator<<(std::ostream &os, yas::ui::texture::draw_image_error const &error) {
    os << to_string(error);
    return os;
}

std::ostream &operator<<(std::ostream &os, yas::ui::texture::method const &method) {
    os << to_string(method);
    return os;
}
