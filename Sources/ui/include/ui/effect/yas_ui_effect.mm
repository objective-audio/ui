//
//  yas_ui_effect.mm
//

#include "yas_ui_effect.h"

#include <ui/metal/yas_ui_metal_texture.h>
#include <ui/texture/yas_ui_texture.h>

using namespace yas;
using namespace yas::ui;

effect::effect() {
    this->_updates.flags.set();
}

void effect::set_metal_handler(metal_handler_f handler) {
    this->_metal_handler = std::move(handler);
    this->_updates.set(effect_update_reason::handler);
}

effect::metal_handler_f const &effect::metal_handler() const {
    return this->_metal_handler;
}

void effect::set_textures(std::shared_ptr<texture> const &src, std::shared_ptr<texture> const &dst) {
    this->_src_texture = src;
    this->_dst_texture = dst;
    this->_updates.set(effect_update_reason::textures);
}

effect_updates_t &effect::updates() {
    return this->_updates;
}

void effect::clear_updates() {
    this->_updates.flags.reset();
}

void effect::encode(id<MTLCommandBuffer> const commandBuffer) {
    if (!this->_metal_system || !this->_metal_handler) {
        return;
    }

    if (this->_src_texture && this->_dst_texture) {
        this->_metal_handler(this->_src_texture, this->_dst_texture, this->_metal_system, commandBuffer);
    }
}

setup_metal_result effect::metal_setup(std::shared_ptr<metal_system> const &system) {
    if (this->_metal_system != system) {
        this->_metal_system = system;
    }

    return setup_metal_result{nullptr};
}

effect::metal_handler_f const &effect::through_metal_handler() {
    static metal_handler_f _handler = nullptr;
    if (!_handler) {
        _handler = [](std::shared_ptr<texture> const &src_texture, std::shared_ptr<texture> const &dst_texture,
                      std::shared_ptr<metal_system> const &, id<MTLCommandBuffer> const commandBuffer) mutable {
            auto const srcTexture = src_texture->metal_texture()->texture();
            auto const dstTexture = dst_texture->metal_texture()->texture();
            auto const width = std::min(srcTexture.width, dstTexture.width);
            auto const height = std::min(srcTexture.height, dstTexture.height);
            auto const zero_origin = MTLOriginMake(0, 0, 0);

            auto encoder =
                objc_ptr<id<MTLBlitCommandEncoder>>([commandBuffer]() { return [commandBuffer blitCommandEncoder]; });

            [*encoder copyFromTexture:srcTexture
                          sourceSlice:0
                          sourceLevel:0
                         sourceOrigin:zero_origin
                           sourceSize:MTLSizeMake(width, height, srcTexture.depth)
                            toTexture:dstTexture
                     destinationSlice:0
                     destinationLevel:0
                    destinationOrigin:zero_origin];

            [*encoder endEncoding];
        };
    }
    return _handler;
}

std::shared_ptr<effect> effect::make_through_effect() {
    auto effect = effect::make_shared();
    effect->set_metal_handler(effect::through_metal_handler());
    return effect;
}

std::shared_ptr<effect> effect::make_shared() {
    return std::shared_ptr<effect>(new effect{});
}
