//
//  yas_ui_render_encoder_protocol.mm
//

#include "yas_ui_render_encoder_protocol.h"
#include "yas_ui_mesh.h"
#include "yas_ui_metal_encode_info.h"
#include "yas_ui_renderer.h"

using namespace yas;

#pragma mark - ui::render_effectable

ui::render_effectable::render_effectable(std::shared_ptr<impl> impl) : protocol(std::move(impl)) {
}

ui::render_effectable::render_effectable(std::nullptr_t) : protocol(nullptr) {
}

void ui::render_effectable::append_effect(ui::effect_ptr const &effect) {
    impl_ptr<impl>()->append_effect(effect);
}

void append_effect(ui::effect_ptr);

#pragma mark - ui::render_stackable

ui::render_stackable::render_stackable(std::shared_ptr<impl> impl) : protocol(std::move(impl)) {
}

ui::render_stackable::render_stackable(std::nullptr_t) : protocol(nullptr) {
}

void ui::render_stackable::push_encode_info(ui::metal_encode_info_ptr const &info) {
    impl_ptr<impl>()->push_encode_info(info);
}

void ui::render_stackable::pop_encode_info() {
    impl_ptr<impl>()->pop_encode_info();
}

ui::metal_encode_info_ptr const &ui::render_stackable::current_encode_info() {
    return impl_ptr<impl>()->current_encode_info();
}
