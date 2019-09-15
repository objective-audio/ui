//
//  yas_ui_blur.mm
//

#include "yas_ui_blur.h"
#include <MetalPerformanceShaders/MetalPerformanceShaders.h>
#include "yas_ui_effect.h"
#include "yas_ui_metal_texture.h"
#include "yas_ui_texture.h"

using namespace yas;

ui::blur::blur() : _effect(ui::effect::make_shared()) {
}

void ui::blur::set_sigma(double const sigma) {
    this->_sigma->set_value(sigma);
}

double ui::blur::sigma() const {
    return this->_sigma->raw();
}

ui::effect_ptr &ui::blur::effect() {
    return this->_effect;
}

void ui::blur::_prepare(std::shared_ptr<ui::blur> &blur) {
    auto weak_blur = to_weak(blur);

    this->_sigma_observer = this->_sigma->chain()
                                .guard([weak_blur](double const &) { return !weak_blur.expired(); })
                                .perform([weak_blur](double const &) { weak_blur.lock()->_update_effect_handler(); })
                                .sync();
}

void ui::blur::_update_effect_handler() {
    double const sigma = this->_sigma->raw();

    if (sigma > 0.0) {
        this->_effect->set_metal_handler([sigma, prev_scale_factor = std::optional<double>{std::nullopt},
                                          blur = objc_ptr<MPSImageGaussianBlur *>{nullptr}](
                                             ui::texture_ptr const &src_texture, ui::texture_ptr const &dst_texture,
                                             ui::metal_system_ptr const &metal_system,
                                             id<MTLCommandBuffer> const commandBuffer) mutable {
            double const scale_factor = src_texture->scale_factor();

            if (!prev_scale_factor || scale_factor != *prev_scale_factor) {
                prev_scale_factor = scale_factor;
                double const blur_sigma = sigma * scale_factor;
                blur = ui::makable_metal_system::cast(metal_system)->make_mtl_blur(blur_sigma);
            }

            auto const srcTexture = src_texture->metal_texture()->texture();
            auto const dstTexture = dst_texture->metal_texture()->texture();
            [*blur encodeToCommandBuffer:commandBuffer sourceTexture:srcTexture destinationTexture:dstTexture];
        });
    } else {
        this->_effect->set_metal_handler(ui::effect::through_metal_handler());
    }
}

ui::blur_ptr ui::blur::make_shared() {
    auto shared = std::shared_ptr<blur>(new blur{});
    shared->_prepare(shared);
    return shared;
}
