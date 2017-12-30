//
//  yas_ui_effect.mm
//

#include "yas_ui_effect.h"
#include "yas_ui_texture.h"
#include "yas_ui_metal_texture.h"
#include "yas_property.h"

using namespace yas;

struct ui::effect::impl : base::impl, renderable_effect::impl, encodable_effect::impl, metal_object::impl {
    impl() {
        this->_updates.flags.set();
    }

    void setup_observers(ui::effect &effect) {
        auto weak_effect = to_weak(effect);

        this->_observers.emplace_back(this->_texture_property.subject().make_observer(
            property_method::did_change, [weak_effect](auto const &context) {
                if (auto effect = weak_effect.lock()) {
                    effect.impl_ptr<impl>()->_set_updated(effect_update_reason::texture);
                }
            }));
    }

    void encode(id<MTLCommandBuffer> const commandBuffer) override {
        if (!this->_metal_system || !this->_metal_handler) {
            return;
        }

        if (auto &texture = this->_texture_property.value()) {
            this->_metal_handler(texture, this->_metal_system, commandBuffer);
        }
    }

    void set_metal_handler(metal_handler_f &&handler) {
        this->_metal_handler = std::move(handler);
        this->_set_updated(effect_update_reason::handler);
    }
    
    metal_handler_f const &metal_handler() {
        return this->_metal_handler;
    }

    void set_texture(ui::texture &&texture) override {
        this->_texture_property.set_value(std::move(texture));
    }

    ui::setup_metal_result metal_setup(ui::metal_system const &metal_system) override {
        if (!is_same(this->_metal_system, metal_system)) {
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

    property<std::nullptr_t, ui::texture> _texture_property{{.value = nullptr}};

   private:
    ui::metal_system _metal_system = nullptr;
    ui::effect_updates_t _updates;
    metal_handler_f _metal_handler = nullptr;
    std::vector<base> _observers;

    void _set_updated(ui::effect_update_reason const reason) {
        this->_updates.set(reason);
    }
};

ui::effect::effect() : base(std::make_shared<impl>()) {
    impl_ptr<impl>()->setup_observers(*this);
}

ui::effect::effect(std::nullptr_t) : base(nullptr) {
}

void ui::effect::set_metal_handler(metal_handler_f handler) {
    impl_ptr<impl>()->set_metal_handler(std::move(handler));
}

ui::effect::metal_handler_f const &ui::effect::metal_handler() const {
    return impl_ptr<impl>()->metal_handler();
}

ui::renderable_effect &ui::effect::renderable() {
    if (!this->_renderable) {
        this->_renderable = ui::renderable_effect{impl_ptr<ui::renderable_effect::impl>()};
    }
    return this->_renderable;
}

ui::encodable_effect &ui::effect::encodable() {
    if (!this->_encodable) {
        this->_encodable = ui::encodable_effect{impl_ptr<ui::encodable_effect::impl>()};
    }
    return this->_encodable;
}

ui::metal_object &ui::effect::metal() {
    if (!this->_metal) {
        this->_metal = ui::metal_object{impl_ptr<ui::metal_object::impl>()};
    }
    return this->_metal;
}
