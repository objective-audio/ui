//
//  yas_ui_effect.mm
//

#include "yas_ui_effect_protocol.h"
#include "yas_ui_texture.h"

using namespace yas;

#pragma mark - renderable_effect

ui::renderable_effect::renderable_effect(std::shared_ptr<impl> impl) : protocol(std::move(impl)) {
}

ui::renderable_effect::renderable_effect(std::nullptr_t) : protocol(nullptr) {
}

void ui::renderable_effect::set_texture(ui::texture texture) {
    impl_ptr<impl>()->set_texture(std::move(texture));
}

ui::effect_updates_t const &ui::renderable_effect::updates() {
    return impl_ptr<impl>()->updates();
}

void ui::renderable_effect::clear_updates() {
    impl_ptr<impl>()->clear_updates();
}

#pragma mark - encodable_effect

ui::encodable_effect::encodable_effect(std::shared_ptr<impl> impl) : protocol(std::move(impl)) {
}

ui::encodable_effect::encodable_effect(std::nullptr_t) : protocol(nullptr) {
}

void ui::encodable_effect::encode(id<MTLCommandBuffer> const commandBuffer) {
    impl_ptr<impl>()->encode(commandBuffer);
}
