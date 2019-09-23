//
//  yas_ui_mesh_data.h
//

#pragma once

#include <cpp_utils/yas_objc_ptr.h>
#include <vector>
#include "yas_ui_mesh_data_protocol.h"
#include "yas_ui_metal_protocol.h"
#include "yas_ui_ptr.h"
#include "yas_ui_types.h"

namespace yas::ui {
struct mesh_data : renderable_mesh_data, metal_object {
    struct args {
        std::size_t vertex_count = 0;
        std::size_t index_count = 0;
    };

    ui::vertex2d_t const *vertices() const;
    std::size_t vertex_count() const;
    ui::index2d_t const *indices() const;
    std::size_t index_count() const;

    virtual void write(std::function<void(std::vector<ui::vertex2d_t> &, std::vector<ui::index2d_t> &)> const &);

    std::shared_ptr<ui::metal_system> const &metal_system();

    [[nodiscard]] static mesh_data_ptr make_shared(args);

   protected:
    std::size_t _vertex_count;
    std::size_t _index_count;
    std::vector<ui::vertex2d_t> _vertices;
    std::vector<ui::index2d_t> _indices;
    std::size_t _dynamic_buffer_index = 0;
    mesh_data_updates_t _updates;

    mesh_data(args &&);

    virtual std::size_t dynamic_buffer_count();

   private:
    ui::metal_system_ptr _metal_system = nullptr;

    objc_ptr<id<MTLBuffer>> _vertex_buffer;
    objc_ptr<id<MTLBuffer>> _index_buffer;

    mesh_data(mesh_data const &) = delete;
    mesh_data(mesh_data &&) = delete;
    mesh_data &operator=(mesh_data const &) = delete;
    mesh_data &operator=(mesh_data &&) = delete;

    std::size_t vertex_buffer_byte_offset() override;
    std::size_t index_buffer_byte_offset() override;
    id<MTLBuffer> vertexBuffer() override;
    id<MTLBuffer> indexBuffer() override;

    mesh_data_updates_t const &updates() override;
    void update_render_buffer() override;
    void clear_updates() override;

    ui::setup_metal_result metal_setup(std::shared_ptr<ui::metal_system> const &) override;
};

struct dynamic_mesh_data final : mesh_data {
    virtual ~dynamic_mesh_data();

    std::size_t max_vertex_count() const;
    std::size_t max_index_count() const;

    void set_vertex_count(std::size_t const);
    void set_index_count(std::size_t const);

    void write(std::function<void(std::vector<ui::vertex2d_t> &, std::vector<ui::index2d_t> &)> const &func) override;

    [[nodiscard]] static dynamic_mesh_data_ptr make_shared(args);

   private:
    dynamic_mesh_data(args &&);

    dynamic_mesh_data(dynamic_mesh_data const &) = delete;
    dynamic_mesh_data(dynamic_mesh_data &&) = delete;
    dynamic_mesh_data &operator=(dynamic_mesh_data const &) = delete;
    dynamic_mesh_data &operator=(dynamic_mesh_data &&) = delete;

    std::size_t vertex_buffer_byte_offset() override;
    std::size_t index_buffer_byte_offset() override;

    std::size_t dynamic_buffer_count() override;
};
}  // namespace yas::ui
