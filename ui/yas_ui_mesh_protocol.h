//
//  yas_ui_mesh_protocol.h
//

#pragma once

#include <Metal/Metal.h>
#include <cpp_utils/yas_flagset.h>
#include <simd/simd.h>
#include <ostream>

namespace yas::ui {
class batch_render_mesh_info;
enum class batch_building_type;

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

class renderable_mesh;
using renderable_mesh_ptr = std::shared_ptr<renderable_mesh>;

struct renderable_mesh {
    virtual ~renderable_mesh() = default;

    virtual simd::float4x4 const &matrix() = 0;
    virtual void set_matrix(simd::float4x4 const &) = 0;
    virtual std::size_t render_vertex_count() = 0;
    virtual std::size_t render_index_count() = 0;
    virtual mesh_updates_t const &updates() = 0;
    virtual bool pre_render() = 0;
    virtual void batch_render(batch_render_mesh_info &, ui::batch_building_type const) = 0;
    virtual bool is_rendering_color_exists() = 0;
    virtual void clear_updates() = 0;

    static renderable_mesh_ptr cast(renderable_mesh_ptr const &);
};
}  // namespace yas::ui

namespace yas {
std::string to_string(ui::mesh_update_reason const &);
}

std::ostream &operator<<(std::ostream &os, yas::ui::mesh_update_reason const &);
