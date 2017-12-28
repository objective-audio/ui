//
//  yas_ui_effect.mm
//

#include "yas_ui_metal_effect.h"

using namespace yas;

ui::metal_effect::metal_effect(std::shared_ptr<impl> impl) : protocol(std::move(impl)) {
}

ui::metal_effect::metal_effect(std::nullptr_t) : protocol(nullptr) {
}

void ui::metal_effect::encode(id<MTLCommandBuffer> const commandBuffer) {
    impl_ptr<impl>()->encode(commandBuffer);
}
