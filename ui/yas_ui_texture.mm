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

using namespace yas;

namespace yas::ui {
using image_pair_t = std::pair<uint_size, texture::image_handler>;
}

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
          _usages(usages),
          _pixel_format(format) {
    }

    ui::setup_metal_result metal_setup(ui::metal_system const &metal_system) {
        if (!is_same(this->_metal_system, metal_system)) {
            this->_metal_system = metal_system;
            this->_metal_texture = nullptr;
        }

        if (!this->_metal_texture) {
            this->_metal_texture = ui::metal_texture{this->_actual_size, this->_usages, this->_pixel_format};

#warning metal_textureのmetal_setupは毎回呼ぶようにした方が良い？
            if (auto ul = unless(this->_metal_texture.metal().metal_setup(metal_system))) {
                return ul.value;
            }

            this->_add_images_to_metal_texture();
        }

#warning todo
        return ui::setup_metal_result{nullptr};
    }

    void add_image_handler(image_pair_t pair) {
        if (this->_metal_texture) {
            this->_add_image_to_metal_texture(pair);
        }

        this->_image_handlers.emplace_back(std::move(pair));
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
    ui::texture_usages_t const _usages;
    ui::pixel_format const _pixel_format;

    ui::metal_texture _metal_texture = nullptr;

   private:
    ui::metal_system _metal_system = nullptr;
    uint32_t _max_line_height = 0;
    uint32_t const _draw_actual_padding;
    uint_point _draw_actual_pos;
    std::vector<image_pair_t> _image_handlers;

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

    void _add_images_to_metal_texture() {
        for (auto const &pair : this->_image_handlers) {
            this->_add_image_to_metal_texture(pair);
        }
    }

    void _add_image_to_metal_texture(image_pair_t const &pair) {
        if (!this->_metal_texture) {
            throw std::runtime_error("metal_texture not found.");
        }

        auto const &point_size = pair.first;
        auto const &image_handler = pair.second;

        ui::image image{{.point_size = point_size, .scale_factor = this->_scale_factor}};

        if (auto reserve_result = this->_reserve_image_size(image)) {
            if (image_handler) {
                auto const &tex_coords = reserve_result.value();
                image_handler(image, tex_coords);
                this->_replace_image(image, tex_coords.origin);
            }
        }
    }
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

void ui::texture::add_image_handler(ui::uint_size size, image_handler handler) {
    impl_ptr<impl>()->add_image_handler(std::make_pair(std::move(size), std::move(handler)));
}

ui::metal_texture &ui::texture::metal_texture() {
    return impl_ptr<impl>()->_metal_texture;
}

ui::metal_texture const &ui::texture::metal_texture() const {
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

ui::make_texture_result ui::make_texture(ui::texture::args args, ui::metal_system const &metal_system) {
    auto factory = ui::texture_factory{std::move(args.point_size), args.scale_factor, args.draw_padding, args.usages,
                                       args.pixel_format};
    if (auto result = factory.metal().metal_setup(metal_system)) {
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
