//
//  yas_ui_blur.mm
//

#include "yas_ui_blur.h"
#include <MetalPerformanceShaders/MetalPerformanceShaders.h>
#include "yas_property.h"
#include "yas_ui_effect.h"
#include "yas_ui_metal_texture.h"
#include "yas_ui_texture.h"

using namespace yas;

struct ui::blur::impl : base::impl {
    property<double> _sigma_property{{.value = 0.0}};
    ui::effect _effect;

    void prepare(ui::blur &blur) {
        auto weak_blur = to_weak(blur);

        this->_sigma_flow =
            this->_sigma_property.begin_value_flow()
                .filter([weak_blur](double const &) { return !!weak_blur; })
                .perform([weak_blur](double const &) { weak_blur.lock().impl_ptr<impl>()->_update_effect_handler(); })
                .sync();
    }

   private:
    flow::observer _sigma_flow = nullptr;

    void _update_effect_handler() {
        double const sigma = this->_sigma_property.value();

        if (sigma > 0.0) {
            this->_effect.set_metal_handler(
                [sigma, prev_scale_factor = std::experimental::optional<double>{nullopt},
                 blur = objc_ptr<MPSImageGaussianBlur *>{nullptr}](ui::texture &src_texture, ui::texture &dst_texture,
                                                                   ui::metal_system &metal_system,
                                                                   id<MTLCommandBuffer> const commandBuffer) mutable {
                    double const scale_factor = src_texture.scale_factor();

                    if (!prev_scale_factor || scale_factor != *prev_scale_factor) {
                        prev_scale_factor = scale_factor;
                        double const blur_sigma = sigma * scale_factor;
                        blur = metal_system.makable().make_mtl_blur(blur_sigma);
                    }

                    auto const srcTexture = src_texture.metal_texture().texture();
                    auto const dstTexture = dst_texture.metal_texture().texture();
                    [*blur encodeToCommandBuffer:commandBuffer sourceTexture:srcTexture destinationTexture:dstTexture];
                });
        } else {
            this->_effect.set_metal_handler(ui::effect::through_metal_handler());
        }
    }
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
