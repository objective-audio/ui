//
//  yas_ui_renderer_dependency.h
//

#pragma once

#include <cpp_utils/yas_flagset.h>
#include <simd/simd.h>
#include <ui/yas_ui_action_types.h>
#include <ui/yas_ui_render_info_dependency.h>
#include <ui/yas_ui_render_target_types.h>

namespace yas::ui {
enum class mesh_update_reason : std::size_t {
    vertex_data,
    index_data,
    texture,
    primitive_type,
    color,
    use_mesh_color,
    matrix,

    count,
};

using mesh_updates_t = flagset<mesh_update_reason>;

enum class mesh_data_update_reason : std::size_t {
    data_content,
    data_count,
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

struct tree_updates {
    node_updates_t node_updates;
    mesh_updates_t mesh_updates;
    mesh_data_updates_t vertex_data_updates;
    mesh_data_updates_t index_data_updates;
    render_target_updates_t render_target_updates;
    effect_updates_t effect_updates;

    [[nodiscard]] bool is_any_updated() const;
    [[nodiscard]] bool is_collider_updated() const;
    [[nodiscard]] bool is_render_target_updated() const;
    [[nodiscard]] ui::batch_building_type batch_building_type() const;
};

struct renderable_node {
    virtual ~renderable_node() = default;

    virtual void fetch_updates(ui::tree_updates &) = 0;
    virtual void build_render_info(ui::render_info &) = 0;
    [[nodiscard]] virtual bool is_rendering_color_exists() = 0;
    virtual void clear_updates() = 0;

    [[nodiscard]] static std::shared_ptr<renderable_node> cast(std::shared_ptr<renderable_node> const &node) {
        return node;
    }
};

struct renderable_batch {
    virtual ~renderable_batch() = default;

    [[nodiscard]] virtual std::vector<std::shared_ptr<mesh>> const &meshes() = 0;
    virtual void begin_render_meshes_building(batch_building_type const) = 0;
    virtual void commit_render_meshes_building() = 0;
    virtual void clear_render_meshes() = 0;

    [[nodiscard]] static std::shared_ptr<renderable_batch> cast(std::shared_ptr<renderable_batch> const &batch) {
        return batch;
    }
};

struct renderable_collider {
    virtual ~renderable_collider() = default;

    [[nodiscard]] virtual simd::float4x4 const &matrix() const = 0;
    virtual void set_matrix(simd::float4x4 const &) = 0;

    [[nodiscard]] static std::shared_ptr<renderable_collider> cast(
        std::shared_ptr<renderable_collider> const &renderable) {
        return renderable;
    }
};

struct detector_for_renderer : detector_for_render_info {
    virtual ~detector_for_renderer() = default;

    virtual void begin_update() = 0;
    virtual void end_update() = 0;

    [[nodiscard]] static std::shared_ptr<detector_for_renderer> cast(
        std::shared_ptr<detector_for_renderer> const &detector) {
        return detector;
    }
};

struct renderable_mesh {
    virtual ~renderable_mesh() = default;

    [[nodiscard]] virtual simd::float4x4 const &matrix() = 0;
    virtual void set_matrix(simd::float4x4 const &) = 0;
    [[nodiscard]] virtual std::size_t render_vertex_count() = 0;
    [[nodiscard]] virtual std::size_t render_index_count() = 0;
    [[nodiscard]] virtual mesh_updates_t const &updates() = 0;
    [[nodiscard]] virtual bool pre_render() = 0;
    virtual void batch_render(batch_render_mesh_info &, ui::batch_building_type const) = 0;
    [[nodiscard]] virtual bool is_rendering_color_exists() = 0;
    virtual void clear_updates() = 0;

    [[nodiscard]] static std::shared_ptr<renderable_mesh> cast(std::shared_ptr<renderable_mesh> const &mesh) {
        return mesh;
    }
};

struct renderable_effect {
    virtual ~renderable_effect() = default;

    virtual void set_textures(std::shared_ptr<texture> const &src, std::shared_ptr<texture> const &dst) = 0;
    [[nodiscard]] virtual ui::effect_updates_t &updates() = 0;
    virtual void clear_updates() = 0;

    [[nodiscard]] static std::shared_ptr<renderable_effect> cast(std::shared_ptr<renderable_effect> const &effect) {
        return effect;
    }
};

struct action_manager_for_renderer {
    virtual ~action_manager_for_renderer() = default;

    virtual void update(time_point_t const &) = 0;
};

struct view_look_for_renderer {
    virtual ~view_look_for_renderer() = default;

    [[nodiscard]] virtual simd::float4x4 const &projection_matrix() const = 0;
};

struct system_for_renderer {
    virtual ~system_for_renderer() = default;

    virtual void view_render(std::shared_ptr<ui::detector_for_render_info> const &,
                             simd::float4x4 const &projection_matrix, std::shared_ptr<ui::node> const &) = 0;
};
}  // namespace yas::ui

namespace yas {
std::string to_string(ui::node_update_reason const &);
std::string to_string(ui::batch_building_type const &);
std::string to_string(ui::mesh_data_update_reason const &);
std::string to_string(ui::mesh_update_reason const &);
std::string to_string(ui::effect_update_reason const &);
std::string to_string(ui::effect_updates_t const &);
}  // namespace yas

std::ostream &operator<<(std::ostream &os, yas::ui::node_update_reason const &);
std::ostream &operator<<(std::ostream &os, yas::ui::batch_building_type const &);
std::ostream &operator<<(std::ostream &os, yas::ui::mesh_data_update_reason const &);
std::ostream &operator<<(std::ostream &os, yas::ui::mesh_update_reason const &);
std::ostream &operator<<(std::ostream &os, yas::ui::effect_update_reason const &);
std::ostream &operator<<(std::ostream &os, yas::ui::effect_updates_t const &);
