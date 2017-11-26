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
        if (!is_same(this->_metal_system, metal_system)) {
            this->_metal_system = metal_system;
            this->_texture_object.set_object(nil);
            this->_sampler_object.set_object(nil);
        }

        if (!this->_texture_object) {
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

            this->_target = textureDesc.textureType;

            this->_texture_object = this->_metal_system.makable().make_mtl_texture(textureDesc);

            if (!this->_texture_object) {
                return ui::setup_metal_result{ui::setup_metal_error::create_texture_failed};
            }
        }

        if (!this->_sampler_object) {
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

            this->_sampler_object = this->_metal_system.makable().make_mtl_sampler_state(samplerDesc);

            if (!this->_sampler_object.object()) {
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

ui::metal_texture::~metal_texture() = default;

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

ui::metal_system const &ui::metal_texture::metal_system() {
    return impl_ptr<impl>()->_metal_system;
}

ui::metal_object &ui::metal_texture::metal() {
    if (!this->_metal_object) {
        this->_metal_object = ui::metal_object{impl_ptr<ui::metal_object::impl>()};
    }
    return this->_metal_object;
}
