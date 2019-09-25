//
//  yas_ui_batch.h
//

#pragma once

#include "yas_ui_batch_protocol.h"
#include "yas_ui_metal_protocol.h"
#include "yas_ui_ptr.h"
#include "yas_ui_render_encoder_protocol.h"

namespace yas::ui {
struct batch final : renderable_batch, render_encodable, metal_object {
    virtual ~batch();

    [[nodiscard]] static batch_ptr make_shared();

   private:
    std::vector<ui::batch_render_mesh_info> _render_mesh_infos;
    std::vector<ui::mesh_ptr> _render_meshes;
    ui::batch_building_type _building_type = ui::batch_building_type::none;
    ui::metal_system_ptr _metal_system = nullptr;

    batch();

    batch(batch const &) = delete;
    batch(batch &&) = delete;
    batch &operator=(batch const &) = delete;
    batch &operator=(batch &&) = delete;

    std::vector<ui::mesh_ptr> const &meshes() override;
    void begin_render_meshes_building(batch_building_type const) override;
    void commit_render_meshes_building() override;
    void clear_render_meshes() override;
    void append_mesh(ui::mesh_ptr const &) override;

    ui::setup_metal_result metal_setup(std::shared_ptr<ui::metal_system> const &) override;

    ui::batch_render_mesh_info &_find_or_make_mesh_info(ui::texture_ptr const &);
    ui::batch_render_mesh_info &_add_mesh_info(ui::texture_ptr const &);
};
}  // namespace yas::ui
