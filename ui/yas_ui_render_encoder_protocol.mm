//
//  yas_ui_render_encoder_protocol.mm
//

#include "yas_ui_render_encoder_protocol.h"
#include "yas_ui_effect.h"
#include "yas_ui_mesh.h"
#include "yas_ui_metal_encode_info.h"
#include "yas_ui_renderer.h"

using namespace yas;

#pragma mark - ui::render_encodable

ui::render_encodable::render_encodable(std::shared_ptr<impl> impl) : protocol(std::move(impl)) {
}

ui::render_encodable::render_encodable(std::nullptr_t) : protocol(nullptr) {
}

void ui::render_encodable::append_mesh(ui::mesh mesh) {
    impl_ptr<impl>()->append_mesh(std::move(mesh));
}

#pragma mark - ui::render_effectable

ui::render_effectable::render_effectable(std::shared_ptr<impl> impl) : protocol(std::move(impl)) {
}

ui::render_effectable::render_effectable(std::nullptr_t) : protocol(nullptr) {
}

void ui::render_effectable::append_effect(ui::effect effect) {
    impl_ptr<impl>()->append_effect(std::move(effect));
}

void append_effect(ui::effect);

#pragma mark - ui::render_stackable

ui::render_stackable::render_stackable(std::shared_ptr<impl> impl) : protocol(std::move(impl)) {
}

ui::render_stackable::render_stackable(std::nullptr_t) : protocol(nullptr) {
}

void ui::render_stackable::push_encode_info(ui::metal_encode_info info) {
    impl_ptr<impl>()->push_encode_info(std::move(info));
}

void ui::render_stackable::pop_encode_info() {
    impl_ptr<impl>()->pop_encode_info();
}

ui::metal_encode_info const &ui::render_stackable::current_encode_info() {
    return impl_ptr<impl>()->current_encode_info();
}
