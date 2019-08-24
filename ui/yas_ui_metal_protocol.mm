//
//  yas_ui_metal_protocol.mm
//

#include "yas_ui_metal_protocol.h"

using namespace yas;

ui::metal_object::metal_object(std::shared_ptr<impl> impl) : protocol(std::move(impl)) {
}

ui::metal_object::metal_object(std::nullptr_t) : protocol(nullptr) {
}

ui::setup_metal_result ui::metal_object::metal_setup(std::shared_ptr<ui::metal_system> const &metal_system) {
    return impl_ptr<impl>()->metal_setup(metal_system);
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
        case ui::setup_metal_error::create_vertex_buffer_failed:
            return "create_vertex_buffer_failed";
        case ui::setup_metal_error::create_index_buffer_failed:
            return "create_index_buffer_failed";
        case ui::setup_metal_error::create_argument_encoder_failed:
            return "create_argument_encoder_failed";
        case ui::setup_metal_error::create_argument_buffer_failed:
            return "create_argument_buffer_failed";
        case ui::setup_metal_error::unknown:
            return "unknown";
    }
}

std::ostream &operator<<(std::ostream &os, yas::ui::setup_metal_error const &error) {
    os << to_string(error);
    return os;
}
