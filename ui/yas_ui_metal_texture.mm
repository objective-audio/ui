//
//  yas_ui_metal_texture.mm
//

#include "yas_objc_ptr.h"
#include "yas_ui_metal_system.h"
#include "yas_ui_metal_texture.h"
#include "yas_ui_types.h"

using namespace yas;

#pragma mark - ui::metal_texture::impl

struct ui::metal_texture::impl : base::impl, ui::metal_object::impl {
    impl(ui::uint_size &&size) : _size(std::move(size)) {
    }

    ui::setup_metal_result metal_setup(ui::metal_system const &metal_system) override {
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