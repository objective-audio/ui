//
//  yas_ui_blur.mm
//

#include "yas_ui_blur.h"
#include <MetalPerformanceShaders/MetalPerformanceShaders.h>
#include <chaining/yas_chaining_umbrella.h>
#include "yas_ui_effect.h"
#include "yas_ui_metal_texture.h"
#include "yas_ui_texture.h"

using namespace yas;

struct ui::blur::impl : base::impl {
    chaining::value::holder<double> _sigma{0.0};
    ui::effect _effect;

    void prepare(std::shared_ptr<ui::blur> &blur) {
        auto weak_blur = to_weak(blur);

        this->_sigma_observer =
            this->_sigma.chain()
                .guard([weak_blur](double const &) { return !weak_blur.expired(); })
                .perform([weak_blur](double const &) { weak_blur.lock()->impl_ptr<impl>()->_update_effect_handler(); })
                .sync();
    }

   private:
    chaining::any_observer_ptr _sigma_observer = nullptr;

    void _update_effect_handler() {
        double const sigma = this->_sigma.raw();

        if (sigma > 0.0) {
            this->_effect.set_metal_handler(
                [sigma, prev_scale_factor = std::optional<double>{std::nullopt},
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

ui::blur::blur() : base(std::make_shared<blur::impl>()) {
}

void ui::blur::set_sigma(double const sigma) {
    impl_ptr<impl>()->_sigma.set_value(sigma);
}

double ui::blur::sigma() const {
    return impl_ptr<impl>()->_sigma.raw();
}

ui::effect &ui::blur::effect() {
    return impl_ptr<impl>()->_effect;
}

std::shared_ptr<ui::blur> ui::blur::make_shared() {
    auto shared = std::shared_ptr<blur>(new blur{});
    shared->impl_ptr<impl>()->prepare(shared);
    return shared;
}
