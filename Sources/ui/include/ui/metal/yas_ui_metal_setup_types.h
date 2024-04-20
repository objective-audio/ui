//
//  yas_ui_metal_setup_types.h
//

#pragma once

#include <cpp-utils/yas_result.h>
#include <ui/common/yas_ui_types.h>

#include <ostream>

namespace yas::ui {
enum class setup_metal_error {
    unknown,
    create_vertex_buffer_failed,
    create_index_buffer_failed,
    create_texture_descriptor_failed,
    create_texture_failed,
    create_sampler_descriptor_failed,
    create_sampler_failed,
    create_argument_encoder_failed,
    create_argument_buffer_failed,
};

using setup_metal_result = result<std::nullptr_t, setup_metal_error>;
}  // namespace yas::ui

namespace yas {
std::string to_string(ui::setup_metal_error const);
}

std::ostream &operator<<(std::ostream &, yas::ui::setup_metal_error const &);
