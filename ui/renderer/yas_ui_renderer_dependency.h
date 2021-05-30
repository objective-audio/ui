//
//  yas_ui_renderer_dependency.h
//

#pragma once

#include <Metal/Metal.h>
#include <simd/simd.h>
#include <ui/yas_ui_render_target_types.h>
#include <ui/yas_ui_types.h>

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
    view_rect,
    safe_area_rect,

    count,
};

using renderer_updates_t = flagset<renderer_update_reason>;

struct renderable_render_target {
    virtual ~renderable_render_target() = default;

    [[nodiscard]] virtual std::shared_ptr<mesh> const &mesh() const = 0;
    [[nodiscard]] virtual std::shared_ptr<effect> const &effect() const = 0;
    [[nodiscard]] virtual render_target_updates_t const &updates() const = 0;
    virtual void clear_updates() = 0;
    [[nodiscard]] virtual MTLRenderPassDescriptor *renderPassDescriptor() const = 0;
    [[nodiscard]] virtual simd::float4x4 const &projection_matrix() const = 0;
    [[nodiscard]] virtual bool push_encode_info(std::shared_ptr<render_stackable> const &) = 0;

    static std::shared_ptr<renderable_render_target> cast(
        std::shared_ptr<renderable_render_target> const &render_target) {
        return render_target;
    }
};

class render_info;

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

enum class batch_building_type;

struct tree_updates {
    node_updates_t node_updates;
    mesh_updates_t mesh_updates;
    mesh_data_updates_t mesh_data_updates;
    render_target_updates_t render_target_updates;
    effect_updates_t effect_updates;

    [[nodiscard]] bool is_any_updated() const;
    [[nodiscard]] bool is_collider_updated() const;
    [[nodiscard]] bool is_render_target_updated() const;
    [[nodiscard]] ui::batch_building_type batch_building_type() const;
};

struct renderable_node {
    virtual ~renderable_node() = default;

    [[nodiscard]] virtual std::shared_ptr<renderer> renderer() const = 0;
    virtual void set_renderer(std::shared_ptr<ui::renderer> const &) = 0;
    virtual void fetch_updates(ui::tree_updates &) = 0;
    virtual void build_render_info(ui::render_info &) = 0;
    [[nodiscard]] virtual bool is_rendering_color_exists() = 0;
    virtual void clear_updates() = 0;

    [[nodiscard]] static std::shared_ptr<renderable_node> cast(std::shared_ptr<renderable_node> const &node) {
        return node;
    }
};

enum class background_update_reason : std::size_t {
    color,
    alpha,

    count,
};

using background_updates_t = flagset<background_update_reason>;

struct renderer_background_interface {
    virtual ~renderer_background_interface() = default;

    [[nodiscard]] virtual background_updates_t const &updates() const = 0;
    virtual void clear_updates() = 0;

    [[nodiscard]] static std::shared_ptr<renderer_background_interface> cast(
        std::shared_ptr<renderer_background_interface> const &background) {
        return background;
    }
};

enum class batch_building_type {
    none,
    rebuild,
    overwrite,
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

struct renderer_detector_interface {
    virtual ~renderer_detector_interface() = default;

    [[nodiscard]] virtual bool is_updating() = 0;
    virtual void begin_update() = 0;
    virtual void push_front_collider(std::shared_ptr<collider> const &) = 0;
    virtual void end_update() = 0;

    [[nodiscard]] static std::shared_ptr<renderer_detector_interface> cast(
        std::shared_ptr<renderer_detector_interface> const &detector) {
        return detector;
    }
};

struct renderable_mesh_data {
    virtual ~renderable_mesh_data() = default;

    [[nodiscard]] virtual std::size_t vertex_buffer_byte_offset() = 0;
    [[nodiscard]] virtual std::size_t index_buffer_byte_offset() = 0;
    [[nodiscard]] virtual id<MTLBuffer> vertexBuffer() = 0;
    [[nodiscard]] virtual id<MTLBuffer> indexBuffer() = 0;

    [[nodiscard]] virtual mesh_data_updates_t const &updates() = 0;
    virtual void update_render_buffer() = 0;
    virtual void clear_updates() = 0;

    [[nodiscard]] static std::shared_ptr<renderable_mesh_data> cast(
        std::shared_ptr<renderable_mesh_data> const &mesh_data) {
        return mesh_data;
    }
};

class batch_render_mesh_info;

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
