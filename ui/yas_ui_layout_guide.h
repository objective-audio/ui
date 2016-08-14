//
//  yas_ui_layout_guide.h
//

#pragma once

#include "yas_base.h"
#include "yas_observing.h"
#include "yas_ui_types.h"

namespace yas {
namespace ui {
    class layout_guide : public base {
        class impl;

       public:
        struct change_context {
            float const &old_value;
            float const &new_value;
            layout_guide const &layout_guide;
        };

        enum class method {
            value_changed,
        };

        using subject_t = subject<change_context, method>;
        using observer_t = observer<change_context, method>;

        layout_guide();
        explicit layout_guide(float const);
        layout_guide(std::nullptr_t);

        virtual ~layout_guide() final;

        void set_value(float const);
        float const &value() const;

        subject_t &subject();
    };

    class layout_vertical_range : public base {
        class impl;

       public:
        struct args {
            float top_value = 0.0f;
            float bottom_value = 0.0f;
        };

        layout_vertical_range();
        explicit layout_vertical_range(args);
        layout_vertical_range(std::nullptr_t);

        virtual ~layout_vertical_range() final;

        layout_guide &top_guide();
        layout_guide &bottom_guide();
    };

    class layout_horizontal_range : public base {
        class impl;

       public:
        struct args {
            float left_value = 0.0f;
            float right_value = 0.0f;
        };

        layout_horizontal_range();
        explicit layout_horizontal_range(args);
        layout_horizontal_range(std::nullptr_t);

        virtual ~layout_horizontal_range() final;

        layout_guide &left_guide();
        layout_guide &right_guide();
    };

    class layout_rect : public base {
        class impl;

       public:
        struct args {
            layout_vertical_range::args vertical_range;
            layout_horizontal_range::args horizontal_range;
        };

        layout_rect();
        explicit layout_rect(args);
        layout_rect(std::nullptr_t);

        virtual ~layout_rect() final;

        layout_vertical_range &vertical_range();
        layout_horizontal_range &horizontal_range();
    };
}
}