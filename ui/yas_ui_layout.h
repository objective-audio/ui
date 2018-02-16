//
//  yas_ui_layout.h
//

#pragma once

#include "yas_base.h"
#include "yas_ui_layout_guide.h"

namespace yas::ui {
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

namespace yas::ui::fixed_layout {
struct args {
    float distance;
    ui::layout_guide source_guide;
    ui::layout_guide destination_guide;
};
}

namespace yas::ui::justified_layout {
struct args {
    ui::layout_guide first_source_guide = nullptr;
    ui::layout_guide second_source_guide = nullptr;
    std::vector<ui::layout_guide> destination_guides;
    std::vector<float> ratios;
};
}

namespace yas::ui::min_layout {
struct args {
    std::vector<ui::layout_guide> source_guides;
    ui::layout_guide destination_guide;
};
}

namespace yas::ui::max_layout {
struct args {
    std::vector<ui::layout_guide> source_guides;
    ui::layout_guide destination_guide;
};
}

namespace yas::ui {
ui::layout make_layout(fixed_layout::args);
ui::layout make_layout(justified_layout::args);

ui::layout make_layout(min_layout::args);
ui::layout make_layout(max_layout::args);
}
