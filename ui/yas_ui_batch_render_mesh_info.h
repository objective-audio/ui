//
//  yas_ui_batch_render_mesh_info.h
//

#pragma once

#include <vector>
#include "yas_ui_mesh.h"
#include "yas_ui_mesh_data.h"

namespace yas::ui {
struct batch_render_mesh_info {
    ui::mesh_ptr render_mesh = ui::mesh::make_shared();
    std::vector<ui::mesh_ptr> src_meshes;
    ui::dynamic_mesh_data_ptr mesh_data = nullptr;

    std::size_t vertex_count = 0;
    std::size_t index_count = 0;
    std::size_t vertex_idx = 0;
    std::size_t index_idx = 0;
};
}  // namespace yas::ui
