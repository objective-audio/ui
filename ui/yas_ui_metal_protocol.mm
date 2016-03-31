//
//  yas_ui_metal_protocol.mm
//

#include "yas_ui_metal_protocol.h"

using namespace yas;

ui::metal_object::metal_object(std::shared_ptr<impl> impl) : protocol(std::move(impl)) {
}

ui::setup_metal_result ui::metal_object::setup(id<MTLDevice> const device) {
    return impl_ptr<impl>()->setup(device);
}

std::string yas::to_string(ui::setup_metal_error const error) {
    switch (error) {
        case ui::setup_metal_error::create_texture_descriptor_failed:
            return "create_texture_descriptor_failed";
        case ui::setup_metal_error::create_texture_failed:
            return "create_texture_failed";
        case ui::setup_metal_error::create_sampler_descriptor_failed:
            return "create_sampler_descriptor_failed";
        case ui::setup_metal_error::create_sampler_failed:
            return "create_sampler_failed";
        default:
            return "unknown";
    }
}