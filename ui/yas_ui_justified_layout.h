//
//  yas_ui_justified_layout.h
//

#pragma once

#include "yas_base.h"
#include "yas_ui_layout_guide.h"

namespace yas {
namespace ui {
    class layout_guide;

    class justified_layout : public base {
        class impl;

       public:
        struct args {
            ui::layout_guide first_source_guide = nullptr;
            ui::layout_guide second_source_guide = nullptr;
            std::vector<ui::layout_guide> destination_guides;
        };

        justified_layout(args);
        justified_layout(std::nullptr_t);

        virtual ~justified_layout() final;

        ui::layout_guide const &first_source_guide() const;
        ui::layout_guide const &second_source_guide() const;
        std::vector<ui::layout_guide> const &destination_guides() const;
    };
}
}
