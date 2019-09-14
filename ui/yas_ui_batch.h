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

    std::shared_ptr<ui::render_encodable> encodable();
    ui::metal_object_ptr metal();

    [[nodiscard]] static batch_ptr make_shared();

   private:
    class impl;

    std::unique_ptr<impl> _impl;
    std::weak_ptr<batch> _weak_batch;

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
};
}  // namespace yas::ui
