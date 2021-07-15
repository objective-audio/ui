//
//  yas_ui_blur.mm
//

#include "yas_ui_blur.h"
#include <MetalPerformanceShaders/MetalPerformanceShaders.h>
#include <ui/yas_ui_effect.h>
#include <ui/yas_ui_metal_texture.h>
#include <ui/yas_ui_texture.h>

using namespace yas;
using namespace yas::ui;

blur::blur() : _effect(effect::make_shared()) {
    this->_update_effect_handler();
}

void blur::set_sigma(double const sigma) {
    if (this->_sigma != sigma) {
        this->_sigma = sigma;
        this->_update_effect_handler();
    }
}

double blur::sigma() const {
    return this->_sigma;
}

std::shared_ptr<effect> const &blur::effect() const {
    return this->_effect;
}

void blur::_update_effect_handler() {
    double const sigma = this->_sigma;

    if (sigma > 0.0) {
        this->_effect->set_metal_handler(
            [sigma, prev_scale_factor = std::optional<double>{std::nullopt},
             blur = objc_ptr<MPSImageGaussianBlur *>{nullptr}](
                std::shared_ptr<texture> const &src_texture, std::shared_ptr<texture> const &dst_texture,
                std::shared_ptr<metal_system> const &metal_system, id<MTLCommandBuffer> const commandBuffer) mutable {
                double const scale_factor = src_texture->scale_factor();

                if (!prev_scale_factor || scale_factor != *prev_scale_factor) {
                    prev_scale_factor = scale_factor;
                    double const blur_sigma = sigma * scale_factor;
                    blur = makable_metal_system::cast(metal_system)->make_mtl_blur(blur_sigma);
                }

                auto const srcTexture = src_texture->metal_texture()->texture();
                auto const dstTexture = dst_texture->metal_texture()->texture();
                [*blur encodeToCommandBuffer:commandBuffer sourceTexture:srcTexture destinationTexture:dstTexture];
            });
    } else {
        this->_effect->set_metal_handler(effect::through_metal_handler());
    }
}

std::shared_ptr<blur> blur::make_shared() {
    return std::shared_ptr<blur>(new blur{});
}
