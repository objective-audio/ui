//
//  yas_ui_blur.mm
//

#include "yas_ui_blur.h"
#include "yas_ui_effect.h"
#include "yas_property.h"
#include "yas_ui_texture.h"
#include "yas_ui_metal_texture.h"
#include <MetalPerformanceShaders/MetalPerformanceShaders.h>

using namespace yas;

struct ui::blur::impl : base::impl {
    void prepare(ui::blur &blur) {
        auto weak_blur = to_weak(blur);

        this->_observers.emplace_back(this->_sigma_property.subject().make_observer(
            property_method::did_change, [weak_blur](auto const &context) {
                if (auto blur = weak_blur.lock()) {
                    blur.impl_ptr<impl>()->_update_effect_handler();
                }
            }));

        this->_update_effect_handler();
    }

    property<std::nullptr_t, double> _sigma_property{{.value = 0.0}};
    ui::effect _effect;

   private:
    void _update_effect_handler() {
        double const sigma = this->_sigma_property.value();

        if (sigma > 0.0) {
            this->_effect.set_metal_handler([blur = objc_ptr<MPSImageGaussianBlur *>(nil), sigma](
                ui::texture & texture, ui::metal_system & metal_system,
                id<MTLCommandBuffer> const commandBuffer) mutable {
                double const scale_factor = texture.scale_factor();
                blur = metal_system.makable().make_mtl_blur(sigma * scale_factor);
                auto mtl_texture = texture.metal_texture().texture();
                [*blur encodeToCommandBuffer:commandBuffer inPlaceTexture:&mtl_texture fallbackCopyAllocator:nil];
            });
        } else {
            this->_effect.set_metal_handler(nullptr);
        }
    }

    std::vector<base> _observers;
};

ui::blur::blur() : base(std::make_shared<impl>()) {
    impl_ptr<impl>()->prepare(*this);
}

ui::blur::blur(std::nullptr_t) : base(nullptr) {
}

void ui::blur::set_sigma(double const sigma) {
    impl_ptr<impl>()->_sigma_property.set_value(sigma);
}

double ui::blur::sigma() const {
    return impl_ptr<impl>()->_sigma_property.value();
}

ui::effect &ui::blur::effect() {
    return impl_ptr<impl>()->_effect;
}
