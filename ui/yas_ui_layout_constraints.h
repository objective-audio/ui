//
//  yas_ui_layout_constraint.h
//

#pragma once

#include "yas_base.h"
#include "yas_ui_layout_guide.h"

namespace yas {
namespace ui {
    class layout_guide;

    class fixed_layout_constraint : public base {
        class impl;

       public:
        struct args {
            float distance;
            ui::layout_guide source_guide;
            ui::layout_guide destination_guide;
        };

        fixed_layout_constraint(args);
        fixed_layout_constraint(std::nullptr_t);

        virtual ~fixed_layout_constraint() final;

        void set_distance(float const);
        float const &distance() const;

        ui::layout_guide const &source_guide() const;
        ui::layout_guide const &destination_guide() const;
    };
}
}
