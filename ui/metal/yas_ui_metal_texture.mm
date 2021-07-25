//
//  yas_ui_metal_texture.mm
//

#include "yas_ui_metal_texture.h"
#include <ui/yas_ui_metal_buffer.h>
#include <ui/yas_ui_image.h>
#include <ui/yas_ui_metal_system.h>
#include <ui/yas_ui_metal_types.h>

using namespace yas;
using namespace yas::ui;

#pragma mark - metal_texture

metal_texture::metal_texture(uint_size &&actual_size, texture_usages_t const usages, ui::pixel_format const format)
    : _size(std::move(actual_size)),
      _texture_usage(to_mtl_texture_usage(usages)),
      _pixel_format(to_mtl_pixel_format(format)) {
}

metal_texture::~metal_texture() = default;

uint_size metal_texture::size() const {
    return this->_size;
}

id<MTLSamplerState> metal_texture::samplerState() const {
    return this->_sampler_object.object();
}

id<MTLTexture> metal_texture::texture() const {
    return this->_texture_object.object();
}

id<MTLBuffer> metal_texture::argumentBuffer() const {
    return this->_argument_buffer->rawBuffer();
}

MTLTextureType metal_texture::texture_type() const {
    return this->_target;
}

MTLPixelFormat metal_texture::pixel_format() const {
    return this->_pixel_format;
}

MTLTextureUsage metal_texture::texture_usage() const {
    return this->_texture_usage;
}

setup_metal_result metal_texture::metal_setup(std::shared_ptr<ui::metal_system> const &system) {
    if (this->_metal_system != system) {
        this->_metal_system = system;
        this->_texture_object.set_object(nil);
        this->_sampler_object.set_object(nil);
    }

    if (!this->_texture_object) {
        if (this->_size.width == 0 || this->_size.height == 0) {
            return setup_metal_result{setup_metal_error::create_texture_descriptor_failed};
        }

        auto texture_desc = objc_ptr<MTLTextureDescriptor *>([&format = this->_pixel_format, &size = this->_size] {
            return [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:format
                                                                      width:size.width
                                                                     height:size.height
                                                                  mipmapped:false];
        });

        if (!texture_desc) {
            return setup_metal_result{setup_metal_error::create_texture_descriptor_failed};
        }

        auto textureDesc = texture_desc.object();

        this->_target = textureDesc.textureType;

        textureDesc.usage = this->_texture_usage;

        this->_texture_object = makable_metal_system::cast(this->_metal_system)->make_mtl_texture(textureDesc);

        if (!this->_texture_object) {
            return setup_metal_result{setup_metal_error::create_texture_failed};
        }
    }

    if (!this->_sampler_object) {
        auto sampler_desc = objc_ptr_with_move_object([MTLSamplerDescriptor new]);
        if (!sampler_desc) {
            return setup_metal_result{setup_metal_error::create_sampler_descriptor_failed};
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
        samplerDesc.supportArgumentBuffers = true;

        this->_sampler_object = makable_metal_system::cast(this->_metal_system)->make_mtl_sampler_state(samplerDesc);

        if (!this->_sampler_object.object()) {
            return setup_metal_result{setup_metal_error::create_sampler_failed};
        }
    }

    if (!this->_argument_encoder_object) {
        this->_argument_encoder_object = makable_metal_system::cast(this->_metal_system)->make_mtl_argument_encoder();

        if (!this->_argument_encoder_object) {
            return setup_metal_result{setup_metal_error::create_argument_encoder_failed};
        }

        auto encoder = *this->_argument_encoder_object;

        this->_argument_buffer = this->_metal_system->make_metal_buffer(encoder.encodedLength);

        if (!this->_argument_buffer) {
            return setup_metal_result{setup_metal_error::create_argument_buffer_failed};
        }

        [encoder setArgumentBuffer:this->_argument_buffer->rawBuffer() offset:0];
        [encoder setTexture:*this->_texture_object atIndex:0];
        [encoder setSamplerState:*this->_sampler_object atIndex:1];
    }

    return setup_metal_result{nullptr};
}

void metal_texture::replace_data(uint_region const region, void const *data) {
    if (id<MTLTexture> texture = this->texture()) {
        [texture replaceRegion:to_mtl_region(region) mipmapLevel:0 withBytes:data bytesPerRow:region.size.width * 4];
    }
}

std::shared_ptr<metal_texture> metal_texture::make_shared(uint_size size, texture_usages_t const usages,
                                                          ui::pixel_format const format) {
    return std::shared_ptr<metal_texture>(new metal_texture{std::move(size), usages, format});
}
