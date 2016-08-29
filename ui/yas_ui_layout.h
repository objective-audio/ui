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
}
}
