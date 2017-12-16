//
//  yas_ui_render_encoder_protocol.mm
//

#include "yas_ui_mesh.h"
#include "yas_ui_render_encoder_protocol.h"
#include "yas_ui_renderer.h"

using namespace yas;

ui::render_encodable::render_encodable(std::shared_ptr<impl> impl) : protocol(std::move(impl)) {
}

ui::render_encodable::render_encodable(std::nullptr_t) : protocol(nullptr) {
}

void ui::render_encodable::append_mesh(ui::mesh mesh) {
    impl_ptr<impl>()->append_mesh(std::move(mesh));
}
