//
//  yas_ui_batch_protocol.h
//

#pragma once

#include <cpp_utils/yas_protocol.h>
#include <ostream>
#include <string>
#include <vector>

namespace yas::ui {
class mesh;

enum class batch_building_type {
    none,
    rebuild,
    overwrite,
};

struct renderable_batch {
    virtual ~renderable_batch() = default;
    
    virtual std::vector<ui::mesh> &meshes() = 0;
    virtual void begin_render_meshes_building(batch_building_type const) = 0;
    virtual void commit_render_meshes_building() = 0;
    virtual void clear_render_meshes() = 0;
};
}  // namespace yas::ui

namespace yas {
std::string to_string(ui::batch_building_type const &);
}

std::ostream &operator<<(std::ostream &os, yas::ui::batch_building_type const &);
