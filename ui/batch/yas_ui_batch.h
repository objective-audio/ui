//
//  yas_ui_batch.h
//

#pragma once

#include <ui/yas_ui_metal_setup_types.h>
#include <ui/yas_ui_render_info_dependency.h>
#include <ui/yas_ui_renderer_dependency.h>

#include <vector>

namespace yas::ui {
struct batch final : renderable_batch, render_encodable {
    ui::setup_metal_result metal_setup(std::shared_ptr<ui::metal_system> const &);

    [[nodiscard]] static std::shared_ptr<batch> make_shared();

   private:
    std::vector<ui::batch_render_mesh_info> _render_mesh_infos;
    std::vector<std::shared_ptr<mesh>> _render_meshes;
    ui::batch_building_type _building_type = ui::batch_building_type::none;
    std::shared_ptr<metal_system> _metal_system = nullptr;

    batch();

    batch(batch const &) = delete;
    batch(batch &&) = delete;
    batch &operator=(batch const &) = delete;
    batch &operator=(batch &&) = delete;

    std::vector<std::shared_ptr<mesh>> const &meshes() override;
    void begin_render_meshes_building(batch_building_type const) override;
    void commit_render_meshes_building() override;
    void clear_render_meshes() override;
    void append_mesh(std::shared_ptr<mesh> const &) override;

    ui::batch_render_mesh_info &_find_or_make_mesh_info(primitive_type const, std::shared_ptr<texture> const &);
    ui::batch_render_mesh_info &_add_mesh_info(primitive_type const, std::shared_ptr<texture> const &);
};
}  // namespace yas::ui
