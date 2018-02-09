//
//  yas_ui_texture_protocol.mm
//

#include "yas_ui_texture_protocol.h"

using namespace yas;

ui::renderable_texture::renderable_texture(std::shared_ptr<impl> impl) : protocol(std::move(impl)) {
}

ui::renderable_texture::renderable_texture(std::nullptr_t) : protocol(nullptr) {
}
