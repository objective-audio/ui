//
//  yas_ui_batch.h
//

#pragma once

#include <cpp_utils/yas_base.h>
#include "yas_ui_batch_protocol.h"
#include "yas_ui_metal_protocol.h"
#include "yas_ui_render_encoder_protocol.h"

namespace yas::ui {
class node;

struct batch final : base, renderable_batch, std::enable_shared_from_this<batch> {
    class impl;

    virtual ~batch();

    std::shared_ptr<ui::renderable_batch> renderable();
    ui::render_encodable &encodable();
    ui::metal_object &metal();

   private:
    ui::render_encodable _encodable = nullptr;
    ui::metal_object _metal_object = nullptr;

    batch();

    std::vector<ui::mesh> &meshes() override;
    void begin_render_meshes_building(batch_building_type const) override;
    void commit_render_meshes_building() override;
    void clear_render_meshes() override;

   public:
    static std::shared_ptr<batch> make_shared();
};
}  // namespace yas::ui
