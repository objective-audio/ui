//
//  yas_ui_metal_protocol.h
//

#pragma once

#include <cpp_utils/yas_result.h>
#include <ostream>

namespace yas::ui {
class metal_system;

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

struct metal_object {
    virtual ~metal_object() = default;

    virtual ui::setup_metal_result metal_setup(std::shared_ptr<ui::metal_system> const &) = 0;
};

using metal_object_ptr = std::shared_ptr<metal_object>;
}  // namespace yas::ui

namespace yas {
std::string to_string(ui::setup_metal_error const);
}

std::ostream &operator<<(std::ostream &, yas::ui::setup_metal_error const &);
