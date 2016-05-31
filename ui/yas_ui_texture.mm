//
//  yas_ui_texture.mm
//

#include "yas_objc_ptr.h"
#include "yas_ui_image.h"
#include "yas_ui_metal_types.h"
#include "yas_ui_renderer.h"
#include "yas_ui_texture.h"

using namespace yas;

namespace yas {
namespace ui {
    static uint32_t const texture_draw_padding = 2;
}
}

struct ui::texture::impl : base::impl, metal_object::impl {
    impl(uint_size const point_size, double const scale_factor, MTLPixelFormat const pixel_format)
        : _draw_actual_padding(texture_draw_padding * scale_factor),
          point_size(point_size),
          actual_size(uint_size{static_cast<uint32_t>(point_size.width * scale_factor),
                                static_cast<uint32_t>(point_size.height * scale_factor)}),
          scale_factor(scale_factor),
          format(pixel_format) {
    }

    ui::setup_metal_result metal_setup(id<MTLDevice> const device) override {
        if (![_device.object() isEqual:device]) {
            _device.set_object(device);
            texture_object.set_object(nil);
            sampler_object.set_object(nil);
        }

        if (!texture_object) {
            auto texture_desc = make_objc_ptr<MTLTextureDescriptor *>([&format = format, &actual_size = actual_size] {
                return [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:format
                                                                          width:actual_size.width
                                                                         height:actual_size.height
                                                                      mipmapped:false];
            });

            if (!texture_desc) {
                return ui::setup_metal_result{ui::setup_metal_error::create_texture_descriptor_failed};
            }

            auto textureDesc = texture_desc.object();

            target = textureDesc.textureType;

            texture_object.move_object([device newTextureWithDescriptor:textureDesc]);

            if (!texture_object) {
                return ui::setup_metal_result{ui::setup_metal_error::create_texture_failed};
            }
        }

        if (!sampler_object) {
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

            sampler_object.move_object([device newSamplerStateWithDescriptor:samplerDesc]);

            if (!sampler_object.object()) {
                return ui::setup_metal_result{setup_metal_error::create_sampler_failed};
            }
        }

        return ui::setup_metal_result{nullptr};
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

        if (!texture_object || !sampler_object) {
            return draw_image_result{draw_image_error::no_setup};
        }

        auto region = uint_region{origin, image.actual_size()};

        if (id<MTLTexture> texture = texture_object.object()) {
            [texture replaceRegion:to_mtl_region(region)
                       mipmapLevel:0
                         withBytes:image.data()
                       bytesPerRow:region.size.width * 4];
        }

        return draw_image_result{std::move(region)};
    }

    void _prepare_draw_pos(uint_size const size) {
        if (actual_size.width < (_draw_actual_pos.x + size.width + _draw_actual_padding)) {
            _move_draw_pos(size);
        }
    }

    void _move_draw_pos(uint_size const size) {
        _draw_actual_pos.x += size.width + _draw_actual_padding;

        if (actual_size.width < _draw_actual_pos.x) {
            _draw_actual_pos.y += _max_line_height + _draw_actual_padding;
            _max_line_height = 0;
            _draw_actual_pos.x = _draw_actual_padding;
        }

        if (_max_line_height < size.height) {
            _max_line_height = size.height;
        }
    }

    bool _can_draw(uint_size const size) {
        if ((actual_size.width < _draw_actual_pos.x + size.width + _draw_actual_padding) ||
            (actual_size.height < _draw_actual_pos.y + size.height + _draw_actual_padding)) {
            return false;
        }

        return true;
    }

    uint_size const point_size;
    uint_size const actual_size;
    double const scale_factor;
    uint32_t const depth = 1;
    MTLPixelFormat const format;
    MTLTextureType target = MTLTextureType2D;
    bool const has_alpha = false;

    objc_ptr<id<MTLSamplerState>> sampler_object;
    objc_ptr<id<MTLTexture>> texture_object;

   private:
    uint_origin _draw_actual_pos = uint_origin{texture_draw_padding, texture_draw_padding};
    uint32_t _max_line_height = 0;
    uint32_t const _draw_actual_padding;

    objc_ptr<id<MTLDevice>> _device;
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

id<MTLSamplerState> ui::texture::sampler() const {
    return impl_ptr<impl>()->sampler_object.object();
}

id<MTLTexture> ui::texture::mtlTexture() const {
    return impl_ptr<impl>()->texture_object.object();
}

MTLTextureType ui::texture::target() const {
    return impl_ptr<impl>()->target;
}

ui::uint_size ui::texture::point_size() const {
    return impl_ptr<impl>()->point_size;
}

ui::uint_size ui::texture::actual_size() const {
    return impl_ptr<impl>()->actual_size;
}

double ui::texture::scale_factor() const {
    return impl_ptr<impl>()->scale_factor;
}

uint32_t ui::texture::depth() const {
    return impl_ptr<impl>()->depth;
}

MTLPixelFormat ui::texture::pixel_format() const {
    return impl_ptr<impl>()->format;
}

bool ui::texture::has_alpha() const {
    return impl_ptr<impl>()->has_alpha;
}

ui::texture::draw_image_result ui::texture::add_image(image const &image) {
    return impl_ptr<impl>()->add_image(image);
}

ui::texture::draw_image_result ui::texture::replace_image(image const &image, ui::uint_origin const actual_origin) {
    return impl_ptr<impl>()->replace_image(image, actual_origin);
}

ui::metal_object ui::texture::metal() {
    return ui::metal_object{impl_ptr<ui::metal_object::impl>()};
}

#pragma mark -

namespace yas {
namespace ui {
    struct texture_factory : texture {
        texture_factory(uint_size const point_size, double const scale_factor, MTLPixelFormat const format)
            : texture(std::make_shared<texture::impl>(point_size, scale_factor, format)) {
        }
    };
}
}

#pragma mark -

ui::make_texture_result ui::make_texture(id<MTLDevice> const device, uint_size const point_size,
                                         double const scale_factor, MTLPixelFormat const pixel_format) {
    auto factory = ui::texture_factory{point_size, scale_factor, pixel_format};
    if (auto result = factory.metal().metal_setup(device)) {
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
