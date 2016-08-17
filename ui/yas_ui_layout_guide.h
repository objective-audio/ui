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
        using value_changed_f = std::function<void(float const)>;

        layout_guide();
        explicit layout_guide(float const);
        layout_guide(std::nullptr_t);

        virtual ~layout_guide() final;

        void set_value(float const);
        float const &value() const;

        void set_value_changed_handler(value_changed_f);

        subject_t &subject();
    };

    class layout_guide_point : public base {
        class impl;

       public:
        layout_guide_point();
        explicit layout_guide_point(ui::float_origin);
        layout_guide_point(std::nullptr_t);

        virtual ~layout_guide_point() final;

        ui::layout_guide &x_guide();
        ui::layout_guide &y_guide();
    };

    class layout_guide_range : public base {
        class impl;

       public:
        layout_guide_range();
        explicit layout_guide_range(ui::float_range);
        layout_guide_range(std::nullptr_t);

        virtual ~layout_guide_range() final;

        layout_guide &min_guide();
        layout_guide &max_guide();

        void set_range(ui::float_range);
    };

    class layout_guide_rect : public base {
        class impl;

       public:
        struct args {
            ui::float_range vertical_range;
            ui::float_range horizontal_range;
        };

        layout_guide_rect();
        explicit layout_guide_rect(args);
        layout_guide_rect(std::nullptr_t);

        virtual ~layout_guide_rect() final;

        layout_guide_range &vertical_range();
        layout_guide_range &horizontal_range();

        layout_guide &left_guide();
        layout_guide &right_guide();
        layout_guide &bottom_guide();
        layout_guide &top_guide();

        void set_ranges(args);
        void set_region(ui::float_region);
    };
}
}