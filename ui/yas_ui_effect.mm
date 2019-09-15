//
//  yas_ui_effect.mm
//

#include "yas_ui_effect.h"
#include "yas_ui_metal_texture.h"
#include "yas_ui_texture.h"

using namespace yas;

struct ui::effect::impl {
    impl() {
        this->_updates.flags.set();
    }

    void encode(id<MTLCommandBuffer> const commandBuffer) {
        if (!this->_metal_system || !this->_metal_handler) {
            return;
        }

        if (this->_src_texture && this->_dst_texture) {
            this->_metal_handler(this->_src_texture, this->_dst_texture, this->_metal_system, commandBuffer);
        }
    }

    void set_metal_handler(metal_handler_f &&handler) {
        this->_metal_handler = std::move(handler);
        this->_set_updated(effect_update_reason::handler);
    }

    metal_handler_f const &metal_handler() {
        return this->_metal_handler;
    }

    void set_textures(ui::texture_ptr const &src, ui::texture_ptr const &dst) {
        this->_src_texture = src;
        this->_dst_texture = dst;
        this->_set_updated(effect_update_reason::textures);
    }

    ui::setup_metal_result metal_setup(ui::metal_system_ptr const &metal_system) {
        if (this->_metal_system != metal_system) {
            this->_metal_system = metal_system;
        }

        return ui::setup_metal_result{nullptr};
    }

    ui::effect_updates_t &updates() {
        return this->_updates;
    }

    void clear_updates() {
        this->_updates.flags.reset();
    }

   private:
    ui::texture_ptr _src_texture = nullptr;
    ui::texture_ptr _dst_texture = nullptr;
    ui::metal_system_ptr _metal_system = nullptr;
    ui::effect_updates_t _updates;
    metal_handler_f _metal_handler = nullptr;

    void _set_updated(ui::effect_update_reason const reason) {
        this->_updates.set(reason);
    }
};

ui::effect::effect() : _impl(std::make_unique<impl>()) {
}

void ui::effect::set_metal_handler(metal_handler_f handler) {
    this->_impl->set_metal_handler(std::move(handler));
}

ui::effect::metal_handler_f const &ui::effect::metal_handler() const {
    return this->_impl->metal_handler();
}

void ui::effect::set_textures(ui::texture_ptr const &src, ui::texture_ptr const &dst) {
    this->_impl->set_textures(src, dst);
}

ui::effect_updates_t &ui::effect::updates() {
    return this->_impl->updates();
}

void ui::effect::clear_updates() {
    this->_impl->clear_updates();
}

void ui::effect::encode(id<MTLCommandBuffer> const commandBuffer) {
    return this->_impl->encode(commandBuffer);
}

ui::setup_metal_result ui::effect::metal_setup(std::shared_ptr<ui::metal_system> const &system) {
    return this->_impl->metal_setup(system);
}

ui::effect::metal_handler_f const &ui::effect::through_metal_handler() {
    static metal_handler_f _handler = nullptr;
    if (!_handler) {
        _handler = [](ui::texture_ptr const &src_texture, ui::texture_ptr const &dst_texture,
                      ui::metal_system_ptr const &, id<MTLCommandBuffer> const commandBuffer) mutable {
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

ui::effect_ptr ui::effect::make_through_effect() {
    auto effect = ui::effect::make_shared();
    effect->set_metal_handler(ui::effect::through_metal_handler());
    return effect;
}

ui::effect_ptr ui::effect::make_shared() {
    return std::shared_ptr<effect>(new effect{});
}
