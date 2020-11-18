//
//  yas_ui_rect_plane.h
//

#pragma once

#include <ui/yas_ui_mesh_data.h>
#include <ui/yas_ui_node.h>
#include <ui/yas_ui_texture_element.h>
#include <ui/yas_ui_types.h>

#include <vector>

namespace yas::ui {
class color;

struct rect_plane_data final {
    using tex_coords_transform_f = std::function<ui::uint_region(ui::uint_region const &)>;

    virtual ~rect_plane_data();

    void write(std::function<void(ui::vertex2d_rect_t *, ui::index2d_rect_t *)> const &);
    void write_vertex(std::size_t const rect_idx, std::function<void(ui::vertex2d_rect_t &)> const &);
    void write_index(std::size_t const rect_idx, std::function<void(ui::index2d_rect_t &)> const &);

    std::size_t max_rect_count() const;
    std::size_t rect_count() const;
    void set_rect_count(std::size_t const);

    void set_rect_index(std::size_t const index_idx, std::size_t const vertex_idx);
    void set_rect_indices(std::vector<std::pair<std::size_t, std::size_t>> const &idx_pairs);
    void set_rect_position(ui::region const &region, std::size_t const rect_idx,
                           simd::float4x4 const &matrix = matrix_identity_float4x4);
    void set_rect_color(simd::float4 const &color, std::size_t const rect_idx);
    void set_rect_color(ui::color const &color, float const alpha, std::size_t const rect_idx);
    void set_rect_tex_coords(ui::uint_region const &pixel_region, std::size_t const rect_idx);
    void set_rect_vertex(const vertex2d_t *const in_ptr, std::size_t const rect_idx,
                         simd::float4x4 const &matrix = matrix_identity_float4x4);

    void observe_rect_tex_coords(ui::texture_element_ptr const &, std::size_t const rect_idx);
    void observe_rect_tex_coords(ui::texture_element_ptr const &, std::size_t const rect_idx, tex_coords_transform_f);
    void clear_observers();

    ui::dynamic_mesh_data_ptr const &dynamic_mesh_data();

    chaining::receiver<std::pair<ui::uint_region, std::size_t>> &rect_tex_coords_receiver();

    [[nodiscard]] static rect_plane_data_ptr make_shared(ui::dynamic_mesh_data_ptr mesh_data);
    [[nodiscard]] static rect_plane_data_ptr make_shared(std::size_t const max_rect_count);
    [[nodiscard]] static rect_plane_data_ptr make_shared(std::size_t const max_rect_count,
                                                         std::size_t const max_index_count);

   private:
    ui::dynamic_mesh_data_ptr _dynamic_mesh_data;
    std::vector<chaining::any_observer_ptr> _element_observers;
    chaining::perform_receiver_ptr<std::pair<ui::uint_region, std::size_t>> _rect_tex_coords_receiver;

    explicit rect_plane_data(ui::dynamic_mesh_data_ptr mesh_data);

    rect_plane_data(rect_plane_data const &) = delete;
    rect_plane_data(rect_plane_data &&) = delete;
    rect_plane_data &operator=(rect_plane_data const &) = delete;
    rect_plane_data &operator=(rect_plane_data &&) = delete;

    void _prepare(rect_plane_data_ptr const &);
    void _observe_rect_tex_coords(ui::rect_plane_data &, ui::texture_element_ptr const &, std::size_t const rect_idx,
                                  tex_coords_transform_f &&);
};

struct rect_plane final {
    ui::node_ptr &node();
    ui::rect_plane_data_ptr const &data();

    [[nodiscard]] static rect_plane_ptr make_shared(rect_plane_data_ptr const &);
    [[nodiscard]] static rect_plane_ptr make_shared(std::size_t const max_rect_count);
    [[nodiscard]] static rect_plane_ptr make_shared(std::size_t const max_rect_count,
                                                    std::size_t const max_index_count);

   private:
    ui::node_ptr _node = ui::node::make_shared();
    ui::rect_plane_data_ptr _rect_plane_data;

    explicit rect_plane(rect_plane_data_ptr const &);

    rect_plane(rect_plane const &) = delete;
    rect_plane(rect_plane &&) = delete;
    rect_plane &operator=(rect_plane const &) = delete;
    rect_plane &operator=(rect_plane &&) = delete;
};
}  // namespace yas::ui
