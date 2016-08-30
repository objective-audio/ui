//
//  yas_ui_layout.h
//

#pragma once

#include "yas_base.h"
#include "yas_ui_layout_guide.h"

namespace yas {
namespace ui {
    class layout_guide;

    class layout : public base {
        class impl;

       public:
        using handler_f = std::function<void(std::vector<ui::layout_guide> const &source_guides,
                                             std::vector<ui::layout_guide> &destination_guides)>;

        struct args {
            std::vector<ui::layout_guide> source_guides;
            std::vector<ui::layout_guide> destination_guides;
            handler_f handler;
        };

        explicit layout(args);
        layout(std::nullptr_t);

        virtual ~layout() final;

        std::vector<ui::layout_guide> const &source_guides() const;
        std::vector<ui::layout_guide> const &destination_guides() const;
    };

    struct fixed_layout_args {
        float distance;
        ui::layout_guide source_guide;
        ui::layout_guide destination_guide;
    };

    struct justified_layout_args {
        ui::layout_guide first_source_guide = nullptr;
        ui::layout_guide second_source_guide = nullptr;
        std::vector<ui::layout_guide> destination_guides;
        std::vector<float> ratios;
    };

    struct constant_layout_args {
        std::vector<ui::layout_guide> source_guides;
        ui::layout_guide destination_guide;
    };

    ui::layout make_fixed_layout(fixed_layout_args);
    ui::layout make_justified_layout(justified_layout_args);

    ui::layout make_min_layout(constant_layout_args);
    ui::layout make_max_layout(constant_layout_args);
}
}
