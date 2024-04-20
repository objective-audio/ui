//
//  yas_ui_batch_render_mesh_info.h
//

#pragma once

#include <ui/mesh/yas_ui_mesh.h>

#include <vector>

namespace yas::ui {
struct batch_render_mesh_info {
    std::shared_ptr<mesh> render_mesh = ui::mesh::make_shared();
    std::vector<std::shared_ptr<mesh>> src_meshes;
    std::shared_ptr<dynamic_mesh_vertex_data> vertex_data = nullptr;
    std::shared_ptr<dynamic_mesh_index_data> index_data = nullptr;

    std::size_t vertex_count = 0;
    std::size_t index_count = 0;
    std::size_t vertex_idx = 0;
    std::size_t index_idx = 0;
};
}  // namespace yas::ui
