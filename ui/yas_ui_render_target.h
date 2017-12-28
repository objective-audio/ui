//
//  yas_ui_render_target.h
//

#pragma once

#include "yas_base.h"
#include "yas_ui_metal_system.h"
#include "yas_ui_metal_protocol.h"
#include "yas_ui_types.h"
#include "yas_ui_render_target_protocol.h"

namespace yas {
namespace ui {
    class mesh;
    class layout_guide_rect;

    class render_target : public base {
       public:
        class impl;

        render_target();
        render_target(std::nullptr_t);

        ui::layout_guide_rect &layout_guide_rect();

        void set_scale_factor(double const);
        double scale_factor() const;
        
        void set_blur_sigma(double const);
        double blur_sigma() const;

        ui::renderable_render_target &renderable();
        ui::metal_object &metal();

       private:
        ui::metal_object _metal_object = nullptr;
        ui::renderable_render_target _renderable = nullptr;
    };
}
}