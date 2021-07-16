//
//  yas_ui_renderer_dependency_cpp.h
//

#pragma once

#include <cpp_utils/yas_flagset.h>
#include <simd/simd.h>

namespace yas::ui {
enum class mesh_update_reason : std::size_t {
    mesh_data,
    texture,
    primitive_type,
    color,
    use_mesh_color,
    matrix,

    count,
};

using mesh_updates_t = flagset<mesh_update_reason>;

enum class mesh_data_update_reason : std::size_t {
    data,
    vertex_count,
    index_count,
    render_buffer,

    count,
};

using mesh_data_updates_t = flagset<mesh_data_update_reason>;

enum class effect_update_reason : std::size_t {
    textures,
    handler,

    count,
};

using effect_updates_t = flagset<effect_update_reason>;

enum class renderer_update_reason : std::size_t {
    view_region,
    safe_area_region,

    count,
};

using renderer_updates_t = flagset<renderer_update_reason>;

enum class node_update_reason : std::size_t {
    geometry,
    mesh,
    collider,
    enabled,
    children,
    batch,
    render_target,

    count,
};

using node_updates_t = flagset<node_update_reason>;

enum class background_update_reason : std::size_t {
    color,
    alpha,

    count,
};

enum class batch_building_type {
    none,
    rebuild,
    overwrite,
};

struct renderable_view_look {
    virtual ~renderable_view_look() = default;

    [[nodiscard]] virtual simd::float4x4 const &projection_matrix() const = 0;
};
}  // namespace yas::ui
