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

struct batch final : base {
    class impl;

    virtual ~batch();

    ui::renderable_batch &renderable();
    ui::render_encodable &encodable();
    ui::metal_object &metal();

   private:
    ui::renderable_batch _renderable = nullptr;
    ui::render_encodable _encodable = nullptr;
    ui::metal_object _metal_object = nullptr;

    batch();

   public:
    static std::unique_ptr<batch> make_unique();
};
}  // namespace yas::ui
