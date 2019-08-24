//
//  yas_ui_effect.mm
//

#include "yas_ui_effect.h"
#include "yas_ui_metal_texture.h"
#include "yas_ui_texture.h"

using namespace yas;

struct ui::effect::impl : renderable_effect::impl, encodable_effect::impl, metal_object::impl {
    impl() {
        this->_updates.flags.set();
    }

    void encode(id<MTLCommandBuffer> const commandBuffer) override {
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

    void set_textures(ui::texture_ptr const &src, ui::texture_ptr const &dst) override {
        this->_src_texture = src;
        this->_dst_texture = dst;
        this->_set_updated(effect_update_reason::textures);
    }

    ui::setup_metal_result metal_setup(ui::metal_system_ptr const &metal_system) override {
        if (this->_metal_system != metal_system) {
            this->_metal_system = metal_system;
        }

        return ui::setup_metal_result{nullptr};
    }

    ui::effect_updates_t &updates() override {
        return this->_updates;
    }

    void clear_updates() override {
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

ui::effect::effect() : _impl(std::make_shared<impl>()) {
}

void ui::effect::set_metal_handler(metal_handler_f handler) {
    this->_impl->set_metal_handler(std::move(handler));
}

ui::effect::metal_handler_f const &ui::effect::metal_handler() const {
    return this->_impl->metal_handler();
}

ui::renderable_effect &ui::effect::renderable() {
    if (!this->_renderable) {
        this->_renderable = ui::renderable_effect{this->_impl};
    }
    return this->_renderable;
}

ui::encodable_effect &ui::effect::encodable() {
    if (!this->_encodable) {
        this->_encodable = ui::encodable_effect{this->_impl};
    }
    return this->_encodable;
}

ui::metal_object &ui::effect::metal() {
    if (!this->_metal) {
        this->_metal = ui::metal_object{this->_impl};
    }
    return this->_metal;
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
