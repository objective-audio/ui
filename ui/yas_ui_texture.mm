//
//  yas_ui_texture.mm
//

#include "yas_objc_container.h"
#include "yas_ui_image.h"
#include "yas_ui_texture.h"

using namespace yas;

namespace yas {
namespace ui {
    static UInt32 const texture_draw_padding = 2;
}
}

struct ui::texture::impl : public base::impl {
    impl(uint_size const point_size, Float64 const scale_factor, MTLPixelFormat const pixel_format)
        : _draw_actual_padding(texture_draw_padding * scale_factor),
          point_size(point_size),
          actual_size(uint_size{static_cast<UInt32>(point_size.width * scale_factor),
                                static_cast<UInt32>(point_size.height * scale_factor)}),
          scale_factor(scale_factor),
          format(pixel_format) {
    }

    setup_result setup(id<MTLDevice> const device) {
        @autoreleasepool {
            auto texture_desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:format
                                                                                   width:actual_size.width
                                                                                  height:actual_size.height
                                                                               mipmapped:false];
            if (!texture_desc) {
                return setup_result{setup_error::create_texture_descriptor_failed};
            }

            target = texture_desc.textureType;

            auto texture = [device newTextureWithDescriptor:texture_desc];

            if (!texture) {
                return setup_result{setup_error::create_texture_failed};
            }

            texture_container.set_object(texture);
            yas_release(texture);
        }

        auto sampler_desc = [MTLSamplerDescriptor new];

        if (!sampler_desc) {
            return setup_result{setup_error::create_sampler_descriptor_failed};
        }

        sampler_desc.minFilter = MTLSamplerMinMagFilterLinear;
        sampler_desc.magFilter = MTLSamplerMinMagFilterLinear;
        sampler_desc.mipFilter = MTLSamplerMipFilterNotMipmapped;
        sampler_desc.maxAnisotropy = 1.0f;
        sampler_desc.sAddressMode = MTLSamplerAddressModeClampToEdge;
        sampler_desc.tAddressMode = MTLSamplerAddressModeClampToEdge;
        sampler_desc.rAddressMode = MTLSamplerAddressModeClampToEdge;
        sampler_desc.normalizedCoordinates = false;
        sampler_desc.lodMinClamp = 0;
        sampler_desc.lodMaxClamp = FLT_MAX;

        auto sampler = [device newSamplerStateWithDescriptor:sampler_desc];

        yas_release(sampler_desc);

        if (!sampler) {
            return setup_result{setup_error::create_sampler_failed};
        }

        sampler_container.set_object(sampler);

        yas_release(sampler);

        return setup_result{nullptr};
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

        if (!texture_container || !sampler_container) {
            return draw_image_result{draw_image_error::no_setup};
        }

        auto region = uint_region{origin, image.actual_size()};

        if (id<MTLTexture> texture = texture_container.object()) {
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
    Float64 const scale_factor;
    UInt32 const depth = 1;
    MTLPixelFormat const format;
    MTLTextureType target = MTLTextureType2D;
    bool const has_alpha = false;

    objc::container<> sampler_container;
    objc::container<> texture_container;

    uint_origin _draw_actual_pos = uint_origin{texture_draw_padding, texture_draw_padding};
    UInt32 _max_line_height = 0;
    UInt32 const _draw_actual_padding;
};

ui::texture::texture(uint_size const point_size, Float64 const scale_factor, MTLPixelFormat const format)
    : super_class(std::make_shared<impl>(point_size, scale_factor, format)) {
}

ui::texture::texture(std::nullptr_t) : super_class(nullptr) {
}

bool ui::texture::operator==(texture const &rhs) const {
    return super_class::operator==(rhs);
}

bool ui::texture::operator!=(texture const &rhs) const {
    return super_class::operator!=(rhs);
}

ui::texture::setup_result ui::texture::setup(id<MTLDevice> const device) {
    return impl_ptr<impl>()->setup(device);
}

id<MTLSamplerState> ui::texture::mtl_sampler() const {
    return impl_ptr<impl>()->sampler_container.object();
}

id<MTLTexture> ui::texture::mtl_texture() const {
    return impl_ptr<impl>()->texture_container.object();
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

Float64 ui::texture::scale_factor() const {
    return impl_ptr<impl>()->scale_factor;
}

UInt32 ui::texture::depth() const {
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

template <>
ui::texture yas::cast(base const &base) {
    ui::texture obj{nullptr};
    obj.set_impl_ptr(std::dynamic_pointer_cast<ui::texture::impl>(base.impl_ptr()));
    return obj;
}

std::string yas::to_string(ui::texture::setup_error const error) {
    switch (error) {
        case ui::texture::setup_error::create_texture_descriptor_failed:
            return "create_texture_descriptor_failed";
        case ui::texture::setup_error::create_texture_failed:
            return "create_texture_failed";
        case ui::texture::setup_error::create_sampler_descriptor_failed:
            return "create_sampler_descriptor_failed";
        case ui::texture::setup_error::create_sampler_failed:
            return "create_sampler_failed";
        default:
            return "unknown";
    }
}

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
