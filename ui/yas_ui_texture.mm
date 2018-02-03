//
//  yas_ui_texture.mm
//

#include "yas_objc_ptr.h"
#include "yas_ui_image.h"
#include "yas_ui_metal_texture.h"
#include "yas_ui_metal_types.h"
#include "yas_ui_renderer.h"
#include "yas_ui_texture.h"

using namespace yas;

#pragma mark - ui::texture::impl

struct ui::texture::impl : base::impl, renderable_texture::impl, metal_object::impl {
    impl(ui::uint_size &&point_size, double const scale_factor, uint32_t const draw_padding,
         ui::texture_usages_t const usages, ui::pixel_format const format)
        : _draw_actual_padding(draw_padding * scale_factor),
          _draw_actual_pos({_draw_actual_padding, _draw_actual_padding}),
          _point_size(std::move(point_size)),
          _actual_size(uint_size{static_cast<uint32_t>(point_size.width * scale_factor),
                                 static_cast<uint32_t>(point_size.height * scale_factor)}),
          _scale_factor(std::move(scale_factor)),
          _metal_texture(_actual_size, usages, format) {
    }

    ui::setup_metal_result metal_setup(ui::metal_system const &metal_system) {
#warning todo
        return ui::setup_metal_result{nullptr};
    }

    draw_image_result reserve_image_size(image const &image) {
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

    draw_image_result add_image(image const &image) {
        if (auto result = this->reserve_image_size(image)) {
            return this->replace_image(image, result.value().origin);
        } else {
            return result;
        }
    }

    draw_image_result replace_image(image const &image, uint_point const origin) {
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
        if (this->_actual_size.width < (this->_draw_actual_pos.x + size.width + this->_draw_actual_padding)) {
            this->_move_draw_pos(size);
        }
    }

    void _move_draw_pos(uint_size const size) {
        this->_draw_actual_pos.x += size.width + this->_draw_actual_padding;

        if (this->_actual_size.width < this->_draw_actual_pos.x) {
            this->_draw_actual_pos.y += this->_max_line_height + this->_draw_actual_padding;
            this->_max_line_height = 0;
            this->_draw_actual_pos.x = this->_draw_actual_padding;
        }

        if (this->_max_line_height < size.height) {
            this->_max_line_height = size.height;
        }
    }

    bool _can_draw(uint_size const size) {
        if ((this->_actual_size.width < this->_draw_actual_pos.x + size.width + this->_draw_actual_padding) ||
            (this->_actual_size.height < this->_draw_actual_pos.y + size.height + this->_draw_actual_padding)) {
            return false;
        }

        return true;
    }

    uint_size const _point_size;
    uint_size const _actual_size;
    double const _scale_factor;
    uint32_t const _depth = 1;
    bool const _has_alpha = false;

    ui::metal_texture _metal_texture;

   private:
    uint32_t _max_line_height = 0;
    uint32_t const _draw_actual_padding;
    uint_point _draw_actual_pos;
};

ui::texture::texture(std::shared_ptr<impl> &&impl) : base(std::move(impl)) {
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
    return impl_ptr<impl>()->_point_size;
}

ui::uint_size ui::texture::actual_size() const {
    return impl_ptr<impl>()->_actual_size;
}

double ui::texture::scale_factor() const {
    return impl_ptr<impl>()->_scale_factor;
}

uint32_t ui::texture::depth() const {
    return impl_ptr<impl>()->_depth;
}

bool ui::texture::has_alpha() const {
    return impl_ptr<impl>()->_has_alpha;
}

ui::texture::draw_image_result ui::texture::add_image(image const &image) {
    return impl_ptr<impl>()->add_image(image);
}

ui::texture::draw_image_result ui::texture::reserve_image_size(image const &image) {
    return impl_ptr<impl>()->reserve_image_size(image);
}

ui::texture::draw_image_result ui::texture::replace_image(image const &image, ui::uint_point const actual_origin) {
    return impl_ptr<impl>()->replace_image(image, actual_origin);
}

ui::metal_texture &ui::texture::metal_texture() {
    return impl_ptr<impl>()->_metal_texture;
}

#pragma mark - protocol

ui::renderable_texture &ui::texture::renderable() {
    if (!this->_renderable) {
        this->_renderable = ui::renderable_texture{impl_ptr<ui::renderable_texture::impl>()};
    }
    return this->_renderable;
}

ui::metal_object &ui::texture::metal() {
    if (!this->_metal_object) {
        this->_metal_object = ui::metal_object{impl_ptr<ui::metal_object::impl>()};
    }
    return this->_metal_object;
}

#pragma mark -

namespace yas::ui {
struct texture_factory : texture {
    texture_factory(ui::uint_size &&point_size, double const scale_factor, uint32_t draw_padding,
                    ui::texture_usages_t const usages, ui::pixel_format const format)
        : texture(std::make_shared<texture::impl>(std::move(point_size), scale_factor, draw_padding, usages, format)) {
    }
};
}

#pragma mark -

ui::make_texture_result ui::make_texture(ui::texture::args args) {
    auto factory = ui::texture_factory{std::move(args.point_size), args.scale_factor, args.draw_padding, args.usages,
                                       args.pixel_format};
    if (auto result = factory.metal_texture().metal().metal_setup(args.metal_system)) {
        return ui::make_texture_result{std::move(factory)};
    } else {
        return ui::make_texture_result{std::move(result.error())};
    }
}

#pragma mark -

std::string yas::to_string(ui::texture::draw_image_error const error) {
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

std::ostream &operator<<(std::ostream &os, yas::ui::texture::draw_image_error const &error) {
    os << to_string(error);
    return os;
}
