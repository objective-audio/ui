//
//  yas_ui_batch_protocol.h
//

#pragma once

#include <string>
#include <vector>
#include "yas_protocol.h"

namespace yas {
namespace ui {
    class mesh;

    enum class batch_building_type {
        none,
        rebuild,
        overwrite,
    };

    struct renderable_batch : protocol {
        struct impl : protocol::impl {
            virtual std::vector<ui::mesh> &meshes() = 0;
            virtual void begin_render_meshes_building(batch_building_type const) = 0;
            virtual void commit_render_meshes_building() = 0;
            virtual void clear_render_meshes() = 0;
        };

        explicit renderable_batch(std::shared_ptr<impl>);
        renderable_batch(std::nullptr_t);

        std::vector<ui::mesh> &meshes();
        void begin_render_meshes_building(batch_building_type const);
        void commit_render_meshes_building();
        void clear_render_meshes();
    };
}

std::string to_string(ui::batch_building_type const &);
}

std::ostream &operator<<(std::ostream &os, yas::ui::batch_building_type const &);
