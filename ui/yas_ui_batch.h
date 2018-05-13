//
//  yas_ui_batch.h
//

#pragma once

#include "yas_base.h"
#include "yas_ui_batch_protocol.h"
#include "yas_ui_metal_protocol.h"
#include "yas_ui_render_encoder_protocol.h"

namespace yas::ui {
class node;

class batch : public base {
    class impl;

   public:
    batch();
    batch(std::nullptr_t);

    virtual ~batch() final;

    ui::renderable_batch &renderable();
    ui::render_encodable &encodable();
    ui::metal_object &metal();

   private:
    ui::renderable_batch _renderable = nullptr;
    ui::render_encodable _encodable = nullptr;
    ui::metal_object _metal_object = nullptr;
};
}  // namespace yas::ui
