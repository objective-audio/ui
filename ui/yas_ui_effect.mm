//
//  yas_ui_effect.mm
//

#include "yas_ui_effect.h"
#include "yas_ui_texture.h"
#include "yas_ui_metal_texture.h"

using namespace yas;

struct ui::effect::impl : base::impl, metal_effect::impl {
    metal_handler_f _metal_handler;
    texture _texture = nullptr;

    void encode(id<MTLCommandBuffer> const commandBuffer) override {
        if (this->_metal_handler && this->_texture) {
            this->_metal_handler(this->_texture.metal_texture().texture(), commandBuffer);
        }
    }
};

ui::effect::effect() : base(std::make_shared<impl>()) {
}

ui::effect::effect(std::nullptr_t) : base(nullptr) {
}

void ui::effect::set_texture(ui::texture texture) {
    impl_ptr<impl>()->_texture = std::move(texture);
}

void ui::effect::set_metal_handler(metal_handler_f handler) {
    impl_ptr<impl>()->_metal_handler = std::move(handler);
}

ui::effect::metal_handler_f const &ui::effect::metal_handler() const {
    return impl_ptr<impl>()->_metal_handler;
}

ui::metal_effect &ui::effect::metal_effect() {
    if (!this->_metal_effect) {
        this->_metal_effect = ui::metal_effect{impl_ptr<ui::metal_effect::impl>()};
    }
    return this->_metal_effect;
}
