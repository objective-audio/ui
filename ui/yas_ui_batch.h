//
//  yas_ui_batch.h
//

#pragma once

#include "yas_ui_batch_protocol.h"
#include "yas_ui_metal_protocol.h"
#include "yas_ui_ptr.h"
#include "yas_ui_render_encoder_protocol.h"

namespace yas::ui {
struct batch final : renderable_batch, std::enable_shared_from_this<batch> {
    class impl;

    virtual ~batch();

    std::shared_ptr<ui::renderable_batch> renderable();
    ui::render_encodable &encodable();
    ui::metal_object &metal();

    [[nodiscard]] static batch_ptr make_shared();

   private:
    std::shared_ptr<impl> _impl;

    ui::render_encodable _encodable = nullptr;
    ui::metal_object _metal_object = nullptr;

    batch();

    batch(batch const &) = delete;
    batch(batch &&) = delete;
    batch &operator=(batch const &) = delete;
    batch &operator=(batch &&) = delete;

    std::vector<ui::mesh_ptr> const &meshes() override;
    void begin_render_meshes_building(batch_building_type const) override;
    void commit_render_meshes_building() override;
    void clear_render_meshes() override;
};
}  // namespace yas::ui
