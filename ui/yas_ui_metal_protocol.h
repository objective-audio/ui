//
//  yas_ui_metal_protocol.h
//

#pragma once

#include "yas_protocol.h"
#include "yas_result.h"

namespace yas {
namespace ui {
    class metal_system;

    enum class setup_metal_error {
        unknown,
        create_vertex_buffer_failed,
        create_index_buffer_failed,
        create_texture_descriptor_failed,
        create_texture_failed,
        create_sampler_descriptor_failed,
        create_sampler_failed,
    };

    using setup_metal_result = result<std::nullptr_t, setup_metal_error>;

    struct metal_object : protocol {
        struct impl : protocol::impl {
            virtual ui::setup_metal_result metal_setup(ui::metal_system const &) = 0;
        };

        explicit metal_object(std::shared_ptr<impl>);
        metal_object(std::nullptr_t);

        ui::setup_metal_result metal_setup(ui::metal_system const &);
    };
}

std::string to_string(ui::setup_metal_error const);
}

std::ostream &operator<<(std::ostream &, yas::ui::setup_metal_error const &);
