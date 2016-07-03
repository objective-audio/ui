//
//  yas_ui_texture.mm
//

#include "yas_objc_ptr.h"
#include "yas_ui_image.h"
#include "yas_ui_metal_types.h"
#include "yas_ui_renderer.h"
#include "yas_ui_texture.h"

using namespace yas;

#pragma mark - ui::metal_texture::impl

struct ui::metal_texture::impl : base::impl {
    impl(ui::uint_size &&size) : _size(std::move(size)) {
    }

    ui::setup_metal_result metal_setup(ui::metal_system const &metal_system) {
        if (!is_same(_metal_system, metal_system)) {
            _metal_system = metal_system;
            _texture_object.set_object(nil);
            _sampler_object.set_object(nil);
        }

        if (!_texture_object) {
            auto texture_desc = make_objc_ptr<MTLTextureDescriptor *>([&format = _pixel_format, &size = _size] {
                return [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:format
                                                                          width:size.width
                                                                         height:size.height
                                                                      mipmapped:false];
            });

            if (!texture_desc) {
                return ui::setup_metal_result{ui::setup_metal_error::create_texture_descriptor_failed};
            }

            auto textureDesc = texture_desc.object();

            _target = textureDesc.textureType;

            _texture_object.move_object([_metal_system.device() newTextureWithDescriptor:textureDesc]);

            if (!_texture_object) {
                return ui::setup_metal_result{ui::setup_metal_error::create_texture_failed};
            }
        }

        if (!_sampler_object) {
            auto sampler_desc = make_objc_ptr([MTLSamplerDescriptor new]);
            if (!sampler_desc) {
                return ui::setup_metal_result{setup_metal_error::create_sampler_descriptor_failed};
            }

            auto samplerDesc = sampler_desc.object();

            samplerDesc.minFilter = MTLSamplerMinMagFilterLinear;
            samplerDesc.magFilter = MTLSamplerMinMagFilterLinear;
            samplerDesc.mipFilter = MTLSamplerMipFilterNotMipmapped;
            samplerDesc.maxAnisotropy = 1.0f;
            samplerDesc.sAddressMode = MTLSamplerAddressModeClampToEdge;
            samplerDesc.tAddressMode = MTLSamplerAddressModeClampToEdge;
            samplerDesc.rAddressMode = MTLSamplerAddressModeClampToEdge;
            samplerDesc.normalizedCoordinates = false;
            samplerDesc.lodMinClamp = 0;
            samplerDesc.lodMaxClamp = FLT_MAX;

            _sampler_object.move_object([_metal_system.device() newSamplerStateWithDescriptor:samplerDesc]);

            if (!_sampler_object.object()) {
                return ui::setup_metal_result{setup_metal_error::create_sampler_failed};
            }
        }

        return ui::setup_metal_result{nullptr};
    }

    ui::uint_size _size;
    ui::metal_system _metal_system = nullptr;
    objc_ptr<id<MTLSamplerState>> _sampler_object;
    objc_ptr<id<MTLTexture>> _texture_object;
    MTLPixelFormat const _pixel_format = MTLPixelFormatRGBA8Unorm;
    MTLTextureType _target = MTLTextureType2D;
};

#pragma mark - ui::metal_texture

ui::metal_texture::metal_texture(ui::uint_size actual_size) : base(std::make_shared<impl>(std::move(actual_size))) {
}

ui::metal_texture::metal_texture(std::nullptr_t) : base(nullptr) {
}

ui::uint_size ui::metal_texture::size() const {
    return impl_ptr<impl>()->_size;
}

id<MTLSamplerState> ui::metal_texture::samplerState() const {
    return impl_ptr<impl>()->_sampler_object.object();
}

id<MTLTexture> ui::metal_texture::texture() const {
    return impl_ptr<impl>()->_texture_object.object();
}

MTLTextureType ui::metal_texture::texture_type() const {
    return impl_ptr<impl>()->_target;
}

MTLPixelFormat ui::metal_texture::pixel_format() const {
    return impl_ptr<impl>()->_pixel_format;
}

ui::metal_system &ui::metal_texture::metal_system() {
    return impl_ptr<impl>()->_metal_system;
}

ui::metal_object &ui::metal_texture::metal() {
    if (!_metal_object) {
        _metal_object = ui::metal_object{impl_ptr<ui::metal_object::impl>()};
    }
    return _metal_object;
}

#pragma mark - ui::texture::impl

struct ui::texture::impl : base::impl {
    impl(uint_size &&point_size, double const scale_factor, uint32_t const draw_padding)
        : _draw_actual_padding(draw_padding * scale_factor),
          _draw_actual_pos({_draw_actual_padding, _draw_actual_padding}),
          _point_size(std::move(point_size)),
          _actual_size(uint_size{static_cast<uint32_t>(point_size.width * scale_factor),
                                 static_cast<uint32_t>(point_size.height * scale_factor)}),
          _scale_factor(std::move(scale_factor)),
          _metal_texture(_actual_size) {
    }

    draw_image_result add_image(image const &image) {
        if (!image) {
            return draw_image_result{draw_image_error::image_is_null};
        }

        auto const actual_image_size = image.actual_size();

        _prepare_draw_pos(actual_image_size);

        if (!_can_draw(actual_image_size)) {
            return draw_image_result{draw_image_error::out_of_range};
        }

        auto result = replace_image(image, _draw_actual_pos);

        _move_draw_pos(actual_image_size);

        return result;
    }

    draw_image_result replace_image(image const &image, uint_origin const origin) {
        if (!image) {
            return draw_image_result{draw_image_error::image_is_null};
        }

        if (!_metal_texture.texture() || !_metal_texture.samplerState()) {
            return draw_image_result{draw_image_error::no_setup};
        }

        auto region = uint_region{origin, image.actual_size()};

        if (id<MTLTexture> texture = _metal_texture.texture()) {
            [texture replaceRegion:to_mtl_region(region)
                       mipmapLevel:0
                         withBytes:image.data()
                       bytesPerRow:region.size.width * 4];
        }

        return draw_image_result{std::move(region)};
    }

    void _prepare_draw_pos(uint_size const size) {
        if (_actual_size.width < (_draw_actual_pos.x + size.width + _draw_actual_padding)) {
            _move_draw_pos(size);
        }
    }

    void _move_draw_pos(uint_size const size) {
        _draw_actual_pos.x += size.width + _draw_actual_padding;

        if (_actual_size.width < _draw_actual_pos.x) {
            _draw_actual_pos.y += _max_line_height + _draw_actual_padding;
            _max_line_height = 0;
            _draw_actual_pos.x = _draw_actual_padding;
        }

        if (_max_line_height < size.height) {
            _max_line_height = size.height;
        }
    }

    bool _can_draw(uint_size const size) {
        if ((_actual_size.width < _draw_actual_pos.x + size.width + _draw_actual_padding) ||
            (_actual_size.height < _draw_actual_pos.y + size.height + _draw_actual_padding)) {
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
    uint_origin _draw_actual_pos;
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

ui::texture::draw_image_result ui::texture::replace_image(image const &image, ui::uint_origin const actual_origin) {
    return impl_ptr<impl>()->replace_image(image, actual_origin);
}

ui::metal_texture &ui::texture::metal_texture() {
    return impl_ptr<impl>()->_metal_texture;
}

#pragma mark -

namespace yas {
namespace ui {
    struct texture_factory : texture {
        texture_factory(uint_size &&point_size, double const scale_factor, uint32_t draw_padding)
            : texture(std::make_shared<texture::impl>(std::move(point_size), scale_factor, draw_padding)) {
        }
    };
}
}

#pragma mark -

ui::make_texture_result ui::make_texture(ui::texture::args args) {
    auto factory = ui::texture_factory{std::move(args.point_size), args.scale_factor, args.draw_padding};
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
